extends Window

const API_URL = "http://localhost:3000/api/citas"
const API_URL_DETALLE = "http://localhost:3000/api/cita"
const API_TOKEN = ""
const DB_PATH = "user://app_data.db"

@onready var http_request = $HTTPRequest
@onready var coreo = $Correo
@onready var txt_nombre = $Panel2/Nombre
@onready var txt_fechaNacimiento = $Panel2/FechaNacimiento
@onready var txt_dni = $Panel2/NumIdentificacion
@onready var txt_especialidadMedia = $Panel/EscpecialidadMedica
@onready var txt_fechahora = $Panel/FechaHoraCita
@onready var txt_responsable = $Panel/ResponsableMedico

var cita_id = 0
var lista_pacientes = null
var responsable_medico_id = 0
var db: SQLite = null
var enviar_correo_confirmacion = false

func _ready():
	_inicializar_db()

func _inicializar_db():
	# Inicializar conexión con la base de datos
	db = SQLite.new()
	db.path = DB_PATH
	db.open_db()

func _guardar_nombre_fichero(nombre_fichero: String):
	# Guardar el nombre del PDF generado en la base de datos
	var query = "INSERT INTO ficheros (nombre, cita_id) VALUES ('%s', %d);" % [nombre_fichero, cita_id]
	db.query(query)

func inicializar(ventana_lista_citas):
	# Conectar con la ventana principal de lista de citas
	lista_pacientes = ventana_lista_citas

func cargar_cita(id: int):
	# Cargar una cita nueva o existente
	cita_id = id
	
	if cita_id == 0:
		limpiar_formulario()
		_cargar_medico_actual()
		popup_centered()
	else:
		var url = API_URL + "/" + str(cita_id)
		var headers = _get_headers()
		var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
		
		if error != OK:
			_mostrar_error("Error al cargar cita: " + str(error))

func _cargar_medico_actual():
	# Cargar el médico que tiene sesión iniciada
	if db == null:
		return
	
	db.query("SELECT id, nombre_empleado FROM sesion_empleado WHERE id = 1")
	var result = db.query_result
	
	if result.size() > 0:
		responsable_medico_id = int(result[0].get("id", 0))
		txt_responsable.text = result[0].get("nombre_empleado", "")
		txt_responsable.editable = false

func _on_boton_guardar_pressed():
	# Validar formulario y preguntar si enviar correo
	if not _validar_formulario():
		return
	
	var dialog = ConfirmationDialog.new()
	add_child(dialog)
	dialog.dialog_text = "¿Desea enviar un correo de confirmación?"
	dialog.confirmed.connect(_guardar_y_enviar_correo)
	dialog.canceled.connect(_guardar_sin_correo)
	dialog.popup_centered()

func _guardar_y_enviar_correo():
	# Guardar cita y luego abrir ventana de correo
	enviar_correo_confirmacion = true
	_guardar_cita()

func _guardar_sin_correo():
	# Solo guardar la cita sin enviar correo
	enviar_correo_confirmacion = false
	_guardar_cita()

func _guardar_cita():
	# Enviar datos al servidor mediante POST o PUT
	var datos = _get_datos_formulario()
	var json_string = JSON.stringify(datos)
	var headers = _get_headers()
	
	if cita_id == 0:
		http_request.request(API_URL_DETALLE, headers, HTTPClient.METHOD_POST, json_string)
	else:
		var url = API_URL_DETALLE + "/" + str(cita_id)
		http_request.request(url, headers, HTTPClient.METHOD_PUT, json_string)

func _on_boton_borrar_pressed():
	# Confirmar antes de eliminar la cita
	if cita_id == 0:
		_mostrar_error("No hay cita para eliminar")
		return
	
	var dialog = ConfirmationDialog.new()
	add_child(dialog)
	dialog.dialog_text = "¿Está seguro de eliminar esta cita?"
	dialog.confirmed.connect(_confirmar_eliminacion)
	dialog.popup_centered()

func _confirmar_eliminacion():
	# Eliminar la cita del servidor
	var url = API_URL_DETALLE + "/" + str(cita_id)
	var headers = _get_headers()
	http_request.request(url, headers, HTTPClient.METHOD_DELETE)

