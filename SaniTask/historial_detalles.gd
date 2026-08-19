extends Window

# Configuración de la API
const API_URL = "http://localhost:3000/api/paciente"
const API_TOKEN = ""

@onready var http_request = $HTTPRequest

# Datos Personales
@onready var txt_nombre = $DatosPersonales/Nombre
@onready var txt_fechaNacimiento = $DatosPersonales/FechaNacimiento
@onready var txt_genero = $DatosPersonales/Genero
@onready var txt_sangre = $DatosPersonales/Sangre
@onready var txt_rh = $DatosPersonales/RH
@onready var txt_dni = $DatosPersonales/dni
@onready var txt_tarjetaSanitaria = $DatosPersonales/tarjetaSanitaria
@onready var txt_telefono = $DatosPersonales/telefono
@onready var txt_correo = $DatosPersonales/correo

# Historia Clínica
@onready var txt_antecedentesFamiliares = $Historia/AntecedentesFamiliares
@onready var txt_vacunas = $Historia/Vacunas
@onready var txt_habitos = $Historia/Habitos

# Medicación
@onready var txt_alergias = $Medicacion/Alergias
@onready var txt_enfermedadesCronicas = $Medicacion/EnfermedadesCronicas
@onready var txt_tratamientoActual = $Medicacion/TratamientoActual
@onready var txt_cirugias = $Medicacion/Cirugias

@onready var btn_guardar = $BotonGuardar

# Variables de control
var paciente_id = 0  # 0 = nuevo paciente, >0 = editar existente
var ventana_lista: Window  # Referencia a la ventana de lista de pacientes


# Inicializa la ventana con referencia a la lista principal
func inicializar(lista: Window):
	ventana_lista = lista

# Carga un paciente existente o prepara formulario para nuevo paciente
func cargar_paciente(id: int):
	paciente_id = id
	
	if id == 0:
		# Nuevo paciente - limpiar formulario
		limpiar_formulario()
		title = "Nuevo paciente"
	else:
		# Cargar paciente existente desde la API
		title = "Editar paciente"
		var url = API_URL + "/" + str(id)
		var headers = _get_headers()
		http_request.request(url, headers, HTTPClient.METHOD_GET)

# ==================== OPERACIONES CRUD ====================

# Guarda el paciente (crear nuevo o actualizar existente)
func guardar_paciente():
	if not _validar_formulario():
		return
	
	var headers = _get_headers()
	var data = _get_datos_formulario()
	var body = JSON.stringify(data)
	
	if paciente_id == 0:
		# POST - Crear nuevo paciente
		http_request.request(API_URL, headers, HTTPClient.METHOD_POST, body)
	else:
		# PUT - Actualizar paciente existente
		var url = API_URL + "/" + str(paciente_id)
		http_request.request(url, headers, HTTPClient.METHOD_PUT, body)

# Elimina el paciente actual
func eliminar_paciente():
	if paciente_id == 0:
		return
	
	# Mostrar diálogo de confirmación
	var confirmacion = ConfirmationDialog.new()
	add_child(confirmacion)
	confirmacion.dialog_text = "¿Estás seguro de eliminar este paciente?"
	confirmacion.confirmed.connect(_confirmar_eliminacion)
	confirmacion.popup_centered()

# Confirma y ejecuta la eliminación
func _confirmar_eliminacion():
	var url = API_URL + "/" + str(paciente_id)
	var headers = _get_headers()
	http_request.request(url, headers, HTTPClient.METHOD_DELETE)

# ==================== GESTIÓN DEL FORMULARIO ====================

