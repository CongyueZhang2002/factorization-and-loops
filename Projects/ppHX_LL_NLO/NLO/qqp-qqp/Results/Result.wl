<|"Project" -> "ppHX_LL_NLO", "Channel" -> "qqp-qqp", "Scale" -> Global`s, 
 "Variables" -> {Global`v, Global`w}, "Coupling" -> FeynFacet`\[Alpha]s, 
 "CouplingPower" -> 3, "DimensionalPrefactor" -> 
  Global`muR2^(2*Global`Epsilon), "PhysicalChannel" -> 
  <|"Incoming" -> {{"q", "u"}, {"q", "d"}}, "Observed" -> {"q", "u"}, 
   "Recoil" -> {"q", "d"}|>, "Polarization" -> <|"Incoming" -> {"L", "L"}, 
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
      -1/144*((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(225 + 115*FeynCalc`CA^2 - 
           40*FeynCalc`CA*Global`nD - 40*FeynCalc`CA*Global`nU + 
           42*System`Pi^2 + 12*FeynCalc`CA^2*System`Pi^2)*(1 + Global`v)*
          FeynFacet`\[Alpha]s^3)/(FeynCalc`CA^3*System`Pi*Global`s^2*
          (-1 + Global`v)*Global`v) + (3*(-1 + FeynCalc`CA)^2*
         (1 + FeynCalc`CA)^2*(1 + Global`v)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muFA2])/(16*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (11*FeynCalc`CA - 2*Global`nD - 2*Global`nU)*(1 + Global`v)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muR2])/
        (12*FeynCalc`CA^2*System`Pi*Global`s^2*(-1 + Global`v)*Global`v) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(27 + 17*FeynCalc`CA^2 - 
          8*FeynCalc`CA*Global`nD - 8*FeynCalc`CA*Global`nU)*(1 + Global`v)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(48*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)*Global`v) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(1 + 2*FeynCalc`CA^2)*
         (1 + Global`v)*FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v]^2)/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v) + 
       (((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(5 - FeynCalc`CA^2 - 
            3*Global`v + 3*FeynCalc`CA^2*Global`v)*FeynFacet`\[Alpha]s^3)/
          (16*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v) - 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(2*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)*Global`v))*
        System`Log[Global`v] - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (-4 + 3*FeynCalc`CA)*(4 + 3*FeynCalc`CA)*(1 + Global`v)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`v]^2)/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v) + 
       System`Log[Global`muD2]*((3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           (1 + Global`v)*FeynFacet`\[Alpha]s^3)/(16*FeynCalc`CA^3*System`Pi*
           Global`s^2*(-1 + Global`v)*Global`v) + 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`v])/(4*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)*Global`v)) + 
       System`Log[Global`muFB2]*((3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           (1 + Global`v)*FeynFacet`\[Alpha]s^3)/(16*FeynCalc`CA^3*System`Pi*
           Global`s^2*(-1 + Global`v)*Global`v) - 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v)*
           FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v])/
          (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v) + 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`v])/(4*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)*Global`v)) + 
       System`Log[1 - Global`v]*(((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
           (3 + 5*FeynCalc`CA^2 - 2*FeynCalc`CA*Global`nD - 
            2*FeynCalc`CA*Global`nU + 15*Global`v + 2*FeynCalc`CA^2*
             Global`v - 2*FeynCalc`CA*Global`nD*Global`v - 
            2*FeynCalc`CA*Global`nU*Global`v)*FeynFacet`\[Alpha]s^3)/
          (12*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v) + 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v)*
           FeynFacet`\[Alpha]s^3*System`Log[Global`s])/(4*FeynCalc`CA^3*
           System`Pi*Global`s^2*(-1 + Global`v)*Global`v) + 
         ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(-5 + 4*FeynCalc`CA^2)*
           (1 + Global`v)*FeynFacet`\[Alpha]s^3*System`Log[Global`v])/
          (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v)), 
     "PlusCoefficients" -> 
      <|0 -> (3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v)*
           FeynFacet`\[Alpha]s^3)/(16*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v) + ((-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*(1 + Global`v)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muD2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v) + ((-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*(1 + Global`v)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFA2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v) + ((-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*(1 + Global`v)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFB2])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v) - (3*(-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*(1 + Global`v)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v) + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
           (1 + FeynCalc`CA^2)*(1 + Global`v)*FeynFacet`\[Alpha]s^3*
           System`Log[1 - Global`v])/(2*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
           (-11 + 7*FeynCalc`CA^2)*(1 + Global`v)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v])/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)*Global`v), 
       1 -> (-5*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v)*
          FeynFacet`\[Alpha]s^3)/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
          (-1 + Global`v)*Global`v)|>, "RegularCoefficient" -> 
      ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(2 - 2*FeynCalc`CA^2 - 
          4*Global`v + 4*FeynCalc`CA^2*Global`v + 2*Global`v^2 - 
          2*FeynCalc`CA^2*Global`v^2 + 6*Global`w - 2*FeynCalc`CA^2*
           Global`w - 13*Global`v*Global`w + FeynCalc`CA^2*Global`v*
           Global`w + 7*Global`v^2*Global`w + 9*FeynCalc`CA^2*Global`v^2*
           Global`w - 8*FeynCalc`CA^2*Global`v^3*Global`w - 
          6*Global`v*Global`w^2 + 2*FeynCalc`CA^2*Global`v*Global`w^2 + 
          39*Global`v^2*Global`w^2 - 15*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          26*Global`v^3*Global`w^2 + 26*FeynCalc`CA^2*Global`v^3*Global`w^2 - 
          8*FeynCalc`CA^2*Global`v^4*Global`w^2 - 6*Global`v^2*Global`w^3 + 
          2*FeynCalc`CA^2*Global`v^2*Global`w^3 - 15*Global`v^3*Global`w^3 - 
          13*FeynCalc`CA^2*Global`v^3*Global`w^3 + 13*Global`v^4*Global`w^3 + 
          19*FeynCalc`CA^2*Global`v^4*Global`w^3 + 2*Global`v^5*Global`w^3 - 
          2*FeynCalc`CA^2*Global`v^5*Global`w^3 + 6*Global`v^3*Global`w^4 - 
          2*FeynCalc`CA^2*Global`v^3*Global`w^4 - 5*Global`v^4*Global`w^4 - 
          11*FeynCalc`CA^2*Global`v^4*Global`w^4 - 2*Global`v^5*Global`w^4 + 
          2*FeynCalc`CA^2*Global`v^5*Global`w^4)*FeynFacet`\[Alpha]s^3)/
        (16*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v*
         Global`w*(-1 + Global`v*Global`w)^2*(1 - Global`v + 
          Global`v*Global`w)) - ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
         (4 - 5*Global`v + Global`v^2 + 5*Global`v*Global`w - 
          3*Global`v^2*Global`w + 2*Global`v^2*Global`w^2)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muD2])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*
         (1 - Global`v + Global`v*Global`w)) - 
       ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*(1 + Global`v)*
         (-1 + Global`w)*FeynFacet`\[Alpha]s^3*System`Log[Global`muFA2])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v*
         Global`w) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (1 - FeynCalc`CA^2 + Global`v - FeynCalc`CA^2*Global`v - 
          7*Global`v*Global`w + 5*FeynCalc`CA^2*Global`v*Global`w - 
          2*FeynCalc`CA^2*Global`v^2*Global`w + 4*Global`v^2*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v^2*Global`w^2 - 2*FeynCalc`CA^2*Global`v^3*
           Global`w^2 + 2*Global`v^3*Global`w^3 + 2*FeynCalc`CA^2*Global`v^3*
           Global`w^3 + Global`v^4*Global`w^3 - FeynCalc`CA^2*Global`v^4*
           Global`w^3 - 2*Global`v^4*Global`w^4 + 2*FeynCalc`CA^2*Global`v^4*
           Global`w^4)*FeynFacet`\[Alpha]s^3*System`Log[Global`muFB2])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v*
         Global`w*(-1 + Global`v*Global`w)^2) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(2 - 2*FeynCalc`CA^2 - 
          2*Global`v^2 + 2*FeynCalc`CA^2*Global`v^2 - Global`w + 
          FeynCalc`CA^2*Global`w - 11*Global`v*Global`w + 
          9*FeynCalc`CA^2*Global`v*Global`w + 15*Global`v^2*Global`w - 
          15*FeynCalc`CA^2*Global`v^2*Global`w + Global`v^3*Global`w + 
          FeynCalc`CA^2*Global`v^3*Global`w + Global`v*Global`w^2 - 
          FeynCalc`CA^2*Global`v*Global`w^2 - 2*Global`v^2*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v^2*Global`w^2 - 15*Global`v^3*Global`w^2 + 
          9*FeynCalc`CA^2*Global`v^3*Global`w^2 + Global`v^4*Global`w^2 + 
          FeynCalc`CA^2*Global`v^4*Global`w^2 + Global`v^2*Global`w^3 - 
          FeynCalc`CA^2*Global`v^2*Global`w^3 + 13*Global`v^3*Global`w^3 - 
          7*FeynCalc`CA^2*Global`v^3*Global`w^3 - 6*FeynCalc`CA^2*Global`v^4*
           Global`w^3 - 2*Global`v^5*Global`w^3 + 2*FeynCalc`CA^2*Global`v^5*
           Global`w^3 - Global`v^3*Global`w^4 + FeynCalc`CA^2*Global`v^3*
           Global`w^4 - 2*Global`v^4*Global`w^4 + 6*FeynCalc`CA^2*Global`v^4*
           Global`w^4 + 6*Global`v^5*Global`w^4 - 6*FeynCalc`CA^2*Global`v^5*
           Global`w^4 - 4*Global`v^5*Global`w^5 + 4*FeynCalc`CA^2*Global`v^5*
           Global`w^5)*FeynFacet`\[Alpha]s^3*System`Log[Global`s])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v*
         Global`w*(-1 + Global`v*Global`w)^2*(1 - Global`v + 
          Global`v*Global`w)) + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (1 - FeynCalc`CA^2 + Global`v - FeynCalc`CA^2*Global`v - Global`w - 
          2*FeynCalc`CA^2*Global`w - Global`v*Global`w - 
          FeynCalc`CA^2*Global`v*Global`w - 4*Global`v^2*Global`w + 
          FeynCalc`CA^2*Global`v^2*Global`w + 2*FeynCalc`CA^2*Global`v*
           Global`w^2 + 5*Global`v^2*Global`w^2 + FeynCalc`CA^2*Global`v^2*
           Global`w^2 - Global`v^3*Global`w^2 + FeynCalc`CA^2*Global`v^3*
           Global`w^2 - Global`v^2*Global`w^3 + FeynCalc`CA^2*Global`v^2*
           Global`w^3 + 3*Global`v^3*Global`w^3 - 3*FeynCalc`CA^2*Global`v^3*
           Global`w^3 - 2*Global`v^3*Global`w^4 + 2*FeynCalc`CA^2*Global`v^3*
           Global`w^4)*FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v])/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v*
         (-1 + Global`w)*Global`w*(-1 + Global`v*Global`w)) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(2 - 2*FeynCalc`CA^2 - 
          2*Global`v^2 + 2*FeynCalc`CA^2*Global`v^2 - Global`w + 
          FeynCalc`CA^2*Global`w - 43*Global`v*Global`w + 
          25*FeynCalc`CA^2*Global`v*Global`w + 55*Global`v^2*Global`w - 
          35*FeynCalc`CA^2*Global`v^2*Global`w - 7*Global`v^3*Global`w + 
          5*FeynCalc`CA^2*Global`v^3*Global`w + Global`v*Global`w^2 - 
          FeynCalc`CA^2*Global`v*Global`w^2 + 6*Global`v^2*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v^2*Global`w^2 - 55*Global`v^3*Global`w^2 + 
          29*FeynCalc`CA^2*Global`v^3*Global`w^2 + 9*Global`v^4*Global`w^2 - 
          3*FeynCalc`CA^2*Global`v^4*Global`w^2 + Global`v^2*Global`w^3 - 
          FeynCalc`CA^2*Global`v^2*Global`w^3 + 45*Global`v^3*Global`w^3 - 
          23*FeynCalc`CA^2*Global`v^3*Global`w^3 - 6*FeynCalc`CA^2*Global`v^4*
           Global`w^3 - 2*Global`v^5*Global`w^3 + 2*FeynCalc`CA^2*Global`v^5*
           Global`w^3 - Global`v^3*Global`w^4 + FeynCalc`CA^2*Global`v^3*
           Global`w^4 - 10*Global`v^4*Global`w^4 + 10*FeynCalc`CA^2*
           Global`v^4*Global`w^4 + 6*Global`v^5*Global`w^4 - 
          6*FeynCalc`CA^2*Global`v^5*Global`w^4 - 4*Global`v^5*Global`w^5 + 
          4*FeynCalc`CA^2*Global`v^5*Global`w^5)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`v])/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)*Global`v*Global`w*(-1 + Global`v*Global`w)^2*
         (1 - Global`v + Global`v*Global`w)) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(2 - 2*FeynCalc`CA^2 - 
          2*Global`v^2 + 2*FeynCalc`CA^2*Global`v^2 - Global`w + 
          FeynCalc`CA^2*Global`w - 23*Global`v*Global`w + 
          17*FeynCalc`CA^2*Global`v*Global`w + 35*Global`v^2*Global`w - 
          25*FeynCalc`CA^2*Global`v^2*Global`w - 7*Global`v^3*Global`w + 
          3*FeynCalc`CA^2*Global`v^3*Global`w + Global`v*Global`w^2 - 
          FeynCalc`CA^2*Global`v*Global`w^2 + 2*Global`v^2*Global`w^2 - 
          31*Global`v^3*Global`w^2 + 19*FeynCalc`CA^2*Global`v^3*Global`w^2 + 
          9*Global`v^4*Global`w^2 - FeynCalc`CA^2*Global`v^4*Global`w^2 + 
          Global`v^2*Global`w^3 - FeynCalc`CA^2*Global`v^2*Global`w^3 + 
          25*Global`v^3*Global`w^3 - 15*FeynCalc`CA^2*Global`v^3*Global`w^3 - 
          4*Global`v^4*Global`w^3 - 6*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          2*Global`v^5*Global`w^3 + 2*FeynCalc`CA^2*Global`v^5*Global`w^3 - 
          Global`v^3*Global`w^4 + FeynCalc`CA^2*Global`v^3*Global`w^4 - 
          6*Global`v^4*Global`w^4 + 8*FeynCalc`CA^2*Global`v^4*Global`w^4 + 
          6*Global`v^5*Global`w^4 - 6*FeynCalc`CA^2*Global`v^5*Global`w^4 - 
          4*Global`v^5*Global`w^5 + 4*FeynCalc`CA^2*Global`v^5*Global`w^5)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`w])/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v*
         Global`w*(-1 + Global`v*Global`w)^2*(1 - Global`v + 
          Global`v*Global`w)) + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (1 - FeynCalc`CA^2 + Global`v - FeynCalc`CA^2*Global`v + 
          5*Global`w - 2*FeynCalc`CA^2*Global`w - 6*Global`v*Global`w + 
          3*FeynCalc`CA^2*Global`v*Global`w - Global`v^2*Global`w + 
          5*Global`v*Global`w^2 - 2*FeynCalc`CA^2*Global`v*Global`w^2 - 
          3*Global`v^2*Global`w^2 + 2*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          2*Global`v^2*Global`w^3 + FeynCalc`CA^2*Global`v^2*Global`w^3)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`w])/(4*FeynCalc`CA^3*
         System`Pi*Global`s^2*(-1 + Global`v)*Global`v*(-1 + Global`w)*
         Global`w*(-1 + Global`v*Global`w)) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*(1 + Global`v*Global`w)*
         (-1 + FeynCalc`CA^2 - Global`v + FeynCalc`CA^2*Global`v + Global`w + 
          2*FeynCalc`CA^2*Global`w + 3*Global`v*Global`w - 
          3*FeynCalc`CA^2*Global`v*Global`w - 2*Global`v*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v*Global`w^2)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v*Global`w])/(4*FeynCalc`CA^3*System`Pi*
         Global`s^2*(-1 + Global`v)*Global`v*(-1 + Global`w)*Global`w) - 
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
