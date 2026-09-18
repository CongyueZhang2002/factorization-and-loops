# Pro review 19: physical complement-mass periods

Actual ChatGPT 6 Pro, worked for 12m15s in
https://chatgpt.com/c/6aace49d-0888-83e8-a5f1-a9277443ef84.
Code supplied after push: `1b8397b79b1062f7ef42aa5923462b74a9acd47a`.
This is a faithful mathematical summary, not a verbatim transcript.
No measured published NLO EEC coefficient was requested or used. These are
independently derived universal scalar integrals, not hard-function inputs.

Pro inspected the pair-chart/Euler/recoil routines, polynomial-root and dimension
guards, family convention comparison, angular normalization routines, and the
exact differential-consequence implementation. It did not execute our Wolfram
tests or inspect the saved master files. It separately performed symbolic algebra
and Python quadratures.

## Normalization and physical branch

For s=q^2, Q_i=(q-p_i)^2, x_i=2q.p_i/s, the unit measurement polynomial is
G=s^2 x1 x2 (z-r)/2. Let V=v(1-v), x1=u v, x2=u(1-v),
lambda=sqrt(1-4z V), U=2/(1+lambda), and rho=1-u+z V u^2.
The physical branch is 0<v<1 and 0<u<U. The second rho-positive branch
u>2/(1-lambda)>=2 violates positive recoil energy.

C(e)=(4Pi)^(3e) Gamma(1-e)/(2048 Pi^5 Gamma(2-2e)^2).
The exact unit-cut energy measure is
2 C(e) s^(-3e) [z(1-z)]^(-e) u^(1-4e) V^(-2e) rho^(-e) du dv,
times the normalized recoil angular measure. Thus C(0)=1/(2048 Pi^5).
With A_e(lambda)=2F1(1/2,1;3/2-e;lambda^2),
<1/Q3>=2 A_e/(s u) and <1/(Q3 Q4)>=4 A_e/(s^2 u^2).
The recoil code divides its physical angular integral by Phi2 exactly once;
Pro found no missing angular volume, 2Pi or factorial factor.

## Explicit scalar coefficients

Set p=(1-sqrt(1-z))/(1+sqrt(1-z)), z=4p/(1+p)^2,
lambda=(1-p)/(1+p)*(1+p t^2)/(1-p t^2), t in (0,1).
The two v branches are v_+=(1+w)/2, v_-=(1-w)/2,
w=(1-p)t/(1-p t^2). Their combined absolute differential divided by lambda
is (1+p)/(1-p t^2) dt. There is no extra factor of two.
L(t)=log[(1-p^2 t^2)/(p(1-t^2))].

For integer k>=0,
H_k=[integral dPhi4 delta(G) s12^k/Q3]_(e^0)
=2 C0 s^(k-1) (1+p)^2 p^k/(2k+1)
 times integral_0^1 (1-t^2)^k/(1-p^2 t^2)^(k+1) L(t) dt.
In particular H0=2C0/(s z)[2Li2(z)+log(z)log(1-z)].
The tagged double complement is
J=[integral dPhi4 delta(G)/(Q1 Q2)]_(e^0)
=2C0/s^2 [zeta2+Li2(z)+log(1-z)^2/2].

For the mixed tagged/untagged period,
d_+=(1-p)(1-t)/(2(1+p t)), d_-=(1-p)(1+t)/(2(1-p t)),
M13=-2C0/s^2 (1+p) integral_0^1 L(t)*
 [log(d_+)/((1+t)(1-p t))+log(d_-)/((1-t)(1+p t))] dt.
This is a GPL of weight at most3. Keep the complete coefficient of the apparent
1/(1-t) pole together: d_-(1)=1, so its logarithm cancels that pole.

For N34=integral dPhi4 delta(G)/(Q3 Q4), first subtract the soft radial endpoint:
integral_0^1 tau^(-1-4e)(1-tau)^(-e)(1-kappa tau)^(-e) d tau
=-1/(4e)+integral_0^1 tau^(-1-4e)[(1-tau)^(-e)(1-kappa tau)^(-e)-1]d tau.
The residue is
[N34]_-1=-C0/(s^2 sqrt(z)) [Pi^2/4+Li2(-chi)-Li2(chi)],
chi=(1-sqrt(z))/(1+sqrt(z)). Store coverage through -1 only, never an invented
zero finite coefficient or an exact terminating tail.

## Regulator convergence

For fixed z in a compact subset of (0,1), u=U tau and
kappa=(1-lambda)/(1+lambda)<=p<1. For 0<delta<1/4,
|A_e|<=C_delta [v(1-v)]^(-delta) uniformly on compact |Re(e)|<=delta.
This follows directly from the normalized angular beta integral with singular
part bounded by integral a^(-delta)/(v(1-v)+a) da.

H_k is bounded by tau^(2k-4delta)(1-tau)^(-delta)
[v(1-v)]^(k-3delta), which is integrable. The mixed corner w=1-v,
eta=1-tau has majorant w^(-3delta) eta^(-delta)/(w+eta).
With w=r theta, eta=r(1-theta), the radial power is -4delta>-1.
For J the only extra corner has denominator x+(1-y), giving radial power
-3delta>-1. Hence all these finite periods are holomorphic on a sufficient
strip |Re(e)|<1/4. The radially subtracted N34 remainder is holomorphic there.
The bounds also justify the real limit of the original certified prescriptions.
These are **fixed-interior** proofs; none is uniform at z=0 or1 and none determines
measured endpoint distributions or contact order.

## Epsilon orders and next coefficients

Do not feed finite values to the exact-function DE helper. If I1'=e I2, I1
through e^1 is needed for finite I2. Division by a DE coefficient of valuation r
consumes r orders; apply the omitted-tail audit to the full differentiated numerator.
For higher H_k coefficients, radial integration gives
B(2k+1-4e,1-e) 2F1(e,2k+1-4e;2k+2-5e;kappa).
The mixed radial factor is B(1-4e,1-e) AppellF1(1-4e;e,1;2-5e;kappa,vU).
For the first additional order, expand the defining rational-log radial kernel
and integrate with GPL machinery instead of building an Appell engine.

## Independent checks

At z=1/3, after removing the stated scalar normalization:
H0:3.533626231043699899944447; H1:0.07029204197062292253820;
J:2.093348273771872638915480; M13:6.474962697350475509914;
N34 residue after dividing by -C0/s^2:3.337857454270888213857783.
Pro's independent v- and t-quadratures agreed beyond35 digits at z=1/3 and3/5
for H0,H1,H2,M13 and the explicit J/residue forms. These were Pro's Python
checks, separate from our retained production checks.
