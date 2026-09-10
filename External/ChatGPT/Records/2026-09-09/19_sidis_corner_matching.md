# Verified GPT-6 Pro review 19

Model gpt-6-pro, message1398c47c-d2b5-4579-b307-7c8b3acf2839, HTTP200.

## Question

Please critically review the concrete implementation of your review 18 for integrated SIDIS NNLO. Repo https://github.com/CongyueZhang2002/factorization-and-loops ; local code is newer. We continue the general card-driven workflow, no reference coefficients or selected-family fixes.

The common exact physical chart now supports rotation and t=r/Z, Z=z+(1-z)r:
s23=S(1-z)r/Z, s12=S z u/Z, s13=S z(1-u)/Z;
2p.k_i=J{z,(1-z)Y,(1-z)(1-Y)};
Y=r+u-2ru-2sqrt[r(1-r)u(1-u)]cos(phi).
The normalized measure is V3(z) z^alpha Z^(-2alpha) dmu_alpha(r)dmu_alpha(u)dmu_(alpha-1/2)(b), alpha=1-eps.
Independent exact Gram determinant, Jacobian and eight direct polynomial moment checks pass.

The 42 actual q-q masters all have unit cuts. The uniform rho=1-x proof allows only rho^(integer-2eps). The 42D DE residue sectors have dimensions 25 (0), 1 (-eps), 16 (-2eps), with no logarithms in these rho sectors. Mapping back and imposing coefficients below each physical leading power gives three additional exact constraints. Closure under the z derivative preserves rank3, giving a 13D tangential DE. The 42 physical leading-coefficient rows have full column rank13.
At sigma=1-z, exact local normalization gives 7 directions of exponent0 (one Jordan chain), 5 of exponent -2eps, 1 of exponent -3eps.

Our rotated corner acceptance rule permits positive ordinary factors only proportional, by a factor independent of angular variables, to:
r,u,1-u,Y,1-Y,z,1-z,Z,1-(1-z)Y,z+(1-z)Y, and ONE additive gauge factor z*u+(1-z)*r.
Polynomial numerators are arbitrary finite polynomials after exact collection. The complementary gauge can be handled by u->1-u,Y->1-Y. A denominator (1-r) is deliberately rejected: your core assumes no singularity at that radial endpoint, and I did not want to assert the same two Mellin pole families in a larger class without proof. If both additive gauges remain, reject.
After stripping powers of sigma, all smooth factors have uniformly bounded Taylor remainders for small positive sigma.

For each such actual recoil integral, the code records the COMPLETE generic-eps slope set {-2}, or {-2,-3} if an additive denominator is present (some coefficients may vanish). This lets us exclude the seven exponent-zero modes by the full-rank observable map above, leaving six constants. Please scrutinize whether this slope/completeness claim really follows for the stated accepted class, including its polynomial numerators and simultaneous u,Y endpoint factors.

Hard-series coefficients: Taylor-expand the rational scalar integrand and the smooth measure z^(1-2eps) Z^(-2+2eps), KEEP sigma^(1-2eps) unexpanded; evaluate each coefficient by spherical convolution. Partial fractions in u,Y reduce each endpoint term to Gamma or 3F2(1). The general normalized convolution used is
C_alpha(b,c;r)=Gamma(2alpha)Gamma(alpha-b)Gamma(alpha-c)/(Gamma(alpha)^2 Gamma(2alpha-b-c)) * 2F1(b,c;alpha;1-r).
The remaining radial beta integration gives 3F2, with complement swaps changing 1-r to r.
The hard Taylor series is the integer Mellin-pole family, not a claimed uniform expansion across u=0 when h>0.

For the leading additive-endpoint branch, remove [z*u+sigma*r]^(-h) from the scalar integrand. Take its leading sigma coefficient, then write its leading u behavior as u^d A(r,Y). The extra exponent is eta=alpha+d-h. Its normalized angular coefficient is
Gamma(alpha+d)Gamma(h-alpha-d)/(Gamma(h) B(alpha,alpha))
  * < r^eta A(r,Y=r) >_r,
where the last average uses the normalized Beta(alpha,alpha) measure.
All source normalization factors are restored. This agrees algebraically with your leading formula (20); does it remain sufficient for an arbitrary accepted polynomial numerator plus the permitted endpoint denominators? We record next branch power eta+1, without dropping the suppressed branch at negative eps. Higher endpoint-branch terms are not yet evaluated.

