# CF259 / CF303 continuation after CF300

Static, no-kernel assessment made 2026-08-23. No Wolfram/Mathematica or native
kernel was launched, and no package or pre-existing exchange file was changed.
The source snapshot was dirty and active; use `SHA256SUMS` as the actual ABI,
not only git commit `3f519eb94f44953bc1c9c5ee42adece2c927dbc2`.

## Recommendation

Mission order is **finish CF300 -> CF303 -> CF259**.

1. Finish the CF300 rank-2 discriminator and supply/revalidate a consumer which
   installs the reconstructed gauge into the family state. The existing
   assessment says no current package/driver consumes its certified seed
   (`cf300_sector12_physical_rank3_xh/CF300_12_9_rank2_extension_assessment_2026-08-23.md:189-196`).
2. Run a fresh CF303 identity-frame capture. CF303 has exactly CF300's ordered
   square field `{lambda2,lambda3,1-4 v w}`, and is smaller (45 masters, 25
   diagonal sectors) than CF259. Reuse the generic field/adapter/reconstruction
   libraries, but not a CF300 preparation, elimination plan, driver status, or
   state.
3. Run CF259 afterward. Its third square `4 v+w^2` is genuinely different and
   no catalog chart covers it jointly with either Kallen square.

This agrees with the earlier ordering
(`codex_triple_root_assessment_2026-08-22.md:124-145`), sharpened here by the
exact sector DAGs and the absence of any CF259/CF303 recursive artifact.

## Field, size, alphabet, and unresolved work

Let

```
lambda1 = (1-v-w)^2 - 4 v w
lambda2 = lambda1(-v,w)
lambda3 = lambda1(v,-w).
```

The family table constructs identity multiquadratic frames, not a global
rational chart (`FeynFacet/Private/TransportCharts.wl:778-803`):

| family | ordered root squares / grade generators | field | masters | diagonal sectors | canonical masters | raw alphabet |
|---|---|---:|---:|---:|---:|---:|
| CF259 | `{lambda1,lambda3,4v+w^2}` / `{1,2,4}` | degree 8 | 47 | 27 | 9 | 26 entries, 22 non-numeric |
| CF303 | `{lambda2,lambda3,1-4vw}` / `{1,2,4}` | degree 8 | 45 | 25 | 6 | 22 entries, 19 non-numeric |

The three square classes in each family are independent; the exact
eight-channel model is recorded in
`codex_triple_root_assessment_2026-08-22.md:79-104`. Raw family sizes are in
`DifferentialEquations/nnlo_de_summary.wl:38-45,69-74`; full alphabets are at
`nnlo_de_CF259.wl:14466-14472` and `nnlo_de_CF303.wl:13884-13890`. These are raw
coefficient alphabets, not the future blocked strip's dlog one-form list.

There is no `CF259_*_input.wl`, `CF303_*_input.wl`, sector state, strip state,
preparation, or prime artifact in this snapshot. Therefore every off-diagonal
family block is unresolved even though diagonal class forms exist. The only
captured recursive triple-root state/input is CF300. Available fresh inputs are:

* `DifferentialEquations/nnlo_de_CF259.wl` and `nnlo_de_CF303.wl`;
* `BlockClasses/block_class_assign.wl` and corresponding class forms;
* exact identity frames from `TransportFamilyChart`;
* archive VOC maps consumed by normal family assembly.

Here `DifferentialEquations` and `BlockClasses` are below
`ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/`.

The exact assembly topological order reconstructed from the raw DE dependency
graph follows. Each entry is `sector: rows/dimension/class/root`; `R` is
rational. This is the order a fresh state must use, not numerical row order.

