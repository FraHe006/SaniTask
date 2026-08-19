extends Window

# Referencias a elementos de la interfaz
@onready var input_tarea: LineEdit = $NombreNuevaTareaText  
@onready var lista_tareas: VBoxContainer = $Panel/ScrollContainer/ListaTareas  

var db: SQLite  # Conexión a la base de datos

func _ready():
	size = Vector2i(400, 500)
	title = "Lista de Tareas"

# Inicializa la ventana con la base de datos
func inicializar(base_datos: SQLite):
	db = base_datos
	cargar_tareas()

# Carga y muestra todas las tareas desde la BD
func cargar_tareas():
	if db == null:
		return
	
	# Limpiar lista actual
	for child in lista_tareas.get_children():
		child.queue_free()
	
	# Consultar tareas (completadas al final)
	db.query("SELECT id, nombre, completada FROM tareas ORDER BY completada ASC, fecha DESC;")
	
	# Crear un elemento visual por cada tarea
	for tarea in db.query_result:
		var hbox = HBoxContainer.new()
		
		# CheckBox para marcar completada
		var checkbox = CheckBox.new()
		checkbox.button_pressed = bool(tarea["completada"])
		checkbox.toggled.connect(_on_tarea_toggled.bind(tarea["id"]))
		
		# Label con el nombre de la tarea
		var label = Label.new()
		label.text = tarea["nombre"]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Margen para espaciado
		var margen = MarginContainer.new()
		margen.add_theme_constant_override("margin_left", 8)
		margen.add_theme_constant_override("margin_right", 8)
		margen.add_theme_constant_override("margin_top", 8)
		margen.add_theme_constant_override("margin_bottom", 2)
		
		# Estilo de fuente y color
		var fuente = load("res://w95fa/W95FA.otf")
		label.add_theme_font_override("font", fuente)
		label.add_theme_font_size_override("font_size", 20)
		
		# Color gris si está completada, negro si no
		if tarea["completada"]:
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		else:
			label.add_theme_color_override("font_color", Color(0, 0, 0))
		
		# Juntar todos los elementos
		hbox.add_child(checkbox)
		hbox.add_child(label)
		margen.add_child(hbox)
		lista_tareas.add_child(margen)

# Agregar una nueva tarea a la base de datos
func _on_agregar_tarea_pressed():
	var nombre = input_tarea.text.strip_edges()
	
	if nombre != "" and db != null:
		db.query_with_bindings("INSERT INTO tareas (nombre, completada) VALUES (?, 0);", [nombre])
		input_tarea.text = ""  # Limpiar campo de texto
		cargar_tareas()  # Refrescar lista

# Actualiza el estado completada/pendiente de una tarea
func _on_tarea_toggled(completada: bool, id: int):
	if db != null:
		db.query_with_bindings("UPDATE tareas SET completada=? WHERE id=?;", [int(completada), id])
		cargar_tareas()  # Refrescar lista para actualizar color

# Elimina todas las tareas marcadas como completadas
func _on_borrar_tareas_hechas_pressed():
	if db != null:
		db.query("DELETE FROM tareas WHERE completada=1;")
		cargar_tareas()  # Refrescar lista

# Oculta la ventana al cerrar
func _on_close_requested():
	hide()
