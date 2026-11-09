"""Recolorea la paleta (colormap) de Kenney Mini Characters por personaje.
Cada celda de la paleta mide 32×128 px (columna, fila). Se cambia el color manteniendo el degradado original.
Uso: python3 tools/recolor_personajes.py"""
from PIL import Image
import os
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'personajes')
base = Image.open(os.path.join(RAIZ, 'Textures', 'colormap.png')).convert('RGBA')

def pinta(im, celdas, color):
    px = im.load()
    for (c, r) in celdas:
        x0, y0 = c * 32, r * 128
        lums = [sum(px[x, y][:3]) / 3 for x in range(x0, x0 + 32) for y in range(y0, y0 + 128)]
        m = max(sum(lums) / len(lums), 1)
        for x in range(x0, x0 + 32):
            for y in range(y0, y0 + 128):
                k = (sum(px[x, y][:3]) / 3) / m
                k = 0.82 + (k - 1) * 0.6 + 0.18      # degradado suave
                px[x, y] = tuple(max(0, min(255, int(v * k))) for v in color) + (255,)

BATA = (238, 240, 236)
GRIS = (70, 76, 86)
PIJAMA = (150, 200, 205)
SANGRE = (150, 20, 22)
variantes = {
    'investigador_m': [([(9, 2)], BATA), ([(1, 1)], GRIS)],
    'investigador_f': [([(15, 3)], BATA)],   # female-e ya lleva bata blanca y guantes azules
    'paciente_m': [([(9, 2), (1, 1)], PIJAMA)],
    'paciente_f': [([(3, 3)], PIJAMA)],     # female-d: el traje pasa a pijama
    'zombi': [([(3, 3), (5, 3)], (120, 160, 160)), ([(1, 2)], SANGRE), ([(9, 2)], (125, 170, 95))],
}
for nombre, cambios in variantes.items():
    im = base.copy()
    for celdas, color in cambios:
        pinta(im, celdas, color)
    im.save(os.path.join(RAIZ, 'Textures', nombre + '.png'))
print('personajes ok')
