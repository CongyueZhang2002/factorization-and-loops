# Stage 1: canonicalization of the block lattice

This is the fresh-agent operating manual for stage 1 of the
master-solving workflow of `Design/MasterSolvingArchitecture.md`.
Everything needed to rerun the stage lives in this repository: the
package module `FeynFacet/Private/CanonicalBlocks.wl`, the test
`Tests/t_canonical_blocks.wls`, and the differential-equation
artifacts under `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/`.

**Scope.** Stage 1 takes a lattice of family differential equations and
produces one certified epsilon-form per connection-equivalence class of
coupled blocks. It is pure geometry.

**Boundary VALUES are not part of this stage.** They are stage-3
physics input (volume normalization, inherited subsector expansions,
forbidden-mode selection, regularity). A class is canonicalized or it
is not, independently of any integral's value. Nothing in stage 1 may
read, assume, or produce a boundary constant; if a step appears to need
one, the step belongs to stage 2 or 3.

---

## Card settings (canonicalization budget)

The process card may set the stage-1 budget declaratively; explicit
`CanonicalizeClasses` options always win, then the card, then the
built-in defaults:

| card key | default | measured guidance |
|---|---|---|
| `CanonicalizationAnsatzDegrees` | `{0, 1, 2}` | degree 0 suffices for ~96% of classes; degree 1 recovered a handful; degree >= 2 never paid on this problem |
| `CanonicalizationTimeConstraint` | `1200` (s) | 300s missed a 324s success by 24s; extended caps recovered three classes at the ~600s tier; nothing in the residual Kallen geometry cracked past ~700s even at 2400s |
| `CanonicalizationMemoryConstraint` | `6*1024^3` | no memory failure observed at this value on dims <= 4 |

Pass the card as `"Card" -> <association or card-file path>`. Classes
that survive the budgeted ladder are routed to the escape hatches
(chart frames are already inside the ladder; the remainder goes to
maximal-cut/Picard-Fuchs analysis) rather than to ever-larger budgets:
the measured escalation history says the marginal success rate past
the built-in budget is near zero while cost grows multiplicatively.

## 1. Inputs

| Input | Location | Shape |
|---|---|---|
| Family DE artifacts | `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/DifferentialEquations/nnlo_de_CF*.wl` | `<\|"Family", "BlockBasis", "Av", "Aw", ...\|>` |
| NLO reference system | `ppHX_NLO/Results/NLO_UU_Masters.wl`, key `"DifferentialSystem"` | `<\|"Basis", "Av", "Aw"\|>` |
| CANONICA 1.0.3 | `Addon/Mathematica_Addon/CANONICA/src/CANONICA.m` | GPL add-on, loaded on demand |

`Av` and `Aw` are the connection matrices of `dF/dv = Av F`,
`dF/dw = Aw F`. The NNLO artifacts write the regulator as `eps`, the
NLO artifact as `Epsilon`; every entry point takes a `"Regulator"`
option and otherwise infers it by symbol name.

Two file-reading facts that have bitten us:

- the artifacts store *unqualified* symbols (`v`, `w`, `eps`, `gli`).
  Read from inside the package context they would become
  ``FeynFacet`Private`v`` and silently fail to match anything. The
  module reads every artifact in a ``Global` `` reading context; a
  script that reads them itself must run at ``Global` `` too.
- 93 files match `*.wl` in that directory but only 91 are families:
  `GlobalSystem.wl` and `nnlo_de_summary.wl` are not. Always pass
  `"FilePattern" -> "nnlo_de_CF*.wl"`.

---

## 2. The stage sequence

Load the package (`Addon/Load/LoadFACET.wl`), then:

### 2a. Decompose

```wolfram
decomposition = DecomposeFamilyBlocks[deDirectory,
  "FilePattern" -> "nnlo_de_CF*.wl",
  "OutputDirectory" -> workDirectory];
```

Builds, per family, the dependency graph `i -> j` iff row `i`'s
derivative involves basis element `j`, and takes its strongly connected
components. Each component is a *block*: a minimal set of masters that
must be solved together.

