# Pair-coordinate implementation and physical periods — Pro18

Actual ChatGPT6Pro, completed after15m46s:
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84
Exact inspected revision:a46db76779339b4cd7d5a8896876388f8a2f0d09.
The question prohibited published measured NLO EEC coefficients; universal scalar
integral mathematics was allowed. No measured coefficient was supplied or used.

Pro statically inspected normalization, coordinate, pushforward, Euler provider,
tests, coordinate-equivalence, partial equation reuse and typed-cut validation.
It did not execute Wolfram tests or inspect the local RR outputs. Independently,
it checked normalization symbolically and crossed-null/mixed angular formulas
with numerical angular integrals at epsilon=-1/2 (about23 and21 digits).

Confirmed: absolute polynomial-cut Jacobian, labeled phase-space normalization,
physical momentum-frame and positive-energy checks, all-root handling, and the
pure-cut exact beta/Gauss period. No extra symmetry or angular-volume factor.
For dotted cuts C_n(-G)=(-1)^(n-1) C_n(G); the unit-cut equality cannot be used
without that sign for higher powers.

Two guard repairs:
1. Compare the declared integral Dimension after D->4-2epsilon to the chart
   dimension. Typed-cut validation alone does not guarantee this.
2. Coordinate reuse must use cutDefinitionConventions, including Dimension and
   BranchPrescription, not a shorter physical-convention whitelist.
Both repairs are implemented; actual accepted inputs were already compatible.

Additional exact angular-independent periods follow directly from Euler beta
integration. With G=s^2*x1*x2*(z-angle)/2, s_ij=2pi.pj and Q_i=(q-pi)^2,
J_(alpha,beta,gamma)=integral dPhi4 delta(G) s12^-alpha s34^-beta Q1^-gamma is

 2 C(e) s^(-3e-alpha-beta-gamma) z^(-e-alpha)(1-z)^(-e)
 B(1-2e-alpha,1-e-beta) B(1-2e-alpha,2-3e-alpha-beta-gamma)
 2F1(1-2e-alpha,1-2e-alpha;3-5e-2alpha-beta-gamma;z).

Require a common initial convergence domain and the original-product ordinary
prescription certificate before using positive powers. J010 contains the internal
pole B(1-2e,-e). The provider now derives these through the common Euler integrator;
it does not hard-code the displayed formula or a process name.

Recoil angular reduction: s13+s14=2A, s23+s24=2B, Q3+Q4=2L, and
Q4=s12+s13+s23. Affine partial fractions reduce this denominator class to one
massive, two null, or one massive plus one null direction. Keep the introduced
A,B,L,s12 divisors for endpoint analysis. The normalized angular building blocks
are beta quotients, Gauss functions and one-mass Appell F1 functions. Existing
TwoBodyAngularPowers machinery supplies these; do not replace it with process code.
For a massive denominator L+V.n the seed is
 L^-m 2F1(m/2,(m+1)/2;3/2-e;V^2/L^2), with L^2-V^2=s*s12.

An angular-collinear subtraction has exact local term
 -(1-2e)/(2A e) H(n1,e) and remainder <[H(n,e)-H(n1,e)]/s13>.
Other singular directions and overlapping energy endpoints remain. Apply exact
Gauss/Appell connection formulas before treating an endpoint factor as analytic.
Additional prefactor poles can require higher special-function epsilon orders.

For physical constants: close the rational row span of known periods under
L -> dL/dz + L A until rank stabilizes. Known seeds in an autonomous block cannot
fix the remaining blocks. Inclusive moments can remove the measurement without
new energy denominators: for G=A z-B, A>0, define inserted periods with A^(N+1).
Their z^p(1-z)^q moment is the unmeasured period with A^(N-p-q)B^p(A-B)^q;
choose N>=p+q. Establish these on a regulated convergence domain and retain full
endpoint continuation. Reduce both sides with typed IBP, then use generic-epsilon
rank to choose independent equations for only the remaining constants. Do not
impose finiteness of the total observable on individual masters.
