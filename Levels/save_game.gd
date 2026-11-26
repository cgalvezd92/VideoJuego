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
		if FileAccess.file_exists(SAVE_PATH):
			# Recargar la escena hace que se cargue el guardado en _ready.
			get_tree().reload_current_scene()
		else:
			hud.show_message("No hay ninguna partida guardada")
	elif event.is_action_pressed("new_game"):
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(SAVE_PATH)
		get_tree().reload_current_scene()


func _notification(what: int) -> void:
	# Al cerrar la ventana del juego, guarda antes de salir.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game(false)


func save_game(show_message: bool) -> void:
	var campfires: Array = []
	for fire in get_tree().get_nodes_in_group("campfire"):
		campfires.append(_vec_to_array(fire.global_position))

	# Cada refugio: [x, y, z, giro].
	var shelters: Array = []
	for shelter in get_tree().get_nodes_in_group("shelter"):
		shelters.append(_vec_to_array(shelter.global_position) + [shelter.rotation.y])

	var data: Dictionary = {
		"version": 1,
		"player": {
			"position": _vec_to_array(player.global_position),
			"rotation_y": player.rotation.y,
			"head_x": head.rotation.x,
		},
		"survival": {
			"health": survival.health,
			"hunger": survival.hunger,
			"thirst": survival.thirst,
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
		"trees": _names_left(trees),
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

	# Jugador
	var p: Dictionary = data.get("player", {})
	if p.has("position"):
		player.global_position = _array_to_vec(p.position)
	player.rotation.y = p.get("rotation_y", 0.0)
	head.rotation.x = p.get("head_x", 0.0)
	player.velocity = Vector3.ZERO

	# Vida, hambre y sed
	var s: Dictionary = data.get("survival", {})
	survival.health = s.get("health", survival.max_value)
	survival.hunger = s.get("hunger", survival.max_value)
	survival.thirst = s.get("thirst", survival.max_value)
	survival.check_time = 0.0

	# Hora
	day_night.total_hours = data.get("hours", day_night.start_hour)
	day_night._apply()

	# Inventario (JSON guarda los números como decimales: se pasan a enteros).
	var inv: Dictionary = data.get("inventory", {})
	var saved_slots: Array = inv.get("slots", [])
	for i in inventory.SLOT_COUNT:
		var slot = saved_slots[i] if i < saved_slots.size() else null
		if slot == null:
			inventory.slots[i] = null
		else:
			inventory.slots[i] = { "id": slot.id, "name": slot.name, "amount": int(slot.amount) }
	inventory.changed.emit()
	inventory.select(int(inv.get("selected", 0)))

	# Quitar lo que ya se recogió o se taló.
	_remove_missing(objects, data.get("objects", null))
	_remove_missing(trees, data.get("trees", null))

	# Volver a poner las fogatas.
	for pos in data.get("campfires", []):
		var fire: Node3D = CAMPFIRE_SCENE.instantiate()
		main.add_child(fire)
		fire.global_position = _array_to_vec(pos)

	# Volver a poner los refugios.
	for data_shelter in data.get("shelters", []):
		var shelter: Node3D = SHELTER_SCENE.instantiate()
		main.add_child(shelter)
		shelter.global_position = _array_to_vec(data_shelter)
		shelter.rotation.y = data_shelter[3]

	hud.show_message("Partida cargada")


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


func _vec_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _array_to_vec(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])
