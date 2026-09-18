# Virtual integration and the real-virtual route

Actual GPT-6 Pro reviewed pushed a4a8b9bf0deda5cf333f13dc87fc2fc926d94a66 in
14m23s in https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84. It reported
static inspection of the new virtual helper, assembly, family maps, scalar
matching, trace changes and tests, plus the one-loop/box endpoint providers and
the three-body measured integrator. It did not run our jobs or supply a published
NLO EEC coefficient.

No factor-of-two, causal-sign or family-map algebra error was found. The exact
phase measure and generated loop conversion enter before order selection; the
conjugate is added only for (2,0). The negative normalized conjugate-bubble
product and the negative i^2 measure conversion compensate correctly. The
independent square test checks this path, but does not independently check the
two-loop interference. RetainAllPoles gives a safe lower bound; cancellation may
raise the actual onset.

Two concrete fixes were requested and implemented after review: both virtual
integration cache identities now include the derived FlavorMultiplicity and
SymmetryFactor; the family mapper's all-zero output retains the divisor union
and the requested coefficient grouping. A changed FlavorSum can leave the
representative amplitude unchanged while changing the normalization, so the
first issue was a real reuse defect. It does not invalidate freshly generated
results with the current cards. A nontrivial particle-frame permutation should
be checked through the new mapper as well as through the older powered matcher.

For massless three-body real-virtual sources, choose loop-first integration.
The alternative has two real phase-space directions plus one virtual direction;
particle cuts alone cannot span the latter for the existing frame matcher.
Keep mixed cut/uncut IBPs as a fallback requiring separate virtual routing.

Next implementation boundary: a causal loop-integrated scalar-density record
with exact rational coefficients, scalar definitions/prescriptions, measure,
kinematic domain, epsilon coverage and regulated endpoint representations.
Extract the physical measurement roots/Jacobians/kernel from the existing
three-body integrator into a reusable helper. Do not weaken the tree-only
compact-cut certificate to accept virtual propagators. B0/C0 have exact Gamma
representations; D0's finite interior series and its exact endpoint
representations have different contracts. Adding a D0 replacement alone is not
the missing integration.

For the card's pair observable, the derived energy chart has
y=(1-x)/(1-z x), with pair fractions z x(1-x)/(1-z x),
x(1-z)/(1-z x), and 1-x. The physical one-dimensional kernel is
N3 [z(1-z)]^-epsilon [x(1-x)]^(2-2epsilon)/
(4 (1-z x)^(3-2epsilon)), N3=s^(1-2epsilon)(4 Pi)^(2epsilon)/
(128 Pi^3 Gamma[2-2epsilon]). This is a chart derivation, not a hard coefficient.
Production must derive it from the measurement declaration.

Joint endpoints must include t=1-x, lambda=1-z with 1-z x=t+lambda-lambda t;
a fixed-x expansion misses t~lambda. Resolve the sectors and subtract enough
regulated terms before expanding an integrable remainder. UV as well as IR
convergence matters. Kernel orders follow the complete integrated endpoint
model, not only the scalar box pole. Definite GPL integrals retain lower-end
values. Self-pair contacts are separate weighted inclusive integrals; do not
infer them from the distinct-pair interior. No contribution-wise pole or
higher-distribution cancellation is assumed.

Suggested first exact end-to-end test: a bubble insertion in the new loop-density
and measurement interfaces, then triangles and boxes with regulated endpoints.
