extends Window

@onready var lista_notas: ItemList = $Panel/ListaNotas  
@onready var boton_nueva_nota: Button = $BotonNuevaNota 
@onready var ventana_editor_base: Window = $Editor  

# Base de datos y control de ventanas
var db: SQLite  # Conexión a la base de datos
var editores_abiertos: Array = []  # Array de ventanas de edición de notas abiertas

func _ready():
	# Permite abrir una nota al pulsar en ella
	lista_notas.item_clicked.connect(_abrir_nota)

# Iniciarlizar la base de datos y la lista de notas
func inicializar(base_datos: SQLite):
	db = base_datos
	ventana_editor_base.inicializar(db, self)
	actualizar_lista()

# Cargar y mostrar todas las notas desde la BD
func actualizar_lista():
	lista_notas.clear()
	
	if db == null:
		print("Error: Base de datos no inicializada")
		return
	
	# Consultar notas ordenadas por ID, en orden descendente
	var query = "SELECT id, titulo FROM notas ORDER BY id DESC;"
	db.query(query)
	var resultado = db.query_result
	
	# Agregar cada nota a la lista
	if resultado is Array and resultado.size() > 0:
		for nota in resultado:
			var texto_item = str(nota["titulo"])
			lista_notas.add_item(texto_item)
			lista_notas.set_item_metadata(lista_notas.item_count - 1, nota["id"])
		print("Notas cargadas: ", resultado.size())
	else:
		print("No hay notas en la base de datos")

# Crear una ventana de edición por cada nota que se abre
func _on_boton_nueva_nota_pressed() -> void:
	var nuevo_editor = ventana_editor_base.duplicate()
	add_child(nuevo_editor)
	nuevo_editor.inicializar(db, self)
	nuevo_editor.abrir_nota_nueva()
	editores_abiertos.append(nuevo_editor)
	
	# Eliminar del array de notas abrietas cuando se cierra
	nuevo_editor.tree_exited.connect(func(): editores_abiertos.erase(nuevo_editor))

# Evitar duplicidad de notas ya abiertas
func _abrir_nota(index: int, _at_position: Vector2, _mouse_button_index: int):
	var nota_id = lista_notas.get_item_metadata(index)
	
	# Verificar si la nota ya está abierta
	for editor in editores_abiertos:
		if editor.nota_id == nota_id:
			editor.visible = true
			editor.grab_focus()
			return
	
	# Si no ha sido abierta permitir abrirla
	var nuevo_editor = ventana_editor_base.duplicate()
	add_child(nuevo_editor)
	nuevo_editor.nota_id = nota_id
	nuevo_editor.inicializar(db, self)
	nuevo_editor.abrir_nota_existente(nota_id)
	editores_abiertos.append(nuevo_editor)
	
	# Eliminar del array cuando se cierra
	nuevo_editor.tree_exited.connect(func():
		editores_abiertos.erase(nuevo_editor)
	)
	
