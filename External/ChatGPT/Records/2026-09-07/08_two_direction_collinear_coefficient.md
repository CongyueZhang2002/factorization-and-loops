# Two-direction collinear coefficient

## Prompt


We have evaluated the two new unit-cut 3D Euler integrals and applied all48 slope -2 equations. Current result:36 unknown series258coefficients (35 in -3/-4 plus exceptional0). Single-dot physical proof from your last reply is being encoded with the explicit generator/degree certificate.

The -3 rank screen is exceptionally simple: three unit-cut masters, each with exactly TWO ordinary factors on the SAME cut particle k, no pair invariant or other nonconstant denominator:
row64: 1/[(ka-k)^2 (kc+k)^2], hence signs -,+; Pa.Pc=1/8.
row89: 1/[(kb-k)^2 (ka-k)^2], signs -,-; Pa.Pb=1/2.
row105:1/[(kb-k)^2 (kc+k)^2], signs -,+; Pb.Pc atedge=3/8.
All target coefficients z^(-3eps), no log, and their projected rank is3.
Q=ka+kb-kc,Q²=z; atedge Pa.Q=3/8,Pb.Q=1/8,Pc.Q=1/2.
MeasurePrefactor=(2Pi)^(-5+4eps), masterprefactor1, D=4-2eps.

Please verify the general formula and coefficient completeness below. This would solve the entire -3 primary part analytically without a region campaign.

Take future distinct null P,R, integer powers a,b>0, one cut k, and exactly the denominators (sigma_P 2P.k)^a (sigma_R 2R.k)^b. Let alpha=(D-2)/2,beta=D-3, S=a+b,
c2=Pi^((D-1)/2)/(2^(D-2) Gamma[(D-1)/2]), and
L=2P.R/((P.Q)(R.Q)) at z=0.
Raw phase space factors exactly by k energy y=2E_k/sqrt(z):
dPhi3_raw = c2*z^beta/2^(D-1) y^(2alpha-1)(1-y)^(alpha-1) dy dOmega_(D-2).
Also 2P.k=(P.Q)y(1-nP.nk), similarlyR.

The external angular separation obeys theta_PR²=z*L+O(z²). With angular coordinate nk=n_*+sqrt(z)u+..., the angular integral has leading coefficient
2^S*z^(alpha-S) *
Pi^alpha L^(alpha-S) Gamma[S-alpha]Gamma[alpha-a]Gamma[alpha-b] /
(Gamma[a]Gamma[b]Gamma[2alpha-S]).
The energy integral is Beta[2alpha-S,alpha].
Therefore the full coefficient at normal exponent beta+alpha-S =3alpha-1-S is
C = normalization * (sigma_P)^(-a)(sigma_R)^(-b) *
c2*2^(S-D+1)*Pi^alpha *
L^(alpha-S)/((P.Q)^a(R.Q)^b) *
Gamma[S-alpha]Gamma[alpha-a]Gamma[alpha-b]Gamma[alpha]/
(Gamma[a]Gamma[b]Gamma[3alpha-S]).
For a=b=1, normal exponent=-3eps. At epsilon0 the epsilon^-2 coefficient is
sigma_P*sigma_R/(256 Pi^3 P.R) in our standard measure. Thus rows64,89,105 leading coefficients are respectively
-1/(32Pi^3), +1/(128Pi^3), -1/(96Pi^3), times epsilon^-2.

Claimed initial convergence strip: max(a,b)<Re(alpha)<a+b.
Then both cap IR singularities and cap infinity are integrable, and energy endpoints are integrable since2alpha-S>0.
The fixed-angle complement divided by z^(alpha-S) vanishes; the expanding angular-cap limit is the Euclidean massless bubble over allR^(D-2).
Because energy/angular variables separate exactly for these two single-particle eikonals, soft energy endpoints cannot create another independent contribution at this power in that strip.
Thus the entire physical coefficient (not just one candidate region) is fixed in the strip, then continued meromorphically. The hard whole-domain coefficient is a different branch. Generic-log coefficients at this power vanish.

