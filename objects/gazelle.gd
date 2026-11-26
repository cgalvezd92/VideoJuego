extends CharacterBody3D
## Gacela: pasta, pasea por su zona y huye si el jugador se acerca (Etapa 8).
## Se puede cazar con el hacha y reaparece con el tiempo (Etapa 12).
## Va en el nodo raíz "Gazelle" de gazelle.tscn.

enum State { GRAZE, WALK, FLEE }

@export_group("Velocidad")
@export var walk_speed: float = 1.3
@export var run_speed: float = 7.5

@export_group("Distancias (metros)")
## Si el jugador se acerca más que esto, huye.
@export var flee_distance: float = 9.0
## Lo mismo, pero si el jugador va corriendo (hace más ruido).
@export var sprint_flee_distance: float = 15.0
## Lo mismo, pero si el jugador va agachado (Ctrl): casi no lo nota.
@export var crouch_flee_distance: float = 2.5
## Deja de huir cuando el jugador está más lejos que esto.
@export var safe_distance: float = 28.0
## Hasta dónde pasea alrededor de su zona.
@export var wander_radius: float = 10.0
## Más lejos que esto del jugador, la gacela no se mueve (ahorra recursos).
@export var sleep_distance: float = 70.0

@export_group("Caza")
## Golpes de hacha para abatirla (el primero la hiere y la hace más lenta).
@export var hits_needed: int = 2
@export var meat_amount: int = 3
## Segundos hasta que vuelve a aparecer en su zona.
@export var respawn_time: float = 180.0


var state: State = State.GRAZE
var home: Vector3
var target: Vector3
var flee_angle: float = 0.0
var state_time: float = 0.0
var think_time: float = 0.0
var anim_time: float = 0.0
var player: Node3D
var player_distance: float = 999.0
var hits: int = 0
var dead: bool = false
var spawn_point: Vector3

@onready var neck: Node3D = $Model/NeckPivot
@onready var legs: Array[Node3D] = [$Model/LegFL, $Model/LegFR, $Model/LegBL, $Model/LegBR]


func _ready() -> void:
	add_to_group("gazelle")
	home = global_position
	spawn_point = global_position
	player = get_tree().get_first_node_in_group("player")
	# Cada gacela "piensa" en un momento distinto para repartir el trabajo.
	think_time = randf() * 0.2
	_start_graze()


func _physics_process(delta: float) -> void:
	if dead:
		return
	think_time -= delta
	if think_time <= 0.0:
		think_time = 0.2  # Revisa al jugador 5 veces por segundo.
		_think()

	if player_distance > sleep_distance:
		return  # Muy lejos: no se mueve ni se anima.

	state_time -= delta
	var direction := Vector3.ZERO
	var speed: float = 0.0

	match state:
		State.GRAZE:
			if state_time <= 0.0:
				_start_walk()
		State.WALK:
			var to_target: Vector3 = target - global_position
			to_target.y = 0.0
			if to_target.length() < 0.5 or state_time <= 0.0 or is_on_wall():
				_start_graze()
			else:
				direction = to_target.normalized()
				speed = walk_speed
		State.FLEE:
			if state_time <= 0.0 and player_distance > safe_distance:
				home = global_position  # Se queda a pastar donde llegó.
				_start_graze()
			else:
				if is_on_wall():
					flee_angle += PI * 0.5  # Choca con algo: cambia de rumbo.
				direction = _away_from_player()
				# Herida corre más despacio: se la puede alcanzar corriendo.
				speed = run_speed * 0.55 if hits > 0 else run_speed

	_move(direction, speed, delta)
	_animate(speed, delta)


