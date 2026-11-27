extends Node
## Herramientas y objetos de mano (Etapas 9, 12, 26 y 33).
## Va en el nodo "Tools", hijo de Player.
##
## - Clic izquierdo: golpear con hacha, machete, lanza o bastón (talar o
##   cazar) o comer/beber lo que tengas seleccionado.
## - Clic derecho: lanzar la lanza o disparar el arco.
## - Con el arpón, clic izquierdo mirando un río o un lago: pescar (Etapa 33).
## - Al empezar una partida nueva, cada personaje recibe su objeto inicial.

const AXE_SCENE: PackedScene = preload("res://objects/stone_axe.tscn")
const HeldItems = preload("res://Player/held_items.gd")
const Projectile = preload("res://objects/projectile.gd")

## Segundos entre golpe y golpe.
@export var swing_cooldown: float = 0.5

@export_group("Antorcha (Etapa 43)")
## Segundos de fuego de cada antorcha mientras la llevas en la mano.
@export var torch_seconds: float = 180.0

@export_group("Pesca")
## Probabilidad de sacar un pez en cada intento (0.35 = 35 %).
@export_range(0.0, 1.0) var fish_chance: float = 0.35
## Segundos entre intento e intento de pesca.
@export var fish_cooldown: float = 1.2

## Comida y bebida: cuánta hambre/sed quita y cuánta vida suma (negativo = daño).
const FOODS: Dictionary = {
	"carne_cocida": { "hunger": 45.0, "thirst": 0.0, "health": 5.0, "text": "Comiste carne cocida. ¡Qué rica!" },
	"carne_cruda": { "hunger": 5.0, "thirst": 0.0, "health": -10.0, "text": "Comiste carne cruda... te sienta mal" },
	"pescado_cocido": { "hunger": 35.0, "thirst": 0.0, "health": 5.0, "text": "Comiste pescado cocido. ¡Muy bueno!" },
	"pescado_crudo": { "hunger": 8.0, "thirst": 0.0, "health": -6.0, "text": "Comiste pescado crudo... no te sienta bien" },
	"agua": { "hunger": 0.0, "thirst": 40.0, "health": 0.0, "text": "Bebiste agua de la olla" },
}

## Objetos que sirven para golpear (talar o cazar).
const MELEE: Array[String] = ["hacha", "machete", "lanza", "baston", "arpon"]
## Objetos que talan y cuántos golpes de árbol cuenta cada hachazo.
const CHOP_POWER: Dictionary = { "hacha": 1, "machete": 2 }

## Objeto inicial de cada personaje (el "objeto" de personajes.gd).
const START_ITEMS: Dictionary = {
	"machete": [["machete", "Machete", 1]],
	"lanza": [["lanza", "Lanza", 1]],
	"arco": [["arco", "Arco", 1], ["flecha", "Flecha", 3]],
	"antorcha": [["antorcha", "Antorcha", 1]],
	"olla": [["olla", "Olla", 1]],
	"baston": [["baston", "Bastón", 1]],
}

@onready var inventory = owner.get_node("Inventory")
@onready var hud = owner.get_node("HUD")
@onready var camera: Camera3D = owner.get_node("Head/Camera3D")
@onready var interactor: RayCast3D = owner.get_node("Head/Camera3D/Interactor")
@onready var survival = owner.get_node("Survival")

## Modelos en la mano ya creados (se crean la primera vez que se seleccionan).
var held_models: Dictionary = {}
var held: Node3D
var rest_rotation: Vector3
var cooldown: float = 0.0
## Fuego que le queda a la antorcha que llevas (Etapa 43).
var torch_fuel: float = 180.0
var weather: Node


func _ready() -> void:
	# Objeto inicial del personaje. Si luego se carga una partida guardada,
	# el inventario guardado lo sustituye.
	for item in START_ITEMS.get(Personajes.actual()["objeto"], []):
		inventory.add_item(item[0], item[1], item[2])
	# Todos empiezan con un pequeño botiquín: 2 vendas (Etapa 37).
	inventory.add_item("venda", "Venda", 2)

	inventory.changed.connect(_update_held)
	inventory.selection_changed.connect(_update_held)
	_update_held()


