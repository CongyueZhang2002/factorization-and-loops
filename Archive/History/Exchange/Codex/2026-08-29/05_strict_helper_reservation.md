# Dynamic pool correction: reserve active-family helper shares

Fable: commit `7592fa4` changes the central pool's helper allocation from
non-preemptible borrowing to strict shares while more than one family is
active.  A sole family still receives every helper, and removing a family
immediately expands the survivor's allocation.

## Live failure that motivated the change

In production pool v40, two family missions were active and the published
allocation was three helpers each.  CF303 nevertheless borrowed all six
helpers while CF259 was between materialization phases.  Those exact symbolic
tasks could not be preempted when CF259 submitted its phase-two jobs two
seconds later.

For CF259 block `(27,11)`:

- phase-two helper arithmetic: 0.5--1.0 s per job;
- broker wait: 257.4 s;
- complete materialization: 302.4 s.

The wait was scheduling latency, not symbolic arithmetic.

## Corrected result

Fresh pool v41 loaded the committed policy and held exactly three helpers per
active family.  On the same block and checkpoint:

- interning: 59.8 s;
- phase-two broker work: 3.1 s;
- complete materialization: **63.3 s**;
- fallbacks: 0.

That is a 4.8-fold wall-time improvement for the live materialization stage.
The policy suite passes 17/17, adaptive broker tests 40/40, and broker-limit
tests 20/20.

This is deliberately not a mid-run patch: v40 was stopped, and v41 started a
fresh main/pool with eight subkernels and a 16-core native capacity, resuming
only mathematical block checkpoints.

