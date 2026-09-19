# GPT-6 Pro: fiber implementation and differential recovery

Actual 6 Pro, same authorized conversation:
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84

Response completed after4m36s. Pro accessed exact revision
`d88d6195d21bf9414c7c293473270ff400fed12b` and inspected the complete fiber-bound
module, GPL converter, GiNaC evaluator, affine-path tests, updated bound tests
and numerical dispatch. Static inspection only; no Wolfram execution or
verification of production artifacts/timings. This record summarizes the response.

The fixed-fiber proof was accepted on its declared generic interior domain.
It binds the actual Gram, slope, root, complete chart, face exponents and
normalization. RootJacobian1 is distinct from the retained original1/|F|.
It does not imply endpoint uniformity or identical bounds after epsilon-valued
basis transformations.

Positive affine scaling was accepted: c=|u-u0|>0, tau=c*t, and the sign of
u-u0 remains in the original path kernel. Lower tangents stay positive, and
the complete substitution through the existing GPL pullback preserves log(c)
and trailing-zero terms. The original source-path checker was not weakened.

One concrete reuse finding: reconverting a right-domain result with
RescalePathParameter=False could reuse the old expressions but overwrite
PathParameterScale with1. Checking that scale alone then lost the old domain
restriction. The continuation now checks all saved conversion assumptions at
nonstationary numerical points, including after policy-changing reuse. The
separately proved stationary calculation remains available. Twelve focused
assertions pass0.964s, including this regression.

## Differential consequences of known physical functions

For I'=A I and Y=H I, define H_0=H, H_(r+1)=H_r'+H_r A. Stacking the rows gives
R I=D Y. A target row e_j^T=L_j R, verified exactly over the rational coefficient
field, determines I_j=L_j D Y without new integration constants. It is also
useful to test the actual source row rather than all coordinates. Sampled
pivots can guide the selection but are not a proof. Differentiate only newly
independent rows, and retain RHS operators; recombining rows introduces product
rule derivatives of their coefficients.

Prove stabilization by R'+R A=K R exactly. Then further derivatives cannot
enlarge the row span. For exact known functions, a rank-r span leaves42-r
invisible homogeneous directions. Finite epsilon coverage can leave additional
order gaps even within that span. Collect coefficients of identical derivative
inputs before applying the existing valuation/omitted-tail audit. Do not
assume different unknown tails cancel. Gauge factors must be included when
using a prepared basis.

The ten evaluated moments are global integral constraints on the residual
subspace, not pointwise known functions. Their rank on that subspace remains to
be evaluated. In the current production inventory, a sampled derivative test
gave rank16 from16 known records and no increase after one derivative. Exact
closure still needs checking before labeling the other26 directions invisible.
