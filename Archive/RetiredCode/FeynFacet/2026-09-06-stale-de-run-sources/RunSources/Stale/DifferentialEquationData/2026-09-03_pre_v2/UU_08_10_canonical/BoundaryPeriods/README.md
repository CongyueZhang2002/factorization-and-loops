# Boundary periods — UU_08_10_canonical

Version-controlled home of the stage-3 boundary-period evidence. Created in
response to section 4 of
`Exchange/Codex/2026-08-15/02_assessment_of_fable_round6.md`,
which observed that the period records, the survey report and the class data
existed only under an ephemeral `/tmp/claude-1000/.../scratchpad` directory,
so a clean checkout could not repeat the calculations.

Start at **`LEDGER.md`** for the per-period status table.

## What is retained here

Codex's reproducibility list (their section 4) asks for six things. Mapping:

| requirement | here |
|---|---|
| 1. every differential system used by a test | `../DifferentialEquations/nnlo_de_*.wl` (already tracked) and `Certificates/FamilyCutData.wl` for the Kira family definitions, which otherwise live only in the gitignored `Codex/` workspace |
| 2. every supplied transformation and fundamental matrix | `Proofs/*.md` sections 2; the `2F1` closed form and its contiguous relation in `Scripts/verify_period_01_de.wls` |
| 3. exact boundary formulas and their branch assumptions | `Proofs/Period01.md`, `Proofs/Period06_07.md`, sections 3 and 4 |
| 4. exact symbolic residuals, or the commands that produce them | `Scripts/*.wls` — all four run from a clean checkout |
| 5. numerical values only as independent checks | `Proofs/*.md` section 6, explicitly marked not load-bearing |
| 6. expected test results | the "Expected results" / "Reproduction" block at the end of each proof record |

## Path policy

Every script resolves its inputs from `DirectoryName[$InputFileName]`, so
all references are relative to the repository root and nothing depends on a
temporary directory. `extract_families.py` is the one exception by
construction: it *reads* the gitignored Kira workspace in order to
regenerate `Certificates/FamilyCutData.wl`, and is only needed if that
workspace changes.

## Running the checks

```
cd <repo root>
wolframscript -file ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BoundaryPeriods/Scripts/verify_period_01_de.wls
wolframscript -file ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BoundaryPeriods/Scripts/verify_soft_domination.wls
wolframscript -file ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BoundaryPeriods/Scripts/verify_parametric_representation.wls
wolframscript -file ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BoundaryPeriods/Scripts/verify_transfers.wls
```

Acceptance lines:

```
PERIOD01_EXACT_DE     = True      (21 [OK])
SOFT_DOMINATION_EXACT = True      (26 [OK])
PARAMETRIC_REP_EXACT  = True      (12 [OK])
TRANSFERS_CHECKED     = 12
TRANSFERS_EXACT       = 12
CONVENTIONS_UNIFORM   = True
```

Each script is standalone and takes a single Wolfram seat; they are
independent and may be run in any order.

## Conventions

`dI/dv = Av.I` at `2 ka.kb = 1`, `v = 2 ka.kc`, `w = 2 kb.kc`, `D = 4-2 eps`,
per-family cut lists. Physical chamber `0 < v`, `0 < w`, `v+w < 1`, with
`s = 1-v-w` and `P = ka+kb-kc`, `P^2 = s`. Verified uniform across all
thirteen families used here (`CONVENTIONS_UNIFORM = True`).

## Related records

- `Design/Stage3BoundaryToolchain.md` — the toolchain and ledger criterion.
- `Design/Stage3PackageSurvey.md` — the measured package survey behind it.
- `Design/BoundaryNullityCounter.md` — the period census method.
- `QFPilotReport.md` — the quasi-finite pilot that produced the original
  certificates. Retained as provenance; where it and the `Proofs/` records
  differ, the `Proofs/` records supersede it, since several of its steps
  were numeric and have since been replaced by exact ones.
