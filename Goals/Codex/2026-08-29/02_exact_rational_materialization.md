# Exact rational materialization goals

## Production algorithm

- [🟢] Preserve `Together` as a one-second exact fast path so easy operands and
  easy families do not pay for the new collector.

- [🟢] Replace pathological `Together` tails with a general exact rational-DAG
  collector over an explicit polynomial ring.

- [🟢] Use FLINT only for the measured sparse multivariate GCD and exact
  cofactor seam; keep scheduling, fallback, and mathematical semantics in the
  package.

- [🟢] Abort one operand immediately after a native refusal and fall back to
  the historical exact route without ancestor retries.

- [🟢] Keep production validation unchanged: per-block random-point modular
  acceptance followed by the final family certificate.

## Correctness and generality

- [🟢] Preserve rational content, GCD associates/signs, repeated factor powers,
  inversion of rational subtrees, and exact zero.

- [🟢] Support a dynamic variable list and keep every family/chart identifier
  out of `Private` implementation code.

- [🟢] Require a complete declared polynomial ring before native conversion;
  fail closed on algebraic or unsupported coefficients.

- [🟢] Prove downstream compatibility on a saved dependent phase-two assembly,
  comparing the represented mathematical value rather than expression
  spelling or association order.

## Performance gates

- [🟢] Reduce the preserved 300.9-second hard operand materially without
  slowing the ordinary construction suite.  Measured: 86.07 s and 9.45 s,
  respectively.

- [🟢] Test a second hard family and a matched fast sibling.  Measured: 81.63 s
  for the hard operand and 0.0034 s for the fast sibling.

- [🟢] Reject Maple as the primary route after its hard-operand tail exceeded
  120 s and 5.2 GiB, despite winning on one easier hard operand.

- [🟢] Reserve equal helper shares while multiple families are active so
  non-preemptible borrowed work cannot block a peer's next phase.  The same
  live materialization fell from 302.4 s to 63.3 s.

- [🟡] Resume the remaining triple-root families with this backend and record
  per-block materialization telemetry plus existing acceptance records.

- [ ] Consider generic source-first homogenized composition only if campaign
  telemetry still makes materialization a dominant wall.  Reject a
  chart-specific implementation or substantial complexity for a marginal
  stage-level gain.
