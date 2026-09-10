# Shared compact-cut convergence certification

Verified outgoing model: gpt-6-pro; HTTP 200.
Conversation: https://chatgpt.com/c/6a9fbe79-8c30-83e8-8bfb-e3ee1abad5f4
Reviewed source: Sources/14_Convergence.wl (exact submitted version).
The fixes below were implemented after this review and tested locally;
the review is not claimed to have approved a later unseen revision.

## Question

The user asks for only one certification implementation. We consolidated the prescription checker and the older cut-mass convergence proof (your preceding review) into Integrals/Convergence.wl (attached). Both ordinary-i0 removal, Laurent pole bounds and dimensional recurrence convergence now call cutIntegralConvergenceCertificate. Removed the old unit-cut/sign-based independent proof. Unit and arbitrary finite positive integer cut powers use the same nonnegative mass-deformation criterion. Generic endpoint scope remains explicit and does NOT authorize observed delta/plus distributions. No source-level endpoint theorem is being replaced.
Please review this implementation for mathematical regressions, especially the extension from fixed rational kinematics to symbolic domain assumptions, off-shell mass deformation, fixed external null anchors, constant nonzero external denominator check, real signed quadratic normalization, cut Jacobian, and whether source numerator/partial fraction adapters can use it with redundant ordinary propagators. The old cone/rank implementation and external-basis reduction were moved; pole-bound normal derivatives are unchanged. Shared geometric certificate is before differentiation; it proves existence of sufficiently large Re(D), not a value of D*. Failures keep original i0; numerical AMFlow interface is unchanged.
Current tests pass ordinary/dotted/higher derivatives, negative core scales, symbolic physical domain, and nonzero symbolic external denominator requirements. We are also testing all 345 actual NNLO masters and NLO source terms. Identify concrete issues; do not claim full endpoint automation.

## Pro response

Not entirely: the consolidation preserves the mass-deformation argument, but I found a symbolic-domain false-acceptance path in the inherited Baikov fallback, a broken Boolean check in the cut-Jacobian guard, and a conservative failure mode for redundant source denominators. These findings concern the attached checker and the pinned miRepBaikov dependency; I have not executed your current test suite or the 345-master campaign.

1. Symbolic fallback can silently exclude a parameter value that the certificate still claims to cover

The direct bilinear test correctly requires its proportionality factor to be real and nonzero under the supplied assumptions. However, failure of that test falls through to a Baikov coordinate transformation whose invertibility is not established over those assumptions. The fallback then accepts literal False from the transformed zero-containment problem. 

Convergence +1

Here is a concrete counterexample. Take one loop, external null beams with P=k
a
	​

+k
b
	​

, P
2
=s>0, and

D
1
	​

=ℓ
2
,D
2
	​

=(P−ℓ)
2
,Q=λℓ⋅k
a
	​

,

where the assumptions declare λ real but permit λ=0. Both cuts have unit powers.

Write

r=ℓ
2
,u=ℓ⋅k
a
	​

,v=ℓ⋅k
b
	​

.

The fallback’s inverse-propagator coordinates are

z
1
	​

=r,z
2
	​

=r−2u−2v+s,z
3
	​

=λu.

Their transformation determinant is 2λ. For λ

=0,

u=
λ
z
3
	​

	​

,v=
2
s+z
1
	​

−z
2
	​

	​

−
λ
z
3
	​

	​

,G=
s
4uv
	​

−r.

Setting the ordinary coordinate z
3
	​

=0 simplifies this to

G=−z
1
	​

.

Therefore G>0 contradicts the nonnegative cut-mass condition z
1
	​

≥0, and the fallback returns False.

But at λ=0, the original ordinary denominator vanishes everywhere. The massless physical point

r=0,u=v=s/4

has G=s/4>0. The coordinate transformation has silently removed precisely the parameter value that invalidates the claim.

The pinned builder uses symbolic MatrixRank followed by Inverse[a], without proving the transformation determinant nonzero on the requested domain. This is material because MatrixRank treats symbolic parameters generically rather than resolving their exceptional values. 
Wolfram Documentation

