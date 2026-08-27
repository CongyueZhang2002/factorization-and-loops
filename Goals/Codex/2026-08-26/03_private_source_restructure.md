# 03 — Reorganize `FeynFacet/Private`

> **Status:** [ ] Not started  
> **Owner:** Codex  
> **Implementation workspace:** `/home/maxzhang/factorization-and-loops-codex`  
> **Constraint:** no additional worktrees

## Objective

Replace the flat, incrementally accumulated `FeynFacet/Private` layout with a
small number of algorithmic domains and split the genuine monoliths at their
existing mathematical boundaries. Preserve behavior, public APIs, artifact
schemas, checkpoint compatibility, and package conventions.

## Baseline

- 33 `.wl` files and 53,128 lines in one flat directory.
- `MultiquadraticStripSolve.wl`, `MasterTransport.wl`, `Simplification.wl`,
  and `FiniteFieldStripSolve.wl` contain about 43% of all private source.
- The package loader owns one flat handwritten load list.
- 32 physical `FeynFacet/Private/...` references occur across 19 tests and
  scripts.
- Three files own their own `Begin["FeynFacet`Private`"]` context while the
  remaining files rely on the package loader, so the standalone-load contract
  is presently inconsistent.

## Target domains

- `Core/`
- `Physics/`
- `IBP/`
- `Coefficients/`
- `Geometry/`
- `DifferentialEquations/`
- `EpsilonForm/{Strip,Multiquadratic,Diagonal,Family}/`
- `Transport/`

`Geometry/` will own shared radical normalization, multiquadratic frames, and
rational charts; those algorithms are used by both epsilon-form solving and
transport and should not be hidden inside `TransportCharts.wl`.

## Work plan and status

- [🟢] Inventory file sizes, natural section boundaries, current load order,
  context ownership, and direct path consumers.

- [ ] Add one ordered logical-module-to-path manifest consumed by the loader and
  the test path helper.

- [ ] Move intact files into algorithmic domains without changing symbols or
  behavior.

- [ ] Split the multiquadratic solver into common policy, alphabet, screens,
  preparation, compiler, providers, sampling, reconstruction, artifacts, and
  orchestration.

- [ ] Split master transport into representations, closed forms, frames, depth
  budgeting, paths/backends, verification, and orchestration.

- [ ] Split coefficient and finite-field code into normalization, trace
  preparation, modular backend, sampling, interpolation, and solve layers.

- [ ] Move chronological narratives to `Design/` and classify legacy paths as
  production fallback, test oracle, or removable code.

## Structural rules

- No family, process, author, date, or version identifiers in production
  filenames or dispatch conditions.
- No generic `Utils.wl` dumping ground.
- One owning module per private symbol.
- Preserve the current definition/load order during the physical move.
- Do not rename private symbols or alter algorithms in structural commits.
- Extract shared code only where the mathematical contracts are actually
  identical.
- Keep files below roughly 2,000 lines intact unless they clearly own multiple
  independent algorithms.
- Keep chronological implementation history out of production source while
  retaining concise mathematical invariants and measured motivations.

## Completion conditions

- [ ] Fresh-kernel package load succeeds through the manifest.
- [ ] Tests and scripts no longer encode physical private-source paths.
- [ ] The four largest monoliths have coherent, reviewable module boundaries.
- [ ] Public symbols, options, status contracts, and serialized artifact
      formats are unchanged by the structural migration.
- [ ] No family/process-specific executable logic is introduced.
- [ ] Focused epsilon-form, reconstruction, transport, and infrastructure gates
      pass after every split.
- [ ] No material package-load or runtime regression is introduced by the
      reorganization itself.

## Next gate

Wait for Fable's active changes and the Codex rank-3 optimization integration
boundary to settle. Then add the manifest and source-path resolver on that
frozen revision before moving any files. `MultiquadraticStripSolve.wl` and
`BlockEquationDeferred.wl` must not be split while competing edits remain.
