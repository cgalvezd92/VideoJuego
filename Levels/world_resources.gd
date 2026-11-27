extends Node3D
## Recursos por todo el continente (Etapa 22).
## Va en el nodo "World" (Node3D), hijo de Main (en main.tscn).
##
## El mapa se divide en celdas de 64 x 64 m. Solo existen las celdas cercanas
## al jugador: al alejarse se borran y al acercarse se vuelven a crear.
## Cada celda usa una semilla fija, así que siempre sale lo mismo en el mismo
## sitio. Lo que recoges y lo que talas se recuerda (y se guarda en la partida).

const MapSetup = preload("res://Levels/map_setup.gd")
const STONE: PackedScene = preload("res://objects/stone.tscn")
const BRANCH: PackedScene = preload("res://objects/branch.tscn")
const ACACIA: PackedScene = preload("res://objects/acacia.tscn")
const BUSH: PackedScene = preload("res://objects/berry_bush.tscn")
const ROCK: PackedScene = preload("res://objects/rock.tscn")
const GAZELLE: PackedScene = preload("res://objects/gazelle.tscn")
const ZEBRA: PackedScene = preload("res://objects/zebra.tscn")
const GIRAFFE: PackedScene = preload("res://objects/giraffe.tscn")
const LION: PackedScene = preload("res://objects/lion.tscn")
const Crocodile = preload("res://objects/crocodile.gd")

@export var cell_size: float = 64.0
## Celdas activas alrededor del jugador (2 = una cuadrícula de 5 x 5).
@export var active_radius: int = 2
@export var world_seed: int = 2024
## Alrededor del punto de salida no se pone nada (ya tiene sus recursos).
@export var start_zone_radius: float = 75.0
## Distancia máxima a la que se dibuja cada tipo de objeto (ahorra mucho).
## Las piedras y las ramas son pequeñas: no hace falta verlas de lejos.
const VIEW_DISTANCE: Dictionary = {
	"stone": 70.0, "branch": 70.0, "berry_bush": 90.0, "gazelle": 80.0,
	"acacia": 120.0, "rock": 120.0, "zebra": 90.0, "giraffe": 150.0, "lion": 100.0,
}

@export_group("Cantidad por celda")
@export var stones_per_cell: int = 3
@export var branches_per_cell: int = 3
@export var acacias_per_cell: int = 2
@export_range(0.0, 1.0) var bush_chance: float = 0.5
@export_range(0.0, 1.0) var rock_chance: float = 0.4
@export_range(0.0, 1.0) var herd_chance: float = 0.1
## Probabilidad de una manada de 4 cebras o de 2-3 jirafas (Etapa 29).
@export_range(0.0, 1.0) var zebra_chance: float = 0.06
@export_range(0.0, 1.0) var giraffe_chance: float = 0.04
## Probabilidad de que una celda tenga un león con su territorio (Etapa 32).
@export_range(0.0, 1.0) var lion_chance: float = 0.02
## Probabilidad de un cocodrilo si la celda tiene río o lago (Etapa 35).
@export_range(0.0, 1.0) var crocodile_chance: float = 0.5
## Cocodrilo del lago de al lado de la salida (X y Z del mundo).
@export var start_crocodile := Vector2(290.0, 50.0)

var cells: Dictionary = {}  # Vector2i -> Node3D de la celda
var pending: Array[Vector2i] = []  # Celdas que faltan por crear
var collected: Dictionary = {}  # "Cell_x_z/S0" -> true
var felled: Dictionary = {}  # "Cell_x_z/A1" -> hora de tala
var player: Node3D
var zone_center: Vector3
var started: bool = false
var check_time: float = 0.0


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	zone_center = player.spawn_position


## La llama MapSetup cuando el terreno ya tiene colisión.
func start() -> void:
	started = true
	check_time = 0.0
	# El lago junto a la salida también tiene su cocodrilo (Etapa 35).
	var water = _fresh_water_height(start_crocodile.x, start_crocodile.y)
	if water != null:
		add_child(Crocodile.create(Vector3(start_crocodile.x, water, start_crocodile.y)))


