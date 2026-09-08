# Nonlinear-divisor pole orders

## Question

The full 91-family run continues on eight shared cores. Three families (CF13, CF18, CF408) hit the same epsilon-zero homogeneous-preparation gap. Others continue and failed fresh DEs are retained. We reject their unresolved Inactive[Integrate] DSolve expressions rather than claim completion.

Below is the entire representative exact 3x3 epsilon-zero block, variables {v,w}. Existing rational/square-root horizontal-section search uses h=sqrt(P) p/Q, Q initially the least common multiple of matrix denominators, with simple linear-divisor residue bounds, and bounded polynomial degree. It does not increase Q at nonlinear quadratic divisors. This may omit sections with Delta^(-3/2), since the initial Q contains Delta only once. I am testing the inexpensive positive ansatz obtained by multiplying Q once by its nonlinear divisor(s), still accepting only exact all-coordinate identities; this is candidate search, not a nonexistence certificate.

A trial to stop at a strictly triangular zero-order connection did not resolve these blocks. Trying the more complicated coordinate first reached a 90-second probe cap; it is not promoted. I want to avoid spending hours on arbitrary DSolve retries.

Please analyze this specific block and recommend the cheapest general preparation improvement. Is the missing quadratic-divisor pole order the likely gap? If necessary, derive an explicit algebraic horizontal section or a small invariant subspace that a general bounded search should find. We need a triangular epsilon-zero reduction sufficient for finite quadratures, not necessarily a complete homogeneous fundamental matrix. Do not replace the requested explicit finite solution by a lazy ODE generator. Repository context: https://github.com/CongyueZhang2002/factorization-and-loops ; local edits are not committed.

Exact input (Wolfram notation):

<|"Variables" -> {v, w}, "ConnectionMatrices" -> 
  {{{-2/v, (1 - v - 2*w + v*w + w^2)/(v^2*(-1 + v - w)), 
     (-1 + v + 2*w + v*w - w^2)/(v*(-1 + v - w))}, 
    {0, (1 - v + w)/(v*(-1 + v - w)), 0}, 
    {(-1 + v - w)/(v*(1 - 2*v + v^2 - 2*w - 2*v*w + w^2)), 
     (-2*(-1 + 2*v - v^2 + w - 3*v*w + v^2*w + w^2 + v*w^2 - w^3))/
      (v^2*(-1 + v - w)*(1 - 2*v + v^2 - 2*w - 2*v*w + w^2)), 
     (-2*(v - 2*v^2 + v^3 + 4*v*w - 2*v^2*w + v*w^2))/
      (v*(-1 + v - w)*(1 - 2*v + v^2 - 2*w - 2*v*w + w^2))}}, 
   {{0, (1 - w)/(v*(-1 + v - w)), (-1 - v + w)/(-1 + v - w)}, 
    {1/((-1 + w)*w), (-1 + v + 2*w - v^2*w - w^2 + v*w^2)/
      (v*(-1 + v - w)*(-1 + w)*w), (-1 + 2*v - v^2 + 2*w + 2*v*w - w^2)/
      ((-1 + w)*w*(1 - v + w))}, {(-1 + 2*v - v^2 + w + v*w)/
      (v*w*(1 - 2*v + v^2 - 2*w - 2*v*w + w^2)), 
     (1 - 3*v + 3*v^2 - v^3 - 3*w + 8*v*w - 6*v^2*w + v^3*w + 3*w^2 - 
       3*v*w^2 + 3*v^2*w^2 - w^3 - 2*v*w^3)/(v^2*(-1 + v - w)*w*
       (1 - 2*v + v^2 - 2*w - 2*v*w + w^2)), 
     (-1 + 4*v - 6*v^2 + 4*v^3 - v^4 + 3*w - 7*v*w - v^2*w + 5*v^3*w - 
       3*w^2 - 7*v^2*w^2 + w^3 + 3*v*w^3)/(v*(-1 + v - w)*w*
       (1 - 2*v + v^2 - 2*w - 2*v*w + w^2))}}}|>


## Pro response

Yes—the missing quadratic-divisor pole order is a genuine gap for this block, not merely a plausible explanation. One extra factor of Δ admits an exact algebraic horizontal section. Moreover, this representative has a small algebraic gauge to a strictly upper-triangular zero-order connection, and its complete homogeneous solution uses only two logarithms. No further DSolve retry is needed.

I verified the formulas below against both matrices you supplied, using exact arithmetic in

Q(v,w)[r]/(r
2
−Δ).

This conclusion concerns the supplied block, not the unseen local implementation or automatically all three affected families.

1. The missing section and exactly why the current denominator excludes it

Define

q=v−w−1,Δ=q
2
−4w=1−2v+v
2
−2w−2vw+w
2
,r
2
=Δ.

An exact horizontal section is

h=
vr
3
1
	​

	​

−Δ
0
q
	​

	​

=
	​

−
vr
1
	​

0
vr
3
q
	​

	​

	​

.
	​


It satisfies

∂
v
	​

h=A
v
	​

