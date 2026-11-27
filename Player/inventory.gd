extends Node
## Inventario por casillas (Etapa 3).
## Va en el nodo "Inventory", hijo de Player.

## Se emite cuando cambia el contenido de alguna casilla.
signal changed
## Se emite cuando cambia la casilla seleccionada.
signal selection_changed

## Número de casillas: 8, o 12 con la mochila (Etapa 31).
var SLOT_COUNT: int = 8
## Se emite cuando cambia el número de casillas (al hacer la mochila).
signal resized

## Cada casilla es null (vacía) o un diccionario:
## { "id": "piedra", "name": "Piedra", "amount": 3 }
var slots: Array = []
var selected: int = 0

## Usos que aguanta cada herramienta antes de romperse (Etapa 44).
## La casilla guarda los usos que le quedan en "durability".
const MAX_DURABILITY: Dictionary = {
	"hacha": 40, "machete": 60, "lanza": 30, "arpon": 40, "arco": 50,
}


func _ready() -> void:
	slots.resize(SLOT_COUNT)  # Crea 8 casillas vacías (null).


## Añade objetos. Si ya hay una casilla con ese objeto, se apilan;
## si no, usa la primera casilla libre.
## Devuelve el nuevo total, o -1 si el inventario está lleno.
func add_item(id: String, display_name: String, amount: int = 1) -> int:
	var index: int = _find_slot(id)
	if index == -1:
		index = slots.find(null)
		if index == -1:
			return -1
		slots[index] = { "id": id, "name": display_name, "amount": 0 }
		if MAX_DURABILITY.has(id):
			slots[index].durability = MAX_DURABILITY[id]

	slots[index].amount += amount
	changed.emit()
	return slots[index].amount


## Quita objetos si hay suficientes. Devuelve true si se pudo.
## (Se usará en etapas futuras, por ejemplo para fabricar o hacer fuego.)
func remove_item(id: String, amount: int = 1) -> bool:
	var index: int = _find_slot(id)
	if index == -1 or slots[index].amount < amount:
		return false

	slots[index].amount -= amount
	if slots[index].amount == 0:
		slots[index] = null
	changed.emit()
	return true


func get_amount(id: String) -> int:
	var index: int = _find_slot(id)
	return 0 if index == -1 else slots[index].amount


## Cambia la casilla seleccionada (da la vuelta al pasar de la última).
func select(index: int) -> void:
	selected = posmod(index, SLOT_COUNT)
	selection_changed.emit()


## Devuelve lo que hay en la casilla seleccionada (o null).
func get_selected_item():
	return slots[selected]


func _find_slot(id: String) -> int:
	for i in SLOT_COUNT:
		if slots[i] != null and slots[i].id == id:
			return i
	return -1


## Amplía el inventario (la mochila lo deja en 12 casillas). Lo ya guardado
## se queda en su sitio y las casillas nuevas están vacías.
func expand(count: int) -> void:
	if count <= SLOT_COUNT:
		return
	SLOT_COUNT = count
	slots.resize(count)
	resized.emit()
	changed.emit()
	selection_changed.emit()


func has_backpack() -> bool:
	return SLOT_COUNT > 8


## Gasta un uso de una herramienta (Etapa 44). Si se acaba, se rompe: se
## quita 1 y, si tenías más, la siguiente empieza nueva.
## Devuelve "roto", "gastado" (le queda poco) o "".
func wear(id: String, uses: int = 1) -> String:
	var index: int = _find_slot(id)
	if index == -1 or not MAX_DURABILITY.has(id):
		return ""
	var slot: Dictionary = slots[index]
	var top: int = MAX_DURABILITY[id]
	var before: int = slot.get("durability", top)
	slot.durability = before - uses
	if slot.durability <= 0:
		slot.durability = top
		remove_item(id, 1)  # También avisa del cambio.
		return "roto"
	changed.emit()
	if before > top * 0.2 and slot.durability <= top * 0.2:
		return "gastado"
	return ""


## Usos que le quedan a una herramienta (0 a 1), o -1 si no se gasta.
func durability_ratio(slot) -> float:
	if slot == null or not MAX_DURABILITY.has(slot.id):
		return -1.0
	return float(slot.get("durability", MAX_DURABILITY[slot.id])) / MAX_DURABILITY[slot.id]


## Pone los usos que le quedan a una herramienta (al recogerla o sacarla del cofre).
func set_durability(id: String, value: int) -> void:
	var index: int = _find_slot(id)
	if index != -1 and MAX_DURABILITY.has(id):
		slots[index].durability = clampi(value, 1, MAX_DURABILITY[id])
		changed.emit()
