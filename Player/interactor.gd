extends RayCast3D
## Detecta lo que miras: con E recoges objetos o usas cosas
## (beber en la charca, comer bayas...).
## Va en el nodo "Interactor", hijo de Camera3D.

@onready var hud = owner.get_node("HUD")
@onready var inventory = owner.get_node("Inventory")


func _ready() -> void:
	# El rayo ignora el cuerpo del propio jugador.
	add_exception(owner as CollisionObject3D)


func _physics_process(_delta: float) -> void:
	var target: Object = get_collider()

	var pressed: bool = Input.is_action_just_pressed("interact")

	if target != null and target.has_method("collect"):
		# Objetos que se guardan en el inventario (piedras, ramas).
		hud.set_prompt("[E] Recoger " + target.display_name)
		if pressed:
			_pick_up(target)
	elif target != null and target.has_method("interact"):
		# Cosas que se usan en el sitio (charca, arbusto de bayas).
		hud.set_prompt(target.get_prompt())
		if pressed:
			hud.show_message(target.interact(owner))
	else:
		hud.set_prompt("")


func _pick_up(target: Object) -> void:
	var total: int = inventory.add_item(target.item_id, target.display_name, target.amount)
	if total == -1:
		hud.show_message("Inventario lleno")
		return
	hud.show_message("Recogiste: %s (total: %d)" % [target.display_name, total])
	target.collect()
