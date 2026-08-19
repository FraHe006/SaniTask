extends Window

@export var parent_node : Node2D

# Función que se ejecuta cuando se pulsa el botón de maximizar
func _on_maximize_button_pressed():
	# Obtener el tamaño del nodo padre
	var parent_size = parent_node.rect_size
	
	# Ajustar el tamaño del nodo hijo al tamaño máximo del nodo padre
	var max_width = parent_size.x
	var max_height = parent_size.y
	
	# Establecer el tamaño máximo permitido para el nodo hijo (la ventana maximizada)
	self.rect_min_size = Vector2(max_width, max_height)
	
	# Puedes también asegurarte de que la ventana no se mueva fuera del área del padre
	self.position = Vector2.ZERO  # Esto mueve la ventana a la posición 0,0 del nodo padre

	# Ahora maximiza la ventana
	self.rect_size = Vector2(max_width, max_height)
