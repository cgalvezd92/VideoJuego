extends Control
## Brújula: franja arriba en el centro con N, NE, E, SE, S, SO, O, NO (Etapa 20).
## La crea el HUD (hud.gd); no hace falta añadirla a mano en el editor.
## Solo se redibuja cuando el jugador gira (ahorra recursos).

const NAMES: Array[String] = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
## Píxeles por cada grado de giro (2.4 = se ven unos 90° a cada lado).
const PIXELS_PER_DEGREE: float = 2.4

var player: Node3D
var heading: float = 0.0  # Grados: 0 = norte, 90 = este...
## Rumbo hacia el punto de extracción (Etapa 34), en grados.
var extraction_heading: float = -1.0
var extraction: Node3D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	custom_minimum_size = Vector2(420, 30)
	size = custom_minimum_size
	position.x -= size.x * 0.5
	position.y = 10.0


func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	# En el mapa, el norte es -Z. Girar a la derecha aumenta el rumbo.
	var new_heading: float = fposmod(-rad_to_deg(player.rotation.y), 360.0)
	# Rumbo hacia la extracción: atan2(este, norte), con el norte = -Z.
	if extraction == null:
		extraction = get_tree().get_first_node_in_group("extraction")
	var new_target: float = -1.0
	if extraction != null:
		var to: Vector3 = extraction.global_position - player.global_position
		new_target = fposmod(rad_to_deg(atan2(to.x, -to.z)), 360.0)
	if absf(new_heading - heading) > 0.2 or absf(new_target - extraction_heading) > 0.5:
		heading = new_heading
		extraction_heading = new_target
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	var font: Font = get_theme_default_font()
	var center: float = size.x * 0.5

	for degrees in range(0, 360, 15):
		var diff: float = wrapf(degrees - heading, -180.0, 180.0)
		var x: float = center + diff * PIXELS_PER_DEGREE
		if x < 10.0 or x > size.x - 10.0:
			continue
		if degrees % 45 == 0:
			var text: String = NAMES[degrees / 45]
			var color: Color = Color(1.0, 0.35, 0.3) if text == "N" else Color.WHITE
			draw_string(font, Vector2(x - 20.0, 21.0), text, HORIZONTAL_ALIGNMENT_CENTER, 40.0, 16, color)
		else:
			draw_line(Vector2(x, 8.0), Vector2(x, 18.0), Color(1, 1, 1, 0.6), 1.0)

	# Marca verde: dirección del punto de extracción.
	if extraction_heading >= 0.0:
		var ex: float = center + wrapf(extraction_heading - heading, -180.0, 180.0) * PIXELS_PER_DEGREE
		ex = clampf(ex, 6.0, size.x - 6.0)  # Si queda detrás, se ve en el borde.
		draw_rect(Rect2(ex - 5.0, 1.0, 10.0, 6.0), Color(0.2, 0.85, 0.3))

	# Marca central: hacia dónde miras.
	draw_colored_polygon(PackedVector2Array([
		Vector2(center - 6, size.y), Vector2(center + 6, size.y), Vector2(center, size.y - 7)
	]), Color(1.0, 0.85, 0.3))
