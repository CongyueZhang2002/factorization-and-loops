# Polylogarithmic representations: assessment, 2026-09-06

The bounded GPL converter, coordinate pullback and GiNaC experiment are now
implemented. See [the implementation and measured results](GPLImplementation_2026-09-06.md).


This is a design assessment, not an implemented conversion or a new production
solver. The recommended extension rewrites suitable finite coefficient
expressions in standard polylogarithms and lets the existing evaluator select
a suitable numerical backend.

## What the two-root work establishes

The current geometry code contains explicit forward rationalizing
parametrizations for pairs including Kallen12, Kallen13 and Kallen23.
It verifies rational forward coordinate images, square-root identities and a
nonzero Jacobian. It does not verify inverse branches or certify that every
coefficient of a whole family is a GPL.

The number of square roots is not a function-class criterion. For example,
the integral of dt/(sqrt(1-t^2) sqrt(1-m t^2)) is generically an elliptic
integral, although the two square roots are quadratic and individually
rationalizable. Conversely, multiple roots need not obstruct MPL expressions:
different rationalizations of the same path can suffice.
[Papathanasiou et al., 2501.07490](https://arxiv.org/abs/2501.07490) give such
a construction with seven roots.

For this project's catalogued two-root geometries, the rationalizing
parametrizations are strong positive evidence and a useful starting point.
What remains to establish is the function class of the finite recursive
integrands, including homogeneous factors and prefactors. Rational original
DE matrices alone are insufficient: irreducible elliptic period systems can
also have rational matrices.

## A sufficient conversion criterion

Over a chosen algebraic extension of the field of external parameters, a GPL
is an iterated integral with kernels dt/(t-a), where a is independent of t.
Its letters may be algebraic functions of the external endpoint coordinates.

A finite recursive expression closes under GPL integration when each integrand
is a finite sum of rational functions of the integration variable times
products of already-converted hyperlogarithms in that variable, with compatible
endpoint regularization. Rational higher poles and polynomial parts are
reduced by integration by parts. Products are handled by shuffle relations
only where integration requires them. Arbitrary reciprocals or compositions
of GPLs are not covered by this criterion.
[Panzer's HyperInt](https://arxiv.org/abs/1403.3385) provides the relevant
symbolic integration algorithms.

Strict epsilon form is a useful sufficient organization and may dramatically
reduce the number and weights of functions. It is not required for this finite
recursive conversion criterion. The general solver's finite triangular
recursion can be used directly when its actual integrands pass the criterion.
Boundary constants remain symbolic; expressing their coefficient functions
as GPLs does not determine the physical constants or their function class.

## Paths matter

Current finite solutions use a straight path in their stored coordinates.
A straight path in original coordinates may introduce a complicated algebraic
curve even when a rationalizing parametrization exists for the full kinematic
surface. Pulling back that fixed path is different from selecting a simple
path in the new coordinates.

A useful extension permits rational or piecewise rational paths in verified
rationalizing coordinates, with a specified lift of the same original base
point. Equality with the existing solution uses flatness and the same homotopy
class in a nonsingular domain. Individual iterated integrals need not be path
independent. Different pieces cannot be arbitrarily assigned different paths.
The path and tangential-basepoint qualifications are discussed in
[2501.07490, section 2](https://arxiv.org/html/2501.07490v2).

## Current size and nesting observations

A read-only inspection of four current saved solutions found:

| Family | Scalar integral definitions | Shared scalar/integration kernels | Maximum nested integration depth | Transformed epsilon orders |
|---|---:|---:|---:|---|
| CF231 | 1,012 | 10,360 | 29 | 0 through 8 |
| CF254 | 1,013 | 9,069 | 29 | 0 through 8 |
| CF265 | 1,387 | 13,740 | 27 | 0 through 7 |
| CF303 | 2,557 | 30,661 | 28 | 0 through 7 |

Depth counts dependencies between stored scalar integrals. It is not the
minimal GPL weight, and no functional-independence or function-class conclusion
follows from it. Exact differentials, rational prefactors, changes of basis
and cancellations can reduce the effective weight.

This is a practical reason to avoid direct expansion of the whole definition
tree into GPL words. Retain shared expressions and products, reduce exact
differentials early, and consider optional block transformations if they lower
the resulting function count. Do not change mathematically required epsilon
orders to fit a numerical library's convenient weights.

## Numerical options

- GiNaC evaluates general multiple polylogarithms at arbitrary working
  precision. The available WSL pkg-config version is 1.8.7 and ginsh is
  installed. [GiNaC manual](https://www.ginac.de/tutorial/).
- handyG is designed for fast GPL evaluation in Monte Carlo applications.
  It uses fixed double precision, optionally quadruple precision, with explicit
  i0 support. Its published timings do not establish a speedup over our current
  compiled FLINT or Taylor evaluators.
  [Naterop, Signer, Ulrich](https://arxiv.org/html/1909.01656v2).
- GiNaC 1.8.10, released 11 February 2026, adds Gt for elliptic multiple
  polylogarithms with arbitrary arguments. Its numerical method uses
  convergent q-series and arbitrary precision. The installed 1.8.7 predates
  this interface. [Release note](https://www.ginac.de/News.html),
  [Duhr et al., 2602.09956](https://arxiv.org/abs/2602.09956).
- PolyLogTools is useful for symbolic manipulation and fibration bases,
  rather than being a replacement numerical engine by itself.
  It is already present in the read-only Addon installation.
  [Duhr and Dulat](https://arxiv.org/abs/1904.07279).

An eMPL conversion needs the actual elliptic curve, normalized kernels, periods,
marked points and branch data. Three roots do not automatically imply one
elliptic curve, and an elliptic-looking chosen path need not establish an
intrinsic elliptic obstruction.

## Recommended first implementation and benchmark

1. Implement a general conversion of supported finite recursive integrals into
   explicit GPL expressions, with exact-differential reduction and shared
   subexpressions. Recognize classical and harmonic polylogarithms as
   special cases; do not force all MPLs into classical Li_n.
2. Add path selection in verified rationalizing coordinates, preserving the
   base point and declared branch. Keep unconverted blocks explicit in the
   existing format. This is one production workflow with optional standard
   function representations.
3. Exercise the converter on a small rational example and structurally distinct
   two-root cases. Check derivatives/base-point values and a few numerical
   points. Then compare end-to-end time, file size, distinct function count,
   actual retained weights, and achieved accuracy against the compiled finite
   evaluator and Taylor/DE route.
4. Use GiNaC for the high-precision reference. Consider handyG where required
   accuracy and cancellation permit fixed precision. Benchmark both isolated
   points and batches, including nearby points where Taylor reuse is strong.
5. Extend to eMPLs only for verified elliptic subproblems after the GPL path is
   useful. General physical-boundary determination and continuation remain
   necessary regardless of the chosen special-function representation.

My expectation is improved paper presentation and often faster evaluation for
compact GPL expressions. A blanket numerical speedup is not established.
The most useful optimization target is a small stable set of actual special
functions, rather than a change of notation for a large integral expression.

## Independent review

The Pro review agrees with the optional conversion approach and emphasizes:

- Closure requires polynomial dependence on previously converted functions,
  not arbitrary reciprocal or composed dependence.
- A rationalized coefficient or a finite recursion alone is insufficient.
  Homogeneous factors and all nested-variable dependencies must be included.
- Change the path of the complete solution and reconstruct its finite recursion;
  do not independently deform stored auxiliary integrals.
- A correctly chosen regular local lift is sufficient; a globally rational
  inverse is not required.
- Keep numerical continuation and reuse available for the general inventory.
  A bounded conversion experiment must demonstrate that its expression size
  and evaluation time justify broader conversion.

[Full question and response](../External/ChatGPT/Records/2026-09-06/09_polylogarithmic_representation_review.md).
