# Saved integral relation reuse

Model: gpt-6-pro; thinking: standard. Request HTTP 200.

Conversation: 6aa2eb2d-5588-83e8-bf9d-d35cd8d66f3b
Request: 03e12b64-b9c5-4d08-8a72-87a08eb43792

## Request

Continue the ppHX double-real regeneration review (gpt-6-pro). The 50 focused definition/catalog/assembly assertions pass. Typed definition comparison now revalidates Cuts; full domain/measure/dimension data participates. Singular/plural catalog map files remain bound to actual source Definitions+Integrals and exact target catalog, including direct TargetTopologies. WXF writer extension/export/readback/rename are checked. A real producer-consumer CLI regression is queued after production because running it beside reduction exceeded the two main-kernel license limit.

One real issue: all 27 fresh ghost masters exactly affine-match the saved 1,561 local DE positions, but one maps to CF26 row8, not a requested row with an explicit stored solution. Its previously used reduction was an exact global overlap relation (four terms in CF1/CF2, rational in eps,v,w, with s^-3,s^-2,s^-1,1 factors), not another direct affine identity. We must support this generally for the regenerated gluon catalog too.

Available saved data: 430 fully defined original families; GlobalMasterDifferentialSystem has 355 UnreducedMasterIntegralBasis, 348 retained MasterIntegralBasis, 7 independent exact constraint rows, MasterIntegralIdentities, per-family IntegralEmbedding; the original cut equivalence mappings are saved. Source normalized GLIs here all have two loop integrations; every inverse propagator has mass dimension2, and s>0. DE variables are v=-t/s,w=-u/s and DE integrals normalized at s=1. Old exact reduction audit retained explicit row-combination weights proving each nontrivial global identity against those 7 rows. Do not use numeric zero to assert identities.

Proposed general code: compose a catalog's exact affine maps with supplied exact homogeneous linear integral relations; first bind the relation basis to explicit target definitions, verify each linear relation against retained constraint rows exactly, then restore each coefficient's scale factor using explicit integral weights derived from the definitions (equal L gives weight=-sum(powers), common L*D/2 cancels). Keep affine matching and linear reduction provenance separate, and keep endpoint generalized terms retained as user requested. Avoid trying to create missing master solutions when an already established exact relation removes that integral.

Please review the mathematical and software minimum needed, especially scale restoration and binding to correct integral definitions, and suggest the smallest reusable design using existing AssembleCutContributions and RestoreIntegralEquationScale interfaces. Any more direct safe approach? No need for an endpoint cancellation proof or redoing already checked DE solutions. Be concise.

## Review

Yes—compose the exact affine match with the established linear relation. CF26 row 8 does not require a new stored solution when a certified relation expresses it in integrals whose solutions are already available. Keep the two kinds of identity separate.

1. Scale restoration: your weight is correct, with a fixed direction

For the stated bare normalized GLIs, let N
i
	​

=∑
a
	​

n
ia
	​

, including signed numerator indices and raised cut powers. With homogeneous mass-dimension-two inverse propagators,

I
i
	​

(s,−sv,−sw;ϵ)=s
LD/2−N
i
	​

I
i
	​

(v,w;ϵ).

Negative propagator powers represent numerator factors, so they must not be omitted from N
i
	​

. 
FeynCalc

Consequently,

I
i
	​

=
j
∑
	​

r
ij
	​

I
j
	​

⟹
I
i
	​

=
j
∑
	​

r
ij
	​

s
N
j
	​

−N
i
	​

I
j
	​

=
j
∑
	​

r
ij
	​

s
w
i
	​

−w
j
	​

I
j
	​

,w
i
	​

=−N
i
	​

.
	​


For example, N
i
	​

=N
j
	​

+3 gives s
−3
, not s
3
. The common LD/2 cancels because the loop counts and dimensions agree.