h,∂
w
	​

h=A
w
	​

h.

In your search convention,

h=
Δ
	​

vΔ
2
(−Δ,0,q)
T
	​

.
	​


Therefore, a denominator containing only one Δ cannot represent this section in the 
Δ
	​

 character, regardless of numerator degree. Its third component requires Δ
−3/2
, whereas 
Δ
	​

p/Q with ord
Δ
	​

Q=1 has order at least −1/2.

A short derivation that avoids a polynomial search

The second row of A
v
	​

 simplifies to

∂
v
	​

Y
2
	​

=−
v
Y
2
	​

	​

.

Seek a section with Y
2
	​

=0. The second row of the w-equation then imposes

0=
w(w−1)
Y
1
	​

	​

+
w(w−1)q
ΔY
3
	​

	​

,

so

qY
1
	​

+ΔY
3
	​

=0.

Set

Y=f(v,w)(−Δ,0,q)
T
.

Substitution into the remaining equations gives

dlogf=−dlogv−
2
3
	​

dlogΔ,

hence f=1/(vΔ
3/2
), up to a constant.

Thus the rational line

span
Q(v,w)
	​

{(−Δ,0,q)
T
}

is already an invariant line. Only its horizontal normalization requires the square root.

The numerator-degree detail matters

For the simplified supplied matrices, a denominator LCM is

Q
0
	​

=v
2
qw(w−1)Δ.

Your proposed Q
1
	​

=Q
0
	​

Δ contains the section with polynomial numerator

p=vqw(w−1)(−Δ,0,q)
T
.

Its maximum total degree is six.

So the immediate positive-search test should include this distinction:

With the minimal denominator vΔ
2
, degree two suffices.

With the full matrix-denominator LCM multiplied by Δ, degree six suffices.

Multiplying Q while keeping an insufficient numerator bound can still miss the section. More generally, an enlarged-denominator search should preserve the old candidate space: p/Q=(pΔ)/(QΔ).

2. An explicit strictly triangular preparation

The section is enough to start a quotient reduction. For this block, that reduction can be completed explicitly.

Introduce

a=v−w+1,b=v+w−1,n=vq−b.

Use the convention

Y=TZ,B
μ
	​

=T
−1
(A
μ
	​

T−∂
μ
	​

T).

Take

T=
	​

−
vr
1
	​

0
vr
3
q
	​

	​

0
−
vw(w−1)
1
	​

v
2
wΔ
n
	​

	​

0
v(w−1)
1
	​

v
2
Δ
b
	​

	​

	​

.
	​


Its determinant is

detT=
v
3
w(w−1)r
3
q
	​

,
	​


so it is generically invertible on the ordinary domain under consideration.

The transformed connections are

B
v
	​

=
	​

0
0
0
	​

−
vr
a
	​

0
0
	​

−
vr
b
	​

0
0
	​

	​

,B
w
	​

=
	​

0
0
0
	​

wr
q
	​

0
0
	​

r
2
	​

0
0
	​

	​

.
	​


I checked the defining identities directly:

∂
μ
	​

T−A
μ
	​

T+TB
μ
	​

=0,μ=v,w.
	​


The original flatness identity also vanishes exactly.

This is stronger than a triangularity test at sample points. The supplied zero-order block really does admit the strictly triangular reduction that the earlier trial failed to find.

For implementation, its inverse is also small:

T
−1
=
	​

−vr
vw
v
	​

0
−
q
w(w−1)b
	​

q
(w−1)n
	​

	​

0
q
vwΔ
	​

q
vΔ
	​

	​

	​

.
Why this is a suitable target for a general bounded search

The first column of T is the algebraic horizontal section h. The other two columns are rational, and become horizontal after passage to the quotient by that invariant line.

Consequently, the general procedure need not find three algebraic horizontal sections of the original block. It can find one invariant line, construct its two-dimensional quotient over the rational field, and run the existing rational-section search there.

In particular, retaining the rational direction (−Δ,0,q)
T
 separately from its scalar algebraic normalization avoids introducing unnecessary square roots into the quotient calculation.

3. The homogeneous solution is explicit—not an unresolved quadrature

Define the two algebraic letters

L
1
	​

=
b+r
b−r
	​

,L
2
	​

=
a+r
a−r
	​

.
	​


Their logarithmic derivatives are

dlogL
1
	​

=−
vr
a
	​

dv+
wr
q
	​

dw,
dlogL
2
	​

=−
vr
b
	​

dv+
r
2
	​

dw.

These identities were also checked exactly in both variables.

Thus

dZ=(E
12
	​

dlogL
1
	​

+E
13
	​

dlogL
2
	​

)Z.
	​


All pairwise products of the connection matrices vanish:

B
μ
	​

B
ν
	​

=0(μ,ν∈{v,w}).

The complete local homogeneous solution is therefore

Y(v,w)=T(v,w)
	​

C
1
	​

+C
2
	​

logL
1
	​

(v,w)+C
3
	​

logL
2
	​

(v,w)
C
2
	​

