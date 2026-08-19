extends Window

# Configuración de la API
const API_URL = "http://localhost:3000/api/pacientes"
const API_TOKEN = ""

# Referencias a elementos de la interfaz
@onready var http_request = $HTTPRequest  
@onready var line_edit = $LineEdit  
@onready var item_list = $Panel/ListaPacientes 
@onready var historial = $Historial  

var pacientes_cache = []  # Array con todos los pacientes cargados

func _ready():
	line_edit.text_changed.connect(_on_buscar_text_changed)
	item_list.item_selected.connect(_on_paciente_seleccionado)
	historial.inicializar(self)  
	cargar_pacientes()

# Carga todos los pacientes desde la API
func cargar_pacientes():
	var headers = _get_headers()
	http_request.request(API_URL, headers, HTTPClient.METHOD_GET)

# Buscar pacientes por nombre en la API
func buscar_paciente(nombre: String):
	if nombre.is_empty():
		cargar_pacientes()
		return
	
	var url = API_URL + "?nombre=" + nombre.uri_encode()
	var headers = _get_headers()
	http_request.request(url, headers, HTTPClient.METHOD_GET)

# Actualizar la lista de los pacientes
func _actualizar_lista(pacientes: Array):
	item_list.clear()
	for emp in pacientes:
		var texto = emp.get("nombre", "")
		item_list.add_item(texto)
		# Guardar ID del paciente en metadatos
		item_list.set_item_metadata(item_list.item_count - 1, emp.get("id"))

# Filtrar pacientes según texto de búsqueda
func _filtrar_pacientes_local(busqueda: String):
	var filtrados = []
	var busqueda_lower = busqueda.to_lower()
	
	for emp in pacientes_cache:
		var nombre_completo = (emp.get("nombre", "")).to_lower()
		if nombre_completo.contains(busqueda_lower):
			filtrados.append(emp)
	
	_actualizar_lista(filtrados)

# Generar headers HTTP con su token de autenticación
func _get_headers() -> Array:
	var headers = ["Content-Type: application/json"]
	if not API_TOKEN.is_empty():
		headers.append("Authorization: Bearer " + API_TOKEN)
	return headers

# Esta funcion se ejecuta cuando el usuario utiliza el buscador
func _on_buscar_text_changed(nuevo_texto: String):
	if nuevo_texto.is_empty():
		_actualizar_lista(pacientes_cache)  # Mostrar todos
	else:
		_filtrar_pacientes_local(nuevo_texto)  # Filtrar localmente

# Esta funcion se ejecuta cuando se selecciona un paciente de la lista
func _on_paciente_seleccionado(index: int):
	var paciente_id = item_list.get_item_metadata(index)
	_abrir_ventana_detalle(paciente_id)

# Abre la ventana de detalles con el paciente seleccionado
func _abrir_ventana_detalle(paciente_id: int):
	historial.cargar_paciente(paciente_id)
	historial.show()

# Botón para crear nuevo paciente
func _on_button_pressed():
	_abrir_ventana_detalle(0)  # 0 = nuevo paciente

# Recarga la lista cuando se cierra la ventana de detalle
func _on_ventana_detalle_cerrada() -> void:
	cargar_pacientes()
	historial.hide()

# Muestra un diálogo de error
func _mostrar_error(mensaje: String):
	print("ERROR: ", mensaje)
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()

# Imprime mensaje de éxito
func _mostrar_exito(mensaje: String):
	print("ÉXITO: ", mensaje)

# Procesa la respuesta HTTP de la API
func _on_http_request_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Validar conexión exitosa
	if result != HTTPRequest.RESULT_SUCCESS:
		_mostrar_error("Error de conexión")
		return
	
	var response_text = body.get_string_from_utf8()
	
	if response_text.is_empty():
		_mostrar_error("Respuesta vacía del servidor")
		return
	
	# Parsear JSON
	var json = JSON.parse_string(response_text)
	
	if json == null:
		_mostrar_error("Error al parsear JSON: " + response_text)
		return
	
	# Manejar diferentes códigos de respuesta
	match response_code:
		200:  # GET exitoso
			if json is Array:
				pacientes_cache = json
				_actualizar_lista(json)
			else:
				_mostrar_error("Se esperaba Array, recibido: " + str(typeof(json)))
		400:
			var mensaje = "Datos inválidos"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		404:
			_mostrar_error("Error: No se encontraron pacientes")
		500:
			var mensaje = "Error del servidor"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		_:
			_mostrar_error("Error " + str(response_code) + ": " + response_text)
