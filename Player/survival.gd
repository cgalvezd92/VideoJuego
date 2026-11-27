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

var health: float = 100.0
var hunger: float = 100.0
var thirst: float = 100.0
var near_fire: bool = false

# Cada cuánto se revisan las fogatas y se redibujan las barras.
# Así no se hace en cada fotograma (ahorra recursos).
var check_time: float = 0.0

@onready var player = owner
@onready var hud = owner.get_node("HUD")


func _ready() -> void:
	# Ajustes según el personaje elegido (Etapa 25).
	max_health = Personajes.salud_maxima()
	health = max_health
	hunger_per_second *= Personajes.mod("hambre_mult")
	thirst_per_second *= Personajes.mod("sed_mult")
	fed_regen *= Personajes.mod("curacion_mult")
	fire_regen *= Personajes.mod("curacion_mult")


func _process(delta: float) -> void:
	hunger = maxf(hunger - hunger_per_second * delta, 0.0)
	thirst = maxf(thirst - thirst_per_second * delta, 0.0)

	var change: float = 0.0
	if hunger <= 0.0:
		change -= empty_damage
	if thirst <= 0.0:
		change -= empty_damage
	if hunger > max_value * 0.5 and thirst > max_value * 0.5:
		change += fed_regen
	if near_fire:
		change += fire_regen
	health = clampf(health + change * delta, 0.0, max_health)

	check_time -= delta
	if check_time <= 0.0:
		check_time = 0.25
		near_fire = _is_near_fire()
		hud.set_stats(health, max_health, hunger, thirst, max_value, near_fire)

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
func damage(amount: float) -> void:
	health = maxf(health - amount, 0.0)
	check_time = 0.0  # Actualiza las barras enseguida.


## Dormir: el hambre y la sed bajan la mitad de lo normal y recuperas vida.
## "seconds" son los segundos reales que habrían pasado.
func rest(seconds: float) -> void:
	hunger = maxf(hunger - hunger_per_second * seconds * 0.5, 0.0)
	thirst = maxf(thirst - thirst_per_second * seconds * 0.5, 0.0)
	health = minf(health + 30.0, max_health)
	player.restore_stamina()
	check_time = 0.0


func _is_near_fire() -> bool:
	for fire in get_tree().get_nodes_in_group("campfire"):
		if fire.global_position.distance_to(player.global_position) < fire_radius:
			return true
	return false


func _faint() -> void:
	# Te desmayas: vuelves al inicio con el inventario intacto.
	health = max_health
	player.restore_stamina()
	hunger = max_value * 0.6
	thirst = max_value * 0.6
	player.respawn()
	hud.show_message("Te desmayaste... despiertas en el inicio")
