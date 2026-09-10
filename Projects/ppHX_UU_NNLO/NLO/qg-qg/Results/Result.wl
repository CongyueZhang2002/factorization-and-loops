<|"Project" -> "ppHX_UU_NNLO", "Channel" -> "qg-qg", "Scale" -> Global`s, 
 "Variables" -> {Global`v, Global`w}, "Coupling" -> FeynFacet`\[Alpha]s, 
 "CouplingPower" -> 3, "DimensionalPrefactor" -> 
  Global`muR2^(2*Global`Epsilon), "PhysicalChannel" -> 
  <|"Incoming" -> {{"q", "u"}, "g"}, "Observed" -> {"q", "u"}, 
   "Recoil" -> "g"|>, "Polarization" -> <|"Incoming" -> {"U", "U"}, 
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
  <|0 -> <|"DeltaCoefficient" -> 
      ((-63 + 59*FeynCalc`CA^2 + 4*FeynCalc`CA^4 + 10*FeynCalc`CA*Global`nD - 
          10*FeynCalc`CA^3*Global`nD + 10*FeynCalc`CA*Global`nU - 
          10*FeynCalc`CA^3*Global`nU + 9*System`Pi^2 - 12*FeynCalc`CA^2*
           System`Pi^2 + 3*FeynCalc`CA^4*System`Pi^2 + 126*Global`v + 
          17*FeynCalc`CA^2*Global`v + 9*FeynCalc`CA^4*Global`v - 
          20*FeynCalc`CA*Global`nD*Global`v - 20*FeynCalc`CA*Global`nU*
           Global`v - 36*System`Pi^2*Global`v + 15*FeynCalc`CA^2*System`Pi^2*
           Global`v - 126*Global`v^2 + 136*FeynCalc`CA^2*Global`v^2 + 
          26*FeynCalc`CA^4*Global`v^2 + 20*FeynCalc`CA*Global`nD*Global`v^2 - 
          20*FeynCalc`CA^3*Global`nD*Global`v^2 + 20*FeynCalc`CA*Global`nU*
           Global`v^2 - 20*FeynCalc`CA^3*Global`nU*Global`v^2 + 
          63*System`Pi^2*Global`v^2 + 3*FeynCalc`CA^2*System`Pi^2*
           Global`v^2 + 15*FeynCalc`CA^4*System`Pi^2*Global`v^2 + 
          126*Global`v^3 + 17*FeynCalc`CA^2*Global`v^3 + 
          9*FeynCalc`CA^4*Global`v^3 - 20*FeynCalc`CA*Global`nD*Global`v^3 - 
          20*FeynCalc`CA*Global`nU*Global`v^3 - 54*System`Pi^2*Global`v^3 - 
          12*FeynCalc`CA^2*System`Pi^2*Global`v^3 + 18*FeynCalc`CA^4*
           System`Pi^2*Global`v^3 - 63*Global`v^4 + 59*FeynCalc`CA^2*
           Global`v^4 + 4*FeynCalc`CA^4*Global`v^4 + 10*FeynCalc`CA*Global`nD*
           Global`v^4 - 10*FeynCalc`CA^3*Global`nD*Global`v^4 + 
          10*FeynCalc`CA*Global`nU*Global`v^4 - 10*FeynCalc`CA^3*Global`nU*
           Global`v^4 + 18*System`Pi^2*Global`v^4 + 6*FeynCalc`CA^2*
           System`Pi^2*Global`v^4 + 12*FeynCalc`CA^4*System`Pi^2*Global`v^4)*
         FeynFacet`\[Alpha]s^3)/(72*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^2) - (3*(-1 + FeynCalc`CA)*
         (1 + FeynCalc`CA)*(1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 
          2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muFA2])/
        (16*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*
         Global`v^2) + ((11*FeynCalc`CA - 2*Global`nD - 2*Global`nU)*
         (1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
          FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muR2])/(12*FeynCalc`CA^2*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^2) - 
       ((9 + 2*FeynCalc`CA^2 - 2*FeynCalc`CA*Global`nD - 
          2*FeynCalc`CA*Global`nU)*(1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 
          2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(24*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^2) + 
       ((3 + FeynCalc`CA^4 - 10*Global`v - FeynCalc`CA^2*Global`v + 
          2*FeynCalc`CA^4*Global`v + 14*Global`v^2 + 2*FeynCalc`CA^2*
           Global`v^2 + 2*FeynCalc`CA^4*Global`v^2 - 10*Global`v^3 - 
          FeynCalc`CA^2*Global`v^3 + 2*FeynCalc`CA^4*Global`v^3 + 
          3*Global`v^4 + FeynCalc`CA^4*Global`v^4)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v]^2)/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^2) + 
       (-1/24*((-9 + 7*FeynCalc`CA^2 + 2*FeynCalc`CA^4 + 2*FeynCalc`CA*
              Global`nD - 2*FeynCalc`CA^3*Global`nD + 2*FeynCalc`CA*
              Global`nU - 2*FeynCalc`CA^3*Global`nU + 24*Global`v - 
             5*FeynCalc`CA^2*Global`v + 3*FeynCalc`CA^4*Global`v - 
             4*FeynCalc`CA*Global`nD*Global`v - 4*FeynCalc`CA*Global`nU*
              Global`v - 21*Global`v^2 - 19*FeynCalc`CA^2*Global`v^2 + 
             28*FeynCalc`CA^4*Global`v^2 + 4*FeynCalc`CA*Global`nD*
              Global`v^2 - 4*FeynCalc`CA^3*Global`nD*Global`v^2 + 
             4*FeynCalc`CA*Global`nU*Global`v^2 - 4*FeynCalc`CA^3*Global`nU*
              Global`v^2 + 6*Global`v^3 + 28*FeynCalc`CA^2*Global`v^3 - 
             4*FeynCalc`CA*Global`nD*Global`v^3 - 4*FeynCalc`CA*Global`nU*
              Global`v^3 - 11*FeynCalc`CA^2*Global`v^4 + 11*FeynCalc`CA^4*
              Global`v^4 + 2*FeynCalc`CA*Global`nD*Global`v^4 - 
             2*FeynCalc`CA^3*Global`nD*Global`v^4 + 2*FeynCalc`CA*Global`nU*
              Global`v^4 - 2*FeynCalc`CA^3*Global`nU*Global`v^4)*
            FeynFacet`\[Alpha]s^3)/(FeynCalc`CA^3*System`Pi*Global`s^2*
            (-1 + Global`v)^2*Global`v^2) + ((-1 + 3*FeynCalc`CA^2)*
           (1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v^2))*System`Log[Global`v] + 
       ((2 - 12*FeynCalc`CA^2 + 10*FeynCalc`CA^4 - 6*Global`v + 
          21*FeynCalc`CA^2*Global`v + 9*Global`v^2 - 21*FeynCalc`CA^2*
           Global`v^2 + 13*FeynCalc`CA^4*Global`v^2 - 8*Global`v^3 + 
          18*FeynCalc`CA^2*Global`v^3 + 2*FeynCalc`CA^4*Global`v^3 + 
          3*Global`v^4 - 10*FeynCalc`CA^2*Global`v^4 + 3*FeynCalc`CA^4*
           Global`v^4)*FeynFacet`\[Alpha]s^3*System`Log[Global`v]^2)/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^2) + 
       System`Log[Global`muFB2]*
        (-1/24*((11*FeynCalc`CA - 2*Global`nD - 2*Global`nU)*(1 + Global`v^2)*
            (-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
             FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
           (FeynCalc`CA^2*System`Pi*Global`s^2*(-1 + Global`v)^2*
            Global`v^2) + ((1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 
            2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v])/
          (2*FeynCalc`CA*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^2) - 
         ((1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v^2)) + System`Log[Global`muD2]*
        ((-3*(-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(1 + Global`v^2)*
           (-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
          (16*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*
           Global`v^2) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
           (1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v^2)) + System`Log[1 - Global`v]*
        (((4 - FeynCalc`CA^2 + FeynCalc`CA^4 - 8*Global`v - 
            10*FeynCalc`CA^2*Global`v + 10*FeynCalc`CA^4*Global`v + 
            4*Global`v^2 - FeynCalc`CA^2*Global`v^2 + FeynCalc`CA^4*
             Global`v^2)*FeynFacet`\[Alpha]s^3)/(8*FeynCalc`CA^3*System`Pi*
           Global`s^2*(-1 + Global`v)^2*Global`v) - 
         ((1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v^2) - 
         ((-4*FeynCalc`CA^2 + 4*FeynCalc`CA^4 - 2*Global`v + 
            9*FeynCalc`CA^2*Global`v + 5*Global`v^2 - 5*FeynCalc`CA^2*
             Global`v^2 + 5*FeynCalc`CA^4*Global`v^2 - 4*Global`v^3 + 
            6*FeynCalc`CA^2*Global`v^3 + 2*FeynCalc`CA^4*Global`v^3 + 
            Global`v^4 - 2*FeynCalc`CA^2*Global`v^4 + FeynCalc`CA^4*
             Global`v^4)*FeynFacet`\[Alpha]s^3*System`Log[Global`v])/
          (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*
           Global`v^2)), "PlusCoefficients" -> 
      <|0 -> -1/24*((11*FeynCalc`CA - 2*Global`nD - 2*Global`nU)*
            (1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
             FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
           (FeynCalc`CA^2*System`Pi*Global`s^2*(-1 + Global`v)^2*
            Global`v^2) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
           (1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muD2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v^2) - ((-1 + FeynCalc`CA)*
           (1 + FeynCalc`CA)*(1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 
            2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`muFA2])/
          (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*
           Global`v^2) - ((1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 2*Global`v - 
            Global`v^2 + FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFB2])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v^2) + ((-1 + 2*FeynCalc`CA^2)*
           (1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s])/(2*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v^2) - ((1 + Global`v^2)*
           (-1 - 2*FeynCalc`CA^2 + FeynCalc`CA^4 + 2*Global`v + 
            6*FeynCalc`CA^2*Global`v - Global`v^2 - 2*FeynCalc`CA^2*
             Global`v^2 + FeynCalc`CA^4*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[1 - Global`v])/(2*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v^2) + ((1 + Global`v^2)*
           (1 - 5*FeynCalc`CA^2 + 4*FeynCalc`CA^4 - 2*Global`v + 
            8*FeynCalc`CA^2*Global`v + Global`v^2 - 5*FeynCalc`CA^2*
             Global`v^2 + 2*FeynCalc`CA^4*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(2*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2*Global`v^2), 
       1 -> ((-2 + 3*FeynCalc`CA^2)*(1 + Global`v^2)*(-1 + FeynCalc`CA^2 + 
           2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
          FeynFacet`\[Alpha]s^3)/(2*FeynCalc`CA^3*System`Pi*Global`s^2*
          (-1 + Global`v)^2*Global`v^2)|>, "RegularCoefficient" -> 
      -1/24*((12*FeynCalc`CA*Global`v - 36*FeynCalc`CA^3*Global`v - 
           48*FeynCalc`CA*Global`v^2 + 192*FeynCalc`CA^3*Global`v^2 + 
           72*FeynCalc`CA*Global`v^3 - 432*FeynCalc`CA^3*Global`v^3 - 
           48*FeynCalc`CA*Global`v^4 + 528*FeynCalc`CA^3*Global`v^4 + 
           12*FeynCalc`CA*Global`v^5 - 372*FeynCalc`CA^3*Global`v^5 + 
           144*FeynCalc`CA^3*Global`v^6 - 24*FeynCalc`CA^3*Global`v^7 - 
           9*Global`w + 3*FeynCalc`CA*Global`w + 7*FeynCalc`CA^2*Global`w - 
           3*FeynCalc`CA^3*Global`w + 2*FeynCalc`CA^4*Global`w + 
           2*FeynCalc`CA*Global`nD*Global`w - 2*FeynCalc`CA^3*Global`nD*
            Global`w + 2*FeynCalc`CA*Global`nU*Global`w - 
           2*FeynCalc`CA^3*Global`nU*Global`w + 48*Global`v*Global`w - 
           30*FeynCalc`CA*Global`v*Global`w - 24*FeynCalc`CA^2*Global`v*
            Global`w + 54*FeynCalc`CA^3*Global`v*Global`w - 
           24*FeynCalc`CA^4*Global`v*Global`w - 12*FeynCalc`CA*Global`nD*
            Global`v*Global`w + 12*FeynCalc`CA^3*Global`nD*Global`v*
            Global`w - 12*FeynCalc`CA*Global`nU*Global`v*Global`w + 
           12*FeynCalc`CA^3*Global`nU*Global`v*Global`w - 
           132*Global`v^2*Global`w + 84*FeynCalc`CA*Global`v^2*Global`w + 
           64*FeynCalc`CA^2*Global`v^2*Global`w - 204*FeynCalc`CA^3*
            Global`v^2*Global`w + 68*FeynCalc`CA^4*Global`v^2*Global`w + 
           32*FeynCalc`CA*Global`nD*Global`v^2*Global`w - 32*FeynCalc`CA^3*
            Global`nD*Global`v^2*Global`w + 32*FeynCalc`CA*Global`nU*
            Global`v^2*Global`w - 32*FeynCalc`CA^3*Global`nU*Global`v^2*
            Global`w + 228*Global`v^3*Global`w - 72*FeynCalc`CA*Global`v^3*
            Global`w - 132*FeynCalc`CA^2*Global`v^3*Global`w + 
           216*FeynCalc`CA^3*Global`v^3*Global`w - 96*FeynCalc`CA^4*
            Global`v^3*Global`w - 48*FeynCalc`CA*Global`nD*Global`v^3*
            Global`w + 48*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w - 
           48*FeynCalc`CA*Global`nU*Global`v^3*Global`w + 48*FeynCalc`CA^3*
            Global`nU*Global`v^3*Global`w - 237*Global`v^4*Global`w - 
           33*FeynCalc`CA*Global`v^4*Global`w + 159*FeynCalc`CA^2*Global`v^4*
            Global`w + 273*FeynCalc`CA^3*Global`v^4*Global`w + 
           78*FeynCalc`CA^4*Global`v^4*Global`w + 42*FeynCalc`CA*Global`nD*
            Global`v^4*Global`w - 42*FeynCalc`CA^3*Global`nD*Global`v^4*
            Global`w + 42*FeynCalc`CA*Global`nU*Global`v^4*Global`w - 
           42*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w + 
           132*Global`v^5*Global`w + 78*FeynCalc`CA*Global`v^5*Global`w - 
           100*FeynCalc`CA^2*Global`v^5*Global`w - 918*FeynCalc`CA^3*
            Global`v^5*Global`w - 32*FeynCalc`CA^4*Global`v^5*Global`w - 
           20*FeynCalc`CA*Global`nD*Global`v^5*Global`w + 20*FeynCalc`CA^3*
            Global`nD*Global`v^5*Global`w - 20*FeynCalc`CA*Global`nU*
            Global`v^5*Global`w + 20*FeynCalc`CA^3*Global`nU*Global`v^5*
            Global`w - 30*Global`v^6*Global`w - 30*FeynCalc`CA*Global`v^6*
            Global`w + 26*FeynCalc`CA^2*Global`v^6*Global`w + 
           966*FeynCalc`CA^3*Global`v^6*Global`w + 4*FeynCalc`CA^4*Global`v^6*
            Global`w + 4*FeynCalc`CA*Global`nD*Global`v^6*Global`w - 
           4*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w + 
           4*FeynCalc`CA*Global`nU*Global`v^6*Global`w - 4*FeynCalc`CA^3*
            Global`nU*Global`v^6*Global`w - 480*FeynCalc`CA^3*Global`v^7*
            Global`w + 96*FeynCalc`CA^3*Global`v^8*Global`w - 
           3*FeynCalc`CA*Global`w^2 + 6*FeynCalc`CA^2*Global`w^2 + 
           3*FeynCalc`CA^3*Global`w^2 - 6*FeynCalc`CA^4*Global`w^2 + 
           27*Global`v*Global`w^2 + 18*FeynCalc`CA*Global`v*Global`w^2 - 
           29*FeynCalc`CA^2*Global`v*Global`w^2 - 6*FeynCalc`CA^3*Global`v*
            Global`w^2 + 14*FeynCalc`CA^4*Global`v*Global`w^2 - 
           4*FeynCalc`CA*Global`nD*Global`v*Global`w^2 + 4*FeynCalc`CA^3*
            Global`nD*Global`v*Global`w^2 - 4*FeynCalc`CA*Global`nU*Global`v*
            Global`w^2 + 4*FeynCalc`CA^3*Global`nU*Global`v*Global`w^2 - 
           129*Global`v^2*Global`w^2 - 12*FeynCalc`CA*Global`v^2*Global`w^2 + 
           16*FeynCalc`CA^2*Global`v^2*Global`w^2 - 66*FeynCalc`CA^3*
            Global`v^2*Global`w^2 - 47*FeynCalc`CA^4*Global`v^2*Global`w^2 + 
           20*FeynCalc`CA*Global`nD*Global`v^2*Global`w^2 + 
           2*FeynCalc`CA^3*Global`nD*Global`v^2*Global`w^2 + 
           20*FeynCalc`CA*Global`nU*Global`v^2*Global`w^2 + 
           2*FeynCalc`CA^3*Global`nU*Global`v^2*Global`w^2 + 
           243*Global`v^3*Global`w^2 - 150*FeynCalc`CA*Global`v^3*
            Global`w^2 + 67*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
           504*FeynCalc`CA^3*Global`v^3*Global`w^2 + 144*FeynCalc`CA^4*
            Global`v^3*Global`w^2 - 34*FeynCalc`CA*Global`nD*Global`v^3*
            Global`w^2 - 54*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^2 - 
           34*FeynCalc`CA*Global`nU*Global`v^3*Global`w^2 - 
           54*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^2 - 
           285*Global`v^4*Global`w^2 + 387*FeynCalc`CA*Global`v^4*
            Global`w^2 - 53*FeynCalc`CA^2*Global`v^4*Global`w^2 - 
           1365*FeynCalc`CA^3*Global`v^4*Global`w^2 - 296*FeynCalc`CA^4*
            Global`v^4*Global`w^2 + 14*FeynCalc`CA*Global`nD*Global`v^4*
            Global`w^2 + 146*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^2 + 
           14*FeynCalc`CA*Global`nU*Global`v^4*Global`w^2 + 
           146*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^2 + 
           282*Global`v^5*Global`w^2 - 336*FeynCalc`CA*Global`v^5*
            Global`w^2 - 82*FeynCalc`CA^2*Global`v^5*Global`w^2 + 
           1698*FeynCalc`CA^3*Global`v^5*Global`w^2 + 354*FeynCalc`CA^4*
            Global`v^5*Global`w^2 + 22*FeynCalc`CA*Global`nD*Global`v^5*
            Global`w^2 - 186*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^2 + 
           22*FeynCalc`CA*Global`nU*Global`v^5*Global`w^2 - 
           186*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^2 - 
           198*Global`v^6*Global`w^2 + 84*FeynCalc`CA*Global`v^6*Global`w^2 + 
           131*FeynCalc`CA^2*Global`v^6*Global`w^2 - 780*FeynCalc`CA^3*
            Global`v^6*Global`w^2 - 227*FeynCalc`CA^4*Global`v^6*Global`w^2 - 
           26*FeynCalc`CA*Global`nD*Global`v^6*Global`w^2 + 
           116*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^2 - 
           26*FeynCalc`CA*Global`nU*Global`v^6*Global`w^2 + 
           116*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^2 + 
           60*Global`v^7*Global`w^2 + 12*FeynCalc`CA*Global`v^7*Global`w^2 - 
           56*FeynCalc`CA^2*Global`v^7*Global`w^2 - 324*FeynCalc`CA^3*
            Global`v^7*Global`w^2 + 64*FeynCalc`CA^4*Global`v^7*Global`w^2 + 
           8*FeynCalc`CA*Global`nD*Global`v^7*Global`w^2 - 
           28*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^2 + 
           8*FeynCalc`CA*Global`nU*Global`v^7*Global`w^2 - 
           28*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^2 + 
           480*FeynCalc`CA^3*Global`v^8*Global`w^2 - 144*FeynCalc`CA^3*
            Global`v^9*Global`w^2 + 6*FeynCalc`CA*Global`v*Global`w^3 - 
           12*FeynCalc`CA^2*Global`v*Global`w^3 - 6*FeynCalc`CA^3*Global`v*
            Global`w^3 + 12*FeynCalc`CA^4*Global`v*Global`w^3 - 
           9*Global`v^2*Global`w^3 - 57*FeynCalc`CA*Global`v^2*Global`w^3 + 
           35*FeynCalc`CA^2*Global`v^2*Global`w^3 + 33*FeynCalc`CA^3*
            Global`v^2*Global`w^3 - 50*FeynCalc`CA^4*Global`v^2*Global`w^3 - 
           2*FeynCalc`CA*Global`nD*Global`v^2*Global`w^3 + 
           2*FeynCalc`CA^3*Global`nD*Global`v^2*Global`w^3 - 
           2*FeynCalc`CA*Global`nU*Global`v^2*Global`w^3 + 
           2*FeynCalc`CA^3*Global`nU*Global`v^2*Global`w^3 + 
           144*Global`v^3*Global`w^3 + 228*FeynCalc`CA*Global`v^3*
            Global`w^3 - 13*FeynCalc`CA^2*Global`v^3*Global`w^3 - 
           114*FeynCalc`CA^3*Global`v^3*Global`w^3 - 29*FeynCalc`CA^4*
            Global`v^3*Global`w^3 - 20*FeynCalc`CA*Global`nD*Global`v^3*
            Global`w^3 + 38*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^3 - 
           20*FeynCalc`CA*Global`nU*Global`v^3*Global`w^3 + 
           38*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^3 - 
           378*Global`v^4*Global`w^3 - 330*FeynCalc`CA*Global`v^4*
            Global`w^3 - 151*FeynCalc`CA^2*Global`v^4*Global`w^3 + 
           78*FeynCalc`CA^3*Global`v^4*Global`w^3 + 413*FeynCalc`CA^4*
            Global`v^4*Global`w^3 + 190*FeynCalc`CA*Global`nD*Global`v^4*
            Global`w^3 - 242*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^3 + 
           190*FeynCalc`CA*Global`nU*Global`v^4*Global`w^3 - 
           242*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^3 + 
           384*Global`v^5*Global`w^3 + 66*FeynCalc`CA*Global`v^5*Global`w^3 + 
           227*FeynCalc`CA^2*Global`v^5*Global`w^3 + 624*FeynCalc`CA^3*
            Global`v^5*Global`w^3 - 871*FeynCalc`CA^4*Global`v^5*Global`w^3 - 
           512*FeynCalc`CA*Global`nD*Global`v^5*Global`w^3 + 
           568*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^3 - 
           512*FeynCalc`CA*Global`nU*Global`v^5*Global`w^3 + 
           568*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^3 - 
           225*Global`v^6*Global`w^3 + 183*FeynCalc`CA*Global`v^6*
            Global`w^3 - 76*FeynCalc`CA^2*Global`v^6*Global`w^3 - 
           1815*FeynCalc`CA^3*Global`v^6*Global`w^3 + 817*FeynCalc`CA^4*
            Global`v^6*Global`w^3 + 616*FeynCalc`CA*Global`nD*Global`v^6*
            Global`w^3 - 604*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^3 + 
           616*FeynCalc`CA*Global`nU*Global`v^6*Global`w^3 - 
           604*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^3 + 
           144*Global`v^7*Global`w^3 - 84*FeynCalc`CA*Global`v^7*Global`w^3 - 
           58*FeynCalc`CA^2*Global`v^7*Global`w^3 + 2052*FeynCalc`CA^3*
            Global`v^7*Global`w^3 - 328*FeynCalc`CA^4*Global`v^7*Global`w^3 - 
           344*FeynCalc`CA*Global`nD*Global`v^7*Global`w^3 + 
           286*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^3 - 
           344*FeynCalc`CA*Global`nU*Global`v^7*Global`w^3 + 
           286*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^3 - 
           60*Global`v^8*Global`w^3 - 12*FeynCalc`CA*Global`v^8*Global`w^3 + 
           60*FeynCalc`CA^2*Global`v^8*Global`w^3 - 948*FeynCalc`CA^3*
            Global`v^8*Global`w^3 + 24*FeynCalc`CA^4*Global`v^8*Global`w^3 + 
           72*FeynCalc`CA*Global`nD*Global`v^8*Global`w^3 - 
           48*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^3 + 
           72*FeynCalc`CA*Global`nU*Global`v^8*Global`w^3 - 
           48*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^3 + 
           96*FeynCalc`CA^3*Global`v^10*Global`w^3 + 3*FeynCalc`CA*Global`v^2*
            Global`w^4 - 6*FeynCalc`CA^2*Global`v^2*Global`w^4 - 
           3*FeynCalc`CA^3*Global`v^2*Global`w^4 + 6*FeynCalc`CA^4*Global`v^2*
            Global`w^4 - 45*Global`v^3*Global`w^4 + 6*FeynCalc`CA*Global`v^3*
            Global`w^4 + 7*FeynCalc`CA^2*Global`v^3*Global`w^4 - 
           18*FeynCalc`CA^3*Global`v^3*Global`w^4 + 26*FeynCalc`CA^4*
            Global`v^3*Global`w^4 + 8*FeynCalc`CA*Global`nD*Global`v^3*
            Global`w^4 - 8*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^4 + 
           8*FeynCalc`CA*Global`nU*Global`v^3*Global`w^4 - 
           8*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^4 + 
           51*Global`v^4*Global`w^4 - 183*FeynCalc`CA*Global`v^4*Global`w^4 + 
           83*FeynCalc`CA^2*Global`v^4*Global`w^4 + 183*FeynCalc`CA^3*
            Global`v^4*Global`w^4 - 184*FeynCalc`CA^4*Global`v^4*Global`w^4 - 
           128*FeynCalc`CA*Global`nD*Global`v^4*Global`w^4 + 
           112*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^4 - 
           128*FeynCalc`CA*Global`nU*Global`v^4*Global`w^4 + 
           112*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^4 + 
           213*Global`v^5*Global`w^4 + 525*FeynCalc`CA*Global`v^5*
            Global`w^4 - 87*FeynCalc`CA^2*Global`v^5*Global`w^4 - 
           597*FeynCalc`CA^3*Global`v^5*Global`w^4 + 644*FeynCalc`CA^4*
            Global`v^5*Global`w^4 + 558*FeynCalc`CA*Global`nD*Global`v^5*
            Global`w^4 - 530*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^4 + 
           558*FeynCalc`CA*Global`nU*Global`v^5*Global`w^4 - 
           530*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^4 - 
           423*Global`v^6*Global`w^4 - 549*FeynCalc`CA*Global`v^6*
            Global`w^4 - FeynCalc`CA^2*Global`v^6*Global`w^4 + 
           993*FeynCalc`CA^3*Global`v^6*Global`w^4 - 1086*FeynCalc`CA^4*
            Global`v^6*Global`w^4 - 974*FeynCalc`CA*Global`nD*Global`v^6*
            Global`w^4 + 936*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^4 - 
           974*FeynCalc`CA*Global`nU*Global`v^6*Global`w^4 + 
           936*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^4 + 
           288*Global`v^7*Global`w^4 + 282*FeynCalc`CA*Global`v^7*
            Global`w^4 - 52*FeynCalc`CA^2*Global`v^7*Global`w^4 - 
           678*FeynCalc`CA^3*Global`v^7*Global`w^4 + 856*FeynCalc`CA^4*
            Global`v^7*Global`w^4 + 748*FeynCalc`CA*Global`nD*Global`v^7*
            Global`w^4 - 724*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^4 + 
           748*FeynCalc`CA*Global`nU*Global`v^7*Global`w^4 - 
           724*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^4 - 
           144*Global`v^8*Global`w^4 - 156*FeynCalc`CA*Global`v^8*
            Global`w^4 + 52*FeynCalc`CA^2*Global`v^8*Global`w^4 - 
           312*FeynCalc`CA^3*Global`v^8*Global`w^4 - 310*FeynCalc`CA^4*
            Global`v^8*Global`w^4 - 220*FeynCalc`CA*Global`nD*Global`v^8*
            Global`w^4 + 250*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^4 - 
           220*FeynCalc`CA*Global`nU*Global`v^8*Global`w^4 + 
           250*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^4 + 
           60*Global`v^9*Global`w^4 + 72*FeynCalc`CA*Global`v^9*Global`w^4 - 
           56*FeynCalc`CA^2*Global`v^9*Global`w^4 + 696*FeynCalc`CA^3*
            Global`v^9*Global`w^4 + 64*FeynCalc`CA^4*Global`v^9*Global`w^4 + 
           8*FeynCalc`CA*Global`nD*Global`v^9*Global`w^4 - 
           28*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^4 + 
           8*FeynCalc`CA*Global`nU*Global`v^9*Global`w^4 - 
           28*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^4 - 
           240*FeynCalc`CA^3*Global`v^10*Global`w^4 - 24*FeynCalc`CA^3*
            Global`v^11*Global`w^4 - 12*FeynCalc`CA*Global`v^3*Global`w^5 + 
           24*FeynCalc`CA^2*Global`v^3*Global`w^5 + 12*FeynCalc`CA^3*
            Global`v^3*Global`w^5 - 24*FeynCalc`CA^4*Global`v^3*Global`w^5 + 
           45*Global`v^4*Global`w^5 + 81*FeynCalc`CA*Global`v^4*Global`w^5 - 
           43*FeynCalc`CA^2*Global`v^4*Global`w^5 - 33*FeynCalc`CA^3*
            Global`v^4*Global`w^5 + 46*FeynCalc`CA^4*Global`v^4*Global`w^5 - 
           2*FeynCalc`CA*Global`nD*Global`v^4*Global`w^5 + 
           2*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^5 - 
           2*FeynCalc`CA*Global`nU*Global`v^4*Global`w^5 + 
           2*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^5 - 
           216*Global`v^5*Global`w^5 - 144*FeynCalc`CA*Global`v^5*
            Global`w^5 - 114*FeynCalc`CA^2*Global`v^5*Global`w^5 - 
           24*FeynCalc`CA^3*Global`v^5*Global`w^5 - 58*FeynCalc`CA^4*
            Global`v^5*Global`w^5 - 132*FeynCalc`CA*Global`nD*Global`v^5*
            Global`w^5 + 136*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^5 - 
           132*FeynCalc`CA*Global`nU*Global`v^5*Global`w^5 + 
           136*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^5 + 
           264*Global`v^6*Global`w^5 + 54*FeynCalc`CA*Global`v^6*Global`w^5 + 
           210*FeynCalc`CA^2*Global`v^6*Global`w^5 + 138*FeynCalc`CA^3*
            Global`v^6*Global`w^5 + 478*FeynCalc`CA^4*Global`v^6*Global`w^5 + 
           492*FeynCalc`CA*Global`nD*Global`v^6*Global`w^5 - 
           532*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^5 + 
           492*FeynCalc`CA*Global`nU*Global`v^6*Global`w^5 - 
           532*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^5 - 
           132*Global`v^7*Global`w^5 - 48*FeynCalc`CA*Global`v^7*Global`w^5 + 
           24*FeynCalc`CA^2*Global`v^7*Global`w^5 - 348*FeynCalc`CA^3*
            Global`v^7*Global`w^5 - 850*FeynCalc`CA^4*Global`v^7*Global`w^5 - 
           612*FeynCalc`CA*Global`nD*Global`v^7*Global`w^5 + 
           706*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^5 - 
           612*FeynCalc`CA*Global`nU*Global`v^7*Global`w^5 + 
           706*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^5 + 
           81*Global`v^8*Global`w^5 + 93*FeynCalc`CA*Global`v^8*Global`w^5 - 
           41*FeynCalc`CA^2*Global`v^8*Global`w^5 + 819*FeynCalc`CA^3*
            Global`v^8*Global`w^5 + 620*FeynCalc`CA^4*Global`v^8*Global`w^5 + 
           302*FeynCalc`CA*Global`nD*Global`v^8*Global`w^5 - 
           434*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^5 + 
           302*FeynCalc`CA*Global`nU*Global`v^8*Global`w^5 - 
           434*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^5 - 
           12*Global`v^9*Global`w^5 + 54*FeynCalc`CA*Global`v^9*Global`w^5 + 
           46*FeynCalc`CA^2*Global`v^9*Global`w^5 - 810*FeynCalc`CA^3*
            Global`v^9*Global`w^5 - 216*FeynCalc`CA^4*Global`v^9*Global`w^5 - 
           52*FeynCalc`CA*Global`nD*Global`v^9*Global`w^5 + 
           102*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^5 - 
           52*FeynCalc`CA*Global`nU*Global`v^9*Global`w^5 + 
           102*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^5 - 
           30*Global`v^10*Global`w^5 - 78*FeynCalc`CA*Global`v^10*
            Global`w^5 + 26*FeynCalc`CA^2*Global`v^10*Global`w^5 + 
           150*FeynCalc`CA^3*Global`v^10*Global`w^5 + 4*FeynCalc`CA^4*
            Global`v^10*Global`w^5 + 4*FeynCalc`CA*Global`nD*Global`v^10*
            Global`w^5 - 4*FeynCalc`CA^3*Global`nD*Global`v^10*Global`w^5 + 
           4*FeynCalc`CA*Global`nU*Global`v^10*Global`w^5 - 
           4*FeynCalc`CA^3*Global`nU*Global`v^10*Global`w^5 + 
           96*FeynCalc`CA^3*Global`v^11*Global`w^5 + 3*FeynCalc`CA*Global`v^4*
            Global`w^6 - 6*FeynCalc`CA^2*Global`v^4*Global`w^6 - 
           3*FeynCalc`CA^3*Global`v^4*Global`w^6 + 6*FeynCalc`CA^4*Global`v^4*
            Global`w^6 + 9*Global`v^5*Global`w^6 - 42*FeynCalc`CA*Global`v^5*
            Global`w^6 + 25*FeynCalc`CA^2*Global`v^5*Global`w^6 + 
           30*FeynCalc`CA^3*Global`v^5*Global`w^6 - 46*FeynCalc`CA^4*
            Global`v^5*Global`w^6 - 4*FeynCalc`CA*Global`nD*Global`v^5*
            Global`w^6 + 4*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^6 - 
           4*FeynCalc`CA*Global`nU*Global`v^5*Global`w^6 + 
           4*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^6 + 
           69*Global`v^6*Global`w^6 + 132*FeynCalc`CA*Global`v^6*Global`w^6 + 
           58*FeynCalc`CA^2*Global`v^6*Global`w^6 - 18*FeynCalc`CA^3*
            Global`v^6*Global`w^6 - 179*FeynCalc`CA^4*Global`v^6*Global`w^6 - 
           76*FeynCalc`CA*Global`nD*Global`v^6*Global`w^6 + 
           98*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^6 - 
           76*FeynCalc`CA*Global`nU*Global`v^6*Global`w^6 + 
           98*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^6 - 
           123*Global`v^7*Global`w^6 - 114*FeynCalc`CA*Global`v^7*
            Global`w^6 - 215*FeynCalc`CA^2*Global`v^7*Global`w^6 + 
           12*FeynCalc`CA^3*Global`v^7*Global`w^6 + 540*FeynCalc`CA^4*
            Global`v^7*Global`w^6 + 218*FeynCalc`CA*Global`nD*Global`v^7*
            Global`w^6 - 282*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^6 + 
           218*FeynCalc`CA*Global`nU*Global`v^7*Global`w^6 - 
           282*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^6 + 
           81*Global`v^8*Global`w^6 + 165*FeynCalc`CA*Global`v^8*Global`w^6 + 
           31*FeynCalc`CA^2*Global`v^8*Global`w^6 - 339*FeynCalc`CA^3*
            Global`v^8*Global`w^6 - 600*FeynCalc`CA^4*Global`v^8*Global`w^6 - 
           214*FeynCalc`CA*Global`nD*Global`v^8*Global`w^6 + 
           324*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^6 - 
           214*FeynCalc`CA*Global`nU*Global`v^8*Global`w^6 + 
           324*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^6 - 
           114*Global`v^9*Global`w^6 - 312*FeynCalc`CA*Global`v^9*
            Global`w^6 - 2*FeynCalc`CA^2*Global`v^9*Global`w^6 + 
           426*FeynCalc`CA^3*Global`v^9*Global`w^6 + 334*FeynCalc`CA^4*
            Global`v^9*Global`w^6 + 86*FeynCalc`CA*Global`nD*Global`v^9*
            Global`w^6 - 130*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^6 + 
           86*FeynCalc`CA*Global`nU*Global`v^9*Global`w^6 - 
           130*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^6 + 
           78*Global`v^10*Global`w^6 + 144*FeynCalc`CA*Global`v^10*
            Global`w^6 - 71*FeynCalc`CA^2*Global`v^10*Global`w^6 + 
           60*FeynCalc`CA^3*Global`v^10*Global`w^6 - 7*FeynCalc`CA^4*
            Global`v^10*Global`w^6 - 10*FeynCalc`CA*Global`nD*Global`v^10*
            Global`w^6 + 10*FeynCalc`CA^3*Global`nD*Global`v^10*Global`w^6 - 
           10*FeynCalc`CA*Global`nU*Global`v^10*Global`w^6 + 
           10*FeynCalc`CA^3*Global`nU*Global`v^10*Global`w^6 + 
           24*FeynCalc`CA*Global`v^11*Global`w^6 - 168*FeynCalc`CA^3*
            Global`v^11*Global`w^6 + 6*FeynCalc`CA*Global`v^5*Global`w^7 - 
           12*FeynCalc`CA^2*Global`v^5*Global`w^7 - 6*FeynCalc`CA^3*
            Global`v^5*Global`w^7 + 12*FeynCalc`CA^4*Global`v^5*Global`w^7 - 
           27*Global`v^6*Global`w^7 - 27*FeynCalc`CA*Global`v^6*Global`w^7 + 
           FeynCalc`CA^2*Global`v^6*Global`w^7 + 3*FeynCalc`CA^3*Global`v^6*
            Global`w^7 + 2*FeynCalc`CA^4*Global`v^6*Global`w^7 + 
           2*FeynCalc`CA*Global`nD*Global`v^6*Global`w^7 - 
           2*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^7 + 
           2*FeynCalc`CA*Global`nU*Global`v^6*Global`w^7 - 
           2*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^7 + 
           24*Global`v^7*Global`w^7 + 24*FeynCalc`CA*Global`v^7*Global`w^7 + 
           31*FeynCalc`CA^2*Global`v^7*Global`w^7 - 6*FeynCalc`CA^3*
            Global`v^7*Global`w^7 - 89*FeynCalc`CA^4*Global`v^7*Global`w^7 - 
           28*FeynCalc`CA*Global`nD*Global`v^7*Global`w^7 + 
           38*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^7 - 
           28*FeynCalc`CA*Global`nU*Global`v^7*Global`w^7 + 
           38*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^7 - 
           42*Global`v^8*Global`w^7 - 114*FeynCalc`CA*Global`v^8*Global`w^7 + 
           89*FeynCalc`CA^2*Global`v^8*Global`w^7 + 174*FeynCalc`CA^3*
            Global`v^8*Global`w^7 + 205*FeynCalc`CA^4*Global`v^8*Global`w^7 + 
           70*FeynCalc`CA*Global`nD*Global`v^8*Global`w^7 - 
           106*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^7 + 
           70*FeynCalc`CA*Global`nU*Global`v^8*Global`w^7 - 
           106*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^7 + 
           120*Global`v^9*Global`w^7 + 210*FeynCalc`CA*Global`v^9*
            Global`w^7 - 23*FeynCalc`CA^2*Global`v^9*Global`w^7 - 
           180*FeynCalc`CA^3*Global`v^9*Global`w^7 - 247*FeynCalc`CA^4*
            Global`v^9*Global`w^7 - 52*FeynCalc`CA*Global`nD*Global`v^9*
            Global`w^7 + 70*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^7 - 
           52*FeynCalc`CA*Global`nU*Global`v^9*Global`w^7 + 
           70*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^7 - 
           75*Global`v^10*Global`w^7 - 27*FeynCalc`CA*Global`v^10*
            Global`w^7 + 94*FeynCalc`CA^2*Global`v^10*Global`w^7 - 
           165*FeynCalc`CA^3*Global`v^10*Global`w^7 - 19*FeynCalc`CA^4*
            Global`v^10*Global`w^7 + 8*FeynCalc`CA*Global`nD*Global`v^10*
            Global`w^7 - 8*FeynCalc`CA^3*Global`nD*Global`v^10*Global`w^7 + 
           8*FeynCalc`CA*Global`nU*Global`v^10*Global`w^7 - 
           8*FeynCalc`CA^3*Global`nU*Global`v^10*Global`w^7 - 
           72*FeynCalc`CA*Global`v^11*Global`w^7 + 180*FeynCalc`CA^3*
            Global`v^11*Global`w^7 - 3*FeynCalc`CA*Global`v^6*Global`w^8 + 
           6*FeynCalc`CA^2*Global`v^6*Global`w^8 + 3*FeynCalc`CA^3*Global`v^6*
            Global`w^8 - 6*FeynCalc`CA^4*Global`v^6*Global`w^8 + 
           9*Global`v^7*Global`w^8 + 18*FeynCalc`CA*Global`v^7*Global`w^8 - 
           3*FeynCalc`CA^2*Global`v^7*Global`w^8 - 6*FeynCalc`CA^3*Global`v^7*
            Global`w^8 + 6*FeynCalc`CA^4*Global`v^7*Global`w^8 + 
           9*Global`v^8*Global`w^8 - 3*FeynCalc`CA*Global`v^8*Global`w^8 - 
           49*FeynCalc`CA^2*Global`v^8*Global`w^8 - 33*FeynCalc`CA^3*
            Global`v^8*Global`w^8 - 18*FeynCalc`CA^4*Global`v^8*Global`w^8 - 
           8*FeynCalc`CA*Global`nD*Global`v^8*Global`w^8 + 
           12*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^8 - 
           8*FeynCalc`CA*Global`nU*Global`v^8*Global`w^8 + 
           12*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^8 - 
           45*Global`v^9*Global`w^8 - 15*FeynCalc`CA*Global`v^9*Global`w^8 - 
           13*FeynCalc`CA^2*Global`v^9*Global`w^8 + 3*FeynCalc`CA^3*
            Global`v^9*Global`w^8 + 104*FeynCalc`CA^4*Global`v^9*Global`w^8 + 
           10*FeynCalc`CA*Global`nD*Global`v^9*Global`w^8 - 
           14*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^8 + 
           10*FeynCalc`CA*Global`nU*Global`v^9*Global`w^8 - 
           14*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^8 + 
           27*Global`v^10*Global`w^8 - 75*FeynCalc`CA*Global`v^10*
            Global`w^8 - 73*FeynCalc`CA^2*Global`v^10*Global`w^8 + 
           159*FeynCalc`CA^3*Global`v^10*Global`w^8 + 46*FeynCalc`CA^4*
            Global`v^10*Global`w^8 - 2*FeynCalc`CA*Global`nD*Global`v^10*
            Global`w^8 + 2*FeynCalc`CA^3*Global`nD*Global`v^10*Global`w^8 - 
           2*FeynCalc`CA*Global`nU*Global`v^10*Global`w^8 + 
           2*FeynCalc`CA^3*Global`nU*Global`v^10*Global`w^8 + 
           78*FeynCalc`CA*Global`v^11*Global`w^8 - 126*FeynCalc`CA^3*
            Global`v^11*Global`w^8 - 6*FeynCalc`CA*Global`v^9*Global`w^9 + 
           24*FeynCalc`CA^2*Global`v^9*Global`w^9 + 18*FeynCalc`CA^3*
            Global`v^9*Global`w^9 - 24*FeynCalc`CA^4*Global`v^9*Global`w^9 + 
           42*FeynCalc`CA*Global`v^10*Global`w^9 + 36*FeynCalc`CA^2*
            Global`v^10*Global`w^9 - 66*FeynCalc`CA^3*Global`v^10*
            Global`w^9 - 36*FeynCalc`CA^4*Global`v^10*Global`w^9 - 
           36*FeynCalc`CA*Global`v^11*Global`w^9 + 48*FeynCalc`CA^3*
            Global`v^11*Global`w^9 - 6*FeynCalc`CA*Global`v^10*Global`w^10 - 
           12*FeynCalc`CA^2*Global`v^10*Global`w^10 + 6*FeynCalc`CA^3*
            Global`v^10*Global`w^10 + 12*FeynCalc`CA^4*Global`v^10*
            Global`w^10 + 6*FeynCalc`CA*Global`v^11*Global`w^10 - 
           6*FeynCalc`CA^3*Global`v^11*Global`w^10)*FeynFacet`\[Alpha]s^3)/
         (FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^2*
          Global`w^2*(-1 + Global`v*Global`w)^4*
          (1 - Global`v + Global`v*Global`w)^2) + 
       ((-4*FeynCalc`CA^3 + 28*FeynCalc`CA^3*Global`v - 88*FeynCalc`CA^3*
           Global`v^2 + 160*FeynCalc`CA^3*Global`v^3 - 180*FeynCalc`CA^3*
           Global`v^4 + 124*FeynCalc`CA^3*Global`v^5 - 48*FeynCalc`CA^3*
           Global`v^6 + 8*FeynCalc`CA^3*Global`v^7 - 2*Global`w + 
          4*FeynCalc`CA^2*Global`w - 2*FeynCalc`CA^4*Global`w + 
          10*Global`v*Global`w - 20*FeynCalc`CA^2*Global`v*Global`w - 
          16*FeynCalc`CA^3*Global`v*Global`w + 10*FeynCalc`CA^4*Global`v*
           Global`w - 21*Global`v^2*Global`w + 42*FeynCalc`CA^2*Global`v^2*
           Global`w + 104*FeynCalc`CA^3*Global`v^2*Global`w - 
          21*FeynCalc`CA^4*Global`v^2*Global`w + 24*Global`v^3*Global`w - 
          48*FeynCalc`CA^2*Global`v^3*Global`w - 288*FeynCalc`CA^3*Global`v^3*
           Global`w + 24*FeynCalc`CA^4*Global`v^3*Global`w - 
          16*Global`v^4*Global`w + 32*FeynCalc`CA^2*Global`v^4*Global`w + 
          432*FeynCalc`CA^3*Global`v^4*Global`w - 16*FeynCalc`CA^4*Global`v^4*
           Global`w + 6*Global`v^5*Global`w - 12*FeynCalc`CA^2*Global`v^5*
           Global`w - 368*FeynCalc`CA^3*Global`v^5*Global`w + 
          6*FeynCalc`CA^4*Global`v^5*Global`w - Global`v^6*Global`w + 
          2*FeynCalc`CA^2*Global`v^6*Global`w + 168*FeynCalc`CA^3*Global`v^6*
           Global`w - FeynCalc`CA^4*Global`v^6*Global`w - 
          32*FeynCalc`CA^3*Global`v^7*Global`w - 4*Global`v*Global`w^2 + 
          8*FeynCalc`CA^2*Global`v*Global`w^2 - 4*FeynCalc`CA^4*Global`v*
           Global`w^2 + 19*Global`v^2*Global`w^2 + 2*FeynCalc`CA*Global`v^2*
           Global`w^2 - 46*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          32*FeynCalc`CA^3*Global`v^2*Global`w^2 + 27*FeynCalc`CA^4*
           Global`v^2*Global`w^2 - 38*Global`v^3*Global`w^2 - 
          10*FeynCalc`CA*Global`v^3*Global`w^2 + 94*FeynCalc`CA^2*Global`v^3*
           Global`w^2 + 176*FeynCalc`CA^3*Global`v^3*Global`w^2 - 
          56*FeynCalc`CA^4*Global`v^3*Global`w^2 + 40*Global`v^4*Global`w^2 + 
          22*FeynCalc`CA*Global`v^4*Global`w^2 - 94*FeynCalc`CA^2*Global`v^4*
           Global`w^2 - 392*FeynCalc`CA^3*Global`v^4*Global`w^2 + 
          54*FeynCalc`CA^4*Global`v^4*Global`w^2 - 22*Global`v^5*Global`w^2 - 
          26*FeynCalc`CA*Global`v^5*Global`w^2 + 50*FeynCalc`CA^2*Global`v^5*
           Global`w^2 + 440*FeynCalc`CA^3*Global`v^5*Global`w^2 - 
          28*FeynCalc`CA^4*Global`v^5*Global`w^2 + 5*Global`v^6*Global`w^2 + 
          16*FeynCalc`CA*Global`v^6*Global`w^2 - 12*FeynCalc`CA^2*Global`v^6*
           Global`w^2 - 248*FeynCalc`CA^3*Global`v^6*Global`w^2 + 
          7*FeynCalc`CA^4*Global`v^6*Global`w^2 - 4*FeynCalc`CA*Global`v^7*
           Global`w^2 + 56*FeynCalc`CA^3*Global`v^7*Global`w^2 - 
          2*Global`v^2*Global`w^3 + 4*FeynCalc`CA^2*Global`v^2*Global`w^3 - 
          2*FeynCalc`CA^4*Global`v^2*Global`w^3 + 10*Global`v^3*Global`w^3 + 
          6*FeynCalc`CA*Global`v^3*Global`w^3 - 46*FeynCalc`CA^2*Global`v^3*
           Global`w^3 - 36*FeynCalc`CA^3*Global`v^3*Global`w^3 + 
          36*FeynCalc`CA^4*Global`v^3*Global`w^3 - 20*Global`v^4*Global`w^3 - 
          28*FeynCalc`CA*Global`v^4*Global`w^3 + 84*FeynCalc`CA^2*Global`v^4*
           Global`w^3 + 160*FeynCalc`CA^3*Global`v^4*Global`w^3 - 
          64*FeynCalc`CA^4*Global`v^4*Global`w^3 + 18*Global`v^5*Global`w^3 + 
          50*FeynCalc`CA*Global`v^5*Global`w^3 - 62*FeynCalc`CA^2*Global`v^5*
           Global`w^3 - 268*FeynCalc`CA^3*Global`v^5*Global`w^3 + 
          44*FeynCalc`CA^4*Global`v^5*Global`w^3 - 6*Global`v^6*Global`w^3 - 
          40*FeynCalc`CA*Global`v^6*Global`w^3 + 20*FeynCalc`CA^2*Global`v^6*
           Global`w^3 + 200*FeynCalc`CA^3*Global`v^6*Global`w^3 - 
          14*FeynCalc`CA^4*Global`v^6*Global`w^3 + 12*FeynCalc`CA*Global`v^7*
           Global`w^3 - 56*FeynCalc`CA^3*Global`v^7*Global`w^3 + 
          2*Global`v^4*Global`w^4 + 9*FeynCalc`CA*Global`v^4*Global`w^4 - 
          34*FeynCalc`CA^2*Global`v^4*Global`w^4 - 25*FeynCalc`CA^3*
           Global`v^4*Global`w^4 + 32*FeynCalc`CA^4*Global`v^4*Global`w^4 - 
          4*Global`v^5*Global`w^4 - 31*FeynCalc`CA*Global`v^5*Global`w^4 + 
          44*FeynCalc`CA^2*Global`v^5*Global`w^4 + 83*FeynCalc`CA^3*
           Global`v^5*Global`w^4 - 40*FeynCalc`CA^4*Global`v^5*Global`w^4 + 
          2*Global`v^6*Global`w^4 + 36*FeynCalc`CA*Global`v^6*Global`w^4 - 
          18*FeynCalc`CA^2*Global`v^6*Global`w^4 - 92*FeynCalc`CA^3*
           Global`v^6*Global`w^4 + 16*FeynCalc`CA^4*Global`v^6*Global`w^4 - 
          14*FeynCalc`CA*Global`v^7*Global`w^4 + 34*FeynCalc`CA^3*Global`v^7*
           Global`w^4 + 6*FeynCalc`CA*Global`v^5*Global`w^5 - 
          16*FeynCalc`CA^2*Global`v^5*Global`w^5 - 10*FeynCalc`CA^3*
           Global`v^5*Global`w^5 + 16*FeynCalc`CA^4*Global`v^5*Global`w^5 - 
          14*FeynCalc`CA*Global`v^6*Global`w^5 + 12*FeynCalc`CA^2*Global`v^6*
           Global`w^5 + 22*FeynCalc`CA^3*Global`v^6*Global`w^5 - 
          12*FeynCalc`CA^4*Global`v^6*Global`w^5 + 8*FeynCalc`CA*Global`v^7*
           Global`w^5 - 12*FeynCalc`CA^3*Global`v^7*Global`w^5 + 
          2*FeynCalc`CA*Global`v^6*Global`w^6 - 4*FeynCalc`CA^2*Global`v^6*
           Global`w^6 - 2*FeynCalc`CA^3*Global`v^6*Global`w^6 + 
          4*FeynCalc`CA^4*Global`v^6*Global`w^6 - 2*FeynCalc`CA*Global`v^7*
           Global`w^6 + 2*FeynCalc`CA^3*Global`v^7*Global`w^6)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muD2])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^2*
         Global`w^2*(1 - Global`v + Global`v*Global`w)^2) + 
       ((2*FeynCalc`CA - 2*FeynCalc`CA^3 - 6*FeynCalc`CA*Global`v + 
          10*FeynCalc`CA^3*Global`v + 8*FeynCalc`CA*Global`v^2 - 
          24*FeynCalc`CA^3*Global`v^2 - 4*FeynCalc`CA*Global`v^3 + 
          32*FeynCalc`CA^3*Global`v^3 - 24*FeynCalc`CA^3*Global`v^4 + 
          8*FeynCalc`CA^3*Global`v^5 - Global`w - 2*FeynCalc`CA*Global`w + 
          2*FeynCalc`CA^2*Global`w + 2*FeynCalc`CA^3*Global`w - 
          FeynCalc`CA^4*Global`w + 2*Global`v*Global`w + 
          6*FeynCalc`CA*Global`v*Global`w - 2*FeynCalc`CA^2*Global`v*
           Global`w - 10*FeynCalc`CA^3*Global`v*Global`w - 
          2*Global`v^2*Global`w - 8*FeynCalc`CA*Global`v^2*Global`w + 
          4*FeynCalc`CA^2*Global`v^2*Global`w + 24*FeynCalc`CA^3*Global`v^2*
           Global`w - 2*FeynCalc`CA^4*Global`v^2*Global`w + 
          2*Global`v^3*Global`w + 4*FeynCalc`CA*Global`v^3*Global`w - 
          2*FeynCalc`CA^2*Global`v^3*Global`w - 32*FeynCalc`CA^3*Global`v^3*
           Global`w - Global`v^4*Global`w + 2*FeynCalc`CA^2*Global`v^4*
           Global`w + 24*FeynCalc`CA^3*Global`v^4*Global`w - 
          FeynCalc`CA^4*Global`v^4*Global`w - 8*FeynCalc`CA^3*Global`v^5*
           Global`w + Global`w^2 + FeynCalc`CA*Global`w^2 - 
          2*FeynCalc`CA^2*Global`w^2 - FeynCalc`CA^3*Global`w^2 + 
          FeynCalc`CA^4*Global`w^2 - 2*Global`v*Global`w^2 - 
          3*FeynCalc`CA*Global`v*Global`w^2 + 2*FeynCalc`CA^2*Global`v*
           Global`w^2 + 5*FeynCalc`CA^3*Global`v*Global`w^2 + 
          2*Global`v^2*Global`w^2 + 4*FeynCalc`CA*Global`v^2*Global`w^2 - 
          4*FeynCalc`CA^2*Global`v^2*Global`w^2 - 12*FeynCalc`CA^3*Global`v^2*
           Global`w^2 + 2*FeynCalc`CA^4*Global`v^2*Global`w^2 - 
          2*Global`v^3*Global`w^2 - 2*FeynCalc`CA*Global`v^3*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v^3*Global`w^2 + 16*FeynCalc`CA^3*Global`v^3*
           Global`w^2 + Global`v^4*Global`w^2 - 2*FeynCalc`CA^2*Global`v^4*
           Global`w^2 - 12*FeynCalc`CA^3*Global`v^4*Global`w^2 + 
          FeynCalc`CA^4*Global`v^4*Global`w^2 + 4*FeynCalc`CA^3*Global`v^5*
           Global`w^2)*FeynFacet`\[Alpha]s^3*System`Log[Global`muFA2])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^2*
         Global`w^2) + ((FeynCalc`CA - FeynCalc`CA^3 - 3*FeynCalc`CA*
           Global`v + 3*FeynCalc`CA^3*Global`v + 4*FeynCalc`CA*Global`v^2 - 
          4*FeynCalc`CA^3*Global`v^2 - 2*FeynCalc`CA*Global`v^3 + 
          2*FeynCalc`CA^3*Global`v^3 + 2*FeynCalc`CA^2*Global`w - 
          2*FeynCalc`CA^4*Global`w - Global`v*Global`w - 
          3*FeynCalc`CA*Global`v*Global`w - 3*FeynCalc`CA^2*Global`v*
           Global`w + 3*FeynCalc`CA^3*Global`v*Global`w + 
          4*FeynCalc`CA^4*Global`v*Global`w + 3*Global`v^2*Global`w + 
          7*FeynCalc`CA*Global`v^2*Global`w + 3*FeynCalc`CA^2*Global`v^2*
           Global`w - 7*FeynCalc`CA^3*Global`v^2*Global`w - 
          6*FeynCalc`CA^4*Global`v^2*Global`w - 4*Global`v^3*Global`w - 
          10*FeynCalc`CA*Global`v^3*Global`w + 10*FeynCalc`CA^3*Global`v^3*
           Global`w + 4*FeynCalc`CA^4*Global`v^3*Global`w + 
          2*Global`v^4*Global`w + 6*FeynCalc`CA*Global`v^4*Global`w - 
          6*FeynCalc`CA^3*Global`v^4*Global`w - 2*FeynCalc`CA^4*Global`v^4*
           Global`w - 8*FeynCalc`CA^2*Global`v*Global`w^2 + 
          8*FeynCalc`CA^4*Global`v*Global`w^2 + Global`v^2*Global`w^2 + 
          5*FeynCalc`CA*Global`v^2*Global`w^2 + 9*FeynCalc`CA^2*Global`v^2*
           Global`w^2 - 5*FeynCalc`CA^3*Global`v^2*Global`w^2 - 
          2*FeynCalc`CA^4*Global`v^2*Global`w^2 + FeynCalc`CA*Global`nD*
           Global`v^2*Global`w^2 - FeynCalc`CA^3*Global`nD*Global`v^2*
           Global`w^2 + FeynCalc`CA*Global`nU*Global`v^2*Global`w^2 - 
          FeynCalc`CA^3*Global`nU*Global`v^2*Global`w^2 - 
          Global`v^3*Global`w^2 - 7*FeynCalc`CA*Global`v^3*Global`w^2 - 
          11*FeynCalc`CA^2*Global`v^3*Global`w^2 + 7*FeynCalc`CA^3*Global`v^3*
           Global`w^2 + 4*FeynCalc`CA^4*Global`v^3*Global`w^2 - 
          3*FeynCalc`CA*Global`nD*Global`v^3*Global`w^2 + 
          3*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^2 - 
          3*FeynCalc`CA*Global`nU*Global`v^3*Global`w^2 + 
          3*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^2 + 
          2*Global`v^4*Global`w^2 + 10*FeynCalc`CA*Global`v^4*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v^4*Global`w^2 - 10*FeynCalc`CA^3*Global`v^4*
           Global`w^2 + 4*FeynCalc`CA^4*Global`v^4*Global`w^2 + 
          4*FeynCalc`CA*Global`nD*Global`v^4*Global`w^2 - 
          4*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^2 + 
          4*FeynCalc`CA*Global`nU*Global`v^4*Global`w^2 - 
          4*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^2 - 
          2*Global`v^5*Global`w^2 - 8*FeynCalc`CA*Global`v^5*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v^5*Global`w^2 + 8*FeynCalc`CA^3*Global`v^5*
           Global`w^2 - 2*FeynCalc`CA*Global`nD*Global`v^5*Global`w^2 + 
          2*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^2 - 
          2*FeynCalc`CA*Global`nU*Global`v^5*Global`w^2 + 
          2*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^2 + 
          12*FeynCalc`CA^2*Global`v^2*Global`w^3 - 12*FeynCalc`CA^4*
           Global`v^2*Global`w^3 - Global`v^3*Global`w^3 - 
          7*FeynCalc`CA*Global`v^3*Global`w^3 - 3*FeynCalc`CA^2*Global`v^3*
           Global`w^3 + 7*FeynCalc`CA^3*Global`v^3*Global`w^3 - 
          4*FeynCalc`CA^4*Global`v^3*Global`w^3 - Global`v^4*Global`w^3 + 
          7*FeynCalc`CA*Global`v^4*Global`w^3 + 7*FeynCalc`CA^2*Global`v^4*
           Global`w^3 - 7*FeynCalc`CA^3*Global`v^4*Global`w^3 - 
          14*FeynCalc`CA^4*Global`v^4*Global`w^3 - 2*FeynCalc`CA*Global`nD*
           Global`v^4*Global`w^3 + 2*FeynCalc`CA^3*Global`nD*Global`v^4*
           Global`w^3 - 2*FeynCalc`CA*Global`nU*Global`v^4*Global`w^3 + 
          2*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^3 + 
          2*Global`v^5*Global`w^3 - 8*FeynCalc`CA*Global`v^5*Global`w^3 + 
          2*FeynCalc`CA^2*Global`v^5*Global`w^3 + 8*FeynCalc`CA^3*Global`v^5*
           Global`w^3 + 2*FeynCalc`CA*Global`nD*Global`v^5*Global`w^3 - 
          2*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^3 + 
          2*FeynCalc`CA*Global`nU*Global`v^5*Global`w^3 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^3 + 
          8*FeynCalc`CA*Global`v^6*Global`w^3 + 4*FeynCalc`CA^2*Global`v^6*
           Global`w^3 - 8*FeynCalc`CA^3*Global`v^6*Global`w^3 - 
          4*FeynCalc`CA^4*Global`v^6*Global`w^3 - 8*FeynCalc`CA^2*Global`v^3*
           Global`w^4 + 8*FeynCalc`CA^4*Global`v^3*Global`w^4 + 
          2*Global`v^4*Global`w^4 + 8*FeynCalc`CA*Global`v^4*Global`w^4 - 
          16*FeynCalc`CA^2*Global`v^4*Global`w^4 - 8*FeynCalc`CA^3*Global`v^4*
           Global`w^4 + 14*FeynCalc`CA^4*Global`v^4*Global`w^4 + 
          2*FeynCalc`CA*Global`nD*Global`v^4*Global`w^4 - 
          2*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^4 + 
          2*FeynCalc`CA*Global`nU*Global`v^4*Global`w^4 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^4 - 
          4*Global`v^5*Global`w^4 - 8*FeynCalc`CA*Global`v^5*Global`w^4 + 
          8*FeynCalc`CA^2*Global`v^5*Global`w^4 + 8*FeynCalc`CA^3*Global`v^5*
           Global`w^4 - 4*FeynCalc`CA*Global`nD*Global`v^5*Global`w^4 + 
          4*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^4 - 
          4*FeynCalc`CA*Global`nU*Global`v^5*Global`w^4 + 
          4*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^4 + 
          4*Global`v^6*Global`w^4 + 8*FeynCalc`CA*Global`v^6*Global`w^4 - 
          12*FeynCalc`CA^2*Global`v^6*Global`w^4 - 8*FeynCalc`CA^3*Global`v^6*
           Global`w^4 + 16*FeynCalc`CA^4*Global`v^6*Global`w^4 + 
          4*FeynCalc`CA*Global`nD*Global`v^6*Global`w^4 - 
          4*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^4 + 
          4*FeynCalc`CA*Global`nU*Global`v^6*Global`w^4 - 
          4*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^4 - 
          2*Global`v^7*Global`w^4 - 8*FeynCalc`CA*Global`v^7*Global`w^4 - 
          2*FeynCalc`CA^2*Global`v^7*Global`w^4 + 8*FeynCalc`CA^3*Global`v^7*
           Global`w^4 - 2*FeynCalc`CA*Global`nD*Global`v^7*Global`w^4 + 
          2*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^4 - 
          2*FeynCalc`CA*Global`nU*Global`v^7*Global`w^4 + 
          2*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^4 + 
          2*FeynCalc`CA^2*Global`v^4*Global`w^5 - 2*FeynCalc`CA^4*Global`v^4*
           Global`w^5 - Global`v^5*Global`w^5 - 7*FeynCalc`CA*Global`v^5*
           Global`w^5 + 25*FeynCalc`CA^2*Global`v^5*Global`w^5 + 
          7*FeynCalc`CA^3*Global`v^5*Global`w^5 - 12*FeynCalc`CA^4*Global`v^5*
           Global`w^5 + Global`v^6*Global`w^5 + 5*FeynCalc`CA*Global`v^6*
           Global`w^5 - 7*FeynCalc`CA^2*Global`v^6*Global`w^5 - 
          5*FeynCalc`CA^3*Global`v^6*Global`w^5 - 2*FeynCalc`CA^4*Global`v^6*
           Global`w^5 - 2*FeynCalc`CA*Global`nD*Global`v^6*Global`w^5 + 
          2*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^5 - 
          2*FeynCalc`CA*Global`nU*Global`v^6*Global`w^5 + 
          2*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^5 - 
          2*Global`v^7*Global`w^5 - 4*FeynCalc`CA*Global`v^7*Global`w^5 + 
          10*FeynCalc`CA^2*Global`v^7*Global`w^5 + 4*FeynCalc`CA^3*Global`v^7*
           Global`w^5 - 4*FeynCalc`CA^4*Global`v^7*Global`w^5 + 
          2*FeynCalc`CA*Global`nD*Global`v^7*Global`w^5 - 
          2*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^5 + 
          2*FeynCalc`CA*Global`nU*Global`v^7*Global`w^5 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^5 + 
          2*Global`v^8*Global`w^5 + 6*FeynCalc`CA*Global`v^8*Global`w^5 - 
          6*FeynCalc`CA^3*Global`v^8*Global`w^5 - 2*FeynCalc`CA^4*Global`v^8*
           Global`w^5 + Global`v^6*Global`w^6 + 5*FeynCalc`CA*Global`v^6*
           Global`w^6 - 19*FeynCalc`CA^2*Global`v^6*Global`w^6 - 
          5*FeynCalc`CA^3*Global`v^6*Global`w^6 + 10*FeynCalc`CA^4*Global`v^6*
           Global`w^6 + FeynCalc`CA*Global`nD*Global`v^6*Global`w^6 - 
          FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^6 + 
          FeynCalc`CA*Global`nU*Global`v^6*Global`w^6 - 
          FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^6 + 
          Global`v^7*Global`w^6 - FeynCalc`CA*Global`v^7*Global`w^6 - 
          FeynCalc`CA^2*Global`v^7*Global`w^6 + FeynCalc`CA^3*Global`v^7*
           Global`w^6 - 4*FeynCalc`CA^4*Global`v^7*Global`w^6 - 
          FeynCalc`CA*Global`nD*Global`v^7*Global`w^6 + 
          FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^6 - 
          FeynCalc`CA*Global`nU*Global`v^7*Global`w^6 + 
          FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^6 - 
          2*Global`v^8*Global`w^6 - 2*FeynCalc`CA*Global`v^8*Global`w^6 - 
          2*FeynCalc`CA^2*Global`v^8*Global`w^6 + 2*FeynCalc`CA^3*Global`v^8*
           Global`w^6 + 4*FeynCalc`CA^4*Global`v^8*Global`w^6 - 
          2*FeynCalc`CA*Global`v^9*Global`w^6 + 2*FeynCalc`CA^3*Global`v^9*
           Global`w^6 - Global`v^7*Global`w^7 - 3*FeynCalc`CA*Global`v^7*
           Global`w^7 + 9*FeynCalc`CA^2*Global`v^7*Global`w^7 + 
          3*FeynCalc`CA^3*Global`v^7*Global`w^7 - 4*FeynCalc`CA^4*Global`v^7*
           Global`w^7 + Global`v^8*Global`w^7 + FeynCalc`CA*Global`v^8*
           Global`w^7 + FeynCalc`CA^2*Global`v^8*Global`w^7 - 
          FeynCalc`CA^3*Global`v^8*Global`w^7 - 2*FeynCalc`CA^4*Global`v^8*
           Global`w^7 + 2*FeynCalc`CA*Global`v^9*Global`w^7 - 
          2*FeynCalc`CA^3*Global`v^9*Global`w^7 + FeynCalc`CA*Global`v^8*
           Global`w^8 - 2*FeynCalc`CA^2*Global`v^8*Global`w^8 - 
          FeynCalc`CA^3*Global`v^8*Global`w^8 + 2*FeynCalc`CA^4*Global`v^8*
           Global`w^8 - FeynCalc`CA*Global`v^9*Global`w^8 + 
          FeynCalc`CA^3*Global`v^9*Global`w^8)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muFB2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^2*Global`w^2*(-1 + Global`v*Global`w)^
          4) - ((4*FeynCalc`CA - 8*FeynCalc`CA^3 - 20*FeynCalc`CA*Global`v + 
          52*FeynCalc`CA^3*Global`v + 44*FeynCalc`CA*Global`v^2 - 
          156*FeynCalc`CA^3*Global`v^2 - 52*FeynCalc`CA*Global`v^3 + 
          276*FeynCalc`CA^3*Global`v^3 + 32*FeynCalc`CA*Global`v^4 - 
          308*FeynCalc`CA^3*Global`v^4 - 8*FeynCalc`CA*Global`v^5 + 
          216*FeynCalc`CA^3*Global`v^5 - 88*FeynCalc`CA^3*Global`v^6 + 
          16*FeynCalc`CA^3*Global`v^7 - 3*Global`w - 2*FeynCalc`CA*Global`w + 
          10*FeynCalc`CA^2*Global`w + 2*FeynCalc`CA^3*Global`w - 
          7*FeynCalc`CA^4*Global`w + 12*Global`v*Global`w + 
          4*FeynCalc`CA*Global`v*Global`w - 40*FeynCalc`CA^2*Global`v*
           Global`w - 8*FeynCalc`CA^3*Global`v*Global`w + 
          28*FeynCalc`CA^4*Global`v*Global`w - 18*Global`v^2*Global`w + 
          12*FeynCalc`CA*Global`v^2*Global`w + 74*FeynCalc`CA^2*Global`v^2*
           Global`w - 4*FeynCalc`CA^3*Global`v^2*Global`w - 
          56*FeynCalc`CA^4*Global`v^2*Global`w + 10*Global`v^3*Global`w - 
          60*FeynCalc`CA*Global`v^3*Global`w - 78*FeynCalc`CA^2*Global`v^3*
           Global`w + 116*FeynCalc`CA^3*Global`v^3*Global`w + 
          68*FeynCalc`CA^4*Global`v^3*Global`w + 3*Global`v^4*Global`w + 
          106*FeynCalc`CA*Global`v^4*Global`w + 48*FeynCalc`CA^2*Global`v^4*
           Global`w - 386*FeynCalc`CA^3*Global`v^4*Global`w - 
          51*FeynCalc`CA^4*Global`v^4*Global`w - 6*Global`v^5*Global`w - 
          88*FeynCalc`CA*Global`v^5*Global`w - 18*FeynCalc`CA^2*Global`v^5*
           Global`w + 636*FeynCalc`CA^3*Global`v^5*Global`w + 
          24*FeynCalc`CA^4*Global`v^5*Global`w + 2*Global`v^6*Global`w + 
          28*FeynCalc`CA*Global`v^6*Global`w + 4*FeynCalc`CA^2*Global`v^6*
           Global`w - 588*FeynCalc`CA^3*Global`v^6*Global`w - 
          6*FeynCalc`CA^4*Global`v^6*Global`w + 296*FeynCalc`CA^3*Global`v^7*
           Global`w - 64*FeynCalc`CA^3*Global`v^8*Global`w + Global`w^2 + 
          FeynCalc`CA*Global`w^2 - 2*FeynCalc`CA^2*Global`w^2 - 
          FeynCalc`CA^3*Global`w^2 + FeynCalc`CA^4*Global`w^2 + 
          2*Global`v*Global`w^2 - FeynCalc`CA*Global`v*Global`w^2 - 
          14*FeynCalc`CA^2*Global`v*Global`w^2 + 3*FeynCalc`CA^3*Global`v*
           Global`w^2 + 12*FeynCalc`CA^4*Global`v*Global`w^2 - 
          26*Global`v^2*Global`w^2 - 13*FeynCalc`CA*Global`v^2*Global`w^2 + 
          70*FeynCalc`CA^2*Global`v^2*Global`w^2 + 19*FeynCalc`CA^3*
           Global`v^2*Global`w^2 - 28*FeynCalc`CA^4*Global`v^2*Global`w^2 + 
          2*FeynCalc`CA*Global`nD*Global`v^2*Global`w^2 - 
          2*FeynCalc`CA^3*Global`nD*Global`v^2*Global`w^2 + 
          2*FeynCalc`CA*Global`nU*Global`v^2*Global`w^2 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^2*Global`w^2 + 
          68*Global`v^3*Global`w^2 + 35*FeynCalc`CA*Global`v^3*Global`w^2 - 
          140*FeynCalc`CA^2*Global`v^3*Global`w^2 - 145*FeynCalc`CA^3*
           Global`v^3*Global`w^2 + 24*FeynCalc`CA^4*Global`v^3*Global`w^2 - 
          10*FeynCalc`CA*Global`nD*Global`v^3*Global`w^2 + 
          10*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^2 - 
          10*FeynCalc`CA*Global`nU*Global`v^3*Global`w^2 + 
          10*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^2 - 
          91*Global`v^4*Global`w^2 - 24*FeynCalc`CA*Global`v^4*Global`w^2 + 
          178*FeynCalc`CA^2*Global`v^4*Global`w^2 + 398*FeynCalc`CA^3*
           Global`v^4*Global`w^2 - 23*FeynCalc`CA^4*Global`v^4*Global`w^2 + 
          22*FeynCalc`CA*Global`nD*Global`v^4*Global`w^2 - 
          22*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^2 + 
          22*FeynCalc`CA*Global`nU*Global`v^4*Global`w^2 - 
          22*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^2 + 
          70*Global`v^5*Global`w^2 - 46*FeynCalc`CA*Global`v^5*Global`w^2 - 
          138*FeynCalc`CA^2*Global`v^5*Global`w^2 - 486*FeynCalc`CA^3*
           Global`v^5*Global`w^2 + 12*FeynCalc`CA^4*Global`v^5*Global`w^2 - 
          26*FeynCalc`CA*Global`nD*Global`v^5*Global`w^2 + 
          26*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^2 - 
          26*FeynCalc`CA*Global`nU*Global`v^5*Global`w^2 + 
          26*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^2 - 
          28*Global`v^6*Global`w^2 + 92*FeynCalc`CA*Global`v^6*Global`w^2 + 
          66*FeynCalc`CA^2*Global`v^6*Global`w^2 + 136*FeynCalc`CA^3*
           Global`v^6*Global`w^2 - 6*FeynCalc`CA^4*Global`v^6*Global`w^2 + 
          16*FeynCalc`CA*Global`nD*Global`v^6*Global`w^2 - 
          16*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^2 + 
          16*FeynCalc`CA*Global`nU*Global`v^6*Global`w^2 - 
          16*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^2 + 
          4*Global`v^7*Global`w^2 - 44*FeynCalc`CA*Global`v^7*Global`w^2 - 
          20*FeynCalc`CA^2*Global`v^7*Global`w^2 + 284*FeynCalc`CA^3*
           Global`v^7*Global`w^2 + 8*FeynCalc`CA^4*Global`v^7*Global`w^2 - 
          4*FeynCalc`CA*Global`nD*Global`v^7*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^2 - 
          4*FeynCalc`CA*Global`nU*Global`v^7*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^2 - 
          304*FeynCalc`CA^3*Global`v^8*Global`w^2 + 96*FeynCalc`CA^3*
           Global`v^9*Global`w^2 - 2*Global`v*Global`w^3 - 
          2*FeynCalc`CA*Global`v*Global`w^3 + 4*FeynCalc`CA^2*Global`v*
           Global`w^3 + 2*FeynCalc`CA^3*Global`v*Global`w^3 - 
          2*FeynCalc`CA^4*Global`v*Global`w^3 + 13*Global`v^2*Global`w^3 + 
          14*FeynCalc`CA*Global`v^2*Global`w^3 - 26*FeynCalc`CA^2*Global`v^2*
           Global`w^3 - 18*FeynCalc`CA^3*Global`v^2*Global`w^3 + 
          13*FeynCalc`CA^4*Global`v^2*Global`w^3 - 24*Global`v^3*Global`w^3 - 
          22*FeynCalc`CA*Global`v^3*Global`w^3 + 48*FeynCalc`CA^2*Global`v^3*
           Global`w^3 + 64*FeynCalc`CA^3*Global`v^3*Global`w^3 - 
          8*FeynCalc`CA^4*Global`v^3*Global`w^3 + 4*FeynCalc`CA*Global`nD*
           Global`v^3*Global`w^3 - 4*FeynCalc`CA^3*Global`nD*Global`v^3*
           Global`w^3 + 4*FeynCalc`CA*Global`nU*Global`v^3*Global`w^3 - 
          4*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^3 + 
          18*Global`v^4*Global`w^3 - 84*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          88*FeynCalc`CA^3*Global`v^4*Global`w^3 + 18*FeynCalc`CA^4*
           Global`v^4*Global`w^3 - 20*FeynCalc`CA*Global`nD*Global`v^4*
           Global`w^3 + 20*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^3 - 
          20*FeynCalc`CA*Global`nU*Global`v^4*Global`w^3 + 
          20*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^3 + 
          8*Global`v^5*Global`w^3 + 36*FeynCalc`CA*Global`v^5*Global`w^3 + 
          54*FeynCalc`CA^2*Global`v^5*Global`w^3 - 150*FeynCalc`CA^3*
           Global`v^5*Global`w^3 + 26*FeynCalc`CA^4*Global`v^5*Global`w^3 + 
          40*FeynCalc`CA*Global`nD*Global`v^5*Global`w^3 - 
          40*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^3 + 
          40*FeynCalc`CA*Global`nU*Global`v^5*Global`w^3 - 
          40*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^3 - 
          41*Global`v^6*Global`w^3 - 14*FeynCalc`CA*Global`v^6*Global`w^3 + 
          20*FeynCalc`CA^2*Global`v^6*Global`w^3 + 678*FeynCalc`CA^3*
           Global`v^6*Global`w^3 - 59*FeynCalc`CA^4*Global`v^6*Global`w^3 - 
          36*FeynCalc`CA*Global`nD*Global`v^6*Global`w^3 + 
          36*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^3 - 
          36*FeynCalc`CA*Global`nU*Global`v^6*Global`w^3 + 
          36*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^3 + 
          40*Global`v^7*Global`w^3 - 60*FeynCalc`CA*Global`v^7*Global`w^3 - 
          40*FeynCalc`CA^2*Global`v^7*Global`w^3 - 872*FeynCalc`CA^3*
           Global`v^7*Global`w^3 + 24*FeynCalc`CA^4*Global`v^7*Global`w^3 + 
          12*FeynCalc`CA*Global`nD*Global`v^7*Global`w^3 - 
          12*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^3 + 
          12*FeynCalc`CA*Global`nU*Global`v^7*Global`w^3 - 
          12*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^3 - 
          12*Global`v^8*Global`w^3 + 48*FeynCalc`CA*Global`v^8*Global`w^3 + 
          32*FeynCalc`CA^2*Global`v^8*Global`w^3 + 432*FeynCalc`CA^3*
           Global`v^8*Global`w^3 - 20*FeynCalc`CA^4*Global`v^8*Global`w^3 + 
          16*FeynCalc`CA^3*Global`v^9*Global`w^3 - 64*FeynCalc`CA^3*
           Global`v^10*Global`w^3 - Global`v^2*Global`w^4 - 
          FeynCalc`CA*Global`v^2*Global`w^4 + 2*FeynCalc`CA^2*Global`v^2*
           Global`w^4 + FeynCalc`CA^3*Global`v^2*Global`w^4 - 
          FeynCalc`CA^4*Global`v^2*Global`w^4 - 14*Global`v^3*Global`w^4 - 
          9*FeynCalc`CA*Global`v^3*Global`w^4 + 46*FeynCalc`CA^2*Global`v^3*
           Global`w^4 + 7*FeynCalc`CA^3*Global`v^3*Global`w^4 - 
          32*FeynCalc`CA^4*Global`v^3*Global`w^4 + 62*Global`v^4*Global`w^4 + 
          39*FeynCalc`CA*Global`v^4*Global`w^4 - 120*FeynCalc`CA^2*Global`v^4*
           Global`w^4 - 71*FeynCalc`CA^3*Global`v^4*Global`w^4 + 
          42*FeynCalc`CA^4*Global`v^4*Global`w^4 + 6*FeynCalc`CA*Global`nD*
           Global`v^4*Global`w^4 - 6*FeynCalc`CA^3*Global`nD*Global`v^4*
           Global`w^4 + 6*FeynCalc`CA*Global`nU*Global`v^4*Global`w^4 - 
          6*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^4 - 
          116*Global`v^5*Global`w^4 - 47*FeynCalc`CA*Global`v^5*Global`w^4 + 
          228*FeynCalc`CA^2*Global`v^5*Global`w^4 + 285*FeynCalc`CA^3*
           Global`v^5*Global`w^4 - 120*FeynCalc`CA^4*Global`v^5*Global`w^4 - 
          30*FeynCalc`CA*Global`nD*Global`v^5*Global`w^4 + 
          30*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^4 - 
          30*FeynCalc`CA*Global`nU*Global`v^5*Global`w^4 + 
          30*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^4 + 
          145*Global`v^6*Global`w^4 + 6*FeynCalc`CA*Global`v^6*Global`w^4 - 
          292*FeynCalc`CA^2*Global`v^6*Global`w^4 - 558*FeynCalc`CA^3*
           Global`v^6*Global`w^4 + 211*FeynCalc`CA^4*Global`v^6*Global`w^4 + 
          52*FeynCalc`CA*Global`nD*Global`v^6*Global`w^4 - 
          52*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^4 + 
          52*FeynCalc`CA*Global`nU*Global`v^6*Global`w^4 - 
          52*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^4 - 
          104*Global`v^7*Global`w^4 + 24*FeynCalc`CA*Global`v^7*Global`w^4 + 
          176*FeynCalc`CA^2*Global`v^7*Global`w^4 + 424*FeynCalc`CA^3*
           Global`v^7*Global`w^4 - 128*FeynCalc`CA^4*Global`v^7*Global`w^4 - 
          40*FeynCalc`CA*Global`nD*Global`v^7*Global`w^4 + 
          40*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^4 - 
          40*FeynCalc`CA*Global`nU*Global`v^7*Global`w^4 + 
          40*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^4 + 
          24*Global`v^8*Global`w^4 + 32*FeynCalc`CA*Global`v^8*Global`w^4 - 
          68*FeynCalc`CA^2*Global`v^8*Global`w^4 + 116*FeynCalc`CA^3*
           Global`v^8*Global`w^4 + 76*FeynCalc`CA^4*Global`v^8*Global`w^4 + 
          16*FeynCalc`CA*Global`nD*Global`v^8*Global`w^4 - 
          16*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^4 + 
          16*FeynCalc`CA*Global`nU*Global`v^8*Global`w^4 - 
          16*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^4 + 
          4*Global`v^9*Global`w^4 - 44*FeynCalc`CA*Global`v^9*Global`w^4 - 
          20*FeynCalc`CA^2*Global`v^9*Global`w^4 - 356*FeynCalc`CA^3*
           Global`v^9*Global`w^4 + 8*FeynCalc`CA^4*Global`v^9*Global`w^4 - 
          4*FeynCalc`CA*Global`nD*Global`v^9*Global`w^4 + 
          4*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^4 - 
          4*FeynCalc`CA*Global`nU*Global`v^9*Global`w^4 + 
          4*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^4 + 
          136*FeynCalc`CA^3*Global`v^10*Global`w^4 + 16*FeynCalc`CA^3*
           Global`v^11*Global`w^4 + 4*Global`v^3*Global`w^5 + 
          4*FeynCalc`CA*Global`v^3*Global`w^5 - 8*FeynCalc`CA^2*Global`v^3*
           Global`w^5 - 4*FeynCalc`CA^3*Global`v^3*Global`w^5 + 
          4*FeynCalc`CA^4*Global`v^3*Global`w^5 - 9*Global`v^4*Global`w^5 - 
          14*FeynCalc`CA*Global`v^4*Global`w^5 + 6*FeynCalc`CA^2*Global`v^4*
           Global`w^5 + 22*FeynCalc`CA^3*Global`v^4*Global`w^5 + 
          3*FeynCalc`CA^4*Global`v^4*Global`w^5 - 6*Global`v^5*Global`w^5 + 
          4*FeynCalc`CA*Global`v^5*Global`w^5 + 10*FeynCalc`CA^2*Global`v^5*
           Global`w^5 - 56*FeynCalc`CA^3*Global`v^5*Global`w^5 + 
          4*FeynCalc`CA^4*Global`v^5*Global`w^5 + 8*FeynCalc`CA*Global`nD*
           Global`v^5*Global`w^5 - 8*FeynCalc`CA^3*Global`nD*Global`v^5*
           Global`w^5 + 8*FeynCalc`CA*Global`nU*Global`v^5*Global`w^5 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^5 + 
          12*Global`v^6*Global`w^5 + 8*FeynCalc`CA*Global`v^6*Global`w^5 + 
          8*FeynCalc`CA^2*Global`v^6*Global`w^5 + 56*FeynCalc`CA^3*Global`v^6*
           Global`w^5 - 84*FeynCalc`CA^4*Global`v^6*Global`w^5 - 
          32*FeynCalc`CA*Global`nD*Global`v^6*Global`w^5 + 
          32*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^5 - 
          32*FeynCalc`CA*Global`nU*Global`v^6*Global`w^5 + 
          32*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^5 - 
          18*Global`v^7*Global`w^5 + 24*FeynCalc`CA*Global`v^7*Global`w^5 + 
          74*FeynCalc`CA^2*Global`v^7*Global`w^5 + 152*FeynCalc`CA^3*
           Global`v^7*Global`w^5 + 32*FeynCalc`CA^4*Global`v^7*Global`w^5 + 
          48*FeynCalc`CA*Global`nD*Global`v^7*Global`w^5 - 
          48*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^5 + 
          48*FeynCalc`CA*Global`nU*Global`v^7*Global`w^5 - 
          48*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^5 + 
          41*Global`v^8*Global`w^5 - 74*FeynCalc`CA*Global`v^8*Global`w^5 - 
          64*FeynCalc`CA^2*Global`v^8*Global`w^5 - 462*FeynCalc`CA^3*
           Global`v^8*Global`w^5 - 57*FeynCalc`CA^4*Global`v^8*Global`w^5 - 
          36*FeynCalc`CA*Global`nD*Global`v^8*Global`w^5 + 
          36*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^5 - 
          36*FeynCalc`CA*Global`nU*Global`v^8*Global`w^5 + 
          36*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^5 - 
          26*Global`v^9*Global`w^5 + 20*FeynCalc`CA*Global`v^9*Global`w^5 + 
          82*FeynCalc`CA^2*Global`v^9*Global`w^5 + 424*FeynCalc`CA^3*
           Global`v^9*Global`w^5 - 32*FeynCalc`CA^4*Global`v^9*Global`w^5 + 
          12*FeynCalc`CA*Global`nD*Global`v^9*Global`w^5 - 
          12*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^5 + 
          12*FeynCalc`CA*Global`nU*Global`v^9*Global`w^5 - 
          12*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^5 + 
          2*Global`v^10*Global`w^5 + 28*FeynCalc`CA*Global`v^10*Global`w^5 + 
          4*FeynCalc`CA^2*Global`v^10*Global`w^5 - 76*FeynCalc`CA^3*
           Global`v^10*Global`w^5 - 6*FeynCalc`CA^4*Global`v^10*Global`w^5 - 
          56*FeynCalc`CA^3*Global`v^11*Global`w^5 - Global`v^4*Global`w^6 - 
          FeynCalc`CA*Global`v^4*Global`w^6 + 2*FeynCalc`CA^2*Global`v^4*
           Global`w^6 + FeynCalc`CA^3*Global`v^4*Global`w^6 - 
          FeynCalc`CA^4*Global`v^4*Global`w^6 + 14*Global`v^5*Global`w^6 + 
          13*FeynCalc`CA*Global`v^5*Global`w^6 - 34*FeynCalc`CA^2*Global`v^5*
           Global`w^6 - 15*FeynCalc`CA^3*Global`v^5*Global`w^6 + 
          20*FeynCalc`CA^4*Global`v^5*Global`w^6 - 22*Global`v^6*Global`w^6 - 
          19*FeynCalc`CA*Global`v^6*Global`w^6 + 30*FeynCalc`CA^2*Global`v^6*
           Global`w^6 + 57*FeynCalc`CA^3*Global`v^6*Global`w^6 + 
          24*FeynCalc`CA^4*Global`v^6*Global`w^6 + 6*FeynCalc`CA*Global`nD*
           Global`v^6*Global`w^6 - 6*FeynCalc`CA^3*Global`nD*Global`v^6*
           Global`w^6 + 6*FeynCalc`CA*Global`nU*Global`v^6*Global`w^6 - 
          6*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^6 + 
          28*Global`v^7*Global`w^6 + FeynCalc`CA*Global`v^7*Global`w^6 - 
          92*FeynCalc`CA^2*Global`v^7*Global`w^6 - 163*FeynCalc`CA^3*
           Global`v^7*Global`w^6 + 16*FeynCalc`CA^4*Global`v^7*Global`w^6 - 
          22*FeynCalc`CA*Global`nD*Global`v^7*Global`w^6 + 
          22*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^6 - 
          22*FeynCalc`CA*Global`nU*Global`v^7*Global`w^6 + 
          22*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^6 - 
          41*Global`v^8*Global`w^6 + 4*FeynCalc`CA*Global`v^8*Global`w^6 + 
          58*FeynCalc`CA^2*Global`v^8*Global`w^6 + 274*FeynCalc`CA^3*
           Global`v^8*Global`w^6 + 47*FeynCalc`CA^4*Global`v^8*Global`w^6 + 
          30*FeynCalc`CA*Global`nD*Global`v^8*Global`w^6 - 
          30*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^6 + 
          30*FeynCalc`CA*Global`nU*Global`v^8*Global`w^6 - 
          30*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^6 + 
          26*Global`v^9*Global`w^6 + 62*FeynCalc`CA*Global`v^9*Global`w^6 - 
          78*FeynCalc`CA^2*Global`v^9*Global`w^6 - 194*FeynCalc`CA^3*
           Global`v^9*Global`w^6 + 20*FeynCalc`CA^4*Global`v^9*Global`w^6 - 
          14*FeynCalc`CA*Global`nD*Global`v^9*Global`w^6 + 
          14*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^6 - 
          14*FeynCalc`CA*Global`nU*Global`v^9*Global`w^6 + 
          14*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^6 - 
          4*Global`v^10*Global`w^6 - 52*FeynCalc`CA*Global`v^10*Global`w^6 - 
          22*FeynCalc`CA^2*Global`v^10*Global`w^6 - 48*FeynCalc`CA^3*
           Global`v^10*Global`w^6 + 26*FeynCalc`CA^4*Global`v^10*Global`w^6 - 
          8*FeynCalc`CA*Global`v^11*Global`w^6 + 88*FeynCalc`CA^3*Global`v^11*
           Global`w^6 - 2*Global`v^5*Global`w^7 - 2*FeynCalc`CA*Global`v^5*
           Global`w^7 + 4*FeynCalc`CA^2*Global`v^5*Global`w^7 + 
          2*FeynCalc`CA^3*Global`v^5*Global`w^7 - 2*FeynCalc`CA^4*Global`v^5*
           Global`w^7 - Global`v^6*Global`w^7 + 2*FeynCalc`CA*Global`v^6*
           Global`w^7 + 10*FeynCalc`CA^2*Global`v^6*Global`w^7 - 
          6*FeynCalc`CA^3*Global`v^6*Global`w^7 - 9*FeynCalc`CA^4*Global`v^6*
           Global`w^7 + 4*Global`v^7*Global`w^7 + 2*FeynCalc`CA*Global`v^7*
           Global`w^7 + 4*FeynCalc`CA^2*Global`v^7*Global`w^7 + 
          16*FeynCalc`CA^3*Global`v^7*Global`w^7 - 8*FeynCalc`CA^4*Global`v^7*
           Global`w^7 + 4*FeynCalc`CA*Global`nD*Global`v^7*Global`w^7 - 
          4*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^7 + 
          4*FeynCalc`CA*Global`nU*Global`v^7*Global`w^7 - 
          4*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^7 + 
          2*Global`v^8*Global`w^7 + 8*FeynCalc`CA*Global`v^8*Global`w^7 + 
          12*FeynCalc`CA^2*Global`v^8*Global`w^7 - 32*FeynCalc`CA^3*
           Global`v^8*Global`w^7 - 30*FeynCalc`CA^4*Global`v^8*Global`w^7 - 
          12*FeynCalc`CA*Global`nD*Global`v^8*Global`w^7 + 
          12*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^7 - 
          12*FeynCalc`CA*Global`nU*Global`v^8*Global`w^7 + 
          12*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^7 - 
          8*Global`v^9*Global`w^7 - 56*FeynCalc`CA*Global`v^9*Global`w^7 + 
          38*FeynCalc`CA^2*Global`v^9*Global`w^7 + 6*FeynCalc`CA^3*Global`v^9*
           Global`w^7 + 2*FeynCalc`CA^4*Global`v^9*Global`w^7 + 
          8*FeynCalc`CA*Global`nD*Global`v^9*Global`w^7 - 
          8*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^7 + 
          8*FeynCalc`CA*Global`nU*Global`v^9*Global`w^7 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^7 + 
          5*Global`v^10*Global`w^7 + 22*FeynCalc`CA*Global`v^10*Global`w^7 + 
          36*FeynCalc`CA^2*Global`v^10*Global`w^7 + 98*FeynCalc`CA^3*
           Global`v^10*Global`w^7 - 41*FeynCalc`CA^4*Global`v^10*Global`w^7 + 
          24*FeynCalc`CA*Global`v^11*Global`w^7 - 84*FeynCalc`CA^3*
           Global`v^11*Global`w^7 + Global`v^6*Global`w^8 + 
          FeynCalc`CA*Global`v^6*Global`w^8 - 2*FeynCalc`CA^2*Global`v^6*
           Global`w^8 - FeynCalc`CA^3*Global`v^6*Global`w^8 + 
          FeynCalc`CA^4*Global`v^6*Global`w^8 - 2*Global`v^7*Global`w^8 - 
          3*FeynCalc`CA*Global`v^7*Global`w^8 + 2*FeynCalc`CA^2*Global`v^7*
           Global`w^8 + 5*FeynCalc`CA^3*Global`v^7*Global`w^8 + 
          2*Global`v^8*Global`w^8 + FeynCalc`CA*Global`v^8*Global`w^8 - 
          4*FeynCalc`CA^2*Global`v^8*Global`w^8 - 9*FeynCalc`CA^3*Global`v^8*
           Global`w^8 + 2*FeynCalc`CA^4*Global`v^8*Global`w^8 + 
          2*FeynCalc`CA*Global`nD*Global`v^8*Global`w^8 - 
          2*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^8 + 
          2*FeynCalc`CA*Global`nU*Global`v^8*Global`w^8 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^8 + 
          4*Global`v^9*Global`w^8 + 19*FeynCalc`CA*Global`v^9*Global`w^8 - 
          28*FeynCalc`CA^2*Global`v^9*Global`w^8 + 15*FeynCalc`CA^3*
           Global`v^9*Global`w^8 - 2*FeynCalc`CA*Global`nD*Global`v^9*
           Global`w^8 + 2*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^8 - 
          2*FeynCalc`CA*Global`nU*Global`v^9*Global`w^8 + 
          2*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^8 - 
          5*Global`v^10*Global`w^8 + 10*FeynCalc`CA*Global`v^10*Global`w^8 - 
          32*FeynCalc`CA^2*Global`v^10*Global`w^8 - 62*FeynCalc`CA^3*
           Global`v^10*Global`w^8 + 37*FeynCalc`CA^4*Global`v^10*Global`w^8 - 
          28*FeynCalc`CA*Global`v^11*Global`w^8 + 52*FeynCalc`CA^3*
           Global`v^11*Global`w^8 - 2*Global`v^9*Global`w^9 - 
          4*FeynCalc`CA*Global`v^9*Global`w^9 + 10*FeynCalc`CA^2*Global`v^9*
           Global`w^9 + 2*Global`v^10*Global`w^9 - 12*FeynCalc`CA*Global`v^10*
           Global`w^9 + 22*FeynCalc`CA^2*Global`v^10*Global`w^9 + 
          20*FeynCalc`CA^3*Global`v^10*Global`w^9 - 24*FeynCalc`CA^4*
           Global`v^10*Global`w^9 + 16*FeynCalc`CA*Global`v^11*Global`w^9 - 
          20*FeynCalc`CA^3*Global`v^11*Global`w^9 + 4*FeynCalc`CA*Global`v^10*
           Global`w^10 - 8*FeynCalc`CA^2*Global`v^10*Global`w^10 - 
          4*FeynCalc`CA^3*Global`v^10*Global`w^10 + 8*FeynCalc`CA^4*
           Global`v^10*Global`w^10 - 4*FeynCalc`CA*Global`v^11*Global`w^10 + 
          4*FeynCalc`CA^3*Global`v^11*Global`w^10)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`s])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^2*Global`w^2*(-1 + Global`v*Global`w)^4*
         (1 - Global`v + Global`v*Global`w)^2) - 
       ((2*FeynCalc`CA - 8*FeynCalc`CA*Global`v - 2*FeynCalc`CA^3*Global`v + 
          14*FeynCalc`CA*Global`v^2 + 8*FeynCalc`CA^3*Global`v^2 - 
          12*FeynCalc`CA*Global`v^3 - 14*FeynCalc`CA^3*Global`v^3 + 
          4*FeynCalc`CA*Global`v^4 + 12*FeynCalc`CA^3*Global`v^4 - 
          4*FeynCalc`CA^3*Global`v^5 - 4*Global`w - 2*FeynCalc`CA*Global`w - 
          FeynCalc`CA^2*Global`w - FeynCalc`CA^4*Global`w + 
          19*Global`v*Global`w - 2*FeynCalc`CA*Global`v*Global`w + 
          10*FeynCalc`CA^2*Global`v*Global`w + 4*FeynCalc`CA^3*Global`v*
           Global`w - 38*Global`v^2*Global`w + 36*FeynCalc`CA*Global`v^2*
           Global`w - 23*FeynCalc`CA^2*Global`v^2*Global`w - 
          18*FeynCalc`CA^3*Global`v^2*Global`w + FeynCalc`CA^4*Global`v^2*
           Global`w + 39*Global`v^3*Global`w - 96*FeynCalc`CA*Global`v^3*
           Global`w + 28*FeynCalc`CA^2*Global`v^3*Global`w + 
          36*FeynCalc`CA^3*Global`v^3*Global`w - FeynCalc`CA^4*Global`v^3*
           Global`w - 20*Global`v^4*Global`w + 120*FeynCalc`CA*Global`v^4*
           Global`w - 18*FeynCalc`CA^2*Global`v^4*Global`w - 
          36*FeynCalc`CA^3*Global`v^4*Global`w + 4*Global`v^5*Global`w - 
          72*FeynCalc`CA*Global`v^5*Global`w + 4*FeynCalc`CA^2*Global`v^5*
           Global`w + 14*FeynCalc`CA^3*Global`v^5*Global`w + 
          FeynCalc`CA^4*Global`v^5*Global`w + 16*FeynCalc`CA*Global`v^6*
           Global`w + Global`w^2 + 3*FeynCalc`CA^2*Global`w^2 - 
          2*FeynCalc`CA^4*Global`w^2 - 7*Global`v*Global`w^2 + 
          10*FeynCalc`CA*Global`v*Global`w^2 - 16*FeynCalc`CA^2*Global`v*
           Global`w^2 - 2*FeynCalc`CA^3*Global`v*Global`w^2 + 
          FeynCalc`CA^4*Global`v*Global`w^2 + 16*Global`v^2*Global`w^2 - 
          62*FeynCalc`CA*Global`v^2*Global`w^2 + 22*FeynCalc`CA^2*Global`v^2*
           Global`w^2 + 12*FeynCalc`CA^3*Global`v^2*Global`w^2 - 
          3*FeynCalc`CA^4*Global`v^2*Global`w^2 - 14*Global`v^3*Global`w^2 + 
          164*FeynCalc`CA*Global`v^3*Global`w^2 - 19*FeynCalc`CA^2*Global`v^3*
           Global`w^2 - 34*FeynCalc`CA^3*Global`v^3*Global`w^2 + 
          3*FeynCalc`CA^4*Global`v^3*Global`w^2 - 2*Global`v^4*Global`w^2 - 
          228*FeynCalc`CA*Global`v^4*Global`w^2 + 10*FeynCalc`CA^2*Global`v^4*
           Global`w^2 + 52*FeynCalc`CA^3*Global`v^4*Global`w^2 - 
          4*FeynCalc`CA^4*Global`v^4*Global`w^2 + 10*Global`v^5*Global`w^2 + 
          156*FeynCalc`CA*Global`v^5*Global`w^2 + 8*FeynCalc`CA^2*Global`v^5*
           Global`w^2 - 38*FeynCalc`CA^3*Global`v^5*Global`w^2 + 
          2*FeynCalc`CA^4*Global`v^5*Global`w^2 - 4*Global`v^6*Global`w^2 - 
          40*FeynCalc`CA*Global`v^6*Global`w^2 - 4*FeynCalc`CA^2*Global`v^6*
           Global`w^2 + 14*FeynCalc`CA^3*Global`v^6*Global`w^2 - 
          FeynCalc`CA^4*Global`v^6*Global`w^2 - 4*FeynCalc`CA^3*Global`v^7*
           Global`w^2 + Global`v*Global`w^3 + FeynCalc`CA^2*Global`v*
           Global`w^3 + Global`v^2*Global`w^3 + 12*FeynCalc`CA*Global`v^2*
           Global`w^3 + 11*FeynCalc`CA^2*Global`v^2*Global`w^3 - 
          2*FeynCalc`CA^3*Global`v^2*Global`w^3 - 4*FeynCalc`CA^4*Global`v^2*
           Global`w^3 - 8*Global`v^3*Global`w^3 - 64*FeynCalc`CA*Global`v^3*
           Global`w^3 - 34*FeynCalc`CA^2*Global`v^3*Global`w^3 + 
          16*FeynCalc`CA^3*Global`v^3*Global`w^3 - 5*FeynCalc`CA^4*Global`v^3*
           Global`w^3 + 16*Global`v^4*Global`w^3 + 140*FeynCalc`CA*Global`v^4*
           Global`w^3 + 32*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          50*FeynCalc`CA^3*Global`v^4*Global`w^3 + 14*FeynCalc`CA^4*
           Global`v^4*Global`w^3 - 16*Global`v^5*Global`w^3 - 
          132*FeynCalc`CA*Global`v^5*Global`w^3 - 36*FeynCalc`CA^2*Global`v^5*
           Global`w^3 + 68*FeynCalc`CA^3*Global`v^5*Global`w^3 - 
          13*FeynCalc`CA^4*Global`v^5*Global`w^3 + 6*Global`v^6*Global`w^3 + 
          48*FeynCalc`CA*Global`v^6*Global`w^3 + 10*FeynCalc`CA^2*Global`v^6*
           Global`w^3 - 48*FeynCalc`CA^3*Global`v^6*Global`w^3 + 
          4*FeynCalc`CA^4*Global`v^6*Global`w^3 - 4*FeynCalc`CA*Global`v^7*
           Global`w^3 + 16*FeynCalc`CA^3*Global`v^7*Global`w^3 - 
          3*Global`v^2*Global`w^4 - 5*FeynCalc`CA^2*Global`v^2*Global`w^4 + 
          2*FeynCalc`CA^4*Global`v^2*Global`w^4 + 6*Global`v^3*Global`w^4 + 
          8*FeynCalc`CA*Global`v^3*Global`w^4 + 19*FeynCalc`CA^2*Global`v^3*
           Global`w^4 - 4*FeynCalc`CA^3*Global`v^3*Global`w^4 + 
          7*FeynCalc`CA^4*Global`v^3*Global`w^4 - 4*Global`v^4*Global`w^4 - 
          44*FeynCalc`CA*Global`v^4*Global`w^4 - 13*FeynCalc`CA^2*Global`v^4*
           Global`w^4 + 28*FeynCalc`CA^3*Global`v^4*Global`w^4 - 
          24*FeynCalc`CA^4*Global`v^4*Global`w^4 + 2*Global`v^5*Global`w^4 + 
          68*FeynCalc`CA*Global`v^5*Global`w^4 + 21*FeynCalc`CA^2*Global`v^5*
           Global`w^4 - 62*FeynCalc`CA^3*Global`v^5*Global`w^4 + 
          27*FeynCalc`CA^4*Global`v^5*Global`w^4 - Global`v^6*Global`w^4 - 
          44*FeynCalc`CA*Global`v^6*Global`w^4 - 2*FeynCalc`CA^2*Global`v^6*
           Global`w^4 + 64*FeynCalc`CA^3*Global`v^6*Global`w^4 - 
          12*FeynCalc`CA^4*Global`v^6*Global`w^4 + 12*FeynCalc`CA*Global`v^7*
           Global`w^4 - 26*FeynCalc`CA^3*Global`v^7*Global`w^4 + 
          Global`v^3*Global`w^5 + FeynCalc`CA^2*Global`v^3*Global`w^5 - 
          3*Global`v^4*Global`w^5 + 8*FeynCalc`CA*Global`v^4*Global`w^5 - 
          6*FeynCalc`CA^2*Global`v^4*Global`w^5 - 6*FeynCalc`CA^3*Global`v^4*
           Global`w^5 + 13*FeynCalc`CA^4*Global`v^4*Global`w^5 + 
          4*Global`v^5*Global`w^5 - 22*FeynCalc`CA*Global`v^5*Global`w^5 + 
          4*FeynCalc`CA^2*Global`v^5*Global`w^5 + 26*FeynCalc`CA^3*Global`v^5*
           Global`w^5 - 22*FeynCalc`CA^4*Global`v^5*Global`w^5 - 
          2*Global`v^6*Global`w^5 + 28*FeynCalc`CA*Global`v^6*Global`w^5 - 
          11*FeynCalc`CA^2*Global`v^6*Global`w^5 - 42*FeynCalc`CA^3*
           Global`v^6*Global`w^5 + 17*FeynCalc`CA^4*Global`v^6*Global`w^5 - 
          14*FeynCalc`CA*Global`v^7*Global`w^5 + 22*FeynCalc`CA^3*Global`v^7*
           Global`w^5 - Global`v^5*Global`w^6 + 2*FeynCalc`CA*Global`v^5*
           Global`w^6 - 3*FeynCalc`CA^2*Global`v^5*Global`w^6 - 
          4*FeynCalc`CA^3*Global`v^5*Global`w^6 + 8*FeynCalc`CA^4*Global`v^5*
           Global`w^6 + Global`v^6*Global`w^6 - 10*FeynCalc`CA*Global`v^6*
           Global`w^6 + 11*FeynCalc`CA^2*Global`v^6*Global`w^6 + 
          14*FeynCalc`CA^3*Global`v^6*Global`w^6 - 12*FeynCalc`CA^4*
           Global`v^6*Global`w^6 + 8*FeynCalc`CA*Global`v^7*Global`w^6 - 
          10*FeynCalc`CA^3*Global`v^7*Global`w^6 + 2*FeynCalc`CA*Global`v^6*
           Global`w^7 - 4*FeynCalc`CA^2*Global`v^6*Global`w^7 - 
          2*FeynCalc`CA^3*Global`v^6*Global`w^7 + 4*FeynCalc`CA^4*Global`v^6*
           Global`w^7 - 2*FeynCalc`CA*Global`v^7*Global`w^7 + 
          2*FeynCalc`CA^3*Global`v^7*Global`w^7)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^2*(-1 + Global`w)*Global`w^2*
         (-1 + Global`v*Global`w)*(1 - Global`v + Global`v*Global`w)) - 
       ((4*FeynCalc`CA - 16*FeynCalc`CA^3 - 20*FeynCalc`CA*Global`v + 
          100*FeynCalc`CA^3*Global`v + 44*FeynCalc`CA*Global`v^2 - 
          284*FeynCalc`CA^3*Global`v^2 - 52*FeynCalc`CA*Global`v^3 + 
          468*FeynCalc`CA^3*Global`v^3 + 32*FeynCalc`CA*Global`v^4 - 
          476*FeynCalc`CA^3*Global`v^4 - 8*FeynCalc`CA*Global`v^5 + 
          296*FeynCalc`CA^3*Global`v^5 - 104*FeynCalc`CA^3*Global`v^6 + 
          16*FeynCalc`CA^3*Global`v^7 - 3*Global`w - 2*FeynCalc`CA*Global`w + 
          18*FeynCalc`CA^2*Global`w + 2*FeynCalc`CA^3*Global`w - 
          15*FeynCalc`CA^4*Global`w + 12*Global`v*Global`w + 
          20*FeynCalc`CA*Global`v*Global`w - 72*FeynCalc`CA^2*Global`v*
           Global`w - 8*FeynCalc`CA^3*Global`v*Global`w + 
          64*FeynCalc`CA^4*Global`v*Global`w - 18*Global`v^2*Global`w - 
          84*FeynCalc`CA*Global`v^2*Global`w + 126*FeynCalc`CA^2*Global`v^2*
           Global`w - 12*FeynCalc`CA^3*Global`v^2*Global`w - 
          128*FeynCalc`CA^4*Global`v^2*Global`w + 10*Global`v^3*Global`w + 
          196*FeynCalc`CA*Global`v^3*Global`w - 118*FeynCalc`CA^2*Global`v^3*
           Global`w + 180*FeynCalc`CA^3*Global`v^3*Global`w + 
          152*FeynCalc`CA^4*Global`v^3*Global`w + 3*Global`v^4*Global`w - 
          278*FeynCalc`CA*Global`v^4*Global`w + 56*FeynCalc`CA^2*Global`v^4*
           Global`w - 578*FeynCalc`CA^3*Global`v^4*Global`w - 
          111*FeynCalc`CA^4*Global`v^4*Global`w - 6*Global`v^5*Global`w + 
          248*FeynCalc`CA*Global`v^5*Global`w - 10*FeynCalc`CA^2*Global`v^5*
           Global`w + 908*FeynCalc`CA^3*Global`v^5*Global`w + 
          48*FeynCalc`CA^4*Global`v^5*Global`w + 2*Global`v^6*Global`w - 
          132*FeynCalc`CA*Global`v^6*Global`w - 772*FeynCalc`CA^3*Global`v^6*
           Global`w - 10*FeynCalc`CA^4*Global`v^6*Global`w + 
          32*FeynCalc`CA*Global`v^7*Global`w + 344*FeynCalc`CA^3*Global`v^7*
           Global`w - 64*FeynCalc`CA^3*Global`v^8*Global`w + Global`w^2 + 
          FeynCalc`CA*Global`w^2 - 2*FeynCalc`CA^2*Global`w^2 - 
          FeynCalc`CA^3*Global`w^2 + FeynCalc`CA^4*Global`w^2 + 
          2*Global`v*Global`w^2 - FeynCalc`CA*Global`v*Global`w^2 - 
          30*FeynCalc`CA^2*Global`v*Global`w^2 + 3*FeynCalc`CA^3*Global`v*
           Global`w^2 + 28*FeynCalc`CA^4*Global`v*Global`w^2 - 
          30*Global`v^2*Global`w^2 - 13*FeynCalc`CA*Global`v^2*Global`w^2 + 
          142*FeynCalc`CA^2*Global`v^2*Global`w^2 + 31*FeynCalc`CA^3*
           Global`v^2*Global`w^2 - 76*FeynCalc`CA^4*Global`v^2*Global`w^2 + 
          2*FeynCalc`CA*Global`nD*Global`v^2*Global`w^2 - 
          2*FeynCalc`CA^3*Global`nD*Global`v^2*Global`w^2 + 
          2*FeynCalc`CA*Global`nU*Global`v^2*Global`w^2 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^2*Global`w^2 + 
          88*Global`v^3*Global`w^2 + 51*FeynCalc`CA*Global`v^3*Global`w^2 - 
          276*FeynCalc`CA^2*Global`v^3*Global`w^2 - 233*FeynCalc`CA^3*
           Global`v^3*Global`w^2 + 100*FeynCalc`CA^4*Global`v^3*Global`w^2 - 
          10*FeynCalc`CA*Global`nD*Global`v^3*Global`w^2 + 
          10*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^2 - 
          10*FeynCalc`CA*Global`nU*Global`v^3*Global`w^2 + 
          10*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^2 - 
          135*Global`v^4*Global`w^2 - 152*FeynCalc`CA*Global`v^4*Global`w^2 + 
          310*FeynCalc`CA^2*Global`v^4*Global`w^2 + 654*FeynCalc`CA^3*
           Global`v^4*Global`w^2 - 127*FeynCalc`CA^4*Global`v^4*Global`w^2 + 
          22*FeynCalc`CA*Global`nD*Global`v^4*Global`w^2 - 
          22*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^2 + 
          22*FeynCalc`CA*Global`nU*Global`v^4*Global`w^2 - 
          22*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^2 + 
          122*Global`v^5*Global`w^2 + 338*FeynCalc`CA*Global`v^5*Global`w^2 - 
          186*FeynCalc`CA^2*Global`v^5*Global`w^2 - 806*FeynCalc`CA^3*
           Global`v^5*Global`w^2 + 116*FeynCalc`CA^4*Global`v^5*Global`w^2 - 
          26*FeynCalc`CA*Global`nD*Global`v^5*Global`w^2 + 
          26*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^2 - 
          26*FeynCalc`CA*Global`nU*Global`v^5*Global`w^2 + 
          26*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^2 - 
          60*Global`v^6*Global`w^2 - 452*FeynCalc`CA*Global`v^6*Global`w^2 + 
          46*FeynCalc`CA^2*Global`v^6*Global`w^2 + 252*FeynCalc`CA^3*
           Global`v^6*Global`w^2 - 62*FeynCalc`CA^4*Global`v^6*Global`w^2 + 
          16*FeynCalc`CA*Global`nD*Global`v^6*Global`w^2 - 
          16*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^2 + 
          16*FeynCalc`CA*Global`nU*Global`v^6*Global`w^2 - 
          16*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^2 + 
          12*Global`v^7*Global`w^2 + 324*FeynCalc`CA*Global`v^7*Global`w^2 - 
          4*FeynCalc`CA^2*Global`v^7*Global`w^2 + 356*FeynCalc`CA^3*
           Global`v^7*Global`w^2 + 20*FeynCalc`CA^4*Global`v^7*Global`w^2 - 
          4*FeynCalc`CA*Global`nD*Global`v^7*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^2 - 
          4*FeynCalc`CA*Global`nU*Global`v^7*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^2 - 
          96*FeynCalc`CA*Global`v^8*Global`w^2 - 352*FeynCalc`CA^3*Global`v^8*
           Global`w^2 + 96*FeynCalc`CA^3*Global`v^9*Global`w^2 - 
          2*Global`v*Global`w^3 - 2*FeynCalc`CA*Global`v*Global`w^3 + 
          4*FeynCalc`CA^2*Global`v*Global`w^3 + 2*FeynCalc`CA^3*Global`v*
           Global`w^3 - 2*FeynCalc`CA^4*Global`v*Global`w^3 + 
          13*Global`v^2*Global`w^3 + 14*FeynCalc`CA*Global`v^2*Global`w^3 - 
          34*FeynCalc`CA^2*Global`v^2*Global`w^3 - 18*FeynCalc`CA^3*
           Global`v^2*Global`w^3 + 21*FeynCalc`CA^4*Global`v^2*Global`w^3 - 
          28*Global`v^3*Global`w^3 - 46*FeynCalc`CA*Global`v^3*Global`w^3 + 
          64*FeynCalc`CA^2*Global`v^3*Global`w^3 + 76*FeynCalc`CA^3*
           Global`v^3*Global`w^3 - 28*FeynCalc`CA^4*Global`v^3*Global`w^3 + 
          4*FeynCalc`CA*Global`nD*Global`v^3*Global`w^3 - 
          4*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^3 + 
          4*FeynCalc`CA*Global`nU*Global`v^3*Global`w^3 - 
          4*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^3 + 
          30*Global`v^4*Global`w^3 + 176*FeynCalc`CA*Global`v^4*Global`w^3 - 
          72*FeynCalc`CA^2*Global`v^4*Global`w^3 - 144*FeynCalc`CA^3*
           Global`v^4*Global`w^3 + 94*FeynCalc`CA^4*Global`v^4*Global`w^3 - 
          20*FeynCalc`CA*Global`nD*Global`v^4*Global`w^3 + 
          20*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^3 - 
          20*FeynCalc`CA*Global`nU*Global`v^4*Global`w^3 + 
          20*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^3 + 
          12*Global`v^5*Global`w^3 - 476*FeynCalc`CA*Global`v^5*Global`w^3 - 
          30*FeynCalc`CA^2*Global`v^5*Global`w^3 - 150*FeynCalc`CA^3*
           Global`v^5*Global`w^3 - 70*FeynCalc`CA^4*Global`v^5*Global`w^3 + 
          40*FeynCalc`CA*Global`nD*Global`v^5*Global`w^3 - 
          40*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^3 + 
          40*FeynCalc`CA*Global`nU*Global`v^5*Global`w^3 - 
          40*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^3 - 
          93*Global`v^6*Global`w^3 + 626*FeynCalc`CA*Global`v^6*Global`w^3 + 
          108*FeynCalc`CA^2*Global`v^6*Global`w^3 + 918*FeynCalc`CA^3*
           Global`v^6*Global`w^3 - 39*FeynCalc`CA^4*Global`v^6*Global`w^3 - 
          36*FeynCalc`CA*Global`nD*Global`v^6*Global`w^3 + 
          36*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^3 - 
          36*FeynCalc`CA*Global`nU*Global`v^6*Global`w^3 + 
          36*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^3 + 
          104*Global`v^7*Global`w^3 - 292*FeynCalc`CA*Global`v^7*Global`w^3 - 
          40*FeynCalc`CA^2*Global`v^7*Global`w^3 - 1172*FeynCalc`CA^3*
           Global`v^7*Global`w^3 + 48*FeynCalc`CA^4*Global`v^7*Global`w^3 + 
          12*FeynCalc`CA*Global`nD*Global`v^7*Global`w^3 - 
          12*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^3 + 
          12*FeynCalc`CA*Global`nU*Global`v^7*Global`w^3 - 
          12*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^3 - 
          36*Global`v^8*Global`w^3 - 96*FeynCalc`CA*Global`v^8*Global`w^3 + 
          8*FeynCalc`CA^2*Global`v^8*Global`w^3 + 520*FeynCalc`CA^3*
           Global`v^8*Global`w^3 - 32*FeynCalc`CA^4*Global`v^8*Global`w^3 + 
          96*FeynCalc`CA*Global`v^9*Global`w^3 + 32*FeynCalc`CA^3*Global`v^9*
           Global`w^3 - 64*FeynCalc`CA^3*Global`v^10*Global`w^3 - 
          Global`v^2*Global`w^4 - FeynCalc`CA*Global`v^2*Global`w^4 + 
          2*FeynCalc`CA^2*Global`v^2*Global`w^4 + FeynCalc`CA^3*Global`v^2*
           Global`w^4 - FeynCalc`CA^4*Global`v^2*Global`w^4 - 
          14*Global`v^3*Global`w^4 - 9*FeynCalc`CA*Global`v^3*Global`w^4 + 
          78*FeynCalc`CA^2*Global`v^3*Global`w^4 + 7*FeynCalc`CA^3*Global`v^3*
           Global`w^4 - 64*FeynCalc`CA^4*Global`v^3*Global`w^4 + 
          70*Global`v^4*Global`w^4 + 15*FeynCalc`CA*Global`v^4*Global`w^4 - 
          248*FeynCalc`CA^2*Global`v^4*Global`w^4 - 71*FeynCalc`CA^3*
           Global`v^4*Global`w^4 + 66*FeynCalc`CA^4*Global`v^4*Global`w^4 + 
          6*FeynCalc`CA*Global`nD*Global`v^4*Global`w^4 - 
          6*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^4 + 
          6*FeynCalc`CA*Global`nU*Global`v^4*Global`w^4 - 
          6*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^4 - 
          172*Global`v^5*Global`w^4 + 65*FeynCalc`CA*Global`v^5*Global`w^4 + 
          460*FeynCalc`CA^2*Global`v^5*Global`w^4 + 365*FeynCalc`CA^3*
           Global`v^5*Global`w^4 - 136*FeynCalc`CA^4*Global`v^5*Global`w^4 - 
          30*FeynCalc`CA*Global`nD*Global`v^5*Global`w^4 + 
          30*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^4 - 
          30*FeynCalc`CA*Global`nU*Global`v^5*Global`w^4 + 
          30*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^4 + 
          277*Global`v^6*Global`w^4 + 6*FeynCalc`CA*Global`v^6*Global`w^4 - 
          452*FeynCalc`CA^2*Global`v^6*Global`w^4 - 826*FeynCalc`CA^3*
           Global`v^6*Global`w^4 + 307*FeynCalc`CA^4*Global`v^6*Global`w^4 + 
          52*FeynCalc`CA*Global`nD*Global`v^6*Global`w^4 - 
          52*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^4 + 
          52*FeynCalc`CA*Global`nU*Global`v^6*Global`w^4 - 
          52*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^4 - 
          212*Global`v^7*Global`w^4 - 456*FeynCalc`CA*Global`v^7*Global`w^4 + 
          144*FeynCalc`CA^2*Global`v^7*Global`w^4 + 664*FeynCalc`CA^3*
           Global`v^7*Global`w^4 - 212*FeynCalc`CA^4*Global`v^7*Global`w^4 - 
          40*FeynCalc`CA*Global`nD*Global`v^7*Global`w^4 + 
          40*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^4 - 
          40*FeynCalc`CA*Global`nU*Global`v^7*Global`w^4 + 
          40*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^4 + 
          24*Global`v^8*Global`w^4 + 632*FeynCalc`CA*Global`v^8*Global`w^4 - 
          28*FeynCalc`CA^2*Global`v^8*Global`w^4 + 120*FeynCalc`CA^3*
           Global`v^8*Global`w^4 + 100*FeynCalc`CA^4*Global`v^8*Global`w^4 + 
          16*FeynCalc`CA*Global`nD*Global`v^8*Global`w^4 - 
          16*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^4 + 
          16*FeynCalc`CA*Global`nU*Global`v^8*Global`w^4 - 
          16*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^4 + 
          28*Global`v^9*Global`w^4 - 220*FeynCalc`CA*Global`v^9*Global`w^4 - 
          4*FeynCalc`CA^2*Global`v^9*Global`w^4 - 412*FeynCalc`CA^3*
           Global`v^9*Global`w^4 + 12*FeynCalc`CA^4*Global`v^9*Global`w^4 - 
          4*FeynCalc`CA*Global`nD*Global`v^9*Global`w^4 + 
          4*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^4 - 
          4*FeynCalc`CA*Global`nU*Global`v^9*Global`w^4 + 
          4*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^4 - 
          32*FeynCalc`CA*Global`v^10*Global`w^4 + 136*FeynCalc`CA^3*
           Global`v^10*Global`w^4 + 16*FeynCalc`CA^3*Global`v^11*Global`w^4 + 
          4*Global`v^3*Global`w^5 + 4*FeynCalc`CA*Global`v^3*Global`w^5 - 
          8*FeynCalc`CA^2*Global`v^3*Global`w^5 - 4*FeynCalc`CA^3*Global`v^3*
           Global`w^5 + 4*FeynCalc`CA^4*Global`v^3*Global`w^5 - 
          9*Global`v^4*Global`w^5 - 14*FeynCalc`CA*Global`v^4*Global`w^5 - 
          2*FeynCalc`CA^2*Global`v^4*Global`w^5 + 22*FeynCalc`CA^3*Global`v^4*
           Global`w^5 + 11*FeynCalc`CA^4*Global`v^4*Global`w^5 + 
          10*Global`v^5*Global`w^5 + 4*FeynCalc`CA*Global`v^5*Global`w^5 + 
          50*FeynCalc`CA^2*Global`v^5*Global`w^5 - 80*FeynCalc`CA^3*
           Global`v^5*Global`w^5 + 8*FeynCalc`CA*Global`nD*Global`v^5*
           Global`w^5 - 8*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^5 + 
          8*FeynCalc`CA*Global`nU*Global`v^5*Global`w^5 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^5 - 
          36*Global`v^6*Global`w^5 - 152*FeynCalc`CA*Global`v^6*Global`w^5 - 
          148*FeynCalc`CA^2*Global`v^6*Global`w^5 + 144*FeynCalc`CA^3*
           Global`v^6*Global`w^5 - 180*FeynCalc`CA^4*Global`v^6*Global`w^5 - 
          32*FeynCalc`CA*Global`nD*Global`v^6*Global`w^5 + 
          32*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^5 - 
          32*FeynCalc`CA*Global`nU*Global`v^6*Global`w^5 + 
          32*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^5 - 
          30*Global`v^7*Global`w^5 + 560*FeynCalc`CA*Global`v^7*Global`w^5 + 
          314*FeynCalc`CA^2*Global`v^7*Global`w^5 + 124*FeynCalc`CA^3*
           Global`v^7*Global`w^5 + 100*FeynCalc`CA^4*Global`v^7*Global`w^5 + 
          48*FeynCalc`CA*Global`nD*Global`v^7*Global`w^5 - 
          48*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^5 + 
          48*FeynCalc`CA*Global`nU*Global`v^7*Global`w^5 - 
          48*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^5 + 
          157*Global`v^8*Global`w^5 - 554*FeynCalc`CA*Global`v^8*Global`w^5 - 
          136*FeynCalc`CA^2*Global`v^8*Global`w^5 - 574*FeynCalc`CA^3*
           Global`v^8*Global`w^5 - 65*FeynCalc`CA^4*Global`v^8*Global`w^5 - 
          36*FeynCalc`CA*Global`nD*Global`v^8*Global`w^5 + 
          36*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^5 - 
          36*FeynCalc`CA*Global`nU*Global`v^8*Global`w^5 + 
          36*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^5 - 
          90*Global`v^9*Global`w^5 + 12*FeynCalc`CA*Global`v^9*Global`w^5 + 
          42*FeynCalc`CA^2*Global`v^9*Global`w^5 + 500*FeynCalc`CA^3*
           Global`v^9*Global`w^5 - 48*FeynCalc`CA^4*Global`v^9*Global`w^5 + 
          12*FeynCalc`CA*Global`nD*Global`v^9*Global`w^5 - 
          12*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^5 + 
          12*FeynCalc`CA*Global`nU*Global`v^9*Global`w^5 - 
          12*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^5 - 
          6*Global`v^10*Global`w^5 + 140*FeynCalc`CA*Global`v^10*Global`w^5 - 
          76*FeynCalc`CA^3*Global`v^10*Global`w^5 - 6*FeynCalc`CA^4*
           Global`v^10*Global`w^5 - 56*FeynCalc`CA^3*Global`v^11*Global`w^5 - 
          Global`v^4*Global`w^6 - FeynCalc`CA*Global`v^4*Global`w^6 + 
          2*FeynCalc`CA^2*Global`v^4*Global`w^6 + FeynCalc`CA^3*Global`v^4*
           Global`w^6 - FeynCalc`CA^4*Global`v^4*Global`w^6 + 
          14*Global`v^5*Global`w^6 + 13*FeynCalc`CA*Global`v^5*Global`w^6 - 
          50*FeynCalc`CA^2*Global`v^5*Global`w^6 - 15*FeynCalc`CA^3*
           Global`v^5*Global`w^6 + 36*FeynCalc`CA^4*Global`v^5*Global`w^6 - 
          26*Global`v^6*Global`w^6 + 29*FeynCalc`CA*Global`v^6*Global`w^6 + 
          102*FeynCalc`CA^2*Global`v^6*Global`w^6 + 53*FeynCalc`CA^3*
           Global`v^6*Global`w^6 + 56*FeynCalc`CA^4*Global`v^6*Global`w^6 + 
          6*FeynCalc`CA*Global`nD*Global`v^6*Global`w^6 - 
          6*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^6 + 
          6*FeynCalc`CA*Global`nU*Global`v^6*Global`w^6 - 
          6*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^6 + 
          96*Global`v^7*Global`w^6 - 175*FeynCalc`CA*Global`v^7*Global`w^6 - 
          180*FeynCalc`CA^2*Global`v^7*Global`w^6 - 203*FeynCalc`CA^3*
           Global`v^7*Global`w^6 + 12*FeynCalc`CA^4*Global`v^7*Global`w^6 - 
          22*FeynCalc`CA*Global`nD*Global`v^7*Global`w^6 + 
          22*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^6 - 
          22*FeynCalc`CA*Global`nU*Global`v^7*Global`w^6 + 
          22*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^6 - 
          177*Global`v^8*Global`w^6 + 60*FeynCalc`CA*Global`v^8*Global`w^6 - 
          2*FeynCalc`CA^2*Global`v^8*Global`w^6 + 366*FeynCalc`CA^3*
           Global`v^8*Global`w^6 + 23*FeynCalc`CA^4*Global`v^8*Global`w^6 + 
          30*FeynCalc`CA*Global`nD*Global`v^8*Global`w^6 - 
          30*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^6 + 
          30*FeynCalc`CA*Global`nU*Global`v^8*Global`w^6 - 
          30*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^6 + 
          66*Global`v^9*Global`w^6 + 286*FeynCalc`CA*Global`v^9*Global`w^6 + 
          2*FeynCalc`CA^2*Global`v^9*Global`w^6 - 242*FeynCalc`CA^3*
           Global`v^9*Global`w^6 + 48*FeynCalc`CA^4*Global`v^9*Global`w^6 - 
          14*FeynCalc`CA*Global`nD*Global`v^9*Global`w^6 + 
          14*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^6 - 
          14*FeynCalc`CA*Global`nU*Global`v^9*Global`w^6 + 
          14*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^6 + 
          28*Global`v^10*Global`w^6 - 204*FeynCalc`CA*Global`v^10*
           Global`w^6 - 10*FeynCalc`CA^2*Global`v^10*Global`w^6 - 
          48*FeynCalc`CA^3*Global`v^10*Global`w^6 + 26*FeynCalc`CA^4*
           Global`v^10*Global`w^6 - 8*FeynCalc`CA*Global`v^11*Global`w^6 + 
          88*FeynCalc`CA^3*Global`v^11*Global`w^6 - 2*Global`v^5*Global`w^7 - 
          2*FeynCalc`CA*Global`v^5*Global`w^7 + 4*FeynCalc`CA^2*Global`v^5*
           Global`w^7 + 2*FeynCalc`CA^3*Global`v^5*Global`w^7 - 
          2*FeynCalc`CA^4*Global`v^5*Global`w^7 - Global`v^6*Global`w^7 + 
          2*FeynCalc`CA*Global`v^6*Global`w^7 + 18*FeynCalc`CA^2*Global`v^6*
           Global`w^7 - 6*FeynCalc`CA^3*Global`v^6*Global`w^7 - 
          17*FeynCalc`CA^4*Global`v^6*Global`w^7 - 16*Global`v^7*Global`w^7 + 
          10*FeynCalc`CA*Global`v^7*Global`w^7 - 28*FeynCalc`CA^2*Global`v^7*
           Global`w^7 + 28*FeynCalc`CA^3*Global`v^7*Global`w^7 - 
          20*FeynCalc`CA^4*Global`v^7*Global`w^7 + 4*FeynCalc`CA*Global`nD*
           Global`v^7*Global`w^7 - 4*FeynCalc`CA^3*Global`nD*Global`v^7*
           Global`w^7 + 4*FeynCalc`CA*Global`nU*Global`v^7*Global`w^7 - 
          4*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^7 + 
          46*Global`v^8*Global`w^7 + 88*FeynCalc`CA*Global`v^8*Global`w^7 + 
          112*FeynCalc`CA^2*Global`v^8*Global`w^7 - 56*FeynCalc`CA^3*
           Global`v^8*Global`w^7 - 2*FeynCalc`CA^4*Global`v^8*Global`w^7 - 
          12*FeynCalc`CA*Global`nD*Global`v^8*Global`w^7 + 
          12*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^7 - 
          12*FeynCalc`CA*Global`nU*Global`v^8*Global`w^7 + 
          12*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^7 + 
          16*Global`v^9*Global`w^7 - 240*FeynCalc`CA*Global`v^9*Global`w^7 - 
          14*FeynCalc`CA^2*Global`v^9*Global`w^7 + 18*FeynCalc`CA^3*
           Global`v^9*Global`w^7 - 22*FeynCalc`CA^4*Global`v^9*Global`w^7 + 
          8*FeynCalc`CA*Global`nD*Global`v^9*Global`w^7 - 
          8*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^7 + 
          8*FeynCalc`CA*Global`nU*Global`v^9*Global`w^7 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^7 - 
          43*Global`v^10*Global`w^7 + 118*FeynCalc`CA*Global`v^10*
           Global`w^7 + 12*FeynCalc`CA^2*Global`v^10*Global`w^7 + 
          98*FeynCalc`CA^3*Global`v^10*Global`w^7 - 41*FeynCalc`CA^4*
           Global`v^10*Global`w^7 + 24*FeynCalc`CA*Global`v^11*Global`w^7 - 
          84*FeynCalc`CA^3*Global`v^11*Global`w^7 + Global`v^6*Global`w^8 + 
          FeynCalc`CA*Global`v^6*Global`w^8 - 2*FeynCalc`CA^2*Global`v^6*
           Global`w^8 - FeynCalc`CA^3*Global`v^6*Global`w^8 + 
          FeynCalc`CA^4*Global`v^6*Global`w^8 - 2*Global`v^7*Global`w^8 - 
          3*FeynCalc`CA*Global`v^7*Global`w^8 + 2*FeynCalc`CA^2*Global`v^7*
           Global`w^8 + 5*FeynCalc`CA^3*Global`v^7*Global`w^8 + 
          2*Global`v^8*Global`w^8 - 23*FeynCalc`CA*Global`v^8*Global`w^8 - 
          20*FeynCalc`CA^2*Global`v^8*Global`w^8 - 9*FeynCalc`CA^3*Global`v^8*
           Global`w^8 - 6*FeynCalc`CA^4*Global`v^8*Global`w^8 + 
          2*FeynCalc`CA*Global`nD*Global`v^8*Global`w^8 - 
          2*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^8 + 
          2*FeynCalc`CA*Global`nU*Global`v^8*Global`w^8 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^8 - 
          28*Global`v^9*Global`w^8 + 67*FeynCalc`CA*Global`v^9*Global`w^8 - 
          36*FeynCalc`CA^2*Global`v^9*Global`w^8 + 15*FeynCalc`CA^3*
           Global`v^9*Global`w^8 + 8*FeynCalc`CA^4*Global`v^9*Global`w^8 - 
          2*FeynCalc`CA*Global`nD*Global`v^9*Global`w^8 + 
          2*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^8 - 
          2*FeynCalc`CA*Global`nU*Global`v^9*Global`w^8 + 
          2*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^8 + 
          27*Global`v^10*Global`w^8 - 14*FeynCalc`CA*Global`v^10*Global`w^8 - 
          8*FeynCalc`CA^2*Global`v^10*Global`w^8 - 62*FeynCalc`CA^3*
           Global`v^10*Global`w^8 + 37*FeynCalc`CA^4*Global`v^10*Global`w^8 - 
          28*FeynCalc`CA*Global`v^11*Global`w^8 + 52*FeynCalc`CA^3*
           Global`v^11*Global`w^8 + 6*Global`v^9*Global`w^9 - 
          4*FeynCalc`CA*Global`v^9*Global`w^9 + 18*FeynCalc`CA^2*Global`v^9*
           Global`w^9 - 6*Global`v^10*Global`w^9 - 12*FeynCalc`CA*Global`v^10*
           Global`w^9 + 14*FeynCalc`CA^2*Global`v^10*Global`w^9 + 
          20*FeynCalc`CA^3*Global`v^10*Global`w^9 - 24*FeynCalc`CA^4*
           Global`v^10*Global`w^9 + 16*FeynCalc`CA*Global`v^11*Global`w^9 - 
          20*FeynCalc`CA^3*Global`v^11*Global`w^9 + 4*FeynCalc`CA*Global`v^10*
           Global`w^10 - 8*FeynCalc`CA^2*Global`v^10*Global`w^10 - 
          4*FeynCalc`CA^3*Global`v^10*Global`w^10 + 8*FeynCalc`CA^4*
           Global`v^10*Global`w^10 - 4*FeynCalc`CA*Global`v^11*Global`w^10 + 
          4*FeynCalc`CA^3*Global`v^11*Global`w^10)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`v])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^2*Global`w^2*(-1 + Global`v*Global`w)^4*
         (1 - Global`v + Global`v*Global`w)^2) - 
       ((4*FeynCalc`CA - 12*FeynCalc`CA^3 - 20*FeynCalc`CA*Global`v + 
          76*FeynCalc`CA^3*Global`v + 44*FeynCalc`CA*Global`v^2 - 
          220*FeynCalc`CA^3*Global`v^2 - 52*FeynCalc`CA*Global`v^3 + 
          372*FeynCalc`CA^3*Global`v^3 + 32*FeynCalc`CA*Global`v^4 - 
          392*FeynCalc`CA^3*Global`v^4 - 8*FeynCalc`CA*Global`v^5 + 
          256*FeynCalc`CA^3*Global`v^5 - 96*FeynCalc`CA^3*Global`v^6 + 
          16*FeynCalc`CA^3*Global`v^7 - 5*Global`w - 2*FeynCalc`CA*Global`w + 
          16*FeynCalc`CA^2*Global`w + 2*FeynCalc`CA^3*Global`w - 
          11*FeynCalc`CA^4*Global`w + 24*Global`v*Global`w + 
          16*FeynCalc`CA*Global`v*Global`w - 62*FeynCalc`CA^2*Global`v*
           Global`w - 8*FeynCalc`CA^3*Global`v*Global`w + 
          46*FeynCalc`CA^4*Global`v*Global`w - 50*Global`v^2*Global`w - 
          60*FeynCalc`CA*Global`v^2*Global`w + 104*FeynCalc`CA^2*Global`v^2*
           Global`w - 8*FeynCalc`CA^3*Global`v^2*Global`w - 
          92*FeynCalc`CA^4*Global`v^2*Global`w + 62*Global`v^3*Global`w + 
          140*FeynCalc`CA*Global`v^3*Global`w - 88*FeynCalc`CA^2*Global`v^3*
           Global`w + 148*FeynCalc`CA^3*Global`v^3*Global`w + 
          110*FeynCalc`CA^4*Global`v^3*Global`w - 51*Global`v^4*Global`w - 
          214*FeynCalc`CA*Global`v^4*Global`w + 28*FeynCalc`CA^2*Global`v^4*
           Global`w - 482*FeynCalc`CA^3*Global`v^4*Global`w - 
          81*FeynCalc`CA^4*Global`v^4*Global`w + 26*Global`v^5*Global`w + 
          212*FeynCalc`CA*Global`v^5*Global`w + 6*FeynCalc`CA^2*Global`v^5*
           Global`w + 772*FeynCalc`CA^3*Global`v^5*Global`w + 
          36*FeynCalc`CA^4*Global`v^5*Global`w - 6*Global`v^6*Global`w - 
          124*FeynCalc`CA*Global`v^6*Global`w - 4*FeynCalc`CA^2*Global`v^6*
           Global`w - 680*FeynCalc`CA^3*Global`v^6*Global`w - 
          8*FeynCalc`CA^4*Global`v^6*Global`w + 32*FeynCalc`CA*Global`v^7*
           Global`w + 320*FeynCalc`CA^3*Global`v^7*Global`w - 
          64*FeynCalc`CA^3*Global`v^8*Global`w + Global`w^2 + 
          FeynCalc`CA*Global`w^2 - 2*FeynCalc`CA^2*Global`w^2 - 
          FeynCalc`CA^3*Global`w^2 + FeynCalc`CA^4*Global`w^2 + 
          4*Global`v*Global`w^2 - FeynCalc`CA*Global`v*Global`w^2 - 
          28*FeynCalc`CA^2*Global`v*Global`w^2 + 3*FeynCalc`CA^3*Global`v*
           Global`w^2 + 20*FeynCalc`CA^4*Global`v*Global`w^2 - 
          46*Global`v^2*Global`w^2 - 17*FeynCalc`CA*Global`v^2*Global`w^2 + 
          120*FeynCalc`CA^2*Global`v^2*Global`w^2 + 23*FeynCalc`CA^3*
           Global`v^2*Global`w^2 - 50*FeynCalc`CA^4*Global`v^2*Global`w^2 + 
          2*FeynCalc`CA*Global`nD*Global`v^2*Global`w^2 - 
          2*FeynCalc`CA^3*Global`nD*Global`v^2*Global`w^2 + 
          2*FeynCalc`CA*Global`nU*Global`v^2*Global`w^2 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^2*Global`w^2 + 
          136*Global`v^3*Global`w^2 + 59*FeynCalc`CA*Global`v^3*Global`w^2 - 
          222*FeynCalc`CA^2*Global`v^3*Global`w^2 - 177*FeynCalc`CA^3*
           Global`v^3*Global`w^2 + 60*FeynCalc`CA^4*Global`v^3*Global`w^2 - 
          10*FeynCalc`CA*Global`nD*Global`v^3*Global`w^2 + 
          10*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^2 - 
          10*FeynCalc`CA*Global`nU*Global`v^3*Global`w^2 + 
          10*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^2 - 
          219*Global`v^4*Global`w^2 - 136*FeynCalc`CA*Global`v^4*Global`w^2 + 
          240*FeynCalc`CA^2*Global`v^4*Global`w^2 + 490*FeynCalc`CA^3*
           Global`v^4*Global`w^2 - 75*FeynCalc`CA^4*Global`v^4*Global`w^2 + 
          22*FeynCalc`CA*Global`nD*Global`v^4*Global`w^2 - 
          22*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^2 + 
          22*FeynCalc`CA*Global`nU*Global`v^4*Global`w^2 - 
          22*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^2 + 
          224*Global`v^5*Global`w^2 + 282*FeynCalc`CA*Global`v^5*Global`w^2 - 
          114*FeynCalc`CA^2*Global`v^5*Global`w^2 - 582*FeynCalc`CA^3*
           Global`v^5*Global`w^2 + 64*FeynCalc`CA^4*Global`v^5*Global`w^2 - 
          26*FeynCalc`CA*Global`nD*Global`v^5*Global`w^2 + 
          26*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^2 - 
          26*FeynCalc`CA*Global`nU*Global`v^5*Global`w^2 + 
          26*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^2 - 
          136*Global`v^6*Global`w^2 - 400*FeynCalc`CA*Global`v^6*Global`w^2 - 
          6*FeynCalc`CA^2*Global`v^6*Global`w^2 + 128*FeynCalc`CA^3*
           Global`v^6*Global`w^2 - 36*FeynCalc`CA^4*Global`v^6*Global`w^2 + 
          16*FeynCalc`CA*Global`nD*Global`v^6*Global`w^2 - 
          16*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^2 + 
          16*FeynCalc`CA*Global`nU*Global`v^6*Global`w^2 - 
          16*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^2 + 
          36*Global`v^7*Global`w^2 + 308*FeynCalc`CA*Global`v^7*Global`w^2 + 
          12*FeynCalc`CA^2*Global`v^7*Global`w^2 + 356*FeynCalc`CA^3*
           Global`v^7*Global`w^2 + 16*FeynCalc`CA^4*Global`v^7*Global`w^2 - 
          4*FeynCalc`CA*Global`nD*Global`v^7*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^2 - 
          4*FeynCalc`CA*Global`nU*Global`v^7*Global`w^2 + 
          4*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^2 - 
          96*FeynCalc`CA*Global`v^8*Global`w^2 - 336*FeynCalc`CA^3*Global`v^8*
           Global`w^2 + 96*FeynCalc`CA^3*Global`v^9*Global`w^2 - 
          2*Global`v*Global`w^3 - 2*FeynCalc`CA*Global`v*Global`w^3 + 
          4*FeynCalc`CA^2*Global`v*Global`w^3 + 2*FeynCalc`CA^3*Global`v*
           Global`w^3 - 2*FeynCalc`CA^4*Global`v*Global`w^3 + 
          23*Global`v^2*Global`w^3 + 14*FeynCalc`CA*Global`v^2*Global`w^3 - 
          28*FeynCalc`CA^2*Global`v^2*Global`w^3 - 18*FeynCalc`CA^3*
           Global`v^2*Global`w^3 + 17*FeynCalc`CA^4*Global`v^2*Global`w^3 - 
          60*Global`v^3*Global`w^3 - 34*FeynCalc`CA*Global`v^3*Global`w^3 + 
          52*FeynCalc`CA^2*Global`v^3*Global`w^3 + 72*FeynCalc`CA^3*
           Global`v^3*Global`w^3 - 20*FeynCalc`CA^4*Global`v^3*Global`w^3 + 
          4*FeynCalc`CA*Global`nD*Global`v^3*Global`w^3 - 
          4*FeynCalc`CA^3*Global`nD*Global`v^3*Global`w^3 + 
          4*FeynCalc`CA*Global`nU*Global`v^3*Global`w^3 - 
          4*FeynCalc`CA^3*Global`nU*Global`v^3*Global`w^3 + 
          66*Global`v^4*Global`w^3 + 104*FeynCalc`CA*Global`v^4*Global`w^3 - 
          76*FeynCalc`CA^2*Global`v^4*Global`w^3 - 124*FeynCalc`CA^3*
           Global`v^4*Global`w^3 + 64*FeynCalc`CA^4*Global`v^4*Global`w^3 - 
          20*FeynCalc`CA*Global`nD*Global`v^4*Global`w^3 + 
          20*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^3 - 
          20*FeynCalc`CA*Global`nU*Global`v^4*Global`w^3 + 
          20*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^3 - 
          8*Global`v^5*Global`w^3 - 328*FeynCalc`CA*Global`v^5*Global`w^3 - 
          24*FeynCalc`CA^2*Global`v^5*Global`w^3 - 126*FeynCalc`CA^3*
           Global`v^5*Global`w^3 - 28*FeynCalc`CA^4*Global`v^5*Global`w^3 + 
          40*FeynCalc`CA*Global`nD*Global`v^5*Global`w^3 - 
          40*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^3 + 
          40*FeynCalc`CA*Global`nU*Global`v^5*Global`w^3 - 
          40*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^3 - 
          103*Global`v^6*Global`w^3 + 498*FeynCalc`CA*Global`v^6*Global`w^3 + 
          88*FeynCalc`CA^2*Global`v^6*Global`w^3 + 730*FeynCalc`CA^3*
           Global`v^6*Global`w^3 - 43*FeynCalc`CA^4*Global`v^6*Global`w^3 - 
          36*FeynCalc`CA*Global`nD*Global`v^6*Global`w^3 + 
          36*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^3 - 
          36*FeynCalc`CA*Global`nU*Global`v^6*Global`w^3 + 
          36*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^3 + 
          144*Global`v^7*Global`w^3 - 252*FeynCalc`CA*Global`v^7*Global`w^3 + 
          8*FeynCalc`CA^2*Global`v^7*Global`w^3 - 912*FeynCalc`CA^3*
           Global`v^7*Global`w^3 + 36*FeynCalc`CA^4*Global`v^7*Global`w^3 + 
          12*FeynCalc`CA*Global`nD*Global`v^7*Global`w^3 - 
          12*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^3 + 
          12*FeynCalc`CA*Global`nU*Global`v^7*Global`w^3 - 
          12*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^3 - 
          60*Global`v^8*Global`w^3 - 96*FeynCalc`CA*Global`v^8*Global`w^3 - 
          16*FeynCalc`CA^2*Global`v^8*Global`w^3 + 392*FeynCalc`CA^3*
           Global`v^8*Global`w^3 - 32*FeynCalc`CA^4*Global`v^8*Global`w^3 + 
          96*FeynCalc`CA*Global`v^9*Global`w^3 + 48*FeynCalc`CA^3*Global`v^9*
           Global`w^3 - 64*FeynCalc`CA^3*Global`v^10*Global`w^3 - 
          Global`v^2*Global`w^4 - FeynCalc`CA*Global`v^2*Global`w^4 + 
          2*FeynCalc`CA^2*Global`v^2*Global`w^4 + FeynCalc`CA^3*Global`v^2*
           Global`w^4 - FeynCalc`CA^4*Global`v^2*Global`w^4 - 
          32*Global`v^3*Global`w^4 - 9*FeynCalc`CA*Global`v^3*Global`w^4 + 
          68*FeynCalc`CA^2*Global`v^3*Global`w^4 + 7*FeynCalc`CA^3*Global`v^3*
           Global`w^4 - 48*FeynCalc`CA^4*Global`v^3*Global`w^4 + 
          146*Global`v^4*Global`w^4 + 27*FeynCalc`CA*Global`v^4*Global`w^4 - 
          186*FeynCalc`CA^2*Global`v^4*Global`w^4 - 71*FeynCalc`CA^3*
           Global`v^4*Global`w^4 + 52*FeynCalc`CA^4*Global`v^4*Global`w^4 + 
          6*FeynCalc`CA*Global`nD*Global`v^4*Global`w^4 - 
          6*FeynCalc`CA^3*Global`nD*Global`v^4*Global`w^4 + 
          6*FeynCalc`CA*Global`nU*Global`v^4*Global`w^4 - 
          6*FeynCalc`CA^3*Global`nU*Global`v^4*Global`w^4 - 
          284*Global`v^5*Global`w^4 + 41*FeynCalc`CA*Global`v^5*Global`w^4 + 
          374*FeynCalc`CA^2*Global`v^5*Global`w^4 + 317*FeynCalc`CA^3*
           Global`v^5*Global`w^4 - 140*FeynCalc`CA^4*Global`v^5*Global`w^4 - 
          30*FeynCalc`CA*Global`nD*Global`v^5*Global`w^4 + 
          30*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^4 - 
          30*FeynCalc`CA*Global`nU*Global`v^5*Global`w^4 + 
          30*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^4 + 
          363*Global`v^6*Global`w^4 - 22*FeynCalc`CA*Global`v^6*Global`w^4 - 
          370*FeynCalc`CA^2*Global`v^6*Global`w^4 - 638*FeynCalc`CA^3*
           Global`v^6*Global`w^4 + 277*FeynCalc`CA^4*Global`v^6*Global`w^4 + 
          52*FeynCalc`CA*Global`nD*Global`v^6*Global`w^4 - 
          52*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^4 + 
          52*FeynCalc`CA*Global`nU*Global`v^6*Global`w^4 - 
          52*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^4 - 
          268*Global`v^7*Global`w^4 - 360*FeynCalc`CA*Global`v^7*Global`w^4 + 
          64*FeynCalc`CA^2*Global`v^7*Global`w^4 + 448*FeynCalc`CA^3*
           Global`v^7*Global`w^4 - 184*FeynCalc`CA^4*Global`v^7*Global`w^4 - 
          40*FeynCalc`CA*Global`nD*Global`v^7*Global`w^4 + 
          40*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^4 - 
          40*FeynCalc`CA*Global`nU*Global`v^7*Global`w^4 + 
          40*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^4 + 
          40*Global`v^8*Global`w^4 + 560*FeynCalc`CA*Global`v^8*Global`w^4 - 
          20*FeynCalc`CA^2*Global`v^8*Global`w^4 + 156*FeynCalc`CA^3*
           Global`v^8*Global`w^4 + 100*FeynCalc`CA^4*Global`v^8*Global`w^4 + 
          16*FeynCalc`CA*Global`nD*Global`v^8*Global`w^4 - 
          16*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^4 + 
          16*FeynCalc`CA*Global`nU*Global`v^8*Global`w^4 - 
          16*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^4 + 
          36*Global`v^9*Global`w^4 - 204*FeynCalc`CA*Global`v^9*Global`w^4 + 
          12*FeynCalc`CA^2*Global`v^9*Global`w^4 - 348*FeynCalc`CA^3*
           Global`v^9*Global`w^4 + 16*FeynCalc`CA^4*Global`v^9*Global`w^4 - 
          4*FeynCalc`CA*Global`nD*Global`v^9*Global`w^4 + 
          4*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^4 - 
          4*FeynCalc`CA*Global`nU*Global`v^9*Global`w^4 + 
          4*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^4 - 
          32*FeynCalc`CA*Global`v^10*Global`w^4 + 112*FeynCalc`CA^3*
           Global`v^10*Global`w^4 + 16*FeynCalc`CA^3*Global`v^11*Global`w^4 + 
          4*Global`v^3*Global`w^5 + 4*FeynCalc`CA*Global`v^3*Global`w^5 - 
          8*FeynCalc`CA^2*Global`v^3*Global`w^5 - 4*FeynCalc`CA^3*Global`v^3*
           Global`w^5 + 4*FeynCalc`CA^4*Global`v^3*Global`w^5 - 
          7*Global`v^4*Global`w^5 - 14*FeynCalc`CA*Global`v^4*Global`w^5 + 
          4*FeynCalc`CA^2*Global`v^4*Global`w^5 + 22*FeynCalc`CA^3*Global`v^4*
           Global`w^5 + 7*FeynCalc`CA^4*Global`v^4*Global`w^5 - 
          30*Global`v^5*Global`w^5 - 8*FeynCalc`CA*Global`v^5*Global`w^5 + 
          10*FeynCalc`CA^2*Global`v^5*Global`w^5 - 68*FeynCalc`CA^3*
           Global`v^5*Global`w^5 + 4*FeynCalc`CA^4*Global`v^5*Global`w^5 + 
          8*FeynCalc`CA*Global`nD*Global`v^5*Global`w^5 - 
          8*FeynCalc`CA^3*Global`nD*Global`v^5*Global`w^5 + 
          8*FeynCalc`CA*Global`nU*Global`v^5*Global`w^5 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^5*Global`w^5 + 
          56*Global`v^6*Global`w^5 - 80*FeynCalc`CA*Global`v^6*Global`w^5 - 
          76*FeynCalc`CA^2*Global`v^6*Global`w^5 + 84*FeynCalc`CA^3*
           Global`v^6*Global`w^5 - 130*FeynCalc`CA^4*Global`v^6*Global`w^5 - 
          32*FeynCalc`CA*Global`nD*Global`v^6*Global`w^5 + 
          32*FeynCalc`CA^3*Global`nD*Global`v^6*Global`w^5 - 
          32*FeynCalc`CA*Global`nU*Global`v^6*Global`w^5 + 
          32*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^5 - 
          94*Global`v^7*Global`w^5 + 432*FeynCalc`CA*Global`v^7*Global`w^5 + 
          276*FeynCalc`CA^2*Global`v^7*Global`w^5 + 152*FeynCalc`CA^3*
           Global`v^7*Global`w^5 + 50*FeynCalc`CA^4*Global`v^7*Global`w^5 + 
          48*FeynCalc`CA*Global`nD*Global`v^7*Global`w^5 - 
          48*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^5 + 
          48*FeynCalc`CA*Global`nU*Global`v^7*Global`w^5 - 
          48*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^5 + 
          175*Global`v^8*Global`w^5 - 474*FeynCalc`CA*Global`v^8*Global`w^5 - 
          76*FeynCalc`CA^2*Global`v^8*Global`w^5 - 446*FeynCalc`CA^3*
           Global`v^8*Global`w^5 - 55*FeynCalc`CA^4*Global`v^8*Global`w^5 - 
          36*FeynCalc`CA*Global`nD*Global`v^8*Global`w^5 + 
          36*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^5 - 
          36*FeynCalc`CA*Global`nU*Global`v^8*Global`w^5 + 
          36*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^5 - 
          98*Global`v^9*Global`w^5 + 8*FeynCalc`CA*Global`v^9*Global`w^5 + 
          10*FeynCalc`CA^2*Global`v^9*Global`w^5 + 348*FeynCalc`CA^3*
           Global`v^9*Global`w^5 - 56*FeynCalc`CA^4*Global`v^9*Global`w^5 + 
          12*FeynCalc`CA*Global`nD*Global`v^9*Global`w^5 - 
          12*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^5 + 
          12*FeynCalc`CA*Global`nU*Global`v^9*Global`w^5 - 
          12*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^5 - 
          6*Global`v^10*Global`w^5 + 132*FeynCalc`CA*Global`v^10*Global`w^5 - 
          4*FeynCalc`CA^2*Global`v^10*Global`w^5 - 40*FeynCalc`CA^3*
           Global`v^10*Global`w^5 - 8*FeynCalc`CA^4*Global`v^10*Global`w^5 - 
          48*FeynCalc`CA^3*Global`v^11*Global`w^5 - Global`v^4*Global`w^6 - 
          FeynCalc`CA*Global`v^4*Global`w^6 + 2*FeynCalc`CA^2*Global`v^4*
           Global`w^6 + FeynCalc`CA^3*Global`v^4*Global`w^6 - 
          FeynCalc`CA^4*Global`v^4*Global`w^6 + 28*Global`v^5*Global`w^6 + 
          13*FeynCalc`CA*Global`v^5*Global`w^6 - 52*FeynCalc`CA^2*Global`v^5*
           Global`w^6 - 15*FeynCalc`CA^3*Global`v^5*Global`w^6 + 
          28*FeynCalc`CA^4*Global`v^5*Global`w^6 - 50*Global`v^6*Global`w^6 + 
          17*FeynCalc`CA*Global`v^6*Global`w^6 + 92*FeynCalc`CA^2*Global`v^6*
           Global`w^6 + 61*FeynCalc`CA^3*Global`v^6*Global`w^6 + 
          38*FeynCalc`CA^4*Global`v^6*Global`w^6 + 6*FeynCalc`CA*Global`nD*
           Global`v^6*Global`w^6 - 6*FeynCalc`CA^3*Global`nD*Global`v^6*
           Global`w^6 + 6*FeynCalc`CA*Global`nU*Global`v^6*Global`w^6 - 
          6*FeynCalc`CA^3*Global`nU*Global`v^6*Global`w^6 + 
          80*Global`v^7*Global`w^6 - 151*FeynCalc`CA*Global`v^7*Global`w^6 - 
          186*FeynCalc`CA^2*Global`v^7*Global`w^6 - 179*FeynCalc`CA^3*
           Global`v^7*Global`w^6 + 28*FeynCalc`CA^4*Global`v^7*Global`w^6 - 
          22*FeynCalc`CA*Global`nD*Global`v^7*Global`w^6 + 
          22*FeynCalc`CA^3*Global`nD*Global`v^7*Global`w^6 - 
          22*FeynCalc`CA*Global`nU*Global`v^7*Global`w^6 + 
          22*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^6 - 
          133*Global`v^8*Global`w^6 + 68*FeynCalc`CA*Global`v^8*Global`w^6 - 
          20*FeynCalc`CA^2*Global`v^8*Global`w^6 + 250*FeynCalc`CA^3*
           Global`v^8*Global`w^6 + 35*FeynCalc`CA^4*Global`v^8*Global`w^6 + 
          30*FeynCalc`CA*Global`nD*Global`v^8*Global`w^6 - 
          30*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^6 + 
          30*FeynCalc`CA*Global`nU*Global`v^8*Global`w^6 - 
          30*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^6 + 
          52*Global`v^9*Global`w^6 + 246*FeynCalc`CA*Global`v^9*Global`w^6 + 
          10*FeynCalc`CA^2*Global`v^9*Global`w^6 - 138*FeynCalc`CA^3*
           Global`v^9*Global`w^6 + 40*FeynCalc`CA^4*Global`v^9*Global`w^6 - 
          14*FeynCalc`CA*Global`nD*Global`v^9*Global`w^6 + 
          14*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^6 - 
          14*FeynCalc`CA*Global`nU*Global`v^9*Global`w^6 + 
          14*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^6 + 
          24*Global`v^10*Global`w^6 - 184*FeynCalc`CA*Global`v^10*
           Global`w^6 + 2*FeynCalc`CA^2*Global`v^10*Global`w^6 - 
          44*FeynCalc`CA^3*Global`v^10*Global`w^6 + 32*FeynCalc`CA^4*
           Global`v^10*Global`w^6 - 8*FeynCalc`CA*Global`v^11*Global`w^6 + 
          64*FeynCalc`CA^3*Global`v^11*Global`w^6 - 2*Global`v^5*Global`w^7 - 
          2*FeynCalc`CA*Global`v^5*Global`w^7 + 4*FeynCalc`CA^2*Global`v^5*
           Global`w^7 + 2*FeynCalc`CA^3*Global`v^5*Global`w^7 - 
          2*FeynCalc`CA^4*Global`v^5*Global`w^7 - 11*Global`v^6*Global`w^7 + 
          2*FeynCalc`CA*Global`v^6*Global`w^7 + 12*FeynCalc`CA^2*Global`v^6*
           Global`w^7 - 6*FeynCalc`CA^3*Global`v^6*Global`w^7 - 
          13*FeynCalc`CA^4*Global`v^6*Global`w^7 + 16*Global`v^7*Global`w^7 + 
          14*FeynCalc`CA*Global`v^7*Global`w^7 - 16*FeynCalc`CA^2*Global`v^7*
           Global`w^7 + 16*FeynCalc`CA^3*Global`v^7*Global`w^7 - 
          12*FeynCalc`CA^4*Global`v^7*Global`w^7 + 4*FeynCalc`CA*Global`nD*
           Global`v^7*Global`w^7 - 4*FeynCalc`CA^3*Global`nD*Global`v^7*
           Global`w^7 + 4*FeynCalc`CA*Global`nU*Global`v^7*Global`w^7 - 
          4*FeynCalc`CA^3*Global`nU*Global`v^7*Global`w^7 + 
          10*Global`v^8*Global`w^7 + 64*FeynCalc`CA*Global`v^8*Global`w^7 + 
          100*FeynCalc`CA^2*Global`v^8*Global`w^7 - 12*FeynCalc`CA^3*
           Global`v^8*Global`w^7 - 28*FeynCalc`CA^4*Global`v^8*Global`w^7 - 
          12*FeynCalc`CA*Global`nD*Global`v^8*Global`w^7 + 
          12*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^7 - 
          12*FeynCalc`CA*Global`nU*Global`v^8*Global`w^7 + 
          12*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^7 + 
          16*Global`v^9*Global`w^7 - 204*FeynCalc`CA*Global`v^9*Global`w^7 - 
          12*FeynCalc`CA^2*Global`v^9*Global`w^7 - 6*FeynCalc`CA^3*Global`v^9*
           Global`w^7 - 4*FeynCalc`CA^4*Global`v^9*Global`w^7 + 
          8*FeynCalc`CA*Global`nD*Global`v^9*Global`w^7 - 
          8*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^7 + 
          8*FeynCalc`CA*Global`nU*Global`v^9*Global`w^7 - 
          8*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^7 - 
          29*Global`v^10*Global`w^7 + 102*FeynCalc`CA*Global`v^10*
           Global`w^7 + 62*FeynCalc`CA^3*Global`v^10*Global`w^7 - 
          45*FeynCalc`CA^4*Global`v^10*Global`w^7 + 24*FeynCalc`CA*
           Global`v^11*Global`w^7 - 56*FeynCalc`CA^3*Global`v^11*Global`w^7 + 
          Global`v^6*Global`w^8 + FeynCalc`CA*Global`v^6*Global`w^8 - 
          2*FeynCalc`CA^2*Global`v^6*Global`w^8 - FeynCalc`CA^3*Global`v^6*
           Global`w^8 + FeynCalc`CA^4*Global`v^6*Global`w^8 - 
          3*FeynCalc`CA*Global`v^7*Global`w^8 + 12*FeynCalc`CA^2*Global`v^7*
           Global`w^8 + 5*FeynCalc`CA^3*Global`v^7*Global`w^8 - 
          2*Global`v^8*Global`w^8 - 19*FeynCalc`CA*Global`v^8*Global`w^8 - 
          18*FeynCalc`CA^2*Global`v^8*Global`w^8 - 13*FeynCalc`CA^3*
           Global`v^8*Global`w^8 + 2*FeynCalc`CA*Global`nD*Global`v^8*
           Global`w^8 - 2*FeynCalc`CA^3*Global`nD*Global`v^8*Global`w^8 + 
          2*FeynCalc`CA*Global`nU*Global`v^8*Global`w^8 - 
          2*FeynCalc`CA^3*Global`nU*Global`v^8*Global`w^8 - 
          12*Global`v^9*Global`w^8 + 59*FeynCalc`CA*Global`v^9*Global`w^8 - 
          30*FeynCalc`CA^2*Global`v^9*Global`w^8 + 7*FeynCalc`CA^3*Global`v^9*
           Global`w^8 + 4*FeynCalc`CA^4*Global`v^9*Global`w^8 - 
          2*FeynCalc`CA*Global`nD*Global`v^9*Global`w^8 + 
          2*FeynCalc`CA^3*Global`nD*Global`v^9*Global`w^8 - 
          2*FeynCalc`CA*Global`nU*Global`v^9*Global`w^8 + 
          2*FeynCalc`CA^3*Global`nU*Global`v^9*Global`w^8 + 
          13*Global`v^10*Global`w^8 - 10*FeynCalc`CA*Global`v^10*Global`w^8 - 
          2*FeynCalc`CA^2*Global`v^10*Global`w^8 - 34*FeynCalc`CA^3*
           Global`v^10*Global`w^8 + 35*FeynCalc`CA^4*Global`v^10*Global`w^8 - 
          28*FeynCalc`CA*Global`v^11*Global`w^8 + 36*FeynCalc`CA^3*
           Global`v^11*Global`w^8 - 4*FeynCalc`CA^2*Global`v^8*Global`w^9 + 
          2*Global`v^9*Global`w^9 - 4*FeynCalc`CA*Global`v^9*Global`w^9 + 
          16*FeynCalc`CA^2*Global`v^9*Global`w^9 + 4*FeynCalc`CA^3*Global`v^9*
           Global`w^9 - 2*FeynCalc`CA^4*Global`v^9*Global`w^9 - 
          2*Global`v^10*Global`w^9 - 12*FeynCalc`CA*Global`v^10*Global`w^9 + 
          12*FeynCalc`CA^2*Global`v^10*Global`w^9 + 12*FeynCalc`CA^3*
           Global`v^10*Global`w^9 - 22*FeynCalc`CA^4*Global`v^10*Global`w^9 + 
          16*FeynCalc`CA*Global`v^11*Global`w^9 - 16*FeynCalc`CA^3*
           Global`v^11*Global`w^9 + 4*FeynCalc`CA*Global`v^10*Global`w^10 - 
          8*FeynCalc`CA^2*Global`v^10*Global`w^10 - 4*FeynCalc`CA^3*
           Global`v^10*Global`w^10 + 8*FeynCalc`CA^4*Global`v^10*
           Global`w^10 - 4*FeynCalc`CA*Global`v^11*Global`w^10 + 
          4*FeynCalc`CA^3*Global`v^11*Global`w^10)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`w])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^2*Global`w^2*(-1 + Global`v*Global`w)^4*
         (1 - Global`v + Global`v*Global`w)^2) + 
       ((-2*FeynCalc`CA + 4*FeynCalc`CA^3 + 8*FeynCalc`CA*Global`v - 
          22*FeynCalc`CA^3*Global`v - 14*FeynCalc`CA*Global`v^2 + 
          56*FeynCalc`CA^3*Global`v^2 + 12*FeynCalc`CA*Global`v^3 - 
          82*FeynCalc`CA^3*Global`v^3 - 4*FeynCalc`CA*Global`v^4 + 
          72*FeynCalc`CA^3*Global`v^4 - 36*FeynCalc`CA^3*Global`v^5 + 
          8*FeynCalc`CA^3*Global`v^6 + 2*Global`w + 2*FeynCalc`CA*Global`w - 
          5*FeynCalc`CA^2*Global`w - 4*FeynCalc`CA^3*Global`w + 
          3*FeynCalc`CA^4*Global`w - 7*Global`v*Global`w - 
          8*FeynCalc`CA*Global`v*Global`w + 15*FeynCalc`CA^2*Global`v*
           Global`w + 28*FeynCalc`CA^3*Global`v*Global`w - 
          8*FeynCalc`CA^4*Global`v*Global`w + 10*Global`v^2*Global`w + 
          14*FeynCalc`CA*Global`v^2*Global`w - 22*FeynCalc`CA^2*Global`v^2*
           Global`w - 88*FeynCalc`CA^3*Global`v^2*Global`w + 
          12*FeynCalc`CA^4*Global`v^2*Global`w - 7*Global`v^3*Global`w - 
          10*FeynCalc`CA*Global`v^3*Global`w + 17*FeynCalc`CA^2*Global`v^3*
           Global`w + 146*FeynCalc`CA^3*Global`v^3*Global`w - 
          10*FeynCalc`CA^4*Global`v^3*Global`w + 2*Global`v^4*Global`w - 
          2*FeynCalc`CA*Global`v^4*Global`w - 7*FeynCalc`CA^2*Global`v^4*
           Global`w - 126*FeynCalc`CA^3*Global`v^4*Global`w + 
          5*FeynCalc`CA^4*Global`v^4*Global`w + 4*FeynCalc`CA*Global`v^5*
           Global`w + 2*FeynCalc`CA^2*Global`v^5*Global`w + 
          44*FeynCalc`CA^3*Global`v^5*Global`w - 2*FeynCalc`CA^4*Global`v^5*
           Global`w + 8*FeynCalc`CA^3*Global`v^6*Global`w - 
          8*FeynCalc`CA^3*Global`v^7*Global`w - Global`w^2 + 
          FeynCalc`CA^2*Global`w^2 + Global`v*Global`w^2 - 
          5*FeynCalc`CA^2*Global`v*Global`w^2 - 6*FeynCalc`CA^3*Global`v*
           Global`w^2 + 5*FeynCalc`CA^4*Global`v*Global`w^2 + 
          7*Global`v^2*Global`w^2 - 3*FeynCalc`CA*Global`v^2*Global`w^2 + 
          12*FeynCalc`CA^2*Global`v^2*Global`w^2 + 37*FeynCalc`CA^3*
           Global`v^2*Global`w^2 - 16*FeynCalc`CA^4*Global`v^2*Global`w^2 - 
          20*Global`v^3*Global`w^2 + 14*FeynCalc`CA*Global`v^3*Global`w^2 - 
          12*FeynCalc`CA^2*Global`v^3*Global`w^2 - 78*FeynCalc`CA^3*
           Global`v^3*Global`w^2 + 24*FeynCalc`CA^4*Global`v^3*Global`w^2 + 
          25*Global`v^4*Global`w^2 - 21*FeynCalc`CA*Global`v^4*Global`w^2 + 
          47*FeynCalc`CA^3*Global`v^4*Global`w^2 - 16*FeynCalc`CA^4*
           Global`v^4*Global`w^2 - 16*Global`v^5*Global`w^2 + 
          18*FeynCalc`CA*Global`v^5*Global`w^2 + 2*FeynCalc`CA^2*Global`v^5*
           Global`w^2 + 44*FeynCalc`CA^3*Global`v^5*Global`w^2 + 
          7*FeynCalc`CA^4*Global`v^5*Global`w^2 + 4*Global`v^6*Global`w^2 - 
          8*FeynCalc`CA*Global`v^6*Global`w^2 - 2*FeynCalc`CA^2*Global`v^6*
           Global`w^2 - 72*FeynCalc`CA^3*Global`v^6*Global`w^2 + 
          28*FeynCalc`CA^3*Global`v^7*Global`w^2 + Global`v*Global`w^3 + 
          FeynCalc`CA^2*Global`v*Global`w^3 - 5*Global`v^2*Global`w^3 + 
          3*FeynCalc`CA*Global`v^2*Global`w^3 - FeynCalc`CA^2*Global`v^2*
           Global`w^3 - 5*FeynCalc`CA^3*Global`v^2*Global`w^3 + 
          7*FeynCalc`CA^4*Global`v^2*Global`w^3 + 14*Global`v^3*Global`w^3 - 
          24*FeynCalc`CA*Global`v^3*Global`w^3 - 3*FeynCalc`CA^2*Global`v^3*
           Global`w^3 + 14*FeynCalc`CA^3*Global`v^3*Global`w^3 - 
          21*FeynCalc`CA^4*Global`v^3*Global`w^3 - 27*Global`v^4*Global`w^3 + 
          52*FeynCalc`CA*Global`v^4*Global`w^3 + 17*FeynCalc`CA^2*Global`v^4*
           Global`w^3 + 24*FeynCalc`CA^3*Global`v^4*Global`w^3 + 
          21*FeynCalc`CA^4*Global`v^4*Global`w^3 + 27*Global`v^5*Global`w^3 - 
          51*FeynCalc`CA*Global`v^5*Global`w^3 - 11*FeynCalc`CA^2*Global`v^5*
           Global`w^3 - 103*FeynCalc`CA^3*Global`v^5*Global`w^3 - 
          11*FeynCalc`CA^4*Global`v^5*Global`w^3 - 10*Global`v^6*Global`w^3 + 
          20*FeynCalc`CA*Global`v^6*Global`w^3 + 5*FeynCalc`CA^2*Global`v^6*
           Global`w^3 + 110*FeynCalc`CA^3*Global`v^6*Global`w^3 - 
          40*FeynCalc`CA^3*Global`v^7*Global`w^3 - Global`v^2*Global`w^4 - 
          FeynCalc`CA^2*Global`v^2*Global`w^4 - Global`v^3*Global`w^4 + 
          8*FeynCalc`CA*Global`v^3*Global`w^4 + 6*FeynCalc`CA^2*Global`v^3*
           Global`w^4 + 6*FeynCalc`CA^4*Global`v^3*Global`w^4 + 
          15*Global`v^4*Global`w^4 - 28*FeynCalc`CA*Global`v^4*Global`w^4 - 
          20*FeynCalc`CA^2*Global`v^4*Global`w^4 - 22*FeynCalc`CA^3*
           Global`v^4*Global`w^4 - 12*FeynCalc`CA^4*Global`v^4*Global`w^4 - 
          26*Global`v^5*Global`w^4 + 36*FeynCalc`CA*Global`v^5*Global`w^4 + 
          13*FeynCalc`CA^2*Global`v^5*Global`w^4 + 70*FeynCalc`CA^3*
           Global`v^5*Global`w^4 + 9*FeynCalc`CA^4*Global`v^5*Global`w^4 + 
          13*Global`v^6*Global`w^4 - 16*FeynCalc`CA*Global`v^6*Global`w^4 - 
          6*FeynCalc`CA^2*Global`v^6*Global`w^4 - 78*FeynCalc`CA^3*Global`v^6*
           Global`w^4 + FeynCalc`CA^4*Global`v^6*Global`w^4 + 
          30*FeynCalc`CA^3*Global`v^7*Global`w^4 + Global`v^3*Global`w^5 + 
          FeynCalc`CA^2*Global`v^3*Global`w^5 - 7*Global`v^4*Global`w^5 + 
          3*FeynCalc`CA*Global`v^4*Global`w^5 + 6*FeynCalc`CA^2*Global`v^4*
           Global`w^5 + 5*FeynCalc`CA^3*Global`v^4*Global`w^5 + 
          15*Global`v^5*Global`w^5 - 7*FeynCalc`CA*Global`v^5*Global`w^5 - 
          3*FeynCalc`CA^2*Global`v^5*Global`w^5 - 21*FeynCalc`CA^3*Global`v^5*
           Global`w^5 - 2*FeynCalc`CA^4*Global`v^5*Global`w^5 - 
          9*Global`v^6*Global`w^5 + 4*FeynCalc`CA*Global`v^6*Global`w^5 + 
          4*FeynCalc`CA^2*Global`v^6*Global`w^5 + 28*FeynCalc`CA^3*Global`v^6*
           Global`w^5 - 2*FeynCalc`CA^4*Global`v^6*Global`w^5 - 
          12*FeynCalc`CA^3*Global`v^7*Global`w^5 - 2*FeynCalc`CA^2*Global`v^4*
           Global`w^6 - 2*Global`v^5*Global`w^6 - FeynCalc`CA^2*Global`v^5*
           Global`w^6 + 2*FeynCalc`CA^3*Global`v^5*Global`w^6 - 
          FeynCalc`CA^4*Global`v^5*Global`w^6 + 2*Global`v^6*Global`w^6 - 
          FeynCalc`CA^2*Global`v^6*Global`w^6 - 4*FeynCalc`CA^3*Global`v^6*
           Global`w^6 + FeynCalc`CA^4*Global`v^6*Global`w^6 + 
          2*FeynCalc`CA^3*Global`v^7*Global`w^6)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`w])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^2*(-1 + Global`w)*Global`w^2*
         (-1 + Global`v*Global`w)*(1 - Global`v + Global`v*Global`w)) + 
       ((-2*FeynCalc`CA + 2*FeynCalc`CA^3 + 6*FeynCalc`CA*Global`v - 
          6*FeynCalc`CA^3*Global`v - 8*FeynCalc`CA*Global`v^2 + 
          8*FeynCalc`CA^3*Global`v^2 + 4*FeynCalc`CA*Global`v^3 - 
          4*FeynCalc`CA^3*Global`v^3 + 3*Global`w + 2*FeynCalc`CA*Global`w - 
          2*FeynCalc`CA^2*Global`w - 2*FeynCalc`CA^3*Global`w + 
          3*FeynCalc`CA^4*Global`w - 11*Global`v*Global`w - 
          2*FeynCalc`CA*Global`v*Global`w - 2*FeynCalc`CA^2*Global`v*
           Global`w + 8*FeynCalc`CA^3*Global`v*Global`w - 
          4*FeynCalc`CA^4*Global`v*Global`w + 16*Global`v^2*Global`w - 
          6*FeynCalc`CA*Global`v^2*Global`w + 6*FeynCalc`CA^2*Global`v^2*
           Global`w - 18*FeynCalc`CA^3*Global`v^2*Global`w + 
          6*FeynCalc`CA^4*Global`v^2*Global`w - 12*Global`v^3*Global`w + 
          14*FeynCalc`CA*Global`v^3*Global`w - 10*FeynCalc`CA^2*Global`v^3*
           Global`w + 16*FeynCalc`CA^3*Global`v^3*Global`w - 
          3*FeynCalc`CA^4*Global`v^3*Global`w + 4*Global`v^4*Global`w - 
          8*FeynCalc`CA*Global`v^4*Global`w + 4*FeynCalc`CA^2*Global`v^4*
           Global`w - 4*FeynCalc`CA^3*Global`v^4*Global`w + 
          2*FeynCalc`CA^4*Global`v^4*Global`w + Global`v*Global`w^2 - 
          4*FeynCalc`CA*Global`v*Global`w^2 + 5*FeynCalc`CA^2*Global`v*
           Global`w^2 - 2*FeynCalc`CA^3*Global`v*Global`w^2 + 
          6*FeynCalc`CA^4*Global`v*Global`w^2 - 3*Global`v^2*Global`w^2 + 
          14*FeynCalc`CA*Global`v^2*Global`w^2 - FeynCalc`CA^2*Global`v^2*
           Global`w^2 + 16*FeynCalc`CA^3*Global`v^2*Global`w^2 - 
          14*FeynCalc`CA^4*Global`v^2*Global`w^2 + 6*Global`v^3*Global`w^2 - 
          16*FeynCalc`CA*Global`v^3*Global`w^2 + 10*FeynCalc`CA^2*Global`v^3*
           Global`w^2 - 26*FeynCalc`CA^3*Global`v^3*Global`w^2 + 
          13*FeynCalc`CA^4*Global`v^3*Global`w^2 - 4*Global`v^4*Global`w^2 + 
          2*FeynCalc`CA*Global`v^4*Global`w^2 - 6*FeynCalc`CA^2*Global`v^4*
           Global`w^2 + 16*FeynCalc`CA^3*Global`v^4*Global`w^2 - 
          5*FeynCalc`CA^4*Global`v^4*Global`w^2 + 4*FeynCalc`CA*Global`v^5*
           Global`w^2 - 4*FeynCalc`CA^3*Global`v^5*Global`w^2 + 
          Global`v^2*Global`w^3 - 7*FeynCalc`CA^2*Global`v^2*Global`w^3 - 
          6*FeynCalc`CA^3*Global`v^2*Global`w^3 + 14*FeynCalc`CA^4*Global`v^2*
           Global`w^3 - 5*Global`v^3*Global`w^3 - 4*FeynCalc`CA*Global`v^3*
           Global`w^3 - FeynCalc`CA^2*Global`v^3*Global`w^3 + 
          16*FeynCalc`CA^3*Global`v^3*Global`w^3 - 15*FeynCalc`CA^4*
           Global`v^3*Global`w^3 + 4*Global`v^4*Global`w^3 + 
          12*FeynCalc`CA*Global`v^4*Global`w^3 - 18*FeynCalc`CA^3*Global`v^4*
           Global`w^3 + 9*FeynCalc`CA^4*Global`v^4*Global`w^3 - 
          8*FeynCalc`CA*Global`v^5*Global`w^3 + 8*FeynCalc`CA^3*Global`v^5*
           Global`w^3 + Global`v^3*Global`w^4 + 2*FeynCalc`CA*Global`v^3*
           Global`w^4 + 4*FeynCalc`CA^2*Global`v^3*Global`w^4 - 
          2*FeynCalc`CA^3*Global`v^3*Global`w^4 + 7*FeynCalc`CA^4*Global`v^3*
           Global`w^4 - Global`v^4*Global`w^4 - 8*FeynCalc`CA*Global`v^4*
           Global`w^4 + 4*FeynCalc`CA^2*Global`v^4*Global`w^4 + 
          8*FeynCalc`CA^3*Global`v^4*Global`w^4 - 7*FeynCalc`CA^4*Global`v^4*
           Global`w^4 + 6*FeynCalc`CA*Global`v^5*Global`w^4 - 
          6*FeynCalc`CA^3*Global`v^5*Global`w^4 + 2*FeynCalc`CA*Global`v^4*
           Global`w^5 - 4*FeynCalc`CA^2*Global`v^4*Global`w^5 - 
          2*FeynCalc`CA^3*Global`v^4*Global`w^5 + 4*FeynCalc`CA^4*Global`v^4*
           Global`w^5 - 2*FeynCalc`CA*Global`v^5*Global`w^5 + 
          2*FeynCalc`CA^3*Global`v^5*Global`w^5)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v*Global`w])/(4*FeynCalc`CA^3*System`Pi*
         Global`s^2*(-1 + Global`v)^2*Global`v^2*(-1 + Global`w)*
         Global`w^2) - ((2 + 2*FeynCalc`CA^2 - 10*Global`v + 
          2*FeynCalc`CA*Global`v - 9*FeynCalc`CA^2*Global`v + 21*Global`v^2 - 
          10*FeynCalc`CA*Global`v^2 + 17*FeynCalc`CA^2*Global`v^2 + 
          2*FeynCalc`CA^3*Global`v^2 - 23*Global`v^3 + 18*FeynCalc`CA*
           Global`v^3 - 17*FeynCalc`CA^2*Global`v^3 - 6*FeynCalc`CA^3*
           Global`v^3 + 13*Global`v^4 - 14*FeynCalc`CA*Global`v^4 + 
          9*FeynCalc`CA^2*Global`v^4 + 6*FeynCalc`CA^3*Global`v^4 - 
          3*Global`v^5 + 4*FeynCalc`CA*Global`v^5 - 2*FeynCalc`CA^2*
           Global`v^5 - 2*FeynCalc`CA^3*Global`v^5 + 6*Global`v*Global`w - 
          2*FeynCalc`CA*Global`v*Global`w + 7*FeynCalc`CA^2*Global`v*
           Global`w + 2*FeynCalc`CA^4*Global`v*Global`w - 
          25*Global`v^2*Global`w + 15*FeynCalc`CA*Global`v^2*Global`w - 
          26*FeynCalc`CA^2*Global`v^2*Global`w - 3*FeynCalc`CA^3*Global`v^2*
           Global`w - 5*FeynCalc`CA^4*Global`v^2*Global`w + 
          42*Global`v^3*Global`w - 36*FeynCalc`CA*Global`v^3*Global`w + 
          42*FeynCalc`CA^2*Global`v^3*Global`w + 10*FeynCalc`CA^3*Global`v^3*
           Global`w + 5*FeynCalc`CA^4*Global`v^3*Global`w - 
          33*Global`v^4*Global`w + 35*FeynCalc`CA*Global`v^4*Global`w - 
          34*FeynCalc`CA^2*Global`v^4*Global`w - 11*FeynCalc`CA^3*Global`v^4*
           Global`w - 3*FeynCalc`CA^4*Global`v^4*Global`w + 
          10*Global`v^5*Global`w - 12*FeynCalc`CA*Global`v^5*Global`w + 
          11*FeynCalc`CA^2*Global`v^5*Global`w + 4*FeynCalc`CA^3*Global`v^5*
           Global`w + FeynCalc`CA^4*Global`v^5*Global`w + 
          7*Global`v^2*Global`w^2 - 5*FeynCalc`CA*Global`v^2*Global`w^2 + 
          10*FeynCalc`CA^2*Global`v^2*Global`w^2 + FeynCalc`CA^3*Global`v^2*
           Global`w^2 + 6*FeynCalc`CA^4*Global`v^2*Global`w^2 - 
          27*Global`v^3*Global`w^2 + 22*FeynCalc`CA*Global`v^3*Global`w^2 - 
          32*FeynCalc`CA^2*Global`v^3*Global`w^2 - 4*FeynCalc`CA^3*Global`v^3*
           Global`w^2 - 11*FeynCalc`CA^4*Global`v^3*Global`w^2 + 
          35*Global`v^4*Global`w^2 - 31*FeynCalc`CA*Global`v^4*Global`w^2 + 
          43*FeynCalc`CA^2*Global`v^4*Global`w^2 + 5*FeynCalc`CA^3*Global`v^4*
           Global`w^2 + 9*FeynCalc`CA^4*Global`v^4*Global`w^2 - 
          15*Global`v^5*Global`w^2 + 14*FeynCalc`CA*Global`v^5*Global`w^2 - 
          21*FeynCalc`CA^2*Global`v^5*Global`w^2 - 2*FeynCalc`CA^3*Global`v^5*
           Global`w^2 - 4*FeynCalc`CA^4*Global`v^5*Global`w^2 + 
          7*Global`v^3*Global`w^3 - 4*FeynCalc`CA*Global`v^3*Global`w^3 + 
          7*FeynCalc`CA^2*Global`v^3*Global`w^3 + 7*FeynCalc`CA^4*Global`v^3*
           Global`w^3 - 19*Global`v^4*Global`w^3 + 12*FeynCalc`CA*Global`v^4*
           Global`w^3 - 24*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          9*FeynCalc`CA^4*Global`v^4*Global`w^3 + 13*Global`v^5*Global`w^3 - 
          8*FeynCalc`CA*Global`v^5*Global`w^3 + 19*FeynCalc`CA^2*Global`v^5*
           Global`w^3 + 6*FeynCalc`CA^4*Global`v^5*Global`w^3 + 
          4*Global`v^4*Global`w^4 - 2*FeynCalc`CA*Global`v^4*Global`w^4 + 
          6*FeynCalc`CA^2*Global`v^4*Global`w^4 + 3*FeynCalc`CA^4*Global`v^4*
           Global`w^4 - 6*Global`v^5*Global`w^4 + 2*FeynCalc`CA*Global`v^5*
           Global`w^4 - 9*FeynCalc`CA^2*Global`v^5*Global`w^4 - 
          4*FeynCalc`CA^4*Global`v^5*Global`w^4 + Global`v^5*Global`w^5 + 
          2*FeynCalc`CA^2*Global`v^5*Global`w^5 + FeynCalc`CA^4*Global`v^5*
           Global`w^5)*FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v + 
           Global`v*Global`w])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2*(-1 + Global`w)*Global`w*
         (1 - Global`v + Global`v*Global`w)^2)|>|>, 
 "DensityConvention" -> "E_c d sigma/d^(D-1)p_c", 
 "DistributionBasis" -> <|"Variable" -> Global`w, "Endpoint" -> 1, 
   "Interval" -> {0, 1}, "Distance" -> 1 - Global`w|>, 
 "PlusConvention" -> "At each axis, PlusCoefficients[k] multiplies \
[Log[Distance]^k/Distance]_+ on Interval, with subtraction at Endpoint. For \
DistributionBasis[Axes], delta/plus/regular values repeat recursively in the \
listed axis order."|>
