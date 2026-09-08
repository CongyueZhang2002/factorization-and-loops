# Repository consolidation, 2026-09-06

The active tree now distinguishes the general NNLO implementation from its
upstream workspaces, independent mathematical references and historical
experiments. The current DEs and finite solutions were not regenerated or changed.

## Folder changes

Sizes below are decimal MB of regular-file contents. They describe this
cleanup only, excluding the earlier 5.70 GB net removal.

| Folder | Before | After | Decision |
|---|---:|---:|---|
| Archive | 0.90 | about 10.55 | Historical notes, plans and correspondence; old VoC source moved to code backup and its generated maps removed |
| Codex | 11,250.93 | 10,887.90 | Active Kira/reconstruction workspaces retained; old probes, duplicate tests and transport environment removed |
| Design | 8.69 | about 6.62 | Current methods and evidence; 20 superseded top-level documents and their evidence moved to history |
| Examples | 0.026 | 0.027 | General input examples retained and indexed |
| Exchange | 1,139.47 | 0 | Correspondence moved to history, source to backup, old generated results removed |
| Goals | 0.126 | 0.002 | Dated objectives replaced by one current general NNLO roadmap |
| Prototypes | 0.060 | 0 | Two independent references moved to Tests/Support; unused prototype retired |
| Runtime | 263.93 | 0 | Stopped old kernel-pool and DE-closure runs removed; five scripts preserved |
| Scripts | 1.245 | 0.478 | 149 files reduced to 59; old drivers, duplicate wrappers and migration tools retired |

A total of 704 files moved to the code backup, 953 to historical records,
and three to active test support. The prior chronological status and terminology
revision were also preserved before rewriting their current guides.

Removed 15,058 generated or duplicate files, totaling
1,745,350,041 bytes (about 1.745 GB). After new manifests, snapshots and
documentation, the working-tree reduction is about **1.74 GB**.
This does not imply that Windows automatically shrinks the WSL virtual disk.

## Current path and retained mathematics

[Scripts/Transport](../Scripts/Transport/README.md) is the general production
entry-point guide. Optional epsilon-form algorithms and input-driven benchmarks
remain available. HardClasses experiments, old-format diagnostic reports,
process-specific DE construction scripts, duplicate two-root wrappers and
completed migration tools are retired.

Tests/Support holds the independent finite-field row-transformation evaluator,
the experimental letter-discovery reference, and the NLO angular-integral
reference. Their mathematical role is explicit, and no test loads a backup.
Six focused tests retain the corresponding mathematical comparisons.

The large Codex coefficient-reconstruction and Kira directories are active
upstream workspaces used by the general modules. Physical AMFlow endpoint work,
downloaded boundary-method references, the required CF269 dimensional recurrence,
CF303 preparation, current numerical results and regression fixtures remain.

Historical boundary inventories and explicit NLO endpoint formulas were retained
as mathematical research records. The old Python environment was unused after
retiring its transport code; its installed package versions are recorded in
the backup. New scratch computations belong outside the repository.

## Documentation and verification

STATUS now states completion of the stored solutions up to constants without
mixing in older incomplete-run statuses. Goals contains the remaining general
NNLO work. Design/MathematicalTerminology distinguishes integral-family
equivalence, DE epsilon form, kernel coefficients, pole residues, epsilon
valuations and boundary data; it no longer instructs users to run a retired
converter or lists retired matching functions as live interfaces.

- All six focused test files passed: **153 assertions, zero failures**.
- All 182 current solution/input WXF files were inspected: no references to
  the retired run directories.
- **89,405 protected files** retained their paths, sizes and modification times,
  including current results, upstream workspaces and numerical references.
- All 15 active shell/Python scripts passed syntax checks.
- No active source import of Archive, Private_Backup, Exchange or Prototypes
  was found. Package algorithms and current artifact contents were unchanged.
- Selected-file whitespace checks passed. This cleanup preserves unrelated
  user edits in AGENTS.md.

The tests covered relocated mathematical references, current optional
canonicalization launchers, the master-order-to-solution workflow and NLO
numerical reference values. Expensive family regeneration was unnecessary.

[Verification logs](../ppHX_NNLO_DoubleReal/Results/Validation/RepositoryConsolidation_2026-09-06) contain the
test results and dependency check. [The backup manifest](../Archive/RetiredCode/FeynFacet/2026-09-06-repository-consolidation/manifest.json)
records every original moved/deleted path, destination, size and reason.
Original file contents were compared directly before removal.
