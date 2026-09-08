# CF303 physical coefficients, p-path six-mode layer (agent T, 2026-09-03)

Produced by `scratchpad/round4/T/round9/cf303_stage_a.wls` through `Scripts/seat_run.sh` (900 s cap; total 0.34 s after package load). Inputs: the accepted `Scripts/Transport/CF303/Artifacts/CF303SixModeEndpointFrame.wl` `ProductionInput` (four source modes on letters {0, 1-2p^2}, two target zero modes on {0, 1, -1}, six rational-in-(eps,p) incoming entries, path p: 4/11 -> pFinal), Codex's accepted T25 target gauge (`AcceptedTargetGauge["Matrix"]`, polynomial in eps of degree 2, evaluated at p = pFinal).

## Reading the table (round 9b, R3's F5)

- The rows at eps orders -4..-1 ("0 paper terms") are a statement of the accepted frame's CONVENTION, not a physical result: the six-mode frame is eps-normalized so that every period enters at eps order 0 (`BoundarySelectors -> <|0 -> ...|>`) and its layer window starts at 0. Codex's physical masters have valuation -4; those orders live in the periods' own eps expansions and in the junction/z-path composition (Stage B), which are Stage-3 data not materialized here.
- The "cross-check" is a second run of the SAME code with an independent prime schedule (seed 90031, prime sets disjoint) plus the four-argument predicate's re-verification at a new prime: it certifies the modular reconstruction's consistency, not the correctness of the frame's construction. No independent number for rows 44/45 exists in Codex's tree to compare against (R3 looked; so did T).
- The T25-gauged coefficient exists for 11 of the 14 demanded pairs. It is typed `RationalLayerDemandOutsideAcceptedPairs` at (-4, 44), (-4, 45) and (-3, 45): the gauge is polynomial of degree 2 in eps, so the gauged order n needs the frame coefficients at n-1 and n-2, which lie below the demanded window -4 (row 44's row of T25 has no eps^2 term, so at -3 it needs only the frame orders -3 and -4 and composes; row 45's row has one, so it needs -5 and is refused).

## What is materialized (Stage A)

