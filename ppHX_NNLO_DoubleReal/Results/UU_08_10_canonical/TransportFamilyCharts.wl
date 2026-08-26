(* Family -> transport-chart assignments for the ppHX NNLO double-real
   inventory (project data; moved out of FeynFacet/Private/TransportCharts.wl
   2026-08-23 -- the package is general, this table is not).  Values are
   either a catalogued chart name (TransportChartCatalog[]) or, for the
   three-root families with no global rational parametrization, the exact
   root-square list in the source variables v, w.  Loaded by campaign
   scripts through FeynFacet`TransportFamilyChartRegister /
   TransportFamilyChartLoad; the package ships with an EMPTY table. *)
<|
  (* lambda1 = (1-v-w)^2 - 4 v w only *)
  "CF13" -> "Kallen1", "CF20" -> "Kallen1", "CF24" -> "Kallen1", "CF26" -> "Kallen1",
  "CF230" -> "Kallen1", "CF258" -> "Kallen1", "CF264" -> "Kallen1", "CF88" -> "Kallen1",
  "CF98" -> "Kallen1", "CF384" -> "Kallen1", "CF388" -> "Kallen1", "CF407" -> "Kallen1",
  "CF50" -> "Kallen1", "CF56" -> "Kallen1",
  (* lambda2 = lambda1(-v,w) only (incl. v<->w members of lambda3 classes) *)
  "CF18" -> "Kallen2", "CF21" -> "Kallen2", "CF23" -> "Kallen2", "CF33" -> "Kallen2",
  "CF53" -> "Kallen2", "CF57" -> "Kallen2", "CF91" -> "Kallen2", "CF97" -> "Kallen2",
  "CF413" -> "Kallen2", "CF416" -> "Kallen2", "CF420" -> "Kallen2",
  (* lambda3 = lambda1(v,-w) only *)
  "CF248" -> "Kallen3", "CF253" -> "Kallen3",
  (* 4 v + w^2 and its v<->w image *)
  "CF260" -> "Q4a", "CF48" -> "Q4b", "CF52" -> "Q4b",
  (* 1 - 4 v w *)
  "CF299" -> "Bilinear115",
  (* two roots *)
  "CF232" -> "Kallen12", "CF236" -> "Kallen12", "CF240" -> "Kallen12", "CF319" -> "Kallen12",
  "CF321" -> "Kallen12", "CF385" -> "Kallen12", "CF408" -> "Kallen12",
  "CF249" -> "Kallen13", "CF254" -> "Kallen13", "CF265" -> "Kallen13",
  "CF226" -> "Kallen23", "CF231" -> "Kallen23", "CF305" -> "Kallen23",
  (* Legacy chart aliases (moved out of FeynFacet/Private/FamilyEpsForm.wl
     2026-08-23, generality pass A3): early census records store a
     descriptive substitution string instead of the catalog name.  The map
     is exact -- the alias was itself generated from the catalog
     substitution it names.  Records carrying it:
     FamilyEpsForms{,Certified}/family_epsform_CF20.wl, _CF24.wl,
     family_epsform_CF230_offdiag_2026-08-17.wl. *)
  "v = x y, w = (1-x)(1-y)" -> <|"ChartAlias" -> "Kallen1"|>,
  (* three roots: retain the exact multiquadratic field in an identity
     frame; no global rational parametrization is assumed *)
  "CF259" -> <|"RootSquares" -> {
    (1 - Global`v - Global`w)^2 - 4 Global`v Global`w,
    (1 - Global`v + Global`w)^2 + 4 Global`v Global`w,
    4 Global`v + Global`w^2}|>,
  "CF300" -> <|"RootSquares" -> {
    (1 + Global`v - Global`w)^2 + 4 Global`v Global`w,
    (1 - Global`v + Global`w)^2 + 4 Global`v Global`w,
    1 - 4 Global`v Global`w}|>,
  "CF303" -> <|"RootSquares" -> {
    (1 + Global`v - Global`w)^2 + 4 Global`v Global`w,
    (1 - Global`v + Global`w)^2 + 4 Global`v Global`w,
    1 - 4 Global`v Global`w}|>
|>
