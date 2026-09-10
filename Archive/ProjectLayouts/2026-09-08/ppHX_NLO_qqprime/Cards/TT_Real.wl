<|"ForwardAmplitudes" -> <|"LoopOrder" -> 0, "LoopMomenta" -> {}, 
   "DiagramIndices" -> {1, 2, 3, 4, 5}|>, "ConjugateAmplitudes" -> 
  <|"LoopOrder" -> 0, "LoopMomenta" -> {}, "DiagramIndices" -> {1, 2, 3, 4, 
    5}|>, "Partons" -> {F[3, {1}], F[4, {1}]} -> 
   {F[3, {1}], F[4, {1}], V[5]}, "Model" -> "SMQCD", 
 "InsertionLevel" -> {Classes}, "ExcludeTopologies" -> 
  {Tadpoles, WFCorrections}, "ExcludeParticles" -> {S[_], V[1], V[2], V[3]}, 
 "PartonMomentum" -> {ka, kb} -> {kc, kd, ke}, 
 "PhaseSpaceMomentum" -> {kd, ke}, "PartonIntegrated" -> {kd}, 
 "MomentumFraction" -> {xa, xb} -> {zh, Missing["NotApplicable"], 
    Missing["NotApplicable"]}, "HadronMomentum" -> 
  {Pa, Pb} -> {Ph, Missing["NotApplicable"], Missing["NotApplicable"]}, 
 "HadronLongDirection" -> {n, nb} -> {nh, Missing["NotApplicable"], 
    Missing["NotApplicable"]}, "HadronDualDirection" -> 
  {nb, n} -> {nhb, Missing["NotApplicable"], Missing["NotApplicable"]}, 
 "HadronLongSpin" -> {0, 0} -> {0, Missing["NotApplicable"], 
    Missing["NotApplicable"]}, "HadronTransSpin" -> 
  {STavec, STbvec} -> {0, Missing["NotApplicable"], 
    Missing["NotApplicable"]}, "HadronicVariables" -> 
  <|"Coordinates" -> <|Pa -> {0, Sqrt[s/(xa*xb)]/Sqrt[2], 0, 0}, 
     Pb -> {Sqrt[s/(xa*xb)]/Sqrt[2], 0, 0, 0}, 
     Ph -> {-((t*Sqrt[xb/(s*xa)]*zh)/Sqrt[2]), 
       -((u*Sqrt[xa/(s*xb)]*zh)/Sqrt[2]), Sqrt[(t*u)/s]*zh, 0}, 
     nh -> {(t*xb)/(u*xa + t*xb), (u*xa)/(u*xa + t*xb), 
       -((Sqrt[2]*Sqrt[t*u*xa*xb])/(u*xa + t*xb)), 0}, 
     nhb -> {(u*xa)/(u*xa + t*xb), (t*xb)/(u*xa + t*xb), 
       (Sqrt[2]*Sqrt[t*u*xa*xb])/(u*xa + t*xb), 0}, 
     STvec -> {0, 0, ST*Cos[\[Phi]a], ST*Sin[\[Phi]a]}, 
     SThvec -> {-((Sqrt[2]*STh*Sqrt[t*u*xa*xb]*Cos[\[Phi]h])/(u*xa + t*xb)), 
       (Sqrt[2]*STh*Sqrt[t*u*xa*xb]*Cos[\[Phi]h])/(u*xa + t*xb), 
       -((STh*(-(u*xa) + t*xb)*Cos[\[Phi]h])/(u*xa + t*xb)), 
       STh*Sin[\[Phi]h]}, STavec -> {0, 0, STa*Cos[phiA], STa*Sin[phiA]}, 
     STbvec -> {0, 0, STb*Cos[phiB], STb*Sin[phiB]}|>, 
   "Assumptions" -> s > 0 && t < 0 && u < 0 && s + t + u > 0 && CA > 0 && 
     CF > 0 && \[Alpha]s > 0 && 0 < Epsilon < 1 && 
     Element[s | t | u | ST | STh | \[Phi]a | \[Phi]h, Reals] && 
     Element[STa | STb | phiA | phiB, Reals]|>, 
 "KinematicMassDimensions" -> <|s -> 2, t -> 2, u -> 2|>, 
 "CoefficientKinematics" -> <|"PositiveFractions" -> Automatic, 
   "DistributionFactor" -> D1[zh]*h1[xa]*h1[xb], 
   "LaurentValuation" -> <|xa -> -1, xb -> -1, zh -> -2|>, "Scale" -> s, 
   "DimensionlessCoordinates" -> <|x -> -(t/s), y -> -(u/s)|>, 
   "ForbiddenVariables" -> Automatic, "BranchGrammar" -> 
    "PositiveMonomialRoots", "PhysicalRegion" -> 
    x > 0 && y > 0 && x + y < 1 && Element[x | y, Reals]|>, 
 "SetDistributionZero" -> {f1, g1L, G1L, H1}, 
 "SetMassZero" -> {Pa, Pb, Ph, ka, kb, kc, kd, ke}|>