- `BuildRationalEpsilonLayerTransport` on the demand {-4..2} x {rows 44, 45} with `WordRepresentation -> LazyOperator`: accepted, window {0, 2}; a second run with an independent prime schedule (seed 90031, prime sets disjoint) gives SameQ `KResidues` and `GaugeAtEndpoint`; both four-argument predicates (re-verification at a new prime) True. `BuildRationalEpsilonLayerOperator`: accepted.
- A formal six-coordinate boundary in the frame's `BoundaryCoordinateOrder` (each period enters at eps order 0, as the accepted frame's selectors declare) attached with `AttachTransportBoundaryToRationalLayer` (selectors equal the production input's).
- `BuildPhysicalTransportCoefficient` for every demanded pair, in the frame's F25 coordinates and with the T25 output gauge (`OutputGaugeByOrder`, orders 0..2). Orders -4..-1 are exactly zero in this eps-normalized frame (its window starts at 0); the T25 gauge at order n needs the frame coefficients at n-1 and n-2, so the gauged coefficient is typed `RationalLayerDemandOutsideAcceptedPairs` where those orders lie below the demanded window.

| eps order | physical row | frame status | paper terms | active periods (frame F25 coordinates) | gauged (I25 = T25.F25) status | active periods after T25 |
|---|---|---|---|---|---|---|
| -4 | 44 | PhysicalTransportCoefficientBuilt | 0 (frame convention) | (none) | RationalLayerDemandOutsideAcceptedPairs | None |
| -4 | 45 | PhysicalTransportCoefficientBuilt | 0 (frame convention) | (none) | RationalLayerDemandOutsideAcceptedPairs | None |
| -3 | 44 | PhysicalTransportCoefficientBuilt | 0 (frame convention) | (none) | PhysicalTransportCoefficientBuilt | (none) |
| -3 | 45 | PhysicalTransportCoefficientBuilt | 0 (frame convention) | (none) | RationalLayerDemandOutsideAcceptedPairs | None |
| -2 | 44 | PhysicalTransportCoefficientBuilt | 0 (frame convention) | (none) | PhysicalTransportCoefficientBuilt | (none) |
| -2 | 45 | PhysicalTransportCoefficientBuilt | 0 (frame convention) | (none) | PhysicalTransportCoefficientBuilt | (none) |
| -1 | 44 | PhysicalTransportCoefficientBuilt | 0 (frame convention) | (none) | PhysicalTransportCoefficientBuilt | (none) |
| -1 | 45 | PhysicalTransportCoefficientBuilt | 0 (frame convention) | (none) | PhysicalTransportCoefficientBuilt | (none) |
| 0 | 44 | PhysicalTransportCoefficientBuilt | 1 | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode1 | PhysicalTransportCoefficientBuilt | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode1, IndependentTargetMode2 |
| 0 | 45 | PhysicalTransportCoefficientBuilt | 1 | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode2 | PhysicalTransportCoefficientBuilt | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode1, IndependentTargetMode2 |
| 1 | 44 | PhysicalTransportCoefficientBuilt | 7 | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode1, IndependentTargetMode2 | PhysicalTransportCoefficientBuilt | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode1, IndependentTargetMode2 |
| 1 | 45 | PhysicalTransportCoefficientBuilt | 7 | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode1, IndependentTargetMode2 | PhysicalTransportCoefficientBuilt | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode1, IndependentTargetMode2 |
| 2 | 44 | PhysicalTransportCoefficientBuilt | 26 | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode1, IndependentTargetMode2 | PhysicalTransportCoefficientBuilt | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode1, IndependentTargetMode2 |
| 2 | 45 | PhysicalTransportCoefficientBuilt | 26 | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode1, IndependentTargetMode2 | PhysicalTransportCoefficientBuilt | Block23Zero, Block24Mode1, Block24Mode2, IndependentTargetMode1, IndependentTargetMode2 |

Files: `cf303_p_layer_physical_coefficients.wl` (transport, second-seed certificate, cross-check, operator, boundary, gauge by order, every coefficient record with its paper-facing `Expression`; SHA-256 735b922e6a730ffb...), `cf303_stage3_evaluation_list.wl` (the list above with the expressions dropped; SHA-256 1a8335c477331e4f...).

The order-0 coefficient of row 44 in the frame is, for example, `(-8 - 6 pFinal + 847/4 pFinal^3)/pFinal^3 P[Block23Zero] + (...) P[Block24Mode1] + (...) P[Block24Mode2] + P[IndependentTargetMode1]`; from order 1 on the words are explicit `TransportIteratedIntegral` GPL words on {0, 1, -1} and the marked points of 1-2p^2 along p from 4/11 to pFinal.

## What is NOT materialized (Stage B, typed)

The demanded coefficients of rows 44/45 in the canonical normalization at the physical soft point are the composition Z_q . J_r . P_s (accepted z-path operator, regularized soft junction, p-path layer; `CF303_SIX_MODE_ENDPOINT_FRAME.md`). P_s is above. J_r is Codex's in-flight work: `CF303JunctionRebase.wl` expects an order-keyed `SourceModeMap` deck, while the checkpointed `Artifacts/CF303TangentialJunctionMap.wl` stores a single rational-eps 43 x 13 `SourceModeMapRationalEpsilon` (reconstructed at ONE prime, one held-out point, no fresh-prime certificate); `CF303RebaseLazyAdapterAtJunction[adapter, junction, {-4, 2}]` on the accepted adapter returns `CF303JunctionModeDeckInvalid` (`scratchpad/round4/T/round9/probe_cf303_junction.log`). Until the junction deck is produced and certified at fresh primes, the Stage-3 evaluation list for the canonical rows 44/45 is: the six frame periods above (plus the seven inherited soft modes of the junction map's `CombinedModeOrder`) enter through J and Z with coefficients not yet materialized.