This is exactly the direction implemented by RestoreIntegralEquationScale[rules,normalization]. Its RHS must remain independent of the scale symbol: restore with s,v,w independent, then substitute v=−t/s, w=−u/s if needed.

The indispensable qualification is that the definitions actually realize this homogeneity. Explicit integral-dependent prefactors or dimensionful parameters held fixed can change it. Since your interface requires integer weights, cancelling the common LD/2 is appropriate; reject differing loop counts rather than silently applying the same shortcut.

Do not manufacture the normalization certificate by setting its success flag. Given unit-scale constraint coefficients K
aj
	​

, construct the lifted rows

K
aj
	​

s
−w
j
	​

,

pass them through NormalizeIntegralEquationScale, and verify that normalization returns the original rows exactly. That interface certifies the algebraic change of unknowns—not physical homogeneity, which must come from the bound definitions.

2. Minimal exact relation certificate

Let U be the ordered 355-element unreduced basis, and K the seven constraint rows in that basis. For each proposed rule, translate its LHS and RHS into U using the saved, definition-bound affine maps. Form the residual row

ℓ=e
i
	​

−
j
∑
	​

r
ij
	​

e
j
	​

,

with the corresponding mapped rows replacing e
i
	​

,e
j
	​

 when necessary. Accept only after checking the retained witness

ℓ−ωK=0
	​


entrywise by exact rational cancellation.

That is sufficient; no minimality or completeness argument is needed. Bind K,ω,ℓ to the same ordered basis, regulator, coordinate convention and original family definitions. A matching family name or row number is not a binding.

Also distinguish the two embeddings: the global IntegralEmbedding maps the unreduced basis to the retained basis; each family embedding maps its local basis to the retained basis. The baseline constructs precisely these orientations. Do not apply MasterIntegralIdentities a second time to an already reduced family embedding.

3. Smallest reusable design

Add one adapter between catalog matching and assembly:

Bind and verify. Consume the affine-match record, relation basis/definitions, exact constraint matrix, proposed linear images and witnesses. Require homogeneous linear GLI expressions with zero scalar remainder. Preserve the existing source and target bindings.

Resolve to solution-backed targets. Prefer an existing direct affine destination with sufficient saved orders. Otherwise use a verified relation whose entire RHS has suitable saved solutions. The 348 retained global coordinates are not automatically the solution-backed target set. Use the family embeddings to propose images, but verify the resulting relation against K.

Restore and compose once. Restore the relation coefficients’ scale factors, then produce a fully flattened source-to-final-target rule list for each contribution. Pass those lists through MasterIntegralRulesByContribution; no new assembly format is needed. The existing linear-combination infrastructure already supports exact composition of linear reductions, whereas linearMapIntegrals only supports integral-to-integral renaming.

Keep catalog identities disjoint until composition finishes. Avoid unrestricted //. rewriting: source and target names can coincide, and identity/cyclic rules are not a reduction strategy. Store affine provenance, constraint witnesses and scale restoration separately.

Finally, recompute order requirements from the fresh composed coefficients. Rational relation coefficients can introduce epsilon poles and demand deeper saved target expansions. This does not require recomputing already sufficient solutions, and it must not trigger physical-measure conversion twice.

More direct safe approach

Replay the saved four-term rule and its witness first. Rebind its GLIs to the current target definitions, verify ℓ=ωK, restore scale, and compose. For regenerated gluon masters, repeat only for needed images; perform a small exact elimination against the same seven rows only when no saved suitable image exists. There is no reason to reconstruct the global DE or solve unused local positions.

The highest-value new tests are the CF26 four-term scale exponents; rejection of a reordered or wrongly bound constraint basis; rejection of incompatible normalization/loop count; complete flattening into solution-backed targets despite source-name collisions; and an epsilon-pole relation that correctly increases the required saved order.

The composed rules should inherit the established relation/domain scope, not acquire a stronger endpoint certificate. Generalized endpoint terms remain retained as requested.