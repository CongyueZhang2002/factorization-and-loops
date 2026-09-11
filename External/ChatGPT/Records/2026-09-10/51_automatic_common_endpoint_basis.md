# Automatic common endpoint basis

Verified model: gpt-6-pro.

## Question

Important recovered local evidence: the earlier September7 ppHX run ALREADY handles the moving poles by exact common-basis scalar-row cancellation, and the current general endpoint planner already rejects residual moving divisors. Thus do NOT design new joint beta moments for this case yet.

Design/CoefficientPoleCancellation.md states: simple-pole residue r satisfies r*T(zc)=0 exactly in common normalized DE gauge; pole parts restored exactly; check full c^T*T rational row has no coalescing divisors; accepted normalized DE/gauge has fixed joint eps,z meromorphic class and uniform physical primary bounds. Existing coefficientEndpointCoalescingDivisors scans actual analytic unit values, and DetermineMasterCoefficientEndpointOrders multiplies exact full rational coefficients with gauge BEFORE expansions and fails CoalescingCoefficientEndpointDivisor if unresolved.

Old process-specific drivers selected two 13-master supports, common closed families CF230/CF231, shared CF1 masters, split exact CF1 pole parts from old epsilon5 finite coefficients, assembled all other supported full coefficients in these common bases. Exact FLINT cancellation removed moving poles in complete normalized rows. Four last projections+physical solutions47-68s each. 84ordinary families+8complementary outputs covered345 coefficient entries. The remaining weakness is that selection/construction lived in manual process drivers, not general campaign automation. Saved DE closures/embeddings and gauge identities exist, but fresh coefficient residues MUST be recomputed and checked.

Our fresh source partition now completed exact exceptional reconstruction of both CF1 sources in203s on1core (4.5MBresult). Their finite regular parts have proved eps1 cutoff and are reconstructing. All343other columns full rational ongoing. Final Terms preserves exact exceptional + finite regular with explicit uniform source tail class.

Proposed GENERAL automation:
1 positive denominator/unit classification identifies coalescing divisors and their master supports, across all physical weighted coefficients including ghosts.
2 use exact cut-integral catalog matches to find a retained closed family basis covering each support; smallest suitable closure, no family-name conditions. Existing complete family bases/catalog contain1561 local rows across91families; physical master definitions determine identity, not labels.
3 Masters unique to a pole group can contribute their entire exact coefficient row there (avoids unnecessary epsilon-pole growth from splitting every coefficient). Masters shared between groups are split into exact principal parts plus an exactly canceled regular remainder; finite regular terms stay with their original source/master tail certificate.
4 common-row gauge multiplication and existing exact FLINT cancellation verify removal of all moving divisors. Check fixed joint remainder class/domain with existing engine. If coverage/cancellation fails, explicit unsupported case; no dropping or guessing.
5 existing endpoint driver consumes generated common/regular inputs, coverage metadata ensures each whole master and removed/added exact piece appears exactly once.

Questions: is selection via physical exact affine catalog sufficient if normalized gauge has parameter-dependent degeneracy but complete fixed-unit connection? What bindings/closure checks are essential to safely use a different family's full row with shared partial pieces? Is it best to assign whole exact coefficients for unique group masters and only residues for shared masters as above, or can cancellation fail after this assignment despite residue cancellation (regular rows should add no moving poles)? Can reuse old source-only embeddings/gauge certificates after exact DE/definition match while recomputing fresh row, without rerunningDE production? Review for gaps and unnecessary complexity. Existing code's strict coefficient tail and coalescing-divisor checks mean the old final result is not invalidated just by identifying individual moving denominators.

Repo https://github.com/CongyueZhang2002/factorization-and-loops unpushed current changes. No new broad joint-moment machinery unless common-basis method truly fails.

## Pro response

Your correction is right: the recovered common-row cancellation addresses the moving-divisor risk. Individual coefficient poles do not invalidate an assembly that cancelled them exactly before expansion and passed the joint remainder checks. Automating that existing route is the appropriate fix; no new moving-kernel integration machinery is needed now. The baseline design explicitly documents this sequence and the exact-piece bookkeeping.

The proposed automation is sound, with the following qualifications.

1. Affine coverage identifies integrals—not an admissible endpoint frame

For a candidate closed family, write

I
support
	​

=E
F
	​

J
F
	​

,J
F
	​

=T
F
	​

Y
F
	​

,q
F
	​

=c
support
T
	​

E
F
	​

T
F
	​

.

The object to certify is the complete contracted row q
F
	​

 together with the already established uniform class of Y
F
	​

.

Exact affine matches suffice to construct E
F
	​

 when every required integral has a matching family position. They do not independently certify the gauge, physical solution or endpoint domain. Conversely, failure of affine coverage does not establish failure of coverage by the already verified linear relations; the existing relation adapter is a suitable bounded fallback.

Parameter-dependent degeneracy of T
F
	​

 is not automatically disqualifying. Its determinant may vanish at the moving divisor or at ϵ=0. Indeed, such degeneracy can make a nonzero residue row satisfy r
T
T
F
	​

(z
c
	​

)=0. Require generic validity of the transformation and the existing fixed joint-meromorphic class and physical bounds—not invertibility after a singular specialization.

A regular normalized connection alone is insufficient: its selected physical solution and boundary constants must have the stated meromorphic bounds. Preserve the established tangential domain; cancellation does not remove unrelated exclusions.

