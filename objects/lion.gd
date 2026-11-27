extends CharacterBody3D
## León (Etapa 32): defiende su territorio de día. Si entras, ruge, acecha y
## ataca. Le teme al fuego y a la antorcha; con 4 golpes se retira. De noche
## duerme en su guarida.
## Va en el nodo raíz "Lion" de lion.tscn.

enum State { REST, PATROL, STALK, CHARGE, FLEE, RETURN }

@export_group("Velocidad")
@export var walk_speed: float = 1.6
@export var stalk_speed: float = 3.0
## Algo más lento que el jugador corriendo (6.5): se puede escapar.
@export var charge_speed: float = 6.2
@export var flee_speed: float = 8.0

@export_group("Territorio")
## Si el jugador entra en este radio alrededor de la guarida, el león ataca.
@export var territory_radius: float = 25.0
## Si el jugador se aleja más que esto de la guarida, deja de perseguirlo.
@export var chase_radius: float = 40.0
## Más lejos que esto del jugador, el león no hace nada (ahorra recursos).
@export var sleep_distance: float = 90.0

@export_group("Ataque")
@export var bite_damage: float = 20.0
@export var bite_cooldown: float = 1.6
## Golpes para que se retire a su guarida.
@export var hits_to_scare: int = 4
## Segundos que se queda tranquilo después de retirarse.
@export var calm_seconds: float = 60.0
## Junto a una fogata encendida (a esta distancia) el león no ataca.
@export var safe_fire_radius: float = 6.0

var state: State = State.REST
var den: Vector3  # Guarida: donde aparece y adonde vuelve.
var target: Vector3
var flee_from: Vector3
var state_time: float = 0.0
var think_time: float = 0.0
var bite_time: float = 0.0
var calm_time: float = 0.0
var anim_time: float = 0.0
var hits: int = 0
var player_distance: float = 999.0
var player: Node3D
var day_night: Node

@onready var head: Node3D = $Model/HeadPivot
@onready var legs: Array[Node3D] = [$Model/LegFL, $Model/LegFR, $Model/LegBL, $Model/LegBR]


func _ready() -> void:
	add_to_group("lion")
	den = global_position
	player = get_tree().get_first_node_in_group("player")
	think_time = randf() * 0.2
	_set_state(State.REST, randf_range(3.0, 8.0))


func _physics_process(delta: float) -> void:
	think_time -= delta
	if think_time <= 0.0:
		think_time = 0.2  # Piensa 5 veces por segundo.
		_think()
	if player_distance > sleep_distance:
		return  # Muy lejos: no se mueve.

	state_time -= delta
	bite_time -= delta
	calm_time -= delta
	var direction := Vector3.ZERO
	var speed: float = 0.0

	match state:
		State.PATROL:
			var to_target: Vector3 = _flat(target - global_position)
			if to_target.length() < 0.6 or state_time <= 0.0 or is_on_wall():
				_set_state(State.REST, randf_range(5.0, 12.0))
			else:
				direction = to_target.normalized()
				speed = walk_speed
		State.STALK, State.CHARGE:
			var to_player: Vector3 = _flat(player.global_position - global_position)
			direction = to_player.normalized()
			speed = stalk_speed if state == State.STALK else charge_speed
			if to_player.length() < 1.9:
				speed = 0.0
				if state == State.CHARGE:
					_try_bite()
		State.FLEE:
			var away: Vector3 = _flat(global_position - flee_from)
			direction = away.normalized() if away.length() > 0.1 else Vector3.FORWARD
			speed = flee_speed
		State.RETURN:
			var to_den: Vector3 = _flat(den - global_position)
			if to_den.length() < 1.5:
				_set_state(State.REST, randf_range(5.0, 12.0))
			else:
				direction = to_den.normalized()
				speed = walk_speed * 2.0

	_move(direction, speed, delta)
	_animate(speed, delta)


