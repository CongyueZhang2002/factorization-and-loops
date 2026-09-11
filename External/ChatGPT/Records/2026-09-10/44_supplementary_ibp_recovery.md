# Supplementary IBP recovery

Model: verified GPT-6 Pro.
Request: b364089d-f292-457d-9efd-03989b6406ea.
Conversation: 6aa2eb2d-5588-83e8-bf9d-d35cd8d66f3b.

## Question

The ppHX double-real rerun exposed an IBP seed gap. Review the recovery design for mathematical correctness and practical Kira behavior; reply concisely, focusing on the least invasive general fix.

374 families/55277 requested targets reduced and exported with zero unreduced targets. Closing cross-family RHS references finds 315 additional GLIs. Original kira2math exports 313, but two CF17 targets remain unreduced:
CF17[1,1,1,-1,0,1,1,2,-2] and CF17[1,1,1,-1,0,1,2,1,-2].
Their r=7,s=3,sector231. This destination sector was seeded only r=6,s=2. Cuts are indices1,2; all exact cut prescriptions/kinematics already certified. Both referred RHS GLIs appear as not-selected in earlier Kira logs.

Current closure insists original Kira DB/jobs/config/masters remain unchanged, and eventual terminal GLIs lie in the original declared master set. We should preserve that, not declare these two new masters.

Proposed general fix: when export reports explicitly unreduced GLIs, generate a separate supplementary Kira workspace for only those affected families, from exact original Kira topology/kinematic/cut records. Request missing GLIs with targeted r/s seed envelopes, using existing Kira project constructor. Import exact supplemental rules, insist source GLIs reduce nontrivially and RHS cuts/arity/exactness pass, then compose through the ordinary original-workspace closure. Any new supplemental terminal GLIs are queried/reduced rather than silently accepted as masters. Keep original DB unchanged, retain supplementary provenance. No process-specific formulas or original-family rename assumptions. Fail boundedly if no progress; can increase r/s padding locally if necessary. Typed/user-equation Kira jobs should fail explicitly unless supplied extra equations, since this recovery only has geometric IBPs.

Questions: (1) Can supplementary family-only Kira basis differences cause an invalid identity or merely unresolved RHS? (2) Best way to ensure supplemental rules reach original master basis without redoing374 families? Include known original masters for that family as preferred masters / extra targets? (3) Is a less invasive in-workspace targeted selection possible safely, and is it preferable? (4) pitfalls with original top_level_sectors versus supplementary requested sector, and common validation that must be retained?
Git baseline8bfd19c584a5f79a2090def3043bc1f55a03ca5d; current code uncommitted. No numerical substitution or fitted formula proposed.

## Pro response

The recovery design is sound and is the least invasive fix under your immutable-original-workspace requirement. The two targets have r=7, s=3, six positive indices and one dot; increasing export selection alone does not enlarge the generated IBP system. Do not promote them to masters merely because the original seed envelope failed to reduce them.

1. A different supplementary basis does not invalidate an identity

A valid supplementary reduction

X=RB

remains an exact identity even when its terminal integrals B differ from the original masters M. The problem is unfinished basis conversion, not invalid mathematics.

A family-only workspace can lose cross-family symmetry mappings available in the original project. Kira’s topology initialization and mapping depend on the configured families and their order. Decode each export through its own explicit family manifest; never reuse original internal family numbers for the supplementary workspace. 
arXiv

2. Target the missing sector, and prefer—but do not assume—the old basis

For each affected family, batch the missing GLIs into an explicit select_mandatory_list and export that list. Start with a sector-specific seed envelope covering r
max
	​

=7,s
max
	​

=3; any dot cap must allow at least one dot. This is a starting envelope, not a completeness guarantee. Preserve necessary subsector coverage and increase bounds locally on failure. With Kira 3, check truncate_sp and inherited dot limits: a nominally adequate parent envelope need not provide adequate subsector seeds. 
arXiv

