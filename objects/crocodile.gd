extends CharacterBody3D
## Cocodrilo (Etapa 35): vive en ríos y lagos, casi hundido (solo asoman los
## ojos y el lomo). Si te acercas a la orilla, nada hacia ti y, cuando estás
## cerca, salta fuera del agua y muerde. Agachado (Ctrl) tarda más en notarte.
## Con un golpe se hunde un rato; con 3 se aleja durante un minuto.
##
## No tiene escena: lo crea World (world_resources.gd) con Crocodile.create().
## El modelo es una sola malla con colores por vértice (2 llamadas de dibujo).

enum State { LURK, STALK, LUNGE, RETREAT }

const MapSetup = preload("res://Levels/map_setup.gd")
## Script de sí mismo, para crear cocodrilos con create().
const SELF_PATH: String = "res://objects/crocodile.gd"

@export_group("Velocidad")
@export var swim_speed: float = 1.0
@export var stalk_speed: float = 2.6
## El salto fuera del agua: más rápido que el jugador corriendo, pero corto.
@export var lunge_speed: float = 8.5
@export var lunge_distance: float = 4.5

@export_group("Ataque")
## Distancia a la que te nota (agachado, el 60 %).
@export var notice_radius: float = 12.0
@export var bite_damage: float = 25.0
@export var hits_to_scare: int = 3
## Más lejos que esto del jugador, no hace nada (ahorra recursos).
@export var sleep_distance: float = 60.0
## Distancia máxima que se aleja de su sitio.
@export var home_radius: float = 25.0

## Altura del modelo: hundido (solo asoman los ojos) o fuera del agua.
const SUBMERGED_Y: float = -0.3

var state: State = State.LURK
var home: Vector3
var water_y: float
var target: Vector3
var state_time: float = 0.0
var think_time: float = 0.0
var calm_time: float = 0.0
var hits: int = 0
var bitten: bool = false
var warned: bool = false
var can_advance: bool = false
var lunge_start: Vector3
var player_distance: float = 999.0
var player: Node3D

var model: Node3D
var jaw: Node3D

static var _body_mesh: ArrayMesh
static var _jaw_mesh: ArrayMesh


## Crea un cocodrilo en un punto del agua (la altura es la del agua).
static func create(water_point: Vector3) -> CharacterBody3D:
	var croc := CharacterBody3D.new()
	croc.set_script(load(SELF_PATH))
	croc.name = "Crocodile"
	croc.position = water_point
	return croc


func _ready() -> void:
	add_to_group("crocodile")
	home = global_position
	water_y = global_position.y
	target = home
	player = get_tree().get_first_node_in_group("player")
	think_time = randf() * 0.25
	rotation.y = randf() * TAU
	_build()


func _physics_process(delta: float) -> void:
	think_time -= delta
	if think_time <= 0.0:
		think_time = 0.25  # Piensa 4 veces por segundo.
		_think()
	if player_distance > sleep_distance:
		return
	state_time -= delta

	var direction := Vector3.ZERO
	var speed: float = 0.0
	var y_target: float = water_y
	match state:
		State.LURK:
			var to_target: Vector3 = _flat(target - global_position)
			if to_target.length() > 0.5:
				direction = to_target.normalized()
				speed = swim_speed
		State.STALK:
			if can_advance:
				direction = _flat(player.global_position - global_position).normalized()
				speed = stalk_speed
		State.LUNGE:
			var to_player: Vector3 = _flat(player.global_position - global_position)
			direction = to_player.normalized()
			speed = lunge_speed
			y_target = _surface_height()
			if to_player.length() < 1.9 and not bitten:
				_bite()
			if bitten or state_time <= 0.0 or _flat(global_position - lunge_start).length() > lunge_distance:
				_set_state(State.RETREAT, 12.0)
		State.RETREAT:
			var to_home: Vector3 = _flat(home - global_position)
			if to_home.length() < 1.0 or state_time <= 0.0:
				_set_state(State.LURK, 0.0)
				target = home
			else:
				direction = to_home.normalized()
				speed = stalk_speed * 1.4
				y_target = _surface_height()

	if speed > 0.0:
		global_position += direction * speed * delta
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 6.0 * delta)
	global_position.y = lerpf(global_position.y, y_target, 8.0 * delta)

	# Hundido en el agua; entero al saltar o en tierra.
	var out_of_water: bool = state == State.LUNGE or global_position.y > water_y + 0.1
	model.position.y = lerpf(model.position.y, 0.0 if out_of_water else SUBMERGED_Y, 6.0 * delta)
	# La boca se abre al saltar.
	jaw.rotation.x = lerpf(jaw.rotation.x, -0.6 if state == State.LUNGE and not bitten else 0.0, 12.0 * delta)


