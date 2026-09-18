# Numerical integer-relation reconstruction for coefficients and boundaries

The user suggested high-precision numerical PSLQ as a potential speedup. No
production reconstruction method has been replaced and no end-to-end speedup has been measured.
Actual GPT-6 Pro review29 completed against pushed f688f4596f0e184fc81e45031ea6049e6bcde80e.
The user clarified the intended broader target is reconstruction in a known
coefficient/function basis throughout reduction and DE calculations; review30
completed and explicitly endorses testing small known ansätze beyond boundaries.

Three different tasks must be distinguished:

| Object | Current or proposed approach | Assessment |
|---|---|---|
| Rational functions of kinematics and dimension in IBP/DE relations | Kira/FireFly finite-field interpolation and rational reconstruction | Compare a small known-ansatz numerical pilot; retain modular production until total-time evidence supports a change. |
| Physical boundary Laurent coefficients | Direct physical periods or continued moment constraints, possibly followed by PSLQ | Useful candidate for a bounded pilot. |
| The entire measured function | A previously established GPL/function basis and numerical coefficient fitting | Requires an independently derived alphabet, prefactors, weights and branches; not a shortcut supplied by PSLQ itself. |

PSLQ recognizes a number in terms of a supplied constant basis. It does not
evaluate the physical integral, establish its normalization, construct a complete
constant basis, or prove the recognized identity from finite precision alone.
The precision demand grows with the vector length and integer coefficient size.
The expensive stage may be the numerical period or continued moment, not PSLQ.

For the present calculation, the identical-quark DE has closed exactly with42
coordinates. Ten inclusive moment RHS combinations have already been evaluated
analytically using6 separately identified universal scalar values. Recognizing
these already available RHSs would not resolve the outstanding physical modes.
The opportunity is instead a still-unknown boundary coefficient, or the numerical
moment matrix acting on unresolved homogeneous solutions, with controlled endpoint
continuation and Laurent-order demands.

Candidate pilot: choose one unresolved source-relevant coefficient, derive a small
candidate constant basis from its scalar geometry/DE rather than the published
EEC answer, obtain independent high-precision values, and test recognition with
additional digits. Compare total time including numerical evaluation, extraction
of Laurent coefficients and checks. A successful integer relation is initially
numerical evidence; seek an exact physical identity or retain that qualification.
Use a withheld physical moment or an independent period for validation, not the
same condition that fixed the coefficient. Do not assume an arbitrary interior
base point yields only multiple zeta values.

Primary sources checked:

- [FireFly implementation and papers](https://github.com/jklappert/FireFly).
- [Bailey's description of PSLQ and precision requirements](https://www.cecm.sfu.ca/organics/papers/bailey/paper/html/node3-an.shtml).
- [Lee, Smirnov and Smirnov on high-precision DE expansions](https://arxiv.org/abs/1709.07525).

No measured NLO EEC reference coefficient was opened for this assessment.

## Known rational-ansatz pilot after the user's clarification

The broader proposal is legitimate. If the denominator and numerator monomials
are known, numerical reconstruction only needs their rational constant
coefficients. Multi-point lattice reduction can trade additional samples for
lower precision. This is distinct from knowing only the master-integral basis,
which does not specify the rational-function ansatz for its coefficients.
See [Barrera et al., arXiv:2507.17815](https://arxiv.org/abs/2507.17815).

A small actual-DE test uses selected entries of the saved identical-quark system,
sets Q2=1, and supplies the exact denominator and sparse numerator support to
both algorithms. The numerical oracle evaluates the saved rational expression;
it does not run numerical IBP or evaluate any physical integral. Truth coefficients
are withheld from PSLQ and checked exactly after reconstruction. The modular
baseline interpolates the same support using one61-bit prime, justified here by
the declared integer numerator coefficient bound10^9. It is a simple known-support
Python interpolation, not a full Kira/FireFly benchmark.

| Numerator terms | PSLQ time | Precision | Modular interpolation time | Exact recovery |
|---:|---:|---:|---:|---|
|4|0.000789s|80 requested digits|0.0000252s|Both|
|8|0.0357s|80 requested digits|0.0000701s|Both|
|16|1.852s|160 requested digits|0.000359s|Both|

Oracle evaluation, common support extraction and Python startup are excluded
from these algorithm timings. This is not a production speed comparison. At16
terms,80 requested digits produced a spurious relation rejected by exact checking.
At160 digits/3000 iterations no relation was found; increasing the iteration cap
to12000 recovered the correct relation.320 digits/12000 iterations also recovered
it in3.172s. The last two changes are recorded separately; higher precision alone
is not credited for fixing an iteration-limit failure.

The benchmark establishes feasibility on real coefficient data, not an end-to-end
speed advantage. PSLQ used one high-precision sample; the modular method used as
many samples as supplied monomials. Actual black-box evaluation costs can therefore
change the conclusion. Multi-point LLL and coefficient/DE-ansatz reconstruction
from expensive numerical solves remain unbenchmarked. Production is unchanged.

Records: `IdenticalQuarks/Work/CoefficientReconstructionBenchmark.json`;
driver: `Archive/Runs/2026-09-18/NLOEECChecks/benchmark_pslq_coefficients.py`.


## Multi-point lattice pilot

The same saved-formula oracle and sparse supports were also tested with a
multi-point integer lattice, using SymPy1.14.0 with python-flint0.9.0 in an
isolated temporary virtual environment. No installed production Python package
was replaced. The pure-Python SymPy LLL initially raised an internal assertion;
that failed launch did not produce a reconstruction result.

For16 numerator terms,2 samples at40 lattice digits found no candidate passing
the withheld-point check.4 samples at40 lattice digits recovered the exact
coefficient vector in0.001846771s including one withheld numerical check;
sample evaluation and lattice setup took0.000800353s. Arithmetic used70 digits.
4 samples at80 lattice digits also passed,0.006829134s recognition/check.
The4/8-term cases passed with2 or4 samples. All accepted candidates then matched
the saved exact numerator coefficients; exact truth was not used to select a row.

This shows the points/precision tradeoff on these actual DE coefficients.
Comparing native FLINT LLL with Python mpmath PSLQ is implementation-specific.
Neither the numerical sample cost nor the modular baseline is a full specialized
IBP solve, so this still establishes no production speedup. A fair next benchmark
must generate samples from original equations with the same ansatz for each method.
