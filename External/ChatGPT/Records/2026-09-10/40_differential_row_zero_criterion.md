# Differential row closure as a sufficient zero criterion

Verified model: gpt-6-pro. Conversation: 6aa2eb2d-5588-83e8-bf9d-d35cd8d66f3b. Request: b0a73d87-4a5e-45e4-920f-b998dd0157f6.

## Question

A follow-up on your recommended summed-row/physical-subspace test.

The existing exact endpoint construction has, per family, rational-in-(v,eps) normal gauge T, normalized normal residue R, full Frobenius recurrence jets, and tangential amplitude DE c'=C(v,eps)c. Normal eigenvalues have zero integer part (epsilon slopes retained); all Jordan blocks are included. At v0=1/4, exact rational matching embeds the same global physical seed space (84 columns, 83 unfixed amplitudes before explicit physical evaluation) into the family amplitude spaces. Actual boundary values are known, but involve many finite scalar-integral definitions.

Proposed reusable zero test, to avoid simplifying those boundary functions:
1. Form the covectors q(v,eps) for every forbidden normal power/log coefficient of the full weighted physical sum, after exact scalar denominator cancellation and enough normal Frobenius jets. Work class by class in the retained epsilon slopes and logarithms. The fiber is the direct sum of the family tangential systems, with a common matching matrix S0 into the physical seed space at v0.
2. Close these covectors under the covariant derivative nabla q = d_v q + q C over Q(v,eps,external parameters), retaining an exact rational row basis Q and an exactly checked closure identity Q' + Q C = A Q. Field rank selection could use rational/modular samples, but the final closure residual must be exact (or explicitly remain numerical evidence).
3. If Q(v0,eps) S0(eps) = 0 exactly, uniqueness of the finite tangential homogeneous DE proves every selected forbidden coefficient identically zero on the nonsingular connected tangential interval for every allowed physical amplitude, without using actual boundary values. A nonzero projection means merely this sufficient physical-subspace criterion failed.
4. Require the endpoint-family meromorphic distribution-identification and joint normal/epsilon uniformity hypotheses you already specified; retain them independently. Do not infer epsilon-pole cancellation from the normal-power theorem.

Is this valid, including all epsilon-dependent/Jordan residue classes and meromorphic initial-data columns? Any important obstruction to finite row closure, specialization at the ordinary base point, or the use of an overcomplete direct-sum master space? Is there a cheaper necessary closure/projection test that uses the known exact family/global overlap maps first? Please focus on whether this is a sound practical sufficient criterion, not a proof of completeness/minimality. We are regenerating current-card rational coefficients now; old master solutions are kept only as mathematical reuse candidates.


## Pro response

The differential-closure idea is valid, but step 3 needs an additional regular-specialization condition. As written, it can give a false-positive zero even when C is regular at v
0
	​

. With that correction, plus an exact check that the closed row space contains every requested covector, this is a sound sufficient criterion that avoids evaluating the physical boundary functions.

The most economical implementation is overlap reduction first, inexpensive projected-derivative screening second, exact differential closure and regular specialization last.

1. The corrected certificate and its proof

Let

k=Q(ϵ,external parameters),K=k(v),

with the external parameters constant under ∂
v
	​

. Stack the forbidden coefficient covectors into a matrix B(v), so the outputs to be proved zero are

f(v)=B(v)c(v),c
′
=Cc,c(v
0
	​

)=S
0
	​

b.

Here b contains the global seed amplitudes, including any fixed normalization amplitude retained as a homogeneous column.

Your derivative

∇q=q
′
+qC

is exactly the output-derivative operation used in observability tests for time-dependent linear systems. 
arXiv

A sufficient certificate consists of exact rational identities

B=UQ,Q
′
+QC=AQ,Q(v
0
	​

)S
0
	​

=0,
	​


together with meaningful specialization of Q at v
0
	​

 and an ordinary initial-value problem for the induced A-system there. In particular, Q,C,A regular in v at v
0
	​

, for generic regulator and external parameters, is sufficient.

The proof is immediate but important. Let

P
′
=CP,P(v
0
	​

)=S
0
	​

,

so every selected solution is c=Pb. Then

Y:=QP

satisfies

Y
′
=(Q
′
+QC)P=AY,Y(v
0
	​

)=0.

Ordinary-point uniqueness gives Y=0, hence

BP=UQP=0,Bc=0.

The relevant uniqueness is uniqueness for an ordinary linear system, not uniqueness for an arbitrary singular system. 
arXiv

No boundary amplitude is evaluated in this proof. It proves a matrix identity before multiplying by b.

Also, minimality of Q is unnecessary. Any finite closed row space containing the requested covectors and annihilating the selected seeds suffices. Computing the smallest such differential closure is an economy choice, not a correctness requirement.

2. The specialization obstruction—and a reusable repair

Set x=v−v
0
	​

 and consider

C=0,B=x,S
0
	​

=1.

Choose the field row basis Q=x. Then

Q
′
+QC=1=
x
1
	​

Q,Q(v
0
	​

)S
0
	​

=0.

