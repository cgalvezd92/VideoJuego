extends CanvasLayer
## Pantalla de muerte (Etapa 53): sale cuando la vida llega a 0.
## Dice qué te dejó sin vida y un resumen de la partida, y deja elegir:
## "Despertar en la salida" (sigues con tu inventario) o "Cargar el último
## guardado". La crea Survival (survival.gd); el juego se pausa mientras está.

var survival: Node


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_death(cause: String) -> void:
	var player: Node = get_parent()
	survival = player.get_node("Survival")
	var objectives = player.get_node("Objectives")
	objectives.count("desmayos")

	var background := ColorRect.new()
	background.color = Color(0.25, 0.0, 0.0, 0.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	# El rojo aparece poco a poco.
	var tween := create_tween()
	tween.tween_property(background, "color:a", 0.85, 0.8)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	_label(box, "Te desmayaste", 46, Color(1.0, 0.45, 0.4))
	_label(box, "Causa: %s." % cause, 22, Color.WHITE)
	_label(box, objectives.summary(), 16, Color(1, 1, 1, 0.8))
	_label(box, "Desmayos en esta partida: %d" % objectives.stats.get("desmayos", 0), 15, Color(1, 0.85, 0.7, 0.9))
	_label(box, _tip(cause), 16, Color(1.0, 0.85, 0.4))

	var wake := _button(box, "Despertar en la salida (conservas tus cosas)")
	wake.pressed.connect(_on_wake)
	var save_game = get_tree().current_scene.get_node_or_null("SaveGame")
	if save_game != null and save_game.has_save():
		var load_button := _button(box, "Cargar el último guardado")
		load_button.pressed.connect(_on_load.bind(save_game))

	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	wake.grab_focus()


## Un consejo según la causa.
func _tip(cause: String) -> String:
	if cause.contains("sed"):
		return "Consejo: lleva agua en la olla y bebe en ríos y lagos (en la estación seca las charcas se secan)."
	if cause.contains("hambre"):
		return "Consejo: caza gacelas, pesca con el arpón o busca bayas (¡ojo con las oscuras!)."
	if cause.contains("sangre"):
		return "Consejo: usa una venda (V) en cuanto te muerdan para parar la sangre."
	if cause.contains("león"):
		return "Consejo: el león defiende su territorio de día; rodéalo o lleva una antorcha."
	if cause.contains("hiena"):
		return "Consejo: de noche quédate junto a una fogata o lleva una antorcha."
	if cause.contains("cocodrilo"):
		return "Consejo: acércate al agua agachado (Ctrl) y apártate si ves moverse algo."
	if cause.contains("comida cruda"):
		return "Consejo: cocina la carne y el pescado en la fogata antes de comerlos."
	return "Consejo: descansa en un refugio y no te quedes sin comida ni agua."


func _on_wake() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	survival.wake_up()
	queue_free()


func _on_load(save_game: Node) -> void:
	get_tree().paused = false
	save_game.load_last()


func _label(parent: Control, text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(720, 0)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	parent.add_child(label)
	return label


func _button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(420, 46)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 18)
	parent.add_child(button)
	return button
