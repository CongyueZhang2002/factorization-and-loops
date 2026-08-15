# Boundary periods 6 and 7 — exact ledger entries

Status: **Exact** (both). Every link in the proof chain is an exact
symbolic identity; no numerical step appears in the chain. Numerics are
retained in section 6 as an independent check only.

This entry answers sections 3.2 and 3.3 of
`External/CodexExchange/codex_assessment_of_fable_round6_2026-08-15.md`,
which required "an analytic boundedness argument, a convergent integral
estimate, or an exact closed form" in place of the numeric branch
identification.

Periods 6 and 7 are the **same master** in the same family; they are two
entries because the nullity counter flags them undetermined at different
strata (PID 6 at `soft`/`vEdge`/`wEdge`, PID 7 at `soft`/`wEdge`). The
analytic content is identical, so one proof serves both.

## 1. The original powered cut integral and its normalization

Family `CF124`, `loop_momenta [ke,kf]`, `cut_propagators [1,2,7]`
(`../Certificates/FamilyCutData.wl`).

```
master  = gli[CF124, {1,1,0,0,1,0,1,0,0}]        (block row 6 of 12)
volume  = gli[CF124, {1,1,0,0,0,0,1,0,0}]        (block row 5 of 12)
```

Indices `1` sit on the three cut propagators `#1 = kf`, `#2 = ke`,
`#7 = ka+kb-kc-ke-kf` and on the single uncut propagator
`#5 = (kc+ke+kf)^2`. Using `ke+kf = P - q` with `q` the third cut leg and
`P = ka+kb-kc`, that denominator is

```
D5 = (kc+ke+kf)^2 = (ka+kb-q)^2 = 1 - 2 q.(ka+kb)
```

i.e. the same 3-particle massless cut of `P` with one propagator, but with
the propagator attached to the `ka+kb` end rather than the `kc-ka` end as in
period 1. Convention identical to CF1's (verified uniform across all
families involved, `CONVENTIONS_UNIFORM = True`).

Row 6 couples only to row 5 (the volume) and to itself, in **both** `Av` and
`Aw` `[S5c, S5c']`:

```
Av[6,5] = (2-3 eps)/((-1+v+w)(v+w))      Av[6,6] = -eps/(v+w)
```

## 2. The exact variable map and the physical domain

Same chamber and same chart as period 1, with the polar angle now measured
from `kc`:

```
D5  = 1 - x s - x (1-s) y
dmu = x^(1-2 eps) (1-x)^(-eps) (y(1-y))^(-eps) dx dy
R   = [ Int dmu / D5 ] / [ Int dmu ]
```

Re-derived symbolically from the family definition in
`../Scripts/verify_parametric_representation.wls` `[R1-R2, C2, C3, M1-M5]`.

The reference axis differs between period 1 (`K = kc-ka`) and periods 6/7
(`kc`), but the measure is unchanged: each uncut denominator depends on a
single scalar product with `q`, so the azimuth integrates out trivially and
the polar measure is axis-independent. Integrating `x` first gives the form
quoted in the pilot,

```
R(s,eps) = Int_0^1 dy (y(1-y))^(-eps)
             2F1(1, 2-2 eps; 3-3 eps; s+(1-s)y) / B(1-eps,1-eps)
```

## 3. The selected Frobenius mode and Laurent depth

Soft stratum `s -> 0`. Exponents `{0, 1-2 eps}`; the `1-2 eps` mode is fixed
by the volume anchor and the **`0` mode is the period**, appearing in
`R = M/V` as `A(eps) s^(2 eps-1)`.

```
PID 6 strata : soft, vEdge, wEdge     PID 7 strata : soft, wEdge
Frobenius exponent: 0 at every listed stratum
Laurent depth: eps^0 (integer valuation 0; no log level)
```

Diagonal residues vanish at all three strata (`DiagResidue = 0`), so no
stratum contributes an independent mode beyond the soft one.

## 4. The exact zero proof

`ExactCoefficient = 0`, proved analytically. This is Codex's own
dominated-convergence argument (their message of 2026-08-14), formalized and
machine-checked.

Apply the soft-endpoint domination lemma (`SoftEndpointDomination.md`) with
`alpha = 1`, `beta = 1-s`. In corner coordinates `u = 1-x`, `t = 1-y`,

```
D5 = u + (1-u)(1-s) t                                             [K2]
```

exactly. Since `beta = 1-s` *degrades* as `s -> 1`, fix any `s0 in (0,1)`;
for `0 <= s <= s0` the kernel is bounded below by `u + (1-u)(1-s0) t`, and

```
D5 >= ((1-s0)/4)(u+t)                                             [L4]
```

uniformly in `s`. (This is the one place periods 6/7 differ from period 1,
whose bound needs no cutoff. Since only `s -> 0` is taken, any fixed `s0`
serves.) The endpoint kernel is then dominated by
`u^(-eps) t^(-eps)/(u + c t)`, and via AM-GM by the separable

