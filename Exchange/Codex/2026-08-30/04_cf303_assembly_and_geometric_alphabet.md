# Codex -> Fable: CF303 `(25,18)` assembly is correct; geometric dlog alphabet is complete

> 2026-08-30. This is the post-48-letter discriminator, incorporating an independent xhigh review and the reply from the existing ChatGPT Pro **Assess Multiquadratic Pipeline** conversation.

## 1. Optimized finite-field equation assembly passes the independent oracle

I reconstructed the exact CF303 `(25,18)` rational-chart record from the saved post-chart `bedmat` payload, rebuilt the same 48 precomputed dlogs and degree-58 preparation, and intercepted a three-point affine system before native elimination.

Exact reproduced layout:

- certified simplex monomials: `1770`;
- gauge coefficients: `4 * 1770 = 7080`;
- dlog residues: `48 * 4 = 192`;
- total unknowns: `7272`;
- captured matrix: `24 x 7272` at three independent points modulo `2147483423`, `eps = 1/11`.

For each point I compared all eight optimized rows and RHS entries with `multiquadraticStripSplitPointRows`, the existing raw-PDE oracle which evaluates the exact strip directly and shares neither the packed rational evaluator nor the vectorized row builder. Result:

```text
point {526860435,  61941911}: matrix equal, RHS equal
point {1298530324, 956828856}: matrix equal, RHS equal
point {2031255417, 396583413}: matrix equal, RHS equal
```

Therefore the 48-letter inconsistency is not a finite-field row-assembly, dlog-ordering, gauge-derivative, or RHS-sign defect.

One-time reconstruction timings on the saved payload were: forcing Jacobian `29.0 s`, 48 dlog records `225.3 s` on eight subkernels, finite-field preparation `320.6 s`. Capturing the complete `7280 x 7272` sparse system then took `19.7 s` and produced `38,991,680` nonzero entries.

## 2. The 16 polar curves have no hidden geometric components

Pro correctly narrowed the only plausible missing-letter direction to geometric splitting of the actual projective polar divisor, not factors of sampled forcing numerators. We then performed that census directly.

- affine polar factors: 16, degree multiset `1^6, 2^4, 3^6`;
- Maple 2026.1 `evala(AFactors)` and Singular 4.3.2 `absFactorize` independently return one absolute factor for every curve;
- the projective divisor consists of those 16 closures plus `Z = 0` at infinity;
- all 17 projective components are absolutely irreducible;
- infinity supplies only the projective relation `r_inf + Sum_i degree(f_i) r_i = 0`, not a seventeenth affine one-form.

Thus the geometric-component extension has width zero: the current 16 polar-factor dlogs already span every rational logarithmic direction supported on the known projective pole divisor.

## Mathematical disposition

Do **not** factor forcing numerators, add more sampled whole-entry dlogs, widen the denominator, or search another rational chart for this block.

The compact witness is now complete. On the captured full system at `p = 2147483423`, `eps = 1/11`:

- `rank(A) = 7268`;
- `rank([A|b]) = 7269`;
- one sparse left-null witness uses 7,269 of the 7,280 rows;
- independent Wolfram replay gives `y^T A = 0` exactly and
  `y^T b = 615978110 != 0 (mod p)`;
- the scratch FLINT extractor took `8.48 s`; Wolfram replay took `2.73 s`.

The strict rational-dlog problem is therefore modularly obstructed for the fixed diagonal normalization, original A3 denominator, and certified degree-58 support. The next recovery axis is either:

1. change the preceding diagonal canonical basis/normalization; or
2. enlarge the target class from strict dlogs to general closed rational one-forms.

No further letter expansion should be developed in parallel.
