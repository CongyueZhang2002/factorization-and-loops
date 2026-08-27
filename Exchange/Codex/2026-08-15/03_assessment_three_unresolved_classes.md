# Codex assessment of Fable's implementations for classes 97, 77, and 79

Date: 2026-08-15

## Criterion used here

A hard differential-equation class is called **physically determined** only
when all of the following have been obtained:

1. the complete master vector, including lower-sector inhomogeneous terms;
2. both differential equations in the two independent kinematic variables;
3. the physical boundary constants and branch prescription;
4. the exact endpoint modes needed before plus-distribution expansion; and
5. an independent numerical comparison at physical kinematic points.

Vanishing of a scalar-ODE residual is a necessary intermediate result, but it
does not by itself determine the physical master vector.

## Shared epsilon-graded construction

`Scripts/EpsilonGraded.wl` expands the monic scalar operator as

\[
L_x(\epsilon)=L_{x,0}+\epsilon L_{x,1}+\epsilon^2 L_{x,2}+\cdots
\]

and uses the exact first-order factorization

\[
L_{x,0}=(\partial_x-r_4)(\partial_x-r_3)
        (\partial_x-r_2)(\partial_x-r_1)
\]

to determine a particular solution recursively. At order \(n\), the general
scalar result is

\[
f_n(x,y)=f_n^{\mathrm{part}}(x,y)
 +\sum_{a=1}^{4}c_{n,a}(y)h_a(x,y),
\]

where the four \(h_a\) span \(\ker L_{x,0}\). The current implementation
computes \(f_n^{\mathrm{part}}\) and the \(h_a\), but does not determine the
functions \(c_{n,a}(y)\). They must be fixed by the second differential
equation, up to true constants that are fixed by physical boundary data.

The existing test file contains nine assertions. All nine were satisfied on
2026-08-15. Their mathematical scope is:

- exact differentiation of the GPL primitive engine;
- exact recomposition of the three \(\epsilon=0\) factor chains; and
- rational stage weights for class 97.

The test file does not insert the scalar solutions into the second
differential equation, reconstruct the four-master vectors, or impose
physical boundary conditions.

## Independent residual calculations

I reloaded the stored scalar solutions, reconstructed the graded operators
from their stored symbolic coefficients, and recomputed the residual at each
order rather than trusting the stored Boolean values. The results were

| class | order | exact scalar residual | verification time |
|---|---:|---:|---:|
| 97 | \(\epsilon^1\) | 0 | 0.10 s |
| 97 | \(\epsilon^2\) | 0 | 2.26 s |
| 97 | \(\epsilon^3\) | 0 | 45.21 s |
| 77, charted | \(\epsilon^1\) | 0 | 0.14 s |
| 77, charted | \(\epsilon^2\) | 0 | 4.01 s |
| 77, charted | \(\epsilon^3\) | 0 | 85.70 s |

Thus the stored one-variable continuations for classes 97 and 77 are genuine
solutions of their respective homogeneous scalar equations through
\(\epsilon^3\).

## Class 97: CF258_B9

Established:

- The \(\epsilon=0\) fourth-order scalar operator recomposes exactly from
  four first-order factors.
- One rational kernel mode has been continued through \(\epsilon^3\).
- Every graded scalar residual through \(\epsilon^3\) vanishes identically.
- The resulting GPL alphabet is
  \(\{0,1,-y,y/(y-1),y\}\).

Still required:

- reconstruct the four-component CF258 master vector from the cyclic scalar
  variable;
- include any source from lower differential-equation sectors;
- determine the four functions \(c_{n,a}(y)\) from the \(y\)-equation;
- fix the remaining constants from physical boundary data;
- reconstruct unexpanded endpoint modes; and
- compare the resulting physical masters with AMFlow.

The stored generation times for the successive nontrivial orders were
0.15 s, 88.52 s, and 742.09 s. Codex's independent sparse-GPL recursion was
substantially faster on this class, although the two calculations currently
use different scalar gauges. A system-level comparison is therefore needed
before identifying their scalar expressions term by term.

## Class 77: CF230_B1

Established:

