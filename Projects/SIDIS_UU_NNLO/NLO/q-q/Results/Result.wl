<|"Channel" -> "q-q", "Coupling" -> FeynFacet`\[Alpha]s, 
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
 "PhysicalChannel" -> <|"Incoming" -> {{"q", "u"}}, 
   "Observed" -> {"q", "u"}|>, "Polarization" -> 
  <|"Incoming" -> {"U"}, "Observed" -> "U"|>, "Project" -> "SIDIS_UU_NNLO", 
 "Scale" -> Global`Q2, "StructureFunctions" -> {"2F1", "FL/x"}, 
 "Variables" -> {Global`x, Global`z}, "Contribution" -> "Total", 
 "IncludedContributions" -> {"Real", "Virtual", "Counterterm"}, 
 "PlusConvention" -> "At each axis, PlusCoefficients[k] multiplies \
[Log[Distance]^k/Distance]_+ on Interval, with subtraction at Endpoint. For \
DistributionBasis[Axes], delta/plus/regular values repeat recursively in the \
listed axis order.", "RequiredContributions" -> 
  {"Real", "Virtual", "Counterterm"}, "Assumptions" -> 
  Global`Q2 > 0 && Global`muR2 > 0 && Global`muF2 > 0 && Global`muD2 > 0, 
 "Schemes" -> <|"Incoming" -> "MSbar", "Observed" -> "MSbar"|>, 
 "LowerOrderResults" -> 
  <|"q-q" -> <|"File" -> "../../../LO/q-q/Results/Result.wl", 
     "EpsilonRange" -> {0, 2}|>, "qbar-qbar" -> 
    <|"File" -> "../../../LO/qbar-qbar/Results/Result.wl", 
     "EpsilonRange" -> {0, 2}|>|>, "Format" -> "FeynFacet-PartonicResult", 
 "FormatVersion" -> 1, "EpsilonRange" -> {0, 1}, "LaurentLowerBound" -> 0, 
 "Coefficients" -> 
  <|0 -> <|"DeltaCoefficient" -> <|"DeltaCoefficient" -> 
        {-1/18*((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*
            (16 + 3*System`Log[Global`muD2*Global`muF2] - 
             6*System`Log[Global`Q2]))/(FeynCalc`CA*System`Pi), 0}, 
       "PlusCoefficients" -> 
        <|0 -> {(2*(-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*
             System`Log[Global`Q2/Global`muD2])/(9*FeynCalc`CA*System`Pi), 
           0}, 1 -> {(2*(-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s)/
            (9*FeynCalc`CA*System`Pi), 0}|>, "RegularCoefficient" -> 
        {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*(-(-1 + Global`z)^2 + 
            (-1 + Global`z^2)*System`Log[Global`muD2] + (1 + Global`z^2)*
             System`Log[Global`z^(-1)] - (-1 + Global`z^2)*
             System`Log[Global`Q2 - Global`Q2*Global`z]))/
          (9*FeynCalc`CA*System`Pi*(-1 + Global`z)), 0}|>, 
     "PlusCoefficients" -> <|0 -> <|"DeltaCoefficient" -> 
          {(2*(-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*System`Log[
              Global`Q2/Global`muF2])/(9*FeynCalc`CA*System`Pi), 0}, 
         "PlusCoefficients" -> <|0 -> {(2*(-1 + FeynCalc`CA^2)*
               FeynFacet`\[Alpha]s)/(9*FeynCalc`CA*System`Pi), 0}|>, 
         "RegularCoefficient" -> {-1/9*((-1 + FeynCalc`CA^2)*(1 + Global`z)*
              FeynFacet`\[Alpha]s)/(FeynCalc`CA*System`Pi), 0}|>, 
       1 -> <|"DeltaCoefficient" -> {(2*(-1 + FeynCalc`CA^2)*
             FeynFacet`\[Alpha]s)/(9*FeynCalc`CA*System`Pi), 0}, 
         "PlusCoefficients" -> <||>, "RegularCoefficient" -> {0, 0}|>|>, 
     "RegularCoefficient" -> <|"DeltaCoefficient" -> 
        {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*(-(-1 + Global`x)^2 - 
            System`Log[Global`muF2] + System`Log[Global`x] + 
            Global`x^2*System`Log[Global`muF2*Global`x] - (-1 + Global`x^2)*
             System`Log[Global`Q2 - Global`Q2*Global`x]))/
          (9*FeynCalc`CA*System`Pi*(-1 + Global`x)), 0}, 
       "PlusCoefficients" -> 
        <|0 -> {-1/9*((-1 + FeynCalc`CA^2)*(1 + Global`x)*
              FeynFacet`\[Alpha]s)/(FeynCalc`CA*System`Pi), 0}|>, 
       "RegularCoefficient" -> {(2*(-1 + FeynCalc`CA^2)*
           (1 + Global`x*Global`z)*FeynFacet`\[Alpha]s)/(9*FeynCalc`CA*
           System`Pi), (4*(-1 + FeynCalc`CA^2)*Global`x*Global`z*
           FeynFacet`\[Alpha]s)/(9*FeynCalc`CA*System`Pi)}|>|>, 
   1 -> <|"DeltaCoefficient" -> <|"DeltaCoefficient" -> 
        {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*(-64 + System`Pi^2 + 
            3*System`Log[Global`muD2]^2 + 3*System`Log[Global`muF2]^2 - 
            2*System`Log[Global`muR2]*(16 + 3*System`Log[Global`muD2*
                 Global`muF2] - 6*System`Log[Global`Q2]) + 
            32*System`Log[Global`Q2] - 6*System`Log[Global`Q2]^2 + 
            16*System`Zeta[3]))/(36*FeynCalc`CA*System`Pi), 0}, 
       "PlusCoefficients" -> 
        <|0 -> {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*(System`Pi^2 + 
              6*System`Log[Global`muR2/Global`muD2]^2 - 
              6*System`Log[Global`muR2/Global`Q2]^2))/(54*FeynCalc`CA*
             System`Pi), 0}, 1 -> {(2*(-1 + FeynCalc`CA^2)*
             FeynFacet`\[Alpha]s*System`Log[Global`muR2/Global`Q2])/
            (9*FeynCalc`CA*System`Pi), 0}, 
         2 -> {-1/9*((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s)/
             (FeynCalc`CA*System`Pi), 0}|>, "RegularCoefficient" -> 
        {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*
           (-(System`Pi^2*(-1 + Global`z^2)) - 6*(-1 + Global`z^2)*
             System`Log[Global`muD2/Global`muR2]^2 - 
            12*System`Log[Global`muR2/Global`Q2]^2 + 
            24*System`Log[Global`muR2/Global`Q2]*System`Log[1 - Global`z] + 
            6*System`Log[1 - Global`z]*(2*(-1 + Global`z)^2 + 
              (-1 + Global`z^2)*System`Log[1 - Global`z]) - 
            12*((-1 + Global`z)^2 + (1 + Global`z^2)*System`Log[
                1 - Global`z])*System`Log[Global`muR2/(Global`Q2*Global`z)] + 
            6*(1 + Global`z^2)*System`Log[Global`muR2/(Global`Q2*Global`z)]^
              2))/(108*FeynCalc`CA*System`Pi*(-1 + Global`z)), 0}|>, 
     "PlusCoefficients" -> <|0 -> <|"DeltaCoefficient" -> 
          {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*(System`Pi^2 + 
              6*System`Log[Global`muR2/Global`muF2]^2 - 
              6*System`Log[Global`muR2/Global`Q2]^2))/(54*FeynCalc`CA*
             System`Pi), 0}, "PlusCoefficients" -> 
          <|0 -> {(2*(-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*System`Log[
                Global`muR2/Global`Q2])/(9*FeynCalc`CA*System`Pi), 0}, 
           1 -> {(-2*(-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s)/
              (9*FeynCalc`CA*System`Pi), 0}|>, "RegularCoefficient" -> 
          {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*((-1 + Global`z)^2 + 
              (-1 + Global`z^2)*System`Log[1 - Global`z] - Global`z^2*
               System`Log[Global`muR2/(Global`Q2*Global`z)] - 
              System`Log[Global`Q2/(Global`muR2*Global`z)]))/
            (9*FeynCalc`CA*System`Pi*(-1 + Global`z)), 0}|>, 
       1 -> <|"DeltaCoefficient" -> {(2*(-1 + FeynCalc`CA^2)*
             FeynFacet`\[Alpha]s*System`Log[Global`muR2/Global`Q2])/
            (9*FeynCalc`CA*System`Pi), 0}, "PlusCoefficients" -> 
          <|0 -> {(-2*(-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s)/
              (9*FeynCalc`CA*System`Pi), 0}|>, "RegularCoefficient" -> 
          {((-1 + FeynCalc`CA^2)*(1 + Global`z)*FeynFacet`\[Alpha]s)/
            (9*FeynCalc`CA*System`Pi), 0}|>, 
       2 -> <|"DeltaCoefficient" -> {-1/9*((-1 + FeynCalc`CA^2)*
              FeynFacet`\[Alpha]s)/(FeynCalc`CA*System`Pi), 0}, 
         "PlusCoefficients" -> <||>, "RegularCoefficient" -> {0, 0}|>|>, 
     "RegularCoefficient" -> <|"DeltaCoefficient" -> 
        {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*
           (-(System`Pi^2*(-1 + Global`x^2)) - 6*(-1 + Global`x^2)*
             System`Log[Global`muR2/Global`muF2]^2 - 
            12*System`Log[Global`muR2/Global`Q2]^2 + 
            24*System`Log[Global`muR2/Global`Q2]*System`Log[1 - Global`x] + 
            6*System`Log[1 - Global`x]*(2*(-1 + Global`x)^2 + 
              (-1 + Global`x^2)*System`Log[1 - Global`x]) - 
            12*((-1 + Global`x)^2 + (1 + Global`x^2)*System`Log[
                1 - Global`x])*System`Log[(Global`muR2*Global`x)/Global`Q2] + 
            6*(1 + Global`x^2)*System`Log[(Global`muR2*Global`x)/Global`Q2]^
              2))/(108*FeynCalc`CA*System`Pi*(-1 + Global`x)), 0}, 
       "PlusCoefficients" -> 
        <|0 -> {((-1 + FeynCalc`CA^2)*FeynFacet`\[Alpha]s*
             ((-1 + Global`x)^2 + 2*System`Log[Global`muR2] - 
              2*System`Log[Global`Q2] + (-1 + Global`x^2)*System`Log[
                1 - Global`x] - (1 + Global`x^2)*System`Log[
                (Global`muR2*Global`x)/Global`Q2]))/(9*FeynCalc`CA*System`Pi*
             (-1 + Global`x)), 0}, 1 -> {((-1 + FeynCalc`CA^2)*(1 + Global`x)*
             FeynFacet`\[Alpha]s)/(9*FeynCalc`CA*System`Pi), 0}|>, 
       "RegularCoefficient" -> {-1/9*((-1 + FeynCalc`CA^2)*
            FeynFacet`\[Alpha]s*(-2*(-1 + Global`x)*(-1 + Global`z) + 
             2*(-Global`z + Global`x*(-1 + Global`z)*(1 + (-1 + Global`x)*
                  Global`z))*System`Log[1 - Global`x] + System`Log[
              Global`x] + Global`x^2*System`Log[(Global`muR2*Global`x)/
                Global`Q2] + 2*System`Log[Global`muR2 - Global`muR2*
                 Global`x] + 2*System`Log[1 - Global`z] - 
             2*Global`x*System`Log[1 - Global`z] - 2*Global`z*
              System`Log[1 - Global`z] + 4*Global`x*Global`z*System`Log[1 - 
                Global`z] - 2*Global`x^2*Global`z*System`Log[1 - Global`z] - 
             2*Global`x*Global`z^2*System`Log[1 - Global`z] + 
             2*Global`x^2*Global`z^2*System`Log[1 - Global`z] + 
             System`Log[Global`z^(-1)] + Global`z^2*System`Log[Global`muR2/
                (Global`Q2*Global`z)] - ((-2 + Global`x)*Global`x - 2*
                (-1 + Global`x)^2*Global`z + (1 + 2*(-1 + Global`x)*Global`x)*
                Global`z^2)*System`Log[(Global`muR2*Global`x)/(Global`Q2*
                 Global`z)] - 2*System`Log[(Global`muR2^2*Global`x)/
                (Global`Q2*Global`z)]))/(FeynCalc`CA*System`Pi*
            (-1 + Global`x)*(-1 + Global`z)), (-4*(-1 + FeynCalc`CA^2)*
           Global`x*Global`z*FeynFacet`\[Alpha]s*
           (1 + System`Log[1 - Global`x] + System`Log[1 - Global`z] - 
            System`Log[(Global`muR2*Global`x)/(Global`Q2*Global`z)]))/
          (9*FeynCalc`CA*System`Pi)}|>|>|>|>
