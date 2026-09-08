# FeynFacet

A Wolfram Language framework for NNLO hadronic cross sections using collinear
factorization, reverse unitarity, IBP reduction and master-integral differential
equations. Process definitions enter through cards and mathematical input data.

The general DE solver constructs explicit finite epsilon coefficients up to
kinematics-independent initial constants. It determines sufficient orders and
stores actual finite expressions. Full epsilon-form canonicalization is optional.
A standalone arbitrary-precision evaluator reads these expressions; compiled
FLINT evaluation, parallel batches and local Taylor expansions are available.

- [Current status](STATUS.md)
- [General production path and commands](Scripts/Transport/README.md)
- [Mathematical solution format](Design/FiniteMasterIntegralSolutions.md)
- [Order requests and examples](Examples/Transport/README.md)
- [Complete UU, LL and TT NLO example](ppHX_NLO_qqprime/README.md)
- [Other scripts](Scripts/README.md) and [tests](Tests/README.md)

Physical boundary values, general singular matching/continuation, and complete
endpoint/renormalization/factorization order coverage remain separate work.
Stored ordinary-point solutions do not claim those steps are complete.

Retired code is preserved in `Archive/RetiredCode/FeynFacet/` and is never loaded.
[The latest retirement manifest](Archive/RetiredCode/FeynFacet/2026-09-06-production-consolidation/README.md)
records the old implementations and mathematical capabilities archived with them.

## Repository layout

| Directory | Role |
|---|---|
| FeynFacet | General package and numerical backends |
| Scripts | Current drivers, operations and optional general methods |
| Examples | Small input examples for the general interfaces |
| Tests | Active mathematical tests, fixtures and independent references |
| process/Cards and Results | Process definitions and generated mathematical data |
| Codex | Pro consultation bridge state |
| Design | Current interfaces and methods; result links point into process folders |
| Goals | One current general NNLO roadmap |
| Archive/History | Superseded plans, correspondence and research records |
| Archive/RetiredCode/FeynFacet | Retired code, never loaded |

The former Exchange, Prototypes and Runtime directories are removed.
Persistent mathematical outputs, benchmarks and numerical references belong in
`<process>/Results/`; Kira workspaces belong in `<process>/Kira/`.
Temporary scratch is removed after the retained outputs have been saved there.
[The repository cleanup report](Design/RepositoryConsolidation_2026-09-06.md)
records retained material, removed output and verification.

The package now has separate symbolic, standalone solution and optional epsilon-form entry points. See the [package organization and extension guide](FeynFacet/README.md).
