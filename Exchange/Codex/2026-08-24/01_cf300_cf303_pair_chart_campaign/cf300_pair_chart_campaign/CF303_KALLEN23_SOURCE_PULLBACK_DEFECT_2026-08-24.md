# CF303 Kallen23 source-pullback defect (2026-08-24)

## Scope

This is a package defect report only. No package file was modified.

Pinned source:

- `/home/maxzhang/factorization-and-loops/FeynFacet/Private/TransportCharts.wl`
- SHA-256 `2cd6cc63a94762c4546954881d5a16931e4ca1a6e7de716920882bad13d3efc9`
- Relevant path: `SolveEpsFormStripInFrame`, especially the source-gauge pullback and exact roundtrip at lines 584--599.

## Defect

For a Kallen pair chart, `masterTransportRecordCoordinateMap` can return an exact inverse map containing a nested square root which is algebraically a declared multiquadratic expression. `SolveEpsFormStripInFrame` currently applies only `Together` after substituting that map:

```wl
sourceGauge = Map[Together, chartGauge /. coordinateMap["Map"], {2}];
```

`Together` does not canonicalize the nested radical. Consequently the following branch substitution can fail to recognize an otherwise exact gauge, and the wrapper can return `StripGaugeRoundTripFailed`.

The CF303 19->18 Kallen23 pullback exhibits the issue. Before canonicalization its exact source census contains undeclared-looking bases `2` and

```wl
(lambda2) (1 + x + y + Sqrt[lambda1])^2/2
```

even though the latter has the declared-field image

```wl
Sqrt[lambda2] (1 + x + y + Sqrt[lambda1])/Sqrt[2].
```

The raw exact roundtrip therefore finds no accepted sheet. Evidence:

- failure artifact: `/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/cf303_19_18_kallen23_source_pullback_v1/failure_25ddb1e7fc0942c0874bd6cd774a2767.wl`
- SHA-256 `7f68503c190876d700aaf83463fe0d37bbe9f71e1841b89903847ad529c2d3a5`
- recorded checks: coordinate composition exact, chart exact, but `GaugeRoundTripHasSheet -> False`; unclassified radical bases contain the nested radicand above.

## Exact workaround and result

The scratch driver canonicalizes only the pinned nested radicand before the package-equivalent branch and source-frame checks:

```wl
canonicalize[expression_] := Together[expression /.
  Power[base_, exponent_Rational] :> If[
    Denominator[exponent] === 2 &&
      TrueQ[Together[base - nestedRadicand] === 0],
    nestedRootImage^(2 exponent), Power[base, exponent]]];
```

After this exact rewrite:

- the apparent `Sqrt[2]` cancels, so the constant field is `Q`;
- the source root census is exactly `{1,2}` and root 3 is absent;
- accepted branch signs are `{{1,1},{1,-1}}` (the gauge is invariant under the unused second sign on this block);
- gauge roundtrip and all source-frame identities pass exactly.

Certified output:

- `/tmp/codex-triple-root-20260824-pairchart.jnlBfZ/cf303_19_18_kallen23_source_pullback_v1/source_gauge_19_18.wxf`
- SHA-256 `c770cba5c46fc942f2da9c5b057c2b148afc69b0646b087887376ce03b2c7cb6`
- summary SHA-256 `569897e98846c6af931bdbf6ffd0111cedf3da0e2c3333fb9ac8922c9922772b`

## Suggested package-level repair

Add a chart-owned exact inverse-radical canonicalization step between `coordinateMap["Map"]` substitution and branch roundtrip. It should be generic chart metadata or a verified normalization hook, not a CF303-family special case. Acceptance must remain fail-closed:

1. rewrite only identities supplied/derived and exactly verified by the selected chart;
2. exact-compose the normalized source expression back to the chart expression;
3. retain the existing branch roundtrip and transformed-one-form pullback checks;
4. add a Kallen23 regression with a nontrivial algebraic gauge whose inverse map creates the nested radical.

The scratch workaround is evidence for the missing normalization, not suitable package code by itself because its `NestedRadicand` and `NestedRootImage` are supplied by a CF303 campaign artifact.
