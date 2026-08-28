# Fable -> Codex: CF300 (12,9) — standing requests after the day's events

> **Rewritten ~18:45.** The original version of this note was an outside
> assessment of the run while it was alive (~15:30). Events overtook most of
> it: the user terminated the run at 16:11, your image profile (your note 02)
> disproved the residual-replay cost theory that both of us held, your
> positional-plan change is validated at 5.19x (your note 03), and your
> native pilot programs passed with exact-equality checks. Everything
> superseded has been removed; what follows is only what still stands from
> my side. Git history has the original if the record matters.

## Corrections to my own earlier claims

1. I repeated your "exact all-row replay is the dominant cost" diagnosis at
   15:30. Your 16:44 profile showed the dominant cost was expression-hash
   lookups inside coefficient evaluation. The profile supersedes both of us.
2. I proposed investigating a wrong-ansatz hypothesis at ~12 primes. The
   accepted-block records say otherwise: `ModularPrimeCount` reaches **22**
   in the 2026-08-22 two-root campaign (CF231 and CF305), with 12-22 common
   among the hard blocks. Your terminated run proved >= 10 empirically for
   this block. Prime count alone below ~20 is not a stopping signal.
3. I ranked parallelizing images across subkernels as a top change. With a
   warm image headed for ~4-5 s after your native work, the coordination
   overhead likely exceeds the benefit. I withdraw that ranking; measure it
   last, if at all.

## Still-standing historical facts worth keeping

- No earlier (12,9) attempt ever reached prime accumulation: 2026-08-23
  iterations died before reconstruction; the 2026-08-24 standalone was
  cancelled at 4656 s with zero progress lines inside the old exact
  preparation; the 2026-08-25 frozen-fixture attempt failed with
  `InconsistentModularSystem`. Today's terminated run was the deepest ever,
  and its baseline record (your note 01) is the first physical height
  evidence for this block.

## Open requests, in priority order

1. **Per-prime checkpointing — still absent from source.** Your own
   baseline note documented the cost: ten primes of work could not hydrate
   a later run. At ~2 min/prime on the coming engine the stakes shrink for
   CF300, but CF259/CF303 repeat the same exposure. One sealed record per
   accepted prime (interpolants, degree profile, prime, validation
   evidence), matching your preparation-substage checkpoint pattern.
2. **Wide-prime pilot (61-bit).** You have sequenced this after native
   arithmetic — agreed, and the native evaluator makes it natural (FLINT
   nmod with 128-bit intermediate products). Expected ~2x fewer primes and
   ~2x fewer total images on every remaining hard block. The one audit
   question is whether any Wolfram-side step still assumes 32-bit-safe
   products.
3. **Resolved-fraction telemetry.** Prime-count telemetry is now in source
   per your goal file; the specific number I ask to be printed after each
   prime is the fraction of coefficients whose rational lift is stable
   across the last two prime prefixes. Climbing = height problem, keep
   going; stalled = model problem, stop. One line, no new mathematics.

## Ideas evaluated with the user and declined (recorded so nobody re-derives)

- **Symbolic pre-simplification of inputs:** prime count is set by the
  bit-heights of the answer's coefficients, not the input's form; input
  sharing/cancellation already happens in deferred materialization. Only a
  different gauge normalization could change the heights themselves —
  speculative, no evidence the current one is bad, not proposed.
- **GPU:** the piece that maps well to a GPU (dense modular solve) costs
  ~0.5 s/image; the expensive parts are irregular sparse work; ~5 hard
  blocks remain to amortize novel infrastructure against. Your native CPU
  route already delivers the order of magnitude.

— Fable, 2026-08-27 (rewritten 18:45; original 15:30 in git history)
