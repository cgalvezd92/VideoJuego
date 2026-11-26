extends StaticBody3D
## Fogata: la luz y las llamas parpadean un poco (Etapa 4).
## Va en el nodo raíz "Campfire" de campfire.tscn.

@export var base_energy: float = 1.5

@onready var light: OmniLight3D = $Light
@onready var flames: Node3D = $Flames

var time: float = 0.0


func _ready() -> void:
	# Cada fogata empieza en un momento distinto para que no parpadeen igual.
	time = randf() * 10.0
	# El grupo "campfire" permite al jugador saber si está cerca de una fogata.
	add_to_group("campfire")


func _process(delta: float) -> void:
	# Movimiento barato: solo dos senos, sin partículas ni sombras.
	time += delta
	var flicker: float = sin(time * 11.0) * 0.5 + sin(time * 7.3) * 0.5
	light.light_energy = base_energy + flicker * 0.25
	flames.scale = Vector3(1.0, 1.0 + flicker * 0.12, 1.0)
