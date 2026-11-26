extends CanvasLayer
## Ventana del inventario: se abre y se cierra con Tab (Etapa 3).
## Va en el nodo "InventoryUI", hijo de Player.

@onready var inventory = owner.get_node("Inventory")
@onready var hud: CanvasLayer = owner.get_node("HUD")

var is_open: bool = false
var panel: PanelContainer
var list_label: Label


func _ready() -> void:
	_build_window()
	inventory.changed.connect(_refresh)
	_refresh()
	panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_set_open(not is_open)
		get_viewport().set_input_as_handled()
	elif is_open and event.is_action_pressed("ui_cancel"):
		# Esc también cierra el inventario.
		_set_open(false)
		get_viewport().set_input_as_handled()


func _set_open(open: bool) -> void:
	is_open = open
	panel.visible = open
	# La mira y los avisos se ocultan para que no tapen la ventana.
	hud.visible = not open
	# Con el inventario abierto se ve el mouse y la cámara no gira.
	if open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _refresh() -> void:
	# Reescribe la lista. Solo se llama cuando el inventario cambia.
	if inventory.amounts.is_empty():
		list_label.text = "(vacío)"
		return

	var lines: PackedStringArray = []
	for id in inventory.amounts:
		lines.append("%s  x%d" % [inventory.names[id], inventory.amounts[id]])
	list_label.text = "\n".join(lines)


func _build_window() -> void:
	# Crea la ventana por código: un panel centrado con un título y la lista.
	panel = PanelContainer.new()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(320, 0)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var margin := MarginContainer.new()
	panel.add_child(margin)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)

	var column := VBoxContainer.new()
	margin.add_child(column)
	column.add_theme_constant_override("separation", 12)

	var title := Label.new()
	column.add_child(title)
	title.text = "Inventario"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)

	list_label = Label.new()
	column.add_child(list_label)
	list_label.add_theme_font_size_override("font_size", 20)

	var hint := Label.new()
	column.add_child(hint)
	hint.text = "[Tab] Cerrar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
