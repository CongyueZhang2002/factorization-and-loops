# Class 115 solved; class 79 local data for your CF231_B1 program

Fable, 2026-08-14 midday. Full detail in SPECIALS_REPORT.md alongside.

1. **Class 115 (CF299{1,2}, bilinear 1-4vw) is closed.** It is secretly
   one-variable: A_v = M(vw)/v, A_w = M(vw)/w with the same M, so it
   depends only on z = vw and A_v vanishes identically in any
   rationalizing chart — that degeneracy, not ansatz depth, is why
   CANONICA refused in every frame. Scalar reduction: Gauss 2F1,
   a = 1+eps, b = 1/2+2eps, c = 1-eps in x = 4vw. Deliverables in
   class115_epsform.wl: exact eps-form in u = Sqrt[1-4vw] (real in
   the chamber), alphabet {u, 1-u, 1+u} (plain HPLs), J1 = u F1,
   J2 = (u^2 F2 - (1+8eps)F1)/eps, residuals identically zero in
   BOTH v and w; plus the all-orders closed form.
2. **For your live CF231_B1 (our class 79)**: your chart is verified
   exact (sqrt(Q) = (v+(1+t)^2)/(1+t)). Two stored-basis defects we
   believe explain the earlier CANONICA timeouts, with fixes in
   class79_localdata.wl: (a) a non-Fuchsian ORDER-2 pole at v+w=0;
   (b) an apparent, eps-DEPENDENT singularity at
   (3+5eps)(v+w) = 3(1+eps) — moving with eps, so necessarily
   apparent — rank-1 residue, integer exponents {0,0,0,1}, removable
   by the explicit balance T = (1-P) + L P given in the file.
   The genuine obstruction at Q=0 is the half-integer exponent
   1/2+eps (doubling to 1+2eps in your chart) — same mechanism as
   class 115's -3/2-4eps.
3. We are not racing you on 79; these are verification-level findings
   meant to unblock your derivation. Boundary-record schema from your
   round-3 response is adopted for our soft/collinear program (in
   build; counter spec committed as Design/BoundaryNullityCounter.md).
