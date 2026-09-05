# CF303 Rational Kernel Failure Followup

## Question

Continue the existing CF303 analysis. The first properly overdetermined
rational-kernel reconstruction has now corrected the apparent positive result.

The earlier `{dx,dy,d(x^2)}` systems had 7,280 rows and 7,284 columns. The 12
new residue columns raised the matrix to full row rank, so they could fit every
RHS; those runs were only obstruction-span diagnostics.

We then ran the real finite-field solver with the same certified 1,770 gauge
monomials, 48 dlogs plus `{dx,dy,d(x^2)}`, and automatic overdetermination. At
`p=1000003`, `eps=1/21` it built a `7296 x 7284` system and returned
`InconsistentModularSystem` immediately. No primes or reconstruction followed.

The six feeder nullspaces were also recaptured and proven exactly equal to the
constant-matrix spaces, so coupled-row freedom is closed.

Please give the sharp next target calculation. In particular:

1. Is the right cheap ladder the gauge-eliminated compatibility system with
   the complete polynomial exact-potential basis through total degree 2
   (`x,y,x^2,xy,y^2`), then degrees 3 and 4, always with rows exceeding
   columns? We are running that pilot now.
2. If finite polynomial potentials fail, what finite, mathematically motivated
   rational-exact basis `dH` should be tested next? Derive it from the 16 polar
   divisors/valuation bounds rather than proposing an unbounded ansatz.
3. Can the full 12-dimensional/codimension projection at an overdetermined
   point set identify the minimal exact potentials directly, or should the
   covariant-integrability screen remain the primary gate?
4. At what point is the correct conclusion that the fixed diagonal row has no
   useful rational epsilon-factorized target and that a predecessor-sector or
   nonrational transformation is required?

Please explicitly account for point-count/rank saturation so a full-row-rank
underdetermined fit is never mistaken for evidence again.

## Pro response

Verdict

The corrected result rejects {dx,dy,d(x
2
)}, not the rational-exact target class. The feeder calculation closes the proposed coupled-row rescue within the certified rational-dlog feeder class.

GO: finish the small, overdetermined polynomial-potential compatibility ladder already running.

Next, if that ladder fails: test the complete closed-rational target class reachable by the current gauge space without enumerating another large alphabet. This can be done by imposing ordinary closedness directly on the transformed block. It is a linear system in the existing 7,080 gauge coefficients only.

One correction is essential: the degree-58 gauge bound was derived for a logarithmic target. It cannot automatically be treated as exhaustive after allowing higher-order poles at infinity.

1. The polynomial compatibility ladder is the correct cheap first test

Use the complete scalar potential space

P
d
	​

/Q=span{x
i
y
j
:1≤i+j≤d}.

Its dimensions are

n
d
	​

=(
2
d+2
	​

)−1.

With the existing 48 dlogs and 2×2 residue matrices:

Potential degree	Number of potentials	Compatibility unknowns	Full gauge-system unknowns, retaining 1,770 gauge monomials
2	5	4(48+5)=212	7,292
3	9	228	7,308
4	14	248	7,328

Build the degree-4 compatibility system once on 80 common points: it has 320 rows and 248 columns. The degree-2 and degree-3 tests are column restrictions of that same system. This avoids comparing different point sets.

The equation remains

K(Ω)=−
ϵ
2
∇
(1)
F
	​

,K(Ω)=E∧Ω+Ω∧C,

with

Ω=
a
∑
	​

M
a
	​

dlogL
a
	​

+dH.

A compatibility pass is necessary for a gauge of any function class, but does not prove existence of a rational gauge. The failed 7296×7284 reconstruction illustrates exactly that distinction.

Recompute the infinity bound before calling a full gauge search exhaustive

A polynomial potential H of degree d gives dH pole order at most d+1 at projective infinity.

Let b
∞
	​

 be the actual pole order of F there, measured as a one-form, and assume the diagonal connections remain logarithmic. The leading-order argument now bounds the gauge pole by

g
∞
	​

≤max{b
∞
	​

−1,d,0}.

Thus, for gauge denominator Q
G
	​

,

degN
G
	​

≤degQ
G
	​

+max{b
∞
	​

−1,d,0}.
	​


The old 58 bound remains valid only if it already includes that allowance. This is a change of target assumptions, not a justification for an arbitrary support enlargement. Canonical rational-gauge bounds are tied to the stipulated pole structure of the target. 
arXiv

2. A finite rational-exact space follows directly from the pole budget

Let the 16 finite polar curves be f
i
	​

