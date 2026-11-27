extends CanvasLayer
## Mapa del continente: se abre y se cierra con M (Etapa 20).
## Va en el nodo "MapView" (CanvasLayer), hijo de Player.
##
## La imagen (mapas/mapa_africa.png) es una foto desde arriba del mapa 3D,
## hecha una sola vez: el juego no gasta nada en dibujarla.

const MAP_TEXTURE: Texture2D = preload("res://mapas/mapa_africa.png")
## La imagen cubre de -700 a 700 metros en X (oeste-este) y en Z (norte-sur).
const WORLD_MIN: float = -700.0
const WORLD_SIZE: float = 1400.0
## Radio de la zona de recursos alrededor del punto de salida.
const ZONE_RADIUS: float = 60.0

@onready var player: Node3D = owner

var panel: Control
var markers: Control


func _ready() -> void:
	layer = 5  # Encima del HUD, debajo del menú de pausa.
	_build()
	panel.visible = false
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		panel.visible = not panel.visible
		# El HUD se oculta para que no se mezcle con el mapa.
		player.get_node("HUD").visible = not panel.visible
		player.get_node("InventoryUI").visible = not panel.visible
		# Solo se actualiza mientras está abierto.
		set_process(panel.visible)
		markers.queue_redraw()


func _process(_delta: float) -> void:
	markers.queue_redraw()  # La flecha sigue al jugador.


func _build() -> void:
	panel = ColorRect.new()
	add_child(panel)
	panel.color = Color(0, 0, 0, 0.6)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var map_rect := TextureRect.new()
	panel.add_child(map_rect)
	map_rect.texture = MAP_TEXTURE
	map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_rect.offset_top = 50.0
	map_rect.offset_bottom = -50.0
	map_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Capa transparente encima de la imagen para dibujar las marcas.
	markers = Control.new()
	map_rect.add_child(markers)
	markers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	markers.draw.connect(_draw_markers)

	var title := _add_label("Mapa de África", 26, Control.PRESET_CENTER_TOP)
	title.offset_top = 12.0
	var legend := _add_label("Flecha: tú   ·   Naranja: fogatas   ·   Marrón: refugios   ·   Círculo: zona de recursos   ·   Rojo: león   ·   Verde: extracción   ·   [M] Cerrar", 15, Control.PRESET_CENTER_BOTTOM)
	legend.offset_bottom = -16.0


func _add_label(text: String, font_size: int, preset: int) -> Label:
	var label := Label.new()
	panel.add_child(label)
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.set_anchors_and_offsets_preset(preset)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN if preset == Control.PRESET_CENTER_BOTTOM else Control.GROW_DIRECTION_END
	return label


## Pasa una posición del mundo (metros) a un punto de la imagen en pantalla.
func _to_map(world: Vector3, origin: Vector2, side: float) -> Vector2:
	return origin + Vector2((world.x - WORLD_MIN) / WORLD_SIZE, (world.z - WORLD_MIN) / WORLD_SIZE) * side


func _draw_markers() -> void:
	# La imagen es cuadrada y está centrada: se calcula dónde quedó dibujada.
	var side: float = minf(markers.size.x, markers.size.y)
	var origin: Vector2 = (markers.size - Vector2(side, side)) * 0.5

	# Zona de recursos (alrededor del punto de salida).
	var zone: Vector2 = _to_map(player.spawn_position, origin, side)
	markers.draw_arc(zone, ZONE_RADIUS / WORLD_SIZE * side, 0.0, TAU, 32, Color(1, 1, 1, 0.8), 1.5)

	# Territorios de león (Etapa 32): círculo rojo alrededor de su guarida.
	for lion in get_tree().get_nodes_in_group("lion"):
		var den: Vector2 = _to_map(lion.den, origin, side)
		var radius: float = lion.territory_radius / WORLD_SIZE * side
		markers.draw_circle(den, radius, Color(0.85, 0.1, 0.1, 0.25))
		markers.draw_arc(den, radius, 0.0, TAU, 24, Color(0.9, 0.15, 0.1, 0.9), 1.5)

	# Punto de extracción (Etapa 34): cuadrado verde.
	for extraction in get_tree().get_nodes_in_group("extraction"):
		var e: Vector2 = _to_map(extraction.global_position, origin, side)
		markers.draw_rect(Rect2(e - Vector2(7, 7), Vector2(14, 14)), Color(0.2, 0.85, 0.3))
		markers.draw_rect(Rect2(e - Vector2(7, 7), Vector2(14, 14)), Color.BLACK, false, 1.5)

	for shelter in get_tree().get_nodes_in_group("shelter"):
		var p: Vector2 = _to_map(shelter.global_position, origin, side)
		markers.draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), Color(0.45, 0.28, 0.12))
	for fire in get_tree().get_nodes_in_group("fire_pit"):
		markers.draw_circle(_to_map(fire.global_position, origin, side), 4.0, Color(1.0, 0.55, 0.1))

	# Flecha del jugador, apuntando hacia donde mira (norte = arriba).
	var heading: float = -player.rotation.y
	var forward := Vector2(sin(heading), -cos(heading))
	var p: Vector2 = _to_map(player.global_position, origin, side)
	var arrow := PackedVector2Array([
		p + forward * 12.0,
		p + forward.rotated(2.4) * 8.0,
		p + forward.rotated(-2.4) * 8.0,
	])
	markers.draw_colored_polygon(arrow, Color.WHITE)
	markers.draw_polyline(arrow + PackedVector2Array([arrow[0]]), Color.BLACK, 1.5)
