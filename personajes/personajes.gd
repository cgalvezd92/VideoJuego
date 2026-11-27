# personajes.gd
# AUTOLOAD (singleton). Regístralo en:
#   Proyecto > Configuración del proyecto > Globales (Autoload)
#   Ruta: res://personajes/personajes.gd   Nombre: Personajes
#
# Guarda los 6 sobrevivientes y cuál eligió el jugador.
# Desde cualquier script del juego puedes usar, por ejemplo:
#   Personajes.actual()["nombre"]
#   Personajes.stat("fuerza")
#   Personajes.mod("hambre_mult")
#   Personajes.salud_maxima()
extends Node

# Índice del personaje elegido en la pantalla de selección.
var elegido: int = 0

# Dificultad elegida al empezar (Etapa 36): 0 = Fácil, 1 = Normal, 2 = Difícil.
# Se guarda en la partida. Desde cualquier script: Personajes.dif("dias")
var dificultad: int = 1
const DIFICULTADES := [
	{
		"id": "facil", "nombre": "Fácil",
		"hambre_sed": 0.75,  # el hambre y la sed bajan más despacio
		"dano": 0.6,         # los animales hacen menos daño
		"dias": 10,          # días hasta la extracción
		"texto": "10 días · el hambre y la sed bajan más despacio · los animales hacen menos daño",
	},
	{
		"id": "normal", "nombre": "Normal",
		"hambre_sed": 1.0, "dano": 1.0, "dias": 14,
		"texto": "14 días · la experiencia pensada para el juego",
	},
	{
		"id": "dificil", "nombre": "Difícil",
		"hambre_sed": 1.3, "dano": 1.5, "dias": 20,
		"texto": "20 días · más hambre y sed · los animales muerden más fuerte",
	},
]

# Valores por defecto de los modificadores de juego.
# Si un personaje no define uno, se usa este valor.
const MOD_BASE := {
	"velocidad_mult": 1.0,         # velocidad al caminar/correr
	"estamina_mult": 1.0,          # cuánto aguanta corriendo
	"hambre_mult": 1.0,            # qué tan rápido baja el hambre
	"sed_mult": 1.0,               # qué tan rápido baja la sed
	"dano_sol_mult": 1.0,          # daño por sol / calor
	"carga_mult": 1.0,             # cuántas piedras y ramas puede llevar
	"construccion_mult": 1.0,      # velocidad para construir el refugio
	"curacion_mult": 1.0,          # cuánto curan plantas y vendajes
	"comida_mult": 1.0,            # cuánto llena la comida cocinada
	"sigilo_mult": 1.0,            # 1 = normal, menor = los animales te detectan antes
	"cordura_oscuridad_mult": 1.0, # cuánto le afecta estar sin fuego de noche
	"vision_noche": false,         # se orienta de noche / mapa más rápido
	"ve_huellas": false,           # ve rastros de animales
	"agua_segura": false,          # el agua hervida nunca enferma
	"fuego_seguro": false,         # enciende fuego al primer intento
	"conoce_plantas": false,       # distingue plantas comestibles de venenosas
}

