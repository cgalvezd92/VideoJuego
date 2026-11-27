# seleccion_personaje.gd
# Pantalla para elegir sobreviviente al comenzar el juego.
# Toda la interfaz se crea por código: solo necesitas la escena
# seleccion_personaje.tscn (un nodo Control con este script).
#
# Controles: flechas izquierda/derecha (o los botones) para cambiar,
# Enter o el botón "Comenzar" para empezar.
extends Control

# Escena del juego que se abre al apretar "Comenzar".
# Cámbiala en el Inspector si tu escena principal tiene otro nombre.
@export_file("*.tscn") var escena_juego: String = "res://main.tscn"

const COLOR_FONDO := Color("#f3e4c4")
const COLOR_TEXTO := Color("#2a1e14")
const COLOR_ACENTO := Color("#7a3b1d")
const COLOR_VERDE := Color("#2f6b45")
const COLOR_ROJO := Color("#a3361d")

const STATS := [
	["salud", "Salud"],
	["fuerza", "Fuerza"],
	["clima", "Aguante al clima"],
	["caza", "Caza"],
]

var indice := 0
var modelo: SobrevivienteModelo

var lbl_nombre: Label
var lbl_rol: Label
var lbl_objeto: Label
var lbl_fortaleza: Label
var lbl_debilidad: Label
var lbl_contador: Label
var lbl_dificultad: Label
var botones_dificultad: Array[Button] = []
var barras: Array[ProgressBar] = []
var valores: Array[Label] = []


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_crear_interfaz()
	indice = Personajes.elegido
	_mostrar()


func _process(delta: float) -> void:
	if modelo:
		modelo.rotate_y(delta * 0.6)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_cambiar(-1)
	elif event.is_action_pressed("ui_right"):
		_cambiar(1)
	elif event.is_action_pressed("ui_cancel"):
		# Esc: volver a la pantalla de inicio.
		get_tree().change_scene_to_file("res://Levels/title_screen.tscn")


func _cambiar(paso: int) -> void:
	indice = wrapi(indice + paso, 0, Personajes.lista.size())
	_mostrar()


func _mostrar() -> void:
	var d: Dictionary = Personajes.lista[indice]
	lbl_nombre.text = d["nombre"]
	lbl_rol.text = d["rol"]
	lbl_objeto.text = d["objeto_nombre"]
	lbl_fortaleza.text = d["fortaleza"]
	lbl_debilidad.text = d["debilidad"]
	lbl_contador.text = "%d / %d" % [indice + 1, Personajes.lista.size()]
	for i in STATS.size():
		var v: int = d["stats"][STATS[i][0]]
		barras[i].value = v
		valores[i].text = str(v)
	modelo.construir(d["apariencia"], d["objeto"])


func _comenzar() -> void:
	Personajes.elegido = indice
	if ResourceLoader.exists(escena_juego):
		get_tree().change_scene_to_file(escena_juego)
	else:
		push_error("No encuentro la escena del juego: " + escena_juego + ". Cámbiala en el Inspector (Escena Juego).")


# ------------------------------------------------------------
# Construcción de la interfaz
# ------------------------------------------------------------

func _crear_interfaz() -> void:
	var fondo := ColorRect.new()
	fondo.color = COLOR_FONDO
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)

	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 32)
	add_child(margen)

	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 40)
	margen.add_child(fila)

	_crear_vista_3d(fila)
	_crear_panel(fila)


func _crear_vista_3d(padre: Control) -> void:
	var contenedor := SubViewportContainer.new()
	contenedor.stretch = true
	contenedor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenedor.size_flags_vertical = Control.SIZE_EXPAND_FILL
	padre.add_child(contenedor)

	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	contenedor.add_child(vp)

	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_CLEAR_COLOR
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(1.0, 0.95, 0.85)
	entorno.ambient_light_energy = 0.7
	var mundo := WorldEnvironment.new()
	mundo.environment = entorno
	vp.add_child(mundo)

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-45, 30, 0)
	luz.light_energy = 1.1
	vp.add_child(luz)

	var cam := Camera3D.new()
	cam.fov = 40
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, 1.25, 4.0), Vector3(0, 1.05, 0))

	# Plataforma de arena bajo el personaje
	var base := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = 0.8
	disco.bottom_radius = 0.8
	disco.height = 0.06
	disco.radial_segments = 12
	base.mesh = disco
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#c99549")
	mat.roughness = 1.0
	base.material_override = mat
	base.position = Vector3(0, -0.03, 0)
	vp.add_child(base)

	modelo = SobrevivienteModelo.new()
	vp.add_child(modelo)


