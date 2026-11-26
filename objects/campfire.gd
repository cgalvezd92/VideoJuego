extends StaticBody3D
## Fogata: la luz y las llamas parpadean un poco (Etapa 4).
## Mírala y pulsa E para cocinar carne cruda (Etapa 12).
## La lluvia la apaga; con E y 1 rama se reaviva (Etapa 30).
## Va en el nodo raíz "Campfire" de campfire.tscn.

@export var base_energy: float = 1.5

@onready var light: OmniLight3D = $Light
@onready var flames: Node3D = $Flames

var time: float = 0.0
## Encendida o apagada (la lluvia la apaga).
var lit: bool = true


func _ready() -> void:
	# Cada fogata empieza en un momento distinto para que no parpadeen igual.
	time = randf() * 10.0
	# El grupo "campfire" son las fogatas encendidas: curan y asustan a la hiena.
	add_to_group("campfire")
	# El grupo "fire_pit" son todas, encendidas o apagadas (para guardar y la lluvia).
	add_to_group("fire_pit")


func get_prompt() -> String:
	if not lit:
		return "[E] Reavivar la fogata (1 rama)"
	var inventory = get_tree().get_first_node_in_group("player").get_node("Inventory")
	var raw: int = inventory.get_amount("carne_cruda")
	if raw > 0:
		return "[E] Cocinar carne cruda (tienes %d)" % raw
	return "Fogata (aquí puedes cocinar carne)"


## La llama el Interactor. Cocina un trozo de carne por pulsación.
func interact(player: Node) -> String:
	var inventory = player.get_node("Inventory")
	if not lit:
		if not inventory.remove_item("rama", 1):
			return "Necesitas 1 rama para reavivar la fogata"
		relight()
		return "Reavivaste la fogata"
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


## La apaga (la lluvia): sin luz ni llamas, no cura ni asusta a la hiena.
func extinguish() -> void:
	lit = false
	remove_from_group("campfire")
	light.visible = false
	flames.visible = false
	set_process(false)


func relight() -> void:
	lit = true
	add_to_group("campfire")
	light.visible = true
	flames.visible = true
	set_process(true)
