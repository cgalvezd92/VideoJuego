extends Node
## Lluvia (Etapa 30), tormentas de arena (Etapa 49) y estaciones (Etapa 50).
##
## Estaciones: cada SEASON_DAYS días cambia entre la estación seca (casi no
## llueve, más sed, charcas secas, ríos bajos y hierba amarilla) y la lluviosa
## (llueve mucho, ríos y lagos más altos y hierba verde).
## Va en el nodo "Weather", hijo de Main (en main.tscn).
##
## Tormentas de arena: solo en el desierto del norte (más al norte que
## DESERT_Z). La arena vuela alrededor del jugador, la bruma se vuelve color
## arena y muy cercana (se ve muy poco) y la sed baja más rápido, salvo en un
## refugio o una cueva.
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

@export_group("Estaciones (Etapa 50)")
## Días que dura cada estación. Se empieza en la seca.
@export var season_days: int = 5
## Cuánto suben (lluviosa) o bajan (seca) los ríos y lagos, en metros.
@export var rainy_water_rise: float = 0.45
@export var dry_water_drop: float = 0.25

@export_group("Tormenta de arena (Etapa 49)")
## Al norte de esta Z (metros) empieza el desierto.
@export var desert_z: float = -200.0
@export_range(0.0, 1.0) var sandstorm_chance: float = 0.2
## Duración, en horas del juego.
@export var sandstorm_min_hours: float = 1.0
@export var sandstorm_max_hours: float = 2.0

var raining: bool = false
var rain_until: float = 0.0
## De 0 (seco) a 1 (lluvia fuerte); sube y baja poco a poco.
var rain_amount: float = 0.0
var check_time: float = 0.0
var fire_check: float = 0.0
var pot_time: float = 0.0
var rain_fx: GPUParticles3D
var sandstorm: bool = false
var sandstorm_until: float = 0.0
## De 0 (nada) a 1 (tormenta fuerte); sube y baja poco a poco.
var sand_amount: float = 0.0
var sand_check: float = 0.0
var was_in_desert: bool = false
var sand_fx: GPUParticles3D
## Cantidad de partículas según la calidad (Etapa 52).
var particle_factor: float = 1.0
## "seca" o "lluviosa".
var season: String = ""
## Nivel del agua de ríos y lagos (-1 seca, 0 normal, 1 lluviosa); cambia despacio.
var water_level: float = 0.0
var water_meshes: Array[Node3D] = []
var water_base_y: Array[float] = []
var season_check: float = 0.0

@onready var day_night = $"../DayNight"
@onready var player: Node3D = $"../Player"
@onready var hud = $"../Player/HUD"


func _ready() -> void:
	add_to_group("weather")
	check_time = check_every
	rain_fx = _make_rain()
	player.add_child(rain_fx)  # La lluvia acompaña al jugador.
	sand_fx = _make_sand()
	player.add_child(sand_fx)


func _process(delta: float) -> void:
	check_time -= delta
	if not raining and check_time <= 0.0:
		check_time = check_every
		# En el desierto casi no llueve; en la estación lluviosa mucho más.
		var chance: float = rain_chance * (0.25 if in_desert() else 1.0)
		chance *= 2.5 if season == "lluviosa" else 0.3
		if randf() < chance and not sandstorm:
			start_rain()
	_update_sandstorm(delta)
	_update_season(delta)
	if raining and day_night.total_hours >= rain_until:
		stop_rain()

	# La intensidad cambia despacio (unos 8 s para empezar o parar del todo).
	rain_amount = move_toward(rain_amount, 1.0 if raining else 0.0, delta / 8.0)
	rain_fx.emitting = rain_amount > 0.01
	rain_fx.amount_ratio = rain_amount * particle_factor

	if raining:
		fire_check -= delta
		if fire_check <= 0.0:
			fire_check = 3.0
			_douse_fires()
		pot_time += delta
		if pot_time >= pot_fill_seconds:
			pot_time = 0.0
			_fill_pot()


# --- Estaciones (Etapa 50) ---

## Estación según el día del juego: días 1-5 seca, 6-10 lluviosa, 11-15 seca...
func current_season() -> String:
	var day: int = int(day_night.total_hours / 24.0)
	return "seca" if (day / season_days) % 2 == 0 else "lluviosa"


