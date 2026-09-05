# 83bb analytic master-family handoff

Status date: 2026-07-31

This document is the handoff record for the hardest of the three completed
NNLO master families (`83bb`, `f228`, and `d099`). It records both the analytic
argument and the implementation sequence needed to reproduce the exact
multiscale Laurent expansion. It is intended for a fresh Codex instance or a
different AI coding system that has not seen the exploratory conversation.

The scientific output is an exact function of the dimensionless invariants

```text
x = -t/s,   y = -u/s,   D = 4 - 2 eps,
```

through `eps^2`. Fixed-point AMFlow values are an independent check and are not
boundary data or part of the analytic construction.

## 1. Result in one paragraph

The physical reverse-unitarity family `ruTopology41` closes on eight masters.
Correct derivatives with respect to `s,t,u` give a flat two-variable system in
`x,y`. Its only non-Fuchsian obstruction is a rank-one double pole at
`1-x-y=0`; a rational Moser transformation exposes how to remove it, and
CANONICA produces an exact epsilon form with the six-letter alphabet

```text
{x, 1-x, y, 1-y, 1-x-y, (1-x)^2-y}.
```

The physical boundary must be derived as a separate `y=0+` cut family. Direct
substitution into the two-variable canonical transformation is wrong. The
boundary contains hard, collinear, and `x^(-2 eps)` regions. Because the
matching matrix has a simple `1/x` pole, the first subleading Frobenius
coefficient of every region is required. Six lower boundary masters reduce to
Beta/Gamma data. The last corner constant is a positive three-fold Euler
integral evaluated exactly with SubTropica. The canonical solution is then
transported along `(0,0) -> (x,0) -> (x,y)` in GPLs. The target master and the
other seven basis masters are exact through `eps^2`; the target agrees with an
independent AMFlow calculation coefficient by coefficient.

## 2. Family definition

### 2.1 Kinematics and cuts

The external momenta are massless and obey

```text
ka^2 = kb^2 = kc^2 = 0,
2 ka.kb = s,
-2 ka.kc = t,
-2 kb.kc = u.
```

The loop momenta are `ke,kf`. The nine denominator slots are

```text
D1 = ke^2                                      (cut)
D2 = kf^2                                      (cut)
D3 = (ka+kb-kc-ke-kf)^2                       (cut)
D4 = ka.kf                                     (basis completion)
D5 = kb.ke                                     (basis completion)
D6 = (ka+kb-kc-ke)^2
D7 = (ka+kb-kc-kf)^2
D8 = (ka-kc-kf)^2
D9 = (ka-ke)^2
```

The first three positions are protected cut slots. Their powers must stay
positive under reduction. Slots 4 and 5 complete the scalar-product basis but
have zero powers in every master below.

For an index vector `nu={nu1,...,nu9}`, write the corresponding cut integral as
`I[nu]`. The precise common loop-measure and cut normalization is carried
unchanged by the stored `FCTopology`, Kira family, boundary calculation, and
AMFlow manifest. Do not silently replace it by a different `2 Pi` convention.

### 2.2 Eight-master basis

The stable ordered basis is

```text
G1 = I[{1,1,1,0,0,0,0,0,0}]
G2 = I[{1,1,1,0,0,0,0,1,0}]
G3 = I[{1,1,1,0,0,0,0,1,1}]
G4 = I[{1,1,2,0,0,0,0,1,1}]
G5 = I[{1,1,1,0,0,1,0,1,0}]
G6 = I[{1,1,1,0,0,1,0,1,1}]
G7 = I[{1,1,1,0,0,1,1,1,1}]   target
G8 = I[{1,1,2,0,0,1,1,1,1}]
```

The doubled third cut in `G4` and `G8` is a derivative cut, not an ordinary
doubled propagator. Preserve that distinction in every interface.

## 3. Exact differential system

### 3.1 The derivative that must be used

The most important early failure mode was differentiating replacement symbols
`s,t,u` while holding loop-external scalar products fixed. That does not
differentiate the physical integral. The correct on-shell vector derivatives
are

```text
d/ds = (ka.d/dka + kb.d/dkb - kc.d/dkc)/(2 s)
d/dt = (ka.d/dka - kb.d/dkb + kc.d/dkc)/(2 t)
d/du = (-ka.d/dka + kb.d/dkb + kc.d/dkc)/(2 u)
```

