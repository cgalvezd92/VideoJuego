extends Node
## Supervivencia: vida, hambre y sed (Etapa 5).
## Va en el nodo "Survival", hijo de Player.

## Máximo del hambre y la sed.
@export var max_value: float = 100.0
## Vida máxima: la pone el personaje elegido (Personajes.salud_maxima()).
var max_health: float = 100.0

@export_group("Cuánto bajan (por segundo)")
## 0.2 por segundo = de lleno a vacío en unos 8 minutos.
@export var hunger_per_second: float = 0.2
## 0.33 por segundo = de lleno a vacío en unos 5 minutos.
@export var thirst_per_second: float = 0.33
## Vida que pierdes por segundo si el hambre o la sed están a 0.
@export var empty_damage: float = 2.0

@export_group("Recuperar vida (por segundo)")
## Si el hambre y la sed están por encima de la mitad.
@export var fed_regen: float = 0.5
## Si estás cerca de una fogata.
@export var fire_regen: float = 3.0
@export var fire_radius: float = 4.0

@export_group("Sangrar (Etapa 37)")
## Vida que pierdes por segundo mientras sangras.
@export var bleed_damage: float = 1.0
## Segundos que sangras tras un mordisco si no te vendas.
@export var bleed_seconds: float = 40.0
## Vida que cura una venda.
@export var bandage_heal: float = 15.0

@export_group("Clima (Etapa 39)")
## Horas del día en las que el sol aprieta.
@export var heat_start_hour: float = 11.0
@export var heat_end_hour: float = 16.0
## Sed extra al sol (1.5 = la sed baja 2,5 veces más rápido con aguante normal).
@export var heat_thirst_extra: float = 1.5
## Radio de la sombra de una acacia (se multiplica por su tamaño).
@export var shade_radius: float = 3.2
## Cerca de una fogata a esta distancia no tienes frío.
@export var warm_radius: float = 6.0
## Cerca de un refugio tienes sombra de día y no pasas frío de noche.
@export var shelter_radius: float = 3.5

var health: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var near_fire: bool = false
## Segundos de sangrado que quedan (0 = no sangras).
var bleeding: float = 0.0
## Clima (Etapa 39): calor al sol del mediodía y frío de noche lejos del fuego.
var hot: bool = false
var cold: bool = false
var climate_time: float = 0.0
var day_night: Node
var weather: Node

# Cada cuánto se revisan las fogatas y se redibujan las barras.
# Así no se hace en cada fotograma (ahorra recursos).
var check_time: float = 0.0

@onready var player = owner
@onready var hud = owner.get_node("HUD")


func _ready() -> void:
	# Ajustes según el personaje elegido (Etapa 25).
	max_health = Personajes.salud_maxima()
	health = max_health
	# Dificultad (Etapa 36): en Fácil bajan más despacio, en Difícil más rápido.
	hunger_per_second *= Personajes.mod("hambre_mult") * Personajes.dif("hambre_sed")
	thirst_per_second *= Personajes.mod("sed_mult") * Personajes.dif("hambre_sed")
	fed_regen *= Personajes.mod("curacion_mult")
	fire_regen *= Personajes.mod("curacion_mult")
	bandage_heal *= Personajes.mod("curacion_mult")


func _process(delta: float) -> void:
	hunger = maxf(hunger - hunger_per_second * delta, 0.0)
	# Al sol del mediodía la sed baja más rápido (más con poco aguante al clima).
	var thirst_rate: float = thirst_per_second
	if hot:
		thirst_rate *= 1.0 + heat_thirst_extra * Personajes.dano_clima()
	thirst = maxf(thirst - thirst_rate * delta, 0.0)

	# El clima se revisa una vez por segundo (no en cada fotograma).
	climate_time -= delta
	if climate_time <= 0.0:
		climate_time = 1.0
		_update_climate()

	var change: float = 0.0
	if hunger <= 0.0:
		change -= empty_damage
	if thirst <= 0.0:
		change -= empty_damage
	if bleeding > 0.0:
		# Sangrando: pierdes vida y no te recuperas comiendo (Etapa 37).
		bleeding = maxf(bleeding - delta, 0.0)
		change -= bleed_damage
		if bleeding == 0.0:
			hud.show_message("La herida dejó de sangrar")
	elif hunger > max_value * 0.5 and thirst > max_value * 0.5:
		change += fed_regen
	if near_fire:
		change += fire_regen
	health = clampf(health + change * delta, 0.0, max_health)

	check_time -= delta
	if check_time <= 0.0:
		check_time = 0.25
		near_fire = _is_near_fire()
		hud.set_stats(health, max_health, hunger, thirst, max_value, near_fire, bleeding > 0.0)

	if health <= 0.0:
		_faint()


