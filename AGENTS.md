# FeynFacet

FeynFacet is a Wolfram Language package for NNLO hadronic cross sections by
collinear factorization and reverse unitarity: process cards -> diagrams ->
cut-aware IBP reduction (Kira) -> master integrals from their differential
equations (epsilon form, solution along paths, boundary data) -> endpoint
expansion -> assembly of the hard function. The process enters only through
its cards. 

Read `STATUS.md` for current state

## Layout

- `FeynFacet/` is the active package, organized by mathematical responsibility;
  read `FeynFacet/README.md`. `Kernel/Modules.wl` explicitly lists the symbolic,
  optional epsilon-form and standalone solution modules. Retired code is in
  `Archive/RetiredCode/FeynFacet/`, outside loading and active source scans.
- `Scripts/` drivers and launchers; `Tests/` the tests; each has a README.
- `Projects/<project>/card.wl` common physics; `Projects/<project>/<order>/<channel>/Cards/`
  contribution cards; `Results/` and `Kira/` belong to that order/channel.
  Read `Design/ProjectCardsAndResults.md`. Old layouts are archived; no adapters.
- `Design/` current methods; `Goals/README.md` current roadmap;
  `Archive/History/` superseded plans and correspondence.
- `Codex/` Pro consultation bridge state; `Tests/Support/` independent test
  implementations. Upstream reduction/reconstruction data stays with its process.
- Persistent outputs and validation records live in Projects/<project>/<order>/<channel>/Results;
  Kira workspaces live in Projects/<project>/<order>/<channel>/Kira. Do not write result trees under Codex,
  Design, Scripts or Examples. Scratch is temporary and removed after retained
  results are saved in the process folder.
- `~/FACET` is the frozen legacy tree, read-only.

## Tips

- If you feel getting stuck, ask chatgpt pro through `External/ChatGPT`, along with latest github link. It has higher reasoning budget. You can also ask it for review of plan/code/result. 

## Traps (each one cost real time)

- DeleteDuplicates takes its equality predicate directly as its second argument.
  SameTest -> SameQ silently leaves duplicates. SameTest is valid for Complement
  and Intersection; do not replace those option rules.

- Prevent using hashes if possibke, it often turned out to be counterproductive.
- Regulator symbols differ per package (`eps`, `ep`, `Epsilon`,
  `CANONICA`eps`): normalize by `SymbolName` at every boundary, never by
  symbol identity.
- After LoadFACET a bare `Names` binds to the empty `FeynCalc`Names`
  shadow: write `System`Names` in scripts and tests.
- Qualify cross-module public function calls when the callee declaration loads later. Otherwise a private undefined shadow can be captured at definition time.
- Packages dump symbols into `Global`` (asy, SubTropica's `line`,
  PolyLogTools).
- `Lookup[{}, key, default]` returns the default: check the container's
  head before `Lookup` on a possibly-empty list.
- `Return` inside `Do` discards results; `Module` initializers are not
  sequentially scoped; `Missing[] =!= None` in both directions.
- On Wolfram 14.2, ClearAll inside Internal`InheritedBlock destroys saved definitions. Use Clear and explicit attribute/option assignments; test restoration. Runtime scopes must live outside contexts cleared by package entry files.
- Parse reloadable runtime packages with BeginPackage so caller Global names cannot capture private locals. Uninstall native WSTP links inside InheritedBlock, before it restores caller definitions; Uninstall also removes installed functions. MPSolve needs its own -j 1 thread limit.
- Do not initialize generic script/evaluation scopes with unlimited extra precision. N can chase relative digits of exact-zero Gamma/digamma combinations indefinitely; keep a finite extra-precision budget and use explicit working-precision/accuracy controls. AMFlow DESolver may choose its own setting inside its isolated scope.
- FLINT 3.0.x generic complex-ball method tables initialize lazily without synchronization. Initialize gr_ctx_init_complex_acb before the first OpenMP region using polynomial operations.
- FileNameSplit on Unix uses an empty first component for the filesystem root.
  Preserve it when removing redundant path separators; DirectoryName can retain a trailing slash.
- For `Exists`/`ForAll` with a computed variable list, inject the list and condition using `With` before `Resolve`; a held symbol with an OwnValue is not the intended quantified list.
- `Put` is not atomic: write to a temporary file and `RenameFile`.
- `Put` and `Compress` can omit context names using the caller's context path.
  Artifact writes use an empty `$ContextPath` and a neutral output context,
  qualifying package symbols and shadowable System names. Otherwise
  ``Global`Epsilon`` or ``System`Generic`` can be rebound by `Get`;
  a guarded reader alone is insufficient.
- `Together` rationalizes square-root denominators and destroys
  algebraic-letter expressions.
- Libra `Projector` returns a zero matrix on Wolfram 14.2 unless
  `Off[OptionValue::optnf]` is set; `Fuchsify` only walks off-diagonal
  blocks.
- `wolframscript -file` on a missing path exits 0: a run with no printed
  tally is void, not passing.
- Libra's Fermat banner puts a raw 0xA9 byte in solve logs and the shell's
  `grep` skips binary streams silently: use `command grep -a`.
- Kernel start can hang on a paclet-server fetch; `$AllowInternet = False`
  is set in `~/.Wolfram/Kernel/init.m` for that reason.

## Language

Public names, documentation, reports, plans and exchange notes use standard
mathematics or amplitude terminology whenever a mathematical object exists.
Coding terms are confined to private implementation. Everything must be
readable by a physicist without knowledge of the implementation.

Rules:

1. One name per concept, fixed at first use and anchored to the literature;
   the same name in code, chat, plans, artifacts and agent briefs.

Banned words (word -> replacement): 

arm -> start; 
drain -> finish; 
fire -> starts; 
gate -> check or test;
in flight -> running; 
land, ship -> finished; 
lever -> option orchange; 
meticulous;
post-mortem;
port;
spawn -> start; suite -> test; 
wall (metaphor) -> the measured limit;
