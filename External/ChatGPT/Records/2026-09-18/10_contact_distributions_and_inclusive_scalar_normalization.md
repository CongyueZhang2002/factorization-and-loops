# GPT-6 Pro review: endpoint distributions and inclusive scalar normalization

Actual GPT-6 Pro, completed after 17m21s in the existing EEC review conversation.
Reviewed exact pushed revision `7451de587239d749186c384ceaad2cf08a521452`:
https://github.com/CongyueZhang2002/factorization-and-loops/tree/7451de587239d749186c384ceaad2cf08a521452
Conversation: https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84

This is a retained summary of the visible response, not a verbatim transcript.
Pro explicitly inspected the endpoint cube, contact charts, scalar density,
Hermitian integration, measurement moments, cached rows and restricted DE
constructor; it did not run Wolfram or inspect the saved production charts.
No published alpha_s-squared EEC coefficient was used or supplied.

## Findings

The eight-chart cover per density has the correct half-square and sector
Jacobians. A finite-pole-cleared holomorphic L1 representation of
[z(1-z)]^(r+1) times each original prescribed component fixes the distribution
on tests with endpoint jets through r zero. The remaining ambiguity consists
of delta derivatives through r at the two endpoints. The current nonnegative
integer-power bound is sufficient, locally uniformly on nonsingular compact
subsets of external parameter space.

One automatic guard was missing: coordinate independence does not establish
finite meromorphy in epsilon. The branch prefactor also needs to participate
in the proof. Reject exp(1/epsilon), Gamma(1/epsilon), log(epsilon) and irregular
hypergeometric parameters; check a sufficient supported grammar rather than
assuming arbitrary factors are meromorphic. These repairs are being tested in
production. Also bind cached StructureFunctions to the actual input labels,
not only to the saved row's own coefficient count.

Exact prepared-input equality in binary metadata and consistent restricted
Targets/Rules/Masters repair the previous interfaces; no extra hash is needed.

## Distribution basis

For the established ordinary-contact class define an interpolation finite part
E[f][phi] = integral_0^1 f(z) (phi(z)-(1-z)phi(0)-z phi(1)) dz.
It has zero zeroth and first moments. If independently generated normalized
inclusive moments are T and T/2, the full distribution is
E[f] + (T/2) delta(z) + (T/2) delta(1-z).
These contacts include self pairs; do not add their separate source again.
Use a dedicated distribution head/basis tag, not RegularCoefficient. This is
an explicit distribution once f and T are explicit, like a conventional plus
distribution; it is not a deferred master integration. Conversion to the usual
log-plus basis can be separate. Multiplication by a nonconstant smooth factor
requires induced contact corrections, so naive density multiplication is invalid.

## Universal scalar normalization, independently derived

With +i0 denominators and loop measure d^Dk/(i pi^(D/2)), the bubble is
Gamma(e) Gamma(1-e)^2/Gamma(2-2e) s^(-e) exp(i pi e).
Restoring d^Dk/(2pi)^D supplies i kappa_e; the external -i in the definitions
of hep-ph/0403057 Appendix A.2 gives a PLUS real projection. Direct Dirichlet
integration therefore gives plus signs for V5a and V5b under these literal
conventions. This establishes a convention/definition mismatch with the printed
sign, not which edit the authors intended. Do not change our amplitude sign.

For box chords (0,p1,p1+p3,q), a=s13/s, b=s23/s, c=1-a-b, the parameter
polynomial is a alpha0 alpha2 + alpha0 alpha3 + b alpha1 alpha3.
The substitution (alpha0,alpha1,alpha2,alpha3) =
(lambda u,lambda(1-u),(1-lambda)(1-v),(1-lambda)v) gives
Jbox = exp(i pi e) s^(-2-e) Gamma(2+e) B(-e,-e)
       integral_[0,1]^2 (a u+b v+c u v)^(-2-e) du dv.
Insert the physical simplex measure and 1/(s c) to define the COMPLEX inclusive
U8. The literal V8 is kappa_e Re U8. Its parameter integral is positive for
-1/2<e<0 and its leading normalized coefficient is +5/(2e^4). Do not blindly
negate all subleading coefficients of a published table.

A branch-unambiguous Gauss form uses F(r)=2F1(-e,-e;1-e;r) and
H=(1-a)^e F(c/(1-a))+(1-b)^e F(c/(1-b))
  -((1-a)(1-b))^e F(c/((1-a)(1-b))).
Jbox=2 rGamma exp(i pi e) s^(-2-e) (ab)^(-1-e) H/e^2.
Pro independently evaluated this against the Euler box at e=-1/4,a=1/3,b=1/5,
getting phase-stripped 278.022143683173251463564802042... (>30 digit agreement).
This check must still be run locally before using a new provider.
The first two inclusive Gauss terms each integrate to
B(-2e,-2e) B(-e,-2e) 3F2(-e,-e,-e;1-e,-3e;1).
The third remains a two-variable convergent Euler/Gauss integral. Its Laurent
coefficients, normalization and required orders remain to be computed; this
review did NOT supply a complete explicit inclusive RV master.
