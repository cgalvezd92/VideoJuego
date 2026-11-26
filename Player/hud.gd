extends CanvasLayer
## Interfaz: mira central, aviso de interacción y mensajes.
## Va en el nodo "HUD", hijo de Player.

var prompt_label: Label
var message_label: Label
var hint_label: Label
var message_time: float = 0.0

const CONTROLS_TEXT: String = """WASD  Moverse
Shift  Correr
Espacio  Saltar
E  Recoger
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
