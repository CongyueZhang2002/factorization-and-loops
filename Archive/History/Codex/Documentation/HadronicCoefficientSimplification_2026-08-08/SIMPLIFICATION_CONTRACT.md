# Exact hard-coefficient simplification contract

`SimplifyHardCoefficients[data, setup]` is the maintained normalization for
both NLO and NNLO coefficients. `data` may contain assembled master
coefficients or one list of additive contributions per master. Both forms are
converted to contribution groups and enter the same exact algebra.

## Card data

Every card must provide the following entries inside
`setup["CoefficientKinematics"]`:

1. `"PositiveFractions"`: variables constrained to `0 < xi < 1`.
2. `"DistributionFactor"`: the twist-two distribution product, or
   `Automatic` when it must be derived from the complete contribution sum.
3. `"LaurentValuation"`: the expected fraction powers, or `Automatic` when
   they must be derived from the complete contribution sum.
4. `"PhysicalRegion"`: the source-invariant chamber.
5. `"Scale"`: a positive dimensionful invariant.
6. `"DimensionlessCoordinates"`: exact definitions, inverse rules, and the
   dimensionless physical chamber.
7. `"ForbiddenVariables"`: variables that cannot remain in the hard
   coefficient. Fractions and declared external hadronic objects are added
   automatically.
8. `"BranchGrammar"`: the permitted fraction-dependent powers. The current
   grammar is `"PositiveMonomialRoots"`.

The NLO UU and TT cards explicitly declare

```wl
"LaurentValuation" -> <|xa -> -1, xb -> -1, zh -> -2|>
```

and their polarization-dependent distribution products. The NNLO UU card
currently uses `Automatic` for the valuation; it should be made explicit only
after the complete 342-master expression establishes a common value.

## Exact acceptance criteria

The calculation terminates with `$Failed` unless all of the following hold:

- every dimensionless coordinate has mass dimension zero;
- the scale has positive mass dimension and is positive in the source chamber;
- the coordinate map is invertible in both directions;
- the source and dimensionless chambers are separately nonempty and map into
  each other;
- the declared or derived distribution product reconstructs every master
  coefficient after summing cancellations required within that master;
- the declared or derived Laurent valuation reconstructs each coefficient;
- every fraction-dependent noninteger power is a half-integer power of a
  positive monomial in the declared fractions;
- no forbidden variable remains in the physical or dimensionless hard
  coefficient;
- restoring the scale and coordinate map reconstructs the physical
  coefficient exactly.

No `PowerExpand` is used. Fraction-independent logarithms, Gamma functions,
noninteger powers, angular functions, distributions, and BMHV tensors are
temporarily replaced by inert symbols while their rational coefficients are
simplified, then restored with an exact reconstruction check.

## Measured calculations, 9 August 2026

- NLO UU stored result: 6 coefficients, 48.51 s, 859.88 KiB.
- NLO TT smallest stored coefficient: 2.58 s, 67.16 KiB.
- NNLO UU stored two-contribution target: 2.34 s, 27.91 KiB.
- End-to-end NLO: 16 cut integrals reduced to 1 master; Kira 17.50 s,
  coefficient normalization 10.34 s, compact result 122.48 KiB.

All four calculations satisfied symbolic reconstruction. The NNLO timing is
only for one stored target and is not an estimate for all 342 masters.
