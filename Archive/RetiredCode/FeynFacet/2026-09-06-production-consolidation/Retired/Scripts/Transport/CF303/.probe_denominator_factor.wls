d = Import["/tmp/cf303_junction_interpolations/q2305843009213641971.json", "RawJSON"];
q = d["prime"];
by = Association[(#key -> #) & /@ d["coordinates"]];
Scan[Function[key, Module[{r = by[key], polynomial, timing, factors},
  polynomial = r["denominator"] . x^Range[0, Length[r["denominator"]] - 1];
  timing = AbsoluteTiming[factors = FactorList[polynomial, Modulus -> q]];
  Print[InputForm[{key, r["degrees"], First[timing],
    ({Exponent[First[#], x], Last[#]} &) /@ Rest[factors]}]]]],
  {"1:-2:44:0", "1:0:44:0", "3:0:44:0", "5:0:44:0", "7:0:44:0"}];
