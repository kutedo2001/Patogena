"""Texturas generadas: etiquetas de producto y calcomanías de máquina (sin palabras).
Uso: python3 tools/texturas.py   (escribe en assets/texturas/)"""
from PIL import Image, ImageDraw, ImageFilter
import math, random, os
RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets', 'texturas')

def biohazard(d, cx, cy, r, col, ancho=None):
    ancho = ancho or max(2, int(r * 0.16))
    for k in range(3):
        a = math.radians(90 + k * 120)
        x, y = cx + math.cos(a) * r * 0.45, cy - math.sin(a) * r * 0.45
        d.ellipse([x - r * 0.5, y - r * 0.5, x + r * 0.5, y + r * 0.5], outline=col, width=ancho)
    d.ellipse([cx - r * 0.22, cy - r * 0.22, cx + r * 0.22, cy + r * 0.22], outline=col, width=max(2, int(ancho * 0.75)))

def logo(d, x, y, s, col, fondo):
    d.rectangle([x, y, x + s * 0.22, y + s], fill=col)
    d.pieslice([x, y, x + s * 0.8, y + s * 0.62], -90, 90, fill=col)
    d.pieslice([x + s * 0.18, y + s * 0.15, x + s * 0.6, y + s * 0.47], -90, 90, fill=fondo)

def etiqueta(nombre, franja, W=512, H=256, seed=1):
    random.seed(seed)
    im = Image.new('RGB', (W, H), (246, 245, 238)); d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W, int(H * 0.2)], fill=franja)
    d.rectangle([0, H - int(H * 0.07), W, H], fill=franja)
    x = int(W * 0.06)
    while x < W * 0.62:
        w = random.choice((2, 3, 5, 7)); d.rectangle([x, int(H * 0.32), x + w, int(H * 0.78)], fill=(25, 25, 25)); x += w + random.choice((3, 4, 6))
    biohazard(d, int(W * 0.8), int(H * 0.5), int(H * 0.2), (200, 30, 30))
    logo(d, int(W * 0.67), int(H * 0.04), int(H * 0.12), (250, 250, 246), franja)
    d.rectangle([int(W * 0.06), int(H * 0.83), int(W * 0.06) + random.randint(60, 200), int(H * 0.86)], fill=(120, 120, 120))
    im.save(os.path.join(RAIZ, 'etiquetas', nombre + '.png'))

