# CF259 Q4 rank-three transfer gate

Prepared statically on 2026-08-23. No Wolfram/Mathematica kernel, native
solver, pool mission, or user process was launched, stopped, signalled, or
modified. No package file or pre-existing live artifact was edited.

## Ownership and nearest nonduplicative step

CF259 is not under active runtime ownership in the inspected snapshot. There
is no CF259 mission in the current pool and no CF259 captured recursive state,
physical strip input, preparation, prime shard, or reconstruction result. The
existing CF259/CF303 continuation directory contains only the static
assessment. CF303's physical identity-frame capture is live and CF300 V6e is
live, so neither is duplicated here.

The nearest bounded gap is the arithmetic transfer from CF300/CF303's third
square `1-4 x y` to CF259's genuinely different third square
`Q4=4 x+y^2`. The staged gate exercises the generic rank-three reconstruction
ABI over CF259's exact field

```
{lambda1, lambda3, Q4} = {
  (1-x-y)^2-4 x y,
  (1-x+y)^2+4 x y,
  4 x+y^2
}.
```

This is deliberately a **constructed oracle**, not a solved physical CF259
sector. It certifies that the generic external arithmetic/reconstruction path
survives the Q4 field change before a long physical CF259 capture consumes a
worker. The subsequent physical step remains a fresh standard CF259
identity-frame capture to its first typed stop, followed by a preparation made
from that exact captured strip. No numerical object from this constructed
oracle may be installed into a family state.

## Runtime gate

`TripleRootRank3CF259Oracle.wl` constructs a one-by-one rank-three identity
frame whose gauge has all eight root grades and all three support monomials.
The driver then requires:

1. exact CF259 radicands and family binding;
2. all seven nonempty square-class products nonsquare, hence rank three;
3. the exact Q4 radical derivative coefficients `2/Q4` and `y/Q4`;
4. a valid canonical preparation with 25 unknowns and 16 equations per point;
5. nonzero forcing in all eight grades;
6. exact reconstruction from three fresh `3 mod 4` training primes;
7. exact characteristic-zero channel residual zero;
8. unseen-prime verification for all eight root-sign masks; and
9. exact rejection of a corrupted Q4-bearing gauge coefficient.

The output is written atomically with `OverwriteTarget -> False`. Source drift,
an existing output, a non-pool kernel, nested kernels, or a nonzero helper
ceiling fails before mathematical work or output mutation.

## No-kernel adversarial evidence

Run:

```bash
python3 External/CodexExchange/triple_root_2026-08-22/cf259_q4_rank3_oracle_2026-08-23_xh/test_cf259_q4_rank3_oracle_static.py
```

Current result: **191/191 PASS**. The verifier checks the four pinned sources,
manifest/path-traversal/duplicate mutants, balanced Wolfram syntax, absence of
process controls/parallel launches/context-line truncation, the fresh output
contract, and an independent Python finite-field model. The latter covers 24
deterministic simultaneous split points over three primes, eight-channel
Hadamard evaluation/projection, extension multiplication, all-sign
permutations, single-branch corruption, and ramified-point rejection.

The additional dispatch mutants model wrong worker IDs `{None,0,24,141,144,
146,"145"}` and prove they fail before any target-level source-manifest read
or output-freshness probe. K145 alone advances to I/O. `kpsubmit.sh` still
performs its generated wrapper's held parse of the target itself before `Get`;
after the K145 guard, this gate loads all four pinned semantic sources with
`Get` before constructing the oracle. A separate held-parse mission is
therefore neither needed nor safe while K146 is reserved.

The exact square-class proof used independently by the verifier is also
structural. Viewed as primitive quadratics in `x`, `lambda1` and `lambda3`
have discriminants `16 y` and `-16 y`, so both are irreducible over `Q(y)`;
`Q4` is primitive linear in `x`. They are pairwise nonassociate. Every
nonempty product therefore contains at least one irreducible factor to odd
multiplicity and is nonsquare in `Q(x,y)`.

## Resource and launch contract

Required resources are exactly **the existing pool worker K145, zero Wolfram
helpers/subkernels, and zero native/FLINT workers**. The target has a hard
`$KernelID===145` guard before target-level I/O; an accidental K146 dispatch
fails immediately without reading the source manifest or probing/writing the
result path. The constructed system is only 25 unknowns and needs no CPU
allocation beyond K145. It is independent of the live CF300 and CF303
artifacts.

Because the current pool API does not expose a target-kernel argument, submit
only when central scheduling makes K145 the worker available for this mission
(and K146 remains occupied/reserved by its recapture gate). Do not weaken the
hard guard or repeatedly resubmit after a wrong-worker failure.

From `/home/maxzhang/factorization-and-loops`:

```bash
POOL=/tmp/codex-triple-root-20260823c.vx654S/pool \
FACET_TASK_BROKER_MAX_HELPERS=0 \
Scripts/kpsubmit.sh \
  cf259_q4_rank3_oracle_xh_v1 \
  External/CodexExchange/triple_root_2026-08-22/cf259_q4_rank3_oracle_2026-08-23_xh/run_cf259_q4_rank3_oracle_xh_v1.wls
```

Fresh output required before launch:

```
/tmp/codex-triple-root-20260823c.vx654S/cf259_q4_rank3_oracle_xh_v1.wl
```

Acceptance requires pool status `OK`, pool/result worker `K145`, result status
`CF259Q4Rank3OraclePassedV1`, exactly 12/12 runtime checks, preparation
`UnknownCount -> 25`, reconstruction `Rank -> 25`, `Nullity -> 0`, square-class
`Rank -> 3`, exact residual zero, and eight unseen-prime branch summaries. Any
source drift should be treated as a deliberate rebase event, not bypassed.

## Frozen hashes

* Oracle: `b431db4737dab33329eeea709d9999990522e0925a26c9974d14faa3b2512d71`
* Runtime driver: `0358739c35505923412fba0504dd9edce0eaf8daea142f7308ffcbbdeef9ee90`
* Static/adversarial verifier: `5e69088cb24a80c4fa1c6ce6cd999e6d9525ff58a9df2b842703100296884899`
* Source manifest: `dc64dfb52af72dcb387a0c4fdfaf83fa9a6b8de8d85fbad9e2a297bf5c88b271`
