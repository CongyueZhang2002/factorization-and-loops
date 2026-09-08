# FeynFacet

FeynFacet is a Wolfram Language package for NNLO hadronic cross sections by
collinear factorization and reverse unitarity: process cards -> diagrams ->
cut-aware IBP reduction (Kira) -> master integrals from their differential
equations (epsilon form, solution along paths, boundary data) -> endpoint
expansion -> assembly of the hard function. The process enters only through
its cards. 

Read `STATUS.md` for current state

## Layout

- `FeynFacet/` the package; `Private/<Layer>/` holds the modules in the
  order of `Private/LoadOrder.wl`; `Private_Backup/` is retired code,
  never loaded.
- `Scripts/` drivers and launchers; `Tests/` the tests; each has a README.
- `<process>/Cards/` process definitions; `<process>/Results/` generated
  mathematical data; `Stale/` pre-V2 data, evidence only, never an input.
- `Design/` method records; `Exchange/`, `Goals/` correspondence and goals.
- Scratch lives in the session scratchpad, never in the tree.
- `~/FACET` is the frozen legacy tree, read-only.

## Tips

- If you feel getting stuck, ask chatgpt pro through `External/ChatGPT`, along with latest github link. It has higher reasoning budget. You can also ask it for review of plan/code/result. 

## Traps (each one cost real time)

- Prevent using hashes if possibke, it often turned out to be counterproductive.
- Regulator symbols differ per package (`eps`, `ep`, `Epsilon`,
  `CANONICA`eps`): normalize by `SymbolName` at every boundary, never by
  symbol identity.
- After LoadFACET a bare `Names` binds to the empty `FeynCalc`Names`
  shadow: write `System`Names` in scripts and tests.
- Packages dump symbols into `Global`` (asy, SubTropica's `line`,
  PolyLogTools).
- `Lookup[{}, key, default]` returns the default: check the container's
  head before `Lookup` on a possibly-empty list.
- `Return` inside `Do` discards results; `Module` initializers are not
  sequentially scoped; `Missing[] =!= None` in both directions.
- `Put` is not atomic: write to a temporary file and `RenameFile`.
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