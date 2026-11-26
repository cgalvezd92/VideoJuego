extends CharacterBody3D
## Hiena: aparece de noche, ronda al jugador y ataca. Le tiene miedo al fuego
## y huye si la golpeas con el hacha (Etapa 17).
## Va en el nodo raíz "Hyena" de hyena.tscn.

enum State { HIDDEN, PROWL, CHARGE, FLEE, LEAVE }

@export_group("Velocidad")
@export var prowl_speed: float = 3.0
## Algo más lenta que el jugador corriendo (6.5): se puede escapar.
@export var charge_speed: float = 6.0
@export var flee_speed: float = 7.5

@export_group("Comportamiento")
## Distancia a la que ronda alrededor del jugador.
@export var prowl_radius: float = 12.0
## Distancia a la que aparece al llegar la noche.
@export var spawn_distance: float = 35.0
@export var bite_damage: float = 12.0
## Segundos entre mordisco y mordisco.
@export var bite_cooldown: float = 1.5
## Golpes de hacha para que se vaya hasta la noche siguiente.
@export var hits_to_drive_away: int = 3

@export_group("Miedo al fuego")
## Si el jugador está así de cerca de una fogata, no ataca.
@export var safe_fire_radius: float = 6.0
## La hiena nunca se acerca más que esto a una fogata.
@export var fear_fire_radius: float = 8.0

const MapSetup = preload("res://Levels/map_setup.gd")

var state: State = State.HIDDEN
var state_time: float = 0.0
var think_time: float = 0.0
var bite_time: float = 0.0
var whoop_time: float = 0.0
var anim_time: float = 0.0
var orbit_angle: float = 0.0
var orbit_dir: float = 1.0
var hits: int = 0
var gone_tonight: bool = false
var flee_from: Vector3

var player: Node3D
var day_night: Node

@onready var head: Node3D = $Model/HeadPivot
@onready var legs: Array[Node3D] = [$Model/LegFL, $Model/LegFR, $Model/LegBL, $Model/LegBR]


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	_hide()


func _physics_process(delta: float) -> void:
	think_time -= delta
	if think_time <= 0.0:
		# De día (escondida) piensa solo una vez por segundo; si no, 5 veces.
		think_time = 1.0 if state == State.HIDDEN else 0.2
		_think()

	if state == State.HIDDEN:
		return

	state_time -= delta
	bite_time -= delta
	var direction := Vector3.ZERO
	var speed: float = 0.0
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0

	match state:
		State.PROWL:
			# Da vueltas alrededor del jugador.
			orbit_angle += orbit_dir * delta * 0.25
			var spot: Vector3 = player.global_position + Vector3(cos(orbit_angle), 0, sin(orbit_angle)) * prowl_radius
			var to_spot: Vector3 = spot - global_position
			to_spot.y = 0.0
			if to_spot.length() > 0.5:
				direction = to_spot.normalized()
				speed = prowl_speed
			if is_on_wall():
				orbit_dir = -orbit_dir
		State.CHARGE:
			direction = to_player.normalized()
			speed = charge_speed
			if to_player.length() < 1.7:
				speed = 0.0
				_try_bite()
		State.FLEE, State.LEAVE:
			var away: Vector3 = global_position - flee_from
			away.y = 0.0
			direction = away.normalized() if away.length() > 0.1 else Vector3.FORWARD
			speed = flee_speed

	_move(direction, speed, delta)
	_animate(speed, delta)


func _think() -> void:
	# DayNight está más abajo en el árbol: se busca aquí, cuando ya existe.
	if day_night == null:
		day_night = get_tree().get_first_node_in_group("day_night")
	if player == null or day_night == null:
		return

	if state == State.HIDDEN:
		if day_night.is_night() and not gone_tonight:
			_appear()
		elif not day_night.is_night():
			gone_tonight = false  # Una noche nueva, puede volver.
		return

	# Amanece: se va.
	if not day_night.is_night() and state != State.LEAVE:
		_leave()
		return

	var fire = _nearest_fire(global_position)
	var player_fire = _nearest_fire(player.global_position)
	var player_safe: bool = player_fire != null and player_fire.global_position.distance_to(player.global_position) < safe_fire_radius

	match state:
		State.PROWL:
			whoop_time -= 0.2
			if whoop_time <= 0.0:
				whoop_time = randf_range(8.0, 15.0)
			if fire != null and fire.global_position.distance_to(global_position) < fear_fire_radius:
				_flee(fire.global_position, 3.0)
			elif state_time <= 0.0 and not player_safe:
				state = State.CHARGE
				state_time = 12.0
		State.CHARGE:
			if fire != null and fire.global_position.distance_to(global_position) < fear_fire_radius:
				_flee(fire.global_position, 4.0)  # Se asusta del fuego.
			elif player_safe or state_time <= 0.0:
				_start_prowl()
		State.FLEE:
			if state_time <= 0.0:
				_start_prowl()
		State.LEAVE:
			if state_time <= 0.0 or global_position.distance_to(player.global_position) > 45.0:
				_hide()


