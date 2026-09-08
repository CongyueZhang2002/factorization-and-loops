# To Fable: dynamic family resource pooling is now physically enforced

Date: 2026-08-28

I implemented the resource-pool correction directly in the package. The
important distinction is now explicit: Wolfram subkernel seats and native CPU
threads are different resources and are scheduled independently.

## Allocation invariants

For `S` live subkernels and `F` active family controllers, helper capacity is
`H = max(0, S - F)`. The main KernelPool is the sole helper dispatcher. It
chooses the least-served, then least-recently-served family, so every family
gets one helper before another gets a second. An idle entitlement may be
borrowed, but physical dispatch still bounds total Wolfram jobs by `S`.

Native capacity is read live from `control/native_cores` and divided across
active families by quotient and remainder. A family may own more than eight
total cores, but one native call is capped at eight. When the family has
multiple sample/image workers, its quota is divided over those workers.

Adding/removing a family republishes the allocation immediately. Existing
Wolfram tasks are not destructively preempted; completed seats are reassigned
fairly. This is deliberate because cancelling a nearly complete modular image
would lose work.

## The snapshot race is closed

A quota snapshot alone is insufficient: an existing eight-thread FLINT
process cannot be shrunk when another family arrives. All five native adapter
entry points now pass through `Scripts/native_core_lease.sh`. The lease is
process-shared and FIFO. A new call waits or receives fewer threads until older
leases drain, and its final thread argument is replaced by the granted value.

This gives the required physical invariant across transitions: active native
subprocesses never exceed the live core budget merely because a previous call
started under an older allocation. A live expansion admits disjoint work
immediately; a shrink waits for oversized old work to drain.

## Owner lifetime and stale work

Every family controller now receives a unique owner identity; TaskBroker
helpers inherit it. A second controller for the same family group is serialized
rather than double-counted. When a controller finishes, its queued helpers are
filed `OWNERFINISHED`; they cannot resurrect during a later solve/certificate
mission with the same family name. A helper already running is allowed to
drain, while the native lease protects the global CPU bound.

## Parallelism choices

- Adaptive regulator interpolation uses the live native grant; fixed-profile
  interpolation stays at one thread because thread startup loses there.
- Finite-field sample workers divide the family quota, including the local
  worker. The serial/no-helper path is also recapped immediately before use.
- Multiquadratic follower-image waves are serial while multiple families are
  active. The last family may use at most the measured two-image tail wave
  when its total native quota supports it.
- The existing cost gate still decides whether finite-field farming is worth
  the broker round trip. A zero helper grant computes locally.

## Evidence

Green focused gates:

- resource policy: 16/0;
- native shrink/expand lease: 4/0;
- kpsubmit wrapper/owner metadata: 34/0;
- TaskBroker grants, sample-worker division and native routing: 17/0;
- adaptive broker regression: 39/0;
- finite-field native interpolation: 9/0;
- multiquadratic follower waves: 12/0;
- direct row-gauge resume ABI: 25/0;
- renamed-variable and package generality: 53/0 and 30/0.

Two actual KernelPool campaigns also passed:

1. `1 family -> 2 families -> native cores 12 -> 8 -> 1 family`, observing
   grants `A:12`, then `A:6/B:6`, then `A:4/B:4`, then `A:8`, with fair helper
   admission at the two-family stage.
2. A synthetic controller exited while one helper ran and another remained
   queued; the queued helper was quarantined `OWNERFINISHED` and never ran.

No family name or current CF-specific assumption appears in `FeynFacet/Private`.
The remaining yellow item is performance calibration on the next physical
mixed-family campaign. Please keep the two-image cap unless timing shows a
material improvement; do not add scheduler complexity for a few percent.
