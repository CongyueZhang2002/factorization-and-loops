# Transport-checker diagnosis, 2026-08-18

## Result

The reported failures of CF21, CF50, CF53, CF248, and CF253 do not establish
an under-ordered transport series. They arise from two omissions in the
sampled original-equation check. With both corrected, the unchanged transport
algorithm gives `TrueWhereCheckable` for all five families.

The blanket `lowPad = 2` experiment therefore tested the wrong hypothesis. It
increased the attainable iterated-integral weight of every block and cost more
than 25 times the unpadded calculation, while the unpadded results already
satisfy the original differential equation at every order that the stored
series permits one to evaluate.

## Residual being tested

Along the path

\[
  x(\tau)=x_0+\tau\,\Delta x,
  \qquad
  y(\tau)=y_0+\tau\,\Delta y,
\]

write

\[
  A_\tau(\tau,\epsilon)
  =\Delta x\,A_x(x(\tau),y(\tau),\epsilon)
   +\Delta y\,A_y(x(\tau),y(\tau),\epsilon)
  =\sum_r \epsilon^r A_{\tau,r}(\tau)
\]

and

\[
  I(\tau,\epsilon)=\sum_n \epsilon^n I_n(\tau).
\]

At a rational sample point \(\tau=\tau_0\), the coefficient residual is

\[
  R_n(\tau_0)
  =\left.\frac{d I_n}{d\tau}\right|_{\tau_0}
   -\sum_r A_{\tau,r}(\tau_0) I_{n-r}(\tau_0).
\]

Every factor in both terms must therefore be evaluated at the same
\(\tau_0\).

## Two checker defects

1. The earlier randomization rules were generated from the transported
   solution but not from the path matrices and endpoint variables. The saved
   CF50 diagnostic consequently reported residuals containing `{x,y}`. These
   are unevaluated expressions, not nonzero residuals.

2. After the first correction, the right-hand side still used

   ```wl
   series["I"][[nn - r - o0 + 1]] /. smp["WordRules"]
   ```

   while the matrix and left-hand side had already been evaluated at
   `tau -> smp["Tau"]`. The required expression is

   ```wl
   series["I"][[nn - r - o0 + 1]] /.
     smp["WordRules"] /. tau -> smp["Tau"]
   ```

The current shared `Scripts/sweep_transport.wls` contains the first correction
but, at the time of this note, not the second one.

## Independent calculations

The tests below used a temporary copy of the sweep driver differing from the
current shared driver only by the missing `tau` substitution above. No lower
padding was used, and no transport data were copied into the production
directory.

| Family | Wall time | Maximum weight | Maximum words | Original-DE result |
|---|---:|---:|---:|---|
| CF21  | 21 s  | 5 | 4519 | `TrueWhereCheckable` |
| CF50  | 205 s | 5 | 6832 | `TrueWhereCheckable` |
| CF53  | 174 s | 5 | 6697 | `TrueWhereCheckable` |
| CF248 | 17 s  | 4 | 1353 | `TrueWhereCheckable` |
| CF253 | 73 s  | 5 | 6693 | `TrueWhereCheckable` |

For CF50, every available residual at orders \(\epsilon^0\) and
\(\epsilon^1\) vanishes exactly at all three rational sample points. The
higher requested checks report `InsufficientOrders`, not a nonzero residual.
The reason is the \(\epsilon^{-2}\) part of the original differential
equation: checking \(R_n\) requires \(I_{n+2}\). This is missing *upper*
series coverage and is unrelated to extending the lower end of the
transformed-basis series.

The Libra messages in the CF21, CF248, and CF253 mission wrappers are only the
package's obsolete-interface warning; they do not occur in the residual
calculation.

## Why positive powers in `TTotal` do not imply the proposed lower padding

For

\[
  I=T(\epsilon)F,
  \qquad
  T(\epsilon)=\sum_k \epsilon^k T_k,
\]

the coefficient is

\[
  I_n=\sum_k T_k F_{n-k}.
\]

The largest transformed-basis order needed to obtain a requested upper order
\(n_{\max}\) is controlled by the smallest Laurent order of the relevant
entries of \(T\), exactly as in `blockDemands`. The lower transformed-basis
valuation follows from

\[
  F=T^{-1}I
\]

and the smallest Laurent orders in the corresponding rows of \(T^{-1}\), as
used by `blockLowerOrders`. Positive powers in \(T\) select lower coefficients
of \(F\); they do not by themselves prove that coefficients below the
`TTotalInverse` valuation are nonzero.

If a concern remains about constants of the general solution below the
physical valuation, it needs a separate mathematical counterexample: an
explicit omitted coefficient that changes a demanded physical master after
the valuation equations are imposed. The saved CF50 residual does not provide
one, and the corrected calculation gives exact zeros wherever evaluation is
possible.

## Recommended production action

1. Add `/. tau -> smp["Tau"]` to the right-hand-side series coefficient.
2. Regenerate the five families with `lowPad = 0`.
3. Keep `InsufficientOrders` distinct from a nonzero residual.
4. If original-equation checks are required through the last delivered order,
   extend the *upper* transport window by the pole depth of the original
   differential equation. Do this only for verification, because the exact
   block-recursion and map-back identities already determine the delivered
   coefficients and the extra weight is expensive.
5. Retain the exact block-recursion, transformation, valuation, and Phi
   certificates. The rational-point residual check uses exact arithmetic but
   samples finitely many points; it is a strong independent test, not a
   symbolic identity proof unless accompanied by a degree bound.
