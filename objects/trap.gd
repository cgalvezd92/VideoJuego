extends StaticBody3D
## Trampa de lazo (Etapa 54): se pone con U delante del jugador.
## Pasadas unas horas del juego (de 3 a 8), puede haber atrapado un conejo
## (65 %) o haber saltado sin nada. Con E:
## - con conejo: das 1 de carne cruda (y a veces 1 piel) y la trampa se vuelve a armar;
## - si saltó vacía: la vuelves a armar.
## No tiene escena: la crea Crafting o SaveGame al cargar.

const HeldItems = preload("res://Player/held_items.gd")

## Probabilidad de atrapar algo.
const CATCH_CHANCE: float = 0.65

## "esperando", "conejo" o "vacia".
var state: String = "esperando"
## Hora del juego en que se comprueba si cayó algo.
var check_at: float = 0.0
var day_night: Node
var timer: float = 0.0
var rabbit: Node3D
var noose: Node3D


func _ready() -> void:
	add_to_group("trap")
	_build_model()
	_update_model()


## Arma la trampa: se revisará dentro de 3 a 8 horas del juego.
func arm() -> void:
	state = "esperando"
	check_at = _hours() + randf_range(3.0, 8.0)
	_update_model()


func _process(delta: float) -> void:
	# Se revisa cada 2 segundos (casi no gasta nada).
	timer -= delta
	if timer > 0.0 or state != "esperando":
		return
	timer = 2.0
	if _hours() >= check_at:
		state = "conejo" if randf() < CATCH_CHANCE else "vacia"
		_update_model()


func _hours() -> float:
	if day_night == null:
		day_night = get_tree().get_first_node_in_group("day_night")
	return 0.0 if day_night == null else day_night.total_hours


func get_prompt() -> String:
	match state:
		"conejo":
			return "[E] Sacar el conejo de la trampa"
		"vacia":
			return "[E] Volver a armar la trampa (saltó sin atrapar nada)"
	var left: float = maxf(check_at - _hours(), 0.0)
	return "Trampa armada: vuelve en unas %d horas" % maxi(1, ceili(left))


func interact(player: Node) -> String:
	var inventory = player.get_node("Inventory")
	match state:
		"conejo":
			if inventory.add_item("carne_cruda", "Carne cruda", 1) == -1:
				return "Inventario lleno"
			var text: String = "Atrapaste un conejo: +1 carne cruda"
			if randf() < 0.3 and inventory.add_item("piel", "Piel", 1) != -1:
				text += " y 1 piel"
			get_tree().call_group("objectives", "count", "conejos")
			arm()
			return text + ". La trampa queda armada otra vez"
		"vacia":
			arm()
			return "Volviste a armar la trampa"
	return "Todavía no ha caído nada. Vuelve más tarde"


func _update_model() -> void:
	if rabbit == null:
		return
	rabbit.visible = state == "conejo"
	# El lazo se ve tenso (armado) o caído (saltó).
	noose.rotation_degrees.x = 0.0 if state == "esperando" else 70.0


func _build_model() -> void:
	var wood := Color("#7a5530")
	var rope := Color("#d8c9a0")
	# Dos estacas, un palo arriba y el lazo colgando.
	for x in [-0.3, 0.3]:
		var stake := HeldItems._part(self, HeldItems._cylinder(0.025, 0.55), wood, Vector3(x, 0.27, 0))
		stake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	HeldItems._part(self, HeldItems._cylinder(0.02, 0.7), wood, Vector3(0, 0.52, 0), Vector3(0, 0, 90))
	noose = Node3D.new()
	noose.position = Vector3(0, 0.52, 0)
	add_child(noose)
	HeldItems._part(noose, HeldItems._box(0.012, 0.3, 0.012), rope, Vector3(0, -0.15, 0))
	var loop := HeldItems._part(noose, _torus(), rope, Vector3(0, -0.36, 0), Vector3(90, 0, 0))
	loop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Conejo atrapado (oculto hasta que cae uno).
	rabbit = Node3D.new()
	add_child(rabbit)
	var fur := Color("#9b8b78")
	var body := HeldItems._part(rabbit, HeldItems._sphere(0.14), fur, Vector3(0.05, 0.12, 0.1))
	body.scale = Vector3(1.3, 0.9, 1.0)
	HeldItems._part(rabbit, HeldItems._sphere(0.08), fur, Vector3(0.24, 0.18, 0.1))
	HeldItems._part(rabbit, HeldItems._box(0.03, 0.14, 0.05), fur, Vector3(0.26, 0.3, 0.07), Vector3(0, 0, -15))
	HeldItems._part(rabbit, HeldItems._box(0.03, 0.14, 0.05), fur, Vector3(0.26, 0.3, 0.13), Vector3(0, 0, -25))
	HeldItems._part(rabbit, HeldItems._sphere(0.04), Color("#f2f0ea"), Vector3(-0.13, 0.12, 0.1))
	for mi in find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 60.0
	# Choque pequeño para que el rayo de la E la encuentre.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, 0.6, 0.5)
	shape.shape = box
	shape.position = Vector3(0, 0.3, 0)
	add_child(shape)


func _torus() -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = 0.07
	t.outer_radius = 0.09
	t.rings = 8
	t.ring_segments = 4
	return t
