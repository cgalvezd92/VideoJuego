extends StaticBody3D
## Arbusto con bayas: pulsa E para comer. Las bayas vuelven a crecer (Etapa 5).
## Algunos son venenosos (Etapa 38): sus bayas son algo más oscuras y quitan
## vida y sed. Mama Zuri (conoce_plantas) los reconoce y no se las come.
## Después de probar uno venenoso, ese arbusto queda marcado como venenoso.
## Va en el nodo raíz "BerryBush" de berry_bush.tscn.

@export var hunger_restored: float = 25.0
## Segundos hasta que vuelven a salir bayas.
@export var regrow_time: float = 60.0

@export_group("Veneno (Etapa 38)")
## Marca esta casilla en el Inspector para que el arbusto sea venenoso.
@export var poisonous: bool = false
@export var poison_damage: float = 15.0
@export var poison_thirst: float = 15.0

## Color de las bayas venenosas: parecido al bueno, pero más oscuro.
const POISON_COLOR := Color(0.42, 0.06, 0.22)
static var _poison_material: StandardMaterial3D

@onready var berries: Node3D = $Berries

var has_berries: bool = true
## ¿Ya sabe el jugador que este arbusto es venenoso?
var known_poisonous: bool = false


func _ready() -> void:
	if poisonous:
		set_poisonous(true)


## La usa World para hacer venenoso un arbusto que crea por código.
func set_poisonous(value: bool) -> void:
	poisonous = value
	if not poisonous:
		return
	if _poison_material == null:
		_poison_material = StandardMaterial3D.new()
		_poison_material.albedo_color = POISON_COLOR
	for berry in berries.get_children():
		berry.material_override = _poison_material


func _player_knows() -> bool:
	return known_poisonous or Personajes.mod("conoce_plantas")


func get_prompt() -> String:
	if not has_berries:
		return "Arbusto venenoso (sin bayas)" if poisonous and _player_knows() else "Arbusto sin bayas"
	if poisonous and _player_knows():
		if Personajes.mod("conoce_plantas"):
			return "Bayas venenosas (Mama Zuri las reconoce)"
		return "Bayas venenosas: no te las comas"
	return "[E] Comer bayas"


## La llama el Interactor. Devuelve el mensaje que se muestra en pantalla.
func interact(player: Node) -> String:
	if not has_berries:
		return "Las bayas todavía no han vuelto a crecer"
	if poisonous and _player_knows():
		if Personajes.mod("conoce_plantas"):
			return "«Estas no, son venenosas», dice Mama Zuri"
		return "Ya sabes que estas bayas son venenosas"

	var survival = player.get_node("Survival")
	has_berries = false
	berries.visible = false
	_regrow()
	if poisonous:
		known_poisonous = true
		survival.health = maxf(survival.health - poison_damage, 1.0)
		survival.thirst = maxf(survival.thirst - poison_thirst, 0.0)
		survival.check_time = 0.0
		player.get_node("HUD").flash_damage()
		return "¡Bayas venenosas! Te sientan fatal (-%d vida, -%d sed)" % [poison_damage, poison_thirst]
	survival.eat(hunger_restored)
	return "Comiste bayas"


func _regrow() -> void:
	# Espera sin usar _process: un temporizador avisa cuando termina.
	await get_tree().create_timer(regrow_time).timeout
	if not is_inside_tree():
		return
	has_berries = true
	berries.visible = true