It also emits the **block-lower-triangularity certificate** per family:
the blocks are topologically ordered so that every dependency precedes
its dependent, and the certificate counts connection entries pointing
strictly forward in that order. `"ForwardCouplings" -> 0` and
`"BlockLowerTriangular" -> True` is what licenses solving a family one
block at a time.

Be clear about what this certificate is. The condensation of a
strongly-connected-component decomposition is a directed acyclic graph,
so a *correct* implementation always yields zero forward couplings: the
certificate is a machine-checkable self-consistency check on the
decomposition, not a discriminating test of the physics. What it
actually catches is a decomposition bug — components that are not
strongly connected, an ordering built from the wrong direction, or a
graph built with a different zero test than the one used to count
violations. That is worth having, because every one of those is a
silent failure otherwise. The discriminating check on the block
structure itself is the dimension histogram, which is why the test
asserts the NLO system splits into more than one block rather than
merely summing to 7 rows.

`"ZeroTest" -> "Structural"` (default) treats a textually nonzero entry
as a coupling. This is the setting that reproduces the measured block
inventory and Codex's independent SCC count; `"Algebraic"` additionally
runs `Together` on every entry, which is slower and can only merge
blocks, never split them.

### 2b. Classify

```wolfram
classification = ClassifyBlocks[decomposition,
  "OutputDirectory" -> workDirectory];
```

Quotients the block set by connection equivalence: basis permutation
composed with an optional `v <-> w` relabelling (which exchanges the
roles of `Av` and `Aw` as well as their arguments). Blocks are bucketed
by permutation-invariant entry multisets, then matched *exactly* inside
a bucket by searching for a group element and accepting it only when
the images agree entry by entry.

Two failure modes of an earlier, external implementation are why this
is done this way, and both are guarded here:

- a "canonical" form that is not canonical under its own group (two
  classes that were literal column permutations of each other);
- structural `===` on mathematically equal but textually different
  matrices.

The normal form is `Cancel[Together[...]]` with the denominator's
leading coefficient divided out, so two entries agree exactly when they
are equal as rational functions. That over-splitting cost 186 classes
where there are 173.

Blocks of dimension above `"MaxBlockDimension"` (default 7) are
**refused**, not approximated: the orbit key enumerates `d!`
permutations, and a wrong canonical form silently merges or splits
classes and poisons every downstream reuse. Our data tops out at
dimension 4.

**Correctness does not depend on the bucketing.** This is worth stating
because the first implementation of this module reproduced the very bug
it exists to prevent. Its bucket key folded in the swap by exchanging
`Av` and `Aw` *without* relabelling `v <-> w` inside the entries, so
swap-equivalent blocks landed in different buckets, were never compared,
and became separate classes — over-splitting, exactly as before. The
NLO system caught it: 7 blocks produced 7 classes where 5 is correct.

The structural fix is that the invariant is now only an optimization.
Provisional classes are merged on the **orbit key**, which is canonical
by construction, so any two provisional classes sharing one are the same
class however they were bucketed; member maps are then re-derived
against the *final* representative. A bad invariant can now only make
the quotient slower, never wrong. `Tests/t_canonical_blocks.wls`
criterion C asserts the quotient is strictly coarser than the block set
with every member map independently verified, which is the regression
for this bug.

### 2c. Canonicalize

```wolfram
run = CanonicalizeClasses[classification,
  "OutputDirectory" -> formDirectory,
  "AnsatzDegrees" -> {0},
  "TimeConstraint" -> 1200];
```

