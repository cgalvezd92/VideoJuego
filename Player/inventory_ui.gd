extends CanvasLayer
## Barra de inventario con casillas, abajo al centro (Etapa 3).
## Teclas 1-8 o rueda del mouse para elegir casilla.
## Va en el nodo "InventoryUI", hijo de Player.

const SLOT_SIZE: float = 72.0

@onready var inventory = owner.get_node("Inventory")

# Por cada casilla guardamos su panel y sus textos para actualizarlos.
var slot_panels: Array[Panel] = []
var name_labels: Array[Label] = []
var count_labels: Array[Label] = []

var style_normal: StyleBoxFlat
var style_selected: StyleBoxFlat


func _ready() -> void:
	style_normal = _make_style(Color(1, 1, 1, 0.35), 2)
	style_selected = _make_style(Color(1.0, 0.85, 0.3), 3)
	_build_bar()
	inventory.changed.connect(_refresh_items)
	inventory.selection_changed.connect(_refresh_selection)
	_refresh_items()
	_refresh_selection()


func _unhandled_input(event: InputEvent) -> void:
	# Teclas 1 a 8: elegir casilla directamente.
	if event is InputEventKey and event.pressed and not event.echo:
		var number: int = event.physical_keycode - KEY_1
		if number >= 0 and number < inventory.SLOT_COUNT:
			inventory.select(number)
	# Rueda del mouse: casilla siguiente o anterior.
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			inventory.select(inventory.selected + 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			inventory.select(inventory.selected - 1)


func _refresh_items() -> void:
	# Solo se llama cuando el inventario cambia, no en cada fotograma.
	for i in inventory.SLOT_COUNT:
		var item = inventory.slots[i]
		if item == null:
			name_labels[i].text = ""
			count_labels[i].text = ""
		else:
			name_labels[i].text = item.name
			count_labels[i].text = "x%d" % item.amount


func _refresh_selection() -> void:
	for i in inventory.SLOT_COUNT:
		var style: StyleBoxFlat = style_selected if i == inventory.selected else style_normal
		slot_panels[i].add_theme_stylebox_override("panel", style)


func _build_bar() -> void:
	# Fila de casillas pegada abajo y centrada.
	var bar := HBoxContainer.new()
	add_child(bar)
	bar.add_theme_constant_override("separation", 6)
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -20.0
	# El mouse atraviesa la barra (no bloquea clics).
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for i in inventory.SLOT_COUNT:
		var panel := Panel.new()
		bar.add_child(panel)
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Número de la casilla (arriba a la izquierda).
		var number := _add_label(panel, str(i + 1), 12, Control.PRESET_TOP_LEFT)
		number.position = Vector2(5, 2)
		number.modulate = Color(1, 1, 1, 0.6)

		# Nombre del objeto (centro).
		var item_name := _add_label(panel, "", 14, Control.PRESET_FULL_RECT)
		item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_labels.append(item_name)

		# Cantidad (abajo a la derecha).
		var count := _add_label(panel, "", 13, Control.PRESET_FULL_RECT)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count.offset_right = -6.0
		count.offset_bottom = -3.0
		count_labels.append(count)

		slot_panels.append(panel)


func _add_label(parent: Control, text: String, size: int, preset: int) -> Label:
	var label := Label.new()
	parent.add_child(label)
	label.set_anchors_and_offsets_preset(preset)
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	return label


func _make_style(border_color: Color, border_width: int) -> StyleBoxFlat:
	# Fondo oscuro semitransparente con borde y esquinas redondeadas.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.45)
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	return style
