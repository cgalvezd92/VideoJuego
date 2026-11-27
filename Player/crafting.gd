extends Node
## Construcción: F fogata (Etapa 4), C hacha (Etapa 9) y R refugio (Etapa 11).
## Va en el nodo "Crafting", hijo de Player.

const CAMPFIRE_SCENE: PackedScene = preload("res://objects/campfire.tscn")
const SHELTER_SCENE: PackedScene = preload("res://objects/shelter.tscn")
const Chest = preload("res://objects/chest.gd")
const Bed = preload("res://objects/bed.gd")

@export var fire_branches: int = 3
@export var fire_stones: int = 2
## A cuántos metros delante del jugador aparece la fogata.
@export var place_distance: float = 2.0

@export_group("Hacha")
@export var axe_branches: int = 2
@export var axe_stones: int = 1

@export_group("Refugio")
@export var shelter_wood: int = 6
@export var shelter_branches: int = 4
## A cuántos metros delante del jugador aparece el refugio.
@export var shelter_distance: float = 3.5

@export_group("Flechas y lanza")
## Flechas (X): 1 rama + 1 piedra = 2 flechas.
@export var arrow_branches: int = 1
@export var arrow_stones: int = 1
@export var arrows_made: int = 2
## Mochila (P): 3 pieles + 2 ramas; el inventario pasa a 12 casillas.
@export var backpack_hides: int = 3
@export var backpack_branches: int = 2
## Lanza (L): 2 madera + 1 piedra.
@export var spear_wood: int = 2
@export var spear_stones: int = 1
## Arpón (G, Etapa 33): 1 madera + 2 piedras. Sirve para pescar.
@export var harpoon_wood: int = 1
@export var harpoon_stones: int = 2
## Arco (K): 2 madera + 2 ramas. Dispara flechas con clic derecho.
@export var bow_wood: int = 2
@export var bow_branches: int = 2
## Vendas (V, Etapa 37): 1 piel + 1 rama = 2 vendas.
@export var bandage_hides: int = 1
@export var bandage_branches: int = 1
@export var bandages_made: int = 2
## Antorcha (T, Etapa 43): 1 rama + 1 piel.
@export var torch_branches: int = 1
@export var torch_hides: int = 1
## Cofre (J, Etapa 41): 4 madera + 2 ramas.
@export var chest_wood: int = 4
@export var chest_branches: int = 2
## Cama de pieles (N, Etapa 41): 3 pieles + 2 madera.
@export var bed_hides: int = 3
@export var bed_wood: int = 2

@onready var player: CharacterBody3D = owner
@onready var inventory = owner.get_node("Inventory")
@onready var hud = owner.get_node("HUD")


func _ready() -> void:
	# Los avisos "[F] Hacer fogata", "[C] Hacer hacha" y "[R] Hacer refugio"
	# se actualizan solo cuando cambia el inventario.
	inventory.changed.connect(_update_book)
	_update_book()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_fire"):
		_try_build_fire()
	elif event.is_action_pressed("craft_axe"):
		_try_craft_axe()
	elif event.is_action_pressed("build_shelter"):
		_try_build_shelter()
	elif event.is_action_pressed("craft_arrows"):
		_craft_item({"rama": arrow_branches, "piedra": arrow_stones}, "flecha", "Flecha", arrows_made)
	elif event.is_action_pressed("craft_backpack"):
		_try_craft_backpack()
	elif event.is_action_pressed("craft_spear"):
		_craft_item({"madera": spear_wood, "piedra": spear_stones}, "lanza", "Lanza", 1)
	elif event.is_action_pressed("craft_torch"):
		_craft_item({"rama": torch_branches, "piel": torch_hides}, "antorcha", "Antorcha", 1)
	elif event.is_action_pressed("build_chest"):
		_place_furniture(Chest, {"madera": chest_wood, "rama": chest_branches}, 1.6,
			"Hiciste un cofre: míralo y pulsa E para guardar cosas")
	elif event.is_action_pressed("build_bed"):
		_place_furniture(Bed, {"piel": bed_hides, "madera": bed_wood}, 2.0,
			"Hiciste una cama de pieles: de noche, E para dormir y curarte más")
	elif event.is_action_pressed("craft_bandage"):
		_craft_item({"piel": bandage_hides, "rama": bandage_branches}, "venda", "Venda", bandages_made)
	elif event.is_action_pressed("craft_bow"):
		if inventory.get_amount("arco") > 0:
			hud.show_message("Ya tienes un arco")
		else:
			_craft_item({"madera": bow_wood, "rama": bow_branches}, "arco", "Arco", 1)
	elif event.is_action_pressed("craft_harpoon"):
		if inventory.get_amount("arpon") > 0:
			hud.show_message("Ya tienes un arpón")
		else:
			_craft_item({"madera": harpoon_wood, "piedra": harpoon_stones}, "arpon", "Arpón", 1)


