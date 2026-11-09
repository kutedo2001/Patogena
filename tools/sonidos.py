"""Sonidos de Patógena S.A. sintetizados por código (V1.11): efectos de interfaz y del laboratorio,
ambiente de sala y música en bucle. Todo propio (sin muestras de terceros).
Uso: python3 tools/sonidos.py assets/sonido
"""
import sys, os, math
import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, lfilter

SR = 44100
rng = np.random.default_rng(7)


def t(d):
    return np.arange(int(SR * d)) / SR


def env(n, a=0.005, r=0.1, sostener=None):
    x = np.ones(n)
    na = max(1, int(a * SR))
    x[:na] = np.linspace(0, 1, na)
    nr = max(1, int(r * SR))
    if nr < n:
        x[-nr:] *= np.linspace(1, 0, nr) ** 2
    return x


def filtro(x, f, tipo="low", orden=2):
    b, a = butter(orden, f / (SR / 2), btype=tipo)
    return lfilter(b, a, x)


def ruido(d):
    return rng.uniform(-1, 1, int(SR * d))


def guardar(carpeta, nombre, x, vol=0.8):
    x = np.asarray(x, dtype=np.float64)
    m = np.max(np.abs(x)) or 1.0
    x = x / m * vol
    wavfile.write(os.path.join(carpeta, nombre + ".wav"), SR, (x * 32767).astype(np.int16))
    print("SON", nombre, round(len(x) / SR, 2), "s")


def clic():
    tt = t(0.06)
    return np.sin(2 * np.pi * 1800 * tt) * np.exp(-tt * 90) + 0.3 * filtro(ruido(0.06), 4000, "high") * np.exp(-tt * 200)


def pulsador():
    tt = t(0.12)
    a = np.sin(2 * np.pi * 420 * tt) * np.exp(-tt * 40)
    b = filtro(ruido(0.12), 2500) * np.exp(-tt * 70) * 0.6
    return a + b


def construir():
    tt = t(0.45)
    golpe = filtro(ruido(0.45), 900) * np.exp(-tt * 18)
    metal = sum(np.sin(2 * np.pi * f * tt) * np.exp(-tt * k) for f, k in ((310, 9), (733, 12), (1210, 16))) * 0.5
    tornillo = np.zeros_like(tt)
    for k in range(3):
        i0 = int((0.18 + k * 0.07) * SR)
        n = int(0.04 * SR)
        tornillo[i0:i0 + n] += filtro(ruido(0.04), 3000, "high")[:n] * np.exp(-np.arange(n) / SR * 80) * 0.5
    return golpe + metal + tornillo


def quitar():
    tt = t(0.35)
    sweep = np.sin(2 * np.pi * (600 - 900 * tt) * tt) * np.exp(-tt * 9)
    return sweep * 0.6 + filtro(ruido(0.35), 1200) * np.exp(-tt * 14) * 0.5


def vender():
    tt = t(0.55)
    campana = sum(np.sin(2 * np.pi * f * tt) * np.exp(-tt * 6) for f in (1318, 1975, 2637)) * 0.4
    caja = filtro(ruido(0.55), 2000) * np.exp(-tt * 30) * 0.6
    return campana + caja


def error():
    tt = t(0.3)
    return np.sign(np.sin(2 * np.pi * 140 * tt)) * env(len(tt), 0.005, 0.08) * 0.5 + np.sin(2 * np.pi * 95 * tt) * env(len(tt), 0.005, 0.1) * 0.5


def pinchazo():
    """Aguja que entra: chasquido corto y un «squish» húmedo."""
    tt = t(0.35)
    chasq = filtro(ruido(0.35), 5000, "high") * np.exp(-tt * 120)
    hum = filtro(ruido(0.35), 700) * np.exp(-((tt - 0.06) ** 2) / 0.002) * 0.9
    return chasq * 0.7 + hum


def tubo_lleno():
    """Tubo que se llena y se tapa: burbujeo que sube y «plop»."""
    tt = t(0.8)
    burb = np.zeros_like(tt)
    for k in range(14):
        c = rng.uniform(0.0, 0.55)
        f = 300 + 900 * c + rng.uniform(-40, 40)
        burb += np.sin(2 * np.pi * f * tt) * np.exp(-np.maximum(tt - c, 0) * 60) * (tt > c) * 0.4
    i0 = int(0.62 * SR)
    pt = tt[i0:] - tt[i0]
    plop = np.zeros_like(tt)
    plop[i0:] = np.sin(2 * np.pi * (500 - 380 * pt * 4) * pt) * np.exp(-pt * 30)
    return burb + plop


def mejora():
    """Mejora de la cepa: acorde menor con pulso de bajo y arpegio inquietante."""
    tt = t(2.2)
    notas = [110, 130.81, 164.81, 207.65]  # La menor con séptima mayor (inquietante)
    x = np.zeros_like(tt)
    for i, f in enumerate(notas):
        on = tt > i * 0.14
        x += (np.sin(2 * np.pi * f * 2 * tt) + 0.4 * np.sin(2 * np.pi * f * 4 * tt)) * np.exp(-np.maximum(tt - i * 0.14, 0) * 1.6) * on * 0.3
    x += np.sin(2 * np.pi * 55 * tt) * np.exp(-tt * 1.2) * 0.8
    x += filtro(ruido(2.2), 300) * np.exp(-tt * 3) * 0.3
    return x * env(len(tt), 0.01, 0.6)


