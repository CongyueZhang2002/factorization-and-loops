# Overhaul analysis tools (2026-09-02)

Static analyses over `FeynFacet/Private/` used by the overhaul; all read
the repository at `/home/maxzhang/factorization-and-loops` (edit `ROOT`
to point elsewhere) and write beside themselves.

- `reachability.py` — definitions per module, call graph, reachability
  from the public API (usage messages), production scripts and
  string-constructed names (`Symbol["FeynFacet`Private`" <> ...]`,
  `ToExpression`); reports live / test-only / dead symbols
  (`dead_and_testonly.txt`, `reachability.json`). Handles comment markers
  inside strings.
- `route_split.py` — for each candidate stale route root, the symbols
  reachable only through it (the evidence table of
  `Private_Backup/EVIDENCE.md`).
- `move_to_backup.py` — moves the top-level definitions of named symbols
  from a module into `Private_Backup/<module>` with a provenance header
  (`--dry-run`, `--keep-options`).
- `structure_move.py` — the layer move and manifest generator (already
  applied; kept for the record).
