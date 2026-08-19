extends Label

func _process(_delta):
	var tiempo = Time.get_time_dict_from_system()
	
	var hora = tiempo.hour
	var minutos = tiempo.minute
	
	var hora_texto = str(hora) if hora >= 10 else "0" + str(hora)
	var min_texto = str(minutos) if minutos >= 10 else "0" + str(minutos)
	
	text = hora_texto + ":" + min_texto