## Fabrica un objeto si tienes los materiales (Etapa 28).
## "cost" es { id del material: cantidad }.
## ¿Tienes los materiales? Si no, avisa de lo que falta.
func _has_materials(cost: Dictionary) -> bool:
	# Nombre en singular y plural de cada material.
	var names: Dictionary = {
		"rama": ["rama", "ramas"], "piedra": ["piedra", "piedras"],
		"madera": ["de madera", "de madera"], "piel": ["piel", "pieles"],
	}
	var missing: PackedStringArray = []
	for material in cost:
		var have: int = inventory.get_amount(material)
		if have < cost[material]:
			var word: String = names[material][0] if cost[material] == 1 else names[material][1]
			missing.append("%d %s (tienes %d)" % [cost[material], word, have])
	if not missing.is_empty():
		hud.show_message("Necesitas " + ", ".join(missing))
		return false
	return true


## La mochila no ocupa casilla: amplía el inventario a 12 (Etapa 31).
func _try_craft_backpack() -> void:
	if inventory.has_backpack():
		hud.show_message("Ya tienes una mochila")
		return
	var cost: Dictionary = { "piel": backpack_hides, "rama": backpack_branches }
	if not _has_materials(cost):
		return
	for material in cost:
		inventory.remove_item(material, cost[material])
	inventory.expand(12)
	hud.show_message("Hiciste una mochila: ahora tienes 12 casillas (teclas 9 y 0, y la rueda)")


func _craft_item(cost: Dictionary, id: String, display_name: String, amount: int) -> void:
	# Nombre en singular y plural de cada material.
	if not _has_materials(cost):
		return
	if inventory.add_item(id, display_name, amount) == -1:
		hud.show_message("Inventario lleno")
		return
	for material in cost:
		inventory.remove_item(material, cost[material])
	if amount > 1:
		hud.show_message("Hiciste %d %ss" % [amount, display_name.to_lower()])
	else:
		var article: String = "un" if display_name in ["Arpón", "Arco"] else "una"
		hud.show_message("Hiciste %s %s" % [article, display_name.to_lower()])


## Pone un mueble (cofre o cama) delante del jugador (Etapa 41).
func _place_furniture(script: Script, cost: Dictionary, distance: float, message: String) -> void:
	if not _has_materials(cost):
		return
	var spot = _find_spot(distance)
	if spot == null:
		hud.show_message("No hay espacio aquí")
		return
	for material in cost:
		inventory.remove_item(material, cost[material])
	var furniture: Node3D = script.new()
	player.get_parent().add_child(furniture)
	furniture.global_position = spot
	furniture.rotation.y = player.rotation.y
	hud.show_message(message)


func _try_build_shelter() -> void:
	var wood: int = inventory.get_amount("madera")
	var branches: int = inventory.get_amount("rama")
	if wood < shelter_wood or branches < shelter_branches:
		hud.show_message("Necesitas %d de madera y %d ramas (tienes %d y %d)"
			% [shelter_wood, shelter_branches, wood, branches])
		return

	var spot = _find_spot(shelter_distance)
	if spot == null or not _is_area_free(spot):
		hud.show_message("No hay espacio para el refugio aquí")
		return

	inventory.remove_item("madera", shelter_wood)
	inventory.remove_item("rama", shelter_branches)

	var shelter: Node3D = SHELTER_SCENE.instantiate()
	player.get_parent().add_child(shelter)
	shelter.global_position = spot
	# La entrada del refugio mira hacia el jugador.
	shelter.rotation.y = player.rotation.y
	hud.show_message("Hiciste un refugio: de noche, míralo y pulsa E para dormir")


