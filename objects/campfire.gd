extends StaticBody3D
## Fogata: la luz y las llamas parpadean un poco (Etapa 4).
## Mírala y pulsa E para cocinar carne cruda (Etapa 12) o pescado (Etapa 33).
## La lluvia la apaga; con E y 1 rama se reaviva (Etapa 30).
## Con piedras en la mano, E la rodea con un muro de 4 piedras: la lluvia
## ya no la apaga (Etapa 43).
## Va en el nodo raíz "Campfire" de campfire.tscn.

@export var base_energy: float = 1.5

@onready var light: OmniLight3D = $Light
@onready var flames: Node3D = $Flames

var time: float = 0.0
## Encendida o apagada (la lluvia la apaga).
var lit: bool = true
## Rodeada por un muro de piedras: la lluvia no la apaga (Etapa 43).
var protected: bool = false
## Piedras que hacen falta para el muro.
const WALL_STONES: int = 4


func _ready() -> void:
	# Cada fogata empieza en un momento distinto para que no parpadeen igual.
	time = randf() * 10.0
	# El grupo "campfire" son las fogatas encendidas: curan y asustan a la hiena.
	add_to_group("campfire")
	# El grupo "fire_pit" son todas, encendidas o apagadas (para guardar y la lluvia).
	add_to_group("fire_pit")


func get_prompt() -> String:
	if not protected and _holding_stones():
		return "[E] Rodear con %d piedras (la lluvia no la apagará)" % WALL_STONES
	if not lit:
		return "[E] Reavivar la fogata (1 rama)"
	var inventory = get_tree().get_first_node_in_group("player").get_node("Inventory")
	var raw: int = inventory.get_amount("carne_cruda")
	if raw > 0:
		return "[E] Cocinar carne cruda (tienes %d)" % raw
	var fish: int = inventory.get_amount("pescado_crudo")
	if fish > 0:
		return "[E] Cocinar pescado crudo (tienes %d)" % fish
	return "Fogata (aquí puedes cocinar carne y pescado)"


## La llama el Interactor. Cocina un trozo de carne por pulsación.
func interact(player: Node) -> String:
	var inventory = player.get_node("Inventory")
	if not protected and _holding_stones():
		if not inventory.remove_item("piedra", WALL_STONES):
			return "Necesitas %d piedras para el muro (tienes %d)" % [WALL_STONES, inventory.get_amount("piedra")]
		protect()
		return "Rodeaste la fogata con piedras: la lluvia ya no la apagará"
	if not lit:
		if not inventory.remove_item("rama", 1):
			return "Necesitas 1 rama para reavivar la fogata"
		relight()
		return "Reavivaste la fogata"
	if inventory.get_amount("carne_cruda") > 0:
		if inventory.add_item("carne_cocida", "Carne cocida", 1) == -1:
			return "Inventario lleno"
		inventory.remove_item("carne_cruda", 1)
		get_tree().call_group("objectives", "complete", "cocinar")
		return "Cocinaste un trozo de carne"
	# Etapa 33: también se cocina el pescado.
	if inventory.get_amount("pescado_crudo") > 0:
		if inventory.add_item("pescado_cocido", "Pescado cocido", 1) == -1:
			return "Inventario lleno"
		inventory.remove_item("pescado_crudo", 1)
		get_tree().call_group("objectives", "complete", "cocinar")
		return "Cocinaste un pescado"
	return "No tienes carne ni pescado crudo para cocinar"


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


func _holding_stones() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	return player != null and player.get_node("Tools").is_holding("piedra")


## Pone el muro de piedras alrededor (Etapa 43). También al cargar la partida.
func protect() -> void:
	if protected:
		return
	protected = true
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#7d786e")
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.32, 0.22)
	for i in 8:
		var angle: float = i * TAU / 8.0
		var stone := MeshInstance3D.new()
		stone.mesh = box
		stone.material_override = material
		stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		stone.position = Vector3(cos(angle), 0.0, sin(angle)) * 0.78 + Vector3(0, 0.16, 0)
		stone.rotation.y = -angle + PI / 2.0
		add_child(stone)
