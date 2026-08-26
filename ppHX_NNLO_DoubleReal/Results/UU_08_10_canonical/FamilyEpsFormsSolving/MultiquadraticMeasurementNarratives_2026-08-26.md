# Multiquadratic engine: dated family measurement narratives

Moved out of `FeynFacet/Private/` source comments on 2026-08-26, in the
round-2 review wave, executing Codex review §3.1 and ChatGPT Pro's
generality list:

> Private source comments contain extensive family-specific timing
> histories and current-campaign narratives. Move those to `Results/` or
> a design/measurement note and keep only invariant algorithm comments in
> loaded code.

Nothing here is deleted from the project record — it is moved. The
loaded source keeps the one-line invariant statement each measurement
supports, plus a pointer to this file. Every number below was measured
on this machine on the date given; none is an estimate unless it says so.

The reason the split matters: a comment that says *"the default is False
because it is faster on CF300 (12,9)"* is a fact about one block of one
family at one commit, and a reader of the algorithm cannot tell whether
it still holds. The invariant statement — *"pre-building the core pays
only where a core is reused"* — is what belongs beside the code.

---

## 1. `multiquadraticStripPrepare` "CompileCore": why the default is False

**Measured 2026-08-25, cold, on the real CF300 (12,9) descriptor**
(52-letter ansatz, 1808 unknowns, gauge support 100). Both routes reach
the same byte-identical preparation and the same assembly fingerprints.

| Route | prepare | compile | total |
|---|---:|---:|---:|
| `CompileCore -> False` | 2710.9 s | 91.3 s | 2802.2 s |
| `CompileCore -> True`  | 2810.7 s | 89.8 s | 2900.5 s |

Building the core early cost 99.8 s and gave back 1.5 s. The duplication
it was meant to remove is already gone: the compiler receives prepare's
sealed channels, and its whole core stage is 0.16 s of a 91.3 s compile,
of which 89.0 s is the one-form compilation. Pre-building E, C and every
BBar channel in prepare therefore buys nothing on this shape.

**Invariant statement kept in the source:** the option exists because a
core IS reused on a degree-offset ladder rung, on a second ansatz over
the same equation, and on a re-prepare; turning it on is a measured
decision per shape, not a default.

**Round-2 note.** This whole comparison is about the *cost of preparing
global exact channels*, which round-2 item 9 demotes from the primary
route to a per-entry artifact fallback. If the direct coefficient
providers replace it, both rows of this table become historical.

## 2. Prepare intermediate persistence: what the round-6 cancellation cost

**Measured 2026-08-25.** `multiquadraticStripPrepare` took 2710.9 s cold
on the same CF300 (12,9) descriptor and checkpointed nothing: a cancelled
or budget-stopped run discarded every completed substage and the next
attempt started from zero. That is what the round-6 cancellation cost.

The repair (landed in the hardening wave) writes one self-describing,
sealed record at each of the three substage boundaries the cooperative
deadline already names — `ForcingChannels`, `CandidateLetters`,
`GaugeDenominator`.

**Invariant statement kept in the source:** each expensive substage
boundary persists a sealed record and a resumed preparation may read it
back; a checkpoint is authenticated provenance, never a cache keyed by a
file name.

## 3. `CompileShards`: why it is a private test control and not production

**Measured 2026-08-25.** On CF300 (12,9) the entire one-form compilation
is 89 s, so serializing the payload to shard workers would dominate the
work being sharded. Sharding is therefore not demonstrated to pay on the
one real shape available.

What a production shard contract still needs (Codex 14:30, shard row;
agreed disposition): a strict per-shard result schema validated before
anything is interned; a helper-leak guarantee, so a helper that dies
cannot leave a claimed index uncompiled and unrecomputed; absolute
deadlines instead of a fixed 7200 s timeout; and a measured per-entry
stage cost showing that sharding pays at all.

**Invariant statement kept in the source:** `CompileShards` is a private
test control with no production caller and is absent from the public
option set by decision, so the shard path stays exercised by its tests
without being reachable from production.

## 4. The 807 s second decomposition

**Measured 2026-08-25 (post-mortem item 5).** Decomposing the forcing a
second time inside `multiquadraticStripCompile`, after prepare had
already decomposed it, was 807 s of the 4872 s compile of CF300 (12,9).
Prepare now hands the compiler its sealed channels.

## 5. Alphabet construction: the CF300 (12,9) post-mortem of 2026-08-24

Three measured facts drove the alphabet section as it now stands.

1. The engine's historical regulator sample list `{0, 1, -1, 2}` lands on
   poles of that block's forcing — its channel denominators carry `eps^3`
   and `1 + eps` — so **14 of 32 candidate dlogs were lost** before the
   solve ever ran. Sample values are now chosen: a generic pool is tested
   entry by entry and a value that makes any entry singular is
   re-sampled.
2. The block's integrability condition is inconsistent with any alphabet
   of rational letters, and is repaired by four algebraic letters
   `A ± Sqrt[delta]` whose norms `A^2 - delta` factor completely into the
   strip's rational alphabet: the norms are `-4y`, `-4xy`,
   `4y(1+x+y)` and `4x^2y^2`.
3. The letters of the row's already-installed blocks were not in the
   candidate basis at all, though the row's flatness identity couples
   them to this block.

**Invariant statements kept in the source:** regulator sample values are
chosen against the forcing's poles, never fixed; algebraic letters are
generated with a norm certificate rather than guessed; the row and column
alphabets are adjoined when the caller supplies them.

## 6. Screen costs against the compile they screen

**Measured 2026-08-25 on CF300 (12,9).** The full-gauge per-image screen
costs 43 s at 1816 unknowns and 98 s at 3128 unknowns, against a compile
of the same ansatz measured at ~7900 s. The degree-offset ladder costs
one screen per image per rung (50-90 s on that block).

That ratio — screens are two orders of magnitude below the compile they
gate — is the invariant reason the screens run first, and round-2 item 9
moves the gauge screen ahead of exact preparation for the same reason.

---

## Remaining inventory (declared, not yet moved)

The round-2 pass moved the narratives above out of
`MultiquadraticStripSolve.wl`. A comment-stripped scan on 2026-08-26
finds family-named comment lines still in these loaded files:

| File | lines mentioning a CF family |
|---|---:|
| `MasterTransport.wl` | 25 |
| `FiniteFieldStripSolve.wl` | 16 |
| `TransportCharts.wl` | 14 |
| `BlockEquationDeferred.wl` | 12 |
| `FamilyRegulatorFactor.wl` | 12 |
| `BlockwiseTransport.wl` | 5 |
| `EpsFormStripObstruction.wl` | 3 |
| `FamilyRowGaugeResume.wl` | 3 |
| `FamilyCertificateModular.wl`, `FamilyEpsForm.wl`, `FamilyRowGauge.wl`, `FiniteFieldEpsForm.wl` | 1 each |

Most of these are single-line measurement citations attached to a
default, not narratives; separating the two is a per-line judgement and
is left as a bounded follow-up rather than done mechanically. No
executable dispatch keyed to a family name exists in any of them — that
was checked independently by Codex and by Pro, and re-checked here.
