# GPT-6 Pro: automatic reconstruction planning

Model: gpt-6-pro. Conversation: 6aa43002-7ab8-83e8-a5b9-98673bb33f6f.
Request: 9d4e0fd9-0c85-4048-90ae-8e2183422056.

## Question

This is a NEW question: review automatic PRE-INTERPOLATION partition and order discovery. The previous leading-zero/final-acceptance review is complete. Please answer the new planning question below and inspect the attached current source.

Review the next general-workflow integration for ppHX NNLO, resumed by the user. Baseline accepted bare two-gluon result is unchanged; https://github.com/CongyueZhang2002/factorization-and-loops (working changes unpushed).

We now automate the remaining pre-interpolation order/partition plan. Contribution cards should provide only endpoint catalog/physical-normalization dependencies, the endpoint coordinate map/domain and desired epsilon range, never selected coefficient columns or guessed orders. Candidate expensive columns are selected by expression size. All other columns remain exactly rational.

For candidates, match the source powered-integral definitions from Kira metadata to the accepted cut catalog, choose a covering accepted endpoint frame, derive the source physical momentum-space normalization using the same ConstructMasterIntegralDefinitions and ConstructPhysicalMasterCoefficientDensity as final assembly (using unit placeholder coefficients, not reading old reconstructed values), and multiply its complete analytic signature and global prefactor. A shared divisor analysis classifies source denominator factors as fixed epsilon/normal powers times a proved joint analytic unit. Literal summands involving any rejected divisor stay exact; only the remaining literal regular sum gets a finite order from existing uniform complete-physical-sector bounds, including Jordan/log moment pole losses. If a bound, normalization, map or regular partition is unsupported, preserve the full source column as exact and record the reason; do not silently truncate. Invalid/missing declared input artifacts fail rather than pretending to be valid.

Requirements: affine polynomial coordinate substitutions (reject numerator substitutions introducing new poles); physical prefactor independent of normal coordinate for this first supported optimization; exact source/partition identity; exact endpoint, normalization, source-definition and trace-column binding. The planner will be invoked automatically by CoefficientSimplification when its contribution card declares endpoint inputs, otherwise full rational reconstruction remains sound. A standalone general CLI exposes preparation for testing/reuse. Validate automatically selected columns and finite orders against the actual accepted NNLO source partitions without redoing hours of reconstruction unnecessarily. Do not introduce family-name or output-index cases.

Any concrete mathematical gap? Especially source-to-frame normalization, where affine equivalent integrals have factor 1; nonconstant matching factors can simply remain full rational. This is a planning aid prior to the already-reviewed exact moving-pole common-frame cancellation, not a replacement for that endpoint engine.


Actual first replay now selects outputs 20 and 22 by size, derives epsilon^1 for both, and reproduces regular/exact partitions byte-for-byte. Preparation driver 109 seconds. The project card integration is being completed. Check API scoping, keys, source-to-frame normalization, numerator coordinate maps, unsupported fallbacks and stale input handling. Do not answer the old leading-zero question again.


## Pro response

Your pre-interpolation strategy is mathematically sound, but the attached implementation still has integration gaps. The most important are the incomplete validation of the effective coordinate map, the missing explicit source-physical-master-to-endpoint-row binding, and saved-plan reuse without checking the current mathematical inputs.

I reviewed the four attached source files. The card dispatcher, standalone CLI, partition backend, and accepted NNLO replay artifacts are not included, so I have not independently reproduced the reported selection of outputs 20 and 22, their orders, or the byte-for-byte partition comparison.

1. The effective coordinate map can bypass the numerator/divisor safeguards

This is a concrete mathematical gap in the shown integration.

The planner applies PhysicalNormalization["KinematicRules"] to the analytic signature and obtains physical multipliers from a table whose coefficient is identically one. It then analyzes the rational source using only the separate planning KinematicRules. In contrast, ConstructPhysicalMasterCoefficientDensity applies its own rules to the actual rational coefficient during final conversion. Thus, a transformation affecting the rational numerator or denominator can enter final assembly without entering the planner’s divisor proof. 

automatic_reconstruction +1

An exact counterexample is

C(ϵ,x)=
1+ϵx
x
	​

,physical-normalization rule: x↦
z
1
	​

,planning rules: {}.

The planner sees the mixed denominator 1+ϵx, whose value at ϵ=z=0 is 1, so its divisor analysis can certify a joint analytic unit. The actual physical coefficient is instead

C
phys
	​

(ϵ,z)=
z+ϵ
1
	​

.

Truncating the source through ϵ
1
 gives

C
phys
	​

−(
z
1
	​

−
z
2
ϵ
	​

)=
z
2
(z+ϵ)
ϵ
2
	​

,

