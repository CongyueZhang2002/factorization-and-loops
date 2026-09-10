(* Exact analytic NLO spacelike UU/LL and timelike UU splitting functions.
   Reproduced from APFEL++ commit 27deaec493d95bad0686b3b1c91fbbc910c891ff.
   Universal kernels only; no SIDIS coefficient functions are used.
   Tests/Support/translate_apfel_nlo_splitting.py reproduces these definitions.
   Sources and the GPL-3.0 license are in External/References/SIDIS/APFEL_Splitting.
   The retained base expressions use alpha_s/(4 Pi), converted at the public
   boundary. Singlet multiplicities are removed for individual species.
   Closed quark loops carry TR nf. Pure singlets and g->q carry TR; the
   timelike q->g singlet factor 2 nf is a multiplicity and carries no TR. *)
BeginPackage["FeynFacet`"];
NextToLeadingSplittingKernel::usage="NextToLeadingSplittingKernel[daughter,parent,spin,x,parameters,evolution] returns individual-species P^(1) in a=alpha_s/(2 Pi), with explicit delta/plus/regular coefficients. Evolution is SpaceLike (UU/LL) or TimeLike (UU). Labels always mean physical daughter <- parent; a fragmentation matrix has parent as its row. LL is the conventional helicity MSbar scheme.";
Begin["`Private`"];
splittingNLORegular["SpaceLike","U","nsp",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,pqq,pqqmx,S2x,gqq1,gqq1l},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1 - x];
 pqq=2 / ( 1 - x ) - 1 - x;
 pqqmx=2 / ( 1 + x ) - 1 + x;
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 gqq1=+ 2 * cf * (2 tr nf) * ( ( - 10 / 9 - 2 * lnx / 3 ) * pqq - 4 * ( 1 - x ) / 3 )
      + 4 * ca * cf * ( ( 67 / 18 + 11 * lnx / 6 + lnx2 / 2 - Pi^2 / 6 ) * pqq
                        + 20 * ( 1 - x ) / 3 + lnx * ( 1 + x ) )
      + 4 * cf * cf * ( ( - 3 * lnx / 2 - 2 * ln1mx * lnx ) * pqq - 5 * ( 1 - x )
                        - lnx2 * ( 1 + x ) / 2 - lnx * ( (3/2) + 7 * x / 2 ) )
      + 4 * cf * ( cf - ca / 2 ) * ( 2 * pqqmx * S2x + 4 * ( 1 - x ) + 2 * lnx * ( 1 + x ) );
 gqq1l=(-80 cf tr nf/9+(268/9-8 Zeta[2])ca cf) / ( 1 - x );
 gqq1 - gqq1l
];

splittingNLORegular["SpaceLike","U","nsm",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,pqq,pqqmx,S2x,gqq1,gqq1l},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1 - x];
 pqq=2 / ( 1 - x ) - 1 - x;
 pqqmx=2 / ( 1 + x ) - 1 + x;
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 gqq1=+ 2 * cf * (2 tr nf) * ( ( - 10 / 9 - 2 * lnx / 3 ) * pqq - 4 * ( 1 - x ) / 3 )
      + 4 * ca * cf * ( ( 67 / 18 + 11 * lnx / 6 + lnx2 / 2 - Pi^2 / 6 ) * pqq
                        + 20 * ( 1 - x ) / 3 + lnx * ( 1 + x ) )
      + 4 * cf * cf * ( ( - 3 * lnx / 2 - 2 * ln1mx * lnx ) * pqq - 5 * ( 1 - x )
                        - lnx2 * ( 1 + x ) / 2 - lnx * ( (3/2) + 7 * x / 2 ) )
      - 4 * cf * ( cf - ca / 2 ) * ( 2 * pqqmx * S2x + 4 * ( 1 - x ) + 2 * lnx * ( 1 + x ) );
 gqq1l=(-80 cf tr nf/9+(268/9-8 Zeta[2])ca cf) / ( 1 - x );
 gqq1 - gqq1l
];

splittingNLORegular["SpaceLike","U","ps",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2},
 lnx=Log[x];
 lnx2=lnx * lnx;
 (2 tr nf) * cf * ( - 8 + 24 * x - 224 / 9 * x * x + 80 / 9 / x
                   + ( 4 + 20 * x ) * lnx + 32 / 3 * x * x * lnx
                   - ( 4 + 4 * x ) * lnx2 )
];

