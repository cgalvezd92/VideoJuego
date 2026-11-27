extends StaticBody3D
## Acacia: se puede talar con el hacha (Etapa 9) y vuelve a crecer (Etapa 18).
## Va en el nodo raíz "Acacia" de acacia.tscn.
##
## Al talarla queda un tocón; después sale un brote que crece poco a poco
## hasta ser un árbol entero. El tiempo cuenta en horas del juego (DayNight),
## así que dormir también lo adelanta.

## Golpes de hacha necesarios para talarla.
@export var hits_needed: int = 4
## Madera que da al caer.
@export var wood_amount: int = 4

@export_group("Rebrote (horas del juego)")
## Horas que queda solo el tocón.
@export var stump_hours: float = 12.0
## Horas desde la tala hasta ser un árbol completo otra vez.
@export var regrow_hours: float = 48.0

var hits: int = 0
var felled: bool = false
var felled_at: float = 0.0
var base_scale: Vector3
var check_time: float = 0.0

@onready var parts: Array[Node3D] = [$Trunk, $Branch1, $Branch2, $Canopy]
@onready var stump: Node3D = $Stump
@onready var collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	base_scale = scale  # Cada acacia del mapa tiene su propio tamaño.
	add_to_group("shade_tree")  # Su copa da sombra al mediodía (Etapa 39).
	set_process(false)  # Solo los árboles talados necesitan revisarse.


func _process(delta: float) -> void:
	# Revisa el crecimiento cada 2 segundos (no en cada fotograma).
	check_time -= delta
	if check_time <= 0.0:
		check_time = 2.0
		_update_growth()


## ¿Se puede talar ahora? (no si es un tocón o un brote que está creciendo)
func can_chop() -> bool:
	return not felled and hits < hits_needed


## La llama Tools al golpear. Devuelve la madera conseguida (0 si aún no cae).
func chop() -> int:
	if not can_chop():
		return 0
	hits += 1

	if hits < hits_needed:
		_shake()
		return 0

	_fall()
	return wood_amount


func get_chop_text() -> String:
	if felled:
		return "Acacia joven: todavía está creciendo"
	return "Talar acacia (%d/%d)" % [hits, hits_needed]


## Convierte el árbol en tocón, contando desde la hora "at_hours" del juego.
## También la usa SaveGame al cargar una partida.
func set_felled(at_hours: float) -> void:
	felled = true
	felled_at = at_hours
	hits = hits_needed
	rotation.z = 0.0
	check_time = 0.0
	set_process(true)
	_update_growth()


func _shake() -> void:
	# Pequeña sacudida para notar el golpe.
	var tween := create_tween()
	tween.tween_property(self, "rotation:z", 0.04, 0.05)
	tween.tween_property(self, "rotation:z", -0.03, 0.08)
	tween.tween_property(self, "rotation:z", 0.0, 0.08)


func _fall() -> void:
	# Deja de chocar y cae de lado; luego queda el tocón.
	collision.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "rotation:z", PI * 0.5, 1.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(0.6)
	tween.tween_callback(func(): set_felled(_hours_now()))


func _update_growth() -> void:
	var hours: float = _hours_now() - felled_at

	if hours < stump_hours:
		# Solo el tocón.
		_show_tree(false)
		scale = base_scale
		collision.set_deferred("disabled", true)
	elif hours < regrow_hours:
		# Brote que crece del 15 % al 100 % de su tamaño.
		var growth: float = (hours - stump_hours) / (regrow_hours - stump_hours)
		var size: float = lerpf(0.15, 1.0, growth)
		_show_tree(true)
		scale = base_scale * size
		# Choca solo cuando ya es un arbolito de cierto tamaño.
		collision.set_deferred("disabled", size < 0.5)
	else:
		# Árbol completo otra vez: se puede volver a talar.
		felled = false
		hits = 0
		_show_tree(true)
		scale = base_scale
		collision.set_deferred("disabled", false)
		set_process(false)


func _show_tree(tree_visible: bool) -> void:
	for part in parts:
		part.visible = tree_visible
	stump.visible = not tree_visible


func _hours_now() -> float:
	var day_night = get_tree().get_first_node_in_group("day_night")
	return day_night.total_hours if day_night != null else 0.0
