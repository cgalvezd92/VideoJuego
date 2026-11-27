extends StaticBody3D
## Nota de Joseph (Etapa 51): un papel sujeto con piedras. Mírala y pulsa E
## para leerla. La crea Story (story.gd), que muestra el texto.

const HeldItems = preload("res://Player/held_items.gd")

var note_id: String = ""
var story: Node


func _ready() -> void:
	# Montoncito de piedras (se ve de lejos) con un papel claro encima.
	var stone := Color("#8f8a80")
	for p in [Vector3(-0.15, 0.1, 0.0), Vector3(0.15, 0.1, 0.05), Vector3(0.0, 0.1, -0.15), Vector3(0.0, 0.27, 0.0)]:
		var mi: MeshInstance3D = HeldItems._part(self, HeldItems._box(0.24, 0.18, 0.22), stone, p, Vector3(0, randf() * 90.0, 0))
		mi.visibility_range_end = 80.0
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var paper: MeshInstance3D = HeldItems._part(self, HeldItems._box(0.3, 0.01, 0.22), Color("#f1e7cf"), Vector3(0, 0.37, 0), Vector3(0, 20, 0), true)
	paper.visibility_range_end = 80.0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.5, 0.6)
	shape.shape = box
	shape.position.y = 0.22
	add_child(shape)


func get_prompt() -> String:
	return story.note_prompt(note_id)


func interact(_player: Node) -> String:
	story.read_note(note_id)
	return ""
