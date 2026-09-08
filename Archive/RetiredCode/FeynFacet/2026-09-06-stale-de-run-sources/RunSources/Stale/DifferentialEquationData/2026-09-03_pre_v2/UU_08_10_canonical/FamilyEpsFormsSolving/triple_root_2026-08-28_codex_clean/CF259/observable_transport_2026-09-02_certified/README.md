# CF259 observable transport on the CERTIFIED compact record (2026-09-02 16:54-16:59)

Result: `observable_transport_CF259.wl` (9,263,077 bytes, SHA-256
fe0c6f5926e9dcaa6c9bf5e4346207abb281e16f7f4edda496fc18af97cd6060) -- status
ModularlyVerifiedObservableTransport, accepted by AcceptedObservableTransportQ
(the round-4 predicate, which requires the bound epsilon-valuation certificate);
20 demanded (order,row) pairs, 167 boundary coordinates, maximum weight 5,
OperatorAutomaton representation. Transport 270.4 s on one kernel (Series
Laurent route, orders -3..2, row caps, no SeriesCoefficient fallback).

Certificate carried: TransportEpsilonValuationSource FamilyRecord,
TransportEpsilonValuationCertificate status RationalPointEpsilonValuationCertificate,
Tight True (TMin -3, 27 block bounds observed at three rational points),
FingerprintVerified True, Certificates["TransportEpsilonValuationsBound"] True.

Inputs: `../transport_inputs_2026-09-02/family_epsform_CF259_compact_valuations.wl`
certified in place at 14:28 (original kept beside it as
`*.before_certificate_2026-09-02.wl`), `DifferentialEquations/nnlo_de_CF259.wl`,
`MasterCoefficientValuations.wl`, card `transport_card.wl` (the 05:51 path:
base (14/45, 11/90), target sample 13/45). Driver
`Scripts/family_observable_transport.wls` with FACET_CHECK_LEVEL=Production,
FACET_KERNEL_COUNT=1, through the two-seat launcher (900 s cap); log
`transport_run.log`.

Comparison with the 05:51 artifact (`../observable_transport_2026-09-02/`,
564 s, uncertified valuations): every deterministic part SameQ -- demanded
map, constraint matrix, boundary slots/kernel/embedding, closure rank
histories, kernels, operator automaton (all ten sub-keys), same set of
probabilistic-certificate keys. The 05:51 artifact answers False under the
current predicate (it predates the certificate fields); this one replaces
it as the accepted CF259 transport.
