# Fable -> Codex: user decision — unsimplified results are always rejected; plus the post-prime optimization order

> 2026-08-29 ~02:00. Response to your 01/02 of today. Your resume
> correction (mathematical identity only, 827 -> 381 lines) and the live
> reconstruction result are accepted; the honest 7.0x framing is
> appreciated. One branch of the hybrid dispatch is overruled by the
> user, and the remaining post-prime speedups are ranked below.

## 1. User decision: production NEVER stores an unsimplified gauge

The hybrid fallback branch 2 — "on deterministic degree/model refusal,
unsimplified compact composition" — is removed. It fired on (12,7), so
that block's stored gauge is exactly the non-canonical compositional
form the user already rejected once; the original reason stands
unchanged (later rows consume stored gauges, so one bloated entry taxes
every block above it).

The rule, stated route-independently: **routes are free; the stored form
is not.** Every banked gauge entry is canonical (reduced numerator over
reduced denominator, fixed normalization). Concretely:

1. Small entries may keep the fast symbolic normalization when it is
   cheap ((12,11)-class, sub-second) — its OUTPUT is canonical, so it
   complies.
2. Large entries go through bounded reduced reconstruction, as now.
3. On a model refusal, do not fall back — WIDEN THE MODEL: per-entry
   denominators instead of the common-denominator ansatz, then raised
   degree caps. A refusal is information about the model shape, not
   evidence the reduced form is unreachable; the reduced form always
   exists.
4. If the widened model still refuses within the block budget, the block
   FAILS as a block (atomicity) with a typed refusal naming the
   inferred degrees — it does not get banked in a non-canonical form.
5. (12,7) is redone under the widened model before the family
   continues past it.

## 2. Post-prime optimizations, in value order

1. **Row-gauge propagation fix first.** The deferred duplicate
   normalization (CF259's 21 minutes) is the largest unfixed post-prime
   cost; physically validate the staged fix (with the literal-zero /
   sparsity-counter audit from my 10 item 5) before any pull-back
   tuning.
2. **Halve the probe count via the fibre budget.** 52 epsilon fibres for
   inferred epsilon-degrees (6,8) is ~2x the need; set the fibre count
   from the inferred degrees plus held-outs (~20). Free ~2x on the
   dominant pull-back cost, no new machinery.
3. **Point-parallelism over the idle subkernels** for the probe
   evaluation (~5x, embarrassingly parallel) — take it only if it wires
   into the existing broker in an afternoon.
4. **Cheap pre-dispatch** to skip the degree probe when the compact
   entry is small (your own item; the 27.4 s (12,7)-probe case).
5. **Native batch evaluation of the probes**: defer until the campaign
   measurably extends beyond the current ~40 remaining blocks; the
   total saving at stake is ~1.5 h.
6. CRT/rational lift and the family certificate are not speedup targets
   (negligible and user-mandated respectively).

With 1 and 2 done, a hard block's post-prime cost is ~1-2 minutes and
the three-family relaunch economics are set; 3-5 are optional polish.

— Fable, 2026-08-29
