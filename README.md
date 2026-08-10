# FACET

FACET is the Linux production tree for the Factorization Agent for Collider
and Event-shape Theory. This repository starts with infrastructure only; the
existing exploratory Windows and Linux projects remain unchanged.

## Layout

- `External/ChatGPT`: bridge files for the signed-in ChatGPT Pro session.
- `Addon/Load`: FACET's repository-relative loader.
- `Addon/Mathematica_Addon`: third-party Wolfram Language packages.
- `Addon/Other_Addon`: non-Mathematica tools, currently Kira.
- `FeynFacet`: FACET's modular Wolfram Language package. `FeynFacet.m` is the
  public facade; focused files under `Private` own core exact algebra, process
  cards, topology and cut handling, dimensional shifts, collinear
  factorization, and Kira reduction.
- `Codex`: agent-owned Kira workspaces, run state, scratch files, logs,
  staging files, backups, and the reusable test suite under `Codex/Tests`,
  organized by calculation. Production code and durable analytic results are
  kept outside this directory.

## Load

```wl
Get["/home/maxzhang/FACET/Addon/Load/LoadFACET.wl"];
```

This resolves dependencies relative to this repository. It does not depend on
the old `Hard Function` or `Hard-pphX-Linux` directory after setup.

Third-party software remains subject to its own license and citation terms.
Those terms must be reviewed before publishing a redistributable release.

## Calculation boundary

`CollinearFactorizePreIBP` owns one diagram pair from generation through its
cut-aware, dimension-shifted `GLI` representation. Reduction is separate:
`KiraReduction` returns validated exact IBP rules and masters, while
`CoefficientSimplification` streams the pair results and constructs the
compact analytic master coefficients. This separation allows a Kira project
to be reused without retaining all unreduced pair expressions in memory.

The durable interfaces are Associations with versioned formats and analytic
contexts. They fail closed on missing BMHV, branch, cut, exactness, source, or
causal information. Physical cut metadata is never inferred back from a bare
Kira family.

## Topology equivalence

After partial fractions and `BuildTopologies`, compare all cut-aware family
records with

```wl
equivalence = TopologyEquivalence[Topologies];
```

The function accepts only complete unit-power families and exact rational
affine loop-momentum maps with unit Jacobian that preserve the complete
propagator permutation, stored eta signs, cut slots, cut energy directions,
kinematic rules, and AMFlow routing labels. It returns representatives,
equivalence classes, physical mapping metadata, and fresh `GLI` replacement
rules synthesized from the verified propagator permutation.

The result is deliberately conservative. `PhysicalCausalStatus` is `Verified`
only when every input record supplies per-propagator physical-role metadata;
otherwise the classes are certified for the cut-aware IBP representation.
`ConservativelySeparated` means a mapping proposed by FeynCalc failed a FACET
check. It does not prove that no other valid loop-momentum map exists.
