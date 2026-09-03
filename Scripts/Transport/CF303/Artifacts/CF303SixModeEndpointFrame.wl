<|"Status" -> "CF303SixModeEndpointFrameAcceptedV1", "Family" -> "CF303", 
 "Basis" -> "PhysicalBlockBasis", "PhysicalRows" -> {1, 2, 3, 4, 5, 6}, 
 "StateCanonicalRowOrder" -> {42, 43, 40, 41, 44, 45}, 
 "NormalResidue" -> <|"Matrix" -> {{0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, 
     {0, 0, 0, 0, 0, 0}, {0, 0, (2 + 9*eps + 10*eps^2)/p^2, -2*(1 + 2*eps), 
      0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, (-2 - 9*eps - 10*eps^2)/p^4, 
      (2*(1 + 2*eps))/p^2, 0, 0}}, "Rank" -> 1, "NonzeroEigenvalue" -> 
    -2*(1 + 2*eps), "SpectralProjector" -> {{0, 0, 0, 0, 0, 0}, 
     {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, (-2 - 5*eps)/(2*p^2), 1, 
      0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, (2 + 5*eps)/(2*p^4), -p^(-2), 0, 
      0}}|>, "ModeFrame" -> 
  <|"Builder" -> "BuildEndpointLeveltModeConnection", 
   "Convention" -> 
    "columns are five zero modes followed by one nonzero mode", 
   "Labels" -> {"ZeroE1", "ZeroE2", "ZeroBlock23", "ZeroTargetE5", 
     "ZeroTargetE6", "NonzeroBlock23"}, 
   "Matrix" -> {{1, 0, 0, 0, 0, 0}, {0, 1, 0, 0, 0, 0}, {0, 0, 1, 0, 0, 0}, 
     {0, 0, (2 + 5*eps)/(2*p^2), 0, 0, 1}, {0, 0, 0, 1, 0, 0}, 
     {0, 0, 0, 0, 1, -p^(-2)}}, "Inverse" -> {{1, 0, 0, 0, 0, 0}, 
     {0, 1, 0, 0, 0, 0}, {0, 0, 1, 0, 0, 0}, {0, 0, 0, 0, 1, 0}, 
     {0, 0, (-2 - 5*eps)/(2*p^4), p^(-2), 0, 1}, {0, 0, (-2 - 5*eps)/(2*p^2), 
      1, 0, 0}}, "ResidueInFrame" -> {{0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, 
     {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, 
     {0, 0, 0, 0, 0, -2*(1 + 2*eps)}}, "ExponentData" -> 
    {<|"Exponent" -> 0, "IntegerPart" -> 0, "RegulatorCoefficient" -> 0, 
      "AffineInRegulator" -> True|>, <|"Exponent" -> 0, "IntegerPart" -> 0, 
      "RegulatorCoefficient" -> 0, "AffineInRegulator" -> True|>, 
     <|"Exponent" -> 0, "IntegerPart" -> 0, "RegulatorCoefficient" -> 0, 
      "AffineInRegulator" -> True|>, <|"Exponent" -> 0, "IntegerPart" -> 0, 
      "RegulatorCoefficient" -> 0, "AffineInRegulator" -> True|>, 
     <|"Exponent" -> 0, "IntegerPart" -> 0, "RegulatorCoefficient" -> 0, 
      "AffineInRegulator" -> True|>, <|"Exponent" -> -2*(1 + 2*eps), 
      "IntegerPart" -> -2, "RegulatorCoefficient" -> -4, 
      "AffineInRegulator" -> True|>}, "ExponentSectors" -> 
    {{1, 2, 3, 4, 5}, {6}}|>, "TangentialConnection" -> 
  <|"Convention" -> "Gamma=V^-1 B_parallel V - V^-1 dV/dp", 
   "SparseEntries" -> {<|"Row" -> 1, "Column" -> 1, 
      "Value" -> (-2*(-1 - eps + 2*p^2 + eps*p^2))/((-1 + p)*p*(1 + p))|>, 
     <|"Row" -> 2, "Column" -> 1, "Value" -> (1 + 4*eps + 4*eps^2)/
        ((1 + eps)*p)|>, <|"Row" -> 2, "Column" -> 2, 
      "Value" -> (3 + 2*eps - 5*p^2 - 2*eps*p^2)/((-1 + p)*p*(1 + p))|>, 
     <|"Row" -> 3, "Column" -> 3, "Value" -> 
       (-2*(-2 - 4*eps + 3*p^2 + 4*eps*p^2))/((-1 + p)*p*(1 + p))|>, 
     <|"Row" -> 4, "Column" -> 1, "Value" -> (2*(eps + 2*eps^2))/
        ((1 + eps)*p)|>, <|"Row" -> 4, "Column" -> 2, 
      "Value" -> (2*(1 + eps))/((1 + 2*eps)*p)|>, 
     <|"Row" -> 4, "Column" -> 4, "Value" -> (4 + 3*eps - 6*p^2 - 3*eps*p^2)/
        ((-1 + p)*p*(1 + p))|>, <|"Row" -> 4, "Column" -> 5, 
      "Value" -> -2*p|>, <|"Row" -> 5, "Column" -> 1, 
      "Value" -> (-2 - 8*eps - 8*eps^2 + p^2 + 7*eps*p^2 + 10*eps^2*p^2)/
        ((-1 + p)*p^3*(1 + p))|>, <|"Row" -> 5, "Column" -> 2, 
      "Value" -> (4 + 9*eps + 5*eps^2)/((1 + 2*eps)*(-1 + p)*p*(1 + p))|>, 
     <|"Row" -> 5, "Column" -> 3, "Value" -> (-6 - 25*eps - 25*eps^2)/
        (2*(-1 + p)*p^5*(1 + p))|>, <|"Row" -> 5, "Column" -> 4, 
      "Value" -> (2 + 5*eps + 3*eps^2)/(2*(-1 + p)*p*(1 + p))|>, 
     <|"Row" -> 5, "Column" -> 5, "Value" -> (5 + 3*eps - 11*p^2 - 7*eps*p^2)/
        ((-1 + p)*p*(1 + p))|>, <|"Row" -> 6, "Column" -> 6, 
      "Value" -> (-2*(-2*eps - 5*p^2 - 2*eps*p^2 + 6*p^4 + 4*eps*p^4))/
        ((-1 + p)*p*(1 + p)*(-1 + 2*p^2))|>}, "ZeroEigenspaceBlock" -> 
    {{(-2*(-1 - eps + 2*p^2 + eps*p^2))/((-1 + p)*p*(1 + p)), 0, 0, 0, 0}, 
     {(1 + 4*eps + 4*eps^2)/((1 + eps)*p), (3 + 2*eps - 5*p^2 - 2*eps*p^2)/
       ((-1 + p)*p*(1 + p)), 0, 0, 0}, 
     {0, 0, (-2*(-2 - 4*eps + 3*p^2 + 4*eps*p^2))/((-1 + p)*p*(1 + p)), 0, 
      0}, {(2*(eps + 2*eps^2))/((1 + eps)*p), (2*(1 + eps))/((1 + 2*eps)*p), 
      0, (4 + 3*eps - 6*p^2 - 3*eps*p^2)/((-1 + p)*p*(1 + p)), -2*p}, 
     {(-2 - 8*eps - 8*eps^2 + p^2 + 7*eps*p^2 + 10*eps^2*p^2)/
       ((-1 + p)*p^3*(1 + p)), (4 + 9*eps + 5*eps^2)/((1 + 2*eps)*(-1 + p)*p*
        (1 + p)), (-6 - 25*eps - 25*eps^2)/(2*(-1 + p)*p^5*(1 + p)), 
      (2 + 5*eps + 3*eps^2)/(2*(-1 + p)*p*(1 + p)), 
      (5 + 3*eps - 11*p^2 - 7*eps*p^2)/((-1 + p)*p*(1 + p))}}, 
   "NonzeroEigenspaceBlock" -> 
    {{(-2*(-2*eps - 5*p^2 - 2*eps*p^2 + 6*p^4 + 4*eps*p^4))/
       ((-1 + p)*p*(1 + p)*(-1 + 2*p^2))}}, "CrossToNonzero" -> 
    {{0}, {0}, {0}, {0}, {0}}, "CrossFromNonzero" -> {{0, 0, 0, 0, 0}}|>, 
 "AcceptedTargetGauge" -> <|"Convention" -> "I25=T25.F25", 
   "Provenance" -> "accepted CF303 PhysicalGaugeByOrderPairs at rho=0", 
   "Matrix" -> {{(-2 - 3*eps)/(4*(-1 + p)^2*p^4*(1 + p)^2), 
      ((2 + 3*eps)*(2 + p))/(8*(-1 + p)^2*p^4*(1 + p)^2)}, 
     {(-2 - 7*eps - 6*eps^2)/(4*(-1 + p)^3*p^4*(1 + p)^3), 
      (2 + 9*eps + 9*eps^2 + 8*p + 28*eps*p + 24*eps^2*p + 2*p^2 + 
        5*eps*p^2 + 3*eps^2*p^2)/(16*(-1 + p)^3*p^5*(1 + p)^3)}}, 
   "Inverse" -> {{(4*(-1 + p)*p^4*(1 + p)*(1 + 3*eps + 4*p + 8*eps*p + p^2 + 
         eps*p^2))/((1 + 3*eps)*(2 + 3*eps)), 
      (-8*(-1 + p)^2*p^5*(1 + p)^2*(2 + p))/((1 + 3*eps)*(2 + 3*eps))}, 
     {(16*(1 + 2*eps)*(-1 + p)*p^5*(1 + p))/((1 + 3*eps)*(2 + 3*eps)), 
      (-16*(-1 + p)^2*p^5*(1 + p)^2)/((1 + 3*eps)*(2 + 3*eps))}}, 
   "Determinant" -> (4 + 24*eps + 45*eps^2 + 27*eps^3)/
     (64*(-1 + p)^4*p^9*(1 + p)^4), "AcceptedModeFrame" -> 
    {{1, 0, 0, 0, 0, 0}, {0, 1, 0, 0, 0, 0}, {0, 0, 1, 0, 0, 0}, 
     {0, 0, (2 + 5*eps)/(2*p^2), 0, 0, 1}, 
     {0, 0, 0, (-2 - 3*eps)/(4*(-1 + p)^2*p^4*(1 + p)^2), 
      ((2 + 3*eps)*(2 + p))/(8*(-1 + p)^2*p^4*(1 + p)^2), 0}, 
     {0, 0, 0, (-2 - 7*eps - 6*eps^2)/(4*(-1 + p)^3*p^4*(1 + p)^3), 
      (2 + 9*eps + 9*eps^2 + 8*p + 28*eps*p + 24*eps^2*p + 2*p^2 + 
        5*eps*p^2 + 3*eps^2*p^2)/(16*(-1 + p)^3*p^5*(1 + p)^3), -p^(-2)}}, 
   "TangentialConnectionSparseEntries" -> 
    {<|"Row" -> 1, "Column" -> 1, "Value" -> 
       (-2*(-1 - eps + 2*p^2 + eps*p^2))/((-1 + p)*p*(1 + p))|>, 
     <|"Row" -> 2, "Column" -> 1, "Value" -> (1 + 4*eps + 4*eps^2)/
        ((1 + eps)*p)|>, <|"Row" -> 2, "Column" -> 2, 
      "Value" -> (3 + 2*eps - 5*p^2 - 2*eps*p^2)/((-1 + p)*p*(1 + p))|>, 
     <|"Row" -> 3, "Column" -> 3, "Value" -> 
       (-2*(-2 - 4*eps + 3*p^2 + 4*eps*p^2))/((-1 + p)*p*(1 + p))|>, 
     <|"Row" -> 4, "Column" -> 1, "Value" -> 
       (-8*(-1 + p)*(1 + p)*(-4*p^2 - 20*eps*p^2 - 32*eps^2*p^2 - 
          16*eps^3*p^2 - 2*p^3 - 11*eps*p^3 - 21*eps^2*p^3 - 14*eps^3*p^3 + 
          2*p^4 + 12*eps*p^4 + 18*eps^2*p^4 + 4*eps^3*p^4 + p^5 + 7*eps*p^5 + 
          14*eps^2*p^5 + 8*eps^3*p^5))/((1 + eps)*(1 + 3*eps)*(2 + 3*eps))|>, 
     <|"Row" -> 4, "Column" -> 2, "Value" -> 
       (-8*(p^3 + 4*eps*p^3 + 3*eps^2*p^3 - 4*p^4 - 6*eps*p^4 - 2*eps^2*p^4 - 
          4*p^5 - 11*eps*p^5 - 7*eps^2*p^5 + 4*p^6 + 6*eps*p^6 + 
          2*eps^2*p^6 + 3*p^7 + 7*eps*p^7 + 4*eps^2*p^7))/
        ((1 + 2*eps)*(1 + 3*eps)*(2 + 3*eps))|>, <|"Row" -> 4, "Column" -> 3, 
      "Value" -> (4*(-12 - 50*eps - 50*eps^2 - 6*p - 25*eps*p - 25*eps^2*p + 
          12*p^2 + 50*eps*p^2 + 50*eps^2*p^2 + 6*p^3 + 25*eps*p^3 + 
          25*eps^2*p^3))/((1 + 3*eps)*(2 + 3*eps))|>, 
     <|"Row" -> 4, "Column" -> 4, "Value" -> (3*eps + 2*eps*p - 6*eps*p^2)/
        ((-1 + p)*p*(1 + p))|>, <|"Row" -> 4, "Column" -> 5, 
      "Value" -> (-eps + 4*eps*p)/(2*(-1 + p)*(1 + p))|>, 
     <|"Row" -> 5, "Column" -> 1, "Value" -> 
       (-16*(-1 + p)*(1 + p)*(-2*p^2 - 10*eps*p^2 - 16*eps^2*p^2 - 
          8*eps^3*p^2 + p^4 + 6*eps*p^4 + 9*eps^2*p^4 + 2*eps^3*p^4))/
        ((1 + eps)*(1 + 3*eps)*(2 + 3*eps))|>, <|"Row" -> 5, "Column" -> 2, 
      "Value" -> (-16*(2 + 3*eps + eps^2)*(-1 + p)*p^4*(1 + p))/
        ((1 + 2*eps)*(1 + 3*eps)*(2 + 3*eps))|>, <|"Row" -> 5, "Column" -> 3, 
      "Value" -> (8*(-6 - 25*eps - 25*eps^2 + 6*p^2 + 25*eps*p^2 + 
          25*eps^2*p^2))/((1 + 3*eps)*(2 + 3*eps))|>, 
     <|"Row" -> 5, "Column" -> 4, "Value" -> (2*eps)/((-1 + p)*(1 + p))|>, 
     <|"Row" -> 5, "Column" -> 5, "Value" -> (3*eps - 2*eps*p - 4*eps*p^2)/
        ((-1 + p)*p*(1 + p))|>, <|"Row" -> 6, "Column" -> 6, 
      "Value" -> (-2*(-2*eps - 5*p^2 - 2*eps*p^2 + 6*p^4 + 4*eps*p^4))/
        ((-1 + p)*p*(1 + p)*(-1 + 2*p^2))|>}, "TargetEpsilonConnection" -> 
    {{(eps*(3 + 2*p - 6*p^2))/((-1 + p)*p*(1 + p)), 
      (eps*(-1 + 4*p))/(2*(-1 + p)*(1 + p))}, {(2*eps)/((-1 + p)*(1 + p)), 
      (eps*(3 - 2*p - 4*p^2))/((-1 + p)*p*(1 + p))}}, 
   "TargetGPLCouplings" -> <|"InvP" -> {{-3, 0}, {0, -3}}, 
     "InvOneMinusP" -> {{1/2, -3/4}, {-1, 3/2}}, "InvOnePlusP" -> 
      {{-5/2, 5/4}, {-1, 1/2}}|>, "GPLAlphabet" -> {0, 1, -1}|>, 
 "EpsilonNormalizedNonzeroMode" -> <|"Convention" -> "J6=rho^-2 R6 K6", 
   "IntegerShearPower" -> -2, "NormalExponentBefore" -> -2*(1 + 2*eps), 
   "NormalExponentAfter" -> 2 - 2*(1 + 2*eps), 
   "R6" -> 1/((1 - 2*p^2)^2*(1 - p^2)), "TangentialConnectionAfter" -> 
    eps*(4/p + (16*p)/(1 - 2*p^2)), "GPLAlphabet" -> 
    {0, 1/Sqrt[2], -(1/Sqrt[2])}|>, "ProductionInput" -> 
  <|"Status" -> "CF303SixModeRationalLayerInputAcceptedV1", 
   "FrameColumnOrder" -> {"Block24Mode1", "Block24Mode2", "Block23Zero", 
     "TargetMode1", "TargetMode2", "Block23Nonzero"}, 
   "SourceModeOrder" -> {"Block24Mode1", "Block24Mode2", "Block23Zero", 
     "Block23Nonzero"}, "PhysicalModeFrame" -> 
    {{1/(p^2*(-1 + p^2)), 0, 0, 0, 0, 0}, 
     {1/(p^2*(-1 + p^2)) + (eps*(3 + 4*eps))/((1 + eps)*p^2*(-1 + p^2)), 
      1/(p^3*(-1 + p^2)), 0, 0, 0, 0}, {0, 0, 1/(p^4*(-1 + p^2)), 0, 0, 0}, 
     {0, 0, (2 + 5*eps)/(2*p^6*(-1 + p^2)), 0, 0, 
      1/((1 - 2*p^2)^2*(1 - p^2))}, {0, 0, 0, (-2 - 3*eps)/
       (4*(-1 + p)^2*p^4*(1 + p)^2), ((2 + 3*eps)*(2 + p))/
       (8*(-1 + p)^2*p^4*(1 + p)^2), 0}, {0, 0, 0, (-2 - 7*eps - 6*eps^2)/
       (4*(-1 + p)^3*p^4*(1 + p)^3), (2 + 9*eps + 9*eps^2 + 8*p + 28*eps*p + 
        24*eps^2*p + 2*p^2 + 5*eps*p^2 + 3*eps^2*p^2)/
       (16*(-1 + p)^3*p^5*(1 + p)^3), -(1/(p^2*(1 - 2*p^2)^2*(1 - p^2)))}}, 
   "TangentialConnectionSparseEntries" -> 
    {<|"Row" -> 1, "Column" -> 1, "Value" -> (-2*eps)/p|>, 
     <|"Row" -> 2, "Column" -> 2, "Value" -> (-2*eps)/p|>, 
     <|"Row" -> 3, "Column" -> 3, "Value" -> (-8*eps)/p|>, 
     <|"Row" -> 4, "Column" -> 1, "Value" -> 
       (-8*(-4 - 20*eps - 32*eps^2 - 16*eps^3 - 3*p - 17*eps*p - 32*eps^2*p - 
          20*eps^3*p + 6*p^2 + 26*eps*p^2 + 32*eps^2*p^2 + 8*eps^3*p^2 + 
          4*p^3 + 20*eps*p^3 + 32*eps^2*p^3 + 16*eps^3*p^3))/
        ((1 + eps)*(1 + 3*eps)*(2 + 3*eps))|>, <|"Row" -> 4, "Column" -> 2, 
      "Value" -> (-8*(-1 - 4*eps - 3*eps^2 + 4*p + 6*eps*p + 2*eps^2*p + 
          3*p^2 + 7*eps*p^2 + 4*eps^2*p^2))/((1 + 2*eps)*(1 + 3*eps)*
         (2 + 3*eps))|>, <|"Row" -> 4, "Column" -> 3, 
      "Value" -> (4*(12 + 50*eps + 50*eps^2 + 6*p + 25*eps*p + 25*eps^2*p))/
        ((1 + 3*eps)*(2 + 3*eps)*p^4)|>, <|"Row" -> 4, "Column" -> 4, 
      "Value" -> (3*eps + 2*eps*p - 6*eps*p^2)/((-1 + p)*p*(1 + p))|>, 
     <|"Row" -> 4, "Column" -> 5, "Value" -> (-eps + 4*eps*p)/
        (2*(-1 + p)*(1 + p))|>, <|"Row" -> 5, "Column" -> 1, 
      "Value" -> (-16*(-2 - 10*eps - 16*eps^2 - 8*eps^3 + 3*p^2 + 
          13*eps*p^2 + 16*eps^2*p^2 + 4*eps^3*p^2))/((1 + eps)*(1 + 3*eps)*
         (2 + 3*eps))|>, <|"Row" -> 5, "Column" -> 2, 
      "Value" -> (-16*(2 + 3*eps + eps^2)*p)/((1 + 2*eps)*(1 + 3*eps)*
         (2 + 3*eps))|>, <|"Row" -> 5, "Column" -> 3, 
      "Value" -> (8*(6 + 25*eps + 25*eps^2))/((1 + 3*eps)*(2 + 3*eps)*p^4)|>, 
     <|"Row" -> 5, "Column" -> 4, "Value" -> (2*eps)/((-1 + p)*(1 + p))|>, 
     <|"Row" -> 5, "Column" -> 5, "Value" -> (3*eps - 2*eps*p - 4*eps*p^2)/
        ((-1 + p)*p*(1 + p))|>, <|"Row" -> 6, "Column" -> 6, 
      "Value" -> (-4*(eps + 2*eps*p^2))/(p*(-1 + 2*p^2))|>}, 
   "Source" -> <|"Dimension" -> 4, "Letters" -> {{"GPLPole", 0}, 
       {"GPLFactor", 1 - 2*p^2, 1}}, "Residues" -> {{{-2, 0, 0, 0}, {0, -2, 
       0, 0}, {0, 0, -8, 0}, {0, 0, 0, 4}}, {{0, 0, 0, 0}, {0, 0, 0, 0}, {0, 
       0, 0, 0}, {0, 0, 0, 16}}}, "BoundarySelectors" -> 
      <|0 -> {{1, 0, 0, 0, 0, 0}, {0, 1, 0, 0, 0, 0}, {0, 0, 1, 0, 0, 0}, {0, 
        0, 0, 1, 0, 0}}|>|>, "Layer" -> <|"Rows" -> {44, 45}, 
     "PathVariable" -> p, "Regulator" -> eps, "BasePoint" -> 4/11, 
     "Endpoint" -> pFinal, "Diagonal" -> 
      {{{"GPLPole", 0}, {{-3, 0}, {0, -3}}}, {{"GPLPole", 1}, 
        {{-1/2, 3/4}, {1, -3/2}}}, {{"GPLPole", -1}, 
        {{-5/2, 5/4}, {-1, 1/2}}}}, "Incoming" -> 
      {<|"Row" -> 1, "Column" -> 1, "Coefficient" -> 
         (-8*p*(-4 - 20*eps - 32*eps^2 - 16*eps^3 - 3*p - 17*eps*p - 
            32*eps^2*p - 20*eps^3*p + 6*p^2 + 26*eps*p^2 + 32*eps^2*p^2 + 
            8*eps^3*p^2 + 4*p^3 + 20*eps*p^3 + 32*eps^2*p^3 + 16*eps^3*p^3))/
          ((1 + eps)*(1 + 3*eps)*(2 + 3*eps)), "Letter" -> {"GPLPole", 0}|>, 
       <|"Row" -> 1, "Column" -> 2, "Coefficient" -> 
         (-8*p*(-1 - 4*eps - 3*eps^2 + 4*p + 6*eps*p + 2*eps^2*p + 3*p^2 + 
            7*eps*p^2 + 4*eps^2*p^2))/((1 + 2*eps)*(1 + 3*eps)*(2 + 3*eps)), 
        "Letter" -> {"GPLPole", 0}|>, <|"Row" -> 1, "Column" -> 3, 
        "Coefficient" -> (4*(12 + 50*eps + 50*eps^2 + 6*p + 25*eps*p + 
            25*eps^2*p))/((1 + 3*eps)*(2 + 3*eps)*p^3), 
        "Letter" -> {"GPLPole", 0}|>, <|"Row" -> 2, "Column" -> 1, 
        "Coefficient" -> (-16*p*(-2 - 10*eps - 16*eps^2 - 8*eps^3 + 3*p^2 + 
            13*eps*p^2 + 16*eps^2*p^2 + 4*eps^3*p^2))/((1 + eps)*(1 + 3*eps)*
           (2 + 3*eps)), "Letter" -> {"GPLPole", 0}|>, 
       <|"Row" -> 2, "Column" -> 2, "Coefficient" -> 
         (-16*(2 + 3*eps + eps^2)*p^2)/((1 + 2*eps)*(1 + 3*eps)*(2 + 3*eps)), 
        "Letter" -> {"GPLPole", 0}|>, <|"Row" -> 2, "Column" -> 3, 
        "Coefficient" -> (8*(6 + 25*eps + 25*eps^2))/((1 + 3*eps)*(2 + 3*eps)*
           p^3), "Letter" -> {"GPLPole", 0}|>}, "ZeroColumns" -> {4}, 
     "TargetBoundarySelectors" -> 
      <|0 -> {{0, 0, 0, 0, 1, 0}, {0, 0, 0, 0, 0, 1}}|>, 
     "SharedBoundaryCoordinates" -> True|>, "BoundaryCoordinateOrder" -> 
    {"Block24Mode1", "Block24Mode2", "Block23Zero", "Block23Nonzero", 
     "IndependentTargetMode1", "IndependentTargetMode2"}, 
   "CompactPhysicalGauges" -> <|"Block24" -> {{1/(p^2*(-1 + p^2)), 0}, 
       {1/(p^2*(-1 + p^2)) + (eps*(3 + 4*eps))/((1 + eps)*p^2*(-1 + p^2)), 
        1/(p^3*(-1 + p^2))}}, "Block23Zero" -> 1/(p^4*(-1 + p^2)), 
     "Block23Nonzero" -> 1/((1 - 2*p^2)^2*(1 - p^2)), 
     "TargetBlock25" -> {{(-2 - 3*eps)/(4*(-1 + p)^2*p^4*(1 + p)^2), 
        ((2 + 3*eps)*(2 + p))/(8*(-1 + p)^2*p^4*(1 + p)^2)}, 
       {(-2 - 7*eps - 6*eps^2)/(4*(-1 + p)^3*p^4*(1 + p)^3), 
        (2 + 9*eps + 9*eps^2 + 8*p + 28*eps*p + 24*eps^2*p + 2*p^2 + 
          5*eps*p^2 + 3*eps^2*p^2)/(16*(-1 + p)^3*p^5*(1 + p)^3)}}|>, 
   "AcceptedCoordinateBinding" -> <|"Block24CanonicalToProduction" -> 
      {{(-3*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/(2*eps^3), 
        (3*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/(8*eps^3)}, 
       {0, (-3*(1 + 6*eps + 8*eps^2)*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
         (16*eps^3*(1 + eps))}}, "Block23ZeroCanonicalToProduction" -> 
      (-7*(1 + 5*eps)*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
       (4*eps^3*(1 + 4*eps)), "Block23NonzeroCanonicalToProduction" -> 
      (14*(1 + 4*eps)*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/eps^3, 
     "Block23NonzeroAcceptedTargetExtension" -> 
      {(-14*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/(eps^3*(2 + 3*eps)), 
       (-14*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/(eps^3*(2 + 3*eps))}, 
     "Block23NonzeroTargetExtensionInProductionNormalization" -> 
      {-(1/((2 + 3*eps)*(1 + 4*eps))), -(1/((2 + 3*eps)*(1 + 4*eps)))}, 
     "TargetExtensionEncodedInNonzeroModeFrame" -> True, 
     "TargetBoundarySelectorsContainOnlyIndependentZeroModes" -> True, 
     "FrobeniusRegularPrefactorRequired" -> True|>, 
   "PrepareOnlyControl" -> <|"Status" -> "Prepared", "Orders" -> {0}, 
     "Factors" -> {-1 + p, p, 1 + p, -1/2 + p^2}, "Dimensions" -> {2, 4}, 
     "SharedBoundaryCoordinates" -> True|>, "FullRunEvidence" -> 
    <|"DemandPairs" -> {{0, 1}, {0, 2}}, "TransportStatus" -> 
      "RationalEpsilonLayerTransportAccepted", 
     "Route" -> "SealedModularCircuit", "GaugeStatus" -> 
      "GaugeRationalFunctionReconstructed", "GaugeRepresentation" -> 
      "RationalFunction", "Window" -> {0, 0}, 
     "Primes" -> {1545924587, 1979909543, 1511375849}, 
     "FreshValidationPrime" -> 1928321617, "GaugeOrders" -> {0}, 
     "GaugeNonzeroEntries" -> 6, "GaugeByteCount" -> 3112, 
     "TransportByteCount" -> 37712, "FourArgumentPredicate" -> True, 
     "OperatorStatus" -> "RationalEpsilonLayerOperatorAccepted", 
     "OperatorPredicate" -> True, "OperatorByteCount" -> 26320, 
     "TimingsSeconds" -> <|"Transport" -> 0.042469, 
       "Operator" -> 0.000789|>|>, "AcceptedZPathJunction" -> 
    <|"Status" -> "CF303AcceptedZPathJunctionModeMapV1", 
     "Junction" -> <|"p" -> pFinal, "z" -> 2*pFinal, "NormalCoordinate" -> 
        "rho=2p-z", "Prescription" -> "TangentialRegularized"|>, 
     "AcceptedSourceStateRows" -> {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 
      14, 15, 16, 17, 18, 19, 20, 21, 22, 26, 27, 29, 30, 31, 32, 33, 34, 35, 
      36, 39, 40, 41, 42, 43, 23, 24, 25, 28, 37, 38}, 
     "SourceModeMap" -> SparseArray[Automatic, {43, 6}, 0, 
       {1, {{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
         0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 3, 5, 6, 6, 6, 6, 6, 6, 
         6}, {{3}, {4}, {4}, {1}, {2}, {2}}}, 
        {(-4*eps^3*(1 + 4*eps))/(7*(1 + 5*eps)*(-2 + 13*eps - 27*eps^2 + 
            18*eps^3)), eps^3/(14*(1 + 4*eps)*(-2 + 13*eps - 27*eps^2 + 
            18*eps^3)), -1/7*eps^3/((1 + 4*eps)*(-2 + 13*eps - 27*eps^2 + 
             18*eps^3)), (-2*eps^3)/(3*(-2 + 13*eps - 27*eps^2 + 18*eps^3)), 
         (-4*(eps^3 + eps^4))/(3*(-2 + eps + 35*eps^2 - 40*eps^3 - 
            108*eps^4 + 144*eps^5)), (-16*(eps^3 + eps^4))/
          (3*(-2 + eps + 35*eps^2 - 40*eps^3 - 108*eps^4 + 144*eps^5))}}], 
     "IndependentTargetRepresentation" -> "F25", 
     "IndependentTargetF25ModeMap" -> SparseArray[Automatic, {2, 6}, 0, 
       {1, {{0, 1, 2}, {{5}, {6}}}, {1, 1}}], 
     "KnownG25NormalResidueExtension" -> SparseArray[Automatic, {2, 6}, 0, 
       {1, {{0, 1, 2}, {{4}, {4}}}, {-(1/((2 + 3*eps)*(1 + 4*eps))), 
         -(1/((2 + 3*eps)*(1 + 4*eps)))}}], "TargetModeMapComplete" -> False, 
     "MissingTargetConversion" -> "Apply G25=F25-H.F_source with the \
principal and finite local H deck contracted against source Frobenius jets", 
     "PhysicalNormalExponents" -> {0, 0, 0, -2 - 4*eps, 0, 0}, 
     "CanonicalNormalExponents" -> {0, 0, 0, -4*eps, 0, 0}, 
     "AcceptedZBasePoint" -> 1/2, "AcceptedZBoundaryColumns" -> 293, 
     "RequiresRegularizedZRebase" -> True, "NoDirectSelectorSubstitution" -> 
      True|>|>, "KernelDecomposition" -> 
  <|"GPLAlphabet" -> {0, 1, -1, 1/Sqrt[2], -(1/Sqrt[2])}, 
   "Kernels" -> {<|"Name" -> "InvP", "Kernel" -> p^(-1), "Type" -> "GPL", 
      "Primitive" -> Log[p], "Couplings" -> {<|"Row" -> 1, "Column" -> 1, 
         "Value" -> -2*(1 + eps)|>, <|"Row" -> 2, "Column" -> 1, 
         "Value" -> (1 + 4*eps + 4*eps^2)/(1 + eps)|>, 
        <|"Row" -> 2, "Column" -> 2, "Value" -> -3 - 2*eps|>, 
        <|"Row" -> 3, "Column" -> 3, "Value" -> -4*(1 + 2*eps)|>, 
        <|"Row" -> 4, "Column" -> 1, "Value" -> (2*(eps + 2*eps^2))/
           (1 + eps)|>, <|"Row" -> 4, "Column" -> 2, 
         "Value" -> (2*(1 + eps))/(1 + 2*eps)|>, <|"Row" -> 4, "Column" -> 4, 
         "Value" -> -4 - 3*eps|>, <|"Row" -> 5, "Column" -> 1, 
         "Value" -> 1 + eps - 2*eps^2|>, <|"Row" -> 5, "Column" -> 2, 
         "Value" -> (-4 - 9*eps - 5*eps^2)/(1 + 2*eps)|>, 
        <|"Row" -> 5, "Column" -> 3, "Value" -> (6 + 25*eps + 25*eps^2)/2|>, 
        <|"Row" -> 5, "Column" -> 4, "Value" -> (-2 - 5*eps - 3*eps^2)/2|>, 
        <|"Row" -> 5, "Column" -> 5, "Value" -> -5 - 3*eps|>, 
        <|"Row" -> 6, "Column" -> 6, "Value" -> 4*eps|>}|>, 
     <|"Name" -> "InvOneMinusP", "Kernel" -> (1 - p)^(-1), "Type" -> "GPL", 
      "Primitive" -> -Log[1 - p], "Couplings" -> 
       {<|"Row" -> 1, "Column" -> 1, "Value" -> 1|>, 
        <|"Row" -> 2, "Column" -> 2, "Value" -> 1|>, 
        <|"Row" -> 3, "Column" -> 3, "Value" -> 1|>, 
        <|"Row" -> 4, "Column" -> 4, "Value" -> 1|>, 
        <|"Row" -> 5, "Column" -> 1, "Value" -> (1 + eps - 2*eps^2)/2|>, 
        <|"Row" -> 5, "Column" -> 2, "Value" -> (-4 - 9*eps - 5*eps^2)/
           (2*(1 + 2*eps))|>, <|"Row" -> 5, "Column" -> 3, 
         "Value" -> (6 + 25*eps + 25*eps^2)/4|>, <|"Row" -> 5, "Column" -> 4, 
         "Value" -> (-2 - 5*eps - 3*eps^2)/4|>, <|"Row" -> 5, "Column" -> 5, 
         "Value" -> 3 + 2*eps|>, <|"Row" -> 6, "Column" -> 6, 
         "Value" -> 1|>}|>, <|"Name" -> "InvOnePlusP", 
      "Kernel" -> (1 + p)^(-1), "Type" -> "GPL", "Primitive" -> Log[1 + p], 
      "Couplings" -> {<|"Row" -> 1, "Column" -> 1, "Value" -> -1|>, 
        <|"Row" -> 2, "Column" -> 2, "Value" -> -1|>, 
        <|"Row" -> 3, "Column" -> 3, "Value" -> -1|>, 
        <|"Row" -> 4, "Column" -> 4, "Value" -> -1|>, 
        <|"Row" -> 5, "Column" -> 1, "Value" -> (-1 - eps + 2*eps^2)/2|>, 
        <|"Row" -> 5, "Column" -> 2, "Value" -> (4 + 9*eps + 5*eps^2)/
           (2*(1 + 2*eps))|>, <|"Row" -> 5, "Column" -> 3, 
         "Value" -> (-6 - 25*eps - 25*eps^2)/4|>, <|"Row" -> 5, 
         "Column" -> 4, "Value" -> (2 + 5*eps + 3*eps^2)/4|>, 
        <|"Row" -> 5, "Column" -> 5, "Value" -> -3 - 2*eps|>, 
        <|"Row" -> 6, "Column" -> 6, "Value" -> -1|>}|>, 
     <|"Name" -> "InvP3", "Kernel" -> p^(-3), "Type" -> "ExactDerivative", 
      "Primitive" -> -1/2*1/p^2, "Couplings" -> 
       {<|"Row" -> 5, "Column" -> 1, "Value" -> 2*(1 + 4*eps + 4*eps^2)|>, 
        <|"Row" -> 5, "Column" -> 3, "Value" -> (6 + 25*eps + 25*eps^2)/
           2|>}|>, <|"Name" -> "InvP5", "Kernel" -> p^(-5), 
      "Type" -> "ExactDerivative", "Primitive" -> -1/4*1/p^4, 
      "Couplings" -> {<|"Row" -> 5, "Column" -> 3, "Value" -> 
          (6 + 25*eps + 25*eps^2)/2|>}|>, <|"Name" -> "P", "Kernel" -> p, 
      "Type" -> "ExactDerivative", "Primitive" -> p^2/2, 
      "Couplings" -> {<|"Row" -> 4, "Column" -> 5, "Value" -> -2|>}|>, 
     <|"Name" -> "QuadraticDLog", "Kernel" -> p/(1 - 2*p^2), 
      "Type" -> "GPLQuadraticDLog", "Primitive" -> -1/4*Log[1 - 2*p^2], 
      "Couplings" -> {<|"Row" -> 6, "Column" -> 6, "Value" -> 
          8*(1 + 2*eps)|>}|>}, "CoefficientEpsilonDegreeMax" -> {2, 1}, 
   "Interpretation" -> 
    "higher-pole and polynomial kernels have rational primitives"|>, 
 "Validation" -> <|"RankOneResidue" -> True, "ProjectorIdempotent" -> True, 
   "FrameDeterminantOne" -> True, "ResidueDiagonalized" -> True, 
   "CrossEigenspaceBlocksVanish" -> True, "KernelRecompositionExact" -> True, 
   "AcceptedTargetGaugeInvertible" -> True, 
   "AcceptedFrameCrossEigenspaceBlocksVanish" -> True, 
   "AcceptedTargetBlockIsEpsilonForm" -> True, 
   "NonzeroModeEpsilonNormalized" -> True, 
   "Block24GaugeIsAcceptedAndEpsilonNormalized" -> True, 
   "ProductionDiagonalBlocksAreEpsilonForm" -> True, 
   "ProductionCrossEigenspaceBlocksVanish" -> True, 
   "AcceptedTargetExtensionBoundToNonzeroFrame" -> True, 
   "RationalLayerProductionInputPrepared" -> True, 
   "FullProductionTransportAccepted" -> True, 
   "AcceptedJunctionModeMapExact" -> True|>, 
 "TimingsSeconds" -> <|"FrameAndGamma" -> 0.006719, 
   "KernelDecomposition" -> 0.01276|>|>
