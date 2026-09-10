<|"Scale" -> Global`Q2, "Variables" -> {Global`z}, 
 "Assumptions" -> Global`Q2 > 0 && Global`muR2 > 0, 
 "Domain" -> Global`Q2 > 0 && System`Inequality[0, System`Less, Global`z, 
    System`LessEqual, 1], "DensityConvention" -> "d sigma_hat/d Q2 = 4 pi \
alpha_em^2/(3 Nc Q2 s) C_DY(z), z=Q2/s; flavor charge included", 
 "LeptonicConvention" -> "The entire scalar integrated leptonic tensor is \
factored out in D dimensions; its physical four-dimensional normalization is \
restored in the cross section.", "CurrentNormalization" -> 
  FeynCalc`CA/(2*System`Pi), "FactorizationLegs" -> 
  <|"IncomingA" -> <|"Role" -> "PDF", "Index" -> 1, "Variable" -> Global`z|>, 
   "IncomingB" -> <|"Role" -> "PDF", "Index" -> 2, 
     "Variable" -> Global`z|>|>, "EndpointExpansion" -> 
  <|"NormalVariables" -> {Global`endpointZ}, "EndpointPowers" -> 
    {-1 - 2*Global`Epsilon}, "TestFunctionSupport" -> 
    <|"ExcludedFaces" -> {Global`endpointZ -> 1}|>, 
   "EndpointConditions" -> <|"JointlySmoothFactors" -> System`True, 
     "UniformEpsilonExpansion" -> System`True, "NoOtherSingularities" -> 
      System`True|>|>, "BareCouplingRules" -> 
  {FeynCalc`SMP["g_s"]^2 -> System`E^(Global`Epsilon*System`EulerGamma)*
     Global`muR2^Global`Epsilon*(4*System`Pi)^(1 - Global`Epsilon)*
     FeynFacet`\[Alpha]s}, "IntegratedPhaseSpaceVariables" -> 
  {Global`angleY}, "TwoParticleMeasurement" -> 
  <|"ReferenceMomentum" -> Global`pa, "TotalMomentum" -> Global`pTotal, 
   "FinalMomenta" -> {Global`k1, Global`q}, "InvariantMassSquared" -> 
    Global`Q2/Global`z, "ReferenceProjection" -> Global`Q2/(2*Global`z), 
   "MassesSquared" -> {0, Global`Q2}, "MeasurementVariable" -> Global`angleY, 
   "EvanescentSquare" -> Global`kappa, "MomentumRules" -> 
    {Global`pb -> -Global`pa + Global`pTotal}, 
   "Assumptions" -> Global`Q2 > 0 && 0 < Global`z < 1 && 
     0 < Global`angleY < 1|>, "DistributionBasis" -> 
  <|"Axes" -> {<|"Variable" -> Global`z, "Endpoint" -> 1, 
      "Interval" -> {0, 1}, "Distance" -> 1 - Global`z, 
      "NormalVariable" -> Global`endpointZ|>}|>, 
 "Project" -> "DrellYan_UU_NLO", "Channel" -> "qbar-q", 
 "PhysicalChannel" -> <|"Incoming" -> {{"qbar", "u"}, {"q", "u"}}|>, 
 "Polarization" -> <|"Incoming" -> {"U", "U"}|>, 
 "ColorRules" -> {FeynCalc`CF -> (-1 + FeynCalc`CA^2)/(2*FeynCalc`CA)}, 
 "Kernels" -> 8, "KinematicConditions" -> Global`z == 1, 
 "Coupling" -> FeynFacet`\[Alpha]s, "DimensionalPrefactor" -> 1, 
 "CouplingPower" -> 0, "DimensionalRegulator" -> Global`Epsilon, 
 "ProcessDefinition" -> <|"ConjugateAmplitudes" -> 
    <|"LoopOrder" -> 0, "LoopMomenta" -> {}, "DiagramIndices" -> {1}|>, 
   "Currents" -> {<|"Momentum" -> Global`q, "Indices" -> 
       <|"Conjugate" -> Global`mu, "Amplitude" -> Global`nu|>, 
      "Coupling" -> FeynCalc`SMP["e"]|>}, "ExcludeParticles" -> 
    {FeynArts`S[_], FeynArts`V[1], FeynArts`V[2], FeynArts`V[3]}, 
   "ExcludeTopologies" -> {FeynArts`Tadpoles, FeynArts`WFCorrections}, 
   "ForwardAmplitudes" -> <|"LoopOrder" -> 0, "LoopMomenta" -> {}, 
     "DiagramIndices" -> {1}|>, "InsertionLevel" -> {FeynArts`Classes}, 
   "MasslessMomenta" -> {Global`pa, Global`pb}, "MasslessQuarkFlavors" -> 
    <|"UpType" -> Global`nU, "DownType" -> Global`nD|>, "Model" -> "SMQCD", 
   "PartonMomentum" -> {Global`pa, Global`pb} -> {Global`q}, 
   "Partons" -> {-FeynArts`F[3, {1}], FeynArts`F[3, {1}]} -> {FeynArts`V[1]}, 
   "PhysicalMomenta" -> {Global`pa, Global`pb}, 
   "SpinDensities" -> {<|"Role" -> "PDF", "Species" -> {"qbar", "u"}, 
      "Polarization" -> "U", "Momentum" -> Global`pa, 
      "MomentumSpace" -> "Physical4"|>, <|"Role" -> "PDF", 
      "Species" -> {"q", "u"}, "Polarization" -> "U", 
      "Momentum" -> Global`pb, "MomentumSpace" -> "Physical4"|>}, 
   "SummedGluons" -> {}, "UnobservedPartons" -> {}|>, 
 "BornCouplingPower" -> 0, "Order" -> "LO", "Contribution" -> "Born", 
 "StructureFunctions" -> {"C_DY"}, "Format" -> "FeynFacet-PartonicResult", 
 "FormatVersion" -> 1, "EpsilonRange" -> {0, 2}, "LaurentLowerBound" -> 0, 
 "Coefficients" -> <|0 -> <|"DeltaCoefficient" -> {4/9}, 
     "PlusCoefficients" -> <||>, "RegularCoefficient" -> 0|>, 
   1 -> <|"DeltaCoefficient" -> {-4/9}, "PlusCoefficients" -> <||>, 
     "RegularCoefficient" -> 0|>, 2 -> <|"DeltaCoefficient" -> {0}, 
     "PlusCoefficients" -> <||>, "RegularCoefficient" -> 0|>|>, 
 "PlusConvention" -> "At each axis, PlusCoefficients[k] multiplies \
[Log[Distance]^k/Distance]_+ on Interval, with subtraction at Endpoint. For \
DistributionBasis[Axes], delta/plus/regular values repeat recursively in the \
listed axis order."|>
