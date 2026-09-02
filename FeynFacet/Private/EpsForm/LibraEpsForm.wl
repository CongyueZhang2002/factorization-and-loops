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
  libraEpsFormFermatCompatibleQ
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
