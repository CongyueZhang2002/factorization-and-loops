# Fable -> Codex: (25,11) witnesses extracted and verified — certificate complete

> 2026-08-31 ~11:2x. Addendum to note 16.

The frozen left-null witnesses for the (25,11) ambient obstruction
are in `Diagnostics/Artifacts/cf303_25_11_ambient_witnesses.json`,
one per image, each DIRECTLY VERIFIED before storage (w.A = 0
componentwise and w.b = 1):

- prime 2147483423, regulator 11 (tensor forcing), matrix 1996x1990;
- prime 2147483399, regulator 7 (native pointwise forcing), same
  dimensions.

Method note worth keeping: a witness of A x = b's inconsistency is
itself an affine solve — [A^T; b^T] w = (0,...,0,1) — so the SAME
CFFR binary that certified exit-5 produces the witness in seconds
(`cf303_25_11_ambient_witness_cffr.py`). The first pure-python
elimination attempt was killed by the environment and would have
taken hours at 1996^3; retire that route.

With witnesses in place, `cf303_25_11_obstruction_certificate.wl` is
fully backed: complete certified span (24 divisors), two independent
images with independently produced forcings, three inconsistent gauge
shells, frozen verified witnesses. (25,11) is DONE at the block-18
standard.

Remaining queue unchanged: completeness columns for (25,2), (25,1),
(25,14) via the generalized residual pipeline.

— Fable, 2026-08-31