func _cargar_datos_formulario(cita: Dictionary) -> void:
	# Llenar los campos del formulario con los datos de la cita
	txt_nombre.text = cita.get("nombre", "")
	txt_dni.text = cita.get("numIdentificacion", "")
	txt_fechaNacimiento.text = _formatear_fecha(cita.get("fechaNacimiento", ""))
	txt_especialidadMedia.text = cita.get("especialidadMedica", "")
	txt_fechahora.text = _formatear_fecha_hora(cita.get("fechaHoraCita", ""))
	responsable_medico_id = cita.get("responsableMedicoId", 0)
	txt_responsable.text = cita.get("responsableMedicoNombre", "")
	txt_responsable.editable = false

func _get_datos_formulario() -> Dictionary:
	# Recoger todos los datos del formulario
	return {
		"nombre": txt_nombre.text.strip_edges(),
		"numIdentificacion": txt_dni.text.strip_edges(),
		"fechaNacimiento": _desformatear_fecha(txt_fechaNacimiento.text),
		"especialidadMedica": txt_especialidadMedia.text.strip_edges(),
		"fechaHoraCita": _desformatear_fecha_hora(txt_fechahora.text),
		"responsableMedicoId": responsable_medico_id
	}

func _validar_formulario() -> bool:
	# Validar todos los campos del formulario
	if txt_nombre.text.strip_edges().is_empty():
		_mostrar_error("El nombre es obligatorio")
		return false
	if txt_nombre.text.strip_edges().length() < 3:
		_mostrar_error("El nombre debe tener al menos 3 caracteres")
		return false
	if not _es_nombre_valido(txt_nombre.text.strip_edges()):
		_mostrar_error("El nombre solo puede contener letras y espacios")
		return false
	
	if txt_dni.text.strip_edges().is_empty():
		_mostrar_error("El DNI es obligatorio")
		return false
	if not _es_dni_valido(txt_dni.text.strip_edges()):
		_mostrar_error("Formato de DNI inválido (ejemplo: 12345678A)")
		return false
	
	if txt_fechaNacimiento.text.strip_edges().is_empty():
		_mostrar_error("La fecha de nacimiento es obligatoria")
		return false
	if not _es_fecha_valida(txt_fechaNacimiento.text.strip_edges()):
		_mostrar_error("Formato de fecha inválido (use DD/MM/YYYY)")
		return false
	if not _es_fecha_pasada(txt_fechaNacimiento.text.strip_edges()):
		_mostrar_error("La fecha de nacimiento debe ser anterior a hoy")
		return false
	
	if txt_especialidadMedia.text.strip_edges().is_empty():
		_mostrar_error("La especialidad médica es obligatoria")
		return false
	if txt_especialidadMedia.text.strip_edges().length() < 3:
		_mostrar_error("La especialidad debe tener al menos 3 caracteres")
		return false
	
	if txt_fechahora.text.strip_edges().is_empty():
		_mostrar_error("La fecha y hora de la cita es obligatoria")
		return false
	if not _es_fecha_hora_valida(txt_fechahora.text.strip_edges()):
		_mostrar_error("Formato de fecha/hora inválido (use DD/MM/YYYY HH:MM)")
		return false
	if not _es_fecha_futura(txt_fechahora.text.strip_edges()):
		_mostrar_error("La fecha de la cita debe ser futura")
		return false
	
	if txt_responsable.text.strip_edges().is_empty() or responsable_medico_id == 0:
		_mostrar_error("El responsable médico es obligatorio")
		return false
	
	return true

func limpiar_formulario() -> void:
	# Limpiar todos los campos del formulario
	txt_nombre.text = ""
	txt_dni.text = ""
	txt_fechaNacimiento.text = ""
	txt_especialidadMedia.text = ""
	txt_fechahora.text = ""
	txt_responsable.text = ""
	txt_responsable.editable = true
	cita_id = 0
	responsable_medico_id = 0

func _es_nombre_valido(nombre: String) -> bool:
	# Verificar que el nombre solo contenga letras y espacios
	var regex = RegEx.new()
	regex.compile("^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$")
	return regex.search(nombre) != null

func _es_dni_valido(dni: String) -> bool:
	# Verificar formato DNI: 8 números + 1 letra
	var regex = RegEx.new()
	regex.compile("^[0-9]{8}[A-Za-z]$")
	return regex.search(dni) != null

