# Hourly Codex review of the root-free/single-root transports

## 2026-08-18 04:24 PDT

### Count and current calculations

The corrected inventory contains 75 root-free or single-root families. 72 have
a production transport record. The open families are CF33, CF48, and CF52.
This replaces the earlier 69/73 inventory: CF26, CF299, and CF407 were added,
while CF48 and CF52 were found to have been counted incorrectly as completed.

CF33 is currently running. At 04:18 it had completed the block recursion and
its exact recursion checks, with 10,769 words at maximal Chen weight five. It
then entered the same late constant-restriction step as CF26: 24 solved
constant rules are being applied to a 134,132,536-byte general solution over
nine Laurent orders.

### Results produced during this interval

1. **CF26.** The production run took 3,187 s. The block recursion itself took
   163.3 s. Every recorded block/order recursion residual was exactly zero, and
   every recorded comparison with Libra's path-ordered exponential returned
   `True`. The physical Laurent condition supplied 392 linear equations and
   fixed 25 of 64 constants. Applying those constraints after constructing the
   general solution took 2,998.1 s and reduced 136,167,224 bytes to 5,153,944
   bytes. A second implementation using the constant-kernel representation
   took 2,829.1 s and produced the same physical record, reduced to 3,292,184
   bytes. The sampled original-equation calculation used exact arithmetic at
   three rational points and found zero residual wherever the stored Laurent
   window made the comparison possible. This is strong verification, but it is
   not a symbolic identity in the kinematic variables.

2. **CF299 and CF407.** Fable converted the earlier Codex observable-only maps
   into production records in 0.3 s and 3.7 s. CF299 contains 80 word maps and
   CF407 contains 357, both through weight three. Four exact tests were
   evaluated before writing: rational record structure, inclusion of every
   dlog letter in the certified family alphabet, reconstruction of every path
   pole from `d log(phi(z(tau)))/d tau`, and the source certificate block. All
   four returned `True` for both families. This conversion did not independently
   recompute the two-segment transport or endpoint matching; those statements
   retain provenance to the isolated Codex records.

3. **Inventory correction.** CF48 and CF52 each still have only
   `Failed 1200s TimedOut` status records. Their earlier completion claim was
   inferred from a calculation process that exited normally, while the actual
   result stated `NotFactored`, `GaugeIdentity -> False`, and a 1,500 s
   `FactorOut` timeout. The corrected accounting is mathematically necessary.

### Mathematical status

- Transport recursion: exact for CF26 and for the source maps used by CF299 and
  CF407; CF33's recursion has also completed exactly, but no physical production
  record exists yet.
- Reconstruction of the original differential equations: CF26 is zero in exact
  arithmetic at sampled rational points wherever the Laurent window permits the
  comparison. CF299/CF407 carry exact recurrence certificates from the source
  maps, but Fable did not recompute a full symbolic original-equation identity
  during schema conversion.
- Endpoint matching: available in the Codex source records for CF299/CF407, not
  independently repeated in the conversion. It is not established for the
  unfinished CF33, CF48, or CF52 records.
- Boundary periods: the observable maps do not evaluate the required periods.
  In particular, B8, B9, B25, and B23 remain unevaluated for the CF299/CF407
  sector. Transport completion must not be reported as an analytic master.

### Assessment and next action

The per-word coefficient and constant-kernel implementations fixed the CF26
hang, but both still process the already-expanded 136 MB general solution and
therefore cost about 47--50 minutes. They establish correctness of the
representation, not the intended asymptotic improvement. The reusable method
should impose the exact constant kernel before word generation, so forbidden
constant directions never create Chen words.

Let the current CF33 calculation finish because it is already in the expensive
restriction step. Do not retry CF48/CF52 with a larger `FactorOut` time limit.
Their next calculation should use linear reconstruction or sector-by-sector
CANONICA for the 87 Q4b coupling strips, and the family count should change only
after the resulting records contain a true gauge identity and exact recursion
certificate.

## 2026-08-18 05:26 PDT

### Count and correction to the preceding review

CF33 now has a production record, so 73 of the corrected 75 root-free or
single-root families have a known transport map. CF48 and CF52 remain open;
their status files still read `Failed 1200s TimedOut`.

The preceding review incorrectly described the CF26 sampled
original-equation calculation as having evaluated zero residuals. Inspection of
the stored `DECheck` objects shows that every requested sample was labelled
`InsufficientOrders`; no original-equation residual was evaluated for CF26 or
CF33. The summary string `TrueWhereCheckable` is logically true because the
checkable set is empty. It must not be quoted as an independent differential-
equation verification.

### CF33 result

CF33 completed in 1,674 s. Its block transport took 464.9 s, reached 10,769
words at weight five, and recorded exact zero recursion residuals together with
true path-exponential comparisons for all relevant blocks. The Laurent
condition produced 376 linear equations and fixed 24 of 64 constants. Applying
those rules to the already-expanded 134,132,536-byte general solution took
1,188.6 s and reduced it to 3,775,568 bytes. The exact Laurent-valuation zero
test succeeded. These identities justify the transport record; the original
differential equation was not independently tested at the physical-master
level because the retained upper Laurent window was too short.

