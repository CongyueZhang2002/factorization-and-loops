# CF303 inherited observable extensions

## Result

The five lower-family observable coefficients required by the CF303 soft
source projection are now derived from the accepted exact gauge and existing
lazy/materialized observable transports.  No whole-family transport was
rerun.

| lower family | requested physical row/order | canonical demand row | result |
|---|---:|---:|---|
| CF12 | row 4 at eps^2 | `{2,6}` | exact demand overlay; physical class-5 soft mode still typed incomplete |
| CF199 | row 1 at eps^2 | `{2,8}` | exact overlay and formal endpoint PID-9 words |
| CF199 | row 2 at eps^3 | `{3,9}` | exact overlay and formal endpoint PID-9 words |
| CF53 | row 4 at eps^2 | `{2,11}` | exact overlay and formal endpoint PID-9 words |
| CF53 | row 5 at eps^3 | `{3,12}` | exact overlay and formal endpoint PID-9 words |

The generated artifact is
`Artifacts/CF303InheritedObservableExtensions.wl`.  It contains only the five
sparse demand overlays, demanded endpoint word maps, and pruned Stage-3 needs;
it does not duplicate a full family automaton or connection.

## Algorithmic change

`PhysicalBoundaryCampaignAdapter.wl` now works backward from the actual
requested observable rows and epsilon window:

1. Retrieve each requested observable word through a shared provider.  Both
   `OperatorAutomaton` and accepted `MaterializedWords` transports are
   supported; a materialized family is not regenerated as a lazy operator.
2. Use `BoundaryBaseEmbedding` for the endpoint ambient-slot lift.  This fixes
   the MovingKernel mismatch where `FinalBoundaryEmbedding` is only the later
   square boundary-coordinate map.
3. Form exact demand duals on the pivot slots and propagate their co-reachable
   row spaces backward through the two path alphabets.
4. Propagate only reachable endpoint-mode states.  Mode epsilon coefficients
   are extracted once before traversal, and each state is projected into the
   demanded output before map materialization.
5. Store only explicitly prepared observable words.  Asking composition for
   any other word returns `EndpointDemandWordNotPrepared`; there is no broad
   production fallback.

This is exact linear algebra over the coefficient field.  The pruning removes
a word state only when every demanded dual annihilates it, so it does not use a
numeric tolerance or probabilistic support guess.

## Timings

All final timings below came from one no-helper mission in the already-running
kernel pool.  Package preload is therefore excluded.

| case | earlier behavior | final adapter | words visited / retained | composition |
|---|---|---:|---:|---:|
| CF199 | broad closure: 2,755 words, 24--28 s; first demand-pruned version: 11.32 s | **0.173 s** | 1,516 / 1,516 | 0.015 s |
| CF53 | broad closure exceeded 500,000 words after 190 s; first demand-pruned materializer was stopped after 180 s | **4.278 s** | 24,282 / 24,282 | 0.210 s |
| CF299 historical control | -- | **0.195 s** | 144 / 63 | 0.002 s |
| CF407 historical control | -- | **0.041 s** | 5 / 4 | 0.0002 s |
| CF123 materialized-word control | unsupported before this change | **0.004 s** | known-zero provider control | -- |

The complete five-row artifact build took 6.91 s and the generic regression
batch took 1.00 s.  CF53 pruned 24,335 child branches; CF199 pruned 557.

The mission ran on a reused pool subkernel.  Its process lifetime high-water
RSS was 1,234,724 kB and post-mission RSS was 573,476 kB, but that high-water
mark already includes earlier missions on the same kernel and is therefore an
upper bound, not a CF53-attributable peak.  During the stopped pre-cache CF53
materializer the observed RSS was roughly 407--476 MB.  No separate main or
subkernel was launched for these controls.

## Correctness controls

- Every previously stored initial-demand row replayed exactly from `TTotal`:
  CF12 30/30, CF199 15/15, CF53 31/31.
- CF299's endpoint residue and regular endpoint series still match the
  historical control.  Its known quotient-frame mismatch remains explicitly
  aggregate-only.
- CF407 matches the historical endpoint residue, regular series, zero word,
  and both one-letter path forms exactly.
- CF123 directly consumed `TwoSegmentWordMaps` through the materialized-word
  provider in 0.004 s.
- CF199 exercises the corrected MovingKernel shapes:
  `BoundaryBaseEmbedding` is 72x48 while the automaton final embedding is
  48x48.  CF53 is the aligned AmbientBasePoint control, 138x105 in both
  locations.
- The full CF53 residue-kernel completion of the class-44 zero mode is
  `{11->2,12->-3,13->-2/5}`.  The shorter two-coordinate vector is not used.
- Formal PID-9 coefficients remain realization-local under keys
  `{"CF199",9}` and `{"CF53",9}` and are labeled `Unevaluated`.

The final bounded pool regression was fully green: all generic assertions and
all CF303 assertions passed.  An earlier metadata assertion had incorrectly
expected CF53 itself to use MovingKernel; the artifact shows CF53 is
AmbientBasePoint.  The corrected control uses CF199 as the MovingKernel case
and CF53 as the aligned case.  The final control mission took 1.42 s.

## Remaining physical inputs

This artifact supplies physical `F_source` endpoint columns.  It deliberately
does not claim a paper-ready CF303 target result.  The remaining inputs are:

- a physical realization of the CF12 class-5 soft zero mode;
- evaluation or a justified realization transfer for the separate CF199 and
  CF53 PID-9 coefficient series;
- one composition with the regularized target junction
  `G25 = F25 - H F_source`.

The last operation must consume these source columns exactly once.  Raw
physical/canonical `F25` and regularized `G25` remain distinct to prevent
double counting of the inherited extension.
