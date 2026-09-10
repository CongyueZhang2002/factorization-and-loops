<|"Project" -> "ppHX_UU_NNLO", "Channel" -> "qqbar-qpqpbar", 
 "Scale" -> Global`s, "Variables" -> {Global`v, Global`w}, 
 "Coupling" -> FeynFacet`\[Alpha]s, "CouplingPower" -> 3, 
 "DimensionalPrefactor" -> Global`muR2^(2*Global`Epsilon), 
 "PhysicalChannel" -> <|"Incoming" -> {{"q", "u"}, {"qbar", "u"}}, 
   "Observed" -> {"q", "d"}, "Recoil" -> {"qbar", "d"}|>, 
 "Polarization" -> <|"Incoming" -> {"U", "U"}, "Observed" -> "U"|>, 
 "Order" -> "NLO", "Contribution" -> "Total", 
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
      -1/144*((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
          (-225 - 115*FeynCalc`CA^2 + 40*FeynCalc`CA*Global`nD + 
           40*FeynCalc`CA*Global`nU + 30*System`Pi^2 + 6*FeynCalc`CA^2*
            System`Pi^2)*(1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^
           3)/(FeynCalc`CA^3*System`Pi*Global`s^2*Global`v) - 
       (3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 - 2*Global`v + 
          2*Global`v^2)*FeynFacet`\[Alpha]s^3*System`Log[Global`muFA2])/
        (16*FeynCalc`CA^3*System`Pi*Global`s^2*Global`v) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(11*FeynCalc`CA - 2*Global`nD - 
          2*Global`nU)*(1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muR2])/(12*FeynCalc`CA^2*System`Pi*Global`s^2*
         Global`v) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (27 + 17*FeynCalc`CA^2 - 8*FeynCalc`CA*Global`nD - 
          8*FeynCalc`CA*Global`nU)*(1 - 2*Global`v + 2*Global`v^2)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(48*FeynCalc`CA^3*
         System`Pi*Global`s^2*Global`v) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-3 + 2*FeynCalc`CA^2 + 
          6*Global`v - 4*FeynCalc`CA^2*Global`v - 2*Global`v^2 + 
          2*FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v]^2)/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         Global`v) + (-1/16*((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
            (-11 + 3*FeynCalc`CA^2 + 14*Global`v - 6*FeynCalc`CA^2*Global`v - 
             6*Global`v^2 + 6*FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^
             3)/(FeynCalc`CA^3*System`Pi*Global`s^2*Global`v) + 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 - 2*Global`v + 
            2*Global`v^2)*FeynFacet`\[Alpha]s^3*System`Log[Global`s])/
          (2*FeynCalc`CA^3*System`Pi*Global`s^2*Global`v))*
        System`Log[Global`v] + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (6 + FeynCalc`CA^2 - 12*Global`v - 2*FeynCalc`CA^2*Global`v + 
          14*Global`v^2 + 2*FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`v]^2)/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         Global`v) + System`Log[Global`muD2]*
        ((-3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 - 2*Global`v + 
            2*Global`v^2)*FeynFacet`\[Alpha]s^3)/(16*FeynCalc`CA^3*System`Pi*
           Global`s^2*Global`v) - ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           (1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           Global`v)) + System`Log[Global`muFB2]*
        ((-3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 - 2*Global`v + 
            2*Global`v^2)*FeynFacet`\[Alpha]s^3)/(16*FeynCalc`CA^3*System`Pi*
           Global`s^2*Global`v) + ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           (1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[1 - Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           Global`v) - ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           (1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           Global`v)) + System`Log[1 - Global`v]*
        (((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-2 + FeynCalc`CA^2)*
           FeynFacet`\[Alpha]s^3)/(4*FeynCalc`CA^3*System`Pi*Global`s^2) - 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 - 2*Global`v + 
            2*Global`v^2)*FeynFacet`\[Alpha]s^3*System`Log[Global`s])/
          (4*FeynCalc`CA^3*System`Pi*Global`s^2*Global`v) + 
         ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-7 + FeynCalc`CA^2)*
           (1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           Global`v)), "PlusCoefficients" -> 
      <|0 -> (-3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 - 2*Global`v + 
            2*Global`v^2)*FeynFacet`\[Alpha]s^3)/(16*FeynCalc`CA^3*System`Pi*
           Global`s^2*Global`v) - ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           (1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muD2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           Global`v) - ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           (1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFA2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           Global`v) - ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           (1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFB2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           Global`v) + (3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           (1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           Global`v) + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
           (-3 + FeynCalc`CA^2)*(1 - 2*Global`v + 2*Global`v^2)*
           FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v])/
          (2*FeynCalc`CA^3*System`Pi*Global`s^2*Global`v) + 
         ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(5 + 3*FeynCalc`CA^2)*
           (1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           Global`v), 1 -> (5*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
          (1 - 2*Global`v + 2*Global`v^2)*FeynFacet`\[Alpha]s^3)/
         (4*FeynCalc`CA^3*System`Pi*Global`s^2*Global`v)|>, 
     "RegularCoefficient" -> ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (-2 + 2*FeynCalc`CA^2 + 8*Global`v - 8*FeynCalc`CA^2*Global`v - 
          12*Global`v^2 + 12*FeynCalc`CA^2*Global`v^2 + 8*Global`v^3 - 
          8*FeynCalc`CA^2*Global`v^3 - 2*Global`v^4 + 2*FeynCalc`CA^2*
           Global`v^4 + 10*Global`w - 2*FeynCalc`CA^2*Global`w - 
          27*Global`v*Global`w + 3*FeynCalc`CA^2*Global`v*Global`w + 
          10*Global`v^2*Global`w + 14*FeynCalc`CA^2*Global`v^2*Global`w + 
          38*Global`v^3*Global`w - 38*FeynCalc`CA^2*Global`v^3*Global`w - 
          54*Global`v^4*Global`w + 30*FeynCalc`CA^2*Global`v^4*Global`w + 
          29*Global`v^5*Global`w - 5*FeynCalc`CA^2*Global`v^5*Global`w - 
          6*Global`v^6*Global`w - 2*FeynCalc`CA^2*Global`v^6*Global`w + 
          20*Global`v*Global`w^2 - 4*FeynCalc`CA^2*Global`v*Global`w^2 - 
          96*Global`v^2*Global`w^2 + 20*FeynCalc`CA^2*Global`v^2*Global`w^2 + 
          151*Global`v^3*Global`w^2 - 47*FeynCalc`CA^2*Global`v^3*
           Global`w^2 - 103*Global`v^4*Global`w^2 + 63*FeynCalc`CA^2*
           Global`v^4*Global`w^2 + 43*Global`v^5*Global`w^2 - 
          43*FeynCalc`CA^2*Global`v^5*Global`w^2 - 21*Global`v^6*Global`w^2 + 
          9*FeynCalc`CA^2*Global`v^6*Global`w^2 + 6*Global`v^7*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v^7*Global`w^2 + 2*Global`v^3*Global`w^3 + 
          18*FeynCalc`CA^2*Global`v^3*Global`w^3 - 13*Global`v^4*Global`w^3 - 
          31*FeynCalc`CA^2*Global`v^4*Global`w^3 - 16*Global`v^5*Global`w^3 + 
          20*FeynCalc`CA^2*Global`v^5*Global`w^3 + 39*Global`v^6*Global`w^3 - 
          3*FeynCalc`CA^2*Global`v^6*Global`w^3 - 12*Global`v^7*Global`w^3 - 
          4*FeynCalc`CA^2*Global`v^7*Global`w^3 - 20*Global`v^3*Global`w^4 + 
          4*FeynCalc`CA^2*Global`v^3*Global`w^4 + 66*Global`v^4*Global`w^4 - 
          22*FeynCalc`CA^2*Global`v^4*Global`w^4 - 39*Global`v^5*Global`w^4 + 
          15*FeynCalc`CA^2*Global`v^5*Global`w^4 - 15*Global`v^6*Global`w^4 - 
          5*FeynCalc`CA^2*Global`v^6*Global`w^4 + 6*Global`v^7*Global`w^4 + 
          10*FeynCalc`CA^2*Global`v^7*Global`w^4 - 10*Global`v^4*Global`w^5 + 
          2*FeynCalc`CA^2*Global`v^4*Global`w^5 + 9*Global`v^5*Global`w^5 + 
          3*FeynCalc`CA^2*Global`v^5*Global`w^5 + 3*Global`v^6*Global`w^5 + 
          9*FeynCalc`CA^2*Global`v^6*Global`w^5 - 16*FeynCalc`CA^2*Global`v^7*
           Global`w^5 - 8*FeynCalc`CA^2*Global`v^6*Global`w^6 + 
          8*FeynCalc`CA^2*Global`v^7*Global`w^6)*FeynFacet`\[Alpha]s^3)/
        (16*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v*
         Global`w*(-1 + Global`v*Global`w)*(1 - Global`v + Global`v*Global`w)^
          3) + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-1 + FeynCalc`CA^2 + 
          6*Global`v - 6*FeynCalc`CA^2*Global`v - 16*Global`v^2 + 
          16*FeynCalc`CA^2*Global`v^2 + 24*Global`v^3 - 24*FeynCalc`CA^2*
           Global`v^3 - 21*Global`v^4 + 21*FeynCalc`CA^2*Global`v^4 + 
          10*Global`v^5 - 10*FeynCalc`CA^2*Global`v^5 - 2*Global`v^6 + 
          2*FeynCalc`CA^2*Global`v^6 - 8*Global`v*Global`w + 
          6*FeynCalc`CA^2*Global`v*Global`w + 41*Global`v^2*Global`w - 
          31*FeynCalc`CA^2*Global`v^2*Global`w - 87*Global`v^3*Global`w + 
          65*FeynCalc`CA^2*Global`v^3*Global`w + 95*Global`v^4*Global`w - 
          69*FeynCalc`CA^2*Global`v^4*Global`w - 53*Global`v^5*Global`w + 
          37*FeynCalc`CA^2*Global`v^5*Global`w + 12*Global`v^6*Global`w - 
          8*FeynCalc`CA^2*Global`v^6*Global`w - 11*Global`v^2*Global`w^2 + 
          7*FeynCalc`CA^2*Global`v^2*Global`w^2 + 53*Global`v^3*Global`w^2 - 
          33*FeynCalc`CA^2*Global`v^3*Global`w^2 - 95*Global`v^4*Global`w^2 + 
          59*FeynCalc`CA^2*Global`v^4*Global`w^2 + 75*Global`v^5*Global`w^2 - 
          47*FeynCalc`CA^2*Global`v^5*Global`w^2 - 22*Global`v^6*Global`w^2 + 
          14*FeynCalc`CA^2*Global`v^6*Global`w^2 - 10*Global`v^3*Global`w^3 + 
          4*FeynCalc`CA^2*Global`v^3*Global`w^3 + 37*Global`v^4*Global`w^3 - 
          19*FeynCalc`CA^2*Global`v^4*Global`w^3 - 47*Global`v^5*Global`w^3 + 
          27*FeynCalc`CA^2*Global`v^5*Global`w^3 + 20*Global`v^6*Global`w^3 - 
          12*FeynCalc`CA^2*Global`v^6*Global`w^3 - 8*Global`v^4*Global`w^4 + 
          4*FeynCalc`CA^2*Global`v^4*Global`w^4 + 21*Global`v^5*Global`w^4 - 
          9*FeynCalc`CA^2*Global`v^5*Global`w^4 - 14*Global`v^6*Global`w^4 + 
          6*FeynCalc`CA^2*Global`v^6*Global`w^4 - 6*Global`v^5*Global`w^5 + 
          2*FeynCalc`CA^2*Global`v^5*Global`w^5 + 8*Global`v^6*Global`w^5 - 
          4*FeynCalc`CA^2*Global`v^6*Global`w^5 - 2*Global`v^6*Global`w^6 + 
          2*FeynCalc`CA^2*Global`v^6*Global`w^6)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muD2])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v*Global`w*(1 - Global`v + Global`v*Global`w)^
          3) + ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
         (1 - 2*Global`v + 2*Global`v^2)*(-1 + Global`w)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muFA2])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*Global`v*Global`w) + 
       ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(-4 + 7*Global`v - 
          4*Global`v^2 + 9*Global`v*Global`w - 10*Global`v^2*Global`w + 
          4*Global`v^3*Global`w - 6*Global`v^2*Global`w^2 + 
          2*Global`v^3*Global`w^2 + 2*Global`v^3*Global`w^3)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muFB2])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*
         (-1 + Global`v*Global`w)) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (2 - 2*FeynCalc`CA^2 - 12*Global`v + 12*FeynCalc`CA^2*Global`v + 
          32*Global`v^2 - 32*FeynCalc`CA^2*Global`v^2 - 48*Global`v^3 + 
          48*FeynCalc`CA^2*Global`v^3 + 42*Global`v^4 - 42*FeynCalc`CA^2*
           Global`v^4 - 20*Global`v^5 + 20*FeynCalc`CA^2*Global`v^5 + 
          4*Global`v^6 - 4*FeynCalc`CA^2*Global`v^6 - Global`w + 
          FeynCalc`CA^2*Global`w + 19*Global`v*Global`w - 
          17*FeynCalc`CA^2*Global`v*Global`w - 79*Global`v^2*Global`w + 
          69*FeynCalc`CA^2*Global`v^2*Global`w + 149*Global`v^3*Global`w - 
          127*FeynCalc`CA^2*Global`v^3*Global`w - 144*Global`v^4*Global`w + 
          118*FeynCalc`CA^2*Global`v^4*Global`w + 64*Global`v^5*Global`w - 
          48*FeynCalc`CA^2*Global`v^5*Global`w - 4*Global`v^6*Global`w - 
          4*Global`v^7*Global`w + 4*FeynCalc`CA^2*Global`v^7*Global`w - 
          2*Global`v*Global`w^2 + 2*FeynCalc`CA^2*Global`v*Global`w^2 + 
          15*Global`v^2*Global`w^2 - 13*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          34*Global`v^3*Global`w^2 + 24*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          16*Global`v^4*Global`w^2 - 2*FeynCalc`CA^2*Global`v^4*Global`w^2 + 
          44*Global`v^5*Global`w^2 - 46*FeynCalc`CA^2*Global`v^5*Global`w^2 - 
          63*Global`v^6*Global`w^2 + 55*FeynCalc`CA^2*Global`v^6*Global`w^2 + 
          24*Global`v^7*Global`w^2 - 20*FeynCalc`CA^2*Global`v^7*Global`w^2 - 
          15*Global`v^3*Global`w^3 + 17*FeynCalc`CA^2*Global`v^3*Global`w^3 + 
          68*Global`v^4*Global`w^3 - 66*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          128*Global`v^5*Global`w^3 + 112*FeynCalc`CA^2*Global`v^5*
           Global`w^3 + 119*Global`v^6*Global`w^3 - 99*FeynCalc`CA^2*
           Global`v^6*Global`w^3 - 44*Global`v^7*Global`w^3 + 
          36*FeynCalc`CA^2*Global`v^7*Global`w^3 + 2*Global`v^3*Global`w^4 - 
          2*FeynCalc`CA^2*Global`v^3*Global`w^4 - 19*Global`v^4*Global`w^4 + 
          17*FeynCalc`CA^2*Global`v^4*Global`w^4 + 50*Global`v^5*Global`w^4 - 
          44*FeynCalc`CA^2*Global`v^5*Global`w^4 - 67*Global`v^6*Global`w^4 + 
          55*FeynCalc`CA^2*Global`v^6*Global`w^4 + 36*Global`v^7*Global`w^4 - 
          28*FeynCalc`CA^2*Global`v^7*Global`w^4 + Global`v^4*Global`w^5 - 
          FeynCalc`CA^2*Global`v^4*Global`w^5 - 2*Global`v^5*Global`w^5 + 
          2*FeynCalc`CA^2*Global`v^5*Global`w^5 + 15*Global`v^6*Global`w^5 - 
          7*FeynCalc`CA^2*Global`v^6*Global`w^5 - 20*Global`v^7*Global`w^5 + 
          12*FeynCalc`CA^2*Global`v^7*Global`w^5 - 4*Global`v^6*Global`w^6 + 
          12*Global`v^7*Global`w^6 - 8*FeynCalc`CA^2*Global`v^7*Global`w^6 - 
          4*Global`v^7*Global`w^7 + 4*FeynCalc`CA^2*Global`v^7*Global`w^7)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(8*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)*Global`v*Global`w*
         (-1 + Global`v*Global`w)*(1 - Global`v + Global`v*Global`w)^3) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(4 - 3*FeynCalc`CA^2 + 
          Global`v + 5*FeynCalc`CA^2*Global`v - 23*Global`v^2 + 
          FeynCalc`CA^2*Global`v^2 + 32*Global`v^3 - 7*FeynCalc`CA^2*
           Global`v^3 - 14*Global`v^4 + 4*FeynCalc`CA^2*Global`v^4 - 
          13*Global`v*Global`w + 4*FeynCalc`CA^2*Global`v*Global`w + 
          30*Global`v^2*Global`w - 11*FeynCalc`CA^2*Global`v^2*Global`w - 
          32*Global`v^3*Global`w + 12*FeynCalc`CA^2*Global`v^3*Global`w + 
          16*Global`v^4*Global`w - 6*FeynCalc`CA^2*Global`v^4*Global`w + 
          5*Global`v^2*Global`w^2 - 4*Global`v^3*Global`w^2 + 
          FeynCalc`CA^2*Global`v^3*Global`w^2 - 4*Global`v^4*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v^4*Global`w^2 - 2*FeynCalc`CA^2*Global`v^3*
           Global`w^3 + 4*Global`v^4*Global`w^3 - 2*FeynCalc`CA^2*Global`v^4*
           Global`w^3 - 2*Global`v^4*Global`w^4 + 2*FeynCalc`CA^2*Global`v^4*
           Global`w^4)*FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v*
         (-1 + Global`w)*(1 - Global`v + Global`v*Global`w)) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(2 - 2*FeynCalc`CA^2 - 
          12*Global`v + 12*FeynCalc`CA^2*Global`v + 32*Global`v^2 - 
          32*FeynCalc`CA^2*Global`v^2 - 48*Global`v^3 + 48*FeynCalc`CA^2*
           Global`v^3 + 42*Global`v^4 - 42*FeynCalc`CA^2*Global`v^4 - 
          20*Global`v^5 + 20*FeynCalc`CA^2*Global`v^5 + 4*Global`v^6 - 
          4*FeynCalc`CA^2*Global`v^6 - Global`w + FeynCalc`CA^2*Global`w - 
          13*Global`v*Global`w - 17*FeynCalc`CA^2*Global`v*Global`w + 
          73*Global`v^2*Global`w + 69*FeynCalc`CA^2*Global`v^2*Global`w - 
          147*Global`v^3*Global`w - 127*FeynCalc`CA^2*Global`v^3*Global`w + 
          152*Global`v^4*Global`w + 118*FeynCalc`CA^2*Global`v^4*Global`w - 
          88*Global`v^5*Global`w - 48*FeynCalc`CA^2*Global`v^5*Global`w + 
          28*Global`v^6*Global`w - 4*Global`v^7*Global`w + 
          4*FeynCalc`CA^2*Global`v^7*Global`w - 2*Global`v*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v*Global`w^2 + 7*Global`v^2*Global`w^2 - 
          13*FeynCalc`CA^2*Global`v^2*Global`w^2 - 18*Global`v^3*Global`w^2 + 
          24*FeynCalc`CA^2*Global`v^3*Global`w^2 + 32*Global`v^4*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v^4*Global`w^2 - 36*Global`v^5*Global`w^2 - 
          46*FeynCalc`CA^2*Global`v^5*Global`w^2 + 25*Global`v^6*Global`w^2 + 
          55*FeynCalc`CA^2*Global`v^6*Global`w^2 - 8*Global`v^7*Global`w^2 - 
          20*FeynCalc`CA^2*Global`v^7*Global`w^2 + 41*Global`v^3*Global`w^3 + 
          17*FeynCalc`CA^2*Global`v^3*Global`w^3 - 108*Global`v^4*
           Global`w^3 - 66*FeynCalc`CA^2*Global`v^4*Global`w^3 + 
          112*Global`v^5*Global`w^3 + 112*FeynCalc`CA^2*Global`v^5*
           Global`w^3 - 65*Global`v^6*Global`w^3 - 99*FeynCalc`CA^2*
           Global`v^6*Global`w^3 + 20*Global`v^7*Global`w^3 + 
          36*FeynCalc`CA^2*Global`v^7*Global`w^3 + 2*Global`v^3*Global`w^4 - 
          2*FeynCalc`CA^2*Global`v^3*Global`w^4 - 11*Global`v^4*Global`w^4 + 
          17*FeynCalc`CA^2*Global`v^4*Global`w^4 + 34*Global`v^5*Global`w^4 - 
          44*FeynCalc`CA^2*Global`v^5*Global`w^4 - 27*Global`v^6*Global`w^4 + 
          55*FeynCalc`CA^2*Global`v^6*Global`w^4 + 4*Global`v^7*Global`w^4 - 
          28*FeynCalc`CA^2*Global`v^7*Global`w^4 + Global`v^4*Global`w^5 - 
          FeynCalc`CA^2*Global`v^4*Global`w^5 - 26*Global`v^5*Global`w^5 + 
          2*FeynCalc`CA^2*Global`v^5*Global`w^5 + 39*Global`v^6*Global`w^5 - 
          7*FeynCalc`CA^2*Global`v^6*Global`w^5 - 20*Global`v^7*Global`w^5 + 
          12*FeynCalc`CA^2*Global`v^7*Global`w^5 - 4*Global`v^6*Global`w^6 + 
          12*Global`v^7*Global`w^6 - 8*FeynCalc`CA^2*Global`v^7*Global`w^6 - 
          4*Global`v^7*Global`w^7 + 4*FeynCalc`CA^2*Global`v^7*Global`w^7)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`v])/(8*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)*Global`v*Global`w*
         (-1 + Global`v*Global`w)*(1 - Global`v + Global`v*Global`w)^3) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(2 - 2*FeynCalc`CA^2 - 
          12*Global`v + 12*FeynCalc`CA^2*Global`v + 32*Global`v^2 - 
          32*FeynCalc`CA^2*Global`v^2 - 48*Global`v^3 + 48*FeynCalc`CA^2*
           Global`v^3 + 42*Global`v^4 - 42*FeynCalc`CA^2*Global`v^4 - 
          20*Global`v^5 + 20*FeynCalc`CA^2*Global`v^5 + 4*Global`v^6 - 
          4*FeynCalc`CA^2*Global`v^6 - Global`w + FeynCalc`CA^2*Global`w + 
          15*Global`v*Global`w - 21*FeynCalc`CA^2*Global`v*Global`w - 
          67*Global`v^2*Global`w + 91*FeynCalc`CA^2*Global`v^2*Global`w + 
          141*Global`v^3*Global`w - 177*FeynCalc`CA^2*Global`v^3*Global`w - 
          152*Global`v^4*Global`w + 176*FeynCalc`CA^2*Global`v^4*Global`w + 
          76*Global`v^5*Global`w - 82*FeynCalc`CA^2*Global`v^5*Global`w - 
          8*Global`v^6*Global`w + 8*FeynCalc`CA^2*Global`v^6*Global`w - 
          4*Global`v^7*Global`w + 4*FeynCalc`CA^2*Global`v^7*Global`w - 
          2*Global`v*Global`w^2 + 2*FeynCalc`CA^2*Global`v*Global`w^2 + 
          19*Global`v^2*Global`w^2 - 15*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          54*Global`v^3*Global`w^2 + 32*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          48*Global`v^4*Global`w^2 - 10*FeynCalc`CA^2*Global`v^4*Global`w^2 + 
          28*Global`v^5*Global`w^2 - 54*FeynCalc`CA^2*Global`v^5*Global`w^2 - 
          67*Global`v^6*Global`w^2 + 73*FeynCalc`CA^2*Global`v^6*Global`w^2 + 
          28*Global`v^7*Global`w^2 - 28*FeynCalc`CA^2*Global`v^7*Global`w^2 - 
          7*Global`v^3*Global`w^3 + 23*FeynCalc`CA^2*Global`v^3*Global`w^3 + 
          60*Global`v^4*Global`w^3 - 90*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          144*Global`v^5*Global`w^3 + 156*FeynCalc`CA^2*Global`v^5*
           Global`w^3 + 143*Global`v^6*Global`w^3 - 141*FeynCalc`CA^2*
           Global`v^6*Global`w^3 - 52*Global`v^7*Global`w^3 + 
          52*FeynCalc`CA^2*Global`v^7*Global`w^3 + 2*Global`v^3*Global`w^4 - 
          2*FeynCalc`CA^2*Global`v^3*Global`w^4 - 27*Global`v^4*Global`w^4 + 
          19*FeynCalc`CA^2*Global`v^4*Global`w^4 + 74*Global`v^5*Global`w^4 - 
          52*FeynCalc`CA^2*Global`v^5*Global`w^4 - 83*Global`v^6*Global`w^4 + 
          69*FeynCalc`CA^2*Global`v^6*Global`w^4 + 36*Global`v^7*Global`w^4 - 
          36*FeynCalc`CA^2*Global`v^7*Global`w^4 + Global`v^4*Global`w^5 - 
          FeynCalc`CA^2*Global`v^4*Global`w^5 - 6*Global`v^5*Global`w^5 + 
          11*Global`v^6*Global`w^5 - 5*FeynCalc`CA^2*Global`v^6*Global`w^5 - 
          12*Global`v^7*Global`w^5 + 12*FeynCalc`CA^2*Global`v^7*Global`w^5 + 
          8*Global`v^7*Global`w^6 - 8*FeynCalc`CA^2*Global`v^7*Global`w^6 - 
          4*Global`v^7*Global`w^7 + 4*FeynCalc`CA^2*Global`v^7*Global`w^7)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`w])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v*
         Global`w*(-1 + Global`v*Global`w)*(1 - Global`v + Global`v*Global`w)^
          3) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-1 + FeynCalc`CA^2 + 
          3*Global`v - 3*FeynCalc`CA^2*Global`v - 4*Global`v^2 + 
          4*FeynCalc`CA^2*Global`v^2 + 2*Global`v^3 - 2*FeynCalc`CA^2*
           Global`v^3 + 7*Global`w - FeynCalc`CA^2*Global`w - 
          12*Global`v*Global`w + 3*FeynCalc`CA^2*Global`v*Global`w + 
          12*Global`v^2*Global`w - 4*FeynCalc`CA^2*Global`v^2*Global`w - 
          4*Global`v^3*Global`w + 2*FeynCalc`CA^2*Global`v^3*Global`w - 
          3*Global`v*Global`w^2 - 4*Global`v^2*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v^2*Global`w^2 + 4*Global`v^3*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v^3*Global`w^2 + 12*Global`v^2*Global`w^3 - 
          2*FeynCalc`CA^2*Global`v^2*Global`w^3 - 4*Global`v^3*Global`w^3 + 
          2*FeynCalc`CA^2*Global`v^3*Global`w^3 + 2*Global`v^3*Global`w^4)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`w])/(4*FeynCalc`CA^3*
         System`Pi*Global`s^2*Global`v*(-1 + Global`w)*Global`w*
         (1 - Global`v + Global`v*Global`w)) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(4 - 3*FeynCalc`CA^2 - 
          5*Global`v + 4*FeynCalc`CA^2*Global`v + 2*Global`v^2 - 
          2*FeynCalc`CA^2*Global`v^2 - 7*Global`v*Global`w + 
          5*FeynCalc`CA^2*Global`v*Global`w + 6*Global`v^2*Global`w - 
          4*FeynCalc`CA^2*Global`v^2*Global`w - 2*Global`v^3*Global`w + 
          2*FeynCalc`CA^2*Global`v^3*Global`w + 4*Global`v^2*Global`w^2 - 
          4*FeynCalc`CA^2*Global`v^2*Global`w^2 - 2*Global`v^3*Global`w^3 + 
          2*FeynCalc`CA^2*Global`v^3*Global`w^3)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v*Global`w])/(4*FeynCalc`CA^3*System`Pi*
         Global`s^2*(-1 + Global`v)*Global`v*(-1 + Global`w)) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-2 + 3*FeynCalc`CA^2 + 
          8*Global`v - 12*FeynCalc`CA^2*Global`v - 13*Global`v^2 + 
          21*FeynCalc`CA^2*Global`v^2 + 10*Global`v^3 - 18*FeynCalc`CA^2*
           Global`v^3 - 3*Global`v^4 + 6*FeynCalc`CA^2*Global`v^4 - 
          4*Global`v*Global`w + 6*FeynCalc`CA^2*Global`v*Global`w + 
          10*Global`v^2*Global`w - 16*FeynCalc`CA^2*Global`v^2*Global`w - 
          12*Global`v^3*Global`w + 18*FeynCalc`CA^2*Global`v^3*Global`w + 
          6*Global`v^4*Global`w - 8*FeynCalc`CA^2*Global`v^4*Global`w + 
          7*Global`v^2*Global`w^2 - FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          10*Global`v^3*Global`w^2 + 2*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          2*Global`v^4*Global`w^2 + 2*FeynCalc`CA^2*Global`v^4*Global`w^2 + 
          12*Global`v^3*Global`w^3 - 2*FeynCalc`CA^2*Global`v^3*Global`w^3 - 
          10*Global`v^4*Global`w^3 - 4*FeynCalc`CA^2*Global`v^4*Global`w^3 + 
          5*Global`v^4*Global`w^4 + 4*FeynCalc`CA^2*Global`v^4*Global`w^4)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v + Global`v*Global`w])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*Global`v*(-1 + Global`w)*
         (1 - Global`v + Global`v*Global`w)^3)|>|>, 
 "DensityConvention" -> "E_c d sigma/d^(D-1)p_c", 
 "DistributionBasis" -> <|"Variable" -> Global`w, "Endpoint" -> 1, 
   "Interval" -> {0, 1}, "Distance" -> 1 - Global`w|>, 
 "PlusConvention" -> "At each axis, PlusCoefficients[k] multiplies \
[Log[Distance]^k/Distance]_+ on Interval, with subtraction at Endpoint. For \
DistributionBasis[Axes], delta/plus/regular values repeat recursively in the \
listed axis order."|>
