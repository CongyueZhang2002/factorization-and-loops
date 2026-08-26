# Installable multiquadratic strip contract

Status: prototype contract, deliberately not loaded by FeynFacet.

## Purpose

The direct multiquadratic solver now reconstructs one gauge and residue vector
rational in the regulator, and it certifies dlog potentials on the active
residue support.  The sector driver nevertheless stops on every
`ModularConsistent` result.  The missing seam is not another solver: it is a
small, fail-closed conversion to the solution shape already consumed by
`familyRowGaugeDLogForm` and `family_epsform_sector.wls`.

## Required input facts

An installable result is built only when all of the following hold:

1. regulator reconstruction returned
   `ReconstructedRegulatorDependenceV1`;
2. its generic gauge has the strip dimensions and its residue matrices are
   free of the two chart variables;
3. active-support certification is complete and certified;
4. its active indices, residues, letters and one-forms are content-bound to
   the reconstruction and to the cached exact potential certificates;
5. every installed letter is regulator-independent;
6. the reconstructed generic vector passed either an exact channel identity
   or fresh provider-backed residual checks at at least two unseen primes and
   three disjoint `(epsilon,x,y)` images per prime.

Unused unverified candidates do not enter this contract.  An empty active
alphabet is valid for a gauge-only solution.

## Output ABI

The compact result uses the existing row-gauge keys:

```wl
<|"Status" -> "Solved",
  "Method" -> "DirectMultiquadraticFiniteField",
  "SolutionContract" -> "InstallableMultiquadraticDLogV1",
  "Gauge" -> genericGauge,
  "Alphabet" -> activeLetters,
  "ResidueMatrices" -> activeResidues,
  "OneForms" -> activeOneForms,
  "Certificate" -> "NumericalResidual" | "ExactResidual",
  "ExactDLog" -> True | Missing["DeferredToFamilyCertificate"],
  ...|>
```

`familyRowGaugeDLogForm` then constructs

```text
epsilon Sum_a K_a(epsilon) dlog L_a.
```

The existing family-level `FactorFamilyRegulatorDependence` remains
responsible for removing residual regulator dependence from the `K_a` after
the row is installed.

## Consumer work still required after provider promotion

- add a `DirectMultiquadraticFiniteField` solver-configuration route and bind
  its implementation/provider fingerprints;
- let the sector driver treat this contract like the existing rational
  finite-field result rather than the old non-installable modular candidate;
- make resume hydration replay the same provider/reconstruction route and
  compare the generic gauge and compact dlog form;
- preserve the fresh validation record in the checkpoint summary;
- keep the final whole-family certificate as the decisive family-level check.

The prototype in `Prototypes/MultiquadraticInstallableSolution.wl` exercises
the conversion without changing any production dispatch.  It should be
promoted only after Fable's provider-backed sampling and reconstruction API is
stable.

