# Resource split: finish CF259/CF303 while building the path-transport seam

Timestamp: 2026-08-30 PDT

Fable,

Please work in parallel on **one narrow, independent transport task** while Codex keeps the main critical path on closing CF259 and CF303.

## Current resource decision

The active CF259 `(27,7)` native plan discovery is genuinely saturating its allocation: the FLINT worker is using about 7.6 cores, with roughly 12.5 GiB combined kernel/worker RSS and more than 30 GiB memory still available. Do not take Mathematica subkernels or CPU cores away from that active elimination phase.

Your implementation/review work should therefore be CPU-light for now:

- use no Mathematica subkernels while the eight-thread CF259 elimination is active;
- use at most one or two CPU cores for compilation and bounded focused tests;
- do not edit the finite-field solver/resume modules currently on the CF259 critical path;
- when the heavy FLINT phase ends, resources can be redistributed according to the live pool.

## Requested independent task

Implement the smallest generic seam that lets `BlockwiseTransport` consume an already-certified exceptional path-forcing block. The seam should support both forms already encountered:

1. a rational path forcing, as in the accepted CF303 `(25,18)` artifact;
2. a single residual quadratic extension, as in the accepted CF303 `(25,14)` artifact.

The conceptual input should be a typed path-forcing record containing, without any family literals:

- target row/column block identity and dimensions;
- path parameter and path contract;
- exact forcing matrix on that path;
- extension type (`None` or `Quadratic`);
- for a quadratic extension, the declared root, root square, derivative rule, and branch convention;
- regulator valuation/pole information needed to request enough lower-sector orders;
- provenance of the modular acceptance record.

Insert this block **after the ordinary connection has been restricted to the same path and before transport depth/order analysis**. Expand its rational regulator dependence only to the order actually required, then let the existing blockwise recursion handle variation of constants. Ordinary epsilon-form blocks must remain on their existing path.

Useful existing scratch inputs are:

- `/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_18_exact_structured_path.wl`
- `/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_14_exact_quadratic_path.wl`
- `/home/maxzhang/factorization-and-loops-codex/Diagnostics/Scripts/exact_path_transport_exception.wl`

The last file already demonstrates a family-independent scratch adapter and should be the starting point rather than a fresh redesign.

## Acceptance target

Keep the validation mathematical and compact:

- one toy rational forcing and one toy quadratic forcing;
- verify the blockwise recursion/differentiate-back identity through a few regulator orders;
- verify that a negative regulator valuation requests the corresponding extra lower-sector depth;
- verify branch/root differentiation for the quadratic record;
- verify ordinary transport is unchanged when no exception record is supplied.

Please report the proposed package files, insertion point, focused test results, and measured overhead before running a broad suite.

## Explicit non-goals for this parallel task

- Do not build a broad new FLINT transport system yet.
- Do not productionize the entire selected-sheet/two-variable reconstruction pipeline yet.
- Do not add family-specific chart maps or CF259/CF303 names under `FeynFacet/Private`.
- Do not reintroduce eager two-variable `Together`/materialization.
- Do not add redundant pre-load or intermediate acceptance checks.
- Do not alter the epsilon-form solver while Codex is completing the last two families.

Once CF259 and CF303 are closed, the next major engineering round can productionize the selected-sheet finite-field provider as the general replacement for pathological symbolic materialization. For now, the path-forcing seam is the highest-value independent transport work with the lowest merge risk.

