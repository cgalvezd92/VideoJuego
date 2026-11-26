extends StaticBody3D
## Arbusto con bayas: pulsa E para comer. Las bayas vuelven a crecer (Etapa 5).
## Va en el nodo raíz "BerryBush" de berry_bush.tscn.

@export var hunger_restored: float = 25.0
## Segundos hasta que vuelven a salir bayas.
@export var regrow_time: float = 60.0

@onready var berries: Node3D = $Berries

var has_berries: bool = true


func get_prompt() -> String:
	return "[E] Comer bayas" if has_berries else "Arbusto sin bayas"


## La llama el Interactor. Devuelve el mensaje que se muestra en pantalla.
func interact(player: Node) -> String:
	if not has_berries:
		return "Las bayas todavía no han vuelto a crecer"

	player.get_node("Survival").eat(hunger_restored)
	has_berries = false
	berries.visible = false
	_regrow()
	Sounds.play("eat")
	return "Comiste bayas"


func _regrow() -> void:
	# Espera sin usar _process: un temporizador avisa cuando termina.
	await get_tree().create_timer(regrow_time).timeout
	has_berries = true
	berries.visible = true
