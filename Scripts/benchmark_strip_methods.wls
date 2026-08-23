(* Strip-method benchmark (user question 2026-08-21: "Do we really need
   Maple (is it better than finite-field at all)? how does canonica
   numerator compare against finite field?").  One LANE per run, serial
   over the given strip files, one row per strip in OUTDIR/<lane>.tsv:
     C  dlog recognition + CANONICA numerator-degree ladder 0-3 (120 s
        each, serial, no Maple);
     M  Maple residue construction alone, capped at the production budget
        (300 s);
     F  finite-field affine solve alone (1 kernel, fresh artifacts).
   Every solved result is re-verified by VerifyEpsFormStrip (dlog-form
   certificate) before it counts as solved.
   Usage: benchmark_strip_methods.wls LANE OUTDIR FILE... *)
root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
lane = $ScriptCommandLine[[2]]; outdir = $ScriptCommandLine[[3]];
files = Drop[$ScriptCommandLine, 3];
(* read the strips BEFORE anything loads CANONICA (context trap) *)
rd[f_] := Block[{$ContextPath = {"System`", "Global`"}, $Context = "Global`"}, Get[f]];
records = rd /@ files;
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
(* CANONICA parallelises internally and would launch 8 subkernels (measured
   23:27: lane C held 8 kernels); the sector route runs it serial, so does
   this benchmark -- one kernel per lane is the comparison *)
If[lane === "C",
  FeynFacet`Private`epsFormStripLoadCanonica[];
  CANONICA`$ComputeParallel = False; CANONICA`Private`$ComputeParallel = False];
If[! DirectoryQ[outdir], CreateDirectory[outdir, CreateIntermediateDirectories -> True]];
tsv = FileNameJoin[{outdir, lane <> ".tsv"}];
If[! FileExistsQ[tsv], Export[tsv, "strip\tdims\tlane\tsolved\tmethod\tseconds\tnote\n", "Text"]];
row[a__] := (s = OpenAppend[tsv]; WriteString[s, StringRiffle[ToString /@ {a}, "\t"], "\n"]; Close[s]);
(* residues of the transformed coupling bbar + eps (e G - G c) - dG as
   constants (rational in eps) per letter: exact linear solve at random
   rational points, then the certificate decides *)
benchmarkResidues[r_, gauge_, alphabet_] := Module[{e, c, bbar, vars, eps, tr, dlog, pts, unknowns, eqs, sol, dims},
  {e, c, bbar} = r["Strip"]; vars = r["Variables"]; eps = r["Regulator"];
  dims = Dimensions[bbar[[1]]];
  tr = Table[Map[Together, bbar[[mu]] + eps (e[[mu]] . gauge - gauge . c[[mu]]) - D[gauge, vars[[mu]]], {2}], {mu, 2}];
  dlog = Table[Together[D[Log[alphabet[[a]]], vars[[mu]]]], {a, Length[alphabet]}, {mu, 2}];
  SeedRandom[7]; pts = Table[Thread[vars -> RandomInteger[{3, 10^6}, 2]/RandomInteger[{10^6, 10^7}, 2]], {2 Length[alphabet] + 3}];
  Table[Module[{u = Array[Unique["rr"] &, Length[alphabet]], lin},
    eqs = Flatten[Table[(tr[[mu, i, j]] - Sum[u[[a]] dlog[[a, mu]], {a, Length[alphabet]}]) /. pt, {mu, 2}, {pt, pts}]];
    lin = Quiet[Solve[Thread[Together[eqs] == 0], u]];
    (* VerifyEpsFormStrip writes the coupling as eps Sum_a R_a dlog phi_a:
       the fitted coefficients are eps R_a *)
    If[lin === {} || ! ListQ[lin], Indeterminate, Together[(u /. First[lin] /. Thread[u -> 0])/eps]]],
    {i, dims[[1]]}, {j, dims[[2]]}] // Transpose[#, {2, 3, 1}] &];
norm[r_] := Module[{eps = Global`eps, x = Global`x, y = Global`y},
  <|"Strip" -> r["Strip"], "Variables" -> r["Variables"], "Regulator" -> r["Regulator"]|>];
Do[
  Module[{r = norm[records[[i]]], name = FileBaseName[files[[i]]], dims, t0, res, ok, method, seconds, note = ""},
    dims = Dimensions[r["Strip"][[3, 1]]];
    Print["== ", lane, " ", name, " dims ", dims];
    t0 = AbsoluteTime[];
    res = Switch[lane,
      "C", FeynFacet`SolveEpsFormStrip[r["Strip"], r["Variables"], r["Regulator"],
        "UseMaple" -> False, "CANONICAKernels" -> 1, "Tag" -> name, "Verbose" -> False],
      "M", FeynFacet`SolveResidueRationalGauge[r["Strip"], r["Variables"], r["Regulator"],
        "ResidueKernels" -> 1, "TimeLimit" -> 300, "Tag" -> name,
        "ScratchDirectory" -> FileNameJoin[{outdir, "maple_" <> name}], "Verbose" -> False],
      "F", FeynFacet`SolveEpsFormStripFiniteField[r, "KernelCount" -> 1, "Verbose" -> False,
        "ArtifactDirectory" -> FileNameJoin[{outdir, "ff_" <> name}]]];
    seconds = Round[AbsoluteTime[] - t0, 0.1];   (* the solve only *)
    ok = AssociationQ[res] && KeyExistsQ[res, "Gauge"];
    method = If[AssociationQ[res], Lookup[res, "Method", lane], "failed"];
    (* CANONICA's result carries the gauge but no residue matrices: derive
       them from the transformed coupling (exact linear solve of the
       dlog ansatz at sample points), so every lane gets the same
       dlog-form certificate *)
    If[ok && ! KeyExistsQ[res, "ResidueMatrices"],
      res = Join[res, <|"ResidueMatrices" -> benchmarkResidues[r, res["Gauge"], res["Alphabet"]]|>]];
    (* independent dlog-form certificate, OUTSIDE the timer, one kernel *)
    If[ok,
      Module[{v = FeynFacet`VerifyEpsFormStrip[r, res, "KernelCount" -> 1]},
        ok = TrueQ[v["DLogFormCertified"]];
        note = "dlog=" <> ToString[ok] <> " epsfreeres=" <> ToString[v["ResiduesEpsFree"]] <>
          " verify=" <> ToString[Round[Lookup[v, "ExactCheckSeconds", 0], 0.1]] <> "s"]];
    If[AssociationQ[res] && KeyExistsQ[res, "Status"], note = note <> " status=" <> ToString[res["Status"]]];
    row[name, dims, lane, ok, method, seconds, note];
    Print["   -> ", ok, " ", method, " ", seconds, " s ", note]],
  {i, Length[files]}];
Print["LANE ", lane, " DONE"];
