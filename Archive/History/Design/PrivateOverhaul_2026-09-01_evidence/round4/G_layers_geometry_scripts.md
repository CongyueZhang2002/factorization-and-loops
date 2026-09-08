# Round 4, agent G: layer cycle, MapleCanonical mode, campaign scripts

Date 2026-09-02.  Source: Codex review
`Exchange/Codex/2026-09-02/01_private_overhaul_assessment.md`, sections
"Generality" (layer cycle, MapleCanonical) and "Conciseness and ghost
code" (campaign scripts).  Files owned by T (Transport/ObservableTransport*.wl,
Tests/Transport), M (Core/ModularArithmetic.wl, EpsForm/FiniteFieldStripSolve.wl,
EpsForm/MultiquadraticStripSolve.wl, Tests/FiniteField, Tests/Multiquadratic)
and L were not edited.  Nothing committed.  Scratch (scan tooling, logs):
`/tmp/claude-1000/-home-maxzhang/ecf0b429-302d-4fa5-85cc-249574ef5ba1/scratchpad/round4/G/`
(`layer_scan.py`, `symdef.py`, `closure.py`, `move_helpers.py`,
`loadcheck.wls`, `*.log`, `*.time`).

## 1. `GaugePullBackMode -> "MapleCanonical"` removed from the live allowed set

Codex: the mode was accepted by the option gate while its implementation
answered `RouteRetired`.  Changes:

- `FeynFacet/Private/Geometry/TransportCharts.wl`
  - :1242-1248 option gate: allowed set is `{"Exact", "FiniteFieldReconstruct"}`;
    `"MapleCanonical"` now returns
    `<|"Status" -> "InvalidGaugePullBackMode", "Allowed" -> {"Exact",
    "FiniteFieldReconstruct"}, "Actual" -> "MapleCanonical"|>` exactly like
    an unknown name; `productionCanonicalQ = finiteFieldCanonicalQ` (the one
    remaining post-pullback-residual mode).
  - :1130-1142 option comments rewritten for the two live modes; the option
    `"MapleCanonicalCacheDirectory"` is removed from
    `Options[SolveEpsFormStripInFrame]` (no live caller passed it; only
    `Scripts/Backup/family_epsform_sector_2026-09-02_before_legacy_removal.wls`
    did).  `Options[transportChartMapleCanonicalGauge]` (Maple executable,
    time limit, cache) removed as ghost code.
  - unreachable code removed: the `Which` arm that called the Maple
    normalizer (former :1848-1869), the Module variables `mapleCanonicalQ`,
    `mapleGauge`, `preNormalizationGauge`, the `"PostMapleResidualFailed"`
    alternative (:1900), the `"route"` (:1917) and `"Normalizer"` (:1945)
    branches.
  - :2796-2806 the stub `transportChartMapleCanonicalGauge[___] :=
    <|"Status" -> "RouteRetired", ...|>` is KEPT (comment updated): a
    record whose provenance names the mode remains readable, and a direct
    call answers by name.  The symbolic route is not resurrected.
- `FeynFacet/FeynFacet.m:160` usage of `SolveEpsFormStripInFrame`: one
  sentence naming the two allowed modes and the typed refusal (the usage
  did not list the modes before).