## Comprueba que no haya árboles, rocas ni paredes donde va el refugio.
func _is_area_free(spot: Vector3) -> bool:
	var box := BoxShape3D.new()
	box.size = Vector3(3.2, 2.0, 3.2)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	# Se mira de 0.4 m a 2.4 m de altura, así el suelo no cuenta.
	query.transform = Transform3D(Basis(Vector3.UP, player.rotation.y), spot + Vector3(0, 1.4, 0))
	query.exclude = [player.get_rid()]
	return player.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _try_craft_axe() -> void:
	if inventory.get_amount("hacha") > 0:
		hud.show_message("Ya tienes un hacha")
		return

	var branches: int = inventory.get_amount("rama")
	var stones: int = inventory.get_amount("piedra")
	if branches < axe_branches or stones < axe_stones:
		hud.show_message("Necesitas %d ramas y %d piedra (tienes %d y %d)"
			% [axe_branches, axe_stones, branches, stones])
		return

	if inventory.add_item("hacha", "Hacha", 1) == -1:
		hud.show_message("Inventario lleno")
		return
	inventory.remove_item("rama", axe_branches)
	inventory.remove_item("piedra", axe_stones)
	hud.show_message("Hiciste un hacha: selecciona su casilla para usarla")


func _try_build_fire() -> void:
	var branches: int = inventory.get_amount("rama")
	var stones: int = inventory.get_amount("piedra")
	if branches < fire_branches or stones < fire_stones:
		hud.show_message("Necesitas %d ramas y %d piedras (tienes %d y %d)"
			% [fire_branches, fire_stones, branches, stones])
		return

	var spot = _find_spot(place_distance)
	if spot == null:
		hud.show_message("No hay espacio para la fogata aquí")
		return

	inventory.remove_item("rama", fire_branches)
	inventory.remove_item("piedra", fire_stones)

	var fire: Node3D = CAMPFIRE_SCENE.instantiate()
	# La fogata se añade al nivel (el padre del jugador), no al jugador.
	player.get_parent().add_child(fire)
	fire.global_position = spot
	hud.show_message("Hiciste una fogata")
	get_tree().call_group("objectives", "count", "fogatas")


