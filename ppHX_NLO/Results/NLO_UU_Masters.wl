<|"Format" -> "FeynFacet-NLOMasters", "FormatVersion" -> 1, 
 "Created" -> "Wed 12 Aug 2026 02:03:04", 
 "Conventions" -> <|"Measure" -> "GLI = Int d^d ke delta+(ke^2) \
delta+((ka+kb-kc-ke)^2) / (D2 D3), no 2Pi factors", 
   "Dimension" -> Global`D -> 4 - 2*Global`Epsilon, 
   "Variables" -> <|v -> "2 ka.kc / 2 ka.kb", w -> "2 kb.kc / 2 ka.kb", 
     "Region" -> "0 < v, 0 < w, v + w < 1"|>, "ScaleRestoration" -> "multiply \
by (2 ka.kb)^h, h = -Epsilon (volume) or -2-Epsilon (four-index masters)", 
   "SoftConnection" -> 
    "F(1,1;1-e;z) = c1 F(1,1;2+e;1-z) + c2 (1-z)^(-1-e) z^e", 
   "VolumeNormalization" -> (2^(-2 + 2*Global`Epsilon)*
      Pi^((3 - 2*Global`Epsilon)/2))/Gamma[(3 - 2*Global`Epsilon)/2]|>, 
 "Masters" -> <|GLI[TopologyF10C10N1, {1, 0, 0, 1}] -> 
    <|"Exact" -> (2^(-2 + 2*Global`Epsilon)*Pi^((3 - 2*Global`Epsilon)/2))/
       ((1 - v - w)^Global`Epsilon*Gamma[(3 - 2*Global`Epsilon)/2]), 
     "SoftBranches" -> {<|"Exponent" -> -Global`Epsilon, 
        "Coefficient" -> (2^(-2 + 2*Global`Epsilon)*
           Pi^((3 - 2*Global`Epsilon)/2))/Gamma[(3 - 2*Global`Epsilon)/
            2]|>}|>, GLI[TopologyF10C10N1, {1, 1, 1, 1}] -> 
    <|"Exact" -> -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
         Pi^(3/2 - Global`Epsilon)*Hypergeometric2F1[1, 1, 
          1 - Global`Epsilon, (w*(-1 + v + w))/((-1 + w)*(v + w))])/
        (Global`Epsilon*(1 - w)*(1 - v - w)^Global`Epsilon*(v + w)*
         Gamma[(3 - 2*Global`Epsilon)/2])), "CrossRatio" -> 
      (w*(-1 + v + w))/((-1 + w)*(v + w)), "PrefactorR" -> 
      1/((1 - w)*(v + w)), "Normalization" -> 
      -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
         Pi^(3/2 - Global`Epsilon))/(Global`Epsilon*
         Gamma[(3 - 2*Global`Epsilon)/2])), "SoftBranches" -> 
      {<|"Exponent" -> -Global`Epsilon, "Coefficient" -> 
         -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
            Pi^(3/2 - Global`Epsilon)*Hypergeometric2F1[1, 1, 
             1 - Global`Epsilon, (w*(-1 + v + w))/((-1 + w)*(v + w))])/
           (Global`Epsilon*(1 - w)*(v + w)*Gamma[(3 - 2*Global`Epsilon)/
              2]))|>}|>, GLI[TopologyF10C2N2, {1, 1, 1, 1}] -> 
    <|"Exact" -> -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
         Pi^(3/2 - Global`Epsilon)*Hypergeometric2F1[1, 1, 
          1 - Global`Epsilon, -(v/((-1 + w)*(v + w)))])/
        (Global`Epsilon*(1 - w)*(1 - v - w)^Global`Epsilon*(v + w)*
         Gamma[(3 - 2*Global`Epsilon)/2])), "CrossRatio" -> 
      -(v/((-1 + w)*(v + w))), "PrefactorR" -> 1/((1 - w)*(v + w)), 
     "Normalization" -> -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
         Pi^(3/2 - Global`Epsilon))/(Global`Epsilon*
         Gamma[(3 - 2*Global`Epsilon)/2])), "SoftBranches" -> 
      {<|"Exponent" -> -Global`Epsilon, "Coefficient" -> 
         -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
            Pi^(3/2 - Global`Epsilon)*Gamma[-1 - Global`Epsilon]*
            Gamma[1 - Global`Epsilon]*Hypergeometric2F1[1, 1, 
             2 + Global`Epsilon, 1 + v/((-1 + w)*(v + w))])/
           (Global`Epsilon*(1 - w)*(v + w)*Gamma[(3 - 2*Global`Epsilon)/2]*
            Gamma[-Global`Epsilon]^2))|>, 
       <|"Exponent" -> -1 - 2*Global`Epsilon, "Coefficient" -> 
         -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
            Pi^(3/2 - Global`Epsilon)*(-(v/((-1 + w)*(v + w))))^
             Global`Epsilon*(-(w/((-1 + w)*(v + w))))^(-1 - Global`Epsilon)*
            Gamma[1 - Global`Epsilon]*Gamma[1 + Global`Epsilon])/
           (Global`Epsilon*(1 - w)*(v + w)*Gamma[(3 - 2*Global`Epsilon)/
              2]))|>}|>, GLI[TopologyF10C4N2, {1, 1, 1, 1}] -> 
    <|"Exact" -> -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
         Pi^(3/2 - Global`Epsilon)*Hypergeometric2F1[1, 1, 
          1 - Global`Epsilon, (v*(-1 + v + w))/((-1 + v)*(v + w))])/
        (Global`Epsilon*(1 - v)*(1 - v - w)^Global`Epsilon*(v + w)*
         Gamma[(3 - 2*Global`Epsilon)/2])), "CrossRatio" -> 
      (v*(-1 + v + w))/((-1 + v)*(v + w)), "PrefactorR" -> 
      1/((1 - v)*(v + w)), "Normalization" -> 
      -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
         Pi^(3/2 - Global`Epsilon))/(Global`Epsilon*
         Gamma[(3 - 2*Global`Epsilon)/2])), "SoftBranches" -> 
      {<|"Exponent" -> -Global`Epsilon, "Coefficient" -> 
         -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
            Pi^(3/2 - Global`Epsilon)*Hypergeometric2F1[1, 1, 
             1 - Global`Epsilon, (v*(-1 + v + w))/((-1 + v)*(v + w))])/
           (Global`Epsilon*(1 - v)*(v + w)*Gamma[(3 - 2*Global`Epsilon)/
              2]))|>}|>, GLI[TopologyF10C4N3, {1, 1, 1, 1}] -> 
    <|"Exact" -> (2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
        Pi^(3/2 - Global`Epsilon)*Hypergeometric2F1[1, 1, 1 - Global`Epsilon, 
         (v*w)/((-1 + v)*(-1 + w))])/(Global`Epsilon*(1 - v)*(1 - w)*
        (1 - v - w)^Global`Epsilon*Gamma[(3 - 2*Global`Epsilon)/2]), 
     "CrossRatio" -> (v*w)/((-1 + v)*(-1 + w)), "PrefactorR" -> 
      1/((1 - v)*(1 - w)), "Normalization" -> 
      (2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
        Pi^(3/2 - Global`Epsilon))/(Global`Epsilon*
        Gamma[(3 - 2*Global`Epsilon)/2]), "SoftBranches" -> 
      {<|"Exponent" -> -Global`Epsilon, "Coefficient" -> 
         (2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
           Pi^(3/2 - Global`Epsilon)*Gamma[-1 - Global`Epsilon]*
           Gamma[1 - Global`Epsilon]*Hypergeometric2F1[1, 1, 
            2 + Global`Epsilon, 1 - (v*w)/((-1 + v)*(-1 + w))])/
          (Global`Epsilon*(1 - v)*(1 - w)*Gamma[(3 - 2*Global`Epsilon)/2]*
           Gamma[-Global`Epsilon]^2)|>, 
       <|"Exponent" -> -1 - 2*Global`Epsilon, "Coefficient" -> 
         (2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
           Pi^(3/2 - Global`Epsilon)*(1/((-1 + v)*(-1 + w)))^
            (-1 - Global`Epsilon)*((v*w)/((-1 + v)*(-1 + w)))^Global`Epsilon*
           Gamma[1 - Global`Epsilon]*Gamma[1 + Global`Epsilon])/
          (Global`Epsilon*(1 - v)*(1 - w)*Gamma[(3 - 2*Global`Epsilon)/
             2])|>}|>, GLI[TopologyF10C5N2, {1, 1, 1, 1}] -> 
    <|"Exact" -> -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
         Pi^(3/2 - Global`Epsilon)*Hypergeometric2F1[1, 1, 
          1 - Global`Epsilon, -(w/((-1 + v)*(v + w)))])/
        (Global`Epsilon*(1 - v)*(1 - v - w)^Global`Epsilon*(v + w)*
         Gamma[(3 - 2*Global`Epsilon)/2])), "CrossRatio" -> 
      -(w/((-1 + v)*(v + w))), "PrefactorR" -> 1/((1 - v)*(v + w)), 
     "Normalization" -> -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
         Pi^(3/2 - Global`Epsilon))/(Global`Epsilon*
         Gamma[(3 - 2*Global`Epsilon)/2])), "SoftBranches" -> 
      {<|"Exponent" -> -Global`Epsilon, "Coefficient" -> 
         -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
            Pi^(3/2 - Global`Epsilon)*Gamma[-1 - Global`Epsilon]*
            Gamma[1 - Global`Epsilon]*Hypergeometric2F1[1, 1, 
             2 + Global`Epsilon, 1 + w/((-1 + v)*(v + w))])/
           (Global`Epsilon*(1 - v)*(v + w)*Gamma[(3 - 2*Global`Epsilon)/2]*
            Gamma[-Global`Epsilon]^2))|>, 
       <|"Exponent" -> -1 - 2*Global`Epsilon, "Coefficient" -> 
         -((2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
            Pi^(3/2 - Global`Epsilon)*(-(v/((-1 + v)*(v + w))))^
             (-1 - Global`Epsilon)*(-(w/((-1 + v)*(v + w))))^Global`Epsilon*
            Gamma[1 - Global`Epsilon]*Gamma[1 + Global`Epsilon])/
           (Global`Epsilon*(1 - v)*(v + w)*Gamma[(3 - 2*Global`Epsilon)/
              2]))|>}|>, GLI[TopologyF10C5N3, {1, 1, 1, 1}] -> 
    <|"Exact" -> (2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
        Pi^(3/2 - Global`Epsilon)*Hypergeometric2F1[1, 1, 1 - Global`Epsilon, 
         (1 - v - w)/((-1 + v)*(-1 + w))])/(Global`Epsilon*(1 - v)*(1 - w)*
        (1 - v - w)^Global`Epsilon*Gamma[(3 - 2*Global`Epsilon)/2]), 
     "CrossRatio" -> (1 - v - w)/((-1 + v)*(-1 + w)), 
     "PrefactorR" -> 1/((1 - v)*(1 - w)), "Normalization" -> 
      (2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
        Pi^(3/2 - Global`Epsilon))/(Global`Epsilon*
        Gamma[(3 - 2*Global`Epsilon)/2]), "SoftBranches" -> 
      {<|"Exponent" -> -Global`Epsilon, "Coefficient" -> 
         (2^(-1 + 2*Global`Epsilon)*(-1 + 2*Global`Epsilon)*
           Pi^(3/2 - Global`Epsilon)*Hypergeometric2F1[1, 1, 
            1 - Global`Epsilon, (1 - v - w)/((-1 + v)*(-1 + w))])/
          (Global`Epsilon*(1 - v)*(1 - w)*Gamma[(3 - 2*Global`Epsilon)/
             2])|>}|>|>, "DifferentialSystem" -> 
  <|"Basis" -> {GLI[TopologyF10C10N1, {1, 0, 0, 1}], 
     GLI[TopologyF10C10N1, {1, 1, 1, 1}], GLI[TopologyF10C2N2, {1, 1, 1, 1}], 
     GLI[TopologyF10C4N2, {1, 1, 1, 1}], GLI[TopologyF10C4N3, {1, 1, 1, 1}], 
     GLI[TopologyF10C5N2, {1, 1, 1, 1}], GLI[TopologyF10C5N3, {1, 1, 1, 1}]}, 
   "Av" -> {{-(Global`Epsilon/(-1 + v + w)), 0, 0, 0, 0, 0, 0}, 
     {(-2*(1 - 2*Global`Epsilon))/(v*(-1 + v + w)*(v + w)), 
      (-2 - 2*Global`Epsilon)/(2*v), 0, 0, 0, 0, 0}, 
     {(2*(1 - 2*Global`Epsilon))/(v*(-1 + v + w)*(v + w)), 0, 
      (-2*Global`Epsilon - 6*v + (4 - 2*Global`Epsilon)*v + 4*w - 
        (4 - 2*Global`Epsilon)*w)/(2*v*(-1 + v + w)), 0, 0, 0, 0}, 
     {(2*(-1 + 2*Global`Epsilon - 6*v + 2*(4 - 2*Global`Epsilon)*v - 3*w + 
         (4 - 2*Global`Epsilon)*w))/((-1 + v)*v*(-1 + v + w)*(v + w)), 0, 0, 
      Global`Epsilon/v, 0, 0, 0}, {(2*(1 - 2*Global`Epsilon))/
       ((-1 + v)*v*(-1 + v + w)), 0, 0, 0, 
      (-2*Global`Epsilon - 6*v + (4 - 2*Global`Epsilon)*v + 4*w - 
        (4 - 2*Global`Epsilon)*w)/(2*v*(-1 + v + w)), 0, 0}, 
     {(-2*(-1 + 2*Global`Epsilon - 6*v + 2*(4 - 2*Global`Epsilon)*v - 3*w + 
         (4 - 2*Global`Epsilon)*w))/((-1 + v)*v*(-1 + v + w)*(v + w)), 0, 0, 
      0, 0, (2 + 2*Global`Epsilon - 16*v + 3*(4 - 2*Global`Epsilon)*v - 6*w + 
        (4 - 2*Global`Epsilon)*w)/(2*v*(-1 + v + w)), 0}, 
     {(-2*(1 - 2*Global`Epsilon))/((-1 + v)*v*(-1 + v + w)), 0, 0, 0, 0, 0, 
      (-2 - 2*Global`Epsilon)/(2*v)}}, 
   "Aw" -> {{-(Global`Epsilon/(-1 + v + w)), 0, 0, 0, 0, 0, 0}, 
     {(2*(-1 + 2*Global`Epsilon - 3*v + (4 - 2*Global`Epsilon)*v - 6*w + 
         2*(4 - 2*Global`Epsilon)*w))/((-1 + w)*w*(-1 + v + w)*(v + w)), 
      Global`Epsilon/w, 0, 0, 0, 0, 0}, 
     {(-2*(-1 + 2*Global`Epsilon - 3*v + (4 - 2*Global`Epsilon)*v - 6*w + 
         2*(4 - 2*Global`Epsilon)*w))/((-1 + w)*w*(-1 + v + w)*(v + w)), 0, 
      (2 + 2*Global`Epsilon - 6*v + (4 - 2*Global`Epsilon)*v - 16*w + 
        3*(4 - 2*Global`Epsilon)*w)/(2*w*(-1 + v + w)), 0, 0, 0, 0}, 
     {(-2*(1 - 2*Global`Epsilon))/(w*(-1 + v + w)*(v + w)), 0, 0, 
      (-2 - 2*Global`Epsilon)/(2*w), 0, 0, 0}, 
     {(2*(1 - 2*Global`Epsilon))/((-1 + w)*w*(-1 + v + w)), 0, 0, 0, 
      (-2*Global`Epsilon + 4*v - (4 - 2*Global`Epsilon)*v - 6*w + 
        (4 - 2*Global`Epsilon)*w)/(2*w*(-1 + v + w)), 0, 0}, 
     {(2*(1 - 2*Global`Epsilon))/(w*(-1 + v + w)*(v + w)), 0, 0, 0, 0, 
      (-2*Global`Epsilon + 4*v - (4 - 2*Global`Epsilon)*v - 6*w + 
        (4 - 2*Global`Epsilon)*w)/(2*w*(-1 + v + w)), 0}, 
     {(-2*(1 - 2*Global`Epsilon))/((-1 + w)*w*(-1 + v + w)), 0, 0, 0, 0, 0, 
      (-2 - 2*Global`Epsilon)/(2*w)}}, "Convention" -> 
    "dI/dv = Av.I, dI/dw = Aw.I at 2 ka.kb = 1"|>, 
 "Validation" -> <|"FlatnessResidual" -> 0, "NumericAgreement" -> "two-angle \
phase-space integration, 5 (v,w,eps) points: ratios 1 within numeric \
precision (1e-18 at eps=-0.15, 1e-4 at eps=-0.05)", 
   "CrossImplementation" -> "shared family TopologyF10C2N2 matches the \
independent Codex evaluation after the (2Pi)^(d-2) measure conversion"|>|>
