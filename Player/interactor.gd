extends RayCast3D
## Detecta lo que miras y permite recogerlo con E.
## Va en el nodo "Interactor", hijo de Camera3D.

@onready var hud = owner.get_node("HUD")

# Cuenta provisional. En la Etapa 3 será un inventario.
var items: Dictionary = {}


func _ready() -> void:
	# El rayo ignora el cuerpo del propio jugador.
	add_exception(owner as CollisionObject3D)


func _physics_process(_delta: float) -> void:
	var target: Object = get_collider()

	if target == null or not target.has_method("collect"):
		hud.set_prompt("")
		return

	hud.set_prompt("[E] Recoger " + target.display_name)

	if Input.is_action_just_pressed("interact"):
		_pick_up(target)


func _pick_up(target: Object) -> void:
	var id: String = target.item_id
	var total: int = items.get(id, 0) + target.amount
	items[id] = total
	hud.show_message("Recogiste: %s (total: %d)" % [target.display_name, total])
	target.collect()
