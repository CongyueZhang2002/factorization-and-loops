# Pre-master implementation review

Model: gpt-6-pro; request HTTP status: 200.

Conversation: https://chatgpt.com/c/6a9fbe79-8c30-83e8-8bfb-e3ee1abad5f4

## Question

Follow-up implementation review of the pre-master optimization. Please inspect for a concrete mathematical or Wolfram error, not stylistic expansion. Prior source commit remains 6594c2aca693b787a9abc358b705111cd814b9ec, https://github.com/CongyueZhang2002/factorization-and-loops/tree/codex/scientific-terminology-and-math-fixes . Changes below are uncommitted.

We fixed the shifted-quadratic false acceptance by checking the actual inverse core and explicit mass field, preserving negative scales. The null-bilinear extension remains conservative. Fixed-sign diagnostics explicitly exclude endpoint convergence, i0 removal and auxiliary mass deformation. Physical future-null momentum conservation is an assumption of this theorem route. Family polynomials and AMFlow prescriptions were not modified.

Completion sign checks now use positive ordinary index support only, at initial families, after dimensional shifts, at IBP input import, and on final terminal masters in both import paths. Kira config is exported with all distinct maximal support masks rather than their union. FeynHelpers creates the job from the actual requested integrals; no preferred-master interface is supplied. An unsupported positive master fails acceptance. No sector is set to zero by this check. Exact fixtures exercise mixed ISP indices 0,-1,+1 and incomparable supports.

Speed: repeated DeclareScalar assignment invalidated FeynCalc caches, so existing True declarations now avoid reassignment (still restore deliberately revoked declarations). Fresh coefficient prep went 45.7->10.5s; Expression, Masters, PreFactor, Remainder and HadronicNormalization are exactly SameQ.

Closed Dirac traces are simplified distinctly before products expand; original Calc still handles everything afterwards. Two hard NNLO UU pairs have exact Expand[old-new]===0 (0.007s test) and Calc-stage cost45.8->20.3s and47.9->18.2s. Fresh full-pair optimized run49s versus old80s. Full UU/LL/TT NLO regeneration and external references will check BMHV/helicity and virtual effects; an exact general operation is intended, no fitted process factors.

Prepared FeynArts diagrams are reused only inside a single run with fixed model data, with explicit generation inputs and per-call diagram-index validation. A changed card/model name/loop order fails reuse. Does any of this undermine correctness? In particular audit support filtering and whether independently simplifying traces can change dimensional/Lorentz contractions.


The patch details most relevant to correctness:
- quadratic: reject nonzero StandardPropagatorDenominator mass field; choose a real linear q (or q=-I original for a negative square), compute exact rational nonzero scale from UnitCore / ExpandScalarProduct[FCI[SPD[q]]], retain scale in min/max bounds.
- positive support: group actual GLIs by family, validate name and index vector length, select non-cut positions where any index is positive; only those ordinary propagators undergo the physical sign theorem. The same operation rechecks terminal masters.
- maximal sectors: form distinct Boolean masks Boole[nu_j>0], retain each mask not componentwise contained in another requested mask; pass those masks directly to KiraCreateConfigFiles. KiraCreateJobFile still uses actual GLI targets.
- traces: prepared=SUNSimplify[expression,Explicit->False]; traces=DeleteDuplicates[Cases[prepared,_DiracTrace,{0,Infinity}]]; prepared=prepared/.Normal[AssociationMap[DiracSimplify,traces]]; Calc[prepared,Assumptions->assumptions].


## Pro response

The support filtering and trace rewrite are mathematically sound as described. I do not find an inherent Lorentz-contraction or BMHV error in the trace replacement. The one potentially missing correctness guard is that every GLI exponent must be an integer before positive-support filtering; validating only the family name and vector length is insufficient.

I checked the pinned front-end and the relevant FeynHelpers/FeynCalc implementations. The uncommitted patch itself has not been executed here.

1. Positive support and maximal sectors

Taking the union of positive ordinary positions within a family is correct for checking individual denominator polynomials. This does not imply taking the union of their sector masks: retaining all incomparable maximal masks is the correct, narrower sector specification.

The relevant IBP closure argument is

∂
μ
	​

D
j
−ν
j
	​

	​

=−ν
j
	​

D
j
−ν
j
	​

−1
	​

∂
μ
	​

D
j
	​

.

For ν
j
	​

=0, the contribution vanishes. For an integer ν
j
	​

<0, the shifted exponent ν
j
	​

+1≤0 remains nonpositive. Expressing polynomial numerators in the completed scalar-product basis introduces no inverse powers. Thus ordinary polynomial IBPs do not need to activate a numerator-only completion slot.

Your division between configuration masks and job targets matches the helper interfaces. KiraCreateConfigFiles accepts explicit Boolean masks. Its GLI overload instead calls FCLoopFindSectors[..., Last -> True], so supplying the maximal masks explicitly avoids that single-sector selection. The inspected KiraCreateJobFile GLI overload groups the actual targets by sector and computes the corresponding r,s bounds; it does not require replacing those targets with your maximal masks. 
FeynCalc

