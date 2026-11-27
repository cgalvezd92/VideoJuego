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
| 31 | Mochila: cazar gacelas da piel; **P** con 3 pieles + 2 ramas amplía el inventario de 8 a 12 casillas (teclas 9 y 0); se guarda | ✅ Lista |
| 32 | León (`lion.tscn`, `lion.gd`): de día defiende su territorio (25 m, rojo en el mapa), ruge, acecha y ataca; teme fuego y antorcha; 4 golpes lo retiran; uno cerca de la salida y algunos al azar | ✅ Lista |
| 33 | Pesca: arpón con **G** (1 madera + 2 piedras); con el arpón en la mano, clic mirando un río o lago (35 % de sacar un pez); el pescado crudo se cocina en la fogata (**E**). Además, arco con **K** (2 madera + 2 ramas) para usar las flechas | ✅ Lista |
| 34 | Misión principal (sobrevivir 14 días y llegar a la extracción: helicóptero el día 15 a las 7:00, punto verde en mapa y brújula, nodo `Extraction`) y 13 objetivos (nodo `Objectives` del Player, recuadro con **O**); pantalla de rescate; se guarda | ✅ Lista |
| 35 | Cocodrilos (`objects/crocodile.gd`, sin escena, malla única): hundidos en ríos y lagos; a 12 m (7 agachado) nadan hacia ti, saltan a la orilla y muerden (25); 3 golpes los alejan; uno en el lago de la salida y al azar por celdas | ✅ Lista |
| 36 | Dificultad al elegir personaje (Fácil / Normal / Difícil, en `Personajes`): hambre y sed ×0,75 / 1 / 1,3, daño de animales ×0,6 / 1 / 1,5, días hasta la extracción 10 / 14 / 20; se guarda y se ve en Continuar | ✅ Lista |
| 37 | Vendas: los mordiscos (león, hiena, cocodrilo) hacen sangrar 40 s (1 de vida/s, sin curarte comiendo); **V** fabrica 2 vendas (1 piel + 1 rama); con la venda en la mano, clic para parar la sangre y curar 15; todos empiezan con 2 vendas; se guarda | ✅ Lista |
| 38 | Plantas venenosas: arbustos con bayas más oscuras (`poisonous` en `berry_bush.gd`; 3 en la salida y 35 % en las celdas): comerlas quita 15 de vida y 15 de sed y el arbusto queda marcado; Mama Zuri los reconoce y no se las come | ✅ Lista |
| 39 | Sol y temperatura: de 11:00 a 16:00 al sol (sin lluvia) la sed baja más rápido, salvo a la sombra de una acacia o junto a un refugio; de noche, lejos de fogata, refugio o antorcha, hace frío: la energía se recupera despacio y baja a un tope; depende del aguante al clima del personaje | ✅ Lista |
| 40 | Inventario con dibujos: cada objeto tiene su icono PNG de 128×128 en `res://iconos/<id>.png` (19 iconos, hechos fotografiando sus modelos 3D con `iconos/generar_iconos.gd`); el nombre del objeto elegido sale encima de la barra | ✅ Lista |
| 41 | Mejorar el refugio: **J** cofre (4 madera + 2 ramas, `objects/chest.gd`): E abre una ventana con 12 casillas y tu inventario, clic para pasar objetos; **N** cama de pieles (3 pieles + 2 madera, `objects/bed.gd`): de noche, dormir cura 60 y para la sangre; se guardan con su contenido; libro de fabricación en dos columnas | ✅ Lista |
| 42 | Soltar objetos: **Q** suelta 1 del objeto elegido y **Shift+Q** todo el montón delante de ti (los que no tienen modelo 3D se ven con su icono); se recogen con **E** y se guardan en la partida (grupo `dropped`) | ✅ Lista |
| 43 | Antorchas y fogatas mejores: **T** fabrica una antorcha (1 rama + 1 piel); en la mano dura 3 min (el doble de rápido con lluvia) y su luz baja al final; con piedras en la mano, **E** rodea una fogata con un muro (4 piedras) y la lluvia ya no la apaga; se guarda | ✅ Lista |
| 44 | Herramientas que se gastan: hacha 40 usos, machete 60, lanza 30, arpón 40 y arco 50 (`MAX_DURABILITY` en `inventory.gd`); barrita de color en su casilla; aviso cuando queda poco y al romperse; el desgaste se conserva en el cofre, al soltarla y al guardar | 🧪 En pruebas |

Las siguientes etapas se definirán con el usuario antes de empezarlas.
