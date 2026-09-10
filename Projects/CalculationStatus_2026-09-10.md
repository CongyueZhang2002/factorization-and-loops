# Calculation status — 2026-09-10

Times are recorded complete production-driver runtimes per channel, including
pole checks and writing the result, but excluding independent reference checks
and initial kernel/package startup. They are historical measurements, not a
fresh benchmark of today's code. N/A means a complete per-channel time was
not recorded; partial reruns and recovery totals are not substituted.

Sizes are actual final Result.wl disk sizes, in decimal kB (1 kB = 1000 bytes),
including result metadata and stored epsilon coefficients, excluding intermediates.
Drell–Yan and SIDIS NLO files retain epsilon^0 and epsilon^1; ppHX NLO and
SIDIS NNLO final files retain epsilon^0.

A green tick means an independent full finite coefficient comparison passed.
Verification N/A means no such external comparison is retained; it does not
mean that internal tests failed or that no literature result exists.
LL/TT in–in polarizes both incoming partons; transfer polarizes one incoming
parton and the observed outgoing parton. SIDIS channels list incoming → observed
parton; the electromagnetic current is implicit.

| Process | Order | Channel | Total time/channel | Final size/channel | Verification | Source |
|---|---|---|---:|---:|:---:|---|
| pp→hX UU | NLO | qq′ → q+X | 2.54 min | 22.9 kB | ✅ | [INCNLO](https://lapth.cnrs.fr/PHOX_FAMILY/readme_inc.html) |
| pp→hX UU | NLO | q q̄ → q′+X | 2.43 min | 25.6 kB | ✅ | [INCNLO](https://lapth.cnrs.fr/PHOX_FAMILY/readme_inc.html) |
| pp→hX UU | NLO | qg → q+X | N/A | 143.3 kB | ✅ | [INCNLO](https://lapth.cnrs.fr/PHOX_FAMILY/readme_inc.html) |
| pp→hX UU | NLO | qg → g+X | N/A | 71.9 kB | ✅ | [INCNLO](https://lapth.cnrs.fr/PHOX_FAMILY/readme_inc.html) |
| pp→hX LL (in–in) | NLO | qq′ → q+X | 2.80 min | 16.9 kB | ✅ | [Navis](https://github.com/QCDLab/navis) |
| pp→hX LL (in–in) | NLO | q q̄ → q′+X | 2.65 min | 25.7 kB | ✅ | [Navis](https://github.com/QCDLab/navis) |
| pp→hX LL (in–in) | NLO | qg → q+X | N/A | 76.3 kB | ✅ | [Navis](https://github.com/QCDLab/navis) |
| pp→hX LL (in–in) | NLO | qg → g+X | N/A | 47.8 kB | ✅ | [Navis](https://github.com/QCDLab/navis) |
| pp→hX TT (in–in) | NLO | qq′ → q+X | 26.0 s | 1.7 kB | N/A | N/A |
| pp→hX LL (transfer) | NLO | qq′ → q+X | 2.89 min | 22.9 kB | N/A | N/A |
| pp→hX TT (transfer) | NLO | qq′ → q+X | 13.57 min | 20.5 kB | N/A | N/A |
| Drell–Yan UU | NLO | q q̄ | 21.5 s | 4.4 kB | ✅ | [1307.6925](https://arxiv.org/abs/1307.6925) |
| Drell–Yan UU | NLO | q̄ q | 19.3 s | 4.4 kB | ✅ | [1307.6925](https://arxiv.org/abs/1307.6925) |
| Drell–Yan UU | NLO | q g | 8.5 s | 3.0 kB | ✅ | [1307.6925](https://arxiv.org/abs/1307.6925) |
| Drell–Yan UU | NLO | g q | 5.7 s | 3.0 kB | ✅ | [1307.6925](https://arxiv.org/abs/1307.6925) |
| Drell–Yan UU | NLO | q̄ g | 6.1 s | 3.0 kB | ✅ | [1307.6925](https://arxiv.org/abs/1307.6925) |
| Drell–Yan UU | NLO | g q̄ | 5.9 s | 3.0 kB | ✅ | [1307.6925](https://arxiv.org/abs/1307.6925) |
| SIDIS UU | NLO | q → g | 16.8 s | 5.6 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NLO | g → q | 7.7 s | 4.9 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NLO | q̄ → g | 18.5 s | 5.6 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NLO | g → q̄ | 9.5 s | 4.9 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NLO | q → q | 26.7 s | 10.4 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NLO | q̄ → q̄ | 25.0 s | 10.4 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS LL | NLO | q → g | 18.6 s | 5.2 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NLO | g → q | 6.5 s | 4.2 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NLO | q̄ → g | 17.2 s | 5.2 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NLO | g → q̄ | 4.8 s | 4.2 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NLO | q → q | 21.5 s | 9.8 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NLO | q̄ → q̄ | 23.2 s | 9.8 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS UU | NNLO | q → q̄ | N/A | 159.8 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | q̄ → q | N/A | 159.8 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | q → g | N/A | 208.7 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | g → q | N/A | 227.0 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | q̄ → g | N/A | 208.7 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | g → q̄ | N/A | 227.0 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | q → q | N/A | 850.5 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | q̄ → q̄ | N/A | 850.5 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | q → q′ | N/A | 106.5 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | q → q̄′ | N/A | 106.6 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | q̄ → q′ | N/A | 106.6 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | q̄ → q̄′ | N/A | 106.5 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS UU | NNLO | g → g | N/A | 95.9 kB | ✅ | [2401.16281](https://arxiv.org/abs/2401.16281v2) |
| SIDIS LL | NNLO | q → q̄ | N/A | 93.6 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | q̄ → q | N/A | 93.6 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | q → g | N/A | 135.9 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | g → q | N/A | 119.2 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | q̄ → g | N/A | 136.0 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | g → q̄ | N/A | 119.2 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | q → q | N/A | 387.3 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | q̄ → q̄ | N/A | 387.3 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | q → q′ | N/A | 60.4 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | q → q̄′ | N/A | 60.4 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | q̄ → q′ | N/A | 60.4 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | q̄ → q̄′ | N/A | 60.4 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |
| SIDIS LL | NNLO | g → g | N/A | 48.3 kB | ✅ | [2404.08597](https://arxiv.org/abs/2404.08597v3) |

SIDIS NNLO uses a shared master-integral calculation and endpoint analysis;
there is no defensible standalone total runtime for each channel. The final
26 files total 5,176,150 bytes. All NNLO delta/plus/regular coefficients were
compared at five parameter points, with about 40-digit agreement. DY and
SIDIS NLO comparisons are symbolic; SIDIS NLO literature coverage is the
finite coefficient, while DY also checks epsilon^1.

Navis comparisons include both qg observed tags at ten points. Agreement
with Navis does not authenticate an original author-code archive. The
incoming-LL qq-prime result additionally has an exact comparison with the
user-supplied Vogelsang Mathematica file.

The incoming-TT qq-prime result is exactly zero and has internal amplitude
and nonzero-control tests; it has no separate external finite-reference
comparison. LL/TT spin-transfer rows likewise have no retained full external
comparison.

The older ppHX UU NNLO work is a double-real contribution only, not a
complete NNLO hard function. Its retained BareDoubleRealDistributions.wxf
is 317,049,147 bytes. Master-integral checks against AMFlow do not constitute
a verification of a complete NNLO hard function.

## Lower-order dependencies

The following 31 LO outputs are also present. They are lower-order dependency
files, not separately timed full benchmark runs. No independent full-reference
tick is inferred from their use in a successfully verified NLO calculation.

| Process | Order | Channel | Total time/channel | Final size/channel | Verification | Source |
|---|---|---|---:|---:|:---:|---|
| pp→hX UU | LO | gg → gg | N/A | 6.5 kB | N/A | N/A |
| pp→hX UU | LO | gg → q q̄ | N/A | 6.9 kB | N/A | N/A |
| pp→hX UU | LO | qg → qg | N/A | 6.8 kB | N/A | N/A |
| pp→hX UU | LO | q q̄ → q′q̄′ | N/A | 6.7 kB | N/A | N/A |
| pp→hX UU | LO | qq′ → qq′ | N/A | 6.7 kB | N/A | N/A |
| pp→hX UU | LO | q q̄′ → q q̄′ | N/A | 6.7 kB | N/A | N/A |
| pp→hX UU | LO | qg → gq | N/A | 6.8 kB | N/A | N/A |
| pp→hX UU | LO | qq → qq | N/A | 7.5 kB | N/A | N/A |
| pp→hX UU | LO | q q̄ → gg | N/A | 6.9 kB | N/A | N/A |
| pp→hX UU | LO | q q̄ → q q̄ | N/A | 7.5 kB | N/A | N/A |
| pp→hX LL (in–in) | LO | gg → gg | N/A | 6.8 kB | N/A | N/A |
| pp→hX LL (in–in) | LO | gg → q q̄ | N/A | 6.8 kB | N/A | N/A |
| pp→hX LL (in–in) | LO | qg → qg | N/A | 6.7 kB | N/A | N/A |
| pp→hX LL (in–in) | LO | q q̄ → q′q̄′ | N/A | 6.7 kB | N/A | N/A |
| pp→hX LL (in–in) | LO | qq′ → qq′ | N/A | 6.6 kB | N/A | N/A |
| pp→hX LL (in–in) | LO | q q̄′ → q q̄′ | N/A | 6.6 kB | N/A | N/A |
| pp→hX LL (in–in) | LO | qg → gq | N/A | 6.8 kB | N/A | N/A |
| pp→hX LL (in–in) | LO | qq → qq | N/A | 7.0 kB | N/A | N/A |
| pp→hX LL (in–in) | LO | q q̄ → gg | N/A | 7.0 kB | N/A | N/A |
| pp→hX LL (in–in) | LO | q q̄ → q q̄ | N/A | 7.1 kB | N/A | N/A |
| pp→hX TT (in–in) | LO | qq′ → qq′ | N/A | 6.4 kB | N/A | N/A |
| pp→hX LL (transfer) | LO | qg → qg | N/A | 6.8 kB | N/A | N/A |
| pp→hX LL (transfer) | LO | qq′ → qq′ | N/A | 6.7 kB | N/A | N/A |
| pp→hX TT (transfer) | LO | qg → qg | N/A | 6.9 kB | N/A | N/A |
| pp→hX TT (transfer) | LO | qq′ → qq′ | N/A | 7.1 kB | N/A | N/A |
| Drell–Yan UU | LO | q q̄ | N/A | 4.6 kB | N/A | N/A |
| Drell–Yan UU | LO | q̄ q | N/A | 4.6 kB | N/A | N/A |
| SIDIS UU | LO | q → q | N/A | 6.0 kB | N/A | N/A |
| SIDIS UU | LO | q̄ → q̄ | N/A | 6.0 kB | N/A | N/A |
| SIDIS LL | LO | q → q | N/A | 6.0 kB | N/A | N/A |
| SIDIS LL | LO | q̄ → q̄ | N/A | 6.0 kB | N/A | N/A |
