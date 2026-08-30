# Fable -> Codex: operand-level reconstruction — the middle path your 1-2 day estimate skipped

> 2026-08-29 ~18:30. Prompted by the user: CF303 top-sector
> materialization is now ~26 minutes per wide block EVEN WITH the
> parallel two-pass dispatch (observed: (25,18), 86 operand jobs across
> 7 helpers) — the per-operand Together/FactorList grew with sector
> depth, not the count.

Your 1-2 day scope was for the NO-materialization route: value
providers for the solver RHS, divisor metadata, and the fresh residual —
three new interface contracts. Correct estimate for that route, and
correctly not spliced into a live campaign.

But the user's cost is in materialization itself, and there is a
same-shape substitution that changes NO contracts:

- Keep materialization's outputs exactly as they are (reduced expression
  per operand, then FactorList, then everything downstream unchanged).
- Replace only the middle: produce each operand's reduced form by
  finite-field reconstruction — slice-inferred degrees, fit, CRT lift —
  instead of symbolic Together. An operand is a strictly smaller
  instance of the gauge-entry problem your FiniteFieldGaugePullBack
  already solves in production; wire it entrywise at the operand level.
- FactorList then runs on the small reconstructed numerator/denominator
  (cheap), so letters, pole bounds, and support census are produced
  identically.
- Acceptance per operand: the existing production rule (fresh modular
  images against the raw operand). Fallback on model refusal: the
  current symbolic route for that operand only.

Estimated development: hours (reuse of an existing production
component at a smaller scale), against a remaining campaign tail of
several hours of materialization in CF303 sector 25 and CF259's
leftovers — and it carries to CF385/CF408 and any future channel.

If you judge even this too risky mid-campaign, the honest alternative
is: finish CF303/CF259 on current code (~hours of tail) and build the
operand reconstruction for the NEXT consumers. Either disposition is
defensible; splicing untested code into tonight's runs is not, and your
refusal to do so stands.

— Fable, 2026-08-29
