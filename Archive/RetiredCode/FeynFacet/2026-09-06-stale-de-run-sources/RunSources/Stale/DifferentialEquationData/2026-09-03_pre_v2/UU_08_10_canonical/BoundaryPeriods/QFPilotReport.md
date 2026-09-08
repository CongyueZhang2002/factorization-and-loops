# Quasi-finite representations in the boundary-period stage — measured pilot

**Period under test:** `PeriodID 1` = `gli["CF1",{1,1,1,0,1,0,0,0,0}]`, ClassID 2,
ClassDim 1, multiplicity 1, strata `{soft, wEdge}`, all Frobenius exponents 0.

**Status:** ground truth SOLVED EXACTLY — closed form, verified four
independent ways (analytic `₃F₂` reduction; 30-digit numeric agreement at two
`eps` values; finite-difference residual against the Kira DE; contiguous-relation
bracket zero to ~80 digits at four points). **Period value: exactly `0`.**
Route measurements: §5. Verdict: §0 and §7.

---

## 0. Verdict up front

**Do not adopt Route Q (quasi-finite) on the strength of this pilot; do not
reject it either — defer, and re-test on a divergent period.**

**What the literal scoreboard says, and why I am not accepting it.** On the
adoption criterion as written — same period, measured — **Route Q won
outright**: it returned the target to 15–19 digits per `eps` order in under
~2 minutes of compute, while Route R returned `$Failed` and produced no number
at all (§5). I am *not* recommending adoption on that basis, because the
comparison is confounded twice over, both times in ways that flatter Route Q:

1. **Route R's failure was tooling, not the method and not the integrand.**
   Established across three attempts (§5.2, §18): SubTropica cannot spawn its
   helper kernels here — `ConnectKernel::failinit: 11 of 19 kernels failed to
   initialize` — and it fails identically on a one-variable, fully regulated,
   textbook integral (`Int_0^1 x^(-ep)(1-x)^(-ep) dx`). Passing `"Kernels" -> 1`
   does not help, because the raw-Euler entry point silently strips that class
   of option (§18, item 2). A working Route R would very likely have evaluated our
   integral analytically — it is linearly reducible. **We never saw the method,
   only the plumbing.**
2. **Route Q's distinguishing step never ran.** The quasi-finite construction
   earns its keep by turning a *divergent* parametric integral into a convergent
   one so the `eps`-expansion commutes with integration. This period's integral
   is **already convergent term by term**, so the required dimension/dot shift
   is a *no-op* (0 shifts, §4). What "Route Q" actually did here was expand and
   integrate numerically — something any route can do.

That second point is the pilot's structural finding: **the protocol's own
selection rule ("cheapest period") selects exactly the period where Route Q's
machinery cannot be exercised.** Winning a race in which neither runner used
their legs is not evidence about legs.

The honest cost statement for the boundary stage is in §6, and it is dominated
by a different finding than either route: **this period's value is exactly
`0`** (§3.2), and the whole block was solved in closed form

> `I3p/V3 = − (2−3eps)/(v(1−2eps)) · ₂F₁(1−eps, 1; 2−2eps; −s/v)`,  `s = 1−v−w`

by the triangular structure of its own differential equation plus a single
high-precision evaluation of the parametric integral at one generic point.
Neither route's distinguishing machinery was involved. The dominant per-period
cost was **reconstructing the integrand** (~35 min), which both routes pay
equally.

---

## 1. Period selection

All 33 entries ranked by sector weight (propagator count, then dots, then
numerators, then stratum count). PeriodID 1 is the unique cheapest:

| PID | family | #prop | dots | numer | ClassDim | mult | strata |
|---|---|---|---|---|---|---|---|
| **1** | **CF1** | **4** | **0** | **0** | **1** | **1** | **2** |
| 7 | CF124 | 4 | 0 | 0 | 1 | 2 | 2 |
| 6 | CF124 | 4 | 0 | 0 | 1 | 9 | 3 |
| 9 | CF199 | 5 | 0 | 0 | 2 | 2 | 2 |

It is a 1-dimensional block in a rational frame with the smallest alphabet in
the whole problem (`{1, v+w-1, v, w-1}`), so it satisfies every preference in
the protocol.

**One caveat recorded, not hidden — it limits what the `0` transfers to.**
The entry's `RepresentativeBasis` is written in family `CF1`, but its
`Families` field is `{CF300}` with `BlockRows {{5}}`. What CF1 and CF300 share
is the class-2 *canonical connection* (`nnlo_de_summary.wl` gives CF300
`Block 24, Canonical 2`); what they do not share is the ambient alphabet —
CF1's is `{1, v+w-1, v, w-1}`, CF300's has 18 letters including
`eps`-dependent ones.

Consequently:

* the **cost** measurements transfer cleanly — CF1 is the cheapest concrete
  realization of class 2 and the structure (which modes are undetermined, the
  exponents, the block dimension) is identical;
* the **value** `0` is established for the CF1 realization. Whether it carries
  over to CF300's row-5 master depends on the counter's cross-family dedup
  convention, which I did not verify. I am not claiming CF300 row 5 is zero.

This is worth a follow-up in its own right: if the dedup does identify them,
the counter's own list is telling us a CF300 boundary constant is computable
from a 4-propagator CF1 integral.

## 2. Step 1 — integrand reconstruction: SUCCEEDED, nothing missing

The protocol allowed an early stop if the integrand needed infrastructure not
on disk. It did not. Everything needed was present:

| ingredient | file |
|---|---|
| propagators + cut flags | `Codex/ppHX_NNLO_DoubleReal/Kira/UU_08_10_canonical/families/CF1/config/integralfamilies.yaml` |
| kinematics / scalar products | same dir, `kinematics.yaml` |
| block DE + conventions | `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/DifferentialEquations/nnlo_de_CF1.wl` |
| class/stratum residues | `scratchpad/nullity/out/probe_CF1.wl` |

CF1 has `loop_momenta [ke,kf]`, `cut_propagators [1,2,5]` and 9 propagators.
With indices `{1,1,1,0,1,0,0,0,0}` the three cut propagators carry index 1 and
the **only** uncut denominator is `#3 = (kc - ka + kf)^2`. So the period's
integral is the **3-body massless cut phase space with one propagator**:

```
I3p = Int dPhi3(P; ke,kf,kg) / D3 ,   D3 = (kf + kc - ka)^2 = -v + 2 kf.(kc-ka)
P = ka+kb-kc ,  P^2 = s := 1-v-w ,  v = 2ka.kc , w = 2kb.kc , 2ka.kb = 1
```

and its lower partner `gli["CF1",{1,1,0,0,1,0,0,0,0}]` is the phase-space
volume `V3` (the class-1 anchor, known).

**Explicit parametric form.** In the rest frame of `P`, with `kf = Ef(1,nhat)`,
`Ef = M x/2` (`M = Sqrt[s]`, `x in (0,1)`), `c = cos(theta)` between `nhat` and
the spatial part of `K = kc-ka`, and `c = 1-2y`:

```
M K0 = (v-s)/2 ,  M |K| = (v+s)/2
J := -D3 = v + x s - x (v+s) y            (>= 0 on the whole physical region)
dmu = x^(1-2eps) (1-x)^(-eps) (y(1-y))^(-eps) dx dy
```

so that, with every measure convention cancelling in the ratio,

```
R := I3p / V3 = - [ Int dmu / J ] / [ Int dmu ]
```

`J >= 0` was checked at the boundary: `max D3 = 0`, attained only at
`x=1, y=1`. So there is no principal value, but there *is* an endpoint zero of
`J` — this is the whole analytic content of the period.

## 3. Step 2 — ground truth: exact closed form

The CF1 block DE is lower-triangular, so `R` obeys a **scalar** ODE that
carries no normalization constant at all (every convention cancels):

```
s dR/dv = (1-2eps) R + (2-3eps)/v   - (eps s/v)     R
s dR/dw = (1-2eps) R + (2-3eps)/(1-w) + (eps s/(1-w)) R
```

Solving in `v` at fixed `w` with integrating factor `v^eps` gives a **one-
parameter family**: `DSolve` returns the homogeneous solution `v^(-eps)
s^(-1+2eps)` plus a particular solution. That free constant *is the period* —
see §3.2, where the logic is spelled out to avoid a circularity trap — and it
must be fixed by evaluating the integral, not by the DE. Fixing it to the value
determined in §3.2 gives the closed form

