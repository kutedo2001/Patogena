# Documento de diseño · Patógena S.A.

Copia en markdown del documento vivo: https://claude.ai/artifact/XVYRKWeQAvMiSUE9AbUn59 (manda el documento vivo si difieren). Versión aprobada en la puerta 2, 8-nov-2026. **Rediseño 2.0 del 10-nov** (sección «Rediseño 2.0»): manda sobre el resto.

## Resumen y pilares

**Un juego de fábrica en 3D isométrico en el que diriges el laboratorio de una farmacéutica que provoca un apocalipsis zombi.** Extraes materias primas, montas cadenas automatizadas de máquinas y cintas, y fabricas las mutaciones del virus como productos. Cada partida es una pandemia: ganas si conviertes en zombi al 90 % del mundo antes de que la humanidad termine la cura. Duración objetivo: 60–90 minutos por pandemia y unas 15–25 horas de contenido total.

Nombre del juego y de la empresa: **Patógena S.A.** «Farmacorp» se descartó porque es una cadena real de farmacias de Bolivia.

**Pilares**

1. **La fábrica se ve trabajar.** Cada máquina tiene animación, sonido y estado visible sin texto: el rotor gira, el líquido burbujea, la luz cambia de color.
2. **Las mejoras se fabrican.** No hay puntos ni árbol de compra: cada mutación del virus es un producto con su receta y su cadena. Mejorar el virus obliga a ampliar la fábrica.
3. **La pandemia es el reloj.** El mundo avanza solo y la cura humana también. La presión viene de fuera, no de enemigos en la fábrica.
4. **Todo está dentro del juego.** Ningún texto flotando: la información está en las máquinas, en los paneles del HUD y en los objetos del laboratorio (monitor del mundo, tablet, correos de Dirección).
5. **Comedia negra seria.** Una empresa que trata el fin del mundo como un proyecto con plazos. El humor es seco e inteligente: nadie se ríe en el juego, la gracia está en lo que la empresa considera normal. Gore estilizado (sangre, vísceras y mordiscos en low-poly) tratado con frialdad administrativa.

**Lo que NO es**

- No es un juego de combate ni de supervivencia: nadie te ataca dentro del laboratorio.
- No es un simulador médico realista: las recetas son de juego, no de química.
- No tiene multijugador en la versión 1.
- No es un gestor de empleados con necesidades: los ayudantes son herramientas.

## Referencias analizadas

| Referencia | Qué tomamos | Qué evitamos |
| --- | --- | --- |
| Satisfactory | Nodos de recursos con calidad (pobre, normal, pura) y extractores encima. Hitos entregados en un punto físico que desbloquean máquinas. Construcción con fantasma y giro. | Primera persona y mapas enormes. |
| Factorio | Cintas visibles, brazos que meten y sacan, divisores, red eléctrica por postes con radio, ratios como puzle. | Trenes y defensa. Estética gris. |
| Shapez 2 | Cada producto se reconoce por forma y color. Interfaz limpia. Hitos con entregas claras. | Abstracción total. |
| Timberborn | Isométrico bonito y legible, edificios con estado visible, cuadrícula con alturas. | Colonos con hambre y sed. |
| Alchemy Factory | Recetas de laboratorio combinables, colores vivos. | Logística poco profunda. |
| Dyson Sphere Program | Barra de construcción por categorías (1–9), panel de máquina con iconos, estadísticas por minuto, copiar configuración. | Escala planetaria. |
| Palworld | Criaturas que trabajan solas en estaciones: aquí, sujetos de prueba zombificados (versión 1.1). | Combate y captura. |
| Plague Inc | Mapa por regiones, tres ramas de mutaciones, cura como reloj, noticias. | Comprar mutaciones con puntos. |
| Can 'Em All | Correos de Dirección como hilo narrativo, objetos que se cogen y se lanzan, procesado jugoso. | Chiste fácil, gore realista, primera persona. |

## Bucle principal

Extraer → Procesar → Fabricar mutación → La pandemia avanza → Vender vacunas → Ampliar la fábrica → Extraer. Cada mutación mejora el virus, pero las siguientes piden recetas más largas y más producción.

- **Segundo a segundo:** caminas, coges y dejas objetos, colocas máquinas y cintas, ves todo moverse.
- **Minuto a minuto:** detectas un cuello de botella (máquina en ámbar), lo resuelves y entregas un lote.
- **Partida (60–90 min):** laboratorio pequeño a mano → virus liberado → automatización → niveles de laboratorio → carrera contra la cura.
- **Meta:** patentes permanentes, sedes nuevas, planos guardados.

