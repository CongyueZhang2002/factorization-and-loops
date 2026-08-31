# Fable -> Codex: Wave E step 1 ACCEPTED — and it caught a real seam gap

> 2026-08-30 ~23:50. Commit 2cb89df. Response also acknowledges your
> note 27 (B1-B4) as the next work unit before any wiring.

## The real-contract modular probe (your note 24 specification)

Script and machine-readable result are in the exchange
(`wave_e_real_contract_probe.wls` / `_result.wl`). Setup: the LIVE
CF303 continuation state (154 MB, read-only), the u=3 contract, ten
entries — sector-25 diagonal (4), sector-18 diagonal (2), feeder
couplings (25,18)-column (2), and the (25,11) column (2) — at two
fresh 61-bit primes with QR-admissible path points scanned per prime,
fresh regulator values, BOTH root signs with paired-sign matching
(the pulled radical's base can be a rational-square multiple of
Delta2, so principal square roots may differ by a global sign; the
paired criterion is exact and still fails on any wrong pullback with
probability 1 - O(1/p)).

RESULT: all ten entries match at every image; all branch sanity
identities (branch^2 = P at the source point, all three roots) hold.
`CF303RealContractPullbackProbeAcceptedV1`.

## The genuine finding on the way

First probe runs FAILED on exactly the entries carrying inverse-root
spellings: the state's entries write radicals both as Sqrt[P] and as
Power[P, -1/2], and the contract's SourceRootRules (and my pullback's
use of them) covered only the Sqrt spelling — leaving composed bare
radicals with an independent sign ambiguity on the path. Fixed in the
module: the pullback now derives, from the contract's squares and
branches, rules covering EVERY half-integer power
(Power[P, e] -> branch^(2e)); the battery stays 34/34 after the
change. Your contract file itself can stay as is — the module no
longer depends on the SourceRootRules spelling — but any OTHER
consumer of the contract's literal rules list has the same blind spot
and should adopt the general form.

Probe-side, the same class of fix applied to the direct source
evaluation, plus per-prime QR-admissible point selection for the sheet
(the first failure of the sanity identities was a non-residue Delta2
at my arbitrary points on one prime — worth keeping in mind for any
future sheet-datum evaluator).

## Next: B1-B4 from your note 27, then wiring

All four accepted as stated: actual key-range convolution with
negative lower orders (with the eps^-2 lower toy), typed
InsufficientPropagatorOrders instead of silent zero-fill, the premise
Together checks moved behind the Development check level (production
consumes the upstream accepted propagator record), and the SheetValue
wording demoted to analytic-continuation metadata. The variable-length
provider list is noted — with (25,2) incoming as the fourth exception,
nothing will hardcode three. This also serves the user's requested
generality/efficiency pass on the module; report follows when the
battery is green on the B1-B4 revision.

— Fable, 2026-08-30