func _process(delta: float) -> void:
	cooldown -= delta
	if is_holding_torch():
		_burn_torch(delta)


func _unhandled_input(event: InputEvent) -> void:
	# Soltar objetos con Q, o todo el montón con Shift+Q (Etapa 42).
	if event.is_action_pressed("drop_item"):
		drop_selected(Input.is_key_pressed(KEY_SHIFT))
		return
	# Solo con el mouse capturado (el primer clic tras Esc lo recaptura).
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or cooldown > 0.0:
		return
	if event.is_action_pressed("attack"):
		var water = _water_in_front() if is_holding("arpon") else null
		if water != null:
			_fish(water)
		elif can_melee():
			_swing()
		elif is_holding_food():
			_eat()
		elif is_holding("venda"):
			_use_bandage()
	elif event.is_action_pressed("throw"):
		if is_holding("lanza"):
			_launch("lanza", "Lanza", 22.0)
		elif is_holding("arco"):
			if inventory.get_amount("flecha") > 0:
				_launch("flecha", "Flecha", 40.0)
			else:
				hud.show_message("No te quedan flechas")


# --- Qué tienes en la mano ---

func selected_id() -> String:
	var item = inventory.get_selected_item()
	return "" if item == null else item.id


func is_holding(id: String) -> bool:
	return selected_id() == id


func can_chop() -> bool:
	return CHOP_POWER.has(selected_id())


func can_melee() -> bool:
	return selected_id() in MELEE


## Compatibilidad: antes solo existía el hacha.
func is_holding_axe() -> bool:
	return can_chop()


func is_holding_torch() -> bool:
	return is_holding("antorcha")


func is_holding_food() -> bool:
	return FOODS.has(selected_id())


## Aviso para la lanza y el arco cuando no miras nada en concreto.
## También para la venda (Etapa 37).
func ranged_prompt() -> String:
	if is_holding("venda"):
		return "[Clic] Usar venda (sangrando)" if survival.bleeding > 0.0 else "[Clic] Usar venda"
	if is_holding_torch():
		return "Antorcha: le quedan %d:%02d de fuego" % [int(torch_fuel) / 60, int(torch_fuel) % 60]
	if is_holding("lanza"):
		return "[Clic der.] Lanzar la lanza"
	if is_holding("arco"):
		return "[Clic der.] Disparar (flechas: %d)" % inventory.get_amount("flecha")
	return ""


func _update_held() -> void:
	var id: String = selected_id()
	if held != null:
		held.visible = false
	held = null
	if not held_models.has(id):
		var model: Node3D = AXE_SCENE.instantiate() if id == "hacha" else HeldItems.make(id)
		if model == null:
			return
		camera.add_child(model)
		# Delante de la cámara, abajo a la derecha.
		model.position = Vector3(0.32, -0.32, -0.55)
		model.rotation_degrees = Vector3(10, -15, 0)
		if id == "lanza" or id == "arpon":
			model.position = Vector3(0.3, -0.3, -0.4)
			model.rotation_degrees = Vector3(0, -4, 0)
		elif id == "antorcha":
			# Más abajo y más lejos, para que la llama no tape la vista.
			model.position = Vector3(0.42, -0.62, -0.85)
			model.rotation_degrees = Vector3(-10, 0, -12)
		held_models[id] = model
	held = held_models[id]
	held.visible = true
	rest_rotation = held.rotation


# --- Acciones ---

