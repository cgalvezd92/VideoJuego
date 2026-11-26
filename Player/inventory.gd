extends Node
## Inventario: guarda cuántos objetos de cada tipo lleva el jugador (Etapa 3).
## Va en el nodo "Inventory", hijo de Player.

## Se emite cada vez que cambia el contenido, para que la interfaz se actualice
## solo cuando hace falta (y no en cada fotograma).
signal changed

# Cantidad de cada objeto. Ejemplo: { "piedra": 3, "rama": 2 }
var amounts: Dictionary = {}
# Nombre visible de cada objeto. Ejemplo: { "piedra": "Piedra" }
var names: Dictionary = {}


## Añade objetos y devuelve el nuevo total de ese tipo.
func add_item(id: String, display_name: String, amount: int = 1) -> int:
	var total: int = amounts.get(id, 0) + amount
	amounts[id] = total
	names[id] = display_name
	changed.emit()
	return total


## Quita objetos si hay suficientes. Devuelve true si se pudo.
## (Se usará en etapas futuras, por ejemplo para fabricar o hacer fuego.)
func remove_item(id: String, amount: int = 1) -> bool:
	var current: int = amounts.get(id, 0)
	if current < amount:
		return false
	if current == amount:
		amounts.erase(id)
	else:
		amounts[id] = current - amount
	changed.emit()
	return true


func get_amount(id: String) -> int:
	return amounts.get(id, 0)
