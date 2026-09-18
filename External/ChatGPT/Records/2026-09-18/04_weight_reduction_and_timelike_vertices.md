# Measurement numerator and timelike scalar-master review

Actual ChatGPT 6 Pro reviewed pushed revision
`117012d84a3bb09de81253ed025b5f4262aeae43` in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84 .
This record summarizes the review; Pro inspected source but did not execute it.
It explicitly read MeasuredIntegrands, MasslessVertices, their tests, library
providers, virtual matching and decomposition, and the measured DE caller.
No published order-alpha_s-squared EEC coefficient was compared.

The unit-cut reduction is valid as an initial source replacement. With
G=z B-A, the identity B^2/4=A^2/(4z^2)+(z B+A)G/(4z^2) explains the degree
reduction. Differentiating the complete identity requires differentiating
both its rational coefficient and the cut. The unit-cut identity alone is
not valid term by term on dotted cuts. The rational factor 1/z^2 must be
included before regulated endpoint continuation; multiplying an already
expanded plus distribution by that singular factor is not justified.

Pro identified two metadata/certification gaps:

- A generic Groebner basis can lose a special parameter fiber. Retain an
  exactly checked, denominator-cleared identity in the original polynomial
  generators, including all factors of its clearing denominator. Direct
  polynomial division is sufficient for the present single constraint;
  unsupported cases can simply retain the original numerator.
- Merging decompositions must retain both the union of exceptional divisors
  and the per-source divisor lists.

Both repairs are now implemented. Additional tests check the original-generator
identity, divisor propagation, and the differentiated identity's test-function
pairing. The preceding unit-cut tests already cover genuine propagator
cancellation, rejection of dotted records, and an interior causal pole.

The timelike phase table and the negative normalized anti-Feynman bubble
product were confirmed. With the same i*pi^(D/2) denominator for both loop
measures, J_minus=(-1)^L conjugate(J_plus). This sign must survive until the
generated amplitude's measure conversion is restored. The incidence graph is
only a sufficient factorization criterion in its stated canonical routing;
rejecting a mixed connected routing is not proof of physical nonfactorization.

Pro found that the caller-frame scalar catalog did not check whether its
kinematic rules actually imply two null legs and the stated sign of their
total invariant. The constructor now rejects contradictory or unestablished
invariants in either region. Tests cover that rejection and a library-enabled
timelike round trip. No phase formula or compensating normalization was changed.
