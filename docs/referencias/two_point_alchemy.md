# Referencias del rediseño: Two Point Hospital + Alchemy Factory (10-nov-2026)

Lámina: `lamina_two_point_alchemy.jpg`. Capturas a 1280 px en `capturas/` (`tph_*`, `tpm_*`, `alchemy_*`). Fuente: páginas de Steam. Solo para estudio interno: no se publican.

Encargo de Edu: **Two Point Hospital** para todo el hub (cómo se ven las máquinas, la construcción y todo lo demás) y **Alchemy Factory** para la automatización. Lo que Alchemy Factory no resuelva se toma de **Factorio**. Cada cosa y cada pieza ha de tener sentido.

## Two Point Hospital: qué se toma

### Cámara y encuadre
- Perspectiva con FOV moderado, mirando hacia abajo a unos 50–55°.
- Las paredes van en diagonal: la cámara está girada 45° respecto a la rejilla y gira en pasos de 90°.
- Con el zoom cercano, una sala de 4×5 ocupa media pantalla (`tph_03`). Con el lejano se ve el hospital entero y la calle (`tph_04`).

### Salas
- El jugador arrastra el plano. Las paredes salen solas, con la puerta y las ventanas como módulos de pared.
- Cada sala tiene un tamaño mínimo y unos objetos obligatorios (estrella amarilla). Los demás son opcionales y suben el prestigio.
- Fuera de las salas todo es pasillo, con sus propios objetos: recepción, bancos, máquinas de bebidas, plantas, papeleras, radiadores y extintores (`tph_06`).

### Paredes
- Gruesas (0,15–0,2 casillas), con remate blanco plano arriba. Se ven bajadas, a la altura del pecho de una persona, para poder mirar dentro.
- Dos tonos: zócalo saturado (morado, azul o naranja), franja fina de contraste (amarilla) y parte alta clara.
- Por dentro, cada tipo de sala tiene su acabado: madera, papel pintado o azulejo (`tph_09`).

### Suelos
- El pasillo es de baldosa verde agua pálida. Cada sala tiene su suelo: damero, madera, moqueta o goma de puntos.
- El cambio de suelo marca dónde empieza la sala.

### Máquinas
- Grandes (2×3 o más), redondeadas, con biseles gordos y colores planos con poco degradado.
- Tienen partes enormes que se mueven y que se entienden sin explicación. El paciente va dentro o encima y la máquina le hace algo visible; por ejemplo, el anillo que da vueltas en `tph_03`.
- El empleado está siempre al lado, con su consola o sus mandos.
- Hay una luz de estado con un botón verde o rojo en el chasis, y ningún texto sobre el mundo.

### Personas
- Caricaturas: cabeza grande (cerca de 1/5 del cuerpo), manos grandes y poses exageradas.
- Se distinguen por el uniforme y el color: bata blanca para el médico, ropa de calle para el paciente.
- Siempre se ve qué está haciendo cada uno: esperar sentado, andar, trabajar o mearse encima.

### Luz y paleta
- Luz cálida y suave, sombras suaves y AO marcado. Algunas luces locales: la chimenea, la luz de un letrero.
- Pastel saturado: verde agua, morado, azul y naranja. El rojo y el amarillo solo como acento.

### Interfaz
- **Abajo a la izquierda:** el menú principal redondo, con los botones grandes Salas · Objetos · Contratar y una pestaña de información (personal, pacientes, enfermedades).
- **Abajo a la derecha:** dinero (al pasar el ratón, ingresos y gastos), reputación, nivel, velocidad del juego y fecha.
- **Arriba a la derecha:** objetivos, eventos y peticiones.
- **Ficha (inspector):** cabecera con foto o icono y flechas para pasar a la siguiente, pestañas (datos, cola, info) y botones de acción abajo (editar, vender, prioridad, coger).
- **Catálogos:** pestañas por categoría y tarjetas grandes con miniatura, precio y tamaño mínimo.
- **Superposiciones:** atractivo, temperatura, higiene…
- **Aspecto:** paneles redondeados y gruesos, colores claros (blanco, verde agua) con acento naranja, iconos dibujados y letra redonda grande.

## Alchemy Factory: qué se toma

### Cinta
- Ancha: ocupa unas 0,8 casillas.
- Va levantada sobre patas o caballetes, de madera con lamas, con raíles laterales de metal y rodillos y engranajes en los extremos.
- Hay tramos inclinados para subir de nivel (`alchemy_07`, `alchemy_11`).

