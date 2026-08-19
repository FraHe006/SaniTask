extends Window

# Configuración de la API
const API_URL = "http://localhost:3000/api/empleado"
const API_TOKEN = ""

@onready var http_request = $HTTPRequest

#Datos Personales
@onready var txt_nombre = $DatosPersonales/Nombre 
@onready var txt_dni = $DatosPersonales/dni
@onready var txt_fechaNacimiento = $DatosPersonales/FechaNacimiento
@onready var txt_telefono = $DatosPersonales/telefono
@onready var txt_correo = $DatosPersonales/correo
@onready var txt_numEmpleado = $DatosPersonales/numEmpleado
@onready var txt_fechaAlta = $DatosPersonales/fechaAlta
@onready var txt_unidad = $DatosPersonales/unidad
@onready var txt_catProfesional = $DatosPersonales/catProfesional

#Documentación
@onready var txt_titulacion = $Documentacion/Titulacion
@onready var txt_NumColegiacion = $Documentacion/NumColegiacion
@onready var txt_Certificaciones = $Documentacion/Certificaciones
@onready var txt_Reconocimiento = $Documentacion/Reconocimiento
@onready var txt_Vacunaciones = $Documentacion/Vacunaciones

@onready var btn_guardar = $BotonGuardar

var empleado_id = 0  # 0 = nuevo empleado, >0 = empleado existente
var ventana_lista: Window  # Referencia a la ventana principal que contiene la lista

# Referencia a la ventana de que contiene la lista de empleados
func inicializar(lista: Window):
	ventana_lista = lista

# Carga un empleado existente o prepara el formulario para uno nuevo
func cargar_empleado(id: int):
	empleado_id = id
	
	if id == 0:
		# Nuevo empleado, se limpia el formulario
		limpiar_formulario()
		title = "Nuevo Empleado"
	else:
		# Empleado existente, se solicitan los datos del empleado al servidor
		title = "Editar Empleado"
		var url = API_URL + "/" + str(id)
		var headers = _get_headers()
		http_request.request(url, headers, HTTPClient.METHOD_GET)

# ==================== OPERACIONES CRUD ====================

# Guarda el empleado (crea nuevo o actualiza existente)
func guardar_empleado():
	if not _validar_formulario():
		return
	
	var headers = _get_headers()
	var data = _get_datos_formulario()
	var body = JSON.stringify(data)
	
	if empleado_id == 0:
		# POST - Crea un nuevo empleado
		http_request.request(API_URL, headers, HTTPClient.METHOD_POST, body)
	else:
		# PUT - Actualiza el empleado existente
		var url = API_URL + "/" + str(empleado_id)
		http_request.request(url, headers, HTTPClient.METHOD_PUT, body)

# Elimina el empleado actual (solo si existe)
func eliminar_empleado():
	if empleado_id == 0:
		return
	
	# Muestra mensaje de confirmación antes de eliminar
	var confirmacion = ConfirmationDialog.new()
	add_child(confirmacion)
	confirmacion.dialog_text = "¿Estás seguro de eliminar este empleado?"
	confirmacion.confirmed.connect(_confirmar_eliminacion)
	confirmacion.popup_centered()

# Ejecuta la eliminación tras la confirmación del usuario
func _confirmar_eliminacion():
	var url = API_URL + "/" + str(empleado_id)
	var headers = _get_headers()
	http_request.request(url, headers, HTTPClient.METHOD_DELETE)

# ==================== GESTIÓN DEL FORMULARIO ====================

