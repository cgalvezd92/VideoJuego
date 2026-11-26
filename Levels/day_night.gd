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

	sun.visible = height > 0.0
	sun.light_energy = daylight
	sun.light_color = Color.WHITE.lerp(Color(1.0, 0.6, 0.35), sunset)

	var sky: Color = night_sky.lerp(day_sky, daylight)
	environment.background_color = sky.lerp(sunset_sky, sunset * 0.7)
	environment.ambient_light_color = night_ambient.lerp(day_ambient, daylight)

	var day_number: int = int(total_hours / 24.0) + 1
	var hours: int = int(hour)
	var minutes: int = int((hour - hours) * 60.0)
	hud.set_clock("Día %d · %02d:%02d" % [day_number, hours, minutes])
