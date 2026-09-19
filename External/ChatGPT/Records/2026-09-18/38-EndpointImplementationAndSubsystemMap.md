# Pro review 38: endpoint implementation and closed subsystems

Actual ChatGPT 6 Pro, same retained EEC conversation. Worked for8m47s.
Inspected exact pushed revision
2c4638402e6f8c0d4594272a5f80ea5b3330150e: full polynomial measurement bounds,
RegulatorScaling.wl, EndpointExpansion.wl, their relevant tests, supporting GPL
series and boundary connection residual machinery. Static source inspection;
no Wolfram execution, production artifact inspection or timing verification.
Pro reported two separate one-dimensional Python checks of GPL identities.

Accepted the supported endpoint certificate, full generalized-eigenspace
selection and GPL reflection/scaling implementation. No missing sign, reversed
word, angular normalization or tangent logarithm was found. The beta majorant
is only up to an epsilon-dependent constant. The zero-amplitude identity is
continued, not the growth inequality itself near epsilon zero. Seed saturation
must retain its exact amplitude-coordinate change and Laurent valuations.

Reflection uses G(w;1-eta)=sum_k G(1-w_1,...,1-w_k;eta) RegG(w_tail;1).
The two minus signs cancel, with no word reversal. Shuffle multiplicities,
all-zero/all-one endpoint constants and the positive log(a) trailing-zero
correction were accepted. Explicit identities include
G(1,1,0;1-rho)=zeta(3)+zeta(2)log(rho)-Li_3(rho) and
G(a,0;a-rho)=zeta(2)-Li_2(rho/a)+log(a)log(rho/a).

For an exact closed known subsystem P_K A=A_K P_K, the restriction of the
admissible full fundamental solution equals Psi_K C_K(epsilon). Normalize
both generic spectra to beta epsilon. If
Q=H_K^-1 G_K^-1 P_K G H S, then rho Q'=R_K Q-Q R_A. At generic epsilon,
no nonzero integer equals an eigenvalue difference, so Q_n=0 for n!=0 and
R_K Q_0=Q_0 R_A. The exact constant matrix Q_0 is the restriction map;
its kernel contains precisely the structurally invisible amplitude directions.

A pole bound p for G_K^-1 P_K G determines sufficient normal jets through p.
Do not infer sufficiency from stabilization of a short sampled/truncated rank.
If integer exponent offsets remain, normalize them or retain their resonances.
Complete Jordan chains and the saturation change must enter the map.

Partial donor data fix only the available coefficients in visible directions.
Inverse-matrix Laurent valuations determine needed donor depth. Unknown donor
tails remain explicit variables. Apply the43 inclusive moment responses to
the residual amplitude directions, subtracting only actually known visible
contributions. Inclusive values are global equations, not point values.

This review did not inspect the subsequently implemented closed-subsystem map
or establish the reported production rank; those require their own exact run.
