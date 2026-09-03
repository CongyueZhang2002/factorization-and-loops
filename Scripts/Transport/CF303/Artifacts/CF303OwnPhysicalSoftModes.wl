<|
 "Status" -> "CF303OwnCanonicalSoftModesAcceptedV2",
 "Family" -> "CF303",
 "Boundary" -> <|
   "Stratum" -> "s=1-x-y=0",
   "NormalCoordinate" -> "rho=2p-u",
   "Chart" -> "Kallen2Bilinear115",
   "ContinuedSheets" -> <|"SqrtLambda2" -> "a-p",
     "SqrtBilinear115" -> "1+u a"|>|>,
 "AcceptedSourceStateRows" -> Join[Range[22], {26, 27}, Range[29, 36],
   Range[39, 43], {23, 24, 25, 28, 37, 38}],
 "OwnSourceMap" -> <|
   "OriginalMasters" -> {3, 4, 1, 2},
   "CanonicalStateRows" -> {40, 41, 42, 43},
   "AcceptedSourceCoordinates" -> {34, 35, 36, 37}|>,
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
 "FinalIncomingOwnSupport" -> <|
   "StateColumns" -> {41},
   "AcceptedSourceCoordinates" -> {35},
   "BaseChannelResidue" ->
     -28*(-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)/
       (eps^2*(2 + 3*eps)),
   "NonzeroModeTargetExtension" -> <|
     "SourceMode" -> "Block23LambdaMinus4",
     "TargetRows" -> {44, 45},
     "Value" ->
       -14*(-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)/
         (eps^3*(2 + 3*eps))|>,
   "ZeroOnOwnModes" -> {"Block23Lambda0", "Block24Lambda0E42",
     "Block24Lambda0E43"},
   "Treatment" -> "exact characteristic-zero base channel"|>,
 "PhysicalRealization" -> <|
   "AuthoritativeArtifact" -> "CF303PhysicalSoftSixSystem.wl",
   "ModeFrameArtifact" -> "CF303SixModeEndpointFrame.wl",
   "RawTransformationValuationsAccepted" -> False,
   "Reason" -> "TDiagonal.S must act on the full canonical Frobenius regular prefactor H(rho), not on a constant residue eigenvector",
   "Block23Lambda0JetReconciliation" -> <|
     "CanonicalSeed" -> {1, 0},
     "FirstJetSecondComponent" ->
       eps*(2*p^2 - 1)/(2*p^3*(1 + 4*eps)),
     "RawPhysicalRow4RhoMinus1" ->
       -7*(-2 + 13*eps - 27*eps^2 + 18*eps^3)/
         (2*eps^2*(p^2 - 1)*p^3*(2*p^2 - 1)),
     "JetPhysicalRow4RhoMinus1" ->
       7*(-2 + 13*eps - 27*eps^2 + 18*eps^3)/
         (2*eps^2*(p^2 - 1)*p^3*(2*p^2 - 1)),
     "PhysicalLeadingVector" -> {
       -7*(-2 + 13*eps - 27*eps^2 + 18*eps^3)*(1 + 5*eps)/
         (4*eps^3*(1 + 4*eps)*p^4*(p^2 - 1)),
       -7*(-2 + 13*eps - 27*eps^2 + 18*eps^3)*(1 + 5*eps)*
         (2 + 5*eps)/(8*eps^3*(1 + 4*eps)*p^6*(p^2 - 1))},
     "PhysicalResidueEigenvectorRatio" -> (2 + 5*eps)/(2*p^2)|>,
   "SpectrumReconciliation" -> <|
     "CanonicalOwn" -> {0, -4*eps, 0, 0},
     "PhysicalOwn" -> {0, -2 - 4*eps, 0, 0},
     "IntegerShiftOnNonzeroMode" -> -2|>|>,
 "InheritedTreatment" -> "separate inhomogeneous particular forcing"
|>
