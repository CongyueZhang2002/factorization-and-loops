# CF300 sector-12 exact Q(eps) left-obstruction lift

## Status

This adjacent external bundle is frozen as a source-level, fail-closed implementation draft. It does **not** claim that CF300 sector 12 has been certified. The actual run must wait for the V6e I00 prerequisite capture, a central Wolfram held-parse gate, and the bounded runtime driver. No package file, V6d artifact, or live output was edited.

No Wolfram kernel, subprocess pool, or native solve was launched while building or testing this bundle. The no-kernel tests passed 111/111 static checks and 97/97 finite-field/adversarial checks. An independent hash-bound review found no concrete correctness or syntax blocker in the final modular source.

## Frozen inputs and sources

- Frozen V6d artifact: `/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_galois_orbit_forcing_xh_v6d.wl`, SHA256 `20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf`.
- V6d orbit core SHA256: `7a6fa652def2eed1c7315e6c0260ca9c275e7d8c8a06221f22abc8c7a2b311ed`.
- Maximal-assembly fingerprint: `32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7`.
- Exact helper SHA256: `e055bb88e0884c33edb51c3b52f26943b93e69f27317caead8b0d462b580325b`.
- Modular reconstruction SHA256: `0c50fe48adc4bd28181e0954a2191a8c49452779a134405e1c27b6cd27def1ce`.
- Driver SHA256: `446da75743811e2c3d1e2a438205a74786883fa7a4363304c37d911685bfa174`.
- Pinned package finite-field source SHA256: `8721847e5964986a952bb52c2551ed1099b24b255999344f38c5efa848cf4c70`.
- Pinned CFFA4 FLINT binary SHA256: `e2d7d3ee375f712a20c62b31c4510b9cdac2fa13f7cce5256bb05733bee9d46b`.

## What the design does

1. The driver reads the frozen V6d artifact in a dedicated context and extracts its requirements before loading FACET. V6d stores only fingerprints, not the 30 points or the full pivot/free/independent-row arrays, so a missing capture terminates with `CF300ExactQepsWitnessPrerequisiteCaptureRequiredV1`; the driver never rediscovers a plan.
2. The capture validator requires the ordered I00 residues, all six stable plan arrays with their frozen hashes, the maximal assembly, and 60 ordered coordinate reduction records. Every point coordinate is the deterministic minimum-height rational lift modulo 10007, and the captured plan must be revalidated at `eps=1/21`.
3. At each modular image the code selects the pinned 889-by-889 augmented block, solves its transpose against the RHS-pivot unit through the source-pinned CFFA4 FLINT backend, and verifies all 912 coefficient residuals plus `y.b=1` before interpolation.
4. Rational interpolation uses one type-(D,D) modular `NullSpace` per nonzero coordinate/stage, not a scan over every numerator/denominator split. It gcd-reduces one basis pair, validates all `2D+1` images, requires nonvanishing denominators and total degree at most D, and checks the exact kernel-nullity formula. Lower-stage pairs are cached but revalidated on every enlarged image set; cache hits report zero new kernel/GCD work.
5. The staged exploratory ladder is `{8,16,24,32,48,64,80}` with image reuse. Degree 80 is not presented as a theorem-level bound. If the first qualified prime exhausts 161 images at that cap, the run stops rather than replaying structurally identical failures; its typed failure retains image summaries, failed-coordinate fingerprints, timings, and degree evidence for a targeted extension.
6. The first accepted prime cannot seed the degree profile. Two matching profiles are required within the first three qualified primes; an AAB/ABA/ABB minority is retained as a rejected diagnostic, while ABC fails closed.
7. Training grows adaptively from 4 to at most 12 accepted primes. CRT/rational reconstruction must be stable after dropping the last prime. No independent coefficient-height theorem is claimed: qualification comes from prefix stability, exact re-reduction to every training image, two unseen primes at seven regulator values, and the terminal characteristic-zero identities.
8. Held-out regulator values `{163,167,173,179,181,191,193}` are disjoint from the entire construction set both exactly and modulo each held-out prime; distinctness and regulator exceptionality are checked before any native call.
9. The terminal helper assembles the exact system over `Q(eps)`, installs the reconstructed support only on the pinned independent rows, and verifies all 912 cleared-denominator left identities and the exact right pairing `y.b=1`. It contains no 889-by-889 symbolic `LinearSolve`.

## Bounded work and diagnostics

- At most 18 prime candidates, 161 construction epsilon images per training prime, 7 held-out images per held-out prime, and a conservative hard ceiling of 3024 native solve attempts.
- At most 6223 interpolation coordinate/kernel/GCD attempts per training prime and 99568 over 16 possible training candidates. Zero coordinates use no kernel. Cache revalidation is separately bounded by 5334 per prime and 85344 over training.
- `RunProcess` must return an association; nonzero exit, stderr/stdout, missing output, malformed magic/header, truncated payload, and a bad full residual all produce typed failures.
- Prime-static point failures stop the epsilon loop for that prime. Duplicate or exceptional epsilon residues are rejected before assembly.

## Defects explicitly covered

- V6d's recorded 288-column witness score contains indices `0..288` because of head traversal. These indices are never consumed; every source uses explicit 1-based `Pick` masks and contains no runtime `Position[..., Heads->True]` path.
- The earlier naive symbolic 889-by-889 `Q(eps)` solve is absent.
- Generated-source duplicate assignment/terminal-association mutants are rejected.
- A context-qualified symbol may not be split immediately after its context backtick; every selected `.wl`/`.wls` source is scanned for that lexical failure class.
- Cache-hit work counters are stage-local zeros, so actual kernel/GCD telemetry does not count origin work twice.

## Required runtime gates

1. Obtain the atomic V6e capture with status `CF300V6dExactLiftPrerequisiteV1` and pass `EQWPrerequisiteValidQ` under the frozen helper/schema hashes.
2. Run the central held-parse/source-load gate on the exact frozen hashes. This was intentionally not done here because the assignment prohibited launching a Wolfram kernel.
3. Launch the pinned driver only with a fresh output path. A success claim requires final status `CF300Sector12ExactQepsLeftObstructionCertifiedV1`; any other status is diagnostic, not certification.

The manifest and no-kernel test transcript in this directory bind the delivered files.
