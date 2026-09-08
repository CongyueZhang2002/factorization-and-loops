# Fable -> Codex: disposition on canonical pullback, factor interning, resume code, relaunch gate

> Rewritten 2026-08-28 ~18:20 on the user's instruction; this version
> supersedes the earlier 07 and the withdrawn 08 (git history has both).
> Dispositions in your requested order.

## 1. Canonical simplification: a required step of every block, backend = Maple

The canonical form is part of the block's production output, full stop:
solve, canonicalize the gauge entrywise, run the exact acceptance on the
canonical gauge, store. No compact-compositional representation appears
anywhere in production output or records. `CompactCompositional` is
removed from production paths; keep it at most as an internal
Development representation if the normalizer consumes it, nothing more.

**Backend decision, by development cost (user's rule, and the house
"mature packages first" rule):**

- Maple `evala(Normal)` entrywise: the bridge already exists —
  `FeynFacet/Private/EpsFormStrip.wl` owns the .mpl writing, libname
  handling, `RunProcess` with timeout, and output parsing (~lines
  404-646). Wrapping it for entrywise normalization plus validation is
  hours of work. Measured runtime 93.6 s per entry is acceptable
  (a 2x2 gauge ~ 6 min, off nobody's budget).
- An in-house canonicalizer (conjugate-norm rationalization plus
  per-grade rational Cancel) is 1-2 days of new code plus new focused
  tests.

**Therefore: use Maple.** Do not build the in-house route now; revisit
only if Maple proves measurably inadequate at scale (many blocks x many
entries, or availability problems), which would be a measured-inadequacy
trigger under the house rule.

**Validation contract for every Maple-normalized entry (user decision,
2026-08-28 ~18:45): production uses EXACT MODULAR ARITHMETIC AT RANDOM
POINTS ONLY — no full symbolic identity checks in production paths.**

- Acceptance: the normalized entry agrees with the pre-normalization
  gauge at 8 independent images — random kinematic points AND random
  regulator values, across at least 2 distinct 61-bit primes, freshly
  drawn per block (not a fixed schedule). All arithmetic exact mod p;
  root values are OUR declared branches (the recorded quadratic-residue
  square roots), substituted identically into both sides — this settles
  Maple's branch ambiguity in modular terms. A nonzero rational
  discrepancy of our degrees survives 8 such images with probability
  below ~10^-100; record the images with the entry.
- Full symbolic difference-zero checks move to Development and the
  focused test batteries only; they never run in production.
- Floating-point comparison remains a smoke test that can reject and
  accepts nothing.

Scope note: this supersedes my earlier symbolic-at-import-boundaries
requirement for all production block work. The standing 2026-08-22
decision that the FAMILY CERTIFICATE is the one exact symbolic statement
at family level is left untouched unless the user directs otherwise.

## 2. CF259 (21,16) compiler: GO on factor interning

680 registrations x (linear table scan x algebraic `factorMatchQ`)
against 21 distinct factors is yesterday's cache-hashing disease one
level down. Your shape is correct and minimal: exact spelling and
negated spelling -> index, `SameQ` hit returns O(1), miss falls to the
existing exact scan, memoize after fallback or insertion, numbering and
bundle bytes preserved.

One strengthening worth its ~20 lines: a second-level SEMANTIC key —
evaluate each factor at 2-3 fixed kinematic points mod one 61-bit prime
and key on the fingerprint. Equal fingerprints -> run exact
`factorMatchQ`; distinct -> provably distinct, skip all comparisons.
That makes nonidentical-but-equal spellings O(1) expected as well.

Counters: exactly your four (registration calls, exact hits, fallback
comparisons, factor-match seconds). Acceptance: cold compile < 1,550 s
AND byte-identical bundle against current main. Expect well beyond 1.5x
given 680:21. Agreed: no TaskBroker parallelism retry (measured null).

## 3. Mid-block resume machinery: REMOVE COMPLETELY (user decision)

A block is the atomic unit of work. A failed, interrupted, or suspect
block is redone FROM FRESH — reconstruct, re-solve, re-verify. Nothing
of a previous attempt is reused within a block.

Consequences, per the user's explicit instruction:

- **Delete the sealed-strip input reuse code entirely** — seal-based
  acceptance, the reuse path in the driver, and the cache trials'
  plumbing. Not disabled: removed. (Machinery shared with unrelated
  features, e.g. modular-image helpers used elsewhere, stays; only the
  mid-block reuse path goes.)
- Family-level resumption at COMPLETED-BLOCK boundaries (continue at
  the next unsolved block, consuming banked accepted blocks) is normal
  and unaffected.
- First-run cost is addressed the honest way: item 2 above. No caching
  substitute.

The `SealStripMismatch` question from your 06 is thereby moot; for the
record, the failing predicate was the final StripHash check with
connection and prefix hashes passing — fail-closed across your
constructor's representation change, i.e. the gate was working, and it
is being removed as policy, not as defect.

## 4. Smallest relaunch gate

1. The focused batteries you listed stay green on final source.
2. Factor interning: cold CF259 (21,16) compile < 1,550 s, bundle
   byte-identical to current main.
3. Canonical pullback: the captured CF300 (12,9) gauge normalized
   entrywise through Maple, passing the contract of item 1.
4. One fresh CF300 (12,9) end-to-end on final source, producing the
   canonical stored gauge.
5. Confirm no mid-block reuse path remains reachable (grep-level check
   is fine).

Then relaunch all three families under the clean-pool process rule
(package changes = terminate pool, fresh main + 8 clean subkernels —
endorsed).

— Fable, 2026-08-28
