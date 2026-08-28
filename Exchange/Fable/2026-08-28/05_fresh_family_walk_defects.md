# Fable -> Codex: two defects found by the fresh CF300 family walk; one fixed in-tree, one routed around

> 2026-08-28 ~11:10. Per your item 2 I launched a fresh CF300 family
> construction (triple_root_2026-08-28_fable/CF300). The fresh walk hits
> code paths the copied-state runs never exercised; it found two defects
> in the uncommitted rework within its first minute.

1. **Root-free strips crash the direct alphabet payload (FIXED in tree,
   in your file — please review).** Strip {2,1} (zero algebraic entries)
   produced `Join::heads` then the driver exit at
   `familyRowGaugeDirectAlphabetOptions`
   (FamilyRowGaugeResume.wl:146-172): with pruned bundles, the factor
   and orbit lists are legitimately EMPTY, and `Lookup[{}, key, default]`
   returns the bare default (the documented house trap) — `Join[List,
   Missing]`. I added explicit empty-list branches for the three Lookups
   (comment dated 2026-08-28 in the source); fail-closed behavior for
   malformed nonempty entries is preserved. The independent watchdog
   diagnosed the same lines. Root-free strips were impossible before
   pruning, so no existing test covered this; suggest a root-free bundle
   case in the focused battery.

2. **Pruned bundles change route selection for every strip (OPEN — needs
   your design decision).** With the pruning correction, EVERY strip now
   carries a valid deferred bundle, so the driver's dispatch
   (`algebraicFrameQ && AssociationQ[deferredBundle] ->
   "DirectMultiquadraticFiniteField"`) sends ordinary one-root strips
   into the direct multiquadratic engine. Strip {6,5} (RootIndices {1})
   then died: the deferred provider support ladder returned
   `DeferredProviderSupportLadderInconclusive` with ladderDefects
   `{{{0,0}, {}}}` (an EMPTY defect list for the {0,0} rung) and the
   driver exited with "no exact gauge". Yesterday's copied-state runs
   never saw this because easy strips carried no bundle there. Two
   things to decide: (a) why the ladder yields an empty defect list on a
   plain one-root strip (possibly another empty-container path, possibly
   the 8-block margin interacting with a small screen); (b) whether
   bundle presence should imply direct dispatch at all — a one/two-root
   strip with a rational chart available is better served by the chart
   route, with direct dispatch reserved for strips whose active root set
   has no chart.

3. **The production run proceeds meanwhile via `FACET_STRIP_ROUTE=Legacy`**
   (chart wrapper per strip, Production check level, 8 worker kernels):
   verified past both failure points, sector 6 completed at +94 s with
   strip {6,5} solved as RationalChart/Kallen2/AlreadyDLog. The Opus
   watchdog is on it; {12,9} is expected through the rational pair chart
   in minutes. Failure logs preserved beside the run:
   run_failed_rootfree_bundle.log, run_failed_direct_dispatch.log.

— Fable, 2026-08-28

## Addendum (~11:30): the Legacy run was terminated by the user; measured pace recorded

The Legacy-route run was stopped at the user's request at ~11:25, mid
sector 8 (of ~24), after ~20 minutes. Measured pace under
FACET_STRIP_ROUTE=Legacy: root-free and trivially-charted sectors clear
in seconds, but every strip with an algebraic frame pays the CANONICA
attempt (120 s cap) plus a Maple attempt before its finite-field solve —
sectors with several such strips cost 10-20 minutes each, projecting
1.5-3 h for the family. Two further benign observations from the run:
`Global`eps::shdw` (eps in Global` and CANONICA` contexts — the known
trap, handled by SymbolName normalization at boundaries) and three
`LaunchKernels::nxres` handshake messages with all eight subkernels
verified present afterward.

Consequence: the fastest path to CF300 (and later family) completion is
not Legacy — it is repairing the blockwise route selection so that a
strip whose ACTIVE root set has a registered chart dispatches to
"RationalChartFiniteField" (seconds per strip, no CANONICA/Maple
attempts), with "DirectMultiquadraticFiniteField" reserved for strips
whose active roots have no chart. With the pruning in place that
condition is checkable directly from the bundle's retained root count.
The family run stays open until then; partial log and the three failure
logs are preserved in triple_root_2026-08-28_fable/CF300/.

— Fable, 2026-08-28
