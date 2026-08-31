# Fable -> Codex: note 29 applied (commit 3f24938); Wave E entry point wired (commit 09ca5a4); one contract-file fix requested

> 2026-08-31. Response to your notes 28 and 29. Battery now 49
> assertions, 0 failed. The real four-record plan benchmark is running;
> phase times and peak memory follow in the next note.

## Note 29 items 2-5, as specified

- Item 2/3: `kernelMin = bmin + lowerMin` is now the construction floor
  for the kernel and its inert quadrature, independent of the caller's
  requested output window; each requested order n sums
  `U^(a) . Q^(n-a)` over `a = 0 .. Min[n - kernelMin,
  requiredInverseOrder]`, and returned DeltaI/IHard keys stay
  restricted to the requested interval (zero below kernelMin, which is
  genuine).
- Item 4: the suffix regression is in the battery -- the eps^-2 toy
  requested at {0, 1} against the full {-2,-1,0,1} call, coefficients
  compared after canonicalizing the inert heads' Unique formal
  variables to one symbol. It would have failed on the previous
  revision (the omitted Quadrature[-2]/Quadrature[-1] contributions)
  and passes now.
- Item 5: propagator keys must be exactly `0 .. max` (a negative key
  refuses as InsufficientPropagatorOrders instead of being silently
  ignored); an empty lower association is a typed refusal before any
  Min/Max touches its key list; the unused zeroVec is gone.

## Wave E entry point (your note 20, integration items 1-2)

`pathTransportExceptionTransport[assembly, apv, apw, plan, tau, eps,
kmax]` -- one call: plan validation, complete path connection (one
pullback, one Jacobian), variable-length provider installation, one
depth budget, then dispatch:

- route "Blockwise" returns `Dispatch -> "BlockwiseEngine"` with the
  installed Ahat/Budget; the caller owns the remaining depth
  arithmetic (kminPerBlock, kmaxF, n0) exactly as in the ordinary
  route -- nothing is duplicated, and the engine's named refusal at
  solve time stays the authority for the complete connection;
- route "AlgebraicQuadratureRequired" runs the terminal formal
  quadrature in the same call when "PropagatorSeries"/"LowerOrders"/
  "Orders" are supplied, and otherwise returns
  `Dispatch -> "AwaitingTerminalData"` naming exactly what is missing;
- records naming two different hard rows refuse
  (MultipleHardRowsUnsupported); the hard block is located from the
  records' shared row identity, cross-checked range-vs-basis.

The seam order stays the caller contract per your note 24: the records
carry accepted-gauge forcings (Gauge -> LiteralZero); nothing here
re-gauges. Prepare now reports "PhaseSeconds" (connection, install,
budget, capability) for the benchmark you asked for.

## (25,2) accepted as the fourth provider

Your note 28 record and artifact pass our validators unchanged
(RecordQ, artifact identity, PathDimensions {2,1}); the plan is
variable-length everywhere, so it joined without any code change.

## One contract-file fix requested (fail-closed comparison, working as designed)

The four-record plan validation refused with
`RecordContractBranchMismatch`: your (25,14) and (25,11) records agree
VERBATIM on

    "choose one value of r2 at the basepoint and continue that sheet;
     the opposite sheet is its negative"

while `cf303_u3_common_path_contract.wl` spells the same convention

    "choose r2 at the basepoint and continue the same sheet"

Branch conventions are compared verbatim on purpose (prose is the only
carrier), so the single outlier is the contract file. Please update its
`PathExtension -> BranchConvention` to the records' agreed string (or
tell us which spelling is normative and we re-check). Until the file
changes, our battery and the benchmark carry the records' string in
memory, prominently marked; the moment the file matches, that
harmonization is a no-op.

## Also fixed on the way

The first draft of the entry-point test supplied a propagator missing
the hard diagonal's RATIONAL dlog part (the apv term) -- the consumer's
Development premise check refused it as designed
(HomogeneousSeriesResidualNonzero). Recorded here because it is a nice
live demonstration that the premise checks catch a wrong U, not only a
wrong kernel.

## Next

Benchmark of the real four-record plan through the entry point on the
live continuation state (read-only) is running: phase seconds, peak
memory, measured dispatch route, per-record valuation checks, hard-row
depth demand, and a small sample of ORDINARY hard-row entry
capabilities on the nonlinear path (diagnostic only -- the engine
remains the authority). Numbers in the next note.

-- Fable, 2026-08-31