func _think() -> void:
	if player == null:
		return
	if day_night == null:
		day_night = get_tree().get_first_node_in_group("day_night")
	player_distance = global_position.distance_to(player.global_position)
	if player_distance > sleep_distance:
		return

	var night: bool = day_night != null and day_night.is_night()
	var player_from_den: float = _flat(player.global_position - den).length()
	var scared: bool = _player_has_fire()

	match state:
		State.REST, State.PATROL:
			if not night and calm_time <= 0.0 and player_from_den < territory_radius and not scared:
				_roar()
			elif state == State.REST and state_time <= 0.0 and not night:
				# Pasea un poco alrededor de su guarida.
				var angle: float = randf() * TAU
				target = den + Vector3(cos(angle), 0, sin(angle)) * randf_range(3.0, 10.0)
				_set_state(State.PATROL, 12.0)
		State.STALK:
			if scared:
				_flee(player.global_position, 4.0)
			elif player_from_den > chase_radius:
				_set_state(State.RETURN, 20.0)
			elif state_time <= 0.0:
				_set_state(State.CHARGE, 15.0)
		State.CHARGE:
			if scared:
				_flee(player.global_position, 4.0)
			elif player_from_den > chase_radius or state_time <= 0.0:
				_set_state(State.RETURN, 20.0)
		State.FLEE:
			if state_time <= 0.0:
				_set_state(State.RETURN, 20.0)


## Golpe con un arma o flecha: retrocede un momento; con 4 golpes se retira.
func hit() -> int:
	hits += 1
	if hits >= hits_to_scare:
		hits = 0
		calm_time = calm_seconds
		_flee(player.global_position, 6.0)
	else:
		_flee(player.global_position, 1.5)
	return 0


func get_hit_text() -> String:
	return "Golpear al león"


func get_hit_message() -> String:
	if calm_time > 0.0 and hits == 0:
		return "El león se retira a su guarida"
	return "¡El león retrocede! (golpe %d de %d)" % [hits, hits_to_scare]


func _roar() -> void:
	_set_state(State.STALK, 3.0)  # Acecha 3 s antes de atacar.
	player.get_node("HUD").show_message("¡Un rugido! Estás en el territorio de un león: aléjate o usa fuego")


func _try_bite() -> void:
	if bite_time > 0.0:
		return
	bite_time = bite_cooldown
	player.get_node("Survival").damage(bite_damage, true, "un león")  # Sangra (Etapa 37); causa (Etapa 53).
	var hud = player.get_node("HUD")
	hud.flash_damage()
	hud.show_message("¡El león te ataca! Huye de su territorio, usa fuego o golpéalo")


## ¿Está el jugador junto a una fogata encendida o con la antorcha en la mano?
func _player_has_fire() -> bool:
	if player.get_node("Tools").is_holding_torch():
		return true
	for fire in get_tree().get_nodes_in_group("campfire"):
		if fire.global_position.distance_to(player.global_position) < safe_fire_radius:
			return true
	return false


func _flee(from: Vector3, seconds: float) -> void:
	flee_from = from
	_set_state(State.FLEE, seconds)


func _set_state(new_state: State, seconds: float) -> void:
	state = new_state
	state_time = seconds


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)


func _move(direction: Vector3, speed: float, delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var horizontal := Vector2(velocity.x, velocity.z)
	horizontal = horizontal.move_toward(Vector2(direction.x, direction.z) * speed, 20.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	move_and_slide()
	if direction.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 8.0 * delta)


func _animate(speed: float, delta: float) -> void:
	anim_time += delta * (4.0 + speed * 1.5)
	var swing: float = 0.0 if speed < 0.1 else (0.6 if speed > stalk_speed + 0.5 else 0.3)
	for i in legs.size():
		var phase: float = 0.0 if i == 0 or i == 3 else PI
		legs[i].rotation.x = sin(anim_time + phase) * swing
	# Cabeza baja al acechar, alta el resto del tiempo.
	var head_angle: float = -0.3 if state == State.STALK else 0.0
	head.rotation.x = lerpf(head.rotation.x, head_angle, 3.0 * delta)