Thus your stated algebraic closure and projection tests both pass. Nevertheless, the selected solution is c=1, and

Bc=x

=0.

The problem is

A=
x
1
	​

:

the induced equation Y
′
=Y/x has nonzero solutions vanishing at x=0.

Preferred acceptance condition

For a field-independent r×N row basis Q, require

Q,C regular at v
0
	​

,
rank
k
	​

Q(v
0
	​

)=r.
	​


Together with exact closure, this automatically makes A regular after cancellation. Indeed, choose pivot columns J for which Q
J
	​

(v
0
	​

) is invertible. Then

A=(Q
′
+QC)
J
	​

Q
J
−1
	​

,

and both factors are regular locally.

The rank is over k: do not first set ϵ=0.

Local saturation without solving another DE

A concrete repair is to replace the field basis by a basis of

W∩O
v
0
	​

N
	​

,W=rowspan
K
	​

Q,

where O
v
0
	​

	​

 is the ring of rational functions regular at v
0
	​

.

This can be implemented using rational row operations:

Clear any row poles in x, obtaining regular rows.

If their specialization loses rank, find a nontrivial k-linear combination of rows that vanishes at x=0. Replace a participating row by that combination divided by x.

Repeat until the specialized rank equals the field rank, then recompute and check the closure identity.

The division is valid because the entire regular row vanishes at x=0. Each such replacement decreases the common vanishing order of the full-rank minors, so the procedure terminates.

In the example, it replaces Q=x by 
Q
	​

=1. The corrected projection is 1, and the false certificate is rejected.

Clearing denominators alone is not the repair: multiplying rows by factors vanishing at v
0
	​

 can create precisely the false initial zeros at issue.

Once zero is established locally, auxiliary poles of a particular Q or A elsewhere need not become new physical exclusions. Continue the identity using the original coefficient functions and physical tangential system, with the already established domain and branch restrictions.

3. Finite closure is guaranteed; coefficient growth is the practical risk

Define

W
0
	​

=rowspan
K
	​

B,W
j+1
	​

=W
j
	​

+∇W
j
	​

.

It suffices to differentiate a row basis because

∇(aq)=a
′
q+a∇q.

This is the defining Leibniz property of a differential module. 
arXiv

Every strict enlargement increases the K-dimension, and the ambient dimension is N. Therefore there are at most

N−dim
K
	​

W
0
	​


strict enlargement rounds. Once differentiation of the complete current basis produces no new field directions, closure has been reached.

There is no obstruction from increasing rational degrees, meromorphic ϵ-dependence, or Jordan blocks to finite-dimensional termination. There can, however, be substantial numerator/denominator growth.

Two practical points matter.

Check original-row containment, not only final closure. If modular rank selection accidentally discards an essential input row, a smaller matrix may still satisfy a perfectly exact closure identity. The final certificate must include

B−UQ=0

as well as

Q
′
+QC−AQ=0.

Together, these permit sampled rank selection without trusting sampled zero decisions.

Do not use pointwise rank stabilization as the stopping rule. For C=0, B=x
M
, the first M output derivatives at v
0
	​

 can vanish despite a nonzero output. The field closure already has dimension one, but its unsaturated generator specializes badly. There is no universal “check the first N derivatives at this fixed point” replacement for closure plus regular specialization.

For efficiency, restrict computation to the connection-dependency closure of the output support, and reuse closures among outputs sharing that support. Neither optimization requires a selected-family exception.

4. Regulator dependence, Jordan classes, and the seed columns
Meromorphic columns are harmless

Keep ϵ symbolic. Establish the identities for generic ϵ, away from the finitely specified denominator and pivot degeneracies, and then use the stipulated meromorphic interpretation.

Poles in S
0
	​

(ϵ), or in the unknown amplitudes b(ϵ), do not obstruct the argument:

QP=0

is established before multiplication by those amplitudes. Functions of ϵ alone can be treated as constants for the v-connection. The distinction between the differentiation variable and parameter variables is standard in parameter-dependent linear systems. 
arXiv

There is also no need for the auxiliary A to be regular at ϵ=0 for this exact-zero proof. Its ordinary-point requirement concerns v=v
0
	​

 at generic parameters. Your independent uniform-meromorphy hypotheses remain necessary for interpreting the endpoint Laurent expansion.

Do not substitute a truncated epsilon series for the exact rational certificate without propagating the required Laurent orders through all products and divisions.

Jordan blocks do not require a different zero test

For a block

R=λ(ϵ)I+N,N
ν
=0,

the normal factor is

z
R
=z
λ(ϵ)
j=0
∑
ν−1
	​

j!
N
j
	​

(logz)
j
.

After extracting the complete coefficient of a specified normal power, regulator exponent, and logarithm, that coefficient is still a covector applied to the tangential amplitude vector. The same proof applies.

The safeguards are about forming the outputs correctly, not changing the closure theorem:

Collect contributions from all families sharing the same retained exponent/logarithm label before testing.

Retain every Jordan contribution and every derivative of a v-dependent projector, gauge, or prefactor in the chosen coordinates.

