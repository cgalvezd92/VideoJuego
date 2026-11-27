extends Node
## Guardar y cargar la partida (Etapa 10).
## Va en el nodo "SaveGame", hijo de Main (en main.tscn).
##
## F5 guarda, F9 vuelve al último guardado y F8 empieza una partida nueva.
## También guarda solo cada minuto y al cerrar la ventana.
## El archivo es texto (JSON). En Mac está en:
## ~/Library/Application Support/Godot/app_userdata/Proyecto_Mundo_Abierto/partida.json

const SAVE_PATH: String = "user://partida.json"
const CAMPFIRE_SCENE: PackedScene = preload("res://objects/campfire.tscn")
const SHELTER_SCENE: PackedScene = preload("res://objects/shelter.tscn")
const Chest = preload("res://objects/chest.gd")
const Bed = preload("res://objects/bed.gd")
const HeldItems = preload("res://Player/held_items.gd")

## Cada cuántos segundos se guarda automáticamente.
@export var autosave_seconds: float = 60.0

@onready var main: Node = get_parent()
@onready var player: CharacterBody3D = $"../Player"
@onready var head: Node3D = $"../Player/Head"
@onready var inventory = $"../Player/Inventory"
@onready var survival = $"../Player/Survival"
@onready var hud = $"../Player/HUD"
@onready var day_night = $"../DayNight"
@onready var objects: Node = $"../Objects"
@onready var trees: Node = $"../Nature/Trees"
@onready var world = $"../World"
@onready var places = $"../Places"
@onready var objectives = $"../Player/Objectives"

var autosave_time: float = 0.0


func _ready() -> void:
	autosave_time = autosave_seconds
	if FileAccess.file_exists(SAVE_PATH):
		# Se espera a que todo el nivel esté listo antes de cargar.
		load_game.call_deferred()


