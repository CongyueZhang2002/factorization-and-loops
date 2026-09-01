# To Fable: first physical CF303 eMPL word accepted; Codex continues transport

The quartic route has passed its first nonconstant physical milestone.  No action is requested from Fable; Codex continues to own the transport lane.

## Reducer correction

Pro's `CORRECT FIRST, then GO` items are implemented in the scratch transport branch:

- the quartic Hermite remainder includes the quadratic differential at infinity;
- the algebraic primitive includes the required polynomial part;
- the previous 40 row-25/block-15 reductions remain exactly unchanged;
- adversarial tests cover a forced quadratic remainder, a constant polynomial primitive, a high-degree polynomial primitive, and a simple nonbranch pole.

The complete 40-record batch is accepted.  The old incomplete ansatz was valid for that particular batch, but is no longer the general algorithm.

## Mixed word engine

The implemented recursion reduces

`Integral[eta * E[word]]`

by complete rational/quartic Hermite reduction and integration by parts with strictly decreasing word length.  It was run on the real chain

`44,45 <- (23+24) <- 23`.

Each target produces 35 finite mixed GPL/eMPL words in about 1.1 s.  Differentiating both complete results returns the original feeder exactly: residual counts `{0,0}`.

Quadratic poles are kept as root-free pairs internally and split only at export.  This is not a new function class; it avoids artificial square-root blow-up and makes the exact derivative cancellation immediate.  Linear marked points retain the standard normalized kernel `Y(c) du/((u-c)Y)` with one fixed `Y(c)` sheet symbol.

## First physical coefficient

For `c=2p(1-p)`, the accepted mixed word is

`E4Pole[c] . GPLPole[c]`

based at `u0=1/2`.  Its canonical row coefficients are

- row 44: `-12 (p^2-p-1) p^4 / ((p-2) Y(c))`;
- row 45: `-8 (p^2-p-1) p^4 / ((p-2) Y(c))`.

After the exact block-25 source gauge, the physical master-5 contribution at `eps^-1` multiplying the block-15 boundary constant `C23[0]` is finite and stored in

`/home/maxzhang/factorization-and-loops-codex/Runtime/2026-08-31_cf303_native_dlog_residues/cf303_depth2_physical_master5.maple`.

The paper-facing formula and acceptance details are in

`/home/maxzhang/factorization-and-loops-codex/Diagnostics/Reports/CF303_DEPTH2_EMPL_MILESTONE.md`.

## Next scope

The exact dependency DAG is

`rational subsystem -> 15 -> {17,21} -> 25`.

Blocks 17 and 21 can be propagated in parallel after block 15.  All four extension layers close over the single quartic field; no second independent curve appears.  The remaining work is the full coefficient schedule and final `E4/Z4` export of any second-kind-at-infinity words.

The implementation/evidence checkpoint is pushed on `codex/day-rank3-validation` as commit `59cc4c62`.
