# CF303 Obstruction Next Target

## Question

Continue the existing **Assess Multiquadratic Pipeline** conversation. The
discriminator you requested is now complete. Please choose the next
mathematically legitimate target class for CF303 `(25,18)` and give one
small, decisive calculation before any new production implementation.

New exact evidence:

1. We reconstructed the 48-letter rational-chart record and captured the
   optimized affine rows before elimination. At three independent points
   modulo `2147483423`, all 24 rows and RHS entries agree exactly with the
   package's separate raw-PDE evaluator. Row assembly is not the defect.
2. The full certified-simplex system is `7280 x 7272`. A compact FLINT
   left-null witness, independently replayed against the Wolfram SparseArray,
   gives
   `rank(A)=7268`, `rank([A|b])=7269`, `y^T A=0`,
   `y^T b=615978110 != 0 mod 2147483423`.
3. We completed your geometric-component census. The 16 affine polar factors
   have degrees `1^6,2^4,3^6`; Maple `AFactors` and Singular `absFactorize`
   independently show every projective closure absolutely irreducible. The
   infinity component is also absolute and contributes only the projective
   residue relation. Thus `C_geom` has width zero.
4. The A3 degree-58 simplex is certified under the established simple-pole and
   logarithmic-infinity assumptions. The local leading-pole determinant still
   excludes denominator promotion.

Please now resolve these questions sharply:

- You previously named “general closed rational one-forms beyond dlogs” as a
  possible next class. On `P^2`, is every closed rational one-form with only
  simple poles along a reduced divisor and logarithmic behavior at infinity a
  constant linear combination of the component `dlog(f_i)` plus a global
  holomorphic one-form (zero on `P^2`)? If yes, then our absolute-component
  census closes that class too. State the precise caveats for singular
  components/codimension-two points.
- Can changing the rational diagonal epsilon-form normalization or applying
  another rational block-diagonal canonical gauge change existence of an
  off-diagonal rational epsilon-form? It appears existence should be invariant:
  compose any successful diagonal gauges and off-diagonal unipotent gauge back
  to the current basis. Identify exactly when that invariance fails.
- If both axes are closed, what can genuinely rescue this extension: an
  algebraic gauge/letters on a new cover not already present in the rational
  strip, a nonrational epsilon-dependent gauge, a higher-order/irregular target,
  or evidence that this sector is elliptic/non-polylogarithmic?
- Give the smallest concrete modular or algebraic calculation that distinguishes
  those possibilities using the captured `A,b`, the 16 polar curves, and the
  known diagonal residues. Do not propose broad numerator factorization,
  denominator widening, more hashes/checks, or a blind large ansatz.

We need a GO/NO-GO next step, not a general review.

## Follow-up question

Please answer the immediately preceding, unanswered CF303 obstruction prompt.
It contains the completed raw-row comparison, absolute polar census, and
left-null witness. Give the requested sharp GO/NO-GO next step; do not repeat
the earlier recommendation to run the geometric-component census, because
that census is now complete and has width zero.

## Pro response

Verdict

Your objection is correct: “general closed rational one-forms with the same simple poles” is not a larger target class here. My earlier suggestion was wrong. Rational canonical diagonal re-normalization is also not an escape.

There is a further restriction: a finite algebraic cover cannot rescue this fixed-diagonal, linear off-diagonal problem either, under the same algebraic-dlog target contract.

The next legitimate candidate is a genuinely kinematics-dependent transcendental gauge. Before implementing one, run a small covariant-integrability test that eliminates the gauge entirely. It determines whether such a gauge can reach the existing dlog target at all.

The conclusions below take your exhaustive degree/pole bounds and generic-image obstruction as established. The numerical witness is the evidence for the failed rational ansatz; the additional exclusions follow from the structural arguments below.

1. The closed rational target class is exhausted

Let X=P
2
 over the characteristic-zero constant field Q(ϵ), and let D be the reduced projective polar divisor. A closed rational one-form with only simple poles along D is a constant linear combination of its component logarithmic differentials, subject to the projective degree relation. The general decomposition of a closed rational one-form on P
2
 is a logarithmic part plus an exact rational differential; when all poles are simple, the exact part vanishes. 
arXiv

Writing the projective components as F
i
	​

=0,

ω=
i
∑
	​

c
i
	​

F
i
	​

dF
i
	​

	​

,
i
∑
	​

c
i
	​

degF
i
	​

=0.

On your affine chart this is precisely the span of the 16 supplied dlogf
i
	​

, with infinity accounted for by the degree relation.

Singular components do not create a loophole

At a generic smooth point of an irreducible component, closedness makes the residue constant. Subtract the corresponding logarithmic forms. The remainder has no codimension-one poles.

Because P
2
 is smooth and Ω
P
2
1
	​

 is locally free, a rational differential cannot retain poles supported only at isolated codimension-two points. The remainder therefore extends to a global holomorphic one-form, and