# Rellena los campos del formulario con los datos del empleado
func _cargar_datos_formulario(empleado: Dictionary) -> void:
	# Datos Personales
	txt_nombre.text = empleado.get("nombre", "")
	txt_dni.text = empleado.get("dni", "")
	txt_fechaNacimiento.text = _formatear_fecha(empleado.get("fechaNacimiento", ""))
	txt_telefono.text = empleado.get("telefono", "")
	txt_correo.text = empleado.get("correo", "")
	txt_numEmpleado.text = str(empleado.get("numEmpleado", ""))
	txt_fechaAlta.text = _formatear_fecha(empleado.get("fechaAlta", ""))
	txt_unidad.text = empleado.get("unidad", "")
	txt_catProfesional.text = empleado.get("catProfesional", "")
	
	# Documentación
	txt_titulacion.text = empleado.get("titulacion", "")
	txt_NumColegiacion.text = empleado.get("numColegiacion", "")
	txt_Certificaciones.text = empleado.get("certificaciones", "")
	txt_Reconocimiento.text = empleado.get("reconocimiento", "")
	txt_Vacunaciones.text = empleado.get("vacunaciones", "")

# Convierte fecha ISO (YYYY-MM-DD) a formato normal (DD/MM/YYYY)
func _formatear_fecha(fecha) -> String:
	if fecha == null or fecha == "":
		return ""
	
	var fecha_str = str(fecha)
	
	if "T" in fecha_str:
		fecha_str = fecha_str.split("T")[0]
	
	# Convierte YYYY-MM-DD a DD/MM/YYYY
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
		"dni": txt_dni.text.strip_edges().to_upper(),
		"fechaNacimiento": _desformatear_fecha(txt_fechaNacimiento.text),
		"telefono": txt_telefono.text.strip_edges(),
		"correo": txt_correo.text.strip_edges().to_lower(),
		"numEmpleado": txt_numEmpleado.text.strip_edges(),
		"fechaAlta": _desformatear_fecha(txt_fechaAlta.text),
		"unidad": txt_unidad.text.strip_edges(),
		"catProfesional": txt_catProfesional.text.strip_edges(),
		# Documentación
		"titulacion": txt_titulacion.text.strip_edges(),
		"numColegiacion": txt_NumColegiacion.text.strip_edges(),
		"certificaciones": txt_Certificaciones.text.strip_edges(),
		"reconocimiento": txt_Reconocimiento.text.strip_edges(),
		"vacunaciones": txt_Vacunaciones.text.strip_edges()
	}

# Convierte fecha normal (DD/MM/YYYY) a formato ISO (YYYY-MM-DD)
func _desformatear_fecha(fecha_str: String) -> String:
	if fecha_str.is_empty():
		return ""
	
	# Convierte DD/MM/YYYY a YYYY-MM-DD para la base de datos
	if "/" in fecha_str:
		var partes = fecha_str.split("/")
		if partes.size() == 3:
			return partes[2] + "-" + partes[1] + "-" + partes[0]
	
	# Si ya está en formato ISO, lo devuelve sin cambios
	return fecha_str

# Valida que todos los campos obligatorios estén completos y sean correctos
func _validar_formulario() -> bool:
	# Validación de Datos Personales
	if txt_nombre.text.strip_edges().is_empty():
		_mostrar_error("El nombre es obligatorio")
		return false
	
	# Validar DNI 
	var dni = txt_dni.text.strip_edges().to_upper()
	if dni.is_empty():
		_mostrar_error("El DNI es obligatorio")
		return false
	if not _validar_dni(dni):
		_mostrar_error("El DNI no tiene un formato válido (debe ser 8 números seguidos de una letra)")
		return false
	
	# Validar fecha de nacimiento
	if txt_fechaNacimiento.text.strip_edges().is_empty():
		_mostrar_error("La fecha de nacimiento es obligatoria")
		return false
	if not _validar_fecha(txt_fechaNacimiento.text):
		_mostrar_error("La fecha de nacimiento no es válida (formato: DD/MM/YYYY)")
		return false
	
	# Validar teléfono 
	var telefono = txt_telefono.text.strip_edges()
	if telefono.is_empty():
		_mostrar_error("El teléfono es obligatorio")
		return false
	if not _validar_telefono(telefono):
		_mostrar_error("El teléfono debe tener 9 dígitos")
		return false
	
	# Validar correo electrónico
	var correo = txt_correo.text.strip_edges()
	if correo.is_empty():
		_mostrar_error("El correo electrónico es obligatorio")
		return false
	if not _validar_email(correo):
		_mostrar_error("El correo electrónico no tiene un formato válido")
		return false
	
	if txt_numEmpleado.text.strip_edges().is_empty():
		_mostrar_error("El número de empleado es obligatorio")
		return false
	
	# Validar fecha de alta
	if txt_fechaAlta.text.strip_edges().is_empty():
		_mostrar_error("La fecha de alta es obligatoria")
		return false
	if not _validar_fecha(txt_fechaAlta.text):
		_mostrar_error("La fecha de alta no es válida (formato: DD/MM/YYYY)")
		return false
	
	if txt_unidad.text.strip_edges().is_empty():
		_mostrar_error("La unidad es obligatoria")
		return false
	
	if txt_catProfesional.text.strip_edges().is_empty():
		_mostrar_error("La categoría profesional es obligatoria")
		return false
	
	# Validación de Documentación
	if txt_titulacion.text.strip_edges().is_empty():
		_mostrar_error("La titulación es obligatoria")
		return false
	
	if txt_NumColegiacion.text.strip_edges().is_empty():
		_mostrar_error("El número de colegiación es obligatorio")
		return false
	
	if txt_Certificaciones.text.strip_edges().is_empty():
		_mostrar_error("Las certificaciones son obligatorias")
		return false
	
	if txt_Reconocimiento.text.strip_edges().is_empty():
		_mostrar_error("El reconocimiento médico es obligatorio")
		return false
	
	if txt_Vacunaciones.text.strip_edges().is_empty():
		_mostrar_error("Las vacunaciones son obligatorias")
		return false
	
	return true

