<|"Channel" -> "q-qbar", "Coupling" -> FeynFacet`\[Alpha]s, 
 "CouplingPower" -> 1, "CurrentNormalization" -> FeynCalc`CA/(2*System`Pi), 
 "DensityConvention" -> "d sigma_hat/d Q2 = 4 pi alpha_em^2/(3 Nc Q2 s) \
C_DY(z), z=Q2/s; flavor charge included", "DimensionalPrefactor" -> 1, 
 "DimensionalRegulator" -> Global`Epsilon, "DistributionBasis" -> 
  <|"Axes" -> {<|"Variable" -> Global`z, "Endpoint" -> 1, 
      "Interval" -> {0, 1}, "Distance" -> 1 - Global`z, 
      "NormalVariable" -> Global`endpointZ|>}|>, "Order" -> "NLO", 
 "PhysicalChannel" -> <|"Incoming" -> {{"q", "u"}, {"qbar", "u"}}|>, 
 "Polarization" -> <|"Incoming" -> {"U", "U"}|>, 
 "Project" -> "DrellYan_UU_NLO", "Scale" -> Global`Q2, 
 "StructureFunctions" -> {"C_DY"}, "Variables" -> {Global`z}, 
 "Contribution" -> "Total", "IncludedContributions" -> 
  {"Real", "Virtual", "Counterterm"}, "PlusConvention" -> "At each axis, \
PlusCoefficients[k] multiplies [Log[Distance]^k/Distance]_+ on Interval, with \
subtraction at Endpoint. For DistributionBasis[Axes], delta/plus/regular \
values repeat recursively in the listed axis order.", 
 "RequiredContributions" -> {"Real", "Virtual", "Counterterm"}, 
 "Assumptions" -> Global`Q2 > 0 && Global`muR2 > 0 && Global`muF2 > 0 && 
   Global`muF2 > 0, "Schemes" -> <|"IncomingA" -> "MSbar", 
   "IncomingB" -> "MSbar"|>, "LowerOrderResults" -> 
  <|"q-qbar" -> <|"File" -> "../../../LO/q-qbar/Results/Result.wl", 
     "EpsilonRange" -> {0, 2}|>, "qbar-q" -> 
    <|"File" -> "../../../LO/qbar-q/Results/Result.wl", 
     "EpsilonRange" -> {0, 2}|>|>, "Format" -> "FeynFacet-PartonicResult", 
 "FormatVersion" -> 1, "EpsilonRange" -> {0, 1}, "LaurentLowerBound" -> 0, 
 "Coefficients" -> 
  <|0 -> <|"DeltaCoefficient" -> {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*
         (-24 + 2*System`Pi^2 - 9*System`Log[Global`muF2] + 
          9*System`Log[Global`Q2]))/(27*FeynCalc`CA*System`Pi)}, 
     "PlusCoefficients" -> 
      <|0 -> {(-4*(-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*
           System`Log[Global`muF2/Global`Q2])/(9*FeynCalc`CA*System`Pi)}, 
       1 -> {(8*(-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s)/
          (9*FeynCalc`CA*System`Pi)}|>, "RegularCoefficient" -> 
      {(2*(-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*
         (-System`Log[Global`muF2*Global`Q2] + System`Log[Global`z] + 
          Global`z^2*(-2*System`Log[1 - Global`z] + System`Log[
             (Global`muF2*Global`z)/Global`Q2]) + 
          2*System`Log[Global`Q2 - Global`Q2*Global`z]))/
        (9*FeynCalc`CA*System`Pi*(-1 + Global`z))}|>, 
   1 -> <|"DeltaCoefficient" -> {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*
         (-96 + 13*System`Pi^2 + 18*System`Log[Global`muF2/Global`muR2]*
           (2 + System`Log[Global`muF2] - System`Log[Global`muR2]) + 
          2*System`Log[Global`muR2/Global`Q2]*(-30 + 4*System`Pi^2 - 
            9*System`Log[Global`muR2] + 9*System`Log[Global`Q2])))/
        (108*FeynCalc`CA*System`Pi)}, "PlusCoefficients" -> 
      <|0 -> {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*(System`Pi^2 + 
            2*System`Log[Global`muF2]^2 - 2*System`Log[Global`Q2]^2 + 
            4*(-1 + System`Log[Global`muR2])*System`Log[Global`Q2/
               Global`muF2]))/(9*FeynCalc`CA*System`Pi)}, 
       1 -> {(8*(-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*
           (-1 + System`Log[Global`muR2] - System`Log[Global`Q2]))/
          (9*FeynCalc`CA*System`Pi)}, 
       2 -> {(-8*(-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s)/
          (9*FeynCalc`CA*System`Pi)}|>, "RegularCoefficient" -> 
      {-1/18*((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*
          ((-1 + Global`z)*(8 - 8*Global`z + System`Pi^2*(1 + Global`z)) + 
           2*(-1 + Global`z^2)*System`Log[Global`muF2/Global`muR2]^2 - 
           4*System`Log[Global`muF2*Global`muR2] + 
           4*System`Log[Global`muR2/Global`Q2]^2 - 8*(-1 + Global`z^2)*
            System`Log[1 - Global`z]^2 + 4*Global`z^2*System`Log[
             (Global`muF2*Global`z)/Global`Q2] - 2*(1 + Global`z^2)*
            System`Log[(Global`muR2*Global`z)/Global`Q2]^2 + 
           8*System`Log[1 - Global`z]*(1 - Global`z^2 + Global`z^2*
              System`Log[(Global`muR2*Global`z)/Global`Q2] + 
             System`Log[(Global`Q2*Global`z)/Global`muR2]) + 
           4*System`Log[Global`muR2*Global`Q2*Global`z]))/
         (FeynCalc`CA*System`Pi*(-1 + Global`z))}|>|>|>