splittingNLORegular["SpaceLike","U","qg",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,pqg,pqgmx,S2x},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1 - x];
 pqg=x * x + ( 1 - x ) * ( 1 - x );
 pqgmx=x * x + ( 1 + x ) * ( 1 + x );
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 + 2 * cf * (2 tr nf) * ( 4  + 4 * ln1mx + ( 10 - 4 * ( ln1mx - lnx ) + 2 * ( - ln1mx + lnx ) * ( - ln1mx + lnx ) - 2 * Pi^2 / 3 ) * pqg
                         - lnx * ( 1 - 4 * x ) - lnx2 * ( 1  - 2 * x ) - 9 * x )
      + 2 * ca * (2 tr nf) * ( 182 / 9 - 4 * ln1mx
                         + ( - 218 / 9 + 4 * ln1mx - 2 * ln1mx * ln1mx + 44 * lnx / 3 - lnx2 + Pi^2 / 3 ) * pqg
                         + 2 * pqgmx * S2x + 40 / ( 9 * x ) + 14 * x / 9 - lnx2 * ( 2 + 8 * x )
                         + lnx * ( - 38 / 3 + 136 * x / 3 ) )
];

splittingNLORegular["SpaceLike","U","gq",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,pgq,pgqmx,S2x},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1 - x];
 pgq=( 1 + ( 1 - x ) * ( 1 - x ) ) / x;
 pgqmx=- ( 1 + ( 1 + x ) * ( 1 + x ) ) / x;
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 + 2 * cf * (2 tr nf) * ( - ( 20 / 9 + 4 * ln1mx / 3 ) * pgq - 4 * x / 3 )
      + 4 * cf * cf  * ( - (5/2) - ( 3 * ln1mx + ln1mx * ln1mx ) * pgq - lnx2 * ( 1 - x / 2 ) - 7 * x / 2
                         - 2 * ln1mx * x + lnx * ( 2 + 7 * x / 2 ) )
      + 4 * ca * cf  * ( 28 / 9 + pgq * ( (1/2) + 11 * ln1mx / 3 + ln1mx * ln1mx - 2 * ln1mx * lnx + lnx2 / 2 - Pi^2 / 6 ) + pgqmx * S2x
                         + 65 * x / 18 + 2 * ln1mx * x + 44 * x * x / 9 + lnx2 * ( 4 + x ) - lnx * ( 12 + 5 * x + 8 * x * x / 3 ) )
];

splittingNLORegular["SpaceLike","U","gg",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,pgg,pggmx,S2x,ggg1,ggg1l},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1 - x];
 pgg=( 1 / ( 1 - x ) +  1 / x - 2 + x * ( 1 - x ) );
 pggmx=( 1 / ( 1 + x ) -  1 / x - 2 - x * ( 1 + x ) );
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 ggg1=+ 2 * cf * (2 tr nf) * ( - 16 + 4 / ( 3 * x ) + 8 * x + ( 20 * x * x ) / 3 - lnx2 * ( 2 + 2 * x ) - lnx * ( 6 + 10 * x ) )
      + 2 * ca * (2 tr nf) * ( 2 - 20 * pgg / 9 - 2 * x - 4 * lnx * ( 1 + x ) / 3 + 26 * ( - 1 / x + x * x ) / 9 )
      + 4 * ca *  ca * ( pgg * ( 67 / 9 - 4 * ln1mx * lnx + lnx2 - Pi^2 / 3 ) + 2 * pggmx * S2x
                         + 27 * ( 1 - x ) / 2 + 4 * lnx2 * ( 1 + x ) + 67 * ( - 1 / x + x * x ) / 9
                         - lnx * ( 25 / 3 - 11 * x / 3 + 44 * x * x / 3 ) );
 ggg1l=(-80 ca tr nf/9+(268/9-8 Zeta[2])ca^2) / ( 1 - x );
 ggg1 - ggg1l
];

splittingNLORegular["TimeLike","U","nsp",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,pqq,pqqmx,S2x,gqq1,gqq1l},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1-x];
 pqq=2 / ( 1 - x ) - 1 - x;
 pqqmx=2 / ( 1 + x ) - 1 + x;
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 gqq1=+ 2 * cf * (2 tr nf) * ( ( - 10 / 9 - 2 * lnx / 3 ) * pqq - 4 * ( 1 - x ) / 3 )
      + 4 * ca * cf * ( ( 67 / 18 + 11 * lnx / 6 + lnx2 / 2 - Pi^2 / 6 ) * pqq
                        + 20 * ( 1 - x ) / 3 + lnx * ( 1 + x ) )
      + 4 * cf * cf * ( ( 3 * lnx / 2 + 2 * ln1mx * lnx - 2 * lnx2 ) * pqq - 5 * ( 1 - x )
                        + lnx2 * ( 1 + x ) / 2 - lnx * ( (7/2) + 3 * x / 2 ) )
      + 4 * cf * ( cf - ca / 2 ) * ( 2 * pqqmx * S2x + 4 * ( 1 - x ) + 2 * lnx * ( 1 + x ) );
 gqq1l=(-80 cf tr nf/9+(268/9-8 Zeta[2])ca cf) / ( 1 - x );
 gqq1 - gqq1l
];

