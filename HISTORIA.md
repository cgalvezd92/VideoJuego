# 14 días en África — La historia

## El vuelo
La avioneta **Kilima 7** despegó de Nairobi al amanecer con seis pasajeros que no se conocían, rumbo a un campamento de investigación al pie del **Kilimanjaro**. El piloto, **Joseph**, prometió un viaje tranquilo de dos horas.

- **Tomás «Flaco»**, guía de trekking chileno: venía a preparar una ruta para escaladores.
- **Amara**, bióloga nigeriana: iba a estudiar las manadas de gacelas.
- **Bruno «Toro»**, ex bombero brasileño: voluntario para construir el campamento.
- **Kenji**, cocinero japonés: contratado como cocinero del campamento.
- **Lucía**, paramédica argentina: iba a cubrir el puesto médico.
- **Mama Zuri**, herbolaria keniana: volvía a la tierra de su infancia.

## La caída
A mitad del vuelo, una tormenta de arena del norte cubrió el cielo. El motor falló. Joseph gritó por la radio: «¡Kilima 7 cayendo cerca de la montaña!»… y todo se volvió negro.

## El despertar
Tu personaje despierta junto a un lago, bajo el Kilimanjaro nevado, solo. A su lado, una nota de Joseph: un helicóptero vendrá al **viejo puesto de extracción del norte**, en el desierto, cuando acabe la temporada de tormentas. Hay que **aguantar 14 días** (10 en Fácil, 20 en Difícil).

## La sabana y sus huellas
Gacelas, leones, hienas y cocodrilos; sol que quema y noches que hielan; bayas buenas y venenosas. Joseph dejó **notas** en la aldea abandonada (vacía desde la última sequía), en la avioneta (con su botiquín), en el baobab gigante (el árbol de la vida, con miel) y en las cuevas (con dibujos de cazadores antiguos). Las estaciones seca y lluviosa cambian la tierra.

## El último viaje y el rescate
Hay que cruzar el **desierto del norte**, entre tormentas de arena, hasta la bandera roja y la columna de humo del puesto de extracción. La radio de **base Nairobi** da un mensaje distinto según los días que faltan. Al amanecer del último día llega el helicóptero.

Cada personaje tiene su propio final… y desde el aire se ve otra columna de humo en el horizonte: alguien más sigue ahí abajo. ¿Joseph?

## En el juego (Etapa 51)
- **Intro** al empezar una partida nueva (`Levels/story.gd`).
- **6 notas de Joseph** (`Levels/story_note.gd`): junto a la salida y en cada lugar especial; se leen con **E** y se guardan en el **diario (Y)**.
- **Radio** de la extracción con mensajes según los días que faltan (`objects/extraction.gd`).
- **Final** de cada personaje en la pantalla de rescate (`Player/objectives.gd`).