func eat(amount: float) -> void:
	hunger = minf(hunger + amount, max_value)
	check_time = 0.0  # Actualiza las barras enseguida.


func drink(amount: float) -> void:
	thirst = minf(thirst + amount, max_value)
	get_tree().call_group("objectives", "complete", "beber")  # Etapa 34.
	check_time = 0.0


## Daño recibido (por ejemplo, un mordisco de la hiena).
## Con "bleed" la herida además sangra hasta que te vendes (Etapa 37).
func damage(amount: float, bleed: bool = false) -> void:
	amount *= Personajes.dif("dano")  # Mordiscos más o menos fuertes (Etapa 36).
	health = maxf(health - amount, 0.0)
	if bleed:
		bleeding = bleed_seconds
	check_time = 0.0  # Actualiza las barras enseguida.


## Usar una venda: para la sangre y cura un poco (Etapa 37).
func bandage() -> String:
	var was_bleeding: bool = bleeding > 0.0
	bleeding = 0.0
	health = minf(health + bandage_heal, max_health)
	check_time = 0.0
	if was_bleeding:
		return "Te vendaste la herida: ya no sangras"
	return "Te pusiste una venda: +%d de vida" % roundi(bandage_heal)


## Dormir: el hambre y la sed bajan la mitad de lo normal y recuperas vida.
## "seconds" son los segundos reales que habrían pasado.
func rest(seconds: float) -> void:
	hunger = maxf(hunger - hunger_per_second * seconds * 0.5, 0.0)
	thirst = maxf(thirst - thirst_per_second * seconds * 0.5, 0.0)
	health = minf(health + 30.0, max_health)
	player.restore_stamina()
	check_time = 0.0


## ¿Calor o frío? (Etapa 39)
func _update_climate() -> void:
	if day_night == null:
		day_night = get_tree().get_first_node_in_group("day_night")
		weather = get_tree().get_first_node_in_group("weather")
		if day_night == null:
			return
	var hour: float = day_night.get_hour()
	var raining: bool = weather != null and weather.rain_amount > 0.5
	var near_shelter: bool = _near_group("shelter", shelter_radius)

	var was_hot: bool = hot
	hot = hour >= heat_start_hour and hour < heat_end_hour and not raining \
		and not near_shelter and not _in_shade()
	var was_cold: bool = cold
	cold = day_night.is_night() and not near_shelter and not _near_group("campfire", warm_radius) \
		and not player.get_node("Tools").is_holding_torch()

	if hot and not was_hot:
		hud.show_message("¡Qué calor! Busca la sombra de una acacia o un refugio")
	if cold and not was_cold:
		hud.show_message("Hace frío: acércate a una fogata, a un refugio o usa la antorcha")
	hud.set_climate(hot, cold)


## ¿Estás bajo la copa de una acacia en pie?
func _in_shade() -> bool:
	var here := Vector2(player.global_position.x, player.global_position.z)
	for tree in get_tree().get_nodes_in_group("shade_tree"):
		if tree.felled or not tree.is_inside_tree():
			continue
		var radius: float = shade_radius * tree.scale.x
		if Vector2(tree.global_position.x, tree.global_position.z).distance_squared_to(here) < radius * radius:
			return true
	return false


func _near_group(group: String, radius: float) -> bool:
	for node in get_tree().get_nodes_in_group(group):
		if node.global_position.distance_squared_to(player.global_position) < radius * radius:
			return true
	return false


func _is_near_fire() -> bool:
	for fire in get_tree().get_nodes_in_group("campfire"):
		if fire.global_position.distance_to(player.global_position) < fire_radius:
			return true
	return false


func _faint() -> void:
	# Te desmayas: vuelves al inicio con el inventario intacto.
	health = max_health
	bleeding = 0.0
	player.restore_stamina()
	hunger = max_value * 0.6
	thirst = max_value * 0.6
	player.respawn()
	hud.show_message("Te desmayaste... despiertas en el inicio")
