extends CharacterBody3D
## Controlador en primera persona (Etapa 1).
## Va en el nodo raíz "Player" de la escena player.tscn.

@export_group("Movimiento")
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 6.5
## Velocidad agachado (Ctrl): sirve para acercarse a los animales.
@export var crouch_speed: float = 1.8
@export var jump_velocity: float = 4.5
@export var ground_acceleration: float = 30.0
@export var air_acceleration: float = 8.0

@export_group("Energía (estamina)")
## Energía máxima (se multiplica por la "estamina" del personaje).
@export var max_stamina: float = 100.0
## Energía que gasta correr, por segundo.
@export var sprint_cost: float = 15.0
## Energía que gasta cada salto.
@export var jump_cost: float = 12.0
## Energía que se recupera por segundo al caminar (x1.5 si estás parado).
@export var stamina_regen: float = 14.0
## Segundos de espera tras correr o saltar antes de empezar a recuperar.
@export var regen_delay: float = 1.0

@export_group("Cámara")
@export var mouse_sensitivity: float = 0.0025
@export_range(0.0, 89.0) var max_pitch_degrees: float = 85.0

@export_group("Seguridad")
@export var fall_limit: float = -10.0

@onready var head: Node3D = $Head
@onready var tools = $Tools
@onready var hud = $HUD
@onready var survival = $Survival

var stamina: float = 100.0
## Agotado: no puede correr hasta recuperar el 30 % de la energía.
var exhausted: bool = false
var sprinting: bool = false
var regen_wait: float = 0.0
var shown_stamina: float = -1.0
var shown_exhausted: bool = false

var spawn_position: Vector3
var crouching: bool = false
# Último sitio seguro en tierra firme (para volver si te metes en el mar).
var last_safe_position: Vector3
var safe_check_time: float = 0.0
## Por debajo de esta altura estás dentro del mar (el nivel del mar es 0).
const SEA_DEPTH_LIMIT: float = -1.0
const HEAD_HEIGHT: float = 1.6
const CROUCH_HEAD_HEIGHT: float = 1.0


func _ready() -> void:
	spawn_position = global_position
	# Velocidad según el personaje elegido (Etapa 25).
	# Energía según el personaje (Mama Zuri tiene menos) (Etapa 27).
	max_stamina *= Personajes.mod("estamina_mult")
	stamina = max_stamina
	var speed_mult: float = Personajes.mod("velocidad_mult")
	walk_speed *= speed_mult
	sprint_speed *= speed_mult
	crouch_speed *= speed_mult
	last_safe_position = global_position
	# El grupo "player" permite a los animales encontrar al jugador.
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	# (Esc abre el menú de pausa: lo gestiona PauseMenu en main.tscn.)
	if event is InputEventMouseButton and event.pressed:
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
	elif Input.is_action_just_pressed("jump") and stamina >= jump_cost:
		# Saltar cuesta energía (sin energía suficiente no se salta).
		velocity.y = jump_velocity
		stamina -= jump_cost
		regen_wait = regen_delay

	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	var direction: Vector3 = transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)

	crouching = Input.is_action_pressed("crouch")
	var moving: bool = input_dir.length() > 0.1
	# Solo se corre si hay energía y no estás agotado.
	sprinting = Input.is_action_pressed("sprint") and moving and not crouching and not exhausted
	var speed: float = walk_speed
	if crouching:
		speed = crouch_speed
	elif sprinting:
		speed = sprint_speed
	_update_stamina(moving, delta)
	# Con el bastón en la mano se camina un 15 % más rápido (Etapa 26).
	if tools.is_holding("baston"):
		speed *= 1.15

	# Al agacharse, la cámara baja suavemente.
	var head_target: float = CROUCH_HEAD_HEIGHT if crouching else HEAD_HEIGHT
	head.position.y = move_toward(head.position.y, head_target, 4.0 * delta)
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
	_check_sea(delta)


func _check_sea(delta: float) -> void:
	if global_position.y < SEA_DEPTH_LIMIT:
		# Demasiado hondo: vuelves a la orilla.
		global_position = last_safe_position
		velocity = Vector3.ZERO
		get_node("HUD").show_message("El mar es demasiado profundo: vuelves a la orilla")
		return
	# Cada medio segundo, si pisas tierra firme, recuerda este sitio.
	safe_check_time -= delta
	if safe_check_time <= 0.0 and is_on_floor() and global_position.y > 0.5:
		safe_check_time = 0.5
		last_safe_position = global_position


## Las gacelas la usan para saber si te estás acercando con sigilo.
func is_crouching() -> bool:
	return crouching


## ¿Va corriendo? (las gacelas te oyen desde más lejos).
func is_sprinting() -> bool:
	return sprinting


## Gasta o recupera energía y actualiza la barra (Etapa 27).
func _update_stamina(moving: bool, delta: float) -> void:
	if sprinting:
		# Con el bastón correr cansa un 25 % menos.
		var cost: float = sprint_cost * (0.75 if tools.is_holding("baston") else 1.0)
		stamina -= cost * delta
		regen_wait = regen_delay
		if stamina <= 0.0:
			stamina = 0.0
			exhausted = true
			hud.show_message("Estás agotado: camina un poco para recuperar el aliento")
	else:
		regen_wait -= delta
		if regen_wait <= 0.0:
			var rate: float = stamina_regen * (1.0 if moving else 1.5)
			# Con hambre o sed a cero se recupera la mitad.
			if survival.hunger <= 0.0 or survival.thirst <= 0.0:
				rate *= 0.5
			stamina = minf(stamina + rate * delta, max_stamina)
	if exhausted and stamina >= max_stamina * 0.3:
		exhausted = false
	stamina = maxf(stamina, 0.0)

	# La barra solo se redibuja si la energía cambió algo.
	if absf(stamina - shown_stamina) > 0.5 or exhausted != shown_exhausted \
			or (stamina == max_stamina and shown_stamina != max_stamina):
		shown_stamina = stamina
		shown_exhausted = exhausted
		hud.set_stamina(stamina, max_stamina, exhausted)


## Energía al máximo (al dormir o al despertar tras desmayarte).
func restore_stamina() -> void:
	stamina = max_stamina
	exhausted = false


## Vuelve al punto de partida (al caer del mapa o al desmayarse).
func respawn() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