func _eat() -> void:
	cooldown = swing_cooldown
	var item = inventory.get_selected_item()
	var food: Dictionary = FOODS[item.id]
	inventory.remove_item(item.id, 1)
	var hunger_gain: float = food.hunger
	if item.id == "carne_cocida" or item.id == "pescado_cocido":
		hunger_gain *= Personajes.mod("comida_mult")  # Etapa 25: el cocinero rinde más.
	if hunger_gain > 0.0:
		survival.eat(hunger_gain)
	if food.thirst > 0.0:
		survival.drink(food.thirst)
	survival.health = clampf(survival.health + food.health, 0.0, survival.max_health)
	hud.show_message(food.text)


## Venda (Etapa 37): para la sangre y cura un poco.
func _use_bandage() -> void:
	cooldown = swing_cooldown
	inventory.remove_item("venda", 1)
	hud.show_message(survival.bandage())


func _swing() -> void:
	cooldown = swing_cooldown

	# Animación: el objeto baja rápido y vuelve despacio.
	if held != null:
		var tween := create_tween()
		tween.tween_property(held, "rotation", rest_rotation + Vector3(-1.2, 0.2, 0), 0.1)
		tween.tween_property(held, "rotation", rest_rotation, 0.25)

	var target: Object = interactor.get_collider()
	if target != null and target.has_method("hit"):
		_hunt(target)
		return
	if target == null or not target.has_method("chop"):
		return
	if not can_chop():
		hud.show_message("Con esto no puedes talar: usa un hacha o un machete")
		return
	if target.has_method("can_chop") and not target.can_chop():
		hud.show_message("Esta acacia es muy joven: deja que crezca")
		return

	# El machete cuenta como 2 golpes en cada hachazo.
	var wood: int = 0
	for i in CHOP_POWER[selected_id()]:
		wood += target.chop()
		if wood > 0:
			break
	if wood > 0:
		if inventory.add_item("madera", "Madera", wood) == -1:
			hud.show_message("Talaste el árbol, pero el inventario está lleno")
		else:
			hud.show_message("Talaste el árbol: +%d madera" % wood)
		get_tree().call_group("objectives", "complete", "talar")


## Lanza la lanza o dispara una flecha hacia donde mira la cámara.
func _launch(id: String, display_name: String, speed: float) -> void:
	cooldown = swing_cooldown
	inventory.remove_item(id, 1)
	var projectile := Node3D.new()
	projectile.set_script(Projectile)
	projectile.item_id = id
	projectile.item_name = display_name
	projectile.tools = self
	var exclude: Array[RID] = [owner.get_rid()]  # No chocar con el propio jugador.
	projectile.exclude = exclude
	var model: Node3D = HeldItems.make(id)
	projectile.add_child(model)
	var forward: Vector3 = -camera.global_basis.z
	projectile.velocity = forward * speed
	owner.get_parent().add_child(projectile)
	projectile.global_position = camera.global_position + forward * 0.6
	projectile.look_at(projectile.global_position + forward, Vector3.UP)
	if id == "lanza":
		hud.show_message("Lanzaste la lanza: ve a recogerla con E")


## La llama una lanza o flecha al dar a un animal.
func on_projectile_hit(target: Object) -> void:
	_hunt(target)


func _hunt(gazelle: Object) -> void:
	var meat: int = gazelle.hit()
	# Otros animales (la hiena) traen su propio mensaje.
	if gazelle.has_method("get_hit_message"):
		hud.show_message(gazelle.get_hit_message())
	elif meat == 0:
		hud.show_message("¡Gacela herida! Corre tras ella (Shift)")
	elif inventory.add_item("carne_cruda", "Carne cruda", meat) == -1:
		hud.show_message("Cazaste una gacela, pero el inventario está lleno")
	else:
		get_tree().call_group("objectives", "complete", "cazar")
		# Cada gacela da también 1 piel (para la mochila, Etapa 31).
		inventory.add_item("piel", "Piel", 1)
		hud.show_message("Cazaste una gacela: +%d carne cruda y 1 piel" % meat)


# --- Pesca (Etapa 33) ---

