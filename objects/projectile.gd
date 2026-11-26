extends Node3D
## Lanza o flecha en el aire (Etapa 26). La crea Tools al lanzar con clic
## derecho. Avanza con un poco de gravedad y, en cada paso de física, lanza un
## rayo corto para ver si ha chocado. Al chocar o al acabarse su tiempo, cae
## al suelo y se puede recoger con E.

const HeldItems = preload("res://Player/held_items.gd")
const MapSetup = preload("res://Levels/map_setup.gd")

var velocity: Vector3
var item_id: String = "flecha"
var item_name: String = "Flecha"
## Quién la lanzó (para no chocar con él y para avisar del impacto).
var tools: Node
var exclude: Array[RID] = []
var life: float = 5.0


func _physics_process(delta: float) -> void:
	life -= delta
	velocity += Vector3.DOWN * 6.0 * delta  # Gravedad suave.

	var from: Vector3 = global_position
	var to: Vector3 = from + velocity * delta
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = exclude
	query.collision_mask = 0b11  # Capas 1 y 2: animales, árboles, rocas y terreno.
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if not hit.is_empty():
		global_position = hit.position
		if hit.collider.has_method("hit") and tools != null:
			tools.on_projectile_hit(hit.collider)
		_drop()
		return

	global_position = to
	# El modelo apunta hacia donde vuela (su punta mira a -Z).
	if velocity.length() > 0.1:
		look_at(global_position + velocity, Vector3.UP)
	if life <= 0.0:
		_drop()


## Deja en el suelo una lanza o flecha que se puede recoger con E.
func _drop() -> void:
	var ground = MapSetup.ground_height(get_world_3d(), global_position.x, global_position.z)
	if ground != null and ground > 0.3:
		var pickable: Area3D = HeldItems.make_pickable(item_id, item_name)
		get_parent().add_child(pickable)
		pickable.global_position = Vector3(global_position.x, ground, global_position.z)
	queue_free()
