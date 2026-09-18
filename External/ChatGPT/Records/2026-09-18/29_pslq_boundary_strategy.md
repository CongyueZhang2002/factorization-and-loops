# Numerical recognition strategy

Actual ChatGPT6 Pro,3m8s, in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
It received revision f688f4596f0e184fc81e45031ea6049e6bcde80e and the current
calculation status. This was a strategy review, not a source audit or execution.
No measured EEC coefficient was requested or supplied.

Pro recommended retaining modular IBP reconstruction while testing numerical
recognition on a few physical constants. It distinguished this from fitting a
full measured function, which needs a justified function space and rational
prefactor bounds. The candidate constants depend on geometry, endpoint/base
point and branches; a rational DE alphabet alone does not imply only zeta values.

For moments, write I=I_known+Y_U c and M c=b. Numerical propagation of only the
unresolved homogeneous columns, with accumulator V'=Q I, can evaluate the moment
responses without nested quadrature. Regulated endpoint continuation, actual rank,
conditioning and deeper orders induced by inverse-M poles must still be supplied.
A DE residual cannot check constants because a wrong homogeneous shift satisfies
the same DE. The ten available rows are not ten independently fixed constants.

Recognition should require a nonzero coefficient on the target number, otherwise
PSLQ may merely find a relation among supplied basis constants. Rough reliable
digit planning is vector length times log10(integer coefficient height), plus
guard digits and losses from transport, subtraction and conditioning.

Pro's bounded pilot: withhold one known nontrivial coefficient as a control, test
one to three genuinely unknown coefficients in the smallest determined block,
fix bases/height bounds beforehand, compare complete numerical cost at increasing
precision, and check candidates with a withheld moment or independent period.
Store numerical candidates separately until an exact physical identity/rank
certificate or a rigorous bounded-coefficient uniqueness argument establishes
them. An interval residual containing zero alone does not prove equality.

The user subsequently clarified that the main proposal concerns reconstruction
in already known coefficient/function bases throughout reduction and DE work.
A separate follow-up review addresses that broader question. This review's
boundary-focused recommendation is not a dismissal of known-ansatz lattice
reconstruction.