Use the full tangential connection unless a smaller invariant system has actually been established. A logarithm label alone does not justify dropping connection mixing.

Classwise vanishing at generic ϵ remains sufficient when classes coalesce at ϵ=0. It may be stronger than vanishing through a finite requested Laurent order; failure therefore remains inconclusive for the actual requested result.

Overcompleteness is not a correctness problem

The direct sum of the family systems is a legitimate ambient system even when some functions occur several times. Differential-module constructions allow direct sums without requiring independence of particular selected solutions. 
arXiv

What matters is that the initial data are correlated through the same S
0
	​

b, and that the actual physical initial data lie in its image. Use rankS
0
	​

, not the number 84, whenever a rank enters a test.

Conversely, the 84 initial columns do not imply the existence of a rational 84-dimensional tangential reduction. The transported matrix

P(v)=Φ(v,v
0
	​

)S
0
	​


need not have a rational column-space frame over K. Thus a constant projection using S
0
	​

 is not generally a valid reduced differential system.

5. Use the exact overlap maps before constructing a large closure
Best case: a compatible rational embedding

Suppose existing overlap maps provide

c=E(v)d,d
′
=D(v)d,

with the exact compatibility and initial-data identities

E
′
+ED=CE,S
0
	​

=E(v
0
	​

)
S
0
	​

.
	​


Require the same ordinary-point and domain safeguards. This is the connection-preserving condition for a differential-module map. 
arXiv

Then replace the forbidden rows by

B
=BE

and work in the smaller system D. The derivative operation commutes with this reduction:

(BE)
′
+(BE)D
	​

=B
′
E+B(E
′
+ED)
=(B
′
+BC)E.
	​


This gives three immediate savings.

An exact 
B
=0 ends the test before any closure. Otherwise, initial projection and derivatives involve fewer columns. Finally, closure cannot grow into redundant family directions already eliminated by E.

The map must be an actual endpoint-amplitude map in compatible variables, gauges, normalizations, and branches. A bulk overlap involving a kinematic substitution requires the corresponding pullback and chain rule; agreement of two maps only at v
0
	​

 is insufficient.

When only relations are available

Suppose known overlap relations are encoded by rows L satisfying

Lc=0.

If their row module is connection-stable,

L
′
+LC=A
L
	​

L,

and the relation is physically established—either independently or by the same regular initial-value certificate—reduce forbidden rows modulo rowspan
K
	​

L.

Then a quotient closure has the form

B=UQ+VL,Q
′
+QC=AQ+HL.

Since Lc=0, the projected outputs still satisfy

(Qc)
′
=A(Qc).

This avoids constructing a globally minimal basis. It requires only the overlap relations needed to reduce these outputs.

A relation module used for derivative reduction must be stable, or closed first. Otherwise a relation that removes a row today can produce an unaccounted direction after differentiation.

6. Cheap screens before full rational closure

After overlap reduction, evaluate

B(v
0
	​

)S
0
	​

,(∇B)(v
0
	​

)S
0
	​

,(∇
2
B)(v
0
	​

)S
0
	​

,…

where these specializations are regular. These are the projected output derivatives; the recursion follows the same time-dependent observability construction. 
arXiv

Any exact nonzero entry immediately defeats the all-column sufficient criterion. It does not show that the actual physical amplitudes give a nonzero output.

A convenient implementation avoids constructing large rational derivatives in v. Expand locally,

C=
j≥0
∑
	​

C
j
	​

x
j
,P=
j≥0
∑
	​

P
j
	​

x
j
,P
0
	​

=S
0
	​

,

and use

(j+1)P
j+1
	​

=
ℓ=0
∑
j
	​

C
ℓ
	​

P
j−ℓ
	​

.

Multiplication by the local series of B gives the projected output jets directly over k. A few such jets can expose failure before expensive field closure. Zero jets are only a screen, not acceptance.

There is also a cheap rank obstruction. Let

s=rank
k
	​

S
0
	​

.

If the accumulated independent closure rows already have rank r with

r+s>N,

they cannot all annihilate the transported s-dimensional seed image. Stop the universal-subspace test. Apply this after any valid overlap reduction, using the reduced ambient dimension.

When the test fails, retain

M(ϵ)=Q(v
0
	​

,ϵ)S
0
	​

(ϵ)

in the regular frame. Its rows identify the additional seed-amplitude combinations that would have to vanish for a stronger physical-boundary-specific proof. This is more useful than either declaring a physical failure or expanding every boundary integral.

Recommendation

Implement the acceptance condition as

exact output containment+exact differential closure+regular base-point specialization+exact seed annihilation.
	​


Precede it by compatible overlap reduction and inexpensive projected-jet screens. A passing certificate proves the selected forbidden coefficients identically zero for every amplitude vector admitted by S
0
	​

, including the actual meromorphic physical values, without simplifying their scalar-integral definitions.

Your independently retained distribution-identification, normal/epsilon uniformity, complete normal-jet coverage, and tangential-domain hypotheses remain essential. This test proves the coefficient identities; it does not replace those hypotheses, establish a minimal master basis, or infer cancellation of unrelated epsilon poles.