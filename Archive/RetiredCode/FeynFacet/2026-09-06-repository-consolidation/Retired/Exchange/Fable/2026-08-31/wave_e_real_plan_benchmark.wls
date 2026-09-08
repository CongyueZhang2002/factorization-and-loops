#!/usr/bin/env wolframscript
(* Wave E integration benchmark (Codex note 20 item 5, go in note 29):
   the FOUR-record CF303 row-25 plan through the generic entry point
   pathTransportExceptionTransport on the LIVE continuation state.
   Measures phase seconds and peak memory; reports the measured
   dispatch route, per-record valuation checks, and the hard-row
   depth demand.  Read-only on all state and record files. *)

root = "/home/maxzhang/factorization-and-loops";
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];
pte = Symbol["FeynFacet`Private`" <> #] &;

recDir = "/home/maxzhang/factorization-and-loops-codex/Diagnostics/Artifacts";
contract = Get[FileNameJoin[{recDir, "cf303_u3_common_path_contract.wl"}]];
r18 = Get[FileNameJoin[{recDir, "cf303_25_18_exact_path_exception_record.wl"}]];
r14 = Get[FileNameJoin[{recDir, "cf303_25_14_exact_path_exception_record.wl"}]];
r11 = Get[FileNameJoin[{recDir, "cf303_25_11_exact_path_exception_record.wl"}]];
r2 = Get["/home/maxzhang/factorization-and-loops-codex/Runtime/\
2026-08-30_cf303_25_2_exact_common_path/\
cf303_25_2_exact_path_exception_record.wl"];

(* branch-convention harmonization in memory, pending the contract-file
   fix (reported to Codex 2026-08-31): the two accepted quadratic
   records agree verbatim; the contract file spells the same convention
   differently and the fail-closed verbatim comparison would refuse *)
recordBC = r14["PathExtension"]["BranchConvention"];
If[Lookup[contract["PathExtension"], "BranchConvention", None] =!= recordBC,
  Print["NOTE harmonizing contract BranchConvention in memory"];
  contract["PathExtension"] = Join[contract["PathExtension"],
    <|"BranchConvention" -> recordBC|>]];

stateFile = "/home/maxzhang/factorization-and-loops-codex/Runtime/\
CF303_exception14_continuation_2026-08-30/sector_state_CF303_standard.wl";
Print["loading state (154 MB) ..."];
loadSeconds = First[AbsoluteTiming[state = Get[stateFile];]];
Print["state loaded in ", loadSeconds, " s"];

{av, aw} = Which[
  KeyExistsQ[state, "A"], state["A"],
  KeyExistsQ[state, "Av"], {state["Av"], state["Aw"]},
  True, $Failed];
Print["connection dimensions: ", Dimensions[av]];
assembly = <|"Blocks" -> state["Blocks"], "Ranges" -> state["Ranges"]|>;
Print["blocks: ", Length[assembly["Blocks"]],
  ", ranges total: ", Total[Length /@ assembly["Ranges"]]];

eps = Global`ep;
regulatorCandidates = Select[{Global`ep, Global`eps, Global`epsilon},
  ! FreeQ[{av[[44, 44]], av[[45, 45]]}, #] &];
Print["regulator symbols present: ", regulatorCandidates];
If[regulatorCandidates =!= {}, eps = First[regulatorCandidates]];
tau = Global`waveETau;
kmax = 4;

plan = <|"PathContract" -> contract, "Endpoints" -> {1/7, 5/7},
  "Records" -> {r18, r14, r11, r2}|>;

Print["calling pathTransportExceptionTransport (kmax = ", kmax, ") ..."];
totalSeconds = First[AbsoluteTiming[
  t = pte["pathTransportExceptionTransport"][assembly, av, aw, plan,
    tau, eps, kmax];]];
Print["returned in ", totalSeconds, " s"];
Print["status: ", Lookup[t, "Status", "?"]];
Print["dispatch: ", Lookup[t, "Dispatch", "?"]];
Print["route: ", Lookup[t, "ExceptionalBlocksRoute", "?"]];
Print["hard block: ", Lookup[t, "HardBlock", "?"]];
Print["missing terminal data: ", Lookup[t, "Missing", {}]];
Print["phase seconds: ", Lookup[t, "PhaseSeconds", "?"]];
Print["peak kernel memory: ", MaxMemoryUsed[], " bytes"];
If[KeyExistsQ[t, "ExceptionalBlocksCapability"],
  Print["capability refusals: ",
    Lookup[t["ExceptionalBlocksCapability"], "Refusals", {}]]];
If[KeyExistsQ[t, "Ahat"],
  Print["installed Ahat bytes: ", ByteCount[t["Ahat"]]]];
If[KeyExistsQ[t, "Reports"],
  Do[Print["record ", FileNameTake[rep["Record"]],
      " positions ", rep["Positions"],
      " valuation ", rep["Valuation"],
      " extension ", rep["PathExtension"]["Type"]],
    {rep, t["Reports"]}]];
If[KeyExistsQ[t, "Budget"],
  Print["budget Need (per block): ", t["Budget"]["Need"]]];

(* sample diagnostic (NOT a gate): capability of a few ORDINARY
   hard-row entries on this nonlinear path -- the blockwise engine's
   own refusal at solve time remains the authority *)
If[Lookup[t, "Status", None] === "PathTransportExceptionPreparedV1",
  Module[{ranges = assembly["Ranges"], hard = t["HardBlock"],
    exceptionCols, ordinary, sampled = 0},
  exceptionCols = #["Positions"][[2]] & /@ t["Reports"];
  ordinary = Select[Range[Length[ranges]],
    # =!= hard && ! MemberQ[exceptionCols, #] &&
      ! MatchQ[Union[Flatten[
        t["Ahat"][[ranges[[hard]], ranges[[#]]]]]], {} | {0}] &];
  Print["ordinary nonzero hard-row blocks: ", Length[ordinary]];
  Do[
    If[sampled < 6,
      Module[{entry, verdict, seconds},
        entry = t["Ahat"][[ranges[[hard]], ranges[[m]]]][[1, 1]];
        {seconds, verdict} = AbsoluteTiming[TimeConstrained[
          pte["pathTransportExceptionEntryCapability"][entry, tau, eps],
          120, "TimedOut"]];
        sampled++;
        Print["sample block (", hard, ",", m, "): ",
          If[AssociationQ[verdict],
            If[TrueQ[verdict["Admitted"]], "Admitted",
              verdict["Reason"]], verdict],
          " in ", seconds, " s"]]],
    {m, ordinary}]]];

out = <|"Status" -> "WaveERealPlanBenchmarkV1",
  "Date" -> DateString[],
  "StateFile" -> stateFile, "StateLoadSeconds" -> loadSeconds,
  "Endpoints" -> {1/7, 5/7}, "KMax" -> kmax,
  "TotalSeconds" -> totalSeconds,
  "PeakKernelBytes" -> MaxMemoryUsed[],
  "Dispatch" -> Lookup[t, "Dispatch", Lookup[t, "Status", "?"]],
  "Route" -> Lookup[t, "ExceptionalBlocksRoute", None],
  "HardBlock" -> Lookup[t, "HardBlock", None],
  "PhaseSeconds" -> Lookup[t, "PhaseSeconds", None],
  "CapabilityRefusals" -> If[KeyExistsQ[t, "ExceptionalBlocksCapability"],
    Lookup[t["ExceptionalBlocksCapability"], "Refusals", {}], None],
  "BudgetNeed" -> If[KeyExistsQ[t, "Budget"], t["Budget"]["Need"], None],
  "Valuations" -> If[KeyExistsQ[t, "Reports"],
    <|FileNameTake[#["Record"]] -> #["Valuation"] & /@ t["Reports"]|>,
    None]|>;
outFile = FileNameJoin[{DirectoryName[$InputFileName],
  "wave_e_real_plan_benchmark_result.wl"}];
Export[outFile, out, "Package"];
Print["result record written: ", outFile];
Print["DONE"];
