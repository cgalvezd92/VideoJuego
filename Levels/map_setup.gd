extends Node
## Prepara el mapa de África al empezar (Etapa 19).
## Va en el nodo "MapSetup", hijo de Main (en main.tscn).
##
## 1. Activa los colores del terreno y la vegetación (vienen por vértice).
## 2. Pone el terreno en la capa de colisión 2, para que los rayos que buscan
##    el suelo no choquen con árboles, rocas o animales.
## 3. Coloca cada objeto, árbol, roca, charca y animal sobre el relieve.
## 4. Planta la hierba siguiendo las colinas.
## 5. Hace que los ríos, lagos y el mar se puedan mirar con E (Etapa 24).

## Capa de colisión del terreno (la 2).
const GROUND_LAYER: int = 2
## Capa de colisión del agua (la 3): solo la usa el rayo de la E.
const WATER_LAYER: int = 3
const FreshWater = preload("res://objects/fresh_water.gd")
## Nombre de cada malla de agua del mapa y qué tipo de agua es.
const WATER_MESHES: Dictionary = { "Rios": "río", "Lagos_y_oasis": "lago", "Oceano": "mar" }
const WorldResources = preload("res://Levels/world_resources.gd")

@onready var map: Node3D = $"../Mapa"
@onready var animals: Node = $"../Animals"

## Nodos cuyos hijos se colocan sobre el suelo.
@onready var groups_to_snap: Array[Node] = [
	$"../Objects", $"../Nature", $"../Nature/Trees", $"../Nature/Rocks", $"../Animals",
]


func _ready() -> void:
	# Los animales esperan quietos hasta estar sobre el suelo.
	animals.process_mode = Node.PROCESS_MODE_DISABLED
	_enable_vertex_colors()
	_set_ground_layer()
	_setup_water()
	# Las colisiones del terreno están listas tras un fotograma de física.
	await get_tree().physics_frame
	_snap_all()
	$"../Nature/Grass".build()
	$"../World".start()  # Empieza a crear recursos por todo el mapa.
	animals.process_mode = Node.PROCESS_MODE_INHERIT


## Altura del suelo en (x, z), o null si no hay tierra (mar o fuera del mapa).
static func ground_height(world: World3D, x: float, z: float):
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, 200.0, z), Vector3(x, -60.0, z))
	query.collision_mask = 1 << (GROUND_LAYER - 1)
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit.position.y


func _enable_vertex_colors() -> void:
	# Los colores del mapa están guardados en cada vértice: hay que decirle al
	# material que los use (si no, todo se vería blanco).
	for mesh_instance in map.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mesh_instance.mesh
		for surface in mesh.get_surface_count():
			var material = mesh.surface_get_material(surface)
			var has_colors: bool = mesh is ArrayMesh and (mesh.surface_get_format(surface) & Mesh.ARRAY_FORMAT_COLOR) != 0
			if material is StandardMaterial3D and has_colors:
				material.vertex_color_use_as_albedo = true
		# Sin sombras: mucho más rápido.
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Crea una colisión con la forma del agua, solo en la capa 3 (no se choca
## con ella), para que el rayo de la E pueda detectarla.
func _setup_water() -> void:
	for mesh_instance in map.find_children("*", "MeshInstance3D", true, false):
		if not WATER_MESHES.has(str(mesh_instance.name)):
			continue
		var body := StaticBody3D.new()
		body.set_script(FreshWater)
		body.name = "Agua"
		body.kind = WATER_MESHES[str(mesh_instance.name)]
		body.collision_layer = 0
		body.collision_mask = 0
		body.set_collision_layer_value(WATER_LAYER, true)
		var shape := CollisionShape3D.new()
		var water_shape: ConcavePolygonShape3D = mesh_instance.mesh.create_trimesh_shape()
		# Algunas caras del agua miran hacia abajo: así el rayo las detecta igual.
		water_shape.backface_collision = true
		shape.shape = water_shape
		body.add_child(shape)
		mesh_instance.add_child(body)


func _set_ground_layer() -> void:
	for body in map.find_children("*", "StaticBody3D", true, false):
		body.set_collision_layer_value(GROUND_LAYER, true)


func _snap_all() -> void:
	var world: World3D = get_viewport().get_world_3d()
	for group in groups_to_snap:
		for child in group.get_children():
			# Trees, Rocks y Grass son carpetas, no objetos: se saltan.
			if not child is Node3D or child.name in ["Trees", "Rocks", "Grass"]:
				continue
			var height = ground_height(world, child.global_position.x, child.global_position.z)
			if height == null:
				continue
			child.global_position.y = height + (0.05 if child is CharacterBody3D else 0.0)
			# No dibujar de lejos los objetos pequeños (ahorra mucho).
			WorldResources.apply_view_distance(child)
			# Las gacelas recuerdan dónde viven: se actualiza a la nueva altura.
			if "spawn_point" in child:
				child.spawn_point = child.global_position
				child.home = child.global_position
