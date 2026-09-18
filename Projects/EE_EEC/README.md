# Leading-order QCD energy-energy correlation

This project reproduces the full massless vector-current e+e- EEC through
order alpha_s, including self pairs and both angular endpoints. All process
and measurement definitions are in Common-Card.wl and the raw/result cards.
Production does not load a published coefficient.

The observable is the ordered sum (including i=j)

\[
 S(z)=\frac1{\sigma_0}\sum_{i,j}\int d\sigma\,
 \frac{(q\cdot p_i)(q\cdot p_j)}{(q^2)^2}
 \delta\left(z-\frac{q^2 p_i\cdot p_j}{2(q\cdot p_i)(q\cdot p_j)}\right),
 \qquad 0\le z\le1.
\]

sigma0 is the generated four-dimensional Born total rate. The common photon
coupling and scalar-current contraction cancel in this ratio. The photon
current is conserved and there are no incoming colored legs or fragmentation
operators, so this order needs no PDF/FF counterterms or coupling counterterm.
The dimensionally continued real and virtual normalizations are kept through
pole cancellation; division by the Born rate is performed afterward.

## Run from the cards

From the repository root in WSL, use the existing supervised launcher. For
example, this Python invocation includes kernel startup in its timing:

```python
import sys
from pathlib import Path
sys.path.insert(0, 'Scripts')
from wolfram import run_wolfram, atomic_json
output = Path('Projects/EE_EEC/Results/NLO/q-qb')
receipt = run_wolfram(
    'Scripts/run_project_result.wls',
    [str(output / 'Result_Card.wl'), 'all'],
    logfile=output / 'Run.log', completion='PROJECT_RESULT_COMPLETED',
    cpus=list(range(8)), timeout=600)
atomic_json(output / 'Run.json', receipt)
assert receipt['Passed'], receipt
```

`all` regenerates amplitudes and analytic assembly, but compatible Kira
workspaces and the shared master library may still be reused. It is not a
claim of a cold benchmark. `resume` reuses raw results only when their full
card definition and epsilon coverage agree. `assemble` requires matching raw
results and only recombines them. After changing mathematics in the package,
use `all`. No manual coefficient edits are needed.

The standard public `RunProjectResult` dispatches on the integration geometry,
not on the project name. `Scripts/run_measured_result.wls` exposes the same
measured calculation directly. Individual development stages are available
through `Scripts/run_measured_contribution.wls` (prepare, de, masters,
interior, check, virtual). The complete calculation uses the result card.

## Perturbative naming

The project folders count relative to the two-quark Born process:

- `Raw/LO/q-qb/Born`: gamma* -> q qb, gives half a delta at each endpoint.
- `Raw/NLO/q-qb/Real`: generated gamma* -> q qb g tree amplitude.
- `Raw/NLO/q-qb/Virtual`: generated two-body one-loop interference, 2 Re once.
- `Results/NLO/q-qb`: their order-alpha_s sum, normalized to the generated Born rate.

This last order is conventionally called **LO EEC** at nonzero opening angle.
The order-alpha_s^2 EEC (conventional NLO EEC) is being developed in `Raw/NNLO`.
No complete result at that order has been obtained yet. Follow the
[campaign record](../../Reports/2026-09-18/NLOEECOvernight.md).

The current cards sum a unit-charge vector current over `nf` massless flavors.
All are represented by one degenerate model flavor class; `u` and `c` are
distinct dummy labels, not independently counted primary-current attachments.
The four-parton components are qqbgg, identical four-quark states, and distinct
four-quark states. The shared counting code supplies the state factorials and
flavor multiplicities; all photon attachments are generated within each state.
The Born denominator uses the same flavor sum. Lower-order stored raw definitions
from the former fixed-flavor cards required regeneration; the order-alpha_s
result has now been regenerated with exact pole cancellation. This regeneration
has not rerun the separate published-reference comparison.

For this campaign, derive and save the full new coefficient before comparing it
with published EEC coefficients. Internal consistency checks and universal scalar
integral inputs remain separate from that final comparison.

## Read the answer

`Results/NLO/q-qb/Results.wl` is a readable Mathematica association without
context prefixes. Its `.meta.wxf` companion retains executable identities and
provenance; read the pair with ``FeynFacet`FamilyArtifactRead`` or
``FeynFacet`ReadPartonicResult`` after loading the package.

- `Coefficients[0]` contains the order-alpha_s correction.
- `BornExpression` gives the two Born contacts.
- `ExpressionThroughSelectedOrder` gives their sum as a mathematical expression.
- `DeltaCoefficients[0|1]` are unit-mass endpoint deltas.
- `PlusCoefficients[p][k]` multiply [Log[t]^k/t]_+ on the **full** interval,
  with t=z for p=0 or t=1-z for p=1, subtracting the test function value at p.
- `RegularCoefficient` is integrable on the full interval. Its apparent z^-5
  singularity cancels; its z=0 limit is finite.

There are no unevaluated integrals, master symbols, lazy generators, or
undetermined constants in the final coefficient.

## Calculation and verification

The native quadratic measurement polynomial retains its exact Jacobian once.
Polynomial denominator relations accompany the full off-shell IBPs. Kira
constructs a DE with six masters. Their explicit regulator-exact beta/Gauss
values fix the physical normalization and are stored in the shared master
library. The common epsilon planner reconstructs the interior through
spurious reduction poles. Resonant Gauss connection series compute both
endpoints before epsilon expansion. Self contacts are separate inclusive
Dirichlet integrals. The scalar-loop provider retains the timelike phase.

Both Laurent poles cancel exactly after summing the independent raw results.
The answer agrees with [Eq. (21), arXiv:1905.01310](https://arxiv.org/abs/1905.01310),
converting alpha_s/(4 pi) to alpha_s/(2 pi). The interior also agrees with
[Eq. (3), arXiv:1801.03219](https://arxiv.org/abs/1801.03219), with the factor two
from changing d/dcos(chi) to d/dz. Reference formulas occur only in tests.

Run `Tests/Physics/t_eec_complete.wls` for the full distribution, pole
cancellation and independent inclusive-moment comparison, and
`Tests/Physics/t_eec_card_workflow.wls` for the exact/native DE and interior
checks. `Tests/Functions/t_gauss_endpoint_series.wls` tests the generic
resonant endpoint mathematics. All use Scripts/wolfram.py supervision.

The full normalized moments are
\[
 \int_0^1S(z)\,dz=1+\frac{3C_F\alpha_s}{4\pi},\qquad
 \int_0^1zS(z)\,dz=\frac12+\frac{3C_F\alpha_s}{8\pi}.
\]

See [the implementation report](../../Reports/2026-09-17/FullLOEEC.md) and
[general quadratic-measurement design](../../Design/PolynomialMeasurements.md).


The developing NNLO UV card uses the same counterterm operator as other projects,
with no collinear legs. Its consumer-owned lower-order source range is determined
by the UV pole. Shared Born/real/virtual templates are epsilon independent; direct
cards only choose the final requested range. See the campaign record for the
completed UV contribution and the unfinished remaining NNLO integration stages.

The NNLO two-body Virtual raw contribution is also generated and integrated,
including the two-loop/tree interference, the one-loop square and the exactly
vanishing generated two-gluon candidate. It retains its Laurent poles. An
independent one-loop form-factor product checks the square through its finite
coefficient. Four-body physical master integration and measured real-virtual
integration are still required for the complete result. See the campaign record
for timing, reuse and the current DE job.
