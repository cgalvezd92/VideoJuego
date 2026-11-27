# CLAUDE.md

Reglas del proyecto para Claude. Léelas antes de cada tarea.

## El proyecto

- Juego 3D de supervivencia ambientado en África, en primera persona.
- Motor: **Godot 4**.
- Lenguaje: **GDScript** (no usar C#).
- Renderizador: **Compatibility** (no Forward+ ni Mobile).

## Equipo del desarrollador

- MacBook Pro 2015 (Intel), 8 GB de RAM.
- **Priorizar siempre el rendimiento**: geometría simple, pocas luces, sombras
  baratas o desactivadas, texturas pequeñas, sin efectos de post-procesado
  pesados, y evitar código costoso en `_process` / `_physics_process`.

## Forma de trabajar

- Trabajar **por etapas**.
- **No avanzar a la siguiente etapa** hasta que el usuario confirme que la
  anterior funciona.
- **Sin plugins ni recursos innecesarios**: usar solo lo que trae Godot y lo
  imprescindible para la etapa actual.

## El usuario es principiante

En cada etapa, explicar paso a paso:

- Qué **nodos** crear en el editor, de qué tipo y con qué nombre.
- Cómo quedan en el **árbol de escena** (qué nodo es hijo de cuál).
- Qué **propiedades** cambiar en el Inspector.
- **Dónde va cada script**: en qué carpeta guardarlo y a qué nodo adjuntarlo.
- Qué acciones de entrada configurar en *Proyecto > Configuración del
  proyecto > Mapa de entrada*, si hacen falta.

## Etapas

| Etapa | Contenido | Estado |
|-------|-----------|--------|
| 1 | Movimiento, cámara, colisiones, escenario básico | ✅ Lista |
| 2 | Recoger piedras y ramas con la tecla **E** | ✅ Lista |
| 3 | Inventario en barra de 8 casillas abajo al centro (teclas **1–8** o rueda para elegir) | ✅ Lista |
| 4 | Hacer una fogata con **F** (gasta 3 ramas y 2 piedras), con luz que parpadea | ✅ Lista |
| 5 | Vida, hambre y sed: beber en la charca y comer bayas con **E**; la fogata cura | ✅ Lista |
| 6 | Ciclo día/noche: el sol se mueve, el cielo cambia de color y hay reloj en pantalla | ✅ Lista |
| 7 | Escenario de sabana: mapa de 120×120 m, acacias, rocas, hierba (MultiMesh), bruma y más recursos | ✅ Lista |
| 8 | Gacelas: pastan, pasean y huyen del jugador (3 manadas de 4) | ✅ Lista |
| 9 | Hacha de piedra: se hace con **C**, se equipa en una casilla y tala acacias con clic izquierdo (da madera) | ✅ Lista |
| 10 | Guardar y cargar: automático cada minuto y al salir, **F5** guardar, **F9** cargar, **F8** nueva partida | ✅ Lista |
| 11 | Refugio de madera con **R** (6 madera + 4 ramas); de noche, **E** para dormir hasta las 6:00 | ✅ Lista |
| 12 | Cazar y cocinar: **Ctrl** para agacharse, cazar gacelas con el hacha, cocinar en la fogata (**E**) y comer con clic | ✅ Lista |
| 13 | Menú de pausa con **Esc**: continuar, guardar, cargar, nueva partida, mostrar/ocultar controles y salir | ✅ Lista |
| 14 | Quitar los objetos de prueba del centro del mapa (caja, pared gris y rampa roja) | ✅ Lista |
| 15 | Sonidos generados por código (Autoload `Sounds`) — **quitados en la etapa 21** a petición del usuario | ❌ Quitada |
| 16 | Pantalla de inicio (escena principal): Continuar / Nueva partida / Salir; "Volver al inicio" en la pausa | ✅ Lista |
| 17 | Hiena nocturna: ronda y muerde de noche, teme al fuego, 3 hachazos la ahuyentan hasta la noche siguiente | ✅ Lista |
| 18 | Árboles que rebrotan: tocón 12 h, brote que crece hasta árbol completo a las 48 h de juego; se guarda | ✅ Lista |
| 19 | Mapa de África (`mapas/africa_3d.glb`): la zona de juego se lleva al punto de salida y todo se coloca sobre el relieve (`MapSetup`) | ✅ Lista |
| 20 | Brújula arriba en el centro y mapa del continente con **M** (posición, fogatas, refugios y zona de recursos) | ✅ Lista |
| 21 | Quitar todos los sonidos; la lista de controles de la izquierda se pliega y despliega con **H** (se recuerda); el juego empieza en pantalla completa (botón en la pausa para cambiarlo) | ✅ Lista |
| 22 | Recursos por todo el continente: celdas de 64 m que se crean y borran alrededor del jugador (nodo `World`); se guarda lo recogido y talado | ✅ Lista |
| 23 | Libro de fabricación a la derecha (se abre/cierra con **B**): recetas con materiales que tienes/necesitas; sustituye los avisos de encima de la barra | ✅ Lista |
| 24 | Beber con **E** en los ríos y lagos del mapa (colisión solo para el rayo, capa 3); el mar avisa de que es agua salada | ✅ Lista |
| 25 | Personajes: 6 sobrevivientes (`res://personajes/`, Autoload `Personajes`); se eligen al empezar una partida nueva y cambian vida, velocidad, hambre, sed, comida, curación, sigilo y visión nocturna | ✅ Lista |
| 26 | Objetos iniciales: machete (tala x2), lanza (clic derecho la lanza), arco + flechas, antorcha (luz y ahuyenta a la hiena), olla (llevar agua) y bastón (+15 % velocidad) | ✅ Lista |
| 27 | Energía (estamina): correr y saltar la gastan, se recupera al caminar/parar; agotado no corre; Mama Zuri tiene menos y el bastón ahorra | ✅ Lista |
| 28 | Fabricar en el libro: **X** flechas (1 rama + 1 piedra = 2) y **L** lanza (2 madera + 1 piedra) | ✅ Lista |
| 29 | Cebras y jirafas (`zebra.tscn`, `giraffe.tscn`, script `big_animal.gd`): pastan y huyen, no se cazan; manada de cada una cerca de la salida y al azar por el continente; 6 llamadas de dibujo por animal | ✅ Lista |
| 30 | Lluvia (nodo `Weather`): a ratos llueve (partículas GPU), cielo gris; apaga fogatas lejos de un refugio (E + 1 rama las reaviva); llena la olla | ✅ Lista |
| 31 | Mochila: cazar gacelas da piel; **P** con 3 pieles + 2 ramas amplía el inventario de 8 a 12 casillas (teclas 9 y 0); se guarda | 🧪 En pruebas |

Las siguientes etapas se definirán con el usuario antes de empezarlas.
