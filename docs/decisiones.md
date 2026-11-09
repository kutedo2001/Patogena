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