## La llama Tools al golpear con el hacha. La hiena no da carne: huye.
func hit() -> int:
	if state == State.HIDDEN or state == State.LEAVE:
		return 0
	hits += 1
	if hits >= hits_to_drive_away:
		gone_tonight = true
		_leave()
	else:
		_flee(player.global_position, 5.0)
	return 0


func get_hit_text() -> String:
	return "Golpear a la hiena"


func get_hit_message() -> String:
	if hits >= hits_to_drive_away:
		return "La hiena se va... por esta noche"
	return "¡La hiena huye! (golpe %d de %d)" % [hits, hits_to_drive_away]


func _try_bite() -> void:
	if bite_time > 0.0:
		return
	bite_time = bite_cooldown
	player.get_node("Survival").damage(bite_damage)
	var hud = player.get_node("HUD")
	hud.flash_damage()
	hud.show_message("¡La hiena te muerde! Busca una fogata o golpéala con el hacha")


func _appear() -> void:
	hits = 0
	# Aparece lejos del jugador, en una dirección al azar dentro del mapa.
	# Prueba varias direcciones hasta encontrar tierra firme (no el mar).
	var pos: Vector3 = player.global_position
	for attempt in 8:
		var angle: float = randf() * TAU
		var x: float = player.global_position.x + cos(angle) * spawn_distance
		var z: float = player.global_position.z + sin(angle) * spawn_distance
		var ground = MapSetup.ground_height(get_world_3d(), x, z)
		if ground != null and ground > 0.5:
			pos = Vector3(x, ground, z)
			break
	global_position = pos + Vector3.UP * 0.3
	orbit_angle = atan2(pos.z - player.global_position.z, pos.x - player.global_position.x)
	show()
	$CollisionShape3D.disabled = false
	_start_prowl()
	whoop_time = 1.0


func _start_prowl() -> void:
	state = State.PROWL
	state_time = randf_range(8.0, 16.0)  # Tiempo rondando antes de atacar.
	orbit_dir = 1.0 if randf() < 0.5 else -1.0
	orbit_angle = atan2(global_position.z - player.global_position.z, global_position.x - player.global_position.x)


func _flee(from: Vector3, seconds: float) -> void:
	state = State.FLEE
	state_time = seconds
	flee_from = from


func _leave() -> void:
	state = State.LEAVE
	state_time = 10.0
	flee_from = player.global_position


func _hide() -> void:
	state = State.HIDDEN
	velocity = Vector3.ZERO
	hide()
	$CollisionShape3D.set_deferred("disabled", true)


func _nearest_fire(from: Vector3):
	var best = null
	var best_distance: float = INF
	for fire in get_tree().get_nodes_in_group("campfire"):
		var d: float = fire.global_position.distance_to(from)
		if d < best_distance:
			best_distance = d
			best = fire
	return best


func _move(direction: Vector3, speed: float, delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var horizontal := Vector2(velocity.x, velocity.z)
	horizontal = horizontal.move_toward(Vector2(direction.x, direction.z) * speed, 20.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	move_and_slide()

	# Mira hacia donde va; al atacar, mira al jugador.
	var look: Vector3 = direction
	if state == State.CHARGE:
		look = player.global_position - global_position
		look.y = 0.0
	if look.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), 8.0 * delta)


func _animate(speed: float, delta: float) -> void:
	anim_time += delta * (4.0 + speed * 1.6)
	var swing: float = 0.0 if speed < 0.1 else (0.6 if speed > prowl_speed + 0.5 else 0.35)
	for i in legs.size():
		var phase: float = 0.0 if i == 0 or i == 3 else PI
		legs[i].rotation.x = sin(anim_time + phase) * swing
	# Cabeza baja al rondar (olfateando) y alta al atacar.
	var head_angle: float = -0.35 if state == State.PROWL else 0.1
	head.rotation.x = lerpf(head.rotation.x, head_angle, 3.0 * delta)
