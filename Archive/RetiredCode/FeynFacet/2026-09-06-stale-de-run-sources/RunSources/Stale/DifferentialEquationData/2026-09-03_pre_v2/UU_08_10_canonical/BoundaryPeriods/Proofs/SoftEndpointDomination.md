# The soft-endpoint domination lemma

Exact zero proof for the free (`s^0`) Frobenius mode of boundary periods
1 (CF1), 6 and 7 (CF124), at the soft stratum `s = 1-v-w -> 0`.

This is the analytic argument Codex asked for in
`Exchange/Codex/2026-08-15/02_assessment_of_fable_round6.md`
sections 3.2 and 3.3, adapted to cover period 1 as well (their section 3.1).
It replaces the numeric branch identification recorded by the pilot.

Every step below is verified symbolically by
`../Scripts/verify_soft_domination.wls`; the tags `[K1]`, `[L1]`, ... name
the corresponding acceptance lines. Inequalities are decided by `Resolve`
over the reals (exact quantifier elimination), not by sampling. **No
numerical substitution occurs anywhere in this chain.**

## 0. Setting

Physical chamber: `0 < v`, `0 < w`, `v + w < 1`, `s = 1-v-w`,
`P = ka+kb-kc`, `P^2 = s`, all external momenta massless,
`2 ka.kb = 1`, `2 ka.kc = v`, `2 kb.kc = w`.

Each of the three periods is a 3-particle massless cut phase-space integral
of `P` carrying exactly one uncut denominator. In the rest frame of `P`,
writing the selected cut momentum as `q = E(1, nhat)` with `E = M x/2`,
`M = Sqrt[s]`, `x in (0,1)`, and `cos(th) = 1-2y` the polar angle of `nhat`
measured from the reference direction appearing in that period's uncut
denominator,

```
dmu = x^(1-2 eps) (1-x)^(-eps) (y(1-y))^(-eps) dx dy
```

up to an `x,y`-independent factor that cancels in the ratio below. The
kernels are

```
CF1   (PID 1)    J   = v + x s - x (v+s) y          (= -D3, D3 = (kc-ka+kf)^2)
CF124 (PID 6,7)  D5  = 1 - x s - x (1-s) y          (= (ka+kb-q)^2)
```

Both the kernels and the measure exponents are re-derived symbolically from
the Kira family definitions in
`../Scripts/verify_parametric_representation.wls` `[R1-R4, C1-C3, M1-M5]`,
so no link of this chain rests on the pilot's hand derivation.

The measured object in each case is the normalized ratio

```
R(s) = +- N(s) / Int dmu ,      N(s) = Int_[0,1]^2 dmu / D(s)
```

with `D = J` or `D = D5`. `Int dmu = B(2-2 eps, 1-eps) B(1-eps, 1-eps)` is
exact, nonzero and independent of `s`.

## 1. Corner coordinates linearize both kernels

Set `u = 1-x`, `t = 1-y`. Then, exactly (not asymptotically),

```
J   = v u + (1-u)(v+s) t                                            [K1]
D5  =   u + (1-u)(1-s) t                                            [K2]
dmu = (1-u)^(1-2 eps) u^(-eps) (1-t)^(-eps) t^(-eps) du dt
```

Both kernels have the single form `alpha u + beta (1-u) t` with
`alpha, beta > 0`, and both vanish only at the corner `u = t = 0`
(equivalently `x = y = 1`). That corner is the whole analytic content of
these periods.

## 2. Lemma 1 (the geometric inequality)

> For `(u,t)` in the unit square, `u + (1-u) t >= (u+t)/4`, with equality
> only at `u = t = 0`. `[L1, L1b]`

*Proof.* Write `F = u + (1-u)t - (u+t)/4 = (3/4) u + (3/4 - u) t`. If
`u <= 3/4` both terms are nonnegative. If `u > 3/4` the coefficient of `t`
is negative, so `F` is minimized at `t = 1`, where `F = 3/4 - u/4 >= 1/2`.
Hence `F >= 0`, and `F = 0` forces `u = 0` and then `t = 0`. □