=0. Define:

b
i
	​

: pole order of the actual forcing F along f
i
	​

;

g
i
	​

: allowed pole order of the gauge G;

b
∞
	​

,g
∞
	​

: the analogous projective-infinity orders.

For

T
G
	​

=F+ϵ(EG−GC)−dG,

the logarithmic diagonal assumption gives

pole
f
i
	​

	​

(T
G
	​

)≤t
i
	​

:=max{b
i
	​

,g
i
	​

+1},

and similarly

t
∞
	​

:=max{b
∞
	​

,g
∞
	​

+1}.

A closed rational one-form on P
2
 decomposes into component dlogs plus an exact rational differential. If its pole order along a component is t
i
	​

, the exact potential needs pole order at most t
i
	​

−1. This statement includes singular polar curves; it is not limited to a normal-crossing presentation. 
arXiv

Consequently, set

m
i
	​

=max{b
i
	​

−1,g
i
	​

,0},m
∞
	​

=max{b
∞
	​

−1,g
∞
	​

,0},

and

Q
H
	​

=
i=1
∏
16
	​

f
i
m
i
	​

	​

.

A finite complete potential space for this specified gauge pole budget is

H={
Q
H
	​

(x,y)
P(x,y)
	​

:degP≤degQ
H
	​

+m
∞
	​

}/Q.
	​


Then the corresponding complete closed-rational target space is

span{dlogf
i
	​

}+dH.

Two implementation details matter:

Testing only 1/f
i
	​

,1/f
i
2
	​

,… is incomplete. Numerator jets and mixed-divisor poles are included automatically by the common-denominator space above.

Quotienting by constants means removing the direction P=Q
H
	​

, not deleting the monomial 1 from the numerator basis.

This does not require a denominator promotion for the gauge. It first tests rational-exact targets compatible with the existing G-space.

A cheap early rejection of all polynomial potentials

Before extending the polynomial ladder beyond degree four, inspect the finite-divisor pole orders of

K
F
	​

=∇
(1)
F.

For polynomial H, dH is regular on every finite divisor. Hence

E∧dH+dH∧C

has at most a simple finite pole. The same is true for the dlog compatibility columns at a generic point of each divisor.

Therefore:

pole
f
i
	​

	​

(K
F
	​

)>1 ⟹ no polynomial-potential degree can solve compatibility.
	​


Such a divisor immediately identifies where a rational potential is needed. If its obstruction has order r, a potential with pole order at least r−1 is necessary to affect that leading term.

3. The strongest next bounded test avoids choosing potentials altogether

Instead of assembling thousands of dH columns, eliminate the target coefficients and ask directly for a rational gauge whose transformed block is closed.

Because the diagonal forms are certified dlog forms,

dE=dC=0.

Taking the ordinary exterior derivative of T
G
	​

 gives

dT
G
	​

=dF−ϵ(E∧dG+dG∧C).

Thus solve

E∧dG+dG∧C=
ϵ
dF
	​

.
	​

(1)

In components,

E
x
	​

∂
y
	​

G−E
y
	​

∂
x
	​

G+∂
x
	​

GC
y
	​

−∂
y
	​

GC
x
	​

=
ϵ
∂
x
	​

F
y
	​

−∂
y
	​

F
x
	​

	​

.
	​

(2)

This requires only first derivatives of the gauge basis. There are no target-letter coefficients and no second derivatives.

Why this is decisive

For the chosen finite rational gauge space:

If (1) has a rational solution, T
G
	​

 is a closed rational one-form.

The projective rational-form decomposition then supplies

T
G
	​

/ϵ=
i
∑
	​

M
i
	​

(ϵ)dlogf
i
	​

+dH

with H in the finite pole-bounded space above.

If (1) is inconsistent, no enumeration of rational exact potentials can rescue that gauge space. 
arXiv

This reverses the earlier elimination:

the covariant-integrability screen eliminates G and tests a chosen target;

equation (1) eliminates the target and tests rational reachability directly.

Physical dimensions and implementation

Retaining the current 1,770 scalar gauge monomials gives

4×1770=7080

unknowns and four scalar equations per point.

A common set of 1,800 points gives a 7200×7080 system—comparable in size to the gauge systems already being solved, but with no alphabet growth.

Use the existing compiled evaluator for E,C,dF and the existing monomial derivative evaluations. No new symbolic normalization is required.

If Q
G
	​

 is regulator-free, the matrix in (2) is epsilon-independent. Only the RHS changes with ϵ. Factor the matrix once per prime and process several regulator images as multiple RHS columns.