2. Whole exact coefficients for unique masters is the right default

Keeping their exact coefficients together avoids artificial epsilon-pole growth from unnecessary partial fractions. This is also the recommendation recorded in the recovered design.

For shared masters, splitting exact principal parts is sound, but “regular pieces cannot introduce moving poles” needs one qualification:

W
F
	​

=E
F
	​

T
F
	​


must itself be regular along the relevant moving divisor.

If

c
T
=
z−z
c
	​

r
T
	​

+h
T

and W
F
	​

 is regular there, then

PP
z
c
	​

	​

(c
T
W
F
	​

)=
z−z
c
	​

r
T
W
F
	​

(z
c
	​

)
	​

.

Thus assigning h elsewhere cannot spoil that cancellation. But if W
F
	​

 has a pole, a coefficient regular in the original basis can contribute to—and be necessary for—the cancellation.

Consequences for selection: the raw coefficient-divisor inventory is a candidate-support generator, not the final support certificate. After embedding/gauge multiplication, include any additional contributing pieces, try another saved frame, or merge genuinely coupled groups. Do not merge groups merely because they share a master.

For multiple divisors, verify one exact decomposition of the coefficient. Independent local principal-part extractions must not double-count pieces. Differences between pole locations can introduce additional epsilon or tangential denominators; rescan the actual resulting rows. Higher multiplicities require all principal parts, not only the simple residue.

The existing FLINT cancellation operates in the exact rational-function field, so the final reduced-row check can remain the acceptance condition rather than a collection of sampled residue checks. 
Flint Library

3. Important fresh-versus-old split distinction

Do not replay the old finite-coefficient pole-subtraction operation unchanged on the fresh regular series.

The old interface subtracts the expansion of an exact pole part from a finite series representing the original whole coefficient, while restoring that pole part elsewhere. That behavior is explicit in SeparateMasterCoefficientPoles.

Your fresh representation already has

C=R
[≤U]
+E
exact
	​

+δR,

where the regular reconstruction excluded the exceptional source summands. Therefore split only

E
exact
	​

=
g
∑
	​

P
g
	​

+E
0
	​


and leave R
[≤U]
+δR unchanged. Subtracting the pole expansion from R
[≤U]
 again would be double subtraction.

Keep finite regular terms with their original master/source tail certificates, as proposed. An unknown tail must not participate implicitly in a claimed exact moving-pole cancellation after a singular basis transformation. Prefer a suitable frame or preserve the existing composite source-tail argument rather than demanding deeper reconstruction solely because an intermediate gauge gives pessimistic bounds.

4. Essential bindings and reuse checks

The reusable mathematical package should bind:

Definitions and ordered coordinates. Exact bare integral definitions, cuts/prescriptions, scale restoration, dimension/regulator convention, physical measure conversion, and ordered master lists. Distinguish bare masters from normalized gauge components.

The complete saved transformation. The common family’s closed DE, embedding, gauge and coordinate pullback must belong together. Where applicable, the exact compatibility identities are

dE+EA
F
	​

=A
source
	​

E,dT
F
	​

+T
F
	​

B
F
	​

=A
F
	​

T
F
	​

.

Reuse existing certificates for these identities; do not regenerate or repeatedly reprove unchanged systems.

The physical solution. Reuse the matched complete physical boundary data, primary-sector bounds and branch/domain data. Additional basis coordinates with zero physical coefficient do not have zero boundary amplitude by default.

What must be recomputed is the fresh weighted coefficient allocation, residues where used, complete q
F
	​

, residual divisor classification, and coefficient-dependent epsilon/normal-order requirements. The current scalar projection already binds its plan to the ordered original basis and gauge and requires sufficient coefficient tails; retain those checks.

Saved jets/solutions are reusable only through sufficient orders. A new coefficient row can require deeper jets or boundary orders without requiring a new DE reduction. Likewise, a sector absent for the old active support must be reconsidered for the new support; a complete physical absence certificate remains reusable.

5. Smallest general implementation

Add a planning adapter, not a second endpoint engine:

Index saved family bases once by bound integral identities. Generate candidate closures for each divisor support.

Select an admissible saved closure, favoring small dimension and inexpensive embeddings. “Smallest” is a cost heuristic; a slightly larger frame may avoid poles or excessive epsilon orders.

Generate exact group rows and unchanged certified finite-regular inputs, with explicit ownership of every source term/piece.

Run existing full-row cancellation, actual analytic-unit restoration, domain checks and order planning. Only accepted inputs reach the existing endpoint driver.

The design specifically warns that analytic units must be checked at their actual endpoint values; an opaque temporary symbol must not hide a vanishing factor such as s
ϵ
−1+z.

Coverage should count coefficient contributions, not occurrences of masters in auxiliary family bases. The same master may legitimately occur as a coordinate in several closures. Verify the pre-embedding reconstruction identity for each bound source term and require every removed exact piece to have exactly one matching addition.

The highest-value regressions are: an admissible gauge singular in determinant but a regular contracted row; a regular coefficient whose embedding introduces a moving pole; two shared-master pole groups with exact recombination; and the fresh exact-exceptional/finite-regular representation proving that no second pole subtraction occurs.

Bottom line: reuse the saved coefficient-independent mathematics, recompute the fresh scalar rows, and generalize only support selection and piece ownership. A failed first grouping should trigger a bounded alternative closure or coupled-group attempt—not a claim that the physical cancellation failed, and not new joint-moment machinery.