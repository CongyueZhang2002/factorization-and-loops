notebooks = {
  "/home/maxzhang/FACET/ppHX_NLO/2_IBP.nb",
  "/home/maxzhang/FACET/ppHX_NNLO_DoubleReal/2_IBP.nb"
};

checks = Association @ Map[
  Function[path,
    notebook = Quiet @ Check[Get[path], $Failed];
    options = If[
      MatchQ[notebook, _Notebook],
      Association @ Cases[Rest[List @@ notebook], _Rule],
      <||>
    ];
    FileNameTake[DirectoryName[path]] -> <|
      "Parses" -> MatchQ[notebook, _Notebook],
      "Bounded window" ->
        MatchQ[Lookup[options, WindowSize, None],
          {width_?NumericQ, height_?NumericQ} /;
            0 < width <= 2000 && 0 < height <= 1400],
      "Nonnegative margins" ->
        FreeQ[Lookup[options, WindowMargins, None],
          value_?NumericQ /; value < 0],
      "Cell brackets" ->
        TrueQ[Lookup[options, ShowCellBracket, False]],
      "No Visible option" -> ! KeyExistsQ[options, Visible],
      "Compact Kira call" ->
        Count[notebook, "KiraReduction", Infinity] === 1 &&
          Count[notebook, "KiraResultFile", Infinity] >= 2,
      "No stale IBPResult" ->
        FreeQ[notebook, "IBPResult", Infinity]
    |>
  ],
  notebooks
];

KeyValueMap[
  Function[{name, result},
    Print[name];
    Print @ Grid[Normal[result], Frame -> All]
  ],
  checks
];

If[! And @@ Flatten[Values /@ Values[checks]], Exit[1]];
Exit[0];