The constant `1/4` is not optimal but is uniform, which is all that is
needed; `[L1b]` records that no interior contact exists.

## 3. Lemma 2 (uniform lower bound on the kernel)

> With `m = min(alpha, beta) > 0`,
> `alpha u + beta (1-u) t >= m (u + (1-u) t) >= (m/4)(u + t)`. `[L2]`

Instances, each decided directly by quantifier elimination:

| period | `alpha` | `beta` | `m` | bound | uniform in `s` on |
|---|---|---|---|---|---|
| 1 | `v` | `v+s` | `v` | `J >= (v/4)(u+t)` `[L3]` | **all** `s >= 0` |
| 6, 7 | `1` | `1-s` | `1-s` | `D5 >= ((1-s0)/4)(u+t)` `[L4]` | `0 <= s <= s0 < 1` |

The asymmetry is real and worth recording: for CF1 the coefficient `v+s`
*grows* with `s`, so the bound needs no upper cutoff; for CF124 the
coefficient `1-s` *degrades* as `s -> 1`, so an `s0 < 1` must be fixed.
Since we only take `s -> 0`, any fixed `s0 in (0,1)` serves.

## 4. Lemma 3 (dominating function and its exact bound)

Let `sig = Re[eps]`. For `z in (0,1)`, `|z^(-eps)| = z^(-sig)`. Using
Lemma 2 and then AM-GM `u + t >= 2 Sqrt[u t]` `[D1]`,

```
| dmu / D | <= (1/(2m)) u^(-sig-1/2) (1-u)^(1-2 sig)
                        t^(-sig-1/2) (1-t)^(-sig)  du dt  =:  G
```

`G` is independent of `s`, and separates, so it integrates in closed form:

```
Int G = (1/(2m)) B(1/2 - sig, 2 - 2 sig) B(1/2 - sig, 1 - sig)     [D2, D3]
```

which is finite **exactly** for `sig < 1/2` `[D4]`. The binding condition
comes from the corner; the two edges `u -> 0`, `t -> 0` would only require
`sig < 1`.

## 5. Proposition (finiteness and continuity at the soft stratum)

> For `Re[eps] < 1/2`, `N(s)` is finite for every `s` in the range of
> Lemma 2, `|N(s)| <= Int G` uniformly, and `N` is continuous at `s = 0`.

*Proof.* The integrand is measurable and, by Lemma 3, dominated by the
`s`-independent `G in L^1([0,1]^2)`. Finiteness and the uniform bound are
immediate. As `s -> 0+` the integrand converges pointwise a.e. to its value
at `s = 0`, so dominated convergence gives `N(s) -> N(0)`. □

Hence `R(s) = +- N(s)/Int dmu` is **bounded** as `s -> 0+`.

## 6. Corollary (the free mode has zero coefficient)

The block is lower-triangular with the phase-space volume
`V = c(eps) s^(1-2 eps)` as its only lower partner, so `R = M/V` obeys a
scalar inhomogeneous ODE whose soft stratum `s = 0` is a regular singular
point with indicial exponents `{0, 2 eps - 1}`. Its general solution is

```
R(s) = R_part(s) + A(eps) * s^(2 eps - 1) * (1 + O(s)),
```

with `R_part` analytic at `s = 0` and `R_part(0)` the DE-forced soft value.

For `Re[eps] < 1/2` the free mode is unbounded, `|s^(2 eps-1)| = s^(2 sig-1)
-> Infinity` `[B1, B2]`. By the Proposition `R` is bounded, so

```
A(eps) = 0   for every eps with Re[eps] < 1/2.
```

`A` is meromorphic in `eps`, and vanishes on a nonempty open subset of the
`eps` plane, so `A === 0` identically by the identity theorem. □

