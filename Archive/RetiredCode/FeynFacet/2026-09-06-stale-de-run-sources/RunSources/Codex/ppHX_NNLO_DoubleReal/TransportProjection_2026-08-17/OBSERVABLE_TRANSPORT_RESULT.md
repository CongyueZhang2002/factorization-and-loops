# Observable-only transport after Laurent valuation

## Problem

The exact canonical system is

\[
  dF(\epsilon,z)=\epsilon\sum_a R_a\,d\log\phi_a(z)\,F(\epsilon,z),
  \qquad I(\epsilon,z)=T(\epsilon,z)F(\epsilon,z).
\]

The calculation requires selected components of (I_n) for
(n=0,1,2), not every component of (F) through the largest order that
can occur in an intermediate block.  For CF299 and CF407, transporting the
complete block chain first creates weight-four and weight-five words that
cancel after the physical Laurent conditions are imposed.

## Exact reduction before transport

Write the finite collection of Laurent coefficients of (F) that can enter
the requested coefficients as one vector (X).  Its differential equation is

\[
  dX=\sum_a \mathcal R_a\,d\log\phi_a\,X,
\]

where (mathcal R_a) lowers the Laurent order by one.  The forbidden physical
coefficients (I_n), (n<0), define a rational matrix (D(z)) through

\[
  I_{n<0}=D(z)X.
\]

Along the chosen first-variable path, close the rows of (D) under the dual
connection,

\[
  q\longmapsto \frac{dq}{d\tau}+q\mathcal A_{\mathrm{lift}}(\tau).
\]

At the base point this gives exact constraints on the boundary coefficients,

\[
  C(z_2)c(z_2)=0,
  \qquad c(z_2)=N(z_2)b(z_2),
  \qquad C(z_2)N(z_2)=0.
\]

All entries are rational functions over (mathbb Q(z_2)).  No numerical
kinematic value enters the kernel (N).

The demanded weight-(r) map is then formed directly as

\[
  M_{a_1\ldots a_r}(z)=
  P\,T(z)\,\mathcal R_{a_1}\cdots\mathcal R_{a_r}N(z_2),
\]

where (P) selects the requested master rows and epsilon orders.  A word is
written only when this matrix is nonzero.  The calculation therefore never
constructs an undemanded transformed master.

## Exact results

| Family | Boundary coefficients | Rank of (C) | Free boundary coordinates | Exact reachable ranks, weights 0--5 | Physical dlog words, weights 0--3 | GPL words, weights 0--3 |
|---|---:|---:|---:|---|---|---|
| CF27 | 12 | 8 | 4 | 28, 24, 16, 8, 0, 0 | 1, 2, 4, 6 | 1, 2, 4, 6 |
| CF299 | 31 | 13 | 18 | 84, 73, 52, 31, 9, 3 | 1, 5, 26, 48 | 1, 5, 29, 50 |
| CF407 | 35 | 24 | 11 | 83, 71, 47, 23, 0, 0 | 1, 8, 57, 291 | 1, 9, 68, 338 |

For CF299 the constrained state still has dimensions (9) and (3) at
weights four and five, but its projection onto every requested physical
coefficient is identically zero.  CF299 therefore needs the physical
projection during transport.  For CF407, the constrained state itself is zero
from weight four onward.

The field-level statements were checked exactly over (mathbb Q(z_1,z_2)).
Two independent prime fields were also used to count nonzero word matrices;
the counts agreed.

## Independent completed-family check

CF27 provides a completed calculation with the same structure.  After mapping
the boundary coordinates to the stored `TransportConstant` basis and converting
the three active dlog letters to the stored GPL poles, the new construction was
compared with both demanded masters at (epsilon^0,epsilon^1,epsilon^2).
All six symbolic residuals are exactly zero.  This checks the word orientation,
endpoint map, boundary kernel, Laurent orders, and GPL conversion.

The sparse GPL records have sizes 121 kB for CF299 and 2.6 MB for CF407.
Contracting them with symbolic boundary coordinates takes 0.005 s and 0.11 s,
respectively, in Mathematica.  The resulting unevaluated analytic expressions
occupy 1.1 MB and 26.0 MB.  No whole-expression `Together` is applied: each
rational matrix entry is already cancelled, while GPL words remain separate.

## Polynomial dlog letters and branches

The compact record keeps words in the polynomial dlog alphabet.  Only after
the physical projection is complete is each path kernel factorized:

\[
  \frac{d}{d\tau}\log\phi_a(z(\tau))
  =\sum_j\frac{m_{aj}}{\tau-\alpha_{aj}}.
\]

This converts the result to ordinary GPL words.  A quadratic letter contributes
both algebraic roots.  Exchanging the two roots only permutes terms in their
complete sum, so the polynomial dlog expression is the branch-independent
primary record.  A later physical evaluation must still use the chart's stated
square-root branch.

## Files

- `PreTransportValuation.py`: exact Laurent kernel, reachable-space calculation,
  observable dlog maps, and GPL conversion.
- `PreTransportValuationKernel_CF*.wl`: exact (C) and (N) matrices.
- `ObservableTransport_CF*.wl`: sparse physical word matrices and certificates.
- `ObservableTransportConsumer.wl`: contracts a record with analytic boundary
  values and returns an association keyed by `{epsilon order, master row}`.
- `ValidateCF27AgainstStored.wls`: exact comparison with the completed CF27
  result.

The prototype remains isolated from FeynFacet.  The next package change should
insert the same reduction between epsilon-form construction and blockwise word
generation, while retaining the full transport as an optional cross-check on
small families.
