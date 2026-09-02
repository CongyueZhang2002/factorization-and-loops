(* Whole-family epsilon-form construction with Libra.

   The caller supplies the rational chart.  This file performs the exact
   pullback, composes every certified diagonal-block transformation with
   that chart, assembles the block-lower-triangular family connection,
   and lets Libra remove the remaining off-diagonal epsilon dependence.
   No process table, kinematic chamber, or branch choice enters here.
*)

(* Public symbols are Clear'ed, not ClearAll'ed: ClearAll also removes
   the usage messages FeynFacet.m defines before loading this file
   (found 2026-08-21). Clear still drops their definitions, so re-Get of
   this file stays clean. *)
Clear[LibraFamilyEpsForm];
ClearAll[
  libraEpsFormLoadBackend,
  libraEpsFormFermatCompatibleQ,
  $masterTransportLibraLoaded,
  masterTransportLoadLibra
];

LibraFamilyEpsForm::system =
  "The input must contain a square, equally sized pair of connection matrices under \"Av\" and \"Aw\".";
LibraFamilyEpsForm::chart =
  "The supplied chart could not be pulled back and composed with every diagonal block.";
LibraFamilyEpsForm::backend =
  "Libra or its requested exact Fermat algebra engine could not be initialized.";
LibraFamilyEpsForm::rounds =
  "FuchsifyRounds and AlternatingRounds must be positive integers.";

Options[LibraFamilyEpsForm] = {
  "SourceVariables" -> Automatic,
  "Regulator" -> Automatic,
  "Blocks" -> Automatic,
  "FormDirectory" -> None,
  "ConicChartRoute" -> Automatic,
  "UseFermat" -> Automatic,
  "TimeLimit" -> 1500,
  "FuchsifyRounds" -> 3,
  "AlternatingRounds" -> 2,
  "Verbose" -> False
};


libraEpsFormFermatCompatibleQ[expr_] := FreeQ[expr,
  _Root | _AlgebraicNumber |
  Power[_, power_Rational /; Denominator[power] =!= 1] |
  _Log | _Sin | _Cos | _Tan | _ArcSin | _ArcCos | _ArcTan |
  _Exp | _Complex | Pi | E | I];

libraEpsFormLoadBackend[requested_] := Module[
  {useFermat, fermaticaFile, fermatExecutable, libraLoaded, testVariable},
  fermaticaFile = FileNameJoin[{$feynFacetAddonRoot, "Addon",
    "Mathematica_Addon", "Fermatica", "source", "Fermatica.wl"}];
  fermatExecutable = FileNameJoin[{$feynFacetAddonRoot, "Addon",
    "Other_Addon", "Fermat", "fer64"}];
  useFermat = Replace[requested,
    Automatic -> (FileExistsQ[fermaticaFile] && FileExistsQ[fermatExecutable])];
  If[! MemberQ[{True, False}, useFermat],
    Return[<|"Status" -> "UseFermatInvalid"|>]];
  If[useFermat,
    If[DownValues[Fermatica`FTogether] === {},
      Quiet[Get[fermaticaFile], General::shdw]];
    If[DownValues[Fermatica`FTogether] === {},
      Return[<|"Status" -> "FermaticaNotLoaded"|>]];
    Fermatica`$FermatCMD = fermatExecutable;
    ClearAll["Global`FeynFacetFermatCheckVariable"];
    testVariable = Symbol["Global`FeynFacetFermatCheckVariable"];
    If[! TrueQ[Together[
        Fermatica`FTogether[(testVariable^2 - 1)/(testVariable - 1)] -
          (1 + testVariable)] === 0],
      Return[<|"Status" -> "FermatArithmeticFailed"|>]]];
  libraLoaded = masterTransportLoadLibra[$feynFacetAddonRoot];
  If[libraLoaded =!= True,
    Return[<|"Status" -> "LibraNotLoaded"|>]];
  (* the flag is GLOBAL in Libra: a backend requested WITHOUT Fermat must
     also switch it off, otherwise an earlier Fermat-enabled call leaves
     it on and the caller's declined choice is silently overridden
     (2026-08-24) *)
  If[useFermat,
    Libra`$LibraUseFermat = True;
    If[! TrueQ[Libra`$LibraUseFermat],
      Return[<|"Status" -> "LibraFermatNotEnabled"|>]],
    Libra`$LibraUseFermat = False];
  <|"Status" -> "OK", "UseFermat" -> useFermat,
    "Options" -> If[useFermat, {Fermatica`UseFermat -> True}, {}]|>
];

(* Retired route (overhaul 2026-09-02, goal 1): the whole-family Libra
   eps-form construction lives in FeynFacet/Private_Backup/LibraEpsForm.wl
   and is not loaded; this file keeps only the Libra backend loader used
   by FamilyRegulatorFactor.  The production family completion is the
   finite-field off-diagonal route of Scripts/family_epsform_sector.wls
   followed by FactorFamilyRegulatorDependence and CertifyFamilyEpsilonForm. *)
LibraFamilyEpsForm[___] := <|"Status" -> "RouteRetired",
  "Route" -> "LibraFamilyEpsForm",
  "Replacement" -> "the per-sector eps-form driver script (Scripts/) + FactorFamilyRegulatorDependence",
  "Code" -> "FeynFacet/Private_Backup/LibraEpsForm.wl"|>;


(* The Libra loader (moved here verbatim from Transport/MasterTransport.wl,
   layer pass 2026-09-02): the diagonal-block route
   (DiagonalBlockEpsForm.wl, EpsForm) is its production caller and
   Transport loads after EpsForm; MasterTransport.wl's Libra backend
   still calls it. *)
$masterTransportLibraLoaded = False;

masterTransportLoadLibra[root_String] := Module[{file, path},
  If[TrueQ[$masterTransportLibraLoaded] &&
     Length[DownValues[Libra`PexpExpansion]] > 0, Return[True]];
  file = FileNameJoin[{root, "Addon", "Mathematica_Addon", "Libra", "Source", "Libra.m"}];
  If[! FileExistsQ[file], Return[$Failed]];
  path = $ContextPath;
  Quiet[Get[file], {General::shdw}];
  $ContextPath = path;
  (* WL 14.2: Libra's option forwarding can emit OptionValue::optnf in
     Projector and OptionValue::nodef in NewDSystem/HistoryAppend inside
     Check.  The messages make those calls return the wrong object or
     abort despite admissible input.  Do not suppress Libra's banner by
     rebinding Print while loading: that separately rewrites Libra's
     option key Print and also makes NewDSystem abort. *)
  Off[OptionValue::optnf];
  Off[OptionValue::nodef];
  (* B1/B2: Libra ships no derivative rule for its own II, and the
     derivative tag for a list first argument is Derivative[{0,..},1,0]
     with one 0 per index.  We never differentiate II directly -- words
     are converted to TransportWord at once -- but the rule is installed
     anyway so that a caller reaching into the raw output is not silently
     handed an unevaluated Derivative. *)
  Quiet[
    Unprotect[Libra`II];
    Derivative[iw_List, 1, 0][Libra`II][word_List, x_, x0_] :=
      If[word === {}, 0, Libra`II[Rest[word], x, x0]/(x - First[word])];
  ];
  $masterTransportLibraLoaded = Length[DownValues[Libra`PexpExpansion]] > 0;
  If[TrueQ[$masterTransportLibraLoaded], True, $Failed]
];