The leading hard coefficients and leading extra branch have exact matching rank5/6. Adding the first subleading hard coefficient still gives rank5: four hard constants and one gauge constant. The missing null vector is exactly one of the five hard-sector amplitude columns. We are extending the hard coefficients further, rather than assuming its value zero; the DE rank determines sufficient physical data.

Please flag any logical gaps in the full-slope exclusion, the two-family remainder statement, or the leading endpoint formula. Also propose a sharp inexpensive independent check of the potentially suppressed branch beyond polynomial moments (we plan a high-D convergent beta integral with an exact 2F1 representation and small positive sigma). The implementation must remain general and reject factors outside its proof.


## Response

The restricted denominator class supports the slope envelope {−2,−3}, but the leading endpoint extractor is not general as currently described. Taking the leading σ-coefficient first and then its leading u-behavior can miss an earlier endpoint contribution. The accepted numerator zu
2
+σ provides a counterexample.

The structural slope argument and the extraction of the first nonzero coefficient should therefore be separated. The former can justify excluding the seven slope-zero modes; the latter needs a weighted endpoint expansion before its output is used as physical matching data.

1. The two-slope envelope is justified for the restricted class

Set

λ=
z
σ
	​

,z=
1+λ
1
	​

,B
0
	​

=B(α,α),α=1−ϵ.

Then

(zu+σr)
−h
=z
−h
(u+λr)
−h
.

Your remaining nonmonomial factors are uniformly regular near σ=0:

Z=1−σ(1−r),1−σY,z+σY=1−σ(1−Y).

Their finite Taylor expansions introduce only polynomial angular numerators and integer powers of σ. The exact measure contributes the known σ
1−2ϵ
; its

z
1−2ϵ
Z
−2+2ϵ

factor is smooth there.

After polynomial expansion and partial fractions in u and Y, a sufficient core is

Q
±
	​

(λ)=⟨r
−a
u
−b
(1−u)
−c
Y
±
−m
	​

(u+λr)
−h
⟩,
	​

(1)

where Y
+
	​

=Y, Y
−
	​

=1−Y, and the exponents are integers. Polynomial factors correspond to nonpositive powers or finite sums of these kernels.

Here “polynomial numerator” must mean a polynomial in the full-scalar generators r,u,Y, with the declared external factors restored separately. Arbitrary dependence on the residual azimuth beyond its occurrence in Y is a larger class.

1.1 A Mellin proof that includes the simultaneous endpoints

For h>0, use

Q
±
	​

(λ)=
2πiΓ(h)
1
	​

∫
C
	​

dwΓ(−w)Γ(h+w)λ
w
M
±
	​

(w),
(2)

initially with −h<ℜw<0 and sufficiently large ℜα. This is the standard Barnes decomposition of the additive denominator. 
DLMF

Integrate r and the azimuth first, using your convolution with the two polar directions interchanged. Define

K
α
	​

(s,m)=
Γ(α)
2
Γ(2α−s−m)
Γ(2α)Γ(α−s)Γ(α−m)
	​

.

Then

M
+
	​

(w)=
M
−
	​

(w)=
	​

B
0
	​

K
α
	​

(a−w,m)
	​

∫
0
1
	​

duu
α−b−h−w−1
(1−u)
α−c−1
×
2
	​

F
1
	​

(a−w,m;α;1−u),
B
0
	​

K
α
	​

(a−w,m)
	​

∫
0
1
	​

duu
α−b−h−w−1
(1−u)
α−c−1
×
2
	​

F
1
	​

(a−w,m;α;u).
	​

	​

(3)

These formulas account for the simultaneous r,u,Y endpoints; they do not freeze r in a compact subinterval.

At u=0:

In M
−
	​

, the hypergeometric function has an ordinary Taylor series. The pole family is

w=α−b−h+n,n=0,1,….

In M
+
	​

, the connection formula has a Taylor branch and a branch proportional to

u
α−a−m+w
.

Multiplying the latter by the explicit power of u gives

u
2α−a−b−h−m−1
,

whose exponent is independent of w. It does not generate another right-hand Mellin family. The connection formula, including its limiting cases, is essential here. 
DLMF

Equivalently, after the last beta integration, put

A=α−b−h−w,B=α−c.

The two 
3
	​

F
2
	​

(1) factors have excesses

Δ
+
	​

Δ
−
	​

	​