which is not the certified fixed-normal-pole analytic remainder. The physical-density routine permits general exact, regulator-independent kinematic rules; it does not impose the planner’s polynomial restriction. 

automatic_reconstruction +1

The fix is to validate the complete effective substitution acting on the source coefficient, including alias decoding and every subsequent coordinate substitution actually used by assembly. Use that same substitution for the divisor proof, prefactor construction, and endpoint-coordinate binding. It must cover variables occurring only in numerators; unit placeholder coefficients deliberately cannot expose such transformations.

There is also a narrower scope issue: the current predicates check polynomiality, not affinity. They accept nonlinear polynomial substitutions, do not reject duplicate left-hand sides, and do not prohibit rewriting the regulator. PolynomialQ alone is not an affine-map test. 

automatic_reconstruction +1

 
Wolfram Documentation Center

For this first supported optimization, require a regulator-preserving map with unique source-coordinate keys and total degree at most one in the declared coordinate variables. A valid but unsupported effective map should leave the affected source column exact.

2. The unit-coefficient normalization construction is appropriate, but its bridge to the endpoint row is not established here

I agree with your factor-one policy. There is no reason to invent an additional affine matching factor after an accepted equivalence has already established equality in the relevant integral convention. Requiring mapping["Factor"] === 1 and leaving other mappings exact is conservative.

The source multiplier construction is also the right approach: construct the source definitions from metadata, pass unit coefficients through the production physical-density conversion, and combine the resulting multiplier with the global factor and complete analytic signature. The shown extraction uses the converted term’s PreFactor, so it includes the explicitly supplied density factors applied there—not merely the scale-conversion factor recorded separately. 

automatic_reconstruction +2

The missing obligation is the identity

J
source
physical
	​

(φ(endpoint coordinates))=J
selected frame row
physical
	​

,

with the same reference scale, measure, cut conventions, and powered-integral definition.

In the attached caller, these arrive along separate paths:

Catalog matching receives the caller-supplied SourceNormalization.

Physical normalization is reconstructed independently from the source metadata.

The endpoint row is selected through IntegralClasses and RowsByIntegralClass.

The caller checks the source-to-representative factor but does not visibly compare the derived physical convention with the catalog normalization or the selected row’s convention. It also does not inspect a representative-to-row factor when choosing another covering frame. 

automatic_reconstruction

This is a missing binding check, not evidence that your actual ppHX normalization is numerically wrong. If the catalog/frame helpers already guarantee that the classes contain only identical physical integrals with unit transition factors and compatible coordinate/domain bindings, that contract closes the gap. Their implementations are not supplied here.

Otherwise, derive or validate the catalog normalization against the constructed physical definitions, and certify the complete source-to-selected-row identity before using that row’s bounds. Reuse the existing equivalence machinery; no second normalization scheme or general nonconstant-factor implementation is needed.

3. Saved plans retain mathematical inputs but do not validate them against the current request

The execution checks are strong on source identity: trace-manifest hash, regular-expression hash, source master, trace-column metadata, analytic signatures, and source definitions are compared. 

automatic_reconstruction

But the order record also stores PhysicalNormalizationRequest, PhysicalNormalizationConstruction, AcceptedEndpointBinding, coordinate rules, assumptions, endpoint system, and Laurent bounds. Those are not compared with the current declared dependencies in the shown executor. Moreover, ReconstructionOrderInputs is read only when plan === Automatic; an explicitly supplied saved plan bypasses that resolution altogether. 

automatic_reconstruction +1

Consequently, unchanged trace files can pass all displayed checks while:

the requested ThroughOrder has increased;

the physical-normalization request introduces an additional epsilon pole;

the endpoint bounds, coordinate map, or admissible domain have changed.

Execution then takes the old RequiredCoefficientUpperOrder directly as the reconstruction order. This can produce an insufficient pre-interpolation job even if a later acceptance stage eventually rejects it. 

automatic_reconstruction

Preferred fix: resolve the current card dependencies for both automatic and saved-plan execution, then validate the existing mathematical bindings against them. Alternatively, regenerate the inexpensive preparation plan and test whether existing reconstructed results cover its newly required orders.

This is precisely where your preparation-only replay is useful: invalidate or refresh the plan, not automatically the expensive reconstruction. A changed target may require more orders; an unchanged or weaker demand should not force hours of work merely because preparation was rerun.

4. Unsupported mathematics and invalid inputs cross the wrong failure boundaries

There are concrete problems in both directions.

A supported source can be blocked by an unrelated unsupported candidate. coefficientPlanPhysicalFactors is called on all selected masters before the per-column "ExactColumn" catch. Any nonempty UnresolvedIntegralDefinitions aborts that batch. Thus, one unsupported source definition prevents other candidates from being planned, and it can abort even for a master that would subsequently have been left exact because its matching factor is nonunit. 

