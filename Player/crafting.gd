extends Node
## Construcción: con F gastas ramas y piedras para hacer una fogata (Etapa 4).
## Va en el nodo "Crafting", hijo de Player.

const CAMPFIRE_SCENE: PackedScene = preload("res://objects/campfire.tscn")

@export var fire_branches: int = 3
@export var fire_stones: int = 2
## A cuántos metros delante del jugador aparece la fogata.
@export var place_distance: float = 2.0

@onready var player: CharacterBody3D = owner
@onready var inventory = owner.get_node("Inventory")
@onready var hud = owner.get_node("HUD")


func _ready() -> void:
	# El aviso "[F] Hacer fogata" se actualiza solo cuando cambia el inventario.
	inventory.changed.connect(_update_hint)
	_update_hint()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_fire"):
		_try_build_fire()


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
	hud.set_hint("[F] Hacer fogata   (ramas %d/%d · piedras %d/%d)"
		% [branches, fire_branches, stones, fire_stones], available)


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