## Mecánicas de la versión 1

Cuatro sistemas. Ayudantes y líquidos por tubería quedan para la 1.1.

### 1. Extracción
- Materias primas: sangre, cultivo, agua destilada y reactivo.
- Nodos: camillas con pacientes (sangre), incubadoras (cultivo), toma de agua. Calidad pobre/normal/pura (0,5×, 1×, 2×).
- A mano: mantener E 1 s junto al nodo = 1 unidad (primeros 5–10 min).
- Automatizado: extractor sobre camilla, brazo recolector sobre incubadora, bomba sobre toma de agua; Mk1–Mk3.
- Pedidos: reactivos en el terminal, llegan en camión al muelle; el precio sube si pides mucho seguido.
- Casos límite: inventario lleno; nodo ocupado por extractor.

### 2. Producción y logística
- Máquinas con receta, entradas, salidas y tiempo; las de varias recetas se configuran en su panel.
- Cintas Mk1–Mk3 (60/120/240 obj/min), colocadas arrastrando con curvas automáticas.
- Brazos que sacan y meten, con filtro opcional. Divisor, fusionador, almacén (50/200).
- Energía: kW por máquina; generador diésel, paneles solares, batería, reactor experimental; postes con radio. Sin energía, icono de rayo.
- Luz de estado: verde trabajando, ámbar falta entrada o salida llena, rojo sin energía.
- Quitar devuelve el 100 % los primeros 10 s y el 50 % después.

### 3. Mutaciones y la cámara de cepa
- El biorreactor fabrica el vial de la mutación elegida; el vial va a la cámara de cepa y el virus del cilindro crece y cambia.
- Tres ramas, 8 mutaciones cada una; algunas requieren otra antes.
- La primera mutación libera el virus en una región aleatoria.
- Pantalla de cepa con el árbol y las recetas en iconos.
- Un vial repetido se rechaza.

### 4. Pandemia y respuesta humana
- 12 regiones con población, clima y conexiones (aire, mar, tierra).
- Con síntomas de mordisco, los infectados se convierten. Victoria: 90 % zombi. Derrota: cura al 100 %.
- Respuesta: cuarentenas, inspecciones (paran un muelle 60 s), eventos.
- Vacunas: solo fuente de dinero; no afectan a la pandemia. Posible ampliación a otros fármacos.
- Monitor del mundo en la pared, panel del mundo en el HUD, teletipo de noticias.


## Diseño de la 1.0 (decidido con Edu el 9-nov-2026)

Sustituye a lo anterior donde choque. Detalle de referencias en `docs/propuesta_1_0.md`.

- **Tú eres la empresa.** No hay Dirección: el científico funda su propio laboratorio y se expande. Le guía **LISA**, la IA del laboratorio: fría, servicial y con humor negro (como ADA en Satisfactory). Ella explica los pasos y comenta lo que haces.
- **Bucle incremental**: todo empieza a mano (pinchar al paciente con animación vistosa) y la dificultad está en hacer con máquinas, en buena proporción, lo que antes hacías a mano. Arco: jeringa → primer taller → zombis → tuberías y cápsulas → granja de humanos.
- **Objetos al estilo Factorio, sin ventanas**: mochila de casillas con pilas; la pila elegida se ve en las manos. Clic en una máquina: mete lo que llevas en su entrada o recoge su salida; Mayús+clic: todo; clic derecho: abre su ventana con casillas para arrastrar. El científico va andando a hacerlo.
- **Hub de vacunas** (como el HUB de Satisfactory, pero de venta): una plataforma con su vehículo que recibe por cinta las **vacunas con la mutación dentro**. Cada caja vendida da dinero **y propaga esa mutación** por las regiones que compran.
- **Ascensor de pedidos** (como el ascensor espacial): pide lotes grandes de recursos por fases; cada fase completada desbloquea máquinas nuevas. Se ve cargar y despegar.
- **Terreno por parcelas de 8×8** alrededor del laboratorio, compradas con dinero y cada vez más caras; algunas requieren una fase del ascensor.
- **Alcance de la 1.0**: etapas 0–2 completas, tuberías y cápsulas de donante, granja de humanos, mapa del mundo con regiones, cura que avanza y victoria al 90 % zombi.
- **Duración**: partida larga, 8 horas o más.
- **Máquinas con bocas físicas** por ingrediente, cintas que entran y salen por ellas y ritmos redondos (ver la propuesta).

