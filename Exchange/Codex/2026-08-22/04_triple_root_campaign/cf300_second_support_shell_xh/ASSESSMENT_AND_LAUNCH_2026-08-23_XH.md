# CF300 sector 12: denominator closure and next ansatz axes

Date: 2026-08-23
Scope: External-only design and static implementation. No Wolfram kernel was
launched, no running process was signalled or modified, and no package or
active-mission source was edited.

## Final update: MAX5 closes square-free denominators; V3 fixes hydration

The centrally launched frozen V1 `MAX5` mission completed successfully on
kernel 144 in 249.9 seconds. All four images give

```text
rank(A) = 1716, rank([A|b]) = 1717, nullity(A) = 12,
```

so the maximal five-factor target is inconsistent in 4/4 images. Its
99-monomial dense support contains the exact convolution image of every one
of the 31 nonempty square-free subsets, and the residue columns are unchanged.
This result therefore closes every square-free mixture of the three forcing
and two contextual absent factors; separate contextual runs are now only
diagnostics, not open mathematics.

Runtime evidence:

- sealed MAX5 artifact:
  `/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_denom_max5_xh_v1.wl`,
  SHA-256
  `9167588092db9734dbd6f7540575790e4c4eed5eb1e8b4c8327f7854da85d5da`;
- MAX5 log SHA-256:
  `5db80d4d90391612b3d51c7417eab73893c45a4b6aec199fc54f49f8bee937c1`;
- every image has 1,585 nonzero old-witness scores, so the necessary witness
  screen passes but the independent two-rank test proves inconsistency.

Both private-context V2 missions were terminal at exit 68. This exposed a
second, independent persistent-kernel defect: the compiled artifact reader
hydrates its expression under `Global`` but validates it after returning to
the caller's `$ContextPath`. The artifact and assembly fingerprint helpers
hash `ToString[InputForm[value]]`; that string suppresses or prints `Global``
according to `$ContextPath`. Thus V2 changed the serialization of the same
held expressions and rejected a valid cache.

The frozen value-level probe reproduced this on reused kernel 144:

```text
stored/canonical ExactChannelForms fingerprint
  fc5496c7147f6678f32f652d6d2fcf2a5bea908dff32b9031a19d0da6d82e34d
isolated-context fingerprint
  e241f1f4d11a86c96e11cf132a2eb558407505348219f29828d2d0412c241a08
canonical raw/cache validators = True; canonical reader = Association;
isolated reader = $Failed.
```

Probe source SHA-256 is
`16ca166167ef23577e699c1649f2b5024807b587b6ab4033b2ed1e4b14d3cb34`;
the successful runtime log SHA-256 is
`46352636a8e81c495cc70d4384542370ab1fcfee90c0784b80c1b6b8f8c90cef`.

Adjacent V3 drivers preserve every V1 mathematical operation while combining
both required isolation layers:

- all driver helpers/state are in a cleared versioned private context;
- `Global`x`, `Global`y`, and `Global`eps` definitions and attributes are
  dynamically isolated and cleared with `Internal`InheritedBlock`;
- source loading, raw hydration, public validation, sampling, checkpoint
  validation and final validation all run with `System`` and `Global`` on a
  canonical path, retaining compatibility with the pinned legacy hashes;
- raw and validated reads must be identical, both public validators must
  succeed, preparation variables/regulator must be the canonical Global
  symbols, and value-level diagnostics print before fail-closed exits 68/69.

Frozen V3 SHA-256 values:

```text
contextual/MAX5 V3
e99415ab83965704e191774b165abce686f76668c501b51eecef802d401e845c
second-support-shell V3
8517c6ad53c914ae927352833892d542c9b467c92a13e9b39d480aedad5856df
```

V1 remains immutable evidence; V2 is terminal evidence and must not be
relaunched. Since MAX5 is complete, the useful next launch is the second
support shell:

```bash
ROOT=/home/maxzhang/factorization-and-loops
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool
DIR=$ROOT/External/CodexExchange/triple_root_2026-08-22/cf300_second_support_shell_xh
PREP=/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl
CACHE=/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl

POOL="$POOL" FACET_TASK_BROKER_MAX_HELPERS=0 \
  "$ROOT/Scripts/kpsubmit.sh" cf300_s12_second_support_shell_xh_v3 \
  "$DIR/run_cf300_sector12_second_support_shell_screen_v3.wls" \
  "$ROOT" "$PREP" "$CACHE" \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_second_support_shell_xh_v3.wl \
  2
```

