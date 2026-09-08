# dynamic family pool runtime review

## Question

Update: found true numerical bug: FLINT 3.0.1 gr_ctx_init_complex_acb initializes a shared method table without synchronization. Concurrent first acb_poly_taylor_shift calls intermittently overwrite it during use. Same saved input failed 3/60 fresh process runs; explicit serial gr_ctx_init_complex_acb before OpenMP gives 0/100; CF12 and CF18 now pass all 21 masters/138 coefficients. Runtime tests also found an actual Wolfram 14.2 trap: Internal`InheritedBlock[{x},ClearAll[x];x=2] leaves x=2 after original x=1, including lost DownValues/options; Clear[x] preserves restoration. Replaced ClearAll by Clear plus explicit Attributes/Options/DefaultValues/Messages assignments and tests pass. Also FeynFacet.m clears FeynFacet`Private` on package load, so script scope implementation moved into separate FeynFacetAMFlowRuntime`Private` to survive preparation loading package. Outer workers are fresh per family. We are testing two real families concurrently before full8. Please review only if you see a further major issue from these findings.

## Pro response

Your fixes address the demonstrated failures; my earlier ClearAll pattern was wrong for your runtime. I see two remaining potentially major gaps, both conditional on implementation details not shown.

1. The package-reload fix must protect the entire active evaluation, not just the scope function. Any parent state, cleanup callback, or helper still needed after preparation must survive the clearing of FeynFacet`Private` . In particular, Module locals are actual generated symbols—not independent stack storage—so moving only the public entry point while leaving its implementation or live locals in the cleared context is insufficient. 
Wolfram Documentation Center

Also, your demonstrated InheritedBlock failure implies that a subsequent ClearAll inside a loaded script/package can still defeat restoration of affected localized symbols, even after replacing the wrapper’s own ClearAll. The discriminating test is your existing restoration test with the actual preparation/package reload and generated script inside it. Moving the complete runtime implementation into the separate context addresses the first issue; the second depends on what the loaded code executes.

2. The newly identified OpenMP path needs its own one-thread production limit. Eight family workers meet the eight-core requirement only when the native Frobenius backend also uses one computational thread per family. Do not treat AMFlow NThread=1 or Kira -p1 as establishing that limit. Apply the OpenMP configuration before launching each native executable, or use the appropriate runtime API for an already loaded library; late environment-variable changes are not a supported way to reconfigure an existing OpenMP runtime. 
OpenMP

The FLINT source confirms the unsynchronized method-table initialization you identified. Your initialization-before-OpenMP approach addresses that mechanism within each native process; it does not require a cross-family lock or serialized family execution. 
GitHub

With those two conditions covered, I see no further major issue requiring an architectural change.
