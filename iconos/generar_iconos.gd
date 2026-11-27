extends SceneTree
## Uso (desde la carpeta del proyecto): godot --path . -s iconos/generar_iconos.gd
## Genera los iconos PNG del inventario (128x128, fondo transparente)
## fotografiando el modelo 3D de cada objeto.

const HeldItems = preload("res://Player/held_items.gd")
const OUT := "res://iconos/"
const SIZE := 128

var viewport: SubViewport
var camera: Camera3D


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	viewport = SubViewport.new()
	viewport.size = Vector2i(SIZE, SIZE)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 0.97, 0.9)
	env.ambient_light_energy = 0.55
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	viewport.add_child(world_env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 35, 0)
	light.light_energy = 1.25
	viewport.add_child(light)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(0, 0, 10)
	viewport.add_child(camera)

	var items := {
		"rama": _from_scene("res://objects/branch.tscn"),
		"piedra": _from_scene("res://objects/stone.tscn"),
		"hacha": _from_scene("res://objects/stone_axe.tscn"),
		"madera": _logs(),
		"piel": _hide(),
		"carne_cruda": _meat(Color("#b8323a"), Color("#e8a0a0")),
		"carne_cocida": _meat(Color("#7a4524"), Color("#a86a3a")),
		"pescado_crudo": _fish(Color("#8fa6b4"), Color("#c9d6dc")),
		"pescado_cocido": _fish(Color("#a8682e"), Color("#d39a52")),
		"agua": _water(),
		# Para el libro de fabricación (lo que se construye).
		"fogata": _from_scene("res://objects/campfire.tscn"),
		"refugio": _from_scene("res://objects/shelter.tscn"),
		"cofre": _built("res://objects/chest.gd"),
		"cama": _built("res://objects/bed.gd"),
		"mochila": _backpack(),
		"miel": _honey(),
	}
	# Lanza, flecha, arpón y venda: modelos propios con la punta más grande.
	items["lanza"] = _spear()
	items["flecha"] = _arrow()
	items["arpon"] = _harpoon()
	items["venda"] = _bandage()
	for id in ["machete", "arco", "antorcha", "olla", "baston"]:
		items[id] = HeldItems.make(id)

	for id in items:
		await _shoot(id, items[id])
	print("iconos: ", items.size())
	quit()


func _shoot(id: String, model: Node3D) -> void:
	# Quita luces de los modelos (la antorcha) para que no queme la foto.
	for l in model.find_children("*", "Light3D", true, false):
		l.queue_free()
	var outer := Node3D.new()  # Inclinación de la vista.
	var middle := Node3D.new()  # Giro en diagonal.
	var inner := Node3D.new()  # Pone el lado largo en horizontal.
	viewport.add_child(outer)
	outer.add_child(middle)
	middle.add_child(inner)
	inner.add_child(model)
	await process_frame

	var box := _aabb(model)
	var s := box.size
	var longest: float = max(s.x, s.y, s.z)
	var dims := [s.x, s.y, s.z]
	dims.sort()
	var elongated: bool = dims[2] > dims[1] * 1.8 and id != "cama"
	if elongated:
		# Los objetos muy finos se engordan para que se vean en pequeño.
		var thick: float = clampf(dims[2] / dims[1] / 5.0, 1.0, 3.0)
		if s.y == longest:
			model.scale = Vector3(thick, 1, thick)
			inner.rotation_degrees = Vector3(0, 0, -90)
		elif s.z == longest:
			model.scale = Vector3(thick, thick, 1)
			inner.rotation_degrees = Vector3(0, 90, 0)
		else:
			model.scale = Vector3(1, thick, thick)
		middle.rotation_degrees = Vector3(0, 0, 40)
		outer.rotation_degrees = Vector3(18, -15, 0)
	else:
		outer.rotation_degrees = Vector3(30, -30, 0)
	await process_frame

	box = _aabb(model)
	outer.position = -box.get_center()
	camera.size = max(box.size.x, box.size.y) * 1.12
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + id + ".png"))
	outer.queue_free()
	await process_frame


## Caja que encierra todas las mallas, en coordenadas del mundo.
func _aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mi.global_transform * mi.get_aabb()
		result = b if first else result.merge(b)
		first = false
	if node is MeshInstance3D:
		result = node.global_transform * node.get_aabb()
	return result