func _process(delta: float) -> void:
	autosave_time -= delta
	if autosave_time <= 0.0:
		autosave_time = autosave_seconds
		save_game(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		save_game(true)
	elif event.is_action_pressed("load_game"):
		if has_save():
			load_last()
		else:
			hud.show_message("No hay ninguna partida guardada")
	elif event.is_action_pressed("new_game"):
		new_game()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Vuelve al último guardado: recargar la escena hace que se cargue en _ready.
func load_last() -> void:
	get_tree().reload_current_scene()


## Borra el guardado y empieza de cero.
## Borra el guardado y vuelve a elegir personaje para empezar de cero.
func new_game() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://personajes/seleccion_personaje.tscn")


func _notification(what: int) -> void:
	# Al cerrar la ventana del juego, guarda antes de salir.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game(false)


func save_game(show_message: bool) -> void:
	var campfires: Array = []
	# Cada fogata: [x, y, z, encendida] (Etapa 30: la lluvia las apaga).
	for fire in get_tree().get_nodes_in_group("fire_pit"):
		campfires.append(_vec_to_array(fire.global_position) + [fire.lit, fire.protected])

	# Cada refugio: [x, y, z, giro].
	var shelters: Array = []
	for shelter in get_tree().get_nodes_in_group("shelter"):
		shelters.append(_vec_to_array(shelter.global_position) + [shelter.rotation.y])

	# Cofres con lo que guardan y camas (Etapa 41): [x, y, z, giro, (casillas)].
	var chests: Array = []
	for chest in get_tree().get_nodes_in_group("chest"):
		chests.append(_vec_to_array(chest.global_position) + [chest.rotation.y, chest.slots])
	var beds: Array = []
	for bed in get_tree().get_nodes_in_group("bed"):
		beds.append(_vec_to_array(bed.global_position) + [bed.rotation.y])

	# Objetos soltados en el suelo (Etapa 42): [x, y, z, id, nombre, cantidad].
	var dropped: Array = []
	for item in get_tree().get_nodes_in_group("dropped"):
		if not item.is_queued_for_deletion():
			dropped.append(_vec_to_array(item.global_position) + [item.item_id, item.display_name, item.amount, item.get_meta("durability", -1)])

	var data: Dictionary = {
		"version": 2,  # 2 = mapa de África (Etapa 19).
		"personaje": Personajes.actual()["id"],  # Etapa 25.
		"dificultad": Personajes.DIFICULTADES[Personajes.dificultad]["id"],  # Etapa 36.
		"player": {
			"position": _vec_to_array(player.global_position),
			"rotation_y": player.rotation.y,
			"head_x": head.rotation.x,
		},
		"survival": {
			"health": survival.health,
			"hunger": survival.hunger,
			"thirst": survival.thirst,
			"bleeding": survival.bleeding,  # Etapa 37.
		},
		"hours": day_night.total_hours,
		"inventory": {
			"slots": inventory.slots,
			"selected": inventory.selected,
		},
		"campfires": campfires,
		"shelters": shelters,
		# Nombres de lo que sigue en el mapa (lo que falta ya se recogió o taló).
		"objects": _names_left(objects),
		# Acacias taladas y la hora del juego en que se talaron (para el rebrote).
		"felled_trees": _felled_trees(),
		"backpack": inventory.has_backpack(),  # Etapa 31.
		"chests": chests,
		"beds": beds,
		"dropped": dropped,
		"places": places.get_save_data(),  # Etapa 47.
		"notes": $"../Story".get_save_data(),  # Etapa 51.
		"map_fog": player.get_node("MapView").get_save_data(),  # Etapa 48.
		"torch_fuel": player.get_node("Tools").torch_fuel,  # Etapa 43.
		# Objetivos cumplidos y si ya te rescataron (Etapa 34).
		"objectives": objectives.get_save_data(),
		# Lo recogido y talado fuera de la zona inicial (Etapa 22).
		"world": world.get_save_data(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		hud.show_message("No se pudo guardar la partida")
		return
	file.store_string(JSON.stringify(data, "\t"))
	if show_message:
		hud.show_message("Partida guardada")


func load_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		hud.show_message("La partida guardada está dañada")
		return

	# Los guardados del mapa anterior (versión 1) no sirven para posiciones:
	# se conserva el inventario, la vida y la hora, pero empiezas en la salida.
	var same_map: bool = int(data.get("version", 1)) >= 2
	# Dificultad de la partida (Etapa 36); las partidas antiguas son Normal.
	Personajes.dificultad = Personajes.indice_dificultad(data.get("dificultad", "normal"))

	# Jugador
	var p: Dictionary = data.get("player", {})
	if p.has("position") and same_map:
		player.global_position = _array_to_vec(p.position)
	player.rotation.y = p.get("rotation_y", 0.0)
	head.rotation.x = p.get("head_x", 0.0)
	player.velocity = Vector3.ZERO

	# Vida, hambre y sed
	var s: Dictionary = data.get("survival", {})
	survival.health = minf(s.get("health", survival.max_health), survival.max_health)
	survival.hunger = s.get("hunger", survival.max_value)
	survival.thirst = s.get("thirst", survival.max_value)
	survival.bleeding = s.get("bleeding", 0.0)
	survival.check_time = 0.0

	# Hora
	day_night.total_hours = data.get("hours", day_night.start_hour)
	day_night._apply()

	# Inventario (JSON guarda los números como decimales: se pasan a enteros).
	var inv: Dictionary = data.get("inventory", {})
	var saved_slots: Array = inv.get("slots", [])
	if data.get("backpack", false):
		inventory.expand(12)
	for i in inventory.SLOT_COUNT:
		var slot = saved_slots[i] if i < saved_slots.size() else null
		if slot == null:
			inventory.slots[i] = null
		else:
			inventory.slots[i] = _slot_from_save(slot)
	inventory.changed.emit()
	inventory.select(int(inv.get("selected", 0)))

	objectives.set_save_data(data.get("objectives", {}))

	# Quitar lo que ya se recogió o se taló.
	_remove_missing(objects, data.get("objects", null))
	_load_felled_trees(data)
	if same_map and data.has("world"):
		world.set_save_data(data.world)

	# Volver a poner las fogatas.
	for pos in (data.get("campfires", []) if same_map else []):
		var fire: Node3D = CAMPFIRE_SCENE.instantiate()
		main.add_child(fire)
		fire.global_position = _array_to_vec(pos)
		if pos.size() > 3 and not pos[3]:
			fire.extinguish()
		if pos.size() > 4 and pos[4]:
			fire.protect()  # Muro de piedras (Etapa 43).

	# Volver a poner los refugios.
	for data_shelter in (data.get("shelters", []) if same_map else []):
		var shelter: Node3D = SHELTER_SCENE.instantiate()
		main.add_child(shelter)
		shelter.global_position = _array_to_vec(data_shelter)
		shelter.rotation.y = data_shelter[3]

	# Cofres y camas (Etapa 41).
	for c in (data.get("chests", []) if same_map else []):
		var chest: Node3D = Chest.new()
		chest.slots.resize(Chest.SLOT_COUNT)
		var saved: Array = c[4]
		for i in mini(saved.size(), Chest.SLOT_COUNT):
			var slot = saved[i]
			chest.slots[i] = null if slot == null else _slot_from_save(slot)
		main.add_child(chest)
		chest.global_position = _array_to_vec(c)
		chest.rotation.y = c[3]
	for b in (data.get("beds", []) if same_map else []):
		var bed: Node3D = Bed.new()
		main.add_child(bed)
		bed.global_position = _array_to_vec(b)
		bed.rotation.y = b[3]

	for d in (data.get("dropped", []) if same_map else []):
		var item: Area3D = HeldItems.make_pickable(d[3], d[4], int(d[5]))
		if d.size() > 6:
			item.set_meta("durability", int(d[6]))
		main.add_child(item)
		item.global_position = _array_to_vec(d)

	player.get_node("Tools").torch_fuel = data.get("torch_fuel", player.get_node("Tools").torch_seconds)

	if same_map and data.has("map_fog"):
		player.get_node("MapView").set_save_data(data.map_fog)
	$"../Story".set_save_data(data.get("notes", []))
	if same_map and data.has("places"):
		places.set_save_data(data.places)

	hud.show_message("Partida cargada")


func _felled_trees() -> Dictionary:
	var felled: Dictionary = {}
	for tree in trees.get_children():
		if tree.felled:
			felled[str(tree.name)] = tree.felled_at
		elif tree.hits >= tree.hits_needed:
			felled[str(tree.name)] = day_night.total_hours  # Está cayendo ahora.
	return felled


func _load_felled_trees(data: Dictionary) -> void:
	if data.has("felled_trees"):
		var felled: Dictionary = data.felled_trees
		for tree in trees.get_children():
			if felled.has(str(tree.name)):
				tree.set_felled(felled[str(tree.name)])
	elif data.has("trees"):
		# Guardado de antes de la etapa 18: las acacias que faltan pasan a ser
		# tocones que empiezan a rebrotar ahora.
		var left: Array = data.trees
		for tree in trees.get_children():
			if not left.has(str(tree.name)):
				tree.set_felled(day_night.total_hours)


func _names_left(parent: Node) -> Array:
	var names: Array = []
	for child in parent.get_children():
		var falling: bool = "hits" in child and child.hits >= child.hits_needed
		if not child.is_queued_for_deletion() and not falling:
			names.append(str(child.name))
	return names


func _remove_missing(parent: Node, names_left) -> void:
	if names_left == null:
		return  # Guardado antiguo sin esta información: no se toca nada.
	for child in parent.get_children():
		if not names_left.has(str(child.name)):
			child.queue_free()


## Casilla guardada -> casilla del juego (JSON guarda los números como decimales).
func _slot_from_save(slot: Dictionary) -> Dictionary:
	var result: Dictionary = { "id": slot.id, "name": slot.name, "amount": int(slot.amount) }
	if slot.has("durability"):
		result.durability = int(slot.durability)  # Etapa 44.
	return result


func _vec_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _array_to_vec(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])
