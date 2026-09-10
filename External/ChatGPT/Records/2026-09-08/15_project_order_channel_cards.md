# Project/order/channel cards

Verified outgoing gpt-6-pro, HTTP 200.

## Question

Review a project/card redesign for FeynFacet, in light of lower-order channel dependencies. User explicitly wants project/card.wl -> LO/channel, NLO/channel, NNLO/channel, with very few contribution cards (Real, Virtual, Counterterm at NLO) and pleasant Wolfram formatting. No backward compatibility required. Proposed:
- ppHX_UU_NNLO owns LO, NLO, and existing NNLO double-real. Separate ppHX_LL_NLO and ppHX_TT_NLO; both incoming beams polarized as previously fixed. Root card.wl declares common model, kinematics, beam/observed polarization, scales, schemes, species/model map and channel catalog. Runtime geometry/phase-space constraints must still distinguish Born/virtual from real.
- NLO/qqp-qqp/Cards/{Real,Virtual,Counterterm}.wl contain only changes; LO/{qqp-qqp,qg-qg}/Cards/Born.wl; all dependent Born channels resolved by exact existing splitting/finite-kernel enumeration, not just main Born. Custom finite-scheme mixing still expands dependencies.
- Counterterm.wl selects UV+both PDFs+observed FF and kernels/schemes; generated individual convolution records are results, never extra input cards. No generated diagram-index rewrites of user's cards.
- NNLO double-real physical gluon and ghost components can be entries of one DoubleReal.wl, preserving the current 1/2 gluon and -1 ghost weights explicitly, not applying factors twice.
- General reader composes root shared settings, channel identity and contribution delta. Explicit dependency plan and output directories by project/order/channel; no inference that same channel supplies all lower-order inputs.
- Move actual outputs/Kira to matching channel folders; retire stale original seed project separately (its TT was incoming-to-outgoing transfer, unlike current TT). Update active drivers/tests and embedded path references, without changing mathematical formulas.
Do you see a mathematical or maintainability problem? In particular advise on channel identity vs extra real radiation, polarization of parent/daughter Born channels, and making scheme dependencies robust. This is schema/workflow redesign, not a new NNLO calculation. Please keep review focused.

## Pro response

Yes—the proposed layout is sound, and one counterterm card per channel is sufficient. The main risks are letting a Born-style folder name define the channel’s physics, inheriting quark-specific projectors into gluon dependencies, and resolving dependencies before the effective scheme is known.

1. Channel identity must be independent of the extra radiation

For this single-inclusive observable, distinguish the hard coefficient’s identity

(a,b; c
observed
	​

)

from a particular subprocess ab→c+d+⋯. The factorization formula sums over the two incoming species and the fragmenting species; the unobserved final state belongs to the perturbative contribution. 
arXiv

qqp-qqp is an acceptable readable directory name, but its catalog entry should explicitly establish ordered incoming legs, observed species and leg, and the flavor relation q

=q
′
. Do not reconstruct those facts by parsing the directory name.

Thus Real.wl supplies qq
′
→qq
′
g, while Virtual.wl supplies the loop/Born interference for qq
′
→qq
′
, without changing the inclusive channel identity. Likewise, a DoubleReal.wl entry specifies its actual cut particles and observation assignment. It must not determine the underlying channel by deleting whichever particles happen to be last in an outgoing list.

Keep incoming-leg order meaningful. qg-qg and gq-gq can only share results through an explicit beam/momentum map. Also, qg→qg with observed q and the same scattering with observed g are different coefficient requests, even though the generated amplitude may be reusable.

Allow catalog entries without a nonzero Born contribution. A general channel catalog should not require every higher-order channel to have a corresponding nonzero Born.wl.

2. Inherit polarization by physical role, then resolve it by species

The project-level assignments should mean

UU:(U,U;U),LL:(L,L;U),TT:(T,T;U),

for beam A, beam B, and the observed fragmentation leg. They should not mean “insert these two quark correlator expressions into every dependent Born calculation.”

For the established LL dependency through q
′
→g, the required Born is the double-helicity qg Born, with a helicity-gluon projector on the replaced incoming leg and unpolarized fragmentation. It is not the UU qg Born, and it is not polarization transfer to the final quark. The polarized factorization formula and the separate polarized qg Born coefficient make this distinction explicit. 
arXiv
+1

