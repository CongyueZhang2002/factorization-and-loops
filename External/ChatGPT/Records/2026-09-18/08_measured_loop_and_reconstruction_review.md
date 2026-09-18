# GPT-6 Pro — measured loop densities and homogeneous reconstruction

Actual GPT-6 Pro, 11m48s, in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
Static inspection of pushed commit ad73a3623308f96518e22e5286bf3c954cc511fd;
no jobs were executed by Pro and no published NLO EEC coefficient was used.

Inspected: the complete new MeasurementPushforward, OneLoopMeasurement and
MeasuredOneLoop modules; equation scale removal/restoration, the Kira job writer
and selection closure; their tests; one-loop reduction/expansion/triangle and
endpoint providers; CutSystems; and the changed tree, virtual-cache and zero-map
paths.

## Accepted structure

The RV measurement numerator/Jacobian appears once. The transported input is a
scalar density, not the old coordinate measure, so no extra old-to-new-chart
Jacobian is missing. PaVe scalar functions retain the TID i*pi^2 coefficient;
pi^(-epsilon) is applied by scalar evaluation, not once again as an independent
branch factor. The declared current normalization and generated state counts
are consistent, and the output remains one causal amplitude orientation.

Scale removal is an exact change I_i=s^w_i J_i checked on every equation.
Restoration s^(w_i-w_j) is correct; the omitted common loop-measure degree is
irrelevant to this change of unknowns. Selected dependencies are closed before
units are restored, and cached restored reductions are not rescaled twice.
FireFly uses full rational reconstruction, distinct from a numerical sample.
Reduction reconstruction, selected-export closure and DE closure are separate
completion statements. A fresh-prime check remains appropriate for reconstructed
coefficients; a one-variable flatness check is not such a test.

## Concrete repairs

1. Scalar extraction by Coefficient plus the zero-scalar term did not prove
   linearity: B0^2 could silently become zero. Reuse polynomial aliases and
   reject total degree above one. Implemented, with a rejecting regression.
2. The decay guard read IncomingPartons rather than the selected channel's
   Incoming field. Check the selected channel and incoming momenta before
   generation. Implemented, with a rejecting regression.
3. Requested pushforward assumptions replaced the defining domain. Intersect
   them instead. Implemented, with a restricted-domain regression.

The current EEC source does not exercise the invalid inputs; these defects did
not demonstrate a wrong coefficient in its successful preparation.

Pro also requested a small forced extended-selection/import test with scale
removal. That path now passes in the seven-assertion scale regression: an intentionally incomplete native export triggers selection closure, agrees with the direct reduction, and restores units once. The supervised test took 16.77 s.

## Remaining energy integral

The three physical one-mass boxes admit either simultaneous hypergeometric
inversion or the implemented correlated-difference representation at both energy
endpoints, for a fixed measurement in a compact subset of (0,1). At x=1 use
t=1-x on the entire density. Keep local validity domains; do not apply a corner
representation across the whole interval. Coincident bubble differences must
remain correlated.

Expansion under the energy integral is justified after clearing finite regulator
poles if every surviving regulated endpoint term has integer power alpha>-1,
with analytic factors and controlled remainder. Group equal regulator slopes
before using cancellation; epsilon*t^(-1+epsilon) is a counterexample to using
the finite interior alone. If needed, subtract Taylor terms through
floor(-1-p(0)) and keep their collar integrals regulated until order planning.

Prescribed external factors retained only as metadata are not an endpoint
certificate. The original prescribed source must be connected to its rational
interior by a dominated limit or explicit boundary terms. The subsequently
developed implementation therefore partitions the original scalar-loop source
by external propagator product and checks each component separately, using
|(g+i*eta*delta)^(-n)| <= |g|^(-n) for real nonzero g and positive integer n.
This additional implementation was not present in the reviewed commit.

Even a completed fixed-z energy integration is only the RV interior. Regulated
measurement-variable endpoints, self contacts, physical contact-order bounds
and Hermitian completion remain. No full alpha_s-squared result is claimed.
