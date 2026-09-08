# CF300 sector 12: next finite-field ansatz tests

Date: 2026-08-23

Status: design and External-only support code are staged.  No Wolfram
kernel was launched, no package file was edited, and no process was
signalled by this work.

## What the four certified images already say

All four `(p, eps)` images have the same ranks:

| variant | support | one-forms | unknowns | rank A | rank [A|b] | nullity |
|---|---:|---:|---:|---:|---:|---:|
| A0 | 30 | 36 | 624 | 612 | 613 | 12 |
| AS | 42 | 36 | 816 | 804 | 805 | 12 |
| AL | 30 | 48 | 672 | 632 | 633 | 40 |
| ASL | 42 | 48 | 864 | 824 | 825 | 40 |

This is structural, not an unlucky prime or epsilon image.

- The first support shell adds 192 columns and exactly 192 to the rank,
  but leaves the one-dimensional affine obstruction intact.
- The 12 rational-channel factor dlogs add 48 residue columns but only 20
  rank directions and do not touch the obstruction.  They are not the
  missing alphabet by themselves.
- The gauge already contains every grade of the rank-two field, including
  the root-product grade.  This is not a missing-grade bug.
- At a fixed epsilon image every gauge and residue coefficient is already
  free.  Raising the later rational-in-epsilon interpolation degree cannot
  change affine consistency.  There are no normalization equations here.
- Adjoining the inactive third square root is not a first-line repair.  In
  odd characteristic, Galois averaging a solution in a conjugation-stable
  extension ansatz would give a solution over the present rank-two
  subfield.  The current inconsistency therefore survives that extension
  unless the ansatz itself adds a new denominator or letter orbit.

## Highest-information next test: the dropped simple poles

`TRRationalGaugeDenominator` takes a forcing-channel pole of order `p` to
gauge power `max(p-1,0)`.  It therefore drops every simple-pole factor.
That rule is only the minimal higher-pole denominator, not a theorem that
the gauge has no simple poles.  The rational package already exposes
`GaugeDenominatorFactor` for exactly regulator-resonance/simple-pole
widening, and the earlier CF300 `(8,5)` full-alphabet probe needed such a
factor.

The current denominator is

```text
D = y (x+y-1) (4xy-1)^2
    (-1-2 eps-x-2 eps x-y-2 eps y+xy+eps xy).
```

The next census should use the already cached exact rational channels of
`E`, `C`, and `BBar`, factor their denominators, and form the set of
irreducible factors absent from `D`.  Test the absent factors one at a
time as `D f`, with the all-survivor product only after factorwise
screening.  This is different from AL: adding `dlog(f)` changes the target
epsilon-form alphabet; multiplying `D` by `f` changes the admissible gauge
poles.

Denominator tests must be pure supersets.  Either rank
`[A_D | A_(D f)]`, or use common denominator `D f` and certify

```text
S0 + Supp(f)  subset  S_(D f),
```

because `P/D = (P f)/(D f)`.  Merely replacing `D` by `D f` with the old
numerator support could lose the old ansatz and is not a valid
discriminator.

## Certified residual screen

For every inconsistent image `A x = b`, obtain a normalized left witness
by solving

```text
[ A^T ] y = [0]
[ b^T ]     [1]
```

over `F_p`.  The pinned native affine solver can certify this system.
For a candidate column block `C`:

- `y^T C == 0` rigorously proves that this block cannot repair that image;
- `y^T C != 0` is only a necessary pass, after which the full two-rank
  test of `[A C]` and `[[A C]|b]` is required.

This screen is much cheaper than rebuilding and reducing a maximal blind
ansatz.  It should be run at all four existing images.  An all-zero result
at even one certified image rejects the candidate.  A candidate that
passes all four is promoted to a full point count

```text
Max[4, Ceiling[(N + 32)/32]].
```

## Test order

1. Validate the support/denominator/one-form rebind against the A0 cache.
   QUICK mode checks identity rebind, physical column projection,
   support `{0..6} x {0..7}`, a denominator-only rebind, an appended
   one-form-only rebind, their combination, and two fail-closed mutants.
   FULL mode additionally compares the combined rebound assembly with one
   fresh full `DRCAPrepare` by exact `SameQ`.
2. Construct left witnesses for all four certified images.
3. Factor cached `E/C/BBar` channel denominators.  Score each missing
   simple-pole factor as a denominator augmentation.  Combine only the
   factors that pierce every witness, certify support containment, then run
   full ranks.
