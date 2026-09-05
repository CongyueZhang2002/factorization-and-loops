# V2 finite-field migration and test closure

**To:** Fable and user  
**Date:** 2026-09-04

The finite-field performance work is closed.  The retained changes are the
ones with same-block evidence recorded in
`18_hard_block_performance_acceptance.md`: CF259 `(27,23)` fell from
1,436.8 s to 951.4 s, and the complete `(27,19)` inconsistency fell from
more than 538 s to 151.2 s.  The slower mixed-grade alphabet experiment is
not connected to production.

The remainder of this change is a schema and vocabulary migration using the
same mathematics as before:

- square-root records expose `Generator` and `QuadraticRadicand`;
- off-diagonal entries of the basis transformation use
  `OffDiagonalBasisTransformationBlock` names;
- source-variable and coefficient-presentation data remain distinct;
- the family driver consumes the V2 quadratic-radicand records;
- checkpointed inhomogeneity data are compared after canonicalizing the
  mathematical defining data;
- reconstruction tries the available pilot primes until it finds a usable
  image instead of treating the first rejected prime as terminal;
- the finite-field row-basis prototype no longer contains fingerprint or
  hash machinery;
- obsolete V1 ABI/provenance tests were removed, while tests that deliberately
  check rejection of V1 input keep their old keys locally.

Two direct compatibility defects found during the final tests were corrected.
The CF303 adapter now reads the accepted V1 artifact's actual
`PhysicalGaugeOrders` field at the file boundary and points its historical
state-file evidence to `Stale`; its calculation is unchanged.  The deadline
test is now standalone-only because loaded pool state makes byte-for-byte
comparison of operational preparation records nondeterministic, while its
mathematical assertions pass in a fresh kernel.

## Test results

- All 44 changed test files pass.  The final changed-file run passed 43 files
  in the pool/required standalone paths; `t_solver_budget` then passed
  standalone with 31 checks and no failures.
- All 32 transport tests pass, including the CF303 physical-boundary adapter.
- All 56 multiquadratic tests pass.
- All 20 epsilon-form, 15 finite-field, 7 reconstruction, and 2
  differential-equation tests pass.
- The package-generality test and the 12 other core tests relevant to this
  change pass.

The repository-wide inventory still has two unrelated pre-existing failures:
`t_ghost_card_pipeline` fails inside `CollinearFactorizePreIBP`, and
`t_wolfram_traps` requires pre-V2 class-form files that were moved to
`Stale`.  Neither code path is touched by this finite-field/schema change.

`git diff --check` is clean.  No family or process name appears in
`FeynFacet/Private`.
