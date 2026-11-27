extends CanvasLayer
## Interfaz: mira central, aviso de interacción y mensajes.
## Va en el nodo "HUD", hijo de Player.

var prompt_label: Label
var message_label: Label
## Libro de fabricación a la derecha (Etapa 23).
var recipe_book: PanelContainer
var clock_label: Label
## Lista de controles de la izquierda: se pliega y despliega con H.
var controls_label: Label
var controls_expanded: bool = true
const SETTINGS_PATH: String = "user://ajustes.cfg"
var health_bar: ProgressBar
var hunger_bar: ProgressBar
var thirst_bar: ProgressBar
var stamina_bar: ProgressBar
var stamina_title: Label
var thirst_title: Label
var climate_hot: bool = false
var climate_cold: bool = false
var stamina_exhausted: bool = false
var health_title: Label
var message_time: float = 0.0

const CONTROLS_TEXT: String = """WASD  Moverse
Shift  Correr
Ctrl  Agacharse (acercarse a las gacelas)
Espacio  Saltar
E  Recoger / Beber / Comer
F  Hacer fogata
C  Hacer hacha
R  Hacer refugio
J / N  Hacer cofre / cama de pieles
X / K  Hacer flechas / arco
L / G  Hacer lanza / arpón
P  Hacer mochila
V  Hacer vendas
M  Mapa
O  Misión y objetivos
B  Libro de fabricación
Clic izq.  Golpear / Comer / Pescar / Vendarse
Clic der.  Lanzar lanza / Disparar arco
1-8 / Rueda  Elegir casilla (9 y 0 con mochila)
Esc  Pausa (menú)
F5 Guardar · F9 Cargar · F8 Nueva partida"""


func _ready() -> void:
	var crosshair := _create_label(0.0)
	crosshair.text = "+"
	prompt_label = _create_label(40.0)
	message_label = _create_label(80.0)

	# Libro de fabricación (recetas), a la derecha; se abre y cierra con B.
	recipe_book = preload("res://Player/recipe_book.gd").new()
	add_child(recipe_book)

	# Lista de controles, pequeña, arriba a la izquierda.
	controls_label = _create_label(0.0)
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	controls_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	controls_label.offset_left = 16.0
	controls_label.offset_top = 12.0
	controls_label.add_theme_font_size_override("font_size", 14)
	controls_label.add_theme_constant_override("outline_size", 4)
	controls_label.modulate = Color(1, 1, 1, 0.8)
	_load_controls_setting()
	_update_controls()

	_build_stats()

	# Brújula arriba en el centro (Etapa 20).
	add_child(preload("res://Player/compass.gd").new())

	# Reloj arriba a la derecha (lo actualiza DayNight).
	clock_label = _create_label(0.0)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	clock_label.offset_right = -16.0
	clock_label.offset_top = 12.0
	clock_label.add_theme_font_size_override("font_size", 20)


func _process(delta: float) -> void:
	if message_time > 0.0:
		message_time -= delta
		if message_time <= 0.0:
			message_label.text = ""


func set_prompt(new_text: String) -> void:
	prompt_label.text = new_text


func set_stats(health: float, max_health: float, hunger: float, thirst: float, max_value: float, near_fire: bool, bleeding: bool = false) -> void:
	health_bar.max_value = max_health
	hunger_bar.max_value = max_value
	thirst_bar.max_value = max_value
	health_bar.value = health
	hunger_bar.value = hunger
	thirst_bar.value = thirst
	if bleeding:
		# Etapa 37: aviso en rojo hasta que te vendes.
		health_title.text = "Vida (sangrando)"
		health_title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
	else:
		health_title.text = "Vida (fogata)" if near_fire else "Vida"
		health_title.remove_theme_color_override("font_color")


## La llama Player cuando cambia la energía (Etapa 27).
func set_stamina(value: float, max_value: float, exhausted: bool) -> void:
	stamina_bar.max_value = max_value
	stamina_bar.value = value
	stamina_exhausted = exhausted
	_update_climate_titles()


## Calor y frío (Etapa 39): se ven en los títulos de la sed y la energía.
func set_climate(hot: bool, cold: bool) -> void:
	if hot == climate_hot and cold == climate_cold:
		return
	climate_hot = hot
	climate_cold = cold
	_update_climate_titles()


func _update_climate_titles() -> void:
	thirst_title.text = "Sed (calor: busca sombra)" if climate_hot else "Sed"
	_tint(thirst_title, climate_hot, Color(1.0, 0.7, 0.3))
	if stamina_exhausted:
		stamina_title.text = "Energía (agotado)"
	elif climate_cold:
		stamina_title.text = "Energía (frío: busca fuego)"
	else:
		stamina_title.text = "Energía"
	_tint(stamina_title, climate_cold and not stamina_exhausted, Color(0.6, 0.85, 1.0))


func _tint(label: Label, on: bool, color: Color) -> void:
	if on:
		label.add_theme_color_override("font_color", color)
	else:
		label.remove_theme_color_override("font_color")


## Destello rojo al recibir daño.
func flash_damage() -> void:
	var red := ColorRect.new()
	add_child(red)
	red.color = Color(0.8, 0.0, 0.0, 0.35)
	red.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	red.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.tween_property(red, "color:a", 0.0, 0.5)
	tween.tween_callback(red.queue_free)


## Pantalla negra un momento (al dormir).
func fade() -> void:
	var black := ColorRect.new()
	add_child(black)
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.tween_property(black, "color:a", 0.0, 1.5).set_delay(0.6)
	tween.tween_callback(black.queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_controls"):
		toggle_controls()


## Pliega o despliega la lista de controles (H o el botón del menú de pausa).
func toggle_controls() -> void:
	controls_expanded = not controls_expanded
	_update_controls()
	# Se recuerda para la próxima vez que abras el juego.
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("hud", "controls_expanded", controls_expanded)
	config.save(SETTINGS_PATH)
	# Los controles y los objetivos (Etapa 34) no caben abiertos a la vez.
	if controls_expanded:
		get_tree().call_group("objectives", "set_expanded", false)


func _update_controls() -> void:
	if controls_expanded:
		controls_label.text = "[H] Ocultar controles\n" + CONTROLS_TEXT
	else:
		controls_label.text = "[H] Mostrar controles"


func _load_controls_setting() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		controls_expanded = config.get_value("hud", "controls_expanded", true)


func set_clock(new_text: String) -> void:
	clock_label.text = new_text


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
	# Barras abajo a la izquierda: vida, hambre, sed y energía.
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
	thirst_title = _add_stat_title(column, "Sed")
	thirst_bar = _add_stat_bar(column, Color(0.2, 0.55, 0.95))
	stamina_title = _add_stat_title(column, "Energía")
	stamina_bar = _add_stat_bar(column, Color(0.95, 0.8, 0.25))


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