func _think() -> void:
	if player == null:
		return
	player_distance = global_position.distance_to(player.global_position)
	if player_distance > 20.0:
		warned = false  # La próxima vez que te acerques volverá a avisar.
	if player_distance > sleep_distance:
		return
	calm_time -= 0.25

	var flat_distance: float = _flat(player.global_position - global_position).length()
	var notice: float = notice_radius / Personajes.mod("sigilo_mult")
	if player.is_crouching():
		notice *= 0.6

	match state:
		State.LURK:
			if calm_time <= 0.0 and flat_distance < notice:
				_set_state(State.STALK, 20.0)
				if not warned:
					warned = true
					player.get_node("HUD").show_message("¡Algo se mueve en el agua! Aléjate de la orilla")
			elif _flat(target - global_position).length() < 0.6 or randf() < 0.02:
				_pick_drift_target()
		State.STALK:
			if flat_distance > notice * 1.8 or state_time <= 0.0 or _flat(global_position - home).length() > home_radius:
				_set_state(State.RETREAT, 12.0)
			elif flat_distance < lunge_distance:
				lunge_start = global_position
				bitten = false
				_set_state(State.LUNGE, 1.0)
			else:
				# Solo avanza si delante sigue habiendo agua (no sale a perseguirte).
				var ahead: Vector3 = global_position + _flat(player.global_position - global_position).normalized() * 1.5
				var water = _water_height(ahead)
				can_advance = water != null
				if water != null:
					water_y = water


## Golpe con un arma o flecha: se hunde y se aleja; con 3 golpes, un minuto.
func hit() -> int:
	hits += 1
	if hits >= hits_to_scare:
		hits = 0
		calm_time = 60.0
	else:
		calm_time = 10.0
	_set_state(State.RETREAT, 12.0)
	return 0


func get_hit_text() -> String:
	return "Golpear al cocodrilo"


func get_hit_message() -> String:
	if calm_time > 30.0:
		return "El cocodrilo se hunde y se aleja"
	return "¡El cocodrilo retrocede! (golpe %d de %d)" % [hits, hits_to_scare]


func _bite() -> void:
	bitten = true
	calm_time = 6.0
	player.get_node("Survival").damage(bite_damage)
	var hud = player.get_node("HUD")
	hud.flash_damage()
	hud.show_message("¡Un cocodrilo te muerde! Aléjate del agua")


## Elige un punto del agua cerca de su sitio para pasear despacio.
func _pick_drift_target() -> void:
	var angle: float = randf() * TAU
	var point: Vector3 = home + Vector3(cos(angle), 0.0, sin(angle)) * randf_range(2.0, 8.0)
	var water = _water_height(point)
	target = point if water != null else home


## Altura del agua (río o lago) en ese punto, o null si no hay.
func _water_height(point: Vector3):
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 4.0, point + Vector3.DOWN * 4.0)
	query.collision_mask = 1 << (MapSetup.WATER_LAYER - 1)
	var hit_info: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit_info.is_empty() or hit_info.collider.get("kind") == "mar":
		return null
	return hit_info.position.y


