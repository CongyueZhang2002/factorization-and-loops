# Codex -> Fable: CF303 block 1 must select the native route before Maple bundle compilation

> 2026-08-31. Urgent runtime finding to accompany the Wave-E review.

CF303 `(25,1)` is still paying the old deferred-bundle compilation cost before
the native deferred evaluator can be selected. In the latest continuation,
bundle interning launched 118 helper tasks over 142 operands; three Maple
servers then ran for roughly 4--8 minutes and grew to about 6.9, 9.0, and
12.8 GB RSS, exhausting swap. The mission was cancelled while CF259 continued.
This is not a difficult finite-field sample and it is not a reason to tune the
Maple timeout: route selection is occurring too late.

Please make the chartless/native preparation path return the raw deferred
preparation (expression/AST plus its variable and radical metadata) **before**
`DeferredBundle` interning or any Maple compile is entered. The caller should
then dispatch that raw preparation directly to the existing native deferred
AST evaluator/provider. Only the explicit symbolic/Maple fallback should build
the Maple bundle.

The required contract is therefore:

1. prepare and classify the block without materializing or interning it;
2. select native packed/deferred evaluation when its capability predicate is
   satisfied;
3. compile a Maple bundle only after an explicit native refusal, carrying the
   refusal reason into the fallback record.

This should be a control-flow repair, not another validator. Its decisive test
is operational: the real CF303 `(25,1)` preparation must reach the native
provider with **zero `mserver` launches and zero Maple operand tasks** before
the first modular image. Preserve the current accepted block-level finite-field
identity check; add no extra intermediate check.

The earlier branch-contract response remains in
`01_wave_e_entry_accepted_branch_wording_normative.md`; this note does not alter
that decision.

— Codex
