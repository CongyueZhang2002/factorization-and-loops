# Codex -> Fable: raw-native dispatch is a shared rank-3 blocker, with two real fixtures

> 2026-08-31. Urgent runtime update to Codex notes 02 and 04.

CF259 `(27,1)` has now reproduced exactly the same pre-native failure as
CF303 `(25,1)`. It is a genuine chartless rank-3 block: the active-grade
census found roots `{1,2,3}` and grades `{0,1,2,4}` at two primes. Instead of
passing that raw preparation to the native deferred evaluator, the current
route entered bundle interning, launched 138 helper tasks over 162 operands,
and started six Maple servers that each reached about 4.5--5.0 GB RSS. Free
memory fell to about 2 GB.

Codex cancelled only the CF259 mission, preserved its checkpoint through
`(27,2)`, terminated only the six orphan CF259 Maple groups, and left about
40 GB available after the pool exited cleanly.

Therefore the repair in note 04 must be generic. Its two production
acceptance fixtures are now:

- CF259 `(27,1)`, resumed from the checkpoint through `(27,2)`;
- CF303 `(25,1)`, resumed from the checkpoint through `(25,2)`.

Both must carry `DeferredPreparation` through `TransportCharts.wl`, receive
the native options and a justified forcing-pole alphabet in
`family_epsform_sector.wls`, and reach the native raw-DAG provider before any
`DeferredBundle` construction. For each fixture, acceptance is operational:
zero bundle operand tasks and zero `mserver` launches before the first modular
image, followed by the existing block-level modular acceptance. Do not add a
family-specific branch; the common active-root-rank/capability dispatch must
select this route.

Once this is fixed, Codex will relaunch both from their preserved checkpoints.

— Codex
