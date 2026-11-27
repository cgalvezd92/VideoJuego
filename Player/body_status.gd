extends Control
## Panel "digital" de estado (Etapa 46), abajo a la izquierda.
## - A la izquierda, la silueta de un cuerpo que se llena desde los pies según
##   la vida (verde, amarilla o roja; parpadea en rojo si sangras).
## - A la derecha, medidores por segmentos con su porcentaje: vida, hambre,
##   sed y energía, y avisos (sangrando, fogata, calor, frío, agotado).
## Lo crea el HUD (hud.gd); se dibuja con figuras, sin imágenes, y solo se
## vuelve a dibujar cuando cambian los valores (o para parpadear).

const CYAN := Color(0.35, 0.9, 1.0)
const DIM := Color(0.35, 0.9, 1.0, 0.12)
const PANEL := Color(0.02, 0.08, 0.1, 0.72)
const SEGMENTS: int = 12

## Colores de cada medidor.
const COLORS: Dictionary = {
	"vida": Color(0.3, 1.0, 0.55),
	"hambre": Color(1.0, 0.62, 0.2),
	"sed": Color(0.3, 0.7, 1.0),
	"energia": Color(1.0, 0.88, 0.3),
}

var health: float = 1.0  # 0 a 1
var hunger: float = 1.0
var thirst: float = 1.0
var stamina: float = 1.0
var health_text: String = ""
var bleeding: bool = false
var near_fire: bool = false
var hot: bool = false
var cold: bool = false
var exhausted: bool = false
var sandstorm: bool = false

var blink_on: bool = true
var blink_time: float = 0.0

## Silueta en coordenadas de 0 a 1 (ancho x alto de su caja).
var body_shapes: Array[PackedVector2Array] = []
const BODY_BOX := Rect2(10, 10, 66, 128)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(292, 148)
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 16.0
	offset_right = 16.0 + custom_minimum_size.x
	offset_bottom = -18.0
	offset_top = offset_bottom - custom_minimum_size.y
	_make_body()
	set_process(false)


## Actualiza los valores; solo redibuja si algo cambió de verdad.
func set_values(new_health: float, max_health: float, new_hunger: float, new_thirst: float, max_value: float, fire: bool, bleed: bool) -> void:
	var h: float = clampf(new_health / max_health, 0.0, 1.0)
	var text: String = "%d/%d" % [ceili(new_health), roundi(max_health)]
	var hu: float = clampf(new_hunger / max_value, 0.0, 1.0)
	var th: float = clampf(new_thirst / max_value, 0.0, 1.0)
	if absf(h - health) < 0.002 and absf(hu - hunger) < 0.004 and absf(th - thirst) < 0.004 \
			and fire == near_fire and bleed == bleeding and text == health_text:
		return
	health = h
	health_text = text
	hunger = hu
	thirst = th
	near_fire = fire
	bleeding = bleed
	_changed()


func set_stamina(value: float, max_value: float, is_exhausted: bool) -> void:
	stamina = clampf(value / max_value, 0.0, 1.0)
	exhausted = is_exhausted
	_changed()


func set_climate(is_hot: bool, is_cold: bool) -> void:
	hot = is_hot
	cold = is_cold
	_changed()


## Tormenta de arena (Etapa 49): aviso "ARENA" en la sed.
func set_sandstorm(value: bool) -> void:
	if value == sandstorm:
		return
	sandstorm = value
	_changed()


func _changed() -> void:
	# Solo hace falta animar (parpadeo) si algo está en peligro.
	set_process(bleeding or health < 0.25 or hunger < 0.2 or thirst < 0.2)
	queue_redraw()


func _process(delta: float) -> void:
	blink_time += delta
	if blink_time >= 0.3:
		blink_time = 0.0
		blink_on = not blink_on
		queue_redraw()


# --- Dibujo ---

func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)
	draw_rect(box, PANEL)
	draw_rect(box, Color(CYAN, 0.55), false, 1.5)
	_corner_marks(box)
	_draw_body()
	var x: float = 92.0
	var tag: String = ""
	if bleeding:
		tag = "SANGRANDO"
	elif near_fire:
		tag = "FOGATA"
	_draw_meter(x, 8.0, "VIDA", health, health_text, COLORS.vida, tag, bleeding)
	_draw_meter(x, 42.0, "HAMBRE", hunger, "%d%%" % roundi(hunger * 100.0), COLORS.hambre, "", false)
	_draw_meter(x, 76.0, "SED", thirst, "%d%%" % roundi(thirst * 100.0), COLORS.sed, "ARENA" if sandstorm else ("CALOR" if hot else ""), hot or sandstorm)
	var energy_tag: String = "AGOTADO" if exhausted else ("FRÍO" if cold else "")
	_draw_meter(x, 110.0, "ENERGÍA", stamina, "%d%%" % roundi(stamina * 100.0), COLORS.energia, energy_tag, exhausted or cold)


## Pequeñas esquinas más brillantes (aspecto de pantalla).
func _corner_marks(box: Rect2) -> void:
	var l: float = 10.0
	var c := Color(CYAN, 0.95)
	for corner in [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]:
		var dx: float = l if corner.x == box.position.x else -l
		var dy: float = l if corner.y == box.position.y else -l
		draw_line(corner, corner + Vector2(dx, 0), c, 2.0)
		draw_line(corner, corner + Vector2(0, dy), c, 2.0)