# Carga los datos del paciente en los campos del formulario
func _cargar_datos_formulario(paciente: Dictionary) -> void:
	# Datos Personales
	txt_nombre.text = paciente.get("nombre", "")
	txt_dni.text = paciente.get("dni", "")
	txt_fechaNacimiento.text = _formatear_fecha(paciente.get("fechaNacimiento", ""))
	txt_genero.text = paciente.get("genero", "")
	txt_sangre.text = paciente.get("sangre", "")
	txt_rh.text = paciente.get("rh", "")
	txt_tarjetaSanitaria.text = paciente.get("tarjetaSanitaria", "")
	txt_telefono.text = paciente.get("telefono", "")
	txt_correo.text = paciente.get("correo", "")

	# Historia
	txt_antecedentesFamiliares.text = paciente.get("antecedentesFamiliares", "")
	txt_vacunas.text = paciente.get("vacunas", "")
	txt_habitos.text = paciente.get("habitos", "")

	# Medicación
	txt_alergias.text = paciente.get("alergias", "")
	txt_enfermedadesCronicas.text = paciente.get("enfermedadesCronicas", "")
	txt_tratamientoActual.text = paciente.get("tratamientoActual", "")
	txt_cirugias.text = paciente.get("cirugias", "")

# Convierte fecha de formato ISO a formato DD/MM/YYYY
func _formatear_fecha(fecha) -> String:
	if fecha == null or fecha == "":
		return ""
	
	var fecha_str = str(fecha)
	
	# Si viene en formato ISO: "1985-03-15T00:00:00.000Z"
	if "T" in fecha_str:
		fecha_str = fecha_str.split("T")[0]
	
	# Convertir YYYY-MM-DD a DD/MM/YYYY
	if "-" in fecha_str:
		var partes = fecha_str.split("-")
		if partes.size() == 3:
			return partes[2] + "/" + partes[1] + "/" + partes[0]
	
	return fecha_str

# Recopila todos los datos del formulario en un diccionario
func _get_datos_formulario() -> Dictionary:
	return {
		# Datos Personales
		"nombre": txt_nombre.text.strip_edges(),
		"dni": txt_dni.text.strip_edges(),
		"fechaNacimiento": _desformatear_fecha(txt_fechaNacimiento.text),
		"genero": txt_genero.text.strip_edges(),
		"sangre": txt_sangre.text.strip_edges(),
		"rh": txt_rh.text.strip_edges(),
		"tarjetaSanitaria": txt_tarjetaSanitaria.text.strip_edges(),
		"telefono": txt_telefono.text.strip_edges(),
		"correo": txt_correo.text.strip_edges(),

		# Historia
		"antecedentesFamiliares": txt_antecedentesFamiliares.text.strip_edges(),
		"vacunas": txt_vacunas.text.strip_edges(),
		"habitos": txt_habitos.text.strip_edges(),

		# Medicación
		"alergias": txt_alergias.text.strip_edges(),
		"enfermedadesCronicas": txt_enfermedadesCronicas.text.strip_edges(),
		"tratamientoActual": txt_tratamientoActual.text.strip_edges(),
		"cirugias": txt_cirugias.text.strip_edges()
	}

# Convierte fecha de formato DD/MM/YYYY a YYYY-MM-DD para la BD
func _desformatear_fecha(fecha_str: String) -> String:
	if fecha_str.is_empty():
		return ""
	
	# Convertir DD/MM/YYYY a YYYY-MM-DD
	if "/" in fecha_str:
		var partes = fecha_str.split("/")
		if partes.size() == 3:
			return partes[2] + "-" + partes[1] + "-" + partes[0]
	
	return fecha_str

# ==================== VALIDACIÓN ====================

