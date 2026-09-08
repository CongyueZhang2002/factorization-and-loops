(* Independent oracle comparison for the A2/A3/A4 acceptance runs:
   gauge, residue matrices, alphabet of each optimized run vs the frozen
   oracle, plus an exact re-check of the Pfaffian residuals from the
   fixture (not trusting the stored flag). No FeynFacet load. *)
B = "/home/maxzhang/factorization-and-loops/ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BenchmarkStripBackends/";
rd[f_] := Block[{$ContextPath = {"System`", "Global`"}, $Context = "Global`"}, Get[f]];
tog[m_] := Map[Cancel[Together[#]] &, m, {-1}];
residualsZeroQ[fixture_, sol_] := Module[{e, c, bb, vars, eps, G, alph, R, dlog, res},
  {e, c, bb} = fixture["Strip"]; vars = fixture["Variables"]; eps = fixture["Regulator"];
  G = sol["Gauge"]; alph = sol["Alphabet"]; R = sol["ResidueMatrices"];
  dlog = Table[Together[D[Log[alph[[a]]], vars[[mu]]]], {a, Length[alph]}, {mu, 2}];
  res = Table[D[G, vars[[mu]]] - eps (e[[mu]].G - G.c[[mu]]) - bb[[mu]] +
     eps Sum[R[[a]] dlog[[a, mu]], {a, Length[alph]}], {mu, 2}];
  AllTrue[Flatten[Map[Together, res, {3}]], # === 0 &]];
cmp[label_, oracleFile_, runFile_, fixtureFile_] := Module[{o, r, fx, os, rs, t0},
  o = rd[oracleFile]["BackendResult"]; r = rd[runFile]["BackendResult"]; fx = rd[fixtureFile];
  Print["== ", label];
  Print["  status oracle/run: ", o["Status"], " / ", r["Status"], "  CertificationMode run: ", Lookup[r, "CertificationMode", Missing[]]];
  Print["  primes oracle/run: ", Length[o["Primes"]], " / ", Length[r["Primes"]], "   sample counts run: ", Lookup[r, "PrimeSampleCounts", Missing[]]];
  Print["  support run: ", Lookup[r, "GaugeSupportCount", Missing[]], "  shell: ", Lookup[r, "SelectedSupportShell", Missing[]], "  backend per sample: ", Lookup[r, "RegulatorSampling", Missing[]]];
  Print["  Alphabet SameQ: ", o["Alphabet"] === r["Alphabet"]];
  Print["  ResidueMatrices SameQ: ", o["ResidueMatrices"] === r["ResidueMatrices"]];
  Print["  Gauge SameQ (raw): ", o["Gauge"] === r["Gauge"], "   Gauge equal after Together: ", tog[o["Gauge"] - r["Gauge"]] === ConstantArray[0, Dimensions[o["Gauge"]]]];
  Print["  NormalizationColumns SameQ: ", o["NormalizationColumns"] === r["NormalizationColumns"]];
  t0 = AbsoluteTime[];
  Print["  exact Pfaffian residuals of RUN gauge recomputed from fixture: ", residualsZeroQ[fx, r], "  (", Round[AbsoluteTime[] - t0, 0.1], " s)"]];
cmp["CF254 (9,6): new probe order vs frozen M0 census", B <> "frozen_M0/census_run/result_M0_CF254_9_6_FiniteField.wl", "<this directory>/result_PROBEORDER_CF254_9_6_FiniteField.wl", B <> "fixtures/fixture_CF254_9_6.wl"];