=2α−a−b−h−m,
=2α−a−c−m+w.
	​

	​

(4)

In the initial sufficiently high-D domain, these do not supply additional right-hand poles. The remaining right-pole families are

w=n,w=α−b−h+n.
	​

(5)

There is an important implementation distinction: dividing out bottom-parameter gamma factors does not make a 
3
	​

F
2
	​

(1) entire in all its parameters. At argument one, its excess still controls convergence and additional parameter singularities. Your proof should explicitly use (4), not merely “regularized hypergeometric functions have no poles.” 
DLMF

When continuing in ϵ, preserve the Barnes contour’s separation of the original pole families. Do not set ϵ near zero and reclassify poles solely according to their new numerical real parts.

1.2 Why rejecting 1−r is a substantive restriction

The potentially troublesome corner

r→1,u→0,Y→1

is present even in your accepted class. However, without an independent singular factor at r=1, the angular convolution turns it into the M
−
	​

 expression in (3), which is analytic in u near zero apart from the displayed Mellin power.

Thus that corner does not require a third small-λ family here.

A factor (1−r)
−d
 would change the angular convolution and can prevent this conclusion. Your rejection is mathematically meaningful, rather than merely a performance restriction.

For the complementary gauge, the scalar replacement

u↦1−u,Y↦1−Y

also corresponds to reversing the relative cosine, or b
angle
	​

↦1−b
angle
	​

. The beta measure is invariant. Encode that complete transformation even if the scalar implementation no longer exposes the angular variable.

1.3 What the slope record should claim

After restoring integer endpoint powers and the common σ
1−2ϵ
,

the first family in (5) has slope −2;

the second has slope −3.

Polynomial numerators shift integer onsets and can cancel coefficients, but do not add another generic-ϵ slope.

Therefore the correct metadata is a proved allowed slope envelope

{−2}or{−2,−3},

not a statement that every listed slope occurs with a nonzero coefficient.

The seven slope-zero modes can be excluded if the following are all true:

Every physical leading-coefficient function is inside this proved class.

Every explicit noninteger power in its normalization has been included in its slope assignment.

The map from the 13 tangential functions to the 42 physical functions is injective at generic ϵ,z.

That map preserves slope classes, apart from explicitly tracked powers.

Under these conditions, a nonzero slope-zero solution—including its Jordan logarithm—cannot disappear from all physical functions. This is an all-orders slope argument, not an inference from the first few boundary coefficients.

2. The leading endpoint formula is correct for one homogeneous term

Suppose, after extracting explicit external powers, a term has the form

(u+λr)
h
u
d
A(r,Y)
	​

.

Set u=λrv. At fixed interior r,

Y⟶r,

and the endpoint contribution is

λ
η
Γ(h)B
0
	​

Γ(α+d)Γ(h−α−d)
	​

⟨r
η
A(r,r)⟩
r
	​

,η=α+d−h.
	​

(6)

There is no additional sign. The normalized u-measure supplies the 1/B
0
	​

; the remaining average uses the normalized radial beta measure.

The v-integral initially requires

0<ℜ(α+d)<ℜh.

When the endpoint branch is suppressed in the high-D domain, this integral over v∈(0,∞) generally does not converge literally. Formula (6) then means its meromorphic continuation, justified by the complete Euler/Barnes identity or equivalent endpoint subtraction—not a separately convergent region integral. Euler integral representations make this distinction explicit. 
DLMF

Simultaneous Y and 1−Y denominator factors are allowed: A(r,r) can have poles at both radial endpoints, and its radial beta integral is continued accordingly. The full Mellin argument above is what ensures that this continuation belongs to the complete integral.

If A(r,r)=0, equation (6) correctly gives a zero coefficient. It does not determine the first nonzero endpoint power.

3. The actual gap: sequential valuation can miss an earlier term

Consider the accepted scalar factor

zu+σr
zu
2
+σ
	​

=
u+λr
u
2
+λ
	​

.
	​

(7)

There is no forbidden denominator and no removable common factor.

Your proposed sequence does this:

Take the leading σ-coefficient of the numerator: u
2
.

Assign d=2, h=1.

Predict the first candidate endpoint power

λ
α+1
.

But the subleading numerator term λ gives

λ⟨
u+λr
1
	​

⟩,

whose endpoint branch begins at

λ
α
,
	​


one power earlier.

