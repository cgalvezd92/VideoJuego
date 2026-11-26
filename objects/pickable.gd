extends Area3D
## Objeto que se puede recoger (rama, piedra, etc.).
## Va en el nodo raíz de stone.tscn y branch.tscn.

@export var item_id: String = "piedra"
@export var display_name: String = "Piedra"
@export var amount: int = 1


func collect() -> void:
	queue_free()