func _es_fecha_valida(fecha: String) -> bool:
	# Verificar formato DD/MM/YYYY
	var regex = RegEx.new()
	regex.compile("^[0-9]{2}/[0-9]{2}/[0-9]{4}$")
	if regex.search(fecha) == null:
		return false
	
	var partes = fecha.split("/")
	var dia = int(partes[0])
	var mes = int(partes[1])
	var anio = int(partes[2])
	
	if mes < 1 or mes > 12:
		return false
	if dia < 1 or dia > 31:
		return false
	if anio < 1900 or anio > 2100:
		return false
	
	return true

func _es_fecha_hora_valida(fecha_hora: String) -> bool:
	# Verificar formato DD/MM/YYYY HH:MM
	var regex = RegEx.new()
	regex.compile("^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}$")
	if regex.search(fecha_hora) == null:
		return false
	
	var partes = fecha_hora.split(" ")
	if not _es_fecha_valida(partes[0]):
		return false
	
	var hora_partes = partes[1].split(":")
	var hora = int(hora_partes[0])
	var minuto = int(hora_partes[1])
	
	if hora < 0 or hora > 23:
		return false
	if minuto < 0 or minuto > 59:
		return false
	
	return true

func _es_fecha_pasada(fecha: String) -> bool:
	# Verificar que la fecha sea anterior a hoy
	var partes = fecha.split("/")
	var dia = int(partes[0])
	var mes = int(partes[1])
	var anio = int(partes[2])
	
	var hoy = Time.get_datetime_dict_from_system()
	
	if anio > hoy.year:
		return false
	if anio == hoy.year and mes > hoy.month:
		return false
	if anio == hoy.year and mes == hoy.month and dia >= hoy.day:
		return false
	
	return true

func _es_fecha_futura(fecha_hora: String) -> bool:
	# Verificar que la fecha/hora sea posterior a ahora
	var partes = fecha_hora.split(" ")
	var fecha = partes[0]
	var hora = partes[1]
	
	var partes_fecha = fecha.split("/")
	var dia = int(partes_fecha[0])
	var mes = int(partes_fecha[1])
	var anio = int(partes_fecha[2])
	
	var partes_hora = hora.split(":")
	var hora_num = int(partes_hora[0])
	var minuto = int(partes_hora[1])
	
	var ahora = Time.get_datetime_dict_from_system()
	
	if anio < ahora.year:
		return false
	if anio > ahora.year:
		return true
	
	if mes < ahora.month:
		return false
	if mes > ahora.month:
		return true
	
	if dia < ahora.day:
		return false
	if dia > ahora.day:
		return true
	
	if hora_num < ahora.hour:
		return false
	if hora_num > ahora.hour:
		return true
	
	if minuto <= ahora.minute:
		return false
	
	return true

func _formatear_fecha(fecha_iso: String) -> String:
	# Convertir de ISO (YYYY-MM-DD) a DD/MM/YYYY
	if fecha_iso.is_empty():
		return ""
	var partes = fecha_iso.split("T")[0].split("-")
	if partes.size() == 3:
		return "%s/%s/%s" % [partes[2], partes[1], partes[0]]
	return fecha_iso

func _desformatear_fecha(fecha_dd_mm_yyyy: String) -> String:
	# Convertir de DD/MM/YYYY a ISO (YYYY-MM-DD)
	if fecha_dd_mm_yyyy.is_empty():
		return ""
	var partes = fecha_dd_mm_yyyy.split("/")
	if partes.size() == 3:
		return "%s-%s-%s" % [partes[2], partes[1], partes[0]]
	return fecha_dd_mm_yyyy

func _formatear_fecha_hora(fecha_hora_iso: String) -> String:
	# Convertir de ISO (YYYY-MM-DDTHH:MM:SS) a DD/MM/YYYY HH:MM
	if fecha_hora_iso.is_empty():
		return ""
	
	var partes_principales = fecha_hora_iso.split("T")
	if partes_principales.size() < 2:
		return fecha_hora_iso
	
	var partes_fecha = partes_principales[0].split("-")
	var fecha_formateada = ""
	if partes_fecha.size() == 3:
		fecha_formateada = "%s/%s/%s" % [partes_fecha[2], partes_fecha[1], partes_fecha[0]]
	
	var hora_completa = partes_principales[1].split(".")[0]
	var hora_formateada = hora_completa.substr(0, 5)
	
	return "%s %s" % [fecha_formateada, hora_formateada]

