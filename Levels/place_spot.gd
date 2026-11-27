extends StaticBody3D
## Una zona de un lugar especial que se mira con E (Etapa 47): el panal del
## baobab, el botiquín del avión o la entrada de una cueva.
## La crea Places (places.gd), que decide qué pasa al pulsar E.

## "miel", "botiquin" o "cueva".
var kind: String = ""
var places: Node
## Para las cuevas: a esta distancia te protege de la lluvia, el frío y el sol.
var cover_radius: float = 0.0


func get_prompt() -> String:
	return places.spot_prompt(kind)


func interact(_player: Node) -> String:
	return places.spot_interact(kind)
