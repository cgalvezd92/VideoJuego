extends Area3D
## Charca: mírala y pulsa E para beber (Etapa 5).
## Va en el nodo raíz "Water" de water.tscn.

@export var thirst_restored: float = 35.0


func get_prompt() -> String:
	return "[E] Beber"


## La llama el Interactor. Devuelve el mensaje que se muestra en pantalla.
func interact(player: Node) -> String:
	player.get_node("Survival").drink(thirst_restored)
	return "Bebiste agua"
