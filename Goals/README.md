# Current roadmap

The deliverable is general, card-driven perturbative-calculation code.
[WORKFLOW.md](../WORKFLOW.md) specifies how a new agent runs it;
[STATUS.md](../STATUS.md) identifies accepted output and current limits.

## Completed local milestones

- Complete saved electromagnetic SIDIS NNLO results for 13 UU and 13 LL
  channels, with independent reference comparisons:
  [UU](../Projects/SIDIS_UU_NNLO/NNLO/README.md),
  [LL](../Projects/SIDIS_LL_NNLO/NNLO/README.md).
- Regenerated ppHX UU two-gluon double-real contribution with ghost
  subtraction, explicit higher endpoint distributions, zero unknown constants
  and accepted algebra/numerical checks:
  [channel workflow](../Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/README.md).
- Automatic sufficient-order/partition planning for supported physical endpoint
  frames. The two expensive coefficient expansions now take 10.5 minutes
  with eight cores, including input checks.
- Supported complete NLO workflows, shared result formats, Born dependencies,
  quark/gluon collinear correlators and PDF/FF scheme declarations.

## Remaining work depends on the requested process

For a complete ppHX NNLO hard function, include the remaining real/virtual
cuts, UV and PDF/FF counterterms; establish the required domain/continuation and
validate the assembled finite observable. The accepted double-real contribution
alone does not establish this.

General fresh-NNLO orchestration still requires explicit supported integral,
DE and physical-boundary/endpoint specifications. Further automation must
construct and bind these inputs through general algorithms, without hardcoded
family choices or imported reference hard coefficients.

Keep boundary-only and complete-master validation separate. Missing independent
boundary references remain missing even when the complete-master comparison
passes. Use inexpensive exact rational/modular or numerical checks where
appropriate; verification must remain proportionate to the computation.

This roadmap is not an instruction to start an unattended campaign. Follow the
current user request. [Earlier objectives](../Archive/History/Goals/README.md)
and [superseded status](../Archive/History/Status/BeforeWorkflowGuide_2026-09-11.md)
are historical.
