extends Window

# Configuración de la API
const API_URL = "http://localhost:3000/api/empleados"
const API_TOKEN = ""

# Referencias a nodos de la interfaz
@onready var http_request = $HTTPRequest
@onready var line_edit = $LineEdit
@onready var item_list = $Panel/ListaEmpleados
@onready var historial = $Historial

# Almacenamiento local de datos
# Diseñados para abrir más
var empleados_cache = []
var ventanas_detalle_abiertas = []

func _ready():
	# Conecta las señales de los elementos de interfaz
	line_edit.text_changed.connect(_on_buscar_text_changed)
	item_list.item_selected.connect(_on_empleado_seleccionado)
	historial.inicializar(self)
	cargar_empleados()

# Carga todos los empleados 
func cargar_empleados():
	var headers = _get_headers()
	http_request.request(API_URL, headers, HTTPClient.METHOD_GET)

# Busca empleados por nombre
func buscar_empleado(nombre: String):
	if nombre.is_empty():
		cargar_empleados()
		return
	
	var url = API_URL + "?nombre=" + nombre.uri_encode()
	var headers = _get_headers()
	http_request.request(url, headers, HTTPClient.METHOD_GET)

# Actualiza la lista con los empleados 
func _actualizar_lista(empleados: Array):
	item_list.clear()
	for emp in empleados:
		var texto = emp.get("nombre", "")
		item_list.add_item(texto)
		# Guarda el ID del empleado 
		item_list.set_item_metadata(item_list.item_count - 1, emp.get("id"))

# Buscar empleados
func _filtrar_empleados_local(busqueda: String):
	var filtrados = []
	var busqueda_lower = busqueda.to_lower()
	
	for emp in empleados_cache:
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

# Se ejecuta cada vez que el usuario escribe en el buscador
func _on_buscar_text_changed(nuevo_texto: String):
	if nuevo_texto.is_empty():
		_actualizar_lista(empleados_cache)
	else:
		_filtrar_empleados_local(nuevo_texto)

# Se ejecuta cuando el usuario selecciona un empleado de la lista
func _on_empleado_seleccionado(index: int):
	var empleado_id = item_list.get_item_metadata(index)
	_abrir_ventana_detalle(empleado_id)

# Abre la ventana de edición con los datos del empleado seleccionado
func _abrir_ventana_detalle(empleado_id: int):
	historial.cargar_empleado(empleado_id)
	historial.show()

# Abre la ventana de edición para crear un nuevo empleado
func _on_button_pressed():
	_abrir_ventana_detalle(0) # 0 = nuevo empleado

func _on_ventana_detalle_cerrada() -> void:
	cargar_empleados()
	historial.hide()

# Muestra un un mensaje de error
func _mostrar_error(mensaje: String):
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()

# Maneja la respuesta de las peticiones HTTP
func _on_http_request_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Verifica que la petición se completó correctamente
	if result != HTTPRequest.RESULT_SUCCESS:
		_mostrar_error("Error de conexión")
		return
	
	# Obtiene el texto de la respuesta
	var response_text = body.get_string_from_utf8()
	
	if response_text.is_empty():
		_mostrar_error("Respuesta vacía del servidor")
		return
	
	# Parsea el JSON recibido
	var json = JSON.parse_string(response_text)
	
	if json == null:
		_mostrar_error("Error al parsear JSON: " + response_text)
		return
	
	# Procesa la respuesta según el código HTTP
	match response_code:
		200:
			# Petición exitosa
			if json is Array:
				
				empleados_cache = json
				_actualizar_lista(json)
			else:
				_mostrar_error("Se esperaba Array, recibido: " + str(typeof(json)))
		400:
			# Datos inválidos
			var mensaje = "Datos inválidos"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		404:
			# No encontrado
			_mostrar_error("Error: No se encontraron empleados")
		500:
			# Error del servidor
			var mensaje = "Error del servidor"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		_:
			# Otros errores
			_mostrar_error("Error " + str(response_code) + ": " + response_text)
