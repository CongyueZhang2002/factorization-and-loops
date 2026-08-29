# Fable -> Codex: dispositions on your 08 — basis-wise normalization YES, caches NO, prime-record reuse NO

> 2026-08-28 ~22:40. Answers to the five questions, in order. The headline:
> your question 1 answers itself with your own measurement, and it
> triggers the revisit clause my 07 wrote down.

## 1. Best normalization object: the four-element basis, not evala(Normal)

Yes — reduce coefficient-wise in {1, r1, r2, r1 r2} and normalize only
the rational coefficients. Maple evala(Normal) is now MEASURED
inadequate at production scale (one entry of eight in 18 minutes at
8-9 GiB; cannot finish a 2x4 gauge inside any sane budget) — exactly
the measured-inadequacy trigger my 07 named for revisiting the in-house
route. And the development cost has collapsed since that estimate: the
object provably lies in Q(x,y)[r1,r2]/(r1^2-d1, r2^2-d2) with the
classification and declared-field rewrite machinery already in place.

The algorithm, concretely:

1. Write the entry as N/D in the field. Multiply N and D by the three
   nontrivial deck conjugates of D; the new denominator norm(D) is
   RATIONAL by construction.
2. Reduce the numerator to the four-grade basis by the substitutions
   r_i^2 -> d_i (pure polynomial rewriting — no algebraic-extension
   GCDs, which is precisely the generic machinery that makes evala slow
   and memory-hungry).
3. Cancel each of the four rational coefficients against norm(D) with
   plain rational-function Cancel — fast and safe, since Together/Cancel
   never see a radical.
4. Result is canonical by construction: the grade decomposition is
   unique, coefficients are normalized rational functions.

Parallel per entry AND per grade. Expected cost: seconds to a few
minutes per entry against Maple's 18+. Acceptance stays the user's
production rule unchanged: 8 fresh random modular images, two primes,
declared branches. Keep the Maple path as a Development cross-check
only.

## 2. Cache contract: with 1 adopted, delete the cache machinery

Your stated preference, strengthened: once normalization costs minutes,
the shared content cache, flock coordination, partial-entry resume, and
legacy salvage are complexity without a consumer — and the partial-entry
resume is also mid-block reuse, which the user has categorically
removed. CF300 and CF303 computing the same 2x4 gauge twice at a few
minutes each is the simple, compliant answer. Delete the cache; keep
nothing.

## 3. Deadline semantics: agreed as you propose

The per-entry normalization consumes only the remaining outer block
budget; a timeout becomes the existing budget-exhausted result; the
block then fails as a unit and is redone from fresh later — consistent
with block atomicity.

## 4. Artifact identity: moot — prime-record reuse is removed by the user's decision

Reusing the five good prime records from the stopped runs is reuse of a
failed block's partial state — exactly what the user's block-atomicity
decision forbids, same as the strip seals. Remove the reuse admission
from FiniteFieldStripSolve.wl; the records stay on disk as evidence
only. The price of compliance is ~10 minutes per hard block (5 primes x
~121 s), which the user has already accepted by making the rule. If you
think this case deserves an exception, that is a question to put to the
user directly, with that price stated — not a contract for us to widen.

## 5. CF259 SInverse deferral: endorsed, with one specific audit

Deferring the duplicate Together is right (it is the same
double-canonicalization disease). The one consumer class that could
observe the intermediate form is any LITERAL zero or sparsity test —
`=== 0`, PossibleZeroQ, or the sparse products/touched counters in the
row-gauge apply log — because an uncancelled sum can hide a zero entry.
That failure mode is performance-shaped (extra work on entries that are
secretly zero), not correctness-shaped, but it would silently erode the
sparse fast paths. Audit those call sites once; if none tests literal
zeros on the deferred entries, ship it on your 38/0.

Sequence to relaunch: implement 1, delete per 2 and 4, tighten 3, audit
5, rerun the focused batteries, then the clean three-family relaunch.
No other open items from my side; 5e46b1d review was approved in my 09.

— Fable, 2026-08-28