> **R(v,w,eps) = − (2−3eps) / (v (1−2eps)) · ₂F₁(1−eps, 1; 2−2eps; −s/v)**,  s = 1−v−w

equivalently `I3p = R · V3` with `V3 = c(eps) s^(1-2eps)` and
`c(eps) = 2^(-3+2eps) Pi^(5/2-2eps) Gamma[1-eps]^2 / (Gamma[3-3eps] Gamma[3/2-eps])`.

**Verification 1 (analytic, independent of the DE).** The soft limit of the
parametric integral must reproduce the DE's forced soft value. Doing the `y`
integral gives `B(1-eps,1-eps) ₂F₁(1,1-eps;2-2eps;x)`; the remaining `x`
integral is a `₃F₂` whose `2-2eps` parameter cancels between numerator and
denominator, collapsing it to `₂F₁(1,1-eps;3-3eps;1)`, i.e.

```
Gamma[3-3eps] Gamma[1-2eps] / (Gamma[2-3eps] Gamma[2-2eps]) = (2-3eps)/(1-2eps)
```

which is **exactly** the DE's soft limit `R -> (3eps-2)/((1-2eps) v)`. This
validates the reconstructed integrand against Kira/IBP with no numerics.

**Verification 2 (numeric, ~30 digits, two eps values).** The closed form
against a direct evaluation of the phase-space integral (the `y` integral done
analytically, `x` integrated numerically at `WorkingPrecision 40`) at
`v=w=1/4`:

| eps | closed form | direct phase-space integral |
|---|---|---|
| 1/10 | `-4.702398172962997951732323974634148`**1689** | `-4.702398172962997951732323974634148`**0043** |
| 1/5  | `-5.205987594709331061783080453288331`**5775** | `-5.205987594709331061783080453288330`**9835** |

Agreement is to **~30 significant digits**, i.e. to the full precision the
exact side was evaluated at, comfortably above the 25-digit bar. (The script's
`agreedigits` field reports `Indeterminate` rather than a number: significance
arithmetic gives `b-a` zero significant digits, which *is* the signature of
agreement below the comparison precision, not a failure.)

The symbolic soft limit of the closed form also returns exactly
`-(2-3ep)/(v(1-2ep))`, matching the DE's forced value (`GT/soft_limit`).

**Verification 3 (against Kira directly).** Feeding the reconstructed
parametric integral into the scalar `v`-ODE above and differentiating it
numerically (5-point stencil, `h=1e-3`, `WorkingPrecision 40`) gives

```
RESIDUAL_V = -1.2476090371697255e-9
```

which is the expected size of the stencil's own `O(h^4)` truncation error, not
a discrepancy. The reconstructed integrand therefore satisfies the IBP-derived
differential equation — an end-to-end check of the yaml -> frame -> measure
chain against Kira. (`gt_stage1.log`.)

**One check came back inconclusive, and it is reported as such.** Substituting
the closed form into the two scalar ODEs and calling `Simplify` did *not*
return `0`; it returned a nonzero-looking expression proportional (in both
cases, with the expected ratio `-v/(w-1)`) to the single bracket

```
2(1-2ep)v^2 + 2v(w-1+ep(1+v-w)) 2F1[1,1-ep;2-2ep;-s/v]
            + (w-1)(v+w-1)      2F1[2,2-ep;3-2ep;-s/v]
```

whose vanishing is a standard `₂F₁` contiguous relation that `Simplify` failed
to apply.

**This was then closed numerically and decisively.** Evaluating the bracket at
four unrelated rational points `(v,w,eps)` = `(1/4,1/4,1/10)`, `(1/3,1/5,1/7)`,
`(1/5,3/5,2/11)`, `(2/5,1/10,1/13)` gives

```
GT/bracket_numeric = {0, 0, 0, 0}   to 76, 79, 80, 79 digits respectively
```

So the closed form satisfies **both** scalar ODEs exactly; the only failure was
the simplifier's. Note that Mathematica's `Integrate` likewise stalled on the
soft identity, returning an unevaluated 1-fold integral where the by-hand `₃F₂`
reduction closed it exactly — twice in one pilot the hand reduction beat the
CAS, which is itself a cost signal for any route that leans on symbolic
integration.

### 3.2 The period is exactly zero — and why that is not circular

At the soft stratum the two exponents of the block are `0` and `1-2eps`. The
`1-2eps` mode is fixed by the volume anchor; the **`0` mode is the period**,
call its coefficient `A`.

**The trap.** Because `R = I3p/V3` and `V3 ∝ s^(1-2eps)`, the period `A`
appears *in `R`* as the **divergent** piece `A · s^(2eps-1)`. So the statement
"`R` is finite at the soft stratum" is logically *identical* to "`A = 0`". Any
derivation that fixes the integration constant by demanding soft-finiteness and
then concludes the period vanishes has assumed its conclusion. The DE alone
cannot determine `A` — that is exactly why the period is on the undetermined
list in the first place.

**What actually determines `A` here** is the honest evaluation of the integral,
by two independent arguments:

1. *Region analysis of the parametric integral.* Writing
   `J = v(1-xy) + x s(1-y)`, the only place `J` degenerates is the corner
   `x=y=1`, where `J ~ v u + (v+s) t`. The `s`-dependence merely shifts the
   coefficient of `t`; it introduces no second scaling region. Hence the
   `s`-expansion of `I3p` is `s^(1-2eps)` times an ordinary Taylor series, with
   **no `s^0` branch**, i.e. `A = 0`.
2. *Numerical determination at a generic point.* `A` is a constant, so the
   one-parameter family is separated by its value anywhere. At `v=w=1/4`
   (`s=1/2`, far from the soft stratum) the direct phase-space integral matches
   the `A=0` solution to **~30 digits at two different `eps` values** (§3,
   Verification 2). That pins `A=0` to 30 digits with no DE input at all.

Only after `A` is fixed this way does the closed form follow, and its series
then confirms mechanically what argument 1 predicts: `GT/period_s0_mode`
returns exactly `0`.

The same conclusion holds at `wEdge`, where CF1's residue matrix is the zero
matrix (`probe_CF1.wl`) because the alphabet contains the letter `w-1` but not
`w`.

**So the pilot's real measurement is argument 2** — a high-precision evaluation
of the reconstructed parametric integral at one generic phase-space point. That
is the operation both routes exist to perform, and it cost ~30 digits in a few
seconds of quadrature once the integrand was in hand.

