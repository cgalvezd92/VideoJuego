extends StaticBody3D
## Fogata: la luz y las llamas parpadean un poco (Etapa 4).
## Mírala y pulsa E para cocinar carne cruda (Etapa 12).
## Va en el nodo raíz "Campfire" de campfire.tscn.

@export var base_energy: float = 1.5

@onready var light: OmniLight3D = $Light
@onready var flames: Node3D = $Flames

var time: float = 0.0


func _ready() -> void:
	# Cada fogata empieza en un momento distinto para que no parpadeen igual.
	time = randf() * 10.0
	# El grupo "campfire" permite al jugador saber si está cerca de una fogata.
	add_to_group("campfire")


func get_prompt() -> String:
	var inventory = get_tree().get_first_node_in_group("player").get_node("Inventory")
	var raw: int = inventory.get_amount("carne_cruda")
	if raw > 0:
		return "[E] Cocinar carne cruda (tienes %d)" % raw
	return "Fogata (aquí puedes cocinar carne)"


## La llama el Interactor. Cocina un trozo de carne por pulsación.
func interact(player: Node) -> String:
	var inventory = player.get_node("Inventory")
	if inventory.get_amount("carne_cruda") == 0:
		return "No tienes carne cruda para cocinar"
	if inventory.add_item("carne_cocida", "Carne cocida", 1) == -1:
		return "Inventario lleno"
	inventory.remove_item("carne_cruda", 1)
	return "Cocinaste un trozo de carne"


func _process(delta: float) -> void:
	# Movimiento barato: solo dos senos, sin partículas ni sombras.
	time += delta
	var flicker: float = sin(time * 11.0) * 0.5 + sin(time * 7.3) * 0.5
	light.light_energy = base_energy + flicker * 0.25
	flames.scale = Vector3(1.0, 1.0 + flicker * 0.12, 1.0)
