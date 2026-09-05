# Class8 Sourced Correction Review

## Question

_The question was not preserved in the local bridge record._

## Pro response

The calculation is mathematically correct through the displayed O(ε) coefficient of c
1
	​

/M
2
	​

, with remainder O(ε
2
). I found no missing lower-mode, path-gauge, endpoint-regularization, or normalization term that changes the result. The archive does have two reproducibility gaps: the parent two-variable connection is not imported and compared directly in the threshold script, and the three mixed HPL constants are checked numerically rather than by retained exact reduction identities. Neither gap changes the formulas below. 

Class8ThresholdNormalizationRev…

1. Symmetric-path pullback and lower-master rescaling

Along

v(u)=w(u)=
1+u
u
	​

,
du
dv
	​

=
du
dw
	​

=
(1+u)
2
1
	​

,

the unrescaled sourced connection must be

A
u
	​

=
(1+u)
2
A
v
	​

+A
w
	​

	​

.

For the Class‑8 homogeneous block,

K
8
	​

(v,w;ε)=(
1−v
v
	​

)
2ε
F(
1−v
w
	​

;ε),

and the symmetric path gives the two exact identities

1−v
v
	​

=u,
1−v
w
	​

=u.

Consequently,

du
dK
8
	​

	​

=ε[
u
21+R
w
	​

	​

−
1−u
R
s
	​

	​

]K
8
	​

.

This accounts for the 21/u term in the upper block; it is not a missing gauge term.

The lower-master rescaling is

T(ε)=diag(
ε
3
(1−2ε)(2−3ε)(1−3ε)
	​

,
ε
2
(1−2ε)(1−3ε)
	​

,1,1),

with

J=TI.

Since T is independent of u,

du
dT
	​

=0,

and therefore

A
u
(J)
	​

=TA
u
	​

T
−1
.

There is no omitted term of the form
(dT/du)T
−1
. Direct rational reconstruction gives

A
u
(J)
	​

=ε(
u
R
0
	​

	​

+
1−u
R
1
	​

	​

+
1+u
R
−1
	​

	​

),
	​


with precisely the three matrices stored in the archive. The script also verifies

A
u
(J)
	​

/ε−
u
R
0
	​

	​

−
1−u
R
1
	​

	​

−
1+u
R
−1
	​

	​

=0

entry by entry.

The one missing retained check is provenance against the parent system. Production should add the exact identity

T[
(1+u)
2
A
v
	​

+A
w
	​

	​

]
v=w=u/(1+u)
	​

T
−1
−ε(
u
R
0
	​

	​

+
1−u
R
1
	​

	​

+
1+u
R
−1
	​

	​

)=0

using the imported original matrices rather than hard-coded intermediate matrices.

2. The physical zero mode and its normalization

The residue at u=0 has characteristic polynomial

λ(λ+1)(λ−2)(λ−3),

so it is diagonalizable with four distinct eigenvalues. The relevant vectors obey

R
0
	​

e
L
	​

=0,R
0
	​

e
0
	​

=2e
0
	​

,R
0
	​

e
1
	​

=3e
1
	​

,

where

e
L
	​

=
	​

−1
1
0
3
	​

	​

,e
0
	​

=
	​

0
0
1
2
	​

	​

,e
1
	​

=
	​

0
0
1
6
	​

	​

.

Applying the two lower-master rescalings to the exact radial zero mode gives

J
soft
	​

=
ε
2
1−3ε
	​

M
2
	​

e
L
	​

.
	​


Thus

M
2
	​

a
L
	​

	​

=
ε
2
1−3ε
	​

.
	​


This identity can be checked componentwise:

J
1
	​

=−a
L
	​

,J
2
	​

=a
L
	​

,K
8,1
	​

=0,K
8,2
	​

=3a
L
	​

.

Because the R
0
	​

 eigenspaces are distinct and e
L
	​

 lies entirely in the zero eigenspace, this tangential solution contains no independent

u
2ε
e
0
	​

oru
3ε
e
1
	​


nearby cycle. Mixing under the regular u-dependent part of the connection produces analytic integer powers of u, but it does not introduce either noninteger homogeneous mode.

