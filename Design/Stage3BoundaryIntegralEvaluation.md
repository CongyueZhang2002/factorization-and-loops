# Stage 3 boundary-integral evaluation plan

This records the proposal at the start of the 2026-09-07 run. Its 83 amplitude
series and 565 coefficients are historical starting demands. All required
physical boundary values are now determined; see
[the completed report](PhysicalBoundaryResults_2026-09-07.md). The workflow below
remains useful for extending the framework to other integral geometries.

## Mathematical target

Construct an explicit relation

    c(epsilon) = c_known(epsilon) + R(epsilon) B(epsilon),

where c is the existing amplitude vector and B is a reduced set of unevaluated limiting integrals. Definitions include the full measure, cut
powers/orientations, domain, prescriptions, dimensional shifts and scale
factors. R includes the exact normalization conversions. The dimension of B
is a computed result; the former hard-region or period-type counts do not
establish it.

## Proposed workflow

1. Derive a sufficient set of physical asymptotic coefficients from the
   normalized DE, seed and gauges. Select observables that determine the
   remaining amplitudes with low integration cost, and check the rank at
   generic epsilon. Retain generalized eigenspaces and logarithmic chains.
   The z^5 DE subtraction depth is not automatically the physical boundary
   expansion depth.

2. Construct those coefficients from the original cut integrals by expansion
   by regions. Do not simply set z=0 in a vanishing phase-space integral or
   degenerate Gram matrix. Expand the measure, Jacobians, denominators and
   physical domain consistently. Keep powers z^(a+b epsilon) until matching
   and account for the relevant endpoint regions. If separate regions need
   auxiliary analytic regulators, preserve them until their cancellation
   in the assembled result. A region-finder output alone is not a completeness
   proof for sign-indefinite or cut representations.

   asy2 is a candidate region finder; pySecDec also supplies parameter-space
   expansion-by-regions routines. The physical cut/domain adapter remains
   project code. See [asy2](https://arxiv.org/abs/1206.0546) and
   [pySecDec regions](https://arxiv.org/abs/2108.10807).

3. Reduce the limiting integrals globally, across the original family labels.
   Apply boundary symmetries, justified scaleless/zero-cut identities,
   partial fractions and exact cut-aware IBP reduction with Kira. Boundary
   degeneration can create additional relations. Preserve repeated cuts as
   distributions; no unproved deletion of domain-derivative terms.
   Insert known phase-space volumes and Beta/Gamma integrals at this stage.
   [Kira](https://arxiv.org/abs/2505.20197) is the existing default reducer.

4. Propagate the 565 amplitude-coefficient demands through the new reduction
   and matching coefficients to determine sufficient epsilon orders for B.
   Poles in R can require higher orders of B. Do not use one uniform epsilon
   cutoff. Retain the distinction between physical asymptotic order,
   dimensional-regulator order and numerical truncation order.

5. Produce explicit Euler or equivalent phase-space parameter representations
   of the remaining masters. Integrate delta functions and elementary angular
   or Beta integrals first when justified. Retain exact normalization,
   real-domain inequalities and branch information. Use raw Euler input for
   an analytic integrator after cuts have been handled; do not pass cut lines
   as ordinary uncut graph propagators.

6. Evaluate the reduced masters analytically. Prefer existing Gamma/Beta
   results, then SubTropica with HyperFLINT for suitable linearly reducible
   Euler representations. SubTropica handles tropical subtractions and
   regulator expansion; HyperFLINT or built-in HyperIntica performs the
   hyperlogarithm integrations. HyperInt in Maple is an alternative, not
   a required additional layer.

   Linear reducibility is a property of a chosen representation/integration
   order. Failure of one search is not proof that the answer is non-polylogarithmic.
   Try a different representation, basis or valid rationalization before
   choosing an auxiliary DE, Mellin-Barnes method or other function class.
   The root count of the original finite-kinematics DE does not classify every
   boundary integral. [SubTropica paper](https://arxiv.org/abs/2604.20954),
   [implementation](https://github.com/SubTropica/SubTropica),
   [HyperInt](https://arxiv.org/abs/1403.3385).

7. Substitute evaluated B into c, check the required coefficient coverage and
   obtain physical master solutions. Use cheap rational identities and selected
   numerical checks; perform a nonzero comparison with AMFlow. Its phase-space
   method is documented [here](https://arxiv.org/abs/2009.07987).
   pySecDec is a numerical alternative for suitable parameter integrals;
   numerical coefficients must be labelled as such rather than as analytic
   evaluations. The singular-connection endpoint initialization remains
   necessary for the final numerical reconstruction, but does not prevent
   steps 1-6.

## Current tool inventory, inspected 2026-09-07

- SubTropica 1.2.9 source is available through the add-on tree.
- HyperFLINT 1.2.9 has a Linux native library in the user's Wolfram paclet tree.
- polymake and ginsh are available on PATH.
- Kira is present under Addon/Other_Addon/Kira/bin/kira.
- AMFlow is part of the existing integration interface.
- The active package has original integral definitions, Feynman-parameter and
  cut-Baikov builders, elementary phase-space evaluations and Laurent-order
  machinery. Its physical scaling module proves a bound; it does not enumerate
  all asymptotic regions or evaluate their integrals.
- No active SubTropica adapter was found in FeynFacet or Scripts/Boundary.
- asy2 was not found in the inspected add-on/application directories; pySecDec
  was not importable in the default WSL Python. This does not rule out another
  installation elsewhere.
- This inspection did not run an end-to-end SubTropica configuration test.
  Several bundled add-ons point to the frozen FACET tree; upgrades must not
  modify that read-only tree.

## Implementation priorities and deliverables

First produce the boundary-master inventory and sparse matching/reduction map.
For every boundary master, record its definition, originating regions,
epsilon demand, candidate representation, analytic evaluation status and the
amplitude coefficients it supplies. Then connect this general representation
to SubTropica and evaluate the reduced list. Split independent boundary-master
jobs across the allowed eight-core budget and avoid nested oversubscription.

Persist final boundary-master definitions and evaluated Laurent series,
the exact sparse map to c, demanded-order coverage and concise verification
records in the process Results folder. Temporary integration/subtraction
products are disposable. The reusable code accepts process data and has no
special cases for selected CF families.
