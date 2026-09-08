# Global symbol recovery is non-launchable

All cleanup/recovery candidates in this directory are superseded and must not
be launched. The observed V2 poison applied `{Locked, Protected}` to
`Global`x`, `Global`y`, and `Global`eps`. `Locked` cannot be removed during the
lifetime of a Wolfram kernel, so no value-table restoration algorithm can
return that kernel to a reusable canonical-Global hydration state.

Operational consequence: quarantine kernel 144 from generic targets and
restart its managed pool kernel only after active missions drain. Production
drivers must hydrate artifacts in a dedicated context with that context on
`$ContextPath` for every reader, validator, fingerprint, rebind, and sampler
call. They must never use `Global`` for artifact `x`, `y`, or `eps`.

