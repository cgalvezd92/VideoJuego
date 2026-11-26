extends CanvasLayer
## Menú de pausa: Esc lo abre y lo cierra; el juego se detiene (Etapa 13).
## Va en el nodo "PauseMenu" (CanvasLayer), hijo de Main (en main.tscn).
## Su "Process Mode" es "Always" para que funcione con el juego en pausa.

@onready var save_game = $"../SaveGame"
@onready var hud = $"../Player/HUD"

var panel: Control
var status_label: Label
var controls_button: Button
var new_game_button: Button
var continue_button: Button
var confirm_new_game: bool = false


func _ready() -> void:
	layer = 10  # Por encima del HUD.
	_build_menu()
	panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	panel.visible = paused
	hud.visible = not paused  # El HUD se oculta para que no se mezcle con el menú.
	status_label.text = ""
	_reset_new_game_button()
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		continue_button.grab_focus()  # Para usarlo también con flechas y Enter.
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# --- Botones ---

func _on_continue() -> void:
	_set_paused(false)


func _on_save() -> void:
	save_game.save_game(false)
	status_label.text = "Partida guardada"


func _on_load() -> void:
	if not save_game.has_save():
		status_label.text = "No hay ninguna partida guardada"
		return
	get_tree().paused = false
	save_game.load_last()


func _on_new_game() -> void:
	# Primer clic: pide confirmación. Segundo clic: empieza de cero.
	if not confirm_new_game:
		confirm_new_game = true
		new_game_button.text = "¿Seguro? Se borrará el guardado"
		return
	get_tree().paused = false
	save_game.new_game()


func _on_toggle_controls() -> void:
	hud.controls_label.visible = not hud.controls_label.visible
	_update_controls_text()


func _on_title() -> void:
	# Guarda y vuelve a la pantalla de inicio.
	save_game.save_game(false)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Levels/title_screen.tscn")


func _on_quit() -> void:
	save_game.save_game(false)
	get_tree().quit()


func _reset_new_game_button() -> void:
	confirm_new_game = false
	new_game_button.text = "Nueva partida"


func _update_controls_text() -> void:
	if hud.controls_label.visible:
		controls_button.text = "Ocultar controles"
	else:
		controls_button.text = "Mostrar controles"


# --- Construcción del menú (por código, como el HUD) ---

func _build_menu() -> void:
	# Fondo oscuro que cubre toda la pantalla.
	var background := ColorRect.new()
	add_child(background)
	background.color = Color(0, 0, 0, 0.6)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = background

	var column := VBoxContainer.new()
	background.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 10)

	var title := Label.new()
	column.add_child(title)
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)

	continue_button = _add_button(column, "Continuar", _on_continue)
	_add_button(column, "Guardar partida", _on_save)
	_add_button(column, "Cargar último guardado", _on_load)
	new_game_button = _add_button(column, "Nueva partida", _on_new_game)
	controls_button = _add_button(column, "Ocultar controles", _on_toggle_controls)
	_add_button(column, "Volver al inicio", _on_title)
	_add_button(column, "Guardar y salir", _on_quit)

	# Volumen: deslizador de 0 a 100 (se recuerda en user://ajustes.cfg).
	var volume_row := HBoxContainer.new()
	column.add_child(volume_row)
	volume_row.add_theme_constant_override("separation", 12)
	var volume_label := Label.new()
	volume_row.add_child(volume_label)
	volume_label.text = "Volumen"
	volume_label.add_theme_font_size_override("font_size", 20)
	var slider := HSlider.new()
	volume_row.add_child(slider)
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = Sounds.volume * 100.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.value_changed.connect(_on_volume_changed)

	status_label = Label.new()
	column.add_child(status_label)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.custom_minimum_size = Vector2(0, 30)
	status_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.text = text
	button.custom_minimum_size = Vector2(340, 46)
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(action)
	button.pressed.connect(Sounds.play.bind("click", -4.0, 0.0))
	return button


func _on_volume_changed(value: float) -> void:
	Sounds.set_volume(value / 100.0)
	Sounds.play("click", -4.0, 0.0)
