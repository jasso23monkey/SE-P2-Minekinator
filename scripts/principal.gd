extends Node2D

var todos_los_mobs = []
var mobs_restantes = []
var pagina_actual = 0
const MOBS_POR_PAGINA = 5
var total_preguntas_hechas = 1 # Empezamos en la pregunta 1
var lista_preguntas = [] #variables para el gestor de estados
var pregunta_actual_idx = 0


# Ajusta estas rutas a tus nodos
@onready var label_pregunta = %Pregunta
@onready var label_numero = %Numero
# Referencias a los slots de los mobs (HBoxContainer2)
@onready var slots_mobs = [
	%M1, %M2, %M3, %M4, %M5
]


func _ready() -> void:
	cargar_json()
	cargar_preguntas_json()
	print("Mobs cargados: ", todos_los_mobs.size()) # Si sale 0, el problema es el JSON
	mobs_restantes = todos_los_mobs.duplicate()
	actualizar_carrusel()
	# Estado inicial
	pregunta_actual_idx = 0
	total_preguntas_hechas = 1
	label_numero.text = "Pregunta 1"
	mostrar_pregunta_actual()

func cargar_json():
	if FileAccess.file_exists("res://assets/json/mobs_data.json"):
		var archivo = FileAccess.open("res://assets/json/mobs_data.json", FileAccess.READ)
		var datos = JSON.parse_string(archivo.get_as_text())
		if datos: todos_los_mobs = datos

func cargar_preguntas_json():
	var ruta = "res://assets/json/preguntas_data.json"
	if FileAccess.file_exists(ruta):
		var archivo = FileAccess.open(ruta, FileAccess.READ)
		var datos = JSON.parse_string(archivo.get_as_text())
		if datos:
			lista_preguntas = datos
			print("Preguntas cargadas: ", lista_preguntas.size())

func mostrar_pregunta_actual():
	if pregunta_actual_idx < lista_preguntas.size():
		var pregunta = lista_preguntas[pregunta_actual_idx]
		label_pregunta.text = pregunta["texto"]
	else:
		# Si llegamos aquí y hay más de 1 mob, el sistema no fue suficiente
		verificar_resultado_final()
# Esta función centraliza el progreso del juego
func avanzar_a_siguiente_pregunta():
	pregunta_actual_idx += 1
	
	# Verificar si ya solo queda uno antes de preguntar más
	if mobs_restantes.size() <= 1:
		verificar_resultado_final()
	else:
		registrar_nueva_pregunta() # La función que ya tenías para el label "Pregunta X"
		mostrar_pregunta_actual()

func verificar_resultado_final():
	if mobs_restantes.size() == 1:
		#label_pregunta.text = "¡Tu mob es: " + mobs_restantes[0]["nombre"] + "!"
		Global.resultado_final = "Tu mob es: " + mobs_restantes[0]["nombre"] + "!"
		Global.mob_ganador = mobs_restantes[0]
	elif mobs_restantes.size() == 0:
		#label_pregunta.text = "No encontré ningún mob con esas características."
		Global.resultado_final = "No encontré ningún mob con esas características."
		Global.mob_ganador = {}
	else:
		label_pregunta.text = "Me rindo, podría ser: " + mobs_restantes[0]["nombre"] + " u otros."
		Global.resultado_final = "Me rindo, podría ser: " + mobs_restantes[0]["nombre"] + " u otros."
		Global.mob_ganador = mobs_restantes[0]
	#cambia a la escena final
	get_tree().change_scene_to_file("res://scenes/fin.tscn")

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
	procesar_respuesta(false)

func _on_nose_pressed() -> void:
	print("El usuario dijo NO SÉ")
	# En un sistema experto simple, "No sé" suele saltar la regla sin filtrar
	pregunta_actual_idx += 1
	registrar_nueva_pregunta()
	mostrar_pregunta_actual()

func _on_si_pressed() -> void:
	print("El usuario dijo SI")
	procesar_respuesta(true)

# --- MOTOR DE INFERENCIA (Forward Chaining) ---

func procesar_respuesta(valor_usuario: bool):
	if pregunta_actual_idx >= lista_preguntas.size():
		return

	# 1. Obtener la clave de la regla actual (ej: "vuela", "tipo")
	var pregunta_info = lista_preguntas[pregunta_actual_idx]
	var clave_regla = pregunta_info["clave"]
	
	print("Procesando regla: ", clave_regla, " con valor: ", valor_usuario)

	# 2. Filtrado Lógico (Encadenamiento)
	var nueva_lista = []
	
	for mob in mobs_restantes:
		var reglas_mob = mob["reglas"]
		
		# Verificamos si el mob cumple con la condición
		if cumple_regla(reglas_mob, clave_regla, valor_usuario):
			nueva_lista.append(mob)
	
	# 3. Actualizar la base de hechos actual
	mobs_restantes = nueva_lista
	print("Después de filtrar '", clave_regla, "', quedan: ", mobs_restantes.size(), " mobs.")
	actualizar_carrusel()
	
	# 4. Decidir el siguiente estado
	avanzar_a_siguiente_pregunta()

# Función auxiliar para manejar comparaciones especiales (como "tipo" o "dimension")
func cumple_regla(reglas_mob, clave, valor_usuario) -> bool:
	# Si el mob NO tiene la clave, asumimos que el valor es 'false' o 'nulo'
	# Esto evita que los mobs desaparezcan solo porque no tienen todas las etiquetas
	var valor_en_json = false
	if reglas_mob.has(clave):
		valor_en_json = reglas_mob[clave]
	
	# CASO 1: Booleano (true/false)
	if typeof(valor_en_json) == TYPE_BOOL:
		return valor_en_json == valor_usuario
		
	## CASO 2: Strings (tipo, dimension, clasificacion)
	## Si el usuario dice SÍ, buscamos el valor positivo
	#if valor_usuario:
		#if clave == "tipo": return valor_en_json == "hostil"
		#if clave == "dimension": return valor_en_json == "overworld"
		#if clave == "clasificacion": return valor_en_json == "muerto_viviente"
		#if clave == "habitat": return valor_en_json == "acuatico"
	#else:
		## Si el usuario dice NO, aceptamos cualquier cosa que NO sea el valor positivo
		#if clave == "tipo": return valor_en_json != "hostil"
		#if clave == "dimension": return valor_en_json != "overworld"
		#if clave == "clasificacion": return valor_en_json != "muerto_viviente"
		#if clave == "habitat": return valor_en_json != "acuatico"
		
	return valor_en_json == valor_usuario
