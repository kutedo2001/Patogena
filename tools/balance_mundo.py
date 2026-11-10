"""Equilibrado del mundo (V1.10): réplica en Python de scripts/sim/mundo.gd con un calendario de mejoras
y ventas de un jugador normal, lento (×1,5) y rápido (×0,7). Uso: python3 tools/balance_mundo.py CB VIA CURA POR_CAJA ZF
Valores actuales: 0.00003 0.0000006 0.0001 0.002 1 (la zombificación ya va escalada en el JSON)."""
import json, math
d=json.load(open('/home/claude/patogena/datos/fabrica.json'))
M={m['id']:m for m in d['cepa']['mejoras']}
REG=d['mundo']['regiones']
def sim(CB, VIA, CURA, PORCAJA, sched, ventas, horas=12, log=False):
    regs=[dict(r, s=r['pob'], i=0.0, z=0.0) for r in REG]
    cura=0; det=False; hechas=[]; t=0; dt=5.0
    dest_i=0
    out=None
    while t<horas*3600:
        while sched and sched[0][0]*60<=t:
            hechas.append(sched.pop(0)[1])
        e={"contagio":0,"deteccion":0,"zombificacion":0,"resistencia":0,"frio":0,"calido":0,"humedo":0}
        for h in hechas:
            for k,v in M[h]['efecto'].items(): e[k]+=v
        v=ventas(t)
        if v>0:
            # rota destinos por las 4 regiones más pobladas cada 10 min
            r=regs[[7,8,5,9,2,0][int(t/600)%6]]
            n=min(v*dt*PORCAJA, r['s']); r['s']-=n; r['i']+=n
        c=CB*(1+e['contagio']*3)
        via=sum(r['i']+r['z']*0.5 for r in regs)
        for r in regs:
            cm={'frio':1 if e['frio'] else .35,'calido':1 if e['calido'] else .45,'humedo':1 if e['humedo'] else .55}.get(r['clima'],1)
            act=r['i']+r['z']*1.5
            nu=c*cm*act*r['s']/r['pob']*dt + VIA*(1+e['contagio'])*via*r['s']/r['pob']*dt*cm
            nu=min(nu,r['s']); r['s']-=nu; r['i']+=nu
            conv=min(r['i'], e['zombificacion']*ZF*r['i']*dt); r['i']-=conv; r['z']+=conv
        tot=sum(r['pob'] for r in regs)
        if not det and sum(r['i']+r['z'] for r in regs)>=1: det=True
        if det:
            inv=sum(r['riqueza']*r['s'] for r in regs)/tot
            dd=min(max(0.35+e['deteccion'],0.1),1.5)
            cura=min(1,cura+CURA*dd*inv*2/(1+e['resistencia']*1.5)*dt)
        zf=sum(r['z'] for r in regs)/tot; inf=sum(r['i']+r['z'] for r in regs)/tot
        if log and int(t)%1800==0: print(f"{t/3600:4.1f}h inf {inf*100:6.2f}% z {zf*100:6.2f}% cura {cura*100:5.1f}% mej {len(hechas)}")
        if zf>=0.9: return ('gana',t/3600,cura)
        if cura>=1: return ('pierde',t/3600,zf)
        t+=dt
    return ('nada',t/3600,zf,cura)
# calendario estimado (min) de mejoras para un jugador normal: 24 en ~7 h
orden=["tos","fiebre","frio","estornudos","nauseas","calor","agua","insomnio","humedad","ratas","mordisco","farmacos1",
 "mosquitos","hambre","farmacos2","aves","rabia","camuflaje","ganado","necrosis","bunker","aerosol","zombi_total","mutacion_genetica"]
mins=[6,15,25,45,60,75,95,110,125,145,165,185,210,230,250,275,300,320,345,370,390,410,430,450]
def ventas(t):
    m=t/60
    if m<28: return 0
    return min(0.5+ (m-28)/60*1.0, 8)   # cajas/s
import sys
CB,VIA,CURA,PC,ZF=[float(x) for x in sys.argv[1:6]]
print(sim(CB,VIA,CURA,PC,list(zip(mins,orden)),ventas,log=True))
# jugador lento (x1.5 tiempo)
print('lento',sim(CB,VIA,CURA,PC,list(zip([m*1.5 for m in mins],orden)),lambda t: ventas(t/1.5)))
print('rapido',sim(CB,VIA,CURA,PC,list(zip([m*0.7 for m in mins],orden)),lambda t: ventas(t/0.7)))
