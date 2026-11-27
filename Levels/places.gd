extends Node3D
## Lugares especiales del mapa (Etapa 47).
## Va en el nodo "Places" (Node3D), hijo de Main (en main.tscn).
##
## - Baobab gigante con un panal: E para sacar miel (cada día de juego).
##   Sin antorcha, las abejas pican.
## - Aldea abandonada: chozas y un cofre con objetos útiles.
## - Avión estrellado: un botiquín (una vez) que cura del todo y da vendas.
## - Dos cuevas: refugio contra la lluvia, el frío y el sol; de noche se
##   puede dormir en la entrada.
## Al acercarte a menos de 25 m, el lugar queda "descubierto" y sale en el
## mapa (M). Todo se crea por código con figuras sencillas.

const HeldItems = preload("res://Player/held_items.gd")
const MapSetup = preload("res://Levels/map_setup.gd")
const Chest = preload("res://objects/chest.gd")
const PlaceSpot = preload("res://Levels/place_spot.gd")

## Cada lugar: id -> [nombre, posición X, posición Z].
const PLACES: Dictionary = {
	"baobab": ["Baobab gigante", 246.0, 206.0],
	"aldea": ["Aldea abandonada", 311.0, 295.0],
	"avion": ["Avión estrellado", 496.0, 374.0],
	"cueva1": ["Cueva", 244.0, 86.0],
	"cueva2": ["Cueva del oeste", -72.0, 115.0],
}
## Distancia a la que se descubre un lugar.
const DISCOVER_RADIUS: float = 25.0
## Lo que hay en el cofre de la aldea al empezar.
const VILLAGE_LOOT: Array = [
	["antorcha", "Antorcha", 2], ["venda", "Venda", 2], ["flecha", "Flecha", 6],
	["olla", "Olla", 1], ["lanza", "Lanza", 1],
]

var discovered: Dictionary = {}  # id -> true
var medkit_used: bool = false
## Hora del juego en que se sacó miel por última vez (-100 = nunca).
var honey_at: float = -100.0
var village_chest: Node3D
var player: Node3D
var day_night: Node
var check_time: float = 0.0
var built: bool = false


func _ready() -> void:
	add_to_group("places")
	player = get_tree().get_first_node_in_group("player")
	# Espera a que el terreno tenga colisión para colocar todo encima.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_build_baobab(_ground(PLACES.baobab))
	_build_village(_ground(PLACES.aldea))
	_build_plane(_ground(PLACES.avion))
	_build_cave(_ground(PLACES.cueva1), 0.6)
	_build_cave(_ground(PLACES.cueva2), 2.4)
	built = true


func _process(delta: float) -> void:
	check_time -= delta
	if check_time > 0.0 or player == null:
		return
	check_time = 1.0
	for id in PLACES:
		if discovered.has(id):
			continue
		var p: Array = PLACES[id]
		if Vector2(player.global_position.x - p[1], player.global_position.z - p[2]).length() < DISCOVER_RADIUS:
			discovered[id] = true
			player.get_node("HUD").show_message("Descubriste: %s (sale en el mapa, M)" % p[0])


## Posición del lugar sobre el suelo.
func _ground(place: Array) -> Vector3:
	var g = MapSetup.ground_height(get_world_3d(), place[1], place[2])
	return Vector3(place[1], 0.0 if g == null else g, place[2])


func _hours() -> float:
	if day_night == null:
		day_night = get_tree().get_first_node_in_group("day_night")
	return 0.0 if day_night == null else day_night.total_hours


# --- Lo que pasa al pulsar E en cada lugar (lo llama place_spot.gd) ---

