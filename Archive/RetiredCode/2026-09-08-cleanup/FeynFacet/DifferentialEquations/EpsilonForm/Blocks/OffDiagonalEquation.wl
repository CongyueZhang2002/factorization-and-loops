offDiagonalBlockRationalZeroCoefficients[expression_, variables_List] :=
  Module[{numerator = Numerator[Together[expression]]},
    If[TrueQ[numerator === 0], {},
      Values[CoefficientRules[Expand[numerator], variables]]]];
