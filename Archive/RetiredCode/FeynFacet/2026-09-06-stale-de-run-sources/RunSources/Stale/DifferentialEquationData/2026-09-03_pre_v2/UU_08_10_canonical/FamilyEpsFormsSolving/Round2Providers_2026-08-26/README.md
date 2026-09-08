# Round-2 wave: direct coefficient providers, measured on the frozen
# CF300 (12,9) block

Date: 2026-08-26. Machine: the shared box, one main Wolfram kernel, no
subkernels. Fixture: `../FrozenTestFixtures_2026-08-25/` (the frozen
CF300 (12,9) strip input and its frozen exact channel forcing).

Reproduce with

```
wolframscript -file Tests/Multiquadratic/t_multiquadratic_providers.wls
```

The two logs beside this file are that run and the reconstruction run of
the same evening, verbatim.

## What was measured, and what it replaces

The round-1 disposition struck the retiming of the old commit (both
reviewers refused it) and replaced it with: *per-entry timing of the new
provider against the symbolic oracle on the dominant entries*. This is
that measurement.

The symbolic oracle is `multiquadraticFieldDecompose` — the function
whose global application to the whole forcing is 1400.5 s of the
1439.7 s preparation of this block (97.3%).

## Correctness first: the 32/32 anchor

At prime 2147483423, regulator value 5, split point {2, 7}:

- the **split-branch** provider reproduces the frozen exact channels of
  every forcing entry — 8 entries x 4 grades = 32 values, all equal;
- the **quotient-grade** provider reproduces the same 32 values;
- the two providers agree with each other at three further fresh split
  points (regulator value 7).

This is Codex's benchmark result, generalized to a provider and made a
standing test rather than a one-off script.

## Cost, per entry, at one image

The eight forcing entries of this block carry 58 066 to 227 591 leaves.
The three dominant entries, each using both declared roots:

| entry leaves | symbolic oracle | split-branch | quotient-grade |
|---:|---:|---:|---:|
| 227 591 | 9.78 s | **0.279 s** | 12.99 s |
| 226 596 | 9.09 s | **0.263 s** | 11.90 s |
| 207 545 | 8.74 s | **0.259 s** | 11.95 s |

Whole block (all 8 entries, all 4 branches / all 4 grades), one image:

| provider | seconds |
|---|---:|
| split-branch | **1.32** |
| quotient-grade | 59.2 |

## Reading of the numbers, stated plainly

**The split-branch provider is the result.** At ~0.27 s per dominant
entry it is about 35x cheaper than decomposing that entry symbolically,
and it does not build a global object at all: the 1.32 s buys every
coefficient value the row assembler needs at one point, where the global
decomposition buys a function nobody samples more than a few dozen times.
That is the asymptotic change Codex's §2.1 predicted.

**The quotient-grade provider is not yet competitive, and the cause is
named.** It is the same recursive evaluator, but with the roots kept
symbolic it cannot take the substitution shortcut: it walks ~10^5
interpreted expression nodes per entry, carrying a grade vector at every
node. At 11.9-13.0 s per entry it is *slower* than the symbolic oracle
for a single point. It is kept and it is correct — it is the only route
at a nonsplit point, and at rank three only one point in eight splits —
but its production value depends on the compiled modular expression IR
that Codex §2.2 asks for and this wave did not build. That is a round-3
item and it is recorded as one, not glossed.

**What is NOT claimed.** No end-to-end solve was retimed: the wave's
gate forbids family runs, and one image is not a campaign. The honest
statement is the one Codex asked for — compile time, time per accepted
point, assembly time per (p, eps) image, solve time — measured on one
hard block end to end, and that measurement needs a run this wave was
not allowed to make.

## Per-entry active-root reduction

The provider's census on this block: 16 entries of E and C use no
declared root at all, 8 forcing entries use both. The reduction
therefore does nothing for the forcing here and everything for the
diagonal pair, which is the shape Pro predicted and the reason the
census is per entry rather than per block. On the synthetic rank-2
fixture the same census correctly reduces a single-root entry to a
rank-1 local field and lifts its channels back onto the declared grade
ABI (masks 0 and 2 nonzero, masks 1 and 3 exactly zero).
