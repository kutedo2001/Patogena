"""Piezas de la etapa 1–2 (V1.8): sala de espera (2×1), generador diésel (2×2) y generador de biogás
de sangre (2×2). Detalle del lote 1: tornillos, juntas, rejillas, pegatinas, piezas que se mueven.
Uso: blender -b -P tools/blender/piezas_v18.py -- <carpeta_salida> <carpeta_calcomanias>
Nodos animados: generador → "ventilador" (gira en Z), "piston_*" (sube y baja), "escape" (humo en el juego);
biogás → "liquido" (nivel), "agitador" (gira), "llama" (la antorcha). Baliza: "baliza".
Asientos de la sala: vacíos "asiento0..3" (el juego sienta ahí a los pacientes).
"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import importlib, comun
importlib.reload(comun)
from comun import *

CAL = None


def sala_espera():
    """Bancada de 4 sillas de plástico unidas por una viga, mesita con revistas, fuente de agua y
    dispensador de números. Va de x = -1 a 1 (dos casillas), los asientos miran a -Y (+Z del juego)."""
    r = vacio("sala_espera")
    met, gr = mat("metal"), mat("grafito")
    pl = mat("plastico_silla", color=(0.24, 0.58, 0.55), rug=0.45)
    # suelo de moqueta para marcar la zona
    caja("moqueta", (1.94, 0.94, 0.008), (0, 0, 0.004), mat("moqueta", color=(0.55, 0.6, 0.58), rug=0.95), bisel=0.003, padre=r)
    caja("moqueta_ribete", (1.96, 0.96, 0.004), (0, 0, 0.002), gr, bisel=0.001, padre=r)
    # viga y patas de la bancada
    zs = 0.125
    cilindro("viga", 0.012, 1.3, (-0.25, 0.1, zs - 0.03), met, lados=16, giro=(0, math.radians(90), 0), padre=r)
    for x in (-0.85, -0.25, 0.35):
        caja(f"pata_t{x}", (0.02, 0.02, zs - 0.03), (x, 0.1, (zs - 0.03) / 2), met, bisel=0.004, padre=r)
        caja(f"pie_t{x}", (0.03, 0.22, 0.012), (x, 0.1, 0.012), met, bisel=0.004, padre=r)
        for s in (-1, 1):
            cilindro(f"taco{x}{s}", 0.012, 0.008, (x, 0.1 + s * 0.1, 0.004), mat("goma"), lados=12, padre=r)
    for k in range(4):
        x = -0.85 + k * 0.4
        cx = x + 0.0
        a = vacio(f"asiento{k}", (cx, 0.05, zs + 0.01), r)
        caja(f"silla{k}_asiento", (0.24, 0.2, 0.02), (cx, 0.07, zs), pl, bisel=0.008, segmentos=3, padre=r)
        caja(f"silla{k}_respaldo", (0.24, 0.02, 0.2), (cx, 0.175, zs + 0.11), pl, bisel=0.008, segmentos=3, padre=r,
             giro=(math.radians(-8), 0, 0))
        caja(f"silla{k}_soporte", (0.04, 0.03, 0.12), (cx, 0.15, zs + 0.03), met, bisel=0.005, padre=r)
        for s in (-1, 1):
            tornillo(f"silla{k}_torn{s}", (cx + s * 0.06, 0.07, zs - 0.012), r, r=0.005, normal="+Z")
        if k < 3:  # reposabrazos entre sillas
            caja(f"brazo{k}", (0.02, 0.16, 0.012), (cx + 0.2, 0.08, zs + 0.07), gr, bisel=0.004, padre=r)
            caja(f"brazo{k}_poste", (0.015, 0.015, 0.07), (cx + 0.2, 0.08, zs + 0.035), met, bisel=0.003, padre=r)
    # mesita con revistas a la derecha
    mx = 0.78
    caja("mesa_tablero", (0.3, 0.22, 0.015), (mx, 0.05, 0.1), mat("madera_clara", color=(0.72, 0.58, 0.4), rug=0.6),
         bisel=0.005, padre=r)
    for sx in (-1, 1):
        for sy in (-1, 1):
            cilindro(f"mesa_pata{sx}{sy}", 0.008, 0.095, (mx + sx * 0.12, 0.05 + sy * 0.08, 0.048), met, lados=10, padre=r)
    cols = ((0.85, 0.2, 0.2), (0.2, 0.4, 0.85), (0.95, 0.8, 0.2))
    for i, c in enumerate(cols):
        caja(f"revista{i}", (0.1, 0.13, 0.004), (mx - 0.06 + i * 0.05, 0.03 + i * 0.02, 0.11 + i * 0.004),
             mat(f"revista_{i}", color=c, rug=0.5), bisel=0.0, padre=r, giro=(0, 0, math.radians(-15 + i * 12)))
    # dispensador de turnos en un poste
    caja("turnos_poste", (0.02, 0.02, 0.3), (0.95, -0.38, 0.15), met, bisel=0.004, padre=r)
    caja("turnos_base", (0.12, 0.12, 0.012), (0.95, -0.38, 0.006), gr, bisel=0.004, padre=r)
    caja("turnos_caja", (0.07, 0.05, 0.08), (0.95, -0.38, 0.33), mat("rojo_turnos", color=(0.8, 0.12, 0.1), rug=0.45),
         bisel=0.01, padre=r)
    caja("turnos_papel", (0.03, 0.003, 0.04), (0.95, -0.407, 0.305), mat("papel", color=(0.97, 0.97, 0.95), rug=0.8),
         bisel=0.0, padre=r)
    # pantalla de turnos en la pared de atrás (sobre poste doble)
    for s in (-1, 1):
        cilindro(f"pantalla_poste{s}", 0.008, 0.45, (-0.25 + s * 0.18, 0.4, 0.225), met, lados=10, padre=r)
    caja("pantalla_marco", (0.42, 0.03, 0.18), (-0.25, 0.4, 0.5), gr, bisel=0.01, padre=r)
    pantalla_plano("pantalla", 0.38, 0.14, (-0.25, 0.383, 0.5), padre=r)
    # fuente de agua con garrafa
    fx = -0.98
    caja("fuente_cuerpo", (0.12, 0.12, 0.25), (fx + 0.06, -0.35, 0.125), mat("chasis"), bisel=0.012, padre=r)
    caja("fuente_bandeja", (0.08, 0.04, 0.01), (fx + 0.06, -0.415, 0.14), gr, bisel=0.003, padre=r)
    for i, c in enumerate(((0.2, 0.4, 0.9), (0.85, 0.15, 0.1))):
        cilindro(f"fuente_grifo{i}", 0.006, 0.02, (fx + 0.04 + i * 0.04, -0.415, 0.17), mat(f"grifo{i}", color=c, rug=0.4),
                 lados=10, giro=(math.radians(90), 0, 0), padre=r)
    cilindro("garrafa_fuente", 0.05, 0.11, (fx + 0.06, -0.35, 0.31), mat("garrafa_pl", color=(0.6, 0.8, 0.95), rug=0.1, alfa=0.45),
             lados=24, bisel=0.01, padre=r)
    cilindro("garrafa_agua_fuente", 0.046, 0.08, (fx + 0.06, -0.35, 0.3), mat("liq_agua_fuente", color=(0.35, 0.6, 0.95), rug=0.2),
             lados=24, padre=r)
    # cartel «turno» sin texto: icono de persona en la pantalla lo pinta el juego
    return r


def generador():
    """Grupo electrógeno diésel 2×2: bancada, bloque motor con culata y tapa de balancines, radiador con
    ventilador, depósito con indicador, tubo de escape con silencioso, cuadro de control y pegatinas."""
    r = vacio("generador")
    z = base_maquina(r, 2.0, CAL)
    gr, met, ch = mat("grafito"), mat("metal"), mat("chasis")
    amar = mat("amarillo")
    # bancada y depósito
    caja("deposito", (1.6, 1.2, 0.18), (0, 0.1, z + 0.09), ch, bisel=0.03, padre=r)
    caja("deposito_franja", (1.602, 0.05, 0.03), (0, -0.505, z + 0.13), amar, bisel=0.005, padre=r)
    cilindro("deposito_tapon", 0.05, 0.03, (0.55, 0.45, z + 0.195), gr, lados=20, bisel=0.006, padre=r)
    estriado("deposito_tapon_mol", 0.052, 0.02, 16, 0.004, gr, padre=r, pos=(0.55, 0.45, z + 0.2))
    # motor: bloque, culata, tapa de balancines con tornillos, cárter
    zm = z + 0.18
    caja("bloque", (0.8, 0.55, 0.38), (-0.15, 0.1, zm + 0.19), mat("motor_verde", color=(0.22, 0.42, 0.36), rug=0.5), bisel=0.03, padre=r)
    caja("carter", (0.7, 0.45, 0.06), (-0.15, 0.1, zm + 0.03), gr, bisel=0.015, padre=r)
    caja("culata", (0.78, 0.4, 0.12), (-0.15, 0.1, zm + 0.44), mat("motor_verde"), bisel=0.02, padre=r)
    caja("balancines", (0.7, 0.3, 0.08), (-0.15, 0.1, zm + 0.54), mat("tapa_roja", color=(0.75, 0.1, 0.08), rug=0.35), bisel=0.02, padre=r)
    for k in range(6):
        tornillo(f"balancin_torn{k}", (-0.45 + k * 0.12, -0.035, zm + 0.58), r, r=0.012, normal="+Z")
    # pistones visibles (tapa abierta por arriba en la parte trasera: 4 cilindros con varilla)
    for k in range(4):
        x = -0.42 + k * 0.18
        cilindro(f"camisa{k}", 0.055, 0.04, (x, 0.32, zm + 0.42), met, lados=20, padre=r)
        p = vacio(f"piston_{k}", (x, 0.32, zm + 0.44), r)
        cilindro(f"piston_{k}_cabeza", 0.05, 0.05, (0, 0, 0.02), mat("cromo", color=(0.85, 0.86, 0.88), metal=1.0, rug=0.2),
                 lados=20, bisel=0.006, padre=p)
    # colector de admisión y filtro de aire
    cilindro("filtro_aire", 0.12, 0.16, (-0.15, -0.3, zm + 0.5), mat("filtro", color=(0.15, 0.17, 0.18), rug=0.6), lados=28,
             bisel=0.01, giro=(math.radians(90), 0, 0), padre=r)
    estriado("filtro_aire_aletas", 0.125, 0.14, 24, 0.008, gr, padre=r, pos=(-0.15, -0.23, zm + 0.5)).rotation_euler = (math.radians(90), 0, 0)
    # radiador con rejilla y ventilador (lado +X)
    rx = 0.55
    caja("radiador_marco", (0.1, 0.8, 0.7), (rx, 0.1, zm + 0.35), gr, bisel=0.02, padre=r)
    for k in range(12):
        caja(f"radiador_lama{k}", (0.11, 0.7, 0.012), (rx + 0.002, 0.1, zm + 0.06 + k * 0.05), met, bisel=0.002, padre=r)
    v = vacio("ventilador", (rx - 0.1, 0.1, zm + 0.35), r)
    v.rotation_euler = (0, math.radians(90), 0)
    cilindro("vent_buje", 0.05, 0.05, (0, 0, 0), gr, lados=20, bisel=0.008, padre=v)
    for k in range(6):
        a = k * math.tau / 6
        caja(f"vent_pala{k}", (0.24, 0.07, 0.01), (math.cos(a) * 0.14, math.sin(a) * 0.14, 0), mat("pala_negra", color=(0.08, 0.09, 0.09), rug=0.4),
             bisel=0.004, padre=v, giro=(math.radians(25), 0, a))
    tubo_curvo("manguera_rad", [(rx - 0.05, -0.2, zm + 0.6), (0.3, -0.22, zm + 0.62), (0.15, -0.1, zm + 0.5)], 0.025, mat("goma"), padre=r)
    # escape con silencioso y tubo vertical (nodo «escape»: el juego le pone humo)
    tubo_curvo("colector_escape", [(-0.55, 0.15, zm + 0.42), (-0.68, 0.2, zm + 0.45), (-0.72, 0.45, zm + 0.5)], 0.035,
               mat("escape", color=(0.35, 0.22, 0.16), metal=0.6, rug=0.6), padre=r)
    cilindro("silencioso", 0.09, 0.4, (-0.72, 0.55, zm + 0.5), mat("escape"), lados=24, bisel=0.02, giro=(0, math.radians(90), math.radians(90)), padre=r)
    for s in (-1, 1):
        caja(f"silencioso_abrazadera{s}", (0.03, 0.2, 0.2), (-0.72, 0.55 + s * 0.12, zm + 0.5), met, bisel=0.01, padre=r,
             giro=(math.radians(90), 0, 0))
    cilindro("chimenea", 0.04, 0.6, (-0.72, 0.78, zm + 0.8), mat("escape"), lados=20, padre=r)
    cilindro("chimenea_boca", 0.05, 0.04, (-0.72, 0.78, zm + 1.1), gr, lados=20, padre=r)
    vacio("escape", (-0.72, 0.78, zm + 1.14), r)
    # cuadro de control con pantalla, interruptor rojo y manómetros
    caja("cuadro", (0.4, 0.12, 0.45), (0.45, -0.75, z + 0.4), ch, bisel=0.02, padre=r)
    caja("cuadro_poste", (0.08, 0.08, 0.2), (0.45, -0.7, z + 0.1), gr, bisel=0.01, padre=r)
    pantalla_plano("pantalla", 0.22, 0.12, (0.45, -0.812, z + 0.5), padre=r)
    cilindro("cuadro_seta", 0.035, 0.03, (0.33, -0.82, z + 0.28), mat("seta_roja", color=(0.85, 0.08, 0.06), rug=0.35), lados=20,
             bisel=0.008, giro=(math.radians(90), 0, 0), padre=r)
    manometro("mano_aceite", (0.55, -0.815, z + 0.3), r, r=0.04)
    for k in range(4):
        tornillo(f"cuadro_torn{k}", (0.27 + (k % 2) * 0.36, -0.812, z + 0.2 + (k // 2) * 0.4), r, r=0.008)
    # cableado al cuadro
    tubo_curvo("cable_cuadro", [(0.2, -0.15, zm + 0.1), (0.35, -0.5, z + 0.05), (0.45, -0.7, z + 0.2)], 0.015,
               mat("cable_negro", color=(0.06, 0.06, 0.07), rug=0.6), padre=r)
    # pegatinas: peligro eléctrico y la P de la empresa
    if CAL:
        for nombre, w, pos in (("peligro_electrico", 0.14, (-0.15, -0.176, zm + 0.25)),):
            ruta = os.path.join(CAL, nombre + ".png")
            if os.path.exists(ruta):
                calcomania("pegatina_" + nombre, w, w, pos, mat_calcomania(nombre, ruta, recorte=True), padre=r)
    torre_luces((-0.75, -0.75, z), r)
    return r


def biogas():
    """Generador de biogás de sangre 2×2: digestor de acero con mirilla (sangre burbujeando dentro),
    tolva de entrada de tubos, gasómetro con cúpula, antorcha de quemado con llama y motor-generador."""
    r = vacio("biogas")
    z = base_maquina(r, 2.0, CAL)
    gr, met, ch = mat("grafito"), mat("metal"), mat("chasis")
    acero = mat("acero_inox", color=(0.72, 0.74, 0.76), metal=0.85, rug=0.3)
    # digestor
    dx, dy = -0.35, 0.1
    cilindro("digestor", 0.5, 0.75, (dx, dy, z + 0.375), acero, lados=48, bisel=0.02, padre=r)
    for k in range(3):
        toro(f"digestor_aro{k}", 0.505, 0.012, (dx, dy, z + 0.12 + k * 0.25), met, padre=r)
    esfera("digestor_techo", 0.5, (dx, dy, z + 0.75), acero, padre=r, media=True, escala=(1, 1, 0.35))
    # mirilla con la sangre dentro (nodo «liquido» para el nivel)
    caja("mirilla_marco", (0.06, 0.2, 0.4), (dx + 0.48, dy - 0.1, z + 0.4), gr, bisel=0.015, padre=r, giro=(0, 0, math.radians(-12)))
    caja("mirilla_vidrio", (0.065, 0.16, 0.36), (dx + 0.485, dy - 0.1, z + 0.4), mat("cristal", color=(0.75, 0.9, 0.95), rug=0.05, alfa=0.2),
         bisel=0.004, padre=r, giro=(0, 0, math.radians(-12)))
    liq = vacio("liquido", (dx + 0.47, dy - 0.1, z + 0.22), r)
    caja("liquido_sangre", (0.05, 0.15, 0.34), (0, 0, 0.17), mat("liq_sangre_bio", color=(0.3, 0.01, 0.02), rug=0.25), bisel=0.002,
         padre=liq, giro=(0, 0, math.radians(-12)))
    for k in range(8):
        tornillo(f"mirilla_torn{k}", (dx + 0.5, dy - 0.2 + (k % 2) * 0.2, z + 0.22 + (k // 2) * 0.12), r, r=0.007, normal="+X")
    # agitador arriba (motor que gira)
    caja("agitador_motor", (0.16, 0.16, 0.14), (dx, dy, z + 0.98), gr, bisel=0.02, padre=r)
    ag = vacio("agitador", (dx, dy, z + 1.07), r)
    for k in range(4):
        caja(f"agitador_aleta{k}", (0.12, 0.02, 0.03), (math.cos(k * math.pi / 2) * 0.07, math.sin(k * math.pi / 2) * 0.07, 0), met,
             bisel=0.004, padre=ag, giro=(0, 0, k * math.pi / 2))
    # tolva de entrada de tubos (boca por -X)
    caja("tolva", (0.3, 0.35, 0.12), (-0.85, 0.1, z + 0.55), ch, bisel=0.02, padre=r)
    caja("tolva_boca", (0.22, 0.26, 0.02), (-0.85, 0.1, z + 0.615), mat("negro_mate", color=(0.05, 0.055, 0.06), rug=0.7), bisel=0.0, padre=r)
    tubo_curvo("tolva_bajante", [(-0.85, 0.1, z + 0.5), (-0.8, 0.1, z + 0.35), (dx - 0.48, dy, z + 0.3)], 0.05, ch, padre=r)
    puerto_lamas("boca_entrada", -1, -0.99, z + 0.2, r, ancho=0.3, alto=0.2, y=-0.5, z_flecha=z + 0.002)
    # gasómetro: cúpula de lona sobre anillo
    gx, gy = 0.45, 0.45
    cilindro("gasometro_anillo", 0.36, 0.12, (gx, gy, z + 0.06), gr, lados=40, bisel=0.01, padre=r)
    esfera("gasometro_cupula", 0.35, (gx, gy, z + 0.12), mat("lona_verde", color=(0.3, 0.48, 0.32), rug=0.85), padre=r, media=True,
           escala=(1, 1, 0.75))
    for k in range(8):
        a = k * math.tau / 8
        caja(f"gasometro_cincha{k}", (0.012, 0.012, 0.3), (gx + math.cos(a) * 0.3, gy + math.sin(a) * 0.3, z + 0.25), mat("cincha", color=(0.9, 0.75, 0.15)),
             bisel=0.002, padre=r, giro=(math.cos(a + math.pi / 2) * 0.6, math.sin(a + math.pi / 2) * 0.6, 0))
    tubo_curvo("tubo_gas", [(dx + 0.2, dy + 0.1, z + 0.85), (0.1, 0.3, z + 0.8), (gx - 0.1, gy, z + 0.38)], 0.03,
               mat("tubo_amarillo"), padre=r)
    # antorcha de quemado con llama (nodo «llama»)
    ax, ay = 0.82, -0.2
    cilindro("antorcha_mastil", 0.035, 1.1, (ax, ay, z + 0.55), met, lados=16, padre=r)
    cilindro("antorcha_cabeza", 0.06, 0.12, (ax, ay, z + 1.16), gr, lados=20, bisel=0.01, padre=r)
    ll = vacio("llama", (ax, ay, z + 1.24), r)
    esfera("llama_nucleo", 0.06, (0, 0, 0.05), mat("llama", color=(1.0, 0.55, 0.1), rug=1.0, emision=(1.0, 0.5, 0.1), fuerza=6.0),
           padre=ll, escala=(1, 1, 2.2))
    esfera("llama_azul", 0.04, (0, 0, 0.0), mat("llama_azul", color=(0.3, 0.5, 1.0), rug=1.0, emision=(0.3, 0.5, 1.0), fuerza=4.0),
           padre=ll, escala=(1, 1, 1.3))
    for k in range(3):
        cilindro(f"antorcha_viento{k}", 0.008, 0.25, (ax, ay, z + 0.25 + k * 0.3), met, lados=8, padre=r,
                 giro=(math.radians(60), 0, k * 2.1))
    # motor-generador pequeño con cuadro
    caja("motogen", (0.5, 0.35, 0.3), (0.35, -0.5, z + 0.15), mat("motor_verde", color=(0.22, 0.42, 0.36), rug=0.5), bisel=0.025, padre=r)
    caja("motogen_alternador", (0.2, 0.3, 0.28), (0.66, -0.5, z + 0.15), ch, bisel=0.03, padre=r)
    for k in range(6):
        caja(f"motogen_aleta{k}", (0.012, 0.32, 0.3), (0.58 + k * 0.025, -0.5, z + 0.15), met, bisel=0.002, padre=r)
    caja("cuadro_bio", (0.3, 0.08, 0.3), (-0.2, -0.82, z + 0.35), ch, bisel=0.015, padre=r)
    pantalla_plano("pantalla", 0.2, 0.1, (-0.2, -0.862, z + 0.4), padre=r)
    caja("cuadro_bio_poste", (0.06, 0.06, 0.2), (-0.2, -0.78, z + 0.1), gr, bisel=0.01, padre=r)
    manometro("mano_gas", (-0.1, -0.865, z + 0.28), r, r=0.035)
    torre_luces((0.82, -0.82, z), r)
    return r


def main():
    global CAL
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else [".", "."]
    salida, CAL = args[0], args[1]
    os.makedirs(salida, exist_ok=True)
    for nombre, fn in (("sala_espera", sala_espera), ("generador", generador), ("biogas", biogas)):
        limpiar(); comun._mats.clear()
        fn()
        exportar(os.path.join(salida, nombre + ".glb"))
        print("PIEZA", nombre)


if __name__ == "__main__":
    main()