For a short contextual regression only, use the contextual V3 source with
the same preparation/cache, the pinned census
`/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_denominator_census_xh_v5.wl`,
a fresh output path, selector `CTX:BOTH`, and final argument `2`.

## Result that fixes the next ordering

All seven nonempty products of the three forcing simple-pole factors

```text
x,
Q = 1 - 2 x + x^2 + 2 y + 2 x y + y^2,
1 - x
```

are now inconsistent in all four `(prime, epsilon)` images. The four newly
completed product artifacts have no survivors:

| selector | unknowns | rank A | rank [A|b] | nullity | result |
|---|---:|---:|---:|---:|---|
| `MASK:011` | 1168 | 1156 | 1157 | 12 | inconsistent in 4/4 |
| `MASK:101` | 816 | 804 | 805 | 12 | inconsistent in 4/4 |
| `MASK:110` | 1168 | 1156 | 1157 | 12 | inconsistent in 4/4 |
| `MASK:111` | 1296 | 1284 | 1285 | 12 | inconsistent in 4/4 |

The singleton artifacts have the same outcome. Every forcing candidate
passes the necessary left-witness score, but every promoted full system keeps
the same one-dimensional affine inconsistency. The exact ranks are stable at
both primes and both epsilon images.

This does **not** close the denominator axis. The audited census has two more
absent epsilon-free simple poles that occur only in the diagonal `E` channels:

```text
1 + x,
1 + x + y.
```

They were correctly excluded from the forcing-simple-pole candidate list, but
they remain possible regulator/resonance gauge poles. They must be tested
before blind numerator growth.

Product artifact SHA-256 values:

- `MASK:011`: `d9cdee63f757afc124324dbdb29afe50aa458c27e5ab43f14e9fdf9739679bc7`
- `MASK:101`: `58fecdbd08984f2a23b2e9eba9468ddafa96bc843cc724d27c50396ab456f45a`
- `MASK:110`: `f177735d223c46f8085d3e3d4e2f315613193e8d5367a4a258225a45e7a21a0c`
- `MASK:111`: `90b2fc707397c5df5e94f2eac4235bb4e84265f53e8bee8f9abb4a18f284572a`

## Exact contextual and closure sizes

The current denominator has bidegree `(4,5)`, there are 16 gauge channels per
support monomial, and the unchanged 36 one-forms contribute 144 residue
unknowns. With

```text
N = 16 S + 144,
points = Ceiling[(N + 32)/32],
```

the remaining targets are:

| denominator multiplier | denominator bidegree | support `S` | unknowns `N` | points |
|---|---:|---:|---:|---:|
| `1+x` | `(5,5)` | 36 | 720 | 24 |
| `1+x+y` | `(5,6)` | 42 | 816 | 27 |
| `(1+x)(1+x+y)` | `(6,6)` | 49 | 928 | 30 |
| all five absent factors (`MAX5`) | `(10,8)` | 99 | 1728 | 55 |

The recommended schedule is:

1. Run `MAX5` as the decisive denominator-closure mission.
2. Run `CTX:BOTH` in parallel if a diagnostic separating the contextual pair
   from forcing/contextual synergy is useful.
3. Singles are optional diagnostics after `CTX:BOTH`; they cannot strengthen
   a failed `MAX5` certificate.

## Why one failed MAX5 rejects every mixed square-free subset

Let the five absent factors be `f_1,...,f_5`, let

```text
D_MAX = D Product_i f_i,
D_S   = D Product_(i in S) f_i,
F_c   = D_MAX / D_S.
```

For every numerator `P` in a subset ansatz,

```text
P / D_S = (P F_c) / D_MAX.
```

The subset numerator support is the dense rectangle through the bidegree of
`D_S`. Multiplication by `F_c` can only produce exponents through the summed
bidegree `(10,8)`, which is exactly the dense MAX5 support. Multiplication by
a nonzero polynomial is injective over the rational polynomial ring. The
one-form list is unchanged, so every residue column is identical. Therefore
the full affine column space of every one of the 31 nonempty square-free
subsets embeds in the MAX5 column space.

At an accepted finite-field sample, `D_MAX` is nonzero, hence every factor of
`F_c` is nonzero and the same convolution embedding remains valid after
evaluation. The driver independently compares the base convolution projection
against a fresh base assembly on the exact same 21 points at every image. It
also creates an exact 31-record support-containment certificate before
sampling.

Consequently, if MAX5 has `rank[A|b] = rank[A] + 1`, no subset can be
consistent: removing columns cannot put `b` into the column space. This closes
all mixed contextual-plus-forcing **square-free** choices. It does not rule out
repeated pole powers, new numerator support at fixed `D`, or new one-forms.

