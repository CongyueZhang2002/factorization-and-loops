<|"Channel" -> "g-qbar", "Coupling" -> FeynFacet`\[Alpha]s, 
 "CouplingPower" -> 1, "CurrentNormalization" -> FeynCalc`CA/(2*System`Pi), 
 "DensityConvention" -> "d sigma_hat/d Q2 = 4 pi alpha_em^2/(3 Nc Q2 s) \
C_DY(z), z=Q2/s; flavor charge included", "DimensionalPrefactor" -> 1, 
 "DimensionalRegulator" -> Global`Epsilon, "DistributionBasis" -> 
  <|"Axes" -> {<|"Variable" -> Global`z, "Endpoint" -> 1, 
      "Interval" -> {0, 1}, "Distance" -> 1 - Global`z, 
      "NormalVariable" -> Global`endpointZ|>}|>, "Order" -> "NLO", 
 "PhysicalChannel" -> <|"Incoming" -> {"g", {"qbar", "u"}}|>, 
 "Polarization" -> <|"Incoming" -> {"U", "U"}|>, 
 "Project" -> "DrellYan_UU_NLO", "Scale" -> Global`Q2, 
 "StructureFunctions" -> {"C_DY"}, "Variables" -> {Global`z}, 
 "Contribution" -> "Total", "IncludedContributions" -> 
  {"Real", "Counterterm"}, "PlusConvention" -> "At each axis, \
PlusCoefficients[k] multiplies [Log[Distance]^k/Distance]_+ on Interval, with \
subtraction at Endpoint. For DistributionBasis[Axes], delta/plus/regular \
values repeat recursively in the listed axis order.", 
 "RequiredContributions" -> {"Real", "Counterterm"}, 
 "Assumptions" -> Global`Q2 > 0 && Global`muR2 > 0 && Global`muF2 > 0 && 
   Global`muF2 > 0, "Schemes" -> <|"IncomingA" -> "MSbar", 
   "IncomingB" -> "MSbar"|>, "LowerOrderResults" -> 
  <|"q-qbar" -> <|"File" -> "../../../LO/q-qbar/Results/Result.wl", 
     "EpsilonRange" -> {0, 2}|>, "qbar-q" -> 
    <|"File" -> "../../../LO/qbar-q/Results/Result.wl", 
     "EpsilonRange" -> {0, 2}|>|>, "Format" -> "FeynFacet-PartonicResult", 
 "FormatVersion" -> 1, "EpsilonRange" -> {0, 1}, "LaurentLowerBound" -> 0, 
 "Coefficients" -> <|0 -> <|"DeltaCoefficient" -> {0}, 
     "PlusCoefficients" -> <||>, "RegularCoefficient" -> 
      {(FeynFacet`\[Alpha]s*(1 + (6 - 7*Global`z)*Global`z + 
          (-2 - 4*(-1 + Global`z)*Global`z)*System`Log[Global`muF2] + 
          (4 + 8*(-1 + Global`z)*Global`z)*System`Log[1 - Global`z] - 
          2*(1 + 2*(-1 + Global`z)*Global`z)*System`Log[Global`z/Global`Q2]))/
        (18*System`Pi)}|>, 1 -> <|"DeltaCoefficient" -> {0}, 
     "PlusCoefficients" -> <||>, "RegularCoefficient" -> 
      {(FeynFacet`\[Alpha]s*(-2*(-1 + Global`z)*(5 + 7*Global`z) + 
          System`Pi^2*(1 + 2*(-1 + Global`z)*Global`z) + (4 + 8*Global`z^2)*
           System`Log[Global`muF2/Global`muR2] + 
          (2 + 4*(-1 + Global`z)*Global`z)*System`Log[Global`muF2/
              Global`muR2]^2 + 8*Global`z*System`Log[Global`muR2/
             Global`muF2] - 12*System`Log[1 - Global`z] + 
          6*System`Log[(Global`muR2*Global`z)/Global`Q2] - 
          2*(2*System`Log[1 - Global`z] - System`Log[(Global`muR2*Global`z)/
              Global`Q2])*((2 - 3*Global`z)*Global`z + 
            (2 + 4*(-1 + Global`z)*Global`z)*System`Log[1 - Global`z] + 
            (-1 - 2*(-1 + Global`z)*Global`z)*System`Log[(Global`muR2*
                Global`z)/Global`Q2])))/(36*System`Pi)}|>|>|>