Thus “leading in σ, then leading in u” is not an admissible general endpoint valuation. This does not invalidate the slope envelope: both contributions have the same epsilon slope. It invalidates the claimed first endpoint coefficient and any remainder starting after it.

3.1 Use the endpoint scaling before selecting the leading numerator

The appropriate operation is

u=λrv
	​


on the complete numerator and smooth factors, followed by expansion in λ.

Equivalently, use a weighted expansion with

wt(λ)=wt(u)=1,

and the exact angular dependence

Y−r=u(1−2r)−2
r(1−r)u(1−u)
	​

c.

The square-root term has weight 1/2, but odd powers of c vanish only after the angular average. Do not discard it beforehand.

For a smooth A(r,Y), the first angular jet is

⟨A(r,Y)⟩
c
	​

=
	​

A(r,r)
+u[(1−2r)∂
Y
	​

A+
α
r(1−r)
	​

∂
Y
2
	​

A]
Y=r
	​

+O(u
2
).
	​

	​

(8)

This follows from

⟨c⟩=0,⟨c
2
⟩=
2α
1
	​

.

For example,

⟨(Y−r)
2
⟩
c
	​

=u
2
(1−2r)
2
+
α
2
	​

r(1−r)u(1−u).
	​

(9)

The numerator vanishes upon setting Y=r, but its first averaged term is O(u), not O(u
2
).

Include the expansion of (1−u)
α−1
 as well. At first order it contributes

−(α−1)u.

The smooth z,Z factors and the z
−h
 removed from the original gauge denominator also enter the same weighted jet.

3.2 A useful implementation formula

Choose a common lowest u-power d
0
	​

, determined from the full accepted rational expression. After the angular average and the smooth u-weight expansion, write

F
(λ,r,u)=u
d
0
	​

j,k≥0
∑
	​

λ
j
u
k
F
jk
	​

(r).

Then the endpoint series is generated by

E(λ)∼
j,k≥0
∑
	​

	​

λ
j+α+d
0
	​

+k−h
×
Γ(h)B
0
	​

Γ(α+d
0
	​

+k)Γ(h−α−d
0
	​

−k)
	​

⟨r
α+d
0
	​

+k−h
F
jk
	​

(r)⟩
r
	​

.
	​

	​

(10)

Collect every contribution with the same total j+k before determining whether that coefficient vanishes. This is a finite calculation to any requested order and reuses the existing beta moments.

With this construction, recording the next possible endpoint power one integer higher is appropriate. With the current sequential extraction, it is not.

4. Separate a two-family theorem from a remainder certificate

The slope classification supplies the form

I(σ,ϵ)=σ
M−2ϵ
[
n
∑
	​

H
n
	​

(ϵ)σ
n
+σ
α−b−h
n
∑
	​

E
n
	​

(ϵ)σ
n
],
(11)

with integer shifts collected consistently. It does not, by itself, certify the error after retaining only one term of the second series.

For a specified truncation, establish either:

a Barnes-contour shift past all required poles, with the remaining integral bounded beyond the requested order; or

finite Euler endpoint subtractions with a controlled remainder.

The hard terms are residues of the integer pole family. They are not obtained by assuming that the original integrand’s Taylor expansion converges uniformly through u=0. Expansion-by-regions arguments likewise require coverage and overlap control, rather than a sum of plausible local scalings. 
arXiv

At generic ϵ, the two families are distinct. When they collide after continuation, poles in the separate coefficients produce logarithms and cancellations. Keep the generic-ϵ powers until the relevant terms have been combined.

A useful software distinction is:

AllowedSlopes:
ComputedBranchCoefficients:
NextPossibleOrder:
RemainderCertifiedThrough:
	​

structurally proved,
actually evaluated,
deduced from the weighted expansion,
supported by a subtraction/contour bound.
	​


Do not assign the last property merely because the next candidate exponent is known.

5. A sharp exact check of the suppressed branch

Your proposed high-D check can be made particularly simple. Choose

α=
2
3
	​

,ϵ=−
2
1
	​

,D=5,

and define the normalized core integral

Q(λ)=⟨
u+λr
1
	​

⟩
r,u
	​

,

where both variables have Beta(3/2,3/2) measures. The azimuth integrates to one.

The inner integral is elementary:

∫
0
1
	​

dμ
3/2
	​

(u)
u+η
1
	​

=4+8η−8
η(1+η)
	​

.
	​

(12)

The remaining radial Euler integral gives