# Valida formato de DNI español
func _validar_dni(dni: String) -> bool:
	# Eliminar espacios
	dni = dni.strip_edges()
	
	# Verificar longitud
	if dni.length() != 9:
		return false
	
	# Verificar que los primeros 8 caracteres sean números
	var numeros = dni.substr(0, 8)
	if not numeros.is_valid_int():
		return false
	
	# Verificar que el último carácter sea una letra
	var letra = dni.substr(8, 1)
	if not letra.to_upper() in "TRWAGMYFPDXBNJZSQVHLCKE":
		return false
	
	# Validar letra correcta según el algoritmo del DNI
	var letras_dni = "TRWAGMYFPDXBNJZSQVHLCKE"
	var numero = int(numeros)
	var letra_correcta = letras_dni[numero % 23]
	
	return letra.to_upper() == letra_correcta

# Valida formato de fecha DD/MM/YYYY
func _validar_fecha(fecha: String) -> bool:
	fecha = fecha.strip_edges()
	
	if not "/" in fecha:
		return false
	
	var partes = fecha.split("/")
	if partes.size() != 3:
		return false
	
	# Verificar que sean números válidos
	if not partes[0].is_valid_int() or not partes[1].is_valid_int() or not partes[2].is_valid_int():
		return false
	
	var dia = int(partes[0])
	var mes = int(partes[1])
	var anio = int(partes[2])
	
	# Validar rangos
	if mes < 1 or mes > 12:
		return false
	if dia < 1 or dia > 31:
		return false
	if anio < 1900 or anio > 2100:
		return false
	
	# Validar días según el mes
	var dias_por_mes = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	
	# Año bisiesto
	if (anio % 4 == 0 and anio % 100 != 0) or (anio % 400 == 0):
		dias_por_mes[1] = 29
	
	if dia > dias_por_mes[mes - 1]:
		return false
	
	return true

# Valida formato de teléfono 
func _validar_telefono(telefono: String) -> bool:
	telefono = telefono.strip_edges()
	
	# Eliminar espacios y guiones
	telefono = telefono.replace(" ", "").replace("-", "")
	
	# Verificar que tenga 9 dígitos
	if telefono.length() != 9:
		return false
	
	# Verificar que todos sean números
	return telefono.is_valid_int()