## Revisión tras la primera prueba de Edu (9-nov-2026): inicio, científico y estaciones

Sustituye a lo que contradiga en «Mecánicas de la versión 1».

- **El jugador es un científico** (personaje CC0 con bata): WASD o clic en el suelo para ir; clic en algo para usarlo. Al principio lo hace todo a mano.
- **Sin inventario**: lleva las cosas en las manos (una pila visible de hasta 4 del mismo objeto). Las deja en una máquina, una cinta, un almacén o el muelle de envío.
- **Estaciones de extracción construibles**, nada fijo:
  - *Camilla*: llega un paciente por la puerta de la sala, se tumba; el científico le saca sangre (3 s) y el paciente se va.
  - *Incubadora*: el cultivo crece (barra de la estación) y el científico recoge la placa.
  - *Toma de agua*: se coloca junto a la pared; el científico llena la garrafa.
- **Progresión de cada estación**: a mano → **científico con máquina** (mejora construida en la estación, más rápida) → **zombi con máquina** (automático: el producto sale por la boca de la estación a la cinta).
- **Zombis trabajadores**: tras liberar el virus, algunos pacientes vuelven convertidos y esperan en la puerta; se asignan con un clic a una estación o máquina y la operan solos.
- **Máquinas siempre automáticas**: procesan lo que les llegue por cinta o lo que les deje el científico; nunca hace falta hacer clic para que trabajen.
- **Bocas visibles**: flecha verde de entrada y naranja de salida en el suelo, en el fantasma al construir y al seleccionar.
- **Quitar devuelve el 100 %**.
- **Dinero**: el muelle de envío (con su camión) compra lo que le dejas: vacunas a buen precio y plasma barato al «banco de sangre»; Dirección paga cada hito. Nunca hay bloqueo sin salida.
- **Tutorial con historia**: el científico llega al sótano; los correos de Dirección presentan el «Proyecto Reinicio» con su tono corporativo y van dando pasos, con marcas en el mundo (flecha sobre el objetivo) y en el HUD, hasta la primera mutación.

## Rediseño 2.0: Two Point Hospital + Alchemy Factory (10-nov-2026) — MANDA SOBRE LO ANTERIOR

Decidido con Edu el 10-nov: **Two Point Hospital** para todo el hub (salas, construcción, aspecto de máquinas e interfaz) y **Alchemy Factory** para la automatización; **Factorio** para lo que AF no resuelva. Vista de director, todo mezclado (máquinas y cintas dentro de las salas) y personajes CC0 caricaturescos. Análisis de las referencias en `docs/referencias/two_point_alchemy.md`. Donde esta sección choque con las anteriores, manda esta.

**La regla del rediseño: cada cosa y cada pieza tiene sentido.** Antes de añadir una pieza hay que poder contestar qué es en un laboratorio de verdad, por qué tiene esa forma y qué pasaría si no estuviera.

### Cómo se juega
- **Eres la dirección.** Ya no hay un científico que lleves tú; no hay mochila ni WASD.
  - Con el ratón construyes salas, colocas máquinas y cintas, contratas personal y lo asignas.
  - El personal hace el trabajo.
- **El bucle:**
  1. Llegan pacientes.
  2. El personal les saca sangre y la lleva a mano a las máquinas.
  3. Montas cintas y tuberías para que nadie tenga que llevar nada.
  4. Fabricas productos y los envías.
  5. Con eso mejoras la cepa en la sala de cepas y el mundo se va convirtiendo.
- **La gracia, segundo a segundo** (la de Two Point más la de Alchemy Factory):
  - ver a la gente hacer cosas absurdas con total seriedad;
  - resolver dónde va cada sala y por dónde pasa cada cinta;
  - cuadrar cuántas máquinas alimenta una cinta;
  - ver cómo la fábrica se queda sola funcionando.

### El edificio y las salas (Two Point)
- **El laboratorio es una planta con pasillos.** Se amplía comprando parcelas, como los solares de Two Point.
- **Cómo se construye una sala:**
  1. Se arrastra el plano; se pueden añadir o quitar casillas.
  2. Se pone la puerta y, si quieres, ventanas.
  3. Se colocan los objetos obligatorios (marcados con estrella).
  4. Se confirma con el visto verde.
  5. Después se puede editar o vender.
- **Huellas:** cada objeto marca la casilla desde la que se usa. Si queda tapada, no se puede confirmar.