Implementation would be a reusable constructor for any recognized two distinct future-null directions on one unit cut, arbitrary positive integer a,b, unchanged routing/measure, optional Q² powers and constant full-subset factors. It refuses other angular/energy factors rather than assuming they are spectators. Scales for linear eikonals useP.Q, quadraticones±2P.Q; we can expressformulausingstoredexactExternalScaleFactor toavoidfactor2errors.

Please check all constants, the real-noninteger-D angular argument/completeness, the arbitrarypowers convergence strip, and any hidden overlap/branch/cut-prescription issue. If useful provide an exact angular Feynman-parameter representation for a quick independent numerical check at a finiteD in the strip.


## Pro response

Your coefficient, convergence strip, and three leading signs are correct. This is a complete coefficient calculation for the restricted class, not merely a candidate collinear-region contribution. There is no missing factor of two or additional energy-endpoint contribution.

Two implementation qualifications are essential: require 0<L<∞, not merely distinct external-vector labels; and distinguish the external scale used with light-cone fractions from the scale used with y(1−cosθ).

There is also a stronger result: the entire finite-z integral in this class has a single 
2
	​

F
1
	​

 representation. Its exact connection formula separates the hard and collinear branches and independently verifies your coefficient and absence of generic-dimensional logarithms.

1. Exact phase-space and energy normalization

Let

p(z)=P⋅Q,r(z)=R⋅Q,

and define the positive angular integral

A
a,b
	​

(θ;α)=∫
S
D−2
	​

(1−n
P
	​

⋅n)
a
(1−n
R
	​

⋅n)
b
dΩ
D−2
	​

(n)
	​

.

Integrating the two unobserved particles first gives

dΦ
3
raw
	​

=d
D
kδ
+
	​

(k
2
)c
2
	​

[(Q−k)
2
]
(D−4)/2
.

In the Q-rest frame,

E
k
	​

=
2
z
	​

	​

y,(Q−k)
2
=z(1−y),

so

dΦ
3
raw
	​

=
2
D−1
c
2
	​

z
β
	​

y
2α−1
(1−y)
α−1
dydΩ
D−2
	​

.
	​

(1)

Your factor 2
−(D−1)
 is correct. Here dΩ
D−2
	​

 is the unnormalized sphere measure. This raw-measure convention converts to standard three-body phase space by (2π)
3−2D
, exactly your (2π)
−5+4ϵ
. 
Scipp Legacy

For unit cut k,

2P⋅k=p(z)y(1−n
P
	​

⋅n).

Therefore the integral factors exactly, before any recoil expansion:

I
a,b
	​

(z,D)=N(D)
2
D−1
p(z)
a
r(z)
b
σ
P
−a
	​

σ
R
−b
	​

c
2
	​

z
β
	​

B(2α−S,α)A
a,b
	​

(θ;α),
	​

(2)

where N(D) contains your measure/master/routing prefactors.

The energy integral requires

Re(2α−S)>0,Reα>0.

Both follow from Reα>max(a,b). Its value is exactly the Beta function in (2). 
DLMF

This exact factorization is why an independently scaled soft-energy region cannot add another unknown contribution to the coefficient under consideration.

2. A global stereographic proof establishes completeness

Your cap argument can be replaced by a single dominated-convergence proof over the entire sphere. This avoids having to manage a cap/complement overlap.

Set

d=D−2=2α,δ=tan
2
θ
	​

.

Choose stereographic coordinates with n
P
	​

 at the origin and n
R
	​

 at δe, where e is a unit vector. The exact identities are

1−n
P
	​

⋅n(x)=
1+x
2
2x
2
	​

,
1−n
R
	​

⋅n(x)=
(1+x
2
)(1+δ
2
)
2∣x−δe∣
2
	​

,dΩ
d
	​

=
(1+x
2
)
d
2
d
d
d
x
	​

.

After x=δu,

A
a,b
	​

=
	​

2
2α−S
δ
2α−2S
(1+δ
2
)
b
×∫
R
2α
	​

