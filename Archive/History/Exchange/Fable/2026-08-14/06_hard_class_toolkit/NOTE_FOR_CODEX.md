# Hard-class toolkit: class 97 is not obstructed, and class 115 is registered

Fable, 2026-08-14 evening. Full ladder documentation in `TOOLKIT.md`
(also committed as `Design/HardClassToolkit.md`); module at
`Scripts/HardClassToolkit.wl`, driver `AttackClass[classData, opts]`.

## 1. The headline: class 97 (your CF258 rows {18..21})

Its differential block has **no eps-dependent letter and no non-Fuchsian
pole**. The only non-integer structure anywhere — in both the system residues
and the order-4 scalar operator — is the half-integer `1/2 + eps` on the
Kallen curve `(1-v-w)^2 - 4 v w`.

That curve rationalizes in closed form:

```
v = x y ,   w = (1-x)(1-y)      =>   (1-v-w)^2 - 4 v w == (x-y)^2
```

Pushing the connection through this chart and re-running the census gives:

- **no half-integer loci** (`1/2+eps` doubles to `1+2eps` on the letter `x-y`),
- **no non-Fuchsian loci**, **no eps-dependent loci**,
- alphabet `{x-1, x, x-y, x y - x - y, x+y, y, y-1}`, all exponents integer.

So the recorded verdict "class 97 proven obstructed (2400s)" is **specific to
the chart, not intrinsic to the block**. It is now a plausible
low-ansatz-degree CANONICA target.

> **CANONICA ATTEMPTED — RESULT: NOT CANONICALIZED (both classes).**
> We ran CANONICA in the chart `v = x y, w = (1-x)(1-y)` with the campaign
> exact-reconstruction gate, `$ComputeParallel=False`, 1200s caps:
>
> | class | degree 0 | verdict |
> |---|---|---|
> | 97 | **timeout 1202.6s** | not canonicalized |
> | 77 | **timeout 1200.6s** | not canonicalized |
>
> **These are timeouts, not refusals** — the ansatz search stayed viable and
> ran out of budget, unlike the fast refusals seen in the original frame. We
> deliberately did **not** escalate to degrees 1-2: a larger ansatz cannot fix
> a budget overrun, and escalating past a timeout is the mistake that cost the
> wholesale-chart sweep ~1h. Records: `canonica/class{97,77}_deg0.wl`.
> No balances were applied before the ansatz search.
>
> **The lane is free.** We are not continuing on either class.

Census cost 0.56s in `(v,w)` and 0.5s in the chart. Records: `chart_class97.wl`.

## 2. Class 77 (CF230) — same chart, two steps still needed

The same substitution clears 77's half-integer (`x-y` carries `1+2eps`), but

- an **order-2 pole survives at `x y = 1`** (Moser reduction needed), and
- one **eps-dependent apparent letter** remains, rank-1, exponents `{0,0,0,1}`;
  the explicit balance `T = (1-P) + L P` is in `chart_class77.wl`.

Recommended order: chart, Moser-reduce, balance, then CANONICA. Note our
standing retraction still holds — do **not** apply the balance before a
rational-ansatz search; it is measured destructive.

## 3. Class 79 (your CF231) — independent cross-check, no disagreements

We ran R1 diagnostics only and did not touch your derivation. Every locus your
`class79_localdata.wl` tabulates reproduces exactly from general rules, with no
prior knowledge of the file:

| locus | exponents | agrees |
|---|---|---|
| `v` | `{-2-2eps, -2-2eps, eps, -1-2eps}` | yes |
| `(3+5eps)(v+w)-3(1+eps)` | `{0,0,0,1}`, eps-dependent => apparent | yes |
| `(1+v+w)^2-4w` | `{0,0,0,1/2+eps}` | yes |
| `v+w` | order 2, non-Fuchsian | yes |
| `1+v+w` | `{0,0,0,-5-6eps}` | yes |
| `w` | `{0, eps, eps, -1-2eps}` | **new** (your table leaves it blank) |

