extends CharacterBody3D
## Controlador en primera persona (Etapa 1).
## Va en el nodo raíz "Player" de la escena player.tscn.

@export_group("Movimiento")
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 6.5
@export var jump_velocity: float = 4.5
@export var ground_acceleration: float = 30.0
@export var air_acceleration: float = 8.0

@export_group("Cámara")
@export var mouse_sensitivity: float = 0.0025
@export_range(0.0, 89.0) var max_pitch_degrees: float = 85.0

@export_group("Seguridad")
@export var fall_limit: float = -10.0

@onready var head: Node3D = $Head

var spawn_position: Vector3


func _ready() -> void:
	spawn_position = global_position
	# El grupo "player" permite a los animales encontrar al jugador.
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Esc libera el mouse.
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		# Un clic vuelve a capturarlo.
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_camera(event.screen_relative)


func _rotate_camera(mouse_delta: Vector2) -> void:
	# El cuerpo gira hacia los lados; la cabeza mira arriba y abajo.
	rotate_y(-mouse_delta.x * mouse_sensitivity)
	head.rotate_x(-mouse_delta.y * mouse_sensitivity)

	var limit: float = deg_to_rad(max_pitch_degrees)
	head.rotation.x = clampf(head.rotation.x, -limit, limit)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	var direction: Vector3 = transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)

	var speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var acceleration: float = ground_acceleration if is_on_floor() else air_acceleration

	var horizontal := Vector2(velocity.x, velocity.z)
	var target := Vector2(direction.x, direction.z) * speed
	horizontal = horizontal.move_toward(target, acceleration * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.y

	move_and_slide()

	# Si caes del mapa, vuelves al punto de partida.
	if global_position.y < fall_limit:
		respawn()


## Vuelve al punto de partida (al caer del mapa o al desmayarse).
func respawn() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
