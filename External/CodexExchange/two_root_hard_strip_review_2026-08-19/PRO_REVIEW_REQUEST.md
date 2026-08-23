# Request: diagnose the last two unresolved two-root epsilon-form classes

We are constructing exact analytic master integrals for an NNLO double-real
QCD calculation.  The differential systems are rationalized, flat, and
block-lower-triangular.  All diagonal blocks are already in epsilon form.  At
this point only two inequivalent two-root classes remain unresolved:

1. the Kallen-23 class, represented by family `CF231`, with the first hard
   off-diagonal block pair `(8,7)`; `CF305` is related to the same class by an
   exact family transformation;
2. the Kallen-13 class, represented by family `CF254`, with the first hard
   off-diagonal block pair `(9,8)`; `CF265` is related to the same class by an
   exact family transformation.

The attached archive contains the current implementation, the exact charts,
the exact hard-strip data, and the measured logs.  Please inspect the files,
not just this summary.

## Mathematical problem

Let the upper and lower diagonal blocks already be in epsilon form,

\[
 dF_E=\epsilon\,\Omega_E F_E,\qquad
 dF_C=\epsilon\,\Omega_C F_C,
\]

and let the off-diagonal one-form be

\[
 \overline B=\sum_{\mu=1}^{2}\overline B_\mu\,dz_\mu .
\]

For this strip we seek a rational matrix (R(z_1,z_2,\epsilon)) and constant
matrices (K_a) such that

\[
 \partial_\mu R-
 \epsilon\bigl(E_\mu R-RC_\mu\bigr)
 =\overline B_\mu-
 \epsilon\sum_a K_a\,\partial_\mu\log W_a,
 \qquad \mu=1,2.
\]

Here (E_\mu) and (C_\mu) are the two diagonal epsilon-form connections and
(W_a) are irreducible polynomial letters in the rationalized chart.  The
code first solves the exact compatibility equations for the constant
residues (K_a).  It then solves the resulting inhomogeneous rational system
for (R), first in one variable and finally checks both equations exactly.

## Rationalized charts

The two square roots are rationalized simultaneously before the strip solve.
The exact substitutions and square identities are in `TransportCharts.wl`.
The unresolved representatives use:

- `CF231`: `Kallen23`, with chart variables `(y,s)`;
- `CF254`: `Kallen13`, with chart variables `(y,s)` and an exported hard-strip
  record in variables `(x,y)` after chart composition.

Both chart identities were checked exactly.  The transformed Pfaffian systems
are flat, and their diagonal blocks satisfy the epsilon-form identities.

## Methods already attempted

### Whole-family and blockwise routes

- Complete-sector CANONICA was attempted first.
- When that did not find a transformation, individual off-diagonal strips
  were attempted with CANONICA numerator degrees `0,1,2,3`, denominator degree
  `0`, and 120 seconds per degree.
- Libra transformations (`FuchsifyFinite`, `FuchsifyInfinity`, and
  `FactorOut` where applicable) were attempted in both chart variables.
- These routes solved the other two-root classes, but not the two classes
  above.

### Current exact Maple route

`SolveResidueRationalGauge` performs the following steps.

1. Construct a constant-residue dlog ansatz from every irreducible polynomial
   letter of the strip.
2. Solve the exact two-variable compatibility equations for those residues.
3. For each choice of first variable, call Maple
   `IntegrableConnections:-Mratsolde(A_i,z_i,b_i)`.
4. If that returns no solution, use

   \[
   R_j(z_i)=
   \frac{\sum_{k=0}^{\deg_{z_i}D+q}a_{jk}z_i^k}{D(z_i)},
   \qquad
   D(z_i)=\left(\prod_{W_a\,:\,\partial_{z_i}W_a\ne0}
   W_a\right)^p,
   \]

   with (p\in\{1,2,3\}) and (q\in\{0,1,2\}).
5. Substitute a candidate into both Pfaffian equations and into the complete
   transformed dlog identity using exact rational arithmetic.

For `CF254 (9,8)` and `CF265 (14,13)`, both variable orientations reached
Maple.  The enclosing jobs ended after about 3740 seconds.  For `CF231 (8,7)`,
the first orientation returned no result before the job was interrupted; the
second orientation was not completed.  A separate standardized `CF254` run
spent 16854 seconds before reporting no exact gauge.

Important limitation: the Maple script writes its candidate ledger only after
the complete nested search.  The enclosing timeout killed several runs before
that write.  Therefore these records do **not** establish that every
((p,q)\in\{1,2,3\}\times\{0,1,2\}) candidate was actually solved and rejected.
They establish only that the requested finite search did not return a checked
gauge within the allotted time.

## Questions requiring a concrete answer

1. **Is the isolated-strip equation mathematically complete?**  Once every
   diagonal block is in epsilon form, must an epsilon-form transformation
   exist as a sum of independently solvable off-diagonal strip gauges, or can
   the required lower-triangular transformation couple several source blocks
   in one row?  If coupling is possible, write the coupled equation that
   should replace the isolated-strip solve and identify the smallest row of
   blocks that must be solved together.

2. **Can existence of a rational strip gauge be decided before an ansatz
   sweep?**  Please formulate the relevant local-residue, differential-module,
   or cohomological criterion.  We want an exact certificate of either:
   - existence, together with denominator and numerator-degree bounds; or
   - nonexistence within rational functions in the chosen chart.

3. **How should the denominator divisor be derived?**  Is
   (D=(\prod_aW_a)^p) unnecessarily large or incomplete?  Give a method to
   determine pole orders separately at each letter, including infinity, from
   local exponents or residue equations.  State whether apparent letters or
   factors introduced by the chart must be excluded or assigned different
   powers.

4. **Does failure in one-variable integration diagnose anything?**  Is it
   sound to solve
   (partial_{z_1}R-A_1R=b_1) over the field
   (mathbb Q(z_2,\epsilon)(z_1)), then impose the second equation?  If both
   orientations fail, does that imply the absence of a rational two-variable
   solution, or can a rational solution still be missed by `Mratsolde` and the
   finite denominator ansatz?

5. **Which established method is best for this exact extension problem?**
   Compare, specifically for these attached systems:
   - CANONICA's off-diagonal recursion;
   - Libra's dependent-block transformations;
   - Maple `IntegrableConnections`;
   - a coupled sparse linear system over a rational-function field, solved by
     modular exact linear algebra and rational reconstruction;
   - any method used in published multiloop differential-equation work that
     we have omitted.

6. **What is the next decisive calculation?**  Give a prioritized procedure
   that distinguishes these possibilities with minimal wasted runtime.  We
   especially need to know whether to:
   - instrument and complete the ((p,q)) candidate grid;
   - infer sharp pole bounds and solve one sparse exact linear system;
   - solve a coupled block row instead of one strip;
   - change gauge or rationalizing chart;
   - test for a non-polylogarithmic obstruction.

7. If you recommend a sparse modular solve, specify the unknowns and equations
   and explain how to retain the complete affine solution space rather than a
   single particular solution.  If you recommend a different tool, give the
   exact mathematical input it requires.

Please challenge any premise that is mathematically wrong.  Do not merely
recommend longer time limits or higher degrees.  We need a reasoned diagnosis,
a finite test sequence, and explicit alternatives.  Cite only references you
can identify precisely; do not invent citations.
