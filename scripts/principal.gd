extends Node2D

var todos_los_mobs = []
var mobs_restantes = []
var pagina_actual = 0
const MOBS_POR_PAGINA = 5
var total_preguntas_hechas = 1 # Empezamos en la pregunta 1
var lista_preguntas = [] #variables para el gestor de estados
var pregunta_actual_idx = 0
var preguntas_pendientes = [] # Mazo de preguntas que aún no se han hecho
var pregunta_actual_data = {}  # Datos de la pregunta que está en pantalla
var reglas_exclusion = {
	"hostil": ["pasivo", "neutral"],
	"pasivo": ["hostil", "neutral"],
	"neutral": ["hostil", "pasivo"]
	# Quitamos las dimensiones de aquí para evitar el error del Enderman
}


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
			# Creamos el mazo de pendientes y lo barajamos
			preguntas_pendientes = lista_preguntas.duplicate()
			preguntas_pendientes.shuffle() 
			print("Mazo de preguntas barajado: ", preguntas_pendientes.size())

func mostrar_pregunta_actual():
	if preguntas_pendientes.size() > 0:
		# Sacamos la primera del mazo barajado
		pregunta_actual_data = preguntas_pendientes.pop_front()
		label_pregunta.text = pregunta_actual_data["texto"]
	else:
		verificar_resultado_final()

func avanzar_a_siguiente_pregunta():
	if mobs_restantes.size() <= 1:
		verificar_resultado_final()
		return

	# Intentar encontrar una pregunta que separe a los mobs que quedan
	var pregunta_inteligente = buscar_pregunta_discriminatoria()
	
	if not pregunta_inteligente.is_empty():
		pregunta_actual_data = pregunta_inteligente
		registrar_nueva_pregunta()
		label_pregunta.text = pregunta_actual_data["texto"]
		print("Inferencia: Pregunta seleccionada para diferenciar mobs restantes: ", pregunta_actual_data["clave"])
	else:
		# Si no hay una pregunta específica (o falló el buscador), usamos el azar
		if preguntas_pendientes.size() > 0:
			pregunta_actual_data = preguntas_pendientes.pop_front()
			registrar_nueva_pregunta()
			label_pregunta.text = pregunta_actual_data["texto"]
		else:
			verificar_resultado_final()

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
	var clave_regla = pregunta_actual_data["clave"]
	
	# --- NUEVA LÓGICA DE INFERENCIA ---
	if valor_usuario == true:
		podar_preguntas_incompatibles(clave_regla)
	# ----------------------------------

	var nueva_lista = []
	for mob in mobs_restantes:
		if cumple_regla(mob["reglas"], clave_regla, valor_usuario):
			nueva_lista.append(mob)
	
	mobs_restantes = nueva_lista
	actualizar_carrusel()
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
	
func podar_preguntas_incompatibles(clave_confirmada: String):
	if reglas_exclusion.has(clave_confirmada):
		var claves_a_eliminar = reglas_exclusion[clave_confirmada]
		
		# Filtramos el mazo para quitar las preguntas cuyas claves ya deducimos
		var nuevas_pendientes = []
		for p in preguntas_pendientes:
			if not p["clave"] in claves_a_eliminar:
				nuevas_pendientes.append(p)
			else:
				print("Inferencia: Eliminando pregunta redundante de ", p["clave"])
		
		preguntas_pendientes = nuevas_pendientes

func buscar_pregunta_discriminatoria() -> Dictionary:
	if mobs_restantes.size() < 2:
		return {}

	var frecuencias = {}
	for mob in mobs_restantes:
		for regla in mob["reglas"]:
			if mob["reglas"][regla] == true:
				frecuencias[regla] = frecuencias.get(regla, 0) + 1

	# --- AQUÍ ESTÁ EL CAMBIO ---
	# 1. Limpiar preguntas que no dividen el grupo (Nadie las tiene o Todos las tienen)
	var claves_a_eliminar = []
	for i in range(preguntas_pendientes.size() - 1, -1, -1):
		var clave = preguntas_pendientes[i]["clave"]
		var n = frecuencias.get(clave, 0)
		
		# Si n es 0 (nadie la tiene) o n es igual al total (todos la tienen)
		# la pregunta ya no sirve para diferenciar.
		if n == 0 or n == mobs_restantes.size():
			preguntas_pendientes.remove_at(i)
			print("Limpieza: Eliminando pregunta irrelevante: ", clave)
	# ---------------------------

	# 2. Buscar la regla que mejor divida al grupo
	# Lo ideal es una regla que tenga cerca de la mitad de los mobs (50%)
	# Pero en grupos pequeños, cualquier regla que no tengan TODOS y que no tenga NADIE sirve.
	var mejor_clave = ""
	var menor_distancia_al_centro = 999
	
	for clave in frecuencias:
		var n = frecuencias[clave]
		# Si todos los mobs la tienen o ninguno, no nos sirve para diferenciar
		if n > 0 and n < mobs_restantes.size():
			# Calculamos qué tan cerca está de dividir el grupo a la mitad
			var distancia = abs((mobs_restantes.size() / 2.0) - n)
			if distancia < menor_distancia_al_centro:
				menor_distancia_al_centro = distancia
				mejor_clave = clave

	# 3. Buscar esa clave en nuestro mazo de preguntas pendientes
	if mejor_clave != "":
		for i in range(preguntas_pendientes.size()):
			if preguntas_pendientes[i]["clave"] == mejor_clave:
				return preguntas_pendientes.pop_at(i) # La sacamos y la devolvemos
	
	return {}
