# Generality round 2: fix plan for Codex's standardization audit (2026-08-23)

Source: `Exchange/Codex/2026-08-23/16_standardization_generality_audit/
ASSESSMENT.md` (12 pass / 7 strict fail against HEAD 52ce634).
Verdict accepted: the multiquadratic promotion is a sound engine, not yet
a finished process-neutral integration.  This plan makes each gap a
decision, an owner, and a regression.

## F1 (P2, first -- it gates artifact reuse): root-order ABI
`RootSourceIndices` is hashed into the preparation fingerprint
(MultiquadraticStripSolve.wl:591-592) but consumed by nothing; reversing
the DECLARATION order of mathematically identical roots changes the ABI.
Fix: move it out of the hashed payload into non-hashed provenance; bump
the preparation schema; regression = forward vs reverse declaration give
bit-identical fingerprints (Codex's red-team check promoted to Tests/).

## F2 (P1): chartless multiquadratic dispatch in the public solver
`SolveEpsFormStripInFrame` returns `NoRationalStripChart`
(TransportCharts.wl:489) where the promoted engine could run.  Fix: when
`TransportRootSetChart` has no chart, dispatch to
`solveEpsFormStripMultiquadratic` and return its TYPED result --
"ModularConsistent" with reconstruction data, never "Solved" (the
OneForms contract stands).  Sector driver: a ModularConsistent block is
RECORDED (strip summary + a `<family>_<k>_<j>_modular.wl` artifact) and
the run stops typed at that block ("ModularCandidateNotInstallable"),
never silently continues and never claims the family.  Regression: the
audit's fixture -- public path reaches ModularConsistent, rank 3, all
sign branches; and the recorded artifact round-trips.

## F3 (P1, decision): FamilyRowGaugeFiniteField.wl stays a labelled prototype
Not loaded, not wired.  Its unique content (the row-level finite-field
oracle) has no production caller; its algebra now delegates to the
neutral module, and the strip engine covers the production need.
Decision: header labelled "validation prototype -- consumed by tests
only; load explicitly"; NOT added to $feynFacetPrivateFiles.  Revisited
when a CF300-class recapture driver needs a row oracle in production.
(Codex offered load-and-wire or label; wiring without a caller is
cargo cult.)

## F4 (P2, contract statement): the arity contract is two independent variables
The accepted scope (user decision): processes on the Mandelstam surface
s+t+u = const -- i.e. TWO independent variables after eliminating u.
No n-variable refactor.  Fix: state the elimination rule in the usage
strings of every two-variable entry point (SolveEpsFormStripInFrame,
solveEpsFormStripMultiquadratic, DiagonalBlockEpsForm, CertifyFamily
EpsilonForm, TransportFamily) and in the typed arity refusals
("...two independent variables; eliminate the third Mandelstam variable
first").  Promote the audit's two safe-refusal probes (true {s,t,u}
call; unsampled independent u in a root square) into Tests/.

## F5 (P2): executable process conventions become configurable, typed, or project-set
1. Family-name generation: `$canonicalFamilyPrefix` stays the package
   default ("CF" = canonical family, package-owned naming) but becomes
   settable (Global`$FACETFamilyPrefix before load / an option on the
   registry seeding), and generated names go through one function the
   registry owns.  Documented.
2. Undeclared class variables/regulator: `Automatic` resolution keeps
   record -> detection, but when BOTH are silent the fallback to
   Global`v/w/eps is replaced by a typed refusal
   ("ClassVariablesUndeclared"/"RegulatorUndeclared");
   the old silent default moves behind an explicit
   "LegacyVariableDefaults" -> True option used by this repository's
   drivers where needed.
3. Workspace component: the literal "Codex" path segment becomes
   `$feynFacetWorkspaceSubdirectory` (package default: "Workspace",
   process-neutral); THIS repository keeps its layout because
   Addon/Load/LoadFACET.wl sets Global`$FACETWorkspaceSubdirectory =
   "Codex" (project file, project convention).  Delete-guard and Kira
   project location read the variable.
Regressions: the audit's four convention probes, inverted to assert the
new behavior, plus one legacy-mode check.

## F6 (P2 performance): promote the two squeeze patches
1. Scalar-local root-free fast path -> the package's
   `multiquadraticFieldDecompose`: a scalar containing no declared root
   skips branch replacement/field reduction/inversion, is padded to the
   full 2^rank channel vector, and every fast-path result is verified by
   the exact compose check; telemetry `RootFreeFastPathCount`.
   Acceptance: Codex's 240-scalar microbenchmark rerun through the
   package (SameQ across all vectors; fast-path count = the root-free
   population; timing recorded, not asserted), plus the existing 75+80
   multiquadratic assertions.
2. Epsilon-content GCD census -> the support/letter census API that owns
   `NumeratorTotalDegreeBound` (FiniteFieldStripSolve census), not the
   External discriminator driver.  Gate: physical same-result check on
   real strips (CF265 (15,11) and (14,13) inputs are the fixtures:
   identical selected support and identical solution artifacts mod one
   prime, census time recorded before/after).
Patches: `finite_field_scalar_rootfree_squeeze_2026-08-23_xh/000{1,2}-*.patch`
are the reference implementations, to be ported (not blind-applied) with
their static test ideas moved into Tests/.

## F7 (P3, explicitly deferred): comment provenance
CF<n>/Codex mentions in comments are provenance, kept per the earlier
scope decision.  If the package is ever distributed standalone, sweep
them to WORKLOG/Design in a dedicated pass.  Recorded, not scheduled.

## Execution and acceptance
Two implementation agents on disjoint files: agent A = F1, F2, F6.1
(MultiquadraticStripSolve.wl, TransportCharts.wl dispatch site, sector
driver recording, new tests); agent B = F4, F5, F6.2 (CanonicalFamilies,
CanonicalBlocks, DiagonalBlockEpsForm, Reduction/CoefficientStore
workspace variable, LoadFACET project line, FiniteFieldStripSolve census,
usage strings via coordinator, new tests).  F3 is a header edit the
coordinator makes.  Backward-compatibility rule unchanged: current
behavior of THIS repository must be preserved (via the project-set
variable and legacy option), only silent wrong answers may become typed
refusals.  Final gate: the 369 committed assertions + Codex's red-team
test rerun (target: its 7 strict failures become passes or documented
decisions F3/F7) + the two promoted safe-refusal probes; then one
physical family (CF265) re-solved as the F6.2 same-result check.
