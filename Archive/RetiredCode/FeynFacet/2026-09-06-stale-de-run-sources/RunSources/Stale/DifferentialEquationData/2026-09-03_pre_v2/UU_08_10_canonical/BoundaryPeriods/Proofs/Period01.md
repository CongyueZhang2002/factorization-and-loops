# Boundary period 1 — exact ledger entry

Status: **Exact**. Every link in the proof chain is an exact symbolic
identity; no numerical step appears in the chain. Numerics are retained in
section 6 as an independent check only.

This entry answers section 3.1 of
`Exchange/Codex/2026-08-15/02_assessment_of_fable_round6.md`,
which required the differential-equation identity as an exact symbolic
statement and an exact soft-limit analysis in the physical chamber.

The six headings are Codex's ledger criterion as adopted in
`Design/Stage3BoundaryToolchain.md`.

## 1. The original powered cut integral and its normalization

Family `CF1`, `loop_momenta [ke,kf]`, `cut_propagators [1,2,5]`, nine
propagators (`../Certificates/FamilyCutData.wl`).

```
master  = gli[CF1, {1,1,1,0,1,0,0,0,0}]         (block row 2 of 2)
volume  = gli[CF1, {1,1,0,0,1,0,0,0,0}]         (block row 1 of 2)
```

Indices `1` sit on the three cut propagators `#1 = kf`, `#2 = ke`,
`#5 = ka+kb-kc-ke-kf` and on the single uncut propagator
`#3 = (kc-ka+kf)^2`. So the master is the 3-particle massless cut phase
space of `P = ka+kb-kc` with one propagator:

```
I3p = Int dPhi3(P; ke,kf,kg) / D3 ,     D3 = (kc-ka+kf)^2
V3  = Int dPhi3(P; ke,kf,kg)            (the phase-space volume)
R   = I3p / V3
```

Convention (from the DE artifact, uniform across all families involved):
`dI/dv = Av.I` at `2 ka.kb = 1`, `v = 2 ka.kc`, `w = 2 kb.kc`, `D = 4-2 eps`,
cuts `{1,2,5}`. The normalization cancels in `R`, and the recorded period
value is an exact zero, which is invariant under any nonzero normalization.

## 2. The exact variable map and the physical domain

Physical chamber `0 < v`, `0 < w`, `v+w < 1`; `s = 1-v-w`; `M = Sqrt[s]`.
In the rest frame of `P`, with `kf = E(1,nhat)`, `E = M x/2`, `x in (0,1)`,
and `cos(th) = 1-2y` the polar angle of `nhat` from the spatial direction of
`K = kc-ka`:

```
M K0 = (v-s)/2 ,   M |K| = (v+s)/2
J := -D3 = v + x s - x (v+s) y            (>= 0 on the whole chamber)
dmu = x^(1-2 eps) (1-x)^(-eps) (y(1-y))^(-eps) dx dy
R   = - [ Int dmu / J ] / [ Int dmu ]
```

All of this is re-derived symbolically from the family definition in
`../Scripts/verify_parametric_representation.wls` `[R1-R4, C1, M1-M5]`; it is
no longer a hand derivation. `J` vanishes only at the endpoint `x = y = 1`,
so there is no principal value, and that endpoint is the entire analytic
content of the period.

## 3. The selected Frobenius mode and Laurent depth

Soft stratum `s -> 0` at generic `v`. The block's two exponents are `0` and
`1-2 eps`. The `1-2 eps` mode is fixed by the volume anchor; the **`0` mode
is the period**. In the normalized ratio `R = I3p/V3` this mode appears as
the divergent piece `A(eps) v^(-eps) s^(2 eps-1)`.

```
Stratum          : soft (s -> 0, v generic), and wEdge (w -> 0, v generic)
Frobenius exponent: 0 at both strata
Laurent depth    : eps^0 (integer valuation 0; no log level)
```

At `wEdge` the CF1 residue matrix is identically zero, because the alphabet
`{1, -1+v+w, v, -1+w}` contains the letter `w-1` but not `w`; that stratum
therefore carries no independent period.

## 4. The exact zero proof

`ExactCoefficient = 0`, proved analytically.

Apply the soft-endpoint domination lemma (`SoftEndpointDomination.md`) with
`alpha = v`, `beta = v+s`. Because `beta >= alpha` for every `s >= 0`, the
bound

```
J >= (v/4)(u+t) ,      u = 1-x, t = 1-y
```

holds uniformly in `s` with **no upper cutoff on `s`** `[L3]`. The
dominating function is then

```
| dmu / J | <= (2/v) u^(-sig-1/2)(1-u)^(1-2 sig) t^(-sig-1/2)(1-t)^(-sig)
Int = (2/v) B(1/2-sig, 2-2 sig) B(1/2-sig, 1-sig) < Infinity   for sig < 1/2
```

