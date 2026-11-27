extends Node
## Historia del juego (Etapa 51). Va en el nodo "Story" (Node), hijo de Main.
##
## 1. Intro: al empezar una partida nueva, unas pantallas de texto cuentan el
##    vuelo de la Kilima 7, la caída y el despertar (clic, Espacio o Enter
##    para pasar; Esc para saltarla).
## 2. Notas de Joseph, el piloto: una junto al punto de salida y otra en cada
##    lugar especial. Se leen con E y quedan en el diario (tecla Y).
## 3. y 4. Los mensajes de radio de la extracción y los finales de cada
##    personaje están en extraction.gd y objectives.gd (usan este script).
##
## El juego se pausa mientras se lee algo.

const MapSetup = preload("res://Levels/map_setup.gd")
const StoryNote = preload("res://Levels/story_note.gd")
const SAVE_PATH: String = "user://partida.json"

## Notas en el orden de la historia: id -> [título, dónde está, texto].
## "inicio" está junto al punto de salida; el resto en los lugares especiales.
const NOTES: Dictionary = {
	"inicio": ["La nota del lago", "", "Si alguien lee esto: la radio respondió. Un helicóptero de rescate vendrá al viejo puesto de extracción del norte, en el desierto. No puede llegar antes: la temporada de tormentas cierra el paso. Aguantad %d días. Haced fuego. Buscad agua. No os acerquéis a los ríos de noche.\n— Joseph, piloto de la Kilima 7"],
	"avion": ["Junto a la Kilima 7", "avion", "Desperté junto a la avioneta. Los pasajeros salieron despedidos con el golpe; vi huellas hacia el lago, al pie de la montaña. Dejo aquí el botiquín: alguien lo necesitará más que yo. Me llevo la radio rota.\n— J."],
	"aldea": ["La aldea vacía", "aldea", "La aldea está vacía desde la última gran sequía. Dejé en el cofre lo que pude salvar: antorchas, vendas, flechas y una lanza. Cuidado en la estación seca: las charcas desaparecen y solo quedan los ríos.\n— J."],
	"baobab": ["El árbol de la vida", "baobab", "Los ancianos llaman a este baobab el árbol de la vida: guarda miel en su corazón. Las abejas no perdonan... salvo con humo. Me picaron tres veces antes de entenderlo. Lleva una antorcha.\n— J."],
	"cueva1": ["Dibujos en la roca", "cueva1", "Pasé aquí una noche de lluvia. En las paredes hay dibujos de cazadores de hace miles de años: ellos también sobrevivieron. Desde aquí oí rugir al león de la montaña. No entres en su territorio sin fuego.\n— J."],
	"cueva2": ["La última nota", "cueva2", "La radio funcionó un minuto más: el rescate irá al puesto del norte cuando acaben las tormentas. Lleva agua: en el desierto la arena te seca la garganta en minutos. Yo voy delante. Si no me encuentras allí... busca el humo.\n— J."],
}

## Por qué iba cada personaje en la avioneta.
const MOTIVES: Dictionary = {
	"tomas": "Venías a preparar una ruta para escaladores. Llevas tu lanza de punta de piedra, recuerdo de otro viaje.",
	"amara": "Ibas a estudiar las manadas de gacelas. En la mochila, tu arco de práctica y tres flechas.",
	"bruno": "Ibas como voluntario a construir el campamento. Nunca te separas de tu machete oxidado.",
	"kenji": "Te contrataron como cocinero del campamento. Tu olla abollada viaja siempre contigo.",
	"lucia": "Ibas a cubrir el puesto médico. Llevas una antorcha y un pedernal, «por si acaso».",
	"zuri": "Volvías a la tierra de tu infancia. Tu bastón de acacia conoce estos caminos tanto como tú.",
}

## Final de cada personaje (pantalla de rescate).
const ENDINGS: Dictionary = {
	"tomas": "Tomás volverá a Chile con la ruta más dura que ha guiado jamás... y una historia que nadie le creerá.",
	"amara": "Amara llena su cuaderno con todo lo que aprendió de gacelas, leones y cocodrilos. Su investigación nunca será la misma.",
	"bruno": "Bruno, que levantó refugios con sus propias manos, decide volver para reconstruir la aldea abandonada.",
	"kenji": "Kenji abrirá un restaurante en Tokio con un plato nuevo: pescado del lago con miel del baobab.",
	"lucia": "Lucía guarda la última venda como amuleto: se salvó con lo que tenía a mano.",
	"zuri": "Mama Zuri se queda un día más en el campamento: hay plantas que enseñar a los jóvenes.",
}
const TEASER: String = "Desde el aire ves otra columna de humo en el horizonte. Alguien más sigue ahí abajo... ¿Joseph?"

var found: Dictionary = {}  # id de nota -> true
var ui: CanvasLayer
var reading: bool = false
var closed_at: int = 0
var intro_pages: Array = []
var intro_page: int = 0
var text_label: Label
var title_label: Label
var hint_label: Label
var mode: String = ""  # "intro", "nota" o "diario"

@onready var player: Node3D = $"../Player"
@onready var places: Node = $"../Places"


func _ready() -> void:
	add_to_group("story")
	process_mode = Node.PROCESS_MODE_ALWAYS
	var new_game: bool = not FileAccess.file_exists(SAVE_PATH)
	# Espera a que el terreno tenga colisión para colocar las notas.
	await get_tree().physics_frame
	await get_tree().physics_frame
	_place_notes()
	if new_game:
		_start_intro()