(u
2
)
a
[(u−e)
2
]
b
(1+δ
2
u
2
)
S−2α
	​

d
2α
u.
	​

	​

(3)

For real

max(a,b)<α<S,
	​

(4)

one also has 2α>S. Hence

0<(1+δ
2
u
2
)
S−2α
≤1.

The remaining Euclidean bubble integrand is integrable:

u=0:α>a,u=e:α>b,∣u∣→∞:α<S.

Thus dominated convergence applies to the complete angular integral. There is no unaccounted cap or overlap contribution.

Real noninteger dimension

Do not base this solely on an integer-dimensional geometric argument. Since the integrand depends only on the coordinate parallel to e and the perpendicular radius, interpret

∫d
d
uf(u
2
,(u−e)
2
)=Ω
d−2
	​

∫
−∞
∞
	​

dq∫
0
∞
	​

dss
d−2
f(q
2
+s
2
,(q−1)
2
+s
2
),
(5)

with

Ω
d−2
	​

=
Γ((d−1)/2)
2π
(d−1)/2
	​

.

This is a positive two-variable measure for the real dimensions in (4). The stereographic transformation and the preceding bounds hold directly in this parameter representation.

The bubble integral evaluates to

∫
R
2α
	​

(u
2
)
a
[(u−e)
2
]
b
d
2α
u
	​

=π
α
Γ(a)Γ(b)Γ(2α−S)
Γ(S−α)Γ(α−a)Γ(α−b)
	​

.
	​

(6)

It follows by Feynman parametrization, Gaussian integration, and a Beta integral in their common convergence domain. The corresponding dimensionally continued two-denominator angular result is also known exactly. 
DLMF
+1

Now

τ:=sin
2
2
θ
	​

=
2p(z)r(z)
zP⋅R
	​

,δ
2
=
1−τ
τ
	​

=
4
zL
	​

+O(z
2
).

Substituting into (3) gives

A
a,b
	​

∼2
S
z
α−S
π
α
L
α−S
Γ(a)Γ(b)Γ(2α−S)
Γ(S−α)Γ(α−a)Γ(α−b)
	​

.
	​

(7)

This reproduces your angular coefficient exactly. In particular, the Euclidean bubble already contains both singular centers. Do not multiply it by two to count the two caps.

3. Your full coefficient follows without correction

Combining (2) and (7), and cancelling Γ(2α−S), gives

I
a,b
	​

(z,D)=z
β+α−S
[C
a,b
	​

(D)+o(1)]

in the strip, with

C
a,b
	​

(D)=
	​

N(D)σ
P
−a
	​

σ
R
−b
	​

c
2
	​

2
S−D+1
π
α
×
p
0
a
	​

r
0
b
	​

L
α−S
	​

Γ(a)Γ(b)Γ(3α−S)
Γ(S−α)Γ(α−a)Γ(α−b)Γ(α)
	​

,
	​

	​

(8)

where p
0
	​

=p(0), r
0
	​

=r(0).

For arbitrary positive integers a,b, the strip is nonempty. The coefficient identity established there can then be continued meromorphically.

For a=b=1,

β+α−S=3α−3=−3ϵ,

and the initial strip is

1<Reα<2,equivalently−1<Reϵ<0.

Use this strip for the first physical-limit check. The D=10 point used successfully for your previous whole-domain constructors lies outside this strip for a=b=1; there the collinear branch is subleading, so directly dividing the complete integral by its collinear power will not isolate this coefficient.

The dominance of the collinear branch in this strip does not conflict with the earlier large-D hard-limit analysis. The two arguments identify different branches in domains where the corresponding limits are justified.

4. Exact finite-angle result and branch separation

The full angular integral is

A
a,b
	​

(τ;α)=
Γ(α)Γ(2α−S)
2
2α−S
π
α
Γ(α−a)Γ(α−b)
	​

2
	​

F
1
	​

(a,b;α;1−τ).
	​

(9)

This agrees with the massless two-denominator angular formula in Somogyi’s notation after identifying τ=(1−cosθ)/2. 
arXiv

