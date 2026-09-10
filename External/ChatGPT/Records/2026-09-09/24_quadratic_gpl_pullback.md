# Quadratic-root GPL pullback and conjugate virtual master

Verified outgoing model: gpt-6-pro. Retrieved 2026-09-09.

## Question

Please continue as GPT-6 Pro. Repo https://github.com/maxzhang01/factorization-and-loops (local code is newer). We now independently exactly match ALL four generated two-loop quark form-factor master coefficients to hep-ph/0507061 eq (10), plus FL=0; no amplitude reference in production. Regenerating RV after fixing g_s^4 substitution via g_s^2 declaration.

The currently limiting RR step: 55 shared masters, 16 tangential functions, 5 corner constants. Corner GPLs complete. Normal finite DE connection has 249 integrals; after physical constants and coefficient collection, only 2 primitive integrals fail because the integration kernel has ONE quadratic root:
sqrt(q(t)), q(t)=rho^2 t^2+4(1-z)(1-rho t),
with 0<rho,z<1, t from 0 to1. Everything else is rational times rational-argument logs and already converted GPLs G[word,t] with constant-in-t letters. Descendants fail solely due to those two missing integrals. This appears genus zero, not an elliptic obstruction.

Proposed GENERAL fix to GPL integration: q=a t^2+b t+c; s0=sqrt(c), u0=b/(2s0). Set u=(sqrt(q(t))-s0)/t, y=u-u0. Then t(y)=-2s0 y/((y+u0)^2-a), sqrt(q)=s0+(y+u0)t(y); t(0)=0, same local branch. Exact pullback of GPLs G[w,t(y)] into GPLs in y:
- all-zero words: Log[t(y)]^n/n!, normalize Log[t(y)]=Log[y]+Log[t'(0)]+integral of dlog(t(y)/y), branch fixed at0.
- other words recursively integrate t'(y)/(t(y)-firstletter) times pulled-back tail, with finite zero endpoint.
- then rational Hermite integration already implemented.
Questions: (1) correct treatment if t'(0)<0 (this q gives y<0 along positive t); can use y=u0-u instead to ensure positive tangent, or choose orientation from exact physical-domain inequalities? What general branch validation suffices on the whole stored path? (2) Are there hidden constants for words with trailing zeros or letters crossed by rational map? (3) suggest cheap exact derivative/basepoint tests that validate conversion without high-cost numerical checks. (4) If both obstructing primitive kernels are actually exact derivatives of algebraic prefactors times lower-weight GPLs, should we first implement an algebraic Hermite reduction rather than rational pullback, or is pullback the robust minimal extension? Give concrete algorithm, no process-specific hard-function import.

Also virtual one-loop-square: generated denominators separate in ell1(+i0), ell2(-i0), coupled only by polynomial numerator. Same generic IBP reduces to disconnected bubble products. With normalization product dDell/(i*pi^(D/2)) for BOTH loops, scalar library value of [+,-] spacelike product is -J2(Q2)^2, since Jminus=-conjugate(Jplus). Original measure conversion (i*pi^(D/2))^2 then correctly gives a positive physical square. We will exactly verify each propagator and its sign during matching. Please flag any problem with this normalization argument; we will independently compare the square with generated Born times |F1|^2.


## Pro response

The conic pullback is valid, and your mixed-prescription bubble-product sign is correct. One point needs correction: for the quadratic you actually have, y=u−u
0
	​

 is positive along t>0, and t
′
(0)>0. There is no orientation reversal in this case.

I recommend a small refinement: normalize the new coordinate to unit tangent at the origin. This removes the logt
′
(0) basepoint constant, gives a simpler rational map for your quadratic, and lets the existing rational GPL integration engine do the remaining work.

1. The conic chart is correct; its orientation is not the one stated

Write

q(t)=at
2
+bt+c,s
0
	​

=
c
	​

,u
0
	​

=
2s
0
	​

b
	​

,Δ=b
2
−4ac.

Initially assume c

=0, choose the branch with 
q(0)
	​

=s
0
	​

, and take Δ

=0.

The line-through-basepoint parametrization

u=
t
q(t)
	​

−s
0
	​

	​

,y=u−u
0
	​


gives

t=R(y)=−
(y+u
0
	​

)
2
−a
2s
0
	​

y
	​

,W(y)=s
0
	​

+(y+u
0
	​

)R(y).
	​

(1)

It satisfies

W(y)
2
=q(R(y)),W(0)=s
0
	​

.

This is the standard rational-point parametrization of a conic; it rationalizes the curve over the coefficient field containing s
0
	​

. 
arXiv

Its tangent is

κ:=R
′
(0)=−
u
0
2
	​

−a
2s
0
	​

	​

=−
Δ
8s
0
3
	​

	​

.
	​

(2)
For your actual polynomial, κ>0

Put h=
1−z
	​

>0. Then

a=ρ
2
,b=−4ρh
2
,c=4h
2
,

so

s
0
	​

=2h,u
0
	​

=−ρh,Δ=−16ρ
2
zh
2
<0,

and

R
′
(0)=
ρ
2
z
4h
	​

>0.
	​

(3)

Moreover,

y(t)=
q(t)
	​

+h(2−ρt)
ρ
2
zt
	​

>0(0<t≤1).
	​

(4)

This expression is also preferable to subtracting nearly equal square roots when checking the endpoint numerically.

The radicand never vanishes on the stored path:

q(t)=(ρt−2h
2
)
2
+4zh
2
>0.

Thus the positive square-root branch is continuous throughout 0≤t≤1.

The two poles of R(y) are

y
−
	​

=ρ(h−1)<0,y
+
	​

=ρ(h+1)>0.

The physical endpoint

y
1
	​

=
q(1)
	​

−h(2−ρ)

satisfies 0<y
1
	​

<y
+
	​

. Hence the physical y-segment contains no chart pole.

2. A unit-tangent coordinate simplifies both the chart and GPL constants

Set

v=κy.

Then t
′
(0)=1 with respect to v. Define

A(v)=1−
2c
b
	​

v+
16c
2
Δ
	​

v
2
.

The chart becomes

t=R
∗
	​

(v)=
A(v)
v
	​

,
q(t)
	​

=s
0
	​

A(v)
1−
16c
2
Δ
	​

v
2
	​

.
	​

(5)

Its Jacobian obeys

R
∗
′
	​

(v)=
A(v)
2
1−
16c
2
Δ
	​

v
2
	​

,
q(t)
	​

dt
	​

=
s
0
	​

A(v)
dv
	​

.
	​

(6)

I verified the curve identity, unit tangent, and both Jacobian identities exactly.

For your polynomial,

A(v)=1+
2
ρ
	​

v−
16(1−z)
ρ
2
z
	​

v
2
,t=
A(v)
v
	​

.
	​

(7)

Notably, the rational map itself contains no square root of 1−z.

Its inverse along the physical path is

v(t)=
q(t)
	​

+h(2−ρt)
4ht
	​

,v
1
	​

=
q(1)
	​

+h(2−ρ)
4h
	​

.
	​

(8)

Both v and t increase from zero to their respective endpoints. On that segment,

A(v)=
t
v
	​

>0,R
∗
′
	​

(v)>0,

and the reconstructed square root is positive.

This is the chart I would implement. It is only an affine rescaling of your proposal, but it avoids an unnecessary tangent-renormalization constant in every all-zero GPL tail.

For the general routine, handle Δ=0 as a perfect-square case and c=0 as a separate, potentially ramified basepoint case. The original y-construction degenerates there. The current proof is for the open physical parameter domain; it does not automatically authorize taking z→1 in (7).

3. GPL pullback: use differential forms plus the basepoint normalization

Use the convention

G(a
1
	​

,…,a
n
	​

;t)=∫
0
t
	​

t
1
	​

−a
1
	​

dt
1
	​

	​

G(a
2
	​

,…,a
n
	​

;t
1
	​

),G(0
n
;t)=
n!
log
n
t
	​

.

The functions are iterated integrals on a specified path. Their derivatives and logarithmic basepoint normalization determine the required pullback. 
arXiv

For a rational map t=R(v), first construct the pulled-back letter:

ω
a
R
	​

=
R(v)−a
R
′
(v)
	​

dv=dlog(R(v)−a).
	​

(9)

If R=N/D, then

R−a
R
′
	​

=
dv
d
	​

log(N−aD)−
dv
d
	​

logD.
	​

(10)

Factor these polynomials, cancel common factors first, and retain multiplicities:

ω
a
R
	​

=
β
∑
	​

n
aβ
	​

v−β
dv
	​

.

Include the poles of R, with their negative multiplicities. Replacing a letter only by its preimages R(v)=a omits the second term in (10).

There are no higher-order poles in this logarithmic derivative. Consequently, GPL pullback itself can use a sparse letter-substitution map; rational Hermite reduction is needed only for the additional rational integration kernel.

3.1 Your recursion is correct

For the original, non-unit-tangent y-coordinate, define

L
R
	​

(y)=logy+log
γ
	​

κ+∫
0
y
	​

(
R(ξ)
R
′
(ξ)
	​

−
ξ
1
	​

)dξ,
(11)

with the logarithms fixed by the original path. Then

G(0
n
;R(y))=
n!
L
R
	​

(y)
n
	​

.

For every word not consisting entirely of zeros,

G
a,w
	​

(y)=∫
0
y
	​

R(ξ)−a
R
′
(ξ)
	​

G
w
	​

(ξ)dξ,
	​

(12)

with its finite zero limit at the basepoint.

This includes words with trailing zeros. A word containing at least one nonzero letter tends to zero at t→0, although it can behave as a positive power of t times logarithms. No additional arbitrary integration constant is needed in (12).

For the unit-tangent chart (5), κ=1, so

logR
∗
	​

(v)=logv+∫
0
v
	​

(
R
∗
	​

(ξ)
R
∗
′
	​

(ξ)
	​

−
ξ
1
	​

)dξ.
	​

(13)

The tangential normalization agrees directly with the standard v-GPL normalization.

3.2 Trailing zeros can propagate a missed tangent constant

The issue is not an undetermined new constant for every trailing-zero word. It is the propagation of the known logκ from an all-zero tail.

For example, under a simple positive rescaling t=κy,

G(a,0;κy)=G(a/κ,0;y)+logκG(a/κ;y).
	​

(14)

But

G(0,a;κy)=G(0,a/κ;y).

A pullback that treats both words by uncorrected letter substitution fails the first identity.

The treatment of trailing-zero words through shuffle regularization and logarithmic endpoint data is standard hyperlogarithm algebra. 
arXiv

For a genuinely negative original tangent, choosing y↦−y is valid. Simply inserting principal values for both logy and logκ, however, can add an unwanted 2πi. The unit-tangent rescaling avoids that unnecessary ambiguity.

3.3 New algebraic letters are expected, but are not a new elliptic curve

Even after the conic is rationalized, the preimages of an original GPL letter can be algebraic functions of ρ,z.

For the original chart (1), a nonzero source letter ℓ has preimages

y
ℓ,±
	​

=−u
0
	​

−
ℓ
s
0
	​

	​

±
ℓ
q(ℓ)
	​

	​

.
	​

(15)

These square roots are constant in the integration variable. They enlarge the parameter-dependent alphabet, not the genus of the v-integration.

Your converter must therefore support exact algebraic constant letters, or algebraic Root representations. A restriction to letters rational in the external parameters would still reject otherwise valid GPLs. This distinction between algebraic letters in one integration variable and subsequent integration in those parameters is important in general hyperlogarithm algorithms. 
arXiv

Treat coincident preimages by exact multiplicity or a confluent limit. Do not assign two generic simple-pole terms and evaluate them separately at a collision.

4. Global branch validation should be a path check, not an endpoint check

For this particular conic, equations (7)–(8) establish a real, monotone, nonsingular chart on the full stored path. The remaining checks concern the source integrand and GPL alphabet.

For each dependency component, verify:

The chosen square root is continuous and nonzero, with the correct value at t=0.

The rational map and its inverse remain finite and one-to-one along the stored path.

Every source singularity and contour prescription is mapped to the corresponding preimage.

Any apparent pole introduced by factorization is either outside the path or canceled in the complete expression.

Exact real-root isolation and sign checks on the declared parameter chamber are sufficient for the real interval case. Sampling a few kinematic points is not a proof that a letter never crosses the path.

If the original path avoids every nonzero GPL letter, a monotone chart introduces no new physical crossing: a preimage lies on the new path exactly when the original letter lies on the old one. If the original function requires a prescribed bypass, carry that bypass through the map. For a simple real preimage,

R(β)=a,

a small imaginary displacement of the source letter is divided by R
′
(β) in the preimage. Assigning the same independent +i0 to every new algebraic letter is not generally correct.

The endpoint expression alone does not determine the continuation. Iterated-integral continuation retains path and monodromy data; changing to principal logarithms after factorization can change the answer. 
arXiv
 GiNaC likewise has explicit sign arguments for the imaginary parts of GPL letters, separate from its default logarithm branches. 
ginac.de

For rational-argument logarithms, preserve their original constant:

logf(t)=log
γ
	​

f(0)+∫
0
t
	​

f(s)
f
′
(s)
	​

ds

when f(0)

=0, and factor its exact power of t otherwise. The differential alone cannot distinguish, for example, logt from log(−t−i0)=logt−iπ.

Outer endpoint constants remain important after Hermite reduction

For an actually convergent integral, evaluate the complete primitive’s lower limit. Do not set the rational-prefactor terms’ constants to zero individually.

If the original finite connection uses subtraction or finite-part regularization, transform those subtractions as well. A finite part of a pole is not coordinate-invariant, even under a unit-tangent map. From (5),

R
∗
	​

(v)
1
	​

=
v
1
	​

−
2c
b
	​

+
16c
2
Δ
	​

v.

Thus a prescription that discards the pole and constant in the old coordinate is not automatically the same prescription in the new coordinate.

This does not invalidate the GPL pullback: pure GPL basepoint singularities are logarithmic and are handled by (11)–(13). It is a guard for the rational Hermite primitive and the surrounding finite-integral definition.

Also avoid silently rescaling v to v/v
1
	​

 to restore a unit integration interval. That changes the tangent from 1 to v
1
	​

 and reintroduces the corresponding logv
1
	​

 data.

5. Cheap exact tests are enough to validate this extension

No long numerical run is needed. The strongest tests are identities of derivatives together with the specified basepoint data.

Test	Required identity
Conic chart	W
2
=q(R), R(0)=0, W(0)=s
0
	​

, and the exact Jacobian
Letter pullback	R
′
/(R−a)=∑
β
	​

n
aβ
	​

/(v−β), including map poles and multiplicities
Word pullback	∂
v
	​

G
a,w
	​

=
R−a
R
′
	​

G
w
	​

, with the correct zero/logarithmic basepoint
Algebra compatibility	Pullback preserves a few shuffle products and composition of two rational maps
Final primitive	∂
v
	​

F
new
	​

=R
′
f(R,W), followed by the complete lower-endpoint check

Include G(0), G(0,0), G(a,0), G(0,a), G(a,0,0), and a mixed-letter word. Test once with a non-unit positive tangent and once with a negative original tangent—for example q(t)=1+t—even if production uses the normalized chart.

A compact regression using your actual polynomial is

ρ=
3
2
	​

,z=
4
3
	​

.

Then

q(t)=1−
3
2
	​

t+
9
4
	​

t
2
,
R
∗
	​

(v)=
1+v/3−v
2
/12
v
	​

,W(v)=
1+v/3−v
2
/12
1+v
2
/12
	​

,

and

v
1
	​

=2
7
	​

−4.

The exact primitive is

∫
0
R
∗
	​

(v)
	​

q(t)
	​

dt
	​

=
2
3
	​

[G(−2;v)−G(6;v)].
	​

(16)

Its derivative and zero basepoint check both the rationalized root kernel and its orientation. I verified these identities exactly.

Derivative plus basepoint data establish equality on the connected path with its declared continuation. They are substantially more informative here than high-precision comparisons at isolated endpoints.

6. Do not build a second algebraic integration engine first

A bounded exact-derivative precheck can be useful. For w=
q
	​

,

dt
d
	​

[A(t)+B(t)w]=A
′
(t)+(B
′
(t)+
2q(t)
q
′
(t)
	​

B(t))w.
	​

(17)

For a GPL factor,

dt
d
	​

[R
alg
	​

(t)G(a,w;t)]=R
alg
′
	​

G(a,w;t)+
t−a
R
alg
	​

	​

G(w;t).

These formulas allow a small rational-coefficient ansatz to detect a suspected algebraic prefactor times a lower-weight GPL.

But a complete algebraic Hermite/Risch layer is unnecessary for the immediate obstruction. Rationalizing the conic turns the same problem into the rational Hermite and hyperlogarithm integration you already have. Rational prefactors times hyperlogarithms are closed under that integration procedure after the needed alphabet extension. 
arXiv

Recommended order: permit a cheap, bounded exact-derivative check, then use the common conic pullback as the guaranteed supported route. Do not make success of the derivative ansatz a prerequisite.

For performance, cache the letter pullbacks once, memoize word pullbacks by their suffixes, and retain products until a shuffle expansion is actually needed. Apply one chart to the full ancestor dependency component; do not transform only the two outer kernels while leaving their embedded GPLs in the old variable. If a later integration treats ρ or z as the active variable, re-evaluate its alphabet and branch requirements rather than regarding the new algebraic letters as globally constant.

7. The mixed-prescription square normalization is correct

Define both signs with the same normalized measure:

J
±
	​

=∫
iπ
D/2
d
D
ℓ
	​

j
∏
	​

(D
j
	​

±i0)
−ν
j
	​

.

For real external kinematics and real ϵ,

J
+
∗
	​

=∫
−iπ
D/2
d
D
ℓ
	​

j
∏
	​

(D
j
	​

−i0)
−ν
j
	​

=−J
−
	​

.

Therefore

J
−
	​

=−J
+
∗
	​

.
	​

(18)

The normalized scalar integral is real on the spacelike bubble branch, so

J
+
	​

J
−
	​

=−J
2
	​

(Q
2
)
2
.
	​

(19)

Restoring the two original unnormalized loop measures gives

(iπ
D/2
)
2
[−J
2
2
	​

]=+π
D
J
2
2
	​

.

Including both (2π)
−D
 factors,

[
(4π)
D/2
i
	​

]
2
[−J
2
2
	​

]=
(4π)
D
J
2
2
	​

	​

.
	​

(20)

That is the expected sign of the physical square. The 1/(iπ
D/2
) and (2π)
−D
 conventions are distinct and must be converted exactly once. 
FeynCalc

The necessary qualifications are narrow:

In a timelike region, use −∣J
+
	​

∣
2
, not −J
+
2
	​

.

Do not also switch the conjugate-loop normalization to 1/(−iπ
D/2
) while retaining the minus in (19).

Polynomial numerator contractions between the loops do not create a connected scalar denominator topology. Factorize the tensor integrals or reduce them to products with the prescribed loop signs retained.

The one-loop square has no extra factor two. That factor belongs to the two-loop–Born interference, not ∣A
(1)
∣
2
.

The comparison with generated Born times ∣F
1
	​

∣
2
 must use the same coupling, field-renormalization, and scalar-measure conventions.

The minimal permanent extension is therefore a unit-tangent conic chart, a branch-aware GPL letter/word pullback, and the existing rational Hermite integrator. For the stated one-root dependency component, this resolves a genus-zero integration problem; it does not require an elliptic backend or any imported master value.

## Local verification and correction

The question understated the affected set: the complete GPL report contains 20 direct failures and 42 dependency failures, not two primitive failures. The retained PhysicalGPLRadicalDependencies.wl verifies that each ancestor component contains one root only. There are two linear radicands and one quadratic radicand across the separate components. Thus the one-root assumption needed for this review applies component by component. The original orientation claim was wrong and is corrected above. The mixed-prescription square has meanwhile passed its independent exact equation-(8) coefficient check.
