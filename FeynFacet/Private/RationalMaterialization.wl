(* Exact rational-DAG materialization with a native sparse-polynomial
   compaction seam.

   Together is usually the right canonicalizer for a rational operand, but
   it has a severe tail when a rational chart has introduced tens of
   thousands of repeated negative powers.  On a preserved hard operand,
   Together took 300.9 s.  A structural fraction walk followed by
   FLINT reduction only after a local numerator exceeds 1 MiB took 87.7 s and
   returned the same 4.12 MiB / 16-factor canonical operand.

   This module is deliberately narrow.  It accepts only rational arithmetic
   over an explicitly declared polynomial ring.  An unsupported node, a
   missing native backend, or any native refusal returns $Failed; the caller
   then uses the historical Together implementation for that operand.  No
   additional production identity check is introduced: block acceptance and
   the final family certificate remain the mathematical checks. *)

Begin["FeynFacet`Private`"];

ClearAll[
  rationalMaterializationFLINTBinary,
  rationalMaterializationRationalQ,
  rationalMaterializationExpressionSymbols,
  rationalMaterializationSymbols,
  rationalMaterializationCanonicalQuotientValue,
  rationalMaterializationTogetherValue,
  rationalMaterializationPrimitiveRows,
  rationalMaterializationWriteRows,
  rationalMaterializationReadInteger,
  rationalMaterializationReadRows,
  rationalMaterializationRowsPolynomial,
  rationalMaterializationCancelledFactors,
  rationalMaterializationFLINTReduce,
  rationalMaterializationCollect,
  rationalMaterializationCanonicalValue
];

(* Operand size and cheap structural counts do not predict Together's tail:
   preserved siblings with the same 21 KiB / 25-inverse shape took
   either 0.2 s or about 300 s.  A short exact Together probe therefore keeps
   its fast cases; only a measured tail enters the collector. *)
$rationalMaterializationProbeSeconds = 1.;
$rationalMaterializationReductionThreshold = 2^20;
$rationalMaterializationNativeTimeout = 120;

rationalMaterializationFLINTBinary[] := With[{file = FileNameJoin[{
    $feynFacetDirectory, "Backends", "flint", "bin",
    "flint_mpoly_gcd"}]}, If[FileExistsQ[file], file, None]];

rationalMaterializationRationalQ[value_] :=
  MatchQ[value, _Integer | _Rational];

