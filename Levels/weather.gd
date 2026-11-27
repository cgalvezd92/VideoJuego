extends Node
## Lluvia (Etapa 30). Va en el nodo "Weather", hijo de Main (en main.tscn).
##
## De vez en cuando empieza a llover durante unas horas del juego: cae lluvia
## alrededor del jugador, el cielo se oscurece (lo aplica DayNight), las
## fogatas que no están junto a un refugio se apagan y la olla se llena sola.

## Cada cuántos segundos reales se tira el dado para ver si empieza a llover.
@export var check_every: float = 30.0
@export_range(0.0, 1.0) var rain_chance: float = 0.12
## Duración de la lluvia, en horas del juego (1 hora = unos 25 s reales).
@export var min_hours: float = 1.5
@export var max_hours: float = 3.0
## Una fogata a esta distancia de un refugio no se apaga con la lluvia.
@export var shelter_protect_radius: float = 4.5
## Cada cuántos segundos de lluvia se añade 1 de agua si llevas la olla.
@export var pot_fill_seconds: float = 20.0
@export var max_pot_water: int = 5

var raining: bool = false
var rain_until: float = 0.0
## De 0 (seco) a 1 (lluvia fuerte); sube y baja poco a poco.
var rain_amount: float = 0.0
var check_time: float = 0.0
var fire_check: float = 0.0
var pot_time: float = 0.0
var rain_fx: GPUParticles3D

@onready var day_night = $"../DayNight"
@onready var player: Node3D = $"../Player"
@onready var hud = $"../Player/HUD"


func _ready() -> void:
	add_to_group("weather")
	check_time = check_every
	rain_fx = _make_rain()
	player.add_child(rain_fx)  # La lluvia acompaña al jugador.


func _process(delta: float) -> void:
	check_time -= delta
	if not raining and check_time <= 0.0:
		check_time = check_every
		if randf() < rain_chance:
			start_rain()
	if raining and day_night.total_hours >= rain_until:
		stop_rain()

	# La intensidad cambia despacio (unos 8 s para empezar o parar del todo).
	rain_amount = move_toward(rain_amount, 1.0 if raining else 0.0, delta / 8.0)
	rain_fx.emitting = rain_amount > 0.01
	rain_fx.amount_ratio = rain_amount

	if raining:
		fire_check -= delta
		if fire_check <= 0.0:
			fire_check = 3.0
			_douse_fires()
		pot_time += delta
		if pot_time >= pot_fill_seconds:
			pot_time = 0.0
			_fill_pot()


## Empieza a llover. "hours" opcional: cuántas horas del juego dura.
func start_rain(hours: float = -1.0) -> void:
	raining = true
	pot_time = 0.0
	if hours <= 0.0:
		hours = randf_range(min_hours, max_hours)
	rain_until = day_night.total_hours + hours
	hud.show_message("Empieza a llover: protege tus fogatas junto a un refugio")


func stop_rain() -> void:
	raining = false
	hud.show_message("Ha dejado de llover")


## Apaga las fogatas que no están junto a un refugio (con lluvia fuerte).
func _douse_fires() -> void:
	if rain_amount < 0.5:
		return
	for fire in get_tree().get_nodes_in_group("fire_pit"):
		# Las rodeadas de piedras aguantan la lluvia (Etapa 43).
		if fire.lit and not fire.protected and not _is_sheltered(fire.global_position):
			fire.extinguish()
			hud.show_message("La lluvia apagó una fogata (E para reavivarla con 1 rama)")


func _is_sheltered(where: Vector3) -> bool:
	for shelter in get_tree().get_nodes_in_group("shelter"):
		if shelter.global_position.distance_to(where) < shelter_protect_radius:
			return true
	return false


## Si llevas la olla, la lluvia la llena poco a poco.
func _fill_pot() -> void:
	var inventory = player.get_node("Inventory")
	if inventory.get_amount("olla") == 0 or inventory.get_amount("agua") >= max_pot_water:
		return
	if inventory.add_item("agua", "Agua", 1) != -1:
		hud.show_message("La lluvia llena tu olla: +1 agua")


## Partículas de lluvia: 700 gotas finas que caen en una caja de 32 x 32 m
## alrededor del jugador. Se calculan en la tarjeta gráfica (GPU): muy barato.
func _make_rain() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Rain"
	particles.amount = 700
	particles.lifetime = 1.0
	particles.local_coords = false
	particles.emitting = false
	particles.position = Vector3(0, 9, 0)
	particles.visibility_aabb = AABB(Vector3(-20, -15, -20), Vector3(40, 30, 40))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(16, 1, 16)
	process.direction = Vector3(0, -1, 0)
	process.spread = 3.0
	process.initial_velocity_min = 16.0
	process.initial_velocity_max = 20.0
	process.gravity = Vector3(0, -9.8, 0)
	particles.process_material = process

	var drop := QuadMesh.new()
	drop.size = Vector2(0.02, 0.5)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.75, 0.8, 0.9, 0.45)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	material.billboard_keep_scale = true
	drop.material = material
	particles.draw_pass_1 = drop
	return particles
