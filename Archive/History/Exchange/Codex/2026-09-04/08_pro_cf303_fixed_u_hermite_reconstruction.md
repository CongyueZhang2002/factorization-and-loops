# CF303 exact Hermite reconstruction: fixed-u route assessment

Please continue the existing **Assess Multiquadratic Pipeline** discussion and assess the next mathematical/computational step against the actual repository code and data.  We are not asking for another general architecture review.

## Established measurements

For one real CF303 row-2 source operand with 423,816 postfix operations:

- exact fixed-epsilon evaluation over `Q(u)` completed in 66.16 s evaluator time (90.47 s including parsing), 115 MB RSS;
- direct exact `Q(eps)(u)` evaluation made no 50k-operation milestone in 300 s;
- the opposite nesting `Q(u)(eps)` likewise made no 50k milestone in 206.8 CPU s;
- an 8-coefficient Laurent-series ring over `Q(u)` reached 50k operations in 78.86 s, projecting beyond 11 minutes for this one operand before the other source expressions;
- both Wolfram term-wise exact orderings exceeded five minutes without producing a node.

Therefore no characteristic-zero `HermiteSourceComponent` has been compiled and no closure should be claimed.

The already validated finite-field evaluator and exact circuit data live under:

- `Scripts/Transport/CF303/data/normal_factor_exact_circuit/`
- `Scripts/Transport/CF303/CF303NormalBulkCoefficientMap.wl`
- `Tests/Transport/t_cf303_exact_hermite_semantics.py`
- `Tests/Transport/t_cf303_normal_factor_bundle_paths.py`

The exact normal-factor evaluator passes at two unused 61-bit primes in about 30 s each and checks all recurrence, base-point, T25-H, and T25-cross-K entries.

## Proposed route

Evaluate the deferred source at exact fixed values of `u`, obtaining functions in `eps`; use the already reconstructed exact primitive and remainder denominators to formulate a demand-specific linear Hermite ansatz; solve/reconstruct its numerator coefficients from enough exact `u` points under explicit degree and support bounds; then replay the reconstructed node exactly in the defining Hermite equation.  Do not reconstruct the full unused matrix.

For the tangential boundary system, the honest embedding in the differential-system basis is

```text
B_F = [V_S ; V_G + H(2 p) V_S]
```

and it must obey

```text
(A_p + 2 A_z) B_F - d_p B_F - B_F Omega = 0.
```

`CF303JunctionRebase.wl` changes metadata/selectors only; it does not supply `H(2p)`.

## Questions

1. Is fixed-`u` exact interpolation the best exact route here, or is there a better way to exploit the known Hermite denominators and the finite-field circuit?
2. What is the minimal mathematically sufficient degree/support bound and validation needed to make the reconstruction exact, without adding redundant production checks?
3. Can `H(2p)` be obtained directly from the same reconstructed Hermite data without first materializing all of `H(u,eps)`?
4. Please identify any hidden basis/derivative error in the displayed boundary embedding and closure equation.

Please give a concrete go/no-go recommendation and, if go, the smallest implementable algorithm with stopping/refusal conditions.
