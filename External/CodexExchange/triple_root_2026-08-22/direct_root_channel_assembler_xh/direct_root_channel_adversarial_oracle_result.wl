<|"Status" -> "DirectRootChannelAdversarialOracleFailed", 
 "Protocol" -> "DirectRootChannelSparsePolynomialABIV1", "PassCount" -> 16, 
 "FailureCount" -> 26, "Checks" -> 
  {<|"Label" -> "rank-0:compile", "Passed" -> True, 
    "Details" -> <|"CompileSeconds" -> 0.0162|>|>, 
   <|"Label" -> "rank-0:all-grades-active", "Passed" -> True, 
    "Details" -> <|"ActiveForcingGrades" -> {0}|>|>, 
   <|"Label" -> "rank-0-p10007-eps-1-21:split-point", "Passed" -> False, 
    "Details" -> <||>|>, <|"Label" -> "rank-0-p10007-eps-1-11:split-point", 
    "Passed" -> False, "Details" -> <||>|>, 
   <|"Label" -> "rank-0-p10039-eps-1-21:split-point", "Passed" -> False, 
    "Details" -> <||>|>, <|"Label" -> "rank-0-p10039-eps-1-11:split-point", 
    "Passed" -> False, "Details" -> <||>|>, <|"Label" -> "rank-1:compile", 
    "Passed" -> True, "Details" -> <|"CompileSeconds" -> 0.046296|>|>, 
   <|"Label" -> "rank-1:all-grades-active", "Passed" -> True, 
    "Details" -> <|"ActiveForcingGrades" -> {0, 1}|>|>, 
   <|"Label" -> "rank-1-p10007-eps-1-21:split-point", "Passed" -> False, 
    "Details" -> <||>|>, <|"Label" -> "rank-1-p10007-eps-1-11:split-point", 
    "Passed" -> False, "Details" -> <||>|>, 
   <|"Label" -> "rank-1-p10039-eps-1-21:split-point", "Passed" -> False, 
    "Details" -> <||>|>, <|"Label" -> "rank-1-p10039-eps-1-11:split-point", 
    "Passed" -> False, "Details" -> <||>|>, <|"Label" -> "rank-2:compile", 
    "Passed" -> True, "Details" -> <|"CompileSeconds" -> 0.079482|>|>, 
   <|"Label" -> "rank-2:all-grades-active", "Passed" -> True, 
    "Details" -> <|"ActiveForcingGrades" -> {0, 1, 2, 3}|>|>, 
   <|"Label" -> "rank-2-p10007-eps-1-21:split-point", "Passed" -> False, 
    "Details" -> <||>|>, <|"Label" -> "rank-2-p10007-eps-1-11:split-point", 
    "Passed" -> False, "Details" -> <||>|>, 
   <|"Label" -> "rank-2-p10039-eps-1-21:split-point", "Passed" -> False, 
    "Details" -> <||>|>, <|"Label" -> "rank-2-p10039-eps-1-11:split-point", 
    "Passed" -> False, "Details" -> <||>|>, <|"Label" -> "rank-3:compile", 
    "Passed" -> True, "Details" -> <|"CompileSeconds" -> 0.143276|>|>, 
   <|"Label" -> "rank-3:all-grades-active", "Passed" -> True, 
    "Details" -> <|"ActiveForcingGrades" -> {0, 1, 2, 3, 4, 5, 6, 7}|>|>, 
   <|"Label" -> "rank-3-p10007-eps-1-21:split-point", "Passed" -> False, 
    "Details" -> <||>|>, <|"Label" -> "rank-3-p10007-eps-1-11:split-point", 
    "Passed" -> False, "Details" -> <||>|>, 
   <|"Label" -> "rank-3-p10039-eps-1-21:split-point", "Passed" -> False, 
    "Details" -> <||>|>, <|"Label" -> "rank-3-p10039-eps-1-11:split-point", 
    "Passed" -> False, "Details" -> <||>|>, 
   <|"Label" -> "rank-3:zero-gauge-denominator-rejected", "Passed" -> True, 
    "Details" -> <||>|>, <|"Label" -> "rank-3:zero-delta-or-pole-rejected", 
    "Passed" -> True, "Details" -> <||>|>, 
   <|"Label" -> "rank-3:singular-epsilon-rejected", "Passed" -> True, 
    "Details" -> <||>|>, <|"Label" -> "rank-3:epsilon-cache-exact", 
    "Passed" -> True, "Details" -> <||>|>, 
   <|"Label" -> "rank-3:malformed-epsilon-image-rejected", "Passed" -> False, 
    "Details" -> <||>|>, <|"Label" -> "rank-3:perturbed-channel-detected", 
    "Passed" -> False, "Details" -> <||>|>, 
   <|"Label" -> "rank-3:wrong-root-image-rejected", "Passed" -> True, 
    "Details" -> <||>|>, 
   <|"Label" -> "rank-3:nonresidue-direct-point-accepted", "Passed" -> False, 
    "Details" -> <|"Point" -> $Failed, "ExpectedSplitAttemptFactor" -> 8|>|>, 
   <|"Label" -> "source-semantic-mutation-rejected", "Passed" -> True, 
    "Details" -> <||>|>, 
   <|"Label" -> "sparse-large-support-exponent-bounded", "Passed" -> False, 
    "Details" -> <||>|>, <|"Label" -> "epsilon-degree-resource-cap", 
    "Passed" -> True, "Details" -> <||>|>, 
   <|"Label" -> "root-count-resource-cap", "Passed" -> True, 
    "Details" -> <||>|>, <|"Label" -> "projection-A0-from-ASL", 
    "Passed" -> False, "Details" -> <|"ColumnCount" -> 68|>|>, 
   <|"Label" -> "projection-AS-from-ASL", "Passed" -> False, 
    "Details" -> <|"ColumnCount" -> 100|>|>, 
   <|"Label" -> "projection-AL-from-ASL", "Passed" -> False, 
    "Details" -> <|"ColumnCount" -> 72|>|>, 
   <|"Label" -> "projection-ASL-from-ASL", "Passed" -> False, 
    "Details" -> <|"ColumnCount" -> 104|>|>, 
   <|"Label" -> "native-rank-consistent-affine", "Passed" -> False, 
    "Details" -> <|"Coefficient" -> nativeRank[
        Join[Missing["KeyAbsent", "Rows"], {SymbolicZerosArray[
           {Missing["KeyAbsent", "UnknownCount"]}]}], "A", 3001], 
      "ConsistentAugmented" -> nativeRank[MapThread[Append, 
         {Join[Missing["KeyAbsent", "Rows"], {SymbolicZerosArray[
             {Missing["KeyAbsent", "UnknownCount"]}]}], 
          Mod[Missing["KeyAbsent", "Rows"] . Table[Mod[17*index + 3, prime], 
             {index, Missing["KeyAbsent", "UnknownCount"]}], 10007, 0]}], 
        "A|b-consistent", 3002], "InconsistentAugmented" -> 
       nativeRank[MapThread[Append, {Join[Missing["KeyAbsent", "Rows"], 
           {SymbolicZerosArray[{Missing["KeyAbsent", "UnknownCount"]}]}], 
          Mod[Missing["KeyAbsent", "Rows"] . Table[Mod[17*index + 3, prime], 
             {index, Missing["KeyAbsent", "UnknownCount"]}], 10007, 1]}], 
        "A|b-inconsistent", 3003]|>|>, 
   <|"Label" -> "native-rank-perturbed-inconsistent-affine", 
    "Passed" -> False, "Details" -> 
     <|"Coefficient" -> nativeRank[Join[Missing["KeyAbsent", "Rows"], 
         {SymbolicZerosArray[{Missing["KeyAbsent", "UnknownCount"]}]}], "A", 
        3001], "ConsistentAugmented" -> nativeRank[MapThread[Append, 
         {Join[Missing["KeyAbsent", "Rows"], {SymbolicZerosArray[
             {Missing["KeyAbsent", "UnknownCount"]}]}], 
          Mod[Missing["KeyAbsent", "Rows"] . Table[Mod[17*index + 3, prime], 
             {index, Missing["KeyAbsent", "UnknownCount"]}], 10007, 0]}], 
        "A|b-consistent", 3002], "InconsistentAugmented" -> 
       nativeRank[MapThread[Append, {Join[Missing["KeyAbsent", "Rows"], 
           {SymbolicZerosArray[{Missing["KeyAbsent", "UnknownCount"]}]}], 
          Mod[Missing["KeyAbsent", "Rows"] . Table[Mod[17*index + 3, prime], 
             {index, Missing["KeyAbsent", "UnknownCount"]}], 10007, 1]}], 
        "A|b-inconsistent", 3003]|>|>}, "CaseSummaries" -> {}, 
 "ProjectionEvidence" -> 
  {<|"Label" -> "A0", "ColumnMap" -> {1, 2, 4, 5, 7, 8, 10, 11, 13, 14, 16, 
      17, 19, 20, 22, 23, 25, 26, 28, 29, 31, 32, 34, 35, 37, 38, 40, 41, 43, 
      44, 46, 47, 49, 50, 52, 53, 55, 56, 58, 59, 61, 62, 64, 65, 67, 68, 70, 
      71, 73, 74, 76, 77, 79, 80, 82, 83, 85, 86, 88, 89, 91, 92, 94, 95, 97, 
      98, 99, 100}, "Passed" -> False|>, <|"Label" -> "AS", 
    "ColumnMap" -> {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 
      17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 
      35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 
      53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 
      71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 
      89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100}, "Passed" -> False|>, 
   <|"Label" -> "AL", "ColumnMap" -> {1, 2, 4, 5, 7, 8, 10, 11, 13, 14, 16, 
      17, 19, 20, 22, 23, 25, 26, 28, 29, 31, 32, 34, 35, 37, 38, 40, 41, 43, 
      44, 46, 47, 49, 50, 52, 53, 55, 56, 58, 59, 61, 62, 64, 65, 67, 68, 70, 
      71, 73, 74, 76, 77, 79, 80, 82, 83, 85, 86, 88, 89, 91, 92, 94, 95, 97, 
      98, 99, 100, 101, 102, 103, 104}, "Passed" -> False|>, 
   <|"Label" -> "ASL", "ColumnMap" -> {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 
      13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 
      31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 
      49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 
      67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 
      85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 
      102, 103, 104}, "Passed" -> False|>}, 
 "ProductionPointAcceptanceModel" -> 
  <|"DirectRequirement" -> "NonzeroDeltasAndDenominators", 
   "LegacySignRequirement" -> "AllDeltasQuadraticResidues", 
   "ExpectedRank2AttemptReduction" -> 4, "ExpectedRank3AttemptReduction" -> 
    8|>, "NativeRankEvidence" -> 
  <|"Coefficient" -> nativeRank[Join[Missing["KeyAbsent", "Rows"], 
      {SymbolicZerosArray[{Missing["KeyAbsent", "UnknownCount"]}]}], "A", 
     3001], "ConsistentAugmented" -> nativeRank[MapThread[Append, 
      {Join[Missing["KeyAbsent", "Rows"], {SymbolicZerosArray[
          {Missing["KeyAbsent", "UnknownCount"]}]}], 
       Mod[Missing["KeyAbsent", "Rows"] . Table[Mod[17*index + 3, prime], 
          {index, Missing["KeyAbsent", "UnknownCount"]}], 10007, 0]}], 
     "A|b-consistent", 3002], "InconsistentAugmented" -> 
    nativeRank[MapThread[Append, {Join[Missing["KeyAbsent", "Rows"], 
        {SymbolicZerosArray[{Missing["KeyAbsent", "UnknownCount"]}]}], 
       Mod[Missing["KeyAbsent", "Rows"] . Table[Mod[17*index + 3, prime], 
          {index, Missing["KeyAbsent", "UnknownCount"]}], 10007, 1]}], 
     "A|b-inconsistent", 3003]|>, "CapturedLoadMessages" -> "", 
 "CapturedRuntimeMessages" -> "\nPart::partd: Part specification \
Missing[KeyAbsent, Rows][[1,1]]\n     is longer than depth of \
object.\n\nLookup::invrl: The argument $Failed\n     is not a valid \
Association or a list of rules.\n\nPart::partd: Part specification \n    \
Missing[KeyAbsent, Rows][[All,\n     {1, 2, 4, 5, 7, 8, 10, 11, 13, 14, 16, \
17, 19, 20, 22, 23, 25, 26, 28, \n      29, 31, 32, 34, 35, 37, <<30>>, 83, \
85, 86, 88, 89, 91, 92, 94, 95, 97, \n      98, 99, 100}]] is longer than \
depth of object.\n\nPart::partd: Part specification \n    Missing[KeyAbsent, \
Rows][[All,\n     {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, \
18, 19, 20, \n      21, 22, 23, 24, 25, 26, <<61>>, 88, 89, 90, 91, 92, 93, \
94, 95, 96, 97, \n      98, 99, 100}]] is longer than depth of \
object.\n\nGeneral::stop: Further output of Part::partd\n     will be \
suppressed during this calculation.\n\nJoin::heads: Heads Missing and List at \
positions 1 and 2\n     are expected to be the same.\n\nTable::iterb: \
Iterator {index, Missing[KeyAbsent, UnknownCount]}\n     does not have \
appropriate bounds.\n\nTable::iterb: Iterator {index, Missing[KeyAbsent, \
UnknownCount]}\n     does not have appropriate bounds.\n\nMapThread::mptd: \n \
  Object Join[Missing[KeyAbsent, Rows], \n     \
{SymbolicZerosArray[{Missing[KeyAbsent, UnknownCount]}]}] at position {2,\n   \
  1} in MapThread[Append, {Join[Missing[KeyAbsent, Rows], \n       \
{SymbolicZerosArray[{Missing[KeyAbsent, UnknownCount]}]}], \n      \
Mod[Missing[KeyAbsent, Rows] . Table[Mod[<<2>>], {index, <<1>>}], \n       \
10007, 0]}] has only 0 of required 1 dimensions.\n\nMapThread::mptd: \n   \
Object Join[Missing[KeyAbsent, Rows], \n     \
{SymbolicZerosArray[{Missing[KeyAbsent, UnknownCount]}]}] at position {2,\n   \
  1} in MapThread[Append, {Join[Missing[KeyAbsent, Rows], \n       \
{SymbolicZerosArray[{Missing[KeyAbsent, UnknownCount]}]}], \n      \
Mod[Missing[KeyAbsent, Rows] . Table[Mod[<<2>>], {index, <<1>>}], \n       \
10007, 1]}] has only 0 of required 1 dimensions.", "MessagesEmpty" -> False, 
 "ExpectedSourceHashes" -> 
  <|"Dependencies" -> <|"LoadFACET" -> 
      "e324b5f6c30d34a70248b691183abb1904d1a27fd745e3c4b8b0b381122e6164", 
     "FeynFacetPublic" -> 
      "4af4f6a8c3b9201ba6e1088e7fec94b6f0befc1d37bc2d76f43e5509fa64ac9e", 
     "FiniteFieldStripSolve" -> 
      "c6230ae8b6b1d00780ca697cf9e6838a395682a7eabe626b17c8371357bb1671", 
     "FiniteFieldEpsForm" -> 
      "c6dce4f78bd90238b815885e3d622d23aee3cf799a484419ef07d15763e97091", 
     "FamilyEpsForm" -> 
      "436c3fc6216e7be3ee1fce41dd1c98f91f1ce733aff27308214275f1a8221ce4", 
     "TransportCharts" -> 
      "c30e2e54b63abe9eb6c3b82ec2d275b8f4bb247007f2a93fa7db879399de051a", 
     "TripleRootAlgebra" -> 
      "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab", 
     "TripleRootStripAdapter" -> 
      "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5", 
     "TripleRootAffinePilot" -> 
      "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90", 
     "TripleRootReconstructionPrototype" -> 
      "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43"|>, 
   "Adapter" -> 
    "ec35738a2ee518ece02173fd0c1bdb7bbade2aa6455943cd418cbba1725c160c", 
   "Assembler" -> 
    "7b07fd2ed5e33fe85a41daf1003e8b28b7d0efaf339b42adb4a9c660abfcf260", 
   "NativeSource" -> 
    "11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd", 
   "NativeBinary" -> 
    "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5", 
   "Driver" -> 
    "ee80be21997a10f48aaff9a784ae68fabe00653662a76086cddf9774d5863e01"|>, 
 "CompletionSourceHashes" -> 
  <|"Dependencies" -> <|"LoadFACET" -> 
      "e324b5f6c30d34a70248b691183abb1904d1a27fd745e3c4b8b0b381122e6164", 
     "FeynFacetPublic" -> 
      "4af4f6a8c3b9201ba6e1088e7fec94b6f0befc1d37bc2d76f43e5509fa64ac9e", 
     "FiniteFieldStripSolve" -> 
      "c6230ae8b6b1d00780ca697cf9e6838a395682a7eabe626b17c8371357bb1671", 
     "FiniteFieldEpsForm" -> 
      "c6dce4f78bd90238b815885e3d622d23aee3cf799a484419ef07d15763e97091", 
     "FamilyEpsForm" -> 
      "436c3fc6216e7be3ee1fce41dd1c98f91f1ce733aff27308214275f1a8221ce4", 
     "TransportCharts" -> 
      "c30e2e54b63abe9eb6c3b82ec2d275b8f4bb247007f2a93fa7db879399de051a", 
     "TripleRootAlgebra" -> 
      "fe95f47c3e800268b21293ec52dc8deba7ee647f8b89effa9da6a1ff69ec49ab", 
     "TripleRootStripAdapter" -> 
      "ed44790fd3dd1b03a6af39ecd3fdb6415def5b89bcec21ca217ad91ad4f1adc5", 
     "TripleRootAffinePilot" -> 
      "283da5d653b899a461ae69dfec0980fb1bd090579a7ea929a153cc02bfd4fe90", 
     "TripleRootReconstructionPrototype" -> 
      "8b162e6488913fc399dd519eb1f12ab88cbd495a6be2cc48310bd071778efc43"|>, 
   "Adapter" -> 
    "ec35738a2ee518ece02173fd0c1bdb7bbade2aa6455943cd418cbba1725c160c", 
   "Assembler" -> 
    "7b07fd2ed5e33fe85a41daf1003e8b28b7d0efaf339b42adb4a9c660abfcf260", 
   "NativeSource" -> 
    "11f4d337ace94efad2d3736edd5094d7091f5ce4f0ec5be9646a1bd52c5617cd", 
   "NativeBinary" -> 
    "e43a2b791d1d5b988fec9f3de1d84f4c6de5e5d7a7f66e5cdca8bc3813641cb5", 
   "Driver" -> 
    "ee80be21997a10f48aaff9a784ae68fabe00653662a76086cddf9774d5863e01"|>, 
 "SourceHashesStableAtCompletion" -> True|>
