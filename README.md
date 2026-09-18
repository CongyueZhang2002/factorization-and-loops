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
| [ppHX UU](Projects/ppHX_UU/README.md) | Scattering cards and the scope of NLO/NNLO contributions |
| [SIDIS UU](Projects/SIDIS_UU/README.md), [LL](Projects/SIDIS_LL/README.md) | Current cards and regeneration status |
| [Electron-positron EEC](Projects/EE_EEC/README.md) | Quadratic measurements and the complete order-alpha_s result |
| [Physical normalization](FeynFacet/Normalization/README.md) | Derived state counting, operator sewing and observable conventions |
| [Cards and common results](Design/ProjectCardsAndResults.md) | Common/raw/result cards, generated sources, epsilon orders and PDF/FF schemes |
| [Script index](Scripts/README.md) | Driver selection and required inputs |
| [DE and finite solutions](Scripts/Transport/README.md) | Explicit symbolic solutions and numerical evaluation |
| [Physical boundaries](Scripts/Boundary/README.md) | Physical constants and singular matching |
| [Coefficient assembly](Scripts/Coefficients/README.md) | Rational coefficients, endpoint functions and distributions |
| [Validation](Scripts/Validation/README.md), [tests](Tests/README.md) | Coverage and independent checks |
| [Package organization](FeynFacet/README.md) | Mathematical ownership and extension points |
| [Roadmap](Goals/README.md) | Remaining supported-scope and general-framework work |

Shared physics lives in `Projects/PROJECT/Common-Card.wl`. Each independent
contribution has `Raw/ORDER/CHANNEL/CONTRIBUTION/{Card.wl, Results.wl, Work/}`.
An explicit `Results/ORDER/CHANNEL/Result_Card.wl` selects contributions;
the assembled coefficient is `Results.wl` alongside it. Counterterms calculate
their lower-order sources inside their own Work directory. General algorithms
belong in `FeynFacet` and launchers in `Scripts`.

The finite DE representation stores actual epsilon coefficients and closed
definitions. Full epsilon-form canonicalization and GPL conversion are optional.
Physical boundary data, branch/domain conditions and final factorization
coverage are explicit requirements.

Supported channels use `Scripts/run_project_result.wls`. Result cards select
independent raw contributions; current completion and regeneration status is
recorded in `STATUS.md`. A declared card does not establish that all required
integration geometries are implemented or that its result has been calculated.
The ppHX double-real contribution is scoped separately from a complete NNLO
hard function. EEC at order alpha_s is conventional LO; conventional NLO needs
order alpha_s squared and is the current development campaign.

Dated user-facing reports are indexed in [Reports](Reports/README.md).

Retired code is under `Archive/RetiredCode` and is never loaded. Superseded status
and correspondence are under `Archive/History`. Local vendor installations,
ignored results and Wolfram licences are not supplied by a Git clone.