4. If denominators fail, score the second support shell anisotropically,
   not as one blind rectangle.  Relative to the already-tested
   `{0..5} x {0..6}`, partition `{0..6} x {0..7}` into the new x edge
   (7 monomials), new y edge (6 monomials), and corner (1 monomial).
   The combined support has 56 monomials, 896 gauge unknowns, 144 current
   residues, 1040 unknowns total, and requires 34 points.
5. Only then enlarge the algebraic alphabet.  First take Galois conjugate
   orbits of the **forcing potentials** whose dlogs generated the current
   basis, then algebraic factor/conjugate potentials and their norms.
   Preserve each generating potential and the exact `dlog` identity.
   Closed one-form pairs without a potential are diagnostic-only and
   cannot be promoted to a solved package artifact.  Norm dlogs test the
   rational-even direction; conjugate ratios/orbits test the algebraic-odd
   directions.  Compile only the appended one-forms and score their four
   residue columns per letter.

Blind degree growth beyond the anisotropic shell and a third-root
extension are lower-value fallbacks.

## External implementation

- `DirectRootChannelAnsatzRebind.wl`
  - accepts only a fully valid target `PreparedReconstruction`;
  - requires the target one-form list to be a pure prefix-preserving
    superset;
  - reuses compiled `E`, `C`, `BBar`, root squares and root dlogs;
  - changes support without compilation (point assembly already builds
    monomials and their derivatives dynamically);
  - compiles only appended one-forms and, when changed, `D` and `dlog D`;
  - rebuilds every count, column order, exact/compiled fingerprint and the
    complete assembly fingerprint, then calls the public validator;
  - is pinned to assembler SHA-256
    `227a323762a8803b2bf03a9a96dc0d96c61a48d8e4f4213fa6b5a736d216e4f6`.
- `AffineInconsistencyWitness.wl`
  - constructs and independently checks `A^T y=0`, `b^T y=1`;
  - scores candidate blocks and distinguishes rigorous zero-score rejection
    from a merely necessary nonzero pass;
  - pins the adapter and native binary hashes.
- `run_cf300_sector12_ansatz_rebind_gate.wls`
  - consumes the immutable A0 compiled cache rather than recompiling the
    equation core;
  - QUICK is the first required managed-pool mission; FULL is the
    expensive differential mission and should be run once, not per ansatz.
- `test_next_ansatz_static.sh`: 34/34 static checks pass.

The A0 cache exists at
`/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl`
with SHA-256
`0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be`.
It contains the matrix-independent compiled equation core.  It does not
contain an A0 sample matrix; the latter is cheap to regenerate on any
desired common point stream.

## Exact managed-pool launch arguments (not executed here)

```bash
ROOT=/home/maxzhang/factorization-and-loops
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool
DIR=$ROOT/External/CodexExchange/triple_root_2026-08-22/cf300_sector12_next_ansatz_xh
PREP=$ROOT/External/CodexExchange/triple_root_2026-08-22/cf300_sector12_physical_rank3_xh/rank2_cross_prime_v1_xh/CF300_12_9_rank2_preparation.wl
CACHE=/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl

POOL="$POOL" FACET_TASK_BROKER_MAX_HELPERS=0 \
  "$ROOT/Scripts/kpsubmit.sh" cf300_s12_rebind_quick_xh_v1 \
  "$DIR/run_cf300_sector12_ansatz_rebind_gate.wls" \
  "$ROOT" "$PREP" "$CACHE" \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rebind_quick_xh_v1.wl \
  QUICK
```

FULL uses the same arguments with a fresh output and final argument
`FULL`.  It should receive one flat pool kernel, no broker helpers, and no
subkernels.  QUICK should be dominated by reading/validating the 32 MiB
cache and the 28 MiB preparation.  FULL adds one fresh physical direct
compile; the observed A0 compile was about 678 seconds.  Native left
witnesses have shape `625 x 672` for A0 and should be in the same
few-second class as the existing native ranks.

## Current hashes

| file | SHA-256 |
|---|---|
| `DirectRootChannelAnsatzRebind.wl` | `8b0f8d7fdab72d9660836d1f2a92e7f03be5eb1adcbd7082b327ed4bb8b8e907` |
| `AffineInconsistencyWitness.wl` | `1dd64f9a2864a26da5ff5c76eeda1d072736ae05cadaf81916f7ef2462c9a8bc` |
| `run_cf300_sector12_ansatz_rebind_gate.wls` | `41ef1bb5826edbda8afb8c36c9e10be67b540f2e39782738709e04e64a11a5a0` |
| `test_next_ansatz_static.sh` | `a598f30bdd6a2741a681264a7d851803f5e556c79871e0a45252892690f29ed1` |