Each dependency therefore needs the kernel’s parent/daughter species and leg map to resolve its own projectors, spin/color averages, and momentum substitutions. Retain the observed azimuth or harmonic definition as part of the common observable, particularly for TT.

For TT, a missing gluon-transversity route must be excluded by the supported kernel/projector rules—not replaced with an unpolarized gluon or guessed from the project label. Custom finite mixing must still be processed according to its declared spin operator.

Archiving the older spin-transfer TT project separately is necessary. A matching TT label and subprocess name must never be sufficient for result reuse. The resolved polarization roles distinguish the two observables.

3. Resolve schemes before enumerating dependencies

Your existing kernel enumeration is the correct source of dependencies. The root catalog should provide channel definitions or construction rules, not silently truncate the enumeration to the two initially populated LO folders.

For every nonzero splitting or finite-scheme entry, the plan should either resolve the required lower-order channel, establish its zero through the existing general rules, or fail explicitly because it is unsupported. Absence from the catalog is not a zero.

Keep kernel direction, PDF versus FF action, spin type, perturbative order, and normalization explicit. A scheme name alone is insufficient to distinguish different finite kernels. In particular, setting BMHV in FeynCalc does not supply the finite restoring counterterms automatically. 
FeynCalc

Avoid two independent sources of scheme truth. Let Counterterm.wl select the contributions and, where permitted, override named scheme settings; enumerate dependencies only after those overrides have been resolved. Changing a finite kernel must rebuild the affected dependency plan and assembled result. Unchanged generated Born expressions can remain reusable.

The dependency request must also include the required epsilon range and normalization. A finite LO or NLO output is not automatically a sufficient lower-order input for a higher-order counterterm. Aggregate the demands of all consumers before deciding that an existing lower-order artifact satisfies the request.

Keeping UV, both PDFs, and the observed FF in one input card, with individual convolution records generated as results, introduces no mathematical problem.

4. Card composition needs explicit override semantics

The concrete Wolfram trap is a shallow

Wolfram Language
Join[root, channel, contribution]

on nested settings. Join keeps the last value for a repeated association key; it does not automatically merge the nested values. A contribution overriding only "Scales" -> <|"FF" -> ...|> could therefore delete the inherited renormalization and PDF scales. 
Wolfram Documentation

Define the merge behavior: named settings associations merge by field, scalar values replace, and lists replace unless an explicit append operation is requested. Validate the fully resolved card, including incompatible combinations.

Keep process-wide invariant definitions in the root, but derive multiplicity-dependent support from the contribution. In particular, do not inherit

s+t+u=0

into real radiation merely because its channel has a two-body Born representative. Counterterms need their own mapped Born support inside the convolution, not a global Born substitution on the target density.

For readable cards, ordinary multiline associations with comments are sufficient. The reader should expose the resolved card for inspection without writing it back over the user’s input. Generated diagram selections and dependency records belong under results.

5. Component weights, output scope, and migration

One DoubleReal.wl containing the current gluon and ghost entries is appropriate. Preserve the existing 1/2 and −1 weights with an explicit statement of which normalization is already included. Component weights, identical-particle symmetry factors, and interference multiplicities must each be applied once; none should be inferred anew from the folder or component name.

Likewise, ppHX_UU_NNLO may own all three orders without implying that NNLO is complete. Retain bare double-real as the existing NNLO output scope. Missing real–virtual, double-virtual, or counterterm results must not become implicit zeros or automatic new campaign requests.

Within each order/channel, separate solver workspaces by contribution so that real and virtual family/configuration files cannot overwrite each other. Resolve embedded paths relative to the project root, not the current working directory.

For migration, compare old and new resolved physics data and mathematical payloads after excluding only path/bookkeeping changes. The decisive dependency fixtures are the LL qg Born route, a finite kernel that introduces an additional channel, and rejection of reuse from the old spin-transfer TT project.

Keep the proposed directory structure and small card count. Make channel identity, species-resolved polarization, scheme-resolved dependencies, and contribution-specific support explicit; those are the boundaries that prevent this reorganization from changing the calculation.