## Historical V1/V2 contextual/MAX5 driver record

### Persistent-kernel incident and V2 hardening

The first `CTX:BOTH` launch of V1 reached `target_ready` and then failed on a
reused pool kernel before sampling. An unrelated earlier mission had left

```text
Global`checkpointFile = "/tmp/FeynFacet-solver-configuration-test-.../checkpoint.wl"
```

so the top-level definition `checkpointFile[image_Association] := ...` emitted
`SetDelayed::write`. It exited with code 74 and produced no output. The log
SHA-256 was
`7aca52de...` as reported by the pool owner. This is a persistent-kernel
namespace defect, not a mathematical result.

V1 remains immutable because the already-running MAX5 mission source-pinned
it. Adjacent V2 drivers place every helper and state symbol inside a versioned
package-private context. `BeginPackage` removes the Global context from
`$ContextPath`,
`ClearAll` resets only the versioned private namespace, and every explicit
exit runs `End[]; EndPackage[]` before `System`Exit`. Thus poisoned Global own
values, downvalues, and even `Protected`/`Locked` attributes are invisible,
while the pool kernel's prior context is restored on every normal exit.

That namespace fix was necessary but insufficient: removing `Global`` from
the context path broke the context-sensitive legacy artifact fingerprints.
Both V2 launches failed closed at exit 68 and V2 is **not safe to relaunch**.
Use the V3 hashes and commands in the final-update section above.

`run_cf300_sector12_contextual_denominator_closure_screen_v2.wls`:

- accepts exactly `CTX:PLUS_X`, `CTX:PLUS_XY`, `CTX:BOTH`, or `MAX5`;
- resolves the selector before the only target build;
- consumes `AllAbsentCandidates` from the pinned census and checks the exact
  five-factor catalog;
- uses the current post-merge preparation, compiled equation-core cache,
  ansatz-only rebind, corrected FLINT adapter, and certified left witness;
- validates the base convolution projection on common points;
- runs four images and independent native ranks of `A` and `[A|b]`;
- writes one sealed, non-overwriting checkpoint per image and resumes only
  from a fully source/artifact/ABI-bound checkpoint;
- writes the final sealed artifact by typed, read-back-verified atomic rename;
- contains no parallel-kernel, subprocess-control, deletion, signal, affinity,
  or process-management entry point.

Pinned inputs:

- post-merge preparation:
  `6d8d3e594927214c32c05f19686ab653b92e9c1dc8cf5692ab8e83e8752ae5d4`
- compiled cache:
  `0f85d336bb75b6e7b91057d80dc6845a2455f6ecfe868582d52528414e0440be`
- denominator census:
  `c4bd5ceaceba7738d6fbd99e26498967b0f2864c76025b9ba3d74332dfccf29a`

Terminal V2 evidence SHA-256 (do not launch):

```text
cf2486d18a2db16df02037751be996d857785de773a2aae147238508bdbd222f
```

Historical V2 commands (retained for provenance; do not execute):

```bash
ROOT=/home/maxzhang/factorization-and-loops
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool
DIR=$ROOT/External/CodexExchange/triple_root_2026-08-22/cf300_second_support_shell_xh
PREP=/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_rank2_extension_postmerge_xh_v1/preparation.wl
CACHE=/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_a0_direct_compile_cache_xh_v1.wl
CENSUS=/tmp/codex-triple-root-20260823c.vx654S/cf300_s12_denominator_census_xh_v5.wl

POOL="$POOL" FACET_TASK_BROKER_MAX_HELPERS=0 \
  "$ROOT/Scripts/kpsubmit.sh" cf300_s12_denom_max5_xh_v1 \
  "$DIR/run_cf300_sector12_contextual_denominator_closure_screen_v2.wls" \
  "$ROOT" "$PREP" "$CACHE" "$CENSUS" \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_denom_max5_xh_v1.wl \
  MAX5 2

POOL="$POOL" FACET_TASK_BROKER_MAX_HELPERS=0 \
  "$ROOT/Scripts/kpsubmit.sh" cf300_s12_denom_context_both_xh_v1 \
  "$DIR/run_cf300_sector12_contextual_denominator_closure_screen_v2.wls" \
  "$ROOT" "$PREP" "$CACHE" "$CENSUS" \
  /tmp/codex-triple-root-20260823c.vx654S/cf300_s12_denom_context_both_xh_v1.wl \
  CTX:BOTH 2
