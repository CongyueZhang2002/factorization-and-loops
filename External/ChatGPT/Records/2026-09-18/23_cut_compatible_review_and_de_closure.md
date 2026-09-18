# Cut-compatible IBPs and controlled differential closure

Actual ChatGPT 6 Pro, completed after 8m41s in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
Exact source revision inspected: 66be3cfec7a804aaafa984d1ea474b83fcab9371.
This was static source inspection plus an independent symbolic algebra example;
Pro did not execute our tests or inspect our saved inclusive physics results.

Pro found the polynomial vector construction, full divergence, protected
cofactor sign, and treatment of the dependent measurement mathematically sound.
Individual off-shell divisibility is checked; no cut-dot-removal theorem or
complete syzygy module is asserted. Unexported finite-field columns remain
conservative formal remainders, and omitting rank calculations is sound when
only support emptiness guides an exact subsequent solve.

Two orchestration improvements remain:

1. Predecessor discovery must use the same ordinary/compatible operator shifts
   as equation generation. It currently always uses ordinary operators.
   Expose particle-only versus all-cut protection for derivative targets.
2. Before promoting provisional dotted integrals into the next differentiated
   basis, attempt bounded exact reduction into a declared candidate span.
   Keep the differentiated basis fixed throughout that search. A bounded miss
   must return a frontier, not start differentiating it automatically. Retain
   the original source reconstruction map separately instead of reseeding the
   entire source inventory in each derivative solve.

The source span need not be derivative invariant. A candidate set must be
enlargeable explicitly; failure does not establish irreducibility. A future
inhomogeneous lift (partial_z + V)G_b = f_b G_b can avoid some measurement dots
but is separate work and not required for this controlled closure.

Suggested dependent-measurement regression (full D, no on-shell substitution):
x_i=k_i^2, omega=k1.k2, y_i=q.k_i, q^2=s;
G3=(q-k1-k2)^2; M=z(y1+y2)^2-s(k1+k2)^2.
W=omega q-y2 k1-y1 k2; V1=y1 W, V2=-y1 W.
Then Vx1=-2 y1 y2 x1, Vx2=2 y1^2 x2, VG3=VM=0, and
div V=D y1(y1-y2)+s omega-2 y1 y2. The last two terms are
from differentiating the polynomial multiplier and must be retained.

No measured EEC hard coefficient was consulted or compared.
