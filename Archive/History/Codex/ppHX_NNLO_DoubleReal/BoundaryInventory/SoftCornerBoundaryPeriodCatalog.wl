<|"Object" -> "NNLOSoftCornerBoundaryPeriodCatalog", "ClassCount" -> 16, 
 "KnownSolvedClassCount" -> 3, "UnsolvedClassCount" -> 13, 
 "ScalarPeriodClassCount" -> 15, "ScalarPeriodClasses" -> 
  {<|"TemplateIDs" -> {{120}}, "RhoValuations" -> {0}, 
    "KnownSolvedQ" -> True|>, <|"TemplateIDs" -> {{130}}, 
    "RhoValuations" -> {1}, "KnownSolvedQ" -> True|>, 
   <|"TemplateIDs" -> {{127}}, "RhoValuations" -> {0}, 
    "KnownSolvedQ" -> False|>, <|"TemplateIDs" -> {{121}}, 
    "RhoValuations" -> {1}, "KnownSolvedQ" -> False|>, 
   <|"TemplateIDs" -> {{102, 85}}, "RhoValuations" -> {1}, 
    "KnownSolvedQ" -> False|>, <|"TemplateIDs" -> {{108}}, 
    "RhoValuations" -> {1}, "KnownSolvedQ" -> False|>, 
   <|"TemplateIDs" -> {{111}}, "RhoValuations" -> {0}, 
    "KnownSolvedQ" -> False|>, <|"TemplateIDs" -> {{49}}, 
    "RhoValuations" -> {1}, "KnownSolvedQ" -> False|>, 
   <|"TemplateIDs" -> {{105}}, "RhoValuations" -> {1}, 
    "KnownSolvedQ" -> False|>, <|"TemplateIDs" -> {{59}}, 
    "RhoValuations" -> {0}, "KnownSolvedQ" -> False|>, 
   <|"TemplateIDs" -> {{64}}, "RhoValuations" -> {0}, 
    "KnownSolvedQ" -> False|>, <|"TemplateIDs" -> {{106}, {110}}, 
    "RhoValuations" -> {1, 0}, "KnownSolvedQ" -> False|>, 
   <|"TemplateIDs" -> {{87}}, "RhoValuations" -> {2}, 
    "KnownSolvedQ" -> False|>, <|"TemplateIDs" -> {{79}}, 
    "RhoValuations" -> {2}, "KnownSolvedQ" -> True|>, 
   <|"TemplateIDs" -> {{31}}, "RhoValuations" -> {0}, 
    "KnownSolvedQ" -> False|>}, "TemplateClassMap" -> 
  {{120}, {130}, {127}, {121}, {102, 85}, {108}, {111}, {49}, {105}, {59}, 
   {64}, {106}, {110}, {87}, {79}, {31}}, "CoordinateMap" -> 
  <|"InvariantRules" -> {ae -> (1 - a)*(1 - u) + a*u*z - 
       2*v*Sqrt[(1 - a)*a*(1 - u)*u*z], be -> (1 - a)*u + a*(1 - u)*z + 
       2*v*Sqrt[(1 - a)*a*(1 - u)*u*z], af -> u*(1 - z), 
     bf -> (1 - u)*(1 - z)}, "RationalVariables" -> {rz, ra, ru, rv}, 
   "RationalRules" -> {z -> (4*rz^2)/(1 + rz^2)^2, a -> ra^2/(1 + ra^2), 
     u -> ru^2/(1 + ru^2), v -> (1 - rv^2)/(1 + rv^2)}, 
   "RationalInvariantRules" -> 
    {ae -> (1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 
        4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)/
       ((1 + ra^2)*(1 + ru^2)*(1 + rv^2)*(1 + rz^2)^2), 
     be -> (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
        2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)/
       ((1 + ra^2)*(1 + ru^2)*(1 + rv^2)*(1 + rz^2)^2), 
     af -> (ru^2*(1 - 2*rz^2 + rz^4))/((1 + ru^2)*(1 + rz^2)^2), 
     bf -> (1 - 2*rz^2 + rz^4)/((1 + ru^2)*(1 + rz^2)^2)}, 
   "Jacobian" -> (-128*ra*ru*rv*(-1 + rz)*rz*(1 + rz))/
     ((1 + ra^2)^2*(1 + ru^2)^2*(1 + rv^2)^2*(1 + rz^2)^3), 
   "IntegrationDomains" -> {{rz, 0, 1}, {ra, 0, Infinity}, {ru, 0, Infinity}, 
     {rv, 0, Infinity}}|>, "NormalizedPhaseDensity" -> 
  ((1 - v^2)^(-1/2 - ep)*(1 - z)^(1 - 2*ep)*Gamma[1 - ep])/
   ((1 - a)^ep*a^ep*Sqrt[Pi]*(1 - u)^ep*u^ep*z^ep*Beta[1 - ep, 2 - 2*ep]*
    Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), 
 "Checks" -> <|"MomentumConservationAlongKa" -> True, 
   "MomentumConservationAlongKb" -> True, "ExactRationalJacobian" -> True, 
   "RationalizedInvariants" -> True, "RationalizedDensities" -> True, 
   "IntegerOverallSigns" -> True|>, 
 "Classes" -> {<|"Class" -> 1, "TemplateIDs" -> {120}, 
    "RepresentativeTemplateID" -> 120, "CanonicalMaster" -> 
     GLI[CF384, {1, 1, 1, 1, 1, 1, 1, 1, 1}], "KnownSolvedQ" -> True, 
    "RhoValuation" -> 0, "DenominatorCount" -> 6, 
    "DistinctDenominatorCount" -> 4, "AngularDenominatorCount" -> 6, 
    "ExactDenominatorNormalization" -> 1, "OverallSign" -> 1, 
    "InvariantDenominators" -> {<|"Base" -> be, "Power" -> 1|>, 
      <|"Base" -> ae, "Power" -> 1|>, <|"Base" -> 1 - be - bf, 
       "Power" -> 1|>, <|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> ae, "Power" -> 1|>, <|"Base" -> 1 - ae - af, 
       "Power" -> 1|>}, "ScalarPeriodKey" -> "{{1 - ae - af, 1}, {1 - ae - \
af, 1}, {1 - be - bf, 1}, {ae, 1}, {ae, 1}, {be, 1}}", 
    "InvariantDensity" -> ((1 - v^2)^(-1/2 - ep)*(1 - z)^(1 - 2*ep)*
       Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*(1 - u)^ep*u^ep*z^ep*
       (1 - (1 - a)*u - (1 - u)*(1 - z) - a*(1 - u)*z - 
        2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*((1 - a)*(1 - u) + a*u*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*((1 - a)*u + a*(1 - u)*z + 
        2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*(1 - (1 - a)*(1 - u) - u*(1 - z) - 
         a*u*z + 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*Beta[1 - ep, 2 - 2*ep]*
       Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), "RationalDenominator" -> 
     ((1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 4*ra^2*ru^2*rz^2 + 
         2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 4*ra*ru*rz^3 + 
         4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)^2*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
        2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4))/((1 + ra^2)^6*(1 + ru^2)^6*(1 + rv^2)^6*
       (1 + rz^2)^12), "RationalDensity" -> 
     -((2^(7 - 2*ep)*ra*(1 + ra^2)^4*ru*(1 + ru^2)^4*rv*(1 + rv^2)^4*
        (1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*(1 + rz)*
        (1 + rz^2)^9*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*Gamma[1 - ep])/
       (Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^ep*
        (ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*(rz^2/(1 + rz^2)^2)^ep*
        (1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 
          4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
          4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)^2*
        (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
          4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
          4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
        (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
         2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)*
        (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
         2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
         4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
         ra^2*ru^2*rv^2*rz^4)*Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*
        Gamma[1/2 - ep])), "IntegrationDomains" -> 
     {{rz, 0, 1}, {ra, 0, Infinity}, {ru, 0, Infinity}, {rv, 0, Infinity}}, 
    "PhysicalChamber" -> 0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && 
      -1/2 < ep < 0, "DifficultyTuple" -> {6, 6, 2}|>, 
   <|"Class" -> 2, "TemplateIDs" -> {130}, "RepresentativeTemplateID" -> 130, 
    "CanonicalMaster" -> GLI[CF408, {1, 1, 1, 1, 1, 1, 1, 1, 1}], 
    "KnownSolvedQ" -> True, "RhoValuation" -> 1, "DenominatorCount" -> 6, 
    "DistinctDenominatorCount" -> 5, "AngularDenominatorCount" -> 4, 
    "ExactDenominatorNormalization" -> 1, "OverallSign" -> -1, 
    "InvariantDenominators" -> {<|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - af, "Power" -> 1|>, <|"Base" -> be, 
       "Power" -> 1|>, <|"Base" -> ae, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - be, "Power" -> 1|>, 
      <|"Base" -> -1 + ae + af + be + bf, "Power" -> 1|>}, 
    "ScalarPeriodKey" -> "{{1 - ae - af, 1}, {1 - ae - af, 1}, {-1 + ae + af \
+ be + bf, 1}, {1 - ae - be, 1}, {ae, 1}, {be, 1}}", 
    "InvariantDensity" -> -(((1 - v^2)^(-1/2 - ep)*(1 - z)^(1 - 2*ep)*
        Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*(1 - u)^ep*u^ep*z^ep*
        (1 - (1 - a)*(1 - u) - (1 - a)*u - a*(1 - u)*z - a*u*z)*
        (-1 + (1 - a)*(1 - u) + (1 - a)*u + (1 - u)*(1 - z) + u*(1 - z) + 
         a*(1 - u)*z + a*u*z)*((1 - a)*(1 - u) + a*u*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*((1 - a)*u + a*(1 - u)*z + 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*(1 - (1 - a)*(1 - u) - u*(1 - z) - 
          a*u*z + 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*Beta[1 - ep, 2 - 2*ep]*
        Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), "RationalDenominator" -> 
     (ra^2*(1 - 2*rz^2 + rz^4)^2*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
        2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
        2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4))/
      ((1 + ra^2)^6*(1 + ru^2)^4*(1 + rv^2)^4*(1 + rz^2)^12), 
    "RationalDensity" -> (2^(7 - 2*ep)*(1 + ra^2)^4*ru*(1 + ru^2)^2*rv*
       (1 + rv^2)^2*(1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*
       (1 + rz)*(1 + rz^2)^9*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*
       Gamma[1 - ep])/(Sqrt[Pi]*ra*(ra^2/(1 + ra^2))^ep*
       (1 - ra^2/(1 + ra^2))^ep*(ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*
       (rz^2/(1 + rz^2)^2)^ep*(1 - 2*rz^2 + rz^4)^2*(1 + rv^2 - 4*ra*ru*rz + 
        4*ra*ru*rv^2*rz + 2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 
        4*ra^2*ru^2*rv^2*rz^2 - 4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + 
        rv^2*rz^4)*(ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 
         2*ra^2*rz^2 + 4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 
         4*ra*ru*rz^3 - 4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
        2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)*
       Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), 
    "IntegrationDomains" -> {{rz, 0, 1}, {ra, 0, Infinity}, 
      {ru, 0, Infinity}, {rv, 0, Infinity}}, "PhysicalChamber" -> 
     0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && -1/2 < ep < 0, 
    "DifficultyTuple" -> {6, 4, 1}|>, <|"Class" -> 3, "TemplateIDs" -> {127}, 
    "RepresentativeTemplateID" -> 127, "CanonicalMaster" -> 
     GLI[CF407, {1, 1, 1, 1, 1, 1, 1, 1, 1}], "KnownSolvedQ" -> False, 
    "RhoValuation" -> 0, "DenominatorCount" -> 6, 
    "DistinctDenominatorCount" -> 4, "AngularDenominatorCount" -> 4, 
    "ExactDenominatorNormalization" -> -1, "OverallSign" -> 1, 
    "InvariantDenominators" -> {<|"Base" -> ae, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - af, "Power" -> 1|>, <|"Base" -> ae, 
       "Power" -> 1|>, <|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - be, "Power" -> 1|>, 
      <|"Base" -> -1 + ae + af + be + bf, "Power" -> 1|>}, 
    "ScalarPeriodKey" -> "{{1 - ae - af, 1}, {1 - ae - af, 1}, {-1 + ae + af \
+ be + bf, 1}, {1 - ae - be, 1}, {ae, 1}, {ae, 1}}", 
    "InvariantDensity" -> ((1 - v^2)^(-1/2 - ep)*(1 - z)^(1 - 2*ep)*
       Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*(1 - u)^ep*u^ep*z^ep*
       (1 - (1 - a)*(1 - u) - (1 - a)*u - a*(1 - u)*z - a*u*z)*
       (-1 + (1 - a)*(1 - u) + (1 - a)*u + (1 - u)*(1 - z) + u*(1 - z) + 
        a*(1 - u)*z + a*u*z)*((1 - a)*(1 - u) + a*u*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*
       (1 - (1 - a)*(1 - u) - u*(1 - z) - a*u*z + 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*Beta[1 - ep, 2 - 2*ep]*
       Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), "RationalDenominator" -> 
     (ra^2*(1 - 2*rz^2 + rz^4)^2*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
         2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
         4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)^2*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2)/
      ((1 + ra^2)^6*(1 + ru^2)^4*(1 + rv^2)^4*(1 + rz^2)^12), 
    "RationalDensity" -> -((2^(7 - 2*ep)*(1 + ra^2)^4*ru*(1 + ru^2)^2*rv*
        (1 + rv^2)^2*(1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*
        (1 + rz)*(1 + rz^2)^9*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*
        Gamma[1 - ep])/(Sqrt[Pi]*ra*(ra^2/(1 + ra^2))^ep*
        (1 - ra^2/(1 + ra^2))^ep*(ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^
         ep*(rz^2/(1 + rz^2)^2)^ep*(1 - 2*rz^2 + rz^4)^2*
        (1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 
          4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
          4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)^2*
        (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
          4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
          4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
        Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), 
    "IntegrationDomains" -> {{rz, 0, 1}, {ra, 0, Infinity}, 
      {ru, 0, Infinity}, {rv, 0, Infinity}}, "PhysicalChamber" -> 
     0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && -1/2 < ep < 0, 
    "DifficultyTuple" -> {6, 4, 2}|>, <|"Class" -> 4, "TemplateIDs" -> {121}, 
    "RepresentativeTemplateID" -> 121, "CanonicalMaster" -> 
     GLI[CF385, {1, 1, 1, 1, 1, 1, 1, 1, 1}], "KnownSolvedQ" -> False, 
    "RhoValuation" -> 1, "DenominatorCount" -> 6, 
    "DistinctDenominatorCount" -> 4, "AngularDenominatorCount" -> 6, 
    "ExactDenominatorNormalization" -> -1, "OverallSign" -> -1, 
    "InvariantDenominators" -> {<|"Base" -> be, "Power" -> 1|>, 
      <|"Base" -> 1 - be - bf, "Power" -> 1|>, <|"Base" -> 1 - ae - af, 
       "Power" -> 1|>, <|"Base" -> be, "Power" -> 1|>, 
      <|"Base" -> ae, "Power" -> 1|>, <|"Base" -> 1 - ae - af, 
       "Power" -> 1|>}, "ScalarPeriodKey" -> "{{1 - ae - af, 1}, {1 - ae - \
af, 1}, {1 - be - bf, 1}, {ae, 1}, {be, 1}, {be, 1}}", 
    "InvariantDensity" -> -(((1 - v^2)^(-1/2 - ep)*(1 - z)^(1 - 2*ep)*
        Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*(1 - u)^ep*u^ep*z^ep*
        (1 - (1 - a)*u - (1 - u)*(1 - z) - a*(1 - u)*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*((1 - a)*(1 - u) + a*u*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*((1 - a)*u + a*(1 - u)*z + 
          2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*(1 - (1 - a)*(1 - u) - 
          u*(1 - z) - a*u*z + 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*
        Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), 
    "RationalDenominator" -> ((1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
        2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
         2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)^2*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4))/((1 + ra^2)^6*(1 + ru^2)^6*(1 + rv^2)^6*
       (1 + rz^2)^12), "RationalDensity" -> 
     (2^(7 - 2*ep)*ra*(1 + ra^2)^4*ru*(1 + ru^2)^4*rv*(1 + rv^2)^4*
       (1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*(1 + rz)*
       (1 + rz^2)^9*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*Gamma[1 - ep])/
      (Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^ep*
       (ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*(rz^2/(1 + rz^2)^2)^ep*
       (1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 4*ra^2*ru^2*rz^2 + 
        2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 4*ra*ru*rz^3 + 
        4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
         2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)^2*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4)*Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*
       Gamma[1/2 - ep]), "IntegrationDomains" -> 
     {{rz, 0, 1}, {ra, 0, Infinity}, {ru, 0, Infinity}, {rv, 0, Infinity}}, 
    "PhysicalChamber" -> 0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && 
      -1/2 < ep < 0, "DifficultyTuple" -> {6, 6, 2}|>, 
   <|"Class" -> 5, "TemplateIDs" -> {102, 85}, "RepresentativeTemplateID" -> 
     102, "CanonicalMaster" -> GLI[CF259, {1, 1, 1, 1, 1, 0, 1, 1, 1}], 
    "KnownSolvedQ" -> False, "RhoValuation" -> 1, "DenominatorCount" -> 5, 
    "DistinctDenominatorCount" -> 5, "AngularDenominatorCount" -> 3, 
    "ExactDenominatorNormalization" -> 1, "OverallSign" -> 1, 
    "InvariantDenominators" -> {<|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> 1 - be - bf, "Power" -> 1|>, <|"Base" -> ae, 
       "Power" -> 1|>, <|"Base" -> af, "Power" -> 1|>, 
      <|"Base" -> bf, "Power" -> 1|>}, "ScalarPeriodKey" -> 
     "{{1 - ae - af, 1}, {1 - be - bf, 1}, {ae, 1}, {af, 1}, {bf, 1}}", 
    "InvariantDensity" -> ((1 - u)^(-1 - ep)*u^(-1 - ep)*
       (1 - v^2)^(-1/2 - ep)*(1 - z)^(-1 - 2*ep)*Gamma[1 - ep])/
      ((1 - a)^ep*a^ep*Sqrt[Pi]*z^ep*(1 - (1 - a)*u - (1 - u)*(1 - z) - 
        a*(1 - u)*z - 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*
       ((1 - a)*(1 - u) + a*u*z - 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*
       (1 - (1 - a)*(1 - u) - u*(1 - z) - a*u*z + 
        2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*Beta[1 - ep, 2 - 2*ep]*
       Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), "RationalDenominator" -> 
     (ru^2*(1 - 2*rz^2 + rz^4)^2*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
        2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
        4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4))/((1 + ra^2)^3*(1 + ru^2)^5*(1 + rv^2)^3*
       (1 + rz^2)^10), "RationalDensity" -> 
     -((2^(7 - 2*ep)*ra*(1 + ra^2)*(1 + ru^2)^3*rv*(1 + rv^2)*
        (1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*(1 + rz)*
        (1 + rz^2)^7*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*Gamma[1 - ep])/
       (Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^ep*ru*
        (ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*(rz^2/(1 + rz^2)^2)^ep*
        (1 - 2*rz^2 + rz^4)^2*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
         2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
         4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
        (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)*
        (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
         2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
         4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
         ra^2*ru^2*rv^2*rz^4)*Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*
        Gamma[1/2 - ep])), "IntegrationDomains" -> 
     {{rz, 0, 1}, {ra, 0, Infinity}, {ru, 0, Infinity}, {rv, 0, Infinity}}, 
    "PhysicalChamber" -> 0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && 
      -1/2 < ep < 0, "DifficultyTuple" -> {5, 3, 0}|>, 
   <|"Class" -> 6, "TemplateIDs" -> {108}, "RepresentativeTemplateID" -> 108, 
    "CanonicalMaster" -> GLI[CF265, {1, 1, 1, 1, 0, 1, 1, 1, 1}], 
    "KnownSolvedQ" -> False, "RhoValuation" -> 1, "DenominatorCount" -> 5, 
    "DistinctDenominatorCount" -> 5, "AngularDenominatorCount" -> 3, 
    "ExactDenominatorNormalization" -> 1, "OverallSign" -> -1, 
    "InvariantDenominators" -> {<|"Base" -> ae, "Power" -> 1|>, 
      <|"Base" -> bf, "Power" -> 1|>, <|"Base" -> 1 - be - bf, 
       "Power" -> 1|>, <|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> -1 + ae + af + be + bf, "Power" -> 1|>}, 
    "ScalarPeriodKey" -> "{{1 - ae - af, 1}, {-1 + ae + af + be + bf, 1}, {1 \
- be - bf, 1}, {ae, 1}, {bf, 1}}", "InvariantDensity" -> 
     -(((1 - u)^(-1 - ep)*(1 - v^2)^(-1/2 - ep)*Gamma[1 - ep])/
       ((1 - a)^ep*a^ep*Sqrt[Pi]*u^ep*(1 - z)^(2*ep)*z^ep*
        (-1 + (1 - a)*(1 - u) + (1 - a)*u + (1 - u)*(1 - z) + u*(1 - z) + 
         a*(1 - u)*z + a*u*z)*(1 - (1 - a)*u - (1 - u)*(1 - z) - 
         a*(1 - u)*z - 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*
        ((1 - a)*(1 - u) + a*u*z - 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*
        (1 - (1 - a)*(1 - u) - u*(1 - z) - a*u*z + 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*Beta[1 - ep, 2 - 2*ep]*
        Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), "RationalDenominator" -> 
     ((1 - 2*rz^2 + rz^4)^2*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
        2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
        4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4))/((1 + ra^2)^4*(1 + ru^2)^4*(1 + rv^2)^3*
       (1 + rz^2)^10), "RationalDensity" -> 
     (2^(7 - 2*ep)*ra*(1 + ra^2)^2*ru*(1 + ru^2)^2*rv*(1 + rv^2)*
       (1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*(1 + rz)*
       (1 + rz^2)^7*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*Gamma[1 - ep])/
      (Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^ep*
       (ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*(rz^2/(1 + rz^2)^2)^ep*
       (1 - 2*rz^2 + rz^4)^2*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
        2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
        4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4)*Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*
       Gamma[1/2 - ep]), "IntegrationDomains" -> 
     {{rz, 0, 1}, {ra, 0, Infinity}, {ru, 0, Infinity}, {rv, 0, Infinity}}, 
    "PhysicalChamber" -> 0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && 
      -1/2 < ep < 0, "DifficultyTuple" -> {5, 3, 0}|>, 
   <|"Class" -> 7, "TemplateIDs" -> {111}, "RepresentativeTemplateID" -> 111, 
    "CanonicalMaster" -> GLI[CF269, {1, 1, 1, 1, 1, 1, 1, 1, 0}], 
    "KnownSolvedQ" -> False, "RhoValuation" -> 0, "DenominatorCount" -> 5, 
    "DistinctDenominatorCount" -> 4, "AngularDenominatorCount" -> 3, 
    "ExactDenominatorNormalization" -> 1, "OverallSign" -> 1, 
    "InvariantDenominators" -> {<|"Base" -> ae, "Power" -> 1|>, 
      <|"Base" -> bf, "Power" -> 1|>, <|"Base" -> 1 - ae - af, 
       "Power" -> 1|>, <|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - be, "Power" -> 1|>}, "ScalarPeriodKey" -> "{{1 - \
ae - af, 1}, {1 - ae - af, 1}, {1 - ae - be, 1}, {ae, 1}, {bf, 1}}", 
    "InvariantDensity" -> ((1 - u)^(-1 - ep)*(1 - v^2)^(-1/2 - ep)*
       Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*u^ep*(1 - z)^(2*ep)*z^ep*
       (1 - (1 - a)*(1 - u) - (1 - a)*u - a*(1 - u)*z - a*u*z)*
       ((1 - a)*(1 - u) + a*u*z - 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*
       (1 - (1 - a)*(1 - u) - u*(1 - z) - a*u*z + 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*Beta[1 - ep, 2 - 2*ep]*
       Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), "RationalDenominator" -> 
     (ra^2*(1 - 2*rz^2 + rz^4)^2*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
        2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2)/
      ((1 + ra^2)^4*(1 + ru^2)^4*(1 + rv^2)^3*(1 + rz^2)^10), 
    "RationalDensity" -> -((2^(7 - 2*ep)*(1 + ra^2)^2*ru*(1 + ru^2)^2*rv*
        (1 + rv^2)*(1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*
        (1 + rz)*(1 + rz^2)^7*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*
        Gamma[1 - ep])/(Sqrt[Pi]*ra*(ra^2/(1 + ra^2))^ep*
        (1 - ra^2/(1 + ra^2))^ep*(ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^
         ep*(rz^2/(1 + rz^2)^2)^ep*(1 - 2*rz^2 + rz^4)^2*
        (1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 
         4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
         4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
        (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
          4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
          4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
        Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), 
    "IntegrationDomains" -> {{rz, 0, 1}, {ra, 0, Infinity}, 
      {ru, 0, Infinity}, {rv, 0, Infinity}}, "PhysicalChamber" -> 
     0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && -1/2 < ep < 0, 
    "DifficultyTuple" -> {5, 3, 1}|>, <|"Class" -> 8, "TemplateIDs" -> {49}, 
    "RepresentativeTemplateID" -> 49, "CanonicalMaster" -> 
     GLI[CF48, {1, 1, 1, 1, 1, 1, 1, 1, 0}], "KnownSolvedQ" -> False, 
    "RhoValuation" -> 1, "DenominatorCount" -> 5, 
    "DistinctDenominatorCount" -> 4, "AngularDenominatorCount" -> 4, 
    "ExactDenominatorNormalization" -> 1, "OverallSign" -> 1, 
    "InvariantDenominators" -> {<|"Base" -> ae, "Power" -> 1|>, 
      <|"Base" -> bf, "Power" -> 1|>, <|"Base" -> 1 - be - bf, 
       "Power" -> 1|>, <|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> ae, "Power" -> 1|>}, "ScalarPeriodKey" -> 
     "{{1 - ae - af, 1}, {1 - be - bf, 1}, {ae, 1}, {ae, 1}, {bf, 1}}", 
    "InvariantDensity" -> ((1 - u)^(-1 - ep)*(1 - v^2)^(-1/2 - ep)*
       Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*u^ep*(1 - z)^(2*ep)*z^ep*
       (1 - (1 - a)*u - (1 - u)*(1 - z) - a*(1 - u)*z - 
        2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*((1 - a)*(1 - u) + a*u*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*(1 - (1 - a)*(1 - u) - 
        u*(1 - z) - a*u*z + 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*
       Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), 
    "RationalDenominator" -> ((1 - 2*rz^2 + rz^4)*
       (1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 4*ra^2*ru^2*rz^2 + 
         2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 4*ra*ru*rz^3 + 
         4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)^2*(ra^2 + ra^2*rv^2 + 
        4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 4*ru^2*rz^2 + 
        2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4))/((1 + ra^2)^4*(1 + ru^2)^5*(1 + rv^2)^4*
       (1 + rz^2)^10), "RationalDensity" -> 
     -((2^(7 - 2*ep)*ra*(1 + ra^2)^2*ru*(1 + ru^2)^3*rv*(1 + rv^2)^2*
        (1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*(1 + rz)*
        (1 + rz^2)^7*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*Gamma[1 - ep])/
       (Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^ep*
        (ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*(rz^2/(1 + rz^2)^2)^ep*
        (1 - 2*rz^2 + rz^4)*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
          2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
          4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)^2*
        (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)*
        (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
         2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
         4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
         ra^2*ru^2*rv^2*rz^4)*Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*
        Gamma[1/2 - ep])), "IntegrationDomains" -> 
     {{rz, 0, 1}, {ra, 0, Infinity}, {ru, 0, Infinity}, {rv, 0, Infinity}}, 
    "PhysicalChamber" -> 0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && 
      -1/2 < ep < 0, "DifficultyTuple" -> {5, 4, 1}|>, 
   <|"Class" -> 9, "TemplateIDs" -> {105}, "RepresentativeTemplateID" -> 105, 
    "CanonicalMaster" -> GLI[CF260, {1, 1, 1, 1, 1, 1, 1, 1, 0}], 
    "KnownSolvedQ" -> False, "RhoValuation" -> 1, "DenominatorCount" -> 5, 
    "DistinctDenominatorCount" -> 4, "AngularDenominatorCount" -> 3, 
    "ExactDenominatorNormalization" -> 1, "OverallSign" -> 1, 
    "InvariantDenominators" -> {<|"Base" -> ae, "Power" -> 1|>, 
      <|"Base" -> bf, "Power" -> 1|>, <|"Base" -> 1 - ae - af, 
       "Power" -> 1|>, <|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> af, "Power" -> 1|>}, "ScalarPeriodKey" -> 
     "{{1 - ae - af, 1}, {1 - ae - af, 1}, {ae, 1}, {af, 1}, {bf, 1}}", 
    "InvariantDensity" -> ((1 - u)^(-1 - ep)*u^(-1 - ep)*
       (1 - v^2)^(-1/2 - ep)*(1 - z)^(-1 - 2*ep)*Gamma[1 - ep])/
      ((1 - a)^ep*a^ep*Sqrt[Pi]*z^ep*((1 - a)*(1 - u) + a*u*z - 
        2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*(1 - (1 - a)*(1 - u) - u*(1 - z) - 
         a*u*z + 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*Beta[1 - ep, 2 - 2*ep]*
       Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), "RationalDenominator" -> 
     (ru^2*(1 - 2*rz^2 + rz^4)^2*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
        2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2)/
      ((1 + ra^2)^3*(1 + ru^2)^5*(1 + rv^2)^3*(1 + rz^2)^10), 
    "RationalDensity" -> -((2^(7 - 2*ep)*ra*(1 + ra^2)*(1 + ru^2)^3*rv*
        (1 + rv^2)*(1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*
        (1 + rz)*(1 + rz^2)^7*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*
        Gamma[1 - ep])/(Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^
         ep*ru*(ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*
        (rz^2/(1 + rz^2)^2)^ep*(1 - 2*rz^2 + rz^4)^2*(1 + rv^2 - 4*ra*ru*rz + 
         4*ra*ru*rv^2*rz + 2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 
         4*ra^2*ru^2*rv^2*rz^2 - 4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + 
         rv^2*rz^4)*(ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 
          2*ra^2*rz^2 + 4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 
          4*ra*ru*rz^3 - 4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
        Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), 
    "IntegrationDomains" -> {{rz, 0, 1}, {ra, 0, Infinity}, 
      {ru, 0, Infinity}, {rv, 0, Infinity}}, "PhysicalChamber" -> 
     0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && -1/2 < ep < 0, 
    "DifficultyTuple" -> {5, 3, 1}|>, <|"Class" -> 10, "TemplateIDs" -> {59}, 
    "RepresentativeTemplateID" -> 59, "CanonicalMaster" -> 
     GLI[CF50, {1, 1, 1, 1, 1, 1, 1, 1, 0}], "KnownSolvedQ" -> False, 
    "RhoValuation" -> 0, "DenominatorCount" -> 5, 
    "DistinctDenominatorCount" -> 4, "AngularDenominatorCount" -> 4, 
    "ExactDenominatorNormalization" -> -1, "OverallSign" -> -1, 
    "InvariantDenominators" -> {<|"Base" -> ae, "Power" -> 1|>, 
      <|"Base" -> bf, "Power" -> 1|>, <|"Base" -> 1 - be - bf, 
       "Power" -> 1|>, <|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - af, "Power" -> 1|>}, "ScalarPeriodKey" -> "{{1 - \
ae - af, 1}, {1 - ae - af, 1}, {1 - be - bf, 1}, {ae, 1}, {bf, 1}}", 
    "InvariantDensity" -> -(((1 - u)^(-1 - ep)*(1 - v^2)^(-1/2 - ep)*
        Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*u^ep*(1 - z)^(2*ep)*z^ep*
        (1 - (1 - a)*u - (1 - u)*(1 - z) - a*(1 - u)*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*((1 - a)*(1 - u) + a*u*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*(1 - (1 - a)*(1 - u) - u*(1 - z) - 
          a*u*z + 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*Beta[1 - ep, 2 - 2*ep]*
        Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), "RationalDenominator" -> 
     ((1 - 2*rz^2 + rz^4)*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 
        4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4))/((1 + ra^2)^4*(1 + ru^2)^5*(1 + rv^2)^4*
       (1 + rz^2)^10), "RationalDensity" -> 
     (2^(7 - 2*ep)*ra*(1 + ra^2)^2*ru*(1 + ru^2)^3*rv*(1 + rv^2)^2*
       (1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*(1 + rz)*
       (1 + rz^2)^7*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*Gamma[1 - ep])/
      (Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^ep*
       (ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*(rz^2/(1 + rz^2)^2)^ep*
       (1 - 2*rz^2 + rz^4)*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
        2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4)*Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*
       Gamma[1/2 - ep]), "IntegrationDomains" -> 
     {{rz, 0, 1}, {ra, 0, Infinity}, {ru, 0, Infinity}, {rv, 0, Infinity}}, 
    "PhysicalChamber" -> 0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && 
      -1/2 < ep < 0, "DifficultyTuple" -> {5, 4, 1}|>, 
   <|"Class" -> 11, "TemplateIDs" -> {64}, "RepresentativeTemplateID" -> 64, 
    "CanonicalMaster" -> GLI[CF56, {1, 1, 1, 1, 1, 1, 1, 1, 0}], 
    "KnownSolvedQ" -> False, "RhoValuation" -> 0, "DenominatorCount" -> 5, 
    "DistinctDenominatorCount" -> 4, "AngularDenominatorCount" -> 5, 
    "ExactDenominatorNormalization" -> -1, "OverallSign" -> -1, 
    "InvariantDenominators" -> {<|"Base" -> ae, "Power" -> 1|>, 
      <|"Base" -> be, "Power" -> 1|>, <|"Base" -> 1 - be - bf, 
       "Power" -> 1|>, <|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - af, "Power" -> 1|>}, "ScalarPeriodKey" -> "{{1 - \
ae - af, 1}, {1 - ae - af, 1}, {1 - be - bf, 1}, {ae, 1}, {be, 1}}", 
    "InvariantDensity" -> -(((1 - v^2)^(-1/2 - ep)*(1 - z)^(1 - 2*ep)*
        Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*(1 - u)^ep*u^ep*z^ep*
        (1 - (1 - a)*u - (1 - u)*(1 - z) - a*(1 - u)*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*((1 - a)*(1 - u) + a*u*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*((1 - a)*u + a*(1 - u)*z + 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*(1 - (1 - a)*(1 - u) - u*(1 - z) - 
          a*u*z + 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*Beta[1 - ep, 2 - 2*ep]*
        Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), "RationalDenominator" -> 
     ((1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 4*ra^2*ru^2*rz^2 + 
        2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 4*ra*ru*rz^3 + 
        4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
        2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4))/((1 + ra^2)^5*(1 + ru^2)^5*(1 + rv^2)^5*
       (1 + rz^2)^10), "RationalDensity" -> 
     (2^(7 - 2*ep)*ra*(1 + ra^2)^3*ru*(1 + ru^2)^3*rv*(1 + rv^2)^3*
       (1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*(1 + rz)*
       (1 + rz^2)^7*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*Gamma[1 - ep])/
      (Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^ep*
       (ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*(rz^2/(1 + rz^2)^2)^ep*
       (1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 4*ra^2*ru^2*rz^2 + 
        2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 4*ra*ru*rz^3 + 
        4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
         4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
        2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4)*Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*
       Gamma[1/2 - ep]), "IntegrationDomains" -> 
     {{rz, 0, 1}, {ra, 0, Infinity}, {ru, 0, Infinity}, {rv, 0, Infinity}}, 
    "PhysicalChamber" -> 0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && 
      -1/2 < ep < 0, "DifficultyTuple" -> {5, 5, 1}|>, 
   <|"Class" -> 12, "TemplateIDs" -> {106}, "RepresentativeTemplateID" -> 
     106, "CanonicalMaster" -> GLI[CF263, {1, 1, 1, 1, 1, 1, 1, 1, 0}], 
    "KnownSolvedQ" -> False, "RhoValuation" -> 1, "DenominatorCount" -> 5, 
    "DistinctDenominatorCount" -> 4, "AngularDenominatorCount" -> 4, 
    "ExactDenominatorNormalization" -> -1, "OverallSign" -> -1, 
    "InvariantDenominators" -> {<|"Base" -> be, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - af, "Power" -> 1|>, <|"Base" -> 1 - ae - af, 
       "Power" -> 1|>, <|"Base" -> ae, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - be, "Power" -> 1|>}, "ScalarPeriodKey" -> "{{1 - \
ae - af, 1}, {1 - ae - af, 1}, {1 - ae - be, 1}, {ae, 1}, {be, 1}}", 
    "InvariantDensity" -> -(((1 - v^2)^(-1/2 - ep)*(1 - z)^(1 - 2*ep)*
        Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*(1 - u)^ep*u^ep*z^ep*
        (1 - (1 - a)*(1 - u) - (1 - a)*u - a*(1 - u)*z - a*u*z)*
        ((1 - a)*(1 - u) + a*u*z - 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*
        ((1 - a)*u + a*(1 - u)*z + 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*
        (1 - (1 - a)*(1 - u) - u*(1 - z) - a*u*z + 
          2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*Beta[1 - ep, 2 - 2*ep]*
        Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), "RationalDenominator" -> 
     ((ra^2 - 2*ra^2*rz^2 + ra^2*rz^4)*(1 + rv^2 - 4*ra*ru*rz + 
        4*ra*ru*rv^2*rz + 2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 
        4*ra^2*ru^2*rv^2*rz^2 - 4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + 
        rv^2*rz^4)*(ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 
         2*ra^2*rz^2 + 4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 
         4*ra*ru*rz^3 - 4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
        2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4))/
      ((1 + ra^2)^5*(1 + ru^2)^4*(1 + rv^2)^4*(1 + rz^2)^10), 
    "RationalDensity" -> (2^(7 - 2*ep)*ra*(1 + ra^2)^3*ru*(1 + ru^2)^2*rv*
       (1 + rv^2)^2*(1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*
       (1 + rz)*(1 + rz^2)^7*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*
       Gamma[1 - ep])/(Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^ep*
       (ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*(rz^2/(1 + rz^2)^2)^ep*
       (ra^2 - 2*ra^2*rz^2 + ra^2*rz^4)*(1 + rv^2 - 4*ra*ru*rz + 
        4*ra*ru*rv^2*rz + 2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 
        4*ra^2*ru^2*rv^2*rz^2 - 4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + 
        rv^2*rz^4)*(ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 
         2*ra^2*rz^2 + 4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 
         4*ra*ru*rz^3 - 4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
        2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)*
       Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), 
    "IntegrationDomains" -> {{rz, 0, 1}, {ra, 0, Infinity}, 
      {ru, 0, Infinity}, {rv, 0, Infinity}}, "PhysicalChamber" -> 
     0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && -1/2 < ep < 0, 
    "DifficultyTuple" -> {5, 4, 1}|>, <|"Class" -> 13, 
    "TemplateIDs" -> {110}, "RepresentativeTemplateID" -> 110, 
    "CanonicalMaster" -> GLI[CF267, {1, 1, 1, 1, 1, 1, 1, 1, 0}], 
    "KnownSolvedQ" -> False, "RhoValuation" -> 0, "DenominatorCount" -> 5, 
    "DistinctDenominatorCount" -> 4, "AngularDenominatorCount" -> 4, 
    "ExactDenominatorNormalization" -> 1, "OverallSign" -> 1, 
    "InvariantDenominators" -> {<|"Base" -> ae, "Power" -> 1|>, 
      <|"Base" -> be, "Power" -> 1|>, <|"Base" -> 1 - ae - af, 
       "Power" -> 1|>, <|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - be, "Power" -> 1|>}, "ScalarPeriodKey" -> "{{1 - \
ae - af, 1}, {1 - ae - af, 1}, {1 - ae - be, 1}, {ae, 1}, {be, 1}}", 
    "InvariantDensity" -> ((1 - v^2)^(-1/2 - ep)*(1 - z)^(1 - 2*ep)*
       Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*(1 - u)^ep*u^ep*z^ep*
       (1 - (1 - a)*(1 - u) - (1 - a)*u - a*(1 - u)*z - a*u*z)*
       ((1 - a)*(1 - u) + a*u*z - 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*
       ((1 - a)*u + a*(1 - u)*z + 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*
       (1 - (1 - a)*(1 - u) - u*(1 - z) - a*u*z + 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])^2*Beta[1 - ep, 2 - 2*ep]*
       Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), "RationalDenominator" -> 
     ((ra^2 - 2*ra^2*rz^2 + ra^2*rz^4)*(1 + rv^2 - 4*ra*ru*rz + 
        4*ra*ru*rv^2*rz + 2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 
        4*ra^2*ru^2*rv^2*rz^2 - 4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + 
        rv^2*rz^4)*(ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 
         2*ra^2*rz^2 + 4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 
         4*ra*ru*rz^3 - 4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
        2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4))/
      ((1 + ra^2)^5*(1 + ru^2)^4*(1 + rv^2)^4*(1 + rz^2)^10), 
    "RationalDensity" -> -((2^(7 - 2*ep)*ra*(1 + ra^2)^3*ru*(1 + ru^2)^2*rv*
        (1 + rv^2)^2*(1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*
        (1 + rz)*(1 + rz^2)^7*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*
        Gamma[1 - ep])/(Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^
         ep*(ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*
        (rz^2/(1 + rz^2)^2)^ep*(ra^2 - 2*ra^2*rz^2 + ra^2*rz^4)*
        (1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 
         4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
         4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
        (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
          4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
          4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)^2*
        (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
         2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
         4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)*
        Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), 
    "IntegrationDomains" -> {{rz, 0, 1}, {ra, 0, Infinity}, 
      {ru, 0, Infinity}, {rv, 0, Infinity}}, "PhysicalChamber" -> 
     0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && -1/2 < ep < 0, 
    "DifficultyTuple" -> {5, 4, 1}|>, <|"Class" -> 14, "TemplateIDs" -> {87}, 
    "RepresentativeTemplateID" -> 87, "CanonicalMaster" -> 
     GLI[CF213, {1, 1, 1, 1, 1, 1, 1, 1, 0}], "KnownSolvedQ" -> False, 
    "RhoValuation" -> 2, "DenominatorCount" -> 5, 
    "DistinctDenominatorCount" -> 5, "AngularDenominatorCount" -> 3, 
    "ExactDenominatorNormalization" -> -1, "OverallSign" -> 1, 
    "InvariantDenominators" -> {<|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> be, "Power" -> 1|>, <|"Base" -> bf, "Power" -> 1|>, 
      <|"Base" -> 1 - be - bf, "Power" -> 1|>, 
      <|"Base" -> -1 + ae + af + be + bf, "Power" -> 1|>}, 
    "ScalarPeriodKey" -> "{{1 - ae - af, 1}, {-1 + ae + af + be + bf, 1}, {1 \
- be - bf, 1}, {be, 1}, {bf, 1}}", "InvariantDensity" -> 
     ((1 - u)^(-1 - ep)*(1 - v^2)^(-1/2 - ep)*Gamma[1 - ep])/
      ((1 - a)^ep*a^ep*Sqrt[Pi]*u^ep*(1 - z)^(2*ep)*z^ep*
       (-1 + (1 - a)*(1 - u) + (1 - a)*u + (1 - u)*(1 - z) + u*(1 - z) + 
        a*(1 - u)*z + a*u*z)*(1 - (1 - a)*u - (1 - u)*(1 - z) - a*(1 - u)*z - 
        2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*((1 - a)*u + a*(1 - u)*z + 
        2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*(1 - (1 - a)*(1 - u) - u*(1 - z) - 
        a*u*z + 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*Beta[1 - ep, 2 - 2*ep]*
       Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), "RationalDenominator" -> 
     ((1 - 2*rz^2 + rz^4)^2*(ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 
        4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 
        4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + 
        ra^2*rv^2*rz^4)*(ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 
        4*ra^2*rz^2 + 2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 
        4*ra*ru*rz^3 - 4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4))/((1 + ra^2)^4*(1 + ru^2)^4*(1 + rv^2)^3*
       (1 + rz^2)^10), "RationalDensity" -> 
     -((2^(7 - 2*ep)*ra*(1 + ra^2)^2*ru*(1 + ru^2)^2*rv*(1 + rv^2)*
        (1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*(1 + rz)*
        (1 + rz^2)^7*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*Gamma[1 - ep])/
       (Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^ep*
        (ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*(rz^2/(1 + rz^2)^2)^ep*
        (1 - 2*rz^2 + rz^4)^2*(ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 
         4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 
         4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + 
         ra^2*rv^2*rz^4)*(ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 
         4*ra^2*rz^2 + 2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 
         4*ra*ru*rz^3 - 4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)*
        (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
         2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
         4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
         ra^2*ru^2*rv^2*rz^4)*Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*
        Gamma[1/2 - ep])), "IntegrationDomains" -> 
     {{rz, 0, 1}, {ra, 0, Infinity}, {ru, 0, Infinity}, {rv, 0, Infinity}}, 
    "PhysicalChamber" -> 0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && 
      -1/2 < ep < 0, "DifficultyTuple" -> {5, 3, 0}|>, 
   <|"Class" -> 15, "TemplateIDs" -> {79}, "RepresentativeTemplateID" -> 79, 
    "CanonicalMaster" -> GLI[CF198, {1, 1, 1, 1, 1, 1, 1, 1, 0}], 
    "KnownSolvedQ" -> True, "RhoValuation" -> 2, "DenominatorCount" -> 5, 
    "DistinctDenominatorCount" -> 5, "AngularDenominatorCount" -> 4, 
    "ExactDenominatorNormalization" -> -1, "OverallSign" -> -1, 
    "InvariantDenominators" -> {<|"Base" -> ae, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - af, "Power" -> 1|>, <|"Base" -> bf, 
       "Power" -> 1|>, <|"Base" -> be, "Power" -> 1|>, 
      <|"Base" -> 1 - be - bf, "Power" -> 1|>}, "ScalarPeriodKey" -> 
     "{{1 - ae - af, 1}, {1 - be - bf, 1}, {ae, 1}, {be, 1}, {bf, 1}}", 
    "InvariantDensity" -> -(((1 - u)^(-1 - ep)*(1 - v^2)^(-1/2 - ep)*
        Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*u^ep*(1 - z)^(2*ep)*z^ep*
        (1 - (1 - a)*u - (1 - u)*(1 - z) - a*(1 - u)*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*((1 - a)*(1 - u) + a*u*z - 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*((1 - a)*u + a*(1 - u)*z + 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*(1 - (1 - a)*(1 - u) - u*(1 - z) - 
         a*u*z + 2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*Beta[1 - ep, 2 - 2*ep]*
        Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), "RationalDenominator" -> 
     ((1 - 2*rz^2 + rz^4)*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 2*rz^2 + 
        4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
        4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
        2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4))/((1 + ra^2)^4*(1 + ru^2)^5*(1 + rv^2)^4*
       (1 + rz^2)^10), "RationalDensity" -> 
     (2^(7 - 2*ep)*ra*(1 + ra^2)^2*ru*(1 + ru^2)^3*rv*(1 + rv^2)^2*
       (1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*(1 + rz)*
       (1 + rz^2)^7*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*Gamma[1 - ep])/
      (Sqrt[Pi]*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^ep*
       (ru^2/(1 + ru^2))^ep*(1 - ru^2/(1 + ru^2))^ep*(rz^2/(1 + rz^2)^2)^ep*
       (1 - 2*rz^2 + rz^4)*(1 + rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 
        2*rz^2 + 4*ra^2*ru^2*rz^2 + 2*rv^2*rz^2 + 4*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + rz^4 + rv^2*rz^4)*
       (ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 
        4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)*
       (ru^2 + ru^2*rv^2 + 4*ra*ru*rz - 4*ra*ru*rv^2*rz + 4*ra^2*rz^2 + 
        2*ru^2*rz^2 + 4*ra^2*rv^2*rz^2 + 2*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ru^2*rz^4 + ru^2*rv^2*rz^4)*
       (ra^2*ru^2 + ra^2*ru^2*rv^2 - 4*ra*ru*rz + 4*ra*ru*rv^2*rz + 4*rz^2 + 
        2*ra^2*ru^2*rz^2 + 4*rv^2*rz^2 + 2*ra^2*ru^2*rv^2*rz^2 - 
        4*ra*ru*rz^3 + 4*ra*ru*rv^2*rz^3 + ra^2*ru^2*rz^4 + 
        ra^2*ru^2*rv^2*rz^4)*Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*
       Gamma[1/2 - ep]), "IntegrationDomains" -> 
     {{rz, 0, 1}, {ra, 0, Infinity}, {ru, 0, Infinity}, {rv, 0, Infinity}}, 
    "PhysicalChamber" -> 0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && 
      -1/2 < ep < 0, "DifficultyTuple" -> {5, 4, 0}|>, 
   <|"Class" -> 16, "TemplateIDs" -> {31}, "RepresentativeTemplateID" -> 31, 
    "CanonicalMaster" -> GLI[CF23, {1, 1, 1, 1, 1, 1, 0, 1, 0}], 
    "KnownSolvedQ" -> False, "RhoValuation" -> 0, "DenominatorCount" -> 4, 
    "DistinctDenominatorCount" -> 3, "AngularDenominatorCount" -> 1, 
    "ExactDenominatorNormalization" -> 1, "OverallSign" -> -1, 
    "InvariantDenominators" -> {<|"Base" -> 1 - ae - be, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - af, "Power" -> 1|>, 
      <|"Base" -> -1 + ae + af + be + bf, "Power" -> 1|>, 
      <|"Base" -> 1 - ae - be, "Power" -> 1|>}, "ScalarPeriodKey" -> "{{1 - \
ae - af, 1}, {-1 + ae + af + be + bf, 1}, {1 - ae - be, 1}, {1 - ae - be, \
1}}", "InvariantDensity" -> -(((1 - v^2)^(-1/2 - ep)*(1 - z)^(1 - 2*ep)*
        Gamma[1 - ep])/((1 - a)^ep*a^ep*Sqrt[Pi]*(1 - u)^ep*u^ep*z^ep*
        (1 - (1 - a)*(1 - u) - (1 - a)*u - a*(1 - u)*z - a*u*z)^2*
        (-1 + (1 - a)*(1 - u) + (1 - a)*u + (1 - u)*(1 - z) + u*(1 - z) + 
         a*(1 - u)*z + a*u*z)*(1 - (1 - a)*(1 - u) - u*(1 - z) - a*u*z + 
         2*v*Sqrt[(1 - a)*a*(1 - u)*u*z])*Beta[1 - ep, 2 - 2*ep]*
        Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep])), "RationalDenominator" -> 
     (ra^4*(1 - 2*rz^2 + rz^4)^3*(ra^2 + ra^2*rv^2 + 4*ra*ru*rz - 
        4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 4*ru^2*rz^2 + 2*ra^2*rv^2*rz^2 + 
        4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + 
        ra^2*rv^2*rz^4))/((1 + ra^2)^4*(1 + ru^2)*(1 + rv^2)*(1 + rz^2)^8), 
    "RationalDensity" -> (2^(7 - 2*ep)*(1 + ra^2)^2*ru*rv*
       (1 - (1 - rv^2)^2/(1 + rv^2)^2)^(-1/2 - ep)*(-1 + rz)*rz*(1 + rz)*
       (1 + rz^2)^5*(1 - (4*rz^2)/(1 + rz^2)^2)^(1 - 2*ep)*Gamma[1 - ep])/
      (Sqrt[Pi]*ra^3*(ra^2/(1 + ra^2))^ep*(1 - ra^2/(1 + ra^2))^ep*
       (ru^2/(1 + ru^2))^ep*(1 + ru^2)*(1 - ru^2/(1 + ru^2))^ep*(1 + rv^2)*
       (rz^2/(1 + rz^2)^2)^ep*(1 - 2*rz^2 + rz^4)^3*(ra^2 + ra^2*rv^2 + 
        4*ra*ru*rz - 4*ra*ru*rv^2*rz + 2*ra^2*rz^2 + 4*ru^2*rz^2 + 
        2*ra^2*rv^2*rz^2 + 4*ru^2*rv^2*rz^2 + 4*ra*ru*rz^3 - 
        4*ra*ru*rv^2*rz^3 + ra^2*rz^4 + ra^2*rv^2*rz^4)*
       Beta[1 - ep, 2 - 2*ep]*Beta[1 - ep, 1 - ep]^2*Gamma[1/2 - ep]), 
    "IntegrationDomains" -> {{rz, 0, 1}, {ra, 0, Infinity}, 
      {ru, 0, Infinity}, {rv, 0, Infinity}}, "PhysicalChamber" -> 
     0 < rz < 1 && ra > 0 && ru > 0 && rv > 0 && -1/2 < ep < 0, 
    "DifficultyTuple" -> {4, 1, 1}|>}|>