## Copia solo las mallas de una escena (sin scripts ni colisiones).
func _from_scene(path: String) -> Node3D:
	var scene: Node = load(path).instantiate()
	var root := Node3D.new()
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		var copy := MeshInstance3D.new()
		copy.mesh = mi.mesh
		copy.material_override = mi.material_override
		for i in mi.get_surface_override_material_count():
			copy.set_surface_override_material(i, mi.get_surface_override_material(i))
		var t: Transform3D = mi.transform
		var p: Node = mi.get_parent()
		while p != scene and p is Node3D:
			t = p.transform * t
			p = p.get_parent()
		copy.transform = t
		root.add_child(copy)
	scene.free()
	return root


func _part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, rot := Vector3.ZERO, scale := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scale
	parent.add_child(mi)
	return mi


func _cyl(r: float, h: float, seg := 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = seg
	return c


func _box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


func _logs() -> Node3D:
	var root := Node3D.new()
	var bark := Color("#6b4626")
	var cut := Color("#d9b27a")
	for p in [Vector3(-0.12, 0, 0), Vector3(0.12, 0, 0), Vector3(0, 0.2, 0)]:
		_part(root, _cyl(0.11, 0.7), bark, p, Vector3(90, 0, 0))
		_part(root, _cyl(0.095, 0.01), cut, p + Vector3(0, 0, 0.351), Vector3(90, 0, 0))
	return root


func _hide() -> Node3D:
	var root := Node3D.new()
	var c := Color("#b08050")
	_part(root, _box(0.6, 0.03, 0.8), c, Vector3.ZERO)
	for x in [-0.36, 0.36]:
		for z in [-0.34, 0.34]:
			_part(root, _box(0.18, 0.03, 0.12), c, Vector3(x, 0, z), Vector3(0, 25 * sign(x * z), 0))
	_part(root, _box(0.14, 0.03, 0.2), c, Vector3(0, 0, -0.48))
	_part(root, _box(0.3, 0.031, 0.35), Color("#8a5f36"), Vector3(0.05, 0.001, 0.05))
	return root


func _meat(color: Color, inside: Color) -> Node3D:
	var root := Node3D.new()
	_part(root, _sphere(0.22), color, Vector3.ZERO, Vector3.ZERO, Vector3(1.3, 0.8, 1.0))
	_part(root, _sphere(0.12), inside, Vector3(0.12, 0.08, 0.12), Vector3.ZERO, Vector3(1, 0.6, 1))
	_part(root, _cyl(0.035, 0.35), Color("#f2ead8"), Vector3(-0.38, 0, 0), Vector3(0, 0, 90))
	_part(root, _sphere(0.05), Color("#f2ead8"), Vector3(-0.56, 0, 0))
	return root


func _fish(color: Color, belly: Color) -> Node3D:
	var root := Node3D.new()
	_part(root, _sphere(0.2), color, Vector3.ZERO, Vector3.ZERO, Vector3(2.0, 0.9, 0.45))
	_part(root, _sphere(0.16), belly, Vector3(0.02, -0.06, 0.02), Vector3.ZERO, Vector3(1.9, 0.6, 0.45))
	var tail := PrismMesh.new()
	tail.size = Vector3(0.3, 0.25, 0.04)
	_part(root, tail, color, Vector3(-0.47, 0, 0), Vector3(0, 0, 90))
	_part(root, _sphere(0.035), Color.BLACK, Vector3(0.27, 0.05, 0.08))
	return root


func _water() -> Node3D:
	var root: Node3D = HeldItems.make("olla")
	var disc := _part(root, _cyl(0.11, 0.01), Color("#3b8fd6"), Vector3(0, 0.066, 0))
	return root


const WOOD := Color("#7a5530")
const STONE := Color("#8f8a80")


## Palo a lo largo de X, con la punta hacia +X.
func _shaft(root: Node3D, length: float, r: float) -> void:
	_part(root, _cyl(r, length, 8), WOOD, Vector3.ZERO, Vector3(0, 0, 90))


func _tip(root: Node3D, x: float, w: float, l: float, color := STONE) -> void:
	var tip := PrismMesh.new()
	tip.size = Vector3(w, l, w * 0.45)
	_part(root, tip, color, Vector3(x + l * 0.5, 0, 0), Vector3(0, 0, -90))


func _spear() -> Node3D:
	var root := Node3D.new()
	_shaft(root, 1.0, 0.03)
	_tip(root, 0.5, 0.16, 0.3)
	_part(root, _cyl(0.04, 0.06, 8), Color("#4a3320"), Vector3(0.48, 0, 0), Vector3(0, 0, 90))
	return root


func _arrow() -> Node3D:
	var root := Node3D.new()
	_shaft(root, 0.9, 0.022)
	_tip(root, 0.45, 0.1, 0.16)
	for a in [0.0, 90.0]:
		_part(root, _box(0.2, 0.12, 0.01), Color("#efe7d6"), Vector3(-0.36, 0, 0), Vector3(a, 0, 0))
	return root


func _harpoon() -> Node3D:
	var root := Node3D.new()
	_shaft(root, 1.0, 0.026)
	_tip(root, 0.5, 0.1, 0.22)
	# Púas hacia atrás a cada lado.
	_part(root, _box(0.16, 0.035, 0.03), STONE, Vector3(0.48, 0.06, 0), Vector3(0, 0, -35))
	_part(root, _box(0.16, 0.035, 0.03), STONE, Vector3(0.48, -0.06, 0), Vector3(0, 0, 35))
	# Cuerda enrollada al final.
	_part(root, _cyl(0.04, 0.12, 8), Color("#d8c9a0"), Vector3(-0.38, 0, 0), Vector3(0, 0, 90))
	return root


func _bandage() -> Node3D:
	var root := Node3D.new()
	# Rollo visto de frente: cara redonda con el agujero del centro.
	_part(root, _cyl(0.2, 0.16, 16), Color("#ece4d2"), Vector3.ZERO, Vector3(90, 0, 0))
	_part(root, _cyl(0.06, 0.162, 12), Color("#b9ad94"), Vector3.ZERO, Vector3(90, 0, 0))
	_part(root, _box(0.22, 0.01, 0.16), Color("#ece4d2"), Vector3(0.2, -0.19, 0), Vector3(0, 0, -10))
	return root


## Muebles que se crean por código (cofre y cama): se copian sus mallas.
func _built(path: String) -> Node3D:
	var thing: Node3D = load(path).new()
	thing._build_model()
	var root := Node3D.new()
	for mi in thing.find_children("*", "MeshInstance3D", true, false):
		var copy := MeshInstance3D.new()
		copy.mesh = mi.mesh
		copy.material_override = mi.material_override
		copy.transform = mi.transform
		root.add_child(copy)
	thing.free()
	return root


func _backpack() -> Node3D:
	var root := Node3D.new()
	var hide := Color("#a87444")
	var dark := Color("#7a5230")
	_part(root, _box(0.5, 0.6, 0.28), hide, Vector3(0, 0.3, 0))
	_part(root, _box(0.52, 0.22, 0.3), dark, Vector3(0, 0.55, 0.01))
	_part(root, _box(0.36, 0.2, 0.1), dark, Vector3(0, 0.2, 0.18))
	_part(root, _box(0.06, 0.5, 0.04), Color("#5a3c22"), Vector3(-0.14, 0.32, -0.16))
	_part(root, _box(0.06, 0.5, 0.04), Color("#5a3c22"), Vector3(0.14, 0.32, -0.16))
	_part(root, _box(0.08, 0.06, 0.04), Color("#d8c9a0"), Vector3(0, 0.46, 0.16))
	return root


func _honey() -> Node3D:
	var root := Node3D.new()
	_part(root, _cyl(0.2, 0.32, 14), Color("#e0a020"), Vector3(0, 0, 0))
	_part(root, _cyl(0.21, 0.06, 14), Color("#c98a2b"), Vector3(0, 0.05, 0))
	_part(root, _cyl(0.17, 0.08, 14), Color("#8a5a2a"), Vector3(0, 0.2, 0))
	_part(root, _box(0.36, 0.03, 0.06), Color("#d8c9a0"), Vector3(0, 0.24, 0))
	return root
