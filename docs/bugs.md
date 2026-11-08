# Fallos

Formato: síntoma · causa · arreglo · comprobación · cómo evitarlo.

## B1 · Web (Compatibility) se ve quemada en blanco — abierto, se resuelve en P3.3
- Síntoma: la exportación web arranca, pero el suelo y el cielo salen casi blancos y el título del HUD no se lee; en PC (Forward+) se ve bien.
- Causa probable: luz ambiental del cielo procedural y tonemap pensados para Forward+; Compatibility trabaja en otro espacio de color y no tiene SSAO.
- Arreglo: en P3.3, iluminación ajustada y comprobada en los dos renderizadores (captura Forward+ y captura web en cada vuelta).
- Cómo evitarlo: toda captura de luz se hace por partida doble (PC y web).
