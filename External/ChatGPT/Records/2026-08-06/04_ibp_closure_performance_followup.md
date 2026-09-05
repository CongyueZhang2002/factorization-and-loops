# IBP Closure Performance Followup

## Question

Follow-up to your Kira 3.1 closure review. The small reproducer made the recursive selector look inexpensive, but the full history and production-scale run expose a severe cost. Please reassess the recommended architecture using all evidence below. The deliverable must remain exact analytic Kira rules for cut integrals; numerical reduction is not an alternative.

There were three separate changes, which must not be conflated.

1. Correcting malformed dimensional-shift output (earlier change)

- The old accepted NLO path produced only 2 GLIs for a representative pair, but their purported scalar coefficients still contained the loop momentum ke. They were not valid scalar coefficients of GLIs.
- The corrected dimensional-shift/decomposition path produces 8 valid GLIs with loop-independent coefficients for that pair and has fail-fast guards against any phase-space or loop momentum remaining in a coefficient.
- For the full NNLO double-real input, this correction left the number of representative topology families at 374 but increased exact amplitude targets from 9,291 to exactly 44,877.
- Therefore the old full Kira run (1,672.4 s with --parallel=8, 9,105 exported rules, 351 declared masters) is not a valid performance baseline for the corrected physics input. Its target set was incomplete/malformed.

2. Exact-target closure failure and supplemental repair (later change)

- The corrected package used select_mandatory_list on the exact 44,877 target files.
- The two-pair reproducer has 312 unique targets in four families. In one combined Kira project, exact-list selection finishes in about 26 s but transitive closure of exported rules terminates at 7 GLIs while masters.final declares only 5. Two cross-family RHS GLIs have neither an exported rule nor master status.
- Each family reduced alone closes. The failure appears only when families are combined and Kira uses cross-family/sector mappings.
- The first repair retained exact-list selection, discovered missing terminal GLIs after import, then launched a supplemental closure reduction (34 families, 272 missing targets, 814 seed entries in the recorded full-run repair). That closed the output but was a resume/patch workflow, which is not acceptable as the production design.