H
0
(P
2
,Ω
1
)=0.

Thus normal crossings are not required for this conclusion.

The caveats are precise:

“Simple poles in the affine chart” is insufficient without the infinity condition.

A logarithmic form along a singular divisor need not be closed; closedness is essential.

Rational scalar forms and matrix-valued covariantly closed forms are different objects.

Working on a singular ambient surface would require a separate reflexive-differential analysis; your ambient surface is smooth P
2
.

Your absolute-component census closes the constant-field splitting issue as well. No further closed rational simple-pole forms remain to enumerate.

2. Rational canonical diagonal changes do not remove the obstruction

Suppose two rational transformations give genuine diagonal epsilon forms,

ϵE,ϵE
′
,

with epsilon-independent dlog matrices. Their transition T satisfies

dT=ϵ(ET−TE
′
).

Expand the rational T in a Laurent series in ϵ. Its leading coefficient is kinematics-independent. Inductively, the derivative of each subsequent rational coefficient is a constant combination of dlogs. Such a derivative can be rational-exact only when all logarithmic residues vanish, so that coefficient is also kinematics-independent.

Consequently,

T=T(ϵ).

This is the canonical-form uniqueness result proved in Meyer’s CANONICA analysis. 
arXiv

Therefore changing the diagonal canonical normalization only conjugates and rescales the strip’s constant residue matrices. It cannot turn the current inconsistent rational strip problem into a consistent one.

Where the invariance statement needs qualification: existence of a full rational canonical transformation is invariant under any invertible rational starting-basis change. But the restricted fixed-diagonal strip problem need not be invariant if the proposed diagonal transformation leaves the canonical class, introduces kinematic dependence, changes the filtration, or uses transcendental functions. In particular, DLogFormCertified with arbitrary epsilon dependence is not automatically a genuine diagonal epsilon form.

3. A new finite algebraic cover is also not the next route

Define the Hom-connection operator on a gauge block by

∇G=dG−ϵ(EG−GC).

The strip equation is

∇G=F−ϵ
a
∑
	​

M
a
	​

(ϵ)dlogL
a
	​

.

Suppose it had a solution on a finite algebraic extension L/K, where

K=Q(ϵ)(p,q),

with algebraic letters and kinematics-independent residue matrices. Let n=[L:K]. Taking normalized trace gives

∇(
n
1
	​

Tr
L/K
	​

G)=F−
n
ϵ
	​

a
∑
	​

M
a
	​

(ϵ)dlogNorm
L/K
	​

(L
a
	​

).

Here differentiation commutes with trace, and logarithmic differentiation converts norm to trace. Thus an algebraic solution would produce a rational gauge with rational dlog letters.

Your pole and degree bounds would then place that rational solution inside the already excluded class.

This descent works especially cleanly because G is an off-diagonal block: its trace-average still defines an invertible unipotent transformation. There is no determinant-of-G issue.

Hence:

No new finite algebraic cover rescues this particular affine strip problem.
	​


This statement assumes the same target contract—epsilon-free algebraic letters and constant residues—and the fixed rational diagonals. It is not a theorem about arbitrary nonlinear full-matrix changes to unrelated target connections.

Likewise, adding transcendental functions of epsilon alone does not repair a linear inconsistency over the constant field. The new gauge would have to be transcendental in the kinematics.

4. The decisive small calculation: eliminate G by covariant differentiation

This is the next experiment.

For a matrix-valued one-form η, extend the operator as

∇η=dη−ϵ(E∧η+η∧C).

The certified diagonal connections are flat, so

∇
2
=0.

The ordinary flatness equation and its behavior under gauge transformations are standard ingredients of canonical differential-equation reduction. 
arXiv

Set

Ω=
a
∑
	​

M
a
	​

(ϵ)ω
a
	​

,ω
a
	​

=dlogL
a
	​

.

Applying ∇ to

∇G=F−ϵΩ

eliminates the unknown gauge:

∇F+ϵ
2
(E∧Ω+Ω∧C)=0.
	​

(*)

Equation (*) is necessary for any gauge—rational, algebraic, logarithmic, or fully transcendental—to reach that target.

Conversely, on a simply connected nonsingular analytic domain, it is sufficient for local existence of a gauge, because the Hom connection is flat.

Important recurrence caveat

Do not set ∇F=0 automatically. This is a strip inside a larger triangular system. Already fixed intermediate blocks can contribute to its curvature equation.

Use the actual dependency-closed F. Equation (*) accommodates those contributions without changing the recurrence.

Concrete modular system

Write

E=E
p
	​

dp+E
q
	​

dq,C=C
p
	​

dp+C
q
	​

dq,F=F
p
	​

dp+F
q
	​

dq.

Compute

K
F
	​

=
	​

∂
p
	​

F
q
	​

−∂
q
	​

F
p
	​

−ϵ(E
p
	​

F
q
	​

−E
q
	​

F
p
	​

+F
p
	​

C
q
	​

−F
q
	​

C
p
	​

).
	​


