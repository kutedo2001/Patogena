"""Módulos de la sala de cepas (V1.17): pared de laboratorio de 1 m (zócalo, panel, ventana alta de vidrio
con perfiles), puerta corredera doble, buzón de entrega con boca de cinta y muebles que llenan las casillas
de pared por dentro (estantería con frascos, nevera de muestras, campana de gases, armario de reactivos).
Cada módulo ocupa una casilla de 1 m; la pared va por el borde exterior (+Y de Blender = fuera, que el
juego gira según el lado) y el mueble por dentro.
Uso: blender -b -P tools/blender/sala_cepas.py -- <carpeta_salida> <carpeta_calcomanias>
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *

CAL = None
H = 1.25          # altura de la pared
YP = 0.42         # la pared va pegada al borde exterior de la casilla


def pared(r, con_ventana=True):
    gr, ch = mat("grafito"), mat("chasis")
    caja("pared_zocalo", (1.0, 0.12, 0.12), (0, YP, 0.06), gr, bisel=0.01, padre=r)
    caja("pared_panel", (1.0, 0.1, 0.62), (0, YP, 0.12 + 0.31), mat("pared_verde", color=(0.29, 0.58, 0.54), rug=0.6), bisel=0.008, padre=r)
    caja("pared_canto", (1.0, 0.12, 0.03), (0, YP, 0.75), gr, bisel=0.006, padre=r)
    if con_ventana:
        caja("pared_vidrio", (0.96, 0.02, H - 0.8), (0, YP, 0.76 + (H - 0.8) / 2), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.15),
             bisel=0.0, padre=r)
    else:
        caja("pared_alta", (1.0, 0.1, H - 0.78), (0, YP, 0.76 + (H - 0.78) / 2), ch, bisel=0.006, padre=r)
    for x in (-0.49, 0.49):
        caja(f"pared_perfil{x}", (0.04, 0.12, H), (x, YP, H / 2), gr, bisel=0.006, padre=r)
    caja("pared_remate", (1.0, 0.13, 0.04), (0, YP, H), gr, bisel=0.006, padre=r)


def mod_estanteria():
    r = vacio("sala_estanteria"); pared(r)
    met = mat("metal")
    for k in range(3):
        caja(f"estante{k}", (0.85, 0.28, 0.02), (0, 0.22, 0.25 + k * 0.28), met, bisel=0.004, padre=r)
    for sx in (-1, 1):
        caja(f"estante_lado{sx}", (0.02, 0.3, 0.9), (sx * 0.43, 0.22, 0.45), met, bisel=0.004, padre=r)
    cols = ((0.35, 0.15, 0.75), (0.9, 0.5, 0.1), (0.2, 0.7, 0.3), (0.85, 0.85, 0.8), (0.75, 0.1, 0.1))
    for k in range(3):
        for j in range(5):
            c = cols[(k + j) % len(cols)]
            cilindro(f"frasco{k}{j}", 0.04, 0.12, (-0.32 + j * 0.16, 0.22, 0.32 + k * 0.28), mat(f"frasco_pl{(k + j) % 5}", color=c, rug=0.2, alfa=0.75),
                     lados=16, bisel=0.008, padre=r)
            cilindro(f"frasco{k}{j}_tapon", 0.025, 0.03, (-0.32 + j * 0.16, 0.22, 0.395 + k * 0.28), mat("grafito"), lados=12, bisel=0.004, padre=r)
    return r


def mod_nevera():
    r = vacio("sala_nevera"); pared(r, con_ventana=False)
    caja("nevera", (0.7, 0.55, 1.1), (0, 0.08, 0.55), mat("chasis"), bisel=0.03, padre=r)
    caja("nevera_puerta", (0.62, 0.02, 0.8), (0, -0.2, 0.62), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.3), bisel=0.005, padre=r)
    caja("nevera_interior", (0.6, 0.45, 0.78), (0, 0.06, 0.62), mat("interior_frio", color=(0.7, 0.85, 0.95), emision=(0.6, 0.85, 1.0), fuerza=0.5), bisel=0.01, padre=r)
    for k in range(4):
        caja(f"nevera_bandeja{k}", (0.58, 0.42, 0.01), (0, 0.06, 0.3 + k * 0.18), mat("metal"), bisel=0.002, padre=r)
        for j in range(6):
            cilindro(f"nevera_tubo{k}{j}", 0.015, 0.08, (-0.22 + j * 0.09, 0.0, 0.35 + k * 0.18), mat("tapon_sangre", color=(0.62, 0.03, 0.03), rug=0.45),
                     lados=8, padre=r)
    caja("nevera_panel", (0.7, 0.03, 0.12), (0, -0.2, 1.05), mat("grafito"), bisel=0.008, padre=r)
    pantalla_plano("pantalla", 0.2, 0.06, (-0.15, -0.217, 1.05), padre=r)
    caja("nevera_tirador", (0.03, 0.03, 0.3), (0.27, -0.23, 0.62), mat("metal"), bisel=0.006, padre=r)
    return r


def mod_campana():
    r = vacio("sala_campana"); pared(r, con_ventana=False)
    ch, gr = mat("chasis"), mat("grafito")
    caja("campana_mueble", (0.9, 0.55, 0.45), (0, 0.1, 0.225), ch, bisel=0.02, padre=r)
    caja("campana_encimera", (0.92, 0.57, 0.03), (0, 0.1, 0.46), mat("tablero_resina", color=(0.18, 0.2, 0.22), rug=0.35), bisel=0.006, padre=r)
    caja("campana_caja", (0.9, 0.5, 0.55), (0, 0.13, 0.76), ch, bisel=0.02, padre=r)
    caja("campana_hueco", (0.8, 0.42, 0.42), (0, 0.11, 0.72), mat("interior_inc", color=(0.85, 0.88, 0.86), emision=(1.0, 0.95, 0.85), fuerza=0.4), bisel=0.01, padre=r)
    caja("campana_guillotina", (0.82, 0.02, 0.3), (0, -0.12, 0.82), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.25), bisel=0.004, padre=r)
    cilindro("campana_tubo", 0.08, 0.35, (0.25, 0.3, 1.2), mat("metal"), lados=20, padre=r)
    for k in range(3):
        cilindro(f"campana_matraz{k}", 0.04, 0.1, (-0.25 + k * 0.2, 0.15, 0.53), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.3), lados=16, padre=r)
        cilindro(f"campana_liq{k}", 0.035, 0.05, (-0.25 + k * 0.2, 0.15, 0.51), mat(f"liq_campana{k}", color=((0.3, 0.9, 0.2), (0.6, 0.2, 0.8), (0.9, 0.5, 0.1))[k],
                 emision=((0.3, 0.9, 0.2), (0.6, 0.2, 0.8), (0.9, 0.5, 0.1))[k], fuerza=0.6), lados=16, padre=r)
    return r


def mod_armario():
    r = vacio("sala_armario"); pared(r)
    ch, gr = mat("chasis"), mat("grafito")
    caja("armario", (0.85, 0.45, 0.7), (0, 0.15, 0.35), mat("armario_amarillo", color=(0.95, 0.78, 0.2), rug=0.45), bisel=0.02, padre=r)
    for s in (-1, 1):
        caja(f"armario_puerta{s}", (0.4, 0.02, 0.6), (s * 0.21, -0.08, 0.36), mat("armario_amarillo"), bisel=0.005, padre=r)
        caja(f"armario_tirador{s}", (0.02, 0.02, 0.12), (s * 0.04, -0.1, 0.4), gr, bisel=0.004, padre=r)
    if CAL:
        ruta = os.path.join(CAL, "aviso_biorriesgo.png")
        if os.path.exists(ruta):
            calcomania("armario_bio", 0.18, 0.18, (0, -0.092, 0.5), mat_calcomania("aviso_biorriesgo", ruta, recorte=True), padre=r)
    for k in range(3):
        cilindro(f"armario_garrafa{k}", 0.07, 0.2, (-0.25 + k * 0.25, 0.15, 0.81), mat("garrafa_pl", color=(0.8, 0.9, 0.97), rug=0.1, alfa=0.4), lados=20, bisel=0.02, padre=r)
    return r


def mod_esquina():
    """Esquina: dos paredes en L (exterior +Y y +X) y una planta de interior… de plástico."""
    r = vacio("sala_esquina"); pared(r)
    gr = mat("grafito")
    for parte in ("zocalo", "panel", "canto", "vidrio", "remate"):
        pass
    caja("esq_zocalo", (0.12, 1.0, 0.12), (YP, 0, 0.06), gr, bisel=0.01, padre=r)
    caja("esq_panel", (0.1, 1.0, 0.62), (YP, 0, 0.43), mat("pared_verde", color=(0.29, 0.58, 0.54), rug=0.6), bisel=0.008, padre=r)
    caja("esq_canto", (0.12, 1.0, 0.03), (YP, 0, 0.75), gr, bisel=0.006, padre=r)
    caja("esq_vidrio", (0.02, 0.96, H - 0.8), (YP, 0, 0.76 + (H - 0.8) / 2), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.15), bisel=0.0, padre=r)
    caja("esq_remate", (0.13, 1.0, 0.04), (YP, 0, H), gr, bisel=0.006, padre=r)
    cilindro("maceta", 0.12, 0.22, (0.1, 0.1, 0.11), mat("maceta", color=(0.85, 0.85, 0.82), rug=0.6), lados=20, bisel=0.02, padre=r)
    for k in range(7):
        a = k * math.tau / 7
        caja(f"hoja{k}", (0.04, 0.2, 0.01), (0.1 + math.cos(a) * 0.06, 0.1 + math.sin(a) * 0.06, 0.32), mat("hoja", color=(0.2, 0.55, 0.25), rug=0.6), bisel=0.002,
             padre=r, giro=(math.radians(50), 0, a))
    return r


def mod_puerta():
    """Puerta corredera doble de vidrio con marco y luz verde encima (la casilla queda libre para pasar)."""
    r = vacio("sala_puerta")
    gr = mat("grafito")
    caja("puerta_dintel", (1.0, 0.14, 0.15), (0, YP, H - 0.07), gr, bisel=0.01, padre=r)
    for x in (-0.47, 0.47):
        caja(f"puerta_jamba{x}", (0.06, 0.14, H), (x, YP, H / 2), gr, bisel=0.008, padre=r)
    for s in (-1, 1):
        caja(f"puerta_hoja{s}", (0.4, 0.03, H - 0.2), (s * 0.66, YP + 0.04, (H - 0.2) / 2 + 0.02), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.25),
             bisel=0.005, padre=r)
        caja(f"puerta_hoja{s}_marco", (0.42, 0.04, 0.04), (s * 0.66, YP + 0.04, 0.05), gr, bisel=0.004, padre=r)
    caja("puerta_luz", (0.3, 0.05, 0.06), (0, YP - 0.07, H - 0.05), mat("luz_verde", color=(0.3, 1.0, 0.45), emision=(0.3, 1.0, 0.45), fuerza=2.5), bisel=0.008, padre=r)
    caja("puerta_felpudo", (0.8, 0.5, 0.01), (0, 0.0, 0.005), mat("felpudo", color=(0.25, 0.27, 0.28), rug=0.95), bisel=0.002, padre=r)
    return r


def mod_buzon():
    """Buzón de entrega: pared con boca de cinta por fuera (+Y) y tolva por dentro que cae a una caja."""
    r = vacio("sala_buzon")
    pared(r, con_ventana=False)
    # la boca de cinta mira hacia fuera (+Y): se monta girada
    b = vacio("buzon_boca", (0, 0, 0), r)
    b.rotation_euler = (0, 0, math.radians(90))
    boca_cinta("buzon", 1, 0.5, 0.0, b)
    caja("buzon_tolva", (0.5, 0.4, 0.35), (0, 0.05, 0.5), mat("chasis"), bisel=0.03, padre=r)
    caja("buzon_caja", (0.6, 0.45, 0.3), (0, 0.0, 0.15), mat("acento_producto"), bisel=0.02, padre=r)
    pantalla_plano("pantalla", 0.3, 0.12, (0, -0.177, 0.55), padre=r)
    return r


def main():
    global CAL
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [".", "."]
    salida, CAL = args[0], args[1]
    os.makedirs(salida, exist_ok=True)
    for nombre, fn in (("sala_estanteria", mod_estanteria), ("sala_nevera", mod_nevera), ("sala_campana", mod_campana),
                       ("sala_armario", mod_armario), ("sala_esquina", mod_esquina), ("sala_puerta", mod_puerta), ("sala_buzon", mod_buzon)):
        limpiar(); comun._mats.clear()
        fn()
        exportar(os.path.join(salida, nombre + ".glb"))
        print("SALA", nombre)


if __name__ == "__main__":
    main()
