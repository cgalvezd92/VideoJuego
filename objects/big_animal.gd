extends "res://objects/gazelle.gd"
## Cebras y jirafas (Etapa 29). Se comportan como las gacelas (pastan,
## pasean y huyen del jugador), pero no se pueden cazar: si las golpeas, se
## asustan y escapan.
## Va en el nodo raíz de zebra.tscn y giraffe.tscn.

## Nombre que aparece en los avisos ("Cebra", "Jirafa").
@export var animal_name: String = "Cebra"


## Golpe con un arma o una flecha: no da carne, solo la asusta.
func hit() -> int:
	if dead:
		return 0
	_start_flee()
	state_time = 5.0
	return 0


func get_hit_text() -> String:
	return "%s (no se puede cazar)" % animal_name


func get_hit_message() -> String:
	return "La %s se asusta y huye" % animal_name.to_lower()
