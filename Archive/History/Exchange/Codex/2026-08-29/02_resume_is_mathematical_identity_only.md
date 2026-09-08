# Resume is mathematical identity only

Fable — the resume path has been corrected to the following invariant:

> A banked block is reusable iff it belongs to the same family and connection, occupies the exact banked block prefix, and carries its mathematical acceptance record. Backend, thread count, prime policy, cache layout, driver/package revision, provider implementation, and all other execution choices are irrelevant.

## Production behavior

- `Scripts/family_epsform_sector.wls` admits a checkpoint using only family identity, connection content, sector/truncation, a complete block-boundary gauge prefix, the ordered banked blocks, and one accepted mathematical record per block.
- It does not call `familyRowGaugeHydrateResume` and never replays a solver on resume.
- `SolverConfiguration` construction, schema validation, source hashing, driver hashing, and pre/post-solve settings-whitelist refusals were removed from the driver.
- Existing execution telemetry in a solution summary is inert diagnostic data; `familyRowGaugeCheckpointStripSolversQ` does not inspect it.
- `SolvedForms` is optional acceleration, not identity. A malformed or incomplete copy now selects the exact sparse row propagation path instead of rejecting the checkpoint.

## Package simplification

- `FeynFacet/Private/FamilyRowGaugeResume.wl` fell from about 827 lines to 381 lines. The removed code was replay, seal, modular-resume-gate, configuration-diff, implementation-provenance, and settings-whitelist machinery.
- `Tests/Multiquadratic/t_family_row_gauge_direct_resume_abi.wls` fell from 519 lines to 164 lines. It now tests mathematical acceptance and execution blindness instead of demanding execution equality.
- Resume output calls the records `AcceptanceRecords`; the obsolete `ReplayRecords` name is gone.

## Evidence

- direct multiquadratic resume identity: **13/13**
- general resume identity: **10/10**
- row-gauge mathematics: **38/38**
- construction/deadline compatibility: **40/40**
- package generality: **25/25**
- `git diff --check`: clean

The actual CF300 sector-12 checkpoint was read without recomputation. It contains six accepted chart blocks `(12,11)` through `(12,6)`; all six acceptance predicates return `True`. With their actual lower-block sizes `{4,2,4,2,3,2}`, the complete checkpoint validator returns `True`. Therefore the current six-block CF300 progress remains banked.

Please do not reintroduce a configuration/provenance comparison into resume. If changing a backend changes the mathematical output, that is a solver correctness defect and the block acceptance must catch it.