## Envía las recetas al libro de fabricación (se llama al cambiar el inventario).
func _update_book() -> void:
	var branches: int = inventory.get_amount("rama")
	var stones: int = inventory.get_amount("piedra")
	var wood: int = inventory.get_amount("madera")
	var has_axe: bool = inventory.get_amount("hacha") > 0

	hud.recipe_book.set_recipes([
		{
			"key": "F", "icon": "fogata", "name": "Fogata",
			"needs": [["Ramas", branches, fire_branches], ["Piedras", stones, fire_stones]],
			"available": branches >= fire_branches and stones >= fire_stones,
			"note": "Cocina (E); con piedras en la mano, E la protege",
		},
		{
			"key": "C", "icon": "hacha", "name": "Hacha",
			"needs": [["Ramas", branches, axe_branches], ["Piedras", stones, axe_stones]],
			"available": not has_axe and branches >= axe_branches and stones >= axe_stones,
			"note": "Ya tienes una" if has_axe else "Tala acacias y caza",
		},
		{
			"key": "R", "icon": "refugio", "name": "Refugio",
			"needs": [["Madera", wood, shelter_wood], ["Ramas", branches, shelter_branches]],
			"available": wood >= shelter_wood and branches >= shelter_branches,
			"note": "De noche, E para dormir",
		},
		{
			"key": "T", "icon": "antorcha", "name": "Antorcha",
			"needs": [["Ramas", branches, torch_branches], ["Pieles", inventory.get_amount("piel"), torch_hides]],
			"available": branches >= torch_branches and inventory.get_amount("piel") >= torch_hides,
			"note": "Luz y calor; dura 3 min en la mano",
		},
		{
			"key": "J", "icon": "cofre", "name": "Cofre",
			"needs": [["Madera", wood, chest_wood], ["Ramas", branches, chest_branches]],
			"available": wood >= chest_wood and branches >= chest_branches,
			"note": "Guarda 12 montones de objetos (E)",
		},
		{
			"key": "N", "icon": "cama", "name": "Cama de pieles",
			"needs": [["Pieles", inventory.get_amount("piel"), bed_hides], ["Madera", wood, bed_wood]],
			"available": inventory.get_amount("piel") >= bed_hides and wood >= bed_wood,
			"note": "Dormir cura 60 y para la sangre",
		},
		{
			"key": "X", "icon": "flecha", "name": "Flechas (x%d)" % arrows_made,
			"needs": [["Ramas", branches, arrow_branches], ["Piedras", stones, arrow_stones]],
			"available": branches >= arrow_branches and stones >= arrow_stones,
			"note": "Para el arco (clic derecho)",
		},
		{
			"key": "K", "icon": "arco", "name": "Arco",
			"needs": [["Madera", wood, bow_wood], ["Ramas", branches, bow_branches]],
			"available": inventory.get_amount("arco") == 0 and wood >= bow_wood and branches >= bow_branches,
			"note": "Ya tienes uno" if inventory.get_amount("arco") > 0 else "Dispara flechas (clic derecho)",
		},
		{
			"key": "L", "icon": "lanza", "name": "Lanza",
			"needs": [["Madera", wood, spear_wood], ["Piedras", stones, spear_stones]],
			"available": wood >= spear_wood and stones >= spear_stones,
			"note": "Caza de cerca o lánzala (clic derecho)",
		},
		{
			"key": "G", "icon": "arpon", "name": "Arpón",
			"needs": [["Madera", wood, harpoon_wood], ["Piedras", stones, harpoon_stones]],
			"available": inventory.get_amount("arpon") == 0 and wood >= harpoon_wood and stones >= harpoon_stones,
			"note": "Ya tienes uno" if inventory.get_amount("arpon") > 0 else "Pesca en ríos y lagos (clic)",
		},
		{
			"key": "V", "icon": "venda", "name": "Vendas (x%d)" % bandages_made,
			"needs": [["Pieles", inventory.get_amount("piel"), bandage_hides], ["Ramas", branches, bandage_branches]],
			"available": inventory.get_amount("piel") >= bandage_hides and branches >= bandage_branches,
			"note": "Paran la sangre de un mordisco (clic)",
		},
		{
			"key": "P", "icon": "mochila", "name": "Mochila",
			"needs": [["Pieles", inventory.get_amount("piel"), backpack_hides], ["Ramas", branches, backpack_branches]],
			"available": not inventory.has_backpack() and inventory.get_amount("piel") >= backpack_hides and branches >= backpack_branches,
			"note": "Ya tienes una (12 casillas)" if inventory.has_backpack() else "+4 casillas. Piel: caza gacelas",
		},
	])


## Busca suelo a "distance" metros delante del jugador. Devuelve la posición o null.
func _find_spot(distance: float):
	var space := player.get_world_3d().direct_space_state

	# Dirección hacia donde mira el jugador, sin inclinación.
	var forward: Vector3 = -player.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var chest: Vector3 = player.global_position + Vector3.UP
	var ahead: Vector3 = chest + forward * distance

	# 1) ¿Hay una pared o caja entre el jugador y ese punto?
	var query := PhysicsRayQueryParameters3D.create(chest, ahead)
	query.exclude = [player.get_rid()]
	if not space.intersect_ray(query).is_empty():
		return null

	# 2) Rayo hacia abajo para encontrar el suelo.
	query = PhysicsRayQueryParameters3D.create(ahead, ahead + Vector3.DOWN * 3.0)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = space.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit.position
