extends Node
## Cierra la ventana del cofre con E o Esc (Etapa 41).
## La crea chest.gd dentro de la ventana; funciona con el juego en pausa.

var chest: Node


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		chest._close()
