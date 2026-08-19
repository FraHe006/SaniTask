extends Window

# Configuración de la API
const API_URL = "http://localhost:3000/api/empleado/validar"
const WindowsDesktop = "res://WindowsDesktop.tscn"

@onready var http_request = $HTTPRequest
@onready var txt_usuario = $InicioSesion/Nombre
@onready var txt_codigo = $InicioSesion/Codigo
@onready var btn_login = $InicioSesion/login

# SQLite
var db: SQLite

func _ready() -> void:
	move_to_center()
	_inicializar_base_datos() # iniciar base de datos

# ==================== BASE DE DATOS SQLite ====================
func _inicializar_base_datos():
	db = SQLite.new()
	db.path = "user://app_data.db"  # base de datos
	db.open_db()
	
	# Sesión de empleado
	var tabla_sesion = """
	CREATE TABLE IF NOT EXISTS sesion_empleado (
		id INTEGER PRIMARY KEY,
		tipo_empleado TEXT NOT NULL,
		nombre_empleado TEXT NOT NULL
	);
	"""
	db.query(tabla_sesion)
	
	# Notas
	var tabla_notas = """
	CREATE TABLE IF NOT EXISTS notas (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		titulo TEXT NOT NULL,
		contenido TEXT
	);
	"""
	db.query(tabla_notas)
	
	# Tareas
	var tabla_tareas = """
	CREATE TABLE IF NOT EXISTS tareas (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		nombre TEXT NOT NULL,
		completada INTEGER DEFAULT 0,
		fecha DATETIME DEFAULT CURRENT_TIMESTAMP
	);
	"""
	db.query(tabla_tareas) 
	
	# PDF
	var tabla_ficheros = """
	CREATE TABLE IF NOT EXISTS ficheros (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		nombre TEXT NOT NULL, 
		cita_id INTEGER,
		fecha_creacion DEFAULT CURRENT_TIMESTAMP
	);
	"""
	db.query(tabla_ficheros)
	
# función para guardar la sesión
func _guardar_sesion(tipo_empleado: String, nombre_empleado: String):
	# Borrar sesiones antiguas
	db.query("DELETE FROM sesion_empleado;")
	
	# Guardar la nueva sesión
	var query = "INSERT INTO sesion_empleado (tipo_empleado, nombre_empleado) VALUES ('%s', '%s');" % [tipo_empleado, nombre_empleado]
	db.query(query)
	db.close_db()

# ==================== PERMISOS ====================
func _obtener_puesto_por_codigo(codigo: String) -> String:
	var prefijo = codigo.substr(0, 3).to_upper()
	
	match prefijo:
		"ADM": return "Administrador"
		"DOC": return "Doctor"
		"GER": return "Gerente"
		_: return "Empleado General"

# Iniciar sesión
func _on_login_pressed():
	if not _validar_campos():
		return
	
	# Preparar datos para enviar
	var datos = {
		"usuario": txt_usuario.text.strip_edges(),
		"codigoEmpleado": txt_codigo.text.strip_edges()
	}
	
	# Validar que los datos existan en la base de datos
	var json_string = JSON.stringify(datos)
	var headers = ["Content-Type: application/json"]
	
	http_request.request(API_URL, headers, HTTPClient.METHOD_POST, json_string)

# Validar de que existan datos en el formulario
func _validar_campos() -> bool:
	if txt_usuario.text.strip_edges().is_empty():
		_mostrar_error("El usuario es obligatorio")
		return false
	
	if txt_codigo.text.strip_edges().is_empty():
		_mostrar_error("El código de empleado es obligatorio")
		return false
	
	return true

# HTTP
func _on_http_request_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_mostrar_error("Error de conexión con el servidor")
		return
	
	var response_text = body.get_string_from_utf8()
	
	if response_text.is_empty():
		_mostrar_error("El servidor no respondió")
		return
	
	var json = JSON.parse_string(response_text)
	
	if json == null:
		_mostrar_error("Error al procesar respuesta del servidor")
		return
	
	match response_code:
		200:  # Login correcto
			if json is Dictionary and json.has("nombre"):
				var codigo = txt_codigo.text.strip_edges()
				var nombre = json.get("nombre")
				
				# Discernir puesto según el código de empleado
				var tipo_empleado = _obtener_puesto_por_codigo(codigo)
				
				# Guardar en SQLite los datos para futuros usos
				_guardar_sesion(tipo_empleado, nombre)
				
				# Mostrar mensaje de éxito al usuario
				_mostrar_exito("Bienvenido/a %s" % [nombre])
				
				# Cambiar a la escena principal
				await get_tree().create_timer(1.5).timeout
				get_tree().change_scene_to_file(WindowsDesktop)
			else:
				_mostrar_error("Formato de respuesta inválido")
		401:
			_mostrar_error("Usuario o código incorrecto")
		404:
			_mostrar_error("Empleado no encontrado")
		_:
			_mostrar_error("Error del servidor: " + str(response_code))

func _mostrar_error(mensaje: String):
	print("ERROR: ", mensaje)
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()

func _mostrar_exito(mensaje: String):
	print("ÉXITO: ", mensaje)
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()

func _on_close_requested() -> void:
	get_tree().quit()
