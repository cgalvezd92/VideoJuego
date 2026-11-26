extends StaticBody3D
## Acacia: se puede talar con el hacha (Etapa 9).
## Va en el nodo raíz "Acacia" de acacia.tscn.

## Golpes de hacha necesarios para talarla.
@export var hits_needed: int = 4
## Madera que da al caer.
@export var wood_amount: int = 4

var hits: int = 0


## La llama Tools al golpear. Devuelve la madera conseguida (0 si aún no cae).
func chop() -> int:
	if hits >= hits_needed:
		return 0  # Ya está cayendo.
	hits += 1

	if hits < hits_needed:
		_shake()
		return 0

	_fall()
	return wood_amount


func get_chop_text() -> String:
	return "Talar acacia (%d/%d)" % [hits, hits_needed]


func _shake() -> void:
	# Pequeña sacudida para notar el golpe.
	var tween := create_tween()
	tween.tween_property(self, "rotation:z", 0.04, 0.05)
	tween.tween_property(self, "rotation:z", -0.03, 0.08)
	tween.tween_property(self, "rotation:z", 0.0, 0.08)


func _fall() -> void:
	# Deja de chocar y cae de lado; luego desaparece.
	$CollisionShape3D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "rotation:z", PI * 0.5, 1.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(1.0)
	tween.tween_callback(queue_free)
