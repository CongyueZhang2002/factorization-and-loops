# CF303 exact resonant Jordan coupling: reconstruction inquiry

Please continue in this existing **Assess Multiquadratic Pipeline** conversation and assess the mathematical issue below. We need a concrete, rigorous route, not general software advice.

For the CF303 soft boundary stratum, the current preserved data determine:

- an exact rational-in-`p,epsilon` 13-by-13 tangential connection `Omega` for the thirteen boundary functions;
- the thirteen diagonal normal exponents;
- an exact 43-by-13 source-mode map;
- a fully reconstructed tangential junction map, independently checked in 112 modular comparisons;
- the six intrinsic modes and seven inherited modes, including their Jordan levels.

The missing object is the exact rational-in-`p,epsilon` 2-by-4 nilpotent coupling `C(p,epsilon)` in the resonant zero-exponent sector. Its rows are the two independent target modes and its columns are the four inherited zero modes. The preserved record contains `C` only as Laurent coefficients from epsilon orders -3 through 4. Those eight coefficients are not, by themselves, an exact rational function. Replacing the normal residue by its diagonal exponents would erase genuine logarithmic chains and is rejected.

We can still evaluate the original local differential-equation construction at additional rational or finite-field epsilon values, and may be able to generate further Laurent coefficients. The related rational-in-epsilon block transformations have low measured numerator/denominator degrees and known denominator factors.

Please answer:

1. What is the strongest direct defining equation from which `C(p,epsilon)` should be reconstructed (for example, a residue intertwining equation involving the exact local mode map), so that reconstruction is not merely Padé fitting?
2. Given coefficients epsilon^-3 through epsilon^4, how should numerator/denominator degree bounds and normalization be inferred or proven? State the minimum additional coefficients or point evaluations needed for construction and independent validation.
3. Would you prefer common-denominator vector reconstruction of all eight entries, entrywise rational reconstruction, or solving the residue/intertwining equations symbolically/modularly? Explain the expected robustness and cost.
4. What exact or probabilistic finite-field checks are sufficient to accept the reconstructed `C` and the resulting 13-by-13 Jordan normal form without a large symbolic computation?
5. Is there a way to avoid reconstructing `C` altogether while still correctly evolving the boundary functions and preserving the generalized logarithmic chains? If so, give the explicit mathematical representation.

Relevant current files are:

- `Scripts/Transport/CF303/build_cf303_tangential_junction_map.wls`
- `Scripts/Transport/CF303/build_cf303_boundary_function_evolution.wls`
- `FeynFacet/Private/Transport/Boundary/BoundaryFunctionDifferentialSystem.wl`
- stale preserved inputs under `Stale/DifferentialEquationData/2026-09-03_pre_v2/Scripts/Transport/CF303/Artifacts/`

Please be adversarial about underdetermined rational interpolation and distinguish a proved degree bound from a successful finite sample fit.
