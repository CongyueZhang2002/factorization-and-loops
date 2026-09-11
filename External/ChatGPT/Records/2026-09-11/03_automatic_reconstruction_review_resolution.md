# Implementation response to automatic reconstruction review

This is Codex's implementation/validation record, not an additional Pro answer.
The original review came from **gpt-6-pro**, conversation
6aa43002-7ab8-83e8-a5b9-98673bb33f6f, request
9d4e0fd9-0c85-4048-90ae-8e2183422056.
See [the full review](02_automatic_reconstruction.md).
Repository: https://github.com/CongyueZhang2002/factorization-and-loops
The changes below are local and have not been pushed.

All five findings were addressed:

1. PlanningInputs.wl composes all production coordinate substitutions, including
   numerator-only symbols. Supported images are regulator independent and affine
   in endpoint coordinates; rational parameter denominators require a unit proof.
   Orders.wl rechecks the coordinate conditions rather than trusting a boolean.
   The x/(1+epsilon x), x -> 1/z counterexample is rejected for finite planning.
2. The physical source is bound explicitly to its endpoint frame using the AMFlow
   convention, unit representative factors, reference scale and physical
   coordinate identity. Unsupported conversions retain the coefficient exactly.
3. Explicit saved finite plans require current inputs. Changed order,
   normalization, endpoint data, source DE, coordinates or domain invalidates
   reuse before native jobs. The completed-job CLI accepts the current request.
4. Definition resolution is cached per master; unsupported masters do not block
   independent columns. Stale divisor inventories and invalid declarations fail
   instead of becoming unsupported-analysis fallbacks.
5. Dependency validation occurs before candidate selection; even an empty plan
   overwrites Plan.wl and contains current mathematical bindings.

Tests passed: 25 automatic planner assertions, 12 frame/coordinate assertions,
11 order-bound assertions, 10 mixed-assembly assertions, option forwarding and
14 Python divisor/trace tests. Card and direct-request actual source preparations
both pass, taking 109.395 s and 110.473 s respectively. Both discover outputs
20/22 and finite upper order 1. Accepted, card and direct regular/exact files are
byte-identical. The actual active-sector ingredients are p=0, b=0, nu=1, T=0;
the zero-exponent sector is structurally absent in the selected physical row.

The report's source/frame checks rely on the existing accepted cut-equivalence,
DE and physical-bound construction. They do not constitute a new proof of those
upstream results. General nonlinear coordinate maps and unconverted nonunit
physical frame relations remain explicit exact fallbacks.

Reports are under
Projects/ppHX_UU_NNLO/NNLO/qqp-qqp/Results/DoubleReal/Regeneration_2026-09-11.
The accepted 76,125,796-byte double-real artifact was preserved. No interpolation,
DE solve or AMFlow solve was repeated. These facts close the reported integration
gaps within the supported map and physical-normalization scope; this record
does not claim a second Pro review of the fixes.