Required correction: every inverted coefficient matrix used to establish the certificate—not just the external Gram and cut-elimination minor—must be invertible throughout the certified domain. Either prove that condition, return unsupported, or explicitly restrict/split the returned domain. Merely adding Det[a] != 0 inside the QE query would still silently discard the exceptional locus unless that restriction is also part of the certificate.

This applies to symbolic pivots in the effective-external reduction as well. For your usual constant-rational routing matrices, these checks are inexpensive.

2. The cut-Jacobian affineness check is not functioning as intended

The attached condition contains

Wolfram Language
Exponent[poly, coordinates, Max] <= 1

where coordinates is a list. Exponent returns a list of exponents, not their overall maximum. For example,

Wolfram Language
Exponent[u + u^2, {u, v}, Max]

returns {2, 0}. 

Convergence

 
Wolfram Documentation

Consequently, the comparison can remain symbolic. AllTrue can also return a symbolic result, and an If with an undecided condition does not execute its failure branch. Since this If is followed by further statements, the checker can continue without having established affineness. Passing valid-input tests does not expose this defect. 
Wolfram Documentation
+1

Moreover, simply taking the maximum of the per-coordinate degrees would certify multiaffine expressions such as uv, not necessarily affine ones.

Use an exact reconstruction check instead:

Wolfram Language
constant = polynomials /. Thread[coordinates -> 0];
residual = Expand /@
  (polynomials - matrix.coordinates - constant);

