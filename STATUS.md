# Status, 2026-09-05

Rewritten at every change of state; the detailed goal ledger is under
`Goals/<agent>/<date>/STATUS.md`.

- Data: the V2 record schema is live. Pre-V2 results remain under
  `Stale/DifferentialEquationData/2026-09-03_pre_v2/`; regeneration uses the
  preserved Kira streams, family registry, master lists, hard-function
  coefficient valuations and cards. Historical canonicalization and
  path-solution timings are retained in
  `Design/PerformanceBaselines_2026-09-04.md`.
- Stage 1, epsilon forms: finite-field diagonal- and off-diagonal-block
  solvers are the production route; CANONICA and Maple are not production
  fallbacks. The V2 finite-field and square-root terminology migration is
  complete, and all 44 changed test files pass. CF269, CF48, CF265 and CF259
  differential systems were regenerated and exactly match their archived
  systems. CF48's family dlog epsilon form is validated. CF259's measured
  hard blocks are substantially faster, but its complete V2 multiquadratic
  family-level record remains unfinished.
- Stage 2, master-integral solutions: no family yet satisfies the V2
  completion condition. Completion means emitting the exact
  boundary-function epsilon coefficients and iterated integrals required by
  the hard function after solving every required path segment and
  boundary-stratum equation. CF303 has rational-sublayer and formal modular
  path intermediates, but its elliptic final block and positive-dimensional
  soft-boundary data are not a finished physical solution.
- Stage 3, boundary data: three structural boundary constants are proven zero
  (ids 1, 6 and 7); the remaining required constants or boundary functions
  are unevaluated.
- Stage 4, marked-point expansion and hard-function assembly: not started.
- Validation: production large-family validation uses bounded finite-field
  evaluation at independent points. Exact symbolic proof is a separate,
  explicitly requested mode. The repository-wide inventory retains two
  unrelated pre-existing failures: the ghost pre-IBP test and the test that
  requests archived pre-V2 class-form inputs.
- Coordination: the GPT Pro bridge now lives in `External/ChatGPT`; its
  tracked `gpt-6-pro` conversation state lives in the ignored
  `Codex/General/ChatGPT` runtime directory. Permanent exchanges and their
  supporting source packets are organized chronologically under
  `External/ChatGPT/Records/YYYY-MM-DD/NN_summary_name.md`, with the question
  and Pro response in the same numbered file. The bridge and
  state were moved from FACET into this workspace.
- Next work: finish the positive-dimensional boundary-function consumer and
  remaining package-facing terminology migration; complete CF303 in V2 form;
  close one representative at each square-root count; then launch all-family
  regeneration. No all-family V2 campaign is currently complete.