automatic_reconstruction +1

Conversely, an invalid input binding can be downgraded to an ordinary exact fallback. DetermineCoefficientReconstructionOrders explicitly returns DivisorInventorySourceBindingMismatch for a source-path/hash mismatch. The planner sends every non-association result from that function into "ExactColumn", where a Failure becomes an ExactRational report. A stale or mismatched inventory is therefore treated like unsupported tail mathematics. 

automatic_reconstruction +1

The automatic dispatcher has a related issue: a present but malformed ReconstructionOrderInputs value is treated as though planning had not been declared, because every non-association selects <||>. Full rational reconstruction remains mathematically safe, but this violates your declared-input failure contract. 

automatic_reconstruction

The preferred boundary is:

Missing, malformed, stale, or contradictory declared artifacts fail preparation. Valid inputs whose matching, normalization, map, or uniform-bound analysis is unsupported produce a whole-column exact fallback with a reason.

Implement physical-definition resolution per master, or retain per-master outcomes from a batch. Distinguish typed input-integrity failures from unsupported-analysis results before catching them as exact fallbacks.

5. The no-candidate return leaves a stale on-disk plan

When selected === {}, the function returns before adding the complete planning-input binding and before writing Plan.wl. Therefore, a previous finite-partition Plan.wl can remain in the same directory after a successful preparation run that now selects no candidates. A subsequent path-based consumer can read the old plan rather than the newly returned all-rational result. 

automatic_reconstruction +1

That early return also bypasses substantive validation of physical-normalization content and endpoint-frame content. For example, a PhysicalNormalization association lacking its required fields is not examined by the physical constructor when no columns are selected. Missing top-level files already fail during reading; the issue is invalid content that survives that initial read. 

automatic_reconstruction +1

Validate declared dependencies independently of candidate selection, and always serialize the resulting plan, including an empty, fully bound all-rational plan. Old partition files may remain as unused cache material, but the current plan must not reference them.

The finite-order formula itself is appropriate

Subject to the effective-map and physical-frame conditions above, I do not see a new mathematical defect in the displayed order formula.

Let p be the prefactor’s epsilon lower bound, b
s
	​

 the uniform complete physical coefficient lower bound for sector s, and ν
s
	​

 its nilpotency index. An omitted rational tail beginning at ϵ
N+1
, with a fixed normal-pole class, has a distributional lower bound

N+1+p+
s
min
	​

(b
s
	​

−ν
s
	​

).

The subtraction by ν
s
	​

 accounts for logarithmic moments through degree ν
s
	​

−1. Requiring this to exceed the target T gives

N≥T−p−
s
min
	​

(b
s
	​

−ν
s
	​

),

which is what the implementation computes. The code also requires linear regulator exponents and separately refuses the unsupported singular zero-slope situation. 

automatic_reconstruction

Nothing here requires the exceptional exact summands to cancel within the planner. Keeping them exact and leaving their common-frame treatment to the existing endpoint engine is the correct separation of responsibilities.

API scoping, keys, and completion tests

I do not find a public/private symbol mistake in the two self-contained planning/order APIs: their usage symbols are declared in `FeynFacet`` before entering the private context. The compound-key lookup

Wolfram Language
Lookup[mappings, Key[coefficientMasterID[master]], None]

is also correct; Key[...] is needed for a list-valued key in Lookup, whereas direct association application can address that list as one key. 

automatic_reconstruction +2

 
Wolfram Documentation Center
+1

The attachment does not establish loader registration, forwarding from CoefficientSimplification, or the CLI’s use of this same implementation. Those remain integration checks, rather than demonstrated defects.

For the accepted NNLO case, complete validation without invoking interpolation: run the card-resolved preparation and standalone preparation against the same accepted trace, and require the discovered output set, regular/exact expression bytes, literal source-partition identity, physical/frame bindings, and derived order records to agree. Your reported {20,22} and upper orders {1,1} belong in that fixture’s expected results—not in production selection logic. Also inspect the actual stored p,b
s
	​

,ν
s
	​

,T values, rather than checking only that the final integers equal one.

The highest-value additional fixtures are the effective-map counterexample above; unchanged traces with changed normalization, endpoint, or target; a mixed supported/unsupported master batch; and a finite-plan run followed by a no-candidate run in the same directory. None requires rerunning the accepted NNLO reconstruction.

Bottom line: retain the unit-placeholder normalization construction, factor-one matching policy, shared divisor classifier, and physical-sector order formula. Before automatic integration, close the effective-map and source-to-frame bindings, validate saved plans against current dependencies, and correct the fallback and empty-plan paths.