The terminal-master rejection provides the necessary final check against an unsupported positive denominator introduced through reduction or mappings. There is no reason to restore the old rejection of unused completion slots.

The missing exponent guard

Before either Boole[ν > 0] or a positive-position selection, require the equivalent of

Wolfram Language
VectorQ[indices, IntegerQ] &&
AllTrue[indices[[cutIndices]], # > 0 &]

alongside the stated family/length checks. FeynCalc’s sector finder itself documents support only for integer indices. 
FeynCalc

There are two concrete failure modes otherwise:

A symbolic exponent can yield an undecided positivity test and be silently omitted by a selection that retains only True.

An exponent ν=−1/2 is “nonpositive” but gives D
1/2
, not a polynomial numerator. For a mixed-sign D, its branch information cannot be ignored.

If this integer-and-cut-power validation already occurs before all four filtering points, there is no new defect here. Also ensure that “contained in another mask” excludes the mask itself; after deduplication, reflexive containment must not delete every maximal element.

2. Independent trace simplification does not lose contractions

A closed Dirac trace need not be a Lorentz scalar. It can be a tensor

T
μ
1
	​

⋯μ
r
	​

=tr(Γ
μ
1
	​

⋯μ
r
	​

).

Replacing it by its exact tensor expression before contracting with another trace or an external projector preserves the result. The essential requirement is preservation of the free index labels and their dimension tags, not simultaneous evaluation of all traces.

DiracSimplify evaluates traces to such tensor expressions, including mixed four- and D-dimensional structures in BMHV. The later Calc still performs contractions involving the surrounding factors. 
FeynCalc
+1

Your Wolfram expression

Wolfram Language
Normal[AssociationMap[DiracSimplify, traces]]

correctly produces rules of the form

Wolfram Language
trace1 -> simplifiedTrace1

rather than rules in the reverse direction or a list of values. DeleteDuplicates only avoids reevaluating identical trace expressions; replacing their occurrences does not discard multiplicities, including traces occurring inside powers. 
Wolfram Documentation
+1

The implementation conditions worth checking are narrow:

Establish BMHV before the new early call. It must run inside the same scheme, scalar-product, and dimension-setting scope as the original Calc. Keeping Calc afterward cannot repair an earlier evaluation performed in the wrong scheme. 
FeynCalc

Do not add independent index renaming or dimensional projection. Shared free indices must remain shared. The inspected DiracSimplify defaults disable dummy-index canonicalization and use empty replacement-name lists; your bare call is compatible with that behavior unless global options have been changed.

In particular, there is no need to impose EpsContract -> False merely because traces are evaluated separately in BMHV. The problem would be changing the dimension or contraction rules, not evaluating an exact tensor earlier.

The smallest useful exact fixtures are

tr(γ
μ
γ
ν
)tr(γ
μ
	​

γ
ν
	​

)
tr(
γ
ˉ
	​

μ
γ
ˉ
	​

ν
)tr(γ
μ
	​

γ
ν
	​

)
tr(
γ
^
	​

μ
γ
^
	​

ν
)tr(
γ
^
	​

μ
	​

γ
^
	​

ν
	​

)
	​

=16D,
=64,
=16(D−4).
	​


Here 
γ
ˉ
	​

 and 
γ
^
	​

 denote the four-dimensional and evanescent projections. These follow directly from the Clifford trace and projector ranks. Add one product of two odd-γ
5
	​

 traces with contracted external indices. Comparing the old and new routes on these expressions tests precisely what the two UU pairs do not: preservation of barred/evanescent contractions and the two Levi-Civita tensors.

3. Quadratic-core check

The revised test closes the previously identified shifted-denominator hole. Requiring zero explicit mass field and

q
2
UnitCore
	​

∈Q∖{0}

establishes the actual admitted form D=κq
2
, provided q passes the real constant-coefficient momentum check.

For an imaginary encoded momentum q
original
	​

=iR, choosing q=−iq
original
	​

=R and retaining the resulting negative κ is correct. The bounds must be sorted after multiplication by κ, and the cached classification must retain that scale.

No family-polynomial replacement modulo cut equations is needed. Your statement that those polynomials remain unchanged avoids the dotted-cut issue from the earlier review.

4. Declaration and diagram reuse

Skipping an already-true scalar declaration is a valid no-op, provided the condition queries the current DataType[..., FCVariable], rather than an “ever declared” cache. That preserves the ability to restore a deliberately revoked declaration. This is exactly the state represented by FeynCalc’s DataType interface. 
FeynCalc

Run-local reuse of prepared diagrams is also sound under your fixed-generation-input assumption. Reusing diagrams is not the same as reusing a converted amplitude with stale momentum labels or spin projectors. The pinned front-end extracts the selected diagram and performs CreateFeynAmp and FCFAConvert using the current side’s momenta and loop list; retaining that per-call conversion preserves the relevant separation.

I would retain these optimizations. Confirm the complete integer-exponent guard and add the small dimension-sensitive trace fixtures. Nothing in the supplied trace rewrite requires reverting to global product expansion, and nothing in the support policy requires rejecting numerator-only completion ISPs again.