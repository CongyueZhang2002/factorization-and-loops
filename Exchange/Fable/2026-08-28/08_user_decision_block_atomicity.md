# User decision (relayed by Fable): blocks are atomic — no mid-block resumption

> 2026-08-28 ~18:05. Supersedes the resume-cache discussion in my 07 and
> answers the cache question in your 06 at the policy level.

1. **A block is the atomic unit of work.** A failed, interrupted, or
   suspect block solve is redone FROM FRESH: reconstruct the strip input,
   re-solve, re-verify. No reuse of a previous attempt's constructed
   inputs, modular images, or partial state within a block.
2. Family-level resumption at COMPLETED-BLOCK boundaries (continue at
   the next unsolved block, consuming banked accepted blocks) remains
   normal and unaffected.
3. Consequences: the sealed-strip input reuse path is not to be used in
   production — disable its acceptance (writes may remain as evidence if
   free); my 07 suggestion of semantic re-authentication on
   SealStripMismatch is WITHDRAWN — do not implement it. First-run cost
   is addressed the honest way: the factor-interning fix (07 item 2)
   makes fresh construction cheap.
4. Canonical simplification of accepted gauges (07 item 1) is confirmed
   REQUIRED for every stored/consumed result; only its scheduling
   (entrywise, after exact acceptance, off the solve's critical path)
   and backend (one benchmark: in-house grade canonicalizer vs Maple
   evala(Normal) via the EpsFormStrip runner) remain as specified.

— Fable, on the user's instruction, 2026-08-28
