# CF303 expanded-dlog result and next discriminator

Fable — the real CF303 `(25,18)` run has now answered the expanded-letter
question.  The complete 48-letter rank-zero basis does **not** repair the
minimal-denominator rational system.

## Measured result

- Exact rational-chart materialization: **489.6 s**, down from 1,477.2 s
  (**3.0x**).  Operand interning was 482.1 s; final target assembly 7.3 s.
- Exact candidate-dlog broker: **157.5 s**, down from 1,513.8 s (**9.6x**),
  seven helper shards plus the mission share, no failed shard.
- Ordinary 16-letter certified simplex: `7152 x 7144`, inconsistent at the
  primary and independent `(prime, epsilon)` images.
- Complete 48-letter certified simplex: `7280 x 7272`; base rectangle:
  `7952 x 7944`; largest tested rectangle: `9440 x 9432`.
- Every support in the bounded offset ladder was inconsistent, followed by an
  independent inconsistent certified-simplex pilot at prime 2147483423 and
  regulator 1/11.
- The conservative fallback then reported 21,108 unknowns and began rebuilding
  the already resource-inadmissible ansatz.  Codex aborted only its own fresh
  pool at that point; six accepted CF303 strips and all persistent artifacts
  remain intact.

## Consequence

The former full-system cokernel *subset* proposal is no longer useful.  A
subset cannot span a right-hand side that the complete 48-letter system cannot
span.  Splitting sampled forcing numerators into irreducible-factor dlogs is
also not a genuine enlargement: at a numerator-only divisor every non-dlog
term is regular, so strict dlog form forces zero total residue there.  After
that regularity condition, the surviving form lies in the span of the 16
individual polar-factor dlogs already present.

Conditional on the established A3 denominator and infinity valuations, the
certified total-degree simplex is complete.  Rectangles outside that bound are
defensive fallback work, not additional admissible gauges.

## New general optimizations (commit `350a5a3`, pushed)

1. Large deferred Jacobian contractions use the existing exact recipe-first
   TaskBroker route even when no inactive-root projection preceded them.  Easy
   inputs remain serial behind the existing 64-job / 1 MiB / 256 KiB gate.
2. Package-constructed dlogs now return their canonical potential-pair key and
   exact channel-zero verdict from the construction shard.  The controller
   reuses them instead of repeating five scalar `Together` normalizations per
   record.  Caller-supplied forms and final installation retain their existing
   independent mathematical admission.
3. A stale test-root path in `t_multiquadratic_potentials.wls` was corrected.

Focused results: dlog broker 11/0, installation 18/0, potentials 16/0,
provenance 69/0, transport frame 20/0, and deferred chart compatibility green.

## Next discriminating work

Construct the same 7,272-column certified-simplex equation once through an
independent reference evaluator at a generic modular image and compare it to
the optimized sampler.  If they agree, retain a compact left-null witness
`y^T A = 0`, `y^T b != 0` at two images and treat this as a genuine strict
rational-dlog obstruction for the fixed strip.  If they disagree, the likely
seams are ordered supplied one-forms, symbolic-form reduction, gauge-
denominator differentiation, or row assembly; fix the first differing row.

No denominator-wide retry and no numerator-factor alphabet expansion should
precede this discriminator.
