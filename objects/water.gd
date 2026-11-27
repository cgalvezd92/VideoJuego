extends Area3D
## Charca: mírala y pulsa E para beber (Etapa 5).
## Va en el nodo raíz "Water" de water.tscn.

@export var thirst_restored: float = 35.0

## En la estación seca la charca se seca (Etapa 50). Lo cambia Weather.
var dry: bool = false


func _ready() -> void:
	# El grupo "water" sirve para que no crezca hierba dentro de la charca.
	add_to_group("water")


## La seca o la vuelve a llenar (Etapa 50): el agua se oculta.
func set_dry(value: bool) -> void:
	dry = value
	for child in get_children():
		if child is MeshInstance3D:
			child.visible = not dry


func get_prompt() -> String:
	if dry:
		return "Charca seca (estación seca): busca un río o un lago"
	if _holding_pot():
		return "[E] Llenar la olla de agua"
	return "[E] Beber"


## La llama el Interactor. Devuelve el mensaje que se muestra en pantalla.
func interact(player: Node) -> String:
	if dry:
		return "La charca está seca: busca un río o un lago"
	if _holding_pot():
		player.get_node("Inventory").add_item("agua", "Agua", 1)
		return "Llenaste la olla: selecciona el agua y haz clic para beber"
	player.get_node("Survival").drink(thirst_restored)
	return "Bebiste agua"


## ¿Lleva la olla en la mano? (Etapa 26: Kenji puede llevarse agua).
func _holding_pot() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	return player != null and player.get_node("Tools").is_holding("olla")