| Sala | Mínimo | Obligatorio | Personal | Qué pasa dentro |
| --- | --- | --- | --- | --- |
| Recepción (objeto de pasillo) | — | mostrador | recepcionista | el paciente se registra y espera en los bancos del pasillo |
| Sala de extracción | 3×3 | camilla, carrito de extracción | científico o becario | se tumba el paciente, se le saca sangre y se va mareado |
| Laboratorio de sangre | 3×4 | puesto de control | técnico | centrífugas |
| Laboratorio genético | 4×4 | puesto de control, estufa de cultivo | técnico | estufa, secuenciador y biorreactor |
| Sala de mezclas | 3×4 | puesto de control | técnico | mezcladora, destilador y sintetizador |
| Envasado | 3×4 | puesto de control | técnico | envasadora |
| Almacén y muelle | 4×4 | muelle de carga | becario | entran los pedidos y salen los envíos |
| Sala de cepas | 4×5 | mesa de ingeniería, cámara de la cepa | científico | árbol de mejoras y síntesis |
| Sala de máquinas | 3×3 | generador | conserje | energía |
| Sala de descanso | 2×3 | máquina de café | — | el personal recupera energía |
| Sala de cápsulas (tarde) | 4×4 | cápsula | científico | gente en cápsulas que da sangre sin parar |

- **Máquinas por tipo de sala.** Las máquinas solo se colocan en la sala que les corresponde, como la máquina de rayos X de Two Point.
  - Cada sala necesita un técnico presente para que sus máquinas funcionen. Un técnico atiende todas las de su sala.
  - El técnico se ve trabajando en el puesto de control y acude a la máquina que se atasca.
- **Pasillo:** recepción, bancos, máquinas de café, plantas, papeleras, extintores y carteles de la empresa.
  - Los objetos de pasillo suben el ánimo de pacientes y personal.

### Personal
- **Científico:** extrae sangre, trabaja en la sala de cepas y puede hacer de técnico.
- **Técnico:** atiende un laboratorio.
- **Becario:** lleva y trae. Mientras no haya cintas, carga en una gradilla lo que sale de una sala y lo deja en la boca de entrada de la siguiente. Es el transporte manual que la cinta sustituye.
- **Conserje:** limpia sangre y vómitos y repara máquinas.
- **Recepcionista.**
- **Zombis** (tras liberar el virus): personal gratis que lleva cosas y extrae sangre, pero asusta a los pacientes.
- **Atributos:** cada persona tiene sueldo, energía y uno o dos rasgos con gracia (p. ej. «hemofóbico»: trabaja más lento en extracción).

### Pacientes
- **Recorrido:** entran por la puerta del edificio → recepción → bancos → sala de extracción → se van mareados, tambaleándose.
- **Llegada:** depende de la reputación y de las campañas (bocadillo gratis, análisis gratuito, contrato con un hospital).
- **Colas:** cada sala tiene su cola, visible en su ficha.

### Logística con sentido (Alchemy Factory; Factorio donde haga falta)
- **Cada cosa viaja en su envase real.**
  - **Sólidos:** tubo de extracción, bolsa de hematíes, bolsa de plaquetas, placa de Petri, eppendorf de ADN, vial de vector, bote de proteína, cápsides, viales y cajas de vacunas, frasco de reactivo. Van por **cinta**.
  - **Líquidos:** plasma, agua, suero, medio de cultivo, caldo de viriones, neurotoxina. Van por **tubería** y se guardan en **depósitos**.
- **Bocas fijas.** Cada máquina tiene sus entradas y salidas en su sitio:
  - **Tolva de sólidos:** ranura con cortina de lamas y bandeja donde se ve lo que espera amontonado.
  - **Brida de tubería:** con el color del líquido y una mirilla que enseña el nivel.
  - **Bandeja de salida:** pone el objeto en una cinta de una casilla.
  - Una cinta solo conecta por una boca. Al construir se ven las bocas con flechas (verde entra, naranja sale).
- **Cintas.**
  - Forma: anchas (0,8 casillas), a 0,45 m sobre patas, con raíles y rodillos en los extremos.
  - Carga: objetos grandes en fila.
  - Colocación: se colocan arrastrando y, si cruzas una cinta con otra, se crea un divisor o un unificador. Más adelante, divisor con filtro.
  - Obstáculo: la cinta no se puede pisar.
- **Cruzar paredes y pasillos.**
  - **Pasamuros:** módulo de pared, como una ventana, con cortina de lamas por donde pasa la cinta o la tubería.
  - **Paso bajo suelo:** como la cinta subterránea de Factorio, hasta 4 casillas; la gente camina por encima. Así no se corta un pasillo.
