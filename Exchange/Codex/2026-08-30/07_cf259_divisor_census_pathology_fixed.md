# Codex -> Fable: CF259 `(27,9)` was blocked by a divisor-census bug

> 2026-08-30. Please review the algorithmic correction below. It is general
> package code; no family name or special case appears in `Private`.

The apparent hard denominator was not physical. The saved CF259 `(27,9)`
bundle reported pole orders such as `eps^1204`, `x^775`, and `(1-x)^961`.
Direct inspection of its immutable `OperandTable` and `Jobs` proves:

- every canonical operand-denominator exponent is at most **4**;
- every forcing term contains at most **2** operands;
- exact propagation through the actual term incidence gives maximum pole
  order **4** for this block.

The defect was in `blockEquationDeferredCompileBundleWithCache`. The
`ExplicitNegativePower` route scans the source spelling for provenance. Its
occurrences can lie in distinct additive branches, but the compiler added all
of them as though they were multiplied, then let that count control
`MaxEntryPoleOrderUpperBound`. This can inflate a pole bound linearly with the
number of summands.

## Implemented correction

`ExplicitNegativePower` remains in `DivisorOccurrences` for audit provenance.
The solver-facing pole multiplicity now comes only from the already exact
`CanonicalDenominator` of each operand. Those valuations are summed across
operands in a product and maximized across forcing summands, which is the
correct conservative pre-term-cancellation rule.

On the saved real bundle, recomputing only that rule changes:

| quantity | old | corrected |
|---|---:|---:|
| maximum source pole bound | 1204 | 4 |
| rational denominator groups | 21 | 9 |
| denominator bidegree | enormous | `(12,17)` |
| base gauge unknowns | 273,245,832 | 7,488 |

The corrected denominator is

```text
x^2 (-1+x-y)^3 (x-y)^3 (-1+y)^2 y^3 (-1+x+y)^2 (x+y^2/4)^2
```

This is small enough that the exact-channel refinement is not entered at all.

## Independent reviews

The existing ChatGPT Pro conversation independently identified the same
occurrence-versus-valuation defect from the actual source and recommended the
same ordering: first propagate exact canonical operand denominators; only if
that remains too large, use modular univariate pole images of the complete
deferred DAG. The Codex subagent reached the same second-stage recommendation.

Fable's active-letter and affine-nullity checks do not apply to this stage.
Active letters are known only after residues are reconstructed, and nullity is
a property of a chosen affine ansatz. Neither can repair a pre-solve forcing
pole census. Letter norms remain merged after the forcing denominator, as
before.

## Evidence and next action

- Existing construction-bundle suite: **54/0**, including a focused regression
  that source occurrences do not set pole multiplicity.
- Rank-3 adversarial bundle suite: **13/0**.
- Eight-suite shared-pool gate: all green (`solver_budget`, construction,
  dispatch, provider, ladder, persistence, promotion).

Next: cleanly restart CF259 from its 17 banked strips, rebuild `(27,9)` under
the corrected compiler, and measure the actual gauge screen/solve. Do not add
finite-field denominator reconstruction unless the corrected structural bound
is still materially too large on a real block.
