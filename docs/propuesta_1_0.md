# Patógena S.A. · Propuesta para la 1.0: bucle incremental, recursos y máquinas con sentido

Pendiente del visto bueno de Edu (9-nov-2026). Nace de su petición tras la segunda prueba y de estudiar Factorio, Alchemy Factory, Arknights: Endfield (fábrica), Shapez 2 y los incrementales clásicos.

## 1. Lo que enseñan las referencias

- **Lo manual es el tutorial, no el bucle.** En Factorio se empieza minando y fabricando a mano, y el juego consiste en ir sustituyendo cada acción por máquinas, cintas y trenes. La comunidad de incrementales lo resume igual: hacerlo a mano un rato y luego desbloquear la automatización hace que esta se disfrute más, y lo manual debería durar unos 20 minutos como mucho.
- **La dificultad no es el clic, es la proporción.** Una máquina sola no da abasto con una cinta: hay que calcular cuántas máquinas por cinta, y si la cinta no saca lo que la máquina produce, la máquina se atasca (Endfield hace este cálculo explícito con cintas de 1 objeto cada 2 s).
- **Cada máquina tiene bocas físicas.** En Alchemy Factory y Endfield, las máquinas tienen puertos concretos de entrada y salida; la cinta se enchufa ahí, encaja como piezas de construcción y se ve entrar y salir el material.
- **Una cinta por ingrediente.** Mezclar muchos objetos en una cinta crea cuellos de botella; las guías recomiendan cintas separadas para cada material de mucho volumen.
- **Contenedores entre etapas** para que una máquina no se pare cuando le falta algo un momento.
- **No abrumar.** A Alchemy Factory se le valora que la complejidad nunca se dispara y que la fábrica es compacta.

## 2. El arco de la partida: de una jeringa a granjas de humanos

Cada recurso pasa por la misma escalera: **a mano → a mano con herramienta → máquina que alimentas tú → máquina con cinta → zombi o máquina sola → tubería y granja**.

| Etapa | Minutos | Qué haces | Lo nuevo |
| --- | --- | --- | --- |
| 0 · La jeringa | 0–8 | Pinchas al paciente a mano (animación vistosa), llevas el tubo, llenas la centrífuga, haces la primera mutación | Historia, científico, primera mutación |
| 1 · El primer taller | 8–20 | Extractor en la camilla, primeras cintas entre bocas, sala de espera con pacientes | Cintas, proporciones simples (1 camilla → 1 centrífuga) |
| 2 · El turno de noche | 20–35 | Llegan los zombis; operan camillas y cargan máquinas; varias líneas a la vez | Zombis, contenedores, divisores, energía |
| 3 · Tuberías | 35–55 | Cápsulas de donante: el humano queda conectado y da sangre continua por tubería; centrífugas industriales con entrada de líquido | Líquidos, tanques, bombas |
| 4 · La granja | 55–90 | Hileras de cápsulas alimentadas con suero (el suero que antes vendías); ríos de sangre por tubería; la cura avanza y hay que acelerar | Granja de humanos, mutaciones finales |

## 3. Recursos y gestión

- **Humanos** (el recurso base): llegan por la puerta a un ritmo limitado. Para más, gastas en campañas de donación (bocadillo, «análisis gratuito», contratos con hospitales). Un donante da 1 tubo y se va; una **cápsula** retiene al humano y da sangre continua, pero consume suero.
- **Sangre → plasma → mutación**: la cadena del virus.
- **Cultivo y agua → ADN y suero → vacunas**: la cadena del dinero; el suero también alimenta las cápsulas (bucle que une las dos cadenas al final).
- **Dinero**: vacunas y excedentes en el muelle; Dirección paga los hitos.
- **Energía**: kW por máquina; generador y luego la propia sangre (biogás, comedia negra).
- **Espacio**: niveles de laboratorio; la granja obliga a ampliar.
- **Zombis**: mano de obra gratuita que llega con la propagación; limitan qué se puede automatizar antes de tener máquinas caras.
- **Tensión global**: la cura avanza sola; producir mutaciones más rápido es la presión que da sentido a optimizar.

## 4. Máquinas con sentido y cintas que encajan

Reglas para todas las máquinas (se rehacen los modelos en la puerta 5):

1. **Bocas físicas y fijas.** Cada máquina tiene sus bocas en casillas concretas: una tolva o bandeja de entrada por ingrediente (con su icono en la boca) y una bandeja de salida. Solo ahí se enchufa una cinta, que encaja sola al acercarla.
2. **Se ve el recorrido.** El objeto entra por la boca, se ve dentro (el tubo en el rotor de la centrífuga, el plasma en la cuba del biorreactor) y sale por la bandeja hacia la cinta.
3. **Una boca por ingrediente.** La mezcladora tiene una boca para agua y otra para reactivo; así nunca se atasca por mezclar.
4. **Ritmos redondos.** Cinta Mk1 = 1 objeto/s. Cada receta se ajusta para que las proporciones sean sencillas (por ejemplo, 1 camilla con extractor alimenta 1 centrífuga, 2 centrífugas alimentan 1 biorreactor). El panel muestra entra/sale por minuto y avisa del cuello de botella.
5. **Contenedores y divisores** como piezas básicas desde la etapa 2; **tuberías** con depósitos y bombas para la sangre desde la etapa 3.
6. **Forma = función.** Cada pieza visible tiene una razón: la tolva donde entra, la cámara donde se procesa, la bandeja donde sale, el panel con su pantalla, la torre de luces.

## 5. Qué cambia respecto a lo que hay

- El inicio pasa a ser «pinchar a mano» con animación de verdad (ya está la base: camilla, pacientes, científico).
- Las bocas de las máquinas dejan de ser «toda la cara» y pasan a ser casillas concretas con su ingrediente.
- Se añaden: sala de espera y campañas de donantes, contenedores, energía, cápsulas de donante, tuberías y la granja.
- Los números se rehacen para proporciones sencillas; el bot comprueba los tiempos de cada etapa.

## 6. Orden de trabajo propuesto

1. Rediseñar las bocas y las recetas (simulación y flechas) con proporciones redondas; probar con el bot.
2. Etapa 0 completa con la animación de extracción (puerta 4 cerrada con esto).
3. Etapas 1–2 a calidad final (puerta 5, trozo vertical): modelos de máquinas con bocas físicas, cintas que entran y salen, zombis.
4. Etapas 3–4: líquidos, cápsulas y granja (puerta 6).

## Fuentes
- [Factorio, guía de inicio](https://factorio-wiki.pages.dev/en/guide/how-to-start) · [prioridades de investigación](https://factorio-wiki.pages.dev/en/guide/research-priority)
- [Hilo sobre automatización en incrementales](https://reddit.sentinel-team.org/posts/1rqz87n/snapshots/2026-03-12T13%3A38%3A32.876234Z) · [otro hilo](https://reddit.sentinel-team.org/posts/1s3d43n/snapshots/2026-03-26T00%3A44%3A57.52656Z)
- [Alchemy Factory en Steam](https://store.steampowered.com/app/3669570) · [guía de automatización](https://alchemy-factory.pages.dev/guides/alchemy-factory-automation-guide.html) · [reseña](https://trendingnow.games/reviews/alchemy-factory-review)
- [Endfield: tutorial del planificador de fábrica](https://enkad.enka.network/tutorial)
