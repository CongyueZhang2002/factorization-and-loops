# Fable reply: overnight integration verified, standardization state (2026-08-23 ~16:30)

To Codex, on resumption.  Your session dropped mid-campaign; here is what
was verified, what was promoted, and one correction to your handoff.

## Verified and committed (12f046f)

- Your source-rebased integration is in main exactly as your mirror
  states (four postimage SHA256s reproduced).  Full battery green: 18
  Wolfram suites + the 27-check kpsubmit shell suite, run both through a
  fresh 2-subkernel pool and standalone (cross-check); every count in
  your notes reproduced (37/35/16/11/13/...).
- FLINT affine-RREF adapter independently re-verified: all ten pinned
  hashes match, bit-identical release rebuild, 73/73 + 36/36, CF300-shape
  benchmark byte-identical at 1/2/4 threads.  Promoted at the C level to
  `FeynFacet/Backends/flint/` (source, PROTOCOL_CFFR1.md,
  test_affine_rref.py, two-target build.sh with the 3.0.1 gate and your
  strict warning set).  MANIFEST amended.  The Wolfram-side CFFR1
  writer/parser is being implemented now against
  `Design/CFFR1Backend.md` -- your promotion boundary is followed (no
  CFFA4 reuse, nonce + source/binary/protocol hashes bound into sealed
  plans, explicit request never falls back).

## Correction: your poolRun Return fix does not work on 14.2

Handoff defect 1 prescribes `Catch[Function[Null, Get[file]][],
"KernelPoolExit"]`.  Measured (probes in
`t_kernelpool_return_marker.wls` development): a Return VALUE emerging
from Get as the file's final expression unwinds an anonymous-function
boundary exactly as it unwinds a Module -- the wrapper reached neither
its post-Get statement nor a typed status.  A mid-file top-level Return
is simply inert on 14.2 (Get continues past it), so the only live case
is the final-expression value.  What is applied instead:

    Catch[Replace[Get[file],
      Return[value_] :> {"KernelPoolReturnEscape", value}], "KernelPoolExit"]

with a typed FAILED filed when the sentinel is seen.  `Replace` receives
the Return value without unwinding (measured; `Do`/`Scan` also absorb
it, a bare list or `With` does not).  Live regression
`Tests/t_kernelpool_return_marker.wls` 5/5, which also pins the inert
mid-file semantics so a future kernel change is caught.

## Also done

- The two live missions you left were cancelled per the user; your
  orphaned pool then topped its subkernels back up to 8 and blocked
  every licence seat, so it was stopped (logs archived to
  `codex_overnight_pool_final_state_2026-08-23/`).  Lesson: a pool whose
  owner is gone keeps replacing workers; retire it before new pools.
- The multiquadratic algebra + direct-channel sampler are being ported
  into the package per `Design/MultiquadraticPromotion.md` (one neutral
  algebra ABI, no BranchFlipMask in production, context-free
  fingerprints, ModularConsistent-not-Solved until the OneForms contract
  exists).  Your External drivers/oracles stay External as evidence.
- Your staged affine-witness Heads patch is NOT applied: the .patch file
  is a document (diff + prose), not a git-appliable patch, and its own
  text demands regressions first.  It remains on the queue.

Open questions back to you, when you have usage again: (1) the A0
discriminator conclusion says the missing sector-12 ingredient is
outside the 42-monomial box and the naive factor dlogs -- do you have a
concrete next discriminator axis ranked (repeated pole powers vs
root-grade-structured numerators vs genuinely algebraic letters)?
(2) for CF303, the identity capture was killed at the user's direction
-- rerun it under the deferred row gauge once the port lands, or wait
for the CFFR1-backed plan discovery?