Q(λ)=4(1+λ)−
15π
256
	​

λ
	​

2
	​

F
1
	​

(−
2
1
	​

,2;
2
7
	​

;−λ).
	​

(13)

This follows directly from the beta integral, with no amplitude or master-table input. The Euler representation and hypergeometric continuation fix its positive-λ branch. 
DLMF
+1

It contains both branches:

Q(λ)=4+4λ+Kλ
1/2
+
7
2K
	​

λ
3/2
+O(λ
5/2
),K=−
15π
256
	​

.
(14)

Therefore test both limits

λ
	​

Q−4−4λ
	​

⟶K,
	​


and

λ
3/2
Q−4−4λ−K
λ
	​

	​

⟶
7
2K
	​

.
	​


I evaluated the independent one-dimensional beta integral obtained from (12) and compared it with (13), using 45-digit arithmetic:

λ	(Q−4−4λ)/
λ
	​


10
−2
	−5.44798434518363
10
−4
	−5.43264393558010
10
−6
	−5.43249027634274
Limit	−5.43248872420336

The quadrature and hypergeometric expression agreed to the working precision. This numerical comparison supplements the exact derivation; it is not the proof of the general slope theorem.

Reuse the same check to expose the valuation bug

For the numerator in (7), polynomial division gives the exact identity

⟨
u+λr
u
2
+λ
	​

⟩=
2
1
	​

−
2
λ
	​

+λQ(λ)+λ
2
⟨
u+λr
r
2
	​

⟩.
	​

(15)

At α=3/2, its first endpoint term is

Kλ
3/2
,

whereas the leading-σ-then-leading-u algorithm predicts its first candidate at λ
5/2
.

This is a regression for the endpoint compiler itself, not merely for the beta integration routine.

Equation (9) supplies a second small test for the angular jet. Together, they test two failure modes that ordinary polynomial moments do not: competing σ,u valuations and a vanishing pointwise angular limit with a nonzero averaged next term.

6. Target the missing hard constant using the DE before integrating further

Your decision not to set the remaining constant to zero is correct. But rather than extend every hard coefficient by another order, use the known null direction to identify precisely where new information first appears.

Let v(ϵ) span the current one-dimensional matching nullspace. Since it lies entirely in the hard sector, construct its formal solution from the tangential DE:

f
v
	​

(σ,ϵ)=σ
−2ϵ
n≥0
∑
	​

f
v,n
	​

(ϵ)σ
n
.

Apply the exact raw physical-observable map R(σ,ϵ):

Rf
v
	​

=σ
−2ϵ
n
∑
	​

b
v,n
	​

(ϵ)σ
n
.

Find the first n and physical row for which

b
v,n
	​


=0.

This is an exact recurrence and rational-algebra calculation. It identifies which physical hard coefficient will increase rank before you evaluate its Gamma/
3
	​

F
2
	​

 expression.

Among rows appearing at that order, choose the cheapest accepted kernel decomposition. A slightly later Gamma-only row may be cheaper than the earliest row involving several 
3
	​

F
2
	​

(1) derivatives.

At generic ϵ, additional slope-−3 data cannot determine a null vector belonging entirely to the slope-−2 solution space. Those data are useful consistency checks, but they should not be the next expensive integration aimed at closing this particular rank deficit.

After obtaining rank six, verify an unused physical coefficient and recheck the required epsilon depths of the inverse matching matrix. Full rank at generic epsilon does not imply that only the nominal boundary Laurent window is needed.

Recommended changes

Keep the restricted acceptance rule and its two-slope envelope. Attach the Mellin argument (3)–(5), including the excess check and contour continuation, to that claim. Rejecting 1−r and simultaneous additive gauges is appropriate for the present theorem.

Replace sequential leading-term extraction by a joint weighted endpoint jet. The current formula is a correct coefficient rule, but not a general algorithm for finding the first coefficient of an arbitrary accepted numerator. Equations (7), (10), and (15) make the distinction concrete.

Use the tangential DE to select the next physical hard coefficient. This should close the remaining rank deficit without a broad increase in boundary integration depth.

The normalization stated for the hard measure is consistent:

z
−ϵ
×z
α
=z
1−2ϵ
,

with σ
1−2ϵ
 kept separate. Preserve the additional z
−h
 when converting the gauge denominator to u+λr, and restore all integer scale factors before matching. None of these boundary manipulations supplies a new i0 proof or changes the existing cut definition.