- **Tuberías.**
  - Van a ras de suelo, pegadas a la pared, sin dirección, con el color del contenido (rojo sangre, ámbar plasma, azul agua, verde suero, morado viriones).
  - Cruzan igual que las cintas: por pasamuros o bajo el suelo.
- **Colchones:**
  - **Caja de almacén** (1×1, 1 entrada y 1 salida; la grande, 2 y 2);
  - **depósito** para líquidos (2×2, con el nivel a la vista).
- **Velocidades que cuadran.**
  - La cinta empieza en 60 objetos/min y la tubería en 120 l/min.
  - Cada máquina está ajustada a números redondos, para que la proporción se pueda calcular: 1 cinta → 2 centrífugas → 1 envasadora.
  - Las mejoras de cinta y de máquinas van a la par, como en Alchemy Factory.

### Cadena con sentido (sustituye a la tabla de recetas; los números se cierran con el bot)

| Máquina (sala) | Entra | Sale | Sentido |
| --- | --- | --- | --- |
| Camilla (extracción) | paciente | tubo de sangre | se extrae a tubo, como en un análisis |
| Centrífuga (sangre) | 6 tubos de sangre | plasma rico en plaquetas (tubería) + bolsa de hematíes (cinta) | la centrífuga separa la sangre en sus partes: una entrada, dos salidas |
| Centrífuga, segunda vuelta | plasma rico (tubería) | plasma (tubería) + bolsa de plaquetas (cinta) | las plaquetas salen al centrifugar el plasma |
| Toma de agua (pared) | — | agua (tubería) | el agua llega de la red |
| Mezcladora (mezclas) | agua + frasco de reactivo | suero (tubería) | se disuelve el reactivo |
| Mezcladora | plasma + agua | medio de cultivo (tubería) | el medio se hace con plasma |
| Estufa de cultivo (genético) | medio + placa vacía (pedido) | placa con colonias | las colonias crecen en la estufa |
| Secuenciador (genético) | placa con colonias | eppendorf de ADN o tubo de ARN | se extrae el material genético |
| Biorreactor (genético) | ADN + medio | caldo de viriones (tubería) | el virus se multiplica en el caldo |
| Envasadora (envasado) | caldo de viriones + suero + viales vacíos (pedido) | caja de vacunas (cinta) | se llenan los viales y se encajan |
| Sintetizador (mezclas) | plasma + ARN | bote de proteína | |
| Incubadora de vectores (genético) | hematíes + ADN | vial de vector | el vector se cultiva en glóbulos rojos |
| Destilador (mezclas) | suero + proteína | neurotoxina (tubería) | |
| Impresora molecular (genético) | proteína + vector | cápsides | |
| Fusionador (cepas) | cápside + neurotoxina + vectores | núcleo zombi | |
| Muelle (almacén) | cajas | dinero, y la cepa se siembra en el destino elegido | |

### Aspecto (Two Point, con el detalle máximo de siempre)
- **Personas:** pack CC0 caricaturesco.
- **Paredes:**
  - gruesas y bajadas, con remate blanco, zócalo de color, franja y parte alta clara;
  - cada tipo de sala, con su color y su acabado por dentro;
  - suelos propios por sala y pasillo de baldosa verde agua.
- **Máquinas:**
  - grandes, redondeadas y exageradas, con una parte enorme que se mueve y cuenta lo que hace, y la persona al lado;
  - siguen con el detalle máximo de la regla 7: tornillos, cables, pantallas vivas y procesos que se ven. El volumen es el de Two Point; el detalle, el nuestro.
- **Luz:** cálida y suave, con AO, en pastel saturado. El gore en rojo saturado como acento.
- **Cámara:** girada 45° respecto a la rejilla, giro en pasos de 90°, inclinación de 52°.

### Interfaz (Two Point)
- **Abajo a la izquierda:** menú redondo Salas · Objetos · Contratar · Info (personal, pacientes, productos).
- **Abajo a la derecha:** dinero, reputación, velocidad y fecha.
- **Arriba a la derecha:** objetivos, correos de LISA y eventos.
- **Fichas:** de sala, persona o máquina, con pestañas y botones de acción abajo.
- **Catálogos:** con miniaturas y precio.
- **Superposiciones:** flujo de cintas, energía y ánimo.
- **Texto:** nada sobre el mundo; las luces de estado van en las máquinas.

