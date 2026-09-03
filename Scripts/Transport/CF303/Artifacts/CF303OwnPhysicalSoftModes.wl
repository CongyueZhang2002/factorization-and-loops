<|
 "Status" -> "CF303OwnPhysicalSoftModesAcceptedV1",
 "Family" -> "CF303",
 "Boundary" -> <|
   "Stratum" -> "s=1-x-y=0",
   "NormalCoordinate" -> "rho=2p-u",
   "Chart" -> "Kallen2Bilinear115",
   "ContinuedSheets" -> <|"SqrtLambda2" -> "a-p",
     "SqrtBilinear115" -> "1+u a"|>|>,
 "Transformation" -> "I_source=(TDiagonal.S).F_canonical",
 "AcceptedSourceStateRows" -> Join[Range[22], {26, 27}, Range[29, 36],
   Range[39, 43], {23, 24, 25, 28, 37, 38}],
 "OwnSourceMap" -> <|
   "PhysicalRows" -> {40, 41, 42, 43},
   "OriginalMasters" -> {3, 4, 1, 2},
   "CanonicalStateRows" -> {40, 41, 42, 43},
   "AcceptedSourceCoordinates" -> {34, 35, 36, 37},
   "PhysicalCanonicalLeadingMap" -> {
     <|"PhysicalRow" -> 40, "OriginalMaster" -> 3,
       "CanonicalStateRow" -> 40, "Valuation" -> 0,
       "LeadingCoefficient" ->
        (-7*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
         (4*eps^3*(-1 + p)*p^4*(1 + p))|>,
     <|"PhysicalRow" -> 40, "OriginalMaster" -> 3,
       "CanonicalStateRow" -> 41, "Valuation" -> -1,
       "LeadingCoefficient" ->
        (-7*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
         (2*eps^3*(-1 + p)*p*(-1 - p + 2*p^2 + 2*p^3))|>,
     <|"PhysicalRow" -> 41, "OriginalMaster" -> 4,
       "CanonicalStateRow" -> 40, "Valuation" -> -1,
       "LeadingCoefficient" ->
        (-7*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
         (2*eps^2*(-1 + p)*p^3*(-1 - p + 2*p^2 + 2*p^3))|>,
     <|"PhysicalRow" -> 41, "OriginalMaster" -> 4,
       "CanonicalStateRow" -> 41, "Valuation" -> -2,
       "LeadingCoefficient" ->
        (7*(1 + 4*eps)*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
         (eps^3*(-1 + p)*(1 + p)*(-1 + 2*p^2)^2)|>,
     <|"PhysicalRow" -> 42, "OriginalMaster" -> 1,
       "CanonicalStateRow" -> 42, "Valuation" -> 0,
       "LeadingCoefficient" ->
        (-3*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
         (2*eps^3*(-1 + p)*p^2*(1 + p))|>,
     <|"PhysicalRow" -> 42, "OriginalMaster" -> 1,
       "CanonicalStateRow" -> 43, "Valuation" -> 0,
       "LeadingCoefficient" ->
        (3*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
         (8*eps^3*(-1 + p)*p^2*(1 + p))|>,
     <|"PhysicalRow" -> 43, "OriginalMaster" -> 2,
       "CanonicalStateRow" -> 42, "Valuation" -> 0,
       "LeadingCoefficient" ->
        (-3*(1 + 2*eps)^2*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
         (2*eps^3*(1 + eps)*(-1 + p)*p^2*(1 + p))|>,
     <|"PhysicalRow" -> 43, "OriginalMaster" -> 2,
       "CanonicalStateRow" -> 43, "Valuation" -> 0,
       "LeadingCoefficient" ->
        (3*(1 + 2*eps)*(-2 + 13*eps - 27*eps^2 + 18*eps^3)*
          (-1 - 4*eps + 2*p + 4*eps*p))/
         (16*eps^3*(1 + eps)*(-1 + p)*p^3*(1 + p))|>
     }|>,
 "OwnModeEmbedding" -> <|
   "Dimensions" -> {43, 4},
   "Representation" -> "one-based sparse row,column,value triples",
   "SparseTriples" -> {{34, 1, 1}, {34, 2, 1}, {35, 2, -2},
     {36, 3, 1}, {37, 4, 1}},
   "ModeNames" -> {"Block23Lambda0", "Block23LambdaMinus4",
     "Block24Lambda0E42", "Block24Lambda0E43"},
   "NormalizedResidueEigenvalues" -> {0, -4, 0, 0},
   "ConnectionResidueEigenvalues" -> {0, -4*eps, 0, 0},
   "InheritedSourceCoordinates" -> Complement[Range[43], Range[34, 37]]|>,
 "PhysicalModeLeadingMap" -> {
   <|"PhysicalRow" -> 40, "OriginalMaster" -> 3,
     "Mode" -> "Block23Lambda0", "Valuation" -> 0,
     "LeadingCoefficient" ->
      (-7*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
       (4*eps^3*(-1 + p)*p^4*(1 + p))|>,
   <|"PhysicalRow" -> 40, "OriginalMaster" -> 3,
     "Mode" -> "Block23LambdaMinus4", "Valuation" -> -1,
     "LeadingCoefficient" ->
      (7*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
       (eps^3*(-1 + p)*p*(-1 - p + 2*p^2 + 2*p^3))|>,
   <|"PhysicalRow" -> 41, "OriginalMaster" -> 4,
     "Mode" -> "Block23Lambda0", "Valuation" -> -1,
     "LeadingCoefficient" ->
      (-7*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
       (2*eps^2*(-1 + p)*p^3*(-1 - p + 2*p^2 + 2*p^3))|>,
   <|"PhysicalRow" -> 41, "OriginalMaster" -> 4,
     "Mode" -> "Block23LambdaMinus4", "Valuation" -> -2,
     "LeadingCoefficient" ->
      (-14*(1 + 4*eps)*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
       (eps^3*(-1 + p)*(1 + p)*(-1 + 2*p^2)^2)|>,
   <|"PhysicalRow" -> 42, "OriginalMaster" -> 1,
     "Mode" -> "Block24Lambda0E42", "Valuation" -> 0,
     "LeadingCoefficient" ->
      (-3*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
       (2*eps^3*(-1 + p)*p^2*(1 + p))|>,
   <|"PhysicalRow" -> 42, "OriginalMaster" -> 1,
     "Mode" -> "Block24Lambda0E43", "Valuation" -> 0,
     "LeadingCoefficient" ->
      (3*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
       (8*eps^3*(-1 + p)*p^2*(1 + p))|>,
   <|"PhysicalRow" -> 43, "OriginalMaster" -> 2,
     "Mode" -> "Block24Lambda0E42", "Valuation" -> 0,
     "LeadingCoefficient" ->
      (-3*(1 + 2*eps)^2*(-2 + 13*eps - 27*eps^2 + 18*eps^3))/
       (2*eps^3*(1 + eps)*(-1 + p)*p^2*(1 + p))|>,
   <|"PhysicalRow" -> 43, "OriginalMaster" -> 2,
     "Mode" -> "Block24Lambda0E43", "Valuation" -> 0,
     "LeadingCoefficient" ->
      (3*(1 + 2*eps)*(-2 + 13*eps - 27*eps^2 + 18*eps^3)*
        (-1 - 4*eps + 2*p + 4*eps*p))/
       (16*eps^3*(1 + eps)*(-1 + p)*p^3*(1 + p))|>
   },
 "FinalIncomingOwnSupport" -> <|
   "StateColumns" -> {41},
   "AcceptedSourceCoordinates" -> {35},
   "SurvivingOwnMode" -> "Block23LambdaMinus4",
   "ZeroOnOwnModes" -> {"Block23Lambda0", "Block24Lambda0E42",
     "Block24Lambda0E43"},
   "Treatment" -> "exact characteristic-zero base channel"|>,
 "InheritedTreatment" -> "separate inhomogeneous particular forcing"
|>
