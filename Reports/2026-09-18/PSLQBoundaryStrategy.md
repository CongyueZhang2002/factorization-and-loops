# PSLQ as a possible physical-boundary method

The user suggested high-precision numerical PSLQ as a potential speedup. No
production reconstruction method has been replaced and no speedup is yet measured.
Actual GPT-6 Pro review is pending against pushed f688f4596f0e184fc81e45031ea6049e6bcde80e.

Three different tasks must be distinguished:

| Object | Current or proposed approach | Assessment |
|---|---|---|
| Rational functions of kinematics and dimension in IBP/DE relations | Kira/FireFly finite-field interpolation and rational reconstruction | Retain; floating-point PSLQ would still need functional support and adequate precision for rational recovery. |
| Physical boundary Laurent coefficients | Direct physical periods or continued moment constraints, possibly followed by PSLQ | Useful candidate for a bounded pilot. |
| The entire measured function | A previously established GPL/function basis and numerical coefficient fitting | Requires an independently derived alphabet, prefactors, weights and branches; not a shortcut supplied by PSLQ itself. |

PSLQ recognizes a number in terms of a supplied constant basis. It does not
evaluate the physical integral, establish its normalization, construct a complete
constant basis, or prove the recognized identity from finite precision alone.
The precision demand grows with the vector length and integer coefficient size.
The expensive stage may be the numerical period or continued moment, not PSLQ.

For the present calculation, the identical-quark DE has closed exactly with42
coordinates. Ten inclusive moment RHS combinations have already been evaluated
analytically using6 separately identified universal scalar values. Recognizing
these already available RHSs would not resolve the outstanding physical modes.
The opportunity is instead a still-unknown boundary coefficient, or the numerical
moment matrix acting on unresolved homogeneous solutions, with controlled endpoint
continuation and Laurent-order demands.

Candidate pilot: choose one unresolved source-relevant coefficient, derive a small
candidate constant basis from its scalar geometry/DE rather than the published
EEC answer, obtain independent high-precision values, and test recognition with
additional digits. Compare total time including numerical evaluation, extraction
of Laurent coefficients and checks. A successful integer relation is initially
numerical evidence; seek an exact physical identity or retain that qualification.
Use a withheld physical moment or an independent period for validation, not the
same condition that fixed the coefficient. Do not assume an arbitrary interior
base point yields only multiple zeta values.

Primary sources checked:

- [FireFly implementation and papers](https://github.com/jklappert/FireFly).
- [Bailey's description of PSLQ and precision requirements](https://www.cecm.sfu.ca/organics/papers/bailey/paper/html/node3-an.shtml).
- [Lee, Smirnov and Smirnov on high-precision DE expansions](https://arxiv.org/abs/1709.07525).

No measured NLO EEC reference coefficient was opened for this assessment.
