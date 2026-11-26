# sobreviviente_modelo.gd
# Arma el personaje en 3D con figuras básicas de Godot (cajas, cápsulas, esferas).
# No hay que importar ningún modelo: todo se crea por código.
#
# Uso:
#   var m := SobrevivienteModelo.new()
#   add_child(m)
#   m.construir(Personajes.actual()["apariencia"], Personajes.actual()["objeto"])
#
# Mide unos 2 m de alto con la cabeza grande. Los pies quedan en y = 0.
class_name SobrevivienteModelo
extends Node3D

var _materiales := {}


func construir(ap: Dictionary, objeto: String = "ninguno") -> void:
	# Borra el modelo anterior (al cambiar de personaje).
	for hijo in get_children():
		hijo.queue_free()

	var c: float = ap.get("contextura", 1.0)
	var piel := Color(ap["piel"])
	var sombra := Color(ap["piel_sombra"])
	var pelo := Color(ap["color_pelo"])
	var tela := Color(ap["taparrabo"])
	var tela_oscura := tela.darkened(0.2)
	var oscuro := Color("#1d1712")
	var barro := Color("#5a3a22")
	var quemado: bool = ap.get("quemado", false)
	var rojo := sombra.lerp(Color("#e0533a"), 0.45)

	# --- Piernas y pies ---
	_parte(_capsula(0.09, 0.82), piel, Vector3(-0.1, 0.42, 0))
	_parte(_capsula(0.09, 0.82), sombra, Vector3(0.1, 0.42, 0))
	_parte(_caja(0.15, 0.07, 0.26), sombra, Vector3(-0.1, 0.035, 0.05))
	_parte(_caja(0.15, 0.07, 0.26), sombra, Vector3(0.1, 0.035, 0.05))

	# --- Torso ---
	var ancho := 0.42 * c
	var fondo := 0.26 * lerpf(1.0, c, 0.6)
	_parte(_caja(ancho, 0.58, fondo), piel, Vector3(0, 1.08, 0))

	# --- Taparrabo (cinturón + dos solapas) ---
	_parte(_caja(ancho + 0.02, 0.1, fondo + 0.02), tela_oscura, Vector3(0, 0.82, 0))
	_parte(_caja(0.2, 0.28, 0.03), tela, Vector3(0, 0.64, fondo / 2.0 + 0.015))
	_parte(_caja(0.2, 0.28, 0.03), tela, Vector3(0, 0.64, -fondo / 2.0 - 0.015))

	# --- Faja de cuero en el pecho (opcional) ---
	if ap.get("faja", false):
		_parte(_caja(ancho + 0.02, 0.16, fondo + 0.02), tela, Vector3(0, 1.2, 0))

	# --- Pintura de barro en el pecho (opcional) ---
	if ap.get("pintura", false):
		_parte(_caja(ancho * 0.7, 0.025, 0.01), barro, Vector3(0, 1.04, fondo / 2.0 + 0.006))
		_parte(_caja(ancho * 0.7, 0.025, 0.01), barro, Vector3(0, 0.98, fondo / 2.0 + 0.006))

	# --- Brazos y manos ---
	var xb := ancho / 2.0 + 0.075
	_parte(_capsula(0.065, 0.62), piel, Vector3(-xb, 1.04, 0))
	_parte(_capsula(0.065, 0.62), sombra, Vector3(xb, 1.04, 0))
	_parte(_esfera(0.075), piel, Vector3(-xb, 0.7, 0))
	_parte(_esfera(0.075), sombra, Vector3(xb, 0.7, 0))

	# --- Cuello y cabeza (esfera de pocos lados = look low-poly) ---
	_parte(_cilindro(0.07, 0.14), sombra, Vector3(0, 1.42, 0))
	_parte(_esfera(0.24, 0.5, 8, 5), piel, Vector3(0, 1.68, 0))
	_parte(_esfera(0.05), sombra, Vector3(-0.235, 1.67, 0))
	_parte(_esfera(0.05), sombra, Vector3(0.235, 1.67, 0))

	# --- Cara ---
	_parte(_esfera(0.03), oscuro, Vector3(-0.08, 1.71, 0.215))
	_parte(_esfera(0.03), oscuro, Vector3(0.08, 1.71, 0.215))
	_parte(_caja(0.09, 0.02, 0.02), oscuro, Vector3(-0.08, 1.77, 0.21), Vector3(0, 0, -6))
	_parte(_caja(0.09, 0.02, 0.02), oscuro, Vector3(0.08, 1.77, 0.21), Vector3(0, 0, 6))
	_parte(_caja(0.045, 0.08, 0.05), rojo if quemado else sombra, Vector3(0, 1.66, 0.235))
	_parte(_caja(0.1, 0.02, 0.02), oscuro, Vector3(0, 1.58, 0.215))

	if quemado:
		_parte(_caja(0.06, 0.03, 0.01), rojo, Vector3(-0.13, 1.62, 0.2))
		_parte(_caja(0.06, 0.03, 0.01), rojo, Vector3(0.13, 1.62, 0.2))

	if ap.get("pintura", false):
		for y in [1.64, 1.61]:
			_parte(_caja(0.06, 0.015, 0.01), barro, Vector3(-0.13, y, 0.205))
			_parte(_caja(0.06, 0.015, 0.01), barro, Vector3(0.13, y, 0.205))

	if ap.get("barba", false):
		_parte(_caja(0.38, 0.18, 0.14), pelo, Vector3(0, 1.56, 0.13))

	# --- Pelo ---
	match String(ap.get("pelo", "corto")):
		"corto":
			_casco_pelo(pelo)
		"rapado":
			_casco_pelo(pelo.lerp(piel, 0.3), 0.248)
		"tomate":
			_casco_pelo(pelo)
			_parte(_esfera(0.1), pelo, Vector3(0, 2.0, -0.06))
		"largo":
			_casco_pelo(pelo)
			_parte(_caja(0.46, 0.55, 0.14), pelo, Vector3(0, 1.5, -0.17))
		"afro":
			_parte(_esfera(0.34, 0.68, 10, 6), pelo, Vector3(0, 1.8, -0.16))
		_:
			pass # "calvo": sin pelo

	# --- Objeto inicial ---
	var madera := Color("#7a5530")
	var piedra := Color("#8f8a80")
	var metal := Color("#b9b8b2")
	match objeto:
		"lanza":
			_parte(_cilindro(0.022, 2.1), madera, Vector3(xb, 1.05, 0.08))
			_parte(_prisma(0.08, 0.18, 0.03), piedra, Vector3(xb, 2.19, 0.08))
		"machete":
			_parte(_caja(0.05, 0.14, 0.05), oscuro, Vector3(xb, 0.66, 0.08))
			_parte(_caja(0.06, 0.5, 0.015), metal, Vector3(xb, 0.34, 0.08))
		"olla":
			_parte(_cilindro(0.14, 0.16), Color("#5f6366"), Vector3(xb, 0.52, 0.1))
		"antorcha":
			_parte(_cilindro(0.03, 0.7), madera, Vector3(xb, 0.9, 0.1))
			var llama := _parte(_esfera(0.08), Color("#e9862f"), Vector3(xb, 1.32, 0.1))
			llama.scale = Vector3(1, 1.5, 1)
			llama.material_override = _material_brillante(Color("#f2a23a"))
		"arco":
			var xa := -xb - 0.05
			_parte(_caja(0.03, 0.5, 0.03), madera, Vector3(xa, 0.9, 0.1))
			_parte(_caja(0.03, 0.32, 0.03), madera, Vector3(xa + 0.05, 1.27, 0.1), Vector3(0, 0, -25))
			_parte(_caja(0.03, 0.32, 0.03), madera, Vector3(xa + 0.05, 0.53, 0.1), Vector3(0, 0, 25))
			_parte(_caja(0.006, 1.0, 0.006), Color("#efe4cf"), Vector3(xa + 0.11, 0.9, 0.1))
		"baston":
			_parte(_cilindro(0.03, 1.6), madera, Vector3(-xb, 0.8, 0.1))
		_:
			pass


