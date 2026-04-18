extends Node2D
# Usamos el acceso por nombre único (%) como se ve en tu captura
@onready var label_titulo = %titulo
@onready var texture_mob = %mob

func _ready() -> void:
	# 1. Mostramos el mensaje guardado (ej: "Tu mob es: Abeja")
	label_titulo.text = Global.resultado_final
	
	# 2. Verificamos si hay un mob guardado para poner su foto
	if Global.mob_ganador.size() > 0:
		# Formateamos el ID a 3 dígitos (ej: 1 -> 001)
		var id_formateado = str(Global.mob_ganador["id"]).pad_zeros(3)
		var ruta_foto = "res://assets/images/mobs/" + id_formateado + ".png"
		
		if FileAccess.file_exists(ruta_foto):
			texture_mob.texture = load(ruta_foto)
		else:
			print("Advertencia: No existe la imagen en ", ruta_foto)
	else:
		# Si no hay mob (caso de error), podrías poner una imagen por defecto
		print("No hay datos de mob para mostrar.")

# --- LÓGICA DE BOTONES ---

func _on_si_pressed() -> void:
	# Regresa a la escena principal para jugar de nuevo
	get_tree().change_scene_to_file("res://scenes/inicio.tscn")

func _on_no_pressed() -> void:
	# También regresa al inicio por ahora
	get_tree().change_scene_to_file("res://scenes/inicio.tscn")
