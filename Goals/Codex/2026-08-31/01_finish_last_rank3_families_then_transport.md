# Finish the last rank-three families, then take over transport

## Native finite-field route

- [x] 🟢 Evaluate the preserved deferred forcing directly modulo word primes, without Maple or symbolic materialization.
- [x] 🟢 Propagate exact `x,y` derivatives through the native radical DAG so the residue-only integrability test can inspect the real forcing.
- [x] 🟢 Replace the conservative common denominator by a modular pole census and a compact support for the actual forcing.
- [x] 🟢 Keep the existing supplied divisor alphabet without generating the pathological all-pairs closure over every raw divisor.

## CF259 `(27,1)`

- [x] 🟢 Replace the undersized one-point support by the global shell-3 support: 4,628 unknowns, rank 4,588, nullity 40.
- [x] 🟢 Reconstruct one coherent rational-in-epsilon gauge over six 61-bit primes and validate it at a seventh prime plus a fresh provider point.
- [x] 🟢 Install the accepted final block; the contiguous `26..1` checkpoint has `PrevD {2,45}` and is transport-ready.

## CF303 `(25,1)`

- [x] 🟢 Diagnose the current 32-letter basis mathematically: residue-only curl ranks are `36` and `37`, so the alphabet is incomplete independently of the gauge denominator.
- [x] 🟢 Test the bounded 49-letter algebraic completion at two independent provider images; both have coefficient rank 40 and augmented rank 41.
- [x] 🟢 Certify `(25,1)` as an integral-form transport exception and install the completed `24..1` row with exceptions `{18,14,11,2,1}`.
- [ ] 🟡 Test whether the older exceptions `{18,14,11}` genuinely lack an epsilon form before retaining them permanently.  Block 14 now has a confirmed two-image-plus-fresh alphabet-integrability obstruction, and block 2 already has an accepted exact path provider; blocks 18 and 11 remain.

## Transport handoff

- [x] 🟢 Tell Fable to stop transport development and transfer the accepted work/evidence (Exchange note 18).
- [x] 🟢 Extract the complete accepted CF303 order table from the final gauged row without symbolic `Together`: 130 finite edges in 31.94 s, with two independent split points agreeing.
- [x] 🟢 Implement the family-neutral FLINT selected-sheet path-jet backend for rank 0–3 multiquadratic connections, 61-bit primes, and up to eight threads.
- [x] 🟢 Connect native coefficient jets to one formal block-DAG recurrence with the true `ord(TInverse_i)` constant floors and exact propagated depth windows.
- [x] 🟢 Evaluate all 145 CF303 block/order nodes through path order 8: 0.80 s after the coefficient cache is present.
- [x] 🟢 Perform the production-style fresh-prime acceptance: 2,160 differential-equation coefficients and 270 basepoint coefficients vanish/agree exactly modulo `2305843009213641971`.
- [x] 🟢 Package the accepted path contract, provider descriptor, order table, boundary windows, and formal recurrence as a stable serializable artifact; its disk round trip reopens and passes the same modular recurrence acceptance.
- [x] 🟢 Add the family-level driver that rebuilds the accepted source connection from the artifact, generates the native coefficient cache, evaluates the full recurrence, and performs its one direct modular acceptance.
- [x] 🟢 Expose `TransportPathArtifactRun[artifact,p]` for arbitrary two-variable package families and accepted paths, with both direct-state and completed-row source descriptors; finite origin jets remain explicitly distinct from endpoint values.

## Paper-level GPL and elliptic transport

- [x] 🟢 Classify CF303 by function class with an explicit residual-sheet flip: blocks 15, 17, 21, and 25 carry the remaining algebraic sheet, while the maximal downward-closed rational GPL subsystem is 21 blocks (37 masters).  The 48 changed entries in blocks 15 and 17 have mixed even/odd parts, and their odd parts divided by the residual root are sheet-even.
- [x] 🟢 Reject naive direct symbolic path compilation by measurement: 366 active entries, 356 unique entry pairs, and no completion after 600 s with six subkernels, versus about 405 s for the corrected two-dimensional baseline.
- [x] 🟢 Reject parallel symbolic path materialization after a bounded 14-block test: assembly finished in 49--51 s, but the path stage still had not returned after 152 s and occupied about 19.5 GB across the main plus six subkernels.  The attempted worker queue was removed rather than retained as complexity without gain.
- [x] 🟢 Replace symbolic-constant word recursion by a compiled sparse IR: shared letter IDs, interned word cons cells, sparse boundary columns, edge-local epsilon support bounds, and a modular recurrence certificate.
- [x] 🟢 Move identity-gauge physical valuation before GPL materialization. On the real ten-block CF303 anchor, the 20.3 s symbolic rule substitution becomes effectively zero and total transport time falls from 31.53 s to 13.34 s.
- [x] 🟢 Recover one-dimensional dlog residue matrices for the corrected 21-block subsystem with the existing 61-bit FLINT deferred evaluator, bypassing symbolic `Ahat`/`Together`: all 49,284 coordinates stabilized after nine 61-bit primes (549 CRT bits; maximum numerator/denominator sizes 230/203 bits) and pass at a fresh prime and different chart target.
- [x] 🟢 Verify that the accepted total basis transformation preserves the rational subsystem in the source basis: selected source rows receive zero entries from excluded canonical blocks; the reverse algebraic-from-rational direction has 57 entries, as required by triangular variation of constants.
- [x] 🟢 Factor the accepted rank-18 path alphabet exactly and emit a package-readable GPL provider: 14 active factors split into 21 GPL letters, 99 nonempty block couplings, and 2,495 nonzero residue coordinates; every factor identity passes at a fresh prime and target.
- [x] 🟢 Replace the proposed complete eager word table by its exact lazy Chen operator.  The 37-master operator builds in 0.010 s and stores the formula `R[a1]...R[ak] B[q] C G[a1,...,ak]`; an accidental full order-5 expansion is refused before enumerating its 1,891,142,505 candidate words.
- [x] 🟢 Apply the exact source-basis gauge and physical source-boundary embedding, prove the 37-master residue/gauge closure, and package the exact GPL solution through `eps^2` as a paper-facing ancillary.  All 111 row/order requests finish in 208.998 s with six subkernels; the compact artifact retains on-demand row tables instead of one 3.43-million-term textual sum.
- [x] 🟢 Remove symbolic gauge algebra from the GPL prefix tree by factoring each requested row as `L.C` and propagating only rational-constant residue products.  The previous census was unfinished after 1,800 s; the accepted route completes in 208.998 s (greater than 8.6x).
- [x] 🟢 Correct the generated Wolfram GPL endpoint from the invalid pattern-form `u_target` to the legal symbol `uTarget`; all 18 factor identities revalidate and the final 21-letter artifact contains zero `Pattern` objects.
- [ ] 🟡 Implement the quartic elliptic kernel alphabet and Hermite reduction beginning at block 15, propagate its extension through blocks 17 and 21, and feed the resulting mixed GPL/eMPL layers into block 25 without leaving unevaluated master integrals.  The complete finite/infinity Hermite reducer is green; one real `25 <- 15` depth-two feeder produces 35 finite words per target with exact zero differential residual, and its physical master-5 coefficient is accepted.  Remaining scope is the full block DAG `15 -> {17,21} -> 25` and final `E4/Z4` export of any second-kind words.
