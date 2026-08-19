extends Window

func _ready():
	# Obtener el tamaño de la pantalla
	var tamano_pantalla = DisplayServer.screen_get_size()
	
	# Hacer la ventana más grande proporcionalmente
	var escala = 2.5  # Ajusta este número (prueba 2, 3, 4...)
	size = Vector2i(400 * escala, 400 * escala)
	
	# Centrar
	position = (tamano_pantalla - size) / 2
	
	unresizable = true
