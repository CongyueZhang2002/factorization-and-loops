<|"Project" -> "ppHX_LL_NLO", "Channel" -> "u-g_g-u", "Scale" -> Global`s, 
 "Variables" -> {Global`v, Global`w}, "Coupling" -> FeynFacet`\[Alpha]s, 
 "CouplingPower" -> 3, "DimensionalPrefactor" -> 
  Global`muR2^(2*Global`Epsilon), "PhysicalChannel" -> 
  <|"Incoming" -> {{"q", "u"}, "g"}, "Observed" -> "g", 
   "Recoil" -> {"q", "u"}|>, "Polarization" -> <|"Incoming" -> {"L", "L"}, 
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
      ((-96*FeynCalc`CA^2 + 72*FeynCalc`CA^4 - 14*FeynCalc`CA^2*System`Pi^2 - 
          28*FeynCalc`CA^4*System`Pi^2 + 144*FeynCalc`CA^2*Global`v - 
          108*FeynCalc`CA^4*Global`v + 6*System`Pi^2*Global`v + 
          30*FeynCalc`CA^2*System`Pi^2*Global`v + 54*FeynCalc`CA^4*
           System`Pi^2*Global`v + 42*Global`v^2 - 132*FeynCalc`CA^2*
           Global`v^2 + 78*FeynCalc`CA^4*Global`v^2 - 8*System`Pi^2*
           Global`v^2 - 40*FeynCalc`CA^4*System`Pi^2*Global`v^2 - 
          21*Global`v^3 + 42*FeynCalc`CA^2*Global`v^3 - 21*FeynCalc`CA^4*
           Global`v^3 - 2*System`Pi^2*Global`v^3 - 8*FeynCalc`CA^2*
           System`Pi^2*Global`v^3 + 10*FeynCalc`CA^4*System`Pi^2*Global`v^3)*
         FeynFacet`\[Alpha]s^3)/(48*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2) - (3*(-1 + FeynCalc`CA)*
         (1 + FeynCalc`CA)*(-2 + Global`v)*(2*FeynCalc`CA^2 - 
          2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muFA2])/
        (16*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) + 
       ((11*FeynCalc`CA - 2*Global`nD - 2*Global`nU)*(-2 + Global`v)*
         (2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - Global`v^2 + 
          FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muR2])/(12*FeynCalc`CA^2*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2) + (3*(-1 + FeynCalc`CA)*
         (1 + FeynCalc`CA)*(-2 + Global`v)*(2*FeynCalc`CA^2 - 
          2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(16*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) + 
       ((-FeynCalc`CA^2 - 6*FeynCalc`CA^4 + Global`v + 3*FeynCalc`CA^2*
           Global`v + 11*FeynCalc`CA^4*Global`v - 2*Global`v^2 + 
          2*FeynCalc`CA^2*Global`v^2 - 8*FeynCalc`CA^4*Global`v^2 - 
          2*FeynCalc`CA^2*Global`v^3 + 2*FeynCalc`CA^4*Global`v^3)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v]^2)/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) + 
       (-1/16*((-2 + Global`v)*(4*FeynCalc`CA^2 + 4*FeynCalc`CA^4 - 
             4*FeynCalc`CA^2*Global`v - 4*FeynCalc`CA^4*Global`v + 
             3*Global`v^2 - 6*FeynCalc`CA^2*Global`v^2 + 3*FeynCalc`CA^4*
              Global`v^2)*FeynFacet`\[Alpha]s^3)/(FeynCalc`CA^3*System`Pi*
            Global`s^2*(-1 + Global`v)*Global`v^2) + 
         ((-2 + Global`v)*(2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - 
            Global`v^2 + FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s])/(FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2))*System`Log[Global`v] + 
       ((-2 + Global`v)*(FeynCalc`CA^2 + 22*FeynCalc`CA^4 - 
          FeynCalc`CA^2*Global`v - 22*FeynCalc`CA^4*Global`v + Global`v^2 - 
          4*FeynCalc`CA^2*Global`v^2 + 11*FeynCalc`CA^4*Global`v^2)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`v]^2)/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) + 
       System`Log[Global`muD2]*(-1/24*((11*FeynCalc`CA - 2*Global`nD - 
             2*Global`nU)*(-2 + Global`v)*(2*FeynCalc`CA^2 - 
             2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*
              Global`v^2)*FeynFacet`\[Alpha]s^3)/(FeynCalc`CA^2*System`Pi*
            Global`s^2*(-1 + Global`v)*Global`v^2) - 
         ((-2 + Global`v)*(2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - 
            Global`v^2 + FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2)) + System`Log[Global`muFB2]*
        (-1/24*((11*FeynCalc`CA - 2*Global`nD - 2*Global`nU)*(-2 + Global`v)*
            (2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - Global`v^2 + 
             FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
           (FeynCalc`CA^2*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) + 
         ((-2 + Global`v)*(2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - 
            Global`v^2 + FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[1 - Global`v])/(2*FeynCalc`CA*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2) - ((-2 + Global`v)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`v])/(2*FeynCalc`CA*
           System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2)) + 
       System`Log[1 - Global`v]*(((FeynCalc`CA^2 - Global`v)*
           (1 - 5*FeynCalc`CA^2 + 2*Global`v + 2*FeynCalc`CA^2*Global`v)*
           FeynFacet`\[Alpha]s^3)/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2) - ((-2 + Global`v)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(2*FeynCalc`CA*
           System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) - 
         ((-FeynCalc`CA^2 - 14*FeynCalc`CA^4 + Global`v + 3*FeynCalc`CA^2*
             Global`v + 23*FeynCalc`CA^4*Global`v - 2*Global`v^2 - 
            2*FeynCalc`CA^2*Global`v^2 - 16*FeynCalc`CA^4*Global`v^2 + 
            4*FeynCalc`CA^4*Global`v^3)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2)), "PlusCoefficients" -> 
      <|0 -> (-3*(-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-2 + Global`v)*
           (2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
          (16*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*
           Global`v^2) - ((-2 + Global`v)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`muD2])/
          (2*FeynCalc`CA*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) - 
         ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-2 + Global`v)*
           (2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFA2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v^2) - ((-2 + Global`v)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`muFB2])/
          (2*FeynCalc`CA*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) + 
         ((-1 + 5*FeynCalc`CA^2)*(-2 + Global`v)*(2*FeynCalc`CA^2 - 
            2*FeynCalc`CA^2*Global`v - Global`v^2 + FeynCalc`CA^2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(4*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2) - 
         (FeynCalc`CA*(-2 + Global`v)*(-1 + Global`v)*FeynFacet`\[Alpha]s^3*
           System`Log[1 - Global`v])/(System`Pi*Global`s^2*Global`v^2) + 
         ((-2 + Global`v)*(-2*FeynCalc`CA^2 + 18*FeynCalc`CA^4 + 
            2*FeynCalc`CA^2*Global`v - 18*FeynCalc`CA^4*Global`v + 
            Global`v^2 - 6*FeynCalc`CA^2*Global`v^2 + 9*FeynCalc`CA^4*
             Global`v^2)*FeynFacet`\[Alpha]s^3*System`Log[Global`v])/
          (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2), 
       1 -> ((-1 + 3*FeynCalc`CA)*(1 + 3*FeynCalc`CA)*(-2 + Global`v)*
          (2*FeynCalc`CA^2 - 2*FeynCalc`CA^2*Global`v - Global`v^2 + 
           FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
         (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2)|>, 
     "RegularCoefficient" -> 
      -1/16*((-96*FeynCalc`CA^4 + 2*Global`v - 4*FeynCalc`CA^2*Global`v + 
           434*FeynCalc`CA^4*Global`v - 10*Global`v^2 + 24*FeynCalc`CA^2*
            Global`v^2 - 958*FeynCalc`CA^4*Global`v^2 + 18*Global`v^3 - 
           48*FeynCalc`CA^2*Global`v^3 + 1294*FeynCalc`CA^4*Global`v^3 - 
           14*Global`v^4 + 40*FeynCalc`CA^2*Global`v^4 - 1066*FeynCalc`CA^4*
            Global`v^4 + 4*Global`v^5 - 12*FeynCalc`CA^2*Global`v^5 + 
           520*FeynCalc`CA^4*Global`v^5 - 160*FeynCalc`CA^4*Global`v^6 + 
           32*FeynCalc`CA^4*Global`v^7 - 4*FeynCalc`CA^2*Global`w + 
           92*FeynCalc`CA^4*Global`w + 18*FeynCalc`CA^2*Global`v*Global`w - 
           510*FeynCalc`CA^4*Global`v*Global`w + 6*Global`v^2*Global`w - 
           92*FeynCalc`CA^2*Global`v^2*Global`w + 1118*FeynCalc`CA^4*
            Global`v^2*Global`w - 17*Global`v^3*Global`w + 
           232*FeynCalc`CA^2*Global`v^3*Global`w - 1395*FeynCalc`CA^4*
            Global`v^3*Global`w + 7*Global`v^4*Global`w - 252*FeynCalc`CA^2*
            Global`v^4*Global`w + 785*FeynCalc`CA^4*Global`v^4*Global`w + 
           13*Global`v^5*Global`w + 110*FeynCalc`CA^2*Global`v^5*Global`w + 
           205*FeynCalc`CA^4*Global`v^5*Global`w - 9*Global`v^6*Global`w - 
           12*FeynCalc`CA^2*Global`v^6*Global`w - 423*FeynCalc`CA^4*
            Global`v^6*Global`w + 192*FeynCalc`CA^4*Global`v^7*Global`w - 
           64*FeynCalc`CA^4*Global`v^8*Global`w - 4*FeynCalc`CA^2*Global`v*
            Global`w^2 + 92*FeynCalc`CA^4*Global`v*Global`w^2 + 
           6*FeynCalc`CA^2*Global`v^2*Global`w^2 + 54*FeynCalc`CA^4*
            Global`v^2*Global`w^2 - 2*Global`v^3*Global`w^2 - 
           46*FeynCalc`CA^2*Global`v^3*Global`w^2 - 844*FeynCalc`CA^4*
            Global`v^3*Global`w^2 + 37*Global`v^4*Global`w^2 + 
           122*FeynCalc`CA^2*Global`v^4*Global`w^2 + 1817*FeynCalc`CA^4*
            Global`v^4*Global`w^2 - 56*Global`v^5*Global`w^2 - 
           124*FeynCalc`CA^2*Global`v^5*Global`w^2 - 2300*FeynCalc`CA^4*
            Global`v^5*Global`w^2 + 11*Global`v^6*Global`w^2 + 
           80*FeynCalc`CA^2*Global`v^6*Global`w^2 + 1449*FeynCalc`CA^4*
            Global`v^6*Global`w^2 + 10*Global`v^7*Global`w^2 - 
           34*FeynCalc`CA^2*Global`v^7*Global`w^2 - 396*FeynCalc`CA^4*
            Global`v^7*Global`w^2 + 96*FeynCalc`CA^4*Global`v^8*Global`w^2 + 
           32*FeynCalc`CA^4*Global`v^9*Global`w^2 + 8*FeynCalc`CA^2*
            Global`v^2*Global`w^3 - 184*FeynCalc`CA^4*Global`v^2*Global`w^3 - 
           36*FeynCalc`CA^2*Global`v^3*Global`w^3 + 1020*FeynCalc`CA^4*
            Global`v^3*Global`w^3 - 12*Global`v^4*Global`w^3 - 
           12*FeynCalc`CA^2*Global`v^4*Global`w^3 - 1696*FeynCalc`CA^4*
            Global`v^4*Global`w^3 - 38*Global`v^5*Global`w^3 + 
           216*FeynCalc`CA^2*Global`v^5*Global`w^3 + 1574*FeynCalc`CA^4*
            Global`v^5*Global`w^3 + 112*Global`v^6*Global`w^3 - 
           314*FeynCalc`CA^2*Global`v^6*Global`w^3 - 514*FeynCalc`CA^4*
            Global`v^6*Global`w^3 - 71*Global`v^7*Global`w^3 + 
           128*FeynCalc`CA^2*Global`v^7*Global`w^3 - 341*FeynCalc`CA^4*
            Global`v^7*Global`w^3 + 5*Global`v^8*Global`w^3 + 
           26*FeynCalc`CA^2*Global`v^8*Global`w^3 + 129*FeynCalc`CA^4*
            Global`v^8*Global`w^3 - 128*FeynCalc`CA^4*Global`v^9*Global`w^3 + 
           8*FeynCalc`CA^2*Global`v^3*Global`w^4 - 184*FeynCalc`CA^4*
            Global`v^3*Global`w^4 - 12*FeynCalc`CA^2*Global`v^4*Global`w^4 + 
           180*FeynCalc`CA^4*Global`v^4*Global`w^4 + 58*Global`v^5*
            Global`w^4 - 132*FeynCalc`CA^2*Global`v^5*Global`w^4 + 
           362*FeynCalc`CA^4*Global`v^5*Global`w^4 - 132*Global`v^6*
            Global`w^4 + 304*FeynCalc`CA^2*Global`v^6*Global`w^4 - 
           948*FeynCalc`CA^4*Global`v^6*Global`w^4 + 96*Global`v^7*
            Global`w^4 - 116*FeynCalc`CA^2*Global`v^7*Global`w^4 + 
           1092*FeynCalc`CA^4*Global`v^7*Global`w^4 - 9*Global`v^8*
            Global`w^4 - 86*FeynCalc`CA^2*Global`v^8*Global`w^4 - 
           321*FeynCalc`CA^4*Global`v^8*Global`w^4 - 16*FeynCalc`CA^2*
            Global`v^9*Global`w^4 + 208*FeynCalc`CA^4*Global`v^9*Global`w^4 - 
           4*FeynCalc`CA^2*Global`v^4*Global`w^5 + 92*FeynCalc`CA^4*
            Global`v^4*Global`w^5 + 18*FeynCalc`CA^2*Global`v^5*Global`w^5 - 
           510*FeynCalc`CA^4*Global`v^5*Global`w^5 + 22*Global`v^6*
            Global`w^5 - 80*FeynCalc`CA^2*Global`v^6*Global`w^5 + 
           746*FeynCalc`CA^4*Global`v^6*Global`w^5 - 41*Global`v^7*
            Global`w^5 + 16*FeynCalc`CA^2*Global`v^7*Global`w^5 - 
           739*FeynCalc`CA^4*Global`v^7*Global`w^5 + 3*Global`v^8*
            Global`w^5 + 86*FeynCalc`CA^2*Global`v^8*Global`w^5 + 
           199*FeynCalc`CA^4*Global`v^8*Global`w^5 + 64*FeynCalc`CA^2*
            Global`v^9*Global`w^5 - 192*FeynCalc`CA^4*Global`v^9*Global`w^5 - 
           4*FeynCalc`CA^2*Global`v^5*Global`w^6 + 92*FeynCalc`CA^4*
            Global`v^5*Global`w^6 + 6*FeynCalc`CA^2*Global`v^6*Global`w^6 - 
           138*FeynCalc`CA^4*Global`v^6*Global`w^6 + 6*Global`v^7*
            Global`w^6 + 6*FeynCalc`CA^2*Global`v^7*Global`w^6 + 
           160*FeynCalc`CA^4*Global`v^7*Global`w^6 + Global`v^8*Global`w^6 - 
           18*FeynCalc`CA^2*Global`v^8*Global`w^6 - 47*FeynCalc`CA^4*
            Global`v^8*Global`w^6 - 96*FeynCalc`CA^2*Global`v^9*Global`w^6 + 
           128*FeynCalc`CA^4*Global`v^9*Global`w^6 - 8*FeynCalc`CA^2*
            Global`v^8*Global`w^7 + 8*FeynCalc`CA^4*Global`v^8*Global`w^7 + 
           64*FeynCalc`CA^2*Global`v^9*Global`w^7 - 64*FeynCalc`CA^4*
            Global`v^9*Global`w^7 - 16*FeynCalc`CA^2*Global`v^9*Global`w^8 + 
           16*FeynCalc`CA^4*Global`v^9*Global`w^8)*FeynFacet`\[Alpha]s^3)/
         (FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*
          Global`w*(-1 + Global`v*Global`w)^2*
          (1 - Global`v + Global`v*Global`w)^3) - 
       ((-16*FeynCalc`CA^4 - Global`v + 2*FeynCalc`CA^2*Global`v + 
          79*FeynCalc`CA^4*Global`v + 3*Global`v^2 - 6*FeynCalc`CA^2*
           Global`v^2 - 189*FeynCalc`CA^4*Global`v^2 - 4*Global`v^3 + 
          8*FeynCalc`CA^2*Global`v^3 + 284*FeynCalc`CA^4*Global`v^3 + 
          4*Global`v^4 - 8*FeynCalc`CA^2*Global`v^4 - 284*FeynCalc`CA^4*
           Global`v^4 - 3*Global`v^5 + 6*FeynCalc`CA^2*Global`v^5 + 
          189*FeynCalc`CA^4*Global`v^5 + Global`v^6 - 2*FeynCalc`CA^2*
           Global`v^6 - 79*FeynCalc`CA^4*Global`v^6 + 16*FeynCalc`CA^4*
           Global`v^7 - 48*FeynCalc`CA^4*Global`v*Global`w - 
          2*Global`v^2*Global`w - 2*FeynCalc`CA^2*Global`v^2*Global`w + 
          228*FeynCalc`CA^4*Global`v^2*Global`w + 6*Global`v^3*Global`w + 
          12*FeynCalc`CA^2*Global`v^3*Global`w - 514*FeynCalc`CA^4*Global`v^3*
           Global`w - 10*Global`v^4*Global`w - 12*FeynCalc`CA^2*Global`v^4*
           Global`w + 694*FeynCalc`CA^4*Global`v^4*Global`w + 
          10*Global`v^5*Global`w - 4*FeynCalc`CA^2*Global`v^5*Global`w - 
          590*FeynCalc`CA^4*Global`v^5*Global`w - 4*Global`v^6*Global`w + 
          6*FeynCalc`CA^2*Global`v^6*Global`w + 302*FeynCalc`CA^4*Global`v^6*
           Global`w - 72*FeynCalc`CA^4*Global`v^7*Global`w - 
          48*FeynCalc`CA^4*Global`v^2*Global`w^2 - Global`v^3*Global`w^2 - 
          12*FeynCalc`CA^2*Global`v^3*Global`w^2 + 237*FeynCalc`CA^4*
           Global`v^3*Global`w^2 + 7*Global`v^4*Global`w^2 + 
          40*FeynCalc`CA^2*Global`v^4*Global`w^2 - 543*FeynCalc`CA^4*
           Global`v^4*Global`w^2 - 11*Global`v^5*Global`w^2 - 
          32*FeynCalc`CA^2*Global`v^5*Global`w^2 + 675*FeynCalc`CA^4*
           Global`v^5*Global`w^2 + 5*Global`v^6*Global`w^2 + 
          12*FeynCalc`CA^2*Global`v^6*Global`w^2 - 457*FeynCalc`CA^4*
           Global`v^6*Global`w^2 - 8*FeynCalc`CA^2*Global`v^7*Global`w^2 + 
          136*FeynCalc`CA^4*Global`v^7*Global`w^2 - 16*FeynCalc`CA^4*
           Global`v^3*Global`w^3 - 2*Global`v^4*Global`w^3 - 
          22*FeynCalc`CA^2*Global`v^4*Global`w^3 + 136*FeynCalc`CA^4*
           Global`v^4*Global`w^3 + 4*Global`v^5*Global`w^3 + 
          52*FeynCalc`CA^2*Global`v^5*Global`w^3 - 336*FeynCalc`CA^4*
           Global`v^5*Global`w^3 - 2*Global`v^6*Global`w^3 - 
          46*FeynCalc`CA^2*Global`v^6*Global`w^3 + 344*FeynCalc`CA^4*
           Global`v^6*Global`w^3 + 28*FeynCalc`CA^2*Global`v^7*Global`w^3 - 
          140*FeynCalc`CA^4*Global`v^7*Global`w^3 - 22*FeynCalc`CA^2*
           Global`v^5*Global`w^4 + 62*FeynCalc`CA^4*Global`v^5*Global`w^4 + 
          42*FeynCalc`CA^2*Global`v^6*Global`w^4 - 130*FeynCalc`CA^4*
           Global`v^6*Global`w^4 - 36*FeynCalc`CA^2*Global`v^7*Global`w^4 + 
          84*FeynCalc`CA^4*Global`v^7*Global`w^4 - 12*FeynCalc`CA^2*
           Global`v^6*Global`w^5 + 20*FeynCalc`CA^4*Global`v^6*Global`w^5 + 
          20*FeynCalc`CA^2*Global`v^7*Global`w^5 - 28*FeynCalc`CA^4*
           Global`v^7*Global`w^5 - 4*FeynCalc`CA^2*Global`v^7*Global`w^6 + 
          4*FeynCalc`CA^4*Global`v^7*Global`w^6)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muD2])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2*Global`w*
         (1 - Global`v + Global`v*Global`w)^3) - 
       ((4*FeynCalc`CA^2 - 36*FeynCalc`CA^4 - 6*FeynCalc`CA^2*Global`v + 
          54*FeynCalc`CA^4*Global`v - 2*Global`v^2 + 6*FeynCalc`CA^2*
           Global`v^2 - 68*FeynCalc`CA^4*Global`v^2 + Global`v^3 - 
          2*FeynCalc`CA^2*Global`v^3 + 33*FeynCalc`CA^4*Global`v^3 - 
          16*FeynCalc`CA^4*Global`v^4 - 4*FeynCalc`CA^2*Global`w + 
          20*FeynCalc`CA^4*Global`w + 6*FeynCalc`CA^2*Global`v*Global`w - 
          30*FeynCalc`CA^4*Global`v*Global`w + 2*Global`v^2*Global`w - 
          6*FeynCalc`CA^2*Global`v^2*Global`w + 36*FeynCalc`CA^4*Global`v^2*
           Global`w - Global`v^3*Global`w + 2*FeynCalc`CA^2*Global`v^3*
           Global`w - 17*FeynCalc`CA^4*Global`v^3*Global`w + 
          8*FeynCalc`CA^4*Global`v^4*Global`w)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muFA2])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2*Global`w) - 
       ((-16*FeynCalc`CA^4 + Global`v - 2*FeynCalc`CA^2*Global`v + 
          17*FeynCalc`CA^4*Global`v - 2*Global`v^2 + 4*FeynCalc`CA^2*
           Global`v^2 - 34*FeynCalc`CA^4*Global`v^2 + 32*FeynCalc`CA^4*
           Global`v*Global`w - Global`v^2*Global`w - 4*FeynCalc`CA^2*
           Global`v^2*Global`w + 5*FeynCalc`CA^4*Global`v^2*Global`w + 
          4*Global`v^3*Global`w - 8*FeynCalc`CA^2*Global`v^3*Global`w + 
          52*FeynCalc`CA^4*Global`v^3*Global`w - 16*FeynCalc`CA^4*Global`v^2*
           Global`w^2 + 8*FeynCalc`CA^2*Global`v^3*Global`w^2 - 
          40*FeynCalc`CA^4*Global`v^3*Global`w^2 - 4*Global`v^4*Global`w^2 + 
          28*FeynCalc`CA^2*Global`v^4*Global`w^2 - 40*FeynCalc`CA^4*
           Global`v^4*Global`w^2 + 2*Global`v^4*Global`w^3 - 
          22*FeynCalc`CA^2*Global`v^4*Global`w^3 + 36*FeynCalc`CA^4*
           Global`v^4*Global`w^3 - 20*FeynCalc`CA^2*Global`v^5*Global`w^3 + 
          20*FeynCalc`CA^4*Global`v^5*Global`w^3 + 12*FeynCalc`CA^2*
           Global`v^5*Global`w^4 - 12*FeynCalc`CA^4*Global`v^5*Global`w^4 + 
          8*FeynCalc`CA^2*Global`v^6*Global`w^4 - 8*FeynCalc`CA^4*Global`v^6*
           Global`w^4 - 4*FeynCalc`CA^2*Global`v^6*Global`w^5 + 
          4*FeynCalc`CA^4*Global`v^6*Global`w^5)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muFB2])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2*Global`w*(-1 + Global`v*Global`w)^2) + 
       ((4*FeynCalc`CA^2 - 68*FeynCalc`CA^4 - 18*FeynCalc`CA^2*Global`v + 
          306*FeynCalc`CA^4*Global`v - 4*Global`v^2 + 40*FeynCalc`CA^2*
           Global`v^2 - 660*FeynCalc`CA^4*Global`v^2 + 12*Global`v^3 - 
          52*FeynCalc`CA^2*Global`v^3 + 888*FeynCalc`CA^4*Global`v^3 - 
          12*Global`v^4 + 36*FeynCalc`CA^2*Global`v^4 - 776*FeynCalc`CA^4*
           Global`v^4 + 4*Global`v^5 - 10*FeynCalc`CA^2*Global`v^5 + 
          438*FeynCalc`CA^4*Global`v^5 - 160*FeynCalc`CA^4*Global`v^6 + 
          32*FeynCalc`CA^4*Global`v^7 - 4*FeynCalc`CA^2*Global`w + 
          20*FeynCalc`CA^4*Global`w + 22*FeynCalc`CA^2*Global`v*Global`w - 
          158*FeynCalc`CA^4*Global`v*Global`w + 4*Global`v^2*Global`w - 
          58*FeynCalc`CA^2*Global`v^2*Global`w + 366*FeynCalc`CA^4*Global`v^2*
           Global`w - 14*Global`v^3*Global`w + 88*FeynCalc`CA^2*Global`v^3*
           Global`w - 450*FeynCalc`CA^4*Global`v^3*Global`w + 
          8*Global`v^4*Global`w - 52*FeynCalc`CA^2*Global`v^4*Global`w + 
          204*FeynCalc`CA^4*Global`v^4*Global`w + 10*Global`v^5*Global`w - 
          14*FeynCalc`CA^2*Global`v^5*Global`w + 212*FeynCalc`CA^4*Global`v^5*
           Global`w - 8*Global`v^6*Global`w + 18*FeynCalc`CA^2*Global`v^6*
           Global`w - 322*FeynCalc`CA^4*Global`v^6*Global`w + 
          192*FeynCalc`CA^4*Global`v^7*Global`w - 64*FeynCalc`CA^4*Global`v^8*
           Global`w - 4*FeynCalc`CA^2*Global`v*Global`w^2 + 
          20*FeynCalc`CA^4*Global`v*Global`w^2 - 2*FeynCalc`CA^2*Global`v^2*
           Global`w^2 + 106*FeynCalc`CA^4*Global`v^2*Global`w^2 + 
          4*Global`v^3*Global`w^2 + 26*FeynCalc`CA^2*Global`v^3*Global`w^2 - 
          558*FeynCalc`CA^4*Global`v^3*Global`w^2 + 6*Global`v^4*Global`w^2 - 
          52*FeynCalc`CA^2*Global`v^4*Global`w^2 + 1078*FeynCalc`CA^4*
           Global`v^4*Global`w^2 - 24*Global`v^5*Global`w^2 + 
          48*FeynCalc`CA^2*Global`v^5*Global`w^2 - 1368*FeynCalc`CA^4*
           Global`v^5*Global`w^2 + 8*Global`v^6*Global`w^2 + 
          22*FeynCalc`CA^2*Global`v^6*Global`w^2 + 1018*FeynCalc`CA^4*
           Global`v^6*Global`w^2 + 6*Global`v^7*Global`w^2 - 
          38*FeynCalc`CA^2*Global`v^7*Global`w^2 - 424*FeynCalc`CA^4*
           Global`v^7*Global`w^2 + 96*FeynCalc`CA^4*Global`v^8*Global`w^2 + 
          32*FeynCalc`CA^4*Global`v^9*Global`w^2 + 8*FeynCalc`CA^2*Global`v^2*
           Global`w^3 - 40*FeynCalc`CA^4*Global`v^2*Global`w^3 - 
          44*FeynCalc`CA^2*Global`v^3*Global`w^3 + 316*FeynCalc`CA^4*
           Global`v^3*Global`w^3 - 6*Global`v^4*Global`w^3 + 
          60*FeynCalc`CA^2*Global`v^4*Global`w^3 - 582*FeynCalc`CA^4*
           Global`v^4*Global`w^3 + 9*Global`v^5*Global`w^3 + 
          4*FeynCalc`CA^2*Global`v^5*Global`w^3 + 675*FeynCalc`CA^4*
           Global`v^5*Global`w^3 + 14*Global`v^6*Global`w^3 - 
          110*FeynCalc`CA^2*Global`v^6*Global`w^3 - 400*FeynCalc`CA^4*
           Global`v^6*Global`w^3 - 19*Global`v^7*Global`w^3 + 
          64*FeynCalc`CA^2*Global`v^7*Global`w^3 - 21*FeynCalc`CA^4*
           Global`v^7*Global`w^3 + 34*FeynCalc`CA^2*Global`v^8*Global`w^3 + 
          102*FeynCalc`CA^4*Global`v^8*Global`w^3 - 128*FeynCalc`CA^4*
           Global`v^9*Global`w^3 + 8*FeynCalc`CA^2*Global`v^3*Global`w^4 - 
          40*FeynCalc`CA^4*Global`v^3*Global`w^4 - 8*FeynCalc`CA^2*Global`v^4*
           Global`w^4 - 8*FeynCalc`CA^4*Global`v^4*Global`w^4 + 
          4*Global`v^5*Global`w^4 - 42*FeynCalc`CA^2*Global`v^5*Global`w^4 + 
          206*FeynCalc`CA^4*Global`v^5*Global`w^4 - 21*Global`v^6*
           Global`w^4 + 112*FeynCalc`CA^2*Global`v^6*Global`w^4 - 
          363*FeynCalc`CA^4*Global`v^6*Global`w^4 + 24*Global`v^7*
           Global`w^4 - 32*FeynCalc`CA^2*Global`v^7*Global`w^4 + 
          496*FeynCalc`CA^4*Global`v^7*Global`w^4 - Global`v^8*Global`w^4 - 
          80*FeynCalc`CA^2*Global`v^8*Global`w^4 - 295*FeynCalc`CA^4*
           Global`v^8*Global`w^4 - 16*FeynCalc`CA^2*Global`v^9*Global`w^4 + 
          216*FeynCalc`CA^4*Global`v^9*Global`w^4 - 4*FeynCalc`CA^2*
           Global`v^4*Global`w^5 + 20*FeynCalc`CA^4*Global`v^4*Global`w^5 + 
          22*FeynCalc`CA^2*Global`v^5*Global`w^5 - 158*FeynCalc`CA^4*
           Global`v^5*Global`w^5 + 6*Global`v^6*Global`w^5 - 
          46*FeynCalc`CA^2*Global`v^6*Global`w^5 + 248*FeynCalc`CA^4*
           Global`v^6*Global`w^5 - 15*Global`v^7*Global`w^5 + 
          12*FeynCalc`CA^2*Global`v^7*Global`w^5 - 349*FeynCalc`CA^4*
           Global`v^7*Global`w^5 + 2*Global`v^8*Global`w^5 + 
          54*FeynCalc`CA^2*Global`v^8*Global`w^5 + 232*FeynCalc`CA^4*
           Global`v^8*Global`w^5 + 56*FeynCalc`CA^2*Global`v^9*Global`w^5 - 
          208*FeynCalc`CA^4*Global`v^9*Global`w^5 - 4*FeynCalc`CA^2*
           Global`v^5*Global`w^6 + 20*FeynCalc`CA^4*Global`v^5*Global`w^6 + 
          6*FeynCalc`CA^2*Global`v^6*Global`w^6 - 30*FeynCalc`CA^4*Global`v^6*
           Global`w^6 + 4*Global`v^7*Global`w^6 - 6*FeynCalc`CA^2*Global`v^7*
           Global`w^6 + 74*FeynCalc`CA^4*Global`v^7*Global`w^6 - 
          Global`v^8*Global`w^6 - 4*FeynCalc`CA^2*Global`v^8*Global`w^6 - 
          83*FeynCalc`CA^4*Global`v^8*Global`w^6 - 72*FeynCalc`CA^2*
           Global`v^9*Global`w^6 + 128*FeynCalc`CA^4*Global`v^9*Global`w^6 - 
          4*FeynCalc`CA^2*Global`v^8*Global`w^7 + 12*FeynCalc`CA^4*Global`v^8*
           Global`w^7 + 40*FeynCalc`CA^2*Global`v^9*Global`w^7 - 
          48*FeynCalc`CA^4*Global`v^9*Global`w^7 - 8*FeynCalc`CA^2*Global`v^9*
           Global`w^8 + 8*FeynCalc`CA^4*Global`v^9*Global`w^8)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(8*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*Global`w*
         (-1 + Global`v*Global`w)^2*(1 - Global`v + Global`v*Global`w)^3) + 
       ((-FeynCalc`CA^2 - 6*FeynCalc`CA^4 + Global`v + 2*FeynCalc`CA^2*
           Global`v - 4*FeynCalc`CA^4*Global`v - 3*Global`v^2 + 
          3*FeynCalc`CA^4*Global`v^2 + 3*Global`v^3 - 2*FeynCalc`CA^2*
           Global`v^3 - Global`v^4 + FeynCalc`CA^2*Global`v^4 + 
          7*FeynCalc`CA^4*Global`v^4 - 8*FeynCalc`CA^4*Global`w + 
          2*FeynCalc`CA^2*Global`v*Global`w + 47*FeynCalc`CA^4*Global`v*
           Global`w - 6*FeynCalc`CA^2*Global`v^2*Global`w - 
          47*FeynCalc`CA^4*Global`v^2*Global`w + Global`v^3*Global`w + 
          4*FeynCalc`CA^2*Global`v^3*Global`w + 4*FeynCalc`CA^4*Global`v^3*
           Global`w - 2*Global`v^4*Global`w + FeynCalc`CA^2*Global`v^4*
           Global`w - 19*FeynCalc`CA^4*Global`v^4*Global`w + 
          Global`v^5*Global`w + FeynCalc`CA^2*Global`v^5*Global`w - 
          11*FeynCalc`CA^4*Global`v^5*Global`w - 6*FeynCalc`CA^4*Global`v*
           Global`w^2 + 9*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          3*FeynCalc`CA^4*Global`v^2*Global`w^2 - 2*Global`v^3*Global`w^2 - 
          8*FeynCalc`CA^2*Global`v^3*Global`w^2 + 57*FeynCalc`CA^4*Global`v^3*
           Global`w^2 + 3*Global`v^4*Global`w^2 + 5*FeynCalc`CA^2*Global`v^4*
           Global`w^2 + 8*FeynCalc`CA^4*Global`v^4*Global`w^2 - 
          Global`v^5*Global`w^2 - 17*FeynCalc`CA^2*Global`v^5*Global`w^2 + 
          27*FeynCalc`CA^4*Global`v^5*Global`w^2 + 8*FeynCalc`CA^4*Global`v^6*
           Global`w^2 + 8*FeynCalc`CA^4*Global`v^2*Global`w^3 - 
          4*FeynCalc`CA^2*Global`v^3*Global`w^3 - 47*FeynCalc`CA^4*Global`v^3*
           Global`w^3 + FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          15*FeynCalc`CA^4*Global`v^4*Global`w^3 - Global`v^5*Global`w^3 + 
          27*FeynCalc`CA^2*Global`v^5*Global`w^3 - 13*FeynCalc`CA^4*
           Global`v^5*Global`w^3 + 8*FeynCalc`CA^2*Global`v^6*Global`w^3 - 
          28*FeynCalc`CA^4*Global`v^6*Global`w^3 + 6*FeynCalc`CA^4*Global`v^3*
           Global`w^4 - 4*FeynCalc`CA^2*Global`v^4*Global`w^4 + 
          15*FeynCalc`CA^4*Global`v^4*Global`w^4 + Global`v^5*Global`w^4 - 
          13*FeynCalc`CA^2*Global`v^5*Global`w^4 - 5*FeynCalc`CA^4*Global`v^5*
           Global`w^4 - 20*FeynCalc`CA^2*Global`v^6*Global`w^4 + 
          36*FeynCalc`CA^4*Global`v^6*Global`w^4 + 2*FeynCalc`CA^2*Global`v^5*
           Global`w^5 + 2*FeynCalc`CA^4*Global`v^5*Global`w^5 + 
          16*FeynCalc`CA^2*Global`v^6*Global`w^5 - 20*FeynCalc`CA^4*
           Global`v^6*Global`w^5 - 4*FeynCalc`CA^2*Global`v^6*Global`w^6 + 
          4*FeynCalc`CA^4*Global`v^6*Global`w^6)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2*(-1 + Global`w)*Global`w*
         (-1 + Global`v*Global`w)*(1 - Global`v + Global`v*Global`w)) + 
       ((4*FeynCalc`CA^2 - 100*FeynCalc`CA^4 - 18*FeynCalc`CA^2*Global`v + 
          450*FeynCalc`CA^4*Global`v - 4*Global`v^2 + 40*FeynCalc`CA^2*
           Global`v^2 - 948*FeynCalc`CA^4*Global`v^2 + 8*Global`v^3 - 
          48*FeynCalc`CA^2*Global`v^3 + 1224*FeynCalc`CA^4*Global`v^3 + 
          24*FeynCalc`CA^2*Global`v^4 - 1016*FeynCalc`CA^4*Global`v^4 - 
          8*Global`v^5 + 2*FeynCalc`CA^2*Global`v^5 + 534*FeynCalc`CA^4*
           Global`v^5 + 4*Global`v^6 - 4*FeynCalc`CA^2*Global`v^6 - 
          176*FeynCalc`CA^4*Global`v^6 + 32*FeynCalc`CA^4*Global`v^7 - 
          4*FeynCalc`CA^2*Global`w + 20*FeynCalc`CA^4*Global`w + 
          22*FeynCalc`CA^2*Global`v*Global`w - 190*FeynCalc`CA^4*Global`v*
           Global`w + 4*Global`v^2*Global`w - 58*FeynCalc`CA^2*Global`v^2*
           Global`w + 462*FeynCalc`CA^4*Global`v^2*Global`w - 
          6*Global`v^3*Global`w + 80*FeynCalc`CA^2*Global`v^3*Global`w - 
          570*FeynCalc`CA^4*Global`v^3*Global`w - 20*Global`v^4*Global`w - 
          24*FeynCalc`CA^2*Global`v^4*Global`w + 244*FeynCalc`CA^4*Global`v^4*
           Global`w + 34*Global`v^5*Global`w - 42*FeynCalc`CA^2*Global`v^5*
           Global`w + 292*FeynCalc`CA^4*Global`v^5*Global`w - 
          4*Global`v^6*Global`w + 22*FeynCalc`CA^2*Global`v^6*Global`w - 
          410*FeynCalc`CA^4*Global`v^6*Global`w - 8*Global`v^7*Global`w + 
          4*FeynCalc`CA^2*Global`v^7*Global`w + 216*FeynCalc`CA^4*Global`v^7*
           Global`w - 64*FeynCalc`CA^4*Global`v^8*Global`w - 
          4*FeynCalc`CA^2*Global`v*Global`w^2 + 20*FeynCalc`CA^4*Global`v*
           Global`w^2 - 2*FeynCalc`CA^2*Global`v^2*Global`w^2 + 
          170*FeynCalc`CA^4*Global`v^2*Global`w^2 + 4*Global`v^3*Global`w^2 + 
          26*FeynCalc`CA^2*Global`v^3*Global`w^2 - 798*FeynCalc`CA^4*
           Global`v^3*Global`w^2 + 14*Global`v^4*Global`w^2 - 
          60*FeynCalc`CA^2*Global`v^4*Global`w^2 + 1478*FeynCalc`CA^4*
           Global`v^4*Global`w^2 - 16*Global`v^5*Global`w^2 + 
          56*FeynCalc`CA^2*Global`v^5*Global`w^2 - 1788*FeynCalc`CA^4*
           Global`v^5*Global`w^2 - 40*Global`v^6*Global`w^2 + 
          34*FeynCalc`CA^2*Global`v^6*Global`w^2 + 1258*FeynCalc`CA^4*
           Global`v^6*Global`w^2 + 34*Global`v^7*Global`w^2 - 
          50*FeynCalc`CA^2*Global`v^7*Global`w^2 - 460*FeynCalc`CA^4*
           Global`v^7*Global`w^2 + 4*Global`v^8*Global`w^2 + 
          88*FeynCalc`CA^4*Global`v^8*Global`w^2 + 32*FeynCalc`CA^4*
           Global`v^9*Global`w^2 + 8*FeynCalc`CA^2*Global`v^2*Global`w^3 - 
          40*FeynCalc`CA^4*Global`v^2*Global`w^3 - 44*FeynCalc`CA^2*
           Global`v^3*Global`w^3 + 380*FeynCalc`CA^4*Global`v^3*Global`w^3 - 
          6*Global`v^4*Global`w^3 + 60*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          726*FeynCalc`CA^4*Global`v^4*Global`w^3 - 7*Global`v^5*Global`w^3 + 
          4*FeynCalc`CA^2*Global`v^5*Global`w^3 + 835*FeynCalc`CA^4*
           Global`v^5*Global`w^3 + 70*Global`v^6*Global`w^3 - 
          118*FeynCalc`CA^2*Global`v^6*Global`w^3 - 468*FeynCalc`CA^4*
           Global`v^6*Global`w^3 - 43*Global`v^7*Global`w^3 + 
          76*FeynCalc`CA^2*Global`v^7*Global`w^3 - 69*FeynCalc`CA^4*
           Global`v^7*Global`w^3 - 20*Global`v^8*Global`w^3 + 
          30*FeynCalc`CA^2*Global`v^8*Global`w^3 + 130*FeynCalc`CA^4*
           Global`v^8*Global`w^3 - 128*FeynCalc`CA^4*Global`v^9*Global`w^3 + 
          8*FeynCalc`CA^2*Global`v^3*Global`w^4 - 40*FeynCalc`CA^4*Global`v^3*
           Global`w^4 - 8*FeynCalc`CA^2*Global`v^4*Global`w^4 - 
          40*FeynCalc`CA^4*Global`v^4*Global`w^4 + 4*Global`v^5*Global`w^4 - 
          42*FeynCalc`CA^2*Global`v^5*Global`w^4 + 302*FeynCalc`CA^4*
           Global`v^5*Global`w^4 - 37*Global`v^6*Global`w^4 + 
          112*FeynCalc`CA^2*Global`v^6*Global`w^4 - 475*FeynCalc`CA^4*
           Global`v^6*Global`w^4 + 20*Global`v^7*Global`w^4 - 
          44*FeynCalc`CA^2*Global`v^7*Global`w^4 + 596*FeynCalc`CA^4*
           Global`v^7*Global`w^4 + 35*Global`v^8*Global`w^4 - 
          64*FeynCalc`CA^2*Global`v^8*Global`w^4 - 327*FeynCalc`CA^4*
           Global`v^8*Global`w^4 - 16*FeynCalc`CA^2*Global`v^9*Global`w^4 + 
          216*FeynCalc`CA^4*Global`v^9*Global`w^4 - 4*FeynCalc`CA^2*
           Global`v^4*Global`w^5 + 20*FeynCalc`CA^4*Global`v^4*Global`w^5 + 
          22*FeynCalc`CA^2*Global`v^5*Global`w^5 - 190*FeynCalc`CA^4*
           Global`v^5*Global`w^5 + 6*Global`v^6*Global`w^5 - 
          46*FeynCalc`CA^2*Global`v^6*Global`w^5 + 296*FeynCalc`CA^4*
           Global`v^6*Global`w^5 - 7*Global`v^7*Global`w^5 + 
          20*FeynCalc`CA^2*Global`v^7*Global`w^5 - 389*FeynCalc`CA^4*
           Global`v^7*Global`w^5 - 26*Global`v^8*Global`w^5 + 
          34*FeynCalc`CA^2*Global`v^8*Global`w^5 + 244*FeynCalc`CA^4*
           Global`v^8*Global`w^5 + 56*FeynCalc`CA^2*Global`v^9*Global`w^5 - 
          208*FeynCalc`CA^4*Global`v^9*Global`w^5 - 4*FeynCalc`CA^2*
           Global`v^5*Global`w^6 + 20*FeynCalc`CA^4*Global`v^5*Global`w^6 + 
          6*FeynCalc`CA^2*Global`v^6*Global`w^6 - 30*FeynCalc`CA^4*Global`v^6*
           Global`w^6 + 4*Global`v^7*Global`w^6 - 6*FeynCalc`CA^2*Global`v^7*
           Global`w^6 + 74*FeynCalc`CA^4*Global`v^7*Global`w^6 + 
          7*Global`v^8*Global`w^6 + 4*FeynCalc`CA^2*Global`v^8*Global`w^6 - 
          83*FeynCalc`CA^4*Global`v^8*Global`w^6 - 72*FeynCalc`CA^2*
           Global`v^9*Global`w^6 + 128*FeynCalc`CA^4*Global`v^9*Global`w^6 - 
          4*FeynCalc`CA^2*Global`v^8*Global`w^7 + 12*FeynCalc`CA^4*Global`v^8*
           Global`w^7 + 40*FeynCalc`CA^2*Global`v^9*Global`w^7 - 
          48*FeynCalc`CA^4*Global`v^9*Global`w^7 - 8*FeynCalc`CA^2*Global`v^9*
           Global`w^8 + 8*FeynCalc`CA^4*Global`v^9*Global`w^8)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`v])/(8*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*Global`w*
         (-1 + Global`v*Global`w)^2*(1 - Global`v + Global`v*Global`w)^3) + 
       ((4*FeynCalc`CA^2 - 96*FeynCalc`CA^4 - 18*FeynCalc`CA^2*Global`v + 
          432*FeynCalc`CA^4*Global`v - 4*Global`v^2 + 40*FeynCalc`CA^2*
           Global`v^2 - 912*FeynCalc`CA^4*Global`v^2 + 10*Global`v^3 - 
          50*FeynCalc`CA^2*Global`v^3 + 1182*FeynCalc`CA^4*Global`v^3 - 
          6*Global`v^4 + 30*FeynCalc`CA^2*Global`v^4 - 986*FeynCalc`CA^4*
           Global`v^4 - 2*Global`v^5 - 4*FeynCalc`CA^2*Global`v^5 + 
          522*FeynCalc`CA^4*Global`v^5 + 2*Global`v^6 - 2*FeynCalc`CA^2*
           Global`v^6 - 174*FeynCalc`CA^4*Global`v^6 + 32*FeynCalc`CA^4*
           Global`v^7 - 4*FeynCalc`CA^2*Global`w + 20*FeynCalc`CA^4*
           Global`w + 22*FeynCalc`CA^2*Global`v*Global`w - 
          186*FeynCalc`CA^4*Global`v*Global`w + 4*Global`v^2*Global`w - 
          66*FeynCalc`CA^2*Global`v^2*Global`w + 424*FeynCalc`CA^4*Global`v^2*
           Global`w - 10*Global`v^3*Global`w + 112*FeynCalc`CA^2*Global`v^3*
           Global`w - 456*FeynCalc`CA^4*Global`v^3*Global`w - 
          6*Global`v^4*Global`w - 70*FeynCalc`CA^2*Global`v^4*Global`w + 
          76*FeynCalc`CA^4*Global`v^4*Global`w + 22*Global`v^5*Global`w - 
          18*FeynCalc`CA^2*Global`v^5*Global`w + 430*FeynCalc`CA^4*Global`v^5*
           Global`w - 6*Global`v^6*Global`w + 24*FeynCalc`CA^2*Global`v^6*
           Global`w - 472*FeynCalc`CA^4*Global`v^6*Global`w - 
          4*Global`v^7*Global`w + 228*FeynCalc`CA^4*Global`v^7*Global`w - 
          64*FeynCalc`CA^4*Global`v^8*Global`w - 4*FeynCalc`CA^2*Global`v*
           Global`w^2 + 20*FeynCalc`CA^4*Global`v*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v^2*Global`w^2 + 170*FeynCalc`CA^4*
           Global`v^2*Global`w^2 + 4*Global`v^3*Global`w^2 + 
          18*FeynCalc`CA^2*Global`v^3*Global`w^2 - 826*FeynCalc`CA^4*
           Global`v^3*Global`w^2 + 10*Global`v^4*Global`w^2 - 
          60*FeynCalc`CA^2*Global`v^4*Global`w^2 + 1526*FeynCalc`CA^4*
           Global`v^4*Global`w^2 - 20*Global`v^5*Global`w^2 + 
          100*FeynCalc`CA^2*Global`v^5*Global`w^2 - 1778*FeynCalc`CA^4*
           Global`v^5*Global`w^2 - 16*Global`v^6*Global`w^2 - 
          18*FeynCalc`CA^2*Global`v^6*Global`w^2 + 1166*FeynCalc`CA^4*
           Global`v^6*Global`w^2 + 20*Global`v^7*Global`w^2 - 
          36*FeynCalc`CA^2*Global`v^7*Global`w^2 - 368*FeynCalc`CA^4*
           Global`v^7*Global`w^2 + 2*Global`v^8*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v^8*Global`w^2 + 58*FeynCalc`CA^4*Global`v^8*
           Global`w^2 + 32*FeynCalc`CA^4*Global`v^9*Global`w^2 + 
          8*FeynCalc`CA^2*Global`v^2*Global`w^3 - 40*FeynCalc`CA^4*Global`v^2*
           Global`w^3 - 44*FeynCalc`CA^2*Global`v^3*Global`w^3 + 
          380*FeynCalc`CA^4*Global`v^3*Global`w^3 - 6*Global`v^4*Global`w^3 + 
          76*FeynCalc`CA^2*Global`v^4*Global`w^3 - 682*FeynCalc`CA^4*
           Global`v^4*Global`w^3 + Global`v^5*Global`w^3 - 
          60*FeynCalc`CA^2*Global`v^5*Global`w^3 + 663*FeynCalc`CA^4*
           Global`v^5*Global`w^3 + 42*Global`v^6*Global`w^3 - 
          66*FeynCalc`CA^2*Global`v^6*Global`w^3 - 206*FeynCalc`CA^4*
           Global`v^6*Global`w^3 - 31*Global`v^7*Global`w^3 + 
          84*FeynCalc`CA^2*Global`v^7*Global`w^3 - 263*FeynCalc`CA^4*
           Global`v^7*Global`w^3 - 10*Global`v^8*Global`w^3 + 
          20*FeynCalc`CA^2*Global`v^8*Global`w^3 + 168*FeynCalc`CA^4*
           Global`v^8*Global`w^3 - 112*FeynCalc`CA^4*Global`v^9*Global`w^3 + 
          8*FeynCalc`CA^2*Global`v^3*Global`w^4 - 40*FeynCalc`CA^4*Global`v^3*
           Global`w^4 - 8*FeynCalc`CA^2*Global`v^4*Global`w^4 - 
          52*FeynCalc`CA^4*Global`v^4*Global`w^4 + 4*Global`v^5*Global`w^4 - 
          26*FeynCalc`CA^2*Global`v^5*Global`w^4 + 388*FeynCalc`CA^4*
           Global`v^5*Global`w^4 - 29*Global`v^6*Global`w^4 + 
          112*FeynCalc`CA^2*Global`v^6*Global`w^4 - 607*FeynCalc`CA^4*
           Global`v^6*Global`w^4 + 22*Global`v^7*Global`w^4 - 
          86*FeynCalc`CA^2*Global`v^7*Global`w^4 + 668*FeynCalc`CA^4*
           Global`v^7*Global`w^4 + 17*Global`v^8*Global`w^4 - 
          50*FeynCalc`CA^2*Global`v^8*Global`w^4 - 281*FeynCalc`CA^4*
           Global`v^8*Global`w^4 - 16*FeynCalc`CA^2*Global`v^9*Global`w^4 + 
          160*FeynCalc`CA^4*Global`v^9*Global`w^4 - 4*FeynCalc`CA^2*
           Global`v^4*Global`w^5 + 20*FeynCalc`CA^4*Global`v^4*Global`w^5 + 
          22*FeynCalc`CA^2*Global`v^5*Global`w^5 - 202*FeynCalc`CA^4*
           Global`v^5*Global`w^5 + 6*Global`v^6*Global`w^5 - 
          54*FeynCalc`CA^2*Global`v^6*Global`w^5 + 298*FeynCalc`CA^4*
           Global`v^6*Global`w^5 - 11*Global`v^7*Global`w^5 + 
          52*FeynCalc`CA^2*Global`v^7*Global`w^5 - 339*FeynCalc`CA^4*
           Global`v^7*Global`w^5 - 12*Global`v^8*Global`w^5 + 
          28*FeynCalc`CA^2*Global`v^8*Global`w^5 + 150*FeynCalc`CA^4*
           Global`v^8*Global`w^5 + 56*FeynCalc`CA^2*Global`v^9*Global`w^5 - 
          136*FeynCalc`CA^4*Global`v^9*Global`w^5 - 4*FeynCalc`CA^2*
           Global`v^5*Global`w^6 + 20*FeynCalc`CA^4*Global`v^5*Global`w^6 + 
          6*FeynCalc`CA^2*Global`v^6*Global`w^6 - 22*FeynCalc`CA^4*Global`v^6*
           Global`w^6 + 4*Global`v^7*Global`w^6 - 14*FeynCalc`CA^2*Global`v^7*
           Global`w^6 + 34*FeynCalc`CA^4*Global`v^7*Global`w^6 + 
          3*Global`v^8*Global`w^6 + 4*FeynCalc`CA^2*Global`v^8*Global`w^6 - 
          35*FeynCalc`CA^4*Global`v^8*Global`w^6 - 72*FeynCalc`CA^2*
           Global`v^9*Global`w^6 + 88*FeynCalc`CA^4*Global`v^9*Global`w^6 + 
          8*FeynCalc`CA^4*Global`v^7*Global`w^7 - 4*FeynCalc`CA^2*Global`v^8*
           Global`w^7 + 4*FeynCalc`CA^4*Global`v^8*Global`w^7 + 
          40*FeynCalc`CA^2*Global`v^9*Global`w^7 - 40*FeynCalc`CA^4*
           Global`v^9*Global`w^7 - 8*FeynCalc`CA^2*Global`v^9*Global`w^8 + 
          8*FeynCalc`CA^4*Global`v^9*Global`w^8)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`w])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v^2*Global`w*(-1 + Global`v*Global`w)^2*
         (1 - Global`v + Global`v*Global`w)^3) - 
       ((2*FeynCalc`CA^2 + 14*FeynCalc`CA^4 - 5*FeynCalc`CA^2*Global`v - 
          35*FeynCalc`CA^4*Global`v + 2*Global`v^2 + 2*FeynCalc`CA^2*
           Global`v^2 + 76*FeynCalc`CA^4*Global`v^2 - 2*Global`v^3 + 
          FeynCalc`CA^2*Global`v^3 - 87*FeynCalc`CA^4*Global`v^3 + 
          48*FeynCalc`CA^4*Global`v^4 - 16*FeynCalc`CA^4*Global`v^5 - 
          2*FeynCalc`CA^4*Global`w + 5*FeynCalc`CA^4*Global`v*Global`w + 
          8*FeynCalc`CA^2*Global`v^2*Global`w - 66*FeynCalc`CA^4*Global`v^2*
           Global`w - 3*Global`v^3*Global`w - 9*FeynCalc`CA^2*Global`v^3*
           Global`w + 110*FeynCalc`CA^4*Global`v^3*Global`w + 
          5*Global`v^4*Global`w + FeynCalc`CA^2*Global`v^4*Global`w - 
          35*FeynCalc`CA^4*Global`v^4*Global`w + 16*FeynCalc`CA^4*Global`v^6*
           Global`w - 6*FeynCalc`CA^2*Global`v^2*Global`w^2 + 
          22*FeynCalc`CA^4*Global`v^2*Global`w^2 + 2*Global`v^3*Global`w^2 + 
          7*FeynCalc`CA^2*Global`v^3*Global`w^2 - 43*FeynCalc`CA^4*Global`v^3*
           Global`w^2 - 4*Global`v^4*Global`w^2 + FeynCalc`CA^2*Global`v^4*
           Global`w^2 - 65*FeynCalc`CA^4*Global`v^4*Global`w^2 - 
          3*Global`v^5*Global`w^2 - 2*FeynCalc`CA^2*Global`v^5*Global`w^2 + 
          64*FeynCalc`CA^4*Global`v^5*Global`w^2 - 48*FeynCalc`CA^4*
           Global`v^6*Global`w^2 - 2*FeynCalc`CA^4*Global`v^2*Global`w^3 + 
          5*FeynCalc`CA^4*Global`v^3*Global`w^3 - 6*FeynCalc`CA^2*Global`v^4*
           Global`w^3 + 81*FeynCalc`CA^4*Global`v^4*Global`w^3 + 
          5*Global`v^5*Global`w^3 + 6*FeynCalc`CA^2*Global`v^5*Global`w^3 - 
          73*FeynCalc`CA^4*Global`v^5*Global`w^3 + 52*FeynCalc`CA^4*
           Global`v^6*Global`w^3 + 4*FeynCalc`CA^2*Global`v^4*Global`w^4 - 
          30*FeynCalc`CA^4*Global`v^4*Global`w^4 - 2*Global`v^5*Global`w^4 - 
          4*FeynCalc`CA^2*Global`v^5*Global`w^4 + 29*FeynCalc`CA^4*Global`v^5*
           Global`w^4 - 24*FeynCalc`CA^4*Global`v^6*Global`w^4 + 
          4*FeynCalc`CA^4*Global`v^4*Global`w^5 - 4*FeynCalc`CA^4*Global`v^5*
           Global`w^5 + 4*FeynCalc`CA^4*Global`v^6*Global`w^5)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`w])/(4*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*(-1 + Global`w)*
         Global`w*(-1 + Global`v*Global`w)*(1 - Global`v + 
          Global`v*Global`w)) - ((FeynCalc`CA^2 + 14*FeynCalc`CA^4 - 
          Global`v - FeynCalc`CA^2*Global`v - 11*FeynCalc`CA^4*Global`v + 
          2*Global`v^2 - FeynCalc`CA^2*Global`v^2 + 28*FeynCalc`CA^4*
           Global`v^2 - 2*FeynCalc`CA^2*Global`v*Global`w - 
          12*FeynCalc`CA^4*Global`v*Global`w + 3*FeynCalc`CA^2*Global`v^2*
           Global`w - 37*FeynCalc`CA^4*Global`v^2*Global`w - 
          3*Global`v^3*Global`w + 7*FeynCalc`CA^2*Global`v^3*Global`w - 
          9*FeynCalc`CA^4*Global`v^3*Global`w - 8*FeynCalc`CA^2*Global`v^2*
           Global`w^2 + 25*FeynCalc`CA^4*Global`v^2*Global`w^2 + 
          3*Global`v^3*Global`w^2 - 7*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          9*FeynCalc`CA^4*Global`v^3*Global`w^2 - 8*FeynCalc`CA^2*Global`v^4*
           Global`w^2 + 8*FeynCalc`CA^4*Global`v^4*Global`w^2 + 
          4*FeynCalc`CA^2*Global`v^3*Global`w^3 - 4*FeynCalc`CA^4*Global`v^3*
           Global`w^3 + 12*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          12*FeynCalc`CA^4*Global`v^4*Global`w^3 - 4*FeynCalc`CA^2*Global`v^4*
           Global`w^4 + 4*FeynCalc`CA^4*Global`v^4*Global`w^4)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v*Global`w])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*
         (-1 + Global`w)*Global`w) - ((FeynCalc`CA^2 - 2*FeynCalc`CA^4 - 
          3*FeynCalc`CA^2*Global`v + 6*FeynCalc`CA^4*Global`v + 
          3*FeynCalc`CA^2*Global`v^2 - 6*FeynCalc`CA^4*Global`v^2 - 
          3*FeynCalc`CA^2*Global`v^4 + 6*FeynCalc`CA^4*Global`v^4 + 
          3*FeynCalc`CA^2*Global`v^5 - 6*FeynCalc`CA^4*Global`v^5 - 
          FeynCalc`CA^2*Global`v^6 + 2*FeynCalc`CA^4*Global`v^6 + 
          Global`v*Global`w + 3*FeynCalc`CA^2*Global`v*Global`w - 
          FeynCalc`CA^4*Global`v*Global`w - 2*Global`v^2*Global`w - 
          7*FeynCalc`CA^2*Global`v^2*Global`w + 7*FeynCalc`CA^4*Global`v^2*
           Global`w + Global`v^3*Global`w + 8*FeynCalc`CA^2*Global`v^3*
           Global`w - 5*FeynCalc`CA^4*Global`v^3*Global`w + 
          Global`v^4*Global`w - 6*FeynCalc`CA^2*Global`v^4*Global`w - 
          7*FeynCalc`CA^4*Global`v^4*Global`w - 2*Global`v^5*Global`w + 
          FeynCalc`CA^2*Global`v^5*Global`w + 6*FeynCalc`CA^4*Global`v^5*
           Global`w + Global`v^6*Global`w + FeynCalc`CA^2*Global`v^6*
           Global`w + 2*Global`v^2*Global`w^2 + 3*FeynCalc`CA^2*Global`v^2*
           Global`w^2 - 5*FeynCalc`CA^4*Global`v^2*Global`w^2 - 
          3*Global`v^3*Global`w^2 - 3*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          6*FeynCalc`CA^4*Global`v^3*Global`w^2 + 2*Global`v^4*Global`w^2 + 
          11*FeynCalc`CA^2*Global`v^4*Global`w^2 + 3*FeynCalc`CA^4*Global`v^4*
           Global`w^2 + 3*Global`v^5*Global`w^2 - 11*FeynCalc`CA^2*Global`v^5*
           Global`w^2 + 10*FeynCalc`CA^4*Global`v^5*Global`w^2 - 
          4*Global`v^6*Global`w^2 - 14*FeynCalc`CA^4*Global`v^6*Global`w^2 + 
          Global`v^3*Global`w^3 - 5*FeynCalc`CA^2*Global`v^3*Global`w^3 - 
          5*Global`v^4*Global`w^3 + 2*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          5*FeynCalc`CA^4*Global`v^4*Global`w^3 + 9*FeynCalc`CA^2*Global`v^5*
           Global`w^3 - 15*FeynCalc`CA^4*Global`v^5*Global`w^3 + 
          6*Global`v^6*Global`w^3 + 4*FeynCalc`CA^2*Global`v^6*Global`w^3 + 
          22*FeynCalc`CA^4*Global`v^6*Global`w^3 + 2*Global`v^4*Global`w^4 - 
          4*FeynCalc`CA^2*Global`v^4*Global`w^4 + 3*FeynCalc`CA^4*Global`v^4*
           Global`w^4 - Global`v^5*Global`w^4 - 4*FeynCalc`CA^2*Global`v^5*
           Global`w^4 + 6*FeynCalc`CA^4*Global`v^5*Global`w^4 - 
          4*Global`v^6*Global`w^4 - 7*FeynCalc`CA^2*Global`v^6*Global`w^4 - 
          12*FeynCalc`CA^4*Global`v^6*Global`w^4 + 2*FeynCalc`CA^2*Global`v^5*
           Global`w^5 - FeynCalc`CA^4*Global`v^5*Global`w^5 + 
          Global`v^6*Global`w^5 + 3*FeynCalc`CA^2*Global`v^6*Global`w^5 + 
          2*FeynCalc`CA^4*Global`v^6*Global`w^5)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v + Global`v*Global`w])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*
         (-1 + Global`w)*Global`w*(1 - Global`v + Global`v*Global`w)^3)|>|>, 
 "DensityConvention" -> "E_c d sigma/d^(D-1)p_c", 
 "DistributionBasis" -> <|"Variable" -> Global`w, "Endpoint" -> 1, 
   "Interval" -> {0, 1}, "Distance" -> 1 - Global`w|>, 
 "PlusConvention" -> "At each axis, PlusCoefficients[k] multiplies \
[Log[Distance]^k/Distance]_+ on Interval, with subtraction at Endpoint. For \
DistributionBasis[Axes], delta/plus/regular values repeat recursively in the \
listed axis order."|>
