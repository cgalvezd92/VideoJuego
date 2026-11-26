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
| 11 | Refugio de madera con **R** (6 madera + 4 ramas); de noche, **E** para dormir hasta las 6:00 | 🧪 En pruebas |

Las siguientes etapas se definirán con el usuario antes de empezarlas.
