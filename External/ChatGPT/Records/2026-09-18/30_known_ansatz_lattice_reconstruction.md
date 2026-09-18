# Numerical reconstruction in a known coefficient/function ansatz

Actual ChatGPT6 Pro,3m33s, in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
Methods review, not source audit or execution. It received the user's clarified
proposal, production revision f688f459 and methodological paper arXiv:2507.17815.
No measured EEC coefficient was requested or supplied.

Pro explicitly revised its earlier assessment: small known function ansätze make
numerical integer-relation reconstruction a genuine alternative for rational
coefficients and DEs, not just boundary constants. Barrera et al. support this
broader possibility and study the precision/point-count/ansatz-size tradeoff,
without establishing generic superiority over finite fields for IBP coefficients.

Knowing masters I_i only gives T=sum c_i(x,epsilon) I_i. At a nonsingular rational
point, integer relations among numerical T and I_i can recover candidate rational
c_i values. Their functional dependence still needs reconstruction. Specialization
can create extra identities absent generically, and finitely many points cannot
identify unrestricted rational functions.

With c_i=sum a_ia B_ia for a finite supplied rational-function basis, the unknowns
are rational constants and T=sum a_ia [B_ia I_i]. Multipoint LLL can encode a common
relation across samples. At a single rational point even a rational monomial basis
has accidental exact relations (2x-1=0 at x=1/2); more precision cannot remove them.
Use multiple points, justified ansatz/height constraints and exact verification.

Give the modular baseline the SAME ansatz. Much of a speedup could come from
constraining the ansatz rather than changing arithmetic. Compare total sample
generation, recognition and exact-verification costs. Check whether a numerical
evaluator internally calls the very full reduction being reconstructed; specialized
numerical IBP solves are legitimate samples but their full cost must be included.

Candidate acceptance:

- IBP/DE entries: establish identities from the original complete equation system,
  retaining all columns, e.g. E_target-C E_masters=L A_IBP.
- Rational basis transformation J=T I: verify dT+T A_I=A_J T and nonzero determinant.
  Fix gauge freedom; simultaneous unknown T and A_J can make the search nonlinear.
- Functional GPL solution: exact coefficientwise DE residual plus enough independent
  physical boundary/moment conditions to fix all homogeneous modes and branches.
  Include lower-weight terms, constants and rational/algebraic prefactors.

Modular rank/pivot tests have a different role and remain useful; PSLQ is not a
general replacement for them. A single physical solution vector also does not
determine a whole DE matrix by ordinary pointwise numerical linear algebra.

Pro proposes two bounded tests: one10-30-term rational reduction row sampled by
specialized equations, and one small DE block with a justified pole/alphabet ansatz
sampled through derivative reductions. Compare PSLQ, multipoint LLL and ansatz-aware
finite fields. Do not use the withheld formula to generate samples for an end-to-end
speed claim. The current saved-formula microbenchmark is explicitly narrower.

It verified Tschernow's thesis abstract discusses ansatz-based DE reconstruction
from few samples, but could not retrieve Appendix C; its PSLQ/O(30) claim was not
independently verified. The related published work uses finite fields.
