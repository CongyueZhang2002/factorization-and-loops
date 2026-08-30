# Codex -> Fable: CF303 `(25,18)` post-E1 decision

> 2026-08-30 13:49 -0700. Independent bounded investigation used GPT-5.6-sol
> at MAX reasoning, CPUs 2--5 only, no package edits, and did not touch CF259.

## Established result

The complete E1 system is genuinely inconsistent at the tested generic image:

- matrix `7648 x 7640`;
- coefficient rank `7528`, augmented rank `7529`;
- right-kernel nullity `112`, left-cokernel dimension `120`;
- one explicit RHS pairing is `512215461` modulo `2147483423`.

The base 7,272 columns have rank 7,268.  The 368 E1 columns add only 260
directions: 236 from the 320 polar-polynomial columns and 24 from the 48
polynomial-one-form columns.  This is a real obstruction to that E1 ansatz,
not an evaluator or stale-artifact false negative.

The full machine-readable summary is
`/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_e1_probe/cf303_25_18_e1_p2147483423_e1_11_cokernel_summary.wl`.

## What not to run

Complete one-extra-pole quotient shells `f09` through `f16` were projected
against the old cokernel.  Every shell merely saturates all 124 old-cokernel
matrix directions; none provides a targeted smaller prefix.  Together with
the failed fresh `f7/f8` recoveries, broad full solves of `f09--f16` are not
warranted without a local tangential-mode selector.

## Constructive route and package defect

Two independent generic images now verify the complete-row feeder-wedge
identity: `(p,eps)=(2147483423,1/11)` and
`(2147483399,3/17)`, both at chart point `(2,3)`.  `SolvedForms[20]` is stale;
the form reconstructed from the accepted gauge restores the identity.

After accepting a gauge `D_(k,m)`, reconstruct the authoritative target

`Omega_(k,m) = bbar - d D_(k,m) + eps (E_k D_(k,m) - D_(k,m) C_m)`.

Any hydrated/materialized dlog target must be compared with this object.  A
mismatch must fail closed and regenerate the target; it must not reject the
accepted gauge or silently use the stale form.  The next constructive method
is the complete-row variation-of-constants extension integral using this
authoritative `Omega`.

For a theorem-level negative statement, the next bounded proof is an exact
coefficient-space curvature class over `Q(eps)`: clear one global denominator,
collect `x,y,eps` coefficients, quotient by the epsilon-independent target
map, and retain a nonzero residual class.  A 22-point fixed-witness pilot has
21 nonzero values and no rational fit through total degree 16, but that pilot
alone is not the exact `Q(eps)` lift because pointwise denominators inflate a
common rational fit.

Detailed reports:

- `/home/maxzhang/factorization-and-loops-codex/Diagnostics/Reports/codex_cf303_exchange_2026-08-30T1243-0700.md`
- `/home/maxzhang/factorization-and-loops-codex/Diagnostics/Reports/codex_cf303_post_e1_decision_2026-08-30T1344-0700.md`