The separation is unambiguous only with the chosen tangential convention:

J
L
	​

(u)=a
L
	​

[e
L
	​

+O(u)],

with zero coefficients of the 2ε and 3ε modes. This is the precise meaning of the “particular solution” used in the threshold matching.

3. Chen ordering and HPL constants

With

f
0
	​

(u)=
u
1
	​

,f
1
	​

(u)=
1−u
1
	​

,f
−1
	​

(u)=
1+u
1
	​

,

define

H
a
1
	​

,…,a
n
	​

	​

(u)=∫
0
u
	​

f
a
1
	​

	​

(t)H
a
2
	​

,…,a
n
	​

	​

(t)dt.

The tangentially normalized Chen solution is

J(u)=[1+
n≥1
∑
	​

ε
n
a
1
	​

,…,a
n
	​

∑
	​

H
a
1
	​

,…,a
n
	​

	​

(u)R
a
1
	​

	​

⋯R
a
n
	​

	​

]J(0).

Therefore the coefficient of a word
(a
1
	​

,…,a
n
	​

) is

e
3
T
	​

R
a
1
	​

	​

⋯R
a
n
	​

	​

e
L
	​

,

where e
3
T
	​

=(0,0,1,0) selects the first Class‑8 component.

The code starts from e
L
	​

 and traverses the word in reverse. This produces

R
a
1
	​

	​

⋯R
a
n
	​

	​

e
L
	​

,

so the multiplication order is correct.

The nonzero coefficients are exactly

weight 1:
weight 2:
weight 3:
	​

H
−1
	​

,
2H
0,1
	​

+2H
−1,−1
	​

,
10H
0,0,1
	​

−6H
0,0,−1
	​

+10H
0,1,1
	​

−2H
0,1,−1
	​

−2H
0,−1,1
	​

+2H
−1,0,1
	​

+4H
−1,−1,−1
	​

.
	​


Writing L=log2, every endpoint value used in the calculation is correct:

H
−1
	​

(1)=L,
H
0,1
	​

(1)=
6
π
2
	​

,H
−1,−1
	​

(1)=
2
L
2
	​

,
H
0,0,1
	​

(1)=ζ
3
	​

,H
0,0,−1
	​

(1)=
4
3
	​

ζ
3
	​

,H
0,1,1
	​

(1)=ζ
3
	​

,

and the three mixed constants are

H
0,1,−1
	​

(1)=−ζ
3
	​

+
4
π
2
L
	​

,
	​

H
0,−1,1
	​

(1)=
8
13
	​

ζ
3
	​

−
4
π
2
L
	​

,
	​

H
−1,0,1
	​

(1)=−
8
5
	​

ζ
3
	​

+
6
π
2
L
	​

.
	​


Finally,

H
−1,−1,−1
	​

(1)=
6
L
3
	​

.

An exact consistency identity is the shuffle relation

H
0,1,−1
	​

(1)+H
0,−1,1
	​

(1)+H
−1,0,1
	​

(1)=H
−1
	​

(1)H
0,1
	​

(1)=
6
π
2
L
	​

.

The individual mixed formulas also follow from the exact Euler integrals

H
0,1,−1
	​

(1)=−∫
0
1
	​

1−t
logtlog(1+t)
	​

dt,
H
0,−1,1
	​

(1)=∫
0
1
	​

1+t
logtlog(1−t)
	​

dt,
H
−1,0,1
	​

(1)=∫
0
1
	​

1+t
Li
2
	​

(t)
	​

dt,

using the standard exact reductions of
Li
2
	​

(1/2) and
Li
3
	​

(1/2).

The archive’s high-precision quadrature checks these values independently, but production should retain these exact reductions as symbolic certificates rather than only the numerical comparisons.

The resulting lower-to-Class‑8 connection coefficient is

C
L
	​

(ε)=
	​

εL+ε
2
(
3
π
2
	​

+L
2
)
+ε
3
(13ζ
3
	​

+
3
π
2
L
	​

+
3
2L
3
	​

)+O(ε
4
).
	​

	​