They act on every occurrence of the external momenta in the propagators and
therefore differentiate loop-external scalar products consistently.

The implementation uses `FCLoopGLIDifferentiate` for the raw differentiated
integrals, `FCLoopCreateRulesToGLI` to return them to family notation, and
Kira through `FeynNLO`FeynKiraReduce` for the exact reduction.

### 3.2 Closure and consistency tests

Starting from the eight candidate masters, closure takes two iterations:

```text
iteration 1: 84 derivative targets, basis changes once
iteration 2: 87 derivative targets, stable eight-master basis
```

After extracting the mass dimension and setting `x=-t/s`, `y=-u/s`, the
system is

```text
dG = (Ax dx + Ay dy) G.
```

Do not proceed unless all of the following exact checks pass:

```text
row reconstruction                      0
homogeneity residual                    0
residual dependence on the scale s      none
d(Ay)/dx - d(Ax)/dy + Ay.Ax - Ax.Ay    0
```

The final pre-canonical matrices are `8 x 8` with 35 nonzero entries each.

## 4. From the coupled top block to epsilon form

At `eps=0`, six sectors are scalar and the top sector is a coupled `2 x 2`
block. The zero-order fundamental matrix is rational apart from

```text
Log[x/(1-x)] + Log[y/(1-y)].
```

The only non-Fuchsian singularity is a rank-one double pole on
`1-x-y=0`. A useful near-identity Moser transformation for the top block is

```text
M = IdentityMatrix[2]
  + 2 eps y (y-1) (2+3 eps)/((1+eps) (x+y-1)) E21.
```

It cancels the double-pole residual in both differential matrices and leaves
the flatness residual zero. This transformation is a diagnostic certificate
of the obstruction; CANONICA subsequently finds the full eight-dimensional
rational transformation.

With `G = T F`, the canonical basis satisfies

```text
dF = eps Sum[Ra dLog[phi_a]] F,
```

where the six positive physical letters are

```text
phi = {x, 1-x, y, 1-y, 1-x-y, (1-x)^2-y}.
```

The constant residue matrices are stored in
`SummarizeCANONICA83bbFull.wl`. Their exact dlog reconstruction is zero, and
`CheckEpsForm` is `True`. The physical chamber used later is

```text
0 < y < (1-x)^2 < 1-x < 1.
```

No nonzero letter vanishes or changes sign along the chosen transport path.

## 5. Boundary problem

### 5.1 Do not substitute `y=0` into the full transformation

The limit is nonuniform. Substituting `y->0` into the two-variable CANONICA
transformation misses boundary regions; in the actual audit, none of the
substituted rows obeyed the independently derived boundary differential
equation.

Instead impose the physical boundary relation

```text
kc = x kb,   y -> 0+,
```

at the integral-family level, construct the boundary topology, differentiate
that family, and reduce it separately. The resulting seven-master basis is

```text
B1 = G1110000   B2 = G1110010   B3 = G1110011
B4 = G1120000   B5 = G1120010   B6 = G1111010
B7 = G1111111.
```

The first six equations do not contain `B7`.

### 5.2 Three endpoint regions

Let the boundary system near `x=0` be

```text
dB/dx = (Aminus1/x + A0 + O[x]) B.
```

The corrected boundary contains three regions:

```text
hard        x^0
collinear   x^(-eps)
minus-two   x^(-2 eps)
```

Their leading vectors obey

```text
Aminus1.bHard = 0
(Aminus1 + eps IdentityMatrix[7]).bCollinear = 0
(Aminus1 + 2 eps IdentityMatrix[7]).bMinus2 = 0.
```

The hard and collinear coefficients reduce to Beta/Gamma functions. The
third coefficient multiplies the lower-basis direction
`{0,0,0,0,0,1,-1}` and is also an exact Beta/Gamma ratio. A pointwise limit
would erase the two nonuniform regions.

### 5.3 Why the next Frobenius coefficient is essential

For a region with exponent `lambda` write

```text
B_lambda(x) = x^lambda (b0 + x b1 + O[x^2]).
```

The recurrence is

```text
((lambda+1) IdentityMatrix[7] - Aminus1).b1 = A0.b0.
```

The matching from the boundary basis to the canonical basis has the form

```text
C(x) = Cminus1/x + C0 + O[x].
```

Consequently the finite canonical boundary vector is not just `C0.b0`; it is

```text
f_lambda = C0.b0 + Cminus1.b1,
```

after the exact spurious-pole condition `Cminus1.b0=0` has been checked. This
one line explains why keeping only the leading boundary region produced an
apparently extra mode in the early attempt. The corrected canonical vectors
satisfy

```text
Rx.fHard = 0
(Rx + IdentityMatrix[8]).fCollinear = 0
(Rx + 2 IdentityMatrix[8]).fMinus2 = 0
Ry.fHard = Ry.fCollinear = Ry.fMinus2 = 0.
```

## 6. The remaining top-corner constant

The seventh boundary equation is scalar:

```text
dB7/dx = (D-6)/(x-1) B7 + B1coef B1 + B2coef B2
                               + B3coef B3 + B6coef B6.
