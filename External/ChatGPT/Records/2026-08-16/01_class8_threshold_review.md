# Class8 Threshold Review

## Question

# Class-8 threshold normalization: exact follow-up

Please continue the existing FACET Class-77 conversation and inspect the
attached source archive.  This is a focused check of the previous threshold
argument, not a request for a new broad derivation.

The exact generic-ray decomposition of the stored Class-77 lower system gives

\[
\frac{c_0(\varepsilon)}{M_2}
=-\frac{3(3\varepsilon-1)}
{4\varepsilon^2(1+\varepsilon)}
\]

for the one-dimensional radial eigenspace with eigenvalue (2\varepsilon)
and Class-8 vector ((1,2)^T).  The retained hard-region projection also
contains a (3\varepsilon) mode proportional to ((1,6)^T), but that
coefficient is not accepted as the physical weighted period because the
hard-region construction omits the relevant epsilon-weighted subregion.

Your threshold condition gives

\[
\frac{c_1}{c_0}
=-\frac{\Gamma(1-\varepsilon)^2}
{\Gamma(1-3\varepsilon)\Gamma(1+\varepsilon)}.
\]

An independent SymPy check verifies the exact radial eigenspaces, the absence
of (2\varepsilon) and (3\varepsilon) eigenvalues in the first seven lower
masters, the hypergeometric connection coefficient, and the regular-mode
cancellation.  It therefore gives

\[
\frac{c_1(\varepsilon)}{M_2}
=\frac{3(3\varepsilon-1)\Gamma(1-\varepsilon)^2}
{4\varepsilon^2(1+\varepsilon)
 \Gamma(1-3\varepsilon)\Gamma(1+\varepsilon)}.
\]

There are two points requiring your exact review.

1. Confirm that the generic radial hard-region mode is the correct source of
   (c_0).  The strict edge (w=0) is not adequate: there the
   (2\varepsilon) eigenspace is two-dimensional and cannot distinguish the
   Gauss ordinary vector.
2. Confirm or refute the mode-by-mode argument that the lower-sector
   particular solution cannot alter the (2\varepsilon) or
   (3\varepsilon) Class-8 nearby cycles because the lower radial spectrum is
   \(\{0,-\varepsilon,-3\varepsilon,-4\varepsilon\}\).  If that argument is
   insufficient at the (u\to1^-\) threshold, derive the exact regular
   threshold coefficient (a_{\rm part}(\varepsilon)) from the attached
   sourced lower system and give the corrected (c_1\).

Please also check a transcription issue in your preceding answer.  For the
normalization in the attached derivation,

\[
-\frac{\Gamma(1-\varepsilon)^2}
{\Gamma(1-3\varepsilon)\Gamma(1+\varepsilon)}
=-1+\frac{2\pi^2}{3}\varepsilon^2
 +8\zeta_3\varepsilon^3+O(\varepsilon^5),
\]

not the printed (3\pi^2\varepsilon^2/2).

Return a compact analytic certificate: the accepted (c_0), (c_1), the
precise reason the particular solution does or does not enter, and the exact
identity that should be checked in the implementation.

## Pro response

I inspected the exact threshold-normalization archive and its independent SymPy check. The archive verifies the radial eigenspaces, the 2ε projection, the Gauss connection coefficients, and the stated Gamma-ratio expansion. 

Class8ThresholdNormalizationRev…

1. Accepted ordinary nearby-cycle coefficient

The generic-ray coefficient is the correct c
0
	​

:

M
2
	​

c
0
	​

(ε)
	​

=−
4ε
2
(1+ε)
3(3ε−1)
	​

.
	​

(1)

The reason is stronger than the hard-region interpretation alone. In the full radial residue, the 2ε eigenspace is one-dimensional and is supported only on the Class‑8 entries,

b
2ε
	​

∝(0,…,0,1,2)
T
.

The first seven masters have spectrum

specR
lower
	​

={0,−ε,−3ε,−4ε},

so for generic ε,

2ε∈
/
specR
lower
	​

.

Moreover, no nonnegative integer shift of a lower exponent equals 2ε identically in ε. Therefore the lower-sector source cannot generate a term with the exact generic-ray power τ
2ε
. Its coefficient is an unambiguous homogeneous Class‑8 nearby-cycle coefficient.

The strict edge w=0 is insufficient: it collapses the normal-crossing grading and does not distinguish the ordinary e
0
	​

 mode from information carried transversely by the u
ε
e
1
	​

 mode. The generic-ray decomposition is therefore the correct source of c
0
	​

.

2. What the lower-spectrum argument proves—and what it does not

The archive currently makes the inference

{2ε,3ε}∩specR
lower
	​

=∅⟹a
part
	​

(ε)=0.

That implication is not valid.

The spectral nonresonance proves the local statement at the soft corner u=0:

Coeff
τ
2ε
	​

F
part
	​

=0,Coeff
τ
3ε
	​

F
part
	​

=0.
(2)

Thus the lower-sector particular solution does not alter the definitions of c
0
	​

 and c
1
	​

 as the ordinary and weighted nearby-cycle coefficients.

It does not prove that analytic continuation of that particular solution to the distinct singular point u=1 has zero regular threshold coefficient. A solution made entirely from other Frobenius powers at u=0 can acquire a nonzero exponent-zero component when continued to u=1.

Therefore the archive’s assignment

ParticularRegularCoefficientInClass8HomogeneousSectors -> 0

is not established by the displayed spectrum.

3. Exact sourced threshold relation

Let

Φ(u;ε)=(Φ
0
	​

(u;ε),Φ
1
	​

(u;ε))

be the normalized Class‑8 fundamental matrix, whose first components are

f
0
	​

(u)=
2
	​

F
1
	​