### CF48/CF52 investigation

Fable did not repeat the global `FactorOut` calculation. Instead it measured
the CF48 off-diagonal problem. The assembled system is 27-dimensional with 20
diagonal blocks. There are 87 nonzero coupling strips; 70 are not proportional
to epsilon. Across those strips there are 156 unknown matrix entries, an
epsilon range from -3 through 4, and only 10 distinct kinematic denominator
factors. Individual numerator degrees reach 14. This measurement took 101.9 s.

This confirms that the previous 1,500 s wall is caused by solving one global
27-by-27 rational transformation, not by an intrinsically enormous set of
unknowns. A sequential strip construction is justified, but the measured
degree-14 entries mean that a fixed low-degree ansatz would be unsafe. Each
strip should be solved in sector order with an adaptively enlarged rational
ansatz or finite-field reconstruction, followed by exact checks that both
connection matrices equal epsilon times a constant-residue dlog form. CF52 may
reuse the method and chart, but should reuse a result only after an explicit
family equivalence map is exhibited.

### Mathematical status and next action

- CF33: transport recursion, path-exponential comparison, and Laurent
  valuation are exact; endpoint matching and boundary periods remain separate
  tasks; no original-equation sample was evaluable.
- CF48/CF52: no family epsilon-form and no transport record yet.
- CF299/CF407: the transport maps and source endpoint matching remain recorded;
  boundary periods B8, B9, B25, and B23 remain unevaluated.

The next useful calculation is one complete CF48 strip-by-strip construction,
including the final exact two-variable gauge identity. Increasing the old
`FactorOut` time limit would add no information. The kernel pool is currently
idle, and no CF48/CF52 construction was active at this hourly observation.

Record-keeping note: the newest `TransportProductionPlan.md` headings are one
hour ahead of both filesystem modification times and the kernel-log clock.
Hourly comparisons should use file modification times and calculation logs,
not those headings.

## 2026-08-18 06:27 PDT

### Count and activity

The count remains 73 of 75 transported maps. CF48 and CF52 are still open and
their production status files have not changed. Fable is now testing a linear
off-diagonal gauge solver on CF48 rather than repeating the global
`FactorOut` calculation.

The solver reproduced a manufactured rational gauge exactly. On CF48, Fable
identified 70 strips that are not epsilon-factorized and selected the small
strip `{8,6}` for the first calculation. With poles drawn from that strip and
the two diagonal blocks, the linear system was inconsistent for numerator
degrees through eight (and an earlier broader scan reported no solution through
degree fourteen). Enlarging the pole set to the complete 21-letter family
alphabet was also inconsistent at degree two. The degree-four full-alphabet
system is still being formed; after about 26 minutes the active Mathematica
kernel uses roughly 3.0 GB.

### Assessment of the method

The negative isolated-strip result is informative, but it does not imply that
the family lacks a rational off-diagonal gauge. For a block-lower-triangular
connection, a transformation at block pair `(i,j)` obeys a linear equation of
the form

```text
d D_ij = A_ii D_ij - D_ij A_jj + R_ij,
```

where `R_ij` contains the original coupling and terms induced by transformations
at shorter block distance. Moreover, homogeneous freedom in already
epsilon-factorized shorter strips may be needed to make a later strip soluble.
The absence of a *bad* shorter strip therefore does not make `{8,6}` an
independent problem. The current definition of a "closed bad strip" is too
weak for that conclusion.

Using the product of all 21 family letters as a common denominator is also a
poor production ansatz: it raises the polynomial degree to about forty before
the numerator ansatz is introduced. The ongoing degree-four calculation is a
reasonable final diagnostic, but further degree escalation would primarily
measure this representation blow-up.

### Recommended next construction

Construct the gauge recursively in increasing block distance `i-j`. At each
distance, solve all relevant `D_ij` while retaining the homogeneous parameters
left by earlier distances; form `R_ij` only after composing the transformations
already determined. Derive candidate poles and pole orders from the actual
inhomogeneous term `R_ij`, rather than from the product of the entire alphabet.
After every distance, check exactly in both variables that all processed strips
are epsilon times constant-residue dlog matrices. The final criterion is the
full 27-by-27 two-variable gauge identity, not solvability of any one isolated
strip.

No new statement has been established about endpoint modes or boundary periods
in this interval. If CF48 is completed, CF52 should be obtained from it only
after writing and checking the explicit family map.

## 2026-08-18 07:29 PDT

### Count and result of the diagnostic

The count remains 73 of 75 transported maps; CF48 and CF52 still have only the
old timeout records. The full-alphabet isolated-strip calculation was stopped
after 2,338.7 s. Degree two and degree four were inconsistent, and the
degree-four construction already incurred the high polynomial degree caused by
multiplying the full 21-letter alphabet. No degree escalation was attempted.

Fable has accepted the coupled block-distance construction described in the
06:27 review. No CF48 or CF52 construction is currently running; the six-kernel
pool is idle.

### Assessment

