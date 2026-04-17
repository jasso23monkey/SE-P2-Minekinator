extends Node2D

var todos_los_mobs = []
var mobs_restantes = []
var pagina_actual = 0
const MOBS_POR_PAGINA = 5
var total_preguntas_hechas = 1 # Empezamos en la pregunta 1



# Ajusta estas rutas a tus nodos
@onready var label_pregunta = %Pregunta
@onready var label_numero = %Numero
# Referencias a los slots de los mobs (HBoxContainer2)
@onready var slots_mobs = [
	%M1, %M2, %M3, %M4, %M5
]


func _ready() -> void:
	cargar_json()
	print("Mobs cargados: ", todos_los_mobs.size()) # Si sale 0, el problema es el JSON
	mobs_restantes = todos_los_mobs.duplicate()
	actualizar_carrusel()

func cargar_json():
	if FileAccess.file_exists("res://assets/json/mobs_data.json"):
		var archivo = FileAccess.open("res://assets/json/mobs_data.json", FileAccess.READ)
		var datos = JSON.parse_string(archivo.get_as_text())
		if datos: todos_los_mobs = datos
	
func actualizar_carrusel():
	var inicio = pagina_actual * MOBS_POR_PAGINA
	
	for i in range(MOBS_POR_PAGINA):
		var indice_mob = inicio + i
		var slot = slots_mobs[i]
		
		if indice_mob < todos_los_mobs.size():
			var mob = todos_los_mobs[indice_mob]
			slot.visible = true
			
			# --- AQUÍ VA EL NUEVO CÓDIGO ---
			# Convertimos el ID a texto y aseguramos 3 dígitos (ej: de 1 a "001")
			var id_limpio = str(mob["id"]).pad_zeros(3)
			var ruta_foto = "res://assets/images/mobs/" + id_limpio + ".png"
			
			# Esto imprimirá en la consola la ruta que Godot intenta buscar
			print("Intentando cargar: ", ruta_foto)
			
			slot.texture = load(ruta_foto)
			# ------------------------------
			
			# Lógica de oscurecido
			if mob in mobs_restantes:
				slot.modulate = Color(1, 1, 1)
			else:
				slot.modulate = Color(0.1, 0.1, 0.1, 0.8)
		else:
			slot.visible = false

# --- LÓGICA DE FILTRADO (El corazón del sistema) ---

func filtrar_mobs(caracteristica: String, valor_esperado: bool):
	var nueva_lista = []
	for mob in mobs_restantes:
		# Accedemos a mob["reglas"]["vuela"], por ejemplo
		if mob["reglas"][caracteristica] == valor_esperado:
			nueva_lista.append(mob)
	
	mobs_restantes = nueva_lista
	actualizar_carrusel()
	# Aquí llamarías a tu función para poner la siguiente pregunta
	
	
# Botón Derecha (Avanzar)
func _on_der_pressed() -> void:
	# Calculamos si hay más mobs adelante
	# Si (pagina_actual + 1) * 5 es menor que el total, podemos avanzar
	if (pagina_actual + 1) * MOBS_POR_PAGINA < todos_los_mobs.size():
		pagina_actual += 1
		actualizar_carrusel()
		print("Página actual: ", pagina_actual)
	else:
		print("Llegaste al final de la lista")

# Botón Izquierda (Retroceder)
func _on_izq_pressed() -> void:
	# Solo retrocedemos si no estamos en la primera página (0)
	if pagina_actual > 0:
		pagina_actual -= 1
		actualizar_carrusel()
		print("Página actual: ", pagina_actual)
	else:
		print("Ya estás en la primera página")
		
func registrar_nueva_pregunta():
	total_preguntas_hechas += 1
	label_numero.text = "Pregunta " + str(total_preguntas_hechas)
	
	

func _on_no_pressed() -> void:
	print("El usuario dijo NO")
	registrar_nueva_pregunta()

func _on_nose_pressed() -> void:
	print("El usuario dijo NO SÉ")
	registrar_nueva_pregunta()

func _on_si_pressed() -> void:
	print("El usuario dijo SI")
	registrar_nueva_pregunta()
