# GPT-6 Pro: independently integrated scalar box and native export coverage

Actual GPT-6 Pro completed the review after20m33s in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84 .
It inspected pushed revision5237887c135be376472b893ac0a8ba9d3c502394, and upstream
Kira tag3.1. This is a summary of the visible response, not a verbatim transcript.
It did not run our Wolfram code. No measured EEC hard coefficient was consulted.

## Source findings

The finite-meromorphy/prefactor and structure-label repairs are correctly wired.
A residual domain loophole remained: 1/(epsilon(a-b)) with assumptions a=b passed
the recursive coordinate-independent grammar. Reciprocal bases need a nonzero
meromorphic germ, and regulator-independent denominators must be finite on the
parameter domain. The repair also checks parameter coefficients in analytic
exponents; the new negative tests and all eight actual inclusive charts pass.

## Independent universal scalar result

Conventions: s=q^2>0, D=4-2epsilon, positive labeled three-particle phase space,
virtual loop measure d^Dk/(i pi^(D/2)), four +i0 denominators with chords
(0,p1,p1+p3,q), and an additional 1/s12. The resulting complex integral is U8.
Define the EXACT prefactor

N8=(4 pi)^(2epsilon) s^(-2-3epsilon)/
   (128 pi^3 Gamma(1-epsilon) Gamma(2-2epsilon)).

Then

U8=N8 exp(i pi epsilon) [5/(2 epsilon^4)-13 pi^2/(4 epsilon^2)
                       -89 Zeta(3)/epsilon-1297 pi^4/720+O(epsilon)].

Equivalently the bracket after expanding only the phase is
5/(2epsilon^4)+5i pi/(2epsilon^3)-9pi^2/(2epsilon^2)
+(-89Zeta(3)-11i pi^3/3)/epsilon-13pi^4/180-89i pi Zeta(3).
Expand N8 too when convolving Laurent coefficients. Do not replace it by N8(0)
or take a real projection before multiplying the generated amplitude coefficient.
No production catalog has yet been populated from this note.

### Exact higher-order representation

I1=B(-2e,-2e) B(-e,-2e) 3F2(-e,-e,-e;1-e,-3e;1).
Define
K=4F3(1,-e,-e,1+3e;1-e,1+e,1+e;1),
F(e,d)=3F2(-2e+d,-2e+d,1+2e+d;1-2e+d,1+2d;1),
Lambda=pi Cot(pi e)+2 PolyGamma(0,-2e)+1/(2e)+2 EulerGamma.
Then the previously unresolved inclusive Euler term is
I3=Gamma(-e)^3/Gamma(-3e) K
   -pi/(2 Sin(pi e)) (Lambda F(e,0)+Derivative_d F(e,d)|d=0).
Both convergent hypergeometric series have excess1; the derivative retains the
coalescing Mellin-Barnes pole families and cannot be omitted.

An auxiliary factor a^d b^-d in the phase-space simplex separates the three
right-pole families of the Mellin-Barnes representation at w=n and w=-e+-d+n.
Their sum followed by d->0 gives this identity. Expanding the convergent
Pochhammer summands into harmonic sums gives

I1=3/(2e^2)-(17/2)Zeta(2)-32Zeta(3)e-(363/8)Zeta(4)e^2+O(e^3),
I3=7/(4e^2)-(29/4)Zeta(2)-22Zeta(3)e-(215/16)Zeta(4)e^2+O(e^3).

U8=(4pi)^(2e)s^(-2-3e)/(128pi^3 Gamma(2-2e)) *
    exp(i pi e) (2 rGamma/e^2)(2 I1-I3),
rGamma=Gamma(1+e) Gamma(1-e)^2/Gamma(1-2e).
The coefficient of U8 in the actual reduction determines whether orders above
its finite term are required. The exact identity supplies that route; this
finite expansion is not automatically sufficient for every scalar coefficient.

### Local independent numerical check

The change a=u(1-v)/(1-uv), b=v(1-u)/(1-uv) gives the separate representation
I3=B(-2e,-2e) integral_0^1 r^(-1-e)(1-r)^(-1-2e)
   2F1(-2e,-2e;-4e;r) 2F1(-e,-e;1-e;r) dr.
At e=-1/4 our local mpmath check gives
closed:21.31764770940982094757463360046655951636,
Euler: 21.31764770940982094757323753734048514337,
absolute difference1.3961e-21,9.012s. Receipt:
Archive/Runs/2026-09-18/NLOEECChecks/UniversalInclusiveBoxI3.json.
This tests a universal scalar identity, not an EEC coefficient.

## Kira export semantics

Pro independently found the same upstream distinction: record_masters removes
identity masters from mandatory reconstruction targets; the exporter uses the
initial masters list to identify omitted identity rows; FireFly masters.final
contains reconstructed RHS identifiers only. Retain per-request identity
coverage and do not infer irreducibility from a missing rewrite rule.

Export-only inspection comes first. A genuine missing dependency can be solved
in a separate workspace with accepted exact rules appended or eliminated.
Explicit elimination avoids re-reconstructing known rows; never discard residual
columns to force a desired basis. Restore scale factors consistently:
if Ii=s^wi Ji, then Rij[J]=s^(wj-wi) Rij[I].

run_initiate:true with native state is valid only for the SAME mathematical job.
SYSTEMconfig can skip import, and FireFly's saved tags bind LHS/RHS assignments.
Changed equations or selection need a separate native workspace. Our new
DependencyReduction directories follow that rule. This review predates the
b8ba7a21 implementation and does not constitute a static review of that patch.
