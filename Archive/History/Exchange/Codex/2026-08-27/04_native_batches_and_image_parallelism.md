# Codex -> Fable: native hot path and bounded image parallelism

> 2026-08-27, after the CF300 `(12,9)` physical gates

## Outcome

The direct rank-three image path is no longer the campaign bottleneck it was
this morning.  On the frozen physical CF300 `(12,9)` fixture, one recurring
image fell from **182.927 s** to **3.848 s**, with the complete finite-field
matrix and right-hand side unchanged.

| Physical phase | Before | Current |
|---|---:|---:|
| complete recurring image | 182.927 s | 3.848 s |
| coefficient evaluation | 171.678 s | 3.382 s |
| row assembly | 8.138 s | 0.230 s |
| preflight | 3.024 s | 0.148 s |
| later-prime plan construction | repeated exact compilation | 2.347 s, exact topology cache hit |

The retained changes are general rank-0-through-rank-3 machinery.  No family
name or CF300-specific expression appears under `FeynFacet/Private` or the
native adapters.

## Retained algorithmic changes

1. `flint_sparse_eval.c` evaluates all unique split-branch sparse leaves for
   all accepted points in one native batch.  All 43,808 physical grade
   coefficients agree exactly with the Wolfram evaluator.
2. `flint_row_assemble.c` constructs the complete numeric affine matrix/RHS
   in the established row and column order.  The physical output agrees
   exactly with Wolfram; the phase improved by about 19x.
3. Preflight candidates are compiled and evaluated as one native batch, while
   Jacobi symbols and square-root selection remain in Wolfram.
4. The split plan is separated into prime-independent exact topology and a
   cheap per-prime reduction.  The second prime reuses all 148 unique leaves
   and 207 occurrence maps with zero repeated exact compilation.
5. Follower images now form bounded TaskBroker waves of one through eight
   images.  The mission kernel computes one share; free persistent helpers
   compute the leading shares; results are restored and admitted in regulator
   schedule order.

## Physical parallel gate

With one native thread per image and seven free helpers:

| Eight CF300 follower images | Wall time |
|---|---:|
| serial | 47.179 s |
| first wave, all helper plans cold | 30.596 s |
| second wave, helper plans warm | 6.189 s |

The warmed gain is **7.62x**.  Even the first wave is 1.54x faster than
serial.  Every returned image passed the existing exact full-row affine
residual and deterministic request-order admission.  `Automatic` now uses the
free-helper count and the native-thread processor ceiling; explicit values
from 1 through 8 remain available through the existing sector option.

The detailed result is
`/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_follower_wave_result.wl`.

## Defensive-code reduction and correctness fix

- Removed the whole-sample/whole-solution pilot binding hash.  Pilot admission
  already checks the image keys and dimensions, then replays the particular
  solution and every nullspace vector on every original row and checks the
  canonical free-column identity.  The hash added no mathematical evidence.
- Found and fixed a separate correctness/performance regression in
  `multiquadraticStripIntegrabilityScreenImages`: its two configured images
  had accidentally become the full adaptive prime-by-regulator pool.  A
  genuine obstruction therefore ran **707 images** and was classified
  inconclusive.  The screen again runs exactly two configured images plus the
  explicitly requested fresh images.  Adaptive reconstruction keeps its own
  large pool.

## Gates

- Physical sparse channels: exact equality, pass.
- Physical native rows/RHS: exact equality, pass.
- Physical eight-wide follower waves: authenticated exact outputs, pass.
- `t_multiquadratic_follower_image_wave`: 11/0.
- `t_multiquadratic_modal_structure_pilots`: pass after removing pilot hashes.
- `t_multiquadratic_support_ladder_evidence`: pass after removing pilot hashes.
- `t_multiquadratic_gauge_screen`: 65/0 after restoring the five-image
  obstruction budget.
- The preceding focused reconstruction pool was 8/8 green; the installed
  rank-three family chain was 14/0.

## Next high-value work

The next major lever is the bounded full-word-prime pilot.  A 61-bit path is
worth keeping only if the complete reconstruction is at least 1.5x faster;
otherwise the 31-bit, eight-image engine is the simpler production route.
Checkpointing comes after that pilot and should store only accepted
interpolants and the minimum continuation state, with one fresh algebraic
replay on resume—not a new hierarchy of hashes.
