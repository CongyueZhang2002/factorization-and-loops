# V6e exact-channel rebind prototype assessment and benchmark plan

Date: 2026-08-23

## Scope and disposition

An adjacent V6e prototype is implemented without changing any active V6d
source, package file, worker, process, or output.  No Wolfram kernel was
launched while building or testing it.

The prototype is ready for actual held parsing and a fresh CF300 benchmark,
but it is not yet runtime-certified and no speedup is claimed.  It must remain
outside the package until the runtime gates below pass.

Frozen prototype sources:

- `DirectRootChannelExactOneFormRebindV6e.wl`
  - SHA256 `2fea1e07c691ade811162f47db1d71d82a385dd01d07afd20beaa3aa0262f2e8`
- `V6E_DRIVER_INTEGRATION_BLOCK.wl`
  - SHA256 `7ea7a437cd25a440e4713040d0882947977a71f092510f0c02c940d8d02f0dbe`
  - pins the helper hash above exactly

## Concrete V6d baseline

The successful V6d run is now the immutable comparison point:

- artifact SHA256:
  `20823fde76827c8d8a9db66e617eacde276c9bdac0871ccdba80aad1d5aeb1cf`
- wall time: `1791.863386 s`
- orbit census: `270.577244 s`
- exact-channel rebind: `485.843061 s`
- maximal assembly fingerprint:
  `32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7`
- all four images inconsistent with ranks `888/889`, nullity `24`

Only the rebind interval is an apples-to-apples primary performance metric.
Wall time includes the common census and downstream image screens.

## What V6e changes

The V6d orbit records already contain, in matching order, each exact channel,
its canonical expanded `{numerator,denominator}` pair, and the channel
fingerprint.  V6e consumes those records directly.

The helper performs the following fail-closed pipeline:

1. validate the base assembly once and the target preparation once;
2. require the target to be a strict one-form superset with an exact base
   prefix;
3. retain the 144 exact channel-to-target composition/equality checks;
4. flatten the expected `72 x 2 x 4 = 576` rational leaves without reordering;
5. key canonical pairs by SHA256, require exact `SameQ` inside every hash group,
   and reject any collision;
6. require each pair to be the reduced idempotent `Together` pair, to have exact
   rational polynomial coefficients and a nonzero denominator, and to equal
   its exact channel;
7. compile each distinct pair once with the source-pinned polynomial compiler,
   then map the compiled leaf back to all 576 positions;
8. recompile five deterministic leaves with the legacy rational compiler and
   require exact `SameQ` output;
9. join only the one-form suffix, preserving all other exact and compiled form
   fields exactly;
10. compute each legacy whole fingerprint once for downstream compatibility;
11. run exactly one legacy whole-result validation oracle;
12. build a source-pinned specialized suffix seal and validate it; and
13. let the driver consume the seal nonce once instead of running a second
   whole-result validator.

The specialized validator does not reserialize the immutable equation cores.
It proves structural equality to the already validated base, hashes only the
changed suffix/prefix/layout components, checks the exact certificate key set,
and binds the one-time nonce, source hashes, target ABI, counts and column
layout.

## Telemetry

V6e records seconds and `MemoryInUse` before/after for:

- base validation
- target ABI validation
- suffix composition/equality
- canonical leaf grouping
- canonical leaf validation
- unique leaf compilation
- deterministic legacy compiler audit
- exact/compiled joins
- legacy fingerprint construction
- one legacy whole-result oracle
- specialized seal construction
- specialized seal self-validation

It also records raw/unique/reuse/compile/collision counts, expression byte
counts, and the `InputForm` character counts already produced during unavoidable
legacy fingerprint construction.  These fields localize the remaining cost;
they are not themselves evidence of a speedup.

## No-kernel validation completed

- structural/static source gate: `65/65` passed
- independent adversarial model: `57/57` passed
- randomized memo fixtures: `800/800` matched the legacy compile order and
  output

The adversarial suite covers the collision, channel, component, grade,
numerator, denominator, zero-denominator, stale-cache, core, prefix, target ABI,
count, layout, source, certificate and replay mutants required by the V6e plan.

## Mandatory actual Wolfram gates

Before any launch of a V6e CF300 driver:

1. verify this directory's manifest and the two frozen hashes above;
2. run the existing held-parse diagnostic on the helper and integration block;
3. require `SyntaxLength[text] == StringLength[text]`, a `HoldComplete` parse,
   and zero parser messages for both;
4. build a new V6e driver file and fresh output path; do not edit V6d;
5. pin the V6e helper hash in that driver;
6. require the output target not to exist and retain atomic
   `OverwriteTarget -> False` behavior.

For the first full CF300 V6e run, require all of the following:

- the V6d census/character/cardinality/provenance/closure checks remain green;
- appended record order equals `AdditionalOneFormChannels` and the target suffix
  exactly;
- `RawLeafCount == 576`;
- `RawLeafCount == UniqueCompiledLeafCount + CompileCacheReuseCount`;
- `CompileCount == UniqueCompiledLeafCount`;
- `CollisionGroupCount == 0`;
- the five-leaf legacy compiler audit passes exactly;
- `LegacyWholeResultOracleCount == 1`;
- the specialized seal passes and its first driver consumption is `True`;
- a separate fresh fixture obtains nonce-consumption results `{True,False}`;
- source hashes before and after are identical;
- the maximal assembly fingerprint is exactly
  `32f57d91b05f5ef5eedd25d1c4674af8fa877a6d0e8fc35fbfd0865586fc5ab7`;
- exact forms, compiled forms, shapes, column layout and matrix prefixes are
  identical to V6d;
- all four image results retain ranks `888/889`, nullity `24`, and identical
  inconsistency/subset certificates; and
- no successful result contains `$Failed`, `Missing`, an unresolved
  certificate field, or a non-Boolean certificate value.

## Benchmark acceptance

Use V6d `485.843061 s` as the primary cold rebind baseline.  Report every V6e
phase, not only the total.  A first successful run establishes correctness and
the observed unique-leaf count.  Then run at least one same-input repeat under
the same worker/pinning conditions to distinguish cold parsing/cache effects
from the rebind change.

Do not declare the optimization finished unless:

1. both full runs pass every correctness gate;
2. the V6e rebind median is below `485.843061 s`;
3. the improvement is explained by the measured compile, fingerprint, oracle
   and seal phases rather than by a different census or worker allocation; and
4. the remaining dominant phase has been inspected for the next safe adjacent
   optimization.

If `UniqueCompiledLeafCount == 576`, leaf memoization provides no compile reuse
on CF300 and should not be marketed as a speedup; the phase timings will still
quantify the value of removing the duplicate whole-result validator.  If pair
validation dominates, the next step is the already planned upstream lineage
seal, not weakening the exact pair/channel checks.

## Deferred work

- upstream orbit-lineage seal to remove the 144 legacy composition/equality
  reductions after an independent equivalence run;
- source-pinned already-validated sampling token to remove repeated sample-time
  whole-assembly validation;
- component/Merkle fingerprint ABI with the legacy fingerprint retained during
  transition.

None of those deferred changes is included or implied by this prototype.
