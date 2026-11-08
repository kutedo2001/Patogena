# PATÓGENA S.A. — instrucciones para Claude

Juego de Edu. Todo en castellano, respuestas directas. Método: skill `estudio-de-juegos` (si la sesión no la tiene, estas reglas bastan).

Fábrica 3D isométrica de un laboratorio farmacéutico que provoca un apocalipsis zombi. Las mutaciones del virus se fabrican como productos. Tono: comedia negra seria con gore estilizado.

## Dónde vive todo
- GitHub: github.com/kutedo2001/patogena, rama main. La raíz del repo es el proyecto de Godot 4 (GDScript).
- PC de Edu: D:\programar again\juegos\Patogena\proyecto_godot y ...\entregas. Nada en C.
- Documento de diseño: https://claude.ai/artifact/XVYRKWeQAvMiSUE9AbUn59 (copia en docs/diseno.md)
- Hoja de ruta: https://claude.ai/artifact/8sb5FNiWcgFMr6jQvdGpbe (fuente en docs/hoja_de_ruta.html, slug 3fc02851-ded8-4547-9b89-502ae83981ed)
- Prototipos de concepto (three.js, solo referencia): https://claude.ai/artifact/Q7pVRafGUfrY7P8g9AKu38
- Puerta actual: 3 (pantalla objetivo) · Pantalla objetivo: docs/referencias/objetivo.png (pendiente)

## Reglas
1. Hoja de ruta primero: toda petición pasa a tareas con ficha antes de tocar código; se enseña a Edu y se empieza.
2. Calidad antes que velocidad: "hecho" = pasa la barra de calidad; una cosa terminada antes de la siguiente; ante una queja, diagnóstico de la causa antes de cambiar nada.
3. Puertas: no se pasa de puerta sin un «aprobado» de Edu.
4. Gráficos pieza a pieza: cada asset o lote se enseña a Edu en una lámina con la cámara del juego y al lado de las referencias antes de montarlo.
5. Personas, caras, manos y animales: nunca con primitivas ni esculpido por código (pack CC0 recoloreado).
6. Ningún texto flotando sobre el mundo: luces e iconos de estado en las máquinas; el resto en paneles del HUD.

## Sincronización
- git pull al empezar; commit y push al acabar cada tarea; actualizar D: o avisar a Edu.
- D: se actualiza con bundles incrementales en D:\programar again\juegos\Patogena\_sync (nombre distinto cada vez) y `git merge --ff-only`.

## Registro
- Antes de tocar nada: docs/bugs.md y docs/decisiones.md.
- Un commit por tarea: tipo: qué (fix, feat, arte, balance, texto, build, docs).
- Fallo → bugs.md · Decisión → decisiones.md · Cambio visible → CHANGELOG.md.
- Textos siempre con tr() y locale/textos.csv; locale/fallback = es.