4. a
part
	​

 and the corrected c
1
	​


Multiplication by the exact lower-mode coefficient gives

a
part
	​

=a
L
	​

C
L
	​

.

Hence

M
2
	​

a
part
	​

	​

=
	​

ε
L
	​

+
3
π
2
	​

+L
2
−3L
+ε(−π
2
−3L
2
+
3
2L
3
	​

+
3
π
2
L
	​

+13ζ
3
	​

)+O(ε
2
).
	​

	​


The homogeneous threshold coefficients are

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

The ordinary soft coefficient is

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

.
	​


The physical threshold condition is

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

=0.

Solving it gives

c
1
	​

=−
A
1
	​

a
part
	​

+A
0
	​

c
0
	​

	​

.

Expanding through the order required in the archive,

M
2
	​

c
1
	​

	​

=
	​

−
4ε
2
3
	​

+
ε
3−L
	​

−3−L
2
+
6
π
2
	​

+3L
+ε(3−π
2
−7ζ
3
	​

−
3
2L
3
	​

+3L
2
+
3
2π
2
L
	​

)+O(ε
2
).
	​

	​


This agrees with both the Mathematica and SymPy calculations.

The homogeneous ratio is also correctly transcribed:

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
),

with a vanishing ε
4
 coefficient.

5. Endpoint and normalization audit

No additional contribution is missing through the stated order:

No lower-mode term is omitted. The physical lower solution has only the zero-eigenvalue coefficient a
L
	​

e
L
	​

; the other lower radial modes have zero physical coefficients in the retained decomposition.

No u=0 endpoint counterterm is omitted. Since

R
0
	​

e
L
	​

=0,

every word ending in 0 vanishes when acting on e
L
	​

. The contributing Chen integrals are therefore well-defined at the tangential base point.

No u=1 regularization constant is omitted in the first Class‑8 component. Every contributing word begins with 0 or −1, never 1. Thus all HPL values listed above have finite ordinary limits at u=1
−
.

No path-gauge term is omitted. The lower rescaling matrix is u-independent.

No Class‑8 scale factor is missing at threshold. Along the symmetric path,

(
1−v
v
	​

)
2ε
=u
2ε
→1(u→1
−
).

No additional Class‑8 integration constant appears. The two-dimensional homogeneous block has only c
0
	​

 and c
1
	​

; the lower zero mode supplies a fixed particular solution, not a third free period.

The branch is fixed. For 0<u<1, the kernels 1/u, 1/(1−u), and 1/(1+u) are real on the chosen path. As elsewhere in the project, the differential system itself is not a substitute for the physical cycle and branch record; here those data are supplied explicitly by the real path and tangential endpoint prescription. 

ExactPfaffianRouteAssessment_20…

The only retained-source deficiencies are:

the current threshold script hard-codes the pulled-back matrices instead of proving their equality to the imported parent two-variable system;

the current zip does not include all three input records required by the Wolfram script;

the mixed HPL constants are independently checked numerically, but their exact reduction identities should also be retained.

These are certificate and packaging defects, not corrections to a
part
	​

 or c
1
	​

.

Compact analytic certificate for Class 77

The following identities are sufficient to propagate the Class‑8 result into the Class‑77 sourced solution:

T[
(1+u)
2
A
v
	​

+A
w
	​

	​

]
v=w=u/(1+u)
	​

T
−1
=ε(
u
R
0
	​

	​

+
1−u
R
1
	​

	​

+
1+u
R
−1
	​

	​

);
	​

R
0
	​

e
L
	​

=0,J
soft
	​

=
ε
2
1−3ε
	​

M
2
	​

e
L
	​

;
	​

C
L
	​

(ε)=e
3
T
	​

[
n≥1
∑
	​

ε
n
a
∑
	​

H
a
	​

(1)R
a
	​

]e
L
	​

	​


with the explicit series displayed above;

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

;
	​


and

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

=0.
	​


Together these imply the displayed Laurent series for c
1
	​

/M
2
	​

. No unresolved Class‑8 period remains through the required depth.
