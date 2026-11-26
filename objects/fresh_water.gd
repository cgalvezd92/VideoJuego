extends StaticBody3D
## Agua de los ríos, lagos y el mar del mapa (Etapa 24).
## No se pone a mano: MapSetup crea un nodo con este script dentro de las
## mallas "Rios", "Lagos_y_oasis" y "Oceano" del mapa.
##
## Está en la capa de colisión 3: solo la detecta el rayo del Interactor
## (la E). El jugador y los animales no chocan con ella.

## "río", "lago" o "mar".
@export var kind: String = "río"
@export var thirst_restored: float = 35.0


func get_prompt() -> String:
	if kind == "mar":
		return "Agua salada: no se puede beber"
	if _holding_pot():
		return "[E] Llenar la olla de agua"
	return "[E] Beber agua del " + kind


## La llama el Interactor. Devuelve el mensaje que se muestra en pantalla.
func interact(player: Node) -> String:
	if kind == "mar":
		return "El agua del mar es salada: busca un río o un lago"
	if _holding_pot():
		player.get_node("Inventory").add_item("agua", "Agua", 1)
		return "Llenaste la olla: selecciona el agua y haz clic para beber"
	player.get_node("Survival").drink(thirst_restored)
	return "Bebiste agua del " + kind


## ¿Lleva la olla en la mano? (Etapa 26: Kenji puede llevarse agua).
func _holding_pot() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	return player != null and player.get_node("Tools").is_holding("olla")
