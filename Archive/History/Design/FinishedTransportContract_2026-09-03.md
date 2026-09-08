# The one definition of a finished transport (user ruling, 2026-09-03 18:10)

User: "There should only be one definition of a finished transport. You cannot
call the previous lazy representation as transport finished, I cannot use it
to find the boundary conditions and enter stage 3."

## Definition

A family's transport is FINISHED when one self-describing record, status
`PhysicalTransportFinished`, gives for EVERY demanded (epsilon order n,
physical row r) of the depth ledger an explicit expression

    I_r^{(n)} = Sum_w c_w(P) . W_w

where

1. each `W_w` is an explicit iterated integral: its letters are explicit
   functions of the family's variables (the chart and any declared algebraic
   roots are part of the record), its base point is the PHYSICAL boundary
   point or stratum with the tangential prescription stated, its endpoint is
   the physical point; no operator automaton, no lazy word map, no package
   symbol, no placeholder other than the named periods below;
2. each coefficient `c_w(P)` is an explicit rational (or, in a declared
   algebraic field, algebraic) linear combination of a finite NAMED period
   basis `P = {P_1, ..., P_m}`; the record carries the period table: for
   each `P_j` its definition as a boundary datum of a specific cut integral
   (family, stratum, Frobenius mode, integer valuation, the ledger id), its
   status (Exact with value, KnownZero with proof reference, Transferred
   with the transfer id, Unevaluated), and the relations among periods that
   the transport itself implies (so that the unknowns entering Stage 3 are
   independent);
3. three certificates, re-verifiable by `PhysicalTransportFinishedQ`:
   (i) the differential equation: the explicit sum satisfies the family's
   connection at the demanded orders (checked exactly on small families,
   and by exact-rational evaluation at random points with fresh primes on
   large ones, both recorded with their points and primes);
   (ii) the boundary matching: the expansion at the physical endpoint
   reproduces the declared Frobenius modes with the period coefficients;
   (iii) the binding: fingerprints of the eps-form, the observable transport,
   the mode map and the demand the record was built from, and a purity
   check that the stored expressions contain only the documented public
   heads, the family's variables and the period names.

`PhysicalTransportFinishedQ[record]` answers True only under 1-3 for every
demanded pair; anything missing is a typed status naming the pair and the
reason (`PhysicalTransportIncomplete`).

## What the intermediates are

`BuildObservableTransport` (accepted by `AcceptedObservableTransportQ`),
`BuildBoundaryModeMap`, the graded endpoint transport of
`Scripts/Transport/PhysicalBoundary/` and the rational-epsilon-layer operator
are STAGES of the construction. Their accept predicates are stage gates, not
"finished"; prose, HANDOFF and campaign tables must say "stage accepted",
never "transported", for them. The deliverable Stage 3 consumes is the
finished record and only that.

## Consequence for the current artifacts (2026-09-03)

The 87 accepted observable transports and the 39+1 graded endpoint records
are inputs to the finisher; none of them is finished. The finisher
(`FinishPhysicalTransport[family]`) materializes every demanded pair through
the existing per-coefficient composer (`BuildPhysicalTransportCoefficient`,
`TransportIteratedIntegral`, `ExpandTransportWordLetters`) and adds the
period table, the relations and the three certificates.