splittingNLORegular["TimeLike","U","nsm",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,pqq,pqqmx,S2x,gqq1,gqq1l},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1-x];
 pqq=2 / ( 1 - x ) - 1 - x;
 pqqmx=2 / ( 1 + x ) - 1 + x;
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 gqq1=+ 2 * cf * (2 tr nf) * ( ( - 10 / 9 - 2 * lnx / 3 ) * pqq - 4 * ( 1 - x ) / 3 )
      + 4 * ca * cf * ( ( 67 / 18 + 11 * lnx / 6 + lnx2 / 2 - Pi^2 / 6 ) * pqq
                        + 20 * ( 1 - x ) / 3 + lnx * ( 1 + x ) )
      + 4 * cf * cf * ( ( 3 * lnx / 2 + 2 * ln1mx * lnx - 2 * lnx2 ) * pqq - 5 * ( 1 - x )
                        + lnx2 * ( 1 + x ) / 2 - lnx * ( (7/2) + 3 * x / 2 ) )
      - 4 * cf * ( cf - ca / 2 ) * ( 2 * pqqmx * S2x + 4 * ( 1 - x ) + 2 * lnx * ( 1 + x ) );
 gqq1l=(-80 cf tr nf/9+(268/9-8 Zeta[2])ca cf) / ( 1 - x );
 gqq1 - gqq1l
];

splittingNLORegular["TimeLike","U","ps",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2},
 lnx=Log[x];
 lnx2=lnx * lnx;
 (2 tr nf) * cf * ( - 32 + 16 * x + 224 * x * x / 9 - 80 / 9 / x
                   - ( 20 + 36 * x ) * lnx - 32 * x * x * lnx / 3
                   + ( 4 + 4 * x ) * lnx2 )
];

splittingNLORegular["TimeLike","U","qg",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,ln1mx2,pgq,pgqmx,S1x,S2x},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1-x];
 ln1mx2=ln1mx * ln1mx;
 pgq=( 1 + ( 1 - x ) * ( 1 - x ) ) / x;
 pgqmx=- ( 1 + ( 1 + x ) * ( 1 + x ) ) / x;
 S1x=- PolyLog[2,1-x];
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 2 * nf * ( 4 * cf * cf * ( - 1 / 2 + 9 * x / 2 + ( - 8 + x / 2 ) * lnx + 2 * x * ln1mx + ( 1 - x / 2 ) * lnx2
                                  + ( ln1mx2 + 4 * lnx * ln1mx - 8 * S1x - 4 * Pi^2 / 3 ) * pgq )
                  + 4 * cf * ca * ( 62 / 9 - 35 * x / 18 - 44 * x * x / 9 + ( 2 + 12 * x + 8 * x * x / 3 ) * lnx
                                    - 2 * x * ln1mx - ( 4 + x ) * lnx2 + pgqmx * S2x
                                    + ( - 2 * lnx * ln1mx - 3 * lnx - 3 * lnx2 / 2 - ln1mx2
                                        + 8 * S1x + 7 * Pi^2 / 6 + 17 / 18 ) * pgq ) )
];

splittingNLORegular["TimeLike","U","gq",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,ln1mx2,pqg,pqgmx,S1x,S2x},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1-x];
 ln1mx2=ln1mx * ln1mx;
 pqg=x * x + ( 1 - x ) * ( 1 - x );
 pqgmx=x * x + ( 1 + x ) * ( 1 + x );
 S1x=- PolyLog[2,1-x];
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 2 tr (+ (2 tr nf) * ( - 8 / 6 - ( 16 / 18 + 8 * lnx / 6 + 8 * ln1mx / 6 ) * pqg )
      + cf * ( - 2 + 3 * x + ( - 7 + 8 * x ) * lnx - 4 * ln1mx + ( 1 - 2 * x ) * lnx2
               + ( - 2 * Power[lnx + ln1mx, 2] - 2 * ( ln1mx - lnx ) + 16 * S1x + 2 * Pi^2 - 10 ) * pqg )
      + ca * ( - 152 / 9 + 166 * x / 9 - 40 / 9 / x + ( - 4 / 3 - 76 * x / 3 ) * lnx
               + 4 * ln1mx + ( 2 + 8 * x ) * lnx2
               + ( 8 * lnx * ln1mx - lnx2 - 4 * lnx / 3 + 10 * ln1mx / 3
                   + 2 * ln1mx2 - 16 * S1x - 7 * Pi^2 / 3 + 178 / 9 ) * pqg
               + 2 * pqgmx * S2x ))
];

