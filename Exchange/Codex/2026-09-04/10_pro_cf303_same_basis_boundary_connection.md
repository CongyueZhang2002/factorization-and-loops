# CF303 same-basis tangential boundary connection: discriminating step

Please continue the existing **Assess Multiquadratic Pipeline** discussion. We now have a concrete derived-data gap and want the smallest mathematically correct way to close it, not another architecture review.

## What is already present

- A validated exact rational 13 by 13 tangential evolution matrix `Omega(p,eps)` in `DifferentialEquationDataV2/CF303/CF303TangentialBoundaryEvolutionOperatorV2.wl`.
- A coefficientwise boundary embedding through epsilon orders -4 through 3 in `CF303TangentialJunctionMapReconstructed.wl`: `SourceModeMap` is 43 by 13 and `TargetGModeMap` is 2 by 13.
- A one-prime exact finite-field regularized normal action containing all 336 demanded coefficients: 320 explicit rational functions and 16 exact lazy mode-1 regularized-endpoint functional sums.
- The exact physical fixed-rho connection and the exact T25/normal-factor circuit are preserved on disk.
- The package already has the general constructor and acceptance equation

  `B Omega = Gamma B - d_p B`,

  so another generic constructor would be redundant.

## Exact missing operand

The absent quantity is the fixed-rho target action in the same 45-component G25 basis,

`A^F_{p|rho,target,*} B_phys`,

or equivalently the 2 by 43 target-from-source block reduced to its 2 by 13 contraction. With

`B_I = T25 (B_G + Q)`,

forming the residual also requires `d_p Q`. The derivative is immediate for the 320 explicit rational coefficients but is not yet represented for the 16 lazy regularized-endpoint functional sums. A check through rho^0 may also require a small positive-rho window of the target-target connection multiplying the rho^-2 part.

## Proposed discriminating computation

At the existing 61-bit prime and one fresh nonsingular p value:

1. Extract only target rows 5 and 6 of the fixed-rho physical connection, with the minimal positive rho orders needed by the rho^-2 initial data.
2. Assemble `B_I = T25 (B_G + Q)`.
3. Test modes 2 through 7 first. Their Q coefficients are explicit, so this fixes the sign, T25 multiplication order, and 45-column permutation without touching the 16 lazy terms.
4. Only if that passes, differentiate the existing adjoint regularized-endpoint functional for the 16 mode-1 terms and complete the residual.
5. Repeat at a second unused prime before characteristic-zero reconstruction.

## Questions

1. Is this the minimal correct same-basis test, or can the target contraction be obtained more directly from flatness or the already-known Omega and B without extracting additional positive-rho connection coefficients?
2. What is the exact minimal rho-order window implied by a rho^-2 leading term when the connection is regular singular?
3. For the lazy mode-1 terms, should `d_p` be pushed through the regularized-endpoint functional by differentiating its Hermite input and moving endpoint, or is an adjoint/connection identity preferable?
4. Is there any hidden basis-order or derivative term missing from `B_I = T25(B_G+Q)` and `B Omega = Gamma B - d_p B`?

Please give a concrete go/no-go answer and the cheapest sequence of computations/refusals.
