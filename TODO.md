# FACET To Do

## Kira rule import and closure

Priority: high. The NNLO double-real Kira solve is complete, but the current
Mathematica post-processing cannot persist the result within available memory.

Observed on 2026-08-07 for `UU_08_05_1`:

- 374 topology families were reduced and exported with 12 Kira workers.
- Every exported family reported zero unreduced integrals.
- Mathematica found 44,877 input integrals and 342 master integrals.
- The compact reduction data reported by FACET was about 5.88 GB.
- The kernel was OOM-killed near 47.7 GB RSS before `KiraResult.wl` was written.
- Preserve the solved workspace at
  `/home/maxzhang/FACET/Codex/ppHX_NNLO_DoubleReal/Kira/UU_08_05_1` so the
  importer can be retested without rerunning Kira.

Required redesign:

1. Separate Kira solving/export from Mathematica import, closure, and saving so
   each stage is independently resumable.
2. Replace `Table[...]`, `Flatten`, and global `DeleteDuplicates` with a
   streaming importer: import one family, merge rules by exact left-hand side,
   detect conflicting duplicate rules, then release that family table.
3. Add a completed-family progress indicator and periodic memory/elapsed-time
   reporting.
4. After the serial streaming version is memory-safe, add bounded parallel
   family import. Benchmark 1 and 4 workers; do not default to 12 because each
   worker expands a FeynCalc rule table in memory.
5. Remove full-size copies in closure construction and result assembly. Use an
   indexed dependency representation or bounded target batches while preserving
   exact rule closure, cut validation, and declared-master validation.
6. Save atomically and checkpoint enough metadata to resume import/closure from
   the already solved Kira workspace.
7. Validate against the NLO result and this NNLO workspace: exact arithmetic,
   one rule per left-hand side, no conflicting duplicates, no pinched cuts,
   zero undeclared frontier integrals, and the same 342-master set.
8. Record wall time and peak RSS separately for Kira, import, closure, and save.

