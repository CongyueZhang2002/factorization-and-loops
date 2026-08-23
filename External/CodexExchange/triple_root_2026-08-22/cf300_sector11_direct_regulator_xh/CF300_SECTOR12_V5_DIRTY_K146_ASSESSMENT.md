# CF300 sector-12 recapture: failed K146 V4 probe and dirty-worker recovery

## Bottom line

The failed V4 probe did not detect a corrupt worker and did not modify it.  It
proved that K146 is not virgin, so the frozen V4 launcher must not be submitted
there.  Its failure is exactly the V4 contract: 42 source-candidate Global
names already exist, five carry own values, four Global basenames shadow loaded
packages, 1,685 relevant package names exist, and four relevant package
contexts are present in `$Packages`.  The probe was read-only, cleaned its
dedicated context, wrote no recapture output, emitted no messages, and returned
`$Failed`.

A targeted V5 recovery on K146 is technically feasible without killing or
restarting any process, but it is not a drop-in relaxation of V4.  It needs a
new no-write runtime gate before production.  Until that gate passes, a fresh
worker remains the only route carrying the already-frozen V4 proof.

## Why K146 is dirty

K146 first loaded FACET/CANONICA in
`test_row_resume_postmerge_xh_v1` at 09:37.  It later ran only a held parse and
two data-only strip-rescaling diagnostics before the 13:50 V4 probe.  The five
definition-bearing Globals reported by the probe are
`GlobalBasis`, `ranges`, `root`, `t0`, and `variables`; the four package-shadow
names are `dD`, `eps`, `Epsilon`, and `$FeynCalcStartupMessages`.

The current driver has two important self-refresh properties:

1. `LoadFACET.wl` unconditionally `Get`s `FeynFacet.m`, and `FeynFacet.m`
   clears both `FeynFacet\`*` and `FeynFacet\`Private\`*` before reading the
   pinned private files.
2. `family_epsform_sector.wls` resets
   `FeynFacet\`Private\`$canonicalBlocksCanonicaLoaded` and forces a real
   CANONICA `Get` on every mission.

Therefore the package-loaded observation is not by itself stale-FeynFacet or
stale-CANONICA evidence.  FeynCalc/FeynArts are reused, however, and their
in-memory definitions were not fingerprinted by the V4 probe.  That is the
remaining distinction from a virgin-worker proof.

## Safe V5 shape

The staged V5 delta deliberately remains K146-specific and fail-closed:

- require kernel 146, zero nested kernels, and helper ceiling zero;
- retain every V4 source/path/output/provenance gate and use a fresh V5 output;
- allow package presence, but require the exact observed four relevant
  `$Packages` prefixes and reject any additional relevant package prefix;
- allow existing source-candidate Global names only when every definition-
  bearing or package-shadowing one is in the expanded inherited set;
- add `root`, `ranges`, `t0`, `variables`, and `dD` to the V4 inherited Global
  set, then clear them only inside `Internal\`InheritedBlock`;
- accept pre-existing definitions for inherited Globals, but require exact
  definition and namespace restoration afterward;
- keep the dedicated driver parse with only `System\`` visible, the exact
  zero-message contract, exact strip hash/size/identity, and the same
  post-load cooperative quarantine;
- never advertise K146 reusable, even after a successful recapture.

The no-write gate must run first on K146 and prove: exact observed package
prefixes, no unsafe dirty Global, no unsafe package shadow, exact outer
namespace/definition restoration, zero messages, no output, and unchanged V4
files.  Production may follow only if that gate and a Wolfram held parse both
pass.  A package-version telemetry record for FeynCalc/FeynArts is required;
if it differs from the 09:37 load provenance, V5 must reject and wait for a
fresh worker.

## What is and is not proved now

Static analysis proves that the proposed isolation set covers every currently
reported dirty/shadow name and that the driver refreshes FeynFacet and
CANONICA.  It also proves that the frozen V4 files and hashes remain untouched.
It cannot prove the dynamic semantics of the expanded `InheritedBlock`, the
zero-message payload on this already-loaded FeynCalc session, or the exact
post-scope restoration without evaluating the no-write Wolfram gate.  For that
reason this assessment does not authorize launching the staged V5 production
body yet.

## Recommendation

Do not launch V4 on K146.  If a fresh pool worker becomes available, use V4;
that is the shortest proof-preserving route.  If not, materialize the staged
V5 delta under new filenames/output/tokens, run its no-write K146 gate, then
launch V5 only on a clean gate result and leave K146 quarantined.  No process
restart or signal is required for either decision.

