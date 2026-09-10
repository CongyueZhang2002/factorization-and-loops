<|"Project" -> "ppHX_UU_NNLO", "Channel" -> "u-g_g-u", "Scale" -> Global`s, 
 "Variables" -> {Global`v, Global`w}, "Coupling" -> FeynFacet`\[Alpha]s, 
 "CouplingPower" -> 3, "DimensionalPrefactor" -> 
  Global`muR2^(2*Global`Epsilon), "PhysicalChannel" -> 
  <|"Incoming" -> {{"q", "u"}, "g"}, "Observed" -> "g", 
   "Recoil" -> {"q", "u"}|>, "Polarization" -> <|"Incoming" -> {"U", "U"}, 
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
      -1/48*((108*FeynCalc`CA^2 - 60*FeynCalc`CA^4 + 8*FeynCalc`CA^2*
            System`Pi^2 + 40*FeynCalc`CA^4*System`Pi^2 - 216*FeynCalc`CA^2*
            Global`v + 120*FeynCalc`CA^4*Global`v - 22*FeynCalc`CA^2*
            System`Pi^2*Global`v - 104*FeynCalc`CA^4*System`Pi^2*Global`v - 
           42*Global`v^2 + 240*FeynCalc`CA^2*Global`v^2 - 138*FeynCalc`CA^4*
            Global`v^2 + 2*System`Pi^2*Global`v^2 + 14*FeynCalc`CA^2*
            System`Pi^2*Global`v^2 + 110*FeynCalc`CA^4*System`Pi^2*
            Global`v^2 + 42*Global`v^3 - 132*FeynCalc`CA^2*Global`v^3 + 
           78*FeynCalc`CA^4*Global`v^3 - 8*System`Pi^2*Global`v^3 - 
           12*FeynCalc`CA^2*System`Pi^2*Global`v^3 - 52*FeynCalc`CA^4*
            System`Pi^2*Global`v^3 - 21*Global`v^4 + 42*FeynCalc`CA^2*
            Global`v^4 - 21*FeynCalc`CA^4*Global`v^4 + 10*System`Pi^2*
            Global`v^4 + 4*FeynCalc`CA^2*System`Pi^2*Global`v^4 + 
           10*FeynCalc`CA^4*System`Pi^2*Global`v^4)*FeynFacet`\[Alpha]s^3)/
         (FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^3) + 
       (3*(-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(2 - 2*Global`v + Global`v^2)*
         (2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - Global`v^2 + 
          FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muFA2])/(16*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^3) - 
       ((11*FeynCalc`CA - 2*Global`nD - 2*Global`nU)*(2 - 2*Global`v + 
          Global`v^2)*(2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - 
          Global`v^2 + FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muR2])/(12*FeynCalc`CA^2*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^3) - (3*(-1 + FeynCalc`CA)*
         (1 + FeynCalc`CA)*(2 - 2*Global`v + Global`v^2)*
         (2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - Global`v^2 + 
          FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`s])/(16*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^3) - 
       ((8*FeynCalc`CA^4 - FeynCalc`CA^2*Global`v - 20*FeynCalc`CA^4*
           Global`v + Global`v^2 - FeynCalc`CA^2*Global`v^2 + 
          21*FeynCalc`CA^4*Global`v^2 - 2*Global`v^3 - 10*FeynCalc`CA^4*
           Global`v^3 + 2*Global`v^4 + 2*FeynCalc`CA^4*Global`v^4)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v]^2)/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^3) + 
       (((12*FeynCalc`CA^2 - 12*FeynCalc`CA^4 - 24*FeynCalc`CA^2*Global`v + 
            24*FeynCalc`CA^4*Global`v - 2*Global`v^2 - 4*FeynCalc`CA^2*
             Global`v^2 - 2*FeynCalc`CA^4*Global`v^2 + 2*Global`v^3 + 
            16*FeynCalc`CA^2*Global`v^3 - 10*FeynCalc`CA^4*Global`v^3 + 
            3*Global`v^4 - 6*FeynCalc`CA^2*Global`v^4 + 3*FeynCalc`CA^4*
             Global`v^4)*FeynFacet`\[Alpha]s^3)/(16*FeynCalc`CA^3*System`Pi*
           Global`s^2*(-1 + Global`v)*Global`v^3) - 
         ((2 - 2*Global`v + Global`v^2)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(FeynCalc`CA*System`Pi*
           Global`s^2*(-1 + Global`v)*Global`v^3))*System`Log[Global`v] - 
       ((48*FeynCalc`CA^4 - 96*FeynCalc`CA^4*Global`v + 2*Global`v^2 - 
          5*FeynCalc`CA^2*Global`v^2 + 94*FeynCalc`CA^4*Global`v^2 - 
          2*Global`v^3 + 5*FeynCalc`CA^2*Global`v^3 - 46*FeynCalc`CA^4*
           Global`v^3 + 3*Global`v^4 - 2*FeynCalc`CA^2*Global`v^4 + 
          11*FeynCalc`CA^4*Global`v^4)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`v]^2)/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^3) + System`Log[Global`muD2]*
        (((11*FeynCalc`CA - 2*Global`nD - 2*Global`nU)*(2 - 2*Global`v + 
            Global`v^2)*(2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - 
            Global`v^2 + FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
          (24*FeynCalc`CA^2*System`Pi*Global`s^2*(-1 + Global`v)*
           Global`v^3) + ((2 - 2*Global`v + Global`v^2)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`v])/(2*FeynCalc`CA*
           System`Pi*Global`s^2*(-1 + Global`v)*Global`v^3)) + 
       System`Log[Global`muFB2]*(((11*FeynCalc`CA - 2*Global`nD - 
            2*Global`nU)*(2 - 2*Global`v + Global`v^2)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3)/(24*FeynCalc`CA^2*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^3) - ((2 - 2*Global`v + Global`v^2)*
           (2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[1 - Global`v])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^3) + ((2 - 2*Global`v + Global`v^2)*
           (2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^3)) + System`Log[1 - Global`v]*
        (((FeynCalc`CA^2 - Global`v)*(1 - 5*FeynCalc`CA^2 + 2*Global`v + 
            2*FeynCalc`CA^2*Global`v)*FeynFacet`\[Alpha]s^3)/
          (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) + 
         ((2 - 2*Global`v + Global`v^2)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(2*FeynCalc`CA*
           System`Pi*Global`s^2*(-1 + Global`v)*Global`v^3) + 
         ((16*FeynCalc`CA^4 - FeynCalc`CA^2*Global`v - 36*FeynCalc`CA^4*
             Global`v + Global`v^2 + 3*FeynCalc`CA^2*Global`v^2 + 
            37*FeynCalc`CA^4*Global`v^2 - 2*Global`v^3 - 4*FeynCalc`CA^2*
             Global`v^3 - 18*FeynCalc`CA^4*Global`v^3 + 2*Global`v^4 + 
            2*FeynCalc`CA^2*Global`v^4 + 4*FeynCalc`CA^4*Global`v^4)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`v])/(4*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)*Global`v^3)), 
     "PlusCoefficients" -> 
      <|0 -> (3*(-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(2 - 2*Global`v + 
            Global`v^2)*(2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - 
            Global`v^2 + FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
          (16*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*
           Global`v^3) + ((2 - 2*Global`v + Global`v^2)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`muD2])/
          (2*FeynCalc`CA*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^3) + 
         ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(2 - 2*Global`v + Global`v^2)*
           (2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFA2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^3) + ((2 - 2*Global`v + Global`v^2)*
           (2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFB2])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^3) - ((-1 + 5*FeynCalc`CA^2)*
           (2 - 2*Global`v + Global`v^2)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(4*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)*Global`v^3) + 
         (FeynCalc`CA*(-1 + Global`v)*(2 - 2*Global`v + Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v])/
          (System`Pi*Global`s^2*Global`v^3) - ((2 - 2*Global`v + Global`v^2)*
           (-2*FeynCalc`CA^2 + 18*FeynCalc`CA^4 + 2*FeynCalc`CA^2*Global`v - 
            18*FeynCalc`CA^4*Global`v + Global`v^2 - 6*FeynCalc`CA^2*
             Global`v^2 + 9*FeynCalc`CA^4*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^3), 
       1 -> -1/4*((-1 + 3*FeynCalc`CA)*(1 + 3*FeynCalc`CA)*
           (2 - 2*Global`v + Global`v^2)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3)/(FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^3)|>, "RegularCoefficient" -> 
      ((12*FeynCalc`CA^2 - 28*FeynCalc`CA^4 - 72*FeynCalc`CA^2*Global`v + 
          168*FeynCalc`CA^4*Global`v - 6*Global`v^2 + 204*FeynCalc`CA^2*
           Global`v^2 - 470*FeynCalc`CA^4*Global`v^2 + 28*Global`v^3 - 
          356*FeynCalc`CA^2*Global`v^3 + 808*FeynCalc`CA^4*Global`v^3 - 
          52*Global`v^4 + 408*FeynCalc`CA^2*Global`v^4 - 932*FeynCalc`CA^4*
           Global`v^4 + 48*Global`v^5 - 304*FeynCalc`CA^2*Global`v^5 + 
          736*FeynCalc`CA^4*Global`v^5 - 22*Global`v^6 + 140*FeynCalc`CA^2*
           Global`v^6 - 390*FeynCalc`CA^4*Global`v^6 + 4*Global`v^7 - 
          36*FeynCalc`CA^2*Global`v^7 + 128*FeynCalc`CA^4*Global`v^7 + 
          4*FeynCalc`CA^2*Global`v^8 - 20*FeynCalc`CA^4*Global`v^8 + 
          16*FeynCalc`CA^2*Global`w + 16*FeynCalc`CA^4*Global`w - 
          96*FeynCalc`CA^2*Global`v*Global`w - 96*FeynCalc`CA^4*Global`v*
           Global`w - 4*Global`v^2*Global`w + 258*FeynCalc`CA^2*Global`v^2*
           Global`w + 142*FeynCalc`CA^4*Global`v^2*Global`w + 
          22*Global`v^3*Global`w - 410*FeynCalc`CA^2*Global`v^3*Global`w + 
          168*FeynCalc`CA^4*Global`v^3*Global`w - 77*Global`v^4*Global`w + 
          468*FeynCalc`CA^2*Global`v^4*Global`w - 827*FeynCalc`CA^4*
           Global`v^4*Global`w + 166*Global`v^5*Global`w - 
          456*FeynCalc`CA^2*Global`v^5*Global`w + 1242*FeynCalc`CA^4*
           Global`v^5*Global`w - 202*Global`v^6*Global`w + 
          358*FeynCalc`CA^2*Global`v^6*Global`w - 1040*FeynCalc`CA^4*
           Global`v^6*Global`w + 134*Global`v^7*Global`w - 
          174*FeynCalc`CA^2*Global`v^7*Global`w + 548*FeynCalc`CA^4*
           Global`v^7*Global`w - 45*Global`v^8*Global`w + 
          36*FeynCalc`CA^2*Global`v^8*Global`w - 187*FeynCalc`CA^4*Global`v^8*
           Global`w + 6*Global`v^9*Global`w + 34*FeynCalc`CA^4*Global`v^9*
           Global`w + 12*FeynCalc`CA^2*Global`v^2*Global`w^2 + 
          132*FeynCalc`CA^4*Global`v^2*Global`w^2 - 60*FeynCalc`CA^2*
           Global`v^3*Global`w^2 - 660*FeynCalc`CA^4*Global`v^3*Global`w^2 + 
          4*Global`v^4*Global`w^2 + 110*FeynCalc`CA^2*Global`v^4*Global`w^2 + 
          1210*FeynCalc`CA^4*Global`v^4*Global`w^2 - 16*Global`v^5*
           Global`w^2 - 76*FeynCalc`CA^2*Global`v^5*Global`w^2 - 
          884*FeynCalc`CA^4*Global`v^5*Global`w^2 + 37*Global`v^6*
           Global`w^2 + 62*FeynCalc`CA^2*Global`v^6*Global`w^2 - 
          187*FeynCalc`CA^4*Global`v^6*Global`w^2 - 57*Global`v^7*
           Global`w^2 - 154*FeynCalc`CA^2*Global`v^7*Global`w^2 + 
          867*FeynCalc`CA^4*Global`v^7*Global`w^2 + 51*Global`v^8*
           Global`w^2 + 144*FeynCalc`CA^2*Global`v^8*Global`w^2 - 
          703*FeynCalc`CA^4*Global`v^8*Global`w^2 - 23*Global`v^9*
           Global`w^2 - 30*FeynCalc`CA^2*Global`v^9*Global`w^2 + 
          277*FeynCalc`CA^4*Global`v^9*Global`w^2 + 4*Global`v^10*
           Global`w^2 - 8*FeynCalc`CA^2*Global`v^10*Global`w^2 - 
          52*FeynCalc`CA^4*Global`v^10*Global`w^2 - 48*FeynCalc`CA^2*
           Global`v^2*Global`w^3 - 48*FeynCalc`CA^4*Global`v^2*Global`w^3 + 
          240*FeynCalc`CA^2*Global`v^3*Global`w^3 + 240*FeynCalc`CA^4*
           Global`v^3*Global`w^3 + 12*Global`v^4*Global`w^3 - 
          450*FeynCalc`CA^2*Global`v^4*Global`w^3 - 222*FeynCalc`CA^4*
           Global`v^4*Global`w^3 - 44*Global`v^5*Global`w^3 + 
          348*FeynCalc`CA^2*Global`v^5*Global`w^3 - 544*FeynCalc`CA^4*
           Global`v^5*Global`w^3 - 41*Global`v^6*Global`w^3 - 
          84*FeynCalc`CA^2*Global`v^6*Global`w^3 + 1473*FeynCalc`CA^4*
           Global`v^6*Global`w^3 + 277*Global`v^7*Global`w^3 + 
          32*FeynCalc`CA^2*Global`v^7*Global`w^3 - 1497*FeynCalc`CA^4*
           Global`v^7*Global`w^3 - 368*Global`v^8*Global`w^3 + 
          2*FeynCalc`CA^2*Global`v^8*Global`w^3 + 674*FeynCalc`CA^4*
           Global`v^8*Global`w^3 + 219*Global`v^9*Global`w^3 - 
          72*FeynCalc`CA^2*Global`v^9*Global`w^3 - 23*FeynCalc`CA^4*
           Global`v^9*Global`w^3 - 61*Global`v^10*Global`w^3 + 
          20*FeynCalc`CA^2*Global`v^10*Global`w^3 - 83*FeynCalc`CA^4*
           Global`v^10*Global`w^3 + 6*Global`v^11*Global`w^3 + 
          12*FeynCalc`CA^2*Global`v^11*Global`w^3 + 30*FeynCalc`CA^4*
           Global`v^11*Global`w^3 - 60*FeynCalc`CA^2*Global`v^4*Global`w^4 - 
          180*FeynCalc`CA^4*Global`v^4*Global`w^4 + 240*FeynCalc`CA^2*
           Global`v^5*Global`w^4 + 720*FeynCalc`CA^4*Global`v^5*Global`w^4 + 
          102*Global`v^6*Global`w^4 - 312*FeynCalc`CA^2*Global`v^6*
           Global`w^4 - 950*FeynCalc`CA^4*Global`v^6*Global`w^4 - 
          320*Global`v^7*Global`w^4 + 116*FeynCalc`CA^2*Global`v^7*
           Global`w^4 + 324*FeynCalc`CA^4*Global`v^7*Global`w^4 + 
          426*Global`v^8*Global`w^4 - 38*FeynCalc`CA^2*Global`v^8*
           Global`w^4 + 456*FeynCalc`CA^4*Global`v^8*Global`w^4 - 
          308*Global`v^9*Global`w^4 + 76*FeynCalc`CA^2*Global`v^9*
           Global`w^4 - 536*FeynCalc`CA^4*Global`v^9*Global`w^4 + 
          119*Global`v^10*Global`w^4 - 24*FeynCalc`CA^2*Global`v^10*
           Global`w^4 + 197*FeynCalc`CA^4*Global`v^10*Global`w^4 - 
          19*Global`v^11*Global`w^4 + 18*FeynCalc`CA^2*Global`v^11*
           Global`w^4 - 47*FeynCalc`CA^4*Global`v^11*Global`w^4 - 
          16*FeynCalc`CA^2*Global`v^12*Global`w^4 + 48*FeynCalc`CA^2*
           Global`v^4*Global`w^5 + 48*FeynCalc`CA^4*Global`v^4*Global`w^5 - 
          192*FeynCalc`CA^2*Global`v^5*Global`w^5 - 192*FeynCalc`CA^4*
           Global`v^5*Global`w^5 - 12*Global`v^6*Global`w^5 + 
          222*FeynCalc`CA^2*Global`v^6*Global`w^5 + 114*FeynCalc`CA^4*
           Global`v^6*Global`w^5 + 42*Global`v^7*Global`w^5 - 
          2*FeynCalc`CA^2*Global`v^7*Global`w^5 + 332*FeynCalc`CA^4*
           Global`v^7*Global`w^5 - 107*Global`v^8*Global`w^5 - 
          68*FeynCalc`CA^2*Global`v^8*Global`w^5 - 533*FeynCalc`CA^4*
           Global`v^8*Global`w^5 + 150*Global`v^9*Global`w^5 - 
          42*FeynCalc`CA^2*Global`v^9*Global`w^5 + 240*FeynCalc`CA^4*
           Global`v^9*Global`w^5 - 100*Global`v^10*Global`w^5 + 
          152*FeynCalc`CA^2*Global`v^10*Global`w^5 - 4*FeynCalc`CA^4*
           Global`v^10*Global`w^5 + 27*Global`v^11*Global`w^5 - 
          182*FeynCalc`CA^2*Global`v^11*Global`w^5 + 59*FeynCalc`CA^4*
           Global`v^11*Global`w^5 + 64*FeynCalc`CA^2*Global`v^12*Global`w^5 - 
          16*FeynCalc`CA^4*Global`v^12*Global`w^5 + 36*FeynCalc`CA^2*
           Global`v^6*Global`w^6 + 76*FeynCalc`CA^4*Global`v^6*Global`w^6 - 
          108*FeynCalc`CA^2*Global`v^7*Global`w^6 - 228*FeynCalc`CA^4*
           Global`v^7*Global`w^6 + 12*Global`v^8*Global`w^6 + 
          54*FeynCalc`CA^2*Global`v^8*Global`w^6 + 170*FeynCalc`CA^4*
           Global`v^8*Global`w^6 - 36*Global`v^9*Global`w^6 + 
          76*FeynCalc`CA^2*Global`v^9*Global`w^6 + 48*FeynCalc`CA^4*
           Global`v^9*Global`w^6 + 45*Global`v^10*Global`w^6 - 
          264*FeynCalc`CA^2*Global`v^10*Global`w^6 - 25*FeynCalc`CA^4*
           Global`v^10*Global`w^6 - 21*Global`v^11*Global`w^6 + 
          310*FeynCalc`CA^2*Global`v^11*Global`w^6 - 145*FeynCalc`CA^4*
           Global`v^11*Global`w^6 - 96*FeynCalc`CA^2*Global`v^12*Global`w^6 + 
          48*FeynCalc`CA^4*Global`v^12*Global`w^6 - 16*FeynCalc`CA^2*
           Global`v^6*Global`w^7 - 16*FeynCalc`CA^4*Global`v^6*Global`w^7 + 
          48*FeynCalc`CA^2*Global`v^7*Global`w^7 + 48*FeynCalc`CA^4*
           Global`v^7*Global`w^7 + 4*Global`v^8*Global`w^7 - 
          30*FeynCalc`CA^2*Global`v^8*Global`w^7 - 34*FeynCalc`CA^4*
           Global`v^8*Global`w^7 - 4*Global`v^9*Global`w^7 - 
          24*FeynCalc`CA^2*Global`v^9*Global`w^7 - 12*FeynCalc`CA^4*
           Global`v^9*Global`w^7 - 7*Global`v^10*Global`w^7 + 
          148*FeynCalc`CA^2*Global`v^10*Global`w^7 - 57*FeynCalc`CA^4*
           Global`v^10*Global`w^7 + 7*Global`v^11*Global`w^7 - 
          214*FeynCalc`CA^2*Global`v^11*Global`w^7 + 159*FeynCalc`CA^4*
           Global`v^11*Global`w^7 + 64*FeynCalc`CA^2*Global`v^12*Global`w^7 - 
          48*FeynCalc`CA^4*Global`v^12*Global`w^7 - 24*FeynCalc`CA^2*
           Global`v^10*Global`w^8 + 24*FeynCalc`CA^4*Global`v^10*Global`w^8 + 
          64*FeynCalc`CA^2*Global`v^11*Global`w^8 - 64*FeynCalc`CA^4*
           Global`v^11*Global`w^8 - 16*FeynCalc`CA^2*Global`v^12*Global`w^8 + 
          16*FeynCalc`CA^4*Global`v^12*Global`w^8 - 8*FeynCalc`CA^2*
           Global`v^11*Global`w^9 + 8*FeynCalc`CA^4*Global`v^11*Global`w^9)*
         FeynFacet`\[Alpha]s^3)/(16*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^3*Global`w*(-1 + Global`v*Global`w)^3*
         (1 - Global`v + Global`v*Global`w)^3) - 
       ((16*FeynCalc`CA^4 - 112*FeynCalc`CA^4*Global`v + 368*FeynCalc`CA^4*
           Global`v^2 - 752*FeynCalc`CA^4*Global`v^3 + 1056*FeynCalc`CA^4*
           Global`v^4 - 1056*FeynCalc`CA^4*Global`v^5 + 752*FeynCalc`CA^4*
           Global`v^6 - 368*FeynCalc`CA^4*Global`v^7 + 112*FeynCalc`CA^4*
           Global`v^8 - 16*FeynCalc`CA^4*Global`v^9 + 16*FeynCalc`CA^4*
           Global`w - 48*FeynCalc`CA^4*Global`v*Global`w + 
          Global`v^2*Global`w - 2*FeynCalc`CA^2*Global`v^2*Global`w - 
          79*FeynCalc`CA^4*Global`v^2*Global`w - 4*Global`v^3*Global`w + 
          8*FeynCalc`CA^2*Global`v^3*Global`w + 684*FeynCalc`CA^4*Global`v^3*
           Global`w + 7*Global`v^4*Global`w - 14*FeynCalc`CA^2*Global`v^4*
           Global`w - 1721*FeynCalc`CA^4*Global`v^4*Global`w - 
          8*Global`v^5*Global`w + 16*FeynCalc`CA^2*Global`v^5*Global`w + 
          2488*FeynCalc`CA^4*Global`v^5*Global`w + 7*Global`v^6*Global`w - 
          14*FeynCalc`CA^2*Global`v^6*Global`w - 2313*FeynCalc`CA^4*
           Global`v^6*Global`w - 4*Global`v^7*Global`w + 
          8*FeynCalc`CA^2*Global`v^7*Global`w + 1388*FeynCalc`CA^4*Global`v^7*
           Global`w + Global`v^8*Global`w - 2*FeynCalc`CA^2*Global`v^8*
           Global`w - 495*FeynCalc`CA^4*Global`v^8*Global`w + 
          80*FeynCalc`CA^4*Global`v^9*Global`w + 48*FeynCalc`CA^4*Global`v*
           Global`w^2 - 192*FeynCalc`CA^4*Global`v^2*Global`w^2 + 
          2*Global`v^3*Global`w^2 - 6*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          148*FeynCalc`CA^4*Global`v^3*Global`w^2 - 8*Global`v^4*Global`w^2 + 
          10*FeynCalc`CA^2*Global`v^4*Global`w^2 + 638*FeynCalc`CA^4*
           Global`v^4*Global`w^2 + 16*Global`v^5*Global`w^2 + 
          8*FeynCalc`CA^2*Global`v^5*Global`w^2 - 2008*FeynCalc`CA^4*
           Global`v^5*Global`w^2 - 20*Global`v^6*Global`w^2 - 
          32*FeynCalc`CA^2*Global`v^6*Global`w^2 + 2764*FeynCalc`CA^4*
           Global`v^6*Global`w^2 + 14*Global`v^7*Global`w^2 + 
          38*FeynCalc`CA^2*Global`v^7*Global`w^2 - 2156*FeynCalc`CA^4*
           Global`v^7*Global`w^2 - 4*Global`v^8*Global`w^2 - 
          26*FeynCalc`CA^2*Global`v^8*Global`w^2 + 934*FeynCalc`CA^4*
           Global`v^8*Global`w^2 + 8*FeynCalc`CA^2*Global`v^9*Global`w^2 - 
          176*FeynCalc`CA^4*Global`v^9*Global`w^2 + 48*FeynCalc`CA^4*
           Global`v^2*Global`w^3 - 176*FeynCalc`CA^4*Global`v^3*Global`w^3 + 
          3*Global`v^4*Global`w^3 + 8*FeynCalc`CA^2*Global`v^4*Global`w^3 + 
          85*FeynCalc`CA^4*Global`v^4*Global`w^3 - 12*Global`v^5*Global`w^3 - 
          60*FeynCalc`CA^2*Global`v^5*Global`w^3 + 664*FeynCalc`CA^4*
           Global`v^5*Global`w^3 + 22*Global`v^6*Global`w^3 + 
          136*FeynCalc`CA^2*Global`v^6*Global`w^3 - 1654*FeynCalc`CA^4*
           Global`v^6*Global`w^3 - 20*Global`v^7*Global`w^3 - 
          156*FeynCalc`CA^2*Global`v^7*Global`w^3 + 1792*FeynCalc`CA^4*
           Global`v^7*Global`w^3 + 7*Global`v^8*Global`w^3 + 
          104*FeynCalc`CA^2*Global`v^8*Global`w^3 - 983*FeynCalc`CA^4*
           Global`v^8*Global`w^3 - 32*FeynCalc`CA^2*Global`v^9*Global`w^3 + 
          224*FeynCalc`CA^4*Global`v^9*Global`w^3 + 16*FeynCalc`CA^4*
           Global`v^3*Global`w^4 - 48*FeynCalc`CA^4*Global`v^4*Global`w^4 + 
          2*Global`v^5*Global`w^4 + 26*FeynCalc`CA^2*Global`v^5*Global`w^4 - 
          76*FeynCalc`CA^4*Global`v^5*Global`w^4 - 10*Global`v^6*Global`w^4 - 
          110*FeynCalc`CA^2*Global`v^6*Global`w^4 + 512*FeynCalc`CA^4*
           Global`v^6*Global`w^4 + 14*Global`v^7*Global`w^4 + 
          174*FeynCalc`CA^2*Global`v^7*Global`w^4 - 844*FeynCalc`CA^4*
           Global`v^7*Global`w^4 - 6*Global`v^8*Global`w^4 - 
          142*FeynCalc`CA^2*Global`v^8*Global`w^4 + 620*FeynCalc`CA^4*
           Global`v^8*Global`w^4 + 52*FeynCalc`CA^2*Global`v^9*Global`w^4 - 
          180*FeynCalc`CA^4*Global`v^9*Global`w^4 + 2*Global`v^6*Global`w^5 + 
          22*FeynCalc`CA^2*Global`v^6*Global`w^5 - 64*FeynCalc`CA^4*
           Global`v^6*Global`w^5 - 4*Global`v^7*Global`w^5 - 
          72*FeynCalc`CA^2*Global`v^7*Global`w^5 + 204*FeynCalc`CA^4*
           Global`v^7*Global`w^5 + 2*Global`v^8*Global`w^5 + 
          86*FeynCalc`CA^2*Global`v^8*Global`w^5 - 224*FeynCalc`CA^4*
           Global`v^8*Global`w^5 - 44*FeynCalc`CA^2*Global`v^9*Global`w^5 + 
          92*FeynCalc`CA^4*Global`v^9*Global`w^5 + 8*FeynCalc`CA^2*Global`v^7*
           Global`w^6 - 16*FeynCalc`CA^4*Global`v^7*Global`w^6 - 
          20*FeynCalc`CA^2*Global`v^8*Global`w^6 + 36*FeynCalc`CA^4*
           Global`v^8*Global`w^6 + 20*FeynCalc`CA^2*Global`v^9*Global`w^6 - 
          28*FeynCalc`CA^4*Global`v^9*Global`w^6 - 4*FeynCalc`CA^2*Global`v^9*
           Global`w^7 + 4*FeynCalc`CA^4*Global`v^9*Global`w^7)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muD2])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^3*
         Global`w^2*(1 - Global`v + Global`v*Global`w)^3) - 
       ((16*FeynCalc`CA^4 - 48*FeynCalc`CA^4*Global`v + 96*FeynCalc`CA^4*
           Global`v^2 - 112*FeynCalc`CA^4*Global`v^3 + 96*FeynCalc`CA^4*
           Global`v^4 - 48*FeynCalc`CA^4*Global`v^5 + 16*FeynCalc`CA^4*
           Global`v^6 - 4*FeynCalc`CA^2*Global`w - 12*FeynCalc`CA^4*
           Global`w + 12*FeynCalc`CA^2*Global`v*Global`w + 
          36*FeynCalc`CA^4*Global`v*Global`w + 2*Global`v^2*Global`w - 
          18*FeynCalc`CA^2*Global`v^2*Global`w - 80*FeynCalc`CA^4*Global`v^2*
           Global`w - 4*Global`v^3*Global`w + 16*FeynCalc`CA^2*Global`v^3*
           Global`w + 100*FeynCalc`CA^4*Global`v^3*Global`w + 
          3*Global`v^4*Global`w - 8*FeynCalc`CA^2*Global`v^4*Global`w - 
          91*FeynCalc`CA^4*Global`v^4*Global`w - Global`v^5*Global`w + 
          2*FeynCalc`CA^2*Global`v^5*Global`w + 47*FeynCalc`CA^4*Global`v^5*
           Global`w - 16*FeynCalc`CA^4*Global`v^6*Global`w + 
          4*FeynCalc`CA^2*Global`w^2 + 4*FeynCalc`CA^4*Global`w^2 - 
          12*FeynCalc`CA^2*Global`v*Global`w^2 - 12*FeynCalc`CA^4*Global`v*
           Global`w^2 - 2*Global`v^2*Global`w^2 + 18*FeynCalc`CA^2*Global`v^2*
           Global`w^2 + 32*FeynCalc`CA^4*Global`v^2*Global`w^2 + 
          4*Global`v^3*Global`w^2 - 16*FeynCalc`CA^2*Global`v^3*Global`w^2 - 
          44*FeynCalc`CA^4*Global`v^3*Global`w^2 - 3*Global`v^4*Global`w^2 + 
          8*FeynCalc`CA^2*Global`v^4*Global`w^2 + 43*FeynCalc`CA^4*Global`v^4*
           Global`w^2 + Global`v^5*Global`w^2 - 2*FeynCalc`CA^2*Global`v^5*
           Global`w^2 - 23*FeynCalc`CA^4*Global`v^5*Global`w^2 + 
          8*FeynCalc`CA^4*Global`v^6*Global`w^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muFA2])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^3*Global`w^2) - 
       ((-16*FeynCalc`CA^4 + 32*FeynCalc`CA^4*Global`v - 
          48*FeynCalc`CA^4*Global`v^2 + 32*FeynCalc`CA^4*Global`v^3 - 
          16*FeynCalc`CA^4*Global`v^4 - 16*FeynCalc`CA^4*Global`w + 
          96*FeynCalc`CA^4*Global`v*Global`w - Global`v^2*Global`w + 
          2*FeynCalc`CA^2*Global`v^2*Global`w - 113*FeynCalc`CA^4*Global`v^2*
           Global`w + 3*Global`v^3*Global`w - 6*FeynCalc`CA^2*Global`v^3*
           Global`w + 131*FeynCalc`CA^4*Global`v^3*Global`w - 
          4*Global`v^4*Global`w + 8*FeynCalc`CA^2*Global`v^4*Global`w - 
          52*FeynCalc`CA^4*Global`v^4*Global`w + 2*Global`v^5*Global`w - 
          4*FeynCalc`CA^2*Global`v^5*Global`w + 34*FeynCalc`CA^4*Global`v^5*
           Global`w + 48*FeynCalc`CA^4*Global`v*Global`w^2 - 
          192*FeynCalc`CA^4*Global`v^2*Global`w^2 + 2*Global`v^3*Global`w^2 - 
          6*FeynCalc`CA^2*Global`v^3*Global`w^2 + 148*FeynCalc`CA^4*
           Global`v^3*Global`w^2 - 4*Global`v^4*Global`w^2 + 
          26*FeynCalc`CA^2*Global`v^4*Global`w^2 - 182*FeynCalc`CA^4*
           Global`v^4*Global`w^2 + 6*Global`v^5*Global`w^2 - 
          32*FeynCalc`CA^2*Global`v^5*Global`w^2 + 42*FeynCalc`CA^4*
           Global`v^5*Global`w^2 - 4*Global`v^6*Global`w^2 + 
          20*FeynCalc`CA^2*Global`v^6*Global`w^2 - 40*FeynCalc`CA^4*
           Global`v^6*Global`w^2 - 48*FeynCalc`CA^4*Global`v^2*Global`w^3 + 
          160*FeynCalc`CA^4*Global`v^3*Global`w^3 - 3*Global`v^4*Global`w^3 - 
          8*FeynCalc`CA^2*Global`v^4*Global`w^3 - 37*FeynCalc`CA^4*Global`v^4*
           Global`w^3 + 3*Global`v^5*Global`w^3 - 20*FeynCalc`CA^2*Global`v^5*
           Global`w^3 + 129*FeynCalc`CA^4*Global`v^5*Global`w^3 - 
          4*Global`v^6*Global`w^3 + 24*FeynCalc`CA^2*Global`v^6*Global`w^3 - 
          12*FeynCalc`CA^4*Global`v^6*Global`w^3 + 4*Global`v^7*Global`w^3 - 
          28*FeynCalc`CA^2*Global`v^7*Global`w^3 + 32*FeynCalc`CA^4*
           Global`v^7*Global`w^3 + 16*FeynCalc`CA^4*Global`v^3*Global`w^4 - 
          48*FeynCalc`CA^4*Global`v^4*Global`w^4 + 2*Global`v^5*Global`w^4 + 
          26*FeynCalc`CA^2*Global`v^5*Global`w^4 - 76*FeynCalc`CA^4*
           Global`v^5*Global`w^4 + 2*Global`v^6*Global`w^4 + 
          6*FeynCalc`CA^2*Global`v^6*Global`w^4 - 48*FeynCalc`CA^4*Global`v^6*
           Global`w^4 - 4*Global`v^7*Global`w^4 - 4*FeynCalc`CA^4*Global`v^7*
           Global`w^4 + 20*FeynCalc`CA^2*Global`v^8*Global`w^4 - 
          20*FeynCalc`CA^4*Global`v^8*Global`w^4 - 2*Global`v^6*Global`w^5 - 
          22*FeynCalc`CA^2*Global`v^6*Global`w^5 + 64*FeynCalc`CA^4*
           Global`v^6*Global`w^5 + 2*Global`v^7*Global`w^5 - 
          6*FeynCalc`CA^2*Global`v^7*Global`w^5 + 12*FeynCalc`CA^4*Global`v^7*
           Global`w^5 - 8*FeynCalc`CA^2*Global`v^8*Global`w^5 + 
          8*FeynCalc`CA^4*Global`v^8*Global`w^5 - 8*FeynCalc`CA^2*Global`v^9*
           Global`w^5 + 8*FeynCalc`CA^4*Global`v^9*Global`w^5 + 
          8*FeynCalc`CA^2*Global`v^7*Global`w^6 - 16*FeynCalc`CA^4*Global`v^7*
           Global`w^6 + 4*FeynCalc`CA^2*Global`v^8*Global`w^6 - 
          4*FeynCalc`CA^4*Global`v^8*Global`w^6 + 8*FeynCalc`CA^2*Global`v^9*
           Global`w^6 - 8*FeynCalc`CA^4*Global`v^9*Global`w^6 - 
          4*FeynCalc`CA^2*Global`v^9*Global`w^7 + 4*FeynCalc`CA^4*Global`v^9*
           Global`w^7)*FeynFacet`\[Alpha]s^3*System`Log[Global`muFB2])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^3*
         Global`w^2*(-1 + Global`v*Global`w)^3) + 
       ((-48*FeynCalc`CA^4 + 288*FeynCalc`CA^4*Global`v - 
          848*FeynCalc`CA^4*Global`v^2 + 1600*FeynCalc`CA^4*Global`v^3 - 
          2112*FeynCalc`CA^4*Global`v^4 + 2016*FeynCalc`CA^4*Global`v^5 - 
          1392*FeynCalc`CA^4*Global`v^6 + 672*FeynCalc`CA^4*Global`v^7 - 
          208*FeynCalc`CA^4*Global`v^8 + 32*FeynCalc`CA^4*Global`v^9 + 
          4*FeynCalc`CA^2*Global`w - 20*FeynCalc`CA^4*Global`w - 
          24*FeynCalc`CA^2*Global`v*Global`w + 120*FeynCalc`CA^4*Global`v*
           Global`w - 4*Global`v^2*Global`w + 70*FeynCalc`CA^2*Global`v^2*
           Global`w - 338*FeynCalc`CA^4*Global`v^2*Global`w + 
          20*Global`v^3*Global`w - 130*FeynCalc`CA^2*Global`v^3*Global`w + 
          590*FeynCalc`CA^4*Global`v^3*Global`w - 44*Global`v^4*Global`w + 
          168*FeynCalc`CA^2*Global`v^4*Global`w - 892*FeynCalc`CA^4*
           Global`v^4*Global`w + 56*Global`v^5*Global`w - 
          156*FeynCalc`CA^2*Global`v^5*Global`w + 1348*FeynCalc`CA^4*
           Global`v^5*Global`w - 44*Global`v^6*Global`w + 
          102*FeynCalc`CA^2*Global`v^6*Global`w - 1770*FeynCalc`CA^4*
           Global`v^6*Global`w + 20*Global`v^7*Global`w - 
          42*FeynCalc`CA^2*Global`v^7*Global`w + 1750*FeynCalc`CA^4*
           Global`v^7*Global`w - 4*Global`v^8*Global`w + 
          8*FeynCalc`CA^2*Global`v^8*Global`w - 1172*FeynCalc`CA^4*Global`v^8*
           Global`w + 480*FeynCalc`CA^4*Global`v^9*Global`w - 
          96*FeynCalc`CA^4*Global`v^10*Global`w - 4*FeynCalc`CA^2*
           Global`w^2 - 4*FeynCalc`CA^4*Global`w^2 + 24*FeynCalc`CA^2*
           Global`v*Global`w^2 + 24*FeynCalc`CA^4*Global`v*Global`w^2 + 
          2*Global`v^2*Global`w^2 - 54*FeynCalc`CA^2*Global`v^2*Global`w^2 + 
          4*FeynCalc`CA^4*Global`v^2*Global`w^2 - 10*Global`v^3*Global`w^2 + 
          50*FeynCalc`CA^2*Global`v^3*Global`w^2 - 240*FeynCalc`CA^4*
           Global`v^3*Global`w^2 + 16*Global`v^4*Global`w^2 + 
          44*FeynCalc`CA^2*Global`v^4*Global`w^2 + 964*FeynCalc`CA^4*
           Global`v^4*Global`w^2 - 4*Global`v^5*Global`w^2 - 
          212*FeynCalc`CA^2*Global`v^5*Global`w^2 - 2152*FeynCalc`CA^4*
           Global`v^5*Global`w^2 - 24*Global`v^6*Global`w^2 + 
          330*FeynCalc`CA^2*Global`v^6*Global`w^2 + 3014*FeynCalc`CA^4*
           Global`v^6*Global`w^2 + 44*Global`v^7*Global`w^2 - 
          302*FeynCalc`CA^2*Global`v^7*Global`w^2 - 2782*FeynCalc`CA^4*
           Global`v^7*Global`w^2 - 34*Global`v^8*Global`w^2 + 
          164*FeynCalc`CA^2*Global`v^8*Global`w^2 + 1470*FeynCalc`CA^4*
           Global`v^8*Global`w^2 + 10*Global`v^9*Global`w^2 - 
          40*FeynCalc`CA^2*Global`v^9*Global`w^2 - 202*FeynCalc`CA^4*
           Global`v^9*Global`w^2 - 192*FeynCalc`CA^4*Global`v^10*Global`w^2 + 
          96*FeynCalc`CA^4*Global`v^11*Global`w^2 - 24*FeynCalc`CA^2*
           Global`v^2*Global`w^3 + 48*FeynCalc`CA^4*Global`v^2*Global`w^3 + 
          120*FeynCalc`CA^2*Global`v^3*Global`w^3 - 240*FeynCalc`CA^4*
           Global`v^3*Global`w^3 + 12*Global`v^4*Global`w^3 - 
          304*FeynCalc`CA^2*Global`v^4*Global`w^3 + 428*FeynCalc`CA^4*
           Global`v^4*Global`w^3 - 48*Global`v^5*Global`w^3 + 
          496*FeynCalc`CA^2*Global`v^5*Global`w^3 - 272*FeynCalc`CA^4*
           Global`v^5*Global`w^3 + 82*Global`v^6*Global`w^3 - 
          496*FeynCalc`CA^2*Global`v^6*Global`w^3 + 110*FeynCalc`CA^4*
           Global`v^6*Global`w^3 - 78*Global`v^7*Global`w^3 + 
          256*FeynCalc`CA^2*Global`v^7*Global`w^3 - 386*FeynCalc`CA^4*
           Global`v^7*Global`w^3 + 32*Global`v^8*Global`w^3 + 
          24*FeynCalc`CA^2*Global`v^8*Global`w^3 + 1232*FeynCalc`CA^4*
           Global`v^8*Global`w^3 + 10*Global`v^9*Global`w^3 - 
          136*FeynCalc`CA^2*Global`v^9*Global`w^3 - 1658*FeynCalc`CA^4*
           Global`v^9*Global`w^3 - 10*Global`v^10*Global`w^3 + 
          64*FeynCalc`CA^2*Global`v^10*Global`w^3 + 962*FeynCalc`CA^4*
           Global`v^10*Global`w^3 - 224*FeynCalc`CA^4*Global`v^11*
           Global`w^3 - 32*FeynCalc`CA^4*Global`v^12*Global`w^3 + 
          12*FeynCalc`CA^2*Global`v^2*Global`w^4 + 12*FeynCalc`CA^4*
           Global`v^2*Global`w^4 - 60*FeynCalc`CA^2*Global`v^3*Global`w^4 - 
          60*FeynCalc`CA^4*Global`v^3*Global`w^4 - 6*Global`v^4*Global`w^4 + 
          102*FeynCalc`CA^2*Global`v^4*Global`w^4 + 144*FeynCalc`CA^4*
           Global`v^4*Global`w^4 + 24*Global`v^5*Global`w^4 - 
          48*FeynCalc`CA^2*Global`v^5*Global`w^4 - 216*FeynCalc`CA^4*
           Global`v^5*Global`w^4 - 19*Global`v^6*Global`w^4 - 
          178*FeynCalc`CA^2*Global`v^6*Global`w^4 - 211*FeynCalc`CA^4*
           Global`v^6*Global`w^4 - 27*Global`v^7*Global`w^4 + 
          450*FeynCalc`CA^2*Global`v^7*Global`w^4 + 1137*FeynCalc`CA^4*
           Global`v^7*Global`w^4 + 77*Global`v^8*Global`w^4 - 
          500*FeynCalc`CA^2*Global`v^8*Global`w^4 - 2153*FeynCalc`CA^4*
           Global`v^8*Global`w^4 - 81*Global`v^9*Global`w^4 + 
          314*FeynCalc`CA^2*Global`v^9*Global`w^4 + 2279*FeynCalc`CA^4*
           Global`v^9*Global`w^4 + 30*Global`v^10*Global`w^4 - 
          44*FeynCalc`CA^2*Global`v^10*Global`w^4 - 962*FeynCalc`CA^4*
           Global`v^10*Global`w^4 + 2*Global`v^11*Global`w^4 - 
          48*FeynCalc`CA^2*Global`v^11*Global`w^4 + 30*FeynCalc`CA^4*
           Global`v^11*Global`w^4 + 144*FeynCalc`CA^4*Global`v^12*
           Global`w^4 + 36*FeynCalc`CA^2*Global`v^4*Global`w^5 - 
          36*FeynCalc`CA^4*Global`v^4*Global`w^5 - 144*FeynCalc`CA^2*
           Global`v^5*Global`w^5 + 144*FeynCalc`CA^4*Global`v^5*Global`w^5 - 
          24*Global`v^6*Global`w^5 + 306*FeynCalc`CA^2*Global`v^6*
           Global`w^5 - 18*FeynCalc`CA^4*Global`v^6*Global`w^5 + 
          72*Global`v^7*Global`w^5 - 414*FeynCalc`CA^2*Global`v^7*
           Global`w^5 - 450*FeynCalc`CA^4*Global`v^7*Global`w^5 - 
          110*Global`v^8*Global`w^5 + 266*FeynCalc`CA^2*Global`v^8*
           Global`w^5 + 1012*FeynCalc`CA^4*Global`v^8*Global`w^5 + 
          100*Global`v^9*Global`w^5 - 10*FeynCalc`CA^2*Global`v^9*
           Global`w^5 - 1106*FeynCalc`CA^4*Global`v^9*Global`w^5 - 
          30*Global`v^10*Global`w^5 - 162*FeynCalc`CA^2*Global`v^10*
           Global`w^5 + 24*FeynCalc`CA^4*Global`v^10*Global`w^5 - 
          8*Global`v^11*Global`w^5 + 122*FeynCalc`CA^2*Global`v^11*
           Global`w^5 + 430*FeynCalc`CA^4*Global`v^11*Global`w^5 + 
          16*FeynCalc`CA^2*Global`v^12*Global`w^5 - 288*FeynCalc`CA^4*
           Global`v^12*Global`w^5 - 12*FeynCalc`CA^2*Global`v^4*Global`w^6 - 
          12*FeynCalc`CA^4*Global`v^4*Global`w^6 + 48*FeynCalc`CA^2*
           Global`v^5*Global`w^6 + 48*FeynCalc`CA^4*Global`v^5*Global`w^6 + 
          6*Global`v^6*Global`w^6 - 66*FeynCalc`CA^2*Global`v^6*Global`w^6 - 
          132*FeynCalc`CA^4*Global`v^6*Global`w^6 - 18*Global`v^7*
           Global`w^6 + 30*FeynCalc`CA^2*Global`v^7*Global`w^6 + 
          228*FeynCalc`CA^4*Global`v^7*Global`w^6 + 36*Global`v^8*
           Global`w^6 + 124*FeynCalc`CA^2*Global`v^8*Global`w^6 - 
          216*FeynCalc`CA^4*Global`v^8*Global`w^6 - 42*Global`v^9*
           Global`w^6 - 242*FeynCalc`CA^2*Global`v^9*Global`w^6 + 
          108*FeynCalc`CA^4*Global`v^9*Global`w^6 + 5*Global`v^10*
           Global`w^6 + 198*FeynCalc`CA^2*Global`v^10*Global`w^6 + 
          637*FeynCalc`CA^4*Global`v^10*Global`w^6 + 13*Global`v^11*
           Global`w^6 - 80*FeynCalc`CA^2*Global`v^11*Global`w^6 - 
          661*FeynCalc`CA^4*Global`v^11*Global`w^6 - 64*FeynCalc`CA^2*
           Global`v^12*Global`w^6 + 344*FeynCalc`CA^4*Global`v^12*
           Global`w^6 - 16*FeynCalc`CA^2*Global`v^6*Global`w^7 + 
          8*FeynCalc`CA^4*Global`v^6*Global`w^7 + 48*FeynCalc`CA^2*Global`v^7*
           Global`w^7 - 24*FeynCalc`CA^4*Global`v^7*Global`w^7 - 
          104*FeynCalc`CA^2*Global`v^8*Global`w^7 - 40*FeynCalc`CA^4*
           Global`v^8*Global`w^7 + 128*FeynCalc`CA^2*Global`v^9*Global`w^7 + 
          120*FeynCalc`CA^4*Global`v^9*Global`w^7 + 10*Global`v^10*
           Global`w^7 - 26*FeynCalc`CA^2*Global`v^10*Global`w^7 - 
          552*FeynCalc`CA^4*Global`v^10*Global`w^7 - 10*Global`v^11*
           Global`w^7 - 30*FeynCalc`CA^2*Global`v^11*Global`w^7 + 
          488*FeynCalc`CA^4*Global`v^11*Global`w^7 + 104*FeynCalc`CA^2*
           Global`v^12*Global`w^7 - 272*FeynCalc`CA^4*Global`v^12*
           Global`w^7 + 4*FeynCalc`CA^2*Global`v^6*Global`w^8 + 
          4*FeynCalc`CA^4*Global`v^6*Global`w^8 - 12*FeynCalc`CA^2*Global`v^7*
           Global`w^8 - 12*FeynCalc`CA^4*Global`v^7*Global`w^8 - 
          2*Global`v^8*Global`w^8 + 18*FeynCalc`CA^2*Global`v^8*Global`w^8 + 
          32*FeynCalc`CA^4*Global`v^8*Global`w^8 + 4*Global`v^9*Global`w^8 - 
          16*FeynCalc`CA^2*Global`v^9*Global`w^8 - 44*FeynCalc`CA^4*
           Global`v^9*Global`w^8 - 5*Global`v^10*Global`w^8 - 
          46*FeynCalc`CA^2*Global`v^10*Global`w^8 + 211*FeynCalc`CA^4*
           Global`v^10*Global`w^8 + 3*Global`v^11*Global`w^8 + 
          52*FeynCalc`CA^2*Global`v^11*Global`w^8 - 191*FeynCalc`CA^4*
           Global`v^11*Global`w^8 - 88*FeynCalc`CA^2*Global`v^12*Global`w^8 + 
          144*FeynCalc`CA^4*Global`v^12*Global`w^8 + 16*FeynCalc`CA^2*
           Global`v^10*Global`w^9 - 32*FeynCalc`CA^4*Global`v^10*Global`w^9 - 
          16*FeynCalc`CA^2*Global`v^11*Global`w^9 + 32*FeynCalc`CA^4*
           Global`v^11*Global`w^9 + 40*FeynCalc`CA^2*Global`v^12*Global`w^9 - 
          48*FeynCalc`CA^4*Global`v^12*Global`w^9 - 8*FeynCalc`CA^2*
           Global`v^12*Global`w^10 + 8*FeynCalc`CA^4*Global`v^12*Global`w^10)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(8*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^3*Global`w^2*
         (-1 + Global`v*Global`w)^3*(1 - Global`v + Global`v*Global`w)^3) + 
       ((8*FeynCalc`CA^4 - 16*FeynCalc`CA^4*Global`v + 16*FeynCalc`CA^4*
           Global`v^2 - 16*FeynCalc`CA^4*Global`v^4 + 16*FeynCalc`CA^4*
           Global`v^5 - 8*FeynCalc`CA^4*Global`v^6 - FeynCalc`CA^2*Global`v*
           Global`w - 18*FeynCalc`CA^4*Global`v*Global`w + 
          Global`v^2*Global`w + 3*FeynCalc`CA^2*Global`v^2*Global`w + 
          34*FeynCalc`CA^4*Global`v^2*Global`w - 4*Global`v^3*Global`w - 
          2*FeynCalc`CA^2*Global`v^3*Global`w - 37*FeynCalc`CA^4*Global`v^3*
           Global`w + 6*Global`v^4*Global`w - 2*FeynCalc`CA^2*Global`v^4*
           Global`w + 33*FeynCalc`CA^4*Global`v^4*Global`w - 
          4*Global`v^5*Global`w + 3*FeynCalc`CA^2*Global`v^5*Global`w - 
          9*FeynCalc`CA^4*Global`v^5*Global`w + Global`v^6*Global`w - 
          FeynCalc`CA^2*Global`v^6*Global`w + 5*FeynCalc`CA^4*Global`v^6*
           Global`w + 8*FeynCalc`CA^4*Global`v^7*Global`w + 
          8*FeynCalc`CA^4*Global`w^2 - 34*FeynCalc`CA^4*Global`v*Global`w^2 - 
          6*FeynCalc`CA^2*Global`v^2*Global`w^2 + 75*FeynCalc`CA^4*Global`v^2*
           Global`w^2 + 14*FeynCalc`CA^2*Global`v^3*Global`w^2 - 
          98*FeynCalc`CA^4*Global`v^3*Global`w^2 + Global`v^4*Global`w^2 - 
          28*FeynCalc`CA^2*Global`v^4*Global`w^2 + 53*FeynCalc`CA^4*
           Global`v^4*Global`w^2 - 3*Global`v^5*Global`w^2 + 
          37*FeynCalc`CA^2*Global`v^5*Global`w^2 - 33*FeynCalc`CA^4*
           Global`v^5*Global`w^2 + 3*Global`v^6*Global`w^2 - 
          26*FeynCalc`CA^2*Global`v^6*Global`w^2 - 22*FeynCalc`CA^4*
           Global`v^6*Global`w^2 - Global`v^7*Global`w^2 + 
          9*FeynCalc`CA^2*Global`v^7*Global`w^2 + 3*FeynCalc`CA^4*Global`v^7*
           Global`w^2 - 8*FeynCalc`CA^4*Global`v^8*Global`w^2 + 
          8*FeynCalc`CA^4*Global`v^2*Global`w^3 + FeynCalc`CA^2*Global`v^3*
           Global`w^3 - 19*FeynCalc`CA^4*Global`v^3*Global`w^3 + 
          21*FeynCalc`CA^2*Global`v^4*Global`w^3 + 72*FeynCalc`CA^4*
           Global`v^4*Global`w^3 + Global`v^5*Global`w^3 - 
          43*FeynCalc`CA^2*Global`v^5*Global`w^3 - 61*FeynCalc`CA^4*
           Global`v^5*Global`w^3 - 2*Global`v^6*Global`w^3 + 
          22*FeynCalc`CA^2*Global`v^6*Global`w^3 + 123*FeynCalc`CA^4*
           Global`v^6*Global`w^3 + Global`v^7*Global`w^3 - 
          FeynCalc`CA^2*Global`v^7*Global`w^3 - 67*FeynCalc`CA^4*Global`v^7*
           Global`w^3 - 8*FeynCalc`CA^2*Global`v^8*Global`w^3 + 
          32*FeynCalc`CA^4*Global`v^8*Global`w^3 - 8*FeynCalc`CA^4*Global`v^2*
           Global`w^4 + 26*FeynCalc`CA^4*Global`v^3*Global`w^4 - 
          6*FeynCalc`CA^2*Global`v^4*Global`w^4 - 65*FeynCalc`CA^4*Global`v^4*
           Global`w^4 + 7*FeynCalc`CA^2*Global`v^5*Global`w^4 + 
          54*FeynCalc`CA^4*Global`v^5*Global`w^4 + Global`v^6*Global`w^4 + 
          28*FeynCalc`CA^2*Global`v^6*Global`w^4 - 142*FeynCalc`CA^4*
           Global`v^6*Global`w^4 - Global`v^7*Global`w^4 - 
          29*FeynCalc`CA^2*Global`v^7*Global`w^4 + 103*FeynCalc`CA^4*
           Global`v^7*Global`w^4 + 24*FeynCalc`CA^2*Global`v^8*Global`w^4 - 
          52*FeynCalc`CA^4*Global`v^8*Global`w^4 + 4*FeynCalc`CA^2*Global`v^5*
           Global`w^5 + 7*FeynCalc`CA^4*Global`v^5*Global`w^5 - 
          Global`v^6*Global`w^5 - 33*FeynCalc`CA^2*Global`v^6*Global`w^5 + 
          64*FeynCalc`CA^4*Global`v^6*Global`w^5 + Global`v^7*Global`w^5 + 
          29*FeynCalc`CA^2*Global`v^7*Global`w^5 - 63*FeynCalc`CA^4*
           Global`v^7*Global`w^5 - 28*FeynCalc`CA^2*Global`v^8*Global`w^5 + 
          44*FeynCalc`CA^4*Global`v^8*Global`w^5 + 8*FeynCalc`CA^2*Global`v^6*
           Global`w^6 - 16*FeynCalc`CA^4*Global`v^6*Global`w^6 - 
          8*FeynCalc`CA^2*Global`v^7*Global`w^6 + 16*FeynCalc`CA^4*Global`v^7*
           Global`w^6 + 16*FeynCalc`CA^2*Global`v^8*Global`w^6 - 
          20*FeynCalc`CA^4*Global`v^8*Global`w^6 - 4*FeynCalc`CA^2*Global`v^8*
           Global`w^7 + 4*FeynCalc`CA^4*Global`v^8*Global`w^7)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^3*
         (-1 + Global`w)*Global`w^2*(-1 + Global`v*Global`w)*
         (1 - Global`v + Global`v*Global`w)) + 
       ((-80*FeynCalc`CA^4 + 480*FeynCalc`CA^4*Global`v - 
          1392*FeynCalc`CA^4*Global`v^2 + 2560*FeynCalc`CA^4*Global`v^3 - 
          3264*FeynCalc`CA^4*Global`v^4 + 2976*FeynCalc`CA^4*Global`v^5 - 
          1936*FeynCalc`CA^4*Global`v^6 + 864*FeynCalc`CA^4*Global`v^7 - 
          240*FeynCalc`CA^4*Global`v^8 + 32*FeynCalc`CA^4*Global`v^9 + 
          4*FeynCalc`CA^2*Global`w - 52*FeynCalc`CA^4*Global`w - 
          24*FeynCalc`CA^2*Global`v*Global`w + 312*FeynCalc`CA^4*Global`v*
           Global`w - 4*Global`v^2*Global`w + 70*FeynCalc`CA^2*Global`v^2*
           Global`w - 866*FeynCalc`CA^4*Global`v^2*Global`w + 
          20*Global`v^3*Global`w - 130*FeynCalc`CA^2*Global`v^3*Global`w + 
          1470*FeynCalc`CA^4*Global`v^3*Global`w - 48*Global`v^4*Global`w + 
          172*FeynCalc`CA^2*Global`v^4*Global`w - 1948*FeynCalc`CA^4*
           Global`v^4*Global`w + 72*Global`v^5*Global`w - 
          172*FeynCalc`CA^2*Global`v^5*Global`w + 2404*FeynCalc`CA^4*
           Global`v^5*Global`w - 68*Global`v^6*Global`w + 
          126*FeynCalc`CA^2*Global`v^6*Global`w - 2698*FeynCalc`CA^4*
           Global`v^6*Global`w + 36*Global`v^7*Global`w - 
          58*FeynCalc`CA^2*Global`v^7*Global`w + 2422*FeynCalc`CA^4*
           Global`v^7*Global`w - 8*Global`v^8*Global`w + 
          12*FeynCalc`CA^2*Global`v^8*Global`w - 1508*FeynCalc`CA^4*
           Global`v^8*Global`w + 560*FeynCalc`CA^4*Global`v^9*Global`w - 
          96*FeynCalc`CA^4*Global`v^10*Global`w - 4*FeynCalc`CA^2*
           Global`w^2 - 4*FeynCalc`CA^4*Global`w^2 + 24*FeynCalc`CA^2*
           Global`v*Global`w^2 + 24*FeynCalc`CA^4*Global`v*Global`w^2 + 
          2*Global`v^2*Global`w^2 - 54*FeynCalc`CA^2*Global`v^2*Global`w^2 + 
          4*FeynCalc`CA^4*Global`v^2*Global`w^2 - 10*Global`v^3*Global`w^2 + 
          50*FeynCalc`CA^2*Global`v^3*Global`w^2 - 240*FeynCalc`CA^4*
           Global`v^3*Global`w^2 + 24*Global`v^4*Global`w^2 + 
          36*FeynCalc`CA^2*Global`v^4*Global`w^2 + 1060*FeynCalc`CA^4*
           Global`v^4*Global`w^2 - 36*Global`v^5*Global`w^2 - 
          180*FeynCalc`CA^2*Global`v^5*Global`w^2 - 2536*FeynCalc`CA^4*
           Global`v^5*Global`w^2 + 12*Global`v^6*Global`w^2 + 
          290*FeynCalc`CA^2*Global`v^6*Global`w^2 + 3686*FeynCalc`CA^4*
           Global`v^6*Global`w^2 + 48*Global`v^7*Global`w^2 - 
          294*FeynCalc`CA^2*Global`v^7*Global`w^2 - 3454*FeynCalc`CA^4*
           Global`v^7*Global`w^2 - 62*Global`v^8*Global`w^2 + 
          180*FeynCalc`CA^2*Global`v^8*Global`w^2 + 1790*FeynCalc`CA^4*
           Global`v^8*Global`w^2 + 22*Global`v^9*Global`w^2 - 
          48*FeynCalc`CA^2*Global`v^9*Global`w^2 - 170*FeynCalc`CA^4*
           Global`v^9*Global`w^2 - 256*FeynCalc`CA^4*Global`v^10*Global`w^2 + 
          96*FeynCalc`CA^4*Global`v^11*Global`w^2 - 24*FeynCalc`CA^2*
           Global`v^2*Global`w^3 + 144*FeynCalc`CA^4*Global`v^2*Global`w^3 + 
          120*FeynCalc`CA^2*Global`v^3*Global`w^3 - 720*FeynCalc`CA^4*
           Global`v^3*Global`w^3 + 4*Global`v^4*Global`w^3 - 
          296*FeynCalc`CA^2*Global`v^4*Global`w^3 + 1436*FeynCalc`CA^4*
           Global`v^4*Global`w^3 - 16*Global`v^5*Global`w^3 + 
          464*FeynCalc`CA^2*Global`v^5*Global`w^3 - 1424*FeynCalc`CA^4*
           Global`v^5*Global`w^3 + 70*Global`v^6*Global`w^3 - 
          468*FeynCalc`CA^2*Global`v^6*Global`w^3 + 874*FeynCalc`CA^4*
           Global`v^6*Global`w^3 - 154*Global`v^7*Global`w^3 + 
          284*FeynCalc`CA^2*Global`v^7*Global`w^3 - 662*FeynCalc`CA^4*
           Global`v^7*Global`w^3 + 120*Global`v^8*Global`w^3 - 
          24*FeynCalc`CA^2*Global`v^8*Global`w^3 + 1460*FeynCalc`CA^4*
           Global`v^8*Global`w^3 - 2*Global`v^9*Global`w^3 - 
          124*FeynCalc`CA^2*Global`v^9*Global`w^3 - 2038*FeynCalc`CA^4*
           Global`v^9*Global`w^3 - 22*Global`v^10*Global`w^3 + 
          68*FeynCalc`CA^2*Global`v^10*Global`w^3 + 1138*FeynCalc`CA^4*
           Global`v^10*Global`w^3 - 208*FeynCalc`CA^4*Global`v^11*
           Global`w^3 - 32*FeynCalc`CA^4*Global`v^12*Global`w^3 + 
          12*FeynCalc`CA^2*Global`v^2*Global`w^4 + 12*FeynCalc`CA^4*
           Global`v^2*Global`w^4 - 60*FeynCalc`CA^2*Global`v^3*Global`w^4 - 
          60*FeynCalc`CA^4*Global`v^3*Global`w^4 - 6*Global`v^4*Global`w^4 + 
          102*FeynCalc`CA^2*Global`v^4*Global`w^4 + 240*FeynCalc`CA^4*
           Global`v^4*Global`w^4 + 24*Global`v^5*Global`w^4 - 
          48*FeynCalc`CA^2*Global`v^5*Global`w^4 - 600*FeynCalc`CA^4*
           Global`v^5*Global`w^4 - 67*Global`v^6*Global`w^4 - 
          154*FeynCalc`CA^2*Global`v^6*Global`w^4 + 437*FeynCalc`CA^4*
           Global`v^6*Global`w^4 + 117*Global`v^7*Global`w^4 + 
          378*FeynCalc`CA^2*Global`v^7*Global`w^4 + 537*FeynCalc`CA^4*
           Global`v^7*Global`w^4 - 19*Global`v^8*Global`w^4 - 
          436*FeynCalc`CA^2*Global`v^8*Global`w^4 - 2073*FeynCalc`CA^4*
           Global`v^8*Global`w^4 - 129*Global`v^9*Global`w^4 + 
          306*FeynCalc`CA^2*Global`v^9*Global`w^4 + 2671*FeynCalc`CA^4*
           Global`v^9*Global`w^4 + 74*Global`v^10*Global`w^4 - 
          52*FeynCalc`CA^2*Global`v^10*Global`w^4 - 1130*FeynCalc`CA^4*
           Global`v^10*Global`w^4 + 6*Global`v^11*Global`w^4 - 
          48*FeynCalc`CA^2*Global`v^11*Global`w^4 - 34*FeynCalc`CA^4*
           Global`v^11*Global`w^4 + 144*FeynCalc`CA^4*Global`v^12*
           Global`w^4 + 36*FeynCalc`CA^2*Global`v^4*Global`w^5 - 
          132*FeynCalc`CA^4*Global`v^4*Global`w^5 - 144*FeynCalc`CA^2*
           Global`v^5*Global`w^5 + 528*FeynCalc`CA^4*Global`v^5*Global`w^5 + 
          298*FeynCalc`CA^2*Global`v^6*Global`w^5 - 642*FeynCalc`CA^4*
           Global`v^6*Global`w^5 - 390*FeynCalc`CA^2*Global`v^7*Global`w^5 + 
          78*FeynCalc`CA^4*Global`v^7*Global`w^5 - 122*Global`v^8*
           Global`w^5 + 246*FeynCalc`CA^2*Global`v^8*Global`w^5 + 
          972*FeynCalc`CA^4*Global`v^8*Global`w^5 + 244*Global`v^9*
           Global`w^5 - 10*FeynCalc`CA^2*Global`v^9*Global`w^5 - 
          1458*FeynCalc`CA^4*Global`v^9*Global`w^5 - 94*Global`v^10*
           Global`w^5 - 154*FeynCalc`CA^2*Global`v^10*Global`w^5 + 
          124*FeynCalc`CA^4*Global`v^10*Global`w^5 - 28*Global`v^11*
           Global`w^5 + 118*FeynCalc`CA^2*Global`v^11*Global`w^5 + 
          530*FeynCalc`CA^4*Global`v^11*Global`w^5 + 16*FeynCalc`CA^2*
           Global`v^12*Global`w^5 - 288*FeynCalc`CA^4*Global`v^12*
           Global`w^5 - 12*FeynCalc`CA^2*Global`v^4*Global`w^6 - 
          12*FeynCalc`CA^4*Global`v^4*Global`w^6 + 48*FeynCalc`CA^2*
           Global`v^5*Global`w^6 + 48*FeynCalc`CA^4*Global`v^5*Global`w^6 + 
          6*Global`v^6*Global`w^6 - 66*FeynCalc`CA^2*Global`v^6*Global`w^6 - 
          196*FeynCalc`CA^4*Global`v^6*Global`w^6 - 18*Global`v^7*
           Global`w^6 + 30*FeynCalc`CA^2*Global`v^7*Global`w^6 + 
          420*FeynCalc`CA^4*Global`v^7*Global`w^6 + 108*Global`v^8*
           Global`w^6 + 132*FeynCalc`CA^2*Global`v^8*Global`w^6 - 
          552*FeynCalc`CA^4*Global`v^8*Global`w^6 - 186*Global`v^9*
           Global`w^6 - 258*FeynCalc`CA^2*Global`v^9*Global`w^6 + 
          460*FeynCalc`CA^4*Global`v^9*Global`w^6 + 33*Global`v^10*
           Global`w^6 + 190*FeynCalc`CA^2*Global`v^10*Global`w^6 + 
          573*FeynCalc`CA^4*Global`v^10*Global`w^6 + 57*Global`v^11*
           Global`w^6 - 64*FeynCalc`CA^2*Global`v^11*Global`w^6 - 
          741*FeynCalc`CA^4*Global`v^11*Global`w^6 - 64*FeynCalc`CA^2*
           Global`v^12*Global`w^6 + 344*FeynCalc`CA^4*Global`v^12*
           Global`w^6 - 16*FeynCalc`CA^2*Global`v^6*Global`w^7 + 
          40*FeynCalc`CA^4*Global`v^6*Global`w^7 + 48*FeynCalc`CA^2*
           Global`v^7*Global`w^7 - 120*FeynCalc`CA^4*Global`v^7*Global`w^7 - 
          24*Global`v^8*Global`w^7 - 112*FeynCalc`CA^2*Global`v^8*
           Global`w^7 + 104*FeynCalc`CA^4*Global`v^8*Global`w^7 + 
          48*Global`v^9*Global`w^7 + 144*FeynCalc`CA^2*Global`v^9*
           Global`w^7 - 8*FeynCalc`CA^4*Global`v^9*Global`w^7 + 
          38*Global`v^10*Global`w^7 - 6*FeynCalc`CA^2*Global`v^10*
           Global`w^7 - 540*FeynCalc`CA^4*Global`v^10*Global`w^7 - 
          62*Global`v^11*Global`w^7 - 58*FeynCalc`CA^2*Global`v^11*
           Global`w^7 + 524*FeynCalc`CA^4*Global`v^11*Global`w^7 + 
          104*FeynCalc`CA^2*Global`v^12*Global`w^7 - 272*FeynCalc`CA^4*
           Global`v^12*Global`w^7 + 4*FeynCalc`CA^2*Global`v^6*Global`w^8 + 
          4*FeynCalc`CA^4*Global`v^6*Global`w^8 - 12*FeynCalc`CA^2*Global`v^7*
           Global`w^8 - 12*FeynCalc`CA^4*Global`v^7*Global`w^8 - 
          2*Global`v^8*Global`w^8 + 18*FeynCalc`CA^2*Global`v^8*Global`w^8 + 
          32*FeynCalc`CA^4*Global`v^8*Global`w^8 + 4*Global`v^9*Global`w^8 - 
          16*FeynCalc`CA^2*Global`v^9*Global`w^8 - 44*FeynCalc`CA^4*
           Global`v^9*Global`w^8 - 37*Global`v^10*Global`w^8 - 
          70*FeynCalc`CA^2*Global`v^10*Global`w^8 + 219*FeynCalc`CA^4*
           Global`v^10*Global`w^8 + 35*Global`v^11*Global`w^8 + 
          76*FeynCalc`CA^2*Global`v^11*Global`w^8 - 199*FeynCalc`CA^4*
           Global`v^11*Global`w^8 - 88*FeynCalc`CA^2*Global`v^12*Global`w^8 + 
          144*FeynCalc`CA^4*Global`v^12*Global`w^8 + 8*Global`v^10*
           Global`w^9 + 24*FeynCalc`CA^2*Global`v^10*Global`w^9 - 
          32*FeynCalc`CA^4*Global`v^10*Global`w^9 - 8*Global`v^11*
           Global`w^9 - 24*FeynCalc`CA^2*Global`v^11*Global`w^9 + 
          32*FeynCalc`CA^4*Global`v^11*Global`w^9 + 40*FeynCalc`CA^2*
           Global`v^12*Global`w^9 - 48*FeynCalc`CA^4*Global`v^12*Global`w^9 - 
          8*FeynCalc`CA^2*Global`v^12*Global`w^10 + 8*FeynCalc`CA^4*
           Global`v^12*Global`w^10)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`v])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^3*Global`w^2*(-1 + Global`v*Global`w)^3*
         (1 - Global`v + Global`v*Global`w)^3) + 
       ((-64*FeynCalc`CA^4 + 384*FeynCalc`CA^4*Global`v - 
          1120*FeynCalc`CA^4*Global`v^2 + 2080*FeynCalc`CA^4*Global`v^3 - 
          2688*FeynCalc`CA^4*Global`v^4 + 2496*FeynCalc`CA^4*Global`v^5 - 
          1664*FeynCalc`CA^4*Global`v^6 + 768*FeynCalc`CA^4*Global`v^7 - 
          224*FeynCalc`CA^4*Global`v^8 + 32*FeynCalc`CA^4*Global`v^9 + 
          4*FeynCalc`CA^2*Global`w - 52*FeynCalc`CA^4*Global`w - 
          24*FeynCalc`CA^2*Global`v*Global`w + 312*FeynCalc`CA^4*Global`v*
           Global`w - 4*Global`v^2*Global`w + 70*FeynCalc`CA^2*Global`v^2*
           Global`w - 864*FeynCalc`CA^4*Global`v^2*Global`w + 
          20*Global`v^3*Global`w - 130*FeynCalc`CA^2*Global`v^3*Global`w + 
          1460*FeynCalc`CA^4*Global`v^3*Global`w - 46*Global`v^4*Global`w + 
          170*FeynCalc`CA^2*Global`v^4*Global`w - 1906*FeynCalc`CA^4*
           Global`v^4*Global`w + 64*Global`v^5*Global`w - 
          164*FeynCalc`CA^2*Global`v^5*Global`w + 2296*FeynCalc`CA^4*
           Global`v^5*Global`w - 56*Global`v^6*Global`w + 
          114*FeynCalc`CA^2*Global`v^6*Global`w - 2524*FeynCalc`CA^4*
           Global`v^6*Global`w + 28*Global`v^7*Global`w - 
          50*FeynCalc`CA^2*Global`v^7*Global`w + 2236*FeynCalc`CA^4*
           Global`v^7*Global`w - 6*Global`v^8*Global`w + 
          10*FeynCalc`CA^2*Global`v^8*Global`w - 1390*FeynCalc`CA^4*
           Global`v^8*Global`w + 528*FeynCalc`CA^4*Global`v^9*Global`w - 
          96*FeynCalc`CA^4*Global`v^10*Global`w - 4*FeynCalc`CA^2*
           Global`w^2 - 4*FeynCalc`CA^4*Global`w^2 + 24*FeynCalc`CA^2*
           Global`v*Global`w^2 + 24*FeynCalc`CA^4*Global`v*Global`w^2 + 
          2*Global`v^2*Global`w^2 - 54*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          32*FeynCalc`CA^4*Global`v^2*Global`w^2 - 10*Global`v^3*Global`w^2 + 
          50*FeynCalc`CA^2*Global`v^3*Global`w^2 - 60*FeynCalc`CA^4*
           Global`v^3*Global`w^2 + 20*Global`v^4*Global`w^2 + 
          44*FeynCalc`CA^2*Global`v^4*Global`w^2 + 598*FeynCalc`CA^4*
           Global`v^4*Global`w^2 - 20*Global`v^5*Global`w^2 - 
          212*FeynCalc`CA^2*Global`v^5*Global`w^2 - 1768*FeynCalc`CA^4*
           Global`v^5*Global`w^2 - 6*Global`v^6*Global`w^2 + 
          336*FeynCalc`CA^2*Global`v^6*Global`w^2 + 2752*FeynCalc`CA^4*
           Global`v^6*Global`w^2 + 46*Global`v^7*Global`w^2 - 
          320*FeynCalc`CA^2*Global`v^7*Global`w^2 - 2584*FeynCalc`CA^4*
           Global`v^7*Global`w^2 - 48*Global`v^8*Global`w^2 + 
          182*FeynCalc`CA^2*Global`v^8*Global`w^2 + 1262*FeynCalc`CA^4*
           Global`v^8*Global`w^2 + 16*Global`v^9*Global`w^2 - 
          46*FeynCalc`CA^2*Global`v^9*Global`w^2 - 28*FeynCalc`CA^4*
           Global`v^9*Global`w^2 - 256*FeynCalc`CA^4*Global`v^10*Global`w^2 + 
          96*FeynCalc`CA^4*Global`v^11*Global`w^2 - 24*FeynCalc`CA^2*
           Global`v^2*Global`w^3 + 144*FeynCalc`CA^4*Global`v^2*Global`w^3 + 
          120*FeynCalc`CA^2*Global`v^3*Global`w^3 - 720*FeynCalc`CA^4*
           Global`v^3*Global`w^3 + 8*Global`v^4*Global`w^3 - 
          312*FeynCalc`CA^2*Global`v^4*Global`w^3 + 1462*FeynCalc`CA^4*
           Global`v^4*Global`w^3 - 32*Global`v^5*Global`w^3 + 
          528*FeynCalc`CA^2*Global`v^5*Global`w^3 - 1528*FeynCalc`CA^4*
           Global`v^5*Global`w^3 + 76*Global`v^6*Global`w^3 - 
          550*FeynCalc`CA^2*Global`v^6*Global`w^3 + 1118*FeynCalc`CA^4*
           Global`v^6*Global`w^3 - 116*Global`v^7*Global`w^3 + 
          306*FeynCalc`CA^2*Global`v^7*Global`w^3 - 1030*FeynCalc`CA^4*
           Global`v^7*Global`w^3 + 76*Global`v^8*Global`w^3 + 
          4*FeynCalc`CA^2*Global`v^8*Global`w^3 + 1592*FeynCalc`CA^4*
           Global`v^8*Global`w^3 + 4*Global`v^9*Global`w^3 - 
          142*FeynCalc`CA^2*Global`v^9*Global`w^3 - 1810*FeynCalc`CA^4*
           Global`v^9*Global`w^3 - 16*Global`v^10*Global`w^3 + 
          70*FeynCalc`CA^2*Global`v^10*Global`w^3 + 948*FeynCalc`CA^4*
           Global`v^10*Global`w^3 - 176*FeynCalc`CA^4*Global`v^11*
           Global`w^3 - 32*FeynCalc`CA^4*Global`v^12*Global`w^3 + 
          12*FeynCalc`CA^2*Global`v^2*Global`w^4 + 12*FeynCalc`CA^4*
           Global`v^2*Global`w^4 - 60*FeynCalc`CA^2*Global`v^3*Global`w^4 - 
          60*FeynCalc`CA^4*Global`v^3*Global`w^4 - 6*Global`v^4*Global`w^4 + 
          102*FeynCalc`CA^2*Global`v^4*Global`w^4 + 252*FeynCalc`CA^4*
           Global`v^4*Global`w^4 + 24*Global`v^5*Global`w^4 - 
          48*FeynCalc`CA^2*Global`v^5*Global`w^4 - 648*FeynCalc`CA^4*
           Global`v^5*Global`w^4 - 43*Global`v^6*Global`w^4 - 
          202*FeynCalc`CA^2*Global`v^6*Global`w^4 + 545*FeynCalc`CA^4*
           Global`v^6*Global`w^4 + 45*Global`v^7*Global`w^4 + 
          522*FeynCalc`CA^2*Global`v^7*Global`w^4 + 381*FeynCalc`CA^4*
           Global`v^7*Global`w^4 + 29*Global`v^8*Global`w^4 - 
          584*FeynCalc`CA^2*Global`v^8*Global`w^4 - 1583*FeynCalc`CA^4*
           Global`v^8*Global`w^4 - 105*Global`v^9*Global`w^4 + 
          362*FeynCalc`CA^2*Global`v^9*Global`w^4 + 1895*FeynCalc`CA^4*
           Global`v^9*Global`w^4 + 52*Global`v^10*Global`w^4 - 
          54*FeynCalc`CA^2*Global`v^10*Global`w^4 - 722*FeynCalc`CA^4*
           Global`v^10*Global`w^4 + 4*Global`v^11*Global`w^4 - 
          50*FeynCalc`CA^2*Global`v^11*Global`w^4 - 72*FeynCalc`CA^4*
           Global`v^11*Global`w^4 + 128*FeynCalc`CA^4*Global`v^12*
           Global`w^4 + 36*FeynCalc`CA^2*Global`v^4*Global`w^5 - 
          132*FeynCalc`CA^4*Global`v^4*Global`w^5 - 144*FeynCalc`CA^2*
           Global`v^5*Global`w^5 + 528*FeynCalc`CA^4*Global`v^5*Global`w^5 - 
          12*Global`v^6*Global`w^5 + 330*FeynCalc`CA^2*Global`v^6*
           Global`w^5 - 688*FeynCalc`CA^4*Global`v^6*Global`w^5 + 
          36*Global`v^7*Global`w^5 - 486*FeynCalc`CA^2*Global`v^7*
           Global`w^5 + 216*FeynCalc`CA^4*Global`v^7*Global`w^5 - 
          116*Global`v^8*Global`w^5 + 320*FeynCalc`CA^2*Global`v^8*
           Global`w^5 + 518*FeynCalc`CA^4*Global`v^8*Global`w^5 + 
          172*Global`v^9*Global`w^5 + 2*FeynCalc`CA^2*Global`v^9*Global`w^5 - 
          780*FeynCalc`CA^4*Global`v^9*Global`w^5 - 62*Global`v^10*
           Global`w^5 - 186*FeynCalc`CA^2*Global`v^10*Global`w^5 - 
          102*FeynCalc`CA^4*Global`v^10*Global`w^5 - 18*Global`v^11*
           Global`w^5 + 128*FeynCalc`CA^2*Global`v^11*Global`w^5 + 
          440*FeynCalc`CA^4*Global`v^11*Global`w^5 + 16*FeynCalc`CA^2*
           Global`v^12*Global`w^5 - 224*FeynCalc`CA^4*Global`v^12*
           Global`w^5 - 12*FeynCalc`CA^2*Global`v^4*Global`w^6 - 
          12*FeynCalc`CA^4*Global`v^4*Global`w^6 + 48*FeynCalc`CA^2*
           Global`v^5*Global`w^6 + 48*FeynCalc`CA^4*Global`v^5*Global`w^6 + 
          6*Global`v^6*Global`w^6 - 66*FeynCalc`CA^2*Global`v^6*Global`w^6 - 
          176*FeynCalc`CA^4*Global`v^6*Global`w^6 - 18*Global`v^7*
           Global`w^6 + 30*FeynCalc`CA^2*Global`v^7*Global`w^6 + 
          360*FeynCalc`CA^4*Global`v^7*Global`w^6 + 72*Global`v^8*
           Global`w^6 + 172*FeynCalc`CA^2*Global`v^8*Global`w^6 - 
          382*FeynCalc`CA^4*Global`v^8*Global`w^6 - 114*Global`v^9*
           Global`w^6 - 338*FeynCalc`CA^2*Global`v^9*Global`w^6 + 
          220*FeynCalc`CA^4*Global`v^9*Global`w^6 + 19*Global`v^10*
           Global`w^6 + 244*FeynCalc`CA^2*Global`v^10*Global`w^6 + 
          465*FeynCalc`CA^4*Global`v^10*Global`w^6 + 35*Global`v^11*
           Global`w^6 - 78*FeynCalc`CA^2*Global`v^11*Global`w^6 - 
          523*FeynCalc`CA^4*Global`v^11*Global`w^6 - 64*FeynCalc`CA^2*
           Global`v^12*Global`w^6 + 240*FeynCalc`CA^4*Global`v^12*
           Global`w^6 - 16*FeynCalc`CA^2*Global`v^6*Global`w^7 + 
          40*FeynCalc`CA^4*Global`v^6*Global`w^7 + 48*FeynCalc`CA^2*
           Global`v^7*Global`w^7 - 120*FeynCalc`CA^4*Global`v^7*Global`w^7 - 
          12*Global`v^8*Global`w^7 - 128*FeynCalc`CA^2*Global`v^8*
           Global`w^7 + 110*FeynCalc`CA^4*Global`v^8*Global`w^7 + 
          24*Global`v^9*Global`w^7 + 176*FeynCalc`CA^2*Global`v^9*
           Global`w^7 - 20*FeynCalc`CA^4*Global`v^9*Global`w^7 + 
          24*Global`v^10*Global`w^7 - 28*FeynCalc`CA^2*Global`v^10*
           Global`w^7 - 348*FeynCalc`CA^4*Global`v^10*Global`w^7 - 
          36*Global`v^11*Global`w^7 - 52*FeynCalc`CA^2*Global`v^11*
           Global`w^7 + 338*FeynCalc`CA^4*Global`v^11*Global`w^7 + 
          104*FeynCalc`CA^2*Global`v^12*Global`w^7 - 184*FeynCalc`CA^4*
           Global`v^12*Global`w^7 + 4*FeynCalc`CA^2*Global`v^6*Global`w^8 + 
          4*FeynCalc`CA^4*Global`v^6*Global`w^8 - 12*FeynCalc`CA^2*Global`v^7*
           Global`w^8 - 12*FeynCalc`CA^4*Global`v^7*Global`w^8 - 
          2*Global`v^8*Global`w^8 + 18*FeynCalc`CA^2*Global`v^8*Global`w^8 + 
          20*FeynCalc`CA^4*Global`v^8*Global`w^8 + 4*Global`v^9*Global`w^8 - 
          16*FeynCalc`CA^2*Global`v^9*Global`w^8 - 20*FeynCalc`CA^4*
           Global`v^9*Global`w^8 - 21*Global`v^10*Global`w^8 - 
          70*FeynCalc`CA^2*Global`v^10*Global`w^8 + 131*FeynCalc`CA^4*
           Global`v^10*Global`w^8 + 19*Global`v^11*Global`w^8 + 
          76*FeynCalc`CA^2*Global`v^11*Global`w^8 - 123*FeynCalc`CA^4*
           Global`v^11*Global`w^8 - 88*FeynCalc`CA^2*Global`v^12*Global`w^8 + 
          104*FeynCalc`CA^4*Global`v^12*Global`w^8 + 4*Global`v^10*
           Global`w^9 + 24*FeynCalc`CA^2*Global`v^10*Global`w^9 - 
          20*FeynCalc`CA^4*Global`v^10*Global`w^9 - 4*Global`v^11*
           Global`w^9 - 24*FeynCalc`CA^2*Global`v^11*Global`w^9 + 
          20*FeynCalc`CA^4*Global`v^11*Global`w^9 + 40*FeynCalc`CA^2*
           Global`v^12*Global`w^9 - 40*FeynCalc`CA^4*Global`v^12*Global`w^9 - 
          8*FeynCalc`CA^2*Global`v^12*Global`w^10 + 8*FeynCalc`CA^4*
           Global`v^12*Global`w^10)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`w])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^3*Global`w^2*(-1 + Global`v*Global`w)^3*
         (1 - Global`v + Global`v*Global`w)^3) - 
       ((-24*FeynCalc`CA^4 + 96*FeynCalc`CA^4*Global`v - 208*FeynCalc`CA^4*
           Global`v^2 + 288*FeynCalc`CA^4*Global`v^3 - 272*FeynCalc`CA^4*
           Global`v^4 + 176*FeynCalc`CA^4*Global`v^5 - 72*FeynCalc`CA^4*
           Global`v^6 + 16*FeynCalc`CA^4*Global`v^7 + 8*FeynCalc`CA^4*
           Global`w - 32*FeynCalc`CA^4*Global`v*Global`w - 
          2*Global`v^2*Global`w + FeynCalc`CA^2*Global`v^2*Global`w + 
          129*FeynCalc`CA^4*Global`v^2*Global`w + 6*Global`v^3*Global`w - 
          3*FeynCalc`CA^2*Global`v^3*Global`w - 275*FeynCalc`CA^4*Global`v^3*
           Global`w - 8*Global`v^4*Global`w + 5*FeynCalc`CA^2*Global`v^4*
           Global`w + 323*FeynCalc`CA^4*Global`v^4*Global`w + 
          6*Global`v^5*Global`w - 5*FeynCalc`CA^2*Global`v^5*Global`w - 
          225*FeynCalc`CA^4*Global`v^5*Global`w - 2*Global`v^6*Global`w + 
          2*FeynCalc`CA^2*Global`v^6*Global`w + 56*FeynCalc`CA^4*Global`v^6*
           Global`w + 16*FeynCalc`CA^4*Global`v^7*Global`w - 
          16*FeynCalc`CA^4*Global`v^8*Global`w - 4*FeynCalc`CA^2*Global`v^2*
           Global`w^2 - 29*FeynCalc`CA^4*Global`v^2*Global`w^2 + 
          12*FeynCalc`CA^2*Global`v^3*Global`w^2 + 87*FeynCalc`CA^4*
           Global`v^3*Global`w^2 + Global`v^4*Global`w^2 - 
          19*FeynCalc`CA^2*Global`v^4*Global`w^2 - 62*FeynCalc`CA^4*
           Global`v^4*Global`w^2 - 2*Global`v^5*Global`w^2 + 
          18*FeynCalc`CA^2*Global`v^5*Global`w^2 - 21*FeynCalc`CA^4*
           Global`v^5*Global`w^2 - Global`v^6*Global`w^2 - 
          7*FeynCalc`CA^2*Global`v^6*Global`w^2 + 169*FeynCalc`CA^4*
           Global`v^6*Global`w^2 + 2*Global`v^7*Global`w^2 - 
          144*FeynCalc`CA^4*Global`v^7*Global`w^2 + 56*FeynCalc`CA^4*
           Global`v^8*Global`w^2 - 2*FeynCalc`CA^4*Global`v^2*Global`w^3 + 
          6*FeynCalc`CA^4*Global`v^3*Global`w^3 - 4*Global`v^4*Global`w^3 + 
          7*FeynCalc`CA^2*Global`v^4*Global`w^3 - 85*FeynCalc`CA^4*Global`v^4*
           Global`w^3 + 8*Global`v^5*Global`w^3 - 14*FeynCalc`CA^2*Global`v^5*
           Global`w^3 + 160*FeynCalc`CA^4*Global`v^5*Global`w^3 + 
          Global`v^6*Global`w^3 + 7*FeynCalc`CA^2*Global`v^6*Global`w^3 - 
          299*FeynCalc`CA^4*Global`v^6*Global`w^3 - 5*Global`v^7*Global`w^3 + 
          220*FeynCalc`CA^4*Global`v^7*Global`w^3 - 80*FeynCalc`CA^4*
           Global`v^8*Global`w^3 + 2*Global`v^4*Global`w^4 - 
          4*FeynCalc`CA^2*Global`v^4*Global`w^4 + 41*FeynCalc`CA^4*Global`v^4*
           Global`w^4 - 4*Global`v^5*Global`w^4 + 8*FeynCalc`CA^2*Global`v^5*
           Global`w^4 - 82*FeynCalc`CA^4*Global`v^5*Global`w^4 - 
          7*Global`v^6*Global`w^4 - 4*FeynCalc`CA^2*Global`v^6*Global`w^4 + 
          194*FeynCalc`CA^4*Global`v^6*Global`w^4 + 9*Global`v^7*Global`w^4 - 
          153*FeynCalc`CA^4*Global`v^7*Global`w^4 + 60*FeynCalc`CA^4*
           Global`v^8*Global`w^4 - 6*FeynCalc`CA^4*Global`v^4*Global`w^5 + 
          12*FeynCalc`CA^4*Global`v^5*Global`w^5 + 8*Global`v^6*Global`w^5 - 
          57*FeynCalc`CA^4*Global`v^6*Global`w^5 - 8*Global`v^7*Global`w^5 + 
          51*FeynCalc`CA^4*Global`v^7*Global`w^5 - 24*FeynCalc`CA^4*
           Global`v^8*Global`w^5 - 2*Global`v^6*Global`w^6 + 
          6*FeynCalc`CA^4*Global`v^6*Global`w^6 + 2*Global`v^7*Global`w^6 - 
          6*FeynCalc`CA^4*Global`v^7*Global`w^6 + 4*FeynCalc`CA^4*Global`v^8*
           Global`w^6)*FeynFacet`\[Alpha]s^3*System`Log[Global`w])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^3*
         (-1 + Global`w)*Global`w^2*(-1 + Global`v*Global`w)*
         (1 - Global`v + Global`v*Global`w)) - 
       ((-16*FeynCalc`CA^4 + 32*FeynCalc`CA^4*Global`v - 
          48*FeynCalc`CA^4*Global`v^2 + 32*FeynCalc`CA^4*Global`v^3 - 
          16*FeynCalc`CA^4*Global`v^4 + FeynCalc`CA^2*Global`v*Global`w + 
          20*FeynCalc`CA^4*Global`v*Global`w - Global`v^2*Global`w - 
          2*FeynCalc`CA^2*Global`v^2*Global`w + 15*FeynCalc`CA^4*Global`v^2*
           Global`w + 3*Global`v^3*Global`w - 21*FeynCalc`CA^4*Global`v^3*
           Global`w - 4*Global`v^4*Global`w + 3*FeynCalc`CA^2*Global`v^4*
           Global`w + 40*FeynCalc`CA^4*Global`v^4*Global`w + 
          2*Global`v^5*Global`w - 2*FeynCalc`CA^2*Global`v^5*Global`w - 
          6*FeynCalc`CA^4*Global`v^5*Global`w + 6*FeynCalc`CA^2*Global`v^2*
           Global`w^2 - 40*FeynCalc`CA^4*Global`v^2*Global`w^2 - 
          9*FeynCalc`CA^2*Global`v^3*Global`w^2 + 29*FeynCalc`CA^4*Global`v^3*
           Global`w^2 + 3*Global`v^4*Global`w^2 + 18*FeynCalc`CA^2*Global`v^4*
           Global`w^2 - 72*FeynCalc`CA^4*Global`v^4*Global`w^2 - 
          3*Global`v^5*Global`w^2 - 15*FeynCalc`CA^2*Global`v^5*Global`w^2 + 
          27*FeynCalc`CA^4*Global`v^5*Global`w^2 + 8*FeynCalc`CA^2*Global`v^6*
           Global`w^2 - 8*FeynCalc`CA^4*Global`v^6*Global`w^2 + 
          15*FeynCalc`CA^4*Global`v^3*Global`w^3 - 5*Global`v^4*Global`w^3 - 
          25*FeynCalc`CA^2*Global`v^4*Global`w^3 + 42*FeynCalc`CA^4*
           Global`v^4*Global`w^3 + 5*Global`v^5*Global`w^3 + 
          25*FeynCalc`CA^2*Global`v^5*Global`w^3 - 25*FeynCalc`CA^4*
           Global`v^5*Global`w^3 - 16*FeynCalc`CA^2*Global`v^6*Global`w^3 + 
          16*FeynCalc`CA^4*Global`v^6*Global`w^3 + 2*Global`v^4*Global`w^4 + 
          10*FeynCalc`CA^2*Global`v^4*Global`w^4 - 16*FeynCalc`CA^4*
           Global`v^4*Global`w^4 - 2*Global`v^5*Global`w^4 - 
          10*FeynCalc`CA^2*Global`v^5*Global`w^4 + 8*FeynCalc`CA^4*Global`v^5*
           Global`w^4 + 12*FeynCalc`CA^2*Global`v^6*Global`w^4 - 
          12*FeynCalc`CA^4*Global`v^6*Global`w^4 - 4*FeynCalc`CA^2*Global`v^6*
           Global`w^5 + 4*FeynCalc`CA^4*Global`v^6*Global`w^5)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v*Global`w])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^3*
         (-1 + Global`w)*Global`w^2) - 
       ((FeynCalc`CA^2 + 4*FeynCalc`CA^4 - 3*FeynCalc`CA^2*Global`v - 
          12*FeynCalc`CA^4*Global`v + 3*FeynCalc`CA^2*Global`v^2 + 
          12*FeynCalc`CA^4*Global`v^2 - 3*FeynCalc`CA^2*Global`v^4 - 
          12*FeynCalc`CA^4*Global`v^4 + 3*FeynCalc`CA^2*Global`v^5 + 
          12*FeynCalc`CA^4*Global`v^5 - FeynCalc`CA^2*Global`v^6 - 
          4*FeynCalc`CA^4*Global`v^6 + Global`v*Global`w + 
          3*FeynCalc`CA^2*Global`v*Global`w + 5*FeynCalc`CA^4*Global`v*
           Global`w - 2*Global`v^2*Global`w - 5*FeynCalc`CA^2*Global`v^2*
           Global`w - 15*FeynCalc`CA^4*Global`v^2*Global`w + 
          Global`v^3*Global`w - 8*FeynCalc`CA^2*Global`v^3*Global`w + 
          3*FeynCalc`CA^4*Global`v^3*Global`w + Global`v^4*Global`w + 
          30*FeynCalc`CA^2*Global`v^4*Global`w + 29*FeynCalc`CA^4*Global`v^4*
           Global`w - 2*Global`v^5*Global`w - 31*FeynCalc`CA^2*Global`v^5*
           Global`w - 32*FeynCalc`CA^4*Global`v^5*Global`w + 
          Global`v^6*Global`w + 11*FeynCalc`CA^2*Global`v^6*Global`w + 
          10*FeynCalc`CA^4*Global`v^6*Global`w + 2*Global`v^2*Global`w^2 + 
          3*FeynCalc`CA^2*Global`v^2*Global`w^2 + 7*FeynCalc`CA^4*Global`v^2*
           Global`w^2 - Global`v^3*Global`w^2 + 3*FeynCalc`CA^2*Global`v^3*
           Global`w^2 - 2*FeynCalc`CA^4*Global`v^3*Global`w^2 - 
          8*Global`v^4*Global`w^2 - 47*FeynCalc`CA^2*Global`v^4*Global`w^2 - 
          33*FeynCalc`CA^4*Global`v^4*Global`w^2 + 13*Global`v^5*Global`w^2 + 
          71*FeynCalc`CA^2*Global`v^5*Global`w^2 + 34*FeynCalc`CA^4*
           Global`v^5*Global`w^2 - 6*Global`v^6*Global`w^2 - 
          30*FeynCalc`CA^2*Global`v^6*Global`w^2 - 6*FeynCalc`CA^4*Global`v^6*
           Global`w^2 + Global`v^3*Global`w^3 + 5*FeynCalc`CA^2*Global`v^3*
           Global`w^3 - 2*FeynCalc`CA^4*Global`v^3*Global`w^3 + 
          11*Global`v^4*Global`w^3 + 22*FeynCalc`CA^2*Global`v^4*Global`w^3 + 
          23*FeynCalc`CA^4*Global`v^4*Global`w^3 - 24*Global`v^5*Global`w^3 - 
          69*FeynCalc`CA^2*Global`v^5*Global`w^3 - 21*FeynCalc`CA^4*
           Global`v^5*Global`w^3 + 14*Global`v^6*Global`w^3 + 
          36*FeynCalc`CA^2*Global`v^6*Global`w^3 - 2*FeynCalc`CA^4*Global`v^6*
           Global`w^3 - 4*Global`v^4*Global`w^4 - 2*FeynCalc`CA^2*Global`v^4*
           Global`w^4 - 7*FeynCalc`CA^4*Global`v^4*Global`w^4 + 
          17*Global`v^5*Global`w^4 + 34*FeynCalc`CA^2*Global`v^5*Global`w^4 + 
          8*FeynCalc`CA^4*Global`v^5*Global`w^4 - 16*Global`v^6*Global`w^4 - 
          23*FeynCalc`CA^2*Global`v^6*Global`w^4 + 2*FeynCalc`CA^4*Global`v^6*
           Global`w^4 - 4*Global`v^5*Global`w^5 - 8*FeynCalc`CA^2*Global`v^5*
           Global`w^5 - FeynCalc`CA^4*Global`v^5*Global`w^5 + 
          9*Global`v^6*Global`w^5 + 9*FeynCalc`CA^2*Global`v^6*Global`w^5 - 
          2*Global`v^6*Global`w^6 - 2*FeynCalc`CA^2*Global`v^6*Global`w^6)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v + Global`v*Global`w])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*
         (-1 + Global`w)*Global`w*(1 - Global`v + Global`v*Global`w)^3)|>|>, 
 "DensityConvention" -> "E_c d sigma/d^(D-1)p_c", 
 "DistributionBasis" -> <|"Variable" -> Global`w, "Endpoint" -> 1, 
   "Interval" -> {0, 1}, "Distance" -> 1 - Global`w|>, 
 "PlusConvention" -> "At each axis, PlusCoefficients[k] multiplies \
[Log[Distance]^k/Distance]_+ on Interval, with subtraction at Endpoint. For \
DistributionBasis[Axes], delta/plus/regular values repeat recursively in the \
listed axis order."|>
