# Codex Workspace

This directory owns all agent-generated working material. Production package
code, cards, notebooks, pair data, and final analytic results stay outside
`Codex`; temporary scripts, intermediate reductions, logs, staging files, and
backups do not.

## Layout

- `ppHX_NLO`: NLO-specific Kira projects, run state, logs, and scratch work.
- `ppHX_NNLO_DoubleReal`: double-real NNLO Kira projects, run state, logs, and
  scratch work.
- `EvaluateMasters`: master-integral software studies and exploratory runs.
- `General`: shared scratch work and ChatGPT collaboration state.
- `Tests`: reusable package and workflow test programs.
- `Backups`: repository and notebook backups, grouped by source.
- `Staging`: transient files awaiting validation or promotion.
- `TestResults`: generated test logs and test-only artifacts.

Each process directory may contain `Kira`, `Runs`, `Scratch`, and `Logs`.
Nothing under `Codex` is a published physics result unless it is deliberately
promoted to the corresponding production result directory.

## Relocated Material

The 2026-08-06 cleanup placed historical material as follows:

- prior `.Kira` projects and `KiraResult.wl` files are in
  `<process>/Kira/<run>`;
- run controls, diagnostics, manifests, and resource logs are in
  `<process>/Runs/<run>`;
- old `.codex_tmp` research is divided among the process `Scratch` branches,
  `EvaluateMasters/Research`, and `General/Scratch/Legacy_2026-08-06`;
- former root backup and staging trees are in `Backups` and `Staging`;
- generated test logs and round-trip artifacts are in `TestResults`.

The production `ppHX_NLO/Results` tree still contains the available final
`IBPResult.wl` files and the 10-by-10 pair set. The production double-real NNLO
result tree retains its pair set; its unfinished Kira state is under Codex.