func _process(delta: float) -> void:
	if not started:
		return
	# Crea como mucho una celda por fotograma (así no hay tirones).
	if not pending.is_empty():
		var key: Vector2i = pending.pop_front()
		if not cells.has(key):
			_load_cell(key)
		return
	# Cada medio segundo mira si el jugador cambió de celda.
	check_time -= delta
	if check_time <= 0.0:
		check_time = 0.5
		_update_cells()


func _player_cell() -> Vector2i:
	return Vector2i(floori(player.global_position.x / cell_size), floori(player.global_position.z / cell_size))


func _update_cells() -> void:
	var center: Vector2i = _player_cell()
	# Borra las celdas que quedaron lejos (con una celda de margen).
	for key in cells.keys():
		if absi(key.x - center.x) > active_radius + 1 or absi(key.y - center.y) > active_radius + 1:
			_unload_cell(key)
	# Pide las que faltan, las más cercanas primero.
	for dx in range(-active_radius, active_radius + 1):
		for dz in range(-active_radius, active_radius + 1):
			var key := center + Vector2i(dx, dz)
			if not cells.has(key) and not pending.has(key):
				pending.append(key)
	pending.sort_custom(func(a, b): return (a - center).length_squared() < (b - center).length_squared())


func _load_cell(key: Vector2i) -> void:
	var cell := Node3D.new()
	cell.name = "Cell_%d_%d" % [key.x, key.y]
	add_child(cell)
	cells[key] = cell

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(key.x, key.y, world_seed))
	var origin := Vector2(key.x, key.y) * cell_size

	for i in stones_per_cell:
		_place(cell, STONE, "S%d" % i, rng, origin, 1.0)
	for i in branches_per_cell:
		_place(cell, BRANCH, "B%d" % i, rng, origin, 1.0)
	for i in acacias_per_cell:
		_place(cell, ACACIA, "A%d" % i, rng, origin, rng.randf_range(0.8, 1.25))
	# Las tiradas de dado se hacen siempre, aunque no toque poner nada,
	# para que la celda salga igual cada vez.
	var bush_roll: float = rng.randf()
	var rock_roll: float = rng.randf()
	var herd_roll: float = rng.randf()
	var zebra_roll: float = rng.randf()
	var giraffe_roll: float = rng.randf()
	var lion_roll: float = rng.randf()
	if bush_roll < bush_chance:
		_place(cell, BUSH, "Bush", rng, origin, 1.0)
	if rock_roll < rock_chance:
		_place(cell, ROCK, "Rock", rng, origin, rng.randf_range(0.7, 1.8))
	if herd_roll < herd_chance:
		_place_herd(cell, rng, origin, GAZELLE, "G", 3)
	if zebra_roll < zebra_chance:
		_place_herd(cell, rng, origin, ZEBRA, "Z", 4)
	if giraffe_roll < giraffe_chance:
		_place_herd(cell, rng, origin, GIRAFFE, "J", 2 + int(rng.randf() < 0.5))
	if lion_roll < lion_chance:
		var lion: Node3D = _place(cell, LION, "Lion", rng, origin, 1.0)
		if lion != null:
			lion.position.y += 0.05
	# Cocodrilo (Etapa 35): se prueban 6 puntos al azar buscando río o lago.
	# Las tiradas se hacen siempre, para que la celda salga igual cada vez.
	var croc_roll: float = rng.randf()
	var croc_points: Array[Vector2] = []
	for i in 6:
		croc_points.append(origin + Vector2(rng.randf(), rng.randf()) * cell_size)
	if croc_roll < crocodile_chance:
		for point in croc_points:
			if point.distance_to(Vector2(zone_center.x, zone_center.z)) < start_zone_radius:
				continue
			var water = _fresh_water_height(point.x, point.y)
			if water != null:
				cell.add_child(Crocodile.create(Vector3(point.x, water, point.y)))
				break


