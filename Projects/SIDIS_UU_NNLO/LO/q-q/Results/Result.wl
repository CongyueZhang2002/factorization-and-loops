<|"FactorizationLegs" -> <|"Incoming" -> <|"Role" -> "PDF", "Index" -> 1, 
     "Variable" -> Global`x|>, "Observed" -> <|"Role" -> "FF", 
     "Variable" -> Global`z|>|>, "Scale" -> Global`Q2, 
 "Variables" -> {Global`x, Global`z}, "Assumptions" -> 
  Global`Q2 > 0 && Global`muR2 > 0, 
 "Domain" -> Global`Q2 > 0 && System`Inequality[0, System`Less, Global`x, 
    System`LessEqual, 1] && System`Inequality[0, System`Less, Global`z, 
    System`LessEqual, 1], "DensityConvention" -> 
  "Dimensionless electromagnetic SIDIS coefficient, flavor charge included", 
 "CurrentNormalization" -> 1/(4*System`Pi), "EndpointExpansion" -> 
  <|"NormalVariables" -> {Global`endpointX, Global`endpointZ}, 
   "TestFunctionSupport" -> <|"ExcludedFaces" -> {Global`endpointX -> 1, 
       Global`endpointZ -> 1}|>|>, "BareCouplingRules" -> 
  {FeynCalc`SMP["g_s"]^2 -> System`E^(Global`Epsilon*System`EulerGamma)*
     Global`muR2^Global`Epsilon*(4*System`Pi)^(1 - Global`Epsilon)*
     FeynFacet`\[Alpha]s}, "MeasuredPhaseSpace" -> 
  <|"ReferenceMomentum" -> Global`p, "MeasurementVariable" -> Global`z, 
   "ExternalKinematicConditions" -> Global`Q2 > 0 && 0 < Global`x < 1|>, 
 "JointAngularAverage" -> <|"PhysicalMomenta" -> {Global`p, Global`q}, 
   "IntegratedMomenta" -> {Global`k1, Global`k2}, 
   "MomentumRules" -> {Global`k3 -> -Global`k1 - Global`k2 + Global`p + 
       Global`q}, "TimelikeMomentum" -> Global`p + Global`q, 
   "DimensionalRegulator" -> Global`Epsilon, "KinematicRules" -> 
    {FeynCalc`SPD[Global`p, Global`p] -> 0, 
     FeynCalc`SPD[Global`q, Global`q] -> -Global`Q2, 
     FeynCalc`SPD[Global`p, Global`q] -> Global`Q2/(2*Global`x)}, 
   "Assumptions" -> Global`Q2 > 0 && 0 < Global`x < 1 && 0 < Global`z < 1|>, 
 "TwoParticleMeasurement" -> <|"ReferenceMomentum" -> Global`p, 
   "TotalMomentum" -> Global`pTotal, "FinalMomenta" -> 
    {Global`k1, Global`k2}, "InvariantMassSquared" -> 
    (Global`Q2*(1 - Global`x))/Global`x, "ReferenceProjection" -> 
    Global`Q2/(2*Global`x), "MeasurementVariable" -> Global`z, 
   "EvanescentSquare" -> Global`kappa, "MomentumRules" -> 
    {Global`q -> -Global`p + Global`pTotal}, "Assumptions" -> 
    Global`Q2 > 0 && 0 < Global`x < 1 && 0 < Global`z < 1|>, 
 "BornSupportKinematicRules" -> {FeynCalc`SPD[Global`p, Global`p] -> 0, 
   FeynCalc`SPD[Global`q, Global`q] -> -Global`Q2, 
   FeynCalc`SPD[Global`p, Global`q] -> Global`Q2/(2*Global`x)}, 
 "DistributionBasis" -> 
  <|"Axes" -> {<|"Variable" -> Global`x, "Endpoint" -> 1, 
      "Interval" -> {0, 1}, "Distance" -> 1 - Global`x, 
      "NormalVariable" -> Global`endpointX|>, <|"Variable" -> Global`z, 
      "Endpoint" -> 1, "Interval" -> {0, 1}, "Distance" -> 1 - Global`z, 
      "NormalVariable" -> Global`endpointZ|>}|>, 
 "Project" -> "SIDIS_UU_NNLO", "Channel" -> "q-q", 
 "PhysicalChannel" -> <|"Incoming" -> {{"q", "u"}}, 
   "Observed" -> {"q", "u"}|>, "Polarization" -> 
  <|"Incoming" -> {"U"}, "Observed" -> "U"|>, 
 "ColorRules" -> {FeynCalc`CF -> (-1 + FeynCalc`CA^2)/(2*FeynCalc`CA)}, 
 "Kernels" -> 8, "KinematicConditions" -> Global`x == 1 && Global`z == 1, 
 "Coupling" -> FeynFacet`\[Alpha]s, "DimensionalPrefactor" -> 1, 
 "CouplingPower" -> 0, "DimensionalRegulator" -> Global`Epsilon, 
 "ProcessDefinition" -> <|"ConjugateAmplitudes" -> 
    <|"LoopOrder" -> 0, "LoopMomenta" -> {}, "DiagramIndices" -> {1}|>, 
   "Currents" -> {<|"Momentum" -> Global`q, "Indices" -> 
       <|"Conjugate" -> Global`mu, "Amplitude" -> Global`nu|>, 
      "Coupling" -> FeynCalc`SMP["e"]|>}, "ElectromagneticCharges" -> 
    <|"UpType" -> Global`eU, "DownType" -> Global`eD|>, 
   "ExcludeParticles" -> {FeynArts`S[_], FeynArts`V[1], FeynArts`V[2], 
     FeynArts`V[3]}, "ExcludeTopologies" -> {FeynArts`Tadpoles, 
     FeynArts`WFCorrections}, "ForwardAmplitudes" -> 
    <|"LoopOrder" -> 0, "LoopMomenta" -> {}, "DiagramIndices" -> {1}|>, 
   "InsertionLevel" -> {FeynArts`Classes}, "MasslessMomenta" -> 
    {Global`p, Global`k1}, "MasslessQuarkFlavors" -> 
    <|"UpType" -> Global`nU, "DownType" -> Global`nD|>, "Model" -> "SMQCD", 
   "PartonMomentum" -> {Global`p, Global`q} -> {Global`k1}, 
   "Partons" -> {FeynArts`F[3, {1}], FeynArts`V[1]} -> {FeynArts`F[3, {1}]}, 
   "PhysicalMomenta" -> {Global`p, Global`q}, "SpinDensities" -> 
    {<|"Role" -> "PDF", "Species" -> {"q", "u"}, "Polarization" -> "U", 
      "Momentum" -> Global`p, "MomentumSpace" -> "Physical4"|>, 
     <|"Role" -> "FF", "Species" -> {"q", "u"}, "Polarization" -> "U", 
      "Momentum" -> Global`k1, "MomentumSpace" -> "IntegratedD"|>}, 
   "SummedGluons" -> {}, "UnobservedPartons" -> {}|>, "Order" -> "LO", 
 "Contribution" -> "Born", "StructureFunctions" -> {"2F1", "FL/x"}, 
 "Format" -> "FeynFacet-PartonicResult", "FormatVersion" -> 1, 
 "EpsilonRange" -> {0, 2}, "LaurentLowerBound" -> 0, 
 "Coefficients" -> 
  <|0 -> <|"DeltaCoefficient" -> <|"DeltaCoefficient" -> {Global`eU^2, 0}, 
       "PlusCoefficients" -> <||>, "RegularCoefficient" -> 0|>, 
     "PlusCoefficients" -> <||>, "RegularCoefficient" -> 
      <|"DeltaCoefficient" -> 0, "PlusCoefficients" -> <||>, 
       "RegularCoefficient" -> 0|>|>, 
   1 -> <|"DeltaCoefficient" -> <|"DeltaCoefficient" -> {0, 0}, 
       "PlusCoefficients" -> <||>, "RegularCoefficient" -> 0|>, 
     "PlusCoefficients" -> <||>, "RegularCoefficient" -> 
      <|"DeltaCoefficient" -> 0, "PlusCoefficients" -> <||>, 
       "RegularCoefficient" -> 0|>|>, 
   2 -> <|"DeltaCoefficient" -> <|"DeltaCoefficient" -> {0, 0}, 
       "PlusCoefficients" -> <||>, "RegularCoefficient" -> 0|>, 
     "PlusCoefficients" -> <||>, "RegularCoefficient" -> 
      <|"DeltaCoefficient" -> 0, "PlusCoefficients" -> <||>, 
       "RegularCoefficient" -> 0|>|>|>, "PlusConvention" -> "At each axis, \
PlusCoefficients[k] multiplies [Log[Distance]^k/Distance]_+ on Interval, with \
subtraction at Endpoint. For DistributionBasis[Axes], delta/plus/regular \
values repeat recursively in the listed axis order.", 
 "RenormalizationStage" -> "Bare"|>