# Valida todos los campos del formulario 
func _validar_formulario() -> bool:
	# Nombre: mínimo 3 caracteres, solo letras y espacios
	if txt_nombre.text.strip_edges().is_empty():
		_mostrar_error("El nombre es obligatorio")
		return false
	if txt_nombre.text.strip_edges().length() < 3:
		_mostrar_error("El nombre debe tener al menos 3 caracteres")
		return false
	if not _validar_solo_letras_espacios(txt_nombre.text):
		_mostrar_error("El nombre solo puede contener letras y espacios")
		return false
	
	# DNI
	if txt_dni.text.strip_edges().is_empty():
		_mostrar_error("El DNI es obligatorio")
		return false
	if not _validar_dni(txt_dni.text.strip_edges()):
		_mostrar_error("DNI inválido. Formato: 12345678A")
		return false
	
	# Fecha de nacimiento
	if txt_fechaNacimiento.text.strip_edges().is_empty():
		_mostrar_error("La fecha de nacimiento es obligatoria")
		return false
	if not _validar_fecha(txt_fechaNacimiento.text.strip_edges()):
		_mostrar_error("Fecha inválida. Formato: DD/MM/YYYY")
		return false
	
	# Género: debe ser una opción válida
	var genero = txt_genero.text.strip_edges().to_upper()
	if genero.is_empty():
		_mostrar_error("El género es obligatorio")
		return false
	if not genero in ["M", "F", "MASCULINO", "FEMENINO", "OTRO"]:
		_mostrar_error("Género inválido. Opciones: M, F, Otro")
		return false
	
	# Tipo de sangre: validar formato (A, B, AB, O)
	if not txt_sangre.text.strip_edges().is_empty():
		var sangre = txt_sangre.text.strip_edges().to_upper()
		if not sangre in ["A", "B", "AB", "O"]:
			_mostrar_error("Tipo de sangre inválido. Opciones: A, B, AB, O")
			return false
	
	# Factor RH: validar formato (+ o -)
	if not txt_rh.text.strip_edges().is_empty():
		var rh = txt_rh.text.strip_edges()
		if not rh in ["+", "-", "POSITIVO", "NEGATIVO"]:
			_mostrar_error("Factor RH inválido. Opciones: +, -")
			return false
	
	# Teléfono: 9 dígitos
	if txt_telefono.text.strip_edges().is_empty():
		_mostrar_error("El teléfono es obligatorio")
		return false
	if not _validar_telefono(txt_telefono.text.strip_edges()):
		_mostrar_error("Teléfono inválido. Debe tener 9 dígitos")
		return false
	
	# Correo electrónico: formato válido
	if txt_correo.text.strip_edges().is_empty():
		_mostrar_error("El correo electrónico es obligatorio")
		return false
	if not _validar_email(txt_correo.text.strip_edges()):
		_mostrar_error("Correo electrónico inválido")
		return false
	
	# HISTORIA CLÍNICA (obligatoria pero puede estar vacía)
	if txt_antecedentesFamiliares.text.strip_edges().is_empty():
		_mostrar_error("Los antecedentes familiares son obligatorios (escribe 'Ninguno' si no aplica)")
		return false
	
	if txt_vacunas.text.strip_edges().is_empty():
		_mostrar_error("El registro de vacunas es obligatorio (escribe 'Ninguna' si no aplica)")
		return false
	
	# MEDICACIÓN (obligatoria pero puede estar vacía)
	if txt_alergias.text.strip_edges().is_empty():
		_mostrar_error("El campo de alergias es obligatorio (escribe 'Ninguna' si no aplica)")
		return false
	
	if txt_enfermedadesCronicas.text.strip_edges().is_empty():
		_mostrar_error("El campo de enfermedades crónicas es obligatorio (escribe 'Ninguna' si no aplica)")
		return false
	
	return true

# ==================== FUNCIONES DE VALIDACIÓN ====================

