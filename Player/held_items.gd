extends RefCounted
## Modelos sencillos de los objetos de mano (Etapa 26): machete, lanza, arco,
## flecha, antorcha, olla y bastón (y el arpón, Etapa 33). Se crean por código con figuras básicas.
## Los usa Tools (en la mano) y los proyectiles (lanza y flecha en el aire).

const PickableScript = preload("res://objects/pickable.gd")

const WOOD := Color("#7a5530")
const DARK_WOOD := Color("#4a3320")
const STONE := Color("#8f8a80")
const METAL := Color("#b9b8b2")
const POT := Color("#5f6366")


## Devuelve el modelo del objeto, o null si no tiene (el hacha usa su escena).
static func make(id: String) -> Node3D:
	var root := Node3D.new()
	match id:
		"machete":
			_part(root, _box(0.04, 0.16, 0.04), DARK_WOOD, Vector3(0, -0.05, 0))
			_part(root, _box(0.015, 0.55, 0.07), METAL, Vector3(0, 0.3, -0.01))
		"lanza":
			_part(root, _cylinder(0.018, 1.6), WOOD, Vector3(0, 0, 0), Vector3(90, 0, 0))
			_part(root, _prism(0.06, 0.16, 0.025), STONE, Vector3(0, 0, -0.86), Vector3(-90, 0, 0))
		"flecha":
			_part(root, _cylinder(0.008, 0.7), WOOD, Vector3(0, 0, 0), Vector3(90, 0, 0))
			_part(root, _prism(0.035, 0.07, 0.012), STONE, Vector3(0, 0, -0.38), Vector3(-90, 0, 0))
			_part(root, _box(0.05, 0.004, 0.08), Color("#e8e0d0"), Vector3(0, 0, 0.32))
		"arco":
			_part(root, _box(0.025, 0.4, 0.025), WOOD, Vector3(0, 0, 0))
			_part(root, _box(0.025, 0.3, 0.025), WOOD, Vector3(0.04, 0.32, 0), Vector3(0, 0, -25))
			_part(root, _box(0.025, 0.3, 0.025), WOOD, Vector3(0.04, -0.32, 0), Vector3(0, 0, 25))
			_part(root, _box(0.004, 0.9, 0.004), Color("#efe4cf"), Vector3(0.1, 0, 0))
		"arpon":
			# Etapa 33: palo largo con punta de piedra y dos púas.
			_part(root, _cylinder(0.016, 1.4), WOOD, Vector3(0, 0, 0), Vector3(90, 0, 0))
			_part(root, _prism(0.045, 0.13, 0.02), STONE, Vector3(0, 0, -0.76), Vector3(-90, 0, 0))
			_part(root, _box(0.012, 0.012, 0.09), STONE, Vector3(0.03, 0, -0.66), Vector3(0, 30, 0))
			_part(root, _box(0.012, 0.012, 0.09), STONE, Vector3(-0.03, 0, -0.66), Vector3(0, -30, 0))
		"venda":
			# Etapa 37: rollo de tela clara.
			_part(root, _cylinder(0.035, 0.07), Color("#ece4d2"), Vector3(0, 0, 0), Vector3(0, 0, 90))
		"antorcha":
			_part(root, _cylinder(0.025, 0.6), WOOD, Vector3(0, 0, 0))
			var flame := _part(root, _sphere(0.07), Color("#f2a23a"), Vector3(0, 0.36, 0), Vector3.ZERO, true)
			flame.scale = Vector3(1, 1.5, 1)
			# Luz pequeña y sin sombras (barata).
			var light := OmniLight3D.new()
			light.position = Vector3(0, 0.45, 0)
			light.light_color = Color(1.0, 0.65, 0.3)
			light.light_energy = 1.3
			light.omni_range = 7.0
			light.shadow_enabled = false
			root.add_child(light)
		"olla":
			_part(root, _cylinder(0.12, 0.14), POT, Vector3(0, 0, 0))
			_part(root, _box(0.3, 0.015, 0.015), DARK_WOOD, Vector3(0, 0.08, 0))
		"baston":
			_part(root, _cylinder(0.022, 1.3), WOOD, Vector3(0, 0, 0))
		_:
			root.free()
			return null
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


## Crea un objeto que se puede recoger con E (para la lanza o la flecha que
## quedan en el suelo después de lanzarlas, y lo que sueltas con Q, Etapa 42).
## Las ramas y piedras usan su escena; lo que no tiene modelo 3D se ve con
## su dibujo del inventario (un cartel que siempre mira a la cámara).
static func make_pickable(id: String, display_name: String, amount: int = 1) -> Area3D:
	var area: Area3D
	if id == "rama" or id == "piedra":
		area = load("res://objects/%s.tscn" % ("branch" if id == "rama" else "stone")).instantiate()
	else:
		area = Area3D.new()
		area.set_script(PickableScript)
		var model := make(id)
		if model != null:
			model.rotation_degrees = Vector3(0, randf() * 360.0, 0)
			model.position.y = 0.05
			area.add_child(model)
		else:
			var icon_path: String = "res://iconos/%s.png" % id
			if ResourceLoader.exists(icon_path):
				var sprite := Sprite3D.new()
				sprite.texture = load(icon_path)
				sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
				sprite.pixel_size = 0.5 / 128.0  # Unos 50 cm de ancho.
				sprite.shaded = false
				sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
				sprite.position.y = 0.25
				sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				area.add_child(sprite)
		var shape := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.45
		shape.shape = sphere
		shape.position.y = 0.2
		area.add_child(shape)
	area.item_id = id
	area.display_name = display_name
	area.amount = amount
	# Lo que queda en el suelo se guarda en la partida (Etapa 42).
	area.add_to_group("dropped")
	return area


static func _part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO, glow: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if glow:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


static func _box(x: float, y: float, z: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(x, y, z)
	return m


static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = 6
	m.rings = 0
	return m


static func _sphere(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 6
	m.rings = 3
	return m


static func _prism(x: float, y: float, z: float) -> PrismMesh:
	var m := PrismMesh.new()
	m.size = Vector3(x, y, z)
	return m