```

Its homogeneous solution is

```text
h(x) = (1-x)^(D-6) = (1-x)^(-2-2 eps).
```

The hard `1/x` source residue cancels exactly. The collinear
`x^(-1-eps)` source is fixed by the lower collinear vector. An independent
corner reduction has lower rank two, full rank three, and top row `{0,0,1}`;
there is therefore exactly one independent hard top-corner constant.

For its analytic evaluation introduce positive variables `rx,ry,rz` and

```text
alpha_i = ri/(1+ri),
Pxy  = 1-alpha_x alpha_y,
Pxyz = 1-alpha_x alpha_y alpha_z.
```

The normalized constant is represented by the positive Euler density

```text
-Gamma[3-3 eps] Gamma[2-2 eps]
 -------------------------------- Integral_0^Infinity drx dry drz
 eps Gamma[1-eps]^3 Gamma[-2 eps]

    Pxy^(2 eps) Pxyz^eps
 -------------------------------------------------------------- .
 rx ry rz (1+rz) alpha_x^eps (1-alpha_x)^(2 eps)
              alpha_y^eps (1-alpha_y)^(2 eps) alpha_z^eps
```

Every powered base is positive for positive `ri`, so this representation fixes
the real branch rather than relying on `PowerExpand`. SubTropica evaluates it
through `eps^2` as

```text
rTop(eps) = -10/eps^3 + 65/eps^2 - 135/eps + 90 - 8 Zeta[3]
  + eps (52 Zeta[3] - 2 Pi^4/3)
  + eps^2 (13 Pi^4/3 - 108 Zeta[3] - 288 Zeta[5])
  + O[eps^3].
```

This is the only nontrivial corner constant needed after the lower modes have
been fixed.

## 7. GPL transport and reconstruction

Use the piecewise path

```text
(0,0) -> (x,0) -> (x,y).
```

Along the first segment the letters are `{0,1}`. Along the second they are
`{0,1,1-x,(1-x)^2}`. With tangential endpoint regularization, the two ordered
evolution operators are

```text
Ux = P exp[eps Integral AxCanonical dx],
Uy = P exp[eps Integral AyCanonical dy],
F(x,y) = Uy(x;y) Ux(x) Fboundary.
```

Their coefficient of weight `n` is a sum over words of length `n`: a Chen/GPL
iterated integral multiplying the correspondingly ordered product of constant
residue matrices. Because the full basis starts at `eps^-4`, reconstruction
through `eps^2` requires weight six. Finally transform back with `G=T F` and
expand the rational transformation consistently to the same order.

The stored target is `G7`. Its `eps^-4` coefficient vanishes, so its leading
pole is `eps^-3`, but the transport still needs the deeper `eps^-4` basis
bookkeeping.

## 8. Validation

### 8.1 Exact checks

The accepted analytic result has all of these exact certificates:

```text
family and cut support valid
eight-master derivative closure stable
row reconstruction, homogeneity, and curvature zero
CANONICA epsilon-form and dlog reconstruction true
three Frobenius recurrences true
all spurious matching poles zero
all three canonical residue equations true
physical chamber and GPL path valid
target index exactly G7
no unresolved Integrate, SubTropica, PolyGamma, or machine-number object
```

The direct differentiated GPL audit currently covers both PDEs through the
finite coefficient. The epsilon-form and flatness checks are exact at the
system level. The `eps^1` and `eps^2` target coefficients have the independent
AMFlow test described next.

### 8.2 AMFlow check

At

```text
{s,t,u} = {10,-3,-2},   {x,y} = {3/10,1/5},
```

the exact GPL target/base ratio and AMFlow agree for every power from
`eps^-4` through `eps^2`. The comparison tolerance is `10^-12`; the lowest
available AMFlow precision is about 14 decimal digits at `eps^2`.

```text
eps power    exact ratio
-4           0
-3          -0.004
-2           0.028232024127181498559344...
-1          -0.066290998166471340573018...
 0           0.041883703822298626042003...
 1          -0.001221808964614470122794...
 2          -0.003281177029956454278368...
