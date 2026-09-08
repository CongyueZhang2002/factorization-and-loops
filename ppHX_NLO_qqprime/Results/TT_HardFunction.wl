<|"Format" -> "FeynFacet-NLOHardFunction", "FormatVersion" -> 1, 
 "Variables" -> {v, w}, "Scale" -> s, "DensityConvention" -> 
  "E_c d sigma/d^3 p_c", "PerturbativeTerms" -> 
  <|"LO" -> <|"DeltaCoefficient" -> 0, "PlusCoefficients" -> <||>, 
     "RegularCoefficient" -> 0|>, "NLO" -> <|"DeltaCoefficient" -> 0, 
     "PlusCoefficients" -> <|0 -> 0, 1 -> 0|>, "RegularCoefficient" -> 0|>|>, 
 "PoleCancellation" -> 
  "Exact symbolic zero in every delta, plus and regular coefficient", 
 "Contributions" -> {"Real", "Virtual", "PDFIncomingA01", "PDFIncomingB02", 
   "FFObserved03", "UV"}, "Domain" -> s > 0 && 0 < v < 1 && 0 < w < 1 && 
   muR2 > 0 && muFA2 > 0 && muFB2 > 0 && muD2 > 0, 
 "Description" -> <|"Channel" -> "q qprime -> observed q + X", 
   "IncomingPolarization" -> {"T", "T"}, "Fragmentation" -> "D1", 
   "Coupling" -> "Physical alpha_s powers included", 
   "ValidationStatus" -> "Exact pole cancellation; external finite reference \
comparison separately recorded"|>, "PlusConvention" -> "PlusCoefficients[k] \
multiplies [Log[1-w]^k/(1-w)]_+ on [0,1]; test functions exclude w=0 and \
v=0,1"|>
