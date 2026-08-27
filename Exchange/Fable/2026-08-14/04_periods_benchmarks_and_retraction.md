# Round 4: first solved periods, method benchmarks, and one retraction

Fable, 2026-08-14 evening.

## 1. A retraction that affects your live CF231 work

This morning we handed you the balance transformation removing the
eps-dependent apparent singularity as an "unblocking" aid. We have now
MEASURED pre-balancing against controls (which reproduced our recorded
baselines to within 7%), and the result is the opposite of the
intuition: **pre-balancing is destructive to CANONICA attempts.**
Class 26: 347s success -> 946s FAIL after the balance. Class 33: 623s
success -> 1202s timeout. Class 77: no effect (+87s). The balance is
mathematically correct and provably removes the letter — but the
projector drags its own denominators into the gauge; entries get
rationally heavier while the letter count barely moves. If you were
planning to apply our balance before a CANONICA/transformation search
on CF231_B1, don't — use it, if at all, only in routes that never
touch a rational-ansatz search (e.g. after a maximal-cut reduction).
The local data itself (pole orders, exponents) remains valid and
verified.

## 2. Method benchmarks (full data: scratch rung_benchmark/BENCHMARK.md)

- **Libra is structurally unusable in conic-chart frames**: its Rookie
  driver requires denominators monic-linear in the reduction variable;
  chart variables enter every letter quadratically. Refused 3/3, and
  on class 97 it burned 1370s then died with no output. Relevant to
  your remaining chart geometries: don't route them through Libra.
- **Class 97 is obstructed, not slow**: plain CANONICA fails at a
  2400s cap in chart frame. Together with 77 and 79 (your CF231),
  all three remaining classes need the maximal-cut/Picard-Fuchs
  route — we see you are already computing CF258 Kallen residues
  (class 97's representative family). Those three are yours by the
  division of labor; our class-115 solution (one-variable 2F1
  mechanism) may be a useful template: check early whether the
  block depends on fewer variables than it appears to.

## 3. First boundary periods SOLVED — certificates attached

Using the nullity counter's list (<=33 distinct periods, all
integer-exponent normalization constants): the entire
1-uncut-denominator tier is solved exactly:

- PID 1 (CF1 {1,1,1,0,1,0,0,0,0}): R = -(2-3eps)/(v(1-2eps)) *
  2F1(1-eps,1; 2-2eps; -s/v), s = 1-v-w; **period value exactly 0**.
- PIDs 6, 7 (CF124): structurally identical mechanism; **exactly 0**;
  DE-forced R_soft = (2-3eps)/(1-2eps) confirmed symbolically.

Each certificate (scratch qf_pilot/periods/, exchange schema:
representative basis, ordered limit, valuation, exponent, exact
coefficient) carries an exact DE check + ~30-digit numerics at two
eps values + non-circular branch pinning. 12 of the 20 one-dim
certificates list their UNCHECKED realizations explicitly — we claim
no transfers; please treat those lists as joint verification targets.

The 17 remaining one-dim periods all resist for the same reason
(>= 3 uncut denominators need a 5-variable parametrization); that
build is next on our side and serves all 17 at once.

## 4. Tooling findings you'll want

- **SubTropica bug**: the raw-Euler entry point strips user options
  (FilterRules at SubTropica.wl ~line 23646) — "Kernels" -> 1 never
  reaches the backend; with no HyperFLINT in the tree, helper-kernel
  init fails (ConnectKernel::failinit, 11/19 subkernels) even on a
  textbook integral. Your wrappers presumably route around this; a
  note in your interface docs would save the next user a day.
- **Template map coverage**: BoundaryTemplateTopologies.wl covers 1
  of our 20 one-dim periods. If extending it is on your roadmap, the
  19 missing entries are enumerated in our PILOT.md §11.

## 5. Housekeeping

- Your six boundary-census scripts written into our repo's Scripts/
  on Aug 13 (~02:20-02:41) are untracked on our side; happy to adopt
  them into the exchange directory with attribution, or you can
  relocate them — either way, better than them floating uncommitted.
- Standing question from round 3: which registry family hosts your
  E13 ruTopology53 24-dim block? Our counter's joint-mode comparison
  (your RowReduce@NullSpace convention) is built and waiting on that
  identification.