splittingNLORegular["TimeLike","U","gg",x_,ca_,cf_,tr_,nf_]:=
 Module[{x2,lnx,lnx2,ln1mx,pgg,pggmx,S2x,ggg1,ggg1l},
 x2=x * x;
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1-x];
 pgg=( 1 / ( 1 - x ) +  1 / x - 2 + x * ( 1 - x ) );
 pggmx=( 1 / ( 1 + x ) -  1 / x - 2 - x * ( 1 + x ) );
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 ggg1=+ 2 * cf * (2 tr nf) * ( - 4 + 12 * x - 164 * x2 / 9 + ( 10 + 14 * x + 16 * x2 / 3 + 16 / 3 / x )
                         * lnx + 92 / 9 / x + 2 * ( 1 + x ) * lnx2 )
      + 2 * ca * (2 tr nf) * ( 2 - 2 * x + 26 * ( x2 - 1 / x ) / 9 - 4 * ( 1 + x ) * lnx / 3
                         - ( 20 / 9 + 8 * lnx / 3 ) * pgg )
      + 4 * ca * ca * ( 27 * ( 1 - x ) / 2 + 67 * ( x2 - 1 / x ) / 9
                        + ( 11 / 3 - 25 * x / 3 - 44 / 3 / x ) * lnx
                        - 4 * ( 1 + x ) * lnx2
                        + ( 4 * lnx * ln1mx - 3 * lnx2 + 22 * lnx / 3
                            - 2 * Zeta[2] + 67 / 9 ) * pgg + 2 * pggmx * S2x );
 ggg1l=(-80 ca tr nf/9+(268/9-8 Zeta[2])ca^2) / ( 1 - x );
 ggg1 - ggg1l
];

splittingNLORegular["SpaceLike","L","nsp",x_,ca_,cf_,tr_,nf_]:=
 splittingNLORegular["SpaceLike","U","nsm",x,ca,cf,tr,nf];

splittingNLORegular["SpaceLike","L","nsm",x_,ca_,cf_,tr_,nf_]:=
 splittingNLORegular["SpaceLike","U","nsp",x,ca,cf,tr,nf];

splittingNLORegular["SpaceLike","L","ps",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2},
 lnx=Log[x];
 lnx2=lnx * lnx;
 8 * nf * cf * tr * ( ( 1 - x ) - ( 1 - 3 * x ) * lnx - ( 1 + x ) * lnx2 )
];

splittingNLORegular["SpaceLike","L","qg",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,ln1mx2,dpqg,dpqgmx,S2x},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1-x];
 ln1mx2=ln1mx * ln1mx;
 dpqg=2 * x - 1;
 dpqgmx=- 2 * x - 1;
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 + 4 * nf * tr * cf * ( - 22 + 27 * x - 9 * lnx + 8 * ( 1 - x ) * ln1mx + dpqg * ( 2 * ln1mx2 - 4 * ln1mx * lnx + lnx2 - 4 * Zeta[2] ) )
      + 4 * nf * tr * ca * ( ( 24 - 22 * x ) - 8 * ( 1 - x ) * ln1mx + ( 2 + 16 * x ) * lnx - 2 * ( ln1mx2 - Zeta[2] ) * dpqg - ( 2 * S2x - 3 * lnx2 ) * dpqgmx )
];

splittingNLORegular["SpaceLike","L","gq",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,ln1mx2,dpgq,dpgqmx,S2x},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1 - x];
 ln1mx2=ln1mx * ln1mx;
 dpgq=2 - x;
 dpgqmx=2 + x;
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 + 4 * nf * cf * tr * ( - 4 * ( x + 4 ) / 9 - 4 * dpgq * ln1mx / 3 )
      + 4 * cf * cf * ( - 1 / 2 - ( 4 - x ) * lnx / 2 - dpgqmx * ln1mx + ( - 4 - ln1mx2 + lnx2 / 2 ) * dpgq )
      + 4 * cf * ca * ( ( 4 - 13 * x ) * lnx + ( 10 + x ) * ln1mx / 3 + ( 41 + 35 * x ) / 9
                        + ( - 2 * S2x + 3 * lnx2 ) * dpgqmx / 2 + ( ln1mx2 - 2 * ln1mx * lnx - Zeta[2] ) * dpgq )
];