C
3
	​

	​

	​

,
	​


with kinematics-independent constants C
1
	​

,C
2
	​

,C
3
	​

.

Equivalently, a fundamental matrix is

U
0
	​

=T
	​

1
0
0
	​

logL
1
	​

1
0
	​

logL
2
	​

0
1
	​

	​

.

For a chosen ordinary base point z
0
	​

=(v
0
	​

,w
0
	​

), the normalized evolution is

U
0
	​

(z,z
0
	​

)=T(z)[I+E
12
	​

ℓ
1
	​

(z)+E
13
	​

ℓ
2
	​

(z)]T(z
0
	​

)
−1
,
	​


where

ℓ
j
	​

(z)=logL
j
	​

(z)−logL
j
	​

(z
0
	​

)

uses the chosen continuation of the root and logarithms.

There is no need to ask an integrator to rediscover these primitives. The zero-order evolution terminates after one logarithmic insertion; no arbitrary function, inactive integral, or zero-order ODE generator remains.

Choose r at the base point and continue it consistently. The formulas are local identities on a domain avoiding the relevant poles and branch locus, for example

vw(w−1)qΔ

=0.

The logarithm differences should be interpreted by that continuation, not by independently resetting principal values at every endpoint.

This resolves the supplied zero-order preparation. The higher epsilon coefficients still belong to your existing finite integration stage; nothing here asserts a strict epsilon form for the full connection.

4. The local residue predicts the denominator correction cheaply

The missing multiplicity is visible without solving the block.

At a generic smooth point of Δ=0, use Δ as transverse coordinate, holding w fixed. Since

∂
v
	​

Δ=2q,

the normal residue is

R
Δ
	​

=
2q
Δ
	​

A
v
	​

	​

Δ=0
	​

.

Restriction here means reduction in the function field of the divisor, not substitution at an intersection with another pole.

For your matrices it has the shape

R
Δ
	​

=
	​

0
0
∗
	​

0
0
∗
	​

0
0
−
2
3
	​

	​

	​

,

and therefore

specR
Δ
	​

={0,0,−
2
3
	​

}.
	​


After factoring out the candidate character 
Δ
	​

,

h=
Δ
	​

u,

the rational vector u satisfies

du=(A−
2
1
	​

dlogΔI)u.

The shifted normal residue has eigenvalues

−
2
1
	​

,−
2
1
	​

,−2.

The integer exponent −2 identifies the relevant rational denominator multiplicity:

u∼Δ
−2
.

So the extra Δ is locally motivated, not an arbitrary denominator enlargement. This is a candidate-support calculation; it does not turn a failed bounded search into a nonexistence theorem.

The analogous implementation for another nonlinear divisor F is to inspect

∂
μ
	​

F
F
	​

A
μ
	​

	​

F=0
	​


where the selected derivative is nonzero, then account for the exponent contributed by the admitted scalar root character. Apply this simple residue argument only where the normal system has a simple pole. It is not a replacement for an irregular-singularity analysis or a general completeness proof.

5. Recommended bounded improvement

Keep the current campaign running. For this failure class, add the targeted nonlinear-divisor multiplicity correction and stop insisting on a complete algebraic fundamental matrix before accepting a useful preparation.

The smallest useful sequence is:

Try the one-step denominator correction already under test, with enough numerator support to contain the corrected candidate. For this representative, Q
0
	​

Δ and total degree six contain the section explicitly displayed above. Do not compensate for the missing denominator by a long numerator-degree ladder.

Accept one exactly verified invariant line and recurse on the quotient. Keep its rational direction and scalar root factor separate. Here the remaining quotient admits rational horizontal representatives, and the final extension is just the two explicit dlogs above.

Stop at the accepted triangular preparation or its explicit U
0
	​

 and pass it to the existing finite-order solver. Do not spend another 90 seconds on the alternative-coordinate DSolve probe for this representative.

The sparse-row argument in §1 is also a useful inexpensive seed: a component decoupled in one coordinate can suggest setting that component to zero, after which the other coordinate supplies algebraic constraints. But it should remain a small candidate generator with full-coordinate verification—not a new unrestricted invariant-subspace algorithm tonight.

For CF13, CF18, and CF408, apply this general mechanism to each retained current block and verify its own defining identities. The representative is solved explicitly; the family labels alone do not establish that the same T applies to the other blocks.

Reproducible certificate

The Wolfram Language fixture contains the supplied matrices, T, T
−1
, the reduced connection, the two letters, and exact identity checks using a formal root. It is a standalone regression fixture, not a proposed production schema or family-specific dispatch.

The 
independent Python verifier checks flatness, both gauge identities, both inverse identities, the determinant, both-coordinate dlog identities, nilpotent products, and inclusion of h in the enlarged-denominator ansatz. I executed that verifier and all checks passed. The Wolfram fixture has not been executed in a Wolfram kernel here.

The decisive change is pole multiplicity plus quotient reduction—not more DSolve time. For this exact block, that change leads to a fully explicit algebraic/logarithmic homogeneous preparation.