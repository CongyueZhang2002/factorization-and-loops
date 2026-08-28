# Language rules for reports to the user

Every status report, plan, and exchange summary must be readable by a
physicist with no software background: plain English + physics/mathematics
English only. This file is the authoritative banned-word library; re-read
it before writing any status report.

## Rules

1. One name per concept, fixed at first use, anchored to the literature or
   house term; identical in chat, plans, artifacts, and agent briefs.
2. Never use physics-domain vocabulary for scheduling/software concepts.
3. No metaphors in status reports: state the literal mechanism or the
   measured number.
4. Physics/project terms are fine (prime, kernel, residue, alphabet,
   letter, eps-form). Shipped identifiers (`GateVerdict`,
   `family_epsform_*`) stay as identifiers but are described in standard
   vocabulary.
5. A genuinely new object gets its name defined once in the plan file and
   reused exactly.

## Banned-word library (word → replacement)

- arm → start
- blocker → the thing stopping X
- cut / channel / current / propagate (operational use) → literal description
- drain → finish
- fire (a job fires) → starts
- gate / gate-verified / acceptance gate / resume gate / pre-gate → the
  exact ε-form check / the full test run / the checkpoint acceptance
  conditions / candidate
- goal state → the family certificate reports exact agreement
- green / red → passing / failing
- in flight → running
- land / ship → finished
- lever → option / change
- meticulous → precise, or just state the facts
- mortem / post-mortem → record of the terminated run / what happened
- phase (operational use) → stage, batch, step
- port → carrying over
- purification / cleanup / strip gauge → completing the family's ε-form
- spawn → start
- suite → test
- wall (metaphor) → the measured limit
- wave → stage

## Fixed project bindings

- "completing the family's ε-form" / "off-diagonal completion"
- "class ε-form" (stage-1 per-class result); "transport" (solving along a
  path); "couplings" or Lee's "off-diagonal blocks" for B_ij
- "passed the exact ε-form check" = transform by T, verify the exact
  rational identity in both variables equals ε·Σ_a R_a dlog φ_a with
  constant R_a
- "single-root batch / two-root batch / triple-root batch" (not
  phase 1/2/3); no term for transitions — "when the single-root batch
  finishes"
- "diagonal block" = irreducible diagonal subsystem (stage-1 unit);
  "off-diagonal block (k,j)" = its coupling into lower diagonal block j;
  "strip", "sector", and unqualified "block" retired from prose