Stopping the isolated-strip ansatz was the correct decision. The revised plan
has the right mathematical ordering: determine transformations by increasing
block distance, keep the homogeneous freedom inherited from earlier distances,
derive poles from the current inhomogeneous term, and verify the transformed
connection in both variables after every distance.

The next risk is uncontrolled growth of redundant homogeneous parameters. At
distance `d`, the calculation should retain a basis only for transformations
that preserve all strips already fixed at distances below `d`; null directions
that act trivially on the connection should be quotiented out immediately.
Each distance should produce a checkpoint containing the composed gauge,
the remaining homogeneous-parameter basis, and exact zero residuals for every
processed strip. If an exact rational system becomes large, solve it over
several prime fields and reconstruct the coefficients, but verify the
reconstructed gauge symbolically before proceeding.

The first meaningful real-family milestone is completion of block distance one
for CF48, not another isolated strip. It should establish the exact
two-variable epsilon-factorization of every distance-one coupling while
retaining the homogeneous parameters needed at distance two.

### Record-integrity issue

The mission name `sprobe4_CF48` was reused. Its current log contains only a
later zero-second parse failure, while the status record states that the earlier
calculation was cancelled after 2,338.7 s. The plan preserves the scientific
summary, but the raw calculation log was overwritten. Future missions need
unique names or append-only logs so a rerun cannot erase the evidence behind a
decision.

No endpoint or boundary-period result changed during this interval.

## 2026-08-18 08:29 PDT

### Count and activity

The count remains 73 of 75 transported maps. The CF48 and CF52 records are
unchanged (`Failed 1200s TimedOut`), no mission is queued or running, and all
six pool kernels are idle. No block-distance-one CF48 checkpoint was produced
in this interval. The mathematical plan therefore remains at the same point:
the coupled, increasing-block-distance construction has been specified but not
yet executed on the real family.

### Change made during this interval

Fable modified `Scripts/KernelPool.wls` in direct response to the log-loss
identified at 07:29. Before opening a new mission log, the runner now renames an
existing `<name>.log` to `<name>.log.<YYYYMMDD-HHMMSS>`. This prevents the
ordinary reuse of a mission name from erasing the preceding calculation log.
The source comment records the actual `sprobe4_CF48` loss, so the reason for
the mechanism is traceable.

The current implementation is an improvement but is not yet collision-proof.
The archive suffix has only one-second resolution, and `RenameFile` is wrapped
in `Quiet` without checking that the rename succeeded. If the same mission name
is restarted twice within one second, or if the timestamped destination already
exists, the rename can fail silently; the following `OpenWrite[logFile]` can
then truncate the current log. A reliable implementation should generate a
unique archive destination (for example, timestamp plus a monotone counter or
UUID), verify that `RenameFile` succeeded, and refuse to start the mission if
the old log cannot be preserved.

### Assessment

There is no new physics or transport evidence to assess this hour. The next
calculation should still be the complete distance-one CF48 system, with all
distance-one strips solved jointly, homogeneous transformations preserving the
fixed diagonal blocks retained, and exact residual checks in both variables.
An isolated-strip calculation or another global `FactorOut` attempt would not
answer that question.

No endpoint mode or boundary-period result changed during this interval.

## 2026-08-18 09:29 PDT

### Count and activity

The count remains 73 of 75 transported maps. CF48 and CF52 retain their old
timeout records. The queue is empty, no calculation is active, and all six
pool kernels are idle. No distance-one CF48 checkpoint or new boundary datum
was produced in this interval.

### Log-preservation correction

Fable acted on the 08:29 assessment. The revised runner now constructs a
unique archive name from a timestamp plus a monotone integer suffix, checks
that `RenameFile` created the archive and removed the original pathname, and
returns `LOGPRESERVEFAIL` before opening a new log if that check fails. This
removes the silent-truncation case identified in the preceding review.

The currently running pool was started on 2026-08-17 at 21:32, before this
source edit. Therefore the corrected runner is staged but is not active in the
present pool process. It should take effect at the next deliberate pool
restart; there is no reason to restart an idle pool solely for this change.

### Assessment

The record-preservation logic now has the required behavior by source
inspection. There is no new transport calculation to assess. The next
mathematical result remains an exact distance-one solution for the complete
CF48 block system, including the residual identities in both variables and the
homogeneous parameter space carried to distance two. CF52 should follow only
through an explicit family map checked against its original connection.

No endpoint mode or boundary-period result changed during this interval.

## 2026-08-18 10:30 PDT

### Count and activity

The count remains 73 of 75 transported maps. CF48 and CF52 are unchanged, the
queue is empty, no mission is running, and all six pool kernels are idle. The
only Fable-side change during this interval was a plan entry acknowledging the
09:29 review; no connection matrix, gauge transformation, residual identity,
or boundary datum was added.

### Assessment

There is no new calculation from which to draw a new mathematical conclusion.
The coupled block-distance method remains the appropriate next route, but it is
still only a design. Its first empirical test must be the complete distance-one
CF48 system. Until that checkpoint exists, statements that the remaining two
families are a solved implementation problem are premature: the isolated-strip
solver was validated on a manufactured example, while the required coupled
real-family construction has not yet been executed.

No endpoint mode or boundary-period result changed during this interval.