func _desformatear_fecha_hora(fecha_hora_formateada: String) -> String:
	# Convertir de DD/MM/YYYY HH:MM a ISO (YYYY-MM-DDTHH:MM:SS)
	if fecha_hora_formateada.is_empty():
		return ""
	
	var partes = fecha_hora_formateada.split(" ")
	if partes.size() < 2:
		return fecha_hora_formateada
	
	var partes_fecha = partes[0].split("/")
	var fecha_iso = ""
	if partes_fecha.size() == 3:
		fecha_iso = "%s-%s-%s" % [partes_fecha[2], partes_fecha[1], partes_fecha[0]]
	
	var hora_iso = partes[1] + ":00"
	
	return "%sT%s" % [fecha_iso, hora_iso]

func _get_headers() -> Array:
	# Crear headers para peticiones HTTP
	var headers = ["Content-Type: application/json"]
	if not API_TOKEN.is_empty():
		headers.append("Authorization: Bearer " + API_TOKEN)
	return headers

func _mostrar_error(mensaje: String):
	# Mostrar mensaje de error al usuario
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _mostrar_exito(mensaje: String):
	# Mostrar mensaje de éxito
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _mostrar_exito_y_correo(mensaje: String):
	# Mostrar mensaje de éxito y luego abrir ventana de correo
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()
	dialog.confirmed.connect(func(): 
		dialog.queue_free()
		coreo.cargar_ultimo_fichero()
		coreo.popup_centered()
	)

func _generar_pdf():
	# Crear PDF con los datos de la cita
	if cita_id == 0:
		_mostrar_error("Debe guardar la cita antes de generar el PDF")
		return
	
	var datos = _get_datos_formulario()
	
	PDF.newPDF()
	PDF.setTitle("Comprobante Cita Médica")
	PDF.setCreator("Sistema de Gestión Médica")
	
	# Encabezado
	PDF.newBox(1, Vector2(40, 30), Vector2(532, 80), Color(0.95, 0.97, 1.0), Color.ROYAL_BLUE, 3)
	PDF.newLabel(1, Vector2(60, 50), "COMPROBANTE DE CITA MEDICA", 22)
	PDF.newLabel(1, Vector2(60, 75), "Sistema de Gestion Hospitalaria", 12)
	PDF.newLabel(1, Vector2(420, 50), "N CITA", 12)
	PDF.newLabel(1, Vector2(430, 70), str(cita_id).pad_zeros(6), 18)
	
	# Datos del paciente
	var y_pos = 140
	PDF.newBox(1, Vector2(40, y_pos), Vector2(532, 25), Color.ROYAL_BLUE, null, 0)
	PDF.newLabel(1, Vector2(50, y_pos + 7), "DATOS DEL PACIENTE", 14, Color.WHITE)
	
	y_pos += 40
	PDF.newLabel(1, Vector2(50, y_pos), "Nombre completo:", 11)
	PDF.newLabel(1, Vector2(200, y_pos), datos.nombre, 11)
	
	y_pos += 25
	PDF.newLabel(1, Vector2(50, y_pos), "N Identificacion:", 11)
	PDF.newLabel(1, Vector2(200, y_pos), datos.numIdentificacion, 11)
	
	y_pos += 25
	PDF.newLabel(1, Vector2(50, y_pos), "Fecha de Nacimiento:", 11)
	PDF.newLabel(1, Vector2(200, y_pos), txt_fechaNacimiento.text, 11)
	
	var edad = _calcular_edad(txt_fechaNacimiento.text)
	PDF.newLabel(1, Vector2(350, y_pos), "Edad: " + str(edad) + " años", 11)
	
	# Detalles de la cita
	y_pos += 50
	PDF.newBox(1, Vector2(40, y_pos), Vector2(532, 25), Color.ROYAL_BLUE, null, 0)
	PDF.newLabel(1, Vector2(50, y_pos + 7), "DETALLES DE LA CITA", 14, Color.WHITE)
	
	y_pos += 40
	PDF.newLabel(1, Vector2(50, y_pos), "Fecha y Hora:", 11)
	PDF.newLabel(1, Vector2(200, y_pos), txt_fechahora.text, 11)
	
	y_pos += 25
	PDF.newLabel(1, Vector2(50, y_pos), "Especialidad:", 11)
	PDF.newLabel(1, Vector2(200, y_pos), datos.especialidadMedica, 11)
	
	y_pos += 25
	PDF.newLabel(1, Vector2(50, y_pos), "Medico Responsable:", 11)
	PDF.newLabel(1, Vector2(200, y_pos), txt_responsable.text, 11)
	
	# Instrucciones
	y_pos += 50
	PDF.newBox(1, Vector2(40, y_pos), Vector2(532, 120), Color(1, 0.98, 0.9), Color.ORANGE, 2)
	
	y_pos += 15
	PDF.newLabel(1, Vector2(50, y_pos), "INSTRUCCIONES IMPORTANTES", 13)
	
	y_pos += 25
	PDF.newLabel(1, Vector2(60, y_pos), "Llegue 15 minutos antes de su cita para completar el registro.", 10)
	
	y_pos += 20
	PDF.newLabel(1, Vector2(60, y_pos), "Traiga consigo: tarjeta sanitaria y documento de identidad.", 10)
	
	y_pos += 20
	PDF.newLabel(1, Vector2(60, y_pos), "Si no puede asistir, cancele con al menos 24 horas de antelacion.", 10)
	
	y_pos += 20
	PDF.newLabel(1, Vector2(60, y_pos), "En caso de urgencia, acuda directamente al servicio de urgencias.", 10)
	
	# Pie de página
	y_pos += 50
	PDF.newBox(1, Vector2(40, y_pos), Vector2(532, 1), Color.GRAY, null, 0)
	
	y_pos += 20
	var fecha_generacion = Time.get_datetime_string_from_system()
	PDF.newLabel(1, Vector2(50, y_pos), "Documento generado el: " + fecha_generacion, 8, Color.GRAY)
	PDF.newLabel(1, Vector2(350, y_pos), "Este documento es valido sin firma", 8, Color.GRAY)
	
	# Guardar PDF
	var downloads_path = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var filename = "Cita_%s_%s_%s.pdf" % [str(cita_id).pad_zeros(6), datos.numIdentificacion, timestamp]
	var full_path = downloads_path + "/" + filename
	
	var success = PDF.export(full_path)
	
	if success:
		_guardar_nombre_fichero(filename)

