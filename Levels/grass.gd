extends MultiMeshInstance3D
## Hierba de la sabana: miles de matas dibujadas de una sola vez (Etapa 7).
## Un MultiMesh es mucho más rápido que crear un nodo por cada mata.
## Va en el nodo "Grass" (MultiMeshInstance3D), hijo de Nature en main.tscn.

@export var count: int = 2500
## Tamaño del cuadrado (en metros) donde se reparte la hierba.
@export var area_size: float = 115.0
## Misma semilla = la hierba sale siempre en el mismo sitio.
@export var random_seed: int = 7


func _ready() -> void:
	# Se espera un momento para que las charcas ya estén en el grupo "water".
	_build.call_deferred()


func _build() -> void:
	# Una mata = un cono fino de 4 lados.
	var tuft := CylinderMesh.new()
	tuft.top_radius = 0.0
	tuft.bottom_radius = 0.07
	tuft.height = 0.45
	tuft.radial_segments = 4
	tuft.rings = 0

	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true  # Cada mata con su propio tono.
	tuft.material = material

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = tuft
	mm.instance_count = count

	var rng := RandomNumberGenerator.new()
	rng.seed = random_seed
	var ponds: Array = get_tree().get_nodes_in_group("water")
	var half: float = area_size * 0.5

	for i in count:
		var size: float = rng.randf_range(0.6, 1.4)
		# El cono tiene el centro a media altura: se sube para que toque el suelo.
		var pos := Vector3(rng.randf_range(-half, half), 0.22 * size, rng.randf_range(-half, half))
		# Sin hierba dentro de las charcas: se baja bajo el suelo.
		for pond in ponds:
			if Vector2(pos.x, pos.z).distance_to(Vector2(pond.global_position.x, pond.global_position.z)) < 2.6:
				pos.y = -1.0

		var basis := Basis(Vector3.UP, rng.randf() * TAU)
		basis = basis.scaled(Vector3.ONE * size)
		mm.set_instance_transform(i, Transform3D(basis, pos))

		var dry := Color(0.78, 0.68, 0.38)
		var green := Color(0.5, 0.55, 0.28)
		mm.set_instance_color(i, dry.lerp(green, rng.randf()))

	multimesh = mm
	# La hierba no proyecta sombras (ahorra mucho).
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
