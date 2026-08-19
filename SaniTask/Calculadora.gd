extends Control
@onready var pantalla: LineEdit = $"../Texto"  

# Variables para la calculadora
var valor_actual: String = "0"  # Número mostrado en pantalla
var valor_guardado: float = 0.0  # Primer número de la operación
var operacion_actual: String = ""  # Operación a realizar (+, -, *, /)
var numero_nuevo: bool = true  # Indica si empezar número nuevo

func _ready():
	# Conectar botones numéricos (0-9)
	for i in range(10):
		var boton = get_node(str(i))
		if boton:
			boton.pressed.connect(_al_presionar_numero.bind(str(i)))
	
	# Conectar botones de operaciones
	$sumar.pressed.connect(_al_presionar_operacion.bind("+"))
	$restar.pressed.connect(_al_presionar_operacion.bind("-"))
	$multiplicar.pressed.connect(_al_presionar_operacion.bind("*"))
	$dividir.pressed.connect(_al_presionar_operacion.bind("/"))
	
	# Conectar botones especiales
	$igual.pressed.connect(_al_presionar_igual)
	$Cero.pressed.connect(_al_presionar_limpiar)
	
	actualizar_pantalla()

# Agregar dígitos al número actual
func _al_presionar_numero(numero: String):
	if numero_nuevo:
		valor_actual = numero
		numero_nuevo = false
	else:
		if valor_actual == "0":
			valor_actual = numero
		else:
			valor_actual += numero
	actualizar_pantalla()

# Guardar el número y la operación seleccionada
func _al_presionar_operacion(operacion: String):
	if operacion_actual != "" and not numero_nuevo:
		calcular()
	
	valor_guardado = float(valor_actual)
	operacion_actual = operacion
	numero_nuevo = true

# Ejecutar la opereación y mostrar el resultado
func _al_presionar_igual():
	if operacion_actual != "":
		calcular()
		operacion_actual = ""

# Resetear la calculadora a los valores iniciales
func _al_presionar_limpiar():
	valor_actual = "0"
	valor_guardado = 0.0
	operacion_actual = ""
	numero_nuevo = true
	actualizar_pantalla()

# Realizar la operación indicada
func calcular():
	var resultado: float = 0.0
	var actual: float = float(valor_actual)
	
	match operacion_actual:
		"+":
			resultado = valor_guardado + actual
		"-":
			resultado = valor_guardado - actual
		"*":
			resultado = valor_guardado * actual
		"/":
			if actual != 0:
				resultado = valor_guardado / actual
			else:
				valor_actual = "Error"
				actualizar_pantalla()
				return
	
	valor_actual = str(resultado)
	# Limpiar decimales innecesarios
	if resultado == floor(resultado):
		valor_actual = str(int(resultado))
	
	numero_nuevo = true
	actualizar_pantalla()

# Actualizar el texto mostrado en pantalla
func actualizar_pantalla():
	if pantalla:
		pantalla.text = valor_actual
