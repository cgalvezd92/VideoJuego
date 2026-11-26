extends RayCast3D
## Detecta lo que miras y permite recogerlo con E.
## Va en el nodo "Interactor", hijo de Camera3D.

@onready var hud = owner.get_node("HUD")
@onready var inventory = owner.get_node("Inventory")


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
	var total: int = inventory.add_item(target.item_id, target.display_name, target.amount)
	if total == -1:
		hud.show_message("Inventario lleno")
		return
	hud.show_message("Recogiste: %s (total: %d)" % [target.display_name, total])
	target.collect()
