# Fable: cost verdict on CF259 (27,9); the one priced option going forward

> 2026-08-30 13:40. User verdict: "an afternoon for a single block is too
> expensive." Recorded here with the cost breakdown, the decision for the
> run in flight, and the single optimization with named consumers.

## Where the afternoon actually went

- Bugs, not mathematics: the schema-compatibility failure, the pole-census
  inflation (273M-unknown mirage), and the ragged-list registration crash
  consumed the morning. The first uninterrupted mathematical attempt on
  (27,9) started ~12:00.
- The mathematical cost itself: prime 1 (structure discovery + 19 images)
  3,332 s; prime 2 accepted ~20 min later on the known recipe. With the
  (27,11) precedent of six primes, expected completion is roughly 15:00-
  16:30 — about 2-4 hours of pure computation for an 11,008 x 10,888
  system. That is tail-of-campaign scale: (27,11) and (27,9) are the two
  largest systems among all 1,119 blocks; 89 of 91 families never needed
  a tenth of this.

## Decision for the run in flight: do not touch it

Block atomicity (user rule): interrupting discards the accepted primes
and restarts from fresh. The machine is saturated (2 workers x 8 native
threads). There is no intervention that finishes (27,9) sooner than
letting the conveyor run.

## The one optimization with named consumers: wide-prime assembly

The 31-bit prime limit is the packed evaluator's machine-integer
overflow bound (FiniteFieldStripSolve.wl O2 width guard). Porting sample
assembly to FLINT 64-bit modular arithmetic would:

- halve the prime count (61-bit primes carry ~2x the CRT information);
- likely speed the assembly itself (C vs packed Wolfram), which is the
  dominant per-image cost (69 s of the 122 s cold image).

Named consumers after (27,9): exactly ONE candidate — the CF303 (25,18)
E1 reconstruction, if the polynomial-residue probe succeeds and needs a
comparable images-times-primes schedule. No other block of this scale
remains in the campaign.

Per the cost-benefit rule (price builds against named consumers): do NOT
build the port now. First, Codex should record the warm-image time split
(assembly vs FLINT solve) from the current (27,9) stream — it is in the
logs already — and the final prime count. If E1 turns into a real
reconstruction consumer, price the port against those two numbers then.

## Correction (14:45, after Codex note 11)

The implementation premise above was wrong for the live path: the
production split-provider sampler is ALREADY native FLINT with word
limit 2^63 (`flint_sparse_eval.c`, `flint_row_assemble.c`); the 2^31
packed guard gates only the legacy compatibility route. A real 61-bit
CF300 image pilot measured NO per-image penalty (3.804 s vs 3.848 s at
31 bits). The genuinely missing piece is wide-prime interpolation/
profile handling (~6-10 h), expected conveyor gain 1.6-1.9x. The
cost-benefit verdict stands unchanged: do not interrupt (27,9); price
the integration against the next reconstruction consumer only. Codex's
note 11 disposition agrees.

## What NOT to spend on

- No interruption or resume machinery for this block.
- No image-parallelism rework (measured 1.07x previously; machine already
  saturated).
- No general prime-width refactor without the E1 consumer confirmed.

— Fable, 2026-08-30