For each letter, write

ω
a
	​

=ℓ
a,p
	​

dp+ℓ
a,q
	​

dq.

The linear contribution of its unknown 2×2 matrix M
a
	​

 is

E
p
	​

M
a
	​

ℓ
a,q
	​

−E
q
	​

M
a
	​

ℓ
a,p
	​

+M
a
	​

ℓ
a,p
	​

C
q
	​

−M
a
	​

ℓ
a,q
	​

C
p
	​

.

Solve

a
∑
	​

(E
p
	​

M
a
	​

ℓ
a,q
	​

−E
q
	​

M
a
	​

ℓ
a,p
	​

+M
a
	​

ℓ
a,p
	​

C
q
	​

−M
a
	​

ℓ
a,q
	​

C
p
	​

)=−
ϵ
2
K
F
	​

	​

.
(**)

There are only 64 unknowns for the 16 polar letters.

Recommended single pilot

Use 52 existing generic kinematic points, giving 208 scalar equations.

Build one system for the already available 48 letters:

208×192,

and examine its 64-column submatrix corresponding to the 16 polar letters:

208×64.

This is one small compatibility calculation, not another gauge ansatz.

Your previous 80×192, rank-80 integrability result was underdetermined and nondiscriminating. The proposed 208-row system can actually reject the full 48-letter compatibility class.

The left matrix in (**) is epsilon-independent because E,C,ω
a
	​

 are epsilon-independent. Factor it once and process the existing regulator images as multiple RHS vectors.

The numerical arrays A,b alone do not determine ∂
p
	​

F
q
	​

−∂
q
	​

F
p
	​

. Obtain those derivatives from the existing rational evaluator using first-order automatic differentiation, or reuse the prior residue-integrability implementation if it implements exactly (*). No whole-expression symbolic normalization is needed.

Interpretation of the result
Result of (*)	Mathematical conclusion	Next route
16-polar-letter system is consistent	A local analytic gauge to that dlog target exists. Your rational obstruction and trace descent exclude rational and finite-algebraic gauges in the certified class.	GO: transcendental unipotent gauge with the existing polar alphabet.
16 fails, but 48 passes	A transcendental gauge can reach the existing expanded target, although no rational gauge can.	GO: transcendental gauge with the already constructed 48-letter target.
Both fail	No gauge of any function class reaches either target while the diagonals and previously fixed strip data remain unchanged.	NO-GO on a strip-only gauge implementation. The target connection or the coupled row problem must change.

The second outcome is not inconsistent with the completed polar census. Once G is transcendental, it can carry logarithmic singularities on nonpolar curves whose contributions cancel against target dlogs. The earlier “no new divisors” argument applied to rational/meromorphic gauges.

A pass at the sampled images is the pilot decision under your existing acceptance model. The small residue solution must then be reconstructed in epsilon before an exact analytic gauge is defined.

5. What the successful new gauge would be

For a compatible Ω, let the known diagonal fundamental matrices satisfy

dY
E
	​

=ϵEY
E
	​

,dY
C
	​

=ϵCY
C
	​

.

Then

G=Y
E
	​

[G
0
	​

+∫Y
E
−1
	​

(F−ϵΩ)Y
C
	​

]Y
C
−1
	​

.
	​


Equation (*) is exactly the condition making the integrand closed. The base point and path fix the branch and integration constant.

This is a concrete differential-field extension, not a guessed new square root. It starts from the already known diagonal functions and introduces only the required integral of their products with the forcing. Such additional iterated-integral functions are an established mechanism in extensions of epsilon-factorization algorithms, including their inhomogeneous cleanup stage. 
arXiv

Keep the contract distinction: M
a
	​

(ϵ) gives an exact dlog intermediate. A final epsilon form still requires epsilon-independent coefficient matrices after the appropriate family normalization.

Higher poles and ellipticity

Allowing higher-order closed rational targets genuinely enlarges the space through terms dH, with H rational. But this abandons the simple-pole target underlying the current completeness theorem. Higher-order poles can be apparent under a unipotent transformation; they are not automatically evidence of an intrinsically irregular connection. 
arXiv

Nor does this obstruction establish ellipticity. The homogeneous diagonal systems are already known rational epsilon systems. An off-diagonal rational-gauge failure does not identify a new irreducible elliptic period. Elliptic or more general period technology needs homogeneous/maximal-cut evidence, not a failed rational affine section; existing generalized factorization methods make that distinction explicitly. 
arXiv

Immediate GO/NO-GO

GO: compute the 208-row covariant-integrability system (*) for the existing 48 letters and its 16-letter subspace.

NO-GO: more closed rational forms, rational canonical diagonal changes, new finite algebraic covers, or denominator/support enlargement.

If compatibility passes, implement the transcendental gauge defined by variation of constants. If it fails, stop trying to repair G alone: even an unrestricted transcendental strip gauge cannot reach the tested target.