func _think() -> void:
	if player == null:
		return
	player_distance = global_position.distance_to(player.global_position)
	var scare: float = flee_distance
	if player.has_method("is_crouching") and player.is_crouching():
		scare = crouch_flee_distance
	elif player.has_method("is_sprinting") and player.is_sprinting():
		scare = sprint_flee_distance
	# Con poco sigilo (Lucía: 0.5) te notan desde el doble de distancia (Etapa 25).
	scare /= Personajes.mod("sigilo_mult")
	if player_distance < scare and state != State.FLEE:
		_start_flee()
		# Avisa a las gacelas cercanas de su manada.
		for other in get_tree().get_nodes_in_group("gazelle"):
			if other != self and other.global_position.distance_to(global_position) < 12.0:
				other.alarm()


## La llama otra gacela que se ha asustado.
func alarm() -> void:
	if state != State.FLEE and not dead:
		_start_flee()


## La llama Tools al golpear con el hacha. Devuelve la carne conseguida
## (0 si solo queda herida).
func hit() -> int:
	if dead:
		return 0
	hits += 1
	if hits < hits_needed:
		_start_flee()
		state_time = 6.0  # Herida, huye más tiempo.
		for other in get_tree().get_nodes_in_group("gazelle"):
			if other != self and other.global_position.distance_to(global_position) < 12.0:
				other.alarm()
		return 0
	_die()
	return meat_amount


func get_hit_text() -> String:
	return "Cazar gacela" if hits == 0 else "Cazar gacela (herida)"


func _die() -> void:
	dead = true
	velocity = Vector3.ZERO
	$CollisionShape3D.set_deferred("disabled", true)
	# Cae de lado, desaparece y vuelve a aparecer más tarde.
	var tween := create_tween()
	tween.tween_property($Model, "rotation:z", PI * 0.5, 0.5)
	tween.tween_interval(1.5)
	tween.tween_callback(hide)
	tween.tween_interval(respawn_time)
	tween.tween_callback(_respawn)


func _respawn() -> void:
	global_position = spawn_point
	home = spawn_point
	$Model.rotation.z = 0.0
	hits = 0
	dead = false
	$CollisionShape3D.disabled = false
	show()
	_start_graze()


func _start_graze() -> void:
	state = State.GRAZE
	state_time = randf_range(3.0, 8.0)


func _start_walk() -> void:
	state = State.WALK
	state_time = 10.0
	var angle: float = randf() * TAU
	var distance: float = randf_range(2.0, wander_radius)
	target = home + Vector3(cos(angle), 0.0, sin(angle)) * distance


func _start_flee() -> void:
	state = State.FLEE
	state_time = 3.0  # Huye al menos 3 segundos.
	# Cada una huye con un ángulo algo distinto para que la manada se abra.
	flee_angle = randf_range(-0.5, 0.5)


func _away_from_player() -> Vector3:
	var away: Vector3 = global_position - player.global_position
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3.FORWARD
	return away.normalized().rotated(Vector3.UP, flee_angle)


func _move(direction: Vector3, speed: float, delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var horizontal := Vector2(velocity.x, velocity.z)
	horizontal = horizontal.move_toward(Vector2(direction.x, direction.z) * speed, 15.0 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.y
	move_and_slide()

	# Gira suavemente hacia donde camina (el modelo mira hacia -Z).
	if direction != Vector3.ZERO:
		var facing: float = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, facing, 8.0 * delta)


func _animate(speed: float, delta: float) -> void:
	# Patas: se balancean más rápido y más fuerte cuanto más corre.
	anim_time += delta * (4.0 + speed * 1.6)
	var swing: float = 0.0
	if speed > 0.1:
		swing = 0.6 if speed > walk_speed + 0.5 else 0.3
	for i in legs.size():
		# Las patas en diagonal se mueven juntas.
		var phase: float = 0.0 if i == 0 or i == 3 else PI
		legs[i].rotation.x = sin(anim_time + phase) * swing

	# Cuello: agachado al pastar, levantado al moverse.
	var neck_angle: float = -1.1 if state == State.GRAZE else 0.0
	neck.rotation.x = lerpf(neck.rotation.x, neck_angle, 3.0 * delta)
