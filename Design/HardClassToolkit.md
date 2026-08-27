# HARD-CLASS TOOLKIT — a standard attack ladder for non-canonicalizable DE blocks

`HardClassToolkit.wl`, driver `AttackClass[classData, opts]`.
Status: acceptance-gated on class 115; applied to 77, 97; R1-only cross-check on 79.

The point of this file is that **a failed attack must leave the next agent
strictly better informed**. Every rung emits a certificate or a named
obstruction, and the driver's `R5Obstruction` field is the handoff.

---

## Why a ladder

CANONICA answers one question — "is there a rational gauge to eps-form in the
given chart?" — and when it says no (or times out) it says nothing about *why*.
The three recorded failure modes in this campaign were all different:

| class | CANONICA behaviour | actual cause |
|---|---|---|
| 115 | instant refusal | the block is secretly **one-variable**; `A_v` vanishes identically in any rationalizing chart, so it was handed a null direction |
| 97 | 2400s, proven obstructed | (see report) |
| 79 | timeout at degrees 0 and 1 | non-Fuchsian double pole + an eps-dependent apparent letter inflate the required ansatz degree |

None of these is "the ansatz degree was too low". The ladder exists so that the
diagnosis is produced mechanically instead of by inspiration.

---

## The ladder

### R1 — structure diagnostics (seconds, symbolic)

**R1a — one-variable dependence.** Generalizes the class-115 mechanism. Tests
`[Av,Aw] = 0` and whether `Aw = rho*Av` for a *scalar* rational `rho`. If so the
two matrices are `M*dz/dv` and `M*dz/dw` for a common `M`, the level sets of `z`
obey `dv/dw = -rho`, and `z` is recovered **mechanically** as the first integral
of the linear PDE `-rho d_v z + d_w z = 0` — no ansatz, no guessing. The rung
then verifies that `M = Av/(d_v z)` really depends on `(v,w)` only through `z`.

This is the cheapest rung and the highest-value one: a positive answer collapses
a "hard 2-variable block" to a 1-variable ODE, where the whole classical theory
applies. Codex adopted it as their standard early check.

**R1b — apparent-singularity census.** Any singular locus whose *position*
depends on eps is necessarily apparent: Landau loci are eps-independent. For
rank-1 residues with integer trace `n` the spectral projector is `P = R/n` and
the balance is `T = (1-P) + L*P`, `T^-1 = (1-P) + P/L` — no matrix inverse
needed.

> **The balance is REPORTED, never applied.** Measured 2026-08-14: applying a
> pre-balance before a rational-ansatz search is *destructive* (class 26:
> 347s success -> 946s failure; class 33: 623s -> 1202s timeout; class 77:
> +87s for nothing). "Removing a letter is not simplifying the system."
> Balances are safe only inside routes that never run such a search — i.e.
> inside R2/R3, not before CANONICA.

**R1c — exponent census.** Per locus: pole order in both directions, residue
matrix, eigenvalues, algebraic vs geometric multiplicity (Jordan structure), and
a classification of each exponent's eps->0 limit as integer / half-integer /
other. Half-integer flags *which square root the answer needs*; pole order > 1
flags non-Fuchsian loci that need Moser reduction before anything else.

> **The rank-1 trace shortcut is a correctness requirement, not an
> optimization.** On an algebraic locus (the Kallen curve) the residue is
> evaluated where `w` carries a `Sqrt`, and `Eigenvalues` returns an
> unsimplified expression in `Sqrt[-v]`. The half-integer detector then
> classifies it "unrecognized" and the census reports **zero** half-integer
> loci — a false negative on precisely the obstruction the rung exists to
> find (measured on class 79 before the fix). These residues are rank 1, so
> the single nonzero eigenvalue *is* the trace, which simplifies cleanly.
> `HCTHalfIntegerQ` is defined through `HCTExponentClass` so the two cannot
> disagree.

**The hard-class signature.** Measured on 77 and 79, the same defect triple
recurs: one non-Fuchsian double pole, one eps-dependent (hence apparent)
letter, and one half-integer exponent on a Kallen locus. "Hard class" is not a
grab-bag — it is this signature, and R1 identifies all three in seconds.

