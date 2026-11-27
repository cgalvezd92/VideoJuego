extends PanelContainer
## Libro de fabricación: recuadro a la derecha con las recetas (Etapa 23).
## Se abre y se cierra con B (se recuerda). Lo crea el HUD (hud.gd) y
## Crafting (crafting.gd) le pasa las recetas cuando cambia el inventario.

const SETTINGS_PATH: String = "user://ajustes.cfg"

var expanded: bool = true
var recipes: Array = []
var content: VBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Arriba a la derecha, debajo del reloj; crece hacia la izquierda.
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_right = -16.0
	offset_top = 48.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.06, 0.78)  # Color de cuero.
	style.border_color = Color(0.6, 0.45, 0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)

	content = VBoxContainer.new()
	add_child(content)
	content.add_theme_constant_override("separation", 0)

	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		expanded = config.get_value("hud", "recipe_book_open", true)
	_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("recipe_book"):
		toggle()


func toggle() -> void:
	expanded = not expanded
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("hud", "recipe_book_open", expanded)
	config.save(SETTINGS_PATH)
	_rebuild()


## Cada receta: { key, name, needs: [[material, tienes, necesitas], ...],
## available, note }.
func set_recipes(new_recipes: Array) -> void:
	recipes = new_recipes
	_rebuild()


func _rebuild() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

	if not expanded:
		_add("[B] Libro de fabricación", 14, Color(1, 1, 1, 0.85))
	else:
		_add("Libro de fabricación", 16, Color(1.0, 0.88, 0.65))
		_add("[B] Cerrar", 12, Color(1, 1, 1, 0.55))
		for recipe in recipes:
			_add("", 2, Color.WHITE)  # Pequeño espacio entre recetas.
			var title_color: Color = Color(1.0, 0.85, 0.3) if recipe.available else Color(1, 1, 1, 0.8)
			_add("[%s] %s" % [recipe.key, recipe.name], 14, title_color)
			for need in recipe.needs:
				var enough: bool = need[1] >= need[2]
				var color: Color = Color(0.55, 0.9, 0.5) if enough else Color(1.0, 0.55, 0.5)
				_add("    %s  %d/%d" % [need[0], need[1], need[2]], 12, color)
			if recipe.note != "":
				_add("    " + recipe.note, 11, Color(1, 1, 1, 0.6))

	# Ajusta el recuadro al contenido (al cerrarlo se hace pequeño).
	_fit.call_deferred()


## Coloca el recuadro pegado a la derecha con el tamaño justo del contenido.
func _fit() -> void:
	var needed: Vector2 = get_combined_minimum_size()
	offset_right = -16.0
	offset_left = -16.0 - needed.x
	offset_top = 48.0
	offset_bottom = 48.0 + needed.y


func _add(text: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	content.add_child(label)
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
