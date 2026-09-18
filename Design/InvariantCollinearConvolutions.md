# Invariant collinear convolutions

The common contribution executor applies PDF and FF counterterm operators to a
`PartonicResult`. A leg declares its convolution geometry; process names do not
select the operator algebra. Mellin axes and an invariant single-inclusive
density use the same Laurent-order planning, normalization, flavor sums and
result contract.

## Physical density and maps

For `s>0`, `0<v,w<1`, set `t=s(v-1)`, `u=-svw`. The stored density is
`E_c d sigma / d^(D-1)p_c`, expressed as a distribution in `w`.
At Born level `b(s,t,u) delta(s+t+u)` has delta coefficient `b/(sv)`.

Writing the integration fraction as `xi`, the three actions are:

| Leg | Source arguments `(s',v',w')` | Lower fraction | Measure multiplying `d xi K(xi)` |
|---|---|---|---|
| Incoming A | `(xi s, v, w/xi)` | `w` | `1` |
| Incoming B | `(xi s, 1-(1-v)/xi, xi v w/(xi-1+v))` | `(1-v)/(1-vw)` | `1` |
| Observed FF | `(s, 1-(1-v)/xi, v w/(xi-1+v))` | `1-v+vw` | `xi^(-2+2 epsilon)` |

The common dimensional prefactor `muR2^(p epsilon)` is independent of `s`;
all invariant-dependent factors remain inside the coefficients and are
rescaled. The FF factor is expanded only to the order required by the source
and kernel Laurent bounds. Kernels omit their coupling power; the perturbative
plan supplies it once.

## Rational convolution charts

Choose a variable `q` so that the third source argument is exactly `w/q`.
The physical fraction is `xi=chi(q)`:

| Leg | `chi(q)` | Mapped `S(q)` | Mapped `V(q)` |
|---|---|---|---|
| Incoming A | `q` | `s q` | `v` |
| Incoming B | `(1-v)/(1-vq)` | `s(1-v)/(1-vq)` | `v q` |
| Observed FF | `1-v+vq` | `s` | `vq/(1-v+vq)` |

Every singular source coefficient `f(s,v)` therefore defines an effective
Mellin kernel

```
L[f](q) = q omega(q) f(S(q),V(q)) chi'(q) K(chi(q)).
```

The source delta gives `L[h_delta](w)` directly. Each source plus term gives
the ordinary Mellin convolution `L[h_i] convolution D_i`. Only the source's
regular coefficient needs the original physical fraction integral.
The angular and scale arguments are always rescaled.

## Endpoint algebra

For `D_j(x)=[log^j(1-x)/(1-x)]_+` define

```
d(q) = [1-chi(q)]/(1-q), sigma = chi'(1), g(q)=chi'(q)/d(q),
M(q) = q omega(q) f(S(q),V(q)), f0=M(1)=f(s,v).
```

The effective kernel has delta coefficient

```
f0 [k_delta + sum_j k_j log^(j+1)(sigma)/(j+1)]
```

and plus coefficient of order `m`

```
f0 sum_(j>=m) k_j binomial(j,m) log^(j-m)(sigma).
```

Its regular remainder is

```
M(q) chi'(q) k_regular(chi(q))
+ sum_j k_j/[1-q] {
    M(q) g(q) [log(1-q)+log d(q)]^j
    - f0 [log(1-q)+log sigma]^j
  }.
```

The subtracted numerator makes the remainder locally integrable. The
finite delta shift follows from `(sigma^lambda-1)/lambda` in an independent
analytic regulator. The original plus prescription remains on `[0,1]`;
it is not redefined on the truncated physical fraction interval.

The standard Mellin library supplies the universal `D_i convolution D_j`
coefficients, including the `-Zeta[2] delta(1-w)` in `D_0 convolution D_0`.
For a regular effective kernel `r(q)` the remaining integral is

```
integral_w^1 dq [r(q)-w r(w)/q] log^i(1-w/q)/(q-w)
+ r(w) log^(i+1)(1-w)/(i+1).
```

For a regular source define `F(xi)=omega(xi) R(S(xi),V(xi),w'(xi))`.
The action of a kernel plus term is

```
integral_xiMin^1 dxi log^j(1-xi)/(1-xi) [F(xi)-F(1)]
+ F(1) log^(j+1)(1-xiMin)/(j+1).
```

Delta and regular kernel parts act directly. All resulting integrals are
ordinary locally integrable functions; no process-dependent endpoint
constant is inferred from numerical fitting.

Finite scheme operators act only on verified finite sources. No epsilon
continuation of a finite factorization scheme is invented.

## Explicit integration and storage

Elementary rational integrals use Wolfram integration. The general
hyperlogarithmic fallback constructs explicit GPL primitives. Integrable
logarithmic endpoint singularities are retained. Each interval is split at
its midpoint, with each half oriented from a physical endpoint to the
midpoint; this avoids separately evaluating divergent upper-end GPLs.
The source/kernel domain must have no unprescribed singularity in the open
integration interval. Primitive construction does not certify that domain;
the GPL numerical evaluator separately rejects unsupported contour poles.
The standalone GPL integrator requires a regular upper matching point and
rejects nonfinite direct substitution. A singular upper limit would require
a new local coordinate with its full GPL connection constants.

Before testing convergence of a complete GPL primitive, rational logarithm
identities are simplified only when their factors have proven positive signs
under the declared assumptions. This allows equivalent logarithms to cancel
without discarding a genuine divergence or guessing a branch.

During rational integration, summands are expanded only in the integration
variable. Repeated GPL words are collected while their coefficients remain
explicit; logarithms and classical polylogarithms are collected as polynomial
atoms before rational coefficient factorization. This avoids forming a large
polynomial in kinematics and transcendental functions together. All steps are
exact algebraic identities; no numerical reconstruction or fitted coefficient
is used.

The lower limit includes the finite term of a rational pole multiplying a
vanishing GPL. It is computed by formal Laurent division of each rational
summand, with coefficients independent of the integration variable kept
outside the recurrence. For numerator coefficients `n_j` and denominator
coefficients `d_j` after removing their leading powers, the quotient obeys
`a_j=(n_j-sum_(i=1)^j d_i a_(j-i))/d_0`. The result is multiplied by the GPL's
finite local power/log expansion. Contributions from all words are added at
each power and log degree before any divergent coefficient is tested for
exact zero; only then is the finite constant subtracted. Thus this operation
is an ordinary convergent limit, not a finite-part prescription.

Classical polylogarithms of rational arguments are pulled back through their
differential equation with their actual finite basepoint values. Unsupported
analytic continuation is reported, never replaced by a guessed branch.
Accepted coefficients contain no `Integrate`, inactive integral, missing
value, or deferred convolution. GPLs are explicit standard special functions.

`ConvolvePartonicInvariantKernel` is independent of source perturbative order.
`ApplyCountertermDistribution` calls it for Born, real, virtual and finite
subtracted sources. `PlanPartonicRenormalization` preserves each leg's
`ConvolutionRequest`, and sequential insertions use that same action.

GPT-6 Pro reviewed the
[maps and endpoint formulas](../External/ChatGPT/Records/2026-09-12/01_invariant_counterterm_unification.md)
and the [rational coefficient representation and endpoint limits](../External/ChatGPT/Records/2026-09-12/02_gpl_rational_coefficients_and_endpoints.md).
The latter confirms the aggregate Laurent/log cancellation rule and distinguishes
a regular upper matching point from a general singular upper endpoint.