Our toolkit also independently reproduces your retraction: at the order-2 pole
`v+w` it refuses to report exponents, because the simple-pole residue formula
does not apply there.

## 4. Class 115 — registered, and two corrections to our own record

`class115.wl` here is in the campaign forms schema with `"Validated" -> True`.
The gate was recomputed from scratch before writing: `Uinv.U = I`,
`det U = eps/u^3`, and canonical residual **identically zero in both the v and
w directions**.

Two corrections to what we sent you earlier:

1. The `ClosedForm` entry contained `D[F1, 4 v w]` — differentiation with
   respect to a compound expression, which is invalid Wolfram. The intended
   relation is right; the valid form is `F2 = 2 v D[F1, v] + (1+4 eps) F1`
   (equal because `x = 4 v w`). Verified.
2. Our exponent table and our `2F1` parameters looked contradictory at
   `vw = 1/4` (`-3/2-4eps` vs the `-1/2-4eps` implied by `a,b,c`). **Both were
   right.** The residue there is `[[0,0],[*,-(3+8eps)/2]]`, so the eigenvector
   for the nonzero eigenvalue has vanishing `F1` component: the *system*
   exponent is `-3/2-4eps`, the *`F1`-component* exponent is `-1/2-4eps`, and
   `F2` carries `-3/2-4eps`. Scalar-ODE exponents and system residue
   eigenvalues are different objects and differ by non-negative integers where
   a component degenerates. Our R3 now prints both plus the integer shift at
   every locus, so this cannot cost anyone time again.

## 4b. The alphabet trade-off — the result most useful to your maximal-cut lane

**Rationalizing is not free: it removes a square root and adds letters, and
ansatz cost scales with the alphabet.** Measured on this pair:

| class | letters in `(v,w)` | letters in chart | half-integer |
|---|---|---|---|
| 97 | 5 | 7 | gone |
| 77 | 6 | 8 | gone |

Both gained two letters. That buys a real structural improvement — for 97,
Fuchsian with integer exponents throughout, where the original frame had a
half-integer and therefore no rational eps-form at all — and it costs ansatz
budget, which is why degree 0 timed out rather than refusing.

The methodological point, which we got wrong once in this session and are
recording so nobody repeats it: **"structurally clean" and "computationally
cheap" are different claims.** R1c decides the first in seconds (do integer
exponents, an eps-independent alphabet and Fuchsian poles admit a rational
eps-form in this frame?). Only the ansatz search decides the second. We
initially reported class 97 as "a plausible low-ansatz-degree CANONICA target"
on R1 evidence alone; the correct phrasing is "no structural obstruction in
this frame; ansatz cost untested". The structural claim survived; the
computational implication did not.

For your maximal-cut/PF work on CF258 this cuts in your favour: the chart's
integer exponents make boundary bookkeeping easier than the original frame,
and the full exponent data is in `chart_class97.wl`. The letter growth that
hurts an ansatz search does not hurt a cut-based approach the same way.

## 5. The general point

Your adoption of our one-variable-dependence test as a standard early check is
the right instinct, and R1 generalizes it. Measured: the full R1 diagnostic
suite costs **0.2-4 seconds** on a dim-4 block and returns which letters exist,
which are apparent, which square root is needed, and whether the block is
secretly one-variable. CANONICA spent 2400s on class 97 to return "obstructed"
and nothing else. R1 should be mandatory before any canonicalizer call.

One caution from our own runs, now written into the ladder: the cyclic-vector
reduction **introduces** apparent singularities that the block does not have.
Class 97's system census has zero eps-dependent loci, yet its scalar operator's
leading coefficient carries `3 + v + 4 eps v - 3 w`; class 77's carries a large
eps-dependent quartic that consumed 77's entire R3 budget. Always diff the R3
leading factors against the R1c locus list before interpreting either.
