# CF259 observable transport (2026-09-02, overhaul branch)

Result: `observable_transport_CF259.wl` -- status
ModularlyVerifiedObservableTransport, accepted by
AcceptedObservableTransportQ; 20 demanded (order,row) pairs, 167 boundary
coordinates, maximum weight 5, word representation OperatorAutomaton
(lazy exact operator chain; demanded maps materialize on request through
ReconstructObservableTransportWordMaps with fresh modular acceptance).
Wall 564 s on one E-core kernel (probe 5, 05:41-05:51).

Inputs: `../transport_inputs_2026-09-02/family_epsform_CF259_compact_valuations.wl`
(Codex's compact transport-ready record + Codex's transport epsilon
valuations), `DifferentialEquations/nnlo_de_CF259.wl`,
`MasterCoefficientValuations.wl`, card `transport_card.wl` (path base
(14/45, 11/90), target sample 13/45 -- all three radicals rational and
nonzero at the base).

Code: branch `overhaul` at commit 4b36d32e (the adopted
lazy-operator transport of codex/day-rank3-validation plus the fix B8 of
Design/PrivateOverhaul_2026-09-01.md: the finite-field compiler accepts
declared root squares rescaled by a rational factor and numeric square
roots, which is what the constraint matrix carries once x is fixed at
the base point). Probes 1-4 failed at the rank-sampling step
(`SingularConstraintRankSample`); probe 4's named offenders and the dump
`probe4_constraint_rank_failure_dump.wl` (Sqrt[5], Sqrt[56 + 45 y^2],
Sqrt[961 +- 5310 y + 2025 y^2]) pinned the cause; logs of probes 1 and 4
are kept beside the result.

Acceptance level: modular (fresh-prime closures, coordinate and
ambient-invariance certificates recorded in the result), like the 86
ordinary families' results of 2026-09-01; the record's own dlog
residues were computed natively with 13 CRT primes and a fresh prime.
