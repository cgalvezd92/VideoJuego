extends CanvasLayer
## Barra de inventario con casillas, abajo al centro (Etapa 3).
## Teclas 1-8 (y 9, 0 con la mochila) o rueda del mouse para elegir casilla.
## Va en el nodo "InventoryUI", hijo de Player.
##
## Cada objeto se ve con su dibujo (Etapa 40): res://iconos/<id>.png.
## Si un objeto no tiene dibujo, se ve su nombre. El nombre del objeto
## elegido aparece encima de la barra.

const ICONS_PATH: String = "res://iconos/%s.png"

## Tamaño de cada casilla: más pequeñas con la mochila para que quepan 12.
const SLOT_SIZE: float = 72.0
const SMALL_SLOT_SIZE: float = 60.0

@onready var inventory = owner.get_node("Inventory")

# Por cada casilla guardamos su panel y sus textos para actualizarlos.
var slot_panels: Array[Panel] = []
var name_labels: Array[Label] = []
var count_labels: Array[Label] = []
var icon_rects: Array[TextureRect] = []
## Dibujos ya cargados (id -> Texture2D, o null si no hay).
var icons: Dictionary = {}
var selected_label: Label

var style_normal: StyleBoxFlat
var style_selected: StyleBoxFlat
var bar: HBoxContainer


func _ready() -> void:
	style_normal = _make_style(Color(1, 1, 1, 0.35), 2)
	style_selected = _make_style(Color(1.0, 0.85, 0.3), 3)
	_build_bar()
	inventory.changed.connect(_refresh_items)
	inventory.selection_changed.connect(_refresh_selection)
	inventory.resized.connect(_rebuild)
	_refresh_items()
	_refresh_selection()


func _unhandled_input(event: InputEvent) -> void:
	# Teclas 1 a 8: elegir casilla directamente.
	if event is InputEventKey and event.pressed and not event.echo:
		var number: int = event.physical_keycode - KEY_1
		if event.physical_keycode == KEY_0:
			number = 9  # La tecla 0 es la casilla 10.
		if number >= 0 and number < mini(inventory.SLOT_COUNT, 10):
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
			icon_rects[i].texture = null
		else:
			var icon: Texture2D = _icon(item.id)
			icon_rects[i].texture = icon
			# Con dibujo no hace falta el nombre dentro de la casilla.
			name_labels[i].text = "" if icon != null else item.name
			count_labels[i].text = "x%d" % item.amount
	_refresh_selected_name()


func _refresh_selection() -> void:
	for i in inventory.SLOT_COUNT:
		var style: StyleBoxFlat = style_selected if i == inventory.selected else style_normal
		slot_panels[i].add_theme_stylebox_override("panel", style)
	_refresh_selected_name()


## Nombre del objeto elegido, encima de la barra.
func _refresh_selected_name() -> void:
	if selected_label == null:
		return
	var item = inventory.get_selected_item()
	selected_label.text = "" if item == null else item.name


## Carga el dibujo de un objeto una sola vez (luego se reutiliza).
func _icon(id: String) -> Texture2D:
	if not icons.has(id):
		var path: String = ICONS_PATH % id
		icons[id] = load(path) if ResourceLoader.exists(path) else null
	return icons[id]


## Vuelve a crear la barra (cuando la mochila añade casillas).
func _rebuild() -> void:
	bar.queue_free()
	slot_panels.clear()
	name_labels.clear()
	count_labels.clear()
	icon_rects.clear()
	selected_label.queue_free()
	_build_bar()
	_refresh_items()
	_refresh_selection()


func _build_bar() -> void:
	# Fila de casillas pegada abajo y centrada.
	var size: float = SLOT_SIZE if inventory.SLOT_COUNT <= 8 else SMALL_SLOT_SIZE
	bar = HBoxContainer.new()
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
		panel.custom_minimum_size = Vector2(size, size)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Dibujo del objeto (Etapa 40), detrás de los números.
		var icon := TextureRect.new()
		panel.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var margin: float = size * 0.1
		icon.offset_left = margin
		icon.offset_top = margin
		icon.offset_right = -margin
		icon.offset_bottom = -margin
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rects.append(icon)

		# Número de la casilla (arriba a la izquierda).
		var key_text: String = str(i + 1) if i < 9 else ("0" if i == 9 else "")
		var number := _add_label(panel, key_text, 12, Control.PRESET_TOP_LEFT)
		number.position = Vector2(5, 2)
		number.modulate = Color(1, 1, 1, 0.6)

		# Nombre del objeto (centro).
		var item_name := _add_label(panel, "", 14, Control.PRESET_FULL_RECT)
		item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		# Nombres largos ("Carne cocida") pasan a dos líneas.
		item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_labels.append(item_name)

		# Cantidad (abajo a la derecha).
		var count := _add_label(panel, "", 13, Control.PRESET_FULL_RECT)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count.offset_right = -6.0
		count.offset_bottom = -3.0
		count_labels.append(count)

		slot_panels.append(panel)

	# Nombre del objeto elegido, justo encima de la barra.
	selected_label = Label.new()
	add_child(selected_label)
	selected_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	selected_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	selected_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	selected_label.offset_bottom = -20.0 - size - 4.0
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_label.add_theme_font_size_override("font_size", 15)
	selected_label.add_theme_constant_override("outline_size", 4)
	selected_label.add_theme_color_override("font_outline_color", Color.BLACK)


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