**R1d — invariant subspaces.** Two cheap probes: strong connectivity of the
support digraph (a permutation to block-triangular form), and rational
eigenvectors of `Av` that span a genuine rank-1 sub-D-module — the correct test
is that `Av.y - d_v y` and `Aw.y - d_w y` are both parallel to `y`, *not* plain
matrix invariance. A negative result here does **not** prove irreducibility; the
definitive answer comes from R3 factorization. The rung says so in its output.

### R2 — cyclic-vector scalar reduction

Covector recursion `c_{k+1} = d_x c_k + c_k.A` for `y = c.F`; the block becomes
one scalar ODE of order = dim. Several cyclic vectors are tried and scored by
`LeafCount` of the resulting coefficients.

> **Tie-breaking must be deterministic.** `SortBy` breaks ties by canonical
> order of the whole expression, which on class 115 silently selected `e2`
> (component `F2`) over `e1` (`F1`) at equal LeafCount and produced a *correct
> but incomparable* identification (`b = 3/2+2eps` instead of the recorded
> `1/2+2eps`). Ties are now broken by candidate index.

If R1a fired, the reduction is done in the invariant `z`; otherwise in `v` with
`w` a spectator parameter.

### R3 — operator identification

Local exponents come from the indicial polynomial at every singular point plus
infinity, computed by lowest-order extraction (`y = t^s`, resp. `y = x^-s`).
The Fuchs relation `sum of exponents = n(n-1)/2 * (#points - 2)` is checked as a
free consistency test on the whole scheme.

- **order 2 with exactly 3 singular points** => Riemann P => Gauss `2F1`, and
  the parameters follow *by theorem, not by matching*: map the points to
  `{0,1,inf}` by a Mobius transformation and read
  `a = a1+b1+g1`, `b = a1+b1+g2`, `c = 1+a1-a2` off the scheme, with solution
  `X^a1 (1-X)^b1 2F1(a,b;c;X)`. All eight branch choices are enumerated.
- **order 3/4**: necessary exponent-pattern tests before declaring the operator
  genuinely higher — `Sym^2`/`Sym^3` of an order-2 force the exponents at every
  point into arithmetic progression; a tensor product of two order-2s forces
  `e1+e4 == e2+e3` at every point.
- Leading-coefficient factorization is reported **always**, even when the
  explicit singular points cannot be solved for — that factorization is the
  minimum useful handoff.

**R3 reconciliation (do not skip this).** Scalar-ODE exponents and system
residue eigenvalues are *different objects*. The scalar ODE for `y = c.F`
exceeds the system exponent by a non-negative integer at any locus where that
component of the corresponding eigenvector vanishes. On class 115 at `vw=1/4`
the residue is `[[0,0],[*,-(3+8eps)/2]]`: the eigenvector for the nonzero
eigenvalue has vanishing `F1` component, so

- system exponent = `-3/2-4eps` (this is what a residue-eigenvalue table reports)
- `F1`-component exponent = `-1/2-4eps` (this is what the `2F1` parameters imply)
- `F2` carries `-3/2-4eps`

Two correct records therefore *look* contradictory when read side by side. R3
now prints both and the integer shift at every matched locus.

### R3b — rationalize the square-root letter

When R1c reports a half-integer exponent on a *quadratic* locus, that locus is a
conic and is very often rationalizable in closed form. For the Kallen curve
`lambda(1,v,w) = (1-v-w)^2 - 4 v w`, which is shared by classes 77 and 97,

```
v = x y ,   w = (1-x)(1-y)      =>   lambda = (x - y)^2 ,   sqrt(lambda) = x - y
```

Push the connection through by the chain rule
(`A_x = A_v dv/dx + A_w dw/dx`, likewise for `y`) and re-run R1c in the new
variables. The half-integer exponent **doubles** to an integer — measured on
class 97: `1/2+eps` on the Kallen curve becomes `1+2eps` on the letter `x-y`.

This is the cheapest possible resolution of a square-root obstruction and costs
about half a second. Run it before concluding that a class is obstructed: a
CANONICA verdict of "obstructed" is a statement about the *chart*, not about the
block. See the class-97 entry below.

