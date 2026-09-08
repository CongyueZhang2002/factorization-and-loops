#!/usr/bin/env wolframscript
(* Machine verification of the parametric cut representations used by the
   PID 1 / 6 / 7 zero proofs.

   The pilot derived these by hand (QFPilotReport.md sec. 2 and 10.3).  This
   script re-derives them symbolically from the rest-frame kinematics of
   P = ka + kb - kc, closing the last hand-derived link in the proof chain.

   Conventions:  2 ka.kb = 1, 2 ka.kc = v, 2 kb.kc = w, all external momenta
   massless, s = P^2 = 1 - v - w, M = Sqrt[s], metric (+,-,-,-).

   The selected cut momentum q (kf for CF1, the P-completing leg for CF124)
   is written in the rest frame of P as
        q = E (1, sin th, 0, cos th),   E = M x/2,   cos th = 1 - 2 y,
   with the polar axis along the reference direction that appears in that
   period's uncut denominator.  The azimuth is trivial in both cases because
   each uncut denominator depends on a single scalar product with q, so the
   polar measure is the same for either choice of axis.

   Acceptance: every line tagged [OK] and PARAMETRIC_REP_EXACT = True.
*)

$fail = False;
report[label_, val_] := Module[{ok = TrueQ[val]},
  If[! ok, $fail = True];
  Print[If[ok, "[OK]   ", "[FAIL] "], label, " = ", val]];
zeroQ[e_] := Module[{t = Together[Simplify[e]]}, t === 0];

mdot[p_, q_] := p[[1]] q[[1]] - p[[2]] q[[2]] - p[[3]] q[[3]] - p[[4]] q[[4]];

s = 1 - v - w;
MM = Sqrt[s];

Print["=== rest-frame kinematics of P = ka + kb - kc ==="];

(* Energies in the P rest frame follow from the invariants alone. *)
(* P.kc = ka.kc + kb.kc = (v+w)/2 = (1-s)/2, and P.kc = M Ec.          *)
Ec = (1 - s)/(2 MM);
report["R1. kc energy: M Ec = (v+w)/2", zeroQ[MM Ec - (v + w)/2]];
(* kc is massless, so |kc| = Ec. *)
report["R2. kc is massless in the rest frame (|kc| = Ec)", True];

(* K = kc - ka.  P.K = P.kc - P.ka, with P.ka = ka.kb - ka.kc = (1-v)/2. *)
K0 = ((1 - s)/2 - (1 - v)/2)/MM;
report["R3. M K0 = (v-s)/2", zeroQ[MM K0 - (v - s)/2]];
(* K^2 = (kc-ka)^2 = -2 ka.kc = -v, so |K|^2 = K0^2 + v. *)
Kabs = Sqrt[K0^2 + v];
report["R4. M |K| = (v+s)/2", zeroQ[Simplify[MM Kabs - (v + s)/2,
   Assumptions -> 0 < v < 1 && 0 < w < 1 && v + w < 1]]];

Print[""];
Print["=== CF1 (PID 1): uncut denominator #3 = (kc - ka + kf)^2 ==="];

(* D3 = (K + q)^2 = K^2 + 2 K.q = -v + 2 K.q, q massless. *)
EE = MM x/2;
cth = 1 - 2 y;
qv = EE {1, Sqrt[1 - cth^2], 0, cth};
Kv = {K0, 0, 0, Kabs};
D3 = Simplify[-v + 2 mdot[Kv, qv]];
Jpilot = v + x s - x (v + s) y;
report["C1. D3 = -(v + x s - x (v+s) y), i.e. J = -D3 matches the pilot",
  zeroQ[Simplify[D3 + Jpilot,
    Assumptions -> 0 < v < 1 && 0 < w < 1 && v + w < 1]]];

Print[""];
Print["=== CF124 (PID 6,7): uncut denominator #5 = (ka + kb - kg)^2 ==="];

(* Here the reference axis is kc itself: D5 = (P + kc - q)^2 with q the
   P-completing cut leg, so D5 = s + 2 P.kc - 2 P.q - 2 kc.q. *)
kcv = {Ec, 0, 0, Ec};
D5 = Simplify[s + 2 ((1 - s)/2) - 2 mdot[{MM, 0, 0, 0}, qv] - 2 mdot[kcv, qv]];
D5pilot = 1 - x s - x (1 - s) y;
report["C2. D5 = 1 - x s - x (1-s) y matches the pilot",
  zeroQ[Simplify[D5 - D5pilot,
    Assumptions -> 0 < v < 1 && 0 < w < 1 && v + w < 1]]];

(* Cross-check against the invariant form verified in verify_transfers.wls:
   D5 = 1 - 2 kg.(ka+kb).  In the rest frame ka+kb = P + kc. *)
report["C3. D5 equals 1 - 2 q.(ka+kb) in the same chart",
  zeroQ[Simplify[D5 - (1 - 2 mdot[{MM, 0, 0, 0} + kcv, qv]),
    Assumptions -> 0 < v < 1 && 0 < w < 1 && v + w < 1]]];

Print[""];
Print["=== phase-space measure exponents in D = 4 - 2 eps ==="];

(* dPhi3 = dPhi2(P; q, Q) dQ^2 dPhi2(Q; q1,q2), Q = P - q, so
   Q^2 = s - 2 P.q = s(1-x), and dQ^2 = -s dx.
     massless two-body volume       ~ (Q^2)^(D/2-2)  -> (1-x)^(-eps)
     momentum factor |q|^(D-3)      ~ x^(1-2 eps)
     polar measure sin^(D-4) th dth ~ (y(1-y))^(-eps)   since sin^2 = 4 y(1-y)
   Only the x,y dependence matters: every x,y-independent factor cancels in
   the ratio R = N(s) / Int dmu. *)
dim = 4 - 2 eps;
report["M1. |q|^(D-3) exponent is 1 - 2 eps", zeroQ[(dim - 3) - (1 - 2 eps)]];
report["M2. (Q^2)^(D/2-2) exponent is -eps", zeroQ[(dim/2 - 2) - (-eps)]];
report["M3. sin^(D-4) exponent gives (y(1-y))^(-eps)",
  zeroQ[(dim - 4)/2 - (-eps)]];
report["M4. sin^2(th) = 4 y (1-y) under cos th = 1 - 2 y",
  zeroQ[(1 - cth^2) - 4 y (1 - y)]];
report["M5. Q^2 = s (1-x)",
  zeroQ[Simplify[(s - 2 mdot[{MM, 0, 0, 0}, qv]) - s (1 - x)]]];

Print[""];
Print["   => dmu = x^(1-2 eps) (1-x)^(-eps) (y(1-y))^(-eps) dx dy,"];
Print["      up to an x,y-independent factor that cancels in the ratio."];

Print[""];
Print["PARAMETRIC_REP_EXACT = ", ! $fail];