```

Each mission consumes one flat pool kernel. The final integer selects FLINT
threads, not Wolfram subkernels. The pool owner should lower it to one when
both missions would otherwise oversubscribe the available physical cores.

## After denominator closure: evidence-based next axes

### 1. Galois-orbit closure of forcing letters

The rank pattern strongly suggests that blind gauge columns are not touching
the obstruction: support and pole enlargements have repeatedly raised rank
one-for-one while preserving nullity 12 and affine defect one. The first
alphabet enlargement added only rational factor dlogs and also failed.

The current automatic one-form basis has 8 diagonal forms plus 28 forcing
dlogs obtained from four epsilon specializations. It is not closed under the
four sign conjugations of the active rank-two field. The economical next
alphabet screen is:

1. retain source provenance for each of the 28 forcing potentials;
2. generate its four Galois conjugates by sign action on field grades;
3. verify each exact `dlog(potential)` identity and deduplicate by exact field
   channels;
4. assemble one maximal orbit-closed target and project every orbit block;
5. test the maximal target first; if it is inconsistent, every suborbit is
   rejected by column inclusion; if it is consistent, minimize by orbit-wise
   deletion before reconstruction.

There are at most 112 forcing forms after closure. Keeping the 8 diagonal
forms gives at most 120 letters before exact deduplication:

| support | gauge unknowns | maximum residue unknowns | maximum total `N` | points |
|---|---:|---:|---:|---:|
| A0, `S=30` | 480 | 480 | 960 | 31 |
| AS, `S=42` | 672 | 480 | 1152 | 37 |
| second rectangle, `S=56` | 896 | 480 | 1376 | 44 |

Closing all 36 base forms, including the diagonal forms, is the looser
144-letter bound: `(N,points)=(1056,34)`, `(1248,40)`, and `(1472,47)` for
the same three supports.

### 2. Complete second numerator shell

An immediately launchable maximal support screen is staged in the
persistent-kernel-safe
`run_cf300_sector12_second_support_shell_screen_v3.wls`. Relative to the failed
AS rectangle `{0..5} x {0..6}`, it adds:

- x-edge: 7 monomials / 112 columns;
- y-edge: 6 monomials / 96 columns;
- corner: 1 monomial / 16 columns.

The maximal rectangle `{0..6} x {0..7}` has `S=56`, `N=1040`, and 34
points. It is a strict superset of all seven anisotropic combinations. One
maximal inconsistency therefore rejects every second-shell sub-support. The
driver assembles the maximal target once per image, independently reproduces
the AS matrix by column projection on the same 27 points, scores all three
blocks, and checkpoints four full two-rank results.

Exact anisotropic counts:

| blocks added to AS | support | unknowns | points |
|---|---:|---:|---:|
| x-edge | 49 | 928 | 30 |
| y-edge | 48 | 912 | 30 |
| corner | 43 | 832 | 27 |
| x+y | 55 | 1024 | 33 |
| x+corner | 50 | 944 | 31 |
| y+corner | 49 | 928 | 30 |
| all three | 56 | 1040 | 34 |

Superseded V2 driver SHA-256 (do not launch):

```text
321d8a76bfafaefe3eec66d729dc1596549b766caa5a05bfc8376e736a2ff9fb
```

Because the denominator loophole is real and cheap to close, this support
mission should start only after, or alongside spare capacity not needed by,
MAX5.

### 3. Lower-value axes

- **Third root / extra gauge grades:** not indicated. This block's equation is
  over the complete four-grade basis for active roots `{2,3}`. Adjoining an
  inactive independent root without a new letter or pole orbit cannot repair
  an inconsistency: Galois averaging returns a solution over the current
  subfield.
- **Repeated pole powers:** MAX5 closes square-free factors only. Higher powers
  remain logically possible, but the forcing higher-order poles and the
  epsilon-dependent factor are already present at their required powers. A
  repeated contextual power should follow a local residue/resonance bound,
  not a blind exponent cube.
- **Higher epsilon interpolation degree:** irrelevant to fixed-image affine
  consistency; coefficients are already free at each epsilon image.

## Package/addon recommendations

### Proven fingerprint-serialization bug

The runtime probe proves that the direct-channel artifact ABI is accidentally
dependent on the caller's `$ContextPath`. Both
`DirectRootChannelAssembler.wl` and
`DirectRootChannelCompiledArtifact.wl` use
`Hash[ToString[InputForm[value]], ...]` for semantic fingerprints. Since
`InputForm` shortens symbol names using `$ContextPath`, a valid artifact can
fail validation merely because its reader is called from `BeginPackage` or a
persistent kernel with a different path. `DRCAReadCompiledArtifact` makes the
problem sharper: its internal `Get` is canonicalized, but its subsequent
`DRCACompiledArtifactValidQ` call is outside that `Block`.

Backward-compatible minimal fix:

1. centralize the serializer used by every `drcaStableFingerprint` and
   `drcacFingerprint` call;
2. for the current ABI, evaluate `ToString[InputForm[value]]` under exactly
   ``$Context="Global`"`` and
   ``$ContextPath={"System`","Global`"}`` so existing
   hashes remain valid;
