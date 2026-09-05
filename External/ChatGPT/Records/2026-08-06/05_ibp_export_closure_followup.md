# IBP Export Closure Followup

## Question

_The question was not preserved in the local bridge record._

## Pro response

Verdict

Yes. The fixed-point export closure is a principled production architecture. It is materially different from the rejected supplemental-reduction patch:

there is one equation-generation and solve phase;

the mandatory target set, seed envelopes, triangular system, back substitution, and master basis never change afterward;

subsequent jobs invoke only kira2math to materialize rows already present in the solved database;

the final FACET artifact is an exact transitive projection of that single solved system.

Your diagnostic shows that select_mandatory_list selected a sufficient equation system. The missing information was only outside the initially requested export surface. Kira 3 describes its selection procedure as trimming the generated system so that the requested integrals reduce to master integrals, while select_mandatory_list is the documented exact-integral selector. 
arXiv
+1
 Kira’s maintainers also explicitly state that kira2math may be invoked later against the existing database and that reductions of vanishing integrals are stored there for later export. 
GitLab

A useful name is:

one-solve, demand-driven export closure
	​


rather than “closure reduction.”

Recommended fixed-point algorithm

After the clean exact-list solve:

Export the original amplitude target files.

Import the union of all exported rules and masters.final.

Close every original target transitively under the current rule union.

Form the unresolved frontier

F
k
	​

={RHS GLIs}∖({known rule LHSs}∪{declared masters}).

Canonicalize and deduplicate F
k
	​

, group it by family, and query the whole frontier in one export-only kira2math job.

Import those rows, validate them, add them to the rule union, and repeat.

Stop only when the frontier is empty.

Compose the original target rules fully to declared masters and persist that self-contained map.

Conceptually, each closure iteration uses a job containing only:

YAML
jobs:
  - kira2math:
      target:
        - [Topology1, "closure_frontier_001_Topology1"]
        - [Topology2, "closure_frontier_001_Topology2"]
        # ...

It must not contain:

YAML
reduce_sectors:
run_initiate:
run_triangular:
run_back_substitution:

Query each frontier in batches, not one GLI at a time. The iteration depth and frontier sizes should be recorded as diagnostics.

Exactness conditions

The architecture is production-safe provided all of the following are enforced.

Immutable solved system

All export iterations must use exactly the same:

Kira database;

integral-family and kinematics configuration;

cut declarations;

integral ordering;

seed specification;

master basis;

Kira executable.

Take an immutable snapshot of the completed solved project before the first closure query. Either run exports from copies of that snapshot or verify that all database-state hashes are unchanged before and after every export-only invocation.

The initial solve configuration, target files, masters.final, Kira database snapshot, executable, and relevant configuration files should all be fingerprinted.

Query coverage

For each queried frontier GLI G, exactly one of the following must hold after the export:

a rule with LHS G was obtained;

G is in masters.final;

G is explicitly exported as zero.

Kira 3.1 can export zero relations stored in its database. 
GitLab

Fail if Kira reports zero unreduced integrals but:

no rule is returned;

the GLI is not a declared master;

no explicit zero relation is present.

That would indicate another export inconsistency.

Rule integrity

For every newly imported row:

the LHS must be the requested canonical GLI;

coefficients must be exact;

no machine or arbitrary-precision numbers may appear;

all families must be known;

index-vector arity must match the family;

duplicate LHSs must have exactly equivalent sparse RHSs;

the dimension convention must match the solved system.

For duplicate rules, compare sparse GLI coefficients algebraically rather than requiring only syntactic SameQ, since term ordering may differ.

Global closure

After every iteration:

apply the global union of rules, not family-local subsets;

detect nontrivial dependency cycles;

fail on a cycle rather than choosing an arbitrary representative;

require strict progress:

new rule LHS count>0

whenever the frontier is nonempty;

require the final terminal set to be a subset of masters.final.

The terminal set need not equal the entire declared master list; some declared masters may not be reached by the FACET targets.

Physical constraints

Validate cuts and FACET sector restrictions on:

every queried GLI;

every new rule LHS;

every GLI on every RHS;

all composed target images;

all terminal masters.

In particular:

every required cut index remains a positive integer;

mixed auxiliary/ISP indices remain in the permitted nonpositive region;

topology identity and propagator ordering remain valid;

no unknown family or malformed GLI enters through a cross-family row.

Durable artifact

Persisting only the fully composed original-target rules and the declared master list is sound. The final artifact should distinguish:

nontrivial original target -> master rules
original targets that are themselves masters
declared master list

For auditability, also retain a compact closure manifest:

Wolfram Language
<|
  "OriginalTargetFingerprint" -> ...,
  "SolvedProjectFingerprint" -> ...,
  "KiraVersion" -> ...,
  "MastersFinalFingerprint" -> ...,
  "InitialExportFingerprint" -> ...,
  "ClosureIterations" -> {
    <|
      "Iteration" -> 1,
      "QueryFingerprint" -> ...,
      "QueryCount" -> ...,
      "ExportFingerprint" -> ...,
      "NewRuleCount" -> ...,
      "KiraReportedUnreduced" -> 0
    |>,
    ...
  },
  "FinalComposedRulesFingerprint" -> ...,
  "TerminalMasterFingerprint" -> ...
|>

Raw intermediate export rows need not remain in the main analytic artifact, but their hashes and query manifests should remain reproducible.

Does this remove the immediate need for planning and component splitting?

Yes, for correctness and closure.

The experiment establishes that:

exact-list equation selection was sufficient;

cross-family dependencies were already solved;

the initial kira2math target restriction alone caused the non-self-contained table;

recursive mandatory selection was unnecessary for this reproducer.

Therefore a symmetry-planning/canonical-component phase is no longer required to repair closure. It may still be valuable later as a performance optimization if:

the initial exact-list solve is expensive;

the export frontier is very large;

the same cross-family aliases repeatedly inflate the persisted map;

independent components can be rigorously identified.

Such an optimization must be benchmarked separately. It should not be introduced as a prerequisite to obtaining a mathematically complete artifact.

FACET’s existing cut-aware topology canonicalization should remain. The new result only removes the need to add a new Kira symmetry-planning stage for closure.

One remaining recommendation

Submit the four-family reproducer upstream to Kira. The behavior may be intentional—kira2math exporting only the requested rows rather than their transitive dependencies—or it may merit an option such as “export recursively closed target rules.” Either way, FACET should retain its own post-import closure validation because the final requirement is stronger than “Kira internally reduced every requested integral.”

The final production structure should therefore be:

clean exact-list Kira solve
→initial target export
→batched export-only fixed point
→exact global closure validation
→compose original targets to masters
→persist one self-contained analytic artifact.
	​

	​


This retains the performance of exact-list selection while obtaining the same mathematical closure that the broad recursive selector provided.