**The two conditions coincide.** The domination requires `Re[eps] < 1/2`
and the free mode is unbounded precisely when `Re[eps] < 1/2`. There is no
gap between hypothesis and conclusion, and no region where the argument
would have to be patched by a separate estimate.

In terms of the master itself, `M = R V` and
`A s^(2 eps-1) * V ~ s^0`: the free mode of `M` at the soft stratum is the
`s^0` Frobenius mode, which is exactly the boundary period. So `A = 0` is
the statement that the period vanishes.

## 7. Why this is not circular

The pilot flagged the trap (`../QFPilotReport.md` section 3.2) and it is
worth restating, because the obvious argument is invalid.

Since `R = M/V` and `V ~ s^(1-2 eps)`, the period `A` appears *in `R`* as
the divergent piece `A s^(2 eps-1)`. Therefore "`R` is finite at the soft
stratum" and "`A = 0`" are the *same statement*. Any derivation that fixes
the integration constant by demanding soft-finiteness and then concludes the
period vanishes has assumed its conclusion. Equivalently: the differential
equation alone cannot determine `A`, which is why the period is on the
undetermined list at all.

The chain above never uses the differential equation to fix `A`, and never
uses the closed form (which was itself *derived* under `A = 0`). It bounds
the parametric integral directly, from an explicit `s`-independent
dominating function, and reads the branch structure off the indicial
exponents. The DE supplies only the *shape* of the general solution.

## 8. The reconstruction check, without numerics

The argument bounds a parametric integral, so it is only worth as much as
the claim that this integral *is* the master. The pilot supported that with
~30-digit agreement. It is provable exactly.

At `s = 0` both kernels collapse to the same integral `[S0]`:
`J|_{s=0} = v(1-xy)` and `D5|_{s=0} = 1-xy`. Then

1. the `y` integral is Euler's representation,
   `Int_0^1 y^(-eps)(1-y)^(-eps)/(1-xy) dy
      = B(1-eps,1-eps) 2F1(1,1-eps;2-2eps;x)`, for `Re[eps] < 1` `[S1]`;
2. the `x` integral, termwise on that series, gives
   `B(n+2-2eps,1-eps) = B(2-2eps,1-eps) (2-2eps)_n/(3-3eps)_n` `[S2]`;
3. the `(2-2eps)_n` factors cancel, collapsing the resulting `3F2` to
   `2F1(1,1-eps;3-3eps;1)` `[S3]`;
4. Gauss's theorem at unit argument, valid for
   `Re[c-a-b] = Re[1-2 eps] > 0`, gives
   `Gamma[3-3eps]Gamma[1-2eps]/(Gamma[2-3eps]Gamma[2-2eps])
      = (2-3eps)/(1-2eps)` `[S4a, S4b]`.

Hence `N(0) = Int dmu * (2-3 eps)/(1-2 eps)` exactly, so

```
R_124(0) = (2-3 eps)/(1-2 eps),     R_1(0) = -(2-3 eps)/(v (1-2 eps)).
```

Both agree with the values forced by Kira's IBP-reduced connection read from
the repository DE artifacts `[S5d, S6, S7]`. This is a genuine cross-check
of the reconstructed integrand against IBP, and it is numerics-free.

Note that Gauss's convergence condition `Re[eps] < 1/2` is again the same
half-plane as the domination and the branch separation.

## 9. What numerics are still recorded, and where

Nothing in sections 1-8 uses them. The pilot's ~30-digit evaluations are
retained in the ledger entries as *independent checks* only, satisfying item
5 of Codex's reproducibility list and the numerics policy in
`Design/Stage3BoundaryToolchain.md`.

## Expected results

`../Scripts/verify_soft_domination.wls` prints 26 `[OK]` lines and

```
SOFT_DOMINATION_EXACT = True
```

`../Scripts/verify_parametric_representation.wls` prints 12 `[OK]` lines and

```
PARAMETRIC_REP_EXACT = True
```
