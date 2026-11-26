extends Control
## Pantalla de inicio: título, fondo de sabana y botones (Etapa 16).
## Va en el nodo raíz "TitleScreen" (Control) de title_screen.tscn,
## que es la escena principal del proyecto.

const GAME_SCENE: String = "res://Levels/main.tscn"
const SAVE_PATH: String = "user://partida.json"

## Título que se muestra (cámbialo en el Inspector).
@export var game_title: String = "Supervivencia en África"

var new_game_button: Button
var confirm_new_game: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	_build_menu()


# --- Botones ---

func _on_continue() -> void:
	# El nivel carga solo el guardado al empezar (SaveGame).
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_new_game() -> void:
	if FileAccess.file_exists(SAVE_PATH) and not confirm_new_game:
		confirm_new_game = true
		new_game_button.text = "¿Seguro? Se borrará la partida guardada"
		return
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit() -> void:
	get_tree().quit()


## Lee el día y la hora del guardado para mostrarlos en "Continuar".
func _saved_time_text() -> String:
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY or not data.has("hours"):
		return ""
	var total: float = data.hours
	var hour: float = fmod(total, 24.0)
	return "  (Día %d · %02d:%02d)" % [int(total / 24.0) + 1, int(hour), int(fmod(hour, 1.0) * 60.0)]


# --- Menú (por código) ---

func _build_menu() -> void:
	var column := VBoxContainer.new()
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.offset_top = -90.0  # Por encima del centro, sobre el cielo.
	column.add_theme_constant_override("separation", 12)

	var title := Label.new()
	column.add_child(title)
	title.text = game_title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.05))

	var spacer := Control.new()
	column.add_child(spacer)
	spacer.custom_minimum_size = Vector2(0, 24)

	var has_save: bool = FileAccess.file_exists(SAVE_PATH)
	var first: Button
	if has_save:
		first = _add_button(column, "Continuar" + _saved_time_text(), _on_continue)
	new_game_button = _add_button(column, "Nueva partida", _on_new_game)
	_add_button(column, "Salir", _on_quit)
	if first == null:
		first = new_game_button
	first.grab_focus.call_deferred()  # Para usarlo con flechas y Enter.


func _add_button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.text = text
	button.custom_minimum_size = Vector2(420, 52)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(Sounds.play.bind("click", -4.0, 0.0))
	button.pressed.connect(action)
	return button


# --- Fondo: atardecer en la sabana, dibujado con formas simples ---

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()  # Redibuja si cambia el tamaño de la ventana.


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var horizon: float = h * 0.78

	# Cielo: degradado de azul oscuro (arriba) a naranja (horizonte).
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, horizon), Vector2(0, horizon)]),
		PackedColorArray([Color(0.2, 0.18, 0.35), Color(0.2, 0.18, 0.35), Color(0.98, 0.6, 0.3), Color(0.98, 0.6, 0.3)])
	)

	# Sol medio escondido en el horizonte.
	var sun_center := Vector2(w * 0.78, horizon)
	draw_circle(sun_center, h * 0.16, Color(1.0, 0.75, 0.4, 0.35))
	draw_circle(sun_center, h * 0.11, Color(1.0, 0.85, 0.5))

	# Suelo oscuro.
	draw_rect(Rect2(0, horizon, w, h - horizon), Color(0.16, 0.09, 0.06))

	# Siluetas de acacias (posición x, escala).
	var silhouette := Color(0.1, 0.05, 0.04)
	for tree in [[0.08, 1.0], [0.34, 0.5], [0.9, 1.15], [0.62, 0.45]]:
		_draw_acacia(Vector2(w * tree[0], horizon + 2.0), h * 0.0025 * tree[1], silhouette)

	# Gacelas pequeñas a lo lejos.
	for x in [0.2, 0.235, 0.27]:
		_draw_gazelle(Vector2(w * x, horizon), h * 0.0012, silhouette)

	# Hierba en primer plano.
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 140:
		var x: float = rng.randf() * w
		var base_y: float = horizon + rng.randf() * (h - horizon)
		var blade: float = lerpf(6.0, 26.0, (base_y - horizon) / (h - horizon))
		draw_line(Vector2(x, base_y), Vector2(x + rng.randf_range(-4, 4), base_y - blade), Color(0.22, 0.13, 0.07), 2.0)


func _draw_acacia(base: Vector2, s: float, color: Color) -> void:
	# Tronco y dos ramas.
	draw_line(base, base + Vector2(8, -90) * s, color, 9.0 * s)
	draw_line(base + Vector2(6, -70) * s, base + Vector2(-35, -105) * s, color, 5.0 * s)
	draw_line(base + Vector2(7, -75) * s, base + Vector2(45, -108) * s, color, 5.0 * s)
	# Copa plana: una elipse aplastada.
	var points := PackedVector2Array()
	for i in 20:
		var a: float = TAU * i / 20.0
		points.append(base + Vector2(5 + cos(a) * 95, -112 + sin(a) * 16) * s)
	draw_colored_polygon(points, color)


func _draw_gazelle(base: Vector2, s: float, color: Color) -> void:
	draw_rect(Rect2(base + Vector2(-20, -42) * s, Vector2(40, 14) * s), color)  # Cuerpo
	draw_line(base + Vector2(18, -40) * s, base + Vector2(28, -60) * s, color, 5.0 * s)  # Cuello
	draw_line(base + Vector2(28, -60) * s, base + Vector2(24, -76) * s, color, 2.0 * s)  # Cuernos
	for x in [-16, -10, 12, 17]:
		draw_line(base + Vector2(x, -30) * s, base + Vector2(x, 0) * s, color, 3.0 * s)  # Patas