```
CF259
 1:10/1/c1/R        2:41/1/c56/R       3:34/1/c3/R
 4:26/1/c3/R        5:43/1/c57/R       6:13/1/c2/R
 7:35,36/2/c96/R    8:17,18/2/c34/R    9:29,32/2/c35/R
10:1,2/2/c98/Q4    11:45/1/c64/R      12:6,7/2/c100/R
13:21/1/c12/R      14:11/1/c2/R       15:14,15,16,22/4/c49/lambda1
16:37,38,39,40/4/c97/lambda1          17:24,25/2/c8/R
18:27,28,31,33/4/c77/lambda1          19:42/1/c64/R
20:46,47/2/c95/lambda1                21:12/1/c4/R
22:19,20,23/3/c92/lambda3             23:3,4/2/c99/R
24:44/1/c84/R      25:30/1/c94/R      26:8,9/2/c101/lambda1
27:5/1/c65/R

CF303
 1:7/1/c1/R         2:39/1/c5/R        3:35/1/c3/R
 4:26/1/c36/R       5:44/1/c37/R       6:9/1/c2/R
 7:14,15/2/c27/R    8:31/1/c12/R       9:28/1/c50/R
10:45/1/c51/R      11:8/1/c17/R       12:10,11,12,13/4/c62/lambda2
13:16,17,18,19/4/c79/lambda2          14:29,30/2/c44/R
15:32,33,34/3/c75/lambda3             16:36,37/2/c45/R
17:20,21/2/c44/R   18:22,23,24,25/4/c118/lambda2
19:40,41/2/c115/(1-4vw)               20:42,43/2/c117/R
21:38/1/c78/R      22:27/1/c42/R      23:3,4/2/c116/R
24:1,2/2/c122/lambda2                 25:5,6/2/c123/lambda2
```

CF259 has 132 raw nonzero lower-block pairs out of 351 possible strip positions;
CF303 has 124 out of 300. Zero forcing removes many positions cheaply
(`Scripts/family_epsform_sector.wls:663-686`). Static endpoints expose catalog
gaps: CF259 sector `26 -> 10` combines `lambda1` with `Q4=4v+w^2`; CF303 sector
`25 -> 19` combines `lambda2` with `1-4vw`. These are **not predictions of the
first runtime blocker**: recursive row gauges can change support, and the
completed dynamic strip must be classified
(`codex_triple_root_assessment_2026-08-22.md:64-77`).

## Reuse boundary

Reusable without a family-specific mathematical change:

* `TripleRootAlgebra.wl` implements rank-`r` multiquadratic arithmetic,
  conjugates/splits and grade rank, not a CF300-only field.
* `TripleRootStripAdapter.wl` classifies/decomposes an exact strip and builds its
  support, one forms, and denominator in local grades.
* `TripleRootReconstructionPrototype.wl:5-38` exposes generic preparation,
  prime reconstruction, and branch verification. Its ABI binds the exact
  record, roots, dimensions, support, one forms and denominator (`:145-200`).

For dimensions `{du,dl}`, active rank `r`, gauge support size `S`, and one-form
count `L`, preparation has

```
unknowns = du dl (2^r S + L),       equations/sample = 2 du dl 2^r.
```

Thus CF259/CF303 strip dimensions, exact grades, `S`, `L`, and unknown count are
currently **unknown**, not inferable from family totals. A rank-2 blocker uses
four channels; a true rank-3 blocker uses eight.

Not reusable directly:

* `run_cf300_sector12_rank2_extension_prepare.wls:157-182` hard-codes CF300,
  strip `{12,9}`, roots `{2,3}` and its sidecar; `:224-299` hard-codes grades
  `{0,2,4}`, rank 2, dimensions `{2,2}`, and status
  `PreparedCF300Sector12Rank2Extension`.
* Its prime/aggregate drivers accept that status and bind preparation/driver
  hashes. A CF300 elimination plan is invalid for a new equation by ABI design.
* No extension-result loader currently installs a reconstructed row gauge in a
  copied family state. Reusing arithmetic alone does not complete a sector.
* The prototype solves a strip equation; it does not implement the truncated
  constant multiquadratic regulator factorization.

Therefore CF303 can reuse CF300's generic code and field conventions, but needs
a new record, preparation, elimination plan/prime artifacts, and neutral
parameterized wrapper. CF259 additionally needs Q4 root/branch tests. No state
or numerical artifact should cross families.