func _draw_body() -> void:
	var color: Color = COLORS.vida
	if health <= 0.25:
		color = Color(1.0, 0.3, 0.25)
	elif health <= 0.5:
		color = Color(1.0, 0.85, 0.3)
	if bleeding and not blink_on:
		color = Color(1.0, 0.15, 0.15)

	# Fondo de la silueta (vacío).
	for shape in body_shapes:
		draw_colored_polygon(shape, DIM)

	# Relleno: desde los pies hasta la altura de la vida.
	var level: float = BODY_BOX.end.y - BODY_BOX.size.y * health
	var fill_rect := PackedVector2Array([
		Vector2(BODY_BOX.position.x - 2, level), Vector2(BODY_BOX.end.x + 2, level),
		Vector2(BODY_BOX.end.x + 2, BODY_BOX.end.y + 2), Vector2(BODY_BOX.position.x - 2, BODY_BOX.end.y + 2),
	])
	for shape in body_shapes:
		for piece in Geometry2D.intersect_polygons(shape, fill_rect):
			if piece.size() >= 3:
				draw_colored_polygon(piece, Color(color, 0.75))

	# Líneas horizontales finas (como una pantalla) y el contorno.
	var y: float = BODY_BOX.position.y
	while y < BODY_BOX.end.y:
		draw_line(Vector2(BODY_BOX.position.x, y), Vector2(BODY_BOX.end.x, y), Color(0, 0, 0, 0.18), 1.0)
		y += 4.0
	for shape in body_shapes:
		var outline := shape.duplicate()
		outline.append(shape[0])
		draw_polyline(outline, Color(CYAN, 0.9), 1.2)
	# Línea del nivel de vida.
	if health > 0.0 and health < 1.0:
		draw_line(Vector2(BODY_BOX.position.x - 3, level), Vector2(BODY_BOX.end.x + 3, level), Color(color, 0.9), 1.0)


## Un medidor: nombre, valor y fila de segmentos.
func _draw_meter(x: float, y: float, title: String, ratio: float, value: String, color: Color, tag: String, tag_alert: bool) -> void:
	var font: Font = get_theme_default_font()
	var low: bool = ratio < 0.2
	var text_color: Color = Color(CYAN, 0.95)
	draw_string(font, Vector2(x, y + 11), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, text_color)
	if tag != "":
		var tag_color: Color = Color(1.0, 0.4, 0.35) if tag_alert else Color(1.0, 0.75, 0.35)
		if tag == "FRÍO":
			tag_color = Color(0.6, 0.85, 1.0)
		if tag == "FOGATA":
			tag_color = Color(1.0, 0.7, 0.3)
		if not (tag == "SANGRANDO" and not blink_on):
			draw_string(font, Vector2(x + 58, y + 11), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, tag_color)
	draw_string(font, Vector2(x, y + 11), value, HORIZONTAL_ALIGNMENT_RIGHT, 188, 12, color)

	var filled: int = ceili(ratio * SEGMENTS) if ratio > 0.0 else 0
	var seg_w: float = 13.6
	for i in SEGMENTS:
		var rect := Rect2(x + i * (seg_w + 2.0), y + 16, seg_w, 9)
		if i < filled:
			var c: Color = color
			if low and not blink_on:
				c = Color(color, 0.35)
			draw_rect(rect, c)
		else:
			draw_rect(rect, Color(color, 0.12))
			draw_rect(rect, Color(color, 0.25), false, 1.0)


## Silueta: cabeza, cuello, tronco, brazos, cadera y piernas.
func _make_body() -> void:
	var raw: Array = []
	var head := PackedVector2Array()
	for i in 18:
		var a: float = i * TAU / 18.0
		head.append(Vector2(0.5 + cos(a) * 0.15, 0.09 + sin(a) * 0.075))
	raw.append(head)
	raw.append([Vector2(0.43, 0.16), Vector2(0.57, 0.16), Vector2(0.58, 0.21), Vector2(0.42, 0.21)])
	raw.append([Vector2(0.22, 0.21), Vector2(0.78, 0.21), Vector2(0.72, 0.54), Vector2(0.28, 0.54)])
	raw.append([Vector2(0.21, 0.22), Vector2(0.27, 0.33), Vector2(0.17, 0.56), Vector2(0.06, 0.55), Vector2(0.12, 0.27)])
	raw.append([Vector2(0.79, 0.22), Vector2(0.88, 0.27), Vector2(0.94, 0.55), Vector2(0.83, 0.56), Vector2(0.73, 0.33)])
	raw.append([Vector2(0.28, 0.55), Vector2(0.72, 0.55), Vector2(0.74, 0.62), Vector2(0.26, 0.62)])
	raw.append([Vector2(0.26, 0.63), Vector2(0.48, 0.63), Vector2(0.46, 0.99), Vector2(0.30, 0.99)])
	raw.append([Vector2(0.52, 0.63), Vector2(0.74, 0.63), Vector2(0.70, 0.99), Vector2(0.54, 0.99)])
	for points in raw:
		var shape := PackedVector2Array()
		for p in points:
			shape.append(BODY_BOX.position + Vector2(p.x * BODY_BOX.size.x, p.y * BODY_BOX.size.y))
		body_shapes.append(shape)
