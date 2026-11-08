# Referencias

Lámina: `lamina_referencias.jpg` · capturas a 1280 px en `capturas/` (fuente: páginas de Steam; solo para estudio interno, no se publican).

## Conclusión en una frase
**Cámara y legibilidad de Shapez 2, paleta clínica y gore de Can 'Em All, máquinas con volumen industrial de Satisfactory a escala de juguete serio, y balizas de estado de Timberborn.**

## Análisis por referencia

| Referencia | Cámara y encuadre | Luz y paleta | Materiales y proporciones | Interfaz y feedback | Qué tomamos |
| --- | --- | --- | --- | --- | --- |
| **Shapez 2** (`shapez2_02`, `shapez2_03`) | Perspectiva baja de FOV, inclinación ~40–55°, giro libre; la casilla es la unidad visual | Fondo oscuro desaturado; las máquinas son lo único saturado | Volúmenes gruesos, biselados, sin texturas finas; cada familia de máquina tiene su color (crema, magenta, cian, amarillo) | Barra de construcción abajo al centro con números 1-7; metas arriba a la izquierda con icono + contador; cuadro naranja brillante encima = trabajando | Color por familia, luz encima de cada máquina, barra numerada, centro limpio |
| **Can 'Em All** (`canemall_03`, `canemall_04`) | Primera persona (no se toma) | Luz clara y uniforme; paredes verde agua, suelo crema, máquinas blancas con naranja | Máquinas redondeadas tipo electrodoméstico industrial; tubos de cristal con producto dentro | HUD en las cuatro esquinas, paneles con borde grueso crema sobre azul noche; «+$100» al vender | Paleta clínica, gore rojo saturado sobre suelo limpio, producto visible dentro de tubos |
| **Timberborn** (`timberborn_06`) | Isométrica en perspectiva, inclinación ~55°, mucha densidad | Luz cálida de día, sombras suaves y AO marcado | Edificios de madera y metal con detalle medio; personajes diminutos | Balizas luminosas sobre los edificios para indicar estado | Balizas de estado legibles desde lejos, AO, densidad |
| **Satisfactory** (`satisfactory_09`) | Primera persona (no se toma) | Interiores con luz industrial dura | Máquinas con chasis amarillo, rejillas, puertas, tornillería: se leen como máquinas | Hologramas de construcción | Lenguaje de máquina real: chasis, bocas de entrada/salida, paneles, tuberías |
| **Dyson Sphere Program** (`dsp_07`) | Tercera persona orbital | Fría, emisivos azules | Edificios de ciencia ficción | Panel de máquina flotante en HUD con iconos grandes, barra de construcción abajo, minimapa en esquina | Ficha de máquina en panel de HUD, con iconos de entrada y salida |
| **Alchemy Factory** (`alchemy_07`) | Primera persona baja | Estilizada cálida | Mesas de trabajo con los objetos encima | Iconos redondos de producto | Objetos fabricados visibles encima de las máquinas |
| **Factorio** (`factorio_03`) | Cenital | Sucia, terrosa | Densidad máxima | Colores de cintas y tuberías por contenido | La logística se entiende por color de la línea |
| **Palworld** | Tercera persona | Brillante | Criaturas trabajando en estaciones | — | Los becarios trabajan solos en estaciones (personajes CC0, nunca por código) |

## 10 rasgos medibles (contra ellos se compara la pantalla objetivo)
1. **Cámara**: perspectiva con FOV 30°, inclinación 50°, giro en pasos de 45°; zoom entre 12 y 40 casillas de ancho visibles.
2. **Densidad**: a zoom medio caben unas 20 × 12 casillas (Shapez 2 enseña ~18 de ancho).
3. **Tamaño en pantalla**: una máquina de 1 × 1 ocupa el 5–7 % del ancho a zoom medio; la más grande (3 × 3), como máximo el 18 %.
4. **Proporción**: el becario mide 0,9 casillas de alto; una máquina pequeña, 1 × 1 × 1,2.
5. **Color por familia**: cada familia de máquina tiene un acento propio sobre chasis neutro (crema y gris grafito); el laboratorio usa 3 neutros + verde de marca.
6. **Estado**: baliza emisiva encima de cada máquina (verde = trabaja, ámbar = falta algo, rojo = averiada), visible con al menos 6 px al zoom mínimo.
7. **Producto visible**: lo que fabrica una máquina se ve en ella (tubo, bandeja o ventana) y sobre la cinta; cada producto se distingue por silueta en un icono de 24 px.
8. **HUD**: barra superior ≤ 7 % del alto, barra de construcción abajo al centro ≤ 13 %, columna de metas a la izquierda ≤ 15 % del ancho; el 60 % central queda libre. Ningún texto sobre el mundo.
9. **Luz**: clara y uniforme de laboratorio, sombras suaves, AO visible en las uniones; contraste medio. Debe verse igual en PC y en web.
10. **Gore**: rojo saturado (#9E1B1B–#C42626) sobre suelos limpios, en manchas y trozos estilizados; nunca realista ni marrón.