(ε,2ε;1−ε;u),
f
1
	​

(u)=u
ε
2
	​

F
1
	​

(2ε,3ε;1+ε;u).

Let the sourced one-variable equation be

du
dF
	​

=A
8
	​

(u,ε)F+S
8
	​

(u,ε),
(3)

where S
8
	​

 is obtained from the first seven solved lower masters. Choose the tangential particular solution with no 2ε or 3ε nearby cycle at u=0:

F
part
	​

(u)=Φ(u)Reg∫
0
+
u
	​

Φ(t)
−1
S
8
	​

(t)dt.
(4)

Its first component has a threshold expansion

f
part
	​

(u)=a
part
	​

(ε)+O((1−u)
1−4ε
)+higher regular powers.
(5)

The two homogeneous columns have regular threshold coefficients

A
0
	​

(ε)=
Γ(1−2ε)Γ(1−3ε)
Γ(1−ε)Γ(1−4ε)
	​

,
A
1
	​

(ε)=
Γ(1−ε)Γ(1−2ε)
Γ(1+ε)Γ(1−4ε)
	​

.

The physical absence of the exponent-zero threshold mode is therefore

a
part
	​

(ε)+A
0
	​

(ε)c
0
	​

(ε)+A
1
	​

(ε)c
1
	​

(ε)=0.
	​

(6)

Hence the exact weighted coefficient is

c
1
	​

(ε)=−
Γ(1−3ε)Γ(1+ε)
Γ(1−ε)
2
	​

c
0
	​

(ε)−
A
1
	​

(ε)
a
part
	​

(ε)
	​

.
	​

(7)

Dividing by M
2
	​

 and inserting Eq. (1),

M
2
	​

c
1
	​

(ε)
	​

=
	​

4ε
2
(1+ε)Γ(1−3ε)Γ(1+ε)
3(3ε−1)Γ(1−ε)
2
	​

−
Γ(1+ε)Γ(1−4ε)
Γ(1−ε)Γ(1−2ε)
	​

M
2
	​

a
part
	​

(ε)
	​

.
	​

	​

(8)

The Gamma-only expression proposed in the prompt is correct if and only if

a
part
	​

(ε)=0.
	​

(9)

The attached calculations do not yet prove Eq. (9). They prove only Eq. (2).

4. Exact expression that must be evaluated for a
part
	​


The regular coefficient can be obtained without a new independent Class‑8 boundary period. It is a determined functional of the already solved lower sectors:

\boxed{ a_{\rm part}(\varepsilon) = \operatorname{Reg}_{u\to1^-} \operatorname{Coeff}_{(1-u)^0} \left[ e_1^{\mathsf T}_{\rm scalar} \, \Phi(u) \operatorname{Reg} \int_{0^+}^{u} \Phi(t)^{-1}S_8(t)\,dt \right], } \tag{10}

where e_1^{\mathsf T}_{\rm scalar}=(1,0) selects the first canonical component.

Equivalently, if the integral vector in Eq. (4) has a finite regularized limit

q(1;ε)=Reg∫
0
+
1
−
	​

Φ(t)
−1
S
8
	​

(t)dt=(
q
0
	​

q
1
	​

	​

),

then

a
part
	​

=A
0
	​

q
0
	​

+A
1
	​

q
1
	​

.
	​

(11)

The present archive does not contain the solved first-seven-master functions transported to u=1, nor an evaluated version of Eq. (10). It therefore does not support replacing a
part
	​

 by zero. The lower-chart source is retained, but its threshold continuation has not been carried out.

This does not introduce a new free constant: a
part
	​

 is fixed completely by the lower-sector analytic solution and the chosen tangential normalization at u=0.

5. Correct Gamma-ratio expansion

The transcription correction is right:

−
Γ(1−3ε)Γ(1+ε)
Γ(1−ε)
2
	​

=−1+
3
2π
2
	​

ε
2
+8ζ
3
	​

ε
3
+O(ε
5
).
	​

(12)

The coefficient of ε
4
 vanishes. The archive’s independent checker verifies this exact series.

Compact analytic certificate

The presently justified certificate is:

M
2
	​

c
0
	​

	​

=−
4ε
2
(1+ε)
3(3ε−1)
	​

,
	​


because the 2ε radial eigenspace is one-dimensional and absent from the first-seven-master spectrum.

The weighted coefficient is

M
2
	​

c
1
	​

	​

=
4ε
2
(1+ε)Γ(1−3ε)Γ(1+ε)
3(3ε−1)Γ(1−ε)
2
	​

−
Γ(1+ε)Γ(1−4ε)
Γ(1−ε)Γ(1−2ε)
	​

M
2
	​

a
part
	​

	​

.
	​


The lower-spectrum argument proves that F
part
	​

 carries neither the 2ε nor the 3ε soft nearby cycle. It does not prove that its analytically continued exponent-zero coefficient at u=1 vanishes.

The implementation must check the exact identity

a
part
	​

+A
0
	​

c
0
	​

+A
1
	​

c
1
	​

=0
	​

(13)

together with

du
dF
part
	​

	​

−A
8
	​

F
part
	​

−S
8
	​

=0,
(14)

and the two soft normalization conditions

Coeff
u
0
	​

[(
2
3
	​

,−
4
1
	​

)F
part
	​

]=0,
Coeff
u
ε
	​

[(−
2
1
	​

,
4
1
	​

)F
part
	​

]=0.
(15)

Only if the exact evaluation of Eq. (10) gives a
part
	​

=0 may the Gamma-only expression in the prompt be promoted to the final Class‑8 weighted period.

## Sources sent to Pro

- [class8thresholdnormalizationreview.zip](Sources/01_class8_threshold_review/class8thresholdnormalizationreview.zip)