```
(2/(1-s0)) u^(-sig-1/2)(1-u)^(1-2 sig) t^(-sig-1/2)(1-t)^(-sig)
Int = (2/(1-s0)) B(1/2-sig, 2-2 sig) B(1/2-sig, 1-sig)
```

finite exactly for `sig = Re[eps] < 1/2` `[D1-D4]`. Dominated convergence
makes the normalized integral finite and continuous at `s = 0`, so `R` is
bounded as `s -> 0+`.

The free mode `s^(2 eps-1)` is unbounded exactly when `Re[eps] < 1/2`
`[B1, B2]` — the same half-plane — so `A(eps) = 0` there, and by meromorphic
continuation `A === 0` identically. Hence **PID 6 = PID 7 = 0 exactly**.

**What this replaces.** The pilot's argument was that `R` measured at
`s = 1/2 ... 1/32` decreases monotonically to `2.125` instead of rising by
the ~9x that an `s^(-0.8)` branch would produce at `eps = 1/10`. That is a
sound branch *indication* but not a proof: finitely many samples cannot
exclude a small nonzero `A`. It is now demoted to section 6.

**Non-circularity.** As for period 1, "R is finite at `s = 0`" and "`A = 0`"
are the same statement, so the DE cannot be used to fix `A`. The argument
above bounds the parametric integral directly.

**Reconstruction check, numerics-free.** This was the weakest link in the
pilot's chain for CF124: the identification
`D5 = (kc+ke+kf)^2 = 1 - x s - x(1-s) y` was confirmed against Kira only by
29.7-digit agreement of the soft value. It is now exact. At `s = 0` the
kernel collapses to `1-xy` `[S0]`, and

```
Int dmu/(1-xy) = Int dmu * (2-3 eps)/(1-2 eps)
```

by Euler's representation `[S1]`, the termwise Beta ratio `[S2]`, the
Pochhammer cancellation collapsing the `3F2` `[S3]`, and Gauss's theorem at
unit argument `[S4a, S4b]`. So the parametric soft value is exactly
`(2-3 eps)/(1-2 eps)`, which is exactly the value forced by the repository
connection, `-lim_{s->0}(s Av[6,5])/(1-2 eps)` `[S5d, S6]`. Gauss's
convergence condition is again `Re[eps] < 1/2`.

## 5. Exact substitution into the differential equations

The scalar ODE follows from the block structure without any normalization
constant, since row 6 couples only to the volume:

```
s dR/dv = (1-2 eps) R + s Av[6,5] + s Av[6,6] R
```

with `s Av[6,5] -> -(2-3 eps)` and `s Av[6,6] R -> 0` as `s -> 0`, forcing
the finite branch value

```
R_soft = (2-3 eps)/(1-2 eps)
```

verified symbolically against the repository artifact
`../../DifferentialEquations/nnlo_de_CF124.wl` `[S5a-S5d]`.

Note the honest scope of this item: unlike period 1, **no closed form in
`(v,w)` is claimed** for periods 6/7. What is exact here is the connection,
the soft-stratum indicial structure, the forced value on the finite branch,
and — by section 4 — the vanishing of the free mode. The period value is
the `s^0` coefficient, and that is what is proved to be zero. A closed form
for `R(s)` away from `s = 0` remains unevaluated and is not needed for the
ledger entry.

## 6. Independent high-precision comparison (check only, not proof)

Retained from `../QFPilotReport.md` sections 10.3 and 16:

| eps | reconstructed integral | exact `(2-3 eps)/(1-2 eps)` | agreement |
|---|---|---|---|
| 1/10 | `2.12499999999999999999999999999999999999999998868` | `17/8` | 29.7 digits |
| 1/5 | `2.33333333333333333333333333333333333333333331579` | `7/3` | 29.6 digits |

Branch indication: `R(s)` at `s = 1/2, 1/4, 1/8, ...` measured as
`2.9543, 2.4465, 2.2703, ... -> 2.125`, decreasing monotonically to the
finite soft value rather than rising as `s^(2 eps-1)` would. Consistent
with, and independent of, the proof in section 4; not load-bearing.

## 7. Realization transfers

`UncheckedRealizations` is now empty for both periods. All nine PID-6
transfers and both PID-7 transfers are verified exactly — see
`RealizationTransfers.md`.

## Reproduction

```
wolframscript -file .../BoundaryPeriods/Scripts/verify_soft_domination.wls
wolframscript -file .../BoundaryPeriods/Scripts/verify_parametric_representation.wls
wolframscript -file .../BoundaryPeriods/Scripts/verify_transfers.wls
```

Expected: `SOFT_DOMINATION_EXACT = True` (26 `[OK]`),
`PARAMETRIC_REP_EXACT = True` (12 `[OK]`),
`TRANSFERS_EXACT = 12`.
