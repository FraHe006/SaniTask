extends Window

const API_URL_ENVIAR = "http://localhost:3000/api/enviarCorreo"
const DB_PATH = "user://app_data.db"

@onready var http_request = $HTTPRequest
@onready var txt_destinatario = $CuerpoMensaje/Destinatario
@onready var txt_asunto = $CuerpoMensaje/Asunto
@onready var txt_cuerpo = $CuerpoMensaje/Cuerpo

var db: SQLite = null
var archivo_adjunto: String = ""

func _ready():
	_inicializar_db()

func _inicializar_db():
	# Inicializar conexión con la base de datos
	db = SQLite.new()
	db.path = DB_PATH
	db.open_db()

func cargar_ultimo_fichero():
	# Obtener el último fichero PDF generado y construir su ruta completa
	if db == null:
		return
	
	db.query("SELECT nombre FROM ficheros ORDER BY fecha_creacion DESC LIMIT 1")
	var result = db.query_result
	
	if result.size() > 0:
		var nombre_archivo = result[0].get("nombre", "")
		if not nombre_archivo.is_empty():
			var downloads_path = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
			archivo_adjunto = downloads_path + "/" + nombre_archivo
			_mostrar_fichero_en_cuerpo(nombre_archivo)

func _mostrar_fichero_en_cuerpo(nombre_archivo: String):
	# Mostrar información del archivo adjunto al inicio del cuerpo del mensaje
	if not txt_cuerpo.text.begins_with("Archivo adjunto:"):
		var texto_adjunto = "Archivo adjunto: " + nombre_archivo + "\n"
		texto_adjunto += "─────────────────────────────────────\n\n"
		txt_cuerpo.text = texto_adjunto + txt_cuerpo.text

func _on_boton_enviar_pressed():
	# Validar formulario y enviar correo electrónico
	if not _validar_formulario():
		return
	
	if not archivo_adjunto.is_empty() and not FileAccess.file_exists(archivo_adjunto):
		_mostrar_error("El archivo adjunto no existe: " + archivo_adjunto)
		return
	
	var cuerpo_real = _extraer_cuerpo_mensaje()
	
	var datos = {
		"destinatario": txt_destinatario.text.strip_edges(),
		"asunto": txt_asunto.text.strip_edges(),
		"cuerpo": cuerpo_real,
		"adjunto": archivo_adjunto
	}
	
	var json_string = JSON.stringify(datos)
	var headers = ["Content-Type: application/json"]
	
	var error = http_request.request(
		API_URL_ENVIAR,
		headers,
		HTTPClient.METHOD_POST,
		json_string
	)
	
	if error != OK:
		_mostrar_error("Error al conectar con el servidor")

func _validar_formulario() -> bool:
	# Validar que todos los campos obligatorios sean correctos
	var destinatario = txt_destinatario.text.strip_edges()
	var asunto = txt_asunto.text.strip_edges()
	
	if destinatario.is_empty():
		_mostrar_error("El destinatario es obligatorio")
		return false
	
	if not _es_email_valido(destinatario):
		_mostrar_error("El formato del email es inválido (ejemplo: usuario@dominio.com)")
		return false
	
	if asunto.is_empty():
		_mostrar_error("El asunto es obligatorio")
		return false
	
	if asunto.length() < 3:
		_mostrar_error("El asunto debe tener al menos 3 caracteres")
		return false
	
	if asunto.length() > 200:
		_mostrar_error("El asunto no puede tener más de 200 caracteres")
		return false
	
	var cuerpo_real = _extraer_cuerpo_mensaje()
	
	if cuerpo_real.is_empty():
		_mostrar_error("El mensaje es obligatorio")
		return false
	
	if cuerpo_real.length() < 10:
		_mostrar_error("El mensaje debe tener al menos 10 caracteres")
		return false
	
	return true

func _es_email_valido(email: String) -> bool:
	# Verificar formato de email válido
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null

func _extraer_cuerpo_mensaje() -> String:
	# Extraer solo el contenido escrito por el usuario (sin la parte del adjunto)
	var texto_completo = txt_cuerpo.text
	
	if not archivo_adjunto.is_empty():
		var nombre_archivo = archivo_adjunto.get_file()
		var patron_adjunto = "Archivo adjunto: " + nombre_archivo + "\n─────────────────────────────────────\n\n"
		texto_completo = texto_completo.replace(patron_adjunto, "")
	
	return texto_completo.strip_edges()

func _on_http_request_request_completed(result, response_code, headers, body):
	# Procesar respuesta del servidor al enviar el correo
	if result != HTTPRequest.RESULT_SUCCESS:
		_mostrar_error("Error de red al enviar el correo")
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.parse_string(response_text)
	
	match response_code:
		200:
			_mostrar_exito("Correo enviado con éxito")
			limpiar_formulario()
			hide()
		
		400:
			var mensaje = "Datos inválidos"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		
		500:
			var mensaje = "Error del servidor"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		
		_:
			_mostrar_error("Error al enviar: código " + str(response_code))

func limpiar_formulario():
	# Limpiar todos los campos del formulario
	txt_destinatario.text = ""
	txt_asunto.text = ""
	txt_cuerpo.text = ""
	archivo_adjunto = ""

func _mostrar_error(mensaje: String):
	# Mostrar mensaje de error al usuario
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _mostrar_exito(mensaje: String):
	# Mostrar mensaje de éxito al usuario
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _exit_tree():
	# Cerrar base de datos al salir de la escena
	if db:
		db.close_db()