## Agua (río, lago o mar) que tienes delante, o null.
func _water_in_front():
	var target: Object = interactor.get_collider()
	if target != null and "kind" in target:
		return target
	if target != null and (target.has_method("hit") or target.has_method("chop") \
			or target.has_method("collect") or target.has_method("interact")):
		return null  # Miras otra cosa (un animal, un árbol, la charca...).
	var water = interactor._find_water()
	return water if water != null and "kind" in water else null


func _fish(water: Object) -> void:
	cooldown = fish_cooldown
	# Animación: el arpón se clava hacia delante y vuelve.
	if held != null:
		var rest: Vector3 = held.position
		var tween := create_tween()
		tween.tween_property(held, "position", rest + Vector3(0, -0.1, -0.35), 0.12)
		tween.tween_property(held, "position", rest, 0.3)
	if water.kind == "mar":
		hud.show_message("Las olas del mar son muy fuertes: pesca en ríos y lagos")
		return
	if randf() >= fish_chance:
		hud.show_message("Fallaste... el pez se escapó. Vuelve a intentarlo")
		return
	if inventory.add_item("pescado_crudo", "Pescado crudo", 1) == -1:
		hud.show_message("¡Pescaste un pez, pero el inventario está lleno!")
		return
	hud.show_message("¡Pescaste un pez! Cocínalo en una fogata (E)")
	get_tree().call_group("objectives", "complete", "pescar")


# --- Soltar objetos (Etapa 42) ---

## Deja en el suelo, delante de ti, 1 del objeto elegido (o todo el montón).
func drop_selected(all: bool) -> void:
	var item = inventory.get_selected_item()
	if item == null:
		hud.show_message("No tienes nada en esta casilla")
		return
	var amount: int = item.amount if all else 1
	var id: String = item.id
	var item_name: String = item.name
	inventory.remove_item(id, amount)
	var pickable: Area3D = HeldItems.make_pickable(id, item_name, amount)
	owner.get_parent().add_child(pickable)
	pickable.global_position = _drop_spot()
	if amount > 1:
		hud.show_message("Soltaste %d × %s (E para recoger)" % [amount, item_name])
	else:
		hud.show_message("Soltaste: %s (E para recoger)" % item_name)


## Un punto del suelo un poco delante del jugador.
func _drop_spot() -> Vector3:
	var forward: Vector3 = -owner.global_basis.z
	forward.y = 0.0
	# Un poco al azar, para que lo que sueltas no quede todo amontonado.
	var ahead: Vector3 = owner.global_position + forward.normalized() * 1.2 \
		+ Vector3(randf_range(-0.35, 0.35), 0.0, randf_range(-0.35, 0.35))
	var query := PhysicsRayQueryParameters3D.create(ahead + Vector3.UP * 1.5, ahead + Vector3.DOWN * 3.0)
	query.exclude = [owner.get_rid()]
	query.collide_with_areas = false
	var hit: Dictionary = owner.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else owner.global_position


# --- Antorcha que se gasta (Etapa 43) ---

func _burn_torch(delta: float) -> void:
	if weather == null:
		weather = get_tree().get_first_node_in_group("weather")
	# Con lluvia fuerte se consume el doble de rápido.
	var rate: float = 2.0 if weather != null and weather.rain_amount > 0.5 else 1.0
	torch_fuel -= delta * rate
	# La luz baja cuando queda poco fuego.
	if held != null:
		for light in held.find_children("*", "OmniLight3D", true, false):
			light.light_energy = 1.3 * clampf(torch_fuel / (torch_seconds * 0.25), 0.35, 1.0)
	if torch_fuel <= 0.0:
		torch_fuel = torch_seconds
		inventory.remove_item("antorcha", 1)
		var left: int = inventory.get_amount("antorcha")
		if left > 0:
			hud.show_message("Tu antorcha se consumió: enciendes otra (te quedan %d)" % left)
		else:
			hud.show_message("Tu antorcha se consumió. Haz otra con T (1 rama + 1 piel)")
