extends CanvasLayer
## Interfaz: mira central, aviso de interacción y mensajes.
## Va en el nodo "HUD", hijo de Player.

var prompt_label: Label
var message_label: Label
var hint_label: Label
var health_bar: ProgressBar
var hunger_bar: ProgressBar
var thirst_bar: ProgressBar
var health_title: Label
var message_time: float = 0.0

const CONTROLS_TEXT: String = """WASD  Moverse
Shift  Correr
Espacio  Saltar
E  Recoger / Beber / Comer
F  Hacer fogata
1-8 / Rueda  Elegir casilla
Esc  Soltar el mouse"""


func _ready() -> void:
	var crosshair := _create_label(0.0)
	crosshair.text = "+"
	prompt_label = _create_label(40.0)
	message_label = _create_label(80.0)

	# Aviso encima de la barra de casillas (por ejemplo, "[F] Hacer fogata").
	hint_label = _create_label(0.0)
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	hint_label.offset_bottom = -104.0
	hint_label.add_theme_font_size_override("font_size", 18)

	# Lista de controles, pequeña, arriba a la izquierda.
	var controls := _create_label(0.0)
	controls.text = CONTROLS_TEXT
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	controls.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	controls.offset_left = 16.0
	controls.offset_top = 12.0
	controls.add_theme_font_size_override("font_size", 14)
	controls.add_theme_constant_override("outline_size", 4)
	controls.modulate = Color(1, 1, 1, 0.8)

	_build_stats()


func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message_label.text = ""


func set_prompt(new_text: String) -> void:
	prompt_label.text = new_text


## Aviso de acción encima de la barra. Si "available" es false se ve atenuado.
func set_hint(new_text: String, available: bool) -> void:
	hint_label.text = new_text
	if available:
		hint_label.modulate = Color(1.0, 0.85, 0.3)
	else:
		hint_label.modulate = Color(1, 1, 1, 0.55)


## La llama Survival 4 veces por segundo para actualizar las barras.
func set_stats(health: float, hunger: float, thirst: float, max_value: float, near_fire: bool) -> void:
	health_bar.max_value = max_value
	hunger_bar.max_value = max_value
	thirst_bar.max_value = max_value
	health_bar.value = health
	hunger_bar.value = hunger
	thirst_bar.value = thirst
	health_title.text = "Vida (fogata)" if near_fire else "Vida"


func show_message(new_text: String) -> void:
	message_label.text = new_text
	message_time = 2.0


func _create_label(offset_y: float) -> Label:
	# Crea un texto centrado en la pantalla, desplazado hacia abajo.
	var label := Label.new()
	add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.offset_top = offset_y
	label.offset_bottom = offset_y
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	return label


func _build_stats() -> void:
	# Tres barras abajo a la izquierda: vida, hambre y sed.
	var column := VBoxContainer.new()
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	column.offset_left = 16.0
	column.offset_bottom = -20.0
	column.add_theme_constant_override("separation", 2)

	health_title = _add_stat_title(column, "Vida")
	health_bar = _add_stat_bar(column, Color(0.85, 0.2, 0.2))
	_add_stat_title(column, "Hambre")
	hunger_bar = _add_stat_bar(column, Color(0.9, 0.55, 0.15))
	_add_stat_title(column, "Sed")
	thirst_bar = _add_stat_bar(column, Color(0.2, 0.55, 0.95))


func _add_stat_title(parent: Control, text: String) -> Label:
	var label := Label.new()
	parent.add_child(label)
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	return label


func _add_stat_bar(parent: Control, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	parent.add_child(bar)
	bar.custom_minimum_size = Vector2(200, 14)
	bar.show_percentage = false
	bar.value = 100.0

	var background := StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.5)
	background.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", background)

	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	return bar