3. One-pass recursive selector (today's change)

- select_mandatory_list was replaced by select_mandatory_recursively using every per-family reduce record copied verbatim.
- The two-pair reproducer closes correctly in about 32 s: 309 nontrivial rules, exactly 5 terminal GLIs, exactly the 5 declared masters.
- The full job has 374 families, 44,877 original targets, 7,444 reduce records and another 7,444 recursive-selector records. Many records omit d because that is how FeynHelpers generated them.
- In the stopped full run, Kira entered back-substitution systems including 81,200 and 86,001 equations. After roughly 85 minutes only 11 topology blocks had been entered; Kira used about 9 GB RAM and several GB of database/workspace. A 12-30 h projection was plausible. The test was also run with --parallel=1, which worsened wall time, but the dominant change is the much larger mandatory region.
- NLO recursive benchmarks were only about one minute, so they did not reveal this full-scale combinatorial cost.

Questions requiring a precise answer

1. Is the combined-family exact-list closure failure an inherent limitation of select_mandatory_list, or could it be caused by our project construction/export pattern? In particular, should equivalent families be mapped/canonicalized before Kira differently, should target files use representative family names differently, or should relations be organized into connected components rather than putting all 374 families in one project?

2. Kira says zero unreduced requested integrals in the exact-list run. Is it valid for kira2math target rules to contain a cross-family RHS integral that was neither selected nor declared a master? If so, what documented selector/export arrangement is intended to obtain transitively closed target rules?

3. Can we obtain a closure-safe one-run result more selectively than recursively selecting the full generated r,s region? Please assess concrete options, not only state that the mathematical dependency closure is unknown in advance:
   - exact-list selection after canonicalizing all targets to certified representative families;
   - one clean Kira run per relation-connected component of topology families;
   - select_mandatory_list augmented with a statically computable closure under Kira's topology mappings/sector mappings before solving;
   - amplitude_translate or another Kira input-system feature;
   - explicit tight d bounds derived from the actual target indices;
   - a union of exact target lists and narrowly bounded recursive regions only where mappings require them;
   - exporting a broader target table without making the entire region recursively mandatory.

4. Does reducing each family alone lose legitimate master-identification relations, or can one first canonicalize equivalent families and then reduce each independent canonical family/component exactly? State what equivalence information must be preserved to avoid duplicate or inconsistent masters.

5. Is a two-stage dependency-discovery procedure fundamentally unavoidable for a minimal mandatory set? If yes, distinguish an unacceptable ad-hoc result patch from an acceptable deterministic Kira planning phase. Could Kira first generate mappings/dependencies, FACET compute the exact closed target set, and then perform one fresh final reduction whose output is the only retained artifact?

6. The old exact-list full run had 351 masters from malformed/incomplete targets. The corrected target set has previously been reported around 342 masters, but no closure-certified full run has completed. What comparisons can legitimately validate a faster design, and which old master counts must be discarded?

7. Recommend one production architecture that is both closure-certified and realistically close to the prior 0.5-3 h scale, rather than 12-30 h. Include the Kira YAML structure or project partitioning needed, and the exact post-import validation required.

Please challenge our assumptions where necessary. The central question is whether the broad recursive selector is merely sufficient but grossly overselecting, and how to replace it without returning to silently incomplete rules.

## Pro response

Reassessment

The global select_mandatory_recursively change should not be the production default. It is a sufficient closure mechanism, but on the full FACET problem it is grossly overselecting the mandatory integral set. Copying all 7,444 seed-envelope records into the recursive selector explains the observed 80,000-equation back-substitution blocks and the projected 12–30 hour runtime.

The corrected dimensional-shift path and its 44,877 targets are the only valid physics baseline. The older 9,291-target run and its 351 masters must not be used for either performance or master-count validation.

The preferred architecture is:

deterministic mapping plan⟶canonical exact target lists⟶one fresh exact-list reduction per relation component
	​


with narrowly bounded recursive selection only as a component-local fallback.

1. The exact-list failure is not an inherent limitation of select_mandatory_list

Kira’s own recommendation for amplitude reductions is to provide the exact required integrals through select_mandatory_list; recursive selection is intended when one deliberately wants a whole region, for example for a later basis transformation. 
GitLab
+1

More importantly, Kira 3’s equation-selection algorithm is described as follows:

select equations after forward elimination;

solve the selected system once over a finite field;

identify any requested integrals that are still unreduced;

add them and repeat until all requested integrals reduce to the minimal basis. 
arXiv
+1

Therefore, the result

Kira reports zero unreduced requested integrals,

but the exported target rules terminate at undeclared nonmasters,

is not the expected mathematical meaning of exact-list selection.

It points to one of these narrower problems:

a cross-family symmetry or sector mapping is used internally but is not present in the restricted kira2math output;

FACET imports the IBP rows but not the applicable Kira sector/topology mapping;

target files use noncanonical family aliases, while the solved database uses another family as the representative;

the combined project exposes a Kira 3.1 export defect for mapped cross-topology targets;

less likely, the generated combined project contains an inconsistent family relation that does not occur when the families are run independently.

Historically, Kira has had cases where a selected integral was symmetry-equivalent to another-family master but the expected symmetry was not represented in the exported table. That older issue is not proof of a Kira 3.1 bug, but the symptom is close enough that mapping/export behavior should be tested before changing the selector globally. 
GitLab

Immediate diagnostic on the four-family reproducer

For each of the two bad terminal GLIs, perform these checks against the completed exact-list project:

Search Kira’s generated sector/topology mappings for an image of the integral.

Ask kira2math to export that terminal from the already solved database, without running another reduction.

Canonicalize the 312 original targets through the discovered Kira mappings, then rerun the four-family project with select_mandatory_list only.

The outcomes distinguish the cause:

Result	Interpretation
A sector mapping sends the terminal to a declared master	FACET is missing a mapping relation during import
Export-only query produces a rule to masters	The solved database is closed; the original export target set was too narrow
Canonicalized exact-list run closes	Noncanonical family names caused the issue
No mapping and no exportable rule despite “zero unreduced”	Kira 3.1 selector/export inconsistency; submit the reproducer upstream
Only recursive selection creates the rule	The terminal truly was not mandatory in the exact-list solved subsystem

This experiment is much more informative than extrapolating from the recursive run.

2. Is a nonmaster cross-family RHS valid?

There are two distinct notions of closure.

Kira-internal closure

A RHS integral may be an alias that Kira knows how to map through a sector or topology symmetry. In that case, Kira can legitimately regard the selected target as reduced even if a narrowly exported table does not include the separate mapping row.

Standalone FACET-rule closure

For FACET, a persisted exact reduction table is acceptable only if every original target reduces transitively to declared masters using the information stored in the artifact.

Therefore:

A nonselected, nonmaster RHS is acceptable only if its exact mapping relation is also imported or composed before persistence.
	​


If no such mapping relation exists in the Kira project, then the exported reduction is incomplete.

Kira’s documentation establishes that the requested integrals should reduce internally to a minimal basis; I did not find a documented guarantee that a kira2math export restricted to the original target files is necessarily a self-contained transitive rule set across all topology aliases. 
arXiv
+1

So FACET should not interpret “zero unreduced requested integrals” as sufficient artifact validation. Your explicit post-import closure test remains necessary.

3. Assessment of the selective alternatives
A. Canonicalize exact targets before Kira

Recommended as the first production change.

FACET already canonicalizes complete physical topology families. Extend this to the sector-level mappings that Kira will actually use:

GLI[T,a]⟼GLI[T
can
	​

,π(a)].

Then:

put only canonical GLIs into select_mandatory_list;

export only canonical GLIs;

retain the exact original-to-canonical map in the FACET artifact;

reconstruct original targets by composition outside Kira.

This removes the need for Kira to export rules for source-family aliases.

The qualification is important: Kira can find symmetries between sectors, including sectors of different integral families. 
arXiv
 Complete-family equivalence alone is therefore not enough. The canonicalization plan must include relevant sector/subtopology mappings.

Every mapping must pass FACET’s physical checks before use:

cut slots and positive cut powers;

propagator permutation;

allowed auxiliary indices;

exact loop transformation;

declared physical topology identity.

An algebraic Kira mapping that violates FACET’s cut-aware contract must not connect two final projects.

B. Reduce relation-connected components independently

Recommended.

Construct a graph whose nodes are canonical family-sector classes. Add an edge for every accepted:

Kira sector symmetry;

cross-topology mapping;

FACET-certified topology map;

explicit extra relation.

Reduce each connected component in its own fresh Kira project.

This has three benefits:

it prevents unrelated families from enlarging one global mandatory and back-substitution system;

it preserves every legitimate cross-family master relation inside a component;

it makes the largest relation component—not all 374 families—the controlling complexity.

The component graph should be sector-level rather than family-level. Two top-level families may be inequivalent while some lower sectors are mapped.

A Kira symmetry-only planning job is a reasonable way to obtain these mappings. Kira’s maintainers describe an example job that stops after symmetries and trivial sectors are identified, specifically so the mappings can be inspected or modified before the reduction. 
GitLab

C. Statically close the target list under Kira mappings

Recommended together with A and B.

Once the mapping graph is known, compute the finite orbit of each requested GLI under the accepted topology and sector mappings.

Usually the best choice is not to select the entire orbit, but to select only its canonical representative and retain the inverse alias externally. If Kira’s export still refers to a noncanonical orbit member, include that finite mapped set in the exact target/export files.

This is very different from recursive r,s,d-region selection:

mapping orbit closure is finite and structural;
recursive seed-region closure is combinatorial.

Kira’s own improved selector should handle the IBP-equation dependency closure once the exact requested integral identities are canonical.

D. amplitude_translate

Not appropriate for the current artifact contract.

amplitude_translate turns an entire linear combination into the RHS of a synthetic high-weight equation for use in a generated user-defined system. It can be useful if the only desired output is the reduction of one amplitude-level combination, but it does not naturally provide a reusable exact reduction rule for each of FACET’s 44,877 target GLIs. 
GitLab

It is a possible future “hard-function-only” backend, not the replacement for the present Kira-rule artifact.

E. Explicit tight d bounds

Necessary for any recursive fallback and useful for seed generation generally.

Kira 3 explicitly encourages setting d
max
	​

. When only r
max
	​

 is inherited into lower sectors, the allowed dot count can grow substantially; keeping s
max
	​

 constant in lower sectors is even more combinatorial. 
arXiv
+1

Your 7,444 recursive records include many omitted d values. Copying those records verbatim into a mandatory recursive selector can select a far larger region than the amplitude requires.

Do not define a production bound merely as

d
max
	​

=
target
max
	​

d;

IBP equations generally need some headroom beyond the targets. Instead:

derive initial r,s,d from the corrected target set sector by sector;

add a small explicit margin;

inspect masters at the seed edge;

enlarge only the affected sectors;

certify stability under one further enlargement.

Kira 3 provides check_masters specifically to abort if the generated system requires masters beyond a supplied certified basis. 
arXiv

F. Exact list plus narrow recursive regions

Good fallback, not the default.

Kira permits mandatory-list and recursive selection mechanisms as complementary selection modes. 
GitLab

Use recursive selection only for:

a particular relation component;

a particular mapped sector orbit;

explicit small r,s,d bounds;

sectors demonstrated by the reproducer to require it.

Do not pair that component with truncate_sp: Kira 3 explicitly warns that select_mandatory_recursively uses a constant s
max
	​

 over the selected region, while truncate_sp removes required lower-sector seeds, leading to unreduced integrals. 
arXiv

G. Broader export without broader mandatory selection

Test this before any new reduction strategy.

kira2math cannot invent reductions absent from the solved database, but it may be able to export rows that were solved internally even though they were not in the original export files.

On the small reproducer:

retain exact-list selection;

add the two bad terminals only to the kira2math target query;

do not rerun triangular reduction or back substitution.

If the resulting rows close to the five masters, then the full fix is:

canonical/export closure,

not recursive mandatory selection.

If the export query returns no rule or an unreduced rule, the integrals must be included in the selected set—or mapped away before Kira.

4. Can canonical families be reduced independently?

Reducing every raw family independently is exact but can lose legitimate master identifications:

equivalent sectors in different families can yield duplicate masters;

the two runs may choose different representatives of the same master class;

cross-family extra relations will not be used.

This does not necessarily make the resulting hard function wrong, but it produces a nonminimal and potentially inconsistent global master labeling.

The safe statement is:

Canonicalize all accepted equivalences first, then reduce each relation-connected component independently.
	​


The component artifact must retain:

original target → canonical target maps;

propagator-index permutations;

family and sector mappings;

cut-slot mappings;

common kinematic and dimension conventions;

any preferred-master map;

component identifiers.

After the component reductions, canonicalize the component masters again. If two components turn out to contain equivalent masters, the planning graph was incomplete and the final run should fail rather than silently merge them afterward.

5. Is a two-stage planning process unavoidable?

For the minimal mandatory target set, some form of dependency discovery is practically unavoidable when cross-family mappings are involved.

Kira itself already performs an internal iterative selection: it identifies unreduced requested integrals over a finite field, adds them, and repeats. It also states that the resulting equation set is not guaranteed to be globally minimal because additional “stealthy zeros” may remain. 
arXiv
+1

A deterministic FACET planning phase is acceptable and materially different from the rejected supplemental repair.

Acceptable deterministic planning

Start from clean configuration files.

Run only Kira’s symmetry/trivial-sector discovery, or another explicitly defined planning mode.

Extract the mapping graph.

FACET certifies mappings and forms components.

Compute canonical exact target files and bounded seed profiles.

Fingerprint the complete plan.

Delete all planning databases and reduction tables.

Run each final component from a clean directory.

Retain only final component reductions.

The planner determines what the final problem is. It does not patch final coefficients.

Unacceptable patch workflow

run an incomplete reduction;

discover missing RHS integrals;

resume or modify that same solved database;

append supplemental tables generated with a different target/seed specification;

persist the union as though it came from one certified system.

A more expensive but still principled fallback is an exact-list planning reduction whose outputs are discarded, followed by one fresh final reduction on its deterministically computed closed target set. That may not be necessary if the symmetry files already provide the relevant closure.

6. Which master counts remain meaningful?

The following count must be discarded:

351from the malformed 9,291-target system.

That reduction did not correspond to the corrected scalar GLI decomposition.

The reported count near 342 is provisional until a full corrected reduction satisfies:

all 44,877 targets are represented or canonically mapped;

target rules are transitively closed;

every terminal is a declared master;

cuts and auxiliary-index constraints pass;

the master set is stable under seed enlargement;

all relation components have been included.

Raw master count alone is not a sufficient comparison because different projects may choose different bases.

A faster design should be validated by:

exact equality of the corrected original target set;

exact original-to-canonical target mapping;

exact closure of every target rule;

exact cut validation;

exact mapping between competing master bases, when the bases differ;

equality of the final hard function after translating to a common master basis;

stability under a controlled enlargement of r,s,d;

preferred_masters plus check_masters: true once a basis is certified.

Numerical finite-field or AMFlow comparisons can remain independent checks, but they do not establish closure.

7. Recommended production architecture
Phase A: mapping planner

Use one lightweight project containing the relevant algebraic families, but stop after Kira has generated trivial sectors and symmetry/topology mappings.

FACET then:

imports all Kira mapping relations;

rejects any mapping that violates cuts or physical topology identity;

builds the family-sector relation graph;

computes its connected components;

maps all 44,877 targets to canonical representatives;

computes finite mapping-orbit closure where necessary;

derives explicit per-sector seed bounds, including d;

stores a fingerprinted plan.

Phase B: one clean final project per component

For an ordinary component, use exact-list selection:

YAML
jobs:
  - reduce_sectors:
      reduce:
        - {topologies: [T1], sectors: [S1], r: R1, s: S1max, d: D1}
        - {topologies: [T2], sectors: [S2], r: R2, s: S2max, d: D2}

      # Optional only after sector-by-sector tuning:
      truncate_sp:
        - {topologies: [T1, T2], l: L}

      select_integrals:
        select_mandatory_list:
          - [canonical_targets_component]

      integral_ordering: 2

      # Once a basis is certified:
      preferred_masters: preferred_masters_component
      check_masters: true

      run_symmetries: true
      run_initiate: true
      run_triangular: true
      run_back_substitution: true

  - kira2math:
      target:
        - [T1, canonical_targets_T1]
        - [T2, canonical_targets_T2]

The exact placement of preferred_masters and check_masters should follow the Kira 3.1 schema used by your installed executable; their semantics are to compare the generated master set to the supplied basis and abort on additional masters. 
arXiv

For a component that demonstrably still requires recursive selection:

YAML
      select_integrals:
        select_mandatory_list:
          - [canonical_targets_component]

        select_mandatory_recursively:
          - {topologies: [Tbad],
             sectors: [Sbad],
             r: Rbad,
             s: Sbad,
             d: Dbad}

That recursive region must be:

component-local;

sector-local;

explicitly bounded in r,s,d;

justified by the mapping/closure reproducer.

Disable truncate_sp for such a component unless an independent test demonstrates compatibility.

Phase C: exact post-import certification

For each component and then for the global union:

validate all imported objects are exact rules;

reject conflicting duplicate LHSs;

compose original-target → canonical-target mappings;

require every original target to be a rule LHS or declared master;

close all target rules transitively;

detect cycles;

require every terminal to occur in that component’s masters.final;

require every RHS family-sector to belong to the same planned component;

require every cut index to remain strictly positive;

require every mixed auxiliary index to remain nonpositive;

verify GLI arities and topology names;

audit masters at r,s,d seed boundaries;

fingerprint the rules, master files, mapping plan, target files, YAML and Kira binary.

If a rule contains an integral from another component, the component graph was incomplete; discard the final run and regenerate the plan.

Performance expectation

The recursive full job is dominated by the enormous mandatory region, not merely by the 44,877 original targets. Kira’s own paper warns that seed combinatorics become unmanageable at high r,s,d, encourages explicit d bounds, and recommends exact target lists for amplitudes. 
arXiv
+1

Canonical exact-list components should be much closer to the previous exact-list scale than to the observed recursive scale. The actual runtime will be governed by the largest relation component and its seed profile. A 0.5–3 hour target is plausible if:

most of the 374 families split into moderate components;

targets are canonicalized before Kira;

omitted d bounds are eliminated;

final runs use the intended eight-way parallelism;

recursive selection is confined to exceptional components.

It cannot be guaranteed before measuring the component-size distribution, but it is the only proposed architecture that simultaneously preserves exact closure and avoids selecting all 7,444 seed envelopes as mandatory.

Bottom line
Global recursive selection is a diagnostic proof of sufficiency, not the right production selector.
	​


The next experiment should be the four-family exact-list run with:

Kira mapping relations imported or targets canonicalized;

export-only queries for the two bad terminal GLIs;

no recursive selector.

If that closes, the full production solution is canonical exact-list component reduction. If it does not, use a deterministic mapping planner and narrowly recursive exceptional components—not one global recursive envelope.
