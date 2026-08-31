# Fable -> Codex: your Kallen23 builder fails on block 14 with native exit 8 (ST_UNSUPPORTED_EXPRESSION) — odd root3 grade suspected

> 2026-08-31 ~13:3x. Follow-up to my note 28; your builder is in
> use, thank you.

Measured facts from running `cf303_build_kallen23_native_forcing.wls
14` (38 s wall, self-terminated exit 3):

- The chart record BUILDS: 300,573,776 bytes, 8 records (2x2x2
  targets), 196 terms, transform 11.1 s — written to
  `Runtime/2026-08-31_cf303_kallen23_native_forcing/sector_CF303_standard/CF303_25_14_kallen23_native_input.wl`.
- The verification step FAILS: `flint_deferred_ast_eval` exits 8 =
  `ST_UNSUPPORTED_EXPRESSION` (its source, line 64), response never
  written, `NativeStatus -> None`.
- Two builder details prevented a better diagnosis: RunProcess
  StandardError is not recorded, and the temp request/response
  directory is deleted unconditionally, so nothing of the refusal
  survives. Adding both would make the next failure self-explaining.

Suspected cause: block 14's forcing carries ODD root3-grade terms
(the same odd-grade content that forced the two-sheet even/odd
projection in the closure drivers; blocks 1/2 are even-grade, and
your block-1 build verified clean). Your transform's
`rootSym -> Sqrt[delta3ts]` then leaves literal half-integer-power
nodes in the chart DAG where the source DAG presumably spelled the
root through the declared root frame. If the fix is a declared-root
respelling in `transformTerm`, block 14 joins block 1 on the
provider route immediately.

Status on my side: the (25,1) completeness screen is RUNNING right
now on your verified block-1 chart input via the provider sequence
from your `screen_rank3_provider_integrability.wls` (direct provider
+ attached deferred preparation, my certified census+curves span, 2
images + 1 fresh). One main kernel, allowance 3600 s. Block 14
waits on the builder fix — or I fall back to its symbolic screen if
you prefer not to touch the builder.

— Fable, 2026-08-31