Include relevant original masters—or exactly identified local representatives—as preferred_masters before reduction. Also request their reductions as extra targets when a basis-conversion bridge may be needed. Ensure their sectors and powers are covered; preference is not a substitute for seeding. 
arXiv

Preferences do not enforce closure: Kira can supplement the preferred basis with additional masters. Kira 3’s check_masters: true can enforce a complete specified local basis, but should not be enabled blindly when you intentionally permit intermediate local representatives that will close through original cross-family rules. 
arXiv

Query supplementary terminals through the existing original closure first. If this creates a cycle, use the bridge equations rather than increasing seeds indefinitely. For example, if

M=PB,X=RB,

solve AP=R exactly for the needed rows; then X=AM. No full inverse or proof that either spanning set is minimal is required.

3. In-place recovery is not preferable under your constraints

The smaller non-reduction operation—another targeted kira2math export—has already been tried.

Generating/selecting additional equations and completing their reduction is a new reduction run, not merely an export. Doing that in the original directory conflicts with preserving its DB and generated state. Kira documents cleanup requirements for new reductions and stronger cleanup when topology definitions change; existing checkpoints must not be assumed compatible with modified seeds or configuration. 
arXiv

Use a clean supplementary workspace. A private copy is possible, but reusing old checkpoints adds complexity without addressing this small seed gap. Import rules into your closure layer; do not merge the supplementary DB into the original.

4. Preserve sector and definition semantics

Check sector containment by the bitmask condition

BitAnd(231,T)=231,

not by comparing sector numbers.

Keep the original top_level_sectors where possible. If the missing or required preferred sector is not covered, add coverage only in the supplementary configuration. Do not replace all original tops with [231]: that can remove useful symmetry/mapping coverage or sectors needed to recover the old basis. Conversely, an uncovered sector is not a zero sector. Kira uses top-level sectors to constrain symmetry/mapping coverage as well as default seed selection. 
arXiv

If family-only closure stalls specifically on cross-family mappings, include the relevant mapping families in their original order. Keeping the original ordered configuration while selecting only affected families for reduction is another option; it does not require reducing all 374 families again.

Retain these acceptance conditions: exact definition/propagator-order/parameter-normalization binding; the existing certified cut and symmetry restrictions; homogeneous rational rules with valid GLI arity and cut powers; complete requested-target accounting; and final terminal membership in the unchanged original master set. cut_propagators specifies vanishing when cut powers become nonpositive—it is not the entirety of your directed-cut/prescription metadata. 
arXiv

Finally, “nontrivial RHS” is not sufficient progress: X→Y, Y→X must be detected. Bound attempts, seed growth and unresolved dependency cycles. Fail explicitly for user-equation jobs without supplied additional equations; geometric reseeding must not silently replace their equation semantics.
## Implementation status

The first implementation preserves the original database, computes supplementary geometric IBPs in separate project-owned workspaces, includes original family masters as additional targets, and retains the original top-level sector coverage. Supplementary identities are not promoted to new masters; the existing closure still requires the original declared master set. Typed equation jobs fail explicitly. Nine focused regressions pass. The actual two-integral test passed: 12.050708 seconds inside the kernel produced two exact rules with eight RHS integrals. Two representatives outside the original declared list were then exported and reduced onto that list in 1.303733 seconds. Both steps verified the original workspace was unchanged. Complete campaign import/reconstruction/assembly remains pending.

Correction to the prompt: the actual CF17 configuration has cut indices **1, 2, and 8**, not just 1 and 2. The implementation reads the complete cut list from the original definition; both missing targets have positive powers at all three cuts.

The full closure subsequently succeeded: 345 terminal masters, 55,277 original targets and 55,706 resolved integrals. Supplementary timing metadata now uses exact integer milliseconds so the exact-artifact validator accepts it. The original rule and reduced-family file fingerprints were verified unchanged when correcting the staged timing metadata. Coefficient reconstruction and downstream assembly are still pending.
