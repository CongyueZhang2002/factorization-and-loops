from pathlib import Path
import mpmath as mp,json,time
mp.mp.dps=120
cases=[[-2,-3,-7],[-2,-3,-1],[3,-2,-1],[3,-2,-2],[-2,-3,7],[2,3,8],[2,-3,0]]
tiny=mp.mpf('1e-100')
def box(s,t,m,e):
 u=m-s-t
 y1=-u/s;y2=-u/t
 sign=mp.sign(u/(s*t))
 rg=mp.gamma(1+e)*mp.gamma(1-e)**2/mp.gamma(1-2*e)
 value=(mp.mpc(y1,-tiny*sign)**(-e)*mp.hyp2f1(1,-e,1-e,mp.mpc(y1,tiny*mp.sign(y1-y2)))
       +mp.mpc(y2,-tiny*sign)**(-e)*mp.hyp2f1(1,-e,1-e,mp.mpc(y2,tiny*mp.sign(y2-y1))))
 if m:
  y3=-u*m/(s*t)
  value-=mp.mpc(y3,-tiny*sign)**(-e)*mp.hyp2f1(1,-e,1-e,mp.mpc(y3,tiny))
 return 2*rg/(e**2*s*t)*mp.mpc(u/(s*t),tiny)**e*value
out=[]
start=time.monotonic()
for inputs in cases:
 s,t,m=map(mp.mpf,inputs)
 # The generic hypergeometric formula cannot be substituted term by term
 # at a removable X=1 surface: its divergent summands share a kinematic
 # limiting ratio. Approach the full assembled integral before expansion.
 u=m-s-t
 if -u/s==1 or -u/t==1 or (m and -u*m/(s*t)==1):
  t+=mp.mpf('1e-40')
 radius=mp.mpf('0.01');count=48
 samples=[]
 for k in range(count):
  phase=mp.e**(2j*mp.pi*k/count);e=radius*phase
  samples.append((phase,e**2*box(s,t,m,e)))
 coefficients=[]
 for n in range(5):
  value=sum(v/phase**n for phase,v in samples)/(count*radius**n)
  coefficients.append({'Order':n-2,'Real':mp.nstr(value.real,45),'Imaginary':mp.nstr(value.imag,45)})
 out.append({'Invariants':inputs,'Coefficients':coefficients})
 print(inputs,flush=True)
path=Path(__file__).with_name('MasslessBoxCausalReferences.json')
path.write_text(json.dumps({'Method':'Cauchy coefficients of the correlated causal hypergeometric expression, arXiv2211.14110 Eq35','WorkingPrecision':120,'RemovableDiagonalApproach':'t -> t + 10^-40 before evaluating the generic integral; artificial causal infinitesimal 10^-100','CauchyRadius':'0.01','Samples':48,'Rows':out},indent=2))
print('COMPLETED REFERENCES',time.monotonic()-start,flush=True)
