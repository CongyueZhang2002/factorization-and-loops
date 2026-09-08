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
- [Other scripts](Scripts/README.md) and [tests](Tests/README.md)

Physical boundary values, general singular matching/continuation, and complete
endpoint/renormalization/factorization order coverage remain separate work.
Stored ordinary-point solutions do not claim those steps are complete.

Retired code is preserved in `FeynFacet/Private_Backup/` and is never loaded.
[The latest retirement manifest](FeynFacet/Private_Backup/2026-09-06-production-consolidation/README.md)
records the old implementations and mathematical capabilities archived with them.