```

AMFlow is validation only. Do not replace any analytic boundary coefficient by
an AMFlow fit.

## 9. Packages and the small set of functions that matter

| Stage | Package | Functions or objects actually used |
|---|---|---|
| Family algebra | FeynCalc | `FCTopology`, `GLI`, `FCLoopGLIDifferentiate`, `FCLoopCreateRulesToGLI`, `FCLoopFromGLI`, `Contract` |
| IBP | Kira through FeynHelpers/FeynNLO | `KiraCreateConfigFiles`, `KiraCreateIntegralFile`, `KiraCreateJobFile`, `KiraRunReduction`, `KiraImportResults`, wrapped by `FeynKiraReduce` |
| Canonical system | CANONICA 1.0.3 | `SectorBoundariesFromDE`, `RecursivelyTransformSectors`, `CheckEpsForm`, `CalculateDlogForm` |
| Canonical transport | Libra 1.2 | `PexpExpansion`, through `ExactPathOrderedExpansion` |
| Parametric audit | FeynCalc 10.2.1 | `FCFeynmanParametrize`, `FCFeynmanFindDivergences`, `FCFeynmanRegularizeDivergence` |
| Corner integration | SubTropica | `ConfigureSubTropica`, `STIntegrate`, HyperFLINT integration/order search |
| Period cleanup | HyperIntica helper layer | `GetAlgebraicBackSubRules`, `ZeroOnePeriod` |
| Optional MPL cleanup | PolyLogTools 1.4 | `ExtractZeroes`, `DecomposeToLyndonWords`, restricted to same-branch identities |
| Independent GPL values | GiNaC | arbitrary-precision multiple-polylogarithm evaluation |
| Independent master check | AMFlow | `SolveIntegrals`, with Kira as reducer and cut vector `{1,1,1,0,0,0,0,0,0}` |

The analytic packages return symbolic functions or exact Laurent coefficients.
AMFlow returns fixed-point numerical series and is not the main calculation.

## 10. Authoritative files and rerun order

Run from the repository root under Linux/WSL with the activated Wolfram
kernel. Generated `.wl` associations are certificates and inputs to later
stages; `.wls` files are drivers.

### 10.1 Full system

```text
Profile83bbOnShellDerivatives.wls
Close83bbOnShellSystem.wls
Analyze83bbOnShellSystem.wls
Assess83bbCanonicalReadiness.wls
Fuchsify83bbTopBlock.wls
RunCANONICA83bbTopBlock.wls
RunCANONICA83bbFull.wls
SummarizeCANONICA83bbFull.wls
```

The similarly named scripts without `OnShell` used the invalid derivative
probe. Do not use `Probe83bbDerivatives`, `Reduce83bbDerivatives`,
`Close83bbSystem`, or `Analyze83bbSystem` as scientific inputs.

### 10.2 Boundary

```text
Build83bbBoundaryFamily.wls
Reduce83bbBoundaryFamily.wls
Build83bbBoundaryDifferentialSystem.wls
Build83bbScalarBoundarySystem.wls
Reduce83bbBoundaryMastersAtCorner.wls
Explore83bbBoundaryExactRoute.wl
RunSharedTopBoundaryEpsilon2.wls
```

The final corrected three-mode matching is generated by

```text
Fix83bbCanonicalBoundaryModes.wls
```

and its certificate is

```text
Fix83bbCanonicalBoundaryModes.wl.
```

Both files are tracked and contain the hard, collinear, and `x^(-2 eps)`
modes. No scientific input is loaded from `.codex_tmp`.

### 10.3 Transport and validation

```text
Build83bbGPLTransportEpsilon2.wls
Build83bbGPLTransportEpsilon2.wl
Audit83bbTransportPDE.wls              (direct PDE audit through eps^0)
EvaluateMasters/validation/NNLOHardMasters/amflow_generator_used.wls
EvaluateMasters/validation/NNLOHardMasters/comparison_driver_used.wls
EvaluateMasters/validation/NNLOHardMasters/comparison_83bb_epsilon2.wl
```

The epsilon-squared transport loads the tracked corrected boundary certificate
and constructs its ordered transport through Libra.

## 11. Failure modes that cost the most time

1. **Wrong invariant derivative.** A formally reduced but non-flat system is
   usually a derivative-definition error, not a difficult integral.
2. **Taking `y=0` in a transformation matrix.** This loses nonuniform regions.
   Build and reduce the boundary family independently.
3. **Keeping only the leading Frobenius vector.** A `1/x` matching pole makes
   the next coefficient contribute at leading canonical order.
4. **Dropping the `x^(-2 eps)` mode.** The final epsilon-squared result uses
   three modes, not the older two-mode boundary certificate.
5. **Termwise endpoint evaluation.** Divergent GPL terms may cancel only after
   being grouped. Rewrite endpoint-safe sums before numerical evaluation.
6. **Unrestricted power simplification.** The corner density was made positive
   first; no `PowerExpand` branch guess is allowed.
7. **Wrong word ordering.** Residue matrices do not commute. Audit one- and
   two-letter GPL derivatives before building weight six.
8. **Insufficient depth.** The target starts at `eps^-3`, but the basis starts
   at `eps^-4`; weight six is needed for a target through `eps^2`.
9. **Treating AMFlow as a boundary solver.** It validates the final analytic
   series but cannot replace an exact boundary constant.
10. **Hashing held local symbols.** If coefficient jobs are checkpointed,
    materialize the value before applying `HoldComplete` and hashing.

## 12. Fast-start checklist for a fresh agent

1. Read `PROJECT_GOAL.md` and preserve the three cut slots explicitly.
2. Load `Analyze83bbOnShellSystem.wl`; verify `Status -> PASS` before doing any
   new reduction.
3. Load `SummarizeCANONICA83bbFull.wl`; verify epsilon-independent residues and
   exact dlog reconstruction.
4. Load the tracked corrected three-mode boundary certificate and
   verify all sixteen checks, especially the minus-two recurrence and residue.
5. Load `RunSharedTopBoundaryEpsilon2.wl`; verify the exact zeta-valued series.
6. Run or load `Build83bbGPLTransportEpsilon2`; require every check to pass and
   confirm the target is master seven.
7. Use the saved comparison driver for AMFlow. Never use its decimals as input
   to the analytic result.
8. If a rerun differs, stop at the first failed exact certificate. Do not add
   replacement rules downstream to hide it.

## 13. References checked on INSPIRE

- J. M. Henn, *Multiloop integrals in dimensional regularization made simple*,
  Phys. Rev. Lett. 110 (2013) 251601, arXiv:1304.1806.
- C. Meyer, *Algorithmic transformation of multi-loop master integrals to a
  canonical basis with CANONICA*, Comput. Phys. Commun. 222 (2018) 295,
  arXiv:1705.06252.
- E. Panzer, *Algorithms for the symbolic integration of hyperlogarithms with
  applications to Feynman integrals*, Comput. Phys. Commun. 188 (2015) 148,
  arXiv:1403.3385.
- J. Vollinga and S. Weinzierl, *Numerical evaluation of multiple
  polylogarithms*, Comput. Phys. Commun. 167 (2005) 177,
  arXiv:hep-ph/0410259.
- X. Liu, Y.-Q. Ma, W. Tao and P. Zhang, *Calculation of Feynman loop
  integration and phase-space integration via auxiliary mass flow*, Chin.
  Phys. C 45 (2021) 013115, arXiv:2009.07987.
