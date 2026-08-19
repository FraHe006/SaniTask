extends Window

# Referencias a elementos de la interfaz
@onready var texto_nota: TextEdit = $Panel/TextEdit 
@onready var boton_guardar: Button = $BotonGuardar  
@onready var boton_eliminar: Button = $BotonBorrar  

var db: SQLite  # Conexión a la base de datos
var nota_id: int = -1  # ID de la nota (-1 = nueva nota)
var ventana_lista: Window  # Referencia a la ventana principal de lista

# Inicializar el editor con la base de datos y referencia a la lista
func inicializar(base_datos: SQLite, lista: Window):
	db = base_datos
	ventana_lista = lista

# Abre el editor para crear una nota nueva
func abrir_nota_nueva():
	nota_id = -1
	texto_nota.text = ""
	title = "Nueva Nota"
	popup_centered()
	texto_nota.grab_focus()

# Abre el editor con una nota existente desde la BD
func abrir_nota_existente(id: int):
	nota_id = id
	
	# Consultar datos de la nota
	var query = "SELECT titulo, contenido FROM notas WHERE id=?;"
	db.query_with_bindings(query, [id])
	var resultado = db.query_result
	
	# Cargar contenido si existe
	if resultado is Array and resultado.size() > 0:
		texto_nota.text = str(resultado[0]["contenido"])
		title = "Editar: " + str(resultado[0]["titulo"])
	else:
		print("Error al cargar la nota")
		texto_nota.text = ""
		title = "Nueva Nota"
	
	popup_centered()
	texto_nota.grab_focus()

# Guardar la nota (nueva o actualización) en la base de datos
func _on_boton_guardar_pressed() -> void:
	var contenido = texto_nota.text
	
	if db == null:
		print("Error: Base de datos no disponible")
		return
		
	var titulo = _obtener_titulo(contenido)
	
	if nota_id == -1:
		# Insertar nueva nota
		var query = "INSERT INTO notas (titulo, contenido) VALUES (?, ?);"
		db.query_with_bindings(query, [titulo, contenido])
	else:
		# Actualizar nota existente
		var query = "UPDATE notas SET titulo=?, contenido=? WHERE id=?;"
		db.query_with_bindings(query, [titulo, contenido, nota_id])
		print("✓ Nota actualizada: ", titulo)
	
	# Verificar guardado
	db.query("SELECT COUNT(*) as total FROM notas;")
	var verificar = db.query_result
	if verificar and verificar.size() > 0:
		print("Total de notas en DB: ", verificar[0]["total"])
	
	ventana_lista.actualizar_lista()  # Refrescar lista principal
	_on_close_requested()

# Eliminar la nota abierta de la base de datos
func _on_boton_borrar_pressed() -> void:
	if nota_id != -1:
		var query = "DELETE FROM notas WHERE id=?;"
		db.query_with_bindings(query, [nota_id])
		print("✓ Nota eliminada (ID: ", nota_id, ")")
		ventana_lista.actualizar_lista()  # Refrescar lista principal
	
	_on_close_requested()

# Generar un título de la primera línea 
func _obtener_titulo(texto: String) -> String:
	var lineas = texto.split("\n")
	var primera_linea = lineas[0].strip_edges()
	
	# Usar primera línea o primeros 50 caracteres
	if primera_linea.length() > 50:
		return primera_linea.substr(0, 50) + "..."
	elif primera_linea.length() > 0:
		return primera_linea
	else:
		return "Nota sin título"

# Ocultar la ventana al cerrar
func _on_close_requested() -> void:
	hide()
