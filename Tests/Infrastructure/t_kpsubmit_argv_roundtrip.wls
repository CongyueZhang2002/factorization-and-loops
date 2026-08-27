#!/usr/bin/env wolframscript
(* Live KernelPool companion to t_kpsubmit_wrapper.sh.  Submit with the exact
   argv listed below; no package load or worker kernel is required. *)

expected = {"plain", "quote\"arg", "back\\slash", "cr\rvalue",
  "line1\nline2", "tab\tvalue", "close*)comment"};
actual = Rest[$ScriptCommandLine];
Which[
  actual === {},
    (* The ordinary all-tests runner supplies no custom argv. *)
    Print["KPSUBMIT ZERO-ARGV BASELINE PASS"];
    Exit[0],
  SameQ[actual, expected],
    Print["KPSUBMIT ARGV ROUNDTRIP PASS"];
    Exit[0],
  True,
    Print["KPSUBMIT ARGV ROUNDTRIP FAIL: ", InputForm[actual]];
    Exit[1]];
