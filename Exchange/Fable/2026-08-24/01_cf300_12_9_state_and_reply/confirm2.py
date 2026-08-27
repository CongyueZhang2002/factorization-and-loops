"""Confirm the integrability repair at a second (prime, eps) image."""
import sys, time
import numpy as np
import wlparse as W, mqsolve as M, run_diag as R, sweep as SW, curl2 as CU
T0=time.time(); SW.T0=T0; R.T0=T0; log=SW.log
R1='Sqrt[1-2*x+x^2+2*y+2*x*y+y^2]'; R2='Sqrt[1-4*x*y]'
p=int(sys.argv[1]); en=int(sys.argv[2]); ed=int(sys.argv[3]); npts=int(sys.argv[4])
epsv=en*pow(ed,p-2,p)%p
S=R.load(); pts=R.make_points(S,npts,p,epsv,seed=31337+p%43)
log('image p=%d eps=%d/%d, %d points -> %d rows'%(p,en,ed,npts,16*npts))
cache=CU.Cache(S,pts,p); b=cache.rhs()
base=np.concatenate([cache.columns(S,w) for w in S.one_forms],axis=1)
ra,raug,_,_=M.ranks(base,b,p)
log('26 engine letters: cols %d rank %d rank[A|b] %d defect %d'%(base.shape[1],ra,raug,raug-ra))
SET=[('dlog(1-x-y-r1)','(1-x-y)-%s'%R1),('dlog(1-x+y-r1)','(1-x+y)-%s'%R1),
     ('dlog(1+2y-r2)','(1+2*y)-%s'%R2),('dlog(1-2xy-r2)','(1-2*x*y)-%s'%R2)]
cols=[cache.columns(S,('dlog',W.parse_expr(t))) for _,t in SET]
for k in range(1,5):
    A=np.concatenate([base]+cols[:k],axis=1)
    r_,rg_,_,_=M.ranks(A,b,p)
    log('  +%d letters (%s): cols %d rank %d rank[A|b] %d defect %d %s'
        %(k,SET[k-1][0],A.shape[1],r_,rg_,rg_-r_,'CONSISTENT' if r_==rg_ else 'inconsistent'))
