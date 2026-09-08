# Result organization, 2026-09-06

Persistent outputs now belong to their process. Kira workspaces use
<process>/Kira; reconstruction uses <process>/Results/CoefficientSimplification.
The defaults and active source references have been changed accordingly.
Codex now contains only consultation-bridge state and its guide.

Approximately 10.89 GB moved from Codex into the process folders,
including NLO reference work. Retained AMFlow endpoint calculations are under
ppHX_NNLO_DoubleReal/Results/BoundaryValues. Third-party papers and software
moved to External/References/BoundaryMethods.

## Results and cleanup

- Current DEs and finite solutions remain in
  ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/Stage1And2_2026-09-06.
- GPL results are in ppHX_NNLO_DoubleReal/Results/GPL_2026-09-06.
  RationalControl/GPL/solution.wxf and CF254/GPL/solution.wxf contain actual
  finite GPL expressions. The benchmark driver also saves its converted
  solution and any constructed Taylor coefficients beside the report.
- Validation records moved from Design into process Results/Validation.
  Historical work scripts and source snapshots moved to the code backup.
  Example outputs likewise moved into process Results/Examples.
- Removed 898.90 MB of stale repository files:
  seven uncompacted expression backups, three superseded reconstruction
  revision directories, development Taylor expansions, older DE comparison
  inputs and numerical trials, plus archived execution output.
- Removed 419.76 MB of completed temporary runs
  and migration scratch after retaining their useful outputs and records.
  This includes temporary copies created for the migration.
- Source pair inputs, Kira databases/rule tables, current reconstruction stores,
  numerical references and regression fixtures remain available.

The repository's regular-file contents decreased by approximately
895.51 MB.
Moving retained data changes its location, not its contribution to the total.
Sizes count file bytes, excluding .git and linked dependencies.

## Verification

All 91 finite solutions validate. Ninety solution files and ninety construction
input files are byte-identical to the originals. CF269's solution and input had
only two reference strings updated to the retained IBP directory and table;
all mathematical content is unchanged. All 91 raw DE files retain their paths,
sizes, modification times and inodes.

Five active reconstruction manifests resolve every registered expression file
with the expected byte count. Seven expression backups were removed only after
checking those current registrations. The retained production Taylor records
are validated and have the same states, centers and boundary bindings as their
removed development predecessors.

The focused path/generality, reconstruction parser, master-order workflow and
GPL tests passed 99 checks with no failures. Five modified Wolfram sources parse;
the modified Python diagnostic passes syntax checking. Saved GPL representations
and a saved Taylor expansion load and evaluate. Active documentation links and
old Codex process-path scans pass.

No full DE regeneration, canonicalization campaign or new AMFlow computation
was needed. Two optional GPL conversions materialized the previously unstored
benchmark expressions in their permanent project locations.

[The process result index](../ppHX_NNLO_DoubleReal/Results/README.md) lists the
retained data. [The migration and removal records](../ppHX_NNLO_DoubleReal/Results/Validation/ResultOrganization_2026-09-06/)
contain exact paths, byte counts, test logs and integrity checks.
