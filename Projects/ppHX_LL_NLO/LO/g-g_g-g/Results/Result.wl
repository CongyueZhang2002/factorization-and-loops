<|"Project" -> "ppHX_LL_NLO", "Channel" -> "g-g_g-g", "Scale" -> Global`s, 
 "Variables" -> {Global`v, Global`w}, "MandelstamVariables" -> 
  {Global`s, Global`t, Global`u}, "DimensionalRegulator" -> Global`Epsilon, 
 "Coupling" -> FeynFacet`\[Alpha]s, "DimensionalPrefactor" -> 
  Global`muR2^(2*Global`Epsilon), "PhysicalChannel" -> 
  <|"Incoming" -> {"g", "g"}, "Observed" -> "g", "Recoil" -> "g"|>, 
 "Polarization" -> <|"Incoming" -> {"L", "L"}, "Observed" -> "U"|>, 
 "ProcessDefinition" -> <|"CoefficientKinematics" -> 
    <|"PositiveFractions" -> System`Automatic, "LaurentValuation" -> 
      <|Global`xa -> -1, Global`xb -> -1, Global`zh -> -2|>, 
     "Scale" -> Global`s, "DimensionlessCoordinates" -> 
      <|Global`x -> -(Global`t/Global`s), Global`y -> -(Global`u/Global`s)|>, 
     "ForbiddenVariables" -> System`Automatic, "BranchGrammar" -> 
      "PositiveMonomialRoots", "PhysicalRegion" -> 
      Global`x > 0 && Global`y > 0 && Global`x + Global`y == 1 && 
       System`Element[Global`x | Global`y, System`Reals], 
     "DistributionFactor" -> FeynFacet`D1g[Global`zh]*
       FeynFacet`g1g[Global`xa]*FeynFacet`g1g[Global`xb]|>, 
   "ColorRules" -> {FeynCalc`CF -> (-1 + FeynCalc`CA^2)/(2*FeynCalc`CA)}, 
   "ConjugateAmplitudes" -> <|"LoopOrder" -> 0, "LoopMomenta" -> {}, 
     "DiagramIndices" -> {1, 2, 3, 4}|>, "ExcludeParticles" -> 
    {FeynArts`S[_], FeynArts`V[1], FeynArts`V[2], FeynArts`V[3]}, 
   "ExcludeTopologies" -> {FeynArts`Tadpoles, FeynArts`WFCorrections}, 
   "ForwardAmplitudes" -> <|"LoopOrder" -> 0, "LoopMomenta" -> {}, 
     "DiagramIndices" -> {1, 2, 3, 4}|>, "GluonPolarizationReferences" -> 
    <|Global`kc -> Global`ka|>, "HadronDualDirection" -> 
    {Global`nb, Global`n} -> {Global`nhb, System`Missing["NotApplicable"]}, 
   "HadronicVariables" -> <|"Coordinates" -> 
      <|Global`Pa -> {0, System`Sqrt[Global`s/(Global`xa*Global`xb)]/
          System`Sqrt[2], 0, 0}, Global`Pb -> 
        {System`Sqrt[Global`s/(Global`xa*Global`xb)]/System`Sqrt[2], 0, 0, 
         0}, Global`Ph -> 
        {-((Global`t*System`Sqrt[Global`xb/(Global`s*Global`xa)]*Global`zh)/
           System`Sqrt[2]), -((Global`u*System`Sqrt[Global`xa/
              (Global`s*Global`xb)]*Global`zh)/System`Sqrt[2]), 
         System`Sqrt[(Global`t*Global`u)/Global`s]*Global`zh, 0}, 
       Global`nh -> {(Global`t*Global`xb)/(Global`u*Global`xa + 
           Global`t*Global`xb), (Global`u*Global`xa)/(Global`u*Global`xa + 
           Global`t*Global`xb), -((System`Sqrt[2]*System`Sqrt[
             Global`t*Global`u*Global`xa*Global`xb])/(Global`u*Global`xa + 
            Global`t*Global`xb)), 0}, Global`nhb -> 
        {(Global`u*Global`xa)/(Global`u*Global`xa + Global`t*Global`xb), 
         (Global`t*Global`xb)/(Global`u*Global`xa + Global`t*Global`xb), 
         (System`Sqrt[2]*System`Sqrt[Global`t*Global`u*Global`xa*Global`xb])/
          (Global`u*Global`xa + Global`t*Global`xb), 0}, 
       Global`SThvec -> {-((System`Sqrt[2]*Global`STh*System`Sqrt[
             Global`t*Global`u*Global`xa*Global`xb]*System`Cos[
             Global`\[Phi]h])/(Global`u*Global`xa + Global`t*Global`xb)), 
         (System`Sqrt[2]*Global`STh*System`Sqrt[Global`t*Global`u*Global`xa*
             Global`xb]*System`Cos[Global`\[Phi]h])/(Global`u*Global`xa + 
           Global`t*Global`xb), -((Global`STh*(-(Global`u*Global`xa) + 
             Global`t*Global`xb)*System`Cos[Global`\[Phi]h])/
           (Global`u*Global`xa + Global`t*Global`xb)), 
         Global`STh*System`Sin[Global`\[Phi]h]}, Global`STavec -> 
        {0, 0, Global`STa*System`Cos[Global`phiA], Global`STa*
          System`Sin[Global`phiA]}, Global`STbvec -> 
        {0, 0, Global`STb*System`Cos[Global`phiB], Global`STb*
          System`Sin[Global`phiB]}|>, "Assumptions" -> 
      Global`s > 0 && Global`t < 0 && Global`u < 0 && FeynCalc`CA > 0 && 
       FeynCalc`CF > 0 && FeynFacet`\[Alpha]s > 0 && 0 < FeynCalc`Epsilon < 
        1 && System`Element[Global`s | Global`t | Global`u | Global`ST | 
         Global`STh | Global`\[Phi]a | Global`\[Phi]h, System`Reals] && 
       Global`s > 0 && Global`t < 0 && Global`u < 0 && 
       Global`s + Global`t + Global`u == 0|>, "HadronLongDirection" -> 
    {Global`n, Global`nb} -> {Global`nh, System`Missing["NotApplicable"]}, 
   "HadronLongSpin" -> {1, 1} -> {0, System`Missing["NotApplicable"]}, 
   "HadronMomentum" -> {Global`Pa, Global`Pb} -> 
     {Global`Ph, System`Missing["NotApplicable"]}, 
   "HadronTransSpin" -> {0, 0} -> {0, System`Missing["NotApplicable"]}, 
   "InsertionLevel" -> {FeynArts`Classes}, "KinematicMassDimensions" -> 
    <|Global`s -> 2, Global`t -> 2, Global`u -> 2|>, 
   "MasslessQuarkFlavors" -> <|"UpType" -> Global`nU, 
     "DownType" -> Global`nD|>, "Model" -> "SMQCD", 
   "MomentumFraction" -> {Global`xa, Global`xb} -> 
     {Global`zh, System`Missing["NotApplicable"]}, 
   "PartonIntegrated" -> {Global`kd}, "PartonMomentum" -> 
    {Global`ka, Global`kb} -> {Global`kc, Global`kd}, 
   "Partons" -> {FeynArts`V[5], FeynArts`V[5]} -> 
     {FeynArts`V[5], FeynArts`V[5]}, "PhaseSpaceMomentum" -> {Global`kd}, 
   "SetDistributionZero" -> {FeynFacet`f1g[Global`xa], 
     FeynFacet`f1g[Global`xb], FeynFacet`G1g[Global`zh]}, 
   "SetMassZero" -> {Global`Pa, Global`Pb, Global`Ph, Global`ka, Global`kb, 
     Global`kc, Global`kd}|>, "Order" -> "LO", "Contribution" -> "Born", 
 "CouplingPower" -> 2, "GeneratedInterferenceCount" -> 16, 
 "Format" -> "FeynFacet-PartonicResult", "FormatVersion" -> 1, 
 "EpsilonRange" -> {0, 1}, "LaurentLowerBound" -> 0, 
 "Coefficients" -> 
  <|0 -> <|"DeltaCoefficient" -> (-4*FeynCalc`CA^2*(1 - Global`v + 
         Global`v^2)*(2 - Global`v + Global`v^2)*FeynFacet`\[Alpha]s^2)/
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`s^2*(-1 + Global`v)*
        Global`v^2), "PlusCoefficients" -> <||>, "RegularCoefficient" -> 0|>, 
   1 -> <|"DeltaCoefficient" -> (-4*FeynCalc`CA^2*(1 - Global`v + Global`v^2)*
        FeynFacet`\[Alpha]s^2*(Global`v - Global`v^2 + 4*System`Log[2] - 
         2*Global`v*System`Log[2] + 2*Global`v^2*System`Log[2] + 
         4*System`Log[System`Pi] - 2*Global`v*System`Log[System`Pi] + 
         2*Global`v^2*System`Log[System`Pi]))/((-1 + FeynCalc`CA)*
        (1 + FeynCalc`CA)*Global`s^2*(-1 + Global`v)*Global`v^2), 
     "PlusCoefficients" -> <||>, "RegularCoefficient" -> 0|>|>, 
 "DensityConvention" -> "E_c d sigma/d^(D-1)p_c", 
 "DistributionBasis" -> <|"Variable" -> Global`w, "Endpoint" -> 1, 
   "Interval" -> {0, 1}, "Distance" -> 1 - Global`w|>, 
 "PlusConvention" -> "At each axis, PlusCoefficients[k] multiplies \
[Log[Distance]^k/Distance]_+ on Interval, with subtraction at Endpoint. For \
DistributionBasis[Axes], delta/plus/regular values repeat recursively in the \
listed axis order."|>