## Altura a la que va: el agua, o el suelo si está en la orilla.
func _surface_height() -> float:
	var ground = MapSetup.ground_height(get_world_3d(), global_position.x, global_position.z)
	return water_y if ground == null else maxf(ground, water_y)


func _set_state(new_state: State, seconds: float) -> void:
	state = new_state
	state_time = seconds


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


# --- Modelo ---

func _build() -> void:
	if _body_mesh == null:
		_make_meshes()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9

	model = Node3D.new()
	model.position.y = SUBMERGED_Y
	add_child(model)
	var body := MeshInstance3D.new()
	body.mesh = _body_mesh
	body.material_override = material
	model.add_child(body)
	jaw = Node3D.new()
	jaw.position = Vector3(0, 0.12, -1.25)  # Bisagra de la boca.
	model.add_child(jaw)
	var jaw_mesh := MeshInstance3D.new()
	jaw_mesh.mesh = _jaw_mesh
	jaw_mesh.material_override = material
	jaw.add_child(jaw_mesh)
	for mesh in [body, jaw_mesh]:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.visibility_range_end = 80.0

	# Choque: para que lo encuentren el rayo de la E, las flechas y la lanza.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.6, 3.8)
	shape.shape = box
	shape.position = Vector3(0, 0.0, 0.1)
	add_child(shape)


## Une todas las piezas en una sola malla (se hace una vez para todos).
static func _make_meshes() -> void:
	var skin := Color("#3e4a2a")
	var dark := Color("#2c3520")
	var belly := Color("#7d8350")
	var eye := Color("#d8c040")
	_body_mesh = _merge([
		[Vector3(0.75, 0.3, 1.6), Vector3(0, 0.2, 0), skin],         # Cuerpo
		[Vector3(0.6, 0.06, 1.4), Vector3(0, 0.37, 0), dark],        # Lomo
		[Vector3(0.5, 0.22, 0.55), Vector3(0, 0.22, -1.05), skin],   # Cabeza
		[Vector3(0.34, 0.12, 0.8), Vector3(0, 0.2, -1.65), skin],    # Hocico
		[Vector3(0.1, 0.1, 0.1), Vector3(0.15, 0.37, -1.0), eye],    # Ojo
		[Vector3(0.1, 0.1, 0.1), Vector3(-0.15, 0.37, -1.0), eye],   # Ojo
		[Vector3(0.5, 0.24, 0.9), Vector3(0, 0.18, 1.2), skin],      # Cola
		[Vector3(0.3, 0.16, 0.9), Vector3(0, 0.15, 2.05), dark],     # Punta de la cola
		[Vector3(0.2, 0.18, 0.32), Vector3(0.47, 0.07, -0.55), dark],
		[Vector3(0.2, 0.18, 0.32), Vector3(-0.47, 0.07, -0.55), dark],
		[Vector3(0.2, 0.18, 0.32), Vector3(0.47, 0.07, 0.55), dark],
		[Vector3(0.2, 0.18, 0.32), Vector3(-0.47, 0.07, 0.55), dark],
	])
	# Mandíbula de abajo (relativa a la bisagra), con dientes claros.
	_jaw_mesh = _merge([
		[Vector3(0.32, 0.07, 0.8), Vector3(0, -0.02, -0.4), belly],
		[Vector3(0.3, 0.04, 0.7), Vector3(0, 0.03, -0.42), Color("#e8e2c8")],
	])


## Cada pieza: [tamaño, posición, color]. Devuelve una malla con colores.
static func _merge(parts: Array) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in parts:
		var box := BoxMesh.new()
		box.size = part[0]
		var arrays: Array = box.get_mesh_arrays()
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for index in indices:
			tool.set_color(part[2])
			tool.set_normal(normals[index])
			tool.add_vertex(vertices[index] + part[1])
	return tool.commit()
