extends RayCast3D
## Detecta lo que miras: con E recoges objetos o usas cosas
## (beber en la charca, comer bayas...).
## Va en el nodo "Interactor", hijo de Camera3D.

@onready var hud = owner.get_node("HUD")
@onready var inventory = owner.get_node("Inventory")
@onready var tools = owner.get_node("Tools")


func _ready() -> void:
	# El rayo ignora el cuerpo del propio jugador.
	add_exception(owner as CollisionObject3D)
	# También detecta el agua de ríos, lagos y el mar (capa 3, Etapa 24).
	set_collision_mask_value(3, true)


## Alcance para beber: algo más largo que el rayo normal (3 m), porque la
## orilla suele estar por encima del agua.
const WATER_REACH: float = 6.0


func _physics_process(_delta: float) -> void:
	var target: Object = get_collider()
	if target == null or not target.has_method("get_prompt") and not target.has_method("collect") \
			and not target.has_method("chop") and not target.has_method("hit"):
		# Si no hay nada útil delante, busca agua un poco más lejos.
		var water = _find_water()
		if water != null:
			target = water

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
	elif target != null and target.has_method("hit"):
		# Animales: se golpean con hacha, machete, lanza o bastón (Tools).
		if tools.can_melee():
			hud.set_prompt("[Clic] " + target.get_hit_text())
		elif tools.ranged_prompt() != "":
			hud.set_prompt(tools.ranged_prompt())
		else:
			hud.set_prompt("Necesitas algo en la mano para golpear")
	elif target != null and target.has_method("chop"):
		# Árboles: se talan con el hacha o el machete (clic izquierdo, Tools).
		if tools.can_chop():
			if target.has_method("can_chop") and not target.can_chop():
				hud.set_prompt(target.get_chop_text())  # Acacia joven: no se tala.
			else:
				hud.set_prompt("[Clic] " + target.get_chop_text())
		else:
			hud.set_prompt("Necesitas un hacha o un machete en la mano para talar")
	elif tools.is_holding_food():
		var verb: String = "Beber" if tools.is_holding("agua") else "Comer"
		hud.set_prompt("[Clic] %s %s" % [verb, inventory.get_selected_item().name])
	elif tools.ranged_prompt() != "":
		hud.set_prompt(tools.ranged_prompt())
	else:
		hud.set_prompt("")


func _pick_up(target: Object) -> void:
	var total: int = inventory.add_item(target.item_id, target.display_name, target.amount)
	if total == -1:
		hud.show_message("Inventario lleno")
		return
	hud.show_message("Recogiste: %s (total: %d)" % [target.display_name, total])
	target.collect()


## Rayo solo contra el agua (capa 3), de WATER_REACH metros, hacia donde mira la cámara.
func _find_water():
	var from: Vector3 = global_position
	var to: Vector3 = from + global_basis * Vector3(0, 0, -WATER_REACH)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 << 2  # Capa 3
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	# Si hay terreno entre la cámara y el agua, no vale (agua detrás de una loma).
	var ground_query := PhysicsRayQueryParameters3D.create(from, hit.position)
	ground_query.collision_mask = 1 << 1  # Capa 2: terreno
	if not get_world_3d().direct_space_state.intersect_ray(ground_query).is_empty():
		return null
	return hit.collider
