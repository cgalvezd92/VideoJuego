extends Node
## Misión principal y objetivos (Etapa 34).
## Va en el nodo "Objectives" (Node), hijo de Player.
##
## - Misión principal: sobrevivir 14 días y llegar a la extracción. La
##   extracción (un helicóptero) llega el día 15 a las 7:00 al punto verde
##   del mapa (M).
## - Objetivos: pequeñas tareas que enseñan a jugar. El recuadro de abajo a la
##   izquierda muestra los siguientes; se abre y se cierra con O (se recuerda).
##
## Algunos objetivos se comprueban solos una vez por segundo (tener 3 ramas,
## haber hecho una fogata...). Otros los avisan otros scripts al ocurrir
## (beber, cazar, pescar...) con:
##     get_tree().call_group("objectives", "complete", "beber")

const SETTINGS_PATH: String = "user://ajustes.cfg"

## Días que hay que sobrevivir. La extracción llega al empezar el día siguiente.
const DAYS_TO_SURVIVE: int = 14
## Hora del juego a la que llega la extracción: día 15 a las 7:00.
const RESCUE_HOURS: float = DAYS_TO_SURVIVE * 24.0 + 7.0

## Cima del Kilimanjaro (el monte nevado cerca de la salida).
const KILIMANJARO_TOP := Vector3(352.0, 48.4, 56.0)

## Cada objetivo: [id, texto].
const LIST: Array = [
	["ramas", "Recoge 3 ramas (E)"],
	["fogata", "Haz una fogata (F)"],
	["beber", "Bebe agua en una charca, río o lago"],
	["hacha", "Fabrica un hacha (C)"],
	["talar", "Tala una acacia"],
	["cocinar", "Cocina algo en la fogata"],
	["cazar", "Caza una gacela"],
	["pescar", "Pesca un pez (arpón, G)"],
	["refugio", "Construye un refugio (R)"],
	["dormir", "Duerme en tu refugio"],
	["mochila", "Haz una mochila (P)"],
	["kilimanjaro", "Sube a la cima del Kilimanjaro"],
	["dia4", "Sobrevive hasta el día 4"],
]
## Cuántos objetivos pendientes se ven a la vez en el recuadro.
const SHOWN: int = 3

@onready var player: CharacterBody3D = owner
@onready var inventory = owner.get_node("Inventory")
@onready var hud = owner.get_node("HUD")

var done: Dictionary = {}  # id -> true
var rescued: bool = false
var expanded: bool = true
var day_night: Node
var check_time: float = 0.0
var rescue_announced: bool = false

var panel: PanelContainer
var content: VBoxContainer
var victory: CanvasLayer


func _ready() -> void:
	add_to_group("objectives")
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		expanded = config.get_value("hud", "objectives_open", true)
	# Los controles (H) y los objetivos no caben abiertos a la vez: al empezar,
	# se queda abierta la misión y se pliegan los controles.
	if expanded and hud.controls_expanded:
		hud.toggle_controls.call_deferred()
		expanded = true
	_build_panel()
	_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("objectives"):
		set_expanded(not expanded)
		# Al abrir los objetivos se pliegan los controles (no caben los dos).
		if expanded and hud.controls_expanded:
			hud.toggle_controls()
			expanded = true
			_rebuild()


## Abre o pliega el recuadro (se recuerda para la próxima vez).
func set_expanded(value: bool) -> void:
	expanded = value
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("hud", "objectives_open", expanded)
	config.save(SETTINGS_PATH)
	_rebuild()


func _process(delta: float) -> void:
	# Se comprueba una vez por segundo: casi no gasta nada.
	check_time -= delta
	if check_time > 0.0:
		return
	check_time = 1.0
	if day_night == null:
		day_night = get_tree().get_first_node_in_group("day_night")
		if day_night == null:
			return

	if inventory.get_amount("rama") >= 3:
		complete("ramas")
	if not get_tree().get_nodes_in_group("fire_pit").is_empty():
		complete("fogata")
	if inventory.get_amount("hacha") > 0:
		complete("hacha")
	if not get_tree().get_nodes_in_group("shelter").is_empty():
		complete("refugio")
	if inventory.has_backpack():
		complete("mochila")
	if player.global_position.distance_to(KILIMANJARO_TOP) < 15.0:
		complete("kilimanjaro")
	if day_night.total_hours >= 3 * 24.0:
		complete("dia4")

	# Aviso cuando llega la extracción.
	if rescue_ready() and not rescue_announced and not rescued:
		rescue_announced = true
		hud.show_message("¡Llegó la extracción! Ve al punto verde del mapa (M)")
	_rebuild()


## Marca un objetivo como cumplido (si no lo estaba ya).
func complete(id: String) -> void:
	if done.has(id) or _text_of(id) == "":
		return
	done[id] = true
	_rebuild()
	# El aviso sale un momento después, para no tapar el mensaje de la acción
	# (por ejemplo "Bebiste agua del río").
	var text: String = "Objetivo cumplido: %s  (%d/%d)" % [_text_of(id), done.size(), LIST.size()]
	get_tree().create_timer(1.5).timeout.connect(hud.show_message.bind(text))


