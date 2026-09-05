# Hard-block performance acceptance for the finite-field changes

This note applies the required acceptance rule: a general optimization that
affects the hard off-diagonal blocks is retained only when a comparable hard
block is faster.  A first-time completion without a comparable earlier record
is reported, but is not counted as performance evidence.  Older records that
used an incomplete square-root set or a different rational parametrization are
not valid baselines.

## Comparable measurements

| CF259 block | Previous comparable record | Current record | Assessment |
|---|---:|---:|---|
| `(27,23)` | finite-field solve 878.7 s; pull-back acceptance 558.1 s; combined 1,436.8 s | finite-field solve 523.1 s; pull-back acceptance 428.3 s; combined 951.4 s (954.4 s including classification and parametrization) | **Accept.** The combined mathematical block computation is 1.51 times faster.  The solve is 1.68 times faster and acceptance is 1.30 times faster. |
| `(27,19)` complete degree-zero ansatz | the same 480-monomial, 15,500-unknown, 15,616 by 15,500 modular system was still unresolved after approximately 538 s inside reconstruction | the complete-support modular inconsistency is returned in 151.2 s; the preceding 251-monomial denominator-support hypothesis costs 24.9 s | **Accept.** Time to the terminal full-support result improves by more than 3.56 times.  This is an early-propagation improvement; it is not a claim that FLINT's elimination itself became 3.56 times faster. |

The `(27,23)` before/after inputs are mathematically identical: both use the
saved block equation, the `KallenQ4a` parametrization, the same 15-letter
alphabet, the same six reconstruction primes, and the same accepted
denominator/numerator degree pair `{11,15}` / `{12,16}`.  The old numerator
support had 2,926 monomials and 11,764 affine unknowns.  The new first support
has 982 monomials and 3,988 affine unknowns.  The old first native solve took
589.07 s; the new one took 2.56 s.  The full solve comparison above includes
all regulator images, lifting, and the unseen-prime residual, so acceptance is
not based on that pilot number alone.

The old `(27,23)` run had simultaneous live snapshots of approximately
8.2 GiB in the Wolfram parent and 5.9 GiB in FLINT.  During the current run,
the observed sum of the parent and eight Wolfram workers was approximately
4.7 GiB, and the main kernel reported 1,507,192,680 bytes maximum kernel
memory.  These are live/implementation-specific memory observations rather
than an aggregate operating-system peak, so only their order of magnitude is
used.

## Blocks without a valid previous baseline

| CF259 block | Current result | Status of comparison |
|---|---:|---|
| `(26,1)` | construction 14.9 s; solve 97.7 s; acceptance 63.5 s | First completed run with the corrected deferred three-root input.  Earlier attempts failed before solving or entered the retired symbolic route; no speedup is claimed. |
| `(27,21)` | construction 13.0 s; solve 70.5 s; acceptance 57.5 s | First completed corrected-input record found.  A prior run spent 125.2 s on startup and an obsolete 25-offset support search before being stopped, but it did not complete; no full-block speedup is claimed. |
| `(27,20)` | construction 13.0 s; solve 69.0 s; acceptance 16.9 s | First completed run with the corrected input.  No comparable earlier V2 completion was found, so this is qualification evidence only. |

The separately recorded `(23,21)` improvement from a stopped 1,189-second
image-wave run to a 70-second completion belongs to the earlier clean-helper
batching change.  It is a different off-diagonal block and is not used as the
baseline for `(27,21)` here.

Old runs in which `(27,19)` saw only one of its three square roots, and old
`(27,23)` runs in a different parametrization, are intentionally excluded.
Their smaller systems are not the same mathematical problem.

## Rejected experiments

The provisional degree-one restricted-support experiment for `(27,19)` was
removed.  It added a 152--183 s failed solve before reaching the same complete
support and therefore failed the performance gate.  The complete degree-zero
and complete degree-one rectangular ansatzes are both inconsistent, while the
35-one-form residue compatibility system is consistent at the sampled image.
This narrows the mathematical problem but does not yet prove that no rational
dlog epsilon form exists.

A bounded mixed-grade divisor search found one new three-root letter in 204.7 s,
with grade support `{4,5,6}`. It was tested outside the package in three
controlled variants and is rejected:

| `(27,19)` variant | Result | Same-block comparison |
|---|---:|---|
| Automatic norm enlargement, denominator bidegree `{21,29}` | 10,224-unknown denominator-support system inconsistent; 21,264-unknown complete rectangle exceeded the configured sample-memory limit; 53.8 s total | Not a comparable improvement because the denominator and support changed; no solution was obtained. |
| Algebraic norm factor suppressed, base denominator bidegree `{14,17}` | 4,528-unknown denominator-support and 8,784-unknown complete rectangle both inconsistent; 44.8 s total | Useful negative diagnostic only; it tested a smaller denominator than the recorded block and obtained no solution. |
| Original recorded denominator `{19,23}`, original 480-monomial complete support | 15,504 unknowns; terminal inconsistency after 203.5 s, including 169.0 s in the complete system | **Reject.** The current 35-letter method reaches the same terminal result in 151.2 s. The added direction is 1.35 times slower and does not resolve the block. |

The mixed-grade prototype is therefore not connected to production. Any
further alphabet extension must first enlarge the constant-coefficient
one-form span and then beat the current same-block timing.

## Regression evidence

The following focused suites pass after the retained changes:

- `Tests/Transport/t_finite_field_basis_transformation_reexpression.wls`
- `Tests/FiniteField/t_finite_field_deferred_inhomogeneity.wls`
- `Tests/FiniteField/t_finite_field_preparation.wls`
- `Tests/FiniteField/t_finite_field_off_diagonal_block_solve.wls`
- `Tests/Multiquadratic/t_multiquadratic_modal_structure_pilots.wls`

The rank-zero constrained-core path emitted a `Join::normal1` warning during
the adversarial pilot test.  The construction now handles a rank-zero matrix
as the normalization selector itself; the test remains 8/0 and is warning-free.

## Source evidence

- Previous `(27,23)`:
  `/tmp/codex-v2-cf259-pool-20260904ae/logs/fresh_sol_CF259_1339363.log`
- Current `(27,23)`:
  `/tmp/cf259_27_23_current_benchmark_summary.wl`
- Current `(27,21)` and `(27,20)`:
  `/tmp/codex-v2-cf259-pool-20260904ag/logs/fresh_sol_CF259_1369626.log`
- Previous and current `(27,19)`:
  `/tmp/codex-v2-cf259-pool-20260904ag/logs/fresh_sol_CF259_1369626.log` and
  `/tmp/codex-v2-cf259-pool-20260904ah/logs/fresh_sol_CF259_1382230.log`
