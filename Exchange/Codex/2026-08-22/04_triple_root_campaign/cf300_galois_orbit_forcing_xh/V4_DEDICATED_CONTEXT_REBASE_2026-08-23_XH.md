# CF300 Galois-orbit forcing screen V4: dedicated-context rebase

Date: 2026-08-23

Status: frozen for central review/launch; production V4 was not launched by
the subagent. V1--V3 and all Global-symbol recovery candidates are
non-launchable.

## Runtime conclusion

Artifact hydration must not use `Global``. The package's public
`DRCAReadCompiledArtifact[file]` currently hardcodes both `$Context =
"Global`"` and `$ContextPath = {"System`", "Global`"}`. It is therefore
intentionally not called. V4 raw-loads the pinned preparation and cache in the
fixed, mission-owned context `CodexCF300GaloisOrbitArtifactV4`` and then calls
the public value validators in that same dynamic context.

The fixed context is explicitly on `$ContextPath` for the entire
fingerprint-sensitive computation: raw hydration, preparation/cache/assembly
validation, fingerprint recomputation, Galois census, ansatz rebind, and all
finite-field sampler calls. `Global`` is absent. The exact owned namespace is
`{v,w,x,y,eps}`; the symbols are precreated definition-free so later contexts
cannot capture unqualified artifact names. V4 verifies the five symbols remain
definition-free, restores the caller context/path, removes the fixed artifact
context with a literal `Remove` pattern, and verifies that no names remain.

Raw `Get` uses `Quiet[CheckAbort[Get[file], $Aborted]]`, not
`Quiet[Check[Get[file], $Failed]]`. The latter caused V1's valid preparation
value to be replaced by `$Failed` when any message was observed. The V2 live
gate showed that message-tolerant raw reads return both preparation and cache
as associations with zero messages in the corrected five-symbol context.

## Live gate evidence

The dedicated-context V2 gate ran centrally on poisoned kernel 144. It proved:

- the exact Global poison state and all three whole-state fingerprints were
  identical before and after;
- the exact dedicated namespace was `{v,w,x,y,eps}`, with all eight definition
  components empty before and after hydration;
- preparation, cache, and assembly public validators all returned `True`;
- stored and recomputed exact-channel fingerprint both equaled
  `fc5496c...e34d`;
- stored and recomputed compiled-form fingerprint both equaled
  `e9f7152a...039e7`;
- raw preparation/cache heads were `Association`, neither value was `$Failed`
  or `$Aborted`, and neither emitted a message;
- caller `$Context` and `$ContextPath` were restored.

The gate's only `EXIT2` condition was a diagnostic bug: `Context[regulator]`
inspected the held private carrier rather than its symbol value. Production V4
uses `Context[Evaluate[hydratedRegulator]]`. This correction is statically
pinned.

## Galois and subset certificate

The physics logic remains the exact V1 construction: preserve potential,
matrix-entry, derivative-component and epsilon provenance; generate all four
rank-two sign conjugates; verify dlog, closedness, involution and Klein-four
composition identities exactly; decompose and round-trip field channels; and
deduplicate only exact canonical channels.

The maximal orbit basis gives a valid column-subset implication for this
ansatz axis. Gauge columns and right-hand sides are unchanged, the old basis is
a literal prefix, and every appended letter supplies its own residue-column
block. Therefore, at any image where the maximal system is inconsistent,
every deletion subset is also inconsistent. V4 now distinguishes that exact
implication from the observed image results:

- `ColumnDeletionImplicationExact -> True`;
- `SubsetRejectionCertifiedByImage` records the actual per-image booleans;
- `EveryTestedImageRejectsEveryLetterSubset` is computed from the image
  results rather than asserted unconditionally.

This remains a certificate only for subsets of the four-sign closure of the
current forcing-entry dlogs at epsilon samples `{0,1,-1,2}`. Modular rejection
alone is not a lifted characteristic-zero obstruction certificate.

## Package-level findings for Fable

1. `DRCAReadCompiledArtifact` is not context-parametric; its hardcoded Global
   hydration makes it unsafe on a reused or poisoned kernel. A future package
   fix should separate raw loading from value validation or accept an explicit
   artifact context.
2. Wrapping artifact `Get` in `Quiet[Check[..., $Failed]]` discards valid return
   values whenever any message occurs. Use `CheckAbort` plus separate
   `$MessageList` telemetry, then let value validators decide validity.
3. `Context[carrier]` can report the private carrier symbol when the API holds
   its argument. Inspect the evaluated symbol value explicitly.
4. Wolfram's `Locked` attribute is irreversible for the kernel lifetime.
   Cleanup/recovery drivers cannot make kernel 144 reusable; quarantine and a
   managed restart are required.

## Central launch candidate

Only after assigning a clean non-144 main kernel and adding the mission to the
central watchdog:

```sh
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_galois_orbit_forcing_xh_v4 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/run_cf300_sector12_galois_orbit_forcing_screen_v4.wls \
  /home/maxzhang/factorization-and-loops \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v4.wl \
  2
```

V4 launches no Wolfram subkernels. The last argument grants two native FLINT
threads.

