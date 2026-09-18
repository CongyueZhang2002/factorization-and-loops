# Gauss epsilon expansion and numerator family maps

Actual GPT-6 Pro in https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84
reviewed pushed revision a023942abc8ebdd337daa1872587ac2a9f393bd8; response took
11m56s. It explicitly reported reading the Gauss and combination sources, cut
equivalence and affine-basis construction, polynomial insertion/differentiation,
measurement preparation/merging, vertex guards and the relevant tests. Static
review, not execution of our Wolfram jobs. No published NLO EEC coefficient was
supplied or compared.

The Gauss two-by-two epsilon system, GPL signs, analytic zero-slope continuation,
one extra order for H/epsilon, and lower-parameter-first contiguous shifts are
correct. The solution is the analytic branch at the origin; arbitrary winding
paths or a physical side of the argument cut are not inferred. Endpoint Gamma
and resonant failures remain explicit. Tiny-epsilon numerical tests weakly
discriminate the highest coefficient: add a coefficientwise DE residual and a
complex-conjugate pair of arguments.

The proposed family mapping is valid. Use the union of all positive target
supports plus every cut as a numerator-free anchor. With original-to-canonical
frames Ts and Tr, source-to-representative is Ts Inverse[Tr], with unchanged
external blocks. Reconstruct and verify each covered positive slot exactly,
including prescriptions and directed particle momenta. Do not make measurement
polynomials monic or introduce scaling identities implicitly.

Transform the numerator using the representative's complete affine scalar-product
basis, leaving the nonlinear measurement as an additional denominator. Reuse
MultiplyCutIntegral, which already implements polynomial multiplication, exponent
shifts and cut pinches. Under the normalized cut convention G C_n(G)=C_(n-1)(G)
for n>1 and G C_1(G)=0, so the exact off-shell family map also handles dotted cuts.
The earlier on-shell simplification remains unit-cut-only.

The map must record an allowed positive slot set and reject an unmatched
auxiliary slot if its power becomes positive. Negative auxiliary powers are
finite polynomial numerators; positive powers generally require a new family.
Keep physical definitions, time directions, normalization and external divisors.
Equal-support maps first; containment can be added later. No minimal master
count follows from matching.

Requested bounded tests: an auxiliary mapping to multiple affine denominators
and a constant, both unit and dotted cuts; reject a positive unmatched auxiliary
or changed ordinary prescription; exact off-shell slot/numerator checks.
