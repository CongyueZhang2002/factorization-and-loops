# FeynFacet

A Wolfram Language framework for collinear-factorization calculations using
diagrams, reverse unitarity, IBP reduction, master-integral differential equations,
physical boundary integration and endpoint distributions.

**Start with [WORKFLOW.md](WORKFLOW.md).** It gives installation checks, CPU
limits, card layout, scientific stages, commands, reuse rules and completion
criteria. [STATUS.md](STATUS.md) is the current state; [AGENTS.md](AGENTS.md)
contains implementation conventions.

| Guide | Use |
|---|---|
| [Project index](Projects/README.md) | Choose an existing process, polarization and channel |
| [ppHX UU NNLO channel workflow](Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/README.md) | Current scoped double-real result and exact replay directions |
| [SIDIS UU NNLO](Projects/SIDIS_UU_NNLO/NNLO/README.md), [LL NNLO](Projects/SIDIS_LL_NNLO/NNLO/README.md) | Complete saved channel results and reference comparisons |
| [Cards and common results](Design/ProjectCardsAndResults.md) | Root/contribution cards, Born dependencies, epsilon orders, PDF/FF schemes |
| [Script index](Scripts/README.md) | Driver selection and required inputs |
| [DE and finite solutions](Scripts/Transport/README.md) | Explicit symbolic solutions and numerical evaluation |
| [Physical boundaries](Scripts/Boundary/README.md) | Physical constants and singular matching |
| [Coefficient assembly](Scripts/Coefficients/README.md) | Rational coefficients, endpoint functions and distributions |
| [Validation](Scripts/Validation/README.md), [tests](Tests/README.md) | Coverage and independent checks |
| [Package organization](FeynFacet/README.md) | Mathematical ownership and extension points |
| [Roadmap](Goals/README.md) | Remaining supported-scope and general-framework work |

Process inputs and outputs live under `Projects/PROJECT/ORDER/CHANNEL`:
`Cards` holds contribution declarations, `Results` holds mathematical output,
and `Kira` holds reduction workspaces. Shared physics is in
`Projects/PROJECT/card.wl`. General algorithms belong in `FeynFacet` and general
launchers in `Scripts`.

The finite DE representation stores actual epsilon coefficients and closed
definitions. Full epsilon-form canonicalization and GPL conversion are optional.
Physical boundary data, branch/domain conditions and final factorization
coverage are explicit requirements.

Supported NLO channels have a complete orchestration command. Existing NNLO
calculations have documented phase/replay inputs; arbitrary new NNLO geometry
is not promised to work from one card alone. The current ppHX double-real
contribution is scoped separately from a complete NNLO hard function.

Retired code is under `Archive/RetiredCode` and is never loaded. Superseded status
and correspondence are under `Archive/History`. Local vendor installations,
ignored results and Wolfram licences are not supplied by a Git clone.
