# Dynamic family resource pooling

## Allocation model

- [🟢] Treat Wolfram subkernel seats and native CPU threads as independent
  resources. One family controller occupies one subkernel; the remaining
  seats are helper capacity.

- [🟢] Recompute grants whenever a family or helper enters/leaves. Split
  native cores by quotient and remainder, rotate the remainder when the
  active-family set changes, and keep helper dispatch least-served then
  least-recently-served.

- [🟢] Make the allocation work-conserving: a family may borrow an otherwise
  idle helper seat, but the central dispatcher still enforces the physical
  subkernel total.

- [🟢] Publish the live allocation atomically and let long-running family
  missions adopt it at solver, strip, prime, and native-call boundaries.

## Physical enforcement

- [🟢] Put all five FLINT/native adapter entry points behind a process-shared
  native-core lease. A new call waits or receives fewer threads while an old
  oversized call drains, so a family transition cannot oversubscribe merely
  because the old subprocess cannot be shrunk in place.

- [🟢] Keep the per-call native cap at eight while allowing a lone family to
  own more than eight total cores for independent work. Divide a family's
  total quota across simultaneous sample workers.

- [🟢] Make live core-capacity changes independent of subkernel count. The
  pool creates and rereads `control/native_cores`; an existing pool therefore
  scales without restart.

- [🟢] Give every controller a unique owner identity, inherit it into helpers,
  serialize duplicate controllers for one family group, and quarantine queued
  helpers when their owner finishes. Already-running helpers drain without
  destructive preemption.

## Avoid harmful nested parallelism

- [🟢] Keep fixed-profile regulator interpolation single-threaded and cap
  adaptive native discovery by the live grant.

- [🟢] Suppress multiquadratic follower-image waves while multiple families
  are active. Permit at most the measured two-image tail wave for the last
  family when its native quota can support it.

- [🟢] Retain the existing cost gate for finite-field sample farming; a zero
  helper grant computes locally rather than waiting.

## Validation and remaining calibration

- [🟢] Pass policy, wrapper, TaskBroker, native lease, finite-field backend,
  multiquadratic follower, direct-resume, broker-adaptive, two-core, and
  package-generality tests.

- [🟢] Pass live transitions `1 family -> 2 families -> core shrink -> 1
  family`, including fair helper order and restored tail allocation.

- [🟢] Pass a live owner-failure test proving that a queued helper is filed
  `OWNERFINISHED` and never resurrected.

- [🟡] Record production phase timings from the next mixed-family campaign.
  Change the two-image tail limit only if those measurements show a material
  gain; reject more scheduler complexity for a small percentage improvement.
