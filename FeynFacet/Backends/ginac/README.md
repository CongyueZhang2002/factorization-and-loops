# Optional GiNaC GPL evaluation

Build on Linux/WSL with a C++17 compiler, pkg-config, GiNaC and CLN development
packages. On Ubuntu the relevant packages are `g++ pkg-config libginac-dev`.

```sh
bash FeynFacet/Backends/ginac/build.sh
```

The build writes `bin/evaluate_gpl` atomically; this generated binary is ignored
by git. The tested version is GiNaC 1.8.7. No eMPL support is claimed.

The standalone Wolfram reader calls this executable in batches, once per
working-precision pass. Each process uses one core. Independent evaluation
requests use the existing batch driver, with up to eight workers. Input is
explicit GPL words, not differential equations or deferred generators.

The adapter follows GiNaC's `G(letters, endpoint)` convention, equivalent to
`G[{a1,...,an},z]` with kernels `dt/(t-ai)`. The Wolfram caller refuses
nonzero letters on the straight contour, source singularities, and source
principal-log cut crossings. It does not select a physical i0 prescription.

Kinematic expressions and substitutions must be exact in this first version;
rational numbers and exact algebraic numbers are supported. Numerical boundary
coefficients are accepted with their supplied precision. Increasing working
precision and checking the assembled result provides empirical convergence
evidence, not a rigorous error enclosure.

See [the general interface and measured scope](../../../Design/GPLImplementation_2026-09-06.md).