# Casco de pelo: una esfera aplastada que cubre la parte de arriba y de atrás de la cabeza.
func _casco_pelo(color: Color, radio: float = 0.26) -> void:
	var p := _parte(_esfera(radio, radio * 2.0, 8, 5), color, Vector3(0, 1.8, -0.06))
	p.scale = Vector3(1, 0.7, 1)


# ------------------------------------------------------------
# Ayudantes: crean las piezas y los materiales
# ------------------------------------------------------------

func _parte(malla: Mesh, color: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malla
	mi.material_override = _material(color)
	mi.position = pos
	mi.rotation_degrees = rot
	add_child(mi)
	return mi


func _material(color: Color) -> StandardMaterial3D:
	var clave := color.to_html()
	if not _materiales.has(clave):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 1.0
		_materiales[clave] = m
	return _materiales[clave]


func _material_brillante(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.5
	return m


func _caja(x: float, y: float, z: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(x, y, z)
	return m


func _capsula(radio: float, alto: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radio
	m.height = alto
	m.radial_segments = 8
	m.rings = 2
	return m


func _esfera(radio: float, alto: float = -1.0, lados: int = 8, anillos: int = 4) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radio
	m.height = alto if alto > 0.0 else radio * 2.0
	m.radial_segments = lados
	m.rings = anillos
	return m


func _cilindro(radio: float, alto: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radio
	m.bottom_radius = radio
	m.height = alto
	m.radial_segments = 8
	return m


func _prisma(x: float, y: float, z: float) -> PrismMesh:
	var m := PrismMesh.new()
	m.size = Vector3(x, y, z)
	return m