### Qué se queda y qué se va
- **Se queda:**
  - el árbol de la cepa y el mundo (regiones, cura, campañas);
  - energía, cápsulas, guardado, sonido y LISA;
  - las recetas como base de datos;
  - los objetos de laboratorio modelados (tubos, viales, bolsas), retocados al estilo nuevo.
- **Se va:**
  - el científico que manejas, la mochila y el WASD;
  - estaciones con «mejora a máquina»: ahora se automatiza con personal y cintas;
  - el tutorial basado en el científico. Se rehace con LISA y salas.
- **Orden:** pantalla objetivo nueva (puerta 3) → núcleo (salas, personal, pacientes, logística, interfaz) → prueba de 15 minutos (puerta 4) → migrar el resto → trozo vertical (puerta 5).

## Contenido y números

14 objetos, 27 construcciones, 24 mutaciones, 12 regiones, 4 niveles de laboratorio, 10 eventos, 15 patentes, 4 sedes. Números iniciales; se equilibran con el bot.

### Objetos y recetas

| Objeto | Forma | Se obtiene en | Receta | Tiempo |
| --- | --- | --- | --- | --- |
| Sangre | tubo rojo, tapón blanco | camilla | — | 1 s a mano / 4 s extractor Mk1 |
| Cultivo | placa de Petri verde | incubadora | — | 1 s a mano / 5 s recolector Mk1 |
| Agua destilada | garrafa transparente | toma de agua | — | 3 s bomba Mk1 |
| Reactivo | frasco azul | pedido | 4 por 14 €, 10 por 30 € | 8–12 s de camión |
| Plasma | tubo amarillo | centrífuga | 1 sangre | 3 s |
| ADN viral | tubo verde brillante | secuenciador | 1 cultivo | 4 s |
| Suero | bolsa de suero | mezcladora | 1 agua + 1 reactivo → 2 | 3 s |
| Proteína vírica | cristal naranja | sintetizador | 2 plasma + 1 ADN | 6 s |
| Vector | cápsula blanca y roja | incubadora de vectores | 1 ADN + 1 suero | 6 s |
| Neurotoxina | ampolla morada | destilador | 2 suero + 1 proteína | 8 s |
| Cápside | esfera geodésica | impresora molecular | 2 proteína + 1 vector | 10 s |
| Núcleo zombi | cubo verde que late | fusionador genético | 1 cápside + 1 neurotoxina + 2 vector | 15 s |
| Vial de mutación | vial con tapón dorado | biorreactor | según mutación | 6–20 s |
| Caja de vacunas | caja blanca con cruz verde | envasadora | 1 ADN + 1 suero | 4 s |

### Construcciones

| Categoría | Construcciones | Nivel |
| --- | --- | --- |
| Extracción | extractor de sangre Mk1–Mk3, brazo recolector Mk1–Mk3, bomba Mk1–Mk2 | 1–4 |
| Procesado | centrífuga, secuenciador, mezcladora, sintetizador, incubadora de vectores, destilador, impresora molecular, fusionador genético | 1–4 |
| Producto | biorreactor, envasadora | 1 |
| Logística | cinta Mk1–Mk3, brazo, brazo con filtro, divisor, fusionador de cintas, almacén pequeño y grande | 1–3 |
| Energía | poste, generador diésel, panel solar, batería, reactor experimental | 1–4 |
| Fijas | cámara de cepa, muelle de envío, muelle de carga y terminal, despacho de Dirección | — |

### Mutaciones

| Rama | N1 (plasma, ADN) | N2 (proteína, suero) | N3 (vector, neurotoxina, cápside) | N4 (núcleo) |
| --- | --- | --- | --- | --- |
| Transmisión | Tos, Estornudos | Agua, Ratas | Mosquitos, Aves | Ganado, Aerosol total |
| Síntomas | Fiebre, Náuseas | Insomnio, Mordisco | Hambre voraz, Rabia | Necrosis, Zombi total |
| Resistencias | Frío, Calor | Humedad, Fármacos I | Fármacos II, Camuflaje | Búnker, Mutación genética |

Receta tipo: N1 = 2 plasma o 2 ADN · N2 = 2 proteína + 1 suero · N3 = 1 vector + 1 neurotoxina + 1 cápside · N4 = 2 núcleos + 1 cápside; cada mutación varía la mezcla.

### Niveles de laboratorio e hitos

