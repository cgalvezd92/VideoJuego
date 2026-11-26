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

Las siguientes etapas se definirán con el usuario antes de empezarlas.
