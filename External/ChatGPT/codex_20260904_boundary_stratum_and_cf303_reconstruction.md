# Continue the existing Assess Multiquadratic Pipeline review

Please use the full mathematical and package context already established in
this conversation.  I need an independent expert assessment of two current
critical-path decisions.  Focus on the mathematics and algorithms, not hashes,
provenance machinery, or generic software advice.

## 1. Boundary data on a positive-dimensional physical stratum

The package can already construct a truncated local Frobenius solution in a
normal coordinate and transform the tangential connection to an eigenbasis of
the normal residue, including the derivative of that moving eigenbasis.  At a
boundary point the remaining coefficients are constants.  On a boundary
stratum they are functions of the tangential variable.  A rejected shortcut
treated those functions as inert constants.

Please state the mathematically minimal complete construction that turns the
normal Frobenius data and the restricted tangential connection into a
master-integral solution in terms of constants at a tangential base point.
In particular:

- what differential equation must the boundary functions obey, including
  resonant/Jordan sectors;
- what compatibility (flatness, preservation of normal-exponent sectors,
  moving-basis terms) is required;
- how the tangential evolution composes with the normal Frobenius solution and
  the subsequent path evolution into the bulk;
- whether an epsilon-factorized/dlog tangential connection may reuse the same
  iterated-integral coefficient operator, and what must be done when the
  tangential subsystem is rational in epsilon or elliptic;
- the smallest honest output contract needed before one may claim a complete
  `MasterIntegralSolution`, and which checks are mathematically essential.

Please give explicit matrix equations and flag any common but false shortcut.

## 2. CF303 rational-function reconstruction from modular images

For one unresolved rational function of a parameter p we have six independent
61-bit construction primes (combined modulus about 366 bits) and one held-out
61-bit validation prime at one p value.  The fitted rational function has a
degree-66 denominator.  Factoring the first modular denominator by
multiplicity, recombining complete multiplicity groups, and replaying at all
six primes reconstructs the exact monic denominator successfully.  A fixed
partial-fraction coordinate vector has length 71.

Coefficientwise rational reconstruction fails.  A simultaneous projective
LLL lift of the 71 coefficients produces shortest primitive candidates of
about 344 bits; all replay at the six construction primes but fail the held-out
function value.  The first 12 reduced rows and 1,334 primitive combinations of
the two shortest rows also fail.  Across the full job, ordinary lifting solves
72/112 coordinates and the factor-aware route solves 17 more, leaving 23.

Please assess:

- whether the evidence indicates insufficient modulus information rather than
  a wrong denominator/partial-fraction alignment;
- whether imposing the held-out scalar evaluation as a congruence and reducing
  the resulting sublattice is mathematically worthwhile, or underdetermined;
- whether there is a better exact reconstruction exploiting the known exact
  denominator and the common origin of numerator coefficients;
- how to estimate the minimum additional prime count before generating more
  expensive images;
- the most efficient next experiment that cleanly distinguishes lack of
  information from an alignment/normalization bug.

Return a prioritized recommendation with explicit stopping criteria.  Do not
recommend symbolic `Together` reconstruction of the full expressions.