- The original-variable \(\epsilon=0\) operator has an exact four-factor
  decomposition, but its third-stage integrating factor contains an apparent
  sextic and is rejected by `EGChainData`.
- A charted operator, stored as `eps0_c77x_chart_factored.wl`, has rational
  stage weights accepted by the quadrature engine.
- One charted scalar mode has been continued through \(\epsilon^3\), with
  exact vanishing residuals at all three orders.
- Its GPL alphabet is \(\{0,1,2-y,1/y,y\}\).

The charted calculation is substantial progress, but its current record is
not reproducible from the committed driver:

- `eps0_c77x_chart_factored.wl` and `c77x_egsolve.wl` are untracked;
- the forward and inverse chart maps are not stored with the result;
- the script that creates the charted scalar operator and invokes `EGSolve`
  is absent; and
- the README still states that class 77 has not been continued.

Without the chart map and cyclic reconstruction data, the charted scalar
answer cannot yet be transported reliably back to the physical CF230
masters. Its Hlog alphabet also contains the moving letter \(x=y\); whether
this letter crosses the integration path depends on the physical chart
chamber, which is currently not recorded.

## Class 79: CF231_B1

Established:

- The \(\epsilon=0\) scalar operator recomposes exactly from four first-order
  factors.

Not established:

- `EGChainData` rejects the current chain because of its apparent sextic;
- there is no charted clean factor chain in the result directory;
- there is no epsilon-graded scalar continuation; and
- the scalar reduction and chart transformations are not retained in the
  factor file.

Class 79 is therefore the least developed of the three. The immediate task is
to retain an explicit rationalizing chart and derive a factor chain whose
stage weights have a controlled rational alphabet. The previously derived
balance that removes the epsilon-dependent apparent singularity should not be
applied before a rational-ansatz search: Fable's measured timings showed that
it enlarges the rational expressions and makes CANONICA slower. If no clean
chart/gauge is found, the maximal-cut Picard--Fuchs route remains the relevant
alternative.

## Implementation findings

1. `EGSolve` accepts only a homogeneous scalar operator and one seed mode. It
   has no argument for the second differential equation, a lower-sector
   source, boundary data, or an endpoint-mode basis.
2. The returned string `"Status" -> "OK"` means only that the selected scalar
   residuals vanish. It must not be interpreted as a physically determined
   master class.
3. The quadrature convention selects primitives with implicit integration
   constants, but no physical base point, path, or branch is stored.
4. Differentiation of Hlog words is implemented only with respect to their
   integration variable. Pinning the arbitrary functions with the second
   equation requires derivatives with respect to the parameter-dependent
   letters as well.
5. The HyperIntica location is hard-coded as
   `/home/maxzhang/.Wolfram/Paclets/Repository/SubTropica-1.2.9/HyperIntica.wl`.
6. The finite specialized `ore_algebra` calculations give strong evidence for
   generic irreducibility, but finitely many specializations alone are not a
   symbolic irreducibility proof for classes 77 and 79.

## Recommended next calculation

Do not spend time extending the stored particular solutions to another order
in \(\epsilon\) yet. The missing common step for classes 97 and 77 is the
two-variable completion:

1. store the chart, cyclic covector, and scalar-to-vector reconstruction
   matrix with each result;
2. reconstruct the four-component particular vector;
3. write
   \(\mathbf I_n=\mathbf I_n^{\mathrm{part}}
   +\sum_a c_{n,a}(y)\mathbf h_a\);
4. substitute this expression into
   \(\partial_y\mathbf I=A_y\mathbf I+\mathbf S_y\);
5. solve the resulting equations for the \(c_{n,a}(y)\), checking their
   compatibility exactly;
6. impose the physical boundary periods and branch chamber; and
7. compare the completed master vector with AMFlow.

For the one-variable quadratures of classes 97 and charted 77, retain Fable's
exact factor chains and residual identities but investigate replacing the
current primitive layer by the sparse GPL word recursion. For class 79, first
obtain and retain the clean charted factor chain.

Under the criterion stated at the beginning, the current count is **zero of
three physically determined classes**. Classes 97 and 77 each have one exact
homogeneous scalar continuation through \(\epsilon^3\); class 79 currently
has only its \(\epsilon=0\) scalar factorization.
