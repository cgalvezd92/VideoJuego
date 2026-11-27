extends StaticBody3D
## Punto de extracción (Etapa 34): un campamento con una radio, una bandera
## roja y una columna de humo que se ve desde lejos. El día 15 a las 7:00
## aterriza un helicóptero: míralo y pulsa E para subir y ganar la partida.
## Va en el nodo "Extraction" (StaticBody3D), hijo de Main (en main.tscn).
## Todo el modelo se crea por código con figuras sencillas.

const HeldItems = preload("res://Player/held_items.gd")
const MapSetup = preload("res://Levels/map_setup.gd")

## Dónde está (X y Z del mundo). La altura se pone sola sobre el suelo.
@export var spot := Vector2(-52.0, -245.0)

var helicopter: Node3D
var rotor: Node3D
var radio_shape: CollisionShape3D
var helicopter_shape: CollisionShape3D
var objectives: Node
var check_time: float = 0.0


func _ready() -> void:
	add_to_group("extraction")
	_build()
	helicopter.visible = false
	helicopter_shape.disabled = true
	global_position = Vector3(spot.x, 0.0, spot.y)
	# Espera a que el terreno tenga colisión para ponerse encima.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var ground = MapSetup.ground_height(get_world_3d(), spot.x, spot.y)
	if ground != null:
		global_position.y = ground


func _process(delta: float) -> void:
	if objectives == null:
		objectives = get_tree().get_first_node_in_group("objectives")
		return
	# Una vez por segundo: ¿ya llegó el helicóptero?
	check_time -= delta
	if check_time <= 0.0:
		check_time = 1.0
		var ready: bool = objectives.rescue_ready()
		if ready != helicopter.visible:
			helicopter.visible = ready
			helicopter_shape.disabled = not ready
	if helicopter.visible:
		rotor.rotation.y += delta * 2.0  # Las aspas giran despacio.


func get_prompt() -> String:
	if objectives == null:
		return ""
	if objectives.rescued:
		return "Helicóptero de rescate (ya te rescataron)"
	if objectives.rescue_ready():
		return "[E] Subir al helicóptero"
	return "[E] Radio del punto de extracción"


## La llama el Interactor. Devuelve el mensaje que se muestra en pantalla.
func interact(_player: Node) -> String:
	if objectives == null or objectives.rescued:
		return ""
	if objectives.rescue_ready():
		objectives.finish_mission()
		return ""
	return "Radio: «Aguanta. Llegaremos el día %d a las 7:00» (faltan %d días)" % [
		objectives.DAYS_TO_SURVIVE + 1, objectives.days_left()]


func _build() -> void:
	# Helipuerto: plataforma de tablas con una H amarilla.
	HeldItems._part(self, HeldItems._box(8.0, 0.15, 8.0), Color("#6b5236"), Vector3(0, 0.07, 0))
	HeldItems._part(self, HeldItems._box(0.5, 0.02, 4.0), Color("#e8c23a"), Vector3(-1.2, 0.16, 0))
	HeldItems._part(self, HeldItems._box(0.5, 0.02, 4.0), Color("#e8c23a"), Vector3(1.2, 0.16, 0))
	HeldItems._part(self, HeldItems._box(2.0, 0.02, 0.5), Color("#e8c23a"), Vector3(0, 0.16, 0))

	# Radio sobre una caja, al borde de la plataforma.
	HeldItems._part(self, HeldItems._box(1.0, 0.8, 0.7), Color("#7a5530"), Vector3(5.0, 0.4, 0))
	HeldItems._part(self, HeldItems._box(0.6, 0.35, 0.4), Color("#3b4a3a"), Vector3(5.0, 0.98, 0))
	HeldItems._part(self, HeldItems._cylinder(0.015, 0.9), Color("#222222"), Vector3(5.2, 1.6, 0.1))

	# Mástil con bandera roja y columna de humo (se ve desde lejos).
	HeldItems._part(self, HeldItems._cylinder(0.06, 7.0), Color("#4a3320"), Vector3(-5.0, 3.5, -3.5))
	HeldItems._part(self, HeldItems._box(1.4, 0.8, 0.04), Color("#d42a20"), Vector3(-4.3, 6.5, -3.5), Vector3.ZERO, true)
	var smoke: MeshInstance3D = HeldItems._part(self, HeldItems._cylinder(1.0, 45.0), Color(0.85, 0.85, 0.85), Vector3(-5.5, 23.0, 4.0))
	var smoke_material: StandardMaterial3D = smoke.material_override
	smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_material.albedo_color.a = 0.35
	smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Choque de la radio (para que el rayo de la E la encuentre).
	radio_shape = _add_shape(Vector3(1.4, 1.8, 1.0), Vector3(5.0, 0.9, 0))

	# Helicóptero (oculto hasta el día 15 a las 7:00).
	helicopter = Node3D.new()
	add_child(helicopter)
	var green := Color("#4f5d3a")
	HeldItems._part(helicopter, HeldItems._box(1.8, 1.6, 3.4), green, Vector3(0, 1.3, 0))
	HeldItems._part(helicopter, HeldItems._box(1.6, 1.1, 1.0), Color("#9fc4d6"), Vector3(0, 1.45, -1.9))
	HeldItems._part(helicopter, HeldItems._box(0.35, 0.35, 4.0), green, Vector3(0, 1.7, 3.6))
	HeldItems._part(helicopter, HeldItems._box(0.1, 1.0, 0.6), green, Vector3(0.2, 2.1, 5.4))
	HeldItems._part(helicopter, HeldItems._box(0.1, 0.1, 3.8), Color("#333333"), Vector3(-0.8, 0.25, 0))
	HeldItems._part(helicopter, HeldItems._box(0.1, 0.1, 3.8), Color("#333333"), Vector3(0.8, 0.25, 0))
	HeldItems._part(helicopter, HeldItems._box(0.08, 0.5, 0.08), Color("#333333"), Vector3(-0.8, 0.5, 0))
	HeldItems._part(helicopter, HeldItems._box(0.08, 0.5, 0.08), Color("#333333"), Vector3(0.8, 0.5, 0))
	HeldItems._part(helicopter, HeldItems._cylinder(0.1, 0.4), Color("#333333"), Vector3(0, 2.25, 0))
	rotor = Node3D.new()
	rotor.position = Vector3(0, 2.45, 0)
	helicopter.add_child(rotor)
	HeldItems._part(rotor, HeldItems._box(8.0, 0.05, 0.3), Color("#2a2a2a"), Vector3.ZERO)
	HeldItems._part(rotor, HeldItems._box(0.3, 0.05, 8.0), Color("#2a2a2a"), Vector3.ZERO)
	helicopter_shape = _add_shape(Vector3(1.8, 2.2, 5.0), Vector3(0, 1.1, 0.5))

	# Nada de esto hace sombra (más barato).
	for mesh in find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _add_shape(size: Vector3, pos: Vector3) -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.position = pos
	add_child(shape)
	return shape
