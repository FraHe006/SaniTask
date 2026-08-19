extends Control

var db: SQLite  

@onready var Calculadora = get_node("Panel2/Calculadora")
@onready var Notas = get_node("Panel2/Notas")
@onready var TodoList = get_node("Panel2/TodoList")
@onready var GestionPacientes = get_node("Panel2/GestionPacientes")
@onready var GestionEmpleados = get_node("Panel2/GestionEmpleados")
@onready var GestionCitas = get_node("Panel2/GestionCitas")

@onready var botonCalculadora = get_node("Panel2/CalculadoraBoton")
@onready var botonNotas = get_node("Panel2/NotasBoton")
@onready var botonTodoList = get_node("Panel2/TodoListBoton")
@onready var botonAgregarNotas = get_node("Panel2/Notas/BotonNuevaNota")
@onready var botonGuardarNuevaNota = get_node("Panel2/Notas/Editor/BotonGuardar")
@onready var botonBorrarNota = get_node("Panel2/Notas/Editor/BotonBorrar")

@onready var botonEmpleados = get_node("Panel2/GestionEmpleadosBoton")
@onready var botonEmpleadosCrear = get_node("Panel2/GestionEmpleados/Button")
@onready var botonEmpleadosGuardar = get_node("Panel2/GestionEmpleados/Historial/BotonGuardar")
@onready var botonEmpleadosBorrar = get_node("Panel2/GestionEmpleados/Historial/BotonBorrar")

@onready var botonPacientes = get_node("Panel2/GestionPacientesBoton")
@onready var botonPacientesCrear = get_node("Panel2/GestionPacientes/Button")
@onready var botonPacientesGuardar = get_node("Panel2/GestionPacientes/Historial/BotonGuardar")
@onready var botonPacientesBorrar = get_node("Panel2/GestionPacientes/Historial/BotonBorrar")

@onready var botonCitas = get_node("Panel2/GestionCitasBoton")
@onready var botonCitasCrear = get_node("Panel2/GestionCitas/BotonNuevaNota")
@onready var botonCitasGuardar = get_node("Panel2/GestionCitas/Citas/BotonGuardar")
@onready var botonCitasBorrar = get_node("Panel2/GestionCitas/Citas/BotonBorrar")

const Volver = "res://inicioSesion.tscn"

func inicializar_db():
	# se instacia la base de datos
	db = SQLite.new()
	db.path = "user://app_data.db"
	db.open_db()
	
	print("✓ Base de datos abierta: ", db.path)

func _ready():
	inicializar_db()
	Notas.inicializar(db)  
	TodoList.inicializar(db) 
	mostrarIconosSegunPermisos()

# se cierra la base de datos al salir
func _exit_tree():
	if db:
		db.close_db()

func _on_calculadora_boton_pressed() -> void:
	Calculadora.show()

func _on_window_close_requested() -> void:
	Calculadora.hide()

# Funciones para Notas
func _on_notas_boton_pressed() -> void:
	Notas.show()

func _on_notas_close_requested() -> void:
	Notas.hide()

# Funciones para TodoList
func _on_todo_list_boton_pressed() -> void:
	TodoList.show()

func _on_todo_list_close_requested() -> void:
	TodoList.hide()

# Funciones para Gestión de Pacientes
func _on_gestion_pacientes_boton_pressed() -> void:
	GestionPacientes.show()

func _on_gestion_pacientes_close_requested() -> void:
	GestionPacientes.hide()

# Funciones para Gestión de Empleados
func _on_gestion_empleados_boton_pressed() -> void:
	GestionEmpleados.show()

func _on_gestion_empleados_close_requested() -> void:
	GestionEmpleados.hide()
	
func _on_gestion_citas_boton_pressed() -> void:
	GestionCitas.show()

func mostrarIconosSegunPermisos() -> void:
	var query = "SELECT tipo_empleado FROM sesion_empleado LIMIT 1;"
	db.query(query)
	var resultado = db.query_result
	
	if resultado is Array and resultado.size() > 0:
		for tipo in resultado:
			var tipo_empleado = str(tipo["tipo_empleado"])
			if tipo_empleado == "Administrador":
				mostrarIconosAdministrador()
			elif tipo_empleado == "Doctor":
				mostrarIconosDoctor()
			elif tipo_empleado == "Gerente":
				mostrarIconosGerente()

func mostrarIconosAdministrador():
	botonCalculadora.show()
	botonNotas.show()
	botonAgregarNotas.show()
	botonGuardarNuevaNota.show()
	botonBorrarNota.show()
	botonTodoList.show()
	botonEmpleados.show()
	botonEmpleadosCrear.show()
	botonEmpleadosGuardar.show()
	botonEmpleadosBorrar.show()

func mostrarIconosDoctor():
	botonCalculadora.show()
	botonNotas.show()
	botonAgregarNotas.show()
	botonGuardarNuevaNota.show()
	botonBorrarNota.show()
	botonTodoList.show()
	botonPacientes.show()
	botonPacientesGuardar.show()
	botonPacientesBorrar.show()
	botonCitas.show()
	botonCitasCrear.show()
	botonCitasGuardar.show()
	botonCitasBorrar.show()
	
func mostrarIconosGerente():
	botonCalculadora.show()
	botonNotas.show()
	botonAgregarNotas.show()
	botonGuardarNuevaNota.show()
	botonBorrarNota.show()
	botonTodoList.show()
	botonEmpleados.show()
	botonPacientes.show()
	botonPacientesCrear.show()
	botonPacientesGuardar.show()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file(Volver)

func _on_apagar_pressed() -> void:
	# Muestra diálogo de confirmación antes de cerrar
	var confirmacion = ConfirmationDialog.new()
	add_child(confirmacion)
	confirmacion.dialog_text = "¿Estás seguro de que deseas salir de la aplicación?"
	confirmacion.confirmed.connect(_confirmar_salir)
	confirmacion.popup_centered()

func _confirmar_salir():
	# Cierra la aplicación tras confirmación
	get_tree().quit()