| Nivel | Espacio | Hitos | Desbloquea |
| --- | --- | --- | --- |
| 1 Sótano | 16 × 12 | 10 plasma · 5 ADN · primera mutación | cintas, brazo, extractor Mk1, generador diésel |
| 2 Planta | 24 × 16 | 40 plasma · 20 suero · 10 proteína | sintetizador, mezcladora, almacén, cinta Mk2, Mk2 |
| 3 Ala norte | 32 × 24 | 50 proteína · 30 vector · 10 neurotoxina | incubadora de vectores, destilador, impresora, panel solar, brazo con filtro |
| 4 Complejo | 40 × 32 | 30 cápsides · 10 núcleos | fusionador genético, cinta Mk3, Mk3, reactor |

### Mundo
12 regiones: Norteamérica, Sudamérica, Europa occidental, Europa del Este, Norte de África, África subsahariana, Oriente Medio, India, China, Sudeste asiático, Japón y Corea, Oceanía.

Eventos: inspección sanitaria, huelga de transportistas, apagón, filtración a la prensa, subvención, congreso médico, ola de frío, cuarentena global, el CEO en la tele, auditoría interna.

### Meta
- Patentes (15): capital inicial, máquinas más rápidas, bata con bolsillos, burocracia, planos, cinta Mk2 inicial, proveedor preferente, etc.
- Sedes (4): sótano urbano, granja de investigación, base ártica, isla privada.

### Tiempos objetivo

| Momento | Minuto |
| --- | --- |
| Primer vial y virus liberado | 4–6 |
| Primera cadena automatizada | 10–12 |
| Nivel 2 | 15–20 |
| Primeros zombis (Mordisco) | 25–35 |
| Nivel 3 | 35–45 |
| Nivel 4 y mutaciones finales | 50–65 |
| Final | 60–90 |

## Dirección de arte

**3D estilizado y muy detallado, laboratorio blanco y verde corporativo, vista isométrica.** Pantalla objetivo en la puerta 3 comparada con Timberborn, Shapez 2 y Alchemy Factory.

- Cámara: perspectiva de unos 30° de campo, inclinación 50°, giro de 45° (Q/E), zoom de 4 a 40 casillas (4 = zoom de detalle), WASD o arrastrar.
- Escala: casilla = 1 m; becario 0,9; máquinas 1×1, 2×2 o 3×3 y 1–2,5 de alto; productos a 2,5× su tamaño real.
- **Detalle (lo pide Edu, siempre y cuanto más mejor):** al zoom de detalle todo aguanta. Piezas pequeñas (tornillos, juntas, cables, rejillas, pegatinas, etiquetas), pantallas vivas con información, objetos pieza a pieza (vidrio con grosor, líquidos con menisco, tapones moleteados) y procesos animados que se ven: botellas y viales llenándose, tubos entrando y saliendo, rotores, pórticos, burbujas, bombas. Listón mínimo: el lote 1 detallado (centrífuga, secuenciador, biorreactor).
- Paleta: blanco roto y gris claro, metal gris azulado, verde de marca, productos saturados; verde ácido solo para virus y zombis.
- Luz cenital fría, sombras suaves, máquinas que emiten al trabajar, día y noche por las ventanas.
- Materiales: plástico mate, metal satinado, cristal, líquidos brillantes.
- Evitar: texto sobre el mundo, máquinas de cuatro cajas sin detalle, mezclar packs, gore fotorrealista. El gore va estilizado, a juego con el resto.

| Tipo | Vía |
| --- | --- |
| Máquinas, cintas, objetos, mobiliario, arquitectura | Por código: scripts de Blender → glTF |
| Personajes | Pack CC0 (Kenney Mini Characters o Quaternius) recoloreado |
| Iconos | Renderizados desde los modelos 3D |
| Efectos | Partículas y shaders |
| Sonido | Librerías CC0, en `docs/creditos.md` |

Cada lote de 3–6 piezas se enseña a Edu con la cámara del juego antes de montarlo.

## Interfaz y controles

**Nada de texto sobre el mundo.**

- Barra superior: dinero, energía, mini mapa con % zombis, cura, fecha.
- Barra de construcción inferior por categorías con huecos 1–9 e iconos; ficha al pasar el ratón.
- Panel de máquina a la derecha: entradas y salidas en iconos, progreso, ritmo por minuto, consumo, selector de receta.
- Inventario en hotbar abajo a la izquierda; objetivo actual arriba a la izquierda; teletipo de noticias.
- En el mundo: luz de estado y, si hay problema, icono (rayo, caja tachada, interrogación, flecha vacía); flechas en el suelo; fantasma verde/rojo con zonas de energía; monitor del mundo y pizarra de hitos como objetos del escenario.
- Pantallas completas: Cepa, Mundo, Hitos, Producción, Correo.

