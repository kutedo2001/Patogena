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
