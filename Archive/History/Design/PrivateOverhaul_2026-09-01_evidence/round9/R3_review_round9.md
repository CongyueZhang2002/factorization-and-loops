# R3: adversarial review of round 9 (T's physical transport, M's transport campaign)

HEAD `523cf961` (working tree clean apart from the plan document). Rules kept:
package read only, every kernel through the seat launcher under 300 s,
`TimeConstrained` on every probe, nothing committed. Evidence under
`scratchpad/round4/R1/r3/`: `t_physical_boundary.log`,
`t_observable_transport_certificate_residues.log`, `census_compare.wls/.log`,
`census_compare2.wls/.log`, `r3_eigenspace.wls` + `r3_eigenspace5.log` (the
earlier `r3_eigenspace{,2,3,4}.log` are my own script defects -- a relative
root, then a copied test header whose indented fragments swallowed the
`modeSpec` assignment -- and are superseded).

**Tests.** `Tests/Transport/t_physical_boundary.wls`: 29 assertions, 0 failed
(2.2 s after load). `Tests/Transport/t_observable_transport_certificate_residues.wls`
(the reconstruction unit test T names): 4 assertions, 0 failed (2.1 s).

**Fixture** (`r3_eigenspace.wls`, the test's 2x2 zero-residue control): (A) a
2-d eigenvalue-0 eigenspace whose two directions have different physical
orders under `{{1,1},{u,0}}` -- the admissible direction is NOT a `NullSpace`
basis vector: `BoundaryModeMapBuilt`, one mode, `CanonicalMode` proportional
to `{-1, 1}`, orders {1,1}, no degenerate entry; under `{{1,0},{u,u}}` mode
`{0, 1/eps}`. The valuation selects, basis-independently, as claimed. (C) the
`Basis` policy on that selected case does not split (one mode `mix`). (B)
policy values `"basis"`, `"Bases"`, `True`: refused as
`AmbiguousPhysicalEigenspace` with no mention of the policy (see F4).
(D) both sub-realizations supplied `Formal`: `GPLBoundaryConstantsIncomplete`
with two `Unevaluated` ledger entries `{deg,1}`, `{deg,2}` and no degenerate
marker on them; one supplied `ExactZero`, the other absent:
`GPLBoundaryConstantsIncomplete` (typed, the missing direction is demanded).
(R) the residue reconstruction on the unit test's connection with `eps`
replaced by `(2 + eps^2)/3` and by `eps + 5 eps (eps-1)(eps-2)`: see F1.

## Findings, ranked

### F1 (medium, certificate semantics): the residue reconstruction does not check eps-linearity; two non-linear connections pass with `EpsilonLinearityChecked -> True`

`ObservableTransportFiniteField.wl`: every design row and every fresh
validation point evaluates the connection at eps = 1 (`Append[point, 1]` in
`sampleAt`), and the linearity probe compares eps = 2 against 2 x (eps = 1) at
the first point of each prime only. Failing inputs (fixture R, the unit
test's four letters and residues): `(2 + eps^2)/3 Sum R_i dlog l_i` and
`(eps + 5 eps (eps-1)(eps-2)) Sum R_i dlog l_i` both return
`CertificateLetterResiduesReconstructed` with the residues R_i, 0 mismatches
and `EpsilonLinearityChecked -> True`; the second agrees with `eps` at eps
in {1, 2} exactly and is cubic. What the certificate proves: at the sampled
primes and points, A(x, y, 1) lies in the span of the letters' dlog forms
with constant rational coefficients, reconstructed and validated at a fresh
prime. Eps-linearity and constancy are NOT proved by it; they come from the
family certificate's exact `DLog` (`Valid`, `ConstantResidues -> True`), which
gates the route (`reconstructableCertificateDLogQ`). So no wrong acceptance
today, but the flags `EpsilonLinearityChecked -> True` and
`IdentityExactlyCertifiedOnLetters -> True` (`ObservableTransport.wl:3437-3440`)
overstate the reconstruction's own check and the predicate (`:3448-3479`)
reads them as flags. At a letter whose true residue is not constant, the
overdetermined fit (letterCount + 3 points x 2 variables) refuses
`ConnectionOutsideLetterSpan` generically; a residue that is constant on the
sampled points but not elsewhere would pass -- the exact family certificate
is again what excludes it. Fix: sample eps randomly per point (fit
A(x,y,eps)/eps), validate at random eps, and word the flags as "inherited
from the family certificate".

### F2 (medium, physics/bookkeeping): a "Basis" sub-realization records two formal coefficients where the census counts one period, and the endpoint record does not say so

For `{CF300,12}` the admissible eigenspace is 2-d at every edge point
(T's probes), the census gives ONE period for class 62, and T's own report
says the second coefficient is fixed only by a relation along the stratum.
The `Basis` policy therefore turns one undetermined direction into two
independent formal periods `{CF300,12,1}`, `{CF300,12,2}`: a bookkeeping
device, honestly declared in the mode map (`DegenerateEigenspaces`,
`EigenspaceDimension`, `ParentPeriodID` on the mode records,
`PhysicalBoundary.wl:585-595`), but the installed endpoint record
`PhysicalEndpointTransport/physical_endpoint_transport_CF300.wl` carries no
`DegenerateEigenspace*` key at all (grep): its 57 `Unevaluated` Stage-3
coordinates list `{CF300,12,1}` (25 occurrences) and `{CF300,12,2}` (40) as if
they were two independent periods, and `BuildTransportBoundaryVector`'s ledger
entries (fixture D) carry `PeriodID` and `Status` only. A Stage-3 consumer
would evaluate two transcendental numbers where one plus a rational relation
exists, and nothing machine-readable says which pairs are tied. "7 exact
modes from 6 periods" and `PhysicalBoundaryModeCampaignAcceptedV1` read as
completeness; the mode map is complete modulo one undetermined ratio per
degenerate eigenspace. Fix: carry `ParentPeriodID`/`EigenspaceDimension` into
the boundary-vector ledger and the endpoint record, and count a degenerate
eigenspace once in any period tally.

### F3 (medium, report accuracy): "refused only for lacking the certificate" is content-equivalent where checked, not SameQ

`census_compare.log`, `census_compare2.log`: CF262 -- every deterministic key
SameQ between the 2026-09-01 and the round-9 record apart from the renamed
path symbol (`observablePath37` vs `observablePath30`); the new record adds
only `FamilyInputRoute` and the three `TransportEpsilonValuation*` keys.
CF57 -- `FirstSegmentActiveLetters` {1..8} vs {1,2,3,6,7,8,9,10},
`FirstSegmentKernels`, `FirstSegmentKernelMatrices` and the automaton's
`FirstAlphabetIndices`/`First|SecondOperatorMatrices` differ; the kernel SETS
and the matrices after re-sorting are equal and `FirstSegmentWordMaps`,
`Demand`, `PhysicalDemand` are SameQ -- a letter relabelling. CF27 -- kernel
sets and re-sorted matrices equal, active letters {1,2,3} vs {1,2,5}, but
`FirstSegmentWordMaps` differ (index-keyed), so equivalence is not shown by
my check. The builders changed the first-segment alphabet indexing between
round 4 and round 9; M's sentence "the acceptance changed under the records,
not the records under the acceptance" holds for the transported content only
up to that relabelling, and is unverified for CF27. Fix: an index-invariant
comparison (the demanded map evaluated at one rational point, or the word
maps after the letter permutation) on a sample before the claim.

### F4 (low): an invalid `DegenerateEigenspacePolicy` value is indistinguishable from no policy

`PhysicalBoundary.wl:583-585`: `policy === "Basis"` or default. Fixture B:
`"basis"`, `"Bases"`, `True` all yield `AmbiguousPhysicalEigenspace` without
naming the policy. Typed and safe, but a typo silently disables the split.
Fix: refuse `DegenerateEigenspacePolicyInvalid` for any value outside
{"Refuse", "Basis"}.

### F5 (low-medium, CF303 stage A): no independent check, and the "-4..-1 zero" rows are a convention

T's cross-check is a second seed of the same code (SameQ residues and
endpoint gauge): reconstruction consistency, not correctness of the
construction; nothing in Codex's tree was compared (its
`Runtime/2026-09-03_physical_transport/pool/done/codex_cf303_endpoint_*`
missions are wrappers, and I found no earlier numbers for rows 44/45). The
README states that every period enters at eps order 0 by the frame's
selectors and that a period's own eps expansion is a Stage-3 datum; with
Codex's physical masters at valuation -4, the "0 paper terms" at orders
-4..-1 are therefore a frame statement, not a physical result -- the table
should say so on those rows. The T25-gauged coefficients are typed
`RationalLayerDemandOutsideAcceptedPairs` at (-4, 44), (-4, 45), (-3, 45):
"with and without the T25 gauge" holds for 11 of the 14 demanded pairs.
Stage B is a typed refusal (`CF303JunctionModeDeckInvalid`) on Codex's
one-prime junction checkpoint, correctly not materialized.

### F6 (low, terminology): M's `campaign.tsv` column `exact` marks records whose status is `ModularlyVerifiedObservableTransport`

M defines `exact` as "accepted after `AcceptedObservableTransportQ`"; the
records are probabilistic (modular). CLAUDE.md's reporting language asks for
the measured status; call the column `accepted`.

## Checks that held

Valuation selection is basis-independent and the `Basis` policy does not
split a uniquely selected eigenspace (fixture A, C); a missing direction of a
split eigenspace is demanded (D2); the two unit tests pass; CF262's round-9
record is SameQ with the 2026-09-01 one on every deterministic key; CF265's
acceptance path is a named predicate branch with a fresh prime outside the
CRT primes and the route is gated by the exact family certificate.

## Recommendations, in priority order

1. F1: random eps per sample and per validation point; flags worded as
   inherited; the two failing inputs as unit assertions.
2. F2: propagate the degenerate-eigenspace declaration to the boundary-vector
   ledger and the endpoint record; count the eigenspace once in period
   tallies; state in the CF300 summary that one ratio per degenerate
   eigenspace is Stage-3 work.
3. F3: index-invariant equivalence check on a sample of families before the
   "certificate-only" claim; record the alphabet-indexing change.
4. F4, F6: typed policy validation; rename the column.
5. F5: label the -4..-1 rows as convention; obtain one independent number
   (a modular replay at a different chart point or Codex's values) for one
   stage-A coefficient before Stage B.

## Verdict

Finished with the listed fixes: the degenerate-eigenspace completion is
typed and basis-independent and the residue reconstruction is a sound
number-recovery route under the exact family certificate, but the
reconstruction's certificate claims an eps-linearity check it does not
perform (F1), the Basis split's undetermined ratio is invisible downstream
(F2), and M's "certificate-only" refusal claim is a relabelling-equivalence,
not an identity, and unverified on one of three sampled families (F3).