| Acción | Ratón y teclado | Mando | Táctil |
| --- | --- | --- | --- |
| Mover | WASD o clic en el suelo | stick izq. | tocar el suelo |
| Cámara | rueda, Q/E, botón central | stick der., gatillos | pellizcar, dos dedos |
| Usar | E o clic | A | tocar |
| Construir | 1–9, B, clic, arrastrar cintas, R | Y, A, LB/RB | botón construir |
| Quitar | X o clic der. mantenido | B mantenido | modo quitar |
| Pantallas | Tab, M, H, P | menú radial | botones |
| Pausa | Esc o espacio | Start | botón |

## Tono, textos e idiomas

**Comedia negra que se toma en serio:** la empresa nunca dice «zombi», habla de «fase», «activo» y «objetivo trimestral», y lo terrible se cuenta con la calma de un informe de calidad.

**Historia:** Patógena S.A. ejecuta el «Proyecto Reinicio»: sustituir a la humanidad por una población dócil y controlable. El jugador es un investigador recién contratado en un laboratorio subterráneo; al principio solo recibe objetivos técnicos y los correos, informes y noticias revelan poco a poco qué está construyendo. Las vacunas financian la operación y mantienen la imagen pública; nunca se aclara qué contienen. El final no celebra la victoria: el mundo queda en silencio y Dirección archiva el informe.

- Correos de Dirección (2–4 líneas, lenguaje corporativo neutro): «La fase 2 avanza según lo previsto. Recordamos que la cafetería de la planta 3 queda clausurada hasta nuevo aviso por motivos ajenos a la fase 2».
- Informes y registros desbloqueables con los hitos.
- Noticias sobrias región a región.
- Música ambiental tensa, laboratorio silencioso, sirenas lejanas que crecen.
- Nombres técnicos de catálogo; mutaciones con nombre clínico.
- Castellano fuente + inglés desde la primera versión, todo por la tabla de traducción.

## Tecnología

**Godot 4, GDScript.**

- Simulación a 20 pasos/s con datos puros, separada del dibujo; el bot juega partidas enteras sin pantalla a ×50.
- Datos (objetos, máquinas, recetas, mutaciones, regiones, hitos, eventos) en archivos de `datos/`.
- Objetos de cintas con MultiMesh; 60 fps en PC medio, 30 fps en navegador móvil con nivel 3.
- Forward+ en PC; Compatibility en web y móvil.
- Autoguardado cada 2 min; meta aparte.
- Logros con API names de Steam desde el inicio.
- Pruebas: bot de partida completa, entrada real de ratón y táctil, capturas de pantallas en ES/EN.

## Fases, puertas y tareas

| Fase | Tareas | Hecho cuando |
| --- | --- | --- |
| 2 · Diseño | documento, nombre, repo, `CLAUDE.md`, clon en D:, hoja de ruta, referencias | Edu aprueba (hecho 8-nov-2026) |
| 3 · Pantalla objetivo | cámara y luz, 6 máquinas modeladas, cintas, becario, HUD | captura al lado de las referencias sin desentonar |
| 4 · Mecánica principal | cuadrícula, construir/quitar, cintas con objetos, brazos, extracción, recetas, biorreactor y cepa, bot | Edu juega 15 min sin explicaciones y quiere más |
| 5 · Trozo vertical | nivel 1 con arte final, sonido, tutorial en hitos, guardado, ES/EN | 20 primeros minutos pasan la barra de calidad |
| 6 · Sistemas | pandemia y cura, energía, niveles 2–4, pantallas, eventos, patentes, sedes | cada sistema aprobado; partida completa en el bot |
| 7 · Publicar | builds Windows y web, itch.io, logros, Steamworks | partida completa en Windows y navegador móvil |

## Reglas de decisión

**Claude decide sin preguntar:** equilibrado, recetas concretas, distribución inicial, nombres de máquinas y objetos, textos de correos y noticias, orden de tareas en una fase, arreglos. Todo en `docs/decisiones.md`.

**Decide Edu:** nombre, cada puerta, cambios de estilo o cámara, añadir o quitar mecánicas, precio y plataformas, gastos.

**Ante una duda:** gana lo que haga la fábrica más legible y la decisión del jugador más clara; si empatan, lo más simple.
