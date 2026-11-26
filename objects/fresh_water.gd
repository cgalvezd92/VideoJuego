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
	return "[E] Beber agua del " + kind


## La llama el Interactor. Devuelve el mensaje que se muestra en pantalla.
func interact(player: Node) -> String:
	if kind == "mar":
		return "El agua del mar es salada: busca un río o un lago"
	player.get_node("Survival").drink(thirst_restored)
	return "Bebiste agua del " + kind
