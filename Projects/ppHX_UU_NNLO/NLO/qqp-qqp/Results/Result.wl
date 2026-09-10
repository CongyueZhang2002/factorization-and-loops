<|"Project" -> "ppHX_UU_NNLO", "Channel" -> "qqp-qqp", "Scale" -> Global`s, 
 "Variables" -> {Global`v, Global`w}, "Coupling" -> FeynFacet`\[Alpha]s, 
 "CouplingPower" -> 3, "DimensionalPrefactor" -> 
  Global`muR2^(2*Global`Epsilon), "PhysicalChannel" -> 
  <|"Incoming" -> {{"q", "u"}, {"q", "d"}}, "Observed" -> {"q", "u"}, 
   "Recoil" -> {"q", "d"}|>, "Polarization" -> <|"Incoming" -> {"U", "U"}, 
   "Observed" -> "U"|>, "Order" -> "NLO", "Contribution" -> "Total", 
 "DimensionalRegulator" -> Global`Epsilon, "PoleCancellation" -> 
  "Exact symbolic zero in every delta, plus and regular coefficient", 
 "Contributions" -> {"Real", "Virtual", "Counterterm"}, 
 "Domain" -> Global`s > 0 && 0 < Global`v < 1 && 0 < Global`w < 1 && 
   Global`muR2 > 0 && Global`muFA2 > 0 && Global`muFB2 > 0 && 
   Global`muD2 > 0, "Description" -> 
  <|"Channel" -> "q qprime -> observed q + X", 
   "Polarization" -> <|"Incoming" -> {"U", "U"}, "Observed" -> "U"|>, 
   "Fragmentation" -> "D1", "Coupling" -> 
    "Physical alpha_s powers included"|>, 
 "Format" -> "FeynFacet-PartonicResult", "FormatVersion" -> 1, 
 "EpsilonRange" -> {0, 0}, "LaurentLowerBound" -> 0, 
 "Coefficients" -> 
  <|0 -> <|"DeltaCoefficient" -> ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (225 + 115*FeynCalc`CA^2 - 40*FeynCalc`CA*Global`nD - 
          40*FeynCalc`CA*Global`nU + 42*System`Pi^2 + 12*FeynCalc`CA^2*
           System`Pi^2 + 225*Global`v^2 + 115*FeynCalc`CA^2*Global`v^2 - 
          40*FeynCalc`CA*Global`nD*Global`v^2 - 40*FeynCalc`CA*Global`nU*
           Global`v^2 - 30*System`Pi^2*Global`v^2 + 48*FeynCalc`CA^2*
           System`Pi^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
        (144*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v) - 
       (3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v^2)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muFA2])/
        (16*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(11*FeynCalc`CA - 2*Global`nD - 
          2*Global`nU)*(1 + Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muR2])/(12*FeynCalc`CA^2*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (27 + 17*FeynCalc`CA^2 - 8*FeynCalc`CA*Global`nD - 
          8*FeynCalc`CA*Global`nU)*(1 + Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`s])/(48*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v) + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (5 + 2*FeynCalc`CA^2 - 3*Global`v^2 + 4*FeynCalc`CA^2*Global`v^2)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v]^2)/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v) + 
       (-1/16*((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(5 - FeynCalc`CA^2 - 
             8*Global`v + 4*FeynCalc`CA^2*Global`v - 3*Global`v^2 + 
             3*FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
           (FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v) + 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(2*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v))*
        System`Log[Global`v] + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (-16 + 9*FeynCalc`CA^2 - 20*Global`v^2 + 11*FeynCalc`CA^2*
           Global`v^2)*FeynFacet`\[Alpha]s^3*System`Log[Global`v]^2)/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v) + 
       System`Log[Global`muD2]*((-3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           (1 + Global`v^2)*FeynFacet`\[Alpha]s^3)/(16*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v) - 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`v])/(4*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v)) + 
       System`Log[Global`muFB2]*((-3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           (1 + Global`v^2)*FeynFacet`\[Alpha]s^3)/(16*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v) + 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v])/
          (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v) - 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`v])/(4*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v)) + 
       System`Log[1 - Global`v]*(-1/12*((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
            (3 + 5*FeynCalc`CA^2 - 2*FeynCalc`CA*Global`nD - 
             2*FeynCalc`CA*Global`nU - 3*FeynCalc`CA^2*Global`v + 
             15*Global`v^2 + 2*FeynCalc`CA^2*Global`v^2 - 2*FeynCalc`CA*
              Global`nD*Global`v^2 - 2*FeynCalc`CA*Global`nU*Global`v^2)*
            FeynFacet`\[Alpha]s^3)/(FeynCalc`CA^3*System`Pi*Global`s^2*
            (-1 + Global`v)^2*Global`v) - ((-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*(1 + Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v) - ((-1 + FeynCalc`CA)*
           (1 + FeynCalc`CA)*(-5 + 4*FeynCalc`CA^2 - 9*Global`v^2 + 
            6*FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v)), "PlusCoefficients" -> 
      <|0 -> (-3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v^2)*
           FeynFacet`\[Alpha]s^3)/(16*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v) - ((-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*(1 + Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muD2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v) - ((-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*(1 + Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFA2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v) - ((-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*(1 + Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFB2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v) + (3*(-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*(1 + Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v) - ((-1 + FeynCalc`CA)*
           (1 + FeynCalc`CA)*(1 + FeynCalc`CA^2)*(1 + Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v])/
          (2*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v) + 
         ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-11 + 7*FeynCalc`CA^2)*
           (1 + Global`v^2)*FeynFacet`\[Alpha]s^3*System`Log[Global`v])/
          (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v), 
       1 -> (5*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v^2)*
          FeynFacet`\[Alpha]s^3)/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
          (-1 + Global`v)^2*Global`v)|>, "RegularCoefficient" -> 
      -1/16*((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-4 + 4*FeynCalc`CA^2 + 
           8*Global`v - 8*FeynCalc`CA^2*Global`v - 8*Global`v^2 + 
           8*FeynCalc`CA^2*Global`v^2 + 4*Global`v^3 - 4*FeynCalc`CA^2*
            Global`v^3 - 6*Global`w + 2*FeynCalc`CA^2*Global`w + 
           27*Global`v*Global`w - 7*FeynCalc`CA^2*Global`v*Global`w - 
           58*Global`v^2*Global`w + 18*FeynCalc`CA^2*Global`v^2*Global`w + 
           61*Global`v^3*Global`w - 25*FeynCalc`CA^2*Global`v^3*Global`w - 
           28*Global`v^4*Global`w + 16*FeynCalc`CA^2*Global`v^4*Global`w + 
           12*Global`v*Global`w^2 - 4*FeynCalc`CA^2*Global`v*Global`w^2 - 
           16*Global`v^2*Global`w^2 + 8*FeynCalc`CA^2*Global`v^2*Global`w^2 + 
           9*Global`v^3*Global`w^2 + 3*FeynCalc`CA^2*Global`v^3*Global`w^2 - 
           19*Global`v^4*Global`w^2 - 9*FeynCalc`CA^2*Global`v^4*Global`w^2 + 
           24*Global`v^5*Global`w^2 - 8*FeynCalc`CA^2*Global`v^5*Global`w^2 - 
           30*Global`v^3*Global`w^3 - 10*FeynCalc`CA^2*Global`v^3*
            Global`w^3 + 71*Global`v^4*Global`w^3 + 17*FeynCalc`CA^2*
            Global`v^4*Global`w^3 - 61*Global`v^5*Global`w^3 + 
           FeynCalc`CA^2*Global`v^5*Global`w^3 + 4*Global`v^6*Global`w^3 + 
           8*FeynCalc`CA^2*Global`v^6*Global`w^3 - 12*Global`v^3*Global`w^4 + 
           4*FeynCalc`CA^2*Global`v^3*Global`w^4 + 20*Global`v^4*Global`w^4 - 
           12*FeynCalc`CA^2*Global`v^4*Global`w^4 + 11*Global`v^5*
            Global`w^4 + FeynCalc`CA^2*Global`v^5*Global`w^4 + 
           3*Global`v^6*Global`w^4 - 15*FeynCalc`CA^2*Global`v^6*Global`w^4 + 
           4*Global`v^7*Global`w^4 - 4*FeynCalc`CA^2*Global`v^7*Global`w^4 + 
           6*Global`v^4*Global`w^5 - 2*FeynCalc`CA^2*Global`v^4*Global`w^5 - 
           17*Global`v^5*Global`w^5 + 5*FeynCalc`CA^2*Global`v^5*Global`w^5 - 
           9*Global`v^6*Global`w^5 + 17*FeynCalc`CA^2*Global`v^6*Global`w^5 - 
           8*Global`v^7*Global`w^5 + 8*FeynCalc`CA^2*Global`v^7*Global`w^5 + 
           8*Global`v^6*Global`w^6 - 8*FeynCalc`CA^2*Global`v^6*Global`w^6 + 
           8*Global`v^7*Global`w^6 - 8*FeynCalc`CA^2*Global`v^7*Global`w^6 - 
           4*Global`v^7*Global`w^7 + 4*FeynCalc`CA^2*Global`v^7*Global`w^7)*
          FeynFacet`\[Alpha]s^3)/(FeynCalc`CA^3*System`Pi*Global`s^2*
          (-1 + Global`v)^2*Global`v*Global`w*(-1 + Global`v*Global`w)^3*
          (1 - Global`v + Global`v*Global`w)) + 
       ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(4 - 5*Global`v + 
          2*Global`v^2 - Global`v^3 + 9*Global`v*Global`w - 
          8*Global`v^2*Global`w + 3*Global`v^3*Global`w + 
          6*Global`v^2*Global`w^2 - 4*Global`v^3*Global`w^2 + 
          2*Global`v^3*Global`w^3)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muD2])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*(1 - Global`v + Global`v*Global`w)) + 
       ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v^2)*
         (-1 + Global`w)*FeynFacet`\[Alpha]s^3*System`Log[Global`muFA2])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v*
         Global`w) + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (-1 + FeynCalc`CA^2 - Global`v^2 + FeynCalc`CA^2*Global`v^2 + 
          8*Global`v*Global`w - 6*FeynCalc`CA^2*Global`v*Global`w + 
          Global`v^2*Global`w - FeynCalc`CA^2*Global`v^2*Global`w + 
          3*Global`v^3*Global`w - FeynCalc`CA^2*Global`v^3*Global`w - 
          11*Global`v^2*Global`w^2 + 7*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          9*Global`v^3*Global`w^2 + 5*FeynCalc`CA^2*Global`v^3*Global`w^2 - 
          2*Global`v^4*Global`w^2 + 2*FeynCalc`CA^2*Global`v^4*Global`w^2 + 
          10*Global`v^3*Global`w^3 - 4*FeynCalc`CA^2*Global`v^3*Global`w^3 + 
          7*Global`v^4*Global`w^3 - 7*FeynCalc`CA^2*Global`v^4*Global`w^3 + 
          3*Global`v^5*Global`w^3 - FeynCalc`CA^2*Global`v^5*Global`w^3 - 
          8*Global`v^4*Global`w^4 + 4*FeynCalc`CA^2*Global`v^4*Global`w^4 - 
          5*Global`v^5*Global`w^4 + FeynCalc`CA^2*Global`v^5*Global`w^4 - 
          Global`v^6*Global`w^4 + FeynCalc`CA^2*Global`v^6*Global`w^4 + 
          6*Global`v^5*Global`w^5 - 2*FeynCalc`CA^2*Global`v^5*Global`w^5 + 
          2*Global`v^6*Global`w^5 - 2*FeynCalc`CA^2*Global`v^6*Global`w^5 - 
          2*Global`v^6*Global`w^6 + 2*FeynCalc`CA^2*Global`v^6*Global`w^6)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muFB2])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v*
         Global`w*(-1 + Global`v*Global`w)^3) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-2 + 2*FeynCalc`CA^2 + 
          2*Global`v - 2*FeynCalc`CA^2*Global`v - 2*Global`v^2 + 
          2*FeynCalc`CA^2*Global`v^2 + 2*Global`v^3 - 2*FeynCalc`CA^2*
           Global`v^3 + Global`w - FeynCalc`CA^2*Global`w + 
          12*Global`v*Global`w - 10*FeynCalc`CA^2*Global`v*Global`w - 
          14*Global`v^2*Global`w + 12*FeynCalc`CA^2*Global`v^2*Global`w + 
          4*Global`v^3*Global`w - 2*FeynCalc`CA^2*Global`v^3*Global`w - 
          7*Global`v^4*Global`w + 5*FeynCalc`CA^2*Global`v^4*Global`w - 
          2*Global`v*Global`w^2 + 2*FeynCalc`CA^2*Global`v*Global`w^2 - 
          3*Global`v^2*Global`w^2 + FeynCalc`CA^2*Global`v^2*Global`w^2 + 
          11*Global`v^3*Global`w^2 - 11*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          10*Global`v^4*Global`w^2 - 4*FeynCalc`CA^2*Global`v^4*Global`w^2 + 
          8*Global`v^5*Global`w^2 - 8*FeynCalc`CA^2*Global`v^5*Global`w^2 - 
          15*Global`v^3*Global`w^3 + 17*FeynCalc`CA^2*Global`v^3*Global`w^3 - 
          8*Global`v^4*Global`w^3 - 2*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          14*Global`v^5*Global`w^3 + 16*FeynCalc`CA^2*Global`v^5*Global`w^3 - 
          7*Global`v^6*Global`w^3 + 5*FeynCalc`CA^2*Global`v^6*Global`w^3 + 
          2*Global`v^3*Global`w^4 - 2*FeynCalc`CA^2*Global`v^3*Global`w^4 + 
          11*Global`v^4*Global`w^4 - 9*FeynCalc`CA^2*Global`v^4*Global`w^4 + 
          5*Global`v^5*Global`w^4 - 5*FeynCalc`CA^2*Global`v^5*Global`w^4 + 
          16*Global`v^6*Global`w^4 - 10*FeynCalc`CA^2*Global`v^6*Global`w^4 + 
          2*Global`v^7*Global`w^4 - 2*FeynCalc`CA^2*Global`v^7*Global`w^4 - 
          Global`v^4*Global`w^5 + FeynCalc`CA^2*Global`v^4*Global`w^5 + 
          Global`v^5*Global`w^5 - FeynCalc`CA^2*Global`v^5*Global`w^5 - 
          14*Global`v^6*Global`w^5 + 6*FeynCalc`CA^2*Global`v^6*Global`w^5 - 
          6*Global`v^7*Global`w^5 + 6*FeynCalc`CA^2*Global`v^7*Global`w^5 + 
          4*Global`v^6*Global`w^6 + 8*Global`v^7*Global`w^6 - 
          8*FeynCalc`CA^2*Global`v^7*Global`w^6 - 4*Global`v^7*Global`w^7 + 
          4*FeynCalc`CA^2*Global`v^7*Global`w^7)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`s])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v*Global`w*(-1 + Global`v*Global`w)^3*
         (1 - Global`v + Global`v*Global`w)) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(1 - FeynCalc`CA^2 + 
          Global`v^2 - FeynCalc`CA^2*Global`v^2 - 5*Global`w - 
          2*FeynCalc`CA^2*Global`w + 2*Global`v*Global`w + 
          FeynCalc`CA^2*Global`v*Global`w - 3*Global`v^2*Global`w - 
          2*FeynCalc`CA^2*Global`v^2*Global`w - 2*Global`v^3*Global`w + 
          FeynCalc`CA^2*Global`v^3*Global`w + 2*Global`v*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v*Global`w^2 + 9*Global`v^2*Global`w^2 - 
          5*FeynCalc`CA^2*Global`v^2*Global`w^2 - 2*Global`v^3*Global`w^2 + 
          4*FeynCalc`CA^2*Global`v^3*Global`w^2 + Global`v^4*Global`w^2 - 
          FeynCalc`CA^2*Global`v^4*Global`w^2 - 3*Global`v^2*Global`w^3 + 
          3*FeynCalc`CA^2*Global`v^2*Global`w^3 - 2*FeynCalc`CA^2*Global`v^3*
           Global`w^3 - 3*Global`v^4*Global`w^3 + 3*FeynCalc`CA^2*Global`v^4*
           Global`w^3 + 2*FeynCalc`CA^2*Global`v^3*Global`w^4 + 
          4*Global`v^4*Global`w^4 - 4*FeynCalc`CA^2*Global`v^4*Global`w^4 - 
          2*Global`v^4*Global`w^5 + 2*FeynCalc`CA^2*Global`v^4*Global`w^5)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v*
         (-1 + Global`w)*Global`w*(-1 + Global`v*Global`w)) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-2 + 2*FeynCalc`CA^2 + 
          2*Global`v - 2*FeynCalc`CA^2*Global`v - 2*Global`v^2 + 
          2*FeynCalc`CA^2*Global`v^2 + 2*Global`v^3 - 2*FeynCalc`CA^2*
           Global`v^3 + Global`w - FeynCalc`CA^2*Global`w + 
          44*Global`v*Global`w - 26*FeynCalc`CA^2*Global`v*Global`w - 
          54*Global`v^2*Global`w + 32*FeynCalc`CA^2*Global`v^2*Global`w + 
          20*Global`v^3*Global`w - 10*FeynCalc`CA^2*Global`v^3*Global`w - 
          15*Global`v^4*Global`w + 9*FeynCalc`CA^2*Global`v^4*Global`w - 
          2*Global`v*Global`w^2 + 2*FeynCalc`CA^2*Global`v*Global`w^2 - 
          11*Global`v^2*Global`w^2 + 5*FeynCalc`CA^2*Global`v^2*Global`w^2 + 
          35*Global`v^3*Global`w^2 - 23*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          10*Global`v^4*Global`w^2 - 4*FeynCalc`CA^2*Global`v^4*Global`w^2 + 
          24*Global`v^5*Global`w^2 - 16*FeynCalc`CA^2*Global`v^5*Global`w^2 - 
          71*Global`v^3*Global`w^3 + 45*FeynCalc`CA^2*Global`v^3*Global`w^3 + 
          40*Global`v^4*Global`w^3 - 26*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          62*Global`v^5*Global`w^3 + 40*FeynCalc`CA^2*Global`v^5*Global`w^3 - 
          15*Global`v^6*Global`w^3 + 9*FeynCalc`CA^2*Global`v^6*Global`w^3 + 
          2*Global`v^3*Global`w^4 - 2*FeynCalc`CA^2*Global`v^3*Global`w^4 + 
          19*Global`v^4*Global`w^4 - 13*FeynCalc`CA^2*Global`v^4*Global`w^4 - 
          3*Global`v^5*Global`w^4 - FeynCalc`CA^2*Global`v^5*Global`w^4 + 
          48*Global`v^6*Global`w^4 - 26*FeynCalc`CA^2*Global`v^6*Global`w^4 + 
          2*Global`v^7*Global`w^4 - 2*FeynCalc`CA^2*Global`v^7*Global`w^4 - 
          Global`v^4*Global`w^5 + FeynCalc`CA^2*Global`v^4*Global`w^5 + 
          25*Global`v^5*Global`w^5 - 13*FeynCalc`CA^2*Global`v^5*Global`w^5 - 
          38*Global`v^6*Global`w^5 + 18*FeynCalc`CA^2*Global`v^6*Global`w^5 - 
          6*Global`v^7*Global`w^5 + 6*FeynCalc`CA^2*Global`v^7*Global`w^5 + 
          4*Global`v^6*Global`w^6 + 8*Global`v^7*Global`w^6 - 
          8*FeynCalc`CA^2*Global`v^7*Global`w^6 - 4*Global`v^7*Global`w^7 + 
          4*FeynCalc`CA^2*Global`v^7*Global`w^7)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`v])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v*Global`w*(-1 + Global`v*Global`w)^3*
         (1 - Global`v + Global`v*Global`w)) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-2 + 2*FeynCalc`CA^2 + 
          2*Global`v - 2*FeynCalc`CA^2*Global`v - 2*Global`v^2 + 
          2*FeynCalc`CA^2*Global`v^2 + 2*Global`v^3 - 2*FeynCalc`CA^2*
           Global`v^3 + Global`w - FeynCalc`CA^2*Global`w + 
          24*Global`v*Global`w - 18*FeynCalc`CA^2*Global`v*Global`w - 
          34*Global`v^2*Global`w + 22*FeynCalc`CA^2*Global`v^2*Global`w + 
          12*Global`v^3*Global`w - 6*FeynCalc`CA^2*Global`v^3*Global`w - 
          7*Global`v^4*Global`w + 7*FeynCalc`CA^2*Global`v^4*Global`w - 
          2*Global`v*Global`w^2 + 2*FeynCalc`CA^2*Global`v*Global`w^2 - 
          7*Global`v^2*Global`w^2 + 3*FeynCalc`CA^2*Global`v^2*Global`w^2 + 
          27*Global`v^3*Global`w^2 - 17*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          2*Global`v^4*Global`w^2 - 4*FeynCalc`CA^2*Global`v^4*Global`w^2 + 
          8*Global`v^5*Global`w^2 - 12*FeynCalc`CA^2*Global`v^5*Global`w^2 - 
          39*Global`v^3*Global`w^3 + 31*FeynCalc`CA^2*Global`v^3*Global`w^3 + 
          16*Global`v^4*Global`w^3 - 14*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          22*Global`v^5*Global`w^3 + 28*FeynCalc`CA^2*Global`v^5*Global`w^3 - 
          7*Global`v^6*Global`w^3 + 7*FeynCalc`CA^2*Global`v^6*Global`w^3 + 
          2*Global`v^3*Global`w^4 - 2*FeynCalc`CA^2*Global`v^3*Global`w^4 + 
          19*Global`v^4*Global`w^4 - 11*FeynCalc`CA^2*Global`v^4*Global`w^4 - 
          11*Global`v^5*Global`w^4 - 3*FeynCalc`CA^2*Global`v^5*Global`w^4 + 
          24*Global`v^6*Global`w^4 - 18*FeynCalc`CA^2*Global`v^6*Global`w^4 + 
          2*Global`v^7*Global`w^4 - 2*FeynCalc`CA^2*Global`v^7*Global`w^4 - 
          Global`v^4*Global`w^5 + FeynCalc`CA^2*Global`v^4*Global`w^5 + 
          13*Global`v^5*Global`w^5 - 7*FeynCalc`CA^2*Global`v^5*Global`w^5 - 
          18*Global`v^6*Global`w^5 + 12*FeynCalc`CA^2*Global`v^6*Global`w^5 - 
          6*Global`v^7*Global`w^5 + 6*FeynCalc`CA^2*Global`v^7*Global`w^5 + 
          8*Global`v^7*Global`w^6 - 8*FeynCalc`CA^2*Global`v^7*Global`w^6 - 
          4*Global`v^7*Global`w^7 + 4*FeynCalc`CA^2*Global`v^7*Global`w^7)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`w])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v*
         Global`w*(-1 + Global`v*Global`w)^3*(1 - Global`v + 
          Global`v*Global`w)) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (1 - FeynCalc`CA^2 + Global`v^2 - FeynCalc`CA^2*Global`v^2 + 
          5*Global`w - 2*FeynCalc`CA^2*Global`w - 11*Global`v*Global`w + 
          5*FeynCalc`CA^2*Global`v*Global`w + 7*Global`v^2*Global`w - 
          3*FeynCalc`CA^2*Global`v^2*Global`w - 5*Global`v^3*Global`w + 
          2*FeynCalc`CA^2*Global`v^3*Global`w + 5*Global`v*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v*Global`w^2 - 6*Global`v^2*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v^2*Global`w^2 + 5*Global`v^3*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v^3*Global`w^2 + 8*Global`v^2*Global`w^3 - 
          3*FeynCalc`CA^2*Global`v^2*Global`w^3 - 12*Global`v^3*Global`w^3 + 
          5*FeynCalc`CA^2*Global`v^3*Global`w^3 + 2*Global`v^3*Global`w^4)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`w])/(4*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v*(-1 + Global`w)*
         Global`w*(-1 + Global`v*Global`w)) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-1 + FeynCalc`CA^2 - 
          Global`v^2 + FeynCalc`CA^2*Global`v^2 + 5*Global`w + 
          2*FeynCalc`CA^2*Global`w - Global`v*Global`w - 
          4*FeynCalc`CA^2*Global`v*Global`w - Global`v^2*Global`w + 
          3*FeynCalc`CA^2*Global`v^2*Global`w + Global`v^3*Global`w - 
          FeynCalc`CA^2*Global`v^3*Global`w + Global`v*Global`w^2 + 
          4*FeynCalc`CA^2*Global`v*Global`w^2 - 2*Global`v^2*Global`w^2 - 
          3*FeynCalc`CA^2*Global`v^2*Global`w^2 - 3*Global`v^3*Global`w^2 + 
          3*FeynCalc`CA^2*Global`v^3*Global`w^2 + 4*FeynCalc`CA^2*Global`v^2*
           Global`w^3 + 4*Global`v^3*Global`w^3 - 4*FeynCalc`CA^2*Global`v^3*
           Global`w^3 - 2*Global`v^3*Global`w^4 + 2*FeynCalc`CA^2*Global`v^3*
           Global`w^4)*FeynFacet`\[Alpha]s^3*System`Log[
          1 - Global`v*Global`w])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v*(-1 + Global`w)*Global`w) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-2 + Global`v + Global`v^2 - 
          3*Global`v*Global`w + Global`v^2*Global`w - FeynCalc`CA^2*
           Global`v^2*Global`w - 2*Global`v^2*Global`w^2 + 
          FeynCalc`CA^2*Global`v^2*Global`w^2)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v + Global`v*Global`w])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v*
         (-1 + Global`w)*(1 - Global`v + Global`v*Global`w))|>|>, 
 "DensityConvention" -> "E_c d sigma/d^(D-1)p_c", 
 "DistributionBasis" -> <|"Variable" -> Global`w, "Endpoint" -> 1, 
   "Interval" -> {0, 1}, "Distance" -> 1 - Global`w|>, 
 "PlusConvention" -> "At each axis, PlusCoefficients[k] multiplies \
[Log[Distance]^k/Distance]_+ on Interval, with subtraction at Endpoint. For \
DistributionBasis[Axes], delta/plus/regular values repeat recursively in the \
listed axis order."|>
