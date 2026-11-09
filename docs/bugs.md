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