func spot_prompt(kind: String) -> String:
	match kind:
		"miel":
			if _hours() - honey_at < 24.0:
				return "Panal vacío (la miel vuelve en un día)"
			if player.get_node("Tools").is_holding_torch():
				return "[E] Sacar miel (el humo calma a las abejas)"
			return "[E] Sacar miel (¡cuidado con las abejas! mejor con antorcha)"
		"botiquin":
			return "Botiquín vacío" if medkit_used else "[E] Abrir el botiquín del avión"
		"cueva":
			if day_night != null and day_night.is_night():
				return "[E] Dormir en la cueva hasta las 06:00"
			return "Cueva: refugio contra la lluvia, el frío y el sol"
	return ""


func spot_interact(kind: String) -> String:
	var survival = player.get_node("Survival")
	var inventory = player.get_node("Inventory")
	match kind:
		"miel":
			if _hours() - honey_at < 24.0:
				return "La miel todavía no ha vuelto"
			if inventory.add_item("miel", "Miel", 3) == -1:
				return "Inventario lleno"
			honey_at = _hours()
			if player.get_node("Tools").is_holding_torch():
				return "Sacaste 3 de miel sin que te picaran"
			survival.health = maxf(survival.health - 8.0, 1.0)
			survival.check_time = 0.0
			player.get_node("HUD").flash_damage()
			return "¡Las abejas te pican! Sacaste 3 de miel (-8 vida)"
		"botiquin":
			if medkit_used:
				return "El botiquín está vacío"
			medkit_used = true
			survival.health = survival.max_health
			survival.bleeding = 0.0
			survival.check_time = 0.0
			inventory.add_item("venda", "Venda", 4)
			return "¡Botiquín! Te curaste del todo y conseguiste 4 vendas"
		"cueva":
			if day_night == null or not day_night.is_night():
				return "Solo puedes dormir de noche"
			var hours: float = day_night.skip_to_hour(6.0)
			survival.rest(hours / 24.0 * day_night.day_length_minutes * 60.0, 40.0)
			player.get_node("HUD").fade()
			get_tree().call_group("objectives", "complete", "dormir")
			return "Dormiste %d horas en la cueva" % roundi(hours)
	return ""


# --- Modelos (figuras sencillas) ---

func _part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, rot := Vector3.ZERO, view := 250.0) -> MeshInstance3D:
	var mi: MeshInstance3D = HeldItems._part(parent, mesh, color, pos, rot)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = view
	return mi


func _cone(bottom: float, top: float, height: float, segments := 8) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = bottom
	m.top_radius = top
	m.height = height
	m.radial_segments = segments
	m.rings = 0
	return m


