extends Node
## Ciclo de día y noche: mueve el sol y cambia el color del cielo (Etapa 6).
## Va en el nodo "DayNight", hijo de Main (en main.tscn).

## Minutos reales que dura un día completo del juego.
@export var day_length_minutes: float = 10.0
## Hora a la que empieza la partida (0 a 24).
@export_range(0.0, 24.0) var start_hour: float = 7.0

@export_group("Colores del cielo")
@export var day_sky: Color = Color(0.53, 0.81, 0.92)
@export var sunset_sky: Color = Color(0.93, 0.55, 0.32)
@export var night_sky: Color = Color(0.02, 0.03, 0.08)

@export_group("Luz ambiente")
@export var day_ambient: Color = Color(0.42, 0.42, 0.42)
@export var night_ambient: Color = Color(0.07, 0.08, 0.13)

@onready var sun: DirectionalLight3D = $"../Sun"
@onready var environment: Environment = $"../WorldEnvironment".environment
@onready var hud = $"../Player/HUD"

## Horas pasadas desde el inicio (25.5 = día 2 a las 01:30).
var total_hours: float = 0.0
var update_time: float = 0.0


func _ready() -> void:
	# El grupo "day_night" permite al refugio saber la hora y adelantarla.
	add_to_group("day_night")
	# Tomás se orienta de noche: para él la noche es menos oscura (Etapa 25).
	if Personajes.mod("vision_noche"):
		night_ambient = night_ambient.lerp(Color(0.25, 0.27, 0.35), 0.6)
	total_hours = start_hour
	sun.visible = true
	sun.shadow_enabled = false  # Sin sombras: mucho más rápido.
	_apply()


func _process(delta: float) -> void:
	# 24 horas del juego pasan en "day_length_minutes" minutos reales.
	total_hours += delta * 24.0 / (day_length_minutes * 60.0)

	# Solo se actualizan la luz y el cielo 10 veces por segundo.
	update_time -= delta
	if update_time <= 0.0:
		update_time = 0.1
		_apply()


## Hora del día actual (de 0 a 24).
func get_hour() -> float:
	return fmod(total_hours, 24.0)


## Adelanta el reloj hasta la próxima vez que sea "hour" (por ejemplo, 6:00).
## Devuelve cuántas horas han pasado.
func skip_to_hour(hour: float) -> float:
	var hours: float = fmod(hour - get_hour() + 24.0, 24.0)
	total_hours += hours
	_apply()
	return hours


func is_night() -> bool:
	var hour: float = get_hour()
	return hour < 6.0 or hour >= 18.0


func _apply() -> void:
	var hour: float = get_hour()

	# Altura del sol: 0° a las 6:00, 90° a mediodía y 180° a las 18:00.
	var elevation: float = (hour - 6.0) / 12.0 * 180.0
	sun.rotation_degrees = Vector3(-elevation, 30.0, 0.0)

	# "daylight" vale 1 a pleno día y 0 de noche, con una transición suave
	# alrededor del amanecer y el atardecer.
	var height: float = sin(deg_to_rad(elevation))  # Negativo de noche.
	var daylight: float = smoothstep(-0.1, 0.3, height)
	# "sunset" vale 1 cuando el sol está cerca del horizonte.
	var sunset: float = 1.0 - smoothstep(0.0, 0.35, absf(height))

	# Lluvia (Etapa 30): de 0 a 1, la pone el nodo Weather.
	var weather = get_tree().get_first_node_in_group("weather")
	var rain: float = weather.rain_amount if weather != null else 0.0

	sun.visible = height > 0.0
	sun.light_energy = daylight * (1.0 - 0.6 * rain)
	sun.light_color = Color.WHITE.lerp(Color(1.0, 0.6, 0.35), sunset)

	var sky: Color = night_sky.lerp(day_sky, daylight)
	environment.background_color = sky.lerp(sunset_sky, sunset * 0.7)
	# Con lluvia el cielo se vuelve gris y la bruma se acerca.
	environment.background_color = environment.background_color.lerp(Color(0.42, 0.45, 0.5) * (0.3 + 0.7 * daylight), rain * 0.8)
	environment.fog_depth_end = lerpf(230.0, 110.0, rain)
	# Tormenta de arena (Etapa 49): cielo y bruma color arena, muy cerca.
	var sand: float = weather.sand_amount if weather != null else 0.0
	if sand > 0.0:
		environment.background_color = environment.background_color.lerp(Color(0.72, 0.56, 0.36) * (0.35 + 0.65 * daylight), sand * 0.9)
		environment.fog_depth_end = lerpf(environment.fog_depth_end, 32.0, sand)
	environment.fog_depth_begin = lerpf(70.0, 3.0, sand)
	# La bruma lejana toma el color del cielo para que el horizonte se funda.
	environment.fog_light_color = environment.background_color
	environment.ambient_light_color = night_ambient.lerp(day_ambient, daylight) * (1.0 - 0.3 * rain)

	var day_number: int = int(total_hours / 24.0) + 1
	var hours: int = int(hour)
	var minutes: int = int((hour - hours) * 60.0)
	var clock: String = "Día %d · %02d:%02d" % [day_number, hours, minutes]
	# Estación (Etapa 50).
	if weather != null and weather.season != "":
		clock += " · Estación " + weather.season
	if weather != null and weather.raining:
		clock += " · Lluvia"
	if weather != null and weather.sandstorm:
		clock += " · Tormenta de arena"
	hud.set_clock(clock)
