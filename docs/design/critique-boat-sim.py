"""Boat slalom sim: boat.gd step() (runabout, SPEED_SCALE 1.9) through boat_race.json rings, no banks/waves.
usage: python3 -I boat.py <boat_race.json>"""
import json,math,sys
d=json.load(open(sys.argv[1])); R=d['rings']; flow=(d['flow'][0],d['flow'][1]); grid=d['grid'][0]
TOP=21*1.9; PULL=6.5*1.9; TURN=1.55*1.3; PLANE=9*1.3; G0,G1=1.1,3.2
def ss(a,b,x):
    t=max(0,min(1,(x-a)/(b-a))); return t*t*(3-2*t)
def run(lag=0.0, look=True, boosts=True, gain=2.4, brake=False, aim_off=0.0, mult=1.0):
    dt=1/60; x,z=grid; yaw=math.atan2(R[0]['x']-x,R[0]['z']-z); vx=vz=0.0; yr=0; t=0; nxt=0; miss=0; rhythm=0; gold=0
    steer_q=[]; minv=99; maxv=0; slide=0; offs=[]
    while nxt<len(R) and t<400:
        g=R[nxt]; ax,az=g['x'],g['z']
        if aim_off: # aim at the inside edge share
            ax+=math.cos(g['yaw'])*aim_off; az+=-math.sin(g['yaw'])*aim_off
        dd=math.hypot(ax-x,az-z); wx,wz=ax,az
        sp=math.hypot(vx,vz)
        if look and nxt+1<len(R):
            lk=6+sp*.55
            if dd<lk:
                k=min(.6,(lk-dd)/lk); wx=ax+(R[nxt+1]['x']-ax)*k; wz=az+(R[nxt+1]['z']-az)*k
        err=(math.atan2(wx-x,wz-z)-yaw+math.pi)%(2*math.pi)-math.pi
        steer_q.append(max(-1,min(1,err*gain)))
        steer=steer_q[0] if len(steer_q)<=int(lag*60) else steer_q.pop(0)
        fx,fz=math.sin(yaw),math.cos(yaw); rx,rz=fz,-fx
        relx,relz=vx-flow[0],vz-flow[1]; vf=relx*fx+relz*fz; vr=relx*rx+relz*rz
        boost=(1+.03*min(rhythm,5))*(1.18 if gold>0 else 1) if boosts else 1
        top=TOP*boost*mult; gold=max(0,gold-dt)
        if vf<top: vf+=PULL*(1-min(1,max(0,vf/top))**2)*dt
        vf-=vf*.06*dt
        if vf>top: vf+= (top-vf)*(1-math.exp(-1.5*dt))
        pl=ss(PLANE*.45,PLANE,abs(vf)); vr*=math.exp(-(G0+(G1-G0)*pl)*dt)
        vf-=abs(yr)*abs(vf)*.06*dt
        auth=min(1,abs(vf)/5)*(1-.3*max(0,min(1,(abs(vf)-24)/20)))
        yr+= (TURN*steer*auth-yr)*(1-math.exp(-6*dt)); yaw+=yr*dt
        px,pz=x,z
        vx=fx*vf+rx*vr+flow[0]; vz=fx*0+fz*vf+rz*vr+flow[1]
        x+=vx*dt; z+=vz*dt; t+=dt
        if t>6: minv=min(minv,vf); maxv=max(maxv,vf); slide=max(slide,abs(vr))
        f=(math.sin(g['yaw']),math.cos(g['yaw'])); s0=(px-g['x'])*f[0]+(pz-g['z'])*f[1]; s1=(x-g['x'])*f[0]+(z-g['z'])*f[1]
        if s0<0<=s1:
            ac=abs((x-g['x'])*f[1]-(z-g['z'])*f[0])
            if g['gold']:
                if ac<=g['w']/2-.4: gold=2.5
            elif ac<=g['w']/2-.4: rhythm+=1; offs.append(ac)
            else: miss+=1; rhythm=0
            nxt+=1
    return t,miss,minv*3.6,maxv*3.6,slide,max(offs) if offs else 0, sum(offs)/len(offs)
for name,kw in [('full gas, aim centre, look-past',{}),('full gas, no look-past',dict(look=False)),
  ('full gas, 0.15 s thumb lag',dict(lag=.15)),('full gas, 0.30 s lag, no look-past',dict(lag=.3,look=False)),
  ('full gas, 0.30 s lag, weak steer gain 1.0',dict(lag=.3,look=False,gain=1.0)),
  ('no boosts',dict(boosts=False)),('top x1.25 (60 % more speed felt)',dict(mult=1.25)),('top x1.5',dict(mult=1.5))]:
    t,m,mn,mx,sl,mo,ao=run(**kw); print('%-44s %.1f s  misses %d  speed %.0f-%.0f km/h  max slide %.1f m/s  worst pass %.1f m off centre (avg %.1f) of 11.6'%(name,t,m,mn,mx,sl,mo,ao))