# Valida que el texto solo contenga letras y espacios
func _validar_solo_letras_espacios(texto: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$")
	return regex.search(texto) != null

# Valida formato DNI (8 dígitos + 1 letra)
func _validar_dni(dni: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[0-9]{8}[A-Z]$")
	return regex.search(dni.to_upper()) != null

# Valida formato de fecha DD/MM/YYYY
func _validar_fecha(fecha: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[0-9]{2}/[0-9]{2}/[0-9]{4}$")
	if regex.search(fecha) == null:
		return false
	
	# Validar que sea una fecha real
	var partes = fecha.split("/")
	var dia = int(partes[0])
	var mes = int(partes[1])
	var anio = int(partes[2])
	
	if mes < 1 or mes > 12:
		return false
	if dia < 1 or dia > 31:
		return false
	if anio < 1900 or anio > 2024:
		return false
	
	# Validar días por mes
	var dias_por_mes = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	
	# Año bisiesto
	if (anio % 4 == 0 and anio % 100 != 0) or (anio % 400 == 0):
		dias_por_mes[1] = 29
	
	if dia > dias_por_mes[mes - 1]:
		return false
	
	return true

# Valida formato de teléfono (9 dígitos)
func _validar_telefono(telefono: String) -> bool:
	# Eliminar espacios y guiones
	var tel_limpio = telefono.replace(" ", "").replace("-", "")
	
	var regex = RegEx.new()
	regex.compile("^[0-9]{9}$")
	return regex.search(tel_limpio) != null

# Valida formato de correo electrónico
func _validar_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null

# Limpia todos los campos del formulario
func limpiar_formulario() -> void:
	# Datos Personales
	txt_nombre.text = ""
	txt_dni.text = ""
	txt_fechaNacimiento.text = ""
	txt_genero.text = ""
	txt_sangre.text = ""
	txt_rh.text = ""
	txt_tarjetaSanitaria.text = ""
	txt_telefono.text = ""
	txt_correo.text = ""

	# Historia
	txt_antecedentesFamiliares.text = ""
	txt_vacunas.text = ""
	txt_habitos.text = ""

	# Medicación
	txt_alergias.text = ""
	txt_enfermedadesCronicas.text = ""
	txt_tratamientoActual.text = ""
	txt_cirugias.text = ""

	paciente_id = 0

# Genera headers HTTP con un token de autenticación
func _get_headers() -> Array:
	var headers = ["Content-Type: application/json"]
	if not API_TOKEN.is_empty():
		headers.append("Authorization: Bearer " + API_TOKEN)
	return headers

# Muestra un mensaje de error
func _mostrar_error(mensaje: String):
	print("ERROR: ", mensaje)
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()

# Muestra un mensaje de éxito
func _mostrar_exito(mensaje: String):
	print("ÉXITO: ", mensaje)
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()

# Guarda el paciente y cierra la ventana
func _on_boton_guardar_pressed() -> void:
	guardar_paciente()

# Elimina el paciente y cierra la ventana
func _on_boton_borrar_pressed() -> void:
	eliminar_paciente()

# Procesa la respuesta HTTP de la API
func _on_http_request_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	
	var response_text = body.get_string_from_utf8()
	
	# Validar conexión exitosa
	if result != HTTPRequest.RESULT_SUCCESS:
		_mostrar_error("Error de conexión: " + str(result))
		return
	
	# Manejar respuesta vacía (válido para DELETE 204)
	if response_text.is_empty():
		if response_code == 204:
			_mostrar_exito("Operación completada")
			hide()
			ventana_lista.cargar_pacientes()
			_on_close_requested()
		else:
			_mostrar_error("El servidor devolvió una respuesta vacía (código: " + str(response_code) + ")")
		return
	
	# Parsear JSON
	var json = JSON.parse_string(response_text)
	
	if json == null:
		_mostrar_error("Error al parsear JSON. Ver consola para detalles.")
		return
	
	# Manejar diferentes códigos de respuesta
	match response_code:
		200:  # GET exitoso - paciente cargado
			if json is Dictionary:
				_cargar_datos_formulario(json)
				_mostrar_exito("Paciente cargado correctamente")
			else:
				_mostrar_error("Formato inesperado. Se esperaba Dictionary, recibido: " + str(typeof(json)))
		201:  # POST exitoso - paciente creado
			_mostrar_exito("Paciente creado exitosamente")
			if json is Dictionary and json.has("id"):
				paciente_id = json.get("id", 0)
			ventana_lista.cargar_pacientes()
			_on_close_requested()
		204:  # DELETE exitoso - paciente eliminado
			_mostrar_exito("Paciente eliminado exitosamente")
			ventana_lista.cargar_pacientes()
			_on_close_requested()
		400:
			var mensaje = "Datos inválidos"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		404:
			_mostrar_error("Error: Paciente no encontrado")
		500:
			var mensaje = "Error del servidor"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		_:
			_mostrar_error("Error " + str(response_code) + ": " + response_text)

# Oculta la ventana al cerrar
func _on_close_requested() -> void:
	self.hide()
