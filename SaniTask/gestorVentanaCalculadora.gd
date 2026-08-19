extends Window

@onready var panel_parent = get_parent()

func _process(_delta):
	if panel_parent:
		var parent_rect = panel_parent.get_global_rect()
		
		# Si está en modo maximizado, ajustar al panel
		if mode == Window.MODE_MAXIMIZED:
			mode = Window.MODE_WINDOWED
			size = Vector2i(parent_rect.size)
			position = Vector2i(parent_rect.position)