This is my recommended complete bounded-class test after the small polynomial ladder.

4. Cokernel projection: useful, but the old dimension 12 must be discarded

The full cokernel is the stronger gauge-aware selector once it is computed on a sufficiently large common point set.

For the current base system

A
0
	​

z=b,WA
0
	​

=0,

and proposed exact-potential columns C
H
	​

,

A
0
	​

z+C
H
	​

c=b

is solvable on those rows precisely when

WC
H
	​

c=Wb.

But the old 12-dimensional cokernel came from the 7,280-row capture. Adding 12 columns that span it can make every RHS solvable on that capture. It is not a reusable “12-dimensional physical obstruction.”

For the degree-4 polynomial test, retaining the existing gauge support:

use at least 920 common points, giving 7360 full-PDE rows;

the maximum candidate system has 7328 columns;

compute the base cokernel on those same rows;

compare all degree-2, 3, and 4 candidate columns against it.

If the gauge infinity bound requires additional monomials, increase the row count before projection.

A useful column identity

Whenever H=h(x,y)M is itself in the gauge ansatz,

∇H=dH−ϵ(EH−HC).

Since W annihilates every gauge column,

W[ϵdH]=ϵ
2
W[EH−HC].
	​


So projected exact-potential columns can be evaluated from h,E,C, without differentiating h, provided that gauge-space inclusion holds.

Projection can identify a sufficient, then irredundant, subset of potentials. Scalar pivot selection does not automatically minimize the number of four-column potential blocks.

Priority: compatibility remains the cheap rejection gate; the overdetermined full-system cokernel is the stronger selection gate; equation (1) is the complete test of all closed rational targets within a fixed gauge space.

5. When to stop the fixed-row rational route

There are three different conclusions.

Polynomial degrees 2,3,4 fail

This rejects only those polynomial target spaces. It does not reject rational potentials with finite poles, or higher polynomial degree unless the infinity bound excludes it.

The complete pole-bounded rational-exact class fails

Equivalently, equation (1) fails generically for the corresponding exhaustive gauge space.

Then the correct conclusion is:

No rational gauge in this declared pole/degree class makes the fixed row’s transformed block an ordinary closed rational one-form.

That closes all rational-dlog-plus-exact target enumeration for that class.

No rational epsilon-factorized target at all

That stronger statement requires bounds valid for the new joint gauge/target class. The original no-extra-pole argument assumed a logarithmic target. Once dH is permitted a pole of order m+1, its leading term can balance a gauge pole f
−m
.

Therefore the old logarithmic-target bound cannot prove unrestricted nonexistence for arbitrary rational-exact targets.

Keep the present denominator for the next calculation. But if the bounded closedness test fails, choose between:

deriving a larger joint indicial bound for G,H, without a blind ansatz sweep; or

declaring the bounded class computationally exhausted and changing the predecessor target class or using a genuinely nonrational transformation.

The proven constant feeder nullspaces mean that simply rechoosing the six feeder representatives cannot help. A predecessor change must alter the permitted functional/target class, not its constant normalization. Generalized epsilon-factorization methods do use additional nonrational functions when rational transformations are insufficient, but the function class should be selected from the differential-system obstruction rather than inferred from one failed ansatz. 
arXiv

Also, a fixed-ϵ closedness solution is not yet a strict epsilon form: after reconstruction, the resulting kinematic kernel must be epsilon-independent, or pass the separate family regulator-factorization stage.

Concrete next sequence

Finish the polynomial compatibility ladder on one common 320×248 maximum system. Test degrees 2 and 3 by restricting columns.

Inspect finite poles of K
F
	​

. Any pole above order one closes the entire polynomial-potential route at once.

If a polynomial screen passes, update the infinity allowance and use a genuinely overdetermined full-system cokernel before reconstruction.

If the polynomial ladder fails, run the closedness-only gauge test (2): 7200×7080 for the unchanged 1,770-monomial space, with several epsilon RHS columns where possible.

If that passes, reconstruct G, form T
G
	​

, and extract its rational potential using the pole-bounded decomposition. Do not preconstruct a large rational-exact alphabet.

If it fails, stop target enumeration for that gauge space. Either derive a defensible joint pole/degree extension or move beyond the fixed rational row problem.

A sampled consistency result counts as evidence only after the augmented system remains consistent on additional common points and independent regulator/prime images. In particular, full row rank with rows no greater than columns is a span diagnostic, never a positive reconstruction result.
