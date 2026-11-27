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

## Mapa por descubrir (Etapa 48): el continente se divide en una cuadrícula
## de 128 x 128 casillas (unos 11 m cada una). Al principio todas están en
## negro y se van descubriendo alrededor de donde pasas.
const FOG_CELLS: int = 128
## Metros que descubres a tu alrededor (Tomás, que se orienta bien, más).
const REVEAL_RADIUS: float = 45.0

@onready var player: Node3D = owner

var panel: Control
var markers: Control
## Niebla: 0 = sin descubrir, 255 = descubierto (una casilla por píxel).
var fog: Image
var fog_overlay: Image
var fog_texture: ImageTexture
var fog_rect: TextureRect
var fog_dirty: bool = true
var reveal_time: float = 0.0
var revealed_count: int = 0


func _ready() -> void:
	layer = 5  # Encima del HUD, debajo del menú de pausa.
	fog = Image.create(FOG_CELLS, FOG_CELLS, false, Image.FORMAT_L8)
	fog_overlay = Image.create(FOG_CELLS, FOG_CELLS, false, Image.FORMAT_RGBA8)
	_build()
	panel.visible = false
	# Descubre los alrededores 1 vez por segundo, aunque el mapa esté cerrado.
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_reveal_around_player)
	add_child(timer)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map"):
		panel.visible = not panel.visible
		# El HUD se oculta para que no se mezcle con el mapa.
		player.get_node("HUD").visible = not panel.visible
		player.get_node("InventoryUI").visible = not panel.visible
		# Solo se actualiza mientras está abierto.
		if panel.visible:
			_reveal_around_player()
			_update_fog_texture()
		markers.queue_redraw()


func _process(_delta: float) -> void:
	if panel.visible:
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
	map_rect.offset_bottom = -58.0
	map_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Niebla negra encima del mapa (con bordes suaves al ampliarse).
	fog_texture = ImageTexture.create_from_image(fog_overlay)
	fog_rect = TextureRect.new()
	map_rect.add_child(fog_rect)
	fog_rect.texture = fog_texture
	fog_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fog_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fog_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fog_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Capa transparente encima de la imagen para dibujar las marcas.
	markers = Control.new()
	map_rect.add_child(markers)
	markers.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	markers.draw.connect(_draw_markers)

	var title := _add_label("Mapa de África", 26, Control.PRESET_CENTER_TOP)
	title.offset_top = 12.0
	var legend := _add_label("Negro: sin explorar   ·   Flecha: tú   ·   Naranja: fogatas   ·   Marrón: refugios   ·   Círculo: zona de recursos\nRojo: león   ·   Verde: extracción   ·   Amarillo: lugares descubiertos   ·   [M] Cerrar", 14, Control.PRESET_CENTER_BOTTOM)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.offset_bottom = -8.0


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
		if not is_revealed(lion.den):
			continue  # Los leones de zonas sin explorar no se ven.
		var den: Vector2 = _to_map(lion.den, origin, side)
		var radius: float = lion.territory_radius / WORLD_SIZE * side
		markers.draw_circle(den, radius, Color(0.85, 0.1, 0.1, 0.25))
		markers.draw_arc(den, radius, 0.0, TAU, 24, Color(0.9, 0.15, 0.1, 0.9), 1.5)

	# Punto de extracción (Etapa 34): cuadrado verde.
	for extraction in get_tree().get_nodes_in_group("extraction"):
		var e: Vector2 = _to_map(extraction.global_position, origin, side)
		markers.draw_rect(Rect2(e - Vector2(7, 7), Vector2(14, 14)), Color(0.2, 0.85, 0.3))
		markers.draw_rect(Rect2(e - Vector2(7, 7), Vector2(14, 14)), Color.BLACK, false, 1.5)

	# Lugares especiales descubiertos (Etapa 47): rombo amarillo con su nombre.
	var places = get_tree().get_first_node_in_group("places")
	if places != null:
		var font: Font = markers.get_theme_default_font()
		for id in places.discovered:
			var info: Array = places.PLACES[id]
			var q: Vector2 = _to_map(Vector3(info[1], 0, info[2]), origin, side)
			var diamond := PackedVector2Array([q + Vector2(0, -7), q + Vector2(7, 0), q + Vector2(0, 7), q + Vector2(-7, 0)])
			markers.draw_colored_polygon(diamond, Color(1.0, 0.85, 0.2))
			markers.draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color.BLACK, 1.5)
			markers.draw_string_outline(font, q + Vector2(10, 5), info[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 3, Color.BLACK)
			markers.draw_string(font, q + Vector2(10, 5), info[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.9, 0.5))

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



# --- Mapa por descubrir (Etapa 48) ---

## Casilla de la niebla para una posición del mundo.
func _cell(world: Vector3) -> Vector2i:
	return Vector2i(
		clampi(int((world.x - WORLD_MIN) / WORLD_SIZE * FOG_CELLS), 0, FOG_CELLS - 1),
		clampi(int((world.z - WORLD_MIN) / WORLD_SIZE * FOG_CELLS), 0, FOG_CELLS - 1))


func is_revealed(world: Vector3) -> bool:
	var c := _cell(world)
	return fog.get_pixel(c.x, c.y).r > 0.5


## Descubre un círculo alrededor del jugador (barato: unas 50 casillas).
func _reveal_around_player() -> void:
	if player == null:
		return
	var radius: float = REVEAL_RADIUS * (1.5 if Personajes.mod("vision_noche") else 1.0)
	var cell_size: float = WORLD_SIZE / FOG_CELLS
	var r: int = ceili(radius / cell_size)
	var center := _cell(player.global_position)
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			if dx * dx + dy * dy > r * r:
				continue
			var x: int = center.x + dx
			var y: int = center.y + dy
			if x < 0 or y < 0 or x >= FOG_CELLS or y >= FOG_CELLS:
				continue
			if fog.get_pixel(x, y).r < 0.5:
				fog.set_pixel(x, y, Color.WHITE)
				revealed_count += 1
				fog_dirty = true
	if panel.visible and fog_dirty:
		_update_fog_texture()


## Pasa la niebla a la imagen que se ve (solo si cambió y el mapa está abierto).
func _update_fog_texture() -> void:
	if not fog_dirty:
		return
	fog_dirty = false
	for y in FOG_CELLS:
		for x in FOG_CELLS:
			var seen: bool = fog.get_pixel(x, y).r > 0.5
			fog_overlay.set_pixel(x, y, Color(0.03, 0.03, 0.04, 0.0 if seen else 0.96))
	fog_texture.update(fog_overlay)


## Para la partida guardada: la niebla comprimida en texto.
func get_save_data() -> String:
	return Marshalls.raw_to_base64(fog.get_data().compress(FileAccess.COMPRESSION_DEFLATE))


func set_save_data(text: String) -> void:
	var raw: PackedByteArray = Marshalls.base64_to_raw(text).decompress(FOG_CELLS * FOG_CELLS, FileAccess.COMPRESSION_DEFLATE)
	if raw.size() != FOG_CELLS * FOG_CELLS:
		return
	fog = Image.create_from_data(FOG_CELLS, FOG_CELLS, false, Image.FORMAT_L8, raw)
	fog_dirty = true
