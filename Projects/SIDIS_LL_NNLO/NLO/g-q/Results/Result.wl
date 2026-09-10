<|"Channel" -> "g-q", "Coupling" -> FeynFacet`\[Alpha]s, 
 "CouplingPower" -> 1, "CurrentNormalization" -> 1/(4*System`Pi), 
 "DensityConvention" -> 
  "Dimensionless electromagnetic SIDIS coefficient, flavor charge included", 
 "DimensionalPrefactor" -> 1, "DimensionalRegulator" -> Global`Epsilon, 
 "DistributionBasis" -> 
  <|"Axes" -> {<|"Variable" -> Global`x, "Endpoint" -> 1, 
      "Interval" -> {0, 1}, "Distance" -> 1 - Global`x, 
      "NormalVariable" -> Global`endpointX|>, <|"Variable" -> Global`z, 
      "Endpoint" -> 1, "Interval" -> {0, 1}, "Distance" -> 1 - Global`z, 
      "NormalVariable" -> Global`endpointZ|>}|>, "Order" -> "NLO", 
 "PhysicalChannel" -> <|"Incoming" -> {"g"}, "Observed" -> {"q", "u"}|>, 
 "Polarization" -> <|"Incoming" -> {"L"}, "Observed" -> "U"|>, 
 "Project" -> "SIDIS_LL_NNLO", "Scale" -> Global`Q2, 
 "StructureFunctions" -> {"2g1"}, "Variables" -> {Global`x, Global`z}, 
 "Contribution" -> "Total", "IncludedContributions" -> 
  {"Real", "Counterterm"}, "PlusConvention" -> "At each axis, \
PlusCoefficients[k] multiplies [Log[Distance]^k/Distance]_+ on Interval, with \
subtraction at Endpoint. For DistributionBasis[Axes], delta/plus/regular \
values repeat recursively in the listed axis order.", 
 "RequiredContributions" -> {"Real", "Counterterm"}, 
 "Assumptions" -> Global`Q2 > 0 && Global`muR2 > 0 && Global`muF2 > 0 && 
   Global`muD2 > 0, "Schemes" -> <|"Incoming" -> "HelicityMSbar", 
   "Observed" -> "MSbar"|>, "LowerOrderResults" -> 
  <|"q-q" -> <|"File" -> "../../../LO/q-q/Results/Result.wl", 
     "EpsilonRange" -> {0, 2}|>, "qbar-qbar" -> 
    <|"File" -> "../../../LO/qbar-qbar/Results/Result.wl", 
     "EpsilonRange" -> {0, 2}|>|>, "Format" -> "FeynFacet-PartonicResult", 
 "FormatVersion" -> 1, "EpsilonRange" -> {0, 1}, "LaurentLowerBound" -> 0, 
 "Coefficients" -> 
  <|0 -> <|"DeltaCoefficient" -> <|"DeltaCoefficient" -> {0}, 
       "PlusCoefficients" -> <||>, "RegularCoefficient" -> {0}|>, 
     "PlusCoefficients" -> <||>, "RegularCoefficient" -> 
      <|"DeltaCoefficient" -> {(FeynFacet`\[Alpha]s*
           (System`Log[Global`muF2] + System`Log[Global`x] - 
            2*(-1 + Global`x + Global`x*System`Log[Global`muF2*Global`x]) + 
            (-1 + 2*Global`x)*System`Log[Global`Q2 - Global`Q2*Global`x]))/
          (9*System`Pi)}, "PlusCoefficients" -> 
        <|0 -> {((-1 + 2*Global`x)*FeynFacet`\[Alpha]s)/(9*System`Pi)}|>, 
       "RegularCoefficient" -> {-1/9*((-1 + 2*Global`x)*(-1 + 2*Global`z)*
            FeynFacet`\[Alpha]s)/(System`Pi*Global`z)}|>|>, 
   1 -> <|"DeltaCoefficient" -> <|"DeltaCoefficient" -> {0}, 
       "PlusCoefficients" -> <||>, "RegularCoefficient" -> {0}|>, 
     "PlusCoefficients" -> <||>, "RegularCoefficient" -> 
      <|"DeltaCoefficient" -> {(FeynFacet`\[Alpha]s*(24 - System`Pi^2 + 
            2*(-12 + System`Pi^2)*Global`x + 6*(-1 + 2*Global`x)*
             System`Log[Global`muR2/Global`muF2]^2 + (6 - 12*Global`x)*
             System`Log[1 - Global`x]^2 + 6*System`Log[(Global`muR2*Global`x)/
               Global`Q2]*(4 - 4*Global`x + (1 - 2*Global`x)*System`Log[
                (Global`muR2*Global`x)/Global`Q2]) + 
            12*System`Log[1 - Global`x]*(2*(-1 + Global`x) + 
              (-1 + 2*Global`x)*System`Log[(Global`muR2*Global`x)/
                 Global`Q2])))/(108*System`Pi)}, "PlusCoefficients" -> 
        <|0 -> {(FeynFacet`\[Alpha]s*(2*(-1 + Global`x) + (1 - 2*Global`x)*
               System`Log[1 - Global`x] + (-1 + 2*Global`x)*System`Log[
                (Global`muR2*Global`x)/Global`Q2]))/(9*System`Pi)}, 
         1 -> {(FeynFacet`\[Alpha]s - 2*Global`x*FeynFacet`\[Alpha]s)/
            (9*System`Pi)}|>, "RegularCoefficient" -> 
        {(FeynFacet`\[Alpha]s*((-1 + 2*Global`x)*(-1 + Global`z)*
             (-1 + 2*Global`z)*System`Log[1 - Global`x] + (-1 + 2*Global`x)*
             Global`z*System`Log[(Global`muR2*Global`x)/Global`Q2] + 
            (-1 + Global`z)*(-1 + 2*Global`z)*(2 - 2*Global`x + 
              (-1 + 2*Global`x)*System`Log[1 - Global`z]) - 
            (-1 + 2*Global`x)*(1 + 2*(-1 + Global`z)*Global`z)*
             System`Log[(Global`muR2*Global`x)/(Global`Q2*Global`z)]))/
          (9*System`Pi*(-1 + Global`z)*Global`z)}|>|>|>|>
