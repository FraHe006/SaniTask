extends Window

# Configuración de la API
const API_URL = "http://localhost:3000/api/citas"
const API_TOKEN = ""
const DB_PATH = "user://datos.db"

# Referencias a nodos de la escena
@onready var http_request = $HTTPRequest
@onready var item_list = $Panel/ListaCitasHoy
@onready var citas = $Citas
@onready var boton_nueva_nota = $BotonNuevaNota

# Variables de estado
var pacientes_cache = []  # Almacena las citas cargadas desde la API
var db: SQLite = null  # Conexión a la base de datos SQLite
var empleado_id: int = 0  # ID del empleado actualmente logueado

func _ready():
	# Conecta la señal de selección de items
	item_list.item_selected.connect(_on_paciente_seleccionado)
	
	# Configura la base de datos local
	_inicializar_db()
	
	# Obtiene el ID del empleado desde la base de datos
	empleado_id = _obtener_id_empleado_actual()
	
	# Inicializa la ventana de detalles de citas
	citas.inicializar(self)
	
	# Conecta el botón de nueva cita si existe en la escena
	if boton_nueva_nota:
		boton_nueva_nota.pressed.connect(_on_button_nueva_cita_pressed)
	
	# Carga las citas del empleado
	cargar_citas()

func _inicializar_db():
	db = SQLite.new()
	db.path = DB_PATH
	db.open_db()


# Solicita al servidor las citas del empleado registrado para hoy
func cargar_citas():
	var url_con_filtro = API_URL + "?responsableMedicoId=" + str(empleado_id)
	var headers = _get_headers()
	var error = http_request.request(url_con_filtro, headers, HTTPClient.METHOD_GET)
	
	if error != OK:
		_mostrar_error("Error al iniciar petición HTTP: " + str(error))


# Actualiza la lista visual con las citas recibidas
func _actualizar_lista(citas_list: Array):
	item_list.clear()
	
	if citas_list.is_empty():
		return
	
	# Ordena las citas por hora cronológicamente
	citas_list.sort_custom(func(a, b): 
		return a.get("fechaHoraCita", "") < b.get("fechaHoraCita", "")
	)
	
	# Agrega cada cita a la lista visual
	for cita in citas_list:
		var nombre = cita.get("nombre", "Sin nombre")
		var fecha_hora_cita = cita.get("fechaHoraCita", "")
		var hora_formateada = _formatear_hora(fecha_hora_cita)
		
		# Formato de texto: "08:00 - María Fernández"
		var texto = "%s - %s" % [hora_formateada, nombre]
		item_list.add_item(texto)
		
		# Almacena el ID de la cita en los metadatos para acceso posterior
		var cita_id = cita.get("id", 0)
		item_list.set_item_metadata(item_list.item_count - 1, cita_id)

# Convierte fecha ISO (2026-02-05T08:00:00.000Z) a formato de hora 
func _formatear_hora(fecha_iso: String) -> String:
	if fecha_iso.is_empty():
		return "00:00"
	
	# Separa fecha y hora por la T
	var partes = fecha_iso.split("T")
	if partes.size() < 2:
		return "00:00"
	
	# Extrae solo hora y minutos (08:00:00 -> 08:00)
	var hora_completa = partes[1].split(".")[0]
	var hora_min = hora_completa.substr(0, 5)
	
	return hora_min

# Filtra las citas localmente por nombre de paciente u hora
func _filtrar_pacientes_local(busqueda: String):
	var filtrados = []
	var busqueda_lower = busqueda.to_lower()
	
	for cita in pacientes_cache:
		var nombre = cita.get("nombre", "").to_lower()
		var hora = _formatear_hora(cita.get("fechaHoraCita", ""))
		
		# Incluye la cita si coincide con el nombre o la hora
		if nombre.contains(busqueda_lower) or hora.contains(busqueda_lower):
			filtrados.append(cita)
	
	_actualizar_lista(filtrados)

# Genera los headers HTTP necesarios para las peticiones
func _get_headers() -> Array:
	var headers = ["Content-Type: application/json"]
	if not API_TOKEN.is_empty():
		headers.append("Authorization: Bearer " + API_TOKEN)
	return headers

# Consulta la base de datos local para obtener el ID del empleado logueado
func _obtener_id_empleado_actual() -> int:
	if db == null:
		return 0
	
	db.query("SELECT id FROM sesion_empleado WHERE id = 1")
	var result = db.query_result
	
	if result.size() > 0:
		return int(result[0].get("id", 0))
	
	return 0

# Se ejecuta cada vez que el usuario escribe en el buscador
func _on_buscar_text_changed(nuevo_texto: String):
	if nuevo_texto.is_empty():
		_actualizar_lista(pacientes_cache)
	else:
		_filtrar_pacientes_local(nuevo_texto)

# Se ejecuta cuando el usuario selecciona una cita de la lista
func _on_paciente_seleccionado(index: int):
	var cita_id = item_list.get_item_metadata(index)
	_abrir_ventana_detalle(cita_id)

# Abre la ventana de detalles para ver/editar una cita
func _abrir_ventana_detalle(cita_id: int):
	if citas:
		citas.cargar_cita(cita_id)
		citas.popup_centered()
	else:
		_mostrar_error("La ventana de citas no está configurada")


# Abre la ventana para crear una nueva cita
func _on_button_nueva_cita_pressed():
	_abrir_ventana_detalle(0)  # 0 indica nueva cita

# ==================== MENSAJES ====================

# Muestra un diálogo con mensaje de error
func _mostrar_error(mensaje: String):
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

# ==================== HTTP ====================

# Maneja la respuesta de las peticiones HTTP
func _on_http_request_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Verifica que la conexión fue exitosa
	if result != HTTPRequest.RESULT_SUCCESS:
		_mostrar_error("Error de conexión: código " + str(result))
		return
	
	# Obtiene el texto de la respuesta
	var response_text = body.get_string_from_utf8()
	
	if response_text.is_empty():
		_mostrar_error("Respuesta vacía del servidor")
		return
	
	# Intenta parsear el JSON
	var json = JSON.parse_string(response_text)
	
	if json == null:
		_mostrar_error("Error al parsear respuesta del servidor")
		return
	
	# Procesa la respuesta según el código HTTP
	match response_code:
		200:  # Petición exitosa
			if json is Array:
				pacientes_cache = json
				_actualizar_lista(json)
			else:
				_mostrar_error("Se esperaba un Array de citas, recibido: " + str(typeof(json)))
		
		400:  # Datos inválidos
			var mensaje = "Datos inválidos"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		
		404:  # No encontrado
			pacientes_cache = []
			_actualizar_lista([])
		
		500:  # Error del servidor
			var mensaje = "Error del servidor"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		
		_:  # Otros códigos de error
			_mostrar_error("Error HTTP " + str(response_code))

# Se ejecuta al destruir el nodo - cierra la conexión de base de datos
func _exit_tree():
	if db:
		db.close_db()