> ### The alphabet trade-off: structure bought, letters paid
>
> **Rationalizing is not free. It removes a square root and adds letters, and
> ansatz cost scales with the alphabet.** Measured on this pair:
>
> | class | letters in `(v,w)` | letters in the chart | half-integer |
> |---|---|---|---|
> | 97 | 5 | 7 | gone |
> | 77 | 6 | 8 | gone |
>
> Both gained **two** letters. The chart genuinely removes the obstruction —
> class 97 goes from "half-integer exponent, no rational eps-form possible" to
> Fuchsian with integer exponents throughout — and CANONICA at degree 0 in that
> chart still **timed out at 1200s** where the campaign's earlier failures in
> the original frame were *fast refusals*. A timeout is not a refusal: the
> ansatz search stayed viable and ran out of budget.
>
> ### "Structurally clean" is not "computationally cheap"
>
> These are two different claims and this session conflated them once. Keep
> them apart in writing and in ledgers:
>
> - **Structural**: does a rational eps-form *exist* in this frame? Decided by
>   R1c — exponents integer, alphabet eps-independent, all poles Fuchsian.
>   Costs seconds. For class 97 in the chart the answer is yes.
> - **Computational**: can CANONICA *find* the transformation within a cap?
>   Decided by the ansatz search, and driven by alphabet size, dimension and
>   degree. For class 97 in the chart, not at degree 0 within 1200s.
>
> R1 licenses the first claim only. Reporting "favorable for CANONICA" on R1
> evidence alone overstates it — say "no structural obstruction in this frame;
> ansatz cost untested".
>
> **Corollary for the degree ladder:** if degree 0 *times out*, do not escalate.
> Degrees 1 and 2 use strictly larger ansaetze and are near-certain to time out
> too. A timeout says "this system is too big for this cap", which a higher
> degree makes worse, not better. Escalate only past a *refusal*, which says
> "no transformation of this size exists". Confusing the two is how the
> wholesale-chart sweep lost about an hour (WORKLOG 2026-08-13).

### R4 — certification against the ORIGINAL system

The cyclic-vector reduction is an exact equivalence, so for the `2F1` route it
suffices to show the reduced operator *is* the Gauss operator identically:
substitute `X^p (1-X)^q F[X]`, eliminate `F''` by the Gauss equation, and demand
that the coefficients of `F` and `F'` vanish **separately** (they are
independent — a single `Simplify[resid == 0]` is not a proof). Certificate
grade is recorded: exact-symbolic, or high-precision numeric with
`$MaxExtraPrecision`, never conflated.

### External algebraic-geometry probes (Codex-measured, adopted 2026-08-15)

