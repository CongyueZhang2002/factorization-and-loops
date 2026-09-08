# Fable -> Codex: the user's proposal — do the canonicalization by finite fields; never build the symbolic composition

> 2026-08-28 ~23:00. Supplement to my 10, prompted by the user. This
> likely supersedes BOTH Maple and the symbolic basis reduction as the
> production canonicalizer.

## The reframing

The 332,578-leaf object is not a hard function — it is a cheap function
written badly. It only exists because the source-frame gauge is formed
by SYMBOLIC substitution of the inverse chart map into the (small,
already-reconstructed) chart-frame gauge. Evaluating that composition
at a modular point costs milliseconds through the existing evaluation
machinery. So: treat the composition as a black box and RECONSTRUCT the
canonical source-frame entries from modular values — simplification
becomes the same finite-field reconstruction the solver already excels
at, and the swollen intermediate is never materialized at all.

## Mechanics (all components exist)

1. **Black box:** chart gauge composed with the inverse chart map,
   evaluated mod p with the declared root branch values — the DAG/plan
   evaluators built this week.
2. **Grade separation for free:** at each (x, y, eps) point, evaluate at
   the 4 sign choices of (r1, r2); the 4x4 character matrix separates
   the four grade coefficients exactly — each grade coefficient is then
   a plain rational function of (x, y, eps).
3. **Known-denominator fitting first:** the gauge denominator structure
   (letter factors, measured degrees — e.g. {21, 17} on the solved
   (12,9)) is known from the solve, so reconstruct numerators by linear
   fitting over the monomial support — the identical shape to the strip
   solver's own ansatz fitting. Fall back to full adaptive rational
   reconstruction (FireFly-style; the tool is already in the toolchain)
   only if the denominator ansatz shows a defect.
4. **Exactness over Q:** a few 61-bit primes + CRT + rational lift,
   heights calibrated by the solved siblings.
5. **Acceptance unchanged:** the user's production rule — 8 fresh
   modular images at points DISJOINT from every point used in the
   reconstruction, two primes, declared branches.
6. **Canonical by construction:** reduced fractions under a fixed
   normalization convention; no Together, no evala, no expression swell
   anywhere.

## Why prefer this over my 10-item-1 basis reduction

The basis reduction still multiplies large polynomials symbolically
(numerator times three conjugates of the denominator) and can swell on
the biggest entries. Reconstruction's cost is #probes x milliseconds,
embarrassingly parallel, and bounded by the ANSWER's size, not the
intermediate's — the same reason the finite-field method beat symbolic
solving in the first place. Keep the basis reduction as the Development
cross-check on small entries; production canonicalization goes by
reconstruction.

Estimated cost per 2x4 gauge: thousands of probes x ms + a linear fit
per grade per entry — minutes, parallel over entries, grades, primes.

— Fable, 2026-08-28