var lista: Array[Dictionary] = [
	{
		"id": "tomas",
		"nombre": "Tomás «Flaco»",
		"rol": "Guía de trekking · Chile",
		"objeto": "lanza",
		"objeto_nombre": "Lanza de punta de piedra",
		"fortaleza": "Se orienta sin brújula: ve el mapa más rápido y no se pierde de noche.",
		"debilidad": "Poco peso: el hambre le baja la energía el doble de rápido.",
		"stats": {"salud": 6, "fuerza": 5, "clima": 6, "caza": 7},
		"modificadores": {"vision_noche": true, "hambre_mult": 2.0, "velocidad_mult": 1.1},
		"apariencia": {
			"piel": "#e2b48c", "piel_sombra": "#c8936b", "contextura": 0.9,
			"pelo": "corto", "color_pelo": "#2b1d14", "barba": true,
			"taparrabo": "#8a6a3f", "faja": false, "pintura": false, "quemado": true,
		},
	},
	{
		"id": "amara",
		"nombre": "Amara",
		"rol": "Bióloga · Nigeria",
		"objeto": "arco",
		"objeto_nombre": "Arco corto y 3 flechas",
		"fortaleza": "Lee huellas: ve el rastro de los animales y sabe cuáles evitar.",
		"debilidad": "Le teme a la oscuridad: pierde cordura sin fuego de noche.",
		"stats": {"salud": 7, "fuerza": 5, "clima": 8, "caza": 9},
		"modificadores": {"ve_huellas": true, "cordura_oscuridad_mult": 2.0, "dano_sol_mult": 0.7},
		"apariencia": {
			"piel": "#7a4a2c", "piel_sombra": "#5e3720", "contextura": 1.0,
			"pelo": "afro", "color_pelo": "#1a120c", "barba": false,
			"taparrabo": "#b5854b", "faja": true, "pintura": true, "quemado": false,
		},
	},
	{
		"id": "bruno",
		"nombre": "Bruno «Toro»",
		"rol": "Ex bombero · Brasil",
		"objeto": "machete",
		"objeto_nombre": "Machete oxidado",
		"fortaleza": "Construye refugios en la mitad del tiempo y carga el doble de ramas.",
		"debilidad": "Cuerpo grande: come y bebe el doble para no debilitarse.",
		"stats": {"salud": 9, "fuerza": 10, "clima": 5, "caza": 6},
		"modificadores": {"construccion_mult": 2.0, "carga_mult": 2.0, "hambre_mult": 2.0, "sed_mult": 2.0},
		"apariencia": {
			"piel": "#c48a5e", "piel_sombra": "#a36d45", "contextura": 1.32,
			"pelo": "calvo", "color_pelo": "#3a2618", "barba": true,
			"taparrabo": "#6f5233", "faja": false, "pintura": false, "quemado": true,
		},
	},
	{
		"id": "kenji",
		"nombre": "Kenji",
		"rol": "Cocinero · Japón",
		"objeto": "olla",
		"objeto_nombre": "Olla de metal abollada",
		"fortaleza": "Cocina sin enfermarse y hierve agua segura: las comidas rinden más.",
		"debilidad": "Piel clara: se quema con el sol de mediodía y pierde salud.",
		"stats": {"salud": 6, "fuerza": 4, "clima": 4, "caza": 5},
		"modificadores": {"agua_segura": true, "comida_mult": 1.5, "dano_sol_mult": 2.0},
		"apariencia": {
			"piel": "#e8c39a", "piel_sombra": "#cfa37a", "contextura": 0.88,
			"pelo": "tomate", "color_pelo": "#15110e", "barba": false,
			"taparrabo": "#9a7a4c", "faja": false, "pintura": false, "quemado": true,
		},
	},
	{
		"id": "lucia",
		"nombre": "Lucía",
		"rol": "Paramédica · Argentina",
		"objeto": "antorcha",
		"objeto_nombre": "Antorcha y pedernal",
		"fortaleza": "Cura heridas y picaduras con plantas; enciende fuego al primer intento.",
		"debilidad": "Mala cazadora: los animales la detectan antes.",
		"stats": {"salud": 8, "fuerza": 5, "clima": 6, "caza": 3},
		"modificadores": {"curacion_mult": 2.0, "fuego_seguro": true, "sigilo_mult": 0.5},
		"apariencia": {
			"piel": "#efc6a0", "piel_sombra": "#d4a37b", "contextura": 0.95,
			"pelo": "largo", "color_pelo": "#7a4a24", "barba": false,
			"taparrabo": "#7d5e3a", "faja": true, "pintura": false, "quemado": true,
		},
	},
	{
		"id": "zuri",
		"nombre": "Mama Zuri",
		"rol": "Herbolaria · Kenia",
		"objeto": "baston",
		"objeto_nombre": "Bastón de acacia",
		"fortaleza": "Conoce la flora: distingue frutos comestibles de venenosos al instante.",
		"debilidad": "Mayor de edad: camina lento y se cansa al correr.",
		"stats": {"salud": 7, "fuerza": 4, "clima": 10, "caza": 4},
		"modificadores": {"conoce_plantas": true, "velocidad_mult": 0.85, "estamina_mult": 0.7, "dano_sol_mult": 0.5},
		"apariencia": {
			"piel": "#5e3a24", "piel_sombra": "#472a18", "contextura": 1.12,
			"pelo": "rapado", "color_pelo": "#d9d2c4", "barba": false,
			"taparrabo": "#a0703f", "faja": true, "pintura": true, "quemado": false,
		},
	},
]


# Un valor de la dificultad elegida: "nombre", "hambre_sed", "dano" o "dias".
func dif(clave: String) -> Variant:
	return DIFICULTADES[dificultad][clave]


# Busca la dificultad por su id ("facil", "normal", "dificil"); Normal si no existe.
func indice_dificultad(id: String) -> int:
	for i in DIFICULTADES.size():
		if DIFICULTADES[i]["id"] == id:
			return i
	return 1


# El personaje elegido (un Dictionary).
func actual() -> Dictionary:
	return lista[elegido]


# Un stat del 1 al 10: "salud", "fuerza", "clima" o "caza".
func stat(nombre: String) -> int:
	return int(actual()["stats"].get(nombre, 5))


# Un modificador de juego (ver MOD_BASE).
func mod(nombre: String) -> Variant:
	return actual()["modificadores"].get(nombre, MOD_BASE.get(nombre, 1.0))


# --- Valores listos para usar en el jugador ---

# Salud máxima: de 58 (stat 1) a 130 (stat 10).
func salud_maxima() -> float:
	return 50.0 + stat("salud") * 8.0


# Daño de los golpes/ataques cuerpo a cuerpo.
func dano_ataque() -> float:
	return 5.0 + stat("fuerza") * 1.5


# Multiplicador del daño que hacen el calor, el frío y la lluvia (más aguante = menos daño).
func dano_clima() -> float:
	return (1.5 - stat("clima") * 0.1) * float(mod("dano_sol_mult"))


# Probabilidad (0 a 1) de que una caza salga bien.
func prob_caza() -> float:
	return clamp(0.1 + stat("caza") * 0.08, 0.0, 0.95)