Per class representative: translate the regulator into ``CANONICA`eps``
at the call boundary only, walk the ansatz-degree ladder in `(v, w)`,
and if that fails and the class has **exactly one** irreducible
denominator factor of total degree >= 2, build a conic chart and retry
in the chart frame. Nothing is stored until `ValidateCanonicalForm`
accepts it; writes are atomic (temp + rename); a class whose form file
already exists is skipped, so the campaign is resumable.

The chart builder has two branches, both verified symbolically before
the chart is used:

- **LinearSolve** — `q` is linear in one variable: solve `q == t^2` for
  it directly (covers `4 v + w^2`, `v^2 + 4 w`, the bilinear `1 - 4 v w`);
- **SquareCompletion** — `q = l^2 + (linear)`: shift `u = l + 2 t` and
  solve the linear remainder (covers the three Källén variants).

Single-quadratic detection uses **total** degree in `(v, w)`. Using the
degree in one variable misfiles the bilinear `1 - 4 v w` as linear, and
the chart branch then never engages.

### 2d. Certify

```wolfram
ValidateCanonicalForm[formFileOrRecord]
```

See section 4. Run it as a standalone audit over a form directory at
any time; `CanonicalBlocksStatus[formDirectory, "Validate" -> True]`
does it for every stored form at once.

---

## 3. Expected costs (measured, not estimated)

Measured on the 91-family NNLO UU lattice, one kernel, Wolfram 14.2.

**Inventory**

| Quantity | Value |
|---|---|
| Family DE artifacts | 91 |
| Rows (master instances) | 1561 |
| SCC blocks | 1119 |
| Block dimension histogram | 784 x dim-1, 265 x dim-2, 33 x dim-3, 37 x dim-4 |
| Connection-equivalence classes | **173** |
| Physical masters covered | 347 |

**Canonicalization campaign (degrees 0-2, 300 s cap, 4 GB)**

| Quantity | Value |
|---|---|
| Classes attempted | 166 (7 already done in a prior pass) |
| Canonicalized | 159 |
| Unresolved | 7 |
| Wall time | 5934 s = **1.65 h** |
| Time spent on the 159 successes | **495 s** |
| Time spent on the 7 refusals | 5439 s (**92 % of the campaign**) |
| Slowest success | 82 s (class 123, chart frame) |
| Median success | ~2 s |

**Ansatz-degree sufficiency**

| Degree | Successes |
|---|---|
| 0 | 157 / 159 (**98.7 %**) |
| 1 | 2 / 159 (classes 25 and 171; 6 s and 35 s total) |
| 2 | 0 |

**Frame**

| Frame | Successes |
|---|---|
| `(v, w)` direct | 142 / 159 |
| conic chart | 17 / 159 (**10.7 %**), 1 s to 82 s |

**The 300 s cap lesson.** Class 26 canonicalizes at degree 0 in 324 s
and class 33 in 631 s. The 300 s cap missed class 26 by 24 seconds and
they were both recorded as hard classes; an extended-cap rerun took the
ledger from 166/173 to **168/173**. **Use `"TimeConstraint" -> 1200`.**

**The operational consequence of those two tables.** Cost is dominated
almost entirely by classes that will never resolve, and degree 0 solves
essentially everything that is solvable. So do not run a 0-1-2 ladder
across the whole set:

1. **Pass 1** — `"AnsatzDegrees" -> {0}`, `"TimeConstraint" -> 1200`
   over all classes. Expect ~2 h wall for 173 classes, of which under
   15 min is real work.
2. **Triage the residue by *how* degree 0 failed.** A *fast refusal*
   (CANONICA rejects the ansatz in seconds) is worth escalating: both
   measured degree-1 successes were fast refusals at degree 0. A
   *timeout* is not: a larger ansatz is strictly slower, and every
   degree-1/2 escalation after a degree-0 timeout in our runs also
   timed out.
3. **Pass 2** — `"AnsatzDegrees" -> {1, 2}` with `"Classes" -> {...}`
   restricted to the fast-refusal set only.

`"Verbose" -> True` prints the per-degree status
(`ok`/`refused`/`timeout`/`memory`/`unvalidated`) that this triage
needs.

**Reference points.** CANONICA on the CF3 block: 0.30 s. On the
7 x 7 NLO system: 0.50 s. On a 47-dimensional block: 2.6 s. Size is not
the cost driver; rationality of the alphabet is.

---

## 4. The validation-certificate rule

> **CANONICA reports a failed sector as `{False, {partial
> transformation, partial matrix}}` — a two-element list of two
> matrices, structurally identical to a success.**

A campaign that tests the return shape accepts failures as successes.
Ours did: 47 of a claimed 83 successful blocks were failure tuples, and
the error survived a full sweep, a coverage report and an outgoing note
to a collaborator before the reconstruction gate caught it.

**The only accepted certificate is exact dlog reconstruction from
constant residues.** For the stored `A_eps`, with letters extracted
from the matrix itself:

```
A_eps^(i)  ==  eps * Sum_j  R_j * d/dx_i log(letter_j)
```

with every residue matrix `R_j` **constant** — free of the regulator
and of both variables — and the equality holding **exactly**, entry by
entry, after `Together`. `ValidateCanonicalForm` is this check and
nothing else.

Three rules follow, all enforced in code:

1. `ValidateCanonicalForm` **never reads a stored `"Validated"` flag**.
   A flag is an assertion; the matrices are the evidence. Test G asserts
   that a record claiming `"Validated" -> True` over a bad matrix is
   still rejected.
2. `CanonicalizeClasses` runs the gate **before** writing, so a form
   file cannot exist without its certificate. Failure artifacts go to a
   quarantine directory, never into `forms/`.
3. Nothing enters the shared ledger without its certificate.

**Known gap, stated explicitly.** The gate certifies that the *stored
matrix is an epsilon-form*. It does not re-verify that the stored
transformation `T` conjugates the original system into that matrix.
That check is convention-sensitive (which side `T` acts on, and the
sign of the `dT` term) and has not been validated against the 168
stored forms, so it was deliberately **not** added here rather than
shipped untested. The tier-3 variation-of-constants assembly does
verify the conjugation entry by entry as part of its five-part
certificate, so the composite pipeline is covered; a standalone
`VerifyTransformation` option for stage 1 remains an open item.

---

## 5. Kernel and seat discipline

The machine runs one Wolfram license seat shared with a parallel Codex
session. All of these are recorded incidents, not hypotheticals.

- **Check the seat before EVERY `wolframscript` invocation, including
  one-line probes.** A stray probe kernel killed an overnight
  hard-class run through the ~2-kernel license cap.
- Use `pgrep -x wolframscript` — exact executable match only. A
  substring `pgrep` matches the agent's own shell command line; that
  self-match has bitten us three times.
- If an instance is running that is not yours, **wait** in a background
  sleep loop. Do not start alongside it.
- **One own main kernel maximum**, at most 4 subkernels. Half the
  machine's Wolfram capacity is reserved for the parallel session.
- **Never kill by name pattern.** A `kill -9` by name took down every
  `WolframKernel` on the box including the collaborator's active
  session. Kill only PIDs traced through your own parent chain.
- Long runs get an active health-checker with <= 30-minute visibility
  and per-item progress lines.
- Run scripts **from files**, never from `-code`, so a truncated
  command cannot half-execute.
- Never pipe a long run's stdout through `head` — the `SIGPIPE`
  severed a run's output at minute one and the verdicts had to be
  recovered from files.

`CanonicalizeClasses` prints exactly one greppable line per class:

```
[CanonicalizeClasses] class=98 address=blk... dim=2 status=CANONICALIZED degree=0 frame=chart seconds=1
[CanonicalizeClasses] class=79 address=blk... dim=2 status=UNRESOLVED degree=- frame=chart seconds=3612
```

`CanonicalBlocksStatus[formDirectory, "Classes" -> classification]` is
meant to be called **from a second kernel** while a campaign runs; it
reads only files and reports `DONE`/`MISSING` per class.

---

## 6. Known hard classes and the escape hatches

After the extended-cap rerun the ledger stands at **168/173**. The five
open classes are all single-quadratic and CANONICA-certified
**nonrational in `(v, w)`**.

| Class | Character | State |
|---|---|---|
| 79 | Källén-type variant | degree 0 and 1 both time out at 1200 s in the chart frame |
| 115 | bilinear `1 - 4 v w`, dim 2 | refuses even in the chart frame; queued for direct second-order ODE analysis |
| 77, 97, 118 | Källén / `(v+w-1)^2+4v` variants | degree-0 chart runs requeued |

Escape hatches, cheapest first:

1. **Extended caps.** `"TimeConstraint" -> 1200` (or higher) with
   `"AnsatzDegrees" -> {0}` and `"Classes" -> {26, 33, ...}`. This is
   what recovered classes 26 and 33. Try this before anything else.
2. **Chart frame.** Automatic when the class has exactly one quadratic.
   If the chart does not engage, check the total-degree classifier
   first: the bilinear case is the one that slips through. Run with
   `"Verbose" -> True` to see the built chart printed.
3. **Chart-frame degree escalation.** Only after a *fast* refusal in
   the chart frame; a chart-frame timeout will not improve with a
   larger ansatz.
4. **Direct ODE analysis** for dimension-2 stragglers (class 115): a
   2 x 2 first-order system is one second-order scalar ODE, which can
   be attacked directly instead of through an epsilon-form ansatz.
5. **Tier 3 (block-diagonal + variation of constants)**, per
   `Design/MasterSolvingArchitecture.md`. This is the general fallback
   and it does not need the class to be canonicalizable at all: the
   diagonal sectors get their own frames and the residual couplings are
   integrated order by order. A class that resists 1-4 is not a
   blocker, it is a tier-3 consumer.

No elliptic sector has been demonstrated anywhere in the 91 families.
Every hard sector found so far carries exactly one irreducible
quadratic and is therefore a genus-0 single-conic case.

---

## 7. Content-addressed exchange schema

Class records are keyed by **content**, not by label, so that two sides
computing the same quotient independently agree without negotiating
integer names. Integer `ClassID`s are conveniences assigned after the
partition exists; they are stable within a run and must never be the
join key across sessions.

`ClassifyBlocks` emits `"Classes"` as an association keyed by
`ContentAddress`, each record carrying:

| Key | Meaning |
|---|---|
| `ContentAddress` | `"blk" <> ` truncated SHA-256 of `OrbitKey` — the join key |
| `OrbitKey` | the exact least element of the orbit of the normalized matrix pair; the content itself |
| `RepFamily`, `RepRows`, `RepBasis` | the representative block's identity and **basis** |
| `RepAv`, `RepAw` | the representative connection matrices |
| `Members` | one entry per block in the class |
| `Members[[k]]["Swap"]`, `["Permutation"]` | the **explicit orbit map** |
| `Dim`, `Size`, `Families`, `ClassID` | conveniences |

**Semantics of the orbit map**, which is the part a consumer must get
right: member row `i` corresponds to representative row
`Permutation[[i]]`, after the optional `v <-> w` relabelling indicated
by `Swap`. Concretely the member's matrices are reproduced by

```wolfram
pair = If[Swap, {swapVW[RepAw], swapVW[RepAv]}, {RepAv, RepAw}];
{pair[[1]][[perm, perm]], pair[[2]][[perm, perm]]}
```

and this reproduction is exact, entry by entry — it is a certificate of
equality, not a claim about an invariant. `Tests/t_canonical_blocks.wls`
criterion C recomputes it independently rather than trusting the stored
`MapVerified` flag; a consumer should do the same the first time it
imports a foreign catalogue.

Stored form records (`class<ID>.wl`) carry `ContentAddress`,
`Transformation`, `EpsForm`, `Variables`, `Chart`, `Frame`,
`AnsatzDegree`, `Regulator`, `Seconds`. `Variables` is `{v, w}` for a
direct form and `{v, t}` or `{w, t}` for a chart form — a consumer must
read it and not assume `(v, w)`.

**Ledger rule, both sides:** no entry without its exact certificate —
dlog reconstruction for a canonical form, an explicit verified map for
an equivalence.

---

## 8. Rerunning the test

```bash
cd /home/maxzhang/factorization-and-loops
wolframscript -file Tests/t_canonical_blocks.wls    # one kernel; check the seat first
```

Criteria A-I are listed at the top of the test file. It covers the NLO
system end to end (decompose, classify, canonicalize, validate), both
chart-builder branches on two representatives rebuilt from this
repository's own NNLO artifacts, the failure-tuple regression in three
parts (rejected failure tuple, rejected shape-valid non-form, accepted
genuine form), and the status helper. It needs no scratch directory and
completes in minutes.