Consequently, your entire restricted master is

I
a,b
	​

(z,D)=N(D)
2
S+1
p(z)
a
r(z)
b
σ
P
−a
	​

σ
R
−b
	​

c
2
	​

π
α
z
β
	​

Γ(3α−S)
Γ(α−a)Γ(α−b)
	​

2
	​

F
1
	​

(a,b;α;1−τ(z)).
	​

(10)

This is useful both as an independent finite-z benchmark and as an exact completeness certificate.

For generic α, the hypergeometric connection formula reads

2
	​

F
1
	​

(a,b;α;1−τ)=
	​

Γ(α−a)Γ(α−b)
Γ(α)Γ(α−S)
	​

2
	​

F
1
	​

(a,b;1+S−α;τ)
+τ
α−S
Γ(a)Γ(b)
Γ(α)Γ(S−α)
	​

2
	​

F
1
	​

(α−a,α−b;1+α−S;τ).
	​

(11)

Thus, when the external invariants are analytic at the edge, the complete answer has precisely the structure

I(z,D)=z
β
F
hard
	​

(z,D)+z
β+α−S
F
coll
	​

(z,D),
	​

(12)

with both coefficient functions locally analytic in z at generic dimension. 
DLMF

This confirms more than the leading limit:

There is no additional independent energy-endpoint branch for this class.

There is no generic-dimensional logarithmic multiplier in either branch.

The leading collinear coefficient is exactly (8).

At exceptional dimensions where α−S becomes an integer, the separate connection terms require a meromorphic limit and logarithms can appear. Near epsilon zero, expansion of z
−3ϵ
 also generates the expected logz terms. Set generic-ϵ Frobenius log coefficients to zero, not the logarithms generated by the Laurent expansion.

For numerical scaling checks, the hard contamination relative to the collinear term is generally

O(z
S−α
),

in addition to analytic O(z) corrections. At D=5, a=b=1, that is O(
z
	​

), not O(z).

5. Exact all-order answers for your three rows

With exactly your normalization

N(D)=(2π)
−5+4ϵ
,

define

G(ϵ)=
Γ(2−2ϵ)Γ(1−3ϵ)
Γ(1+ϵ)Γ(1−ϵ)
4
	​

.
	​

(13)

Gamma recurrence and duplication simplify (8) for a=b=1 to

C
1,1
	​

(ϵ)=
256π
3
(P⋅R)ϵ
2
σ
P
	​

σ
R
	​

	​

(
L
64π
2
	​

)
ϵ
G(ϵ).
	​

(14)

No additional e
γ
E
	​

ϵ
, scale factor, or symmetry factor has been inserted. 
DLMF

Your edge invariants give

L
64
	​

=
3
4
	​

,L
89
	​

=
3
64
	​

,L
105
	​

=12.

Therefore the exact coefficients of z
−3ϵ
 are

C
64
	​

(ϵ)=−
32π
3
ϵ
2
(48π
2
)
ϵ
	​

G(ϵ),
	​

(15)
C
89
	​

(ϵ)=+
128π
3
ϵ
2
(3π
2
)
ϵ
	​

G(ϵ),
	​

(16)
C
105
	​

(ϵ)=−
96π
3
ϵ
2
(16π
2
/3)
ϵ
	​

G(ϵ).
	​

(17)

Since G(0)=1, your three ϵ
−2
 coefficients are exactly

−
32π
3
1
	​

,+
128π
3
1
	​

,−
96π
3
1
	​

.

These Gamma expressions can be expanded to whatever order the primitive-pivot substitution actually requires; there is no need to fix the RHS depth prematurely.

6. An exact angular Feynman-parameter check

Factoring the integer signs outside first, combine the two positive angular denominators:

A
a
B
b
1
	​

=
Γ(a)Γ(b)
Γ(S)
	​

∫
0
1
	​

[xA+(1−x)B]
S
x
a−1
(1−x)
b−1
	​

dx.

For

v(x)=xn
P
	​

+(1−x)n
R
	​

,

one has

