# Fallos

Formato: síntoma · causa · arreglo · comprobación · cómo evitarlo.

## B1 · Web (Compatibility) se ve quemada en blanco — resuelto (P3.3)
- Síntoma: la exportación web arranca, pero el suelo y el cielo salen casi blancos y el título del HUD no se lee; en PC (Forward+) se ve bien.
- Causa probable: luz ambiental del cielo procedural y tonemap pensados para Forward+; Compatibility trabaja en otro espacio de color y no tiene SSAO.
- Arreglo: en P3.3, iluminación ajustada y comprobada en los dos renderizadores (captura Forward+ y captura web en cada vuelta).
- Causa real: Godot 4.3 en Compatibility no pasa a lineal el color de fondo ni el del ambiente, no tiene SSAO y satura antes la luz directa.
- Arreglo: `principal.gd::_igualar_renderizadores()` detecta Compatibility (sin RenderingDevice) y corrige fondo, ambiente y sol con valores medidos píxel a píxel.
- Comprobación: misma escena en PC y en Chrome: suelo 203 vs 211, sombra 145 vs 135, fondo 24 vs 22 (diferencias ≤ 5 %).
- Cómo evitarlo: toda captura de luz se hace por partida doble (PC y web); si se toca la luz, se vuelven a medir esos cuatro puntos.
- 2026-11-09, Godot 4.7: Compatibility ya convierte bien fondo y ambiente; ahora solo sale un 14 % más claro. Arreglo nuevo: `adjustment_brightness = 0.88` en Compatibility (brillo medio 175,5 frente a 175,4 en Forward+).

## B2 · En web (Compatibility) no se ve la sangre del suelo — resuelto (P3.8)
- **Síntoma:** charcos, salpicaduras y rastros de sangre invisibles con el renderizador Compatibility.
- **Causa:** los `Decal` no se dibujan en Compatibility.
- **Arreglo:** `Mancha.crear()` usa Decal en Forward+ y un plano transparente pegado al suelo en Compatibility.
- **Comprobación:** captura compat de la horda con charcos y rastros visibles.
- **Cómo evitarlo:** todo efecto nuevo se captura también en compat antes de cerrarlo.

## B3 · Clics que no llegan al mundo en mitad de la pantalla — resuelto (P4.2)
- **Síntoma:** a veces un clic en el suelo no construía, no quitaba o no cancelaba.
- **Causa:** al rehacer la barra de construcción, los nodos viejos seguían dentro hasta el fotograma siguiente; el contenedor crecía hacia arriba y, como los contenedores de maquetación atrapan el ratón, tapaba el centro de la pantalla.
- **Arreglo:** los hijos se sacan al momento al rehacer un panel y los contenedores de maquetación ignoran el ratón (solo las carcasas lo paran).
- **Comprobación:** prueba con ratón real (tools: `-- --prueba_raton`), 16/16.
- **Cómo evitarlo:** todo panel nuevo del HUD se prueba con la prueba de ratón.

## B4 · Cámara de cepa atascada con un vial repetido — resuelto (P4.4)
- **Síntoma:** al cambiar de mutación, el nuevo vial no entraba nunca.
- **Causa:** la cámara rechazaba el vial repetido y se quedaba primero en la cinta, bloqueando los de detrás.
- **Arreglo:** la cámara acepta el vial repetido y lo desecha (con aviso en el teletipo).
- **Comprobación:** prueba de ratón: segunda mutación tras cambiar la receta.

## B5 · No se puede extraer sangre tras intentar la mutación de la tos — resuelto (P4.14)
- **Síntoma:** después de llevar plasma al biorreactor, la camilla ya no daba sangre.
- **Causa:** con otra cosa en las manos (plasma), la sangre extraída no se podía coger y se quedaba en la camilla; la camilla no admite otro paciente hasta que se recoge, y no había aviso ni forma visible de soltar lo que se llevaba.
- **Arreglo:** si se terminan de extraer con las manos ocupadas, la sangre espera y sale un aviso; botón «Tirar lo que llevo» (F) y botón «Ir a recoger lo hecho» en el panel; llevar cosas arrastrándolas.
- **Comprobación:** prueba de ratón: plasma en las manos → extraer → la sangre espera → vender el plasma → recoger la sangre.