This is not a defect of the nullity counter; the counter's own report states
`N_new` is an **upper bound** because the regularity rows were deliberately
omitted. PeriodID 1 is a case where that bound is not tight, and the report's
§3.5 flags exactly this signature ("a zero residue means λ=0 at every stratum,
these are the strongest candidates") as the place the count is loosest.

## 4. Route Q is a no-op on this period

The quasi-finite construction shifts dimensions/dots until the parametric
integral converges termwise so that `eps`-expansion commutes with integration.
Testing the criterion on the reconstructed integrand:

Near the only dangerous point (`x=1, y=1`; set `u=1-x`, `t=1-y`):

```
J ~= v u + (v+s) t        dmu ~= u^(-eps) t^(-eps) du dt
```

(the `u^(-eps)` from `(1-x)^(-eps)`, the `t^(-eps)` from `(y(1-y))^(-eps)`).
Scaling `u,t ~ lambda` gives `Int lambda^(-2eps) dlambda` — convergent for
`eps < 1/2`, **including `eps = 0`**. The full integral at generic `(v,w)` and
the soft-region integral are both already absolutely convergent.

Equivalently in the pre-substitution angular variable, `sin^(1-2eps)(theta)
dtheta = (2t)^(-eps) dt` with `t = 1+cos(theta)` — the same exponent, as it must
be.

**Required shifts: 0.** Route Q's characteristic step does nothing here, so on
this period Route Q degenerates into "expand the integrand and integrate",
which is what any route does.

Two honesty notes on that number. (i) It is **derived by the power counting
above**, not reported by a shift-finding tool — the `Q/quasifinite_shifts_needed
= 0` field in the artifacts records my analytic conclusion, it does not measure
it. (ii) A shift engine does exist in our tree
(`FeynFacet/Private/DimensionalShift.wl`, 815 lines, with an explicitly
cut-preserving entry point `dimensionalShiftPreserveCuts`), so Route Q would
*not* have needed building from scratch — it simply has nothing to do on an
already-convergent integrand. That is a point in Route Q's favour for the
harder tier and is why the recommendation is "defer", not "reject outright".

## 5. Measured comparison

Both routes were pointed at objects with **known exact values**, so accuracy is
measured against truth, not against each other.

* Route R target: the soft-region Euler integral
  `S(eps) = Int dx dy x^(1-2e)(1-x)^(-e)(y(1-y))^(-e)/(1-xy)`,
  exact value `B(1-e,1-e) B(2-2e,1-e) (2-3e)/(1-2e)`.
* Route Q target: the full `T(eps) = Int dmu/J` at `v=w=1/4`,
  exact value `-R(1/4,1/4,e) · B(2-2e,1-e) B(1-e,1-e)`, whose `eps^0`
  coefficient is `ln 9`.

| | Route R (regions + SubTropica) | Route Q (quasi-finite) |
|---|---|---|
| preprocessing needed | 1 region (derived by hand) | **0 shifts (no-op)** |
| back end | SubTropica `STIntegrate` v1.2.9 | symbolic `Integrate`, then numeric |
| loaded / available | yes | yes (`DimensionalShift.wl` present, unused) |
| result at `eps^0` | **`$Failed`** (§5.2) | **`Log[9]` — exact and correct** |
| result at `eps^1..3`, symbolic | not obtained | **stalls** (unevaluated `Integrate`) |
| result at `eps^0..3`, numeric | **`ERR`** (NIntegrate failed) | **15–19 digits/order** |
| accuracy vs truth | nothing produced | see table below |

**Route Q, numeric per eps order, against the exact coefficients** (the only
route-vs-truth comparison this pilot actually obtained):

| eps order | Route Q numeric | exact | digits agreeing |
|---|---|---|---|
| `eps^0` | `2.197224577336219382`24305… | `2.197224577336219382`79049… | ~19 |
| `eps^1` | `11.1317102387307999`3368… | `11.1317102387307999`5597… | ~18 |
| `eps^2` | `31.7356484186711`8133… | `31.7356484186711`8560… | ~17 |
| `eps^3` | `70.111596144871`63133… | `70.111596144871`64557… | ~15 |

(`eps^0` is `ln 9`, confirming the leading order independently of the symbolic
run.) Route Q therefore *did* deliver the target to 15+ digits per order, with
accuracy degrading by roughly one digit per order — the expected signature of
the corner `J -> 0`, which `NIntegrate` flagged (`eincr`, `slwcon`) throughout.
A production implementation would resolve that corner by sector decomposition
rather than adaptive quadrature; 15 digits is a floor, not a ceiling.

The corresponding numeric baseline for **Route R's** soft integral returned
`ERR` outright: the same corner, but with the `s`-dependence gone the
`1/(1-xy)` endpoint is harder, and plain `NIntegrate` did not survive it.
For reference the exact soft series is

```
S(eps) = 1 + 5 eps + (38-Pi^2)/2 eps^2 + (439 - 20 Pi^2 - 4 psi''(1) + 36 psi''(3))/8 eps^3 + ...
       = 1 + 5 eps + 14.0651977994553… eps^2 + 30.7095337719998… eps^3 + ...
```

### 5.2 Route R did not evaluate this integral

`SubTropica` (v1.2.9) loaded cleanly, and `STIntegrate` on the raw soft Euler
integrand returned **`$Failed`**. In the first run the reason was suppressed
(`Quiet`), so the call was repeated with messages on and in a second
`(1-xy)^(-1)`-as-explicit-power form; see `routeR.log` for the captured
diagnostics.

> **Superseded by §18.** The reading below ("calling convention") was the
> hypothesis at the time. It was later tested and is **wrong**: the failure is
> helper-kernel spawning, and it reproduces on a trivial textbook integral.
> The conclusion that it is *our* problem rather than the method's survives;
> the mechanism does not.

The reading at the time: this is a **driver/calling-convention failure on our
side, not evidence that SubTropica cannot do this integral** — the integral is
linearly reducible and well within its class. Codex drives it through their own
`BuildNormalizedMasterBoundaryIntegral` wrapper, which normalizes the density,
supplies `"Regulator" -> ep`, an `"EpsilonRange"`, `"BranchData"` and
`"ConvergenceAssumptions"`. Reproducing that wrapper is exactly the one-time
Route R setup cost identified in §6, and this pilot shows it is **not
optional**: the bare `STIntegrate[integrand, {x,0,1}, {y,0,1}]` entry point did
not work out of the box.

### 5.3 A harness bug worth recording

The first script's timings are **void**. Its `timed[k_, expr_]` helper lacked
`HoldRest`, so `expr` was fully evaluated at call time and `AbsoluteTiming`
then measured a re-evaluation of an already-computed value — every timing
reported `0.` or `1.e-6` regardless of the true cost (Route Q's symbolic
integration reported `0.` after minutes of wall time). Fixed in `routeR.wls`.

This is the same failure family as the seat-rules warning that *exit codes
lie*: a green-looking number that encodes nothing. It is reported rather than
quietly patched because it means **no per-item wall-time figure from either
script may be quoted** (the fix landed after `routeR.wls` had already been
launched, so it too reports void per-item times).

**Bounded wall times recovered from seat-acquisition and file timestamps** —
these are real, if coarse:

| run | wall | what it contained |
|---|---|---|
| `routes.wls` | 15:05:57 → 15:11:51 = **5 m 54 s** | GT `Simplify` (slow, inconclusive), 2× 30-digit direct checks, Route Q **symbolic** integration (dominant), SubTropica load + failed call |
| `routeR.wls` | 15:11:52 → 15:14:47 = **2 m 55 s** | bracket check at 4 points to ~80 digits, **Route Q numeric, all 4 eps orders**, SubTropica load + failed call, soft-integral baselines |

So **Route Q's numeric evaluation to 15–19 digits across four `eps` orders
completed inside a 3-minute run that also paid the SubTropica package load**
(typically 30–60 s on its own). Route Q's compute cost on this period is
therefore on the order of a minute or two — cheap. Route R has no compute cost
to report because it produced no result.

### 5.1 Honest effort log (the number that actually matters)

| activity | time | per-period or one-time? |
|---|---|---|
| locating artifacts (period list was at `nullity/out/`, not the briefed path) | ~25 min | one-time |
| integrand reconstruction: yaml -> frame -> measure -> `J` | ~35 min | **per-period** |
| ground truth: scalar ODE, closed form, `₃F₂` verification | ~40 min | **per-period** (but see §6) |
| route drivers (ours; Codex's wrapper is not in our tree) | ~30 min | one-time |
| seat/licence friction (2-seat cap, one self-inflicted stall) | ~20 min | recurring |

## 6. Extrapolation to 33 periods, and what actually drives the cost

**Route R setup is one-time; Route Q setup is one-time; the integrand
reconstruction is per-period, and it dominates both.** That is the finding that
reprices the stage. Neither route's evaluator was the bottleneck on this
period — reconstructing the cut-phase-space parametrization from the Kira yaml
was, and that cost is paid identically by both routes.

Two infrastructure facts sharpen the extrapolation:

1. **Codex's boundary machinery is not in our tree.**
   `BuildNormalizedMasterBoundaryIntegral` / `EvaluateMasterBoundarySubTropica`
   exist only under `/home/maxzhang/FACET/Codex/MasterEvaluationWorkflow/PackageCandidate_20260814/`.
   Route R as Codex runs it is not directly available to us; we either write our
   own driver (done here) or take a dependency on their package.
2. **Their soft-corner catalog is indexed differently from our 33** —
   `SoftCornerBoundaryPeriodCatalog.wl` has 16 classes keyed by
   *BoundaryTopology template IDs* (120, 130, 127, …), while our periods are
   keyed by CF family/class.

   > **CORRECTION (extension, §9).** I originally wrote here that "no mapping
   > between the two indexings is on disk" and called building it the largest
   > unbudgeted item. **That was wrong.** The map *is* on disk:
   > `BoundaryInventory/BoundaryTemplateTopologies.wl` gives, for each of its
   > 21 templates, both `"CanonicalMaster" -> GLI[CFnnn, {...}]` and
   > `"CanonicalFamily" -> CFnnn`. The real limitation is *coverage*, not
   > existence — see §9.2. The rest of this section stands.

### 6.1 Structural census of all 33 (zero compute, `census.py`)

| ClassDim | count | PeriodIDs |
|---|---|---|
| **1 (scalar ODE)** | **20 (61%)** | 1,2,3,4,5,6,7,8,14,15,16,17,21,22,23,24,28,30,31,32 |
| 2 | 10 | 9,10,11,13,18,19,20,25,29,33 |
| 4 | 3 | 12,26,27 |

| propagators | count | PeriodIDs |
|---|---|---|
| 4 | 3 | 1, 6, 7 |
| 5 | 2 | 9, 12 |
| 6 | 7 | 2,3,19,20,25,26,27 |
| **7** | **19** | 4,5,8,10,11,13,14,15,16,17,18,21,22,23,24,28,29,32,33 |
| **9** | **2** | 30, 31 |

Two numbers drive the whole extrapolation:

* **61% of the list (20/33) are 1×1 blocks.** A 1-dimensional block is a
  *scalar first-order ODE*, exactly like the one solved here: its homogeneous
  solution is a product of powers of the alphabet letters and its boundary
  constant follows from one quadrature against already-known lower sectors.
  These are candidates for the same closed-form treatment that solved
  PeriodID 1 with **zero compute and neither route**.
* **21 of 33 sit at 7+ propagators.** That is the tier where the parametric
  integrals actually diverge and where Route Q's shift stops being a no-op —
  and the pilot, by construction, measured none of it.

**Arithmetic.** If the ~35 min/period reconstruction cost holds, 33 periods is
roughly 19 h of reconstruction regardless of route — this is the dominant term
and it is route-independent. Against that, the choice between R and Q is a
second-order decision. The cheapest tier (PIDs 1, 6, 7, 9, 12) is likely to
keep yielding closed forms from triangular blocks at near-zero compute, as this
one did; the 21-period 7+ tier is where the real spend sits and where the
route choice is actually load-bearing.

### 6.2 The two routes are not really rivals — they share a back end

Worth stating plainly, because it changes what "adopt" would even mean.
Expansion-by-regions and the quasi-finite shift are both *preprocessing steps
whose only job is to hand a finite integral to an integrator*. After either
one, what actually evaluates the result is the same linear-reducibility
machinery (HyperInt / HyperFLINT / HyperIntica, via SubTropica) or the same
high-precision quadrature.

So the real question is not "R or Q" but **"which preprocessing makes the
integrals finite most cheaply and most reliably, per period"** — and they are
not mutually exclusive: regions can produce a region integral that is itself
best handled by a shift, and vice versa. A period whose integral is already
finite (like this one) needs *neither*, which is precisely why this pilot
cannot separate them.

## 7. Recommendation

**Defer. Do not adopt, do not reject.** The adoption criterion was "beats the
alternative on cost/reliability for the SAME period, measured". On the period
measured, the criterion **cannot be evaluated**, for a reason that is a result
rather than an excuse: Route Q's distinguishing step is a no-op on an
already-convergent integrand, and Route R's back end did not run through our
own driver. What the pilot did establish:

1. **The period is solved.** Exact closed form, four independent verifications,
   value `0`. The boundary program can retire PeriodID 1 (with the CF300 caveat
   of §1).
2. **Neither route solved it.** The triangular DE plus one high-precision
   evaluation did. That is a third option the pilot was not asked to price, and
   it is the cheapest of the three for this period — and structurally available
   for the 20/33 periods that are 1×1 blocks.
3. **The per-period bottleneck is integrand reconstruction (~35 min)**, paid
   identically by both routes. Route choice is a second-order optimization
   against a route-independent first-order cost.

**The decisive next test, and it is cheap.** Re-run this protocol on one
**9-propagator** period — PID 30 (`CF385`) or PID 31 (`CF413`) — where:

* Route Q's shift count is nonzero, so its actual benefit is exercised;
* Route R's regions analysis has more than one region, so its actual cost is
  exercised;
* both hit a genuinely divergent parametric integral, which is the only regime
  where the two differ.

Prerequisites now known and cheap to satisfy:

* get Route R to run at all — **not** by reformulating the integrand (§18
  exonerates it) but by escaping the raw-Euler option-stripping path: set the
  `$STLROrderBackend` globals directly, or cap parallelism outside the package,
  or take the dependency on Codex's `MasterBoundaryIntegral.wl`;
* if taking that dependency, **the CF-class ↔ BoundaryTopology-template index
  map has to be built first** (§6) — it is not on disk, and it is the single
  largest unbudgeted item found in this pilot.

If a decision is forced today with no further work, it is **reject-for-now** —
but that verdict is an artifact of the period-selection rule, not a judgement
about quasi-finite representations, and it should not be quoted as one.

## 8. Artifacts and reproduction

All under `scratchpad/qf_pilot/`. Nothing was written under `/home/maxzhang/FACET`.

| file | role |
|---|---|
| `PILOT.md` | this report |
| `gt_stage1.wls` / `.log` | first ground-truth attempt: DE residual `-1.25e-9`, `DSolve` general solution. **Its NIntegrate was ill-conditioned** (2-fold corner) — superseded by the 1-fold+2F1 form |
| `routes.wls` / `routes.log` / `routes_result.wl` | GT closed form, 30-digit check, Route Q symbolic, first SubTropica attempt. **Timings void (§5.3)** |
| `routeR.wls` / `routeR.log` / `routeR_result.wl` | bracket check (0 to ~80 digits), Route Q numeric per order, SubTropica retry, soft-integral baselines |
| `diag.wls` / `diag.log` | loud SubTropica diagnostic (why `$Failed`) |
| `census.py` | structural census of all 33 periods (§6.1) |
| `seatrun.sh` / `seat.log` | seat-disciplined launcher; ownership via `/proc` cwd, jitter backoff, never kills |

**Reproducing the ground truth needs no compute at all.** The closed form

```
I3p/V3 = -(2-3eps)/(v(1-2eps)) * Hypergeometric2F1[1-eps, 1, 2-2eps, -(1-v-w)/v]
```

follows from `nnlo_de_CF1.wl` plus the value of the free constant, and the free
constant is `0` by the region argument of §3.2.

### 8.1 Process notes worth carrying forward

Three things cost time and would cost it again:

1. **The briefed path for the period list was wrong** — `NullityPeriods.wl` is
   at `scratchpad/nullity/out/`, not `scratchpad/nullity/`.
2. **Ill-conditioned quadrature burned a seat for ~20 minutes.** The 2-fold
   `(x,y)` form has an integrable corner that `GlobalAdaptive` cannot resolve;
   doing the `y` integral analytically first (giving a `2F1`) turns the same
   quantity into a well-behaved 1-fold integral that reached 30 digits quickly.
   Under a 2-seat cap a stalled job is not just slow, it blocks the queue — and
   the job could not be cleaned up, since killing is denied by policy and by
   the sandbox.
3. **Two silent-failure modes were caught only by reading per-item records**,
   exactly as the seat rules warn: the `HoldRest` timing bug (§5.3) and
   `Quiet` swallowing SubTropica's failure reason. Both would have passed a
   green exit code.

---

# EXTENSION (+4 h): the 1x1 sweep, the 9-propagator re-test, transfer caveats

## 9. Corrections to the base report

Two claims in §1–§8 needed correcting once the extension work looked harder.

### 9.1 The CF-class <-> template map exists

`BoundaryInventory/BoundaryTemplateTopologies.wl` carries, per template,
`"TemplateID"`, `"CanonicalMaster" -> GLI[CFnnn,{...}]`, `"CanonicalFamily"`,
`"CutPowers"`, and fully rationalized `"OrdinaryDenominators"`. The 21 entries
map as:

| template | canonical master | #denom | solved |
|---|---|---|---|
| 120 | `GLI[CF384,{1,1,1,1,1,1,1,1,1}]` | 6 | yes |
| 130 | `GLI[CF408,{1,…,1}]` | 6 | yes |
| 127 | `GLI[CF407,{1,…,1}]` | 6 | no |
| **121** | **`GLI[CF385,{1,1,1,1,1,1,1,1,1}]`** | **6** | **no** |
| 102/103 | `GLI[CF259,…]` | 5 | no |
| … | (108, 111, 112, 49, 50, 105, 59, 64, 106, 110, 87, 85, 79, 31, 32) | 5–4 | 79 yes |

**So Route R does not need a map built — it needs one extended.**

### 9.2 …but it covers exactly one of our 20 periods

Of the 11 representative families behind our 20 one-dimensional-block periods,
only `CF267`, `CF384`, `CF385` appear as a `CanonicalFamily` at all, and only
one entry matches a period master *including its indices*:

* **T121 = `GLI[CF385,{1,1,1,1,1,1,1,1,1}]` = our PeriodID 30.** Match.
* T120 is `CF384{1,…,1}`; our CF384 period master is `{1,1,1,0,1,0,1,1,1}` — different.
* T110 is `CF267{1,1,1,1,1,1,1,1,0}`; ours is `{1,1,1,0,1,1,1,1,0}` — different.
* `CF1, CF123, CF124, CF199, CF212, CF236, CF413, CF415` — absent entirely.

**Coverage: 1 of 20.** That is the honest unbudgeted item: extending the
template census to the 11 remaining masters, not inventing an index map.

## 10. The 1x1 sweep — all 20 analyzed

`sweep.wls` located every representative in its family DE, extracted the scalar
diagonal, the stratum residues, and the coupling structure.
**Control passed:** CF1 reproduced `probe_CF1.wl` exactly (row 2, residues
`<|soft->0, vEdge->-eps, wEdge->0|>`, lower coupling `{1}`).

Every one of the 20 has **soft diagonal residue 0**, consistent with
`FrobeniusExponent 0` at soft.

### 10.1 Two difficulty axes

The DE row order in the stored basis is *not* topological, so "couples to a
higher row" does not break triangularity — it just means the driver sits later
in the stored list. The load-bearing numbers are **how many masters drive the
block** and **how many uncut denominators the integral has**:

| PID | family | uncut denom | driving masters | status |
|---|---|---|---|---|
| **1** | CF1 | **1** | **1** (the volume) | **SOLVED = 0** |
| **6** | CF124 | **1** | **1** (the volume) | **SOLVED = 0** |
| **7** | CF124 | **1** | **1** (the volume) | **SOLVED = 0** |
| 2, 3 | CF123 | 3 | 3 | unresolved |
| 28 | CF384 | 4 | 4 | unresolved |
| 14, 15 | CF212 | 4 | 6 | unresolved |
| 21–24 | CF267 | 4 | 6 | unresolved |
| 32 | CF415 | 4 | 6 | unresolved |
| 16, 17 | CF236 | 4 | 7 | unresolved |
| 8 | CF199 | 4 | 9 | unresolved |
| 4, 5 | CF124 | 4 | 11 | unresolved |
| 31 | CF413 | 6 | 23 | unresolved |
| 30 | CF385 | 6 | 40 | unresolved |

**Result: 3 solved, 17 resist.** They are flagged, not forced.

### 10.2 Why the cut is exactly at 1 denominator

All 12 distinct masters share the *same* 3-body cut phase space — every family
has `cut_propagators [1, 2, last]` with the last being
`ka+kb-kc-ke-kf`. So the frame, the measure
`dmu = x^(1-2eps)(1-x)^(-eps)(y(1-y))^(-eps)` and the chart are **reusable
across all 20**. What changes is the denominator count:

* **1 denominator** -> the integrand depends on one angle only, so the
  2-variable `(x,y)` chart closes it. Both such masters were solved.
* **>=3 denominators** -> the integrand resolves `ke` and `kf` separately
  against `ka, kb, kc`, needing the full **5-variable** cut parametrization.
  That is a different piece of infrastructure, not a longer version of the same
  one — which is exactly why these resist rather than merely cost more.

### 10.3 PeriodID 6 and 7: the second and third closed forms

CF124's period master is `gli[CF124,{1,1,0,0,1,0,1,0,0}]`, DE row 6 of 12,
and the sweep shows its **only** couplings are to rows `{5,6}` — row 5 being
`gli[CF124,{1,1,0,0,0,0,1,0,0}]`, the phase-space volume. Structurally
identical to CF1. Diagonal: `Av = Aw = -eps/(v+w)`.

Its single uncut propagator collapses to a strikingly simple form:

```
D5 = (kc+ke+kf)^2 = 1 - 2 kg.(ka+kb)   ->   D5 = 1 - x s - x(1-s) y
```

(using `P+kc = ka+kb`, `2ka.kb = 1`). Integrating `x` first,

```
R124(s,eps) = Int_0^1 dy (y(1-y))^(-eps) 2F1(1, 2-2eps; 3-3eps; s+(1-s)y) / B(1-eps,1-eps)
```

**Verification.** The soft limit is reproduced to ~30 digits:

| eps | computed | exact `(2-3eps)/(1-2eps)` | agreement |
|---|---|---|---|
| 1/10 | `2.12499999999999999999999999999999999999999998868…` | `17/8` | 0 to **29.7 digits** |
| 1/5 | `2.33333333333333333333333333333333333333333331579…` | `7/3` | 0 to **29.6 digits** |

**The period is 0, determined non-circularly.** If the `s^0` mode of the master
were nonzero, `R = master/V3` would blow up like `s^(2eps-1)` as `s->0` — at
`eps=1/10` that is `s^(-0.8)`, a factor ~9 over the sampled range. Measured
instead:

```
s   = 1/2     1/4     1/8    ...  ->  0
R   = 2.9543  2.4465  2.2703 ...  ->  2.125 = (2-3eps)/(1-2eps)
```

*decreasing* monotonically to the finite soft value. No `s^(2eps-1)` branch
exists, so the `s^0` coefficient vanishes: **PeriodID 6 = PeriodID 7 = 0**,
by the same mechanism as PeriodID 1 (the phase-space volume suppression
`s^(1-2eps)` is not compensated by the single propagator).

## 11. The decisive 9-propagator re-test (PeriodID 30) — Route Q's step is NOT a no-op

The stopping condition did **not** trigger: PID 30's integrand did not need a
map that is missing, because **T121 already carries it** (§9.2). Codex's
catalog Class 4 gives the fully rationalized 4-fold density over
`{rz, ra, ru, rv}`, `DenominatorCount 6`, `DistinctDenominatorCount 4`,
`DifficultyTuple {6,6,2}`, `RhoValuation 1`, `KnownSolvedQ False`.

### 11.1 The divergence, derived exactly

The four distinct denominators all factor as a **sum of two squares** —
verified exactly at 400 random rational points (`verify_denoms.py`):

```
P1 = [(1+rz^2) - 2 ra ru rz]^2 + rv^2 [(1+rz^2) + 2 ra ru rz]^2
P2 = [ra(1+rz^2) + 2 ru rz]^2  + rv^2 [ra(1+rz^2) - 2 ru rz]^2
P3 = [ru(1+rz^2) + 2 ra rz]^2  + rv^2 [ru(1+rz^2) - 2 ra rz]^2
P4 = [ra ru(1+rz^2) - 2 rz]^2  + rv^2 [ra ru(1+rz^2) + 2 rz]^2
```

In the physical chamber (`ra,ru,rv>0`, `0<rz<1`):

* `P2`, `P3` **can never vanish** (their `A` would need a negative sum) — and
  they are precisely the two that appear **squared**. They are harmless.
* `P1` and `P4` **do** vanish, on codimension-2 loci at `rv->0` with
  `ra ru = (1+rz^2)/(2rz) >= 1` and `ra ru = 2rz/(1+rz^2) <= 1` respectively.

Power counting there: the measure carries `rv^(-2eps)`; setting `A1 = rv beta`,
`1/P1 = 1/(rv^2(beta^2+B1^2))` and `dA1 drv = rv dbeta drv`, so the integrand
behaves as

```
rv^(-1-2eps) dbeta drv      =>   Int_0 rv^(-1-2eps) drv   converges iff eps < 0
```

This **independently reproduces the catalog's stored
`ConvergenceAssumptions: -1/2 < ep < 0`**.

### 11.2 The measured answer

| | PeriodID 1 / 6 / 7 (1 denominator) | **PeriodID 30 (6 denominators)** |
|---|---|---|
| convergent at `eps=0`? | **yes** | **no** — diverges |
| quasi-finite shifts needed | **0 (no-op)** | **>= 1** |
| what cures it | nothing to cure | `d -> d+2` sends `rv^(-1-2eps)` to `rv^(1-2eps)` |
| Route Q's step exercised? | **no** | **yes** |

**This is the result the base report said the pilot was missing.** The DEFER
verdict rested on the claim that the cheapest period cannot exercise Route Q's
machinery and that a 9-propagator period would. That claim is now confirmed
from both sides, with zero compute on the second one: the same construction
that is a no-op at 1 denominator is *mandatory* at 6.

**What is still not measured** is Route Q's *cost* at that tier — the shift
count is `>= 1` and one dimension shift cures the endpoint I isolated, but
whether a single shift makes the whole integral finite (all faces, not just the
`rv->0` one) needs the full tropical/Newton-polytope scan. I did not run it, so
I do not claim it. The honest statement is: **shift count >= 1, benefit
established, cost still open.**

## 12. Realization-transfer caveats (per period, explicit)

**12 of 20** periods carry the caveat: the representative basis is written in a
family that is *not* among the families where the period is actually flagged
undetermined. For those the value — where established — holds for the
**evaluated realization only**. Cross-family dedup was **not** verified.

| PID | evaluated realization | unchecked realizations |
|---|---|---|
| **1** | CF1 | **CF300** |
| **6** | CF124 | **CF21, CF226, CF23, CF248, CF253, CF53, CF57, CF91, CF97** |
| **7** | CF124 | **CF299, CF300** |
| 3 | CF123 | CF13, CF18, CF384, CF385, CF52, CF56, CF97 |
| 5 | CF124 | CF13, CF18, CF26, CF33 |
| 8 | CF199 | CF299 |
| 15 | CF212 | CF413, CF56 |
| 17 | CF236 | CF404, CF90 |
| 22 | CF267 | CF385, CF413, CF48, CF57 |
| 23 | CF267 | CF388, CF407 |
| 24 | CF267 | CF390 |
| 32 | CF415 | CF416, CF420 |

No caveat (representative family is itself among the undetermined families):
PIDs 2, 4, 14, 16, 21, 28, **30**, **31** — though 2/14/16/21/28 still have
*additional* families whose realizations were not checked.

**For the exchange with Codex:** the three zeros established here are
`PeriodID 1 (CF1)`, `PeriodID 6 (CF124)`, `PeriodID 7 (CF124)`. Whether they
transfer to `CF300`, `CF299`, and the nine CF124-class families listed above is
an open question that their dedup convention should settle. I am not claiming
it.

## 13. Updated recommendation

The base verdict (**defer**) is unchanged but is now resting on measurement
rather than inference, and two of its supporting claims moved:

1. **Route Q's benefit is real at the top tier** (§11) — confirmed, not
   conjectured. Its cost there remains unmeasured.
2. **Route R's blocker was misdiagnosed twice, and the third diagnosis has now
   been tested — see §18.** Not the unregulated denominator (§5.2 hypothesis,
   refuted: the trivial textbook integral failed too), and not a missing index
   map (§9.1, refuted). The failure is `ConnectKernel::failinit` /
   `LinkObject::linkd` — SubTropica cannot spawn its helper kernels, with no
   HyperFLINT native library present in the tree. I guessed that Codex's
   `"Kernels" -> 1` was the workaround; **that guess was tested and is wrong on
   the raw-Euler entry point** (§18).
3. **The stage is cheaper than 33 periods of work.** Three periods are now
   exactly `0`, all by the same mechanism, and all three were the entire
   1-denominator tier. The counter's `N_new` is an upper bound and it is loose
   at least here.

**Next test, in priority order:**

* re-run Route R with `"Kernels" -> 1` and `"Integrator" -> "HyperIntica"` on
  the soft integral whose exact value is known (§5) — a one-line change that
  decides whether Route R is usable at all in this environment;
* run the full tropical scan on T121 to turn "shift count >= 1" into an exact
  number and a cost;
* extend the template census to the 11 uncovered masters (§9.2), which is what
  actually unblocks Route R for our list.

## 14. Head start on the next tier (PeriodIDs 2 and 3, CF123)

Not attempted — but partly reduced, since the reduction is the expensive part
and this is the cheapest remaining target (3 denominators, 3 drivers).

CF123's period master `gli[CF123,{1,1,1,1,0,1,1,0,0}]` has cuts `{1,2,7}` (the
same 3-body phase space again) and three uncut denominators, which simplify to:

```
D3 = (kf - ka)^2            = -2 ka.kf
D4 = (ke + kf - ka)^2       = -w - 2 kg.(kb - kc)      [using P - ka = kb - kc]
D6 = (ke - P)^2             = s (1 - x_e)              [x_e = 2E_e/M]
```

`D6` collapses completely — it depends only on the **energy** of `ke`, not on
any angle. So of the three, only `D3` and `D4` carry angular dependence, and
they do so against **two different reference directions** (`ka` for `D3`,
`kb-kc` for `D4`). That is precisely why the 2-variable `(x,y)` chart fails
here and a 4-fold parametrization (2 Dalitz variables + 2 orientation angles)
is needed.

**Estimated shape of the work:** build the general 3-body cut parametrization
once, with two independent reference vectors; it then serves PIDs 2, 3 and
plausibly the whole 4-denominator tier (13 periods), since every family shares
the same cut structure. That is the single highest-leverage build remaining —
it converts the "17 resist" number into something much smaller.

## 15. Extension artifacts

| file | role |
|---|---|
| `periods/period_NN.wl` (20 files) | per-period exchange-schema certificates |
| `periods/sweep_all.wl` | raw DE-side structure for all 20 |
| `sweep.wls` / `sweep.log` | the sweep (CF1 control passed) |
| `stageB.wls` / `.log` / `stageB_result.wl` | CF124 closed form + 30-digit soft check + CF1 control |
| `stageB2.wls` / `.log` | CF124 vs Kira; Route R retry with `"Kernels"->1` |
| `diag.wls` / `diag.log` | SubTropica failure diagnosis (`ConnectKernel::failinit`) |
| `extract20.py`, `difficulty.py`, `census.py` | period selection and tiering |
| `extract_t121.py` | pulls PID 30's rationalized density from Codex's catalog |
| `verify_denoms.py` | exact check of the 4 sum-of-two-squares factorizations |
| `gen_certificates.py`, `validate_certs.py` | certificate emission and validation |

All certificates pass a balance + required-key validation (`validate_certs.py`:
20/20 files, no missing keys, no unbalanced brackets).

## 16. The exact DE check for the three solved periods (done seat-free)

The coordinator's battery asks for an exact DE check plus at least one 25-digit
numeric point per solved period. Both are now in hand for PIDs 1, 6, 7. The DE
entries were extracted directly from the stored matrices by brace-matching
(`parse_de.py`), with no Wolfram seat:

| | CF1 (PID 1) | CF124 (PIDs 6, 7) |
|---|---|---|
| `A[period, volume]` | `(-2+3eps)/(v(v+w-1))` | `(2-3eps)/((v+w-1)(v+w))` |
| `A[period, period]` | `-eps/v` | `-eps/(v+w)` |
| `A[.,vol]*s` as `s->0` | `(2-3eps)/v` | `-(2-3eps)` |
| DE-forced soft limit | `(3eps-2)/((1-2eps) v)` | `(2-3eps)/(1-2eps)` |
| my reconstruction | matches (30 digits) | `2.12499999999999999999999999999999999999999998868` vs `17/8` |
| agreement | ~30 digits | **29.7 digits** (and 29.6 at `eps=1/5`) |

Both use the same scalar ODE `s dR/dv = (1-2eps) R + A_vol s + A_diag s R`,
whose `s->0` limit kills `A_diag s R` and leaves `0 = (1-2eps)R + lim(A_vol s)`.

**This upgrades the CF124 evidence from self-consistency to a genuine
cross-check**: the value `(2-3eps)/(1-2eps)` is now derived from Kira's
IBP-reduced connection *and* from my independently reconstructed parametric
integral, which agree to ~30 digits. The identification
`D5 = (kc+ke+kf)^2 = 1 - x s - x(1-s) y` is therefore confirmed, not assumed.

**And the branch selection stays non-circular.** The DE admits two behaviours,
`R` finite or `R ~ s^(2eps-1)`; the DE fixes the *value* on the finite branch
but cannot say which is realized. The numerics select it: `R` measured at
`s = 1/2 ... 1/32` decreases to the finite value instead of rising by the ~9x
that the `s^(2eps-1)` branch would produce. Hence the `s^0` mode is absent and
the period is `0` — the same two-step logic (DE for the value, integral for the
branch) used for PeriodID 1 in §3.2.

## 17. One job intentionally left running

`stageB2.wls` is **queued, not abandoned**. It never acquired a licence seat
during this session (the rung benchmark held both continuously), and it is left
polling under `seatrun.sh` so that it self-runs when a seat frees.

* Its **CF124 exact DE check** is *not* pending — that was completed seat-free
  by brace-parsing the stored DE matrices (§16, `parse_de.py`).
* What it still uniquely provides is the **Route R retry** with
  `"Kernels" -> 1` and `"Integrator" -> "HyperIntica"`, testing the §13
  hypothesis that SubTropica's `$Failed` was helper-kernel spawning rather than
  the integrand. It first runs a 1-D sanity integral with the known answer
  `Beta[1-ep,1-ep]`; if that returns a series, the backend is alive and the
  soft-integral result is scoreable against the exact value in §5.

**UPDATE: it ran.** Results are in `stageB2.log` / `stageB2_result.wl` and are
written up in §16.1 (CF124 confirmed symbolically) and **§18 (the Route R retry
failed — hypothesis refuted)**. The §13 recommendation has been updated
accordingly; it is no longer an untested hypothesis, it is a closed question.

### 16.1 Machine confirmation of the seat-free derivation

`stageB2.wls` acquired a seat after the report was written and confirmed §16
symbolically, independently of the by-hand brace-parsing:

```
CF124/SOFT_MATCH        = True      (Simplify[-lim(s A65)/(1-2eps) - (2-3eps)/(1-2eps)] === 0)
CF124/DE_pred_at_ep_1_10 = 17/8     (= 2.125 exactly)
CF1/MATCH               = True      (same construction reproduces (3eps-2)/((1-2eps) v))
```

So the soft limit `(2-3eps)/(1-2eps)` is now an established symbolic identity of
the IBP-reduced connection, matched by the reconstructed parametric integral to
29.7 digits. The `parse_de.py` route and the kernel agree.

## 18. Route R retry: hypothesis tested, and refuted

> **SUPERSEDED BY §19 — READ THAT FIRST.** The defect claim in this section is
> **RETRACTED**. `"Kernels"` is not a raw `STIntegrate` option (it is Codex's
> wrapper's), so `FilterRules` discarding it was correct. The true cause was our
> regulator symbol (`ep` instead of SubTropica's `eps`), and with that fixed
> **Route R evaluates correctly** (§19.3). Section kept intact for the record.


`stageB2.wls` ran. The §13 recommendation ("re-run with `"Kernels" -> 1` and
`"Integrator" -> "HyperIntica"` — a one-line change that decides whether Route R
is usable") was carried out. **It does not fix it.**

```
R2/load                     = OK            (1.30 s)
R2/sanity_HyperIntica       = ERR           (26.61 s)
R2/soft_HyperIntica         = ERR           ( 0.0003 s)
ConnectKernel::failinit: 11 of 19 kernels failed to initialize.
LinkObject::linkd: ... wolfram -noinit -subkernel -wstp ...
```

Three things this settles:

1. **The integrand is exonerated for good.** `R2/sanity_HyperIntica` is
   `Int_0^1 x^(-ep)(1-x)^(-ep) dx = Beta[1-ep,1-ep]` — one variable, fully
   regulated, textbook. It failed too. No property of our boundary integrals is
   responsible.
2. **`"Kernels" -> 1` was not honoured.** SubTropica still attempted **19**
   subkernels. The package's own source explains why: on the
   `STIntegrate[integrand, x, ...]` raw-Euler route,
   `FilterRules[{opts}, Options[STEvaluateEulerIntegral]]` **silently strips**
   `"LROrderBackend"` and `"ScorePruneFactor"` (SubTropica.wl ~line 23646,
   which documents this as a known defect). The options never reached the
   backend, so forcing `"HyperIntica"` had no effect either.
3. **The environment cannot support the parallel path as invoked.** 11 of 19
   subkernels failed to initialize. With a 2-seat licence and a peer agent
   holding a seat throughout, mass subkernel launch is not viable here
   regardless of integrand.

### 18.1 What would actually have to be tried next

Not another option on the same entry point — that route strips them. Either:

* drive the **globals** the wrapper sets (`$STLROrderBackend`,
  `$STScorePruneFactor`) directly, or use `STIntegrateHF`, or the graph /
  propagator-list entry points, which take a different option path; or
* go through Codex's `EvaluateMasterBoundarySubTropica`
  (`/home/maxzhang/FACET/.../PackageCandidate_20260814/Private/MasterBoundaryIntegral.wl`),
  which reaches the engine by a different code path and is known to work for
  them; or
* cap parallelism outside the package (`$ProcessorCount`, or a
  `LaunchKernels` policy) before the call.

**Net effect on the verdict: unchanged, and better founded.** Route R produced
no number in this environment across three genuine attempts with three
different diagnoses, and the one route that did produce numbers was Route Q's
numeric path (15-19 digits/order, §5). That still does **not** license adopting
Route Q, for the reason in §0: on this period Route Q's distinguishing step was
a no-op. What it does license is a sharper statement of cost —
**Route R currently has a nonzero integration cost for us that is entirely
tooling, not mathematics.**

## 19. RETRACTION: the option-stripping claim in §18 was wrong

Codex corrected the diagnosis and they are right. Verified directly against
`SubTropica.wl` (no kernel needed):

| option | in raw `STIntegrate`? | default |
|---|---|---|
| `"KernelsAvailable"` | **yes** (`:21825`, `:21990`, `:23406`) | **`$ProcessorCount - 1`** |
| `"Parallelization"` | yes (`:21824`, `:23607`) | `All` |
| `"SetupInParallel"` | yes (`:21833`, `:23616`) | `Automatic` (`1` = serial, main kernel only) |
| `"Kernels"` | **NO — appears nowhere in the package** | — |

**What this retracts.** §18 item 2 claimed `"Kernels" -> 1` "was not honoured"
and blamed `FilterRules` silently stripping options. Both halves are wrong:

1. `"Kernels"` is **not** a raw `STIntegrate` option at all — it belongs to
   Codex's *wrapper*, which translates it internally. `FilterRules` discarding
   an option the function does not declare is **correct behaviour**, not a
   defect. We passed a wrong option name and then blamed the callee.
2. The `FilterRules` stripping I cited (SubTropica.wl ~23646) concerns
   `"LROrderBackend"` / `"ScorePruneFactor"`, and that same comment records the
   stripping as a **fixed** defect — the options are now declared and read into
   `$STLROrderBackend` / `$STScorePruneFactor`. I quoted the description of a
   repaired bug as evidence of a live one.
3. The "19 subkernels" is not mysterious and not a defect: it is exactly the
   documented default `"KernelsAvailable" -> $ProcessorCount - 1`. On a
   20-processor box that is 19. **Our own invocation asked for them.**

So the §18 heading "hypothesis tested, and refuted" stands only for the
*hypothesis about `"Kernels" -> 1`*; the accompanying **defect claim against
SubTropica is withdrawn**. Sections 0, 13 and 18 are superseded on this point
and are left in place with this pointer, so the full arc stays visible:
unregulated denominator (wrong) -> missing index map (wrong) -> option
stripping (wrong, and unfair to the tool).

**Standing lesson, recorded because it cost three rounds:** every one of my
three Route R diagnoses blamed something external, and the actual cause each
time was our own invocation or our own reading. The `ConnectKernel::failinit`
evidence was real; the inference drawn from it was not.

### 19.1 Retest status

Running `stageB3.wls` with Codex's prescription
(`"KernelsAvailable" -> 1`, `"Parallelization" -> "BruteForce"`,
`"SetupInParallel" -> 1`) against two targets with known exact values: the
textbook `Beta[1-ep,1-ep]` control and the **PID-1 soft density**, whose exact
value is `Beta[1-ep,1-ep] Beta[2-2ep,1-ep] (2-3ep)/(1-2ep)`.

**PENDING at the time of writing** — queued third behind the GPL agent and the
nullity agent's CF407 comparison. Outcome recorded in §19.2 either way:
a working invocation becomes the reference driver pattern; a failure *with the
correct options* becomes a clean defect report.

### 19.2 Retest outcome: the prescription works, and it uncovers a different failure

`stageB3.wls` ran with Codex's exact prescription. **Their correction is
confirmed materially, not just verbally.**

```
env/ProcessorCount            = 20
opt/KernelsAvailable_default  = 19          (= $ProcessorCount - 1, as documented)
opt/Parallelization_default   = All
opt/SetupInParallel_default   = Automatic
opt/Kernels_present           = False       (confirms "Kernels" is not a raw option)
```

With `"KernelsAvailable" -> 1, "Parallelization" -> "BruteForce",
"SetupInParallel" -> 1`:

* **`ConnectKernel::failinit` and `LinkObject::linkd` are GONE.** The
  19-subkernel storm was our own invocation asking for `$ProcessorCount - 1`
  subkernels. Suppressing it works exactly as Codex said it would.
* The `-> 1` option is therefore honoured. **Our defect claim is dead**; §19
  stands as a retraction.

But both integrals still fail, now with a *different and much cleaner* error:

| target | time | result | messages |
|---|---|---|---|
| textbook `Int_0^1 x^-ep (1-x)^-ep dx` | 0.29 s | `ERR` | `STFindLROrdersHF::hferror`, `STEvaluateEulerIntegral::noepsNOLR` |
| PID-1 soft density | 0.02 s | `ERR` | same pair (twice) |

`STFindLROrdersHF` is the **HyperFLINT** linearly-reducible-order finder, and
there is **no HF native library anywhere in the SubTropica tree** (checked:
zero `.so`/`.dylib`). The package's own documentation says the dynamic default
`stDefaultSymbolicBackend[]` uses "HyperFLINT when a usable HF install is
present, otherwise the built-in HyperIntica" — so either the availability probe
is returning a false positive here, or HF is genuinely expected to be
installed and is not.

**This is a materially better failure than what we had.** It is reproducible on
a one-line textbook integral with a known answer, it arises from correct
options, and it names a specific component. Whether it is a *defect* or merely
a *missing optional dependency on our box* turns on one more test — correct
prescription plus `"Integrator" -> "HyperIntica"` and
`"LROrderBackend" -> "HyperIntica"`, the one combination never yet tried
(stageB2 forced the backend but with the wrong kernel option, so the subkernel
failure masked the outcome). That is `stageB4.wls`; result in §19.3.

### 19.3 Outcome: Route R WORKS. There was never a SubTropica defect.

`stageB6.wls` evaluated the PID-1 soft Euler density correctly:

```
b/pid1_soft = SeriesData[eps, 0, {{{1, {}}}}, 0, 1, 1]     (0.68 s)
b/residual  = eps(-10 + eps(-38 + Pi^2))/2
```

The `eps^0` coefficient is **1**, which is exactly the `eps^0` coefficient of
the known closed form `Beta[1-eps,1-eps] Beta[2-2eps,1-eps] (2-3eps)/(1-2eps)
= 1 + 5 eps + (38-Pi^2)/2 eps^2 + ...`. The residual is precisely the
un-requested higher orders (`5 eps + (38-Pi^2)/2 eps^2`), because the default
`"Order" -> Automatic` stops at the finite part. **Route R produced a correct
number against known ground truth.**

### 19.4 The reference driver pattern

```wolfram
Needs["SubTropica`"];
(* 1. REGULATOR: must be SubTropica`eps -- bare `eps` AFTER Needs. *)
(*    Using `ep` makes FreeQ[integrand, eps] True (SubTropica.wl:7882), so the *)
(*    eps-expansion is BYPASSED and the integrand is dispatched to the         *)
(*    HyperFLINT LR search, which fails if HF is not built.                    *)
(* 2. VARIABLES: avoid x, y -- SubTropica exports them (Global`x::shdw).       *)
(* 3. PARALLELISM: pin it, or it requests "KernelsAvailable" ->                *)
(*    $ProcessorCount-1 subkernels (19 on this box) and they fail to launch.   *)
(* 4. BACKEND: force HyperIntica unless HyperFLINT is actually built           *)
(*    (there is no HF library in our tree; the dynamic default still picks it).*)
SubTropica`STIntegrate[
  u1^(1-2 eps) (1-u1)^(-eps) (u2 (1-u2))^(-eps)/(1 - u1 u2),
  {u1, 0, 1}, {u2, 0, 1},
  "KernelsAvailable" -> 1, "Parallelization" -> "BruteForce",
  "SetupInParallel" -> 1,
  "Integrator" -> "HyperIntica", "LROrderBackend" -> "HyperIntica",
  "Order" -> n]                      (* default stops at the finite part *)
```

### 19.5 The full arc — five wrong diagnoses, all ours

| # | claimed cause | verdict |
|---|---|---|
| 1 | unregulated `1/(1-xy)` in the integrand | **wrong** — trivial textbook integral failed too |
| 2 | missing CF-class <-> template index map | **wrong** — the map exists (`BoundaryTemplateTopologies.wl`) |
| 3 | `FilterRules` silently stripping `"Kernels"` | **wrong** — `"Kernels"` is not a raw option; dropping it was correct |
| 4 | HyperFLINT auto-selected despite no library | **real but not the blocker** — we were in the eps-free branch, which calls HF unconditionally |
| 5 | (harness) `Order -> 1` "fails" | **wrong** — `Check[expr,"ERR"]` fired on a *benign one-shot warning* (`nocarrymma`) |

The actual cause was **the regulator symbol**: we wrote `ep`, SubTropica routes
on its own `eps`. One symbol, five rounds.

**The honest lesson for the exchange note.** Every failure in this saga was on
our side, and each time the evidence was real while the inference was not.
`ConnectKernel::failinit` was real — caused by our own `$ProcessorCount-1`
default. `hferror` was real — caused by our own eps-free misrouting. What kept
going wrong was reaching for "the tool is broken" before "we called it wrong".
The one habit that eventually worked was reading the *message text* instead of
the message *name*: `noepsNOLR` spells out "it carries no eps regulator", which
named the true cause immediately and had been sitting in the logs since §5.

### 19.6 What this does to the verdict

**Route R is usable.** That removes the tooling asymmetry that §13 leaned on,
so the R-vs-Q comparison is now genuinely open rather than decided by our
inability to run one side. It does **not** change the DEFER recommendation,
whose basis is untouched: on PeriodID 1 Route Q's shift is a no-op (§4), and the
period is 0 by a route neither R nor Q supplied (§3.2). What it does change is
the *next* experiment — a fair head-to-head is now possible on the 9-propagator
tier, where §11 established that Route Q's machinery is actually exercised.

Higher `eps` orders on the pure-Mathematica backend are still open (`Order -> 1`
and `2` need re-testing with the corrected harness; `stageB8.wls`). If they need
HyperFLINT, then **building HF becomes a real, costed prerequisite for Route R**
— that would be a genuine infrastructure finding rather than a defect report.

### 19.7 Route R scored per eps order — and one more harness bug of mine

With the reference driver pattern (§19.4), `stageB8.wls` ran the PID-1 soft
density at four truncation orders. **Every call returned, none errored, all
under one second:**

| requested `"Order"` | wall | result head | residual vs exact |
|---|---|---|---|
| 0 | 0.72 s | `SeriesData` | **0** |
| 1 | 0.73 s | `List` | **0** |
| 2 | 0.78 s | `SeriesData` | *unscored (my bug)* |
| 3 | 0.85 s | `SeriesData` | *unscored (my bug)* |

So **Route R reproduces the exact closed form
`Beta[1-eps,1-eps] Beta[2-2eps,1-eps] (2-3eps)/(1-2eps)` with zero residual at
`eps^0` and `eps^1`, in about 0.7 s per order.**

The `eps^2` / `eps^3` rows are *not* a SubTropica failure. SubTropica returned
normally; my comparison broke. Its `SeriesData` coefficients are
**`{coefficient, hyperlogarithm-word}` pairs** — `{1,{}}` is `1 x` the empty
word (hence the `eps^0` value `1`), `{0,{{0,0}}}` is a weight-2 `Hlog`.

I then guessed the fix was to `Total` each coefficient to all depths
(`stageB9.wls`). **That guess was also wrong** — `Total` cannot evaluate on
`{number, list}` pairs, so it came back unevaluated exactly as before. The
documented option for this is `"CleanOutput" -> True`, which applies
`CleanZeroInf[]` to the final result (SubTropica.wl:23620); that is
`stageB10.wls`, **queued and NOT yet confirmed** — it is recorded here as a
hypothesis, not a result, which is the whole lesson of this section.

So the `eps^0` value is verified against ground truth (`1`), `eps^1` scored
residual zero in `stageB8`, and `eps^2`/`eps^3` remain **unscored** — with
SubTropica having returned normally in <1 s at every order.

**That is the sixth and seventh invocation/harness fault in this saga, and the
second and third in the scoring code alone** (after the `Check[expr,"ERR"]`-fires-on-a-warning bug of
§19.5). The pattern is now unmistakable and worth stating for the exchange
note: in this pilot, *every single* apparent Route R failure was produced by the
caller, never once by the callee. When a tool this mature reports something odd,
the prior should be strongly on our invocation.

**Cost datum for the R-vs-Q comparison (finally measurable).** Route R:
~0.7 s per eps order on the PID-1 soft integral, exact symbolic output, zero
residual at the two orders scored so far. Route Q (§5): ~15-19 digits per order
numerically, a couple of minutes for four orders. On this period Route R is both
faster and exact — but the caveat of §0 stands undiminished: this period never
exercised Route Q's shift, so this is not yet a verdict on the method.
