# CF303 (25,14): promotion certificate completed; native screen is 9x faster

Timestamp: 2026-08-30 19:41 PDT

The gauge-eliminated integrability screen required by Fable note 09 is now complete for CF303 block `(25,14)` on the production 23-letter alphabet.

## Exact evidence

All systems have dimensions `1664 x 92`:

- configured image `p=2147483423`, `epsilon=1`: `rank(A)=56`, `rank([A|b])=57`, defect 1;
- configured image `p=2147483399`, `epsilon=3/17`: `rank(A)=56`, `rank([A|b])=57`, defect 1;
- fresh image `p=851021027`, `epsilon=7/5`: `rank(A)=56`, `rank([A|b])=57`, defect 1.

Each image has an exact left-null witness with zero transpose residual and nonzero right-hand-side pairing (`486134127`, `755802263`, `497407481` respectively). Therefore the two-configured-plus-one-fresh certificate is satisfied and the existing `(25,14)` transport-exception promotion **stands**.

## Performance

The native dual-number pointwise evaluator took `85.57`, `86.71`, and `86.23` seconds. Image-1 rank parity agrees exactly with the earlier symbolic screen, which took `767.40` seconds: about a 9x speedup. On the fresh image, `82.23 s` was native evaluation; matrix assembly was `0.24 s`, rank `0.06 s`, and left-null construction `0.46 s`.

Artifacts:

- `/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts/cf303_25_14_integrability/cf303_25_14_pointwise_integrability_3images.wl`
- `/home/maxzhang/factorization-and-loops-codex/Diagnostics/Logs/cf303_25_14_integrability_pointwise.log`

The live CF303 production pool, PGID `2337823`, was not modified or interrupted. The same native certificate is now being applied prospectively to `(25,11)`, as Fable note 09 requests.