## Altura del agua de un río o lago en (x, z), o null si no hay (Etapa 35).
func _fresh_water_height(x: float, z: float):
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 200.0, z), Vector3(x, -60.0, z))
	query.collision_mask = 1 << (MapSetup.WATER_LAYER - 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider.get("kind") == "mar":
		return null
	return hit.position.y


## Coloca un objeto en un punto al azar de la celda, sobre el suelo.
func _place(cell: Node3D, scene: PackedScene, id: String, rng: RandomNumberGenerator, origin: Vector2, size: float) -> Node3D:
	var x: float = origin.x + rng.randf() * cell_size
	var z: float = origin.y + rng.randf() * cell_size
	var angle: float = rng.randf() * TAU
	var full_id: String = str(cell.name) + "/" + id

	if Vector2(x, z).distance_to(Vector2(zone_center.x, zone_center.z)) < start_zone_radius:
		return null
	if collected.has(full_id):
		return null
	var ground = MapSetup.ground_height(get_world_3d(), x, z)
	if ground == null or ground < 0.5:
		return null  # Mar, agua o fuera del mapa.

	var node: Node3D = scene.instantiate()
	node.name = id
	node.position = Vector3(x, ground, z)
	node.rotation.y = angle
	node.scale = Vector3.ONE * size
	cell.add_child(node)

	apply_view_distance(node)
	if node.has_signal("collected"):
		node.collected.connect(func(): collected[full_id] = true)
	if felled.has(full_id) and node.has_method("set_felled"):
		node.set_felled(felled[full_id])
	return node


## Una manada: el primero se coloca al azar y los demás a su alrededor.
## "prefix" da nombre a cada animal (G0, G1... para gacelas; Z para cebras; J jirafas).
func _place_herd(cell: Node3D, rng: RandomNumberGenerator, origin: Vector2, scene: PackedScene, prefix: String, count: int) -> void:
	var leader: Node3D = _place(cell, scene, prefix + "0", rng, origin, 1.0)
	if leader == null:
		return
	for i in range(1, count):
		var x: float = leader.position.x + rng.randf_range(-3.0, 3.0)
		var z: float = leader.position.z + rng.randf_range(-3.0, 3.0)
		var ground = MapSetup.ground_height(get_world_3d(), x, z)
		if ground == null or ground < 0.5:
			continue
		var gazelle: Node3D = scene.instantiate()
		gazelle.name = "%s%d" % [prefix, i]
		gazelle.position = Vector3(x, ground + 0.05, z)
		gazelle.rotation.y = rng.randf() * TAU
		cell.add_child(gazelle)
		apply_view_distance(gazelle)
	leader.position.y += 0.05


## Pone a cada pieza del objeto su distancia máxima de dibujo.
## También la usa MapSetup para los objetos de la zona inicial.
static func apply_view_distance(node: Node) -> void:
	var kind: String = node.scene_file_path.get_file().get_basename()
	if not VIEW_DISTANCE.has(kind):
		return
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		mesh.visibility_range_end = VIEW_DISTANCE[kind]


func _unload_cell(key: Vector2i) -> void:
	var cell: Node3D = cells[key]
	_remember_trees(cell)
	# Se quita del árbol antes de borrarla, para que una celda nueva con el
	# mismo nombre no choque con la vieja.
	remove_child(cell)
	cell.queue_free()
	cells.erase(key)


## Anota qué acacias de la celda están taladas (para cuando vuelva a crearse).
func _remember_trees(cell: Node3D) -> void:
	for child in cell.get_children():
		if not "felled" in child:
			continue
		var full_id: String = str(cell.name) + "/" + str(child.name)
		if child.felled:
			felled[full_id] = child.felled_at
		elif child.hits >= child.hits_needed:
			felled[full_id] = get_tree().get_first_node_in_group("day_night").total_hours
		else:
			felled.erase(full_id)  # Ya volvió a crecer.


# --- Guardar y cargar (lo usa SaveGame) ---

func get_save_data() -> Dictionary:
	for cell in cells.values():
		_remember_trees(cell)
	return { "collected": collected.keys(), "felled": felled }


func set_save_data(data: Dictionary) -> void:
	collected.clear()
	for id in data.get("collected", []):
		collected[id] = true
	felled = data.get("felled", {}).duplicate()
	# Las celdas ya creadas se rehacen con lo que dice la partida.
	for key in cells.keys():
		remove_child(cells[key])
		cells[key].queue_free()
	cells.clear()
	pending.clear()
	check_time = 0.0
