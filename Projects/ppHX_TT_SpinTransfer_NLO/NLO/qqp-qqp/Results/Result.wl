<|"Project" -> "ppHX_TT_SpinTransfer_NLO", "Channel" -> "qqp-qqp", 
 "Scale" -> Global`s, "Variables" -> {Global`v, Global`w}, 
 "Coupling" -> FeynFacet`\[Alpha]s, "CouplingPower" -> 3, 
 "DimensionalPrefactor" -> Global`muR2^(2*Global`Epsilon), 
 "PhysicalChannel" -> <|"Incoming" -> {{"q", "u"}, {"q", "d"}}, 
   "Observed" -> {"q", "u"}, "Recoil" -> {"q", "d"}|>, 
 "Polarization" -> <|"Incoming" -> {"T", "U"}, "Observed" -> "T"|>, 
 "Order" -> "NLO", "Contribution" -> "Total", 
 "DimensionalRegulator" -> Global`Epsilon, "PoleCancellation" -> 
  "Exact symbolic zero in every delta, plus and regular coefficient", 
 "Contributions" -> {"Real", "Virtual", "Counterterm"}, 
 "Domain" -> Global`s > 0 && 0 < Global`v < 1 && 0 < Global`w < 1 && 
   Global`muR2 > 0 && Global`muFA2 > 0 && Global`muFB2 > 0 && 
   Global`muD2 > 0, "Description" -> 
  <|"Channel" -> "q qprime -> observed q + X", 
   "Polarization" -> <|"Incoming" -> {"T", "U"}, "Observed" -> "T"|>, 
   "Fragmentation" -> "H1", "Coupling" -> 
    "Physical alpha_s powers included"|>, 
 "Format" -> "FeynFacet-PartonicResult", "FormatVersion" -> 1, 
 "EpsilonRange" -> {0, 0}, "LaurentLowerBound" -> 0, 
 "Coefficients" -> 
  <|0 -> <|"DeltaCoefficient" -> ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         Global`STa*Global`STh*(225 + 115*FeynCalc`CA^2 - 
          40*FeynCalc`CA*Global`nD - 40*FeynCalc`CA*Global`nU + 
          24*System`Pi^2 + 21*FeynCalc`CA^2*System`Pi^2 - 
          18*System`Pi^2*Global`v^2 + 9*FeynCalc`CA^2*System`Pi^2*Global`v^2)*
         FeynFacet`\[Alpha]s^3*(System`Cos[Global`phiA]*
           System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
           System`Sin[Global`\[Phi]h]))/(72*FeynCalc`CA^3*System`Pi*
         Global`s^2*(-1 + Global`v)^2) - (3*(-1 + FeynCalc`CA)^2*
         (1 + FeynCalc`CA)^2*Global`STa*Global`STh*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muFA2]*(System`Cos[Global`phiA]*
           System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
           System`Sin[Global`\[Phi]h]))/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2) + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         (11*FeynCalc`CA - 2*Global`nD - 2*Global`nU)*Global`STa*Global`STh*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muR2]*
         (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
          System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
        (6*FeynCalc`CA^2*System`Pi*Global`s^2*(-1 + Global`v)^2) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
         (2 + 2*Global`v^2 + 5*FeynCalc`CA^2*Global`v^2 - 2*Global`v^4 + 
          FeynCalc`CA^2*Global`v^4)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v]^2*(System`Cos[Global`phiA]*
           System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
           System`Sin[Global`\[Phi]h]))/(8*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^2) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
         (1 + FeynCalc`CA^2 - 4*Global`v + 2*FeynCalc`CA^2*Global`v)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`v]*
         (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
          System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
         (-34 + 19*FeynCalc`CA^2 - 2*Global`v^2 + FeynCalc`CA^2*Global`v^2)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`v]^2*
         (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
          System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
        (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2) + 
       System`Log[Global`muD2]*((-3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           Global`STa*Global`STh*FeynFacet`\[Alpha]s^3*
           (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
            System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
          (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2) - 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*Global`STa*Global`STh*
           FeynFacet`\[Alpha]s^3*System`Log[Global`v]*
           (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
            System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
          (2*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2)) + 
       System`Log[Global`muFB2]*((-3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           Global`STa*Global`STh*FeynFacet`\[Alpha]s^3*
           (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
            System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
          (8*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2) + 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*Global`STa*Global`STh*
           FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v]*
           (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
            System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
          (2*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2) - 
         ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*Global`STa*Global`STh*
           FeynFacet`\[Alpha]s^3*System`Log[Global`v]*
           (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
            System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
          (2*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2)) + 
       System`Log[Global`s]*(-1/24*((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
            (27 + 17*FeynCalc`CA^2 - 8*FeynCalc`CA*Global`nD - 
             8*FeynCalc`CA*Global`nU)*Global`STa*Global`STh*
            FeynFacet`\[Alpha]s^3*(System`Cos[Global`phiA]*System`Cos[
               Global`\[Phi]h] + System`Sin[Global`phiA]*System`Sin[
               Global`\[Phi]h]))/(FeynCalc`CA^3*System`Pi*Global`s^2*
            (-1 + Global`v)^2) - ((-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*
           Global`STa*Global`STh*FeynFacet`\[Alpha]s^3*
           System`Log[1 - Global`v]*(System`Cos[Global`phiA]*
             System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
             System`Sin[Global`\[Phi]h]))/(2*FeynCalc`CA^3*System`Pi*
           Global`s^2*(-1 + Global`v)^2) + ((-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*Global`STa*Global`STh*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v]*(System`Cos[Global`phiA]*System`Cos[
              Global`\[Phi]h] + System`Sin[Global`phiA]*System`Sin[
              Global`\[Phi]h]))/(FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2)) + System`Log[1 - Global`v]*
        (((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
           (6 - 18*Global`v - 7*FeynCalc`CA^2*Global`v + 4*FeynCalc`CA*
             Global`nD*Global`v + 4*FeynCalc`CA*Global`nU*Global`v - 
            6*Global`v^2 + 3*FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
            System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
          (12*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*
           Global`v) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*
           Global`STh*(-12 + 9*FeynCalc`CA^2 - 2*Global`v^2 + 
            FeynCalc`CA^2*Global`v^2)*FeynFacet`\[Alpha]s^3*
           System`Log[Global`v]*(System`Cos[Global`phiA]*System`Cos[
              Global`\[Phi]h] + System`Sin[Global`phiA]*System`Sin[
              Global`\[Phi]h]))/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2)), "PlusCoefficients" -> 
      <|0 -> (-3*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*Global`STa*
           Global`STh*FeynFacet`\[Alpha]s^3*(System`Cos[Global`phiA]*
             System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
             System`Sin[Global`\[Phi]h]))/(8*FeynCalc`CA^3*System`Pi*
           Global`s^2*(-1 + Global`v)^2) - ((-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*Global`STa*Global`STh*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muD2]*(System`Cos[Global`phiA]*
             System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
             System`Sin[Global`\[Phi]h]))/(2*FeynCalc`CA^3*System`Pi*
           Global`s^2*(-1 + Global`v)^2) - ((-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*Global`STa*Global`STh*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFA2]*(System`Cos[Global`phiA]*
             System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
             System`Sin[Global`\[Phi]h]))/(2*FeynCalc`CA^3*System`Pi*
           Global`s^2*(-1 + Global`v)^2) - ((-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*Global`STa*Global`STh*FeynFacet`\[Alpha]s^3*
           System`Log[Global`muFB2]*(System`Cos[Global`phiA]*
             System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
             System`Sin[Global`\[Phi]h]))/(2*FeynCalc`CA^3*System`Pi*
           Global`s^2*(-1 + Global`v)^2) + (3*(-1 + FeynCalc`CA)^2*
           (1 + FeynCalc`CA)^2*Global`STa*Global`STh*FeynFacet`\[Alpha]s^3*
           System`Log[Global`s]*(System`Cos[Global`phiA]*System`Cos[
              Global`\[Phi]h] + System`Sin[Global`phiA]*System`Sin[
              Global`\[Phi]h]))/(2*FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
           (1 + FeynCalc`CA^2)*Global`STa*Global`STh*FeynFacet`\[Alpha]s^3*
           System`Log[1 - Global`v]*(System`Cos[Global`phiA]*
             System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
             System`Sin[Global`\[Phi]h]))/(FeynCalc`CA^3*System`Pi*Global`s^2*
           (-1 + Global`v)^2) + ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
           (-11 + 7*FeynCalc`CA^2)*Global`STa*Global`STh*FeynFacet`\[Alpha]s^
            3*System`Log[Global`v]*(System`Cos[Global`phiA]*
             System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
             System`Sin[Global`\[Phi]h]))/(2*FeynCalc`CA^3*System`Pi*
           Global`s^2*(-1 + Global`v)^2), 
       1 -> (5*(-1 + FeynCalc`CA)^2*(1 + FeynCalc`CA)^2*Global`STa*Global`STh*
          FeynFacet`\[Alpha]s^3*(System`Cos[Global`phiA]*
            System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
            System`Sin[Global`\[Phi]h]))/(2*FeynCalc`CA^3*System`Pi*
          Global`s^2*(-1 + Global`v)^2)|>, "RegularCoefficient" -> 
      -1/8*((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
          (3 + 3*FeynCalc`CA^2 - 12*Global`v + 6*Global`v^2 - 
           4*FeynCalc`CA^2*Global`v*Global`w + 6*Global`v^2*Global`w + 
           6*FeynCalc`CA^2*Global`v^2*Global`w - 8*FeynCalc`CA^2*Global`v^3*
            Global`w - 7*Global`v^2*Global`w^2 - 3*FeynCalc`CA^2*Global`v^2*
            Global`w^2 + 14*Global`v^3*Global`w^2 + 2*FeynCalc`CA^2*
            Global`v^3*Global`w^2 - 10*Global`v^4*Global`w^2 + 
           4*FeynCalc`CA^2*Global`v^4*Global`w^2)*FeynFacet`\[Alpha]s^3*
          (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
           System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
         (FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*
          (-1 + Global`v*Global`w)^3) + ((-1 + FeynCalc`CA)^2*
         (1 + FeynCalc`CA)^2*Global`STa*Global`STh*(1 + Global`v*Global`w)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`muD2]*
         (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
          System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
        (2*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
         (1 - FeynCalc`CA^2 - Global`v^2 + FeynCalc`CA^2*Global`v^2 + 
          2*Global`v*Global`w - Global`v^2*Global`w + FeynCalc`CA^2*
           Global`v^2*Global`w + 3*Global`v^3*Global`w - 
          FeynCalc`CA^2*Global`v^3*Global`w - 6*Global`v^2*Global`w^2 + 
          2*FeynCalc`CA^2*Global`v^2*Global`w^2 - 3*Global`v^3*Global`w^2 - 
          FeynCalc`CA^2*Global`v^3*Global`w^2 - Global`v^4*Global`w^2 + 
          FeynCalc`CA^2*Global`v^4*Global`w^2 + 6*Global`v^3*Global`w^3 - 
          2*FeynCalc`CA^2*Global`v^3*Global`w^3 + 2*Global`v^4*Global`w^3 - 
          2*FeynCalc`CA^2*Global`v^4*Global`w^3 - 2*Global`v^4*Global`w^4 + 
          2*FeynCalc`CA^2*Global`v^4*Global`w^4)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`muFB2]*(System`Cos[Global`phiA]*
           System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
           System`Sin[Global`\[Phi]h]))/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*(-1 + Global`v*Global`w)^3) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
         (3 - 3*FeynCalc`CA^2 - Global`v^2 + FeynCalc`CA^2*Global`v^2 - 
          2*Global`v*Global`w + 4*FeynCalc`CA^2*Global`v*Global`w - 
          Global`v^2*Global`w + FeynCalc`CA^2*Global`v^2*Global`w + 
          3*Global`v^3*Global`w - FeynCalc`CA^2*Global`v^3*Global`w - 
          6*Global`v^2*Global`w^2 + 2*FeynCalc`CA^2*Global`v^2*Global`w^2 - 
          3*Global`v^3*Global`w^2 - FeynCalc`CA^2*Global`v^3*Global`w^2 - 
          Global`v^4*Global`w^2 + FeynCalc`CA^2*Global`v^4*Global`w^2 + 
          10*Global`v^3*Global`w^3 - 6*FeynCalc`CA^2*Global`v^3*Global`w^3 + 
          2*Global`v^4*Global`w^3 - 2*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          4*Global`v^4*Global`w^4 + 4*FeynCalc`CA^2*Global`v^4*Global`w^4)*
         FeynFacet`\[Alpha]s^3*System`Log[Global`s]*
         (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
          System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*
         (-1 + Global`v*Global`w)^3) - ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*
         Global`STa*Global`STh*(-2 + 5*Global`v - 3*Global`v^2 - Global`v^3 + 
          Global`v^4 - 3*Global`v*Global`w + 4*Global`v^2*Global`w - 
          8*FeynCalc`CA^2*Global`v^2*Global`w - 2*Global`v^3*Global`w + 
          2*FeynCalc`CA^2*Global`v^3*Global`w + 2*Global`v^4*Global`w - 
          2*FeynCalc`CA^2*Global`v^4*Global`w - Global`v^5*Global`w - 
          Global`v^2*Global`w^2 + FeynCalc`CA^2*Global`v^2*Global`w^2 + 
          Global`v^3*Global`w^2 + 3*FeynCalc`CA^2*Global`v^3*Global`w^2 - 
          3*Global`v^4*Global`w^2 + 3*FeynCalc`CA^2*Global`v^4*Global`w^2 - 
          Global`v^5*Global`w^2 + FeynCalc`CA^2*Global`v^5*Global`w^2 + 
          2*Global`v^3*Global`w^3 + 2*FeynCalc`CA^2*Global`v^3*Global`w^3 + 
          6*Global`v^4*Global`w^3 - 6*FeynCalc`CA^2*Global`v^4*Global`w^3 - 
          4*Global`v^4*Global`w^4 + 4*FeynCalc`CA^2*Global`v^4*Global`w^4)*
         FeynFacet`\[Alpha]s^3*System`Log[1 - Global`v]*
         (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
          System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)^2*Global`v^2*
         (-1 + Global`w)*Global`w*(-1 + Global`v*Global`w)) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
         (19 - 11*FeynCalc`CA^2 - Global`v^2 + FeynCalc`CA^2*Global`v^2 - 
          26*Global`v*Global`w + 16*FeynCalc`CA^2*Global`v*Global`w - 
          13*Global`v^2*Global`w + 7*FeynCalc`CA^2*Global`v^2*Global`w + 
          7*Global`v^3*Global`w - 3*FeynCalc`CA^2*Global`v^3*Global`w - 
          2*Global`v^2*Global`w^2 + 17*Global`v^3*Global`w^2 - 
          11*FeynCalc`CA^2*Global`v^3*Global`w^2 - 9*Global`v^4*Global`w^2 + 
          5*FeynCalc`CA^2*Global`v^4*Global`w^2 + 10*Global`v^3*Global`w^3 - 
          6*FeynCalc`CA^2*Global`v^3*Global`w^3 - 2*Global`v^4*Global`w^3 + 
          4*Global`v^5*Global`w^3 - 2*FeynCalc`CA^2*Global`v^5*Global`w^3 + 
          2*FeynCalc`CA^2*Global`v^4*Global`w^4 - 4*Global`v^5*Global`w^4 + 
          2*FeynCalc`CA^2*Global`v^5*Global`w^4)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`v]*(System`Cos[Global`phiA]*
           System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
           System`Sin[Global`\[Phi]h]))/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*(-1 + Global`v*Global`w)^3) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
         (1 - Global`v^2 + 8*Global`w - 7*FeynCalc`CA^2*Global`w - 
          3*Global`v*Global`w - 2*Global`v^2*Global`w + 
          FeynCalc`CA^2*Global`v^2*Global`w + 3*Global`v^3*Global`w - 
          11*Global`v*Global`w^2 + 10*FeynCalc`CA^2*Global`v*Global`w^2 - 
          4*Global`v^2*Global`w^2 + 4*FeynCalc`CA^2*Global`v^2*Global`w^2 + 
          6*Global`v^3*Global`w^2 - 2*FeynCalc`CA^2*Global`v^3*Global`w^2 - 
          3*Global`v^4*Global`w^2 - Global`v^2*Global`w^3 + 
          FeynCalc`CA^2*Global`v^2*Global`w^3 + 6*Global`v^3*Global`w^3 - 
          6*FeynCalc`CA^2*Global`v^3*Global`w^3 - 4*Global`v^4*Global`w^3 + 
          3*FeynCalc`CA^2*Global`v^4*Global`w^3 + Global`v^5*Global`w^3 + 
          7*Global`v^3*Global`w^4 - 6*FeynCalc`CA^2*Global`v^3*Global`w^4 - 
          FeynCalc`CA^2*Global`v^4*Global`w^4 + Global`v^5*Global`w^4 - 
          FeynCalc`CA^2*Global`v^5*Global`w^4 - 2*Global`v^4*Global`w^5 + 
          3*FeynCalc`CA^2*Global`v^4*Global`w^5 - 2*Global`v^5*Global`w^5 + 
          FeynCalc`CA^2*Global`v^5*Global`w^5)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`w]*(System`Cos[Global`phiA]*
           System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
           System`Sin[Global`\[Phi]h]))/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`w*(-1 + Global`v*Global`w)^3) - 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
         (3 - 3*FeynCalc`CA^2 + Global`v^2 - FeynCalc`CA^2*Global`v^2 + 
          11*Global`w - 4*FeynCalc`CA^2*Global`w - 21*Global`v*Global`w + 
          9*FeynCalc`CA^2*Global`v*Global`w + 7*Global`v^2*Global`w - 
          3*FeynCalc`CA^2*Global`v^2*Global`w - 5*Global`v^3*Global`w + 
          2*FeynCalc`CA^2*Global`v^3*Global`w + 7*Global`v*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v*Global`w^2 - 8*Global`v^2*Global`w^2 + 
          4*FeynCalc`CA^2*Global`v^2*Global`w^2 + 5*Global`v^3*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v^3*Global`w^2 + 2*Global`v^2*Global`w^3 - 
          FeynCalc`CA^2*Global`v^2*Global`w^3 - 2*Global`v^3*Global`w^3 + 
          FeynCalc`CA^2*Global`v^3*Global`w^3)*FeynFacet`\[Alpha]s^3*
         System`Log[Global`w]*(System`Cos[Global`phiA]*
           System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
           System`Sin[Global`\[Phi]h]))/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*(-1 + Global`w)*(-1 + Global`v*Global`w)) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
         (2 - 5*Global`v + 6*Global`v^2 - 3*Global`v^3 + 
          5*Global`v*Global`w - 13*Global`v^2*Global`w + 
          4*FeynCalc`CA^2*Global`v^2*Global`w + 9*Global`v^3*Global`w - 
          2*FeynCalc`CA^2*Global`v^3*Global`w - 5*Global`v^4*Global`w + 
          2*FeynCalc`CA^2*Global`v^4*Global`w + 7*Global`v^2*Global`w^2 + 
          3*FeynCalc`CA^2*Global`v^2*Global`w^2 - 4*Global`v^3*Global`w^2 - 
          FeynCalc`CA^2*Global`v^3*Global`w^2 + 5*Global`v^4*Global`w^2 - 
          2*FeynCalc`CA^2*Global`v^4*Global`w^2 - 2*Global`v^3*Global`w^3 + 
          3*FeynCalc`CA^2*Global`v^3*Global`w^3 - 2*Global`v^4*Global`w^3 + 
          FeynCalc`CA^2*Global`v^4*Global`w^3)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v*Global`w]*(System`Cos[Global`phiA]*
           System`Cos[Global`\[Phi]h] + System`Sin[Global`phiA]*
           System`Sin[Global`\[Phi]h]))/(4*FeynCalc`CA^3*System`Pi*Global`s^2*
         (-1 + Global`v)^2*Global`v^2*(-1 + Global`w)*Global`w) + 
       ((-1 + FeynCalc`CA)*(1 + FeynCalc`CA)*Global`STa*Global`STh*
         (1 - Global`v + Global`v*Global`w)*(-2 + Global`v + Global`v^2 - 
          3*Global`v*Global`w + Global`v^2*Global`w - FeynCalc`CA^2*
           Global`v^2*Global`w - 2*Global`v^2*Global`w^2 + 
          FeynCalc`CA^2*Global`v^2*Global`w^2)*FeynFacet`\[Alpha]s^3*
         System`Log[1 - Global`v + Global`v*Global`w]*
         (System`Cos[Global`phiA]*System`Cos[Global`\[Phi]h] + 
          System`Sin[Global`phiA]*System`Sin[Global`\[Phi]h]))/
        (4*FeynCalc`CA^3*System`Pi*Global`s^2*(-1 + Global`v)*Global`v^2*
         (-1 + Global`w)*Global`w)|>|>, "DensityConvention" -> 
  "E_c d sigma/d^(D-1)p_c", "DistributionBasis" -> 
  <|"Variable" -> Global`w, "Endpoint" -> 1, "Interval" -> {0, 1}, 
   "Distance" -> 1 - Global`w|>, "PlusConvention" -> "At each axis, \
PlusCoefficients[k] multiplies [Log[Distance]^k/Distance]_+ on Interval, with \
subtraction at Endpoint. For DistributionBasis[Axes], delta/plus/regular \
values repeat recursively in the listed axis order."|>