## Cheapest useful fresh plan

1. Snapshot/rehash the current package and driver. Use current
   `Scripts/family_epsform_sector.wls`, a new output directory, identity frame,
   `FiniteFieldFirst`, zero forcing, Production checks, and one worker. Do not
   use `FACET_RECORD_STRIP_ONLY=True` for discovery: it exits on the first strip
   (`:631-643`), not the first extension blocker.
2. Run CF303 normally to its first typed stop. The driver atomically writes each
   exact `CF303_k_l_input.wl` before solving (`:631-638`) and saves state.
   Distinguish:
   * `NeedsMultiquadraticRegulatorFactorization` from `factorTruncated`
     (`:397-414`): implement/certify the constant multiquadratic truncation
     transform; the strip prototype is not the remedy.
   * `NoRationalStripChart` from `SolveEpsFormStripInFrame`
     (`FeynFacet/Private/TransportCharts.wl:472-475`): prepare that captured
     strip through the generic adapter/reconstruction path.
3. For a strip stop, parameterize a fresh copy of the CF300 prepare wrapper in a
   new exchange directory. First perform only classification, termwise
   round-trip, independent-square-class proof, and preparation. Record
   `{du,dl}`, roots/order, grades/rank, `S`, `L`, denominator degrees, unknown
   count, and exact ABI hash; abort above an explicit unknown cap.
4. Only then spend primes: one small-prime smoke/discriminator, then independent
   31-bit prime shards and aggregate/exact residual plus all branch masks. Never
   reuse CF300's fixed-row elimination plan.
5. Revalidate/install the gauge into a copied CF303 state, continue to the next
   stop, and repeat for CF259.

A raw assembly census is cheaper but not useful enough to precede this: it
cannot see recursive grades. The standard capture is the cheapest operation
that produces the exact physical equation required by the extension ABI.

## Bugs and blockers with exact evidence

* **Hard functional limit:** `TransportRootSetChart` can only select a catalog
  chart; `SolveEpsFormStripInFrame` returns `NoRationalStripChart` when none
  exists (`TransportCharts.wl:284-301,472-475`). The catalog has Kallen pairs
  12/13/23 but no Kallen+Q4 or Kallen+bilinear chart (`:751-792`).
* **Intentional safety stop, still unimplemented:** a completed algebraic
  truncation with no joint chart becomes
  `NeedsMultiquadraticRegulatorFactorization` and exits before the next row
  (`family_epsform_sector.wls:397-414`).
* **Continuation blocker:** the certified CF300 seed has no current consumer
  (`CF300_12_9_rank2_extension_assessment_2026-08-23.md:189-196`).
* **CF300 wrapper is not generic:** hard-coded family/strip/root/grade/dimension/
  status checks are at
  `run_cf300_sector12_rank2_extension_prepare.wls:157-182,224-299`.
* **Diagnostic loss:** the driver logs a failed frame result with root indices/
  squares (`family_epsform_sector.wls:687-689`) but `_unsolved.wl` stores the
  strip and optional obstruction, not the returned typed solution (`:737-748`).
  The `_input` permits recovery, but automation should persist the status.
* **Do not resurrect the fixed CF300 factor-order bug:** the current driver calls
  `FactorFamilyRegulatorDependenceInFrame` and makes a typed stop (`:397-414`).
  Older `family_epsform_sector_triple_root_candidate_v3.wls:399-406` calls the
  rational factorizer unconditionally and silently returns `False` on failure.
* **Stale comment only:** `TransportCharts.wl:751-756` says triple-root families
  use `Missing`, while `:778-803` now constructs identity frames.

## Acceptance gate

Require: exact input hash; exact termwise channel round-trip; stable root order
and independent square classes; preparation ABI validation; fresh primes; exact
reconstructed channel PDE; all branch masks at fresh split points; exact
identity-frame recomposition; and a revalidated loader/state-continuation
certificate. A modular success alone does not settle a family sector.