Before R3 declares an operator unidentifiable, probe with the
free-CAS quartet Codex measured (their Exchange/
CodexBoundaryFindingsPlan_2026-08-15.md): **ore_algebra** for
singularities/indicial equations of the reduced scalar operator;
**PassageMath/SageMath** for genus and exact rational parametrization
of the maximal-cut curve (CF231's conic fell to this); **QEPCAD** for
exact sign/chamber decisions; **Singular gmssing.lib** for Bernstein
polynomials. Also: Maxima/FriCAS Kovacic for order-2 pieces (free;
policy: probe existing CAS before any bespoke identification code —
user ruling 2026-08-15). All candidates still pass R4's exact
certificate; foreign-CAS provenance is recorded in the class record.

## R5 — report

Per-rung findings, timings, certificates, and the precise forwarded obstruction.

---

## Budget discipline (the rungs must degrade, not collapse)

A rung that hits its time limit and returns nothing is worse than useless — it
burns a seat and teaches the next agent nothing. Two rules, both retrofitted
after they bit:

- **Partial work is mirrored to a global** (`HCT$LastReductions`,
  `HCT$LastIdentify`) *as it is produced*, so an aborted rung still yields the
  reduction or the operator factorization it had already found. Measured: class
  77's R2 found a working order-4 reduction (`LeafCount` 3976) in seconds and
  was about to discard it after ten minutes of shopping for a prettier one.
- **Stop shopping once you have a working answer.** R2 tries cyclic vectors in
  order and halts as soon as one has succeeded and a third of the budget is
  gone. A cyclic vector that works beats a marginally smaller one that costs
  minutes to find.

Per-locus and per-point time guards mean one hard letter cannot stall a census:
pole orders are cheap and are always retained even when the residue is not.

---

## Wolfram traps this module is written against

All of these bit this project already:

- `Return[]` inside `Do[]` does not return from the enclosing function.
- **Module initializers are not sequentially scoped** — `Module[{n = Length[x],
  a = ConstantArray[0, n]}, ...]` silently yields a `SymbolicZerosArray`
  because `n` is still unassigned. Declare, then assign in the body.
- Self-assignments like `v = Global\`v` create infinite definitions.
- **Regulator naming**: `Epsilon`, `eps`, `ep`, `CANONICA\`eps` all exist in
  this codebase. `HCTNormalize` maps by `SymbolName` at every tool boundary.
- `Missing[]` is not `None` — absent keys are tested with `KeyExistsQ`.
- `Put` is not atomic — `HCTPut` writes a temp file and `RenameFile`s it.
- `SortBy` is not a stable tie-break (see R2 above).
- `Coefficient[expr, f[x]]` needs the expression expanded first, and `F`/`F'`
  must be tested as independent coefficients.

---

## Per-rung measured cost

Wall clock, one Wolfram 14.2 kernel, 2026-08-14. Records in `out/attack_class*.wl`.

| rung | 115 (dim 2, 1-var) | 79 (dim 4) | 77 (dim 4) | 97 (dim 4) |
|---|---|---|---|---|
| R1a one-variable | 0.04s | 0.33s | 0.85s | 0.20s |
| R1b/c census | 0.03s | 4.0s | 1.70s | 0.56s |
| R1d subspaces | 0.00s | 0.13s | 0.13s | 0.07s |
| R2 cyclic vector | 0.02s | — | **372s** | **210s** |
| R3 identification | 0.01s | — | **600s (capped, partial)** | 0.11s |
| R4 certification | 0.01s | — | — | — |
| **total** | **0.1s** | **4.1s** | **975.7s** | **211.2s** |

The shape of this table is the whole argument for the ladder:

- **R1 is free** — seconds on a dim-4 block, and it already produces the
  diagnosis (which letters, which are apparent, which square root, whether the
  block is secretly one-variable). There is no excuse for not running it before
  handing anything to a canonicalizer. Compare 2400s for CANONICA to report
  "obstructed" on class 97 against 0.56s for R1c to report *which* obstruction.
- **R2 is the gate** on dim 4 — minutes, and it dominates. Hence the early-stop:
  the first cyclic vector that works is the one to keep.
- **R3 cost is bimodal**, decided entirely by whether the leading coefficient's
  roots can be solved for: class 97 factored into low-degree pieces and finished
  in 0.11s; class 77 produced a large eps-dependent quartic factor and burned
  the full 600s cap resolving only 5 of 7 points. When R3 is slow, the
  factorization is the deliverable, not the scheme.

**Reduction-introduced apparent singularities.** The cyclic-vector reduction
adds singular points that the block does not have. Class 97's system census has
**zero** eps-dependent loci, yet its scalar operator's leading coefficient
carries the factor `3 + v + 4 eps v - 3 w`; class 77's carries a large
eps-dependent quartic. Both are artifacts of the reduction — eps-dependent, so
they cannot be Landau loci. Do not chase them, and always compare the R3
leading factors against the R1c locus list before interpreting anything.

The exponent pattern makes this visible: at every finite singular point of the
dim-4 scalar operators the exponents come out `{0, 1, 2, X}` with only `X`
genuine — the `0,1,2` are the apparent tower, and R3's reconciliation prints the
integer shifts against the system exponents (e.g. class 97 on the Kallen curve:
system `{0,0,0,1/2+eps}` vs component `{0,1,2,1/2+eps}`, shift `{0,1,2,0}` —
the half-integer is unshifted, confirming it as the real obstruction).

---

## Per-class outcomes (2026-08-14)

| class | rep | dim | verdict |
|---|---|---|---|
| **115** | CF299 {1,2} | 2 | **SOLVED, registered** `forms/class115.wl`, `Validated -> True` |
| **97** | CF258 {18..21} | 4 | structural obstruction **cleared** by the chart; CANONICA deg-0 **timeout 1202.6s** — not canonicalized |
| **77** | CF230 {1..4} | 4 | sqrt cleared; Moser at `xy=1` + one balance still needed; CANONICA deg-0 **timeout 1200.6s** |
| **79** | CF231 {1..4} | 4 | R1 cross-check only — Codex owns it; full agreement |

**Nothing beyond 115 is canonicalized.** The chart result for 97 is a
*structural* clearance, verified by census; it is not an eps-form. The degree
ladder was stopped after the degree-0 triage by decision, not by exhaustion —
see the escalation corollary.

**115.** Independently rederived by the ladder (acceptance gate): `z = v w` at
R1a, `2F1(1+eps, 1/2+2eps; 1-eps; 4vw)` at R2-R3, exact operator identity at R4.
The recorded eps-form in `u = Sqrt[1-4vw]` was then re-verified from scratch —
`Uinv.U = I`, `det U = eps/u^3`, and canonical residual identically zero in
**both** directions. The earlier "reconstruction gate came out False" was a
convention problem, not a mathematical error. The stored `ClosedForm` defect
`D[F1, 4 v w]` (differentiation with respect to a compound expression, invalid
Wolfram) is superseded by the verified `F2 = 2 v D[F1, v] + (1+4 eps) F1`,
which is equal because `x = 4 v w`.

**97 — the actionable one.** Its census in `(v,w)` has *no* eps-dependent
letter and *no* non-Fuchsian pole; the only non-integer structure anywhere is
`1/2+eps` on the Kallen curve, in both the system and the scalar picture. In
the rationalizing chart of R3b the census comes back with **no half-integer
loci, no non-Fuchsian loci, no eps-dependent loci**, and a 7-letter rational
alphabet `{x-1, x, x-y, x y - x - y, x+y, y, y-1}` with integer exponents
throughout. Those are exactly the conditions under which a low ansatz degree is
plausible. The recorded verdict "class 97 proven obstructed (2400s)" was
**chart-specific**; establishing this took 0.56s + 0.5s.

**77.** Same chart clears its half-integer too (`x-y` carries `1+2eps`), but an
order-2 pole survives at `x y = 1` and one eps-dependent apparent letter remains
with rank-1 exponents `{0,0,0,1}` (balance constructed, not applied). Order of
operations: chart, then Moser-reduce, then balance, then CANONICA.

**79.** R1 only, by instruction. Every locus the specials record tabulates is
reproduced exactly — `v`, `L=(3+5eps)(v+w)-3(1+eps)` `{0,0,0,1}`, Kallen
`{0,0,0,1/2+eps}`, `v+w` order 2 non-Fuchsian, `1+v+w` `{0,0,0,-5-6eps}` — plus
one row the record leaves blank: `w` gives `{0, eps, eps, -1-2eps}`. No
disagreement with Codex's data.

## R5 obstruction handoffs (what the next agent should do)

Records: `canonica/class*_deg*.wl` (per-degree, atomic), `chart_class*.wl`
(census in the chart), `attack_class*.wl` (full ladder).

### Class 97 (CF258 {18..21}) — structurally clear, ansatz-expensive

*State.* No structural obstruction in the chart `v = x y, w = (1-x)(1-y)`:
Fuchsian, eps-independent 7-letter alphabet, integer exponents everywhere.
CANONICA degree 0 **timed out at 1202.6s** (not refused). Degrees 1-2 not
attempted, deliberately — see the escalation corollary above.

*Do not repeat.* Re-running the same degree-0 ansatz in the same chart at the
same cap. It is a budget problem, not a degree problem.

*Natural next rungs, cheapest first.*
1. **R2/R3 in the chart variables.** The scalar reduction was never run in the
   chart — only in `(v,w)`, where the half-integer forced the analysis into
   algebraic territory. In the chart the exponents are integers, so the order-4
   operator should factor over `Q(x,y)`, and R3's `Sym^k`/tensor tests apply
   directly. This is minutes, not hours, and it either factors the block (giving
   the answer without CANONICA) or hands back a much smaller sub-block.
2. **Longer cap or a reduced system.** If the ansatz route is kept, raise the
   cap rather than the degree, and consider feeding CANONICA a sub-block from
   step 1 instead of the full 4x4.
3. **Maximal-cut / PF lane** (Codex's program on CF258) — the exponent data in
   `chart_class97.wl` is directly reusable there, and the integer exponents make
   the boundary bookkeeping easier than in the original frame.

### Class 77 (CF230 {1..4}) — two structural defects survive the chart

*State.* CANONICA degree 0 in the chart **timed out at 1200.6s** (not refused),
same as 97. The chart clears the half-integer (`x-y` carries `1+2eps`), but two
defects remain, both already characterized:
- an **order-2 pole at `x y = 1`** — non-Fuchsian, needs Moser reduction;
- an **eps-dependent apparent letter**, rank-1, exponents `{0,0,0,1}`, with the
  explicit balance `T = (1-P) + L P` constructed in `chart_class77.wl`.

*Order of operations.* Chart, then Moser-reduce at `x y = 1`, then the balance,
then CANONICA. The balance must come **after** any rational-ansatz search, never
before (measured destructive, WORKLOG 2026-08-14) — which is why the CANONICA
attempt here was run on the unbalanced system.

*Interpretation.* 77 is strictly harder than 97: 97's only obstruction was the
square root, 77 has two more on top of it. A CANONICA result on 77 in the chart
carries little information until the order-2 pole is reduced, because a
non-Fuchsian pole inflates the required ansatz degree on its own.

## How to use it

```mathematica
Get["HardClassToolkit.wl"];
out = AttackClass[classData];                          (* full ladder *)
out = AttackClass[classData, "Rungs" -> {"R1a","R1c"}] (* diagnostics only *)
out["R5Obstruction"]                                   (* the handoff *)
```

`classData` is one entry of `classes.wl` (needs `RepAv`, `RepAw`; `ClassID`,
`Dim`, `RepFamily`, `RepRows` are used for labelling). Symbol naming is
normalized on entry, so any regulator spelling works.

## Kernel mission pool (added 2026-08-15)

`HCTMissionPool[missions, runFn, "Kernels" -> 4]` runs a heterogeneous
mission queue on 1 main + k subkernels: every spec is submitted up
front, `WaitNext` hands each finished subkernel the next spec. Use it
whenever a class attack has several independent jobs (search chunks,
`DSolve` probes, reductions) — it keeps the second main-kernel license
seat free. The caller must `DistributeDefinitions` `runFn` and its data
first (`DistributeDefinitions` is HoldAll, so the pool cannot forward a
symbol list). Measured on the class-97 order-1 campaign: 12
y-specialized Beke chunks + `DSolve` probe + exterior-square reduction
in 331 s on 4 subkernels (~19 min serial), zero extra main kernels.

Class-97 outcome update (2026-08-15, pooled run): the order-4 operator
has NO first-order right factor — 1,906 forced-degree Beke candidates,
0 survivors at two independent rational y specializations (timeouts
counted as survivors; none occurred), subsuming the earlier pure-power
exhaustion. `DSolve` times out at 300 s. The exterior square Λ²(A)
scalarizes to an order-6 operator (cyclic vector {1,0,0,0,0,0}); its
first-order factors + Plücker condition are the order-2 rung.

**Irreducibility closed (2026-08-15, ore_algebra):** `ore_algebra`
(Kauers et al.; van-Hoeij-type operator factorization) is now installed
at `~/.venvs/ore` (PassageMath wheels, pure-Python build — the box
lacks mpfi headers for its numeric extension, which we don't use).
Positive controls: it splits an order-1×order-1 product and finds the
order-2 right factor of an order-3 product exactly. On the class-97
operator specialized at (y,ε) = (3/7, 17/1000) and (5/11, 23/900) —
leading-coefficient degrees stable at both points, so neither sits on
the degeneracy locus — `factor()` returns the operator whole in 1–3 s:
**no right factor of order 1, 2, or 3 at either specialization**. Since
a factorization over Q(y,ε)(x) specializes to all but a proper closed
set of rational points, the symbolic operator is irreducible
(decision-grade at orders 2–3; order 1 is additionally closed by the
exact symbolic Beke exhaustion above). Consequence for the Φ-route:
no factorization ladder exists — class 97 needs an irreducible rank-4
recognition (Appell F2/F3/F4-type system or the maximal-cut
Picard–Fuchs lane), not further factor search. The same two-point
`ore_algebra` probe is the FIRST move for any future hard class (it
subsumes the R-ladder's factor rungs at specialized points, seconds
per class).

## The epsilon-graded route (2026-08-15/16, all three hard classes)

Since 97/77/79 are order-4 irreducible at generic eps but factor
COMPLETELY at eps=0 (ore_algebra [1,1,1,1] at two independent
specializations each), the production route is the eps-graded scalar
recursion in `Scripts/EpsilonGraded.wl`: grade the monic operator in
eps, invert L0 through its verified first-order chain by exact
anchored quadratures (Hlog words), certify every order by an exact
residual identity.  Chains and the class-97 solution through eps^3
live in Results/UU_08_10_canonical/HardClasses/ (see its README for
provenance and certificates); suite: Tests/EpsilonForm/t_epsilon_graded.wls.
Class-97's order-1 solve matches the independently derived Codex route
in structure; system-level cross-check pending gauge alignment.

Trap-list addition (measured): **HyperIntica's `HyperInticaPrimitive`
returns HALF the true primitive on pure-zero words** (Log powers) in
every on-box version (SubTropica 1.1.10/1.2.3/1.2.9), while words with
any nonzero letter are exact.  EpsilonGraded.wl therefore certifies
every package primitive by an exact derivative identity and routes
failures (and all pure-zero content) to its own by-parts recursion.
Also measured: chain/flag factorizations of these operators generically
carry APPARENT factors in their stage weights (97: one linear-in-x
apparent letter, workable; 77/79: an apparent sextic, not directly
quadrature-ready) — gauge choice (cyclic covector) controls this, and
a letter-only-weight gauge scan is the standard cleanup step.

**Endpoint deliverable requirement (user physics input, 2026-08-16):**
plus-distribution extraction needs the UNEXPANDED endpoint modes
(1-w)^(alpha eps + m) x analytic — an eps-expanded log tower has lost
its delta-function content.  The eps-graded route therefore delivers,
per hard class: the expanded solution PLUS the exact endpoint indicial
exponents and the finite linear matching that resums the log towers
onto the mode basis (exact, since the exponents are DE data; care at
integer-degenerate exponent pairs).  Canonical-class transport keeps
modes resummed natively; the hard classes pay this extra step.
Depth rule restated: an ingredient's eps depth = target order + the
deepest pole it multiplies anywhere in the subtracted assembly
(measure factors, IBP coefficient poles, transport regulator shifts,
subtraction kernels) — the NLO analogue being LO carried to eps (eps^2
for NNLO subtraction).  The stage-4 format question is thereby
narrowed: endpoint content is physics-forced to resummed modes; only
the interior (v,w) representation remains open with Codex.

**Laurent-graded reconstruction (measured 2026-08-16, class 97):** the
cyclic covector stack degenerates at eps=0 (det ~ eps) and its symbolic
inverse carries 1/eps poles in the columns acting on the higher scalar
derivatives.  Consequences: (i) scalar->vector reconstruction is
Laurent-graded — every vector eps-order draws on scalar orders one
deeper (a +1 entry in the depth budget for this gauge); (ii) the eps^0
vector kernel is built from kernel elements CONTINUED to eps^1, so all
four kernel continuations are required, not just the seed mode; (iii)
naive Inverse at eps=0 and naive eps->0 substitution both lie — pole
orders must be read from Series with Cancel'd entries (unsimplified
CoefficientList valuations report false zeros).