## ¿Ya llegó el helicóptero de la extracción?
func rescue_ready() -> bool:
	return day_night != null and day_night.total_hours >= RESCUE_HOURS


## Días que te quedan para la extracción (redondeado hacia arriba).
func days_left() -> int:
	if day_night == null:
		return DAYS_TO_SURVIVE
	return maxi(0, ceili((RESCUE_HOURS - day_night.total_hours) / 24.0))


func _text_of(id: String) -> String:
	for objective in LIST:
		if objective[0] == id:
			return objective[1]
	return ""


# --- Recuadro de objetivos (abajo a la izquierda, encima de las barras) ---

func _build_panel() -> void:
	panel = PanelContainer.new()
	hud.add_child(panel)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.06, 0.65)
	style.border_color = Color(0.55, 0.65, 0.35)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 0)
	panel.add_child(content)


func _rebuild() -> void:
	if content == null:
		return
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	if not expanded:
		_add("[O] Misión y objetivos (%d/%d)" % [done.size(), LIST.size()], 13, Color(1, 1, 1, 0.85))
	else:
		_add("Misión: sobrevive %d días y llega a la extracción" % DAYS_TO_SURVIVE, 14, Color(1.0, 0.85, 0.3))
		if rescued:
			_add("  ¡Completada! Te rescataron", 12, Color(0.55, 0.9, 0.5))
		elif rescue_ready():
			_add("  ¡El helicóptero espera! Punto verde del mapa (M)", 12, Color(0.55, 0.9, 0.5))
		else:
			var day: int = 1 if day_night == null else int(day_night.total_hours / 24.0) + 1
			_add("  Día %d de %d · llega el día %d a las 7:00 (faltan %d)" % [
				mini(day, DAYS_TO_SURVIVE), DAYS_TO_SURVIVE, DAYS_TO_SURVIVE + 1, days_left()], 12, Color(1, 1, 1, 0.8))
		_add("Objetivos %d/%d   [O] Ocultar" % [done.size(), LIST.size()], 13, Color(0.75, 0.9, 0.55))
		var shown: int = 0
		for objective in LIST:
			if done.has(objective[0]):
				continue
			_add("  · " + objective[1], 12, Color(1, 1, 1, 0.85))
			shown += 1
			if shown >= SHOWN:
				break
		if shown == 0:
			_add("  ¡Todos cumplidos!", 12, Color(0.55, 0.9, 0.5))
	_fit.call_deferred()


## Pegado a la izquierda, justo encima de las barras de vida, hambre...
func _fit() -> void:
	var needed: Vector2 = panel.get_combined_minimum_size()
	panel.anchor_left = 0.0
	panel.anchor_right = 0.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 16.0
	panel.offset_right = 16.0 + needed.x
	panel.offset_bottom = -178.0
	panel.offset_top = -178.0 - needed.y


func _add(text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	content.add_child(label)
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color.BLACK)


# --- Rescate (fin de la misión) ---

## La llama el helicóptero (extraction.gd) al subir con E.
func finish_mission() -> void:
	rescued = true
	_rebuild()
	_show_victory()


func _show_victory() -> void:
	victory = CanvasLayer.new()
	victory.layer = 20  # Encima de todo, también del menú de pausa.
	victory.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(victory)

	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.75)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory.add_child(background)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	victory.add_child(box)

	var days: int = int(day_night.total_hours / 24.0) + 1
	_victory_label(box, "¡Te rescataron!", 44, Color(1.0, 0.85, 0.3))
	_victory_label(box, "Sobreviviste %d días en África como %s." % [days, Personajes.actual()["nombre"]], 20, Color.WHITE)
	_victory_label(box, "Objetivos cumplidos: %d de %d" % [done.size(), LIST.size()], 18, Color(0.75, 0.9, 0.55))

	var keep := Button.new()
	keep.text = "Seguir explorando"
	keep.custom_minimum_size = Vector2(280, 44)
	keep.pressed.connect(_on_keep_playing)
	box.add_child(keep)
	var title := Button.new()
	title.text = "Volver al inicio"
	title.custom_minimum_size = Vector2(280, 44)
	title.pressed.connect(_on_back_to_title)
	box.add_child(title)

	# La partida se guarda ya rescatada.
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	keep.grab_focus()
	var save_game = get_tree().current_scene.get_node_or_null("SaveGame")
	if save_game != null:
		save_game.save_game(false)


func _victory_label(box: Control, text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	box.add_child(label)


func _on_keep_playing() -> void:
	victory.queue_free()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_back_to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Levels/title_screen.tscn")


# --- Guardar y cargar (lo usa SaveGame) ---

func get_save_data() -> Dictionary:
	return { "done": done.keys(), "rescued": rescued }


func set_save_data(data: Dictionary) -> void:
	done.clear()
	for id in data.get("done", []):
		done[id] = true
	rescued = data.get("rescued", false)
	rescue_announced = rescued
	_rebuild()