func _unhandled_input(event: InputEvent) -> void:
	if reading:
		var next: bool = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
			or event.is_action_pressed("jump") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
		if event.is_action_pressed("ui_cancel") or (mode == "diario" and event.is_action_pressed("diary")):
			get_viewport().set_input_as_handled()
			_close()
		elif next:
			get_viewport().set_input_as_handled()
			if mode == "intro" and intro_page < intro_pages.size() - 1:
				intro_page += 1
				_show_intro_page()
			else:
				_close()
	elif event.is_action_pressed("diary") and not get_tree().paused:
		get_viewport().set_input_as_handled()
		_open_diary()


## Días que hay que aguantar (dependen de la dificultad).
func days() -> int:
	return Personajes.dif("dias")


# --- Intro ---

func _start_intro() -> void:
	var who: Dictionary = Personajes.actual()
	intro_pages = [
		["Nairobi, 6:00 de la mañana", "La avioneta Kilima 7 despega rumbo al campamento del Kilimanjaro con seis pasajeros que no se conocen."],
		["Tú eres %s" % who["nombre"], "%s.\n\n%s" % [who["rol"], MOTIVES.get(who["id"], "")]],
		["La tormenta", "A mitad del vuelo, una tormenta de arena cubre el cielo. El motor tose... y se apaga.\n\nEl piloto, Joseph, grita por la radio:\n«¡Kilima 7 cayendo cerca de la montaña!»\n\nY todo se vuelve negro."],
		["El despertar", "Despiertas junto a un lago, a los pies del Kilimanjaro nevado. Estás solo.\n\nA tu lado hay una nota escrita a mano. Acércate y léela con E."],
	]
	intro_page = 0
	_open("intro")
	_show_intro_page()


func _show_intro_page() -> void:
	title_label.text = intro_pages[intro_page][0]
	text_label.text = intro_pages[intro_page][1]
	hint_label.text = "[Clic / Espacio] Seguir   ·   [Esc] Saltar   (%d/%d)" % [intro_page + 1, intro_pages.size()]


# --- Notas ---

func _place_notes() -> void:
	for id in NOTES:
		var pos: Vector3
		if id == "inicio":
			pos = player.spawn_position + Vector3(1.5, 0, -2.0)
		else:
			var place: Array = places.PLACES[NOTES[id][1]]
			pos = Vector3(place[1], 0, place[2]) + Vector3(4.0, 0, 6.0)
		var g = MapSetup.ground_height(player.get_world_3d(), pos.x, pos.z)
		pos.y = player.spawn_position.y if g == null else g
		var note := StaticBody3D.new()
		note.set_script(StoryNote)
		note.note_id = id
		note.story = self
		get_parent().add_child.call_deferred(note)
		note.set_deferred("global_position", pos)


func note_prompt(id: String) -> String:
	return "[E] Leer la nota de Joseph" + (" (ya leída)" if found.has(id) else "")


func read_note(id: String) -> void:
	if Time.get_ticks_msec() - closed_at < 300:
		return
	var first: bool = not found.has(id)
	found[id] = true
	_open("nota")
	title_label.text = NOTES[id][0]
	text_label.text = _note_text(id)
	hint_label.text = "[E / Clic] Cerrar   ·   Notas encontradas: %d/%d   ·   [Y] Diario" % [found.size(), NOTES.size()]
	if first and found.size() == NOTES.size():
		player.get_node("HUD").show_message("Encontraste todas las notas de Joseph")


func _note_text(id: String) -> String:
	var text: String = NOTES[id][2]
	return text % days() if id == "inicio" else text


# --- Diario ---

func _open_diary() -> void:
	_open("diario")
	title_label.text = "Diario · Notas de Joseph (%d/%d)" % [found.size(), NOTES.size()]
	var lines: PackedStringArray = []
	for id in NOTES:
		if found.has(id):
			lines.append("■ %s\n%s" % [NOTES[id][0], _note_text(id)])
		else:
			lines.append("■ ???\n(Nota sin encontrar%s)" % ("" if NOTES[id][1] == "" else ": busca en los lugares especiales"))
	text_label.text = "\n\n".join(lines)
	hint_label.text = "[Y] o [Esc] Cerrar"


# --- Ventana de texto ---

func _open(new_mode: String) -> void:
	mode = new_mode
	reading = true
	if ui == null:
		_build_ui()
	ui.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close() -> void:
	reading = false
	ui.visible = false
	closed_at = Time.get_ticks_msec()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 18
	add_child(ui)
	var background := ColorRect.new()
	background.color = Color(0, 0, 0, 0.82)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(background)

	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.93, 0.87, 0.74)  # Papel.
	style.border_color = Color(0.45, 0.32, 0.18)
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	# Un CenterContainer mantiene el papel siempre en el centro de la pantalla.
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(center)
	center.add_child(panel)
	panel.custom_minimum_size = Vector2(720, 0)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	title_label = _label(30, Color(0.36, 0.18, 0.08))
	column.add_child(title_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(664, 0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	text_label = _label(19, Color(0.16, 0.11, 0.07))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.custom_minimum_size = Vector2(650, 0)
	scroll.add_child(text_label)
	hint_label = _label(14, Color(0.4, 0.3, 0.2))
	column.add_child(hint_label)
	# El texto largo del diario se desplaza; el corto ocupa lo justo.
	text_label.resized.connect(func(): scroll.custom_minimum_size.y = minf(text_label.size.y, 420.0))


func _label(size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


# --- Guardar y cargar (lo usa SaveGame) ---

func get_save_data() -> Array:
	return found.keys()


func set_save_data(ids: Array) -> void:
	found.clear()
	for id in ids:
		found[id] = true