# Valida formato de correo electrónico
func _validar_email(email: String) -> bool:
	email = email.strip_edges()
	
	# Verificar que contenga @
	if not "@" in email:
		return false
	
	var partes = email.split("@")
	if partes.size() != 2:
		return false
	
	var local = partes[0]
	var dominio = partes[1]
	
	# Verificar que ambas partes no estén vacías
	if local.is_empty() or dominio.is_empty():
		return false
	
	# Verificar que el dominio contenga al menos un punto
	if not "." in dominio:
		return false
	
	# Verificar que no empiece o termine con punto
	if dominio.begins_with(".") or dominio.ends_with("."):
		return false
	
	return true

# Limpia todos los campos del formulario
func limpiar_formulario() -> void:
	# Datos Personales
	txt_nombre.text = ""
	txt_dni.text = ""
	txt_fechaNacimiento.text = ""
	txt_telefono.text = ""
	txt_correo.text = ""
	txt_numEmpleado.text = ""
	txt_fechaAlta.text = ""
	txt_unidad.text = ""
	txt_catProfesional.text = ""
	
	# Documentación
	txt_titulacion.text = ""
	txt_NumColegiacion.text = ""
	txt_Certificaciones.text = ""
	txt_Reconocimiento.text = ""
	txt_Vacunaciones.text = ""
	
	# Reinicia el ID a 0
	empleado_id = 0


# Genera los headers HTTP para las peticiones a la API
func _get_headers() -> Array:
	var headers = ["Content-Type: application/json"]
	if not API_TOKEN.is_empty():
		headers.append("Authorization: Bearer " + API_TOKEN)
	return headers

# Muestra los mensajes de error
func _mostrar_error(mensaje: String):
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()

# Muestra los mensjes de éxito
func _mostrar_exito(mensaje: String):
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.dialog_text = mensaje
	dialog.popup_centered()

# Se ejecuta cuando se presiona el botón de guardar
func _on_boton_guardar_pressed() -> void:
	guardar_empleado()

# Se ejecuta cuando se presiona el botón de borrar
func _on_boton_borrar_pressed() -> void:
	eliminar_empleado()

# Maneja la respuesta de las peticiones HTTP
func _on_http_request_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	# Verifica que la conexión fue exitosa
	if result != HTTPRequest.RESULT_SUCCESS:
		_mostrar_error("Error de conexión: " + str(result))
		return
	
	# Obtiene el texto de la respuesta
	var response_text = body.get_string_from_utf8()
	
	if response_text.is_empty():
		if response_code == 204:
			_mostrar_exito("Operación completada")
			hide()
		else:
			_mostrar_error("El servidor devolvió una respuesta vacía (código: " + str(response_code) + ")")
		return
	
	# Intenta parsear la respuesta JSON
	var json = JSON.parse_string(response_text)
	
	if json == null:
		_mostrar_error("Error al parsear JSON. Ver consola para detalles.")
		return
	
	# Procesa la respuesta según el código HTTP
	match response_code:
		200:  # GET exitoso - Empleado cargado
			if json is Dictionary:
				_cargar_datos_formulario(json)
				_mostrar_exito("Empleado cargado correctamente")
				ventana_lista.cargar_empleados()
			else:
				_mostrar_error("Formato inesperado. Se esperaba Dictionary, recibido: " + str(typeof(json)))
		
		201:  # POST exitoso - Empleado creado
			_mostrar_exito("Empleado creado exitosamente")
			if json is Dictionary and json.has("id"):
				empleado_id = json.get("id", 0)
			ventana_lista.cargar_empleados()
			_on_close_requested()
		
		204:  # DELETE exitoso - Empleado eliminado
			_mostrar_exito("Empleado eliminado exitosamente")
			ventana_lista.cargar_empleados()
			_on_close_requested()
		
		400:  # Datos inválidos
			var mensaje = "Datos inválidos"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		
		404:  # No encontrado
			_mostrar_error("Error: Empleado no encontrado")
		
		500:  # Error del servidor
			var mensaje = "Error del servidor"
			if json is Dictionary and json.has("error"):
				mensaje += ": " + str(json.get("error"))
			_mostrar_error(mensaje)
		
		_:  # Otros códigos de error
			_mostrar_error("Error " + str(response_code) + ": " + response_text)

func _on_close_requested() -> void:
	self.hide()
