<|"Status" -> "OK", "Purpose" -> "TypedComparatorDebug", "Family" -> "CF300", 
 "Sector" -> 8, "Rows" -> {12, 13, 14, 15}, 
 "Fixture" -> <|"StateFile" -> "/home/maxzhang/factorization-and-loops/Extern\
al/CodexExchange/triple_root_2026-08-22/cf300_sector8_solved_snapshot/sector_\
state_CF300_codex_triple_root.wl", "StateSHA256" -> 
    "e4ef98ddaf0fd8e2e4adb6dacb9184081741ed219b4f839e3b19ce5ca9ffb270", 
   "CheckpointFile" -> "/home/maxzhang/factorization-and-loops/External/Codex\
Exchange/triple_root_2026-08-22/cf300_sector8_solved_snapshot/sector_CF300_co\
dex_triple_root/CF300_8_strip_state.wl", "CheckpointSHA256" -> 
    "dc2feb7cee9d6255d544109374df156cd58f512608872b445f3b19e9e6bc3fea"|>, 
 "CorrectionClassification" -> <|"Status" -> "ExactRootClassification", 
   "Family" -> "CF300", "Sector" -> 8, "LowerSector" -> 1, 
   "RootIndices" -> {1}, "RootCount" -> 1, "RootSquares" -> 
    {1 + 2*x + x^2 - 2*y + 2*x*y + y^2}, "RadicalBases" -> 
    {1 + 2*x + x^2 - 2*y + 2*x*y + y^2}, "UnclassifiedRadicalBases" -> {}|>, 
 "FullFormulaClassification" -> <|"Status" -> "ExactRootClassification", 
   "Family" -> "CF300", "Sector" -> 8, "LowerSector" -> 1, 
   "RootIndices" -> {1, 2, 3}, "RootCount" -> 3, 
   "RootSquares" -> {1 + 2*x + x^2 - 2*y + 2*x*y + y^2, 
     1 - 2*x + x^2 + 2*y + 2*x*y + y^2, 1 - 4*x*y}, 
   "RadicalBases" -> {1 + 2*x + x^2 - 2*y + 2*x*y + y^2, 
     1 - 2*x + x^2 + 2*y + 2*x*y + y^2, 1 - 4*x*y}, 
   "UnclassifiedRadicalBases" -> {}|>, "RootOrderCanonical" -> True, 
 "FullRootCount" -> 3, "FullPreparationSeconds" -> 5.020377, 
 "ExactIndependentTemplateSeconds" -> 0.923874, 
 "FullStatistics" -> <|"Connection" -> <|"CandidateEntries" -> 286, 
     "Products" -> 722, "Touched" -> 108, "TermCount" -> 884|>, 
   "Transformation" -> <|"CandidateEntries" -> 264, "Products" -> 36, 
     "Touched" -> 36, "TermCount" -> 36|>, 
   "Inverse" -> <|"CandidateEntries" -> 96, "Products" -> 36, 
     "Touched" -> 36, "TermCount" -> 36|>, "DerivativeTerms" -> 54, 
   "PrepareSeconds" -> 5.019894|>, "FutureAOnlyTouched" -> 0, 
 "FutureAOnlyTermCount" -> 0, "Samples" -> 
  {<|"Role" -> "Construction", "Prime" -> 1000003, 
    "Point" -> {550663, 659718}, "EpsilonValue" -> 7, 
    "SplitSearchAttempts" -> 1, "FullRankEvaluateSeconds" -> 65.143657, 
    "FutureAOnlyEvaluateSeconds" -> 0.001466, "FullRankBranches" -> {0, 1, 2, 
     3, 4, 5, 6, 7}, "FullHadamardRoundTrip" -> True, 
    "FutureHadamardRoundTrip" -> True, "IndependentDirectSeconds" -> 
     1.290931, "IndependentDirectCheck" -> <|"AllBranchesExact" -> True, 
      "Status" -> "Compared", "BranchExact" -> 
       {<|"Connection" -> True, "Transformation" -> True, 
         "Inverse" -> True|>, <|"Connection" -> True, "Transformation" -> 
          True, "Inverse" -> True|>, <|"Connection" -> True, 
         "Transformation" -> True, "Inverse" -> True|>, 
        <|"Connection" -> True, "Transformation" -> True, 
         "Inverse" -> True|>, <|"Connection" -> True, "Transformation" -> 
          True, "Inverse" -> True|>, <|"Connection" -> True, 
         "Transformation" -> True, "Inverse" -> True|>, 
        <|"Connection" -> True, "Transformation" -> True, 
         "Inverse" -> True|>, <|"Connection" -> True, "Transformation" -> 
          True, "Inverse" -> True|>}|>, "SampleFingerprint" -> 
     "6919f4351d6c262dfcb629e6295245a07fd57ada23f7013818916f047252a3fc"|>}, 
 "AllIndependentExact" -> True, "AllHadamardRoundTrips" -> True, 
 "TwoConstructionPlusUnseen" -> False, "CorruptionStatus" -> 
  "PreparationFingerprintMismatch", "MemoryBytes" -> 
  <|"BeforeLoad" -> 209248000, "BeforePrepare" -> 265970464, 
   "AfterFullPrepare" -> 293116496, "MaxMemoryUsed" -> 955533888|>, 
 "ProductionDecision" -> <|"HookNow" -> False, "Reason" -> "This test \
certifies the modular evaluator, not interpolation/CRT/rational \
reconstruction; production may use it only after the future-row channels \
reconstruct and pass an exact unspecialized gate faster than the \
installed-row sparse exact path.", "EligibleScope" -> "Future-row connection \
entries after installing the certified current dlog row; keep transformation \
and inverse on exact sparse/copy paths."|>|>
