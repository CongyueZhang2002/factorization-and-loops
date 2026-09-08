# Package organization review

## Question

Review this concrete Wolfram NNLO-framework package reorganization. User explicitly permits breaking old paths/API wrappers, wants general code (no process/family hardcoding), standard mathematical terms, and maintainability: future geometries must not be mixed with stable infrastructure. Brief architectural critique, not new physics implementation. Reply with actionable flaws and preferred boundaries.

Current package has a 61 KB FeynFacet.m mixing exports, loading, conventions and formatting; ~80 private files in Core/Process/Reduction/Infrastructure/Geometry/EpsForm/Transport and 6 separate standalone numerical-reader files at root. Core mixes execution/result metadata, FeynCalc kinematics, exact algebra/linear integral sums, multiquadratic arithmetic and two-variable chart pullback. Transport mixes boundary Frobenius math, epsilon-order determination, master-integral representations, finite symbolic solutions and GPL notation. Geometry/TransportCharts.wl combines hardcoded rationalization catalog definitions, generic verification/composition, and process-family root-data registration. Optional epsilon-form code is ~3 MB with rational and multiquadratic methods. Production route is generic closed DE -> sufficient eps orders -> explicit finite integrals up to constants -> standalone numerical evaluation; epsilon form optional. A standalone FeynFacetSolution context supports FLINT, Wolfram quadrature, Taylor expansions and optional GPL/GiNaC. Existing NativePostfix CPU/GPU code has experimental benchmark drivers mixed with potentially reusable native evaluation. A 40 MB Private_Backup and distributions textbook PDF currently clutter package root.

Proposed:
- Keep thin FeynFacet.m main entry and Solution.m standalone reader entry.
- Kernel/{Loader,Modules,PublicSymbols,Formatting}: loading/exports only. Explicit manifest, no recursive auto-loading. Do not pretend folder layout proves a strict call-graph DAG.
- Core: execution, generic data IO, exact/modular arithmetic only. FeynCalc kinematics in Physics; integral linear combinations/definitions in Integrals.
- Physics: cards, collinear distributions, diagrams/cut topology bookkeeping.
- Reduction: IBP reduction and canonical families; external interfaces clearly separated.
- Coefficients: reconstruction and hard-function assembly.
- Geometry: coefficient-field presentations, rational pullback/rationalization, multiquadratic fields. Split catalog data from generic validation/composition. Do not pretend multiquadratic is all algebraic geometry. Future curve types need separate modules and explicit supported operations.
- DifferentialEquations: system assembly, optional Canonicalization/{Blocks,Rational,Multiquadratic,Family}.
- Expansion: sufficient-order logic separated from method-specific pole bounds.
- Boundary: local expansions and physical boundary determination.
- Solutions: finite symbolic construction/validation/write.
- Functions: Chen/GPL mathematics and representations; new special functions added here independently.
- Numerics: standalone reader, quadrature, Taylor, batches and adapters to native libraries; never loads diagrams or canonicalization.
- Interfaces: Kira/Libra/AMFlow-specific integration where separation is real, without artificial wrappers.
- Backends: actual C/C++/CUDA computation, protocol docs/build files; move measurements/test scripts to Tests/Benchmarks. Retired code moves outside active package to Archive/RetiredCode (not extra duplicate).
- Split mixed-responsibility large files only at real existing function/section boundaries; preserve math, update imports/direct source references/tests/docs. No blanket rename of public mathematical symbols or stored mathematical data.
- Add a small rationalization-catalog registration interface if justified so a new catalog entry needs data, not editing pullback algorithms. Avoid speculative giant plugin registry for unimplemented elliptic machinery.
- Verify package loading/reloading, standalone no-FeynCalc loading, selected existing geometry/epsilon-order/finite-solution/GPL/native tests, and source-reference completeness. Checks should not dominate computation.

What would you change? In particular are these folders too fragmented, where should coefficient-field presentations vs geometric curves vs differential-system pullbacks belong, and how can we give real extensibility without building unneeded frameworks?


## Pro response

The proposal is sound, but I would tighten several ownership boundaries before moving files. The folder count is not inherently excessive; the risk is creating multiple plausible homes for the same mathematics. The most important changes concern algebra versus geometry, local analysis versus physical boundaries, and solution representations versus their construction.

1. Separate coefficient fields, geometry, and differential systems

I would give exact algebra a named Algebra home rather than splitting it between an increasingly miscellaneous Core and Geometry.

Responsibility	Preferred owner
Exact/modular arithmetic, reconstruction algorithms, coefficient-field presentations, multiquadratic arithmetic	Algebra, with field-specific implementations beneath it
Coordinate maps, rationalizing parametrizations, chart composition, map domains and admissibility conditions	Geometry
Curve models and operations specific to a supported geometric class	Geometry/Curves, when implemented, not as an empty framework
Pullback of a differential system, including its coefficient one-forms and system metadata	DifferentialEquations/Transformations
Changes of dependent-variable basis and their effect on a differential system	DifferentialEquations/Transformations, distinct from coordinate pullback

Concretely, Geometry should supply and compose a coordinate map; Algebra should perform the coefficient substitutions and reductions needed to verify it; DifferentialEquations should apply it to a system. Do not put system-specific bookkeeping into a generic chart-composition routine.

