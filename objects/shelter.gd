extends StaticBody3D
## Refugio de madera: de noche, mira el refugio y pulsa E para dormir hasta
## las 6:00 (Etapa 11). Va en el nodo raíz "Shelter" de shelter.tscn.

## Hora a la que te despiertas.
@export var wake_hour: float = 6.0


func _ready() -> void:
	# El grupo "shelter" sirve para guardar los refugios en la partida.
	add_to_group("shelter")


func get_prompt() -> String:
	var day_night = get_tree().get_first_node_in_group("day_night")
	if day_night.is_night():
		return "[E] Dormir hasta las %02d:00" % int(wake_hour)
	return "Refugio (se puede dormir de 18:00 a 6:00)"


## La llama el Interactor. Devuelve el mensaje que se muestra en pantalla.
func interact(player: Node) -> String:
	var day_night = get_tree().get_first_node_in_group("day_night")
	if not day_night.is_night():
		return "Solo puedes dormir de noche"

	var hours: float = day_night.skip_to_hour(wake_hour)
	# Segundos reales que habrían pasado esas horas (para el hambre y la sed).
	var seconds: float = hours / 24.0 * day_night.day_length_minutes * 60.0
	player.get_node("Survival").rest(seconds)
	player.get_node("HUD").fade()
	return "Dormiste %d horas. ¡Buenos días!" % roundi(hours)
