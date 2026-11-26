extends Node
## Herramientas: muestra el hacha en la mano y golpea con clic izquierdo (Etapa 9).
## Va en el nodo "Tools", hijo de Player.

const AXE_SCENE: PackedScene = preload("res://objects/stone_axe.tscn")

## Segundos entre golpe y golpe.
@export var swing_cooldown: float = 0.5

@onready var inventory = owner.get_node("Inventory")
@onready var hud = owner.get_node("HUD")
@onready var camera: Camera3D = owner.get_node("Head/Camera3D")
@onready var interactor: RayCast3D = owner.get_node("Head/Camera3D/Interactor")

var axe_model: Node3D
var rest_rotation: Vector3
var cooldown: float = 0.0


func _ready() -> void:
	# El hacha se pone delante de la cámara, abajo a la derecha.
	axe_model = AXE_SCENE.instantiate()
	camera.add_child(axe_model)
	axe_model.position = Vector3(0.32, -0.32, -0.55)
	axe_model.rotation_degrees = Vector3(10, -15, 0)
	rest_rotation = axe_model.rotation

	inventory.changed.connect(_update_held)
	inventory.selection_changed.connect(_update_held)
	_update_held()


func _process(delta: float) -> void:
	cooldown -= delta


func _unhandled_input(event: InputEvent) -> void:
	# Solo golpea con el mouse capturado (el primer clic tras Esc lo recaptura).
	if event.is_action_pressed("attack") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if is_holding_axe() and cooldown <= 0.0:
			_swing()


func is_holding_axe() -> bool:
	var item = inventory.get_selected_item()
	return item != null and item.id == "hacha"


func _update_held() -> void:
	# El hacha solo se ve si su casilla está seleccionada.
	axe_model.visible = is_holding_axe()


func _swing() -> void:
	cooldown = swing_cooldown

	# Animación: el hacha baja rápido y vuelve despacio.
	var tween := create_tween()
	tween.tween_property(axe_model, "rotation", rest_rotation + Vector3(-1.2, 0.2, 0), 0.1)
	tween.tween_property(axe_model, "rotation", rest_rotation, 0.25)

	var target: Object = interactor.get_collider()
	if target == null or not target.has_method("chop"):
		return

	var wood: int = target.chop()
	if wood > 0:
		if inventory.add_item("madera", "Madera", wood) == -1:
			hud.show_message("Talaste el árbol, pero el inventario está lleno")
		else:
			hud.show_message("Talaste el árbol: +%d madera" % wood)
