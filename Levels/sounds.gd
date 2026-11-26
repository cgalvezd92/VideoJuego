extends Node
## Sonidos del juego, generados por código al arrancar (Etapa 15).
## No usa archivos de audio: cada sonido se "dibuja" muestra a muestra.
##
## Es un Autoload llamado "Sounds" (Proyecto > Configuración del proyecto >
## Globales/Autoload), así que cualquier script puede usar:
##   Sounds.play("chop")                     -> sonido normal
##   Sounds.play_at("snort", posicion)       -> sonido 3D en un lugar
##   Sounds.make_loop_player("crackle")      -> sonido 3D que se repite

const RATE: int = 22050  # Muestras por segundo (calidad suficiente y ligera).
const SETTINGS_PATH: String = "user://ajustes.cfg"

var streams: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var next_player: int = 0
var volume: float = 0.8  # De 0 a 1.
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Siempre activo, para que suene el clic de los botones con el juego en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 8 reproductores que se van turnando: pueden sonar 8 sonidos a la vez.
	for i in 8:
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	_build_sounds()
	_load_volume()


## Reproduce un sonido. "pitch_range" cambia un poco el tono para que no
## suene siempre igual.
func play(sound: String, volume_db: float = 0.0, pitch_range: float = 0.1) -> void:
	if not streams.has(sound):
		return
	var player: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stream = streams[sound]
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + rng.randf_range(-pitch_range, pitch_range)
	player.play()


## Reproduce un sonido en un punto del mundo (se oye menos si está lejos).
func play_at(sound: String, where: Vector3, volume_db: float = 0.0) -> void:
	if not streams.has(sound):
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = streams[sound]
	player.volume_db = volume_db
	player.unit_size = 4.0
	player.max_distance = 35.0
	get_tree().root.add_child(player)
	player.global_position = where
	player.finished.connect(player.queue_free)
	player.play()


## Crea un reproductor 3D con un sonido que se repite (para la fogata).
func make_loop_player(sound: String) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = streams.get(sound)
	player.unit_size = 3.0
	player.max_distance = 15.0
	return player


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_mute(0, volume <= 0.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))
	var config := ConfigFile.new()
	config.set_value("audio", "volume", volume)
	config.save(SETTINGS_PATH)


func _load_volume() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		volume = config.get_value("audio", "volume", volume)
	AudioServer.set_bus_mute(0, volume <= 0.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.001)))


# --- Creación de los sonidos ---

func _build_sounds() -> void:
	rng.seed = 1234
	streams["step"] = _make(_step())
	streams["chop"] = _make(_chop())
	streams["hit"] = _make(_hit())
	streams["pickup"] = _make(_pickup())
	streams["drink"] = _make(_drink())
	streams["eat"] = _make(_eat())
	streams["build"] = _make(_build())
	streams["cook"] = _make(_cook())
	streams["snort"] = _make(_snort())
	streams["click"] = _make(_click())
	streams["crackle"] = _make(_crackle(), true)
	rng.randomize()


## Convierte una lista de valores (-1 a 1) en un sonido que Godot puede tocar.
func _make(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav


func _buffer(seconds: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * RATE))
	return samples


## Ruido suavizado: "smooth" pequeño = más grave y apagado.
func _noise(samples: PackedFloat32Array, smooth: float, amount: float, start: float, decay: float) -> void:
	var low: float = 0.0
	for i in range(int(start * RATE), samples.size()):
		var t: float = float(i) / RATE - start
		low += (rng.randf_range(-1.0, 1.0) - low) * smooth
		samples[i] += low * amount * exp(-t * decay)


## Tono simple que se apaga.
func _tone(samples: PackedFloat32Array, freq: float, amount: float, start: float, decay: float) -> void:
	for i in range(int(start * RATE), samples.size()):
		var t: float = float(i) / RATE - start
		samples[i] += sin(TAU * freq * t) * amount * exp(-t * decay)


func _step() -> PackedFloat32Array:
	var s := _buffer(0.1)
	_noise(s, 0.15, 1.2, 0.0, 45.0)
	return s


func _chop() -> PackedFloat32Array:
	var s := _buffer(0.22)
	_noise(s, 0.35, 0.9, 0.0, 28.0)
	_tone(s, 115.0, 0.6, 0.0, 22.0)
	return s


func _hit() -> PackedFloat32Array:
	var s := _buffer(0.22)
	_tone(s, 70.0, 0.9, 0.0, 18.0)
	_noise(s, 0.1, 0.6, 0.0, 30.0)
	return s


func _pickup() -> PackedFloat32Array:
	var s := _buffer(0.12)
	var phase: float = 0.0
	for i in s.size():
		var t: float = float(i) / RATE
		phase += TAU * lerpf(520.0, 880.0, t / 0.12) / RATE
		s[i] = sin(phase) * 0.35 * (1.0 - t / 0.12)
	return s


func _drink() -> PackedFloat32Array:
	var s := _buffer(0.42)
	for gulp in 3:
		var start: float = gulp * 0.13
		var phase: float = 0.0
		for i in range(int(start * RATE), int((start + 0.1) * RATE)):
			var t: float = float(i) / RATE - start
			phase += TAU * lerpf(240.0, 150.0, t / 0.1) / RATE
			s[i] += sin(phase) * 0.5 * sin(PI * t / 0.1)
	return s


func _eat() -> PackedFloat32Array:
	var s := _buffer(0.4)
	for crunch in 3:
		_noise(s, 0.7, 0.45, crunch * 0.12, 40.0)
	return s


func _build() -> PackedFloat32Array:
	var s := _buffer(0.32)
	for knock in 2:
		_tone(s, 180.0, 0.5, knock * 0.14, 30.0)
		_noise(s, 0.3, 0.5, knock * 0.14, 35.0)
	return s


func _cook() -> PackedFloat32Array:
	var s := _buffer(0.6)
	var low: float = 0.0
	for i in s.size():
		var t: float = float(i) / RATE
		var white: float = rng.randf_range(-1.0, 1.0)
		low += (white - low) * 0.2
		s[i] = (white - low) * 0.3 * sin(PI * t / 0.6)  # Chisporroteo agudo.
	return s


func _snort() -> PackedFloat32Array:
	var s := _buffer(0.28)
	var low: float = 0.0
	for i in s.size():
		var t: float = float(i) / RATE
		low += (rng.randf_range(-1.0, 1.0) - low) * 0.25
		s[i] = low * 0.9 * sin(PI * t / 0.28)
	return s


func _click() -> PackedFloat32Array:
	var s := _buffer(0.04)
	_tone(s, 1000.0, 0.3, 0.0, 120.0)
	return s


func _crackle() -> PackedFloat32Array:
	# 2 segundos que se repiten: un murmullo grave y chasquidos al azar.
	var s := _buffer(2.0)
	var low: float = 0.0
	for i in s.size():
		low += (rng.randf_range(-1.0, 1.0) - low) * 0.05
		s[i] = low * 0.35
	for pop in 30:
		var start: float = rng.randf_range(0.0, 1.95)
		var strength: float = rng.randf_range(0.3, 0.8)
		for i in range(int(start * RATE), mini(int((start + 0.02) * RATE), s.size())):
			var t: float = float(i) / RATE - start
			s[i] += rng.randf_range(-1.0, 1.0) * strength * exp(-t * 250.0)
	return s