- `Tests/EpsilonForm/t_gauge_pullback_mode.wls` (new; the existing mode
  refusal lived only in `Tests/Multiquadratic/t_multiquadratic_transport_frame.wls`,
  M's directory, which tests `"NotAMode"`): default is `"Exact"`;
  `"MapleCanonical"` and `"NotAMode"` refused with the live allowed set;
  the stub answers `RouteRetired` naming the mode; no Maple cache key in
  the option list.  6 assertions.

## 2. The layer cycle

### Method

`layer_scan.py` (scratch) reads the manifest, strips comments and strings
(nested comments; backslash-newline inside strings handled -- the first
version swallowed those and mis-numbered TransportCharts.wl by 13 lines),
collects per file the top-level definition heads (`name[`, `name =`,
`name :=`, `name /:`, `Options[name] =`) and every identifier reference,
and reports each reference whose ONLY definitions live in a later layer.
`closure.py` computes the same-file dependency closure of a symbol set
(so a move is a closed block) and lists in-file users left behind;
`symdef.py` gives statement line spans.

### Before (committed layout): 55 upward symbol references in 12 files

| file (layer) | upward symbols | defined in |
|---|---|---|
| Core/RationalMaterialization.wl | `fail` | Process/Process.wl -- FALSE POSITIVE (Module-local `fail`, :249/:254) |
| Process/CanonicalFamilies.wl | `coefficientReadRecord`, `coefficientWriteRecord`, `validPreIBPResultQ` | Reduction |
| Process/Process.wl | `normalizeCoefficientKinematics` | Reduction/Simplification.wl |
| Infrastructure/TaskBroker.wl | `FamilyArtifactRead`, `SampleEpsFormStripAffine`, `finiteFieldStripFingerprint`, `finiteFieldStripPrepare` | EpsForm |
| EpsForm/BlockEquationDeferred.wl | `TransportRootSetChart`, `transportChartApplyRootBranches`, `...CanonicalizeDenestedRadicals`, `...DenestRadicalBase`, `...RadicalBases`, `...RootIndices` | Geometry |
| EpsForm/DiagonalBlockEpsForm.wl | `TransportRootSetChart`, `transportChartRekey`, `masterTransportLoadLibra` | Geometry, Transport |
| EpsForm/FamilyCertificateModular.wl | `transportChartCanonicalizeDenestedRadicals`, `...RadicalBases`, `...RootBranchScale`, `...RootIndices` | Geometry |
| EpsForm/FamilyEpsForm.wl | `TransportChartVerify`, `transportChartCurrentRoots`, `transportFamilyChartAlias`, `masterTransportChartData`, `...Normalize`, `...PointZeroQ`, `...PullBackSystem`, `...ResolveRegulator`, `...ResolveVariables`, `observableTransportBlockLowerQ`, `...RecordChart`, `...ZeroMatrixQ`, `...ZeroQ` | Geometry, Transport |
| EpsForm/FamilyRegulatorFactor.wl | `TransportRootSetChart`, `masterTransportChartData`, `...PullBackOneForm`, `transportChartAlgebraicZeroQ`, `...ApplyRootBranches`, `...CanonicalizeDenestedRadicals`, `...CurrentRoots`, `...Rekey`, `...RootIndices`, `...SquareSplit` | Geometry, Transport |
| EpsForm/LibraEpsForm.wl | `masterTransportLoadLibra` | Transport |
| EpsForm/MultiquadraticStripSolve.wl | `transportChartApplyRootBranches`, `...CanonicalizeDenestedRadicals`, `...CurrentRoots`, `...RadicalBases`, `...RootBranchScale`, `...RootIndices` | Geometry |
| Geometry/TransportCharts.wl | `masterTransportChartData`, `...PullBackOneForm`, `...RecordCoordinateMap` | Transport |

Every one of these is a CALL-TIME reference; the only load-time
cross-layer reference, `Options[SolveEpsFormStripInFrame] = Join[Options[SolveEpsFormStrip], ...]`
(Geometry <- EpsForm), goes DOWNWARD under the manifest order and was
left as is (it is why Geometry follows EpsForm; see "what remains").

### Moves (all verbatim, names unchanged, `move_helpers.py`; manifest ORDER unchanged)

| block | from | to | lines |
|---|---|---|---|
| root/radical algebra: `transportChartRadicalBases`, `...NumericSquareClass`, `...SquareSplit`, `...ExactSquareRoot`, `...SquareClassData`, `...DenestRadicalBase`, `...DenestSign`, `...CanonicalizeDenestedRadicals`, `...RootIndices`, `...CurrentRoots`, `...RootBranchScale`, `...ApplyRootBranches`, `...DeclaredRadicalGenerators`, `...AlgebraicZeroQ`, `transportChartRekey` (closed cluster, no out-of-file dependency) | Geometry/TransportCharts.wl (former :791-1206, :1284-1310, :1505-1668) | Core/MultiquadraticAlgebra.wl:233-868 (before `End[]`) | 622 |
| `masterTransportRecordCoordinateMap` (needs `masterTransportComposeTwoVariableRecord`, Geometry) | Transport/MasterTransport.wl (former :2072-2264) | Geometry/TransportCharts.wl:2596-2790 | 194 |
| `masterTransportLoadLibra`, `$masterTransportLibraLoaded` | Transport/MasterTransport.wl (former :332, :3178-3207) | EpsForm/LibraEpsForm.wl:103-137 | 31 |
| `$masterTransportRegulatorNames`, `$masterTransportZeroTimeLimit`, `masterTransportDefaultVariables`, `...DetectRegulator`, `...ResolveVariables`, `...ResolveRegulator`, `...Normalize`, `...WordFreeQ`, `...NormalizeWords`, `...Collect`, `...RadicalQ`, `...RadicalCanon`, `...RadicalNormalize`, `...RadicalZeroQ`, `...SimplifyZeroQ`, `...ZeroQ`, `...ZeroMatQ`, `...CheckLevel`, `...PointZeroQ`, `...FreeSymbols`, `...RationalQ`, `...ChartRecordQ`, `...ChartData`, `...PullBackOneForm`, `...MapTogetherSubstitute`, `...PullBackSystem` (closure of what EpsForm and Geometry call) | Transport/MasterTransport.wl (former :324-330, :407-455, :461-476, :543-690, :1285-1322, :1815-2071) | Core/Core.wl:610-1293 | 530 |
| `FamilyArtifactRead`, `FamilyArtifactWrite`, `$familyArtifactReadMessages` | EpsForm/FamilyEpsForm.wl (former :30-95) | Core/Core.wl:631-... | 66 |
| `coefficientAppendRecord`, `...WriteRecord`, `...ScanRecords`, `...ReadRecord` (length-prefixed binary record files) | Reduction/CoefficientStore.wl (former :72-125) | Core/Core.wl:719-... | 54 |
| `validPreIBPResultQ` (validator of the record `CollinearFactorizePreIBP` produces) | Reduction/Reduction.wl (former :28-62) | Process/Collinear.wl:786-820 | 35 |
| `normalizeCoefficientKinematics`, `coefficientMassDimension`, `$coefficientBranchGrammars` (the card's `CoefficientKinematics` declaration normalizer, called by the process-card validator) | Reduction/Simplification.wl (former :127, :373-415, :436-634) | Process/Process.wl:955-1205 | 243 |
| `taskBrokerSampleTask`, `taskBrokerSampleWorkerLimit`, `taskBrokerSampleBatch` (the strip sampler's broker client; calls M's `SampleEpsFormStripAffine`/`finiteFieldStripPrepare`/`finiteFieldStripFingerprint`) | Infrastructure/TaskBroker.wl (former :320-416) | EpsForm/FiniteFieldStripBroker.wl (NEW) | 97 |

Bookkeeping that a pure move needs and that the load check verifies:
every moved name was removed from its old owner's `Clear`/`ClearAll`
list (a later-loading file would otherwise wipe the new definitions) and
added to the new owner's; `FeynFacet/Private/LoadOrder.wl:31` lists
`"FiniteFieldStripBroker.wl"` right after `"FiniteFieldStripSolve.wl"`
(the one manifest LIST edit; re-read immediately before editing; the
order of layers and of every other file is unchanged).  Header comments
were updated in FamilyEpsForm.wl (artifact I/O now in Core) and in each
destination (origin and reason of the moved block).

Why these destinations and not "the lowest layer that uses it" for the
chart helpers: under the unchanged order EpsForm < Geometry, everything
EpsForm needs from Geometry can only live in EpsForm or Core; the radical
algebra and the chart-record algebra are generic (no catalog knowledge),
so Core is right under BOTH the current order and the reorder recorded
below, and nothing has to move twice.

### Proof that the moves are pure (coordinator question, answered by `G_move_proof.log`)

The working-tree deletions outside TransportCharts.wl are exactly the
moved blocks plus the `ClearAll` list lines of the moved names (a name
left in an old owner's `ClearAll` would wipe the new definition when
that file loads later):

| file | diff | block lines cut (HEAD numbering) | ClearAll lines |
|---|---|---|---|
| Reduction/Simplification.wl | -245 | 127 (1) + 373-415 (43) + 436-634 (199) = 243 | 2 |
| Reduction/CoefficientStore.wl | -54 | 72-125 (54) | 0 (no list) |
| Reduction/Reduction.wl | -35 | 28-62 (35) | 0 (no list) |
| Transport/MasterTransport.wl | -761 | 324 + 325-330 + 332 + 407-455 + 461-476 + 543-690 + 1285-1322 + 1815-2071 + 2072-2264 + 3178-3207 = 739 | 22 |

`prove_moves.py` (scratch; output copied to `G_move_proof.log` beside this
file) takes every block from `git show HEAD:` at those ranges and requires
it to occur byte-identically, exactly once, in the destination working
file and zero times in the source.  All 20 blocks pass; destinations:

| block (HEAD) | destination (working tree) |
|---|---|
| TransportCharts.wl:791-1206, 1284-1310, 1505-1668 | Core/MultiquadraticAlgebra.wl:259-674, 676-702, 704-867 |
| MasterTransport.wl:324, 325-330, 407-455, 461-476, 543-690, 1285-1322, 1815-2071 | Core/Core.wl:773, 775-780, 782-830, 832-847, 849-996, 998-1035, 1037-1293 |
| MasterTransport.wl:2072-2264 | Geometry/TransportCharts.wl:2602-2794 |
| MasterTransport.wl:332, 3178-3207 | EpsForm/LibraEpsForm.wl:106, 108-137 |
| FamilyEpsForm.wl:30-95 | Core/Core.wl:651-716 |
| CoefficientStore.wl:72-125 | Core/Core.wl:718-771 |
| Reduction.wl:28-62 | Process/Collinear.wl:786-820 |
| TaskBroker.wl:321-416 (320 was the section header line, replaced by the new file's header) | EpsForm/FiniteFieldStripBroker.wl:17-112 |
| Simplification.wl:127, 373-415, 436-634 | Process/Process.wl:961, 963-1005, 1007-1205 |

Definition-head counts (top-level `name[`, `name =`, `name :=`, `name /:`,
`Options[name] =`, comments stripped) over the 13 edited files, HEAD vs
working tree: 694 -> 693 heads, 568 -> 568 symbols, 58 symbols changed
file (listed in the log), no symbol gained a head.  The ONE head that
disappeared is `Options[transportChartMapleCanonicalGauge]` (HEAD
TransportCharts.wl:473-481: Maple executable, time limit, cache
directory), the option list of the retired stub whose `[___]` definition
ignores options -- deleted deliberately under item 1 (MapleCanonical
ghost code), not Reduction pruning.  Everything else removed from
TransportCharts.wl under item 1 (the Maple `Which` arm, three Module
variables, the `If[mapleCanonicalQ, ...]` branches) is unreachable code
inside `SolveEpsFormStripInFrame`, not a definition.  Nothing live was
deleted; nothing needs restoring.

### After: what remains upward, by name (also in the LoadOrder.wl header)

- EpsForm -> Geometry, call-time catalog/registry lookups:
  `TransportRootSetChart` (BlockEquationDeferred.wl, DiagonalBlockEpsForm.wl,
  FamilyRegulatorFactor.wl), `TransportChartVerify` and
  `transportFamilyChartAlias` (FamilyEpsForm.wl).  Not movable: they ARE
  the catalog/registry.  The true graph has the chart catalog BELOW
  EpsForm; it sits above only because `SolveEpsFormStripInFrame` (an
  EpsForm client) shares its file and inherits `Options[SolveEpsFormStrip]`
  at load time.
- EpsForm/FamilyEpsForm.wl -> Transport/ObservableTransport.wl (T's file
  this round): `observableTransportBlockLowerQ`, `observableTransportRecordChart`,
  `observableTransportZeroMatrixQ`, `observableTransportZeroQ` -- four
  predicates, about 40 lines; the two zero tests wrap `masterTransportZeroQ`
  (now Core).  Not moved (ownership).
- Name-only references the scan reports and I accept: Core/Core.wl matches
  the public retired head `TransportWord` as a pattern inside
  `masterTransportZeroQ`'s word branch; Process/Process.wl issues the
  message `BuildSimplificationContext::invalid` (defined in Reduction).
  Neither is a load-time dependency.
- False positive: `fail` in Core/RationalMaterialization.wl (Module-local).

No load-time reference crosses upward.  The scan on the moved tree:
`Core/Core.wl: 1 (TransportWord)`, `Core/RationalMaterialization.wl: 1 (fail)`,
`Process/Process.wl: 1 (BuildSimplificationContext)`,
`EpsForm/BlockEquationDeferred.wl: 1`, `EpsForm/DiagonalBlockEpsForm.wl: 1`,
`EpsForm/FamilyRegulatorFactor.wl: 1` (all `TransportRootSetChart`),
`EpsForm/FamilyEpsForm.wl: 6` (the two catalog names + T's four).
Geometry -> Transport and Infrastructure -> EpsForm are gone; the
FamilyCertificateModular.wl, LibraEpsForm.wl and MultiquadraticStripSolve.wl
upward references are gone without touching M's file (names kept).

### Docs

- `FeynFacet/Private/LoadOrder.wl` header: layer descriptions updated to
  what each layer holds now, plus the measured remaining upward
  references by name and the reorder recipe.
- `Design/GeometryDeclaration_2026-09-02.md`: new section "Where the
  geometry sits in the layer graph" (move table, remaining references,
  follow-up).

## 3. Campaign scripts

- `Scripts/observable_transport_kernelpool_campaign.sh:2-11`: header
  declares it the CANONICAL multi-family driver (one pool main + N
  subkernels; respects the two-main-kernel licence) and says when the
  standalone one applies.
- `Scripts/observable_transport_campaign.sh:2-12`: header labels it
  STANDALONE (one wolframscript = one main kernel per family, no pool, no
  broker), not canonical; use only when no KernelPool can run or for one
  family; warns that `FACET_TRANSPORT_JOBS > 1` starts several mains.
- `Scripts/complete_observable_transport.sh:2-11`: header states that it
  dispatches the standalone driver and how to run the canonical driver on
  the manifest it writes.  Its dispatch was NOT changed (a switch needs a
  pool-root argument and starts a pool: a launch-policy decision).
- `Scripts/complete_master_transport.sh:2-7`: checked -- it does NOT drive
  the retired route: it chains `complete_family_epsforms.sh` and
  `complete_observable_transport.sh` (:63-75).  Kept in place; the header
  now says "master transport" names the two-stage pipeline, not the
  retired Libra `TransportFamily` route.  Nothing moved to
  `Scripts/Backup/retired_routes_2026-09-02/` (so its README is unchanged).
- `Scripts/README.md:18-27`: the four scripts described with the
  canonical/standalone roles.
- `bash -n` on the four scripts: OK.

## 4. Tests run (all through the seat launcher, one seat at a time)

| test | acceptance criterion | result | wall |
|---|---|---|---|
| scratch `loadcheck.wls` (Get LoadFACET.wl; DownValues/OwnValues of 38 private + 9 public moved/affected symbols; option list; five behavioral probes of moved helpers) | every symbol has a value; default mode Exact; ScratchDirectory still inherited; no Maple cache key; `masterTransportZeroQ[Sqrt[2]^2-2]`, `masterTransportRadicalZeroQ[(1+Sqrt[x])(1-Sqrt[x])-(1-x)]` True; `transportChartRadicalBases[1/Sqrt[1-4vw]] == {1-4vw}`; `TransportRootSetChart[{lambda1}]` = Kallen1; `masterTransportChartData` on Kallen1 OK | LOADCHECK OK, 17 EpsForm files loaded | 2.7 s |
| `Tests/EpsilonForm/t_gauge_pullback_mode.wls` (new) | criteria (a)-(d) in the file | 6 assertions, 0 failed (twice: relative path from repo root 3.8 s; absolute path re-run 24.5 s incl. seat wait) | 3.8 s / 24.5 s |
| `Tests/EpsilonForm/t_epsform_obstruction.wls` (regression check; exercises FamilyArtifactRead and the moved radical helpers through the obstruction certificate) | statuses pinned in the file | 7 OK, 0 FAIL ((a) 56.5 s order 1; (b) CF305 order 4 2.4 s; (c) MissingLetters) | 62.6 s |
| `Tests/Core/t_package_generality.wls` (static scan of every package source + runtime registry checks + `transportChartRekey` path) | criteria in the file | 25 assertions, 0 failed | 110.5 s |

Run discipline (coordinator note on false greens): every run above was
judged by its own tally line, never by the exit code -- `LOADCHECK OK`
after the 47-symbol table, `N assertions, M failed` (TestKit),
`t_epsform_obstruction: 7 OK, 0 FAIL`.  The 4-second entry in the seat
log (13:48:41-13:48:45, `t_gauge_pullback_mode`) is genuine: its log
carries the six labelled PASS lines and the tally, and the package loads
in about 2.6 s on this box.  Re-run after the note from the repository
root by ABSOLUTE path: `6 assertions, 0 failed`, 24.5 s wall including
the seat wait (`t_gauge_pullback_mode_rerun.log`).  None of my logs
contains "Failed to open file".  The load check was run from the scratch
directory with a relative path that existed there; from now on every
launch names the script by absolute path from the repository root.

Not run by me (cost/ownership rules): `Tests/Multiquadratic/t_multiquadratic_transport_frame.wls`
(M's directory; it is the one test that SOLVES a strip through
`SolveEpsFormStripInFrame` with the moved chart helpers -- recommended
as the next confirmation), `Tests/Infrastructure/t_broker_adaptive.wls`
(references `taskBrokerSampleBatch` by name, unaffected by the move, but
it may launch kernels), Tests/Transport (T).  The load check does prove
every module parses and every moved definition exists after the full
load order.

## Open items

1. Acyclic layers (recorded, not done): move `SolveEpsFormStripInFrame`
   with its option list and the helpers that call EpsForm
   (`transportChartPullBackDeferredBundle`, `transportChartPullBackDeferredPreparation`,
   `transportChartParallelJacobianPullBack`, `transportChartProjectionDecompose*`,
   about 1,500 lines of TransportCharts.wl) into an EpsForm file listed
   after `EpsFormStrip.wl`, then list Geometry BEFORE EpsForm.  After that
   the only upward references are T's four predicates.  Not done in
   round 4: four agents were editing the EpsForm solvers this function
   calls, and the assignment fixed the manifest.
2. T's four predicates in FamilyEpsForm.wl: pure move of
   `observableTransportZeroQ`/`ZeroMatrixQ`/`BlockLowerQ` to Core next
   to `masterTransportZeroQ`, `observableTransportRecordChart` (needs the
   catalog) to Geometry.
3. The moved helpers keep their `masterTransport*`/`transportChart*`
   prefixes in Core (a rename would touch M's and T's callers).
4. `complete_observable_transport.sh` dispatches the standalone driver;
   switching to the canonical pool driver needs a pool-root argument
   (user decision).
5. `Scripts/Diagnostics/overhaul/*.py` still list the flat `Private/`
   directory (pre-existing; they no longer see the layer folders).
6. Line numbers above are for the tree at 2026-09-02 after this pass;
   other agents' concurrent edits to their own files (visible in
   `git status`) can shift them.

## 5. Epsilon-valuation certificate: script hook and public name (coordinator task 2, 2026-09-02)

Contract used: T's report section 1 -- `observableTransportCertifyEpsilonValuations[record]`
returns `<|"Status" -> "TransportEpsilonValuationsCertified", "Record" -> ..., "Tight" -> ..., "Certificate" -> ...|>`
or a typed refusal; the file variant certifies in place.

Changes:

- `Scripts/compact_family_dlog_record.wls` (lines 25, 34, 92, 98, 99, 111): the script now loads the
  package (`Addon/Load/LoadFACET.wl`, two-level ascent like every top-level
  script) and reads its three inputs through `FamilyArtifactRead` instead
  of bare `Get` (the mandated context-guarded reader once the package is
  on the context path; same typed failure on a non-Association).  After
  `compact` is built it calls `FeynFacet`Private`observableTransportCertifyEpsilonValuations[compact]`;
  the optional TRANSPORT_EPSILON_VALUATIONS file (the script never
  computed valuations itself -- it only took this file, e.g. from
  `ExactAlgebraicPointValuation`) stays in `compact` as the CLAIM the
  certifier checks; without it the valuations are derived.  Only
  `result["Record"]` is written (atomic rename as before); any other
  status prints the typed record (minus `Record`) and exits 3 (2 = usage,
  1 = invalid input, unchanged).  The summary line now carries the
  valuations, the certificate status, `Tight` and the claim source.
- `FeynFacet/FeynFacet.m:269` usage of the new public name
  `CertifyTransportEpsilonValuations` (record or file in, certified record
  or typed refusal out; file variant options).
- `FeynFacet/Private/Transport/ObservableTransport.wl:3565, 3566, 3567` (appended at the
  end, nothing else touched): `CertifyTransportEpsilonValuations[record_Association, opts___] :=
  observableTransportCertifyEpsilonValuations[record, opts]`, the `_String`
  variant onto `...CertifyEpsilonValuationsFile`, and a `[___]` typed
  refusal `TransportEpsilonValuationInputNotWellFormed` (the file's own
  convention for its public entries).  Not added to the file's head
  `Clear[...]` list (T's file, head untouched): a re-`Get` re-adds the
  identical three rules, harmless.

Verification (seat launcher, repository root, absolute paths, verdict by
tally line; logs under `scratchpad/round4/G/certify/`):

| run | criterion | result |
|---|---|---|
| `probe_certify.wls` (load; usage is a string; 3 definitions in `FeynFacet``; T's 1x1 fixture `TTotal={{eps}}`, `TTotalInverse={{1/eps}}`, claim TMin 1 / BlockLower {-1}) | record variant certifies `Tight -> True` and the record's status is `TransportEpsilonValuationsCertified`; stale claim TMin 2 refused `TooHigh`; file variant: dry run certifies and leaves the file uncertified, the write certifies it in place (re-read through `FamilyArtifactRead`), a repeat reports `AlreadyCertified`; `CertifyTransportEpsilonValuations[42]` refused typed | `probe_certify: 11 OK, 0 FAIL`, exit 0 |
| `compact_family_dlog_record.wls` on a two-block synthetic assembly + dlog (scratch `certify/assembly.wl`, `dlog.wl`; one recorded off-diagonal pair so the script's own coverage gate passes) with claim file TMin 1 / BlockLower {-1,-1} | writes the record, summary shows `ValuationCertificate -> <|Status -> TransportEpsilonValuationsCertified, Tight -> True, ClaimSource -> valuations_good.wl|>`, exit 0 | as expected; written record carries the certificate (2915 bytes) |
| same with stale claim TMin 2 | nothing written, typed status printed, exit 3 | `TransportEpsilonValuationsTooHigh, ClaimedTMin -> 2, ObservedTMin -> 1` printed with the three trials; no output file; exit 3 |
| same with no valuation file | valuations derived, record written, exit 0 | `TransportEpsilonValuations -> <|TMin -> 1, BlockLower -> {-1, -1}|>`, `ClaimSource -> DerivedFromTrials`, exit 0 |

Note found on the way (pre-existing, not changed): the script's coverage
gate refuses a ONE-block assembly with `StripSolvers -> {}`
(`Lookup[{}, {"Sector","LowerSector"}, Missing[]]` yields `{Missing[], Missing[]}`,
one "pair" against zero expected), so a single-block family cannot be
compacted by this script as written; the two-block fixture avoids it.

## 6. modularLift consolidation and the JacobiSymbol idiom (coordinator tasks 3 and 4, 2026-09-02)

### 6a. The two spelled-out lifts are modularLift: replaced

Semantics compared (M had already rewired the EpsForm primitives:
`epsFormFiniteFieldRationalReconstruct` := `modularRationalReconstruct`,
`epsFormFiniteFieldCombineLists` := `modularCRT` on padded lists,
`epsFormFiniteFieldImageQ` := `TrueQ[modularImageQ]`), so both bodies were
literally CRT + rational reconstruction at the product modulus (+ image
check at every prime for the diagonal block) on per-prime coefficient
lists padded to the recorded degrees -- the `modularLift` composition
(`Core/ModularArithmetic.wl:254-280`).  Same inputs (padded per-prime
integer lists, the prime list), same failure value (`$Failed` /
the callers' typed statuses, see below), same image check
(`modularImageQ` at each prime, which at a prime is the old
`epsFormFiniteFieldImageQ`).  Two strengthenings, both stated in the
files, neither able to change an accepted result on the callers'
contract: `modularLift` refuses a prime list that is not a list of
distinct primes (the old composition silently combined one; the prime
schedules of both callers never produce one), and the gauge pull-back
lift now carries the image check the diagonal-block lift always had
(provably redundant after `modularRationalReconstruct`'s residual check:
n = a d mod m with gcd(d, m) = 1 gives the congruence at every p | m).

Changes:
- `FeynFacet/Private/EpsForm/FiniteFieldEpsForm.wl:137-158` new
  `epsFormFiniteFieldPaddedCoordinate[data]`: the degree rule and
  `PadRight` of `epsFormFiniteFieldCombineCoordinate` WITHOUT the CRT
  (`$Failed` when the per-prime degree records disagree) -- the input
  `modularLift` expects; added to the file's `ClearAll` (:21).
  `epsFormFiniteFieldCombineCoordinate` itself is untouched (M's strip
  solvers and `MultiquadraticStripReconstruction.wl` use it).
- `FeynFacet/Private/EpsForm/DiagonalBlockEpsForm.wl:945-966`
  `diagonalBlockLiftFunction` = padding + `modularLift` on numerator and
  denominator lists + `FromDigits`; the CRT/reconstruct/image-check
  composition is deleted.
- `FeynFacet/Private/EpsForm/FiniteFieldGaugePullBack.wl:987-1002`
  `finiteFieldGaugePullBackLift`: per-coordinate padding, then
  `modularLift`; `"FiniteFieldGaugePullBackCRTFailed"` keeps its only
  reachable meaning (degree records disagree), `"...ModulusTooSmall"`
  keeps its meaning (a coefficient did not reconstruct; also the
  unreachable CRT/image corner, which the old code routed there too via
  an unevaluated reconstruct call).  File header (:12-23) documents it.

### 6b. `JacobiSymbol[#, p] === 1` -> `modularResidueQ[#, p]`

All four sites sit under odd primes, so the predicates are identical
(`modularResidueQ` = `Mod[a, p] =!= 0 && JacobiSymbol[a, p] === 1`; the
old `#1 =!= 0` on a reduced image is the same nonzero test).  Wrapped in
`TrueQ` so an even modulus (`modularResidueQ` -> `$Failed`) fails closed
as "not split" instead of leaving an `And` unevaluated.
- `FamilyRegulatorFactor.wl:1281` (`familyRegulatorGradedCorroborate`;
  primes are `NextPrime` from 7 10^8 with p = 3 mod 4);
- `BlockEquationDeferred.wl:780, 792` (`blockEquationDeferredActiveGradeCensus`;
  primes from the preparation's schedule, points drawn in [2, p-1]);
- `FamilyCertificateModular.wl:787` (`familyCertMQPrimeAdmissibleQ`, called
  only after `Mod[p, 4] === 3`); `a =!= 0 && b =!= 0` kept as written.

### Verification (seat launcher, repo root, absolute paths; one seat at a time)

| test | route exercised | verdict | wall |
|---|---|---|---|
| `Tests/EpsilonForm/t_diagonal_block_epsform.wls` | `DiagonalBlockEpsForm` end to end (7 calls; the lift on every coordinate) | `25/25 checks passed`, 0 FAIL lines | 6.52 s |
| `Tests/Transport/t_finite_field_gauge_pullback.wls` | `transportChartFiniteFieldCanonicalGauge` rank 0/1 incl. `finiteFieldGaugePullBackLift` (CRT + lift at two primes) | no `FTReport` in this test: all 14 declared `FTAssert`s printed PASS, 0 FAIL, exit 0 | 14.16 s |
| `Tests/EpsilonForm/t_gauge_pullback_mode.wls` | option gate (regression check) | `6 assertions, 0 failed` | 3.41 s |
| `Tests/Multiquadratic/t_multiquadratic_regulator_factor.wls` | `FactorFamilyRegulatorDependence` multiquadratic route incl. `familyRegulatorGradedCorroborate` (split points at the corroboration primes) and the deferred active-grade census | `66 OK, 0 FAIL` | 7.05 s |
| `Tests/Multiquadratic/t_deferred_bundle_chart_compatibility.wls` | `blockEquationDeferredActiveGradeCensus` (`ModularActiveGrades` decisions) | no `FTReport` in this test: all 20 declared `FTAssert`s printed PASS, 0 FAIL, exit 0 | 6.02 s |
| `Tests/Multiquadratic/t_family_certificate_multiquadratic.wls` | `familyCertMQDrawPrime` / `familyCertMQPrimeAdmissibleQ` (admissible fresh primes) | `28 OK, 0 FAIL` | 3.74 s |

Tests in `Tests/Multiquadratic` (M's directory) were run, not edited.
Logs: `scratchpad/round4/G/lift/`.

## 7. Acyclic layers: the in-frame solver moved to EpsForm, Geometry listed first (coordinator task 5, round 7, 2026-09-02)

The follow-up recorded in sections 2 and 6 is done.  Moving set, decided
from a per-statement table of TransportCharts.wl (in-file users,
out-of-file users, EpsForm/Transport references; scratch
`tc_analysis.txt`): a helper moved iff every in-file user moved, starting
from `SolveEpsFormStripInFrame` and from the five helpers that referenced
EpsForm symbols (`transportChartProjectionDecomposeEntry`,
`transportChartParallelJacobianPullBack`, `transportChartPullBackDeferredBundle`,
`transportChartPullBackDeferredPreparation`, the solver).

Changes (all moves verbatim; proof `G_inframe_move_proof.log`, baseline =
the working tree snapshot taken at 16:56 before the edit, NOT HEAD -- see
the concurrency note):

- NEW `FeynFacet/Private/EpsForm/Strip/EpsFormStripInFrame.wl` (1768 lines):
  header (:1-20), `ClearAll` of all 34 private movers (:22-53), then the
  three blocks of the old TransportCharts.wl: :87-483 -> :55-451 (stage-log
  globals and functions, `transportChartTogetherTask`/`ParallelTogether`,
  the projection-decompose and Jacobian-pullback tasks,
  `transportChartLogSuccessTimings`), :850-2152 -> :453-1755
  (`transportChartPullBackStrip`, the deferred-bundle pullbacks,
  `transportChartCanonicalizeFrameImages`, the deadline helpers,
  `Options[SolveEpsFormStripInFrame] = Join[Options[SolveEpsFormStrip], ...]`
  -- the load-time inheritance that caused D1, now same-layer --
  `$transportChartMultiquadraticScopeRefusals`, the timings separation,
  `SolveEpsFormStripInFrame`), :2795-2806 -> :1757-1768 (the RouteRetired
  Maple stub).  The public symbol is not Clear'ed here (TransportCharts.wl
  never did either; usage and SyntaxInformation stay in FeynFacet.m).
- `FeynFacet/Private/Geometry/TransportCharts.wl` (1107 lines, was 2806):
  the 26 moved names dropped from `ClearAll` (:51-62; the list's last entry
  `$transportChartZeroTestTag` needed a comma fix -- the first scan after
  the move flagged exactly that leftover), layer-position note in the
  header (:46-56), and `observableTransportSourceFrameQ` +
  `observableTransportRecordChart` pasted after `masterTransportChartByName`
  (:297-318) with their `ClearAll` entries.  Stays: catalog, verification,
  frame builder, root census, `TransportRootSetChart`, registry/aliases,
  extension, `masterTransportComposeTwoVariableRecord`,
  `masterTransportRecordCoordinateMap`.
- `FeynFacet/Private/Core/Base/Core.wl:782-801`: `observableTransportZeroQ`,
  `observableTransportZeroMatrixQ`, `observableTransportBlockLowerQ` after
  `masterTransportZeroMatQ`, `ClearAll` entries added.
- `FeynFacet/Private/Transport/Observable/ObservableTransport.wl`: the five
  definitions cut (old :80-81, :83-84, :92-96, :593-608, :610-623) and
  their five `ClearAll` entries removed; nothing else touched.
- `FeynFacet/Private/LoadOrder.wl:132-138`: `"Strip/EpsFormStripInFrame.wl"`
  listed right after `"Strip/EpsFormStrip.wl"`; `"Geometry"` moved before
  `"EpsForm"`; header rewritten (layer contents, the measured graph, the
  D1 history, the sub-folder list).
- `Tests/Infrastructure/t_construction_budget.wls:580-581`: the static
  "never TimeConstrained" check reads the solver's source through
  `feynFacetPrivateFile["EpsFormStripInFrame.wl"]` instead of the
  Geometry path (it would otherwise pass vacuously on a file that no
  longer contains the function).
- `Design/PrivateLayers_2026-09-02.md` (rows 5-6, the upward-reference
  paragraph, new section "Correction 2026-09-02 (round 7)" with the
  sub-folder table) and `Design/GeometryDeclaration_2026-09-02.md`
  (new section "Round 7").

Scan after the move (`scan_r7_after.json`; before: 11 upward symbols in
7 files): NO call-time upward reference in any layer.  Reported and
accepted, by name: `Core/Base/Core.wl` matches the public retired head
`TransportWord` as a pattern; `Process/Cards/Process.wl` issues the
message `BuildSimplificationContext::invalid`; the `fail` of
`Core/Algebra/RationalMaterialization.wl` is Module-local (false
positive).  The FamilyEpsForm -> observableTransport* edge is gone (the
four predicates moved down as pure moves; `RecordChart` needed only
`SourceFrameQ`, a five-line string predicate with no other user, which
went with it).

Proof: every one of the 8 blocks occurs byte-identically exactly once
in its destination and zero times in its source; definition heads over
the four files 237 -> 237, symbols 195 -> 195, 40 relocated, none
fewer, none more.

Load check (`loadcheck_r7.wls`, launcher, 2.3 s): order {Core, Process,
Reduction, Infrastructure, Geometry, EpsForm, Transport};
`DownValues[SolveEpsFormStripInFrame]` = 1; `Options` length 25 with
`ScratchDirectory` inherited (`Options[SolveEpsFormStrip]` = 15 keys at
that moment, so the join happened after EpsFormStrip.wl loaded); usage
kept; `feynFacetPrivateFile["EpsFormStripInFrame.wl"]` and
`["Strip/EpsFormStripInFrame.wl"]` resolve to the same existing path;
every moved private symbol defined; `RecordChart` resolves "Kallen1" and
names the source frame `None`; `BlockLowerQ` true/false on a
lower/upper pair.  (The `$transportChartZeroTestTag` line of that probe
is vacuous -- `With` substituted the string value into `DownValues` --
the symbol's OwnValue is proved by the scan and by the solver test.)
26 OK, 0 FAIL.

| test | verdict | wall |
|---|---|---|
| `Tests/Multiquadratic/t_multiquadratic_transport_frame.wls` (solves a one-root strip through the moved `SolveEpsFormStripInFrame`, exercises `transportChartParallelTogether` and the deadline path) | `20 assertions, 0 failed` | 3.16 s |
| `Tests/Infrastructure/t_construction_budget.wls` (edited; static checks on the solver source via the resolver, deadline seams) | `40 OK, 0 FAIL` | 7.27 s |
| `Tests/EpsilonForm/t_epsform_obstruction.wls` | `7 OK, 0 FAIL` | 65.36 s |
| `Tests/Core/t_package_generality.wls` (static scan of every manifest source incl. the new file; registry runtime) | `25 assertions, 0 failed` | 35.98 s |

Concurrency note: `ObservableTransport.wl` was being edited by another
agent while this ran (uncommitted Laurent-jet retirement, file saved
16:53:30; my read/write at 16:56).  My write kept that edit and changed
only the five predicate definitions and `ClearAll` entries; the proof
baseline is the 16:56 snapshot (`scratchpad/round4/G/round7_before/`).
If the other agent writes back from an older buffer, the five
definitions reappear in Transport and the scan will show them again;
re-apply by deleting them there (they are defined in Core and Geometry).