func _sphere(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 8
	m.rings = 4
	return m


## Cuerpo con choque (para no atravesar las cosas).
func _body(pos: Vector3, shape: Shape3D, shape_pos := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	add_child(body)
	body.global_position = pos
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = shape_pos
	body.add_child(cs)
	return body


## Zona que se puede mirar con E (el script está en place_spot.gd).
func _spot(pos: Vector3, kind: String, size: Vector3) -> StaticBody3D:
	var spot := StaticBody3D.new()
	spot.set_script(PlaceSpot)
	spot.kind = kind
	spot.places = self
	add_child(spot)
	spot.global_position = pos
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	spot.add_child(cs)
	return spot


func _build_baobab(at: Vector3) -> void:
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.2
	cyl.height = 10.0
	var tree := _body(at, cyl, Vector3(0, 5, 0))
	var bark := Color("#8a7666")
	_part(tree, _cone(2.6, 1.7, 10.0, 10), bark, Vector3(0, 5, 0), Vector3.ZERO, 600.0)
	# Ramas gruesas arriba y copa escasa (así es el baobab).
	for i in 6:
		var a: float = i * TAU / 6.0
		var dir := Vector3(cos(a), 0, sin(a))
		_part(tree, _cone(0.45, 0.25, 4.0, 6), bark, Vector3(0, 10.5, 0) + dir * 1.6, Vector3(rad_to_deg(dir.z) * 0.6, 0, -rad_to_deg(dir.x) * 0.6), 600.0)
		var leaves := _part(tree, _sphere(1.6), Color("#5f7a34"), Vector3(0, 12.2, 0) + dir * 3.2, Vector3.ZERO, 600.0)
		leaves.scale = Vector3(1.0, 0.55, 1.0)
	# Panal en un hueco del tronco, a la altura de la mano.
	var hive := _part(tree, _sphere(0.4), Color("#c98a2b"), Vector3(0, 1.7, 2.35))
	hive.scale = Vector3(1.0, 1.3, 0.7)
	_spot(at + Vector3(0, 1.7, 2.45), "miel", Vector3(1.0, 1.2, 0.8))


func _build_village(at: Vector3) -> void:
	var mud := Color("#a06b45")
	var straw := Color("#c9a85a")
	var huts := [Vector3(-7, 0, -5), Vector3(6, 0, -6), Vector3(-6, 0, 6), Vector3(7, 0, 5)]
	for i in huts.size():
		var pos: Vector3 = at + huts[i]
		var g = MapSetup.ground_height(get_world_3d(), pos.x, pos.z)
		pos.y = at.y if g == null else g
		var shape := CylinderShape3D.new()
		shape.radius = 1.9
		shape.height = 2.0
		var hut := _body(pos, shape, Vector3(0, 1, 0))
		_part(hut, _cone(1.9, 1.9, 2.0, 10), mud, Vector3(0, 1, 0))
		_part(hut, HeldItems._box(0.9, 1.4, 0.1), Color("#2a1c12"), Vector3(0, 0.7, 1.86))  # Puerta.
		if i != 2:  # Una choza tiene el techo caído.
			_part(hut, _cone(2.4, 0.0, 1.8, 10), straw, Vector3(0, 2.9, 0))
		else:
			_part(hut, _cone(1.6, 0.0, 1.2, 8), straw, Vector3(1.6, 0.5, 1.2), Vector3(70, 0, 20))
	# Restos de una fogata y el cofre con objetos.
	for i in 6:
		var a: float = i * TAU / 6.0
		_part(self, _sphere(0.18), Color("#7d786e"), at + Vector3(cos(a) * 0.6 + 2.0, 0.1, sin(a) * 0.6))
	village_chest = Chest.new()
	village_chest.persistent = true  # No se guarda como cofre del jugador.
	village_chest.slots.resize(Chest.SLOT_COUNT)
	for i in VILLAGE_LOOT.size():
		var it: Array = VILLAGE_LOOT[i]
		village_chest.slots[i] = { "id": it[0], "name": it[1], "amount": it[2] }
	if _saved_chest != null:
		village_chest.slots = _saved_chest
	add_child(village_chest)
	village_chest.global_position = at + Vector3(-1.5, 0, 0)


func _build_plane(at: Vector3) -> void:
	var white := Color("#d9d9d4")
	var grey := Color("#8d9196")
	var root := Node3D.new()
	add_child(root)
	root.global_position = at
	root.rotation.y = 0.5
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 2.4, 10.0)
	var body := _body(at, shape, Vector3(0, 1.0, 0))
	body.rotation.y = 0.5
	# Fuselaje algo hundido e inclinado, ala rota, cola y cabina.
	_part(root, _cone(1.2, 1.2, 10.0, 10), white, Vector3(0, 0.9, 0), Vector3(90, 0, 4))
	_part(root, _cone(1.2, 0.5, 2.0, 10), grey, Vector3(0, 1.0, -6.0), Vector3(-90, 0, 0))
	_part(root, HeldItems._box(1.4, 0.5, 1.0), Color("#3b4a5a"), Vector3(0, 1.9, -4.2))
	_part(root, HeldItems._box(7.0, 0.2, 2.0), white, Vector3(-4.2, 0.9, -1.0), Vector3(0, 0, -8))
	_part(root, HeldItems._box(3.0, 0.2, 1.8), white, Vector3(5.5, 0.15, 1.5), Vector3(0, 35, 12))  # Trozo de ala caído.
	_part(root, HeldItems._box(0.2, 2.2, 1.6), white, Vector3(0, 2.4, 4.6), Vector3(-10, 0, 0))
	_part(root, HeldItems._box(3.2, 0.15, 1.0), white, Vector3(0, 1.4, 4.6))
	_part(root, HeldItems._box(0.5, 0.06, 2.5), Color("#b33a2e"), Vector3(0, 2.11, 0.0))  # Franja roja.
	# Botiquín en el suelo, junto a la puerta.
	var kit_pos: Vector3 = at + Vector3(2.4, 0, 0.5).rotated(Vector3.UP, 0.5)
	var g = MapSetup.ground_height(get_world_3d(), kit_pos.x, kit_pos.z)
	kit_pos.y = at.y if g == null else g
	var kit := _spot(kit_pos + Vector3(0, 0.2, 0), "botiquin", Vector3(0.7, 0.5, 0.5))
	_part(kit, HeldItems._box(0.6, 0.35, 0.4), Color("#f2f2ee"), Vector3.ZERO)
	_part(kit, HeldItems._box(0.4, 0.1, 0.42), Color("#d02a22"), Vector3(0, 0, 0))
	_part(kit, HeldItems._box(0.1, 0.3, 0.42), Color("#d02a22"), Vector3(0, 0, 0))


func _build_cave(at: Vector3, facing: float) -> void:
	var rock := Color("#7a6f63")
	var root := Node3D.new()
	add_child(root)
	root.global_position = at
	root.rotation.y = facing
	# Montículo de rocas con una abertura oscura delante.
	var blobs := [[Vector3(0, 1.2, 0), 4.0, Vector3(1.4, 0.8, 1.1)], [Vector3(-2.8, 0.6, 1.0), 2.4, Vector3(1, 0.8, 1)],
		[Vector3(3.0, 0.7, 0.8), 2.6, Vector3(1, 0.85, 1)], [Vector3(0.5, 2.6, -1.0), 2.6, Vector3(1.2, 0.7, 1)]]
	for b in blobs:
		var mi := _part(root, _sphere(b[1]), rock, b[0], Vector3.ZERO, 400.0)
		mi.scale = b[2]
	var mouth := _part(root, _sphere(1.5), Color("#151210"), Vector3(0, 1.0, 4.1), Vector3.ZERO, 400.0)
	mouth.scale = Vector3(1.0, 0.95, 0.35)
	var shape := SphereShape3D.new()
	shape.radius = 4.2
	var body := _body(at, shape, Vector3(0, 0.8, 0))
	body.rotation.y = facing
	# Entrada: se mira con E; da cobijo en 6 m.
	var entrance := _spot(at + Vector3(0, 1.0, 4.6).rotated(Vector3.UP, facing), "cueva", Vector3(2.6, 2.0, 0.6))
	entrance.add_to_group("cover")
	entrance.cover_radius = 7.0


# --- Guardar y cargar (lo usa SaveGame) ---

var _saved_chest = null


func get_save_data() -> Dictionary:
	return {
		"discovered": discovered.keys(),
		"medkit_used": medkit_used,
		"honey_at": honey_at,
		"chest": village_chest.slots if village_chest != null else _saved_chest,
	}


func set_save_data(data: Dictionary) -> void:
	discovered.clear()
	for id in data.get("discovered", []):
		discovered[id] = true
	medkit_used = data.get("medkit_used", false)
	honey_at = data.get("honey_at", -100.0)
	var saved = data.get("chest", null)
	if saved != null:
		var slots: Array = []
		slots.resize(Chest.SLOT_COUNT)
		for i in mini(saved.size(), Chest.SLOT_COUNT):
			var s = saved[i]
			if s != null:
				slots[i] = { "id": s.id, "name": s.name, "amount": int(s.amount) }
				if s.has("durability"):
					slots[i].durability = int(s.durability)
		_saved_chest = slots
		if village_chest != null:
			village_chest.slots = slots