func _calcular_edad(fecha_nacimiento: String) -> int:
	# Calcular edad a partir de DD/MM/YYYY
	if fecha_nacimiento.is_empty():
		return 0
	
	var partes = fecha_nacimiento.split("/")
	if partes.size() != 3:
		return 0
	
	var dia_nac = int(partes[0])
	var mes_nac = int(partes[1])
	var anio_nac = int(partes[2])
	
	var hoy = Time.get_datetime_dict_from_system()
	var edad = hoy.year - anio_nac
	
	if hoy.month < mes_nac or (hoy.month == mes_nac and hoy.day < dia_nac):
		edad -= 1
	
	return edad

func _on_http_request_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Procesar respuesta del servidor
	if result != HTTPRequest.RESULT_SUCCESS:
		_mostrar_error("Error de conexión: código " + str(result))
		return
	
	var response_text = body.get_string_from_utf8()
	var json = JSON.parse_string(response_text)
	
	match response_code:
		200:
			if json is Dictionary:
				if json.has("nombre"):
					_cargar_datos_formulario(json)
					popup_centered()
				else:
					_generar_pdf()
					if enviar_correo_confirmacion:
						_mostrar_exito_y_correo("Cita actualizada correctamente")
					else:
						_mostrar_exito("Cita actualizada correctamente")
					hide()
					if lista_pacientes:
						lista_pacientes.cargar_citas()
		
		201:
			if json is Dictionary and json.has("id"):
				cita_id = json.get("id")
			_generar_pdf()
			if enviar_correo_confirmacion:
				_mostrar_exito_y_correo("Cita creada correctamente")
			else:
				_mostrar_exito("Cita creada correctamente")
			hide()
			if lista_pacientes:
				lista_pacientes.cargar_citas()
		
		204:
			_mostrar_exito("Cita eliminada correctamente")
			hide()
			if lista_pacientes:
				lista_pacientes.cargar_citas()
		
		400:
			var mensaje = "Datos inválidos"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		
		404:
			_mostrar_error("Cita no encontrada")
		
		500:
			var mensaje = "Error del servidor"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		
		_:
			_mostrar_error("Error HTTP " + str(response_code))

func _exit_tree():
	# Cerrar base de datos al salir
	if db:
		db.close_db()