rationalMaterializationExpressionSymbols[expression_] := SortBy[
  DeleteDuplicates[Cases[Unevaluated[expression],
    symbol_Symbol /; Context[symbol] =!= "System`", {0, Infinity},
    Heads -> True]], {Context[#], SymbolName[#]} &];
rationalMaterializationSymbols[expression_, Automatic] :=
  rationalMaterializationExpressionSymbols[expression];
rationalMaterializationSymbols[expression_, symbols_List] := Module[
  {declared, occurring},
  If[! AllTrue[symbols,
      Head[#] === Symbol && Context[#] =!= "System`" &], Return[$Failed]];
  declared = DeleteDuplicates[symbols];
  occurring = rationalMaterializationExpressionSymbols[expression];
  If[AllTrue[occurring, MemberQ[declared, #] &], declared, $Failed]
];
rationalMaterializationSymbols[_, _] := $Failed;

(* Canonical pair used both by a successful fast Together probe and by the
   historical unbounded fallback. *)
rationalMaterializationCanonicalQuotientValue[q_] := Module[
  {numerator = Numerator[q], denominator = Denominator[q], factorList,
   content, factors},
  If[TrueQ[denominator === 1], Return[{numerator, <||>}]];
  factorList = Quiet[Check[FactorList[denominator], $Failed]];
  If[! ListQ[factorList], Return[$Failed]];
  content = Times @@ ((First[#]^Last[#]) & /@
    Select[factorList, NumericQ[First[#]] &]);
  factors = Association[(First[#] -> Last[#]) & /@
    Select[factorList, ! NumericQ[First[#]] &]];
  {If[TrueQ[content === 1], numerator, Cancel[numerator/content]], factors}
];

rationalMaterializationTogetherValue[expression_] :=
  rationalMaterializationCanonicalQuotientValue[Together[expression]];

(* CoefficientRules is the measured representation boundary: once Wolfram
   has exposed a sparse polynomial, FLINT's exact GCD and two divisions are
   subsecond even on the hard nodes.  Clear rational coefficient content so
   the wire format remains integer-only.  The second return value is the
   exact rational scalar relating the wire polynomial to the input. *)
rationalMaterializationPrimitiveRows[polynomial_, symbols_List] := Module[
  {rules, coefficients, scale, integers, content},
  rules = Quiet[Check[CoefficientRules[polynomial, symbols], $Failed]];
  If[! ListQ[rules] || rules === {} ||
      ! AllTrue[Last /@ rules, rationalMaterializationRationalQ],
    Return[$Failed]];
  coefficients = Last /@ rules;
  scale = Fold[LCM, 1, Denominator /@ coefficients];
  integers = scale coefficients;
  content = Fold[GCD, 0, Abs[integers]];
  If[content === 0, Return[$Failed]];
  {MapThread[Join[#1, {#2/content}] &,
      {First /@ rules, integers}], content/scale}
];

rationalMaterializationReadInteger[text_String] := Which[
  StringMatchQ[text, DigitCharacter ..], FromDigits[text],
  StringStartsQ[text, "-"] && StringLength[text] > 1 &&
      StringMatchQ[StringDrop[text, 1], DigitCharacter ..],
    -FromDigits[StringDrop[text, 1]],
  True, $Failed
];

rationalMaterializationWriteRows[file_String, rows_List,
    variableCount_Integer] := Module[{stream, body, result = $Failed},
  (* ExportString[..., "TSV"] quotes signed and sufficiently large integer
     fields.  FFMG1 deliberately accepts only bare decimal tokens. *)
  body = Quiet[Check[StringRiffle[
      (StringRiffle[ToString[#, InputForm] & /@ #, "\t"] &) /@ rows,
      "\n"], $Failed]];
  If[! StringQ[body], Return[$Failed]];
  stream = Quiet[Check[OpenWrite[file], $Failed]];
  If[Head[stream] =!= OutputStream, Return[$Failed]];
  result = Quiet[Check[
    WriteString[stream, "FFMG1P1\t", ToString[variableCount], "\t",
      ToString[Length[rows]], "\n", body,
      If[rows === {}, "", "\n"]]; file, $Failed]];
  Quiet[Close[stream]];
  result
];

rationalMaterializationReadRows[file_String, variableCount_Integer,
    magic_String] := Module[{lines, header, tokens, rows, declaredRows},
  lines = Quiet[Check[Import[file, "Lines"], $Failed]];
  If[! ListQ[lines] || lines === {}, Return[$Failed]];
  header = StringSplit[First[lines], "\t"];
  If[Length[header] =!= 3 || First[header] =!= magic ||
      rationalMaterializationReadInteger[header[[2]]] =!= variableCount,
    Return[$Failed]];
  declaredRows = rationalMaterializationReadInteger[header[[3]]];
  If[! IntegerQ[declaredRows] || declaredRows =!= Length[lines] - 1,
    Return[$Failed]];
  If[declaredRows === 0, Return[{}]];
  tokens = StringSplit[#, "\t"] & /@ Rest[lines];
  If[! AllTrue[tokens, Length[#] === variableCount + 1 &],
    Return[$Failed]];
  rows = Map[rationalMaterializationReadInteger, tokens, {2}];
  If[! FreeQ[rows, $Failed], $Failed, rows]
];

rationalMaterializationRowsPolynomial[rows_List, symbols_List] := Total[
  (Last[#] Times @@ MapThread[Power, {symbols, Most[#]}]) & /@ rows];

(* Relate FLINT's primitive/positive GCD associate to the factor keys already
   carried by the denominator map.  The residual must be a rational unit.
   Multiplying the quotient by it is essential: discarding a -1 associate,
   for example, would change the represented rational function. *)
rationalMaterializationCancelledFactors[gcd_, factors_Association,
    symbols_List] := Module[{work = gcd, cancelled = <||>, exponent,
    reduction},
  KeyValueMap[Function[{factor, maximum},
    exponent = 0;
    While[exponent < maximum,
      reduction = Quiet[Check[
        PolynomialReduce[work, {factor}, symbols], $Failed]];
      If[! MatchQ[reduction, {{_}, _}] ||
          ! TrueQ[Last[reduction] === 0], Break[]];
      work = First[First[reduction]];
      exponent++];
    If[exponent > 0, cancelled[factor] = exponent]], factors];
  If[! rationalMaterializationRationalQ[work],
    $Failed, {cancelled, work}]
];

(* Native request contract.  The companion binary verifies internally that
   its GCD divides the integer numerator exactly.  Wolfram maps that
   exact GCD back to the pre-factored denominator keys; no duplicate symbolic
   equality test is performed here. *)
rationalMaterializationFLINTReduce[request_Association] := Module[
  {binary, symbols, numerator, relevant, candidate, numeratorData,
   candidateData, directory, numeratorFile, candidateFile, quotientFile,
   gcdFile, command, process, quotientRows, gcdRows, quotient, gcd,
   cancellation, result = $Failed},
  binary = rationalMaterializationFLINTBinary[];
  symbols = Lookup[request, "Symbols", {}];
  numerator = Lookup[request, "Numerator", $Failed];
  relevant = Lookup[request, "RelevantFactors", <||>];
  candidate = Lookup[request, "Candidate", $Failed];
  If[! StringQ[binary] || ! ListQ[symbols] || symbols === {} ||
      ! AssociationQ[relevant] || relevant === <||> ||
      candidate === $Failed, Return[$Failed]];
  numeratorData = rationalMaterializationPrimitiveRows[numerator, symbols];
  candidateData = rationalMaterializationPrimitiveRows[candidate, symbols];
  If[! MatchQ[numeratorData,
        {_List, scalar_ /; rationalMaterializationRationalQ[scalar]}] ||
      ! MatchQ[candidateData,
        {_List, scalar_ /; rationalMaterializationRationalQ[scalar]}],
    Return[$Failed]];
  directory = FileNameJoin[{$TemporaryDirectory,
      "FeynFacetMPolyReduce_" <> StringReplace[CreateUUID[], "-" -> ""]}];
  Quiet[Check[CreateDirectory[directory,
    CreateIntermediateDirectories -> True], Return[$Failed]]];
  numeratorFile = FileNameJoin[{directory, "numerator.tsv"}];
  candidateFile = FileNameJoin[{directory, "candidate.tsv"}];
  quotientFile = FileNameJoin[{directory, "quotient.tsv"}];
  gcdFile = FileNameJoin[{directory, "gcd.tsv"}];
  result = Catch[
    If[rationalMaterializationWriteRows[numeratorFile,
          First[numeratorData], Length[symbols]] === $Failed ||
        rationalMaterializationWriteRows[candidateFile,
          First[candidateData], Length[symbols]] === $Failed,
      Throw[$Failed]];
    command = {"/usr/bin/timeout", "--signal=TERM", "--kill-after=5s",
      ToString[$rationalMaterializationNativeTimeout] <> "s", binary,
      numeratorFile, candidateFile, quotientFile, gcdFile, "1"};
    process = Quiet[Check[RunProcess[command], $Failed]];
    If[! AssociationQ[process] || process["ExitCode"] =!= 0 ||
        ! FileExistsQ[quotientFile] || ! FileExistsQ[gcdFile],
      Throw[$Failed]];
    quotientRows = rationalMaterializationReadRows[
      quotientFile, Length[symbols], "FFMG1Q1"];
    gcdRows = rationalMaterializationReadRows[
      gcdFile, Length[symbols], "FFMG1G1"];
    If[! ListQ[quotientRows] || ! ListQ[gcdRows], Throw[$Failed]];
    quotient = Last[numeratorData] *
      rationalMaterializationRowsPolynomial[quotientRows, symbols];
    gcd = rationalMaterializationRowsPolynomial[gcdRows, symbols];
    cancellation = rationalMaterializationCancelledFactors[
      gcd, relevant, symbols];
    If[! MatchQ[cancellation,
        {_Association, unit_ /; rationalMaterializationRationalQ[unit]}],
      Throw[$Failed]];
    <|"Status" -> "OK",
      "Numerator" -> Last[cancellation] quotient,
      "CancelledFactors" -> First[cancellation]|>
  ];
  Quiet[Check[DeleteDirectory[directory, DeleteContents -> True], Null]];
  result
];

(* Recursive exact fraction collection.  A pair {n, factors, compactQ}
   represents n/Product[f^e].  Small local reductions are deliberately
   deferred; their noncompact status propagates upward.  A mandatory final
   reduction prevents a deferred pair from entering phase-two expansion. *)
rationalMaterializationCollect[expression_, polynomialSymbols_List,
    reducer_, threshold_Integer] := Module[
  {factorCache = <||>, reductionCache = <||>, failureTag = Unique["rmFail"],
   fail, mapProduct, mapScale, mapMerge, mapDifference, mapSubsetQ,
   factorData, topItems, visibleMultiplicity, stripOneFactor,
   stripVisibleFactors, structuralReduce, relevantPlusFactors,
   applyReducer, normalize, pair},

  fail[status_String] := Throw[status, failureTag];
  mapProduct[map_Association] := Times @@ KeyValueMap[#1^#2 &, map];
  mapScale[map_Association, exponent_Integer] := Association @ Select[
    KeyValueMap[#1 -> exponent #2 &, map], Last[#] > 0 &];
  mapMerge[maps_List, combiner_] := If[maps === {} ||
      AllTrue[maps, # === <||> &], <||>, Association @ Select[
        Normal[Merge[maps, combiner]], Last[#] > 0 &]];
  mapDifference[left_Association, right_Association] := Association @ Select[
    KeyValueMap[#1 -> (#2 - Lookup[right, #1, 0]) &, left],
    Last[#] > 0 &];
  mapSubsetQ[small_Association, large_Association] := AllTrue[Normal[small],
    IntegerQ[Last[#]] && Last[#] > 0 &&
      Lookup[large, First[#], -1] >= Last[#] &];

  factorData[polynomial_] := Module[{raw, unit, nonnumeric, factors, value},
    If[KeyExistsQ[factorCache, polynomial], Return[factorCache[polynomial]]];
    If[! PolynomialQ[polynomial, polynomialSymbols] ||
        TrueQ[polynomial === 0], fail["InvalidDenominatorBase"]];
    raw = Quiet[Check[FactorList[polynomial], $Failed]];
    If[! ListQ[raw], fail["FactorizationFailed"]];
    unit = Times @@ ((First[#]^Last[#]) & /@
      Select[raw, NumericQ[First[#]] &]);
    nonnumeric = Select[raw, ! NumericQ[First[#]] &];
    factors = If[nonnumeric === {}, <||>, mapMerge[
      (<|First[#] -> Last[#]|> &) /@ nonnumeric, Total]];
    value = {unit, factors}; factorCache[polynomial] = value; value
  ];

  topItems[value_] := If[Head[value] === Times, List @@ value, {value}];
  visibleMultiplicity[value_, factor_] := Total[Map[Function[item, Which[
    SameQ[item, factor], 1,
    Head[item] === Power && IntegerQ[Last[item]] && Last[item] > 0 &&
      SameQ[First[item], factor], Last[item],
    True, 0]], topItems[value]]];
  stripOneFactor[value_, factor_, requested_Integer] := Module[
    {remaining = requested, output = {}, base, exponent, take},
    Do[If[remaining <= 0, AppendTo[output, item]; Continue[]];
      Which[
        SameQ[item, factor], remaining--,
        Head[item] === Power && IntegerQ[Last[item]] && Last[item] > 0 &&
            SameQ[First[item], factor],
          base = First[item]; exponent = Last[item];
          take = Min[remaining, exponent]; remaining -= take;
          exponent -= take;
          If[exponent > 0, AppendTo[output, base^exponent]],
        True, AppendTo[output, item]], {item, topItems[value]}];
    If[remaining > 0, fail["StructuralCancellationFailed"]];
    Times @@ output
  ];
  stripVisibleFactors[value_, factors_Association] := Fold[
    stripOneFactor[#1, First[#2], Last[#2]] &, value, Normal[factors]];
  structuralReduce[terms_List, denominator_Association] := Module[
    {cancellable, stripped},
    If[denominator === <||> || terms === {},
      Return[{Total[terms], denominator}]];
    cancellable = Association @ Select[KeyValueMap[
      Function[{factor, exponent}, factor -> Min[exponent,
        Min[visibleMultiplicity[#, factor] & /@ terms]]], denominator],
      Last[#] > 0 &];
    If[cancellable === <||>, Return[{Total[terms], denominator}]];
    stripped = stripVisibleFactors[#, cancellable] & /@ terms;
    {Total[stripped], mapDifference[denominator, cancellable]}
  ];
  relevantPlusFactors[children_List, denominator_Association] := KeyTake[
    denominator, Select[Keys[denominator], Function[factor,
      Count[children[[All, 2]], child_ /;
        Lookup[child, factor, 0] === denominator[factor]] >= 2]]];

  applyReducer[nodeKind_String, numerator_, denominator_Association,
      relevant_Association] := Module[{candidate, key, answer, cancelled,
      reducedNumerator},
    If[TrueQ[numerator === 0], Return[{0, <||>, True}]];
    If[denominator === <||> ||
        rationalMaterializationRationalQ[numerator],
      Return[{numerator, denominator, True}]];
    (* For a sum of compact children, an empty relevant map proves that no
       denominator factor can cancel.  Other node kinds pass the complete
       denominator map and cannot enter this branch. *)
    If[relevant === <||>, Return[{numerator, denominator, True}]];
    candidate = mapProduct[relevant];
    If[nodeKind =!= "Final" &&
        ByteCount[numerator] + ByteCount[candidate] < threshold,
      Return[{numerator, denominator, False}]];
    key = HoldComplete[numerator, relevant];
    answer = If[KeyExistsQ[reductionCache, key], reductionCache[key],
      reducer[<|"NodeKind" -> nodeKind, "Numerator" -> numerator,
        "DenominatorFactors" -> denominator,
        "RelevantFactors" -> relevant, "Candidate" -> candidate,
        "Symbols" -> polynomialSymbols|>]];
    If[! AssociationQ[answer] || Lookup[answer, "Status", None] =!= "OK",
      fail["ReducerFailed"]];
    reducedNumerator = Lookup[answer, "Numerator", $Failed];
    cancelled = Lookup[answer, "CancelledFactors", $Failed];
    If[! PolynomialQ[reducedNumerator, polynomialSymbols] ||
        ! AssociationQ[cancelled] || ! mapSubsetQ[cancelled, denominator],
      Return[{numerator, denominator, False}]];
    reductionCache[key] = answer;
    {reducedNumerator, mapDifference[denominator, cancelled], True}
  ];

  normalize[value_] := Module[{children, denominator, lifted, local,
      numerator, relevant, compactChildrenQ, exponent, child, factors,
      inverseNumerator},
    If[PolynomialQ[value, polynomialSymbols], Return[{value, <||>, True}]];
    Switch[Head[value],
      Plus,
        children = normalize /@ (List @@ value);
        denominator = mapMerge[children[[All, 2]], Max];
        lifted = #[[1]] mapProduct[
            mapDifference[denominator, #[[2]]]] & /@ children;
        local = structuralReduce[lifted, denominator];
        numerator = First[local]; denominator = Last[local];
        compactChildrenQ = AllTrue[children[[All, 3]], TrueQ];
        relevant = If[compactChildrenQ,
          relevantPlusFactors[children, denominator], denominator];
        applyReducer["Plus", numerator, denominator, relevant],
      Times,
        children = normalize /@ (List @@ value);
        numerator = Times @@ children[[All, 1]];
        denominator = mapMerge[children[[All, 2]], Total];
        local = structuralReduce[{numerator}, denominator];
        applyReducer["Times", First[local], Last[local], Last[local]],
      Power,
        exponent = Last[value];
        If[! IntegerQ[exponent], fail["UnsupportedPower"]];
        child = normalize[First[value]];
        If[exponent >= 0,
          {child[[1]]^exponent, mapScale[child[[2]], exponent], child[[3]]},
          factors = factorData[child[[1]]];
          inverseNumerator = mapProduct[
              mapScale[child[[2]], -exponent]]/First[factors]^(-exponent);
          {inverseNumerator, mapScale[Last[factors], -exponent], child[[3]]}],
      _, fail["UnsupportedRationalNode"]]
  ];

  pair = Catch[
    pair = normalize[expression];
    If[! TrueQ[pair[[3]]],
      pair = applyReducer["Final", pair[[1]], pair[[2]], pair[[2]]]];
    pair,
    failureTag, Function[{status, tag}, $Failed]];
  If[MatchQ[pair, {_, _Association, True}], pair, $Failed]
];

rationalMaterializationCanonicalValue[expression_, symbols_: Automatic] :=
 Module[{probe, polynomialSymbols, pair},
  If[TrueQ[expression === 0], Return[{0, <||>}]];
  (* Cheap/easy operands should keep Together's excellent fast path.  On a
     preserved hard operand TimeConstrained interrupts Together cleanly
     in 1.18 s; the collector then replaces its 300.9 s tail. *)
  probe = Quiet[Check[TimeConstrained[Together[expression],
      $rationalMaterializationProbeSeconds, $Aborted], $Aborted]];
  If[probe =!= $Aborted,
    Return[rationalMaterializationCanonicalQuotientValue[probe]]];
  (* The collector is a rational-polynomial engine and its Power branch
     necessarily refuses every noninteger exponent.  Detect that contract
     boundary before recursively walking a multi-megabyte algebraic DAG; the
     caller can then use its multiquadratic/Maple backend directly. *)
  If[! FreeQ[expression,
      Power[_, exponent_Rational /; ! IntegerQ[exponent]],
      {0, Infinity}, Heads -> True], Return[$Failed]];
  If[rationalMaterializationFLINTBinary[] === None, Return[$Failed]];
  If[! FreeQ[expression,
      value_ /; NumberQ[value] &&
        ! rationalMaterializationRationalQ[value],
      {0, Infinity}, Heads -> True], Return[$Failed]];
  polynomialSymbols = rationalMaterializationSymbols[expression, symbols];
  If[! ListQ[polynomialSymbols] || polynomialSymbols === {},
    Return[$Failed]];
  pair = Quiet[Check[rationalMaterializationCollect[expression,
      polynomialSymbols, rationalMaterializationFLINTReduce,
      $rationalMaterializationReductionThreshold], $Failed]];
  If[MatchQ[pair, {_, _Association, True}], pair[[1 ;; 2]], $Failed]
];

End[];