func _update_season(delta: float) -> void:
	season_check -= delta
	if season_check <= 0.0:
		season_check = 1.0
		var now: String = current_season()
		if now != season:
			var first: bool = season == ""
			season = now
			_apply_season(first)
	# El agua de ríos y lagos sube o baja poco a poco (unos 40 s de seca a lluviosa).
	var target: float = 1.0 if season == "lluviosa" else -1.0
	if water_level != target:
		water_level = move_toward(water_level, target, delta / 20.0)
		_move_water()


func _apply_season(first: bool) -> void:
	var dry_season: bool = season == "seca"
	for pond in get_tree().get_nodes_in_group("water"):
		if pond.has_method("set_dry"):
			pond.set_dry(dry_season)
	var grass = get_node_or_null("../Nature/Grass")
	if grass != null and grass.material != null:
		grass.material.albedo_color = Color(1.15, 1.0, 0.65) if dry_season else Color(0.8, 1.15, 0.8)
	if first:
		water_level = 1.0 if not dry_season else -1.0
		_move_water()
		return
	if dry_season:
		hud.show_message("Empieza la estación seca: llueve poco, las charcas se secan y los ríos bajan")
	else:
		hud.show_message("Empieza la estación de lluvias: los ríos crecen y las charcas se llenan")


## Mueve las mallas de ríos y lagos (con su colisión para beber).
func _move_water() -> void:
	if water_meshes.is_empty():
		for mesh in get_node("../Mapa").find_children("*", "MeshInstance3D", true, false):
			if str(mesh.name) == "Rios" or str(mesh.name) == "Lagos_y_oasis":
				water_meshes.append(mesh)
				water_base_y.append(mesh.position.y)
	var offset: float = water_level * (rainy_water_rise if water_level > 0.0 else dry_water_drop)
	for i in water_meshes.size():
		water_meshes[i].position.y = water_base_y[i] + offset


## ¿Está el jugador en el desierto del norte? (Etapa 49)
func in_desert() -> bool:
	return player.global_position.z < desert_z


func _update_sandstorm(delta: float) -> void:
	var desert: bool = in_desert()
	if desert and not was_in_desert:
		hud.show_message("Entras en el desierto: lleva agua, aquí hay tormentas de arena")
	was_in_desert = desert
	sand_check -= delta
	if sand_check <= 0.0:
		sand_check = 25.0
		if desert and not sandstorm and not raining and randf() < sandstorm_chance:
			start_sandstorm()
	if sandstorm and (day_night.total_hours >= sandstorm_until or not desert):
		sandstorm = false
		if desert:
			hud.show_message("La tormenta de arena se calma")
	# Unos 6 s para empezar o parar del todo.
	sand_amount = move_toward(sand_amount, 1.0 if sandstorm and desert else 0.0, delta / 6.0)
	sand_fx.emitting = sand_amount > 0.01
	sand_fx.amount_ratio = sand_amount * particle_factor


func start_sandstorm(hours: float = -1.0) -> void:
	sandstorm = true
	if hours <= 0.0:
		hours = randf_range(sandstorm_min_hours, sandstorm_max_hours)
	sandstorm_until = day_night.total_hours + hours
	hud.show_message("¡Tormenta de arena! Casi no se ve y da mucha sed: busca refugio o una cueva")


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
	# Cuevas (Etapa 47).
	for cover in get_tree().get_nodes_in_group("cover"):
		if cover.global_position.distance_to(where) < cover.cover_radius:
			return true
	return false


## Si llevas la olla, la lluvia la llena poco a poco.
func _fill_pot() -> void:
	var inventory = player.get_node("Inventory")
	if inventory.get_amount("olla") == 0 or inventory.get_amount("agua") >= max_pot_water:
		return
	if inventory.add_item("agua", "Agua", 1) != -1:
		hud.show_message("La lluvia llena tu olla: +1 agua")


## Partículas de arena: 500 granos que vuelan de lado alrededor del jugador.
func _make_sand() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Sand"
	particles.amount = 500
	particles.lifetime = 1.2
	particles.local_coords = false
	particles.emitting = false
	particles.position = Vector3(0, 1.5, 0)
	particles.visibility_aabb = AABB(Vector3(-20, -6, -20), Vector3(40, 12, 40))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(14, 3, 14)
	process.direction = Vector3(1, 0.05, 0.3)
	process.spread = 12.0
	process.initial_velocity_min = 14.0
	process.initial_velocity_max = 20.0
	process.gravity = Vector3(0, -1.0, 0)
	particles.process_material = process
	var grain := QuadMesh.new()
	grain.size = Vector2(0.35, 0.06)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.85, 0.68, 0.42, 0.55)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	grain.material = material
	particles.draw_pass_1 = grain
	return particles


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
