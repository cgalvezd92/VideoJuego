extends Node
## Construcción: con F haces una fogata (Etapa 4) y con C un hacha (Etapa 9).
## Va en el nodo "Crafting", hijo de Player.

const CAMPFIRE_SCENE: PackedScene = preload("res://objects/campfire.tscn")

@export var fire_branches: int = 3
@export var fire_stones: int = 2
## A cuántos metros delante del jugador aparece la fogata.
@export var place_distance: float = 2.0

@export_group("Hacha")
@export var axe_branches: int = 2
@export var axe_stones: int = 1

@onready var player: CharacterBody3D = owner
@onready var inventory = owner.get_node("Inventory")
@onready var hud = owner.get_node("HUD")


func _ready() -> void:
	# Los avisos "[F] Hacer fogata" y "[C] Hacer hacha" se actualizan
	# solo cuando cambia el inventario.
	inventory.changed.connect(_update_hint)
	_update_hint()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_fire"):
		_try_build_fire()
	elif event.is_action_pressed("craft_axe"):
		_try_craft_axe()


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

	var spot = _find_spot()
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


func _update_hint() -> void:
	var branches: int = inventory.get_amount("rama")
	var stones: int = inventory.get_amount("piedra")
	var available: bool = branches >= fire_branches and stones >= fire_stones
	hud.set_hint(0, "[F] Hacer fogata   (ramas %d/%d · piedras %d/%d)"
		% [branches, fire_branches, stones, fire_stones], available)

	# El aviso del hacha desaparece cuando ya tienes una.
	if inventory.get_amount("hacha") > 0:
		hud.set_hint(1, "", false)
	else:
		var can_axe: bool = branches >= axe_branches and stones >= axe_stones
		hud.set_hint(1, "[C] Hacer hacha   (ramas %d/%d · piedras %d/%d)"
			% [branches, axe_branches, stones, axe_stones], can_axe)


## Busca suelo delante del jugador. Devuelve la posición o null.
func _find_spot():
	var space := player.get_world_3d().direct_space_state

	# Dirección hacia donde mira el jugador, sin inclinación.
	var forward: Vector3 = -player.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var chest: Vector3 = player.global_position + Vector3.UP
	var ahead: Vector3 = chest + forward * place_distance

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