func _crear_panel(padre: Control) -> void:
	var panel := VBoxContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 8)
	padre.add_child(panel)

	panel.add_child(_label("ELIGE A TU SOBREVIVIENTE Y LA DIFICULTAD", 16, COLOR_ACENTO))
	lbl_nombre = _label("", 44, COLOR_TEXTO)
	panel.add_child(lbl_nombre)
	lbl_rol = _label("", 20, COLOR_ACENTO)
	panel.add_child(lbl_rol)

	lbl_objeto = _seccion(panel, "OBJETO INICIAL", COLOR_ACENTO)
	lbl_fortaleza = _seccion(panel, "FORTALEZA", COLOR_VERDE)
	lbl_debilidad = _seccion(panel, "DEBILIDAD", COLOR_ROJO)

	var grilla := GridContainer.new()
	grilla.columns = 3
	grilla.add_theme_constant_override("h_separation", 16)
	grilla.add_theme_constant_override("v_separation", 6)
	panel.add_child(grilla)
	for s in STATS:
		grilla.add_child(_label(s[1], 18, COLOR_TEXTO))
		var barra := ProgressBar.new()
		barra.min_value = 0
		barra.max_value = 10
		barra.step = 1
		barra.show_percentage = false
		barra.custom_minimum_size = Vector2(240, 18)
		barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		# Relleno de color para que la barra se lea bien sobre el fondo claro.
		var relleno := StyleBoxFlat.new()
		relleno.bg_color = COLOR_ACENTO
		relleno.set_corner_radius_all(4)
		barra.add_theme_stylebox_override("fill", relleno)
		var fondo_barra := StyleBoxFlat.new()
		fondo_barra.bg_color = Color("#dccaa6")
		fondo_barra.set_corner_radius_all(4)
		barra.add_theme_stylebox_override("background", fondo_barra)
		grilla.add_child(barra)
		barras.append(barra)
		var valor := _label("0", 18, COLOR_TEXTO)
		grilla.add_child(valor)
		valores.append(valor)

	_crear_dificultad(panel)

	var espacio := Control.new()
	espacio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(espacio)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	panel.add_child(botones)

	var anterior := _boton("< Anterior")
	anterior.pressed.connect(_cambiar.bind(-1))
	botones.add_child(anterior)

	lbl_contador = _label("", 18, COLOR_TEXTO)
	lbl_contador.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	botones.add_child(lbl_contador)

	var siguiente := _boton("Siguiente >")
	siguiente.pressed.connect(_cambiar.bind(1))
	botones.add_child(siguiente)

	var hueco := Control.new()
	hueco.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botones.add_child(hueco)

	var comenzar := _boton("Comenzar")
	comenzar.custom_minimum_size = Vector2(200, 56)
	comenzar.pressed.connect(_comenzar)
	botones.add_child(comenzar)
	comenzar.grab_focus()


# Fila de dificultad (Etapa 36): tres botones; el elegido queda marcado.
func _crear_dificultad(padre: Control) -> void:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 4)
	padre.add_child(caja)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	caja.add_child(fila)
	var titulo := _label("DIFICULTAD", 14, COLOR_ACENTO)
	titulo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	titulo.custom_minimum_size.x = 110
	fila.add_child(titulo)
	# El botón elegido se ve con el color de acento.
	var marcado := StyleBoxFlat.new()
	marcado.bg_color = COLOR_ACENTO
	marcado.set_corner_radius_all(4)
	var grupo := ButtonGroup.new()
	for i in Personajes.DIFICULTADES.size():
		var b := _boton(Personajes.DIFICULTADES[i]["nombre"])
		b.custom_minimum_size = Vector2(110, 36)
		b.add_theme_stylebox_override("pressed", marcado)
		b.add_theme_stylebox_override("hover_pressed", marcado)
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = i == Personajes.dificultad
		b.pressed.connect(_elegir_dificultad.bind(i))
		fila.add_child(b)
		botones_dificultad.append(b)
	lbl_dificultad = _label("", 16, COLOR_TEXTO)
	lbl_dificultad.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(lbl_dificultad)
	_elegir_dificultad(Personajes.dificultad)


func _elegir_dificultad(i: int) -> void:
	Personajes.dificultad = i
	lbl_dificultad.text = Personajes.DIFICULTADES[i]["texto"]


func _seccion(padre: Control, titulo: String, color: Color) -> Label:
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 2)
	padre.add_child(caja)
	caja.add_child(_label(titulo, 14, color))
	var texto := _label("", 16, COLOR_TEXTO)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caja.add_child(texto)
	return texto


func _label(texto: String, tamano: int, color: Color) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tamano)
	l.add_theme_color_override("font_color", color)
	return l


func _boton(texto: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(150, 56)
	b.add_theme_font_size_override("font_size", 18)
	return b
