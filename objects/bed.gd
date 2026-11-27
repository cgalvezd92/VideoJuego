extends StaticBody3D
## Cama de pieles (Etapa 41): de noche, míralo y pulsa E para dormir hasta
## las 6:00. Cura el doble que el refugio solo y para la sangre.
## No tiene escena: la crea Crafting (tecla N) o SaveGame al cargar.

const HeldItems = preload("res://Player/held_items.gd")

@export var wake_hour: float = 6.0
## Vida que recuperas al dormir en la cama (el refugio solo da 30).
@export var sleep_heal: float = 60.0


func _ready() -> void:
	add_to_group("bed")
	_build_model()


func get_prompt() -> String:
	var day_night = get_tree().get_first_node_in_group("day_night")
	if day_night.is_night():
		return "[E] Dormir en la cama hasta las %02d:00" % int(wake_hour)
	return "Cama de pieles (se puede dormir de 18:00 a 6:00)"


## La llama el Interactor. Devuelve el mensaje que se muestra en pantalla.
func interact(player: Node) -> String:
	var day_night = get_tree().get_first_node_in_group("day_night")
	if not day_night.is_night():
		return "Solo puedes dormir de noche"
	var hours: float = day_night.skip_to_hour(wake_hour)
	var seconds: float = hours / 24.0 * day_night.day_length_minutes * 60.0
	var survival = player.get_node("Survival")
	survival.rest(seconds, sleep_heal)
	survival.bleeding = 0.0
	player.get_node("HUD").fade()
	get_tree().call_group("objectives", "complete", "dormir")
	return "Dormiste %d horas en la cama de pieles. ¡Qué bien se descansa!" % roundi(hours)


func _build_model() -> void:
	var wood := Color("#6b4626")
	var hide := Color("#b08050")
	# Marco de madera con patas y colchón de pieles.
	HeldItems._part(self, HeldItems._box(1.0, 0.12, 2.0), wood, Vector3(0, 0.2, 0))
	for x in [-0.45, 0.45]:
		for z in [-0.95, 0.95]:
			HeldItems._part(self, HeldItems._box(0.1, 0.2, 0.1), wood, Vector3(x, 0.1, z))
	HeldItems._part(self, HeldItems._box(0.92, 0.1, 1.9), hide, Vector3(0, 0.31, 0))
	HeldItems._part(self, HeldItems._box(0.6, 0.1, 0.3), Color("#d8c9a0"), Vector3(0, 0.4, -0.75))
	HeldItems._part(self, HeldItems._box(0.94, 0.04, 1.0), Color("#8a5f36"), Vector3(0, 0.37, 0.4))
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 0.45, 2.0)
	shape.shape = box
	shape.position = Vector3(0, 0.22, 0)
	add_child(shape)
