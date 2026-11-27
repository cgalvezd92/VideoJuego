extends CanvasLayer
## Menú de pausa: Esc lo abre y lo cierra; el juego se detiene (Etapa 13).
## Va en el nodo "PauseMenu" (CanvasLayer), hijo de Main (en main.tscn).
## Su "Process Mode" es "Always" para que funcione con el juego en pausa.

const GameSettings = preload("res://Levels/game_settings.gd")

@onready var save_game = $"../SaveGame"
@onready var hud = $"../Player/HUD"

var panel: Control
var status_label: Label
var controls_button: Button
var fullscreen_button: Button
var new_game_button: Button
var continue_button: Button
var confirm_new_game: bool = false
## Ajustes (Etapa 52).
var main_column: VBoxContainer
var settings_column: VBoxContainer
var quality_buttons: Array[Button] = []
var sensitivity_label: Label
var brightness_label: Label
var fps_label: Label
var fps_time: float = 0.0


func _ready() -> void:
	layer = 10  # Por encima del HUD.
	GameSettings.load_settings()
	_build_menu()
	_build_settings()
	panel.visible = false
	# Contador de FPS arriba a la izquierda (si está activado en Ajustes).
	fps_label = Label.new()
	add_child(fps_label)
	fps_label.position = Vector2(16, 36)
	fps_label.add_theme_font_size_override("font_size", 14)
	fps_label.add_theme_constant_override("outline_size", 4)
	fps_label.add_theme_color_override("font_outline_color", Color.BLACK)
	fps_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	fps_label.visible = GameSettings.show_fps
	# Los ajustes se aplican cuando el mapa y la hierba ya están listos.
	for i in 3:
		await get_tree().physics_frame
	GameSettings.apply(get_tree())


func _process(delta: float) -> void:
	if not fps_label.visible:
		return
	fps_time -= delta
	if fps_time <= 0.0:
		fps_time = 0.5
		fps_label.text = "%d FPS" % Engine.get_frames_per_second()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	panel.visible = paused
	main_column.visible = true
	settings_column.visible = false
	hud.visible = not paused  # El HUD se oculta para que no se mezcle con el menú.
	status_label.text = ""
	_reset_new_game_button()
	_update_controls_text()
	_update_fullscreen_text(_is_fullscreen())
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
	hud.toggle_controls()  # Igual que la tecla H.
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


func _on_toggle_fullscreen() -> void:
	var fullscreen: bool = not _is_fullscreen()
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Se recuerda para la próxima vez que abras el juego.
	var config := ConfigFile.new()
	config.load("user://ajustes.cfg")
	config.set_value("display", "fullscreen", fullscreen)
	config.save("user://ajustes.cfg")
	_update_fullscreen_text(fullscreen)


func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func _update_fullscreen_text(fullscreen: bool) -> void:
	fullscreen_button.text = "Pantalla completa: Sí" if fullscreen else "Pantalla completa: No"


func _update_controls_text() -> void:
	if hud.controls_expanded:
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
	main_column = column
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
	fullscreen_button = _add_button(column, "Pantalla completa: Sí", _on_toggle_fullscreen)
	_add_button(column, "Ajustes (calidad, ratón, brillo)", _on_open_settings)
	_add_button(column, "Volver al inicio", _on_title)
	_add_button(column, "Guardar y salir", _on_quit)

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
	return button




# --- Ajustes (Etapa 52) ---

func _on_open_settings() -> void:
	main_column.visible = false
	settings_column.visible = true
	_refresh_settings()


func _on_close_settings() -> void:
	GameSettings.save_settings()
	settings_column.visible = false
	main_column.visible = true


func _build_settings() -> void:
	settings_column = VBoxContainer.new()
	panel.add_child(settings_column)
	settings_column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	settings_column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	settings_column.grow_vertical = Control.GROW_DIRECTION_BOTH
	settings_column.add_theme_constant_override("separation", 12)
	settings_column.visible = false

	var title := Label.new()
	settings_column.add_child(title)
	title.text = "Ajustes"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)

	settings_column.add_child(_small_label("Calidad gráfica"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	settings_column.add_child(row)
	var group := ButtonGroup.new()
	for i in GameSettings.QUALITY.size():
		var b := Button.new()
		b.text = GameSettings.QUALITY[i]["nombre"]
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(110, 42)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_quality.bind(i))
		row.add_child(b)
		quality_buttons.append(b)
	var help := _small_label("Baja: menos distancia y hierba e imagen a menor resolución (más fluido).\nAlta: más distancia de dibujo y sombras del sol.")
	help.add_theme_font_size_override("font_size", 13)
	help.modulate = Color(1, 1, 1, 0.75)
	settings_column.add_child(help)

	sensitivity_label = _small_label("")
	settings_column.add_child(sensitivity_label)
	settings_column.add_child(_slider(0.3, 2.5, GameSettings.sensitivity, _on_sensitivity))
	brightness_label = _small_label("")
	settings_column.add_child(brightness_label)
	settings_column.add_child(_slider(0.6, 1.6, GameSettings.brightness, _on_brightness))

	var fps := CheckButton.new()
	fps.text = "Mostrar FPS (imágenes por segundo)"
	fps.button_pressed = GameSettings.show_fps
	fps.add_theme_font_size_override("font_size", 18)
	fps.toggled.connect(_on_fps)
	settings_column.add_child(fps)

	_add_button(settings_column, "Volver", _on_close_settings)


func _refresh_settings() -> void:
	for i in quality_buttons.size():
		quality_buttons[i].button_pressed = i == GameSettings.quality
	sensitivity_label.text = "Sensibilidad del ratón: %d %%" % roundi(GameSettings.sensitivity * 100.0)
	brightness_label.text = "Brillo: %d %%" % roundi(GameSettings.brightness * 100.0)


func _on_quality(index: int) -> void:
	GameSettings.quality = index
	GameSettings.apply(get_tree())
	_refresh_settings()


func _on_sensitivity(value: float) -> void:
	GameSettings.sensitivity = value
	GameSettings.apply(get_tree())
	_refresh_settings()


func _on_brightness(value: float) -> void:
	GameSettings.brightness = value
	GameSettings.apply(get_tree())
	_refresh_settings()


func _on_fps(on: bool) -> void:
	GameSettings.show_fps = on
	fps_label.visible = on


func _small_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	return label


func _slider(min_value: float, max_value: float, value: float, action: Callable) -> HSlider:
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(340, 24)
	slider.value_changed.connect(action)
	return slider