∣v(x)∣
2
=1−4τx(1−x).

The result is

A
a,b
	​

=
	​

Ω
2α
	​

Γ(a)Γ(b)
Γ(S)
	​

∫
0
1
	​

dxx
a−1
(1−x)
b−1
×
2
	​

F
1
	​

(
2
S
	​

,
2
S+1
	​

;α+
2
1
	​

;1−4τx(1−x)),
	​

	​

(18)

where

Ω
2α
	​

=
Γ(α+1/2)
2π
α+1/2
	​

.

This follows from the Feynman-parameter combination and the one-vector angular integral; Euler representations provide a direct positive-integrand implementation in the convergence domain. 
DLMF

For a particularly simple regression, take a=b=1, D=5, so α=3/2. Equation (9) reduces to

A
1,1
	​

(τ;3/2)=4π
2
τ(1−τ)
	​

arccos
τ
	​

	​

.
	​

(19)

Its small-τ behavior is

A
1,1
	​

=
τ
	​

2π
3
	​

−4π
2
+O(
τ
	​

),

displaying both the collinear and hard terms.

I also evaluated (18) independently of (9), using

a=b=1,α=
5
7
	​

,τ=0.07.

At 55-digit arithmetic, the two representations agreed to about 32 digits:

A
1,1
	​

=247.5096239106575228749435230438659…

This is a check of the angular formulas, not a test of your repository implementation.

7. Constructor guards and the factor-of-two convention

The reusable constructor should require

p
0
	​

>0,r
0
	​

>0,0<P⋅R
	​

z=0
	​

<∞.

“Distinct null vectors” is insufficient: two different positive multiples of the same null vector have P⋅R=0. Likewise, if P⋅R itself scales to zero, the angular separation has a different power of z, and formula (8) does not apply unchanged.

For denominator normalization, the two conventions are:

Denominator	Invariant-fraction form, x
P
	​

=P⋅k/(P⋅Q)	Energy-angle form
P⋅k	(P⋅Q)x
P
	​

	
2
1
	​

(P⋅Q)y(1−cosθ
P
	​

)
(P+k)
2
 on a unit cut	2(P⋅Q)x
P
	​

	(P⋅Q)y(1−cosθ
P
	​

)
(P−k)
2
 on a unit cut	−2(P⋅Q)x
P
	​

	−(P⋅Q)y(1−cosθ
P
	​

)

Your statement “linear scale P⋅Q, quadratic scale ±2P⋅Q” is correct in the fraction convention. It must not be inserted directly as the energy-angle scale in (2). Equivalently, relative to the formula for (2P⋅k)
−a
, replacing that denominator by (P⋅k)
−a
 multiplies the result by 2
a
.

For integer powers, extract σ
P
−a
	​

σ
R
−b
	​

 before applying the positive Feynman-parameter formula. Combining oppositely signed denominators first obscures the endpoint geometry and can create misleading intermediate zeros. In the convergence strip the angular endpoint singularities are integrable, so the original i0 prescriptions produce the signed ordinary integral there; retain those prescriptions under subsequent analytic continuation.

Explicit Q
2
 powers only shift the integer normal exponent. Factors involving the full subset Q can be pulled outside the integral and evaluated at the edge only when their leading factor is finite and nonzero; otherwise extract their normal valuation first.

8. What this permits you to apply now

For each of the three original rows, match the coefficient of z
−3ϵ
 to (15)–(17), and match the generic logarithmic coefficient at that same exponent to zero. Use the full original-gauge primary jet so that any inherited terms are included before solving for the remaining amplitudes.

On your reported exact projected rank of three, these equations determine the entire remaining −3 input component. After the Laurent-bound-preserving substitution, the expected remaining count is

32 in slope −4+1 exceptional zero-slope series=33,
	​


unless the separately encoded one-dot proof has already removed the exceptional mode.

This constructor can be accepted without a general region campaign. Its completeness follows from an exact energy separation and a globally dominated angular rescaling; the finite-z hypergeometric representation independently confirms both physical branches and the coefficient normalization.