def anuncio():
    tt = t(0.7)
    a = np.sin(2 * np.pi * 880 * tt) * np.exp(-tt * 7) * (tt < 0.35)
    b = np.sin(2 * np.pi * 659.25 * tt) * np.exp(-np.maximum(tt - 0.18, 0) * 7) * (tt > 0.18)
    return (a + b) * 0.6


def furgoneta():
    tt = t(2.5)
    f = 45 + 35 * np.clip(tt / 1.5, 0, 1)
    fase = 2 * np.pi * np.cumsum(f) / SR
    motor = np.sign(np.sin(fase)) * 0.3 + np.sin(fase * 2) * 0.3
    motor = filtro(motor, 600)
    return motor * env(len(tt), 0.2, 1.0) * np.clip(1.6 - tt / 1.6, 0, 1)


def zombi():
    """Gruñido: ruido filtrado con formantes bajos que suben y bajan."""
    tt = t(1.1)
    base = filtro(ruido(1.1), 900)
    fm = 90 + 30 * np.sin(2 * np.pi * 3 * tt)
    voz = np.sign(np.sin(2 * np.pi * np.cumsum(fm) / SR)) * 0.4
    return filtro(base * 0.6 + voz, 1400) * env(len(tt), 0.08, 0.4)


def generador():
    tt = t(2.0)
    f = 30
    x = (np.sign(np.sin(2 * np.pi * f * tt)) * 0.4 + np.sin(2 * np.pi * f * 2 * tt) * 0.4 +
         filtro(ruido(2.0), 400) * 0.3)
    return filtro(x, 500)


def ambiente():
    """Sala de laboratorio en bucle: zumbido eléctrico, ventilación y algún pitido lejano."""
    d = 16.0
    tt = t(d)
    hum = np.sin(2 * np.pi * 50 * tt) * 0.15 + np.sin(2 * np.pi * 100 * tt) * 0.08 + np.sin(2 * np.pi * 150 * tt) * 0.03
    vent = filtro(ruido(d), 500) * 0.35 * (1 + 0.15 * np.sin(2 * np.pi * 0.2 * tt))
    pit = np.zeros_like(tt)
    for c in (3.2, 9.7, 13.1):
        m = (tt > c) & (tt < c + 0.09)
        pit[m] += np.sin(2 * np.pi * 1975 * tt[m]) * 0.05
    x = hum + vent + pit
    n = int(0.5 * SR)  # fundido para que el bucle no chasquee
    x[:n] = x[:n] * np.linspace(0, 1, n) + x[-n:] * np.linspace(1, 0, n)
    return x[:-n]


def musica():
    """Bucle de 32 s: pad oscuro en La menor, bajo pulsante a 92 ppm y una campanita fría."""
    bpm = 92
    beat = 60 / bpm
    d = beat * 48
    tt = t(d)
    x = np.zeros_like(tt)
    acordes = [[110, 130.81, 164.81], [87.31, 110, 130.81], [98, 116.54, 146.83], [82.41, 103.83, 123.47]]
    largo = d / 4
    for i, ac in enumerate(acordes):
        m = (tt >= i * largo) & (tt < (i + 1) * largo)
        tl = tt[m] - i * largo
        e = np.minimum(1, tl / 1.5) * np.minimum(1, (largo - tl) / 1.5)
        for f in ac:
            for det in (-0.6, 0.6):
                x[m] += np.sin(2 * np.pi * (f + det) * tt[m]) * 0.08 * e
        # bajo en corcheas
        fb = ac[0] / 2
        pulso = np.exp(-(tl % (beat / 2)) * 9)
        x[m] += np.sin(2 * np.pi * fb * tt[m]) * pulso * 0.25
    # campanita cada 4 tiempos
    for k in range(12):
        c = k * beat * 4 + beat * 2
        m = tt > c
        f = [659.25, 587.33, 523.25, 493.88][k % 4]
        x[m] += np.sin(2 * np.pi * f * (tt[m] - c)) * np.exp(-(tt[m] - c) * 3) * 0.06
    x = filtro(x, 3500)
    n = int(1.0 * SR)
    x[:n] = x[:n] * np.linspace(0, 1, n) + x[-n:] * np.linspace(1, 0, n)
    return x[:-n]


def main():
    carpeta = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(carpeta, exist_ok=True)
    for nombre, fn, vol in (("clic", clic, 0.5), ("pulsador", pulsador, 0.6), ("construir", construir, 0.8), ("quitar", quitar, 0.7),
                            ("vender", vender, 0.6), ("error", error, 0.5), ("pinchazo", pinchazo, 0.8), ("tubo_lleno", tubo_lleno, 0.6),
                            ("mejora", mejora, 0.9), ("anuncio", anuncio, 0.6), ("furgoneta", furgoneta, 0.6), ("zombi", zombi, 0.7),
                            ("generador", generador, 0.5), ("ambiente", ambiente, 0.5), ("musica", musica, 0.7)):
        guardar(carpeta, nombre, fn(), vol)


if __name__ == "__main__":
    main()
