<|"Status" -> "OK", "Checks" -> {<|"Name" -> "prepared_rank2_identity_frame", 
    "Pass" -> True|>, <|"Name" -> "expected_oracle_vector", "Pass" -> True|>, 
   <|"Name" -> "batch_exact_reconstruction", "Pass" -> True|>, 
   <|"Name" -> "stable_full_rank_normalized_solution", "Pass" -> True|>, 
   <|"Name" -> "reconstructed_vector_matches_oracle", "Pass" -> True|>, 
   <|"Name" -> "reconstructed_nonzero_residue", "Pass" -> True|>, 
   <|"Name" -> "reconstructed_all_four_gauge_grades", "Pass" -> True|>, 
   <|"Name" -> "exact_channel_certificate", "Pass" -> True|>, 
   <|"Name" -> "forcing_exercises_every_grade", "Pass" -> True|>, 
   <|"Name" -> "unseen_prime_and_epsilon_verification", "Pass" -> True|>, 
   <|"Name" -> "all_four_root_sign_branch_permutations_verified", 
    "Pass" -> True|>, <|"Name" -> "root_and_support_order_stable_abi", 
    "Pass" -> True|>, 
   <|"Name" -> "reordered_frame_unseen_prime_verification", "Pass" -> True|>, 
   <|"Name" -> "seen_prime_is_typed_rejection", "Pass" -> True|>, 
   <|"Name" -> "corruption_breaks_exact_certificate", "Pass" -> True|>, 
   <|"Name" -> "corruption_caught_at_unseen_prime", "Pass" -> True|>, 
   <|"Name" -> "residue_corruption_caught_at_unseen_prime", "Pass" -> True|>, 
   <|"Name" -> "abi_fingerprint_corruption_rejected", "Pass" -> True|>}, 
 "TrainingPrimes" -> {10007, 10039, 10067}, "UnseenPrime" -> 1000003, 
 "EpsilonSamples" -> {1/2, 2/3, 3/5}, "ReconstructionSeconds" -> 2.694265, 
 "PreparationSummary" -> <|"Status" -> "PreparedReconstruction", 
   "RootCount" -> 2, "GradeCount" -> 4, "RootSourceIndices" -> {2, 3}, 
   "RootFingerprints" -> 
    {"ceb5ff034e85cb923ec5b8f122cf10057bf11654dd840b7b9db7b30faa44bd94", 
     "c0838fd11402707edfcd6ce196ea3fededb7187705fb0b1102def7a441d727de"}, 
   "GaugeUnknownCount" -> 64, "ResidueUnknownCount" -> 1, 
   "UnknownCount" -> 65, "ABIFingerprint" -> 
    "7036705ff3094559eaf246981898f59d1f1669f76482e06046926b7039bbd40e"|>, 
 "ReconstructionSummary" -> <|"Status" -> "ExactReconstruction", 
   "EpsilonDegree" -> 0, "Rank" -> 65, "Nullity" -> 0, 
   "PivotColumns" -> {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 
     17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 
     35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 
     53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65}, 
   "FreeColumns" -> {}|>, "UnseenPrimeSummary" -> 
  <|"Status" -> "UnseenPrimeVerified", "Prime" -> 1000003, 
   "ABIFingerprint" -> 
    "7036705ff3094559eaf246981898f59d1f1669f76482e06046926b7039bbd40e", 
   "ResidualZero" -> True|>, "SignBranchSummaries" -> 
  {<|"Status" -> "UnseenPrimeVerified", "Prime" -> 1000003, 
    "ABIFingerprint" -> 
     "7036705ff3094559eaf246981898f59d1f1669f76482e06046926b7039bbd40e", 
    "ResidualZero" -> True|>, <|"Status" -> "UnseenPrimeVerified", 
    "Prime" -> 1000003, "ABIFingerprint" -> 
     "7036705ff3094559eaf246981898f59d1f1669f76482e06046926b7039bbd40e", 
    "ResidualZero" -> True|>, <|"Status" -> "UnseenPrimeVerified", 
    "Prime" -> 1000003, "ABIFingerprint" -> 
     "7036705ff3094559eaf246981898f59d1f1669f76482e06046926b7039bbd40e", 
    "ResidualZero" -> True|>, <|"Status" -> "UnseenPrimeVerified", 
    "Prime" -> 1000003, "ABIFingerprint" -> 
     "7036705ff3094559eaf246981898f59d1f1669f76482e06046926b7039bbd40e", 
    "ResidualZero" -> True|>}, "CorruptionSummary" -> 
  <|"Status" -> "UnseenPrimeVerificationFailed", "Prime" -> 1000003, 
   "ABIFingerprint" -> 
    "7036705ff3094559eaf246981898f59d1f1669f76482e06046926b7039bbd40e", 
   "ResidualZero" -> False|>, "ResidueCorruptionSummary" -> 
  <|"Status" -> "UnseenPrimeVerificationFailed", "Prime" -> 1000003, 
   "ABIFingerprint" -> 
    "7036705ff3094559eaf246981898f59d1f1669f76482e06046926b7039bbd40e", 
   "ResidualZero" -> False|>, "ABICorruptionSummary" -> 
  <|"Status" -> "ReconstructionABIMismatch", "ResultABIFingerprint" -> 
    "intentionally-corrupted", "PreparationABIFingerprint" -> 
    "7036705ff3094559eaf246981898f59d1f1669f76482e06046926b7039bbd40e"|>|>
