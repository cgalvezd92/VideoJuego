extends Area3D
## Charca: mírala y pulsa E para beber (Etapa 5).
## Va en el nodo raíz "Water" de water.tscn.

@export var thirst_restored: float = 35.0


func _ready() -> void:
	# El grupo "water" sirve para que no crezca hierba dentro de la charca.
	add_to_group("water")


func get_prompt() -> String:
	if _holding_pot():
		return "[E] Llenar la olla de agua"
	return "[E] Beber"


## La llama el Interactor. Devuelve el mensaje que se muestra en pantalla.
func interact(player: Node) -> String:
	if _holding_pot():
		player.get_node("Inventory").add_item("agua", "Agua", 1)
		return "Llenaste la olla: selecciona el agua y haz clic para beber"
	player.get_node("Survival").drink(thirst_restored)
	return "Bebiste agua"


## ¿Lleva la olla en la mano? (Etapa 26: Kenji puede llevarse agua).
func _holding_pot() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	return player != null and player.get_node("Tools").is_holding("olla")