3. run the public artifact and assembly validators under that same fixed
   serializer scope, including the validator inside `DRCAReadCompiledArtifact`;
4. add an explicit `FingerprintSerializationABI` tag to future artifacts;
5. regress fresh-Global, private-package, and poisoned reused-kernel contexts
   and require byte-identical fingerprints plus identical validator results.

A later ABI may use an explicitly context-qualified symbolic encoder instead
of pretty-printed `InputForm`, but that requires deliberate cache migration.
The V3 drivers are a source-pinned compatibility workaround, not a substitute
for this central fix.

### One-form completeness metadata

One External prototype limitation must also be fixed before an alphabet
inconsistency is called an obstruction:

`TRCandidateOneFormBasis` stores the 36 resulting one-forms and only aggregate
counts. It discards the 28 forcing potentials, their entry/epsilon provenance,
their exact dlog identities, and whether their Galois orbits are complete.
Therefore the present alphabet is a heuristic ansatz, not a completeness
certificate.

Recommended additive fix:

```text
OneFormMetadata -> {
  PotentialRecords,
  SourceEntryAndEpsilon,
  PotentialFingerprint,
  DLogFingerprint,
  ExactDLogVerified,
  GaloisOrbitID,
  GaloisOrbitComplete,
  NormPotentialFingerprint
}
```

The solver/report status should distinguish `AnsatzInconsistent` from a true
`EpsFormObstruction` unless denominator, support, and one-form completeness
certificates are all present.

## Static verification

`test_next_ansatz_drivers_static.sh` passed 93/93 checks. It covers source and
artifact pins, selector-before-build behavior, exact MAX5 counts, the 31-subset
containment contract, common-point projection, sealed checkpoints, typed final
commit, forbidden process-control primitives, nested-comment/string-aware
delimiter and context-token guards, independent count arithmetic, shell
syntax, and whitespace. The added no-kernel namespace test passed 60/60 and
proves exact mechanical equivalence of each V2 to its V1 except for private
package isolation and context-restoring exits; it additionally audits V3's
canonical hydration scope, raw/validated-reader equality, public validators,
value diagnostics, and fail-closed gates. Its adversarial fixture poisons the
Global-context `checkpointFile` with a String and supplies stale own values,
downvalues, `Protected`, `Locked`, and `Listable` attributes, including poisoned
`x`, `y`, and `eps`.

`verify_ansatz_counts.py` independently passed its support, denominator,
orbit-bound, inclusion, unknown, and sample-count assertions.

Current file hashes:

| file | SHA-256 |
|---|---|
| contextual/MAX5 V1 evidence | `f72e238e5d937ecf71f95f0b9bfce70926df4c1e60aa95a1b71f0ebb6748dee0` |
| contextual/MAX5 V2 terminal evidence | `cf2486d18a2db16df02037751be996d857785de773a2aae147238508bdbd222f` |
| contextual/MAX5 V3 launch source | `e99415ab83965704e191774b165abce686f76668c501b51eecef802d401e845c` |
| second-shell V1 evidence | `b698391d77dcfffa01ebc389a3831fa4ccf9e767210d1547bdbb6b90f1bd15b8` |
| second-shell V2 terminal evidence | `321d8a76bfafaefe3eec66d729dc1596549b766caa5a05bfc8376e736a2ff9fb` |
| second-shell V3 launch source | `8517c6ad53c914ae927352833892d542c9b467c92a13e9b39d480aedad5856df` |
| hydration context probe | `16ca166167ef23577e699c1649f2b5024807b587b6ab4033b2ed1e4b14d3cb34` |
| reused-kernel poison fixture | `a09c4de997dfe45b4ac09cdc56807952d00f5406de296bbae6ea93e77e63ce2a` |
| namespace/hydration static test | `76c7402d5850357cc0bbbfa1d1f7c7b6547f94950f43f08fedb49435a4b587f8` |
| independent count model | `ee8814a677ec64450926c3517b0862e56e4ae8a9931517eea390b12282aae88b` |
| static test | `33c54a9a7faae3d6a2334655fc84149f2d72a54f24d5977a51179afaceb08ff1` |
| bundled static result | `53900c798bc88c363f35d625b67027b2893352e6a95ff138cca8c91e837cb9c5` |