Give these records explicit source and target information. Keep algebraic relations separate from the analytic domain and sheet choices attached to a particular realization. Physical selection of those choices belongs to the physics/boundary layer, while the resulting solution must retain them.

Multiquadratic arithmetic should not become the superclass for future geometries. A future curve module may use field arithmetic without adopting multiquadratic assumptions.

2. Reduce fragmentation by clarifying ownership, not merging everything

I would adjust these boundaries:

Core versus Algebra. Keep Core to execution support, generic IO, and genuinely generic result handling. Mathematical records and their serialization rules should remain with their owners. Generic reconstruction algorithms belong in Algebra; reconstructing and assembling a hard function belongs in Coefficients.

Boundary versus local analysis. Put Frobenius construction and reusable local-series recurrences in DifferentialEquations/LocalAnalysis. Let Boundary own boundary conditions, matching, and their physical determination. Numerical Taylor propagation can reuse the small local-analysis module without loading differential-system assembly or epsilon-form machinery.

Expansion versus solution planning. Your separation of sufficient-order logic from bound-producing methods is correct. I would initially place the former under Solutions/Orders, unless it already has substantial independent clients. Bound-producing algorithms stay beside their methods. Coefficients supplies the requested observable order and coefficient information; order planning propagates requirements through dependencies. It should not acquire every method’s pole-bound implementation.

Integrals, Solutions, and Functions. Give master identifiers, scalar-family definitions, and formal integral linear combinations one owner in Integrals. Give finite solution construction and boundary-parameterized solution records to Solutions. Put generic Chen/GPL identities and representations in Functions; conversion of a particular solution belongs in Solutions, calling those operations. Numerical evaluation belongs in Numerics.

Similarly, let Physics construct cut/family data from diagrams and Reduction operate on that data. Avoid maintaining separate authoritative versions of the same cut labels or family definitions.

These can be subdirectories or individual files. They do not each require another package entry point or public context.

3. Keep optional epsilon-form machinery genuinely optional

I prefer DifferentialEquations/EpsilonForm as the optional umbrella, with clearly named rational, multiquadratic, block, and assembly components. Keep dlog-specific work identifiable rather than letting Canonicalization obscure which transformation is actually being attempted.

Family is an ambiguous subdirectory name. If it contains generic assembly across blocks of an input family, call it Assembly. If it contains actual family-specific assignments, those should be supplied as data outside the generic algorithms.

Most importantly, generic finite-solution construction must not import this optional layer merely to obtain a record constructor, order helper, or matrix utility. Move such genuinely shared pieces downward. Failure or absence of epsilon-form machinery must not disable the stated production route.

4. Make extensibility small and concrete

The rationalization catalog is a justified extension point. I would support a small explicit collection of entries containing the mathematical applicability data, parametrization, assumptions, and information needed by the existing verifier.

A fixed catalog of mathematical formulas is not itself process hardcoding. The problematic coupling is a catalog or verifier that knows process names, family identifiers, or where particular roots occurred. Extracted family root data should be passed into matching, not registered as a side effect of loading Geometry.

The contract should be:

A new parametrization using supported operations requires a new data entry; a genuinely new mathematical method may require a new implementation.

Do not promise that every future geometry will be data-only. Add operation-specific dispatch only where existing callers need it, and return an explicit unsupported result when necessary. Avoid a global “supports elliptic geometry” flag, universal geometry object, or speculative plugin lifecycle.

Future curve algorithms, associated special functions, and differential-equation methods should have separate owners, with only the interfaces their actual implementations require.

5. Enforce the reader boundary and avoid duplicate adapter layers

The standalone reader needs an independently loadable solution-representation layer, not the whole symbolic solution builder. Both entry points should use the same mathematical heads and record definitions. Do not copy them into a second reader implementation or make reading depend on producer-side private symbols.

Choose one owner for each external adapter. Interfaces is reasonable for genuine vendor-specific translation and invocation, but do not duplicate it with another adapter under every consumer. In particular, exact FLINT operations should not be classified as numerical merely because the reader also uses FLINT.

Keep reusable native evaluation and its protocol in Backends; keep Wolfram-side translation with the adapter; move benchmark orchestration to Tests/Benchmarks. Neither importing the package nor loading a backend should run measurements.

Treat the proposed Kernel components as small files unless their size warrants directories. Keep one authoritative manifest. Formatting may be installed there, but mathematical definitions and physical conventions should not be owned by the loader.

For testing, distinguish repeated loading from actual reloading: Needs skips loading when the context is already recorded in $Packages, whereas Get reads and evaluates the file. Test the supported reload mechanism explicitly. 
Wolfram Documentation
+1
 Also test both entry-point orders in fresh kernels, because BeginPackage changes context resolution and its dependency form invokes Needs. 
Wolfram Documentation

My preferred acceptance criterion: the reader works without FeynCalc or canonicalization; the generic solver works without epsilon form; adding a catalog entry does not edit pullback algorithms; and each mathematical record has one owner. Combine those checks with your selected existing tests and source-reference updates—not additional expensive certification. Delete obsolete wrappers and duplicate backups, preserve stored mathematical symbols, and exclude retired code and the textbook PDF from the active distribution.