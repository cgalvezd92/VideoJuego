extends RefCounted
## Ajustes del juego (Etapa 52): calidad gráfica, sensibilidad del ratón,
## brillo y contador de FPS. Se guardan en user://ajustes.cfg (sección
## "ajustes") y se aplican al empezar y al cambiarlos en el menú de pausa.
## No es un nodo: sus funciones se llaman con GameSettings.apply(...).

const PATH: String = "user://ajustes.cfg"
const BASE_SENSITIVITY: float = 0.0025

## Cada nivel de calidad:
## scale: resolución del 3D (0.7 = 70 %; lo de la pantalla se ve igual de nítido)
## view: distancia a la que se dibujan objetos y animales (multiplica)
## grass: parte de la hierba que se dibuja
## radius: celdas de recursos alrededor (1 = 3x3, 2 = 5x5)
## shadows: sombras del sol · particles: cantidad de lluvia y arena
## far: distancia máxima de la cámara · fog: dónde termina la bruma
const QUALITY: Array = [
	{ "nombre": "Baja", "scale": 0.7, "view": 0.6, "grass": 0.4, "radius": 1, "shadows": false, "particles": 0.4, "far": 180.0, "fog": 170.0 },
	{ "nombre": "Media", "scale": 1.0, "view": 1.0, "grass": 1.0, "radius": 2, "shadows": false, "particles": 1.0, "far": 240.0, "fog": 230.0 },
	{ "nombre": "Alta", "scale": 1.0, "view": 1.35, "grass": 1.0, "radius": 2, "shadows": true, "particles": 1.0, "far": 320.0, "fog": 300.0 },
]

static var quality: int = 1
static var sensitivity: float = 1.0
static var brightness: float = 1.0
static var show_fps: bool = false
static var loaded: bool = false


static func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		quality = clampi(config.get_value("ajustes", "calidad", 1), 0, QUALITY.size() - 1)
		sensitivity = config.get_value("ajustes", "sensibilidad", 1.0)
		brightness = config.get_value("ajustes", "brillo", 1.0)
		show_fps = config.get_value("ajustes", "fps", false)
	loaded = true


static func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(PATH)  # Conserva el resto de ajustes (pantalla completa, HUD...).
	config.set_value("ajustes", "calidad", quality)
	config.set_value("ajustes", "sensibilidad", sensitivity)
	config.set_value("ajustes", "brillo", brightness)
	config.set_value("ajustes", "fps", show_fps)
	config.save(PATH)


static func q(key: String) -> Variant:
	return QUALITY[quality][key]


## Aplica los ajustes al nivel que se está jugando.
static func apply(tree: SceneTree) -> void:
	if not loaded:
		load_settings()
	tree.root.scaling_3d_scale = q("scale")
	var main: Node = tree.current_scene
	if main == null or not main.has_node("Player"):
		return
	var player: Node = main.get_node("Player")
	player.mouse_sensitivity = BASE_SENSITIVITY * sensitivity
	player.get_node("Head/Camera3D").far = q("far")
	var sun = main.get_node_or_null("Sun")
	if sun != null:
		sun.shadow_enabled = q("shadows")
		sun.directional_shadow_max_distance = 45.0
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	var env_node = main.get_node_or_null("WorldEnvironment")
	if env_node != null:
		env_node.environment.tonemap_exposure = brightness
	var grass = main.get_node_or_null("Nature/Grass")
	if grass != null and grass.multimesh != null:
		grass.multimesh.visible_instance_count = int(grass.multimesh.instance_count * q("grass"))
	var world_script = load("res://Levels/world_resources.gd")
	world_script.view_factor = q("view")
	var world = main.get_node_or_null("World")
	if world != null:
		world.active_radius = q("radius")
		# Las cosas ya creadas toman la nueva distancia de dibujo.
		for cell in world.get_children():
			for thing in cell.get_children():
				world_script.apply_view_distance(thing)
	for path in ["Objects", "Nature", "Nature/Trees", "Nature/Rocks", "Animals"]:
		var group = main.get_node_or_null(path)
		if group != null:
			for thing in group.get_children():
				world_script.apply_view_distance(thing)
	var weather = main.get_node_or_null("Weather")
	if weather != null:
		weather.particle_factor = q("particles")
	var day_night = main.get_node_or_null("DayNight")
	if day_night != null:
		day_night.fog_end = q("fog")
		day_night._apply()