def triangulo_aviso(nombre, dibujo, N=256):
    im = Image.new('RGBA', (N, N), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    m = N * 0.04
    pts = [(N / 2, m), (N - m, N - m * 1.6), (m, N - m * 1.6)]
    d.polygon(pts, fill=(20, 20, 20))
    k = N * 0.07
    pts2 = [(N / 2, m + k * 1.7), (N - m - k * 1.5, N - m * 1.6 - k * 0.8), (m + k * 1.5, N - m * 1.6 - k * 0.8)]
    d.polygon(pts2, fill=(250, 200, 30))
    dibujo(d, N / 2, N * 0.62, N * 0.2)
    im.save(os.path.join(RAIZ, 'calcomanias', nombre + '.png'))

def rotor(d, cx, cy, r):
    d.arc([cx - r, cy - r, cx + r, cy + r], 30, 320, fill=(20, 20, 20), width=int(r * 0.22))
    a = math.radians(320)
    x, y = cx + math.cos(a) * r, cy + math.sin(a) * r
    d.polygon([(x - r * 0.35, y - r * 0.05), (x + r * 0.25, y - r * 0.35), (x + r * 0.15, y + r * 0.3)], fill=(20, 20, 20))
    d.ellipse([cx - r * 0.2, cy - r * 0.2, cx + r * 0.2, cy + r * 0.2], fill=(20, 20, 20))

def placa_logo(N=(512, 256)):
    W, H = N
    im = Image.new('RGB', N, (178, 182, 186)); px = im.load()
    random.seed(9)
    for y in range(H):
        v = random.randint(-8, 8)
        for x in range(W):
            r, g, b = px[x, y]; n = v + random.randint(-3, 3); px[x, y] = (r + n, g + n, b + n)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([4, 4, W - 5, H - 5], radius=18, outline=(120, 124, 128), width=4)
    logo(d, 40, 40, 170, (40, 120, 110), (178, 182, 186))
    for k, w in enumerate((240, 180, 210, 120)):
        d.rectangle([250, 60 + k * 38, 250 + w, 72 + k * 38], fill=(70, 74, 78))
    for x in (20, W - 28):
        for y in (20, H - 28):
            d.ellipse([x - 7, y - 7, x + 7, y + 7], fill=(110, 114, 118))
    im.save(os.path.join(RAIZ, 'calcomanias', 'placa_logo.png'))

def franja_peligro(N=(512, 64)):
    W, H = N
    im = Image.new('RGB', N, (245, 195, 30)); d = ImageDraw.Draw(im)
    for x in range(-H, W + H, H):
        d.polygon([(x, H), (x + H // 2, H), (x + H + H // 2, 0), (x + H, 0)], fill=(25, 25, 25))
    im.save(os.path.join(RAIZ, 'calcomanias', 'franja_peligro.png'))

def caja_vacunas(N=(512, 512)):
    W, H = N
    im = Image.new('RGB', N, (246, 246, 242)); d = ImageDraw.Draw(im)
    d.rectangle([0, H - 70, W, H], fill=(40, 150, 110))
    c, a, g = (W // 2, H // 2 - 30), 120, 42
    d.rectangle([c[0] - g, c[1] - a, c[0] + g, c[1] + a], fill=(40, 150, 110))
    d.rectangle([c[0] - a, c[1] - g, c[0] + a, c[1] + g], fill=(40, 150, 110))
    logo(d, 24, 18, 60, (40, 150, 110), (246, 246, 242))
    random.seed(12)
    x = W - 200
    while x < W - 30:
        w = random.choice((2, 3, 5)); d.rectangle([x, 22, x + w, 70], fill=(30, 30, 30)); x += w + random.choice((2, 4, 5))
    for k in range(6):
        d.ellipse([30 + k * 40, H - 55, 58 + k * 40, H - 27], outline=(246, 246, 242), width=4)
    im.save(os.path.join(RAIZ, 'calcomanias', 'caja_vacunas.png'))

def bolsa_suero(N=(256, 512)):
    W, H = N
    im = Image.new('RGBA', N, (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    for k in range(9):          # graduación
        y = 90 + k * 40
        d.rectangle([20, y, 20 + (60 if k % 2 == 0 else 35), y + 5], fill=(30, 60, 120, 255))
    d.rectangle([110, 120, 236, 300], fill=(246, 246, 240, 235))
    d.rectangle([110, 120, 236, 150], fill=(230, 180, 40, 255))
    logo(d, 122, 165, 50, (40, 150, 110), (246, 246, 240))
    random.seed(13)
    x = 120
    while x < 226:
        w = random.choice((2, 3, 4)); d.rectangle([x, 235, x + w, 285], fill=(30, 30, 30, 255)); x += w + random.choice((2, 3, 4))
    im.save(os.path.join(RAIZ, 'etiquetas', 'suero_bolsa.png'))

def banda(N=(256, 256)):
    W, H = N
    im = Image.new('RGB', N, (52, 55, 58)); px = im.load()
    random.seed(15)
    for y in range(H):
        for x in range(W):
            n = random.randint(-5, 5); r, g, b = px[x, y]; px[x, y] = (r + n, g + n, b + n)
    d = ImageDraw.Draw(im)
    # nervios transversales y chevron central (indica sentido +U)
    for k in range(4):
        y0 = k * H // 4
        d.rectangle([0, y0, W, y0 + 6], fill=(32, 34, 36))
    for k in range(2):
        cy = H // 4 + k * H // 2
        d.polygon([(W * 0.3, cy - 26), (W * 0.62, cy), (W * 0.3, cy + 26), (W * 0.4, cy + 26), (W * 0.72, cy), (W * 0.4, cy - 26)], fill=(88, 92, 96))
    im.rotate(90).save(os.path.join(RAIZ, 'banda.png'))

def banda_curva(N=(256, 256)):
    """Banda para curvas: los nervios transversales se vuelven radiales (como una cinta curva real)
    y el chevron es estrecho y centrado para que no se abra en abanico."""
    W, H = N
    im = Image.new('RGB', N, (52, 55, 58)); px = im.load()
    random.seed(16)
    for y in range(H):
        for x in range(W):
            n = random.randint(-5, 5); r, g, b = px[x, y]; px[x, y] = (r + n, g + n, b + n)
    d = ImageDraw.Draw(im)
    for k in range(8):
        y0 = k * H // 8
        d.rectangle([0, y0, W, y0 + 4], fill=(32, 34, 36))
    for k in range(2):
        cy = H // 4 + k * H // 2
        d.polygon([(W * 0.43, cy - 12), (W * 0.55, cy), (W * 0.43, cy + 12), (W * 0.47, cy + 12), (W * 0.59, cy), (W * 0.47, cy - 12)], fill=(88, 92, 96))
    im.rotate(90).save(os.path.join(RAIZ, 'banda_curva.png'))

if __name__ == '__main__':
    os.makedirs(os.path.join(RAIZ, 'etiquetas'), exist_ok=True)
    os.makedirs(os.path.join(RAIZ, 'calcomanias'), exist_ok=True)
    for n, c, s in (('sangre', (190, 30, 35), 1), ('plasma', (230, 180, 40), 2), ('adn', (60, 170, 80), 3),
                    ('mutacion', (60, 65, 70), 4), ('cultivo', (60, 140, 180), 5),
                    ('agua', (60, 140, 220), 6), ('reactivo', (40, 70, 180), 7), ('neurotoxina', (110, 30, 140), 8)):
        etiqueta(n, c, seed=s)
    triangulo_aviso('aviso_biorriesgo', lambda d, x, y, r: biohazard(d, x, y, r * 1.05, (20, 20, 20), int(r * 0.2)))
    triangulo_aviso('aviso_rotor', rotor)
    placa_logo()
    franja_peligro()
    caja_vacunas()
    bolsa_suero()
    banda()
    banda_curva()
    print('texturas ok')
