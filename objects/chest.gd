extends StaticBody3D
## Cofre de madera (Etapa 41): guarda hasta 12 montones de objetos.
## Míralo y pulsa E: se abre una ventana con el cofre arriba y tu inventario
## abajo. Haz clic en un objeto para pasarlo de un lado al otro.
## E, Esc o el botón "Cerrar" lo cierran. El juego se pausa mientras está abierto.
##
## No tiene escena: lo crea Crafting (tecla J) o SaveGame al cargar.

const HeldItems = preload("res://Player/held_items.gd")
const ICONS_PATH: String = "res://iconos/%s.png"
const SLOT_COUNT: int = 12

## Cada casilla: null o { "id", "name", "amount" } (igual que el inventario).
var slots: Array = []

var ui: CanvasLayer
var chest_grid: GridContainer
var inventory_grid: GridContainer
var player: Node
var closed_at: int = 0


func _ready() -> void:
	add_to_group("chest")
	if slots.size() != SLOT_COUNT:
		slots.resize(SLOT_COUNT)
	_build_model()


func get_prompt() -> String:
	var used: int = SLOT_COUNT - slots.count(null)
	return "[E] Abrir el cofre (%d/%d)" % [used, SLOT_COUNT]


## La llama el Interactor.
func interact(who: Node) -> String:
	# Evita que la misma E que lo cerró lo vuelva a abrir.
	if Time.get_ticks_msec() - closed_at < 300:
		return ""
	player = who
	_open()
	return ""


# --- Ventana del cofre ---

func _open() -> void:
	ui = CanvasLayer.new()
	ui.layer = 15
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)

	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.55)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(background)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.1, 0.07, 0.95)
	style.border_color = Color(0.6, 0.45, 0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	ui.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	column.add_child(_label("Cofre", 22, Color(1.0, 0.88, 0.65)))
	chest_grid = GridContainer.new()
	chest_grid.columns = 6
	column.add_child(chest_grid)
	column.add_child(_label("Tu inventario", 18, Color(1.0, 0.88, 0.65)))
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 6
	column.add_child(inventory_grid)
	column.add_child(_label("Clic en un objeto para pasarlo al otro lado  ·  [E] o [Esc] cerrar", 13, Color(1, 1, 1, 0.7)))
	var close := Button.new()
	close.text = "Cerrar"
	close.pressed.connect(_close)
	column.add_child(close)

	# El script de entrada va en un nodo aparte para recibir E y Esc.
	var keys := Node.new()
	keys.set_script(preload("res://objects/chest_keys.gd"))
	keys.chest = self
	ui.add_child(keys)

	_refresh()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close() -> void:
	if ui == null:
		return
	ui.queue_free()
	ui = null
	closed_at = Time.get_ticks_msec()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh() -> void:
	var inventory = player.get_node("Inventory")
	for grid in [chest_grid, inventory_grid]:
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
	for i in SLOT_COUNT:
		chest_grid.add_child(_slot_button(slots[i], _take.bind(i)))
	for i in inventory.SLOT_COUNT:
		inventory_grid.add_child(_slot_button(inventory.slots[i], _store.bind(i)))


## Del cofre al inventario.
func _take(index: int) -> void:
	var item = slots[index]
	if item == null:
		return
	if player.get_node("Inventory").add_item(item.id, item.name, item.amount) == -1:
		player.get_node("HUD").show_message("Tu inventario está lleno")
		return
	slots[index] = null
	_refresh()


## Del inventario al cofre (se apila si ya hay de ese objeto).
func _store(index: int) -> void:
	var inventory = player.get_node("Inventory")
	var item = inventory.slots[index]
	if item == null:
		return
	var target: int = -1
	for i in SLOT_COUNT:
		if slots[i] != null and slots[i].id == item.id:
			target = i
	if target == -1:
		target = slots.find(null)
	if target == -1:
		player.get_node("HUD").show_message("El cofre está lleno")
		return
	if slots[target] == null:
		slots[target] = { "id": item.id, "name": item.name, "amount": 0 }
	slots[target].amount += item.amount
	inventory.remove_item(item.id, item.amount)
	_refresh()


func _slot_button(item, action: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(64, 64)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	if item == null:
		return button
	button.tooltip_text = item.name
	var path: String = ICONS_PATH % item.id
	if ResourceLoader.exists(path):
		var icon := TextureRect.new()
		icon.texture = load(path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 6
		icon.offset_top = 6
		icon.offset_right = -6
		icon.offset_bottom = -6
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
	else:
		button.text = item.name
		button.clip_text = true
	var count := _label("x%d" % item.amount, 13, Color.WHITE)
	count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	count.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	count.grow_vertical = Control.GROW_DIRECTION_BEGIN
	count.offset_right = -4
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(count)
	return button


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	return label


# --- Modelo (figuras sencillas) ---

func _build_model() -> void:
	var wood := Color("#7a5530")
	var dark := Color("#4a3320")
	HeldItems._part(self, HeldItems._box(1.0, 0.5, 0.6), wood, Vector3(0, 0.25, 0))
	HeldItems._part(self, HeldItems._box(1.04, 0.14, 0.64), dark, Vector3(0, 0.56, 0))
	HeldItems._part(self, HeldItems._box(0.08, 0.52, 0.62), dark, Vector3(-0.42, 0.26, 0))
	HeldItems._part(self, HeldItems._box(0.08, 0.52, 0.62), dark, Vector3(0.42, 0.26, 0))
	HeldItems._part(self, HeldItems._box(0.12, 0.12, 0.04), Color("#8f8a80"), Vector3(0, 0.45, 0.32))
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.04, 0.64, 0.64)
	shape.shape = box
	shape.position = Vector3(0, 0.32, 0)
	add_child(shape)
