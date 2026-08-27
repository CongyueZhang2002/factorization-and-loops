# CF300 sector 12: Galois-orbit-closed forcing-letter screen

Date: 2026-08-23

Scope: External-only design and implementation. No package file, active mission
source, Wolfram kernel, pool mission, or unrelated process was changed or
signalled.

## Conclusion

The current 36-letter preparation is not a Galois-closed test of the forcing
alphabet. Its automatic construction takes the eight diagonal one-forms and
then dlogs of forcing entries at epsilon values `{0,1,-1,2}`. It deduplicates
the resulting one-forms but discards the potential, entry and epsilon
provenance, and it does not explicitly adjoin all sign conjugates in the
rank-two field.

The adjacent V1 driver closes exactly that gap without changing the equation
core, gauge denominator, or gauge support. It:

1. recovers every nonzero kinematics-dependent forcing potential with its
   derivative-component, matrix-entry and epsilon provenance;
2. generates masks `0,1,2,3` of the Klein-four Galois group;
3. checks the involution and full `mask1 XOR mask2` group law exactly;
4. proves both `potential * dlog(potential) = d(potential)` components and
   closedness exactly;
5. decomposes potentials and one-forms into the exact four-channel field ABI,
   round-trips them, and deduplicates by canonical exact field channels with a
   collision check;
6. proves that the identity-mask forcing basis is precisely the existing
   28-letter forcing suffix and preserves all 36 old letters as a literal
   prefix;
7. appends only genuinely new orbit letters, rebinds only the ansatz, and
   screens the maximal target over four finite-field images.

The driver is persistent-kernel-safe: all driver state lives in the unique
`CodexCF300GaloisOrbitForcingDriverV1`Private`` context, sources and artifacts
are pinned before load and rechecked after the screen, output is exclusive and
read-back verified, and the driver starts no subkernels or helper pools.

## Expected size and cost

The identity branch contains exactly 28 forcing dlogs. Four sign images give
at most 112 distinct forcing letters. With eight diagonal letters the maximal
basis therefore has at most 120 one-forms, at most 84 appended letters, 960
unknowns, and 31 sample points. These bounds are runtime contracts, not only
estimates.

The first 21 target points are reused for an exact common-point embedding of
the 624-column base system. A certified base left witness is scored only on the
appended residue columns. If every score vanishes, the maximal system is
rejected without full ranks. Otherwise, the driver runs independent FLINT
ranks of the full coefficient and augmented matrices.

## What the subset certificate proves

The maximal construction gives a valid exact column-subset embedding for this
axis of the ansatz:

- the gauge columns are unchanged;
- the old 36 one-forms are a prefix;
- each appended one-form contributes its own four residue columns;
- every selection of appended letters is obtained by deleting column blocks
  from the maximal system.

Consequently, if the maximal system is inconsistent at a finite-field image,
every subset of these orbit-closed forcing letters is inconsistent at the same
image. This implication is stronger than checking Galois-orbit unions only; it
also covers arbitrary subsets.

There are two important qualifications. First, this closes the orbit of the
package's current forcing-potential heuristic at epsilon samples
`{0,1,-1,2}`; it does not prove that no other algebraic potential or letter
exists. Second, modular image inconsistency is not alone a lifted
characteristic-zero obstruction certificate. A theorem-level obstruction
still needs a rational/exact left witness (or an independently justified
lifting bound). Multiple good-prime images are strong adversarial evidence,
not a substitute for that lift.

If the maximal target is inconsistent in all four images, this particular
letter axis is closed and the next search should change support, repeated pole
order, or the potential generator itself. If it is consistent, the next step
is reconstruction followed by exact residual verification.

## Exact centrally managed launch

Use the existing pool only; do not launch a standalone Wolfram kernel:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
/home/maxzhang/factorization-and-loops/Scripts/kpsubmit.sh \
  cf300_s12_galois_orbit_forcing_xh_v1 \
  /home/maxzhang/factorization-and-loops/External/CodexExchange/triple_root_2026-08-22/cf300_galois_orbit_forcing_xh/run_cf300_sector12_galois_orbit_forcing_screen_v1.wls \
  /home/maxzhang/factorization-and-loops \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v1.wl \
  2
```

The final `2` grants two native FLINT threads. The Wolfram part stays on one
pool subkernel and launches no Wolfram subkernels.

Fresh-output preconditions:

- the output path must not exist;
- add the mission to the central watchdog watchlist before submission;
- do not edit the driver or any pinned source while it is active.

## Pins and hashes

- driver: `ca6cae1937f7c9cf9f619010d779a1b6edd1cd4b153b5af182d9581c8a8e46c0`
- postmerge preparation: `6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4`
- compiled direct cache: `0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be`
- adversarial static test: `ecbc0397ff9fa5ac18a5143fc77d9feff27aa128201aa6dfdd615196053c578f`
- subset model test: `f6aa4181afe9f1e9b9a7dcfe4f6a89bec9fe32ae2961893a8bf15295fef609eb`

All dependent source and native hashes are embedded in the driver and checked
by the static test.

