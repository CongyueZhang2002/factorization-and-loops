"""Known-support reconstruction microbenchmark, not a numerical-IBP benchmark.

Targets are saved exact DE entries. Denominators and numerator support are given
to BOTH methods. The oracle evaluates those saved expressions, not physical
integrals. Exact reference equality is used only after candidate recovery.
"""
from pathlib import Path
import json, os, signal, sys, time
import mpmath as mp
import sympy as sp
from sympy.parsing.mathematica import parse_mathematica

root=Path('/home/maxzhang/factorization-and-loops')
os.sched_setaffinity(0,{7})
started=time.monotonic()
source=root/'Projects/EE_EEC/Raw/NNLO/q-qb/DoubleReal/Work/Components/IdenticalQuarks/Work/DifferentialSystem.wl'
text=source.read_text(); start=text.index('{',text.index('"ConnectionMatrices"'))
depth=0
for end in range(start,len(text)):
    depth+=(text[end]=='{')-(text[end]=='}')
    if depth==0: break
matrix=parse_mathematica(text[start:end+1])[0]
D,z,Q2=sp.symbols('D z Q2')
entries=[]
for i,row in enumerate(matrix):
    for j,value in enumerate(row):
        if value==0: continue
        expr=sp.cancel(value.subs(Q2,1));num,den=sp.fraction(expr)
        poly=sp.Poly(num,D,z)
        if not all(c.is_Integer for c in poly.coeffs()): continue
        if 3<=len(poly.terms())<=24 and max(abs(int(c)) for c in poly.coeffs())<10**9:
            entries.append((i+1,j+1,expr,poly,den))
chosen=[]
for n in (4,8,16):
    candidate=min(entries,key=lambda r:abs(len(r[3].terms())-n))
    if candidate[:2] not in [r[:2] for r in chosen]:chosen.append(candidate)

def alarm(*_): raise TimeoutError('15 second recognition limit')
signal.signal(signal.SIGALRM,alarm)

def solve_mod(a,b,p):
    a=[[(int(v)%p) for v in row]+[int(rhs)%p] for row,rhs in zip(a,b)]
    for k in range(len(b)):
        pivot=next(i for i in range(k,len(b)) if a[i][k])
        a[k],a[pivot]=a[pivot],a[k]
        inv=pow(a[k][k],-1,p);a[k]=[(v*inv)%p for v in a[k]]
        for i in range(len(b)):
            if i!=k:
                f=a[i][k]
                a[i]=[(u-f*v)%p for u,v in zip(a[i],a[k])]
    return [row[-1] if row[-1]<=p//2 else row[-1]-p for row in a]

results=[]
extension=any(flag in sys.argv for flag in ('--higher-precision','--more-steps'))
if extension:chosen=chosen[-1:]
for i,j,expr,poly,den in chosen:
    support=poly.monoms();truth=[int(c) for c in poly.coeffs()];n=len(support)
    oracle=sp.lambdify((D,z),expr,'mpmath')
    denominator=sp.lambdify((D,z),den,'mpmath')
    for digits in ((160,) if '--more-steps' in sys.argv else (320,) if extension else (80,160)):
        with mp.workdps(digits+30):
            x,y=mp.pi,mp.log(2)/2
            t=time.monotonic();value=denominator(x,y)*oracle(x,y)
            vector=[value]+[x**a*y**b for a,b in support]
            evaluation=time.monotonic()-t;t=time.monotonic();signal.alarm(15)
            try:
                relation=mp.pslq(mp.matrix(vector),tol=mp.mpf(10)**(-digits),maxcoeff=10**9,maxsteps=12000 if extension else 3000)
                candidate=([-sp.Rational(v,relation[0]) for v in relation[1:]]
                           if relation and relation[0] else None)
                passed=candidate==truth
                status='ExactReferenceEquality' if passed else 'NoCorrectCandidate'
            except TimeoutError:
                status='RecognitionTimeLimit';relation=None;passed=False
            finally:signal.alarm(0)
            result={'Entry':[i,j],'Terms':n,'Method':'PSLQ','ReliableDigitsRequested':digits,
                    'IterationLimit':12000 if extension else 3000,
                    'OracleSeconds':evaluation,'ReconstructionSeconds':time.monotonic()-t,
                    'Status':status,'Relation':relation,'ExactReferenceEquality':passed}
            results.append(result);print(json.dumps(result),flush=True)
    if extension:continue
    # One prime suffices only because the declared numerator coefficients are
    # integers of magnitude <10^9, far below p/2. No unknown denominator claim.
    p=2**61-1;t=time.monotonic();a=[];b=[]
    for k in range(n):
        x=pow(3,k+1,p);y=pow(5,k+1,p)
        row=[pow(x,u,p)*pow(y,v,p)%p for u,v in support]
        a.append(row);b.append(sum(c*v for c,v in zip(truth,row))%p)
    evaluation=time.monotonic()-t;t=time.monotonic()
    candidate=solve_mod(a,b,p)
    result={'Entry':[i,j],'Terms':n,'Method':'KnownSupportFiniteField','Prime':p,
            'OracleSeconds':evaluation,'ReconstructionSeconds':time.monotonic()-t,
            'ExactReferenceEquality':candidate==truth}
    results.append(result);print(json.dumps(result),flush=True)

report={'Scope':'Known denominator and exact sparse numerator support; saved-expression oracle, not numerical IBP or physical integral evaluation.',
        'Reference':str(source),'SetupAndTotalSeconds':time.monotonic()-started,
        'CoefficientHeightBound':10**9,'Results':results,
        'ProductionSpeedupEstablished':False,'ProductionMethodChanged':False}
output=root/'Projects/EE_EEC/Raw/NNLO/q-qb/DoubleReal/Work/Components/IdenticalQuarks/Work/CoefficientReconstructionBenchmark.json'
if extension:
    previous=json.loads(output.read_text())
    report['Results']=previous['Results']+results
    for row in report['Results']:
        if row['Method']=='PSLQ':row.setdefault('IterationLimit',12000 if row['ReliableDigitsRequested']==320 else 3000)
    report['InitialRunSeconds']=previous['SetupAndTotalSeconds']
    report['ExtensionRunSeconds']=report['SetupAndTotalSeconds']
    report['SetupAndTotalSeconds']+=previous['SetupAndTotalSeconds']
output.write_text(json.dumps(report,indent=2)+'\n')
print('COEFFICIENT RECONSTRUCTION BENCHMARK COMPLETE',flush=True)
