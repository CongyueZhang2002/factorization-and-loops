<|"Project" -> "ppHX_LL_NLO", "Channel" -> "qg-qg", "Scale" -> Global`s, 
 "Variables" -> {Global`v, Global`w}, "Coupling" -> FeynFacet`\[Alpha]s, 
 "CouplingPower" -> 3, "DimensionalPrefactor" -> 
  Global`muR2^(2*Global`Epsilon), "PhysicalChannel" -> 
  <|"Incoming" -> {{"q", "u"}, "g"}, "Observed" -> {"q", "u"}, 
   "Recoil" -> "g"|>, "Polarization" -> <|"Incoming" -> {"L", "L"}, 
   "Observed" -> "U"|>, "Order" -> "NLO", "Contribution" -> "Total", 
 "DimensionalRegulator" -> Global`Epsilon, "PoleCancellation" -> 
  "Exact symbolic zero in every delta, plus and regular coefficient", 
 "Contributions" -> {"Real", "Virtual", "Counterterm"}, 
 "Domain" -> Global`s > 0 && 0 < Global`v < 1 && 0 < Global`w < 1 && 
   Global`muR2 > 0 && Global`muFA2 > 0 && Global`muFB2 > 0 && 
   Global`muD2 > 0, "Description" -> 
  <|"Channel" -> "q qprime -> observed q + X", 
   "Polarization" -> <|"Incoming" -> {"L", "L"}, "Observed" -> "U"|>, 
   "Fragmentation" -> "D1", "Coupling" -> 
    "Physical alpha_s powers included"|>, 
 "Format" -> "FeynFacet-PartonicResult", "FormatVersion" -> 1, 
 "EpsilonRange" -> {0, 0}, "LaurentLowerBound" -> 0, 
 "Coefficients" -> 
  <|0 -> <|"DeltaCoefficient" -> 
      -1/72*((-63 + 59*FeynCalc`CA^2 + 4*FeynCalc`CA^4 + 10*FeynCalc`CA*
            Global`nD - 10*FeynCalc`CA^3*Global`nD + 10*FeynCalc`CA*
            Global`nU - 10*FeynCalc`CA^3*Global`nU + 9*System`Pi^2 - 
           12*FeynCalc`CA^2*System`Pi^2 + 3*FeynCalc`CA^4*System`Pi^2 + 
           63*Global`v + 76*FeynCalc`CA^2*Global`v + 13*FeynCalc`CA^4*
            Global`v - 10*FeynCalc`CA*Global`nD*Global`v - 
           10*FeynCalc`CA^3*Global`nD*Global`v - 10*FeynCalc`CA*Global`nU*
            Global`v - 10*FeynCalc`CA^3*Global`nU*Global`v - 
           27*System`Pi^2*Global`v + 3*FeynCalc`CA^2*System`Pi^2*Global`v + 
           3*FeynCalc`CA^4*System`Pi^2*Global`v + 63*Global`v^2 + 
           76*FeynCalc`CA^2*Global`v^2 + 13*FeynCalc`CA^4*Global`v^2 - 
           10*FeynCalc`CA*Global`nD*Global`v^2 - 10*FeynCalc`CA^3*Global`nD*
            Global`v^2 - 10*FeynCalc`CA*Global`nU*Global`v^2 - 
           10*FeynCalc`CA^3*Global`nU*Global`v^2 + 18*System`Pi^2*
            Global`v^2 + 30*FeynCalc`CA^2*System`Pi^2*Global`v^2 + 
           12*FeynCalc`CA^4*System`Pi^2*Global`v^2 - 63*Global`v^3 + 
           59*FeynCalc`CA^2*Global`v^3 + 4*FeynCalc`CA^4*Global`v^3 + 
           10*FeynCalc`CA*Global`nD*Global`v^3 - 10*FeynCalc`CA^3*Global`nD*
            Global`v^3 + 10*FeynCalc`CA*Global`nU*Global`v^3 - 
           10*FeynCalc`CA^3*Global`nU*Global`v^3 - 12*FeynCalc`CA^2*
            System`Pi^2*Global`v^3 + 12*FeynCalc`CA^4*System`Pi^2*Global`v^3)*
          FeynFacet`\[Alpha]s^3)/(FeynCalc`CA^3*System`Pi*Global`s^2*
          (-1 + Global`v)*Global`v^2) + (3*(-1 + FeynCalc`CA)*
         (1 + FeynCalc`CA)*(1 + Global`v)*(-1 + FeynCalc`CA^2 + 2*Global`v - 
          Global`v^2 + FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muFA2])/(16*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2) - 
       ((11*FeynCalc`CA - 2*Global`nD - 2*Global`nU)*(1 + Global`v)*
         (-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
          FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muR2])/(12*FeynCalc`CA^2*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2) + 
       ((9 + 2*FeynCalc`CA^2 - 2*FeynCalc`CA*Global`nD - 
          2*FeynCalc`CA*Global`nU)*(1 + Global`v)*(-1 + FeynCalc`CA^2 + 
          2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(24*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) - 
       ((1 + Global`v)*(1 - 2*FeynCalc`CA^2 + FeynCalc`CA^4 - 2*Global`v + 
          5*FeynCalc`CA^2*Global`v + Global`v^2 - 2*FeynCalc`CA^2*
           Global`v^2 + FeynCalc`CA^4*Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v]^2)/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2) + 
       (((-9 + 7*FeynCalc`CA^2 + 2*FeynCalc`CA^4 + 2*FeynCalc`CA*Global`nD - 
            2*FeynCalc`CA^3*Global`nD + 2*FeynCalc`CA*Global`nU - 
            2*FeynCalc`CA^3*Global`nU + 15*Global`v + 2*FeynCalc`CA^2*
             Global`v + 5*FeynCalc`CA^4*Global`v - 2*FeynCalc`CA*Global`nD*
             Global`v - 2*FeynCalc`CA^3*Global`nD*Global`v - 
            2*FeynCalc`CA*Global`nU*Global`v - 2*FeynCalc`CA^3*Global`nU*
             Global`v - 6*Global`v^2 + 5*FeynCalc`CA^2*Global`v^2 + 
            11*FeynCalc`CA^4*Global`v^2 - 2*FeynCalc`CA*Global`nD*
             Global`v^2 - 2*FeynCalc`CA^3*Global`nD*Global`v^2 - 
            2*FeynCalc`CA*Global`nU*Global`v^2 - 2*FeynCalc`CA^3*Global`nU*
             Global`v^2 - 11*FeynCalc`CA^2*Global`v^3 + 11*FeynCalc`CA^4*
             Global`v^3 + 2*FeynCalc`CA*Global`nD*Global`v^3 - 
            2*FeynCalc`CA^3*Global`nD*Global`v^3 + 2*FeynCalc`CA*Global`nU*
             Global`v^3 - 2*FeynCalc`CA^3*Global`nU*Global`v^3)*
           FeynFacet`\[Alpha]s^3)/(24*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2) - ((-1 + 3*FeynCalc`CA^2)*
           (1 + Global`v)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2))*System`Log[Global`v] - 
       ((2 - 12*FeynCalc`CA^2 + 10*FeynCalc`CA^4 - 4*Global`v + 
          9*FeynCalc`CA^2*Global`v + 10*FeynCalc`CA^4*Global`v + Global`v^2 + 
          12*FeynCalc`CA^2*Global`v^2 + 3*FeynCalc`CA^4*Global`v^2 + 
          Global`v^3 - 12*FeynCalc`CA^2*Global`v^3 + 3*FeynCalc`CA^4*
           Global`v^3)*FeynFacet`\[Alpha]s^3*System`Log[Global`v]^2)/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) + 
       System`Log[Global`muFB2]*(((11*FeynCalc`CA - 2*Global`nD - 
            2*Global`nU)*(1 + Global`v)*(-1 + FeynCalc`CA^2 + 2*Global`v - 
            Global`v^2 + FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
          (24*FeynCalc`CA^2*System`Pi*Global`s^2*(-1 + Global`v)*
           Global`v^2) - ((1 + Global`v)*(-1 + FeynCalc`CA^2 + 2*Global`v - 
            Global`v^2 + FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[1 - Global`v])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2) + ((1 + Global`v)*
           (-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2)) + System`Log[Global`muD2]*
        ((3*(-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(1 + Global`v)*
           (-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
          (16*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*
           Global`v^2) + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(1 + Global`v)*
           (-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2)) + System`Log[1 - Global`v]*
        (-1/8*((-5 + FeynCalc`CA^2)*(1 + Global`v)*FeynFacet`\[Alpha]s^3)/
           (FeynCalc`CA*System`Pi*Global`s^2*(-1 + Global`v)*Global`v) + 
         ((1 + Global`v)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2) + 
         ((-4*FeynCalc`CA^2 + 4*FeynCalc`CA^4 - 2*Global`v + 
            5*FeynCalc`CA^2*Global`v + 4*FeynCalc`CA^4*Global`v + 
            3*Global`v^2 + 8*FeynCalc`CA^2*Global`v^2 + FeynCalc`CA^4*
             Global`v^2 - Global`v^3 - 4*FeynCalc`CA^2*Global`v^3 + 
            FeynCalc`CA^4*Global`v^3)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2)), "PlusCoefficients" -> 
      <|0 -> ((11*FeynCalc`CA - 2*Global`nD - 2*Global`nU)*(1 + Global`v)*
           (-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
          (24*FeynCalc`CA^2*System`Pi*Global`s^2*(-1 + Global`v)*
           Global`v^2) + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(1 + Global`v)*
           (-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muD2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2) + ((-1 + FeynCalc`CA)*
           (1 + FeynCalc`CA)*(1 + Global`v)*(-1 + FeynCalc`CA^2 + 
            2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`muFA2])/
          (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) + 
         ((1 + Global`v)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFB2])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2) - ((-1 + 2*FeynCalc`CA^2)*
           (1 + Global`v)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s])/(2*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2) + ((1 + Global`v)*
           (-1 - 2*FeynCalc`CA^2 + FeynCalc`CA^4 + 2*Global`v + 
            6*FeynCalc`CA^2*Global`v - Global`v^2 - 2*FeynCalc`CA^2*
             Global`v^2 + FeynCalc`CA^4*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[1 - Global`v])/(2*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2) - ((1 + Global`v)*
           (1 - 5*FeynCalc`CA^2 + 4*FeynCalc`CA^4 - 2*Global`v + 
            8*FeynCalc`CA^2*Global`v + Global`v^2 - 5*FeynCalc`CA^2*
             Global`v^2 + 2*FeynCalc`CA^4*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(2*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2), 
       1 -> -1/2*((-2 + 3*FeynCalc`CA^2)*(1 + Global`v)*(-1 + FeynCalc`CA^2 + 
            2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3)/(FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2)|>, "RegularCoefficient" -> 
      -1/24*((9 - 9*FeynCalc`CA - 7*FeynCalc`CA^2 + 9*FeynCalc`CA^3 - 
           2*FeynCalc`CA^4 - 2*FeynCalc`CA*Global`nD + 2*FeynCalc`CA^3*
            Global`nD - 2*FeynCalc`CA*Global`nU + 2*FeynCalc`CA^3*Global`nU - 
           39*Global`v + 39*FeynCalc`CA*Global`v + 17*FeynCalc`CA^2*
            Global`v - 51*FeynCalc`CA^3*Global`v + 22*FeynCalc`CA^4*
            Global`v + 10*FeynCalc`CA*Global`nD*Global`v - 
           10*FeynCalc`CA^3*Global`nD*Global`v + 10*FeynCalc`CA*Global`nU*
            Global`v - 10*FeynCalc`CA^3*Global`nU*Global`v + 75*Global`v^2 - 
           81*FeynCalc`CA*Global`v^2 - 9*FeynCalc`CA^2*Global`v^2 + 
           165*FeynCalc`CA^3*Global`v^2 - 66*FeynCalc`CA^4*Global`v^2 - 
           18*FeynCalc`CA*Global`nD*Global`v^2 + 18*FeynCalc`CA^3*Global`nD*
            Global`v^2 - 18*FeynCalc`CA*Global`nU*Global`v^2 + 
           18*FeynCalc`CA^3*Global`nU*Global`v^2 - 69*Global`v^3 + 
           81*FeynCalc`CA*Global`v^3 - 5*FeynCalc`CA^2*Global`v^3 - 
           309*FeynCalc`CA^3*Global`v^3 + 74*FeynCalc`CA^4*Global`v^3 + 
           14*FeynCalc`CA*Global`nD*Global`v^3 - 14*FeynCalc`CA^3*Global`nD*
            Global`v^3 + 14*FeynCalc`CA*Global`nU*Global`v^3 - 
           14*FeynCalc`CA^3*Global`nU*Global`v^3 + 24*Global`v^4 - 
           30*FeynCalc`CA*Global`v^4 + 4*FeynCalc`CA^2*Global`v^4 + 
           330*FeynCalc`CA^3*Global`v^4 - 28*FeynCalc`CA^4*Global`v^4 - 
           4*FeynCalc`CA*Global`nD*Global`v^4 + 4*FeynCalc`CA^3*Global`nD*
            Global`v^4 - 4*FeynCalc`CA*Global`nU*Global`v^4 + 
           4*FeynCalc`CA^3*Global`nU*Global`v^4 - 192*FeynCalc`CA^3*
            Global`v^5 + 48*FeynCalc`CA^3*Global`v^6 + 12*FeynCalc`CA*
            Global`w - 6*FeynCalc`CA^2*Global`w - 12*FeynCalc`CA^3*Global`w + 
           6*FeynCalc`CA^4*Global`w - 9*Global`v*Global`w - 
           57*FeynCalc`CA*Global`v*Global`w + 9*FeynCalc`CA^2*Global`v*
            Global`w + 63*FeynCalc`CA^3*Global`v*Global`w - 
           12*FeynCalc`CA^4*Global`v*Global`w + 12*Global`v^2*Global`w + 
           90*FeynCalc`CA*Global`v^2*Global`w + 17*FeynCalc`CA^2*Global`v^2*
            Global`w - 162*FeynCalc`CA^3*Global`v^2*Global`w + 
           95*FeynCalc`CA^4*Global`v^2*Global`w + 4*FeynCalc`CA*Global`nD*
            Global`v^2*Global`w - 26*FeynCalc`CA^3*Global`nD*Global`v^2*
            Global`w + 4*FeynCalc`CA*Global`nU*Global`v^2*Global`w - 
           26*FeynCalc`CA^3*Global`nU*Global`v^2*Global`w + 
           15*Global`v^3*Global`w - 39*FeynCalc`CA*Global`v^3*Global`w - 
           88*FeynCalc`CA^2*Global`v^3*Global`w + 249*FeynCalc`CA^3*
            Global`v^3*Global`w - 277*FeynCalc`CA^4*Global`v^3*Global`w - 
           26*FeynCalc`CA*Global`nD*Global`v^3*Global`w + 88*FeynCalc`CA^3*
            Global`nD*Global`v^3*Global`w - 26*FeynCalc`CA*Global`nU*
            Global`v^3*Global`w + 88*FeynCalc`CA^3*Global`nU*Global`v^3*
            Global`w - 6*Global`v^4*Global`w - 60*FeynCalc`CA*Global`v^4*
            Global`w + 119*FeynCalc`CA^2*Global`v^4*Global`w - 
           132*FeynCalc`CA^3*Global`v^4*Global`w + 263*FeynCalc`CA^4*
            Global`v^4*Global`w + 40*FeynCalc`CA*Global`nD*Global`v^4*
            Global`w - 98*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w + 
           40*FeynCalc`CA*Global`nU*Global`v^4*Global`w - 98*FeynCalc`CA^3*
            Global`nU*Global`v^4*Global`w - 12*Global`v^5*Global`w + 
           54*FeynCalc`CA*Global`v^5*Global`w - 51*FeynCalc`CA^2*Global`v^5*
            Global`w - 138*FeynCalc`CA^3*Global`v^5*Global`w - 
           75*FeynCalc`CA^4*Global`v^5*Global`w - 18*FeynCalc`CA*Global`nD*
            Global`v^5*Global`w + 36*FeynCalc`CA^3*Global`nD*Global`v^5*
            Global`w - 18*FeynCalc`CA*Global`nU*Global`v^5*Global`w + 
           36*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w + 
           228*FeynCalc`CA^3*Global`v^6*Global`w - 96*FeynCalc`CA^3*
            Global`v^7*Global`w - 18*Global`v^2*Global`w^2 + 
           42*FeynCalc`CA*Global`v^2*Global`w^2 + 2*FeynCalc`CA^2*Global`v^2*
            Global`w^2 - 42*FeynCalc`CA^3*Global`v^2*Global`w^2 + 
           16*FeynCalc`CA^4*Global`v^2*Global`w^2 + 4*FeynCalc`CA*Global`nD*
            Global`v^2*Global`w^2 - 4*FeynCalc`CA^3*Global`nD*Global`v^2*
            Global`w^2 + 4*FeynCalc`CA*Global`nU*Global`v^2*Global`w^2 - 
           4*FeynCalc`CA^3*Global`nU*Global`v^2*Global`w^2 + 
           36*Global`v^3*Global`w^2 - 132*FeynCalc`CA*Global`v^3*Global`w^2 + 
           55*FeynCalc`CA^2*Global`v^3*Global`w^2 + 162*FeynCalc`CA^3*
            Global`v^3*Global`w^2 + 191*FeynCalc`CA^4*Global`v^3*Global`w^2 + 
           20*FeynCalc`CA*Global`nD*Global`v^3*Global`w^2 - 
           74*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^2 + 
           20*FeynCalc`CA*Global`nU*Global`v^3*Global`w^2 - 
           74*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^2 - 
           54*Global`v^4*Global`w^2 + 180*FeynCalc`CA*Global`v^4*Global`w^2 - 
           184*FeynCalc`CA^2*Global`v^4*Global`w^2 - 426*FeynCalc`CA^3*
            Global`v^4*Global`w^2 - 552*FeynCalc`CA^4*Global`v^4*Global`w^2 - 
           110*FeynCalc`CA*Global`nD*Global`v^4*Global`w^2 + 
           228*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^2 - 
           110*FeynCalc`CA*Global`nU*Global`v^4*Global`w^2 + 
           228*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^2 + 
           60*Global`v^5*Global`w^2 - 66*FeynCalc`CA*Global`v^5*Global`w^2 + 
           145*FeynCalc`CA^2*Global`v^5*Global`w^2 + 666*FeynCalc`CA^3*
            Global`v^5*Global`w^2 + 441*FeynCalc`CA^4*Global`v^5*Global`w^2 + 
           110*FeynCalc`CA*Global`nD*Global`v^5*Global`w^2 - 
           192*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^2 + 
           110*FeynCalc`CA*Global`nU*Global`v^5*Global`w^2 - 
           192*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^2 - 
           12*Global`v^6*Global`w^2 - 42*FeynCalc`CA*Global`v^6*Global`w^2 - 
           18*FeynCalc`CA^2*Global`v^6*Global`w^2 - 510*FeynCalc`CA^3*
            Global`v^6*Global`w^2 - 108*FeynCalc`CA^4*Global`v^6*Global`w^2 - 
           24*FeynCalc`CA*Global`nD*Global`v^6*Global`w^2 + 
           42*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^2 - 
           24*FeynCalc`CA*Global`nU*Global`v^6*Global`w^2 + 
           42*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^2 + 
           120*FeynCalc`CA^3*Global`v^7*Global`w^2 + 48*FeynCalc`CA^3*
            Global`v^8*Global`w^2 - 24*FeynCalc`CA*Global`v^2*Global`w^3 + 
           12*FeynCalc`CA^2*Global`v^2*Global`w^3 + 24*FeynCalc`CA^3*
            Global`v^2*Global`w^3 - 12*FeynCalc`CA^4*Global`v^2*Global`w^3 + 
           18*Global`v^3*Global`w^3 + 90*FeynCalc`CA*Global`v^3*Global`w^3 - 
           6*FeynCalc`CA^2*Global`v^3*Global`w^3 - 102*FeynCalc`CA^3*
            Global`v^3*Global`w^3 + 12*FeynCalc`CA^4*Global`v^3*Global`w^3 - 
           42*Global`v^4*Global`w^3 - 96*FeynCalc`CA*Global`v^4*Global`w^3 + 
           117*FeynCalc`CA^2*Global`v^4*Global`w^3 + 222*FeynCalc`CA^3*
            Global`v^4*Global`w^3 + 259*FeynCalc`CA^4*Global`v^4*Global`w^3 + 
           72*FeynCalc`CA*Global`nD*Global`v^4*Global`w^3 - 
           118*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^3 + 
           72*FeynCalc`CA*Global`nU*Global`v^4*Global`w^3 - 
           118*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^3 + 
           42*Global`v^5*Global`w^3 - 12*FeynCalc`CA*Global`v^5*Global`w^3 - 
           233*FeynCalc`CA^2*Global`v^5*Global`w^3 - 306*FeynCalc`CA^3*
            Global`v^5*Global`w^3 - 563*FeynCalc`CA^4*Global`v^5*Global`w^3 - 
           160*FeynCalc`CA*Global`nD*Global`v^5*Global`w^3 + 
           242*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^3 - 
           160*FeynCalc`CA*Global`nU*Global`v^5*Global`w^3 + 
           242*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^3 - 
           54*Global`v^6*Global`w^3 + 54*FeynCalc`CA*Global`v^6*Global`w^3 + 
           105*FeynCalc`CA^2*Global`v^6*Global`w^3 + 150*FeynCalc`CA^3*
            Global`v^6*Global`w^3 + 307*FeynCalc`CA^4*Global`v^6*Global`w^3 + 
           72*FeynCalc`CA*Global`nD*Global`v^6*Global`w^3 - 
           112*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^3 + 
           72*FeynCalc`CA*Global`nU*Global`v^6*Global`w^3 - 
           112*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^3 + 
           24*Global`v^7*Global`w^3 + 42*FeynCalc`CA*Global`v^7*Global`w^3 - 
           7*FeynCalc`CA^2*Global`v^7*Global`w^3 + 114*FeynCalc`CA^3*
            Global`v^7*Global`w^3 - 17*FeynCalc`CA^4*Global`v^7*Global`w^3 - 
           2*FeynCalc`CA*Global`nD*Global`v^7*Global`w^3 + 
           2*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^3 - 
           2*FeynCalc`CA*Global`nU*Global`v^7*Global`w^3 + 
           2*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^3 - 
           156*FeynCalc`CA^3*Global`v^8*Global`w^3 + 9*Global`v^4*
            Global`w^4 - 33*FeynCalc`CA*Global`v^4*Global`w^4 + 
           5*FeynCalc`CA^2*Global`v^4*Global`w^4 + 33*FeynCalc`CA^3*
            Global`v^4*Global`w^4 - 14*FeynCalc`CA^4*Global`v^4*Global`w^4 - 
           2*FeynCalc`CA*Global`nD*Global`v^4*Global`w^4 + 
           2*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^4 - 
           2*FeynCalc`CA*Global`nU*Global`v^4*Global`w^4 + 
           2*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^4 - 
           33*Global`v^5*Global`w^4 + 75*FeynCalc`CA*Global`v^5*Global`w^4 + 
           72*FeynCalc`CA^2*Global`v^5*Global`w^4 - 81*FeynCalc`CA^3*
            Global`v^5*Global`w^4 + 231*FeynCalc`CA^4*Global`v^5*Global`w^4 + 
           66*FeynCalc`CA*Global`nD*Global`v^5*Global`w^4 - 
           84*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^4 + 
           66*FeynCalc`CA*Global`nU*Global`v^5*Global`w^4 - 
           84*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^4 + 
           75*Global`v^6*Global`w^4 - 15*FeynCalc`CA*Global`v^6*Global`w^4 - 
           73*FeynCalc`CA^2*Global`v^6*Global`w^4 + 141*FeynCalc`CA^3*
            Global`v^6*Global`w^4 - 316*FeynCalc`CA^4*Global`v^6*Global`w^4 - 
           68*FeynCalc`CA*Global`nD*Global`v^6*Global`w^4 + 
           94*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^4 - 
           68*FeynCalc`CA*Global`nU*Global`v^6*Global`w^4 + 
           94*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^4 - 
           51*Global`v^7*Global`w^4 - 75*FeynCalc`CA*Global`v^7*Global`w^4 - 
           4*FeynCalc`CA^2*Global`v^7*Global`w^4 - 225*FeynCalc`CA^3*
            Global`v^7*Global`w^4 + 55*FeynCalc`CA^4*Global`v^7*Global`w^4 + 
           4*FeynCalc`CA*Global`nD*Global`v^7*Global`w^4 - 
           4*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^4 + 
           4*FeynCalc`CA*Global`nU*Global`v^7*Global`w^4 - 
           4*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^4 - 
           24*FeynCalc`CA*Global`v^8*Global`w^4 + 204*FeynCalc`CA^3*
            Global`v^8*Global`w^4 + 12*FeynCalc`CA*Global`v^4*Global`w^5 - 
           6*FeynCalc`CA^2*Global`v^4*Global`w^5 - 12*FeynCalc`CA^3*
            Global`v^4*Global`w^5 + 6*FeynCalc`CA^4*Global`v^4*Global`w^5 - 
           9*Global`v^5*Global`w^5 - 33*FeynCalc`CA*Global`v^5*Global`w^5 - 
           3*FeynCalc`CA^2*Global`v^5*Global`w^5 + 39*FeynCalc`CA^3*
            Global`v^5*Global`w^5 - 18*Global`v^6*Global`w^5 + 
           10*FeynCalc`CA^2*Global`v^6*Global`w^5 - 54*FeynCalc`CA^3*
            Global`v^6*Global`w^5 + 102*FeynCalc`CA^4*Global`v^6*Global`w^5 + 
           20*FeynCalc`CA*Global`nD*Global`v^6*Global`w^5 - 
           24*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^5 + 
           20*FeynCalc`CA*Global`nU*Global`v^6*Global`w^5 - 
           24*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^5 + 
           39*Global`v^7*Global`w^5 + 27*FeynCalc`CA*Global`v^7*Global`w^5 + 
           11*FeynCalc`CA^2*Global`v^7*Global`w^5 + 105*FeynCalc`CA^3*
            Global`v^7*Global`w^5 - 50*FeynCalc`CA^4*Global`v^7*Global`w^5 - 
           2*FeynCalc`CA*Global`nD*Global`v^7*Global`w^5 + 
           2*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^5 - 
           2*FeynCalc`CA*Global`nU*Global`v^7*Global`w^5 + 
           2*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^5 + 
           66*FeynCalc`CA*Global`v^8*Global`w^5 - 150*FeynCalc`CA^3*
            Global`v^8*Global`w^5 - 12*Global`v^7*Global`w^6 + 
           6*FeynCalc`CA*Global`v^7*Global`w^6 - 18*FeynCalc`CA^3*Global`v^7*
            Global`w^6 + 12*FeynCalc`CA^4*Global`v^7*Global`w^6 - 
           60*FeynCalc`CA*Global`v^8*Global`w^6 + 72*FeynCalc`CA^3*Global`v^8*
            Global`w^6 + 18*FeynCalc`CA*Global`v^8*Global`w^7 - 
           18*FeynCalc`CA^3*Global`v^8*Global`w^7)*FeynFacet`\[Alpha]s^3)/
         (FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*
          Global`w*(-1 + Global`v*Global`w)^2*
          (1 - Global`v + Global`v*Global`w)^2) - 
       ((-2 + 4*FeynCalc`CA^2 - 2*FeynCalc`CA^4 + 8*Global`v - 
          16*FeynCalc`CA^2*Global`v - 4*FeynCalc`CA^3*Global`v + 
          8*FeynCalc`CA^4*Global`v - 13*Global`v^2 + 26*FeynCalc`CA^2*
           Global`v^2 + 20*FeynCalc`CA^3*Global`v^2 - 13*FeynCalc`CA^4*
           Global`v^2 + 11*Global`v^3 - 22*FeynCalc`CA^2*Global`v^3 - 
          44*FeynCalc`CA^3*Global`v^3 + 11*FeynCalc`CA^4*Global`v^3 - 
          5*Global`v^4 + 10*FeynCalc`CA^2*Global`v^4 + 52*FeynCalc`CA^3*
           Global`v^4 - 5*FeynCalc`CA^4*Global`v^4 + Global`v^5 - 
          2*FeynCalc`CA^2*Global`v^5 - 32*FeynCalc`CA^3*Global`v^5 + 
          FeynCalc`CA^4*Global`v^5 + 8*FeynCalc`CA^3*Global`v^6 - 
          4*Global`v*Global`w + 8*FeynCalc`CA^2*Global`v*Global`w - 
          4*FeynCalc`CA^4*Global`v*Global`w + 11*Global`v^2*Global`w - 
          30*FeynCalc`CA^2*Global`v^2*Global`w - 14*FeynCalc`CA^3*Global`v^2*
           Global`w + 19*FeynCalc`CA^4*Global`v^2*Global`w - 
          11*Global`v^3*Global`w + 40*FeynCalc`CA^2*Global`v^3*Global`w + 
          64*FeynCalc`CA^3*Global`v^3*Global`w - 29*FeynCalc`CA^4*Global`v^3*
           Global`w + 5*Global`v^4*Global`w - 22*FeynCalc`CA^2*Global`v^4*
           Global`w - 114*FeynCalc`CA^3*Global`v^4*Global`w + 
          17*FeynCalc`CA^4*Global`v^4*Global`w - Global`v^5*Global`w + 
          4*FeynCalc`CA^2*Global`v^5*Global`w + 92*FeynCalc`CA^3*Global`v^5*
           Global`w - 3*FeynCalc`CA^4*Global`v^5*Global`w - 
          28*FeynCalc`CA^3*Global`v^6*Global`w - 2*Global`v^2*Global`w^2 + 
          4*FeynCalc`CA^2*Global`v^2*Global`w^2 - 2*FeynCalc`CA^4*Global`v^2*
           Global`w^2 + 4*Global`v^3*Global`w^2 + 2*FeynCalc`CA*Global`v^3*
           Global`w^2 - 26*FeynCalc`CA^2*Global`v^3*Global`w^2 - 
          24*FeynCalc`CA^3*Global`v^3*Global`w^2 + 22*FeynCalc`CA^4*
           Global`v^3*Global`w^2 - 2*Global`v^4*Global`w^2 - 
          6*FeynCalc`CA*Global`v^4*Global`w^2 + 30*FeynCalc`CA^2*Global`v^4*
           Global`w^2 + 84*FeynCalc`CA^3*Global`v^4*Global`w^2 - 
          28*FeynCalc`CA^4*Global`v^4*Global`w^2 + 8*FeynCalc`CA*Global`v^5*
           Global`w^2 - 8*FeynCalc`CA^2*Global`v^5*Global`w^2 - 
          100*FeynCalc`CA^3*Global`v^5*Global`w^2 + 8*FeynCalc`CA^4*
           Global`v^5*Global`w^2 - 4*FeynCalc`CA*Global`v^6*Global`w^2 + 
          40*FeynCalc`CA^3*Global`v^6*Global`w^2 + 5*FeynCalc`CA*Global`v^4*
           Global`w^3 - 14*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          21*FeynCalc`CA^3*Global`v^4*Global`w^3 + 14*FeynCalc`CA^4*
           Global`v^4*Global`w^3 - 14*FeynCalc`CA*Global`v^5*Global`w^3 + 
          10*FeynCalc`CA^2*Global`v^5*Global`w^3 + 50*FeynCalc`CA^3*
           Global`v^5*Global`w^3 - 10*FeynCalc`CA^4*Global`v^5*Global`w^3 + 
          10*FeynCalc`CA*Global`v^6*Global`w^3 - 30*FeynCalc`CA^3*Global`v^6*
           Global`w^3 + 6*FeynCalc`CA*Global`v^5*Global`w^4 - 
          4*FeynCalc`CA^2*Global`v^5*Global`w^4 - 10*FeynCalc`CA^3*Global`v^5*
           Global`w^4 + 4*FeynCalc`CA^4*Global`v^5*Global`w^4 - 
          8*FeynCalc`CA*Global`v^6*Global`w^4 + 12*FeynCalc`CA^3*Global`v^6*
           Global`w^4 + 2*FeynCalc`CA*Global`v^6*Global`w^5 - 
          2*FeynCalc`CA^3*Global`v^6*Global`w^5)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muD2])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2*Global`w*
         (1 - Global`v + Global`v*Global`w)^2) - 
       ((-1 - 2*FeynCalc`CA + 2*FeynCalc`CA^2 + 2*FeynCalc`CA^3 - 
          FeynCalc`CA^4 + Global`v + 4*FeynCalc`CA*Global`v - 
          8*FeynCalc`CA^3*Global`v - FeynCalc`CA^4*Global`v + Global`v^2 - 
          4*FeynCalc`CA*Global`v^2 + 16*FeynCalc`CA^3*Global`v^2 - 
          FeynCalc`CA^4*Global`v^2 - Global`v^3 + 2*FeynCalc`CA^2*
           Global`v^3 - 16*FeynCalc`CA^3*Global`v^3 - FeynCalc`CA^4*
           Global`v^3 + 8*FeynCalc`CA^3*Global`v^4 + Global`w + 
          FeynCalc`CA*Global`w - 2*FeynCalc`CA^2*Global`w - 
          FeynCalc`CA^3*Global`w + FeynCalc`CA^4*Global`w - 
          Global`v*Global`w - 2*FeynCalc`CA*Global`v*Global`w + 
          4*FeynCalc`CA^3*Global`v*Global`w + FeynCalc`CA^4*Global`v*
           Global`w - Global`v^2*Global`w + 2*FeynCalc`CA*Global`v^2*
           Global`w - 8*FeynCalc`CA^3*Global`v^2*Global`w + 
          FeynCalc`CA^4*Global`v^2*Global`w + Global`v^3*Global`w - 
          2*FeynCalc`CA^2*Global`v^3*Global`w + 8*FeynCalc`CA^3*Global`v^3*
           Global`w + FeynCalc`CA^4*Global`v^3*Global`w - 
          4*FeynCalc`CA^3*Global`v^4*Global`w)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muFA2])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2*Global`w) - 
       ((2*FeynCalc`CA^2 - 2*FeynCalc`CA^4 - Global`v + 
          FeynCalc`CA*Global`v - FeynCalc`CA^2*Global`v - 
          FeynCalc`CA^3*Global`v + 2*FeynCalc`CA^4*Global`v + 2*Global`v^2 - 
          2*FeynCalc`CA*Global`v^2 + 2*FeynCalc`CA^2*Global`v^2 + 
          2*FeynCalc`CA^3*Global`v^2 - 4*FeynCalc`CA^4*Global`v^2 - 
          4*FeynCalc`CA^2*Global`v*Global`w + 4*FeynCalc`CA^4*Global`v*
           Global`w - Global`v^2*Global`w - FeynCalc`CA*Global`v^2*Global`w + 
          3*FeynCalc`CA^2*Global`v^2*Global`w + FeynCalc`CA^3*Global`v^2*
           Global`w + 6*FeynCalc`CA^4*Global`v^2*Global`w + 
          FeynCalc`CA*Global`nD*Global`v^2*Global`w - FeynCalc`CA^3*Global`nD*
           Global`v^2*Global`w + FeynCalc`CA*Global`nU*Global`v^2*Global`w - 
          FeynCalc`CA^3*Global`nU*Global`v^2*Global`w + 
          4*FeynCalc`CA*Global`v^3*Global`w - 6*FeynCalc`CA^2*Global`v^3*
           Global`w - 4*FeynCalc`CA^3*Global`v^3*Global`w - 
          2*FeynCalc`CA^4*Global`v^3*Global`w - 2*FeynCalc`CA*Global`nD*
           Global`v^3*Global`w + 2*FeynCalc`CA^3*Global`nD*Global`v^3*
           Global`w - 2*FeynCalc`CA*Global`nU*Global`v^3*Global`w + 
          2*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w + 
          2*FeynCalc`CA^2*Global`v^2*Global`w^2 - 2*FeynCalc`CA^4*Global`v^2*
           Global`w^2 - 2*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          2*FeynCalc`CA^4*Global`v^3*Global`w^2 + 2*FeynCalc`CA*Global`nD*
           Global`v^3*Global`w^2 - 2*FeynCalc`CA^3*Global`nD*Global`v^3*
           Global`w^2 + 2*FeynCalc`CA*Global`nU*Global`v^3*Global`w^2 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^2 - 
          4*FeynCalc`CA*Global`v^4*Global`w^2 + 4*FeynCalc`CA^3*Global`v^4*
           Global`w^2 - 8*FeynCalc`CA^4*Global`v^4*Global`w^2 - 
          2*FeynCalc`CA*Global`nD*Global`v^4*Global`w^2 + 
          2*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^2 - 
          2*FeynCalc`CA*Global`nU*Global`v^4*Global`w^2 + 
          2*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^2 - 
          Global`v^4*Global`w^3 + 7*FeynCalc`CA^2*Global`v^4*Global`w^3 + 
          2*FeynCalc`CA^4*Global`v^4*Global`w^3 + FeynCalc`CA*Global`nD*
           Global`v^4*Global`w^3 - FeynCalc`CA^3*Global`nD*Global`v^4*
           Global`w^3 + FeynCalc`CA*Global`nU*Global`v^4*Global`w^3 - 
          FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^3 + 
          2*Global`v^5*Global`w^3 + 4*FeynCalc`CA*Global`v^5*Global`w^3 - 
          4*FeynCalc`CA^3*Global`v^5*Global`w^3 - 2*FeynCalc`CA^4*Global`v^5*
           Global`w^3 - Global`v^5*Global`w^4 - FeynCalc`CA*Global`v^5*
           Global`w^4 - 3*FeynCalc`CA^2*Global`v^5*Global`w^4 + 
          FeynCalc`CA^3*Global`v^5*Global`w^4 + 4*FeynCalc`CA^4*Global`v^5*
           Global`w^4 - 2*FeynCalc`CA*Global`v^6*Global`w^4 + 
          2*FeynCalc`CA^3*Global`v^6*Global`w^4 + FeynCalc`CA*Global`v^6*
           Global`w^5 - FeynCalc`CA^3*Global`v^6*Global`w^5)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muFB2])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*
         Global`w*(-1 + Global`v*Global`w)^2) + 
       ((-3 - 2*FeynCalc`CA + 10*FeynCalc`CA^2 + 2*FeynCalc`CA^3 - 
          7*FeynCalc`CA^4 + 9*Global`v + 10*FeynCalc`CA*Global`v - 
          30*FeynCalc`CA^2*Global`v - 18*FeynCalc`CA^3*Global`v + 
          21*FeynCalc`CA^4*Global`v - 7*Global`v^2 - 22*FeynCalc`CA*
           Global`v^2 + 40*FeynCalc`CA^2*Global`v^2 + 62*FeynCalc`CA^3*
           Global`v^2 - 33*FeynCalc`CA^4*Global`v^2 - Global`v^3 + 
          22*FeynCalc`CA*Global`v^3 - 30*FeynCalc`CA^2*Global`v^3 - 
          110*FeynCalc`CA^3*Global`v^3 + 31*FeynCalc`CA^4*Global`v^3 + 
          2*Global`v^4 - 8*FeynCalc`CA*Global`v^4 + 10*FeynCalc`CA^2*
           Global`v^4 + 112*FeynCalc`CA^3*Global`v^4 - 12*FeynCalc`CA^4*
           Global`v^4 - 64*FeynCalc`CA^3*Global`v^5 + 16*FeynCalc`CA^3*
           Global`v^6 + Global`w + FeynCalc`CA*Global`w - 
          2*FeynCalc`CA^2*Global`w - FeynCalc`CA^3*Global`w + 
          FeynCalc`CA^4*Global`w - 3*Global`v*Global`w - 
          4*FeynCalc`CA*Global`v*Global`w + 4*FeynCalc`CA^2*Global`v*
           Global`w + 6*FeynCalc`CA^3*Global`v*Global`w - 
          FeynCalc`CA^4*Global`v*Global`w - 11*Global`v^2*Global`w + 
          5*FeynCalc`CA*Global`v^2*Global`w + 14*FeynCalc`CA^2*Global`v^2*
           Global`w - 21*FeynCalc`CA^3*Global`v^2*Global`w + 
          13*FeynCalc`CA^4*Global`v^2*Global`w + 2*FeynCalc`CA*Global`nD*
           Global`v^2*Global`w - 2*FeynCalc`CA^3*Global`nD*Global`v^2*
           Global`w + 2*FeynCalc`CA*Global`nU*Global`v^2*Global`w - 
          2*FeynCalc`CA^3*Global`nU*Global`v^2*Global`w + 
          37*Global`v^3*Global`w + 6*FeynCalc`CA*Global`v^3*Global`w - 
          38*FeynCalc`CA^2*Global`v^3*Global`w + 32*FeynCalc`CA^3*Global`v^3*
           Global`w - 47*FeynCalc`CA^4*Global`v^3*Global`w - 
          8*FeynCalc`CA*Global`nD*Global`v^3*Global`w + 8*FeynCalc`CA^3*
           Global`nD*Global`v^3*Global`w - 8*FeynCalc`CA*Global`nU*Global`v^3*
           Global`w + 8*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w - 
          30*Global`v^4*Global`w - 24*FeynCalc`CA*Global`v^4*Global`w + 
          48*FeynCalc`CA^2*Global`v^4*Global`w + 4*FeynCalc`CA^3*Global`v^4*
           Global`w + 30*FeynCalc`CA^4*Global`v^4*Global`w + 
          10*FeynCalc`CA*Global`nD*Global`v^4*Global`w - 
          10*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w + 
          10*FeynCalc`CA*Global`nU*Global`v^4*Global`w - 
          10*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w + 
          6*Global`v^5*Global`w + 16*FeynCalc`CA*Global`v^5*Global`w - 
          26*FeynCalc`CA^2*Global`v^5*Global`w - 68*FeynCalc`CA^3*Global`v^5*
           Global`w + 4*FeynCalc`CA^4*Global`v^5*Global`w - 
          4*FeynCalc`CA*Global`nD*Global`v^5*Global`w + 4*FeynCalc`CA^3*
           Global`nD*Global`v^5*Global`w - 4*FeynCalc`CA*Global`nU*Global`v^5*
           Global`w + 4*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w + 
          80*FeynCalc`CA^3*Global`v^6*Global`w - 32*FeynCalc`CA^3*Global`v^7*
           Global`w + 8*Global`v^2*Global`w^2 + 6*FeynCalc`CA*Global`v^2*
           Global`w^2 - 24*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          6*FeynCalc`CA^3*Global`v^2*Global`w^2 + 16*FeynCalc`CA^4*Global`v^2*
           Global`w^2 - 24*Global`v^3*Global`w^2 - 18*FeynCalc`CA*Global`v^3*
           Global`w^2 + 40*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          32*FeynCalc`CA^3*Global`v^3*Global`w^2 + 16*FeynCalc`CA^4*
           Global`v^3*Global`w^2 + 8*FeynCalc`CA*Global`nD*Global`v^3*
           Global`w^2 - 8*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^2 + 
          8*FeynCalc`CA*Global`nU*Global`v^3*Global`w^2 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^2 + 
          14*Global`v^4*Global`w^2 + 24*FeynCalc`CA*Global`v^4*Global`w^2 - 
          42*FeynCalc`CA^2*Global`v^4*Global`w^2 - 102*FeynCalc`CA^3*
           Global`v^4*Global`w^2 - 52*FeynCalc`CA^4*Global`v^4*Global`w^2 - 
          24*FeynCalc`CA*Global`nD*Global`v^4*Global`w^2 + 
          24*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^2 - 
          24*FeynCalc`CA*Global`nU*Global`v^4*Global`w^2 + 
          24*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^2 + 
          10*Global`v^5*Global`w^2 + 26*FeynCalc`CA^2*Global`v^5*Global`w^2 + 
          172*FeynCalc`CA^3*Global`v^5*Global`w^2 + 28*FeynCalc`CA^4*
           Global`v^5*Global`w^2 + 20*FeynCalc`CA*Global`nD*Global`v^5*
           Global`w^2 - 20*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^2 + 
          20*FeynCalc`CA*Global`nU*Global`v^5*Global`w^2 - 
          20*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^2 - 
          6*Global`v^6*Global`w^2 - 16*FeynCalc`CA*Global`v^6*Global`w^2 + 
          10*FeynCalc`CA^2*Global`v^6*Global`w^2 - 140*FeynCalc`CA^3*
           Global`v^6*Global`w^2 - 20*FeynCalc`CA^4*Global`v^6*Global`w^2 - 
          4*FeynCalc`CA*Global`nD*Global`v^6*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^2 - 
          4*FeynCalc`CA*Global`nU*Global`v^6*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^2 + 
          32*FeynCalc`CA^3*Global`v^7*Global`w^2 + 16*FeynCalc`CA^3*
           Global`v^8*Global`w^2 - 2*Global`v^2*Global`w^3 - 
          2*FeynCalc`CA*Global`v^2*Global`w^3 + 4*FeynCalc`CA^2*Global`v^2*
           Global`w^3 + 2*FeynCalc`CA^3*Global`v^2*Global`w^3 - 
          2*FeynCalc`CA^4*Global`v^2*Global`w^3 + 4*Global`v^3*Global`w^3 + 
          6*FeynCalc`CA*Global`v^3*Global`w^3 - 4*FeynCalc`CA^2*Global`v^3*
           Global`w^3 - 10*FeynCalc`CA^3*Global`v^3*Global`w^3 + 
          2*Global`v^4*Global`w^3 - 4*FeynCalc`CA*Global`v^4*Global`w^3 + 
          6*FeynCalc`CA^2*Global`v^4*Global`w^3 + 34*FeynCalc`CA^3*Global`v^4*
           Global`w^3 + 24*FeynCalc`CA^4*Global`v^4*Global`w^3 + 
          12*FeynCalc`CA*Global`nD*Global`v^4*Global`w^3 - 
          12*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^3 + 
          12*FeynCalc`CA*Global`nU*Global`v^4*Global`w^3 - 
          12*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^3 - 
          6*Global`v^5*Global`w^3 - 8*FeynCalc`CA*Global`v^5*Global`w^3 - 
          38*FeynCalc`CA^2*Global`v^5*Global`w^3 - 66*FeynCalc`CA^3*
           Global`v^5*Global`w^3 - 36*FeynCalc`CA^4*Global`v^5*Global`w^3 - 
          24*FeynCalc`CA*Global`nD*Global`v^5*Global`w^3 + 
          24*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^3 - 
          24*FeynCalc`CA*Global`nU*Global`v^5*Global`w^3 + 
          24*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^3 - 
          6*Global`v^6*Global`w^3 + 4*FeynCalc`CA*Global`v^6*Global`w^3 + 
          4*FeynCalc`CA^2*Global`v^6*Global`w^3 + 40*FeynCalc`CA^3*Global`v^6*
           Global`w^3 + 50*FeynCalc`CA^4*Global`v^6*Global`w^3 + 
          10*FeynCalc`CA*Global`nD*Global`v^6*Global`w^3 - 
          10*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^3 + 
          10*FeynCalc`CA*Global`nU*Global`v^6*Global`w^3 - 
          10*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^3 + 
          6*Global`v^7*Global`w^3 + 16*FeynCalc`CA*Global`v^7*Global`w^3 - 
          2*FeynCalc`CA^2*Global`v^7*Global`w^3 + 36*FeynCalc`CA^3*Global`v^7*
           Global`w^3 - 4*FeynCalc`CA^4*Global`v^7*Global`w^3 - 
          48*FeynCalc`CA^3*Global`v^8*Global`w^3 - 5*Global`v^4*Global`w^4 - 
          4*FeynCalc`CA*Global`v^4*Global`w^4 + 14*FeynCalc`CA^2*Global`v^4*
           Global`w^4 + 4*FeynCalc`CA^3*Global`v^4*Global`w^4 - 
          9*FeynCalc`CA^4*Global`v^4*Global`w^4 + Global`v^5*Global`w^4 + 
          4*FeynCalc`CA*Global`v^5*Global`w^4 + 16*FeynCalc`CA^2*Global`v^5*
           Global`w^4 - 6*FeynCalc`CA^3*Global`v^5*Global`w^4 + 
          15*FeynCalc`CA^4*Global`v^5*Global`w^4 + 8*FeynCalc`CA*Global`nD*
           Global`v^5*Global`w^4 - 8*FeynCalc`CA^3*Global`nD*Global`v^5*
           Global`w^4 + 8*FeynCalc`CA*Global`nU*Global`v^5*Global`w^4 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^4 + 
          17*Global`v^6*Global`w^4 + 14*FeynCalc`CA*Global`v^6*Global`w^4 - 
          6*FeynCalc`CA^2*Global`v^6*Global`w^4 + 20*FeynCalc`CA^3*Global`v^6*
           Global`w^4 - 59*FeynCalc`CA^4*Global`v^6*Global`w^4 - 
          8*FeynCalc`CA*Global`nD*Global`v^6*Global`w^4 + 
          8*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^4 - 
          8*FeynCalc`CA*Global`nU*Global`v^6*Global`w^4 + 
          8*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^4 - 
          13*Global`v^7*Global`w^4 - 22*FeynCalc`CA*Global`v^7*Global`w^4 - 
          8*FeynCalc`CA^2*Global`v^7*Global`w^4 - 62*FeynCalc`CA^3*Global`v^7*
           Global`w^4 + 21*FeynCalc`CA^4*Global`v^7*Global`w^4 - 
          8*FeynCalc`CA*Global`v^8*Global`w^4 + 60*FeynCalc`CA^3*Global`v^8*
           Global`w^4 + Global`v^4*Global`w^5 + FeynCalc`CA*Global`v^4*
           Global`w^5 - 2*FeynCalc`CA^2*Global`v^4*Global`w^5 - 
          FeynCalc`CA^3*Global`v^4*Global`w^5 + FeynCalc`CA^4*Global`v^4*
           Global`w^5 - Global`v^5*Global`w^5 - 2*FeynCalc`CA*Global`v^5*
           Global`w^5 + 4*FeynCalc`CA^3*Global`v^5*Global`w^5 + 
          FeynCalc`CA^4*Global`v^5*Global`w^5 - 7*Global`v^6*Global`w^5 - 
          5*FeynCalc`CA*Global`v^6*Global`w^5 - 4*FeynCalc`CA^2*Global`v^6*
           Global`w^5 - 9*FeynCalc`CA^3*Global`v^6*Global`w^5 + 
          27*FeynCalc`CA^4*Global`v^6*Global`w^5 + 2*FeynCalc`CA*Global`nD*
           Global`v^6*Global`w^5 - 2*FeynCalc`CA^3*Global`nD*Global`v^6*
           Global`w^5 + 2*FeynCalc`CA*Global`nU*Global`v^6*Global`w^5 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^5 + 
          9*Global`v^7*Global`w^5 + 2*FeynCalc`CA*Global`v^7*Global`w^5 + 
          20*FeynCalc`CA^2*Global`v^7*Global`w^5 + 34*FeynCalc`CA^3*
           Global`v^7*Global`w^5 - 29*FeynCalc`CA^4*Global`v^7*Global`w^5 + 
          20*FeynCalc`CA*Global`v^8*Global`w^5 - 44*FeynCalc`CA^3*Global`v^8*
           Global`w^5 - 2*Global`v^7*Global`w^6 + 4*FeynCalc`CA*Global`v^7*
           Global`w^6 - 10*FeynCalc`CA^2*Global`v^7*Global`w^6 - 
          8*FeynCalc`CA^3*Global`v^7*Global`w^6 + 12*FeynCalc`CA^4*Global`v^7*
           Global`w^6 - 16*FeynCalc`CA*Global`v^8*Global`w^6 + 
          20*FeynCalc`CA^3*Global`v^8*Global`w^6 + 4*FeynCalc`CA*Global`v^8*
           Global`w^7 - 4*FeynCalc`CA^3*Global`v^8*Global`w^7)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(8*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*Global`w*
         (-1 + Global`v*Global`w)^2*(1 - Global`v + Global`v*Global`w)^2) + 
       ((-2 + FeynCalc`CA^2 - FeynCalc`CA^4 + 7*Global`v + 
          2*FeynCalc`CA*Global`v + 3*FeynCalc`CA^2*Global`v - 
          FeynCalc`CA^4*Global`v - 7*Global`v^2 - 10*FeynCalc`CA*Global`v^2 - 
          4*FeynCalc`CA^2*Global`v^2 + 2*Global`v^3 + 12*FeynCalc`CA*
           Global`v^3 + 2*FeynCalc`CA^3*Global`v^3 + FeynCalc`CA^4*
           Global`v^3 - 4*FeynCalc`CA*Global`v^4 - 2*FeynCalc`CA^3*
           Global`v^4 + FeynCalc`CA^4*Global`v^4 + Global`w + 
          3*FeynCalc`CA^2*Global`w - 2*FeynCalc`CA^4*Global`w - 
          6*Global`v*Global`w - 2*FeynCalc`CA*Global`v*Global`w - 
          13*FeynCalc`CA^2*Global`v*Global`w + FeynCalc`CA^4*Global`v*
           Global`w + 6*Global`v^2*Global`w + 8*FeynCalc`CA*Global`v^2*
           Global`w + 3*FeynCalc`CA^2*Global`v^2*Global`w + 
          2*Global`v^3*Global`w + 4*FeynCalc`CA*Global`v^3*Global`w + 
          16*FeynCalc`CA^2*Global`v^3*Global`w - 4*FeynCalc`CA^3*Global`v^3*
           Global`w - 3*FeynCalc`CA^4*Global`v^3*Global`w - 
          2*Global`v^4*Global`w - 24*FeynCalc`CA*Global`v^4*Global`w - 
          4*FeynCalc`CA^2*Global`v^4*Global`w + 4*FeynCalc`CA^3*Global`v^4*
           Global`w - 3*FeynCalc`CA^4*Global`v^4*Global`w + 
          12*FeynCalc`CA*Global`v^5*Global`w + 2*FeynCalc`CA^3*Global`v^5*
           Global`w + FeynCalc`CA^4*Global`v^5*Global`w + 
          Global`v*Global`w^2 + FeynCalc`CA^2*Global`v*Global`w^2 + 
          2*Global`v^2*Global`w^2 + 2*FeynCalc`CA*Global`v^2*Global`w^2 + 
          4*FeynCalc`CA^2*Global`v^2*Global`w^2 - 2*FeynCalc`CA^4*Global`v^2*
           Global`w^2 - 8*Global`v^3*Global`w^2 - 24*FeynCalc`CA*Global`v^3*
           Global`w^2 - 20*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          2*FeynCalc`CA^3*Global`v^3*Global`w^2 + FeynCalc`CA^4*Global`v^3*
           Global`w^2 + 4*Global`v^4*Global`w^2 + 52*FeynCalc`CA*Global`v^4*
           Global`w^2 - 4*FeynCalc`CA^2*Global`v^4*Global`w^2 - 
          4*FeynCalc`CA^3*Global`v^4*Global`w^2 + 9*FeynCalc`CA^4*Global`v^4*
           Global`w^2 - 24*FeynCalc`CA*Global`v^5*Global`w^2 + 
          4*FeynCalc`CA^2*Global`v^5*Global`w^2 - 8*FeynCalc`CA^4*Global`v^5*
           Global`w^2 - 4*FeynCalc`CA^3*Global`v^6*Global`w^2 - 
          Global`v^2*Global`w^3 - 3*FeynCalc`CA^2*Global`v^2*Global`w^3 + 
          2*FeynCalc`CA^4*Global`v^2*Global`w^3 + 3*Global`v^3*Global`w^3 + 
          8*FeynCalc`CA*Global`v^3*Global`w^3 + 14*FeynCalc`CA^2*Global`v^3*
           Global`w^3 + FeynCalc`CA^4*Global`v^3*Global`w^3 - 
          Global`v^4*Global`w^3 - 28*FeynCalc`CA*Global`v^4*Global`w^3 + 
          5*FeynCalc`CA^2*Global`v^4*Global`w^3 + 4*FeynCalc`CA^3*Global`v^4*
           Global`w^3 - 11*FeynCalc`CA^4*Global`v^4*Global`w^3 - 
          Global`v^5*Global`w^3 + 16*FeynCalc`CA*Global`v^5*Global`w^3 - 
          8*FeynCalc`CA^2*Global`v^5*Global`w^3 - 10*FeynCalc`CA^3*Global`v^5*
           Global`w^3 + 16*FeynCalc`CA^4*Global`v^5*Global`w^3 - 
          4*FeynCalc`CA*Global`v^6*Global`w^3 + 14*FeynCalc`CA^3*Global`v^6*
           Global`w^3 - Global`v^3*Global`w^4 - FeynCalc`CA^2*Global`v^3*
           Global`w^4 + 4*FeynCalc`CA*Global`v^4*Global`w^4 - 
          FeynCalc`CA^2*Global`v^4*Global`w^4 - 2*FeynCalc`CA^3*Global`v^4*
           Global`w^4 + 7*FeynCalc`CA^4*Global`v^4*Global`w^4 + 
          2*Global`v^5*Global`w^4 - 6*FeynCalc`CA*Global`v^5*Global`w^4 + 
          9*FeynCalc`CA^2*Global`v^5*Global`w^4 + 12*FeynCalc`CA^3*Global`v^5*
           Global`w^4 - 15*FeynCalc`CA^4*Global`v^5*Global`w^4 + 
          10*FeynCalc`CA*Global`v^6*Global`w^4 - 18*FeynCalc`CA^3*Global`v^6*
           Global`w^4 - Global`v^5*Global`w^5 + 2*FeynCalc`CA*Global`v^5*
           Global`w^5 - 5*FeynCalc`CA^2*Global`v^5*Global`w^5 - 
          4*FeynCalc`CA^3*Global`v^5*Global`w^5 + 6*FeynCalc`CA^4*Global`v^5*
           Global`w^5 - 8*FeynCalc`CA*Global`v^6*Global`w^5 + 
          10*FeynCalc`CA^3*Global`v^6*Global`w^5 + 2*FeynCalc`CA*Global`v^6*
           Global`w^6 - 2*FeynCalc`CA^3*Global`v^6*Global`w^6)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*
         (-1 + Global`w)*Global`w*(-1 + Global`v*Global`w)*
         (1 - Global`v + Global`v*Global`w)) + 
       ((-3 - 2*FeynCalc`CA + 18*FeynCalc`CA^2 + 2*FeynCalc`CA^3 - 
          15*FeynCalc`CA^4 + 9*Global`v + 10*FeynCalc`CA*Global`v - 
          54*FeynCalc`CA^2*Global`v - 26*FeynCalc`CA^3*Global`v + 
          49*FeynCalc`CA^4*Global`v - 7*Global`v^2 - 22*FeynCalc`CA*
           Global`v^2 + 68*FeynCalc`CA^2*Global`v^2 + 94*FeynCalc`CA^3*
           Global`v^2 - 77*FeynCalc`CA^4*Global`v^2 - Global`v^3 + 
          22*FeynCalc`CA*Global`v^3 - 50*FeynCalc`CA^2*Global`v^3 - 
          158*FeynCalc`CA^3*Global`v^3 + 71*FeynCalc`CA^4*Global`v^3 + 
          2*Global`v^4 - 8*FeynCalc`CA*Global`v^4 + 22*FeynCalc`CA^2*
           Global`v^4 + 144*FeynCalc`CA^3*Global`v^4 - 32*FeynCalc`CA^4*
           Global`v^4 - 4*FeynCalc`CA^2*Global`v^5 - 72*FeynCalc`CA^3*
           Global`v^5 + 4*FeynCalc`CA^4*Global`v^5 + 16*FeynCalc`CA^3*
           Global`v^6 + Global`w + FeynCalc`CA*Global`w - 
          2*FeynCalc`CA^2*Global`w - FeynCalc`CA^3*Global`w + 
          FeynCalc`CA^4*Global`w - 3*Global`v*Global`w - 
          4*FeynCalc`CA*Global`v*Global`w + 4*FeynCalc`CA^2*Global`v*
           Global`w + 6*FeynCalc`CA^3*Global`v*Global`w - 
          FeynCalc`CA^4*Global`v*Global`w - 15*Global`v^2*Global`w + 
          21*FeynCalc`CA*Global`v^2*Global`w + 38*FeynCalc`CA^2*Global`v^2*
           Global`w - 33*FeynCalc`CA^3*Global`v^2*Global`w + 
          21*FeynCalc`CA^4*Global`v^2*Global`w + 2*FeynCalc`CA*Global`nD*
           Global`v^2*Global`w - 2*FeynCalc`CA^3*Global`nD*Global`v^2*
           Global`w + 2*FeynCalc`CA*Global`nU*Global`v^2*Global`w - 
          2*FeynCalc`CA^3*Global`nU*Global`v^2*Global`w + 
          53*Global`v^3*Global`w - 58*FeynCalc`CA*Global`v^3*Global`w - 
          94*FeynCalc`CA^2*Global`v^3*Global`w + 60*FeynCalc`CA^3*Global`v^3*
           Global`w - 75*FeynCalc`CA^4*Global`v^3*Global`w - 
          8*FeynCalc`CA*Global`nD*Global`v^3*Global`w + 8*FeynCalc`CA^3*
           Global`nD*Global`v^3*Global`w - 8*FeynCalc`CA*Global`nU*Global`v^3*
           Global`w + 8*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w - 
          50*Global`v^4*Global`w + 72*FeynCalc`CA*Global`v^4*Global`w + 
          92*FeynCalc`CA^2*Global`v^4*Global`w - 8*FeynCalc`CA^3*Global`v^4*
           Global`w + 50*FeynCalc`CA^4*Global`v^4*Global`w + 
          10*FeynCalc`CA*Global`nD*Global`v^4*Global`w - 
          10*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w + 
          10*FeynCalc`CA*Global`nU*Global`v^4*Global`w - 
          10*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w + 
          14*Global`v^5*Global`w - 48*FeynCalc`CA*Global`v^5*Global`w - 
          46*FeynCalc`CA^2*Global`v^5*Global`w - 80*FeynCalc`CA^3*Global`v^5*
           Global`w + 8*FeynCalc`CA^4*Global`v^5*Global`w - 
          4*FeynCalc`CA*Global`nD*Global`v^5*Global`w + 4*FeynCalc`CA^3*
           Global`nD*Global`v^5*Global`w - 4*FeynCalc`CA*Global`nU*Global`v^5*
           Global`w + 4*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w + 
          16*FeynCalc`CA*Global`v^6*Global`w + 8*FeynCalc`CA^2*Global`v^6*
           Global`w + 88*FeynCalc`CA^3*Global`v^6*Global`w - 
          4*FeynCalc`CA^4*Global`v^6*Global`w - 32*FeynCalc`CA^3*Global`v^7*
           Global`w + 8*Global`v^2*Global`w^2 + 6*FeynCalc`CA*Global`v^2*
           Global`w^2 - 40*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          6*FeynCalc`CA^3*Global`v^2*Global`w^2 + 32*FeynCalc`CA^4*Global`v^2*
           Global`w^2 - 36*Global`v^3*Global`w^2 + 6*FeynCalc`CA*Global`v^3*
           Global`w^2 + 72*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          36*FeynCalc`CA^3*Global`v^3*Global`w^2 + 8*FeynCalc`CA*Global`nD*
           Global`v^3*Global`w^2 - 8*FeynCalc`CA^3*Global`nD*Global`v^3*
           Global`w^2 + 8*FeynCalc`CA*Global`nU*Global`v^3*Global`w^2 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^2 + 
          38*Global`v^4*Global`w^2 - 32*FeynCalc`CA*Global`v^4*Global`w^2 - 
          34*FeynCalc`CA^2*Global`v^4*Global`w^2 - 130*FeynCalc`CA^3*
           Global`v^4*Global`w^2 - 32*FeynCalc`CA^4*Global`v^4*Global`w^2 - 
          24*FeynCalc`CA*Global`nD*Global`v^4*Global`w^2 + 
          24*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^2 - 
          24*FeynCalc`CA*Global`nU*Global`v^4*Global`w^2 + 
          24*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^2 + 
          6*Global`v^5*Global`w^2 + 24*FeynCalc`CA*Global`v^5*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v^5*Global`w^2 + 216*FeynCalc`CA^3*
           Global`v^5*Global`w^2 - 12*FeynCalc`CA^4*Global`v^5*Global`w^2 + 
          20*FeynCalc`CA*Global`nD*Global`v^5*Global`w^2 - 
          20*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^2 + 
          20*FeynCalc`CA*Global`nU*Global`v^5*Global`w^2 - 
          20*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^2 - 
          14*Global`v^6*Global`w^2 + 8*FeynCalc`CA*Global`v^6*Global`w^2 + 
          14*FeynCalc`CA^2*Global`v^6*Global`w^2 - 160*FeynCalc`CA^3*
           Global`v^6*Global`w^2 - 4*FeynCalc`CA^4*Global`v^6*Global`w^2 - 
          4*FeynCalc`CA*Global`nD*Global`v^6*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^2 - 
          4*FeynCalc`CA*Global`nU*Global`v^6*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^2 - 
          16*FeynCalc`CA*Global`v^7*Global`w^2 - 4*FeynCalc`CA^2*Global`v^7*
           Global`w^2 + 32*FeynCalc`CA^3*Global`v^7*Global`w^2 + 
          16*FeynCalc`CA^3*Global`v^8*Global`w^2 - 2*Global`v^2*Global`w^3 - 
          2*FeynCalc`CA*Global`v^2*Global`w^3 + 4*FeynCalc`CA^2*Global`v^2*
           Global`w^3 + 2*FeynCalc`CA^3*Global`v^2*Global`w^3 - 
          2*FeynCalc`CA^4*Global`v^2*Global`w^3 + 4*Global`v^3*Global`w^3 + 
          6*FeynCalc`CA*Global`v^3*Global`w^3 - 4*FeynCalc`CA^2*Global`v^3*
           Global`w^3 - 10*FeynCalc`CA^3*Global`v^3*Global`w^3 - 
          2*Global`v^4*Global`w^3 - 12*FeynCalc`CA*Global`v^4*Global`w^3 - 
          26*FeynCalc`CA^2*Global`v^4*Global`w^3 + 46*FeynCalc`CA^3*
           Global`v^4*Global`w^3 + 16*FeynCalc`CA^4*Global`v^4*Global`w^3 + 
          12*FeynCalc`CA*Global`nD*Global`v^4*Global`w^3 - 
          12*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^3 + 
          12*FeynCalc`CA*Global`nU*Global`v^4*Global`w^3 - 
          12*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^3 - 
          22*Global`v^5*Global`w^3 + 48*FeynCalc`CA*Global`v^5*Global`w^3 + 
          2*FeynCalc`CA^2*Global`v^5*Global`w^3 - 94*FeynCalc`CA^3*Global`v^5*
           Global`w^3 + 8*FeynCalc`CA^4*Global`v^5*Global`w^3 - 
          24*FeynCalc`CA*Global`nD*Global`v^5*Global`w^3 + 
          24*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^3 - 
          24*FeynCalc`CA*Global`nU*Global`v^5*Global`w^3 + 
          24*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^3 + 
          18*Global`v^6*Global`w^3 - 84*FeynCalc`CA*Global`v^6*Global`w^3 + 
          8*FeynCalc`CA^2*Global`v^6*Global`w^3 + 56*FeynCalc`CA^3*Global`v^6*
           Global`w^3 + 30*FeynCalc`CA^4*Global`v^6*Global`w^3 + 
          10*FeynCalc`CA*Global`nD*Global`v^6*Global`w^3 - 
          10*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^3 + 
          10*FeynCalc`CA*Global`nU*Global`v^6*Global`w^3 - 
          10*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^3 + 
          6*Global`v^7*Global`w^3 + 56*FeynCalc`CA*Global`v^7*Global`w^3 + 
          2*FeynCalc`CA^2*Global`v^7*Global`w^3 + 36*FeynCalc`CA^3*Global`v^7*
           Global`w^3 - 4*FeynCalc`CA^4*Global`v^7*Global`w^3 - 
          48*FeynCalc`CA^3*Global`v^8*Global`w^3 - 5*Global`v^4*Global`w^4 - 
          4*FeynCalc`CA*Global`v^4*Global`w^4 + 22*FeynCalc`CA^2*Global`v^4*
           Global`w^4 + 4*FeynCalc`CA^3*Global`v^4*Global`w^4 - 
          17*FeynCalc`CA^4*Global`v^4*Global`w^4 + 13*Global`v^5*Global`w^4 - 
          20*FeynCalc`CA*Global`v^5*Global`w^4 + 8*FeynCalc`CA^2*Global`v^5*
           Global`w^4 - 2*FeynCalc`CA^3*Global`v^5*Global`w^4 + 
          3*FeynCalc`CA^4*Global`v^5*Global`w^4 + 8*FeynCalc`CA*Global`nD*
           Global`v^5*Global`w^4 - 8*FeynCalc`CA^3*Global`nD*Global`v^5*
           Global`w^4 + 8*FeynCalc`CA*Global`nU*Global`v^5*Global`w^4 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^4 - 
          7*Global`v^6*Global`w^4 + 70*FeynCalc`CA*Global`v^6*Global`w^4 - 
          26*FeynCalc`CA^2*Global`v^6*Global`w^4 + 16*FeynCalc`CA^3*
           Global`v^6*Global`w^4 - 51*FeynCalc`CA^4*Global`v^6*Global`w^4 - 
          8*FeynCalc`CA*Global`nD*Global`v^6*Global`w^4 + 
          8*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^4 - 
          8*FeynCalc`CA*Global`nU*Global`v^6*Global`w^4 + 
          8*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^4 - 
          13*Global`v^7*Global`w^4 - 54*FeynCalc`CA*Global`v^7*Global`w^4 - 
          8*FeynCalc`CA^2*Global`v^7*Global`w^4 - 62*FeynCalc`CA^3*Global`v^7*
           Global`w^4 + 21*FeynCalc`CA^4*Global`v^7*Global`w^4 - 
          8*FeynCalc`CA*Global`v^8*Global`w^4 + 60*FeynCalc`CA^3*Global`v^8*
           Global`w^4 + Global`v^4*Global`w^5 + FeynCalc`CA*Global`v^4*
           Global`w^5 - 2*FeynCalc`CA^2*Global`v^4*Global`w^5 - 
          FeynCalc`CA^3*Global`v^4*Global`w^5 + FeynCalc`CA^4*Global`v^4*
           Global`w^5 - Global`v^5*Global`w^5 - 2*FeynCalc`CA*Global`v^5*
           Global`w^5 + 4*FeynCalc`CA^3*Global`v^5*Global`w^5 + 
          FeynCalc`CA^4*Global`v^5*Global`w^5 + Global`v^6*Global`w^5 - 
          13*FeynCalc`CA*Global`v^6*Global`w^5 + 4*FeynCalc`CA^2*Global`v^6*
           Global`w^5 - 9*FeynCalc`CA^3*Global`v^6*Global`w^5 + 
          27*FeynCalc`CA^4*Global`v^6*Global`w^5 + 2*FeynCalc`CA*Global`nD*
           Global`v^6*Global`w^5 - 2*FeynCalc`CA^3*Global`nD*Global`v^6*
           Global`w^5 + 2*FeynCalc`CA*Global`nU*Global`v^6*Global`w^5 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^5 + 
          9*Global`v^7*Global`w^5 + 10*FeynCalc`CA*Global`v^7*Global`w^5 + 
          20*FeynCalc`CA^2*Global`v^7*Global`w^5 + 34*FeynCalc`CA^3*
           Global`v^7*Global`w^5 - 29*FeynCalc`CA^4*Global`v^7*Global`w^5 + 
          20*FeynCalc`CA*Global`v^8*Global`w^5 - 44*FeynCalc`CA^3*Global`v^8*
           Global`w^5 - 2*Global`v^7*Global`w^6 + 4*FeynCalc`CA*Global`v^7*
           Global`w^6 - 10*FeynCalc`CA^2*Global`v^7*Global`w^6 - 
          8*FeynCalc`CA^3*Global`v^7*Global`w^6 + 12*FeynCalc`CA^4*Global`v^7*
           Global`w^6 - 16*FeynCalc`CA*Global`v^8*Global`w^6 + 
          20*FeynCalc`CA^3*Global`v^8*Global`w^6 + 4*FeynCalc`CA*Global`v^8*
           Global`w^7 - 4*FeynCalc`CA^3*Global`v^8*Global`w^7)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`v])/(8*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*Global`w*
         (-1 + Global`v*Global`w)^2*(1 - Global`v + Global`v*Global`w)^2) + 
       ((-5 - 2*FeynCalc`CA + 16*FeynCalc`CA^2 + 2*FeynCalc`CA^3 - 
          11*FeynCalc`CA^4 + 19*Global`v + 6*FeynCalc`CA*Global`v - 
          46*FeynCalc`CA^2*Global`v - 22*FeynCalc`CA^3*Global`v + 
          35*FeynCalc`CA^4*Global`v - 25*Global`v^2 - 2*FeynCalc`CA*
           Global`v^2 + 50*FeynCalc`CA^2*Global`v^2 + 78*FeynCalc`CA^3*
           Global`v^2 - 55*FeynCalc`CA^4*Global`v^2 + 13*Global`v^3 - 
          14*FeynCalc`CA*Global`v^3 - 26*FeynCalc`CA^2*Global`v^3 - 
          134*FeynCalc`CA^3*Global`v^3 + 51*FeynCalc`CA^4*Global`v^3 - 
          2*Global`v^4 + 20*FeynCalc`CA*Global`v^4 + 6*FeynCalc`CA^2*
           Global`v^4 + 128*FeynCalc`CA^3*Global`v^4 - 22*FeynCalc`CA^4*
           Global`v^4 - 8*FeynCalc`CA*Global`v^5 - 68*FeynCalc`CA^3*
           Global`v^5 + 2*FeynCalc`CA^4*Global`v^5 + 16*FeynCalc`CA^3*
           Global`v^6 + Global`w + FeynCalc`CA*Global`w - 
          2*FeynCalc`CA^2*Global`w - FeynCalc`CA^3*Global`w + 
          FeynCalc`CA^4*Global`w - 5*Global`v*Global`w - 
          4*FeynCalc`CA*Global`v*Global`w + 2*FeynCalc`CA^2*Global`v*
           Global`w + 6*FeynCalc`CA^3*Global`v*Global`w - 
          FeynCalc`CA^4*Global`v*Global`w - 13*Global`v^2*Global`w + 
          9*FeynCalc`CA*Global`v^2*Global`w + 30*FeynCalc`CA^2*Global`v^2*
           Global`w - 25*FeynCalc`CA^3*Global`v^2*Global`w + 
          19*FeynCalc`CA^4*Global`v^2*Global`w + 2*FeynCalc`CA*Global`nD*
           Global`v^2*Global`w - 2*FeynCalc`CA^3*Global`nD*Global`v^2*
           Global`w + 2*FeynCalc`CA*Global`nU*Global`v^2*Global`w - 
          2*FeynCalc`CA^3*Global`nU*Global`v^2*Global`w + 
          55*Global`v^3*Global`w - 30*FeynCalc`CA*Global`v^3*Global`w - 
          76*FeynCalc`CA^2*Global`v^3*Global`w + 36*FeynCalc`CA^3*Global`v^3*
           Global`w - 61*FeynCalc`CA^4*Global`v^3*Global`w - 
          8*FeynCalc`CA*Global`nD*Global`v^3*Global`w + 8*FeynCalc`CA^3*
           Global`nD*Global`v^3*Global`w - 8*FeynCalc`CA*Global`nU*Global`v^3*
           Global`w + 8*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w - 
          52*Global`v^4*Global`w + 68*FeynCalc`CA*Global`v^4*Global`w + 
          76*FeynCalc`CA^2*Global`v^4*Global`w + 16*FeynCalc`CA^3*Global`v^4*
           Global`w + 36*FeynCalc`CA^4*Global`v^4*Global`w + 
          10*FeynCalc`CA*Global`nD*Global`v^4*Global`w - 
          10*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w + 
          10*FeynCalc`CA*Global`nU*Global`v^4*Global`w - 
          10*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w + 
          14*Global`v^5*Global`w - 76*FeynCalc`CA*Global`v^5*Global`w - 
          30*FeynCalc`CA^2*Global`v^5*Global`w - 88*FeynCalc`CA^3*Global`v^5*
           Global`w + 6*FeynCalc`CA^4*Global`v^5*Global`w - 
          4*FeynCalc`CA*Global`nD*Global`v^5*Global`w + 4*FeynCalc`CA^3*
           Global`nD*Global`v^5*Global`w - 4*FeynCalc`CA*Global`nU*Global`v^5*
           Global`w + 4*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w + 
          32*FeynCalc`CA*Global`v^6*Global`w + 88*FeynCalc`CA^3*Global`v^6*
           Global`w - 32*FeynCalc`CA^3*Global`v^7*Global`w + 
          12*Global`v^2*Global`w^2 + 6*FeynCalc`CA*Global`v^2*Global`w^2 - 
          32*FeynCalc`CA^2*Global`v^2*Global`w^2 - 6*FeynCalc`CA^3*Global`v^2*
           Global`w^2 + 24*FeynCalc`CA^4*Global`v^2*Global`w^2 - 
          44*Global`v^3*Global`w^2 + 6*FeynCalc`CA*Global`v^3*Global`w^2 + 
          54*FeynCalc`CA^2*Global`v^3*Global`w^2 + 36*FeynCalc`CA^3*
           Global`v^3*Global`w^2 + 10*FeynCalc`CA^4*Global`v^3*Global`w^2 + 
          8*FeynCalc`CA*Global`nD*Global`v^3*Global`w^2 - 
          8*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^2 + 
          8*FeynCalc`CA*Global`nU*Global`v^3*Global`w^2 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^2 + 
          34*Global`v^4*Global`w^2 - 64*FeynCalc`CA*Global`v^4*Global`w^2 - 
          30*FeynCalc`CA^2*Global`v^4*Global`w^2 - 114*FeynCalc`CA^3*
           Global`v^4*Global`w^2 - 40*FeynCalc`CA^4*Global`v^4*Global`w^2 - 
          24*FeynCalc`CA*Global`nD*Global`v^4*Global`w^2 + 
          24*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^2 - 
          24*FeynCalc`CA*Global`nU*Global`v^4*Global`w^2 + 
          24*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^2 + 
          10*Global`v^5*Global`w^2 + 84*FeynCalc`CA*Global`v^5*Global`w^2 - 
          18*FeynCalc`CA^2*Global`v^5*Global`w^2 + 172*FeynCalc`CA^3*
           Global`v^5*Global`w^2 + 12*FeynCalc`CA^4*Global`v^5*Global`w^2 + 
          20*FeynCalc`CA*Global`nD*Global`v^5*Global`w^2 - 
          20*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^2 + 
          20*FeynCalc`CA*Global`nU*Global`v^5*Global`w^2 - 
          20*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^2 - 
          10*Global`v^6*Global`w^2 - 12*FeynCalc`CA*Global`v^6*Global`w^2 + 
          30*FeynCalc`CA^2*Global`v^6*Global`w^2 - 120*FeynCalc`CA^3*
           Global`v^6*Global`w^2 - 18*FeynCalc`CA^4*Global`v^6*Global`w^2 - 
          4*FeynCalc`CA*Global`nD*Global`v^6*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^2 - 
          4*FeynCalc`CA*Global`nU*Global`v^6*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^2 - 
          24*FeynCalc`CA*Global`v^7*Global`w^2 + 20*FeynCalc`CA^3*Global`v^7*
           Global`w^2 - 2*FeynCalc`CA^4*Global`v^7*Global`w^2 + 
          16*FeynCalc`CA^3*Global`v^8*Global`w^2 - 2*Global`v^2*Global`w^3 - 
          2*FeynCalc`CA*Global`v^2*Global`w^3 + 4*FeynCalc`CA^2*Global`v^2*
           Global`w^3 + 2*FeynCalc`CA^3*Global`v^2*Global`w^3 - 
          2*FeynCalc`CA^4*Global`v^2*Global`w^3 + 8*Global`v^3*Global`w^3 + 
          6*FeynCalc`CA*Global`v^3*Global`w^3 - 10*FeynCalc`CA^3*Global`v^3*
           Global`w^3 - 2*Global`v^4*Global`w^3 + 4*FeynCalc`CA*Global`v^4*
           Global`w^3 - 6*FeynCalc`CA^2*Global`v^4*Global`w^3 + 
          34*FeynCalc`CA^3*Global`v^4*Global`w^3 + 16*FeynCalc`CA^4*
           Global`v^4*Global`w^3 + 12*FeynCalc`CA*Global`nD*Global`v^4*
           Global`w^3 - 12*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^3 + 
          12*FeynCalc`CA*Global`nU*Global`v^4*Global`w^3 - 
          12*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^3 - 
          14*Global`v^5*Global`w^3 + 16*FeynCalc`CA*Global`v^5*Global`w^3 - 
          2*FeynCalc`CA^2*Global`v^5*Global`w^3 - 50*FeynCalc`CA^3*Global`v^5*
           Global`w^3 - 12*FeynCalc`CA^4*Global`v^5*Global`w^3 - 
          24*FeynCalc`CA*Global`nD*Global`v^5*Global`w^3 + 
          24*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^3 - 
          24*FeynCalc`CA*Global`nU*Global`v^5*Global`w^3 + 
          24*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^3 - 
          88*FeynCalc`CA*Global`v^6*Global`w^3 - 8*FeynCalc`CA^2*Global`v^6*
           Global`w^3 + 12*FeynCalc`CA^3*Global`v^6*Global`w^3 + 
          44*FeynCalc`CA^4*Global`v^6*Global`w^3 + 10*FeynCalc`CA*Global`nD*
           Global`v^6*Global`w^3 - 10*FeynCalc`CA^3*Global`nD*Global`v^6*
           Global`w^3 + 10*FeynCalc`CA*Global`nU*Global`v^6*Global`w^3 - 
          10*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^3 + 
          6*Global`v^7*Global`w^3 + 76*FeynCalc`CA*Global`v^7*Global`w^3 - 
          14*FeynCalc`CA^2*Global`v^7*Global`w^3 + 40*FeynCalc`CA^3*
           Global`v^7*Global`w^3 + 2*FeynCalc`CA^4*Global`v^7*Global`w^3 - 
          40*FeynCalc`CA^3*Global`v^8*Global`w^3 - 7*Global`v^4*Global`w^4 - 
          4*FeynCalc`CA*Global`v^4*Global`w^4 + 12*FeynCalc`CA^2*Global`v^4*
           Global`w^4 + 4*FeynCalc`CA^3*Global`v^4*Global`w^4 - 
          13*FeynCalc`CA^4*Global`v^4*Global`w^4 + 11*Global`v^5*Global`w^4 - 
          16*FeynCalc`CA*Global`v^5*Global`w^4 + 16*FeynCalc`CA^2*Global`v^5*
           Global`w^4 - 10*FeynCalc`CA^3*Global`v^5*Global`w^4 + 
          5*FeynCalc`CA^4*Global`v^5*Global`w^4 + 8*FeynCalc`CA*Global`nD*
           Global`v^5*Global`w^4 - 8*FeynCalc`CA^3*Global`nD*Global`v^5*
           Global`w^4 + 8*FeynCalc`CA*Global`nU*Global`v^5*Global`w^4 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^4 + 
          7*Global`v^6*Global`w^4 + 82*FeynCalc`CA*Global`v^6*Global`w^4 - 
          12*FeynCalc`CA^2*Global`v^6*Global`w^4 + 20*FeynCalc`CA^3*
           Global`v^6*Global`w^4 - 57*FeynCalc`CA^4*Global`v^6*Global`w^4 - 
          8*FeynCalc`CA*Global`nD*Global`v^6*Global`w^4 + 
          8*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^4 - 
          8*FeynCalc`CA*Global`nU*Global`v^6*Global`w^4 + 
          8*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^4 - 
          11*Global`v^7*Global`w^4 - 70*FeynCalc`CA*Global`v^7*Global`w^4 + 
          16*FeynCalc`CA^2*Global`v^7*Global`w^4 - 38*FeynCalc`CA^3*
           Global`v^7*Global`w^4 + 17*FeynCalc`CA^4*Global`v^7*Global`w^4 - 
          8*FeynCalc`CA*Global`v^8*Global`w^4 + 40*FeynCalc`CA^3*Global`v^8*
           Global`w^4 + Global`v^4*Global`w^5 + FeynCalc`CA*Global`v^4*
           Global`w^5 - 2*FeynCalc`CA^2*Global`v^4*Global`w^5 - 
          FeynCalc`CA^3*Global`v^4*Global`w^5 + FeynCalc`CA^4*Global`v^4*
           Global`w^5 - 3*Global`v^5*Global`w^5 - 2*FeynCalc`CA*Global`v^5*
           Global`w^5 - 2*FeynCalc`CA^2*Global`v^5*Global`w^5 + 
          4*FeynCalc`CA^3*Global`v^5*Global`w^5 + FeynCalc`CA^4*Global`v^5*
           Global`w^5 - Global`v^6*Global`w^5 - 17*FeynCalc`CA*Global`v^6*
           Global`w^5 - 8*FeynCalc`CA^2*Global`v^6*Global`w^5 - 
          5*FeynCalc`CA^3*Global`v^6*Global`w^5 + 29*FeynCalc`CA^4*Global`v^6*
           Global`w^5 + 2*FeynCalc`CA*Global`nD*Global`v^6*Global`w^5 - 
          2*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^5 + 
          2*FeynCalc`CA*Global`nU*Global`v^6*Global`w^5 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^5 + 
          7*Global`v^7*Global`w^5 + 14*FeynCalc`CA*Global`v^7*Global`w^5 + 
          6*FeynCalc`CA^2*Global`v^7*Global`w^5 + 14*FeynCalc`CA^3*Global`v^7*
           Global`w^5 - 31*FeynCalc`CA^4*Global`v^7*Global`w^5 + 
          20*FeynCalc`CA*Global`v^8*Global`w^5 - 28*FeynCalc`CA^3*Global`v^8*
           Global`w^5 + 4*FeynCalc`CA^2*Global`v^6*Global`w^6 - 
          2*Global`v^7*Global`w^6 + 4*FeynCalc`CA*Global`v^7*Global`w^6 - 
          8*FeynCalc`CA^2*Global`v^7*Global`w^6 - 4*FeynCalc`CA^3*Global`v^7*
           Global`w^6 + 14*FeynCalc`CA^4*Global`v^7*Global`w^6 - 
          16*FeynCalc`CA*Global`v^8*Global`w^6 + 16*FeynCalc`CA^3*Global`v^8*
           Global`w^6 + 4*FeynCalc`CA*Global`v^8*Global`w^7 - 
          4*FeynCalc`CA^3*Global`v^8*Global`w^7)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`w])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2*Global`w*(-1 + Global`v*Global`w)^2*
         (1 - Global`v + Global`v*Global`w)^2) - 
       ((2 - 5*FeynCalc`CA^2 + 3*FeynCalc`CA^4 - 5*Global`v + 
          10*FeynCalc`CA^2*Global`v + 4*FeynCalc`CA^3*Global`v - 
          5*FeynCalc`CA^4*Global`v + 3*Global`v^2 + 2*FeynCalc`CA*
           Global`v^2 - 10*FeynCalc`CA^2*Global`v^2 - 18*FeynCalc`CA^3*
           Global`v^2 + 7*FeynCalc`CA^4*Global`v^2 - 2*FeynCalc`CA*
           Global`v^3 + 5*FeynCalc`CA^2*Global`v^3 + 30*FeynCalc`CA^3*
           Global`v^3 - 5*FeynCalc`CA^4*Global`v^3 - 24*FeynCalc`CA^3*
           Global`v^4 + 8*FeynCalc`CA^3*Global`v^5 - Global`w + 
          FeynCalc`CA^2*Global`w - 4*FeynCalc`CA^2*Global`v*Global`w - 
          4*FeynCalc`CA^3*Global`v*Global`w + 5*FeynCalc`CA^4*Global`v*
           Global`w + 7*Global`v^2*Global`w - 7*FeynCalc`CA*Global`v^2*
           Global`w + 8*FeynCalc`CA^2*Global`v^2*Global`w + 
          25*FeynCalc`CA^3*Global`v^2*Global`w - 11*FeynCalc`CA^4*Global`v^2*
           Global`w - 11*Global`v^3*Global`w + 11*FeynCalc`CA*Global`v^3*
           Global`w - 10*FeynCalc`CA^2*Global`v^3*Global`w - 
          47*FeynCalc`CA^3*Global`v^3*Global`w + 13*FeynCalc`CA^4*Global`v^3*
           Global`w + 4*Global`v^4*Global`w - 2*FeynCalc`CA*Global`v^4*
           Global`w + 32*FeynCalc`CA^3*Global`v^4*Global`w - 
          FeynCalc`CA^4*Global`v^4*Global`w - 8*FeynCalc`CA^3*Global`v^6*
           Global`w + Global`v*Global`w^2 + FeynCalc`CA^2*Global`v*
           Global`w^2 - 6*Global`v^2*Global`w^2 + 5*FeynCalc`CA*Global`v^2*
           Global`w^2 + 8*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          7*FeynCalc`CA^3*Global`v^2*Global`w^2 + FeynCalc`CA^4*Global`v^2*
           Global`w^2 + 14*Global`v^3*Global`w^2 - 13*FeynCalc`CA*Global`v^3*
           Global`w^2 - 7*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          17*FeynCalc`CA^3*Global`v^3*Global`w^2 - 8*FeynCalc`CA^4*Global`v^3*
           Global`w^2 - 9*Global`v^4*Global`w^2 + 3*FeynCalc`CA*Global`v^4*
           Global`w^2 + 12*FeynCalc`CA^2*Global`v^4*Global`w^2 + 
          5*FeynCalc`CA^3*Global`v^4*Global`w^2 + 3*FeynCalc`CA^4*Global`v^4*
           Global`w^2 - 5*FeynCalc`CA^2*Global`v^5*Global`w^2 - 
          34*FeynCalc`CA^3*Global`v^5*Global`w^2 + 24*FeynCalc`CA^3*
           Global`v^6*Global`w^2 + Global`v^2*Global`w^3 - 
          3*FeynCalc`CA^2*Global`v^2*Global`w^3 - 4*Global`v^3*Global`w^3 + 
          4*FeynCalc`CA*Global`v^3*Global`w^3 + 3*FeynCalc`CA^2*Global`v^3*
           Global`w^3 + 5*Global`v^4*Global`w^3 - 7*FeynCalc`CA^2*Global`v^4*
           Global`w^3 - 18*FeynCalc`CA^3*Global`v^4*Global`w^3 - 
          4*FeynCalc`CA^4*Global`v^4*Global`w^3 + Global`v^5*Global`w^3 + 
          8*FeynCalc`CA^2*Global`v^5*Global`w^3 + 40*FeynCalc`CA^3*Global`v^5*
           Global`w^3 + FeynCalc`CA^4*Global`v^5*Global`w^3 - 
          26*FeynCalc`CA^3*Global`v^6*Global`w^3 - Global`v^3*Global`w^4 - 
          FeynCalc`CA^2*Global`v^3*Global`w^4 - FeynCalc`CA*Global`v^4*
           Global`w^4 - 3*FeynCalc`CA^2*Global`v^4*Global`w^4 + 
          5*FeynCalc`CA^3*Global`v^4*Global`w^4 + 2*FeynCalc`CA^4*Global`v^4*
           Global`w^4 - Global`v^5*Global`w^4 - 4*FeynCalc`CA^2*Global`v^5*
           Global`w^4 - 16*FeynCalc`CA^3*Global`v^5*Global`w^4 - 
          2*FeynCalc`CA^4*Global`v^5*Global`w^4 + 12*FeynCalc`CA^3*Global`v^6*
           Global`w^4 + 2*FeynCalc`CA^2*Global`v^4*Global`w^5 + 
          FeynCalc`CA^2*Global`v^5*Global`w^5 + 2*FeynCalc`CA^3*Global`v^5*
           Global`w^5 + FeynCalc`CA^4*Global`v^5*Global`w^5 - 
          2*FeynCalc`CA^3*Global`v^6*Global`w^5)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`w])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2*(-1 + Global`w)*Global`w*
         (-1 + Global`v*Global`w)*(1 - Global`v + Global`v*Global`w)) - 
       ((1 - 4*FeynCalc`CA^2 + 3*FeynCalc`CA^4 - 2*Global`v + 
          2*FeynCalc`CA^3*Global`v - FeynCalc`CA^4*Global`v + 
          2*FeynCalc`CA*Global`v^2 - 2*FeynCalc`CA^2*Global`v^2 - 
          4*FeynCalc`CA^3*Global`v^2 + 5*FeynCalc`CA^4*Global`v^2 + 
          Global`v*Global`w + 5*FeynCalc`CA^2*Global`v*Global`w - 
          2*FeynCalc`CA^3*Global`v*Global`w + 4*FeynCalc`CA^4*Global`v*
           Global`w - 2*FeynCalc`CA*Global`v^2*Global`w + 
          4*FeynCalc`CA^2*Global`v^2*Global`w + 6*FeynCalc`CA^3*Global`v^2*
           Global`w - 10*FeynCalc`CA^4*Global`v^2*Global`w - 
          2*FeynCalc`CA*Global`v^3*Global`w - 2*FeynCalc`CA^2*Global`v^3*
           Global`w + 5*FeynCalc`CA^4*Global`v^3*Global`w - 
          Global`v^2*Global`w^2 + 3*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          2*FeynCalc`CA^3*Global`v^2*Global`w^2 + 8*FeynCalc`CA^4*Global`v^2*
           Global`w^2 + 2*Global`v^3*Global`w^2 + 4*FeynCalc`CA^2*Global`v^3*
           Global`w^2 + 2*FeynCalc`CA^3*Global`v^3*Global`w^2 - 
          9*FeynCalc`CA^4*Global`v^3*Global`w^2 + 4*FeynCalc`CA*Global`v^4*
           Global`w^2 - 4*FeynCalc`CA^3*Global`v^4*Global`w^2 - 
          Global`v^3*Global`w^3 + 2*FeynCalc`CA*Global`v^3*Global`w^3 - 
          6*FeynCalc`CA^2*Global`v^3*Global`w^3 - 2*FeynCalc`CA^3*Global`v^3*
           Global`w^3 + 7*FeynCalc`CA^4*Global`v^3*Global`w^3 - 
          6*FeynCalc`CA*Global`v^4*Global`w^3 + 6*FeynCalc`CA^3*Global`v^4*
           Global`w^3 + 2*FeynCalc`CA*Global`v^4*Global`w^4 - 
          2*FeynCalc`CA^3*Global`v^4*Global`w^4)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v*Global`w])/(4*FeynCalc`CA^3*System`Pi*
         Global`s^2*(-1 + Global`v)*Global`v^2*(-1 + Global`w)*Global`w) - 
       ((-2*FeynCalc`CA - FeynCalc`CA^2 - Global`v + 10*FeynCalc`CA*
           Global`v + 3*FeynCalc`CA^2*Global`v - 2*FeynCalc`CA^3*Global`v + 
          3*Global`v^2 - 18*FeynCalc`CA*Global`v^2 - 3*FeynCalc`CA^2*
           Global`v^2 + 6*FeynCalc`CA^3*Global`v^2 - 3*Global`v^3 + 
          14*FeynCalc`CA*Global`v^3 + FeynCalc`CA^2*Global`v^3 - 
          6*FeynCalc`CA^3*Global`v^3 + Global`v^4 - 4*FeynCalc`CA*
           Global`v^4 + 2*FeynCalc`CA^3*Global`v^4 + 2*Global`w + 
          2*FeynCalc`CA*Global`w + 3*FeynCalc`CA^2*Global`w - 
          7*Global`v*Global`w - 15*FeynCalc`CA*Global`v*Global`w - 
          14*FeynCalc`CA^2*Global`v*Global`w + 3*FeynCalc`CA^3*Global`v*
           Global`w - 3*FeynCalc`CA^4*Global`v*Global`w + 
          6*Global`v^2*Global`w + 36*FeynCalc`CA*Global`v^2*Global`w + 
          18*FeynCalc`CA^2*Global`v^2*Global`w - 10*FeynCalc`CA^3*Global`v^2*
           Global`w + 7*FeynCalc`CA^4*Global`v^2*Global`w + 
          Global`v^3*Global`w - 35*FeynCalc`CA*Global`v^3*Global`w - 
          6*FeynCalc`CA^2*Global`v^3*Global`w + 11*FeynCalc`CA^3*Global`v^3*
           Global`w - 5*FeynCalc`CA^4*Global`v^3*Global`w - 
          2*Global`v^4*Global`w + 12*FeynCalc`CA*Global`v^4*Global`w - 
          FeynCalc`CA^2*Global`v^4*Global`w - 4*FeynCalc`CA^3*Global`v^4*
           Global`w + FeynCalc`CA^4*Global`v^4*Global`w + 
          5*Global`v*Global`w^2 + 5*FeynCalc`CA*Global`v*Global`w^2 + 
          10*FeynCalc`CA^2*Global`v*Global`w^2 - FeynCalc`CA^3*Global`v*
           Global`w^2 + 2*FeynCalc`CA^4*Global`v*Global`w^2 - 
          9*Global`v^2*Global`w^2 - 22*FeynCalc`CA*Global`v^2*Global`w^2 - 
          28*FeynCalc`CA^2*Global`v^2*Global`w^2 + 4*FeynCalc`CA^3*Global`v^2*
           Global`w^2 - 13*FeynCalc`CA^4*Global`v^2*Global`w^2 + 
          Global`v^3*Global`w^2 + 31*FeynCalc`CA*Global`v^3*Global`w^2 + 
          17*FeynCalc`CA^2*Global`v^3*Global`w^2 - 5*FeynCalc`CA^3*Global`v^3*
           Global`w^2 + 15*FeynCalc`CA^4*Global`v^3*Global`w^2 + 
          3*Global`v^4*Global`w^2 - 14*FeynCalc`CA*Global`v^4*Global`w^2 + 
          FeynCalc`CA^2*Global`v^4*Global`w^2 + 2*FeynCalc`CA^3*Global`v^4*
           Global`w^2 - 4*FeynCalc`CA^4*Global`v^4*Global`w^2 + 
          Global`v^2*Global`w^3 + 4*FeynCalc`CA*Global`v^2*Global`w^3 + 
          13*FeynCalc`CA^2*Global`v^2*Global`w^3 + 5*FeynCalc`CA^4*Global`v^2*
           Global`w^3 + 3*Global`v^3*Global`w^3 - 12*FeynCalc`CA*Global`v^3*
           Global`w^3 - 16*FeynCalc`CA^2*Global`v^3*Global`w^3 - 
          15*FeynCalc`CA^4*Global`v^3*Global`w^3 - 5*Global`v^4*Global`w^3 + 
          8*FeynCalc`CA*Global`v^4*Global`w^3 + FeynCalc`CA^2*Global`v^4*
           Global`w^3 + 6*FeynCalc`CA^4*Global`v^4*Global`w^3 - 
          2*Global`v^3*Global`w^4 + 2*FeynCalc`CA*Global`v^3*Global`w^4 + 
          4*FeynCalc`CA^2*Global`v^3*Global`w^4 + 5*FeynCalc`CA^4*Global`v^3*
           Global`w^4 + 4*Global`v^4*Global`w^4 - 2*FeynCalc`CA*Global`v^4*
           Global`w^4 - FeynCalc`CA^2*Global`v^4*Global`w^4 - 
          4*FeynCalc`CA^4*Global`v^4*Global`w^4 - Global`v^4*Global`w^5 + 
          FeynCalc`CA^4*Global`v^4*Global`w^5)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v + Global`v*Global`w])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v*
         (-1 + Global`w)*Global`w*(1 - Global`v + Global`v*Global`w)^2)|>|>, 
 "DensityConvention" -> "E_c d sigma/d^(D-1)p_c", 
 "DistributionBasis" -> <|"Variable" -> Global`w, "Endpoint" -> 1, 
   "Interval" -> {0, 1}, "Distance" -> 1 - Global`w|>, 
 "PlusConvention" -> "At each axis, PlusCoefficients[k] multiplies \
[Log[Distance]^k/Distance]_+ on Interval, with subtraction at Endpoint. For \
DistributionBasis[Axes], delta/plus/regular values repeat recursively in the \
listed axis order."|>
