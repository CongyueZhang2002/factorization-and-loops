# GPT-6 Pro: conic coordinates and distributional DE

Conversation: https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84

Reviewed revision: `48b1911bc942720380a9785f4b96ea5b4fd7b464`.
The actual 6 Pro response completed after 5m55s. This record summarizes that
response, read in full in the browser; it is not a verbatim transcript.

Pro inspected the rationalization verifier/constructor, presentation normalizer,
quadratic GPL domain handling, partial Laurent extension, their tests, and the
implementation report. It did not execute Wolfram or inspect the saved 42-master
solution. It separately checked the conic/inverse/Jacobian identities in Python.

For q1=a+b*z, q2=c+d*z, lambda=d/b, kappa=c-d*a/b=r0^2, the construction
X=2*r0*u/(u^2-lambda), Y=-r0*(u^2+lambda)/(u^2-lambda),
z=(X^2-a)/b is correct. dz/du=-8*kappa*u*(u^2+lambda)/(b*(u^2-lambda)^3).
Exclude map poles, Jacobian zeros, and original/gauge singularities on the local
ordinary chamber, and bind root signs at the lift. The root ordering determines
whether u=1/2 maps to z=9/25 or 16/25; derive the point from the actual map.
Changing the normalization point before assigning constants is legitimate.

Two findings were repaired and tested in the continuation:

- Preserve `ParameterFromRootValues` in the presentation normalizer.
- Compare old/new Laurent overlap from Min[newLower,oldLower], including implied
  zero coefficients below either bound. This is a residual-reporting correction.

Pro accepted the repaired root-domain propagation.

## Smooth restriction from a distributional DE

On a connected ordinary interval Omega suppose the same physical meromorphic
distribution I obeys I'=A I exactly, with epsilon^5 I holomorphic as a
distribution. Let J=T I, with T and T^-1 finite-meromorphic in epsilon, smooth
in z, and T'+T A=B T exactly. Require the full B to be holomorphic in epsilon
near zero and analytic in z, locally uniformly on compact subsets of Omega.
For U'=B U, U(z*)=1, analytic parameter dependence gives an invertible analytic U.
Then Z=U^-1 T I has zero distributional derivative and is a constant distribution.
Pairing it with a smooth compact test function of integral one gives a
finite-meromorphic vector C(epsilon). Thus I=T^-1 U C is smooth-meromorphic;
its coefficients below -5 vanish pointwise because they vanish as distributions.

Gauge poles must be propagated: if T has pole order pT, a safe bound for C is
-5-pT, not automatically -5. The statement excludes interior contacts only on
ordinary chambers. It does not cross excluded points, determine constants,
bound endpoint contact order, or prove weighted L1 behavior. The example
z*delta'(z)=-delta(z) explains why division through singular points is invalid.

Required retained evidence: original typed periods/prescriptions/normalization;
parent pole bound; exact distributional derivative/reduction identities with all
introduced division loci and no omitted boundary sources; ordinary chamber and
root sheet; exact T/T^-1 and gauge identity/valuations; holomorphy of the full B;
actual coordinate map, nonzero Jacobian and lift. A scalar master vector pulls
back as I(z(u)); only its DE receives the signed dz/du, not an absolute Jacobian.

Analytic ODE parameter reference: https://dlmf.nist.gov/1.13#ii

## Scope of the numerical reconstruction comment

The point used to select an LLL row is a selection/validation point, not an
untouched final test. Exact equality subsequently verified that benchmark's
recovered formula. No end-to-end IBP speedup was established. The user has since
deferred this direction; no numerical reconstruction is added to production.