with `sig = Re[eps]` `[D1-D4]`. Dominated convergence makes `N(s)` finite and
continuous at `s = 0`, so `R` is bounded as `s -> 0+`. The free mode
`v^(-eps) s^(2 eps-1)` is unbounded exactly when `Re[eps] < 1/2` `[B1, B2]`,
so `A(eps) = 0` on that half-plane; `A` is meromorphic, hence `A === 0` by
the identity theorem.

This is the step Codex called "the exact soft-limit analysis in the physical
chamber". It replaces the pilot's region argument plus 30-digit
determination, both of which are now downgraded to corroboration.

**Non-circularity.** The differential equation cannot fix `A`; and the
closed form in section 5 was *derived* assuming `A = 0`, so it may not be
used to prove `A = 0`. The argument above uses neither — see
`SoftEndpointDomination.md` section 7.

**Reconstruction check, numerics-free.** The parametric integral's soft
value is computed in closed form (Euler, then a Pochhammer cancellation,
then Gauss at unit argument) and equals the value forced by Kira's connection
`[S0-S4, S7]`. See `SoftEndpointDomination.md` section 8.

## 5. Exact substitution into the differential equations

Only after `A = 0` is established independently does the closed form follow:

```
R(v,w;eps) = - (2-3 eps)/(v (1-2 eps))
             * 2F1(1-eps, 1; 2-2 eps; -(1-v-w)/v)
```

The connection is read from the repository artifact
`../../DifferentialEquations/nnlo_de_CF1.wl`:

```
Av = {{(1-2 eps)/(-1+v+w), 0}, {(-2+3 eps)/(v(-1+v+w)), -eps/v}}
Aw = {{(1-2 eps)/(-1+v+w), 0}, {(2-3 eps)/((-1+w)(-1+v+w)), -eps/(-1+w)}}
```

With `V = volc (1-v-w)^(1-2 eps)` and `I = {V, R V}`, the residuals
`dI - Av.I` and `dI - Aw.I` reduce to **literal zero under `Together`**, in
both the volume row and the period row, and likewise in the reduced scalar
form `s dR/dv - (1-2 eps) R - s A21 - s A22 R` `[P2d-P2i]`.

The derivative of `2F1` raises parameters, so the check runs on an inert
head `ff` with the first-order contiguous relation

```
z(1-z) f'(z) = (a z - (c-1)) f(z) + (c-1),     f(z) = 2F1(a,1;c;z)
```

specialized to `a = 1-eps`, `c = 2-2 eps`. **This relation is itself proved
symbolically**, for general `a` and `c`, from the exact Pochhammer
coefficient recursion `(c+n-1) g[n] = (a+n-1) g[n-1]` with
`g[n] = (a)_n/(c)_n` `[P1a, P1b]`. That is strictly stronger than the
25-digit numeric spot check used by `Tests/Reconstruction/t_nlo_masters.wls` criterion B,
which the same argument would upgrade (`a = 1`, `c = 1-eps` reproduces that
test's relation exactly).

The recorded five-point-stencil residual `1.25e-9` is **withdrawn from the
proof chain**. It was the truncation error of an `O(h^4)` numerical
derivative, not a measure of the identity, and it is superseded by the exact
residual above.

Exact soft value: `lim_{s->0} R = (3 eps-2)/((1-2 eps) v)`, matching the
value forced by the connection `[P3, P3b]`.

## 6. Independent high-precision comparison (check only, not proof)

Retained from `../QFPilotReport.md` section 3, at `v = w = 1/4`:

| eps | closed form | direct phase-space integral | agreement |
|---|---|---|---|
| 1/10 | `-4.7023981729629979517323239746341481689` | `-4.7023981729629979517323239746341480043` | ~30 digits |
| 1/5 | `-5.2059875947093310617830804532883315775` | `-5.2059875947093310617830804532883309835` | ~30 digits |

Contiguous-relation bracket vanishing to 76-80 digits at four unrelated
rational points `(1/4,1/4,1/10)`, `(1/3,1/5,1/7)`, `(1/5,3/5,2/11)`,
`(2/5,1/10,1/13)`. These are consistent with, and independent of, the
symbolic proof; none of them is load-bearing.

## 7. Realization transfer

`UncheckedRealizations` is now empty. The transfer to `CF300` is verified
exactly — see `RealizationTransfers.md`.

## Reproduction

```
wolframscript -file .../BoundaryPeriods/Scripts/verify_period_01_de.wls
wolframscript -file .../BoundaryPeriods/Scripts/verify_soft_domination.wls
wolframscript -file .../BoundaryPeriods/Scripts/verify_parametric_representation.wls
```

Expected: `PERIOD01_EXACT_DE = True` (21 `[OK]` lines),
`SOFT_DOMINATION_EXACT = True` (26 `[OK]`),
`PARAMETRIC_REP_EXACT = True` (12 `[OK]`).
