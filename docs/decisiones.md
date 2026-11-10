# Decisiones

| Fecha | Decisión | Por qué |
| --- | --- | --- |
| 2026-11-08 | Se elige el concepto de fábrica de laboratorio (antes «Farmacorp») frente a Nido y La Granja, que quedan aparcados | Elección de Edu tras jugar los prototipos |
| 2026-11-08 | Nombre: Patógena S.A. | «Farmacorp» es una cadena real de farmacias de Bolivia |
| 2026-11-08 | Vista isométrica 3D low-poly; referencias Satisfactory, Factorio, Shapez 2, Timberborn, Alchemy Factory, Dyson Sphere Program, Palworld, Plague Inc, Can 'Em All | Concepto aprobado por Edu |
| 2026-11-08 | Las mutaciones se fabrican como productos (no se compran con puntos) | Pilar del diseño |
| 2026-11-08 | Partida roguelite por pandemia; patentes como meta entre partidas | Elección de Edu |
| 2026-11-08 | Vacunas: solo fuente de dinero, no afectan a la pandemia; posible ampliación a otros fármacos | Decisión de Edu |
| 2026-11-08 | Tono: comedia negra seria, con gore estilizado en low-poly | Decisión de Edu |
| 2026-11-08 | Motor: Godot 4 con GDScript; los prototipos en three.js quedan solo como referencia | Método del estudio: Windows, Steam y web |
| 2026-11-08 | Interfaz sin texto flotando en el mundo: luces e iconos de estado en las máquinas, el resto en paneles del HUD | Petición de Edu |
| 2026-11-08 | Puerta 2 aprobada | Edu: «hecho» tras revisar el documento de diseño |
| 2026-11-08 | Godot 4.3 estable (no 4.4+) | Es la versión de MOVECORP que Edu tiene instalada; el proyecto abre igual en versiones posteriores |
| 2026-11-08 | Web sin hilos (web_nothreads) | Funciona en itch.io y móviles sin cabeceras COOP/COEP |
| 2026-11-08 | Capturas automáticas con el autoload Captura (`-- --captura=ruta.png`) | Para comparar cada vuelta contra las referencias sin abrir el editor |
| 2026-11-08 | Casilla = 1 m; sala de 24 × 16 casillas, paredes de 3,2 m con zócalo verde clínico y ventanas cada 4 casillas | Proporción con el becario (0,9) y las máquinas (1,2 de alto) |
| 2026-11-08 | Las dos paredes que dan a la cámara se esconden al girar | Como Timberborn / Two Point: nunca tapan la fábrica |
| 2026-11-08 | Fondo oscuro fuera de la sala (sin exterior por ahora) | Como Shapez 2: la fábrica resalta; el exterior se valorará en la pantalla objetivo |
| 2026-11-08 | Cámara: giro en pasos de 45° y zoom de 12 a 40 casillas (el diseño decía 90° y 6–30) | Aprobado por Edu en P3.3; 6 casillas era demasiado cerca para la densidad de Shapez 2 |
| 2026-11-08 | Máquinas por script de Blender 4.2 (tools/blender/) → glTF; piezas animadas con nombre fijo (rotor, cabezal, agitador, líquido, pantalla, baliza) que anima scripts/maquina.gd | Animación por código: un solo script sirve para todas las máquinas y sigue el estado de la simulación |
| 2026-11-08 | Color por familia: procesado = azul cian, producto = verde de marca (resto al llegar a sus lotes); chasis crema y zócalo grafito en todas | Como Shapez 2: se lee la familia de un vistazo |
| 2026-11-08 | Entrada por la izquierda (-X) y salida por la derecha (+X), con chevron amarillo en el zócalo | Sentido del flujo legible sin texto |
| 2026-11-08 | Zoom máximo de detalle: 4 casillas de ancho (antes 12) | Edu quiere ver el detalle al acercarse |
| 2026-11-08 | Los productos se dibujan a 2,5× su tamaño real (un tubo mide 0,33 m en el juego) | A tamaño real no se leían ni con el zoom máximo; como en Can 'Em All, el producto manda |
| 2026-11-08 | Vidrio y plásticos translúcidos con material propio en Godot (scripts/materiales.gd): albedo oscuro, una cara, sin sombra | El vidrio importado blanqueaba la sangre y los líquidos |
| 2026-11-08 | Etiquetas sin palabras: código de barras, franja de color del producto, riesgo biológico y logotipo «P» | Regla de no texto en el mundo y lectura internacional |
| 2026-11-08 | Pantallas de máquina vivas (SubViewport) dibujadas con _draw(): números con unidades, iconos y gráficas, sin palabras | Petición de Edu (pantallas con información) sin romper la regla de no texto en el mundo |
| 2026-11-08 | Torre de luces de 3 colores en las máquinas detalladas (sustituye a la baliza única) | Más legible y más de laboratorio/industria; el estado se lee por posición y color |
| 2026-11-08 | Centrífuga con rotor de ángulo fijo (no basculante) | Los tubos a escala de juego no caben basculando en una cuba de 1 casilla |
| 2026-11-09 | Paso a Godot 4.7 estable (antes 4.3) | Edu tiene la 4.7 y su editor ya había convertido el proyecto; trabajar con la misma versión evita conflictos |
| 2026-11-09 | Nivel de detalle mínimo = el del lote 1 detallado (P3.4c–e), y a ser posible más: procesos animados visibles (botellas llenándose…), piezas pequeñas, pantallas vivas | Edu aprueba el lote 1 y pide «siempre este detalle o más» |
| 2026-11-09 | Edu autoriza hacer todo lo visual hasta P3.6 sin preguntar, con este estilo y estas normas (detalle máximo); se le enseña al final | Agilizar: ya ha validado el nivel con los lotes 1 y 2 |
| 2026-11-09 | Personajes: Kenney Mini Characters 2.0 (CC0) con animaciones de serie, recoloreados por paleta; escala 0,62 (0,9 casillas) | Regla 5: nunca personas por código; mismo estilo amable que contrasta con el gore |
| 2026-11-09 | Gore de personajes como efecto encima del cuerpo del pack: amputar = escalar el hueso a 0, muñón y gotas con mallas simples, poses de zombi por hueso sobre la animación | Cumple la regla 5 (el cuerpo sigue siendo el modelo CC0) y permite cualquier combinación de amputaciones sin modelos nuevos |
| 2026-11-09 | Curvas de cinta con textura propia (nervios radiales, chevron estrecho) | El chevron ancho se abría en abanico y parecían arañazos |
| 2026-11-09 | HUD construido por código (hud.gd) con fuente Inter (OFL), iconos vectoriales propios e iconos 3D renderizados desde los modelos sobre el color de la casilla | Iconos coherentes con el mundo; con fondo transparente el vidrio desaparecía |
| 2026-11-09 | Idioma por defecto castellano hasta que haya menú de opciones; en móvil la interfaz se escala ×1,3 | La pantalla del móvil es pequeña aunque tenga muchos píxeles |
| 2026-11-09 | Marcas de interfaz en el mundo sin texto: anillo de selección pulsante y fantasma verde translúcido con su huella | Regla 6 |
| 2026-11-09 | HUD v2: paneles como piezas del laboratorio (carcasa blanca biselada con tornillos, franja azul de proceso, pantallas iguales que las de las máquinas, bandejas hundidas, pulsadores físicos, franja de peligro) | Edu: el HUD oscuro genérico no tenía el estilo del juego |
| 2026-11-09 | El mapa del mundo pasa a un monitor grande en la pared del fondo (sin ventanas en ese tramo) y sale de la barra superior | Propuesta de Edu: se lee mucho mejor y es parte del laboratorio |
| 2026-11-09 | Rejilla única: casillas de 1 m [n, n+1]; máquinas 2×2 centradas en enteros, 1×1 y 3×3 en n+0,5; cintas corregidas (+0,5) | Las cintas iban media casilla desplazadas respecto al suelo y a las máquinas |
| 2026-11-09 | Pantalla objetivo: laboratorio nivel 2 con dos cadenas reales (cepa al norte, vacunas al sur), corral de pruebas vallado bajo el monitor del mundo y palé de envío | Que la captura sea una fábrica que funciona, no un escaparate |
| 2026-11-09 | Sangre más viva (#B01E20) para entrar en el rango de la guía | Rasgo 10 de las referencias |
| 2026-11-09 | Puerta 3 cerrada: Edu responde «sigue» a la pantalla objetivo (lámina p39_objetivo.jpg) | Aprobado de la puerta 3; se pasa a la fase 4 |
| 2026-11-09 | Simulación separada del dibujo (scripts/sim/fabrica.gd) con datos en datos/fabrica.json, a 20 pasos/s; el bot la juega a ×600 | Diseño: datos puros, bot sin pantalla |
| 2026-11-09 | Cintas Mk1–Mk3 a 0,5 / 1 / 2 casillas/s con separación 0,5 = 60 / 120 / 240 objetos/min; carga lateral a mitad de casilla | Ritmos del documento de diseño |
| 2026-11-09 | Máquinas: entran por toda la cara −X local y sacan por la +X en su fila de salida; tolva de hasta 4 recetas por ingrediente; si la salida se llena, se paran en ámbar sin perder nada | Reglas simples y legibles; casan con las bocas de los modelos |
| 2026-11-09 | Una cinta por ingrediente en los diseños de muestra (el reactivo y el suero entran por la otra casilla de la cara) | Mezclar ingredientes en una cinta puede atascar la máquina, como en Factorio; queda como reto del jugador |
| 2026-11-09 | Fuentes provisionales hasta los extractores de P4.3 | Permiten probar las cadenas ya |
| 2026-11-09 | Puerta 4 sin personaje controlable: se juega con el ratón (mantener clic en un nodo para extraer; clic en una máquina para echar lo del inventario y recoger lo hecho) | Lo más rápido de probar; el becario caminando del diseño queda para después si Edu lo pide (decisión suya) |
| 2026-11-09 | Nivel 1 de prueba: sótano 16 × 12 con 2 donantes, incubadora, toma de agua, terminal de pedidos, muelle de carga, muelle de envío y cámara de cepa fijos; 2 000 € iniciales | Mínimo para jugar el bucle completo |
| 2026-11-09 | Costes iniciales: centrífuga 300, secuenciador 500, mezcladora 400, biorreactor 800, envasadora 600, extractores 150–200, cinta 5, brazo 50, divisor 40, almacén 80; caja de vacunas 30 €; 4 reactivos 14 € | Que la primera mutación sea alcanzable sin vender; se equilibra tras la prueba de Edu |
| 2026-11-09 | Seis mutaciones de nivel 1 en el biorreactor: tos y estornudos (2 plasma), fiebre y náuseas (2 ADN), frío y calor (plasma + ADN); un vial repetido se desecha | Diseño (N1) y para que no se atasque la línea |
| 2026-11-09 | Brazo, divisor, almacén, extractores, muelles y nodos con piezas provisionales sencillas | La puerta 4 se prueba en gris; se modelan con detalle en la puerta 5 |
| 2026-11-09 | Consejo del momento en el panel de objetivo | Hecho cuando de P4.3: que se juegue sin explicaciones |
| 2026-11-09 | Cámara: el arrastre pasa al botón central; el derecho cancela o quita | El derecho se usaba para las dos cosas |
| 2026-11-09 | La pantalla objetivo se conserva como «escaparate» (`-- --escaparate`) con su HUD de datos de muestra | Referencia visual de la puerta 3 |
| 2026-11-09 | Nuevo inicio decidido por Edu: científico controlable (WASD y clic), estaciones de extracción construibles con pacientes que llegan y se van, progresión a mano → científico con máquina → zombi con máquina, sin inventario, máquinas siempre automáticas, bocas visibles, devolución completa, venta clara y tutorial con historia | Primera prueba de Edu: se bloqueó al empezar (P4.5) |
| 2026-11-09 | Dinero inicial 1.000 € = camilla + centrífuga + biorreactor justos con la ayuda de 300 € del correo; hitos pagan 500/400/1.000 € | Que la primera mutación nunca quede bloqueada por dinero |
| 2026-11-09 | La cámara sigue al científico; WASD mueve al científico y las flechas o el botón central mueven la cámara | WASD es del científico (elección de Edu) |
| 2026-11-09 | Tras liberar el virus llega un zombi trabajador cada 40 s (máx. 6 esperando); un zombi solo puede operar una estación ya mejorada con máquina | Progresión pedida por Edu: yo → yo con máquina → zombi con máquina |
| 2026-11-09 | El muelle compra vacunas (30 €), ADN (8 €) y plasma (5 €) | Siempre hay forma de conseguir dinero |
| 2026-11-09 | Clic en una máquina solo abre su panel; las cosas se llevan arrastrando desde las manos o desde la salida de una máquina (el científico va andando); estaciones con botón de trabajar | Edu: el clic que dejaba y cogía todo a la vez liaba mucho |
| 2026-11-09 | Ficha junto al puntero con qué es, qué hace y su estado (panel del HUD, no texto en el mundo) | Pedido por Edu |
| 2026-11-09 | Apuntado para la puerta 5: extracción animada vistosa, partes de máquina con sentido y cintas que entren y salgan por sus bocas como Alchemy Factory | Pedido por Edu; se pule al final |
| 2026-11-09 | Diseño de la 1.0 (ver diseno.md): el jugador es la empresa; guía la IA LISA; objetos al estilo Factorio sin ventanas; hub que vende vacunas con la mutación y propaga el virus; ascensor de pedidos que desbloquea máquinas; parcelas 8×8; alcance completo hasta la granja de humanos; partida de 8 h o más | Respuestas de Edu |
| 2026-11-09 | Edu pide modo autónomo hasta la 1.0 con lo decidido; se le enseña en cada versión jugable | Petición de Edu |
| 2026-11-09 | Fuera el ascensor de pedidos y la cámara de cepa de un solo uso. Entra la **sala de cepas**: una sala con su máquina (mesa de ingeniería genética) y un árbol de mejoras tipo Plague Inc (transmisión, síntomas, resistencias); eliges la mejora, te pide un lote de productos, al entregarlo se aplica a la cepa (afecta a la población) y desbloquea máquinas | Edu: el ascensor no tenía sentido y la cepa estaba mal pensada |
| 2026-11-09 | Las máquinas fabrican sin parar la receta elegida (como los ensambladores de Satisfactory); el biorreactor deja de hacer una mutación y ya; más profundidad: cada materia prima da varios productos intermedios en máquinas distintas (sangre → plasma, hematíes, plaquetas…) que se combinan entre sí | Edu: faltaba profundidad, como hierro → placas, barras, tornillos |
| 2026-11-09 | Las vacunas propagan la cepa actual (con todas sus mejoras), no una mutación por caja | Consecuencia de la sala de cepas |
| 2026-11-10 | Equilibrado del mundo con tools/balance_mundo.py: partida normal ~7,5 h con la cura al ~78 %; un jugador lento pierde, uno rápido gana en ~6 h | Duración objetivo de 8 h y la cura como amenaza real |
| 2026-11-10 | Zoom máximo más cerca (2,5 casillas) para que se vea la extracción y el detalle de las piezas | Petición de Edu de una animación de extracción vistosa |
| 2026-11-10 | Sonido sintetizado por código (tools/sonidos.py) en vez de muestras de terceros | Sin licencias que gestionar; se puede rehacer a gusto |
| 2026-11-10 | Rediseño: **Two Point Hospital** para todo el hub (aspecto de máquinas, construcción de salas, resto del aspecto e interfaz) y **Alchemy Factory** para la automatización; Factorio para lo que AF no resuelva | Edu (10-nov): «cada cosa y cada pieza ha de tener sentido» |
| 2026-11-10 | **Vista de director**: fuera el científico que maneja el jugador; se contrata personal (científicos, becarios, conserjes, luego zombis) que trabaja a mano hasta automatizar | Elección de Edu; así es Two Point |
| 2026-11-10 | **Todo mezclado**: máquinas y cintas dentro de salas Two Point; las cintas cruzan pasillos y paredes por pasamuros | Elección de Edu |
| 2026-11-10 | Personajes: pack CC0 más caricaturesco que Kenney, elegido por Edu en una lámina | Two Point usa personajes exagerados; las personas nunca por código |
| 2026-11-10 | La pantalla objetivo del 9-nov deja de valer: se vuelve a la puerta 3. V1.11, V1.12 y V1.17–V1.19 quedan sustituidas por el rediseño R | El estilo de máquinas, salas e interfaz cambia entero |
| 2026-11-10 | Propuesta de sentido para la logística (se cierra en R0.3): tubos de sangre por cinta hasta la centrífuga; lo que sale es líquido y va por tubería; lo envasado vuelve a la cinta | Sólidos por cinta y líquidos por tubería, como Alchemy Factory |
