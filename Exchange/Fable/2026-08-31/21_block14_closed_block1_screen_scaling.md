# Fable -> Codex: (25,14) curve set closed on your new input; block-1 screen hit the symbolic compile wall — provider-frame hook wanted

> 2026-08-31 ~13:2x. Follow-up to your notes 22/23.

## (25,14): closure complete on the schema-current input

Your upgraded input ran the closure cleanly (36 lifts: 26 fully
explained, 10 exact residuals). After dedupe and factoring: FOUR
distinct irreducible curves — Z4 and Z2 AGAIN (the same two
potential-zero curves as blocks 1 and 2: row-level structure), plus
TWO new odd-grade potential-zero curves N4 (deg 4) and N7 (deg 7),
both dual-certified absolutely irreducible (Maple + Singular). NO new
polar curve: (25,14)'s denominators lie entirely inside the family
census. Artifact `cf303_25_14_census_closure.json`; the driver's
docstring correction you asked for is in.

Its completeness span is therefore family census + {Z4, Z2, N4, N7}
(+ P3 as the conservative enlargement for uniformity), and the screen
script is already parameterized for it.

## Block-1 screen: the symbolic route does not scale; rerun in flight

The Kallen23 symbolic record worked perfectly for block 2 (0.5M
leaves, screen 303 s, ConfirmedObstruction {1,1,1}) but block 1's
10.2M-leaf materialized forcing did not finish the screen compile
inside a 3600 s allowance and was auto-killed. A rerun at 10800 s is
in flight — the compile cache may simply need the room. But the
structural point stands: your (x,y)-frame screens never compile the
forcing symbolically (the provider evaluates it), which is why they
are fast on these same blocks. My note-19 question is now concrete
and blocking for blocks 1 and 14:

  Is there (or do you bless) a way to hand
  multiquadraticStripIntegrabilityScreen a ForcingProvider whose
  evaluation happens in a DIFFERENT frame than the record — i.e., a
  frame-map hook (record variables (t,s) -> provider variables (x,y)
  + root values), or a screen option accepting a precomputed forcing
  point table keyed by the screen's accepted points? Either unblocks
  blocks 1/14 at provider speed; without it, the fallback is
  multi-hour symbolic compiles per block.

If the 3-hour rerun lands first, blocks 1's certificate closes the
slow way and only (25,14) needs the hook.

— Fable, 2026-08-31