If[! TrueQ[
    MatrixQ[matrix, exactRationalQ] &&
    MatrixRank[matrix] === Length[cuts] &&
    AllTrue[polynomials, PolynomialQ[#, coordinates] &] &&
    AllTrue[residual, epsOrderZero]
  ],
  epsOrderFail["ConstantNonsingularCutEliminationRequired"]
];

Also require that constant contains no loop dependence left outside the chosen coordinates.

The eliminated coordinates must be independent loop scalar products. The current collection takes every Pair appearing in the cut polynomials. If symbolic external scalar products have not all been replaced by invariant symbols, that collection can include fixed external parameters and select a minor differentiating with respect to them. Those are not cut-elimination coordinates. 

Convergence

For correctly normalized quadratic cut records, other checks already strongly constrain affineness, so this broken guard does not itself demonstrate an erroneous saved integral. It is nevertheless not a valid certificate check.

3. Redundant source propagators work through the cone path, but not generally through the fallback

The geometric cone/rank tests do not require ordinary propagators to form an independent family. Thus redundant source denominators are mathematically compatible with the convergence theorem.

The fallback does impose a stronger representation requirement:

Wolfram Language
cutOrderReduceExternal[d,g]

passes every active inverse polynomial to miRepBaikov, whose pinned implementation rejects linearly dependent coefficient rows. It also rejects a loop-independent external denominator included as a zero coefficient row. 

Convergence +1

For example, with P=k
a
	​

+k
b
	​

,

D
1
	​

=ℓ
2
,D
2
	​

=(P−ℓ)
2
,D
3
	​

=ℓ⋅k
a
	​

,D
4
	​

=ℓ⋅k
b
	​


satisfy

D
2
	​

=D
1
	​

−2D
3
	​

−2D
4
	​

+s.

A source term containing all four is legitimate, but they cannot all be independent Baikov coordinates.

This is a conservative failure, not false removal: a term may pass when every ordinary factor has a cone witness, then fail when any factor requires QE.

The direct correction is to formulate fallback containment in independent scalar-product coordinates—or an independent completed coordinate basis—while retaining every original ordinary polynomial as a function of those coordinates. Then query its actual polynomial zero set rather than requiring it to be a coordinate z
j
	​

. This uses the same proof and also avoids the symbolic-coordinate singularity in item 1.

Do not discard a redundant denominator from the whole-term proof merely to make the coordinate matrix square. External nonzero factors may be factored out after their domain-dependent nonvanishing check.

4. Source adapters must preserve the correspondence between the cut polynomials and oriented momenta

The central function extracts cut masses and signs using PropagatorMomenta, but constructs the causal cone, energies, and total momentum from OrientedCutMomenta. It does not itself check that those descriptions identify the same off-shell cuts. 

Convergence

For each cut slot c, require the exact off-shell identity

(q
c
oriented
	​

)
2
=m
c,0
2
	​

+σ
c
	​

D
c
	​

,
	​


with the recorded normalization and m
c,0
2
	​

≥0. Otherwise nonnegative deformations of the recorded D
c
	​

 need not make the momentum used as a cone ray future causal.

The earlier master-definition constructor supplied a cut-momentum compatibility check. New raw-source and partial-fraction adapters must supply the same invariant or invoke it here. A constant full-rank cut Jacobian alone does not establish that correspondence.

Similarly, the QE fallback needs real inverse-polynomial coefficients and real coordinate transformations on the stated domain. The direct normalized-quadratic and bilinear paths establish the relevant reality conditions; the fallback should not obtain them merely by calling Resolve[..., Reals].

Your previously described polynomial-numerator validation remains necessary at the source adapter. This file does not inspect a source numerator: it states the admissible numerator class in the returned record. Ignoring a verified polynomial numerator during zero-containment is sound because it is bounded on the compact domain; ignoring an unverified rational numerator could miss another denominator. 

Convergence

5. The underlying deformation proof has not regressed

The important parts remain intact:

The null anchors are still restricted to fixed external rays; deformed cuts are not incorrectly assumed to stay null. The causal-sum and both-energy-sign rank arguments retain their earlier logic. 

Convergence +1

The external-denominator branch now proves core != 0 and reality under the symbolic assumptions rather than equating “not identically zero” with “nonzero throughout the domain.” That is the correct improvement. 

Convergence

The deformation query retains independent signed cut variables and does not set them on shell. The external-basis reduction retains the off-shell inverse polynomials. Arbitrary finite positive integer cut powers therefore do not require a second geometric theorem: their finite derivatives require stronger domination exponents, but the same zero-containment result. 

Convergence +1

For symbolic assumptions, interpret the result pointwise in the stated physical domain, and locally uniformly where the required nonzero factors stay bounded away from zero. It does not assert one global domination constant across external threshold or Gram-degeneracy limits.

I would retain the single implementation, but fix items 1–2 before treating it as a domain-wide symbolic certificate. Resolve item 3 for genuinely general pre-partial-fraction sources, and enforce item 4 at their adapter boundary. None of these findings by itself establishes an error in the previously computed NLO/NNLO values; nor does the consolidated checker confer any new observed delta/plus-distribution authorization.

## Implementation response

1. Replaced the Baikov inverse-propagator-coordinate fallback by a query in
   complete independent loop scalar products. It retains every original
   inverse polynomial, so symbolic zero scales and redundant factors cannot
   disappear through an inverse-propagator coordinate transformation.
2. Replaced the list-valued Exponent comparison by exact affine reconstruction,
   an explicit Boolean result, and independent loop-only scalar-product
   coordinates. External Pairs cannot be cut-elimination coordinates.
3. Required a nonzero domain-wide pivot minor for symbolic effective-external
   bases. Constant rational matrices retain their inexpensive path.
4. Enforced real affine inverse-polynomial coefficients, exact off-shell
   consistency of cut rays with cut polynomials, and a timelike time reference
   in the common checker.
5. Added regressions for the zero-scale counterexample, redundant factors,
   external constants, an interior pole, nonreal coefficients, a multiaffine
   polynomial, mismatched cut rays, and a symbolic external-basis pivot.

The source numerator adapter's polynomial check and endpoint-scope limits remain.

A further local regression exposed held quantifier-list evaluation: inject the
computed variable list and condition using With before Resolve[Exists[...]].
The corrected fallback now positively certifies redundant safe factors and a
strictly nonzero massive shift, while rejecting an actual interior massive
pole. The earlier rejection fixture was a safe spacelike denominator shifted
away from zero; it was replaced by a denominator with a verified interior pole.