### Objetos en la cinta
- Grandes: 0,4–0,5 casillas.
- Pegados en fila, casi tocándose. Se leen desde lejos por silueta y color (`alchemy_12`).

### Bocas
- Cada máquina tiene sus entradas y salidas fijas (Advanced Shaper: 5 entradas; Alembic: 1).
- La cinta acaba en la cara de la máquina y el objeto entra por una ranura o una tolva.
- La salida pone el objeto en una cinta propia de una casilla. Tocar la máquina con la cinta por cualquier lado no vale.

### Existencias a la vista
- Lo que espera para entrar se ve amontonado encima o en la tolva: las piedras sobre los molinos de `alchemy_07`.

### Divisores y unificadores
- Se crean solos al cruzar una cinta con otra.
- Más adelante hay versiones con prioridad y con filtro.

### Cajas de almacén
- Cubos de 1×1 con entrada y salida (las grandes tienen 2 y 2).
- Hacen de colchón entre máquinas y de punto de reparto.

### Elevador de cinta
- Columna de 1×1 que sube o baja la cinta; la entrada y la salida se giran por separado.

### Velocidades que cuadran
- La cinta empieza en 60 objetos/min y sube con mejoras hasta 240.
- Cada máquina está ajustada para que una cinta de su mismo nivel la alimente justo, y la proporción entre máquinas importa: una sierra alimenta a tres procesadoras.
- El juego no avisa: se nota en que una máquina se queda vacía o en que se amontona material.

### Tuberías
- Para líquidos y gases, sin dirección, con puertos fijos por máquina.

### Interfaz de Alchemy Factory
- Arriba, barra de recursos con marcos de pergamino. Abajo al centro, barra rápida del 1 al 0. Abajo a la derecha, 8 botones redondos.
- No se toma: la interfaz es la de Two Point.

## Factorio: lo que Alchemy Factory no resuelve
- **Cruzar un pasillo sin cortarlo:** cinta subterránea (entrada y salida separadas hasta 4 casillas). Aquí será el **paso bajo suelo**: la cinta se mete por una trampilla y sale al otro lado del pasillo, y la gente pasa por encima.
- **Cruzar una pared:** el **pasamuros**, una ventanilla con cortina de lamas en la pared. Es una pieza de pared, como la puerta.
- **Leer de un vistazo qué lleva cada línea:** el color de la tubería según su contenido (rojo sangre, ámbar plasma, verde suero…).

## 10 rasgos medibles del rediseño (contra ellos se compara la pantalla objetivo nueva)
1. **Cámara:** perspectiva con FOV 30–35°, inclinación 52°, giro de 45° respecto a la rejilla en pasos de 90°. Con el zoom cercano, una sala de 4×5 ocupa media pantalla.
2. **Paredes:** grosor 0,18 casillas; altura visible 0,55 m (bajadas) con remate blanco; zócalo saturado de 0,25 m, franja de 0,04 m y parte alta clara. Puerta y ventana son módulos de pared.
3. **Suelos:** baldosa verde agua en el pasillo y suelo propio en cada tipo de sala.
4. **Máquinas:** entre 2×2 y 3×3, biseles visibles a cualquier zoom, colores planos, al menos una parte grande que se mueve y explica lo que hace, y el empleado al lado.
5. **Personas:** cabeza de 1/5 del cuerpo o más; altura de 0,8 casillas; se entiende qué hacen solo por la pose.
6. **Cinta:** ancho de 0,8 casillas, a 0,45 m del suelo sobre patas, con raíles y rodillos en los extremos.
7. **Objetos en la cinta:** de 0,4 casillas, separados 0,5 casillas, distinguibles por silueta y color a zoom medio.
8. **Bocas:** cada máquina tiene entradas y salidas fijas y marcadas (tolva, ranura o bandeja), y lo que espera se ve amontonado. Una cinta solo conecta por una boca.
9. **Interfaz:** menú redondo abajo a la izquierda, dinero y velocidad abajo a la derecha, objetivos arriba a la derecha, fichas con pestañas y botones abajo. Ningún texto sobre el mundo. El centro de la pantalla queda libre.
10. **Luz y paleta:** luz cálida y suave con AO; pastel saturado (verde agua, morado, azul, naranja); el gore en rojo saturado como acento de comedia negra.
