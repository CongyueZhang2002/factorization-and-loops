# Residual integral equation review — completed

Actual ChatGPT6Pro, existing conversation:
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84

Pushed before submission:
https://github.com/CongyueZhang2002/factorization-and-loops/tree/8c92f11b5e1539f748e85b36d3f8235d7e65dcda

Request: inspect EliminateKnownIntegralRules and batched ApplyIntegralReduction
in Reduction/Reuse.wl, KnownIntegralRules composition/scale/resume paths in
Reduction/IBP/CutFamilies.wl, and EliminateKnownRules in
DifferentialEquations/CutSystems.wl. Check all-column retention, exact relation
composition, empty systems, physical-scale restoration and restart binding.
Fourteen tests were run locally; Pro was asked to distinguish source inspection
from execution. A bounded coefficient-swell diagnostic was requested before
using the option on the next large solve. Review also points to the exact-source
and endpoint-support RV fixes since prior review15. Do not consult the published
measured NLO EEC coefficient; the healthy RR job remains unchanged.

## Response (actual Pro, worked for10m13s)

Pro inspected exact revision8c92f11b and the full Reuse.wl/tests, typed Kira
construction/import/resume, equation writer, scale conversion, DE constructor,
rational backend, and RV source-binding/contact-support paths. It explicitly
did not run the local tests or inspect/modify the live native state.

Confirmed: for I_L=R I_U, all rows become (A_L R+A_U)I_U=0. The injection
I=(R,1)I_U identifies this kernel with the original equations plus supplied
identities. Keeping all remaining columns retains nontarget constraints.
Generating seeds on original targets before substitution is correct. The new
native target list is the support of original target images. Physical scale
restoration must precede composition with the supplied physical rules; the code
does so. Both empty cases, changed-input refusal, native-file resume, and batched
coefficient-row reassembly are consistent. Supplied identities remain trusted
physical inputs, not identities proved by syntactic validation.

Findings:

1. A caller-supplied KnownIntegralRules pool can include a relation outside the
   initial target set. Later automatic prior rules overwrite that pool, losing
   a useful constraint. Preserve the initial pool as ExtraEquations once, as
   for full InitialReduction relations. This does not affect the automatic
   path without an additional caller pool.
2. NativeDiagnostic bypasses the new option. Reject KnownIntegralRules on that
   unsupported route instead of silently ignoring it.
3. Retain ResidualEquationCount in the saved elimination summary; EquationCount
   still describes original generation.

All three findings are repaired. Eighteen targeted assertions pass in34.387s
including startup, covering off-target constraint propagation and explicit
NativeDiagnostic rejection. No large production job has used the new option.

Pro's performance advice: measure affected rows, not only arbitrary/unaffected
samples. Use a cheap support census to select high fan-out/high coefficient-size
rows, deterministic affected rows across families/sectors and unaffected controls
(up to512rows). Record row/column/nonzero counts, coefficient sizes/degrees,
separate validation/substitution/cancellation/scale time and peak process-tree
memory. Backend count-based chunking does not bound caller peak expression size.
If fill-in is large, eliminate a cheap subset and retain the other identities
as equations; whole-row chunks can bound preprocessing memory. Use matching
physical/native scale conventions. The96-row completed pilot used native
normalized equations AND native normalized exact rules, not physical rules.
It is not a full-system timing prediction.

RV assessment: exact scalar-source and density inventory checks, inclusive
original-amplitude identity, endpoint-only explicit contacts, retained accepted
records and SourceBindingSchema3 repair both findings from review15. Pro found
no remaining instance in the inspected paths, without independently executing
the eight actual-result checks.