splittingNLORegular["SpaceLike","L","gg",x_,ca_,cf_,tr_,nf_]:=
 Module[{lnx,lnx2,ln1mx,dpgg,dpggmx,S2x,ggg1,ggg1l},
 lnx=Log[x];
 lnx2=lnx * lnx;
 ln1mx=Log[1 - x];
 dpgg=1 / ( 1 - x ) - 2 * x + 1;
 dpggmx=1 / ( 1 + x ) + 2 * x + 1;
 S2x=- 2 * PolyLog[2,-x] + lnx2 / 2 - 2 * lnx * Log[1+x] - Pi^2 / 6;
 ggg1=- 4 * ca * tr * nf * ( 4 * ( 1 - x ) + 4 * ( 1 + x ) / 3 * lnx + 20 / 9 * dpgg )
      - 4 * cf * tr * nf * ( 10 * ( 1 - x ) + 2 * ( 5 - x ) * lnx + 2 * ( 1 + x ) * lnx2 )
      + 4 * ca * ca * ( ( 29 - 67 * x ) * lnx / 3 - 19 * ( 1 - x ) / 2 + 4 * ( 1 + x ) * lnx2
                        - 2 * S2x * dpggmx + ( 67 / 9 - 4 * ln1mx * lnx + lnx2 - 2 * Zeta[2] ) * dpgg );
 ggg1l=(-80 ca tr nf/9+(268/9-8 Zeta[2])ca^2) / ( 1 - x );
 ggg1 - ggg1l
];

NextToLeadingSplittingKernel[daughter_,parent_,spin_,x_Symbol,parameters_Association,
 evolution:("SpaceLike"|"TimeLike")]:=Catch[Module[
 {ca,cf,tr,nf,base,sea,regular,delta=0,plus=<||>,soft,softg,quarkDelta,gluonDelta,ns},
 If[!collinearKernelSpeciesQ[daughter]||!collinearKernelSpeciesQ[parent]||
  !MemberQ[{"U","L"},spin]||(evolution==="TimeLike"&&spin=!="U"),
  collinearKernelFail["NLOSplittingSpeciesSpinEvolutionUnsupported"]];
 If[!ContainsAll[Keys[parameters],{"CA","CF","TR","FlavorCount"}],
  collinearKernelFail["ColorAndFlavorParametersRequired"]];
 {ca,cf,tr,nf}=Lookup[parameters,{"CA","CF","TR","FlavorCount"}];
 base[channel_]:=splittingNLORegular[evolution,spin,channel,x,ca,cf,tr,nf];
 soft=-80 cf tr nf/9+(268/9-8 Zeta[2])ca cf;
 softg=-80 ca tr nf/9+(268/9-8 Zeta[2])ca^2;
 quarkDelta=-2 cf tr nf/3+3 cf^2/2+17 ca cf/6+24 Zeta[3]cf^2-12 Zeta[3]ca cf
  -16 Zeta[2]cf tr nf/3-12 Zeta[2]cf^2+44 Zeta[2]ca cf/3;
 gluonDelta=(-4 cf-16 ca/3)tr nf+(32/3+12 Zeta[3])ca^2;
 Which[
  daughter==="g"&&parent==="g",regular=base["gg"];delta=gluonDelta;plus=<|0->softg|>,
  daughter==="g",regular=If[evolution==="SpaceLike",base["gq"],
    splittingNLORegular[evolution,spin,"qg",x,ca,cf,tr,1]/2],
  parent==="g",regular=If[evolution==="SpaceLike",
    splittingNLORegular[evolution,spin,"qg",x,ca,cf,tr,1]/2,base["gq"]],
  True,
   sea=splittingNLORegular[evolution,spin,"ps",x,ca,cf,tr,1]/2;
   regular=sea;
   If[Last[daughter]===Last[parent],
    ns=If[First[daughter]===First[parent],1,-1];
    regular+=(base["nsp"]+ns base["nsm"])/2;
    If[ns===1,delta=quarkDelta;plus=<|0->soft|>]]
 ];
 Join[collinearKernelRecord[x,delta/4,(#/4&/@plus),regular/4],
  <|"Daughter"->daughter,"Parent"->parent,"Spin"->spin,"Evolution"->evolution,
   "KernelOrder"->1,"PerturbativeParameter"->"alpha_s/(2 Pi)",
   "FactorizationScheme"->If[spin==="L","HelicityMSbar","MSbar"],
   "KernelDirection"->"physical daughter <- parent; fragmentation matrix parent first"|>]
],"CollinearCounterterms"];
End[];EndPackage[];
