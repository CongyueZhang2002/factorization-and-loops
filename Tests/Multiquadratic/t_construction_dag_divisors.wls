#!/usr/bin/env wolframscript
(* THE PRESERVED DEFERRED DAG AND THE DIVISOR METADATA (round-2 wave
   item 8; Codex review 2.2).

   THE DEFECT.  blockEquationDeferredForcing returned
   KeyDrop[preparation, "Records"]: the expression DAG this file exists
   to build was thrown away at the public boundary, so every downstream
   consumer had to work from the huge materialized expression the DAG
   had just avoided.  Codex 2.2 asks for the DAG to be preserved and for
   a SECOND, separate product beside it -- explicit divisor,
   Galois-orbit and multiplicity metadata for alphabet and
   gauge-denominator construction -- because the arithmetic may
   rationalize or use compact norm denominators while the ALPHABET still
   needs the original algebraic divisor.

   ACCEPTANCE CRITERIA, stated before the run.

   The preserved DAG.
   G1  The public result carries a versioned "DeferredDAG" whose Records
       are exactly the preparation's records, with the ABI version, the
       source fingerprint and the term count.  (Pre-fix: absent.)
   G2  Its measured byte size is recorded, so a future byte-bound
       decision has a number instead of a guess.
   G3  A finite "DAGByteLimit" below that size drops the records and SAYS
       SO ("Retained" -> False) rather than silently truncating.
   G4  The preserved DAG still reproduces each forcing entry: summing a
       record's terms symbolically equals the materialized entry.  A
       preserved-but-wrong DAG would pass G1-G3.

   The divisor metadata.
   G5  On a RATIONAL block the metadata lists each polar factor once,
       with the highest multiplicity it reaches in any single entry --
       the per-factor maximum, never a sum across entries.
   G6  On an ALGEBRAIC block the algebraic denominator factors are kept
       as algebraic factors (NOT rationalized away), each with its exact
       Galois orbit and orbit norm.
   G7  The recorded norm of an algebraic factor is exactly the product
       over its distinct conjugates, and it is free of radicals.
   G8  The two products are independent: switching the divisor metadata
       off leaves the DAG, and switching the DAG off leaves the
       metadata. *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

pass = 0; fail = 0;
check[label_, ok_] := If[TrueQ[ok], pass++; Print["OK   ", label],
  fail++; Print["FAIL ", label]];
report[label_, value_] := Print["     ", label, ": ", Short[value, 8]];
mq[name_String] := Symbol["FeynFacet`Private`" <> name];

{forcingOf, dagRecord, divisorMetadata, sourceExpression} =
 mq /@ {"blockEquationDeferredForcing", "blockEquationDeferredDAGRecord",
   "blockEquationDeferredDivisorMetadata",
   "blockEquationDeferredSourceExpression"};

Clear[gx, gy, ge];

(* a 4x4 block-lower-triangular connection with three blocks, so the
   truncated row formula has one feeder *)
ranges = {{1}, {2}, {3, 4}};
buildConnection[entryFunction_] := Table[
  Table[If[i < j, 0, entryFunction[mu, i, j]], {i, 4}, {j, 4}], {mu, 2}];

rationalEntry[mu_, i_, j_] :=
  (ge + mu + i gx + j gy)/((1 + gx)^If[mu === 1, 2, 1] (1 - gy) (i + j));
rationalConnection = buildConnection[rationalEntry];
solved = <|2 -> {{(1 + gx)/(1 - gy)}, {gy/(1 + gx)}}|>;

result = forcingOf[rationalConnection, ranges, 3, 1, solved, {gx, gy}, ge];
check["the deferred forcing is built on the rational block",
  Lookup[result, "Status", None] === "OK"];

(* ---- G1 / G2: the preserved DAG ---- *)
dag = Lookup[result, "DeferredDAG", None];
check["G1 the public result carries a versioned preserved DAG",
  AssociationQ[dag] && dag["Schema"] === "BlockEquationDeferredDAGV1" &&
    TrueQ[dag["Retained"]] && ListQ[dag["Records"]] &&
    dag["Records"] =!= {} &&
    IntegerQ[dag["TermCount"]] && dag["TermCount"] >= 1 &&
    StringQ[dag["SourceFingerprint"]]];
report["G1 DAG", KeyTake[dag, {"Schema", "ABIVersion", "RecordCount",
  "TermCount", "Bytes", "Retained", "Dimensions"}]];
check["G2 the DAG's measured byte size is recorded",
  IntegerQ[dag["Bytes"]] && dag["Bytes"] > 0];

(* ---- G3: the byte bound says so ---- *)
bounded = forcingOf[rationalConnection, ranges, 3, 1, solved, {gx, gy}, ge,
  "DAGByteLimit" -> 1];
check["G3 a byte limit below the measured size drops the records and says so",
  AssociationQ[Lookup[bounded, "DeferredDAG", None]] &&
    bounded["DeferredDAG"]["Retained"] === False &&
    MissingQ[bounded["DeferredDAG"]["Records"]] &&
    IntegerQ[bounded["DeferredDAG"]["Bytes"]]];

(* ---- G4: the preserved DAG still reproduces the forcing ---- *)
preparationLike = Join[KeyTake[dag, {"Variables", "Regulator", "Dimensions"}],
  <|"Records" -> dag["Records"]|>];
dimensions = dag["Dimensions"];
check["G4 every preserved record's term sum equals the materialized entry",
  AllTrue[Flatten[Table[{mu, i, j},
      {mu, dimensions[[1]]}, {i, dimensions[[2]]}, {j, dimensions[[3]]}], 2],
    Function[target,
      TrueQ[Together[sourceExpression[preparationLike, target] -
        result["Forcing"][[target[[1]], target[[2]], target[[3]]]]] === 0]]]];

(* ---- G5: multiplicities are per-factor maxima ---- *)
metadata = Lookup[result, "DivisorMetadata", None];
check["G5 the divisor metadata is produced",
  AssociationQ[metadata] &&
    metadata["Schema"] === "BlockEquationDivisorMetadataV1" &&
    metadata["Status"] === "OK"];
report["G5 rational factors", Lookup[metadata, "RationalFactors", None]];
rationalFactorOf[target_] := SelectFirst[metadata["RationalFactors"],
  TrueQ[Together[#1["Factor"] - target] === 0] ||
    TrueQ[Together[#1["Factor"] + target] === 0] &, Missing["NoFactor"]];
check["G5 the factor (1 + x) is listed once, at its highest single-entry \
multiplicity",
  ! MissingQ[rationalFactorOf[1 + gx]] &&
    rationalFactorOf[1 + gx]["MaximumMultiplicity"] >= 2];
check["G5 each factor appears exactly once in the list",
  DuplicateFreeQ[Expand[Together[#1]] & /@
    Lookup[metadata["RationalFactors"], "Factor", {}]]];

(* ---- G6 / G7: an algebraic block ---- *)
delta = 1 + gx;
algebraicEntry[mu_, i_, j_] :=
  (ge + mu + i gx + j gy)/((2 + gx + Sqrt[delta])^If[mu === 1, 2, 1] (i + j));
algebraicConnection = buildConnection[algebraicEntry];
algebraicSolved = <|2 -> {{(1 + gx)/(1 - gy)}, {gy/(1 + gx)}}|>;
algebraicResult = forcingOf[algebraicConnection, ranges, 3, 1, algebraicSolved,
  {gx, gy}, ge,
  "DivisorRoots" -> {<|"Root" -> Sqrt[delta], "RootSquare" -> delta|>}];
check["the deferred forcing is built on the algebraic block",
  Lookup[algebraicResult, "Status", None] === "OK"];
algebraicMetadata = Lookup[algebraicResult, "DivisorMetadata", None];
report["G6 algebraic factors", Lookup[algebraicMetadata, "AlgebraicFactors",
  None]];
check["G6 the algebraic denominator factor is KEPT algebraic, not \
rationalized away",
  AssociationQ[algebraicMetadata] &&
    Length[Lookup[algebraicMetadata, "AlgebraicFactors", {}]] >= 1 &&
    AnyTrue[Lookup[algebraicMetadata, "AlgebraicFactors", {}],
      ! FreeQ[#1["Factor"], Sqrt[delta]] &]];
algebraicFactor = SelectFirst[
  Lookup[algebraicMetadata, "AlgebraicFactors", {}],
  ! FreeQ[#1["Factor"], Sqrt[delta]] &, Missing["NoAlgebraicFactor"]];
check["G6 it carries a Galois orbit of size two",
  ! MissingQ[algebraicFactor] && algebraicFactor["OrbitSize"] === 2];
check["G7 its recorded norm is the exact product over the orbit and is \
free of radicals",
  ! MissingQ[algebraicFactor] &&
    FreeQ[algebraicFactor["Norm"], Sqrt[delta]] &&
    TrueQ[Together[algebraicFactor["Norm"] -
      Expand[(2 + gx)^2 - delta]] === 0]];
report["G7 norm", Lookup[algebraicFactor, "Norm", None]];
check["G7 the orbit list reproduces the two conjugates",
  ! MissingQ[algebraicFactor] &&
    Length[algebraicFactor["Orbit"]] === 2 &&
    AnyTrue[algebraicFactor["Orbit"],
      TrueQ[Together[#1 - (2 + gx + Sqrt[delta])] === 0] &] &&
    AnyTrue[algebraicFactor["Orbit"],
      TrueQ[Together[#1 - (2 + gx - Sqrt[delta])] === 0] &]];

(* ---- G8: the two products are independent ---- *)
noMetadata = forcingOf[rationalConnection, ranges, 3, 1, solved, {gx, gy}, ge,
  "DivisorMetadata" -> False];
noDAG = forcingOf[rationalConnection, ranges, 3, 1, solved, {gx, gy}, ge,
  "PreserveDAG" -> False];
check["G8 the DAG survives with the metadata switched off",
  TrueQ[Lookup[noMetadata, "DeferredDAG", <||>]["Retained"]] &&
    Lookup[noMetadata, "DivisorMetadata", <||>]["Status"] ===
      "DivisorMetadataSkipped"];
check["G8 the metadata survives with the DAG switched off",
  Lookup[noDAG, "DeferredDAG", <||>]["Retained"] === False &&
    Lookup[noDAG, "DivisorMetadata", <||>]["Status"] === "OK"];

Print["t_construction_dag_divisors: ", pass, " OK, ", fail, " FAIL"];
Exit[If[fail === 0, 0, 1]];
