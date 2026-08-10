# Streaming Kira import and closure (rewrite item 3)

## Problem

The solved NNLO double-real Kira workspace exports 374 per-family rule
tables (~5.88 GB compact). The current importer builds one in-memory
rule list plus a global `Dispatch`, iteratively rewrites all 44,877
targets against it, and `Put`s a 798 MB `KiraResult.wl`. On rerun it
was OOM-killed near 47.7 GB RSS. Measured 2026-08-10: the family count
and master set are already minimal (`Design/CanonicalFamilies.md`), so
the fix is memory architecture, not fewer families.

## Design

Stages, each independently resumable, communicating only through
on-disk artifacts (the existing WXF record store:
`coefficientAppendRecord` / `coefficientScanRecords`):

1. **Per-family import.** For each family, import its
   `kira_integrals_*.m` table alone, validate (exact data, one rule per
   LHS, correct family, no pinched cuts), and write one WXF record file
   `Rules/<family>.wxf` holding `lhsGLI -> rhs` as an Association,
   plus a manifest row (rule count, byte size, SHA-256, cut indices).
   Peak memory: one family table. Parallelizable with bounded workers;
   benchmark 1 and 4 before defaulting higher.
2. **Index.** A small `Index.wxf`: for every LHS integral, its family;
   for every family, its declared masters (from `masters.final`).
   Everything needed to route lookups without loading rule bodies.
3. **Closure check, graph-wise.** Instead of iterating a global
   Dispatch to a fixed point: breadth-first over the dependency graph.
   Maintain a disk-backed memo `Reduced/<family>.wxf` mapping each
   needed integral to its fully-reduced linear form (masters only).
   Process families in dependency order (a family's RHS integrals
   reference only that family or lower sectors after Kira's ordering;
   verify, do not assume). Load one family's rules, reduce all its
   needed integrals using already-memoized lower results, write, free.
   Frontier integrals with no rule and no master declaration fail
   closed exactly as today (`kira2math` export-closure loop unchanged,
   but querying only the missing integrals).
4. **Target reduction.** Stream the pre-IBP targets (already grouped by
   family), compose with the memoized reduced forms via
   `linearComposeReduction`, and accumulate master coefficients into
   per-master record files (the transpose layout that already exists in
   `CoefficientStore.wl`). No global expression is ever materialized.
5. **Artifact.** `KiraResult` becomes a directory: `Manifest.wl`
   (small, human-readable, fingerprints, master list, validation
   summary) + WXF record files. A compatibility loader can present the
   old Association interface lazily. No monolithic `Put`.

## Validation (acceptance)

- NLO UU 10x10: byte-identical masters and reduced targets vs the
  saved `KiraResult.wl`.
- NNLO: run from the preserved solved workspace
  (`~/FACET/Codex/ppHX_NNLO_DoubleReal/Kira/UU_08_05_1`); require the
  same 342-master set, zero undeclared frontier integrals, no
  conflicting duplicate rules, no pinched cuts.
- Record wall time and peak RSS per stage; target < 16 GB peak on the
  NNLO workspace.

## Non-goals

Kira solving itself is unchanged; sector embedding is a separate
benchmark (TODO item 2); coefficient reconstruction continues to read
the store through the existing target-record interface.