## B6 · La cúpula de la cámara de cepa gira como una tapa con bisagra — resuelto (V1.1)
- **Causa:** la pieza se llama «tapa» y recibe la animación de la tapa de la centrífuga.
- **Arreglo:** la animación de tapa solo se aplica a la centrífuga (`maquina.gd`).
- **Comprobación:** captura de la cámara de cepa trabajando; la cúpula ya no se mueve.
- **Evitar:** no reutilizar nombres de nodo con animación genérica entre máquinas.

## B7 · Cambiar de mutación borra lo cargado en el biorreactor — resuelto (V1.1)
- **Causa:** `poner_receta` vacía la tolva y cancela la tanda en curso.
- **Arreglo:** la tanda en curso vuelve a la tolva; lo que no sirve para la nueva receta pasa a la salida.
- **Comprobación:** prueba de ratón «cambiar receta conserva la tolva».
- **Evitar:** cambiar de receta nunca destruye objetos.

## B8 · La primera mutación no da ninguna recompensa visible — resuelto (V1.1)
- **Causa:** aviso solo en el teletipo, propagación inicial 0,001 % que se ve como 0,00 %, premio sin efecto visible.
- **Arreglo:** anuncio grande arriba al hacer una mutación nueva, cumplir un hito, comprar parcela o pasar de fase; la propagación crece con las vacunas vendidas.
- **Comprobación:** prueba de ratón ve el anuncio tras la primera mutación.
- **Evitar:** cada logro importante tiene feedback grande, no solo teletipo.

## B9 · Mutación repetida desaparece en silencio — resuelto (V1.1)
- **Causa:** la cámara desecha la repetida y el biorreactor tiene la tos por defecto.
- **Arreglo:** el biorreactor pasa a estado REPETIDA (luz y aviso) y no fabrica; si llega un vial repetido a la cámara, se desecha con anuncio.
- **Comprobación:** prueba de ratón con la tos dos veces.
- **Evitar:** nada desaparece sin avisar.

## B10 · Al quitar una máquina se pierde lo que tenía dentro — resuelto (V1.1)
- **Arreglo:** quitar devuelve el 100 % y mete lo que tenía dentro en la mochila (o lo deja al lado si está llena).
- **Comprobación:** prueba de ratón «quitar devuelve contenido».
- **Evitar:** quitar nunca destruye objetos.

## B11 · El científico se queda «pillado» al sacar sangre (sigue tras V1.16) — resuelto (V1.16b)
- **Síntoma:** jugando, durante la extracción el científico está en reposo y el brazo se mueve solo siguiendo la aguja; en la demo se veía bien.
- **Causa:** la postura se decidía con `est.trabajando`, que la simulación pone a falso en `fab.avanzar()` antes de que el científico trabaje ese fotograma; en partida siempre salía falso. La demo tenía otro orden.
- **Arreglo:** la postura depende de «estación lista + científico cerca + quieto», que no depende del orden.
- **Comprobación:** fotogramas de la partida real (`--prueba_raton --seq_camilla`), no de la demo.
- **Evitar:** verificar las animaciones en la partida real; nada de leer banderas que la simulación reinicia a mitad de fotograma.

## B12 · Las personas atraviesan el banco en la pantalla objetivo — resuelto (R1.3)
- **Síntoma:** los pacientes sentados metían el tronco en el respaldo y las manos en el asiento de al lado.
- **Causa:** la animación de sentarse (KayKit) echa el cuerpo 0,29 hacia atrás y apoya las manos en reposabrazos a ±0,24 y 0,43 de alto; el banco no tenía reposabrazos y la persona se colocaba en el centro del asiento.
- **Arreglo:** puntos de uso medidos con los huesos de la animación (origen 0,19 delante del centro del banco), reposabrazos entre plazas a 0,40, taburete de recepción a la altura de la animación; comprobación de solapes en la lámina (0 solapes).
- **Evitar:** regla 8 del CLAUDE.md; ningún mueble sin sus puntos de uso medidos.
