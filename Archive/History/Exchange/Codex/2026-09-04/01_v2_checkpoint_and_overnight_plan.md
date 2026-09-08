# V2 checkpoint and overnight plan

**To:** Fable and user
**Date:** 2026-09-04

## Closed in this checkpoint

1. `DeriveMasterIntegralEpsilonOrderRequirements` now derives the required epsilon orders of each master integral from two explicit mathematical inputs:

   `required master order = requested hard-function order - epsilon valuation of its hard-function coefficient`.

   The result is a V2 record whose predicate re-derives this relation from the stored input data. The focused suite passes 7/7.

2. The correct CF303 use of the soft point `z=2p` has been made explicit. Once the complete local maps for the 43 source components and the two `G25` components are known in the same basis as the differential equation, they are initial data for that differential system at a tangential base point. The residue coefficient operator itself is independent of the lower integration limit; the formal Chen integrals are rebuilt with lower limit `z=2p`.

   Consequently, a `293 x 45` inverse map back to the old regular base point is not required. What is required is the complete local `G25` initial-data map, including `G25 = F25 - H(2p)L`. `CF303JunctionRebase.wl` now records the new path consistently in the source operator, final block, and returned adapter. Its focused check passes 2/2.

3. The generic rational-in-epsilon operator now describes this operation accurately as solving the same differential equation with a new base point and new initial data. It no longer labels the operation as path composition. The existing physical-result suite remains green, 9/9.

4. Package-facing usage and load order for the epsilon-order derivation are installed. The usage test reports no missing public documentation, and the package-generality suite passes 24/24.

## Deliberately not promoted

The attempted boundary-function extension of `ConstructMasterIntegralSolution` was not complete or tested and was therefore removed from this checkpoint. A physical boundary stratum leaves functions of its tangential variables, not constants. The final consumer may accept those functions only when their tangential evolution and path representation are explicit. This is the first task in the overnight plan.

The archived CF303 records remain pre-V2 evidence. They have not been relabelled as V2 results. CF303 must be regenerated from the preserved mathematical inputs before a production `MasterIntegralSolution` is emitted.

## Next work

The detailed, ordered overnight program is:

`Goals/Codex/2026-09-04/01_v2_physical_solutions_and_regeneration.md`

Its critical path is boundary-function support, CF303 V2 regeneration and tangential-base solution, demanded-coefficient construction, then all-family regeneration and measurement. General terminology cleanup and removal of obsolete code follow completed mathematical units rather than blocking them.
