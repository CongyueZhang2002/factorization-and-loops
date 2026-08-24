(* The light-cone basis names {nb, n, xhat, yhat} are reserved Global
   symbols.  2026-08-23: the eps-form sector driver assigned nb/n as
   counters, so on a REUSED pool subkernel a FACET reload built
   BuildGlobalBasis[{34, 44, xhat, yhat}] -> $Failed (BuildBasis::length
   in cert_CF385.log).  Pins: (1) a fresh load installs the basis;
   (2) a reload after the historical pollution self-heals (LoadFACET
   clears own-values of the four names first); (3) the production-loop
   scripts assign no reserved kinematics/chart name (string-stripped
   static scan). *)
root = DirectoryName[DirectoryName[$InputFileName]];
pass = 0; fail = 0;
check[label_, ok_] := (If[TrueQ[ok], pass++; Print["OK   ", label], fail++; Print["FAIL ", label]]);
loader = FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}];
Get[loader];
basisOK[] := Global`GlobalBasis === {Global`nb, Global`n, Global`xhat, Global`yhat} &&
  AllTrue[Global`GlobalBasis, MatchQ[#, _Symbol] &];
check["fresh load installs the basis", basisOK[]];
(* the historical pollution *)
Global`nb = 34; Global`n = 44;
quietReload := Quiet[Get[loader], {General::shdw, FeynCalc`FeynCalc::tfadvice}];
quietReload;
check["reload after nb/n pollution self-heals", basisOK[]];
Global`xhat = 7;
quietReload;
check["reload after xhat pollution self-heals", basisOK[]];
(* static scan of the production-loop scripts *)
stripStrings[text_String] := Module[{chars = Characters[text], out = {}, i = 1, inString = False},
  While[i <= Length[chars],
    Which[
      inString && chars[[i]] === "\\", i += 2,
      inString && chars[[i]] === "\"", inString = False; i++,
      inString, i++,
      chars[[i]] === "\"", inString = True; AppendTo[out, " "]; i++,
      True, AppendTo[out, chars[[i]]]; i++]];
  StringJoin[out]];
reserved = {"eps", "Eps", "epsilon", "Epsilon", "ep", "v", "w", "x", "y",
  "u", "t", "tau", "s", "p", "sqrtLambda", "gli", "n", "nb", "xhat", "yhat"};
productionScripts = {"family_epsform_sector.wls", "certify_family_epsform_record.wls"};
Do[Module[{code = stripStrings[Import[FileNameJoin[{root, "Scripts", f}], "Text"]], bad},
  bad = Select[reserved, StringContainsQ[code,
    RegularExpression["(?<![\\w`$])" <> # <> "\\s*=(?![=!])"]] &];
  check["no reserved-name assignment in " <> f, bad === {}];
  If[bad =!= {}, Print["     offending names: ", bad]]], {f, productionScripts}];
Print["t_global_basis_reload: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
