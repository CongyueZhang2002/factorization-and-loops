# Codex triple-root campaign wrap-up — 2026-08-24

## Stop state

The only live mission launched in the latest Codex phase was
`fresh_cf303_21_11_k2_pde_sample_dataset_v1_sample01`. It completed normally
before the stop request, at 2026-08-24T14:22:17. No follow-on reconstruction
was submitted. At wrap-up, Codex has no mission running or queued.

The pool is left healthy at 7 busy / 1 free. The seven pre-existing Fable
missions were not interrupted, and no Wolfram main kernel, subkernel, or user
process was killed.

## Important terminology and scope correction

`21 -> 12` denotes the off-diagonal coupling from ordered CF303 sector/block
21 to lower sector/block 12. The numbers are sector labels, not root counts.
That coupling is the already-resolved two-root Kallen23 block and was used only
as an upstream input.

The later `21 -> 11` investigation was intended to test whether the next
apparent obstruction genuinely required all three roots. It does not: its
forcing contains only the rational and Lambda2 channels. Thus this work rules
out one candidate for the triple-root obstruction, but it does **not** solve a
genuine triple-root off-diagonal block. Continuing the prepared reconstruction
would advance sequential CF303 completion, not the requested three-root
research goal.

## Completed and certified results

### CF303 sector 21 -> 11 root-support certificate

- Four independent finite-field primes.
- All eight sign sheets at every prime: 32 sheet evaluations total.
- Exact eight-sheet Hadamard projection and recomposition checks.
- Forcing support grades are `{0, 1}` only: rational plus Lambda2.
- Lambda3, the third root, and every mixed grade are absent.
- No whole symbolic residual was constructed.
- Heuristic union false-zero bound for the six omitted grades:
  `6.9278824057e-25`.

Certificate:

`/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/cf303_21_11_pointwise_support_certificate_v1/certificate.wxf`

SHA-256:

`119b760406eab5edbf07a907e4f8a740ac1bc02b4ec24f35c755365b0f7d285a`

Detailed checkpoint:

`External/CodexExchange/triple_root_2026-08-24/cf300_pair_chart_campaign/CF303_21_11_POINTWISE_SUPPORT_CHECKPOINT_2026-08-24.md`

### Faster point oracle

The sparse dependency-closed oracle was converted to exact univariate-epsilon
arithmetic over `F_p` using modular `Together` only after kinematic point
evaluation.

- Full epsilon dependence at one Kallen2 point: approximately 0.7 s.
- Previous eight-sheet, single-epsilon route: approximately 30 s per point.
- All four forcing entries have epsilon numerator/denominator degrees 9/10.
- A held-out scalar epsilon specialization matched exactly.
- No source 19 -> 11 gauge and no 45 x 45 transformed matrix were materialized.

Pilot artifact SHA-256:

`21426aa84b4f76ba1a806dff274679a4c43be27725b00d4790b0a7ac4d8bff33`

### Fixed-epsilon kinematic degree census

At epsilon values 37, 103, and 211, generic-line degrees were stable:

- forcing entries 1 and 3: numerator degree 36, denominator degree 34;
- forcing entries 2 and 4: numerator degree 37, denominator degree 36.

The denominators are not common across all four entries. Their factorization
contains inherited mixed regulator/kinematic factors, so a denominator made
only from a provisional physical-letter list is insufficient. The associated
affine PDE pilot was inconsistent for that incomplete denominator; this is not
an obstruction certificate.

Degree-analysis artifact SHA-256:

`4dd63b6b91b7768431f02c61d7c17ffb873254f30b5017f3d13c2e43b36e7d58`

Denominator-factor artifact SHA-256:

`8ad99797290a95e601b667ae3e58f1f2da14a16d4bfa977903e7ec6fc065cc00`

### Completed 1,550-point reusable dataset

The latest mission completed before the stop request:

- prime: `1937041`;
- accepted points: 1,550;
- attempts: 6,139;
- sampling time: 880.078 s;
- mean accepted-point time: 0.56578 s;
- median accepted-point time: 0.50697 s;
- all three square roots split at every retained point;
- forcing, upper diagonal, and lower diagonal shapes passed;
- an independent scalar epsilon specialization passed;
- all input hashes remained stable;
- package source remained unmodified;
- no whole symbolic residual was formed.

Dataset:

`/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/cf303_21_11_kallen2_pde_sample_dataset_v1_01/dataset.wxf`

SHA-256:

`30a799ebd7f55e8abec6b5a9ea5bbe8ae4b1e1fd0a025b5e50741ff7d11f97b7`

Size: 4,816,958 bytes.

## Prepared but deliberately not run

A scratch-only fixed-epsilon CFFR reconstruction driver was prepared:

`C:/Users/congyue zhang/Documents/ChatGPT/Agentic Loops/reconstruct_cf303_21_11_k2_forcing_fixed_epsilon_v1.wl`

SHA-256:

`4417bdfdb452d029778f0285a925193a286e503ed5b9446047c830013576c7d0`

It was not submitted. It would reconstruct all four forcing entries at fixed
epsilon and certify them on at least 64 unseen points, but this block is now
known to be one-root and therefore is not the correct priority for the
triple-root campaign.

## What remains unresolved

No genuine three-root off-diagonal gauge has been solved by this phase. In
particular, this result is not a solution of CF300's algebraic/triple-root
row-gauge problem.

The correct resume gate is:

1. Use a cheap eight-sheet, multi-prime support census on the proposed
   unresolved off-diagonal block.
2. Continue only when the forcing actually has simultaneous support involving
   all three roots; discard one-root/two-root descendants from the triple-root
   research queue.
3. Solve the true block with split-prime point oracles over the multiquadratic
   basis or a verified joint chart if one exists.
4. Accept candidates using unseen points, fresh primes, and all required sign
   sheets. Do not make a global symbolic residual the acceptance bottleneck.

Unless the goal changes to completing all remaining CF303 sectors, do not
resume the prepared `21 -> 11` reconstruction.

## Repository state

No file under `/home/maxzhang/factorization-and-loops` package source was
modified by this phase. All new drivers and reports are scratch or Exchange
artifacts.
