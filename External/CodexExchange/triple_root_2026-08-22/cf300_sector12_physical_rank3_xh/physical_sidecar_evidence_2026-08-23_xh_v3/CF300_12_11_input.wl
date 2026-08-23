<|"Family" -> "CF300", "Sector" -> 12, "LowerSector" -> 11, 
 "Variables" -> {x, y}, "Regulator" -> eps, 
 "Strip" -> {{{{-2/(1 + x), (-2*y)/((1 + x)*(1 + x + y))}, 
     {(-1 - x)^(-1), (-5 - 5*x - y)/((1 + x)*(1 + x + y))}}, 
    {{-2/y, 2/(1 + x + y)}, {y^(-1), (1 + x - 3*y)/(y*(1 + x + y))}}}, 
   {{{(-2*(1 + 4*x*y))/(x*(-1 + 4*x*y)), 
      -1/2*Sqrt[1 - 4*x*y]/(x*(-1 + 4*x*y))}, 
     {(4*Sqrt[1 - 4*x*y])/(x*(-1 + 4*x*y)), -x^(-1)}}, 
    {{(-2*(1 + 4*x*y))/(y*(-1 + 4*x*y)), 
      -1/2*Sqrt[1 - 4*x*y]/(y*(-1 + 4*x*y))}, 
     {(4*Sqrt[1 - 4*x*y])/(y*(-1 + 4*x*y)), -y^(-1)}}}, 
   {{{(2*Sqrt[1 - 4*x*y]*(8*eps*y + 40*eps^2*y - 226*eps^3*y - 322*eps^4*y + 
         1280*eps^5*y + 648*eps^6*y - 2016*eps^7*y + 16*eps*x*y + 
         80*eps^2*x*y - 452*eps^3*x*y - 644*eps^4*x*y + 2560*eps^5*x*y + 
         1296*eps^6*x*y - 4032*eps^7*x*y + 8*eps*x^2*y + 40*eps^2*x^2*y - 
         226*eps^3*x^2*y - 322*eps^4*x^2*y + 1280*eps^5*x^2*y + 
         648*eps^6*x^2*y - 2016*eps^7*x^2*y - 8*y^2 - 34*eps*y^2 + 
         301*eps^2*y^2 + 54*eps^3*y^2 - 1959*eps^4*y^2 + 1122*eps^5*y^2 + 
         3672*eps^6*y^2 - 3456*eps^7*y^2 - 20*x*y^2 - 174*eps*x*y^2 + 
         334*eps^2*x*y^2 + 2666*eps^3*x*y^2 - 1934*eps^4*x*y^2 - 
         10760*eps^5*x*y^2 + 3672*eps^6*x*y^2 + 11520*eps^7*x*y^2 - 
         16*x^2*y^2 - 214*eps*x^2*y^2 - 91*eps^2*x^2*y^2 + 
         4218*eps^3*x^2*y^2 + 1269*eps^4*x^2*y^2 - 20218*eps^5*x^2*y^2 - 
         2736*eps^6*x^2*y^2 + 27360*eps^7*x^2*y^2 - 4*x^3*y^2 - 
         74*eps*x^3*y^2 - 124*eps^2*x^3*y^2 + 1606*eps^3*x^3*y^2 + 
         1244*eps^4*x^3*y^2 - 8336*eps^5*x^3*y^2 - 2736*eps^6*x^3*y^2 + 
         12384*eps^7*x^3*y^2 - 16*y^3 - 94*eps*y^3 + 485*eps^2*y^3 + 
         816*eps^3*y^3 - 3017*eps^4*y^3 - 1614*eps^5*y^3 + 5472*eps^6*y^3 - 
         864*eps^7*y^3 - 32*x*y^3 - 352*eps*x*y^3 + 16*eps^2*x*y^3 + 
         6700*eps^3*x*y^3 + 1288*eps^4*x*y^3 - 32172*eps^5*x*y^3 - 
         2520*eps^6*x*y^3 + 42336*eps^7*x*y^3 - 16*x^2*y^3 - 
         158*eps*x^2*y^3 - 241*eps^2*x^2*y^3 + 3485*eps^3*x^2*y^3 + 
         3787*eps^4*x^2*y^3 - 20191*eps^5*x^2*y^3 - 8658*eps^6*x^2*y^3 + 
         31896*eps^7*x^2*y^3 - 16*x^3*y^3 + 36*eps*x^3*y^3 + 
         694*eps^2*x^3*y^3 - 1936*eps^3*x^3*y^3 - 3642*eps^4*x^3*y^3 + 
         10456*eps^5*x^3*y^3 + 5328*eps^6*x^3*y^3 - 14832*eps^7*x^3*y^3 - 
         8*x^4*y^3 - 4*eps*x^4*y^3 + 336*eps^2*x^4*y^3 - 436*eps^3*x^4*y^3 - 
         2512*eps^4*x^4*y^3 + 3824*eps^5*x^4*y^3 + 5184*eps^6*x^4*y^3 - 
         8064*eps^7*x^4*y^3 - 8*y^4 - 52*eps*y^4 + 224*eps^2*y^4 + 
         536*eps^3*y^4 - 1380*eps^4*y^4 - 1456*eps^5*y^4 + 2448*eps^6*y^4 + 
         576*eps^7*y^4 - 28*x*y^4 - 298*eps*x*y^4 - 174*eps^2*x*y^4 + 
         6182*eps^3*x*y^4 + 2722*eps^4*x*y^4 - 31108*eps^5*x*y^4 - 
         5472*eps^6*x*y^4 + 42912*eps^7*x*y^4 + 8*x^2*y^4 + 124*eps*x^2*y^4 - 
         152*eps^2*x^2*y^4 - 1734*eps^3*x^2*y^4 + 304*eps^4*x^2*y^4 + 
         8238*eps^5*x^2*y^4 - 1116*eps^6*x^2*y^4 - 9504*eps^7*x^2*y^4 - 
         12*x^3*y^4 + 6*eps*x^3*y^4 + 670*eps^2*x^3*y^4 - 
         1174*eps^3*x^3*y^4 - 5658*eps^4*x^3*y^4 + 10544*eps^5*x^3*y^4 + 
         10440*eps^6*x^3*y^4 - 19296*eps^7*x^3*y^4 + 8*x^4*y^4 - 
         4*eps*x^4*y^4 - 324*eps^2*x^4*y^4 + 748*eps^3*x^4*y^4 + 
         1452*eps^4*x^4*y^4 - 4216*eps^5*x^4*y^4 - 576*eps^6*x^4*y^4 + 
         4032*eps^7*x^4*y^4 - 16*x*y^5 - 136*eps*x*y^5 + 64*eps^2*x*y^5 + 
         2600*eps^3*x*y^5 + 144*eps^4*x*y^5 - 12256*eps^5*x*y^5 - 
         576*eps^6*x*y^5 + 16128*eps^7*x*y^5 + 32*x^2*y^5 + 240*eps*x^2*y^5 - 
         592*eps^2*x^2*y^5 - 3120*eps^3*x^2*y^5 + 1584*eps^4*x^2*y^5 + 
         14656*eps^5*x^2*y^5 - 1152*eps^6*x^2*y^5 - 19584*eps^7*x^2*y^5 - 
         16*x^3*y^5 - 104*eps*x^3*y^5 + 256*eps^2*x^3*y^5 + 
         1728*eps^3*x^3*y^5 - 2016*eps^4*x^3*y^5 - 5848*eps^5*x^3*y^5 + 
         3312*eps^6*x^3*y^5 + 5760*eps^7*x^3*y^5))/
       (eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*(-1 + 4*x*y)^3*
        (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 
      ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(6*eps*y + 20*eps^2*y + 
         16*eps^3*y + 12*eps*x*y + 40*eps^2*x*y + 32*eps^3*x*y + 
         6*eps*x^2*y + 20*eps^2*x^2*y + 16*eps^3*x^2*y - 11*y^2 - 
         43*eps*y^2 - 44*eps^2*y^2 - 28*x*y^2 - 172*eps*x*y^2 - 
         300*eps^2*x*y^2 - 136*eps^3*x*y^2 - 23*x^2*y^2 - 191*eps*x^2*y^2 - 
         400*eps^2*x^2*y^2 - 224*eps^3*x^2*y^2 - 6*x^3*y^2 - 62*eps*x^3*y^2 - 
         144*eps^2*x^3*y^2 - 88*eps^3*x^3*y^2 - 23*y^3 - 109*eps*y^3 - 
         152*eps^2*y^3 - 48*eps^3*y^3 - 28*x*y^3 - 240*eps*x*y^3 - 
         532*eps^2*x*y^3 - 336*eps^3*x*y^3 + 15*x^2*y^3 + 16*eps*x^2*y^3 - 
         175*eps^2*x^2*y^3 - 272*eps^3*x^2*y^3 + 14*x^3*y^3 + 
         128*eps*x^3*y^3 + 158*eps^2*x^3*y^3 - 52*eps^3*x^3*y^3 + 
         16*eps*x^4*y^3 + 16*eps^2*x^4*y^3 - 32*eps^3*x^4*y^3 - 12*y^4 - 
         60*eps*y^4 - 88*eps^2*y^4 - 32*eps^3*y^4 - 88*eps*x*y^4 - 
         320*eps^2*x*y^4 - 296*eps^3*x*y^4 + 36*x^2*y^4 + 172*eps*x^2*y^4 + 
         132*eps^2*x^2*y^4 - 132*eps^3*x^2*y^4 - 8*x^3*y^4 + 
         40*eps^2*x^3*y^4 - 32*eps^3*x^3*y^4 - 16*eps*x^4*y^4 + 
         16*eps^3*x^4*y^4 - 32*eps*x*y^5 - 128*eps^2*x*y^5 - 
         128*eps^3*x*y^5 + 32*x^2*y^5 + 144*eps*x^2*y^5 + 176*eps^2*x^2*y^5 + 
         32*eps^3*x^2*y^5 + 16*eps^2*x^3*y^5 + 16*eps^3*x^3*y^5))/
       (eps^2*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*(-1 + 4*x*y)^2*
        (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2)}, 
     {(2*Sqrt[1 - 4*x*y]*(4 + 32*eps - 53*eps^2 - 500*eps^3 + 157*eps^4 + 
         2244*eps^5 - 36*eps^6 - 3024*eps^7 + 12*x + 96*eps*x - 159*eps^2*x - 
         1500*eps^3*x + 471*eps^4*x + 6732*eps^5*x - 108*eps^6*x - 
         9072*eps^7*x + 12*x^2 + 96*eps*x^2 - 159*eps^2*x^2 - 
         1500*eps^3*x^2 + 471*eps^4*x^2 + 6732*eps^5*x^2 - 108*eps^6*x^2 - 
         9072*eps^7*x^2 + 4*x^3 + 32*eps*x^3 - 53*eps^2*x^3 - 500*eps^3*x^3 + 
         157*eps^4*x^3 + 2244*eps^5*x^3 - 36*eps^6*x^3 - 3024*eps^7*x^3 + 
         20*y + 148*eps*y - 371*eps^2*y - 2046*eps^3*y + 1651*eps^4*y + 
         8478*eps^5*y - 2088*eps^6*y - 10368*eps^7*y + 32*x*y + 244*eps*x*y - 
         676*eps^2*x*y - 3239*eps^3*x*y + 3612*eps^4*x*y + 12485*eps^5*x*y - 
         6030*eps^6*x*y - 13032*eps^7*x*y - 12*x^2*y - 80*eps*x^2*y - 
         57*eps^2*x^2*y + 1636*eps^3*x^2*y + 2069*eps^4*x^2*y - 
         9768*eps^5*x^2*y - 6876*eps^6*x^2*y + 18576*eps^7*x^2*y - 40*x^3*y - 
         300*eps*x^3*y + 430*eps^2*x^3*y + 4805*eps^3*x^3*y - 
         94*eps^4*x^3*y - 23079*eps^5*x^3*y - 4014*eps^6*x^3*y + 
         34776*eps^7*x^3*y - 16*x^4*y - 124*eps*x^4*y + 182*eps^2*x^4*y + 
         1976*eps^3*x^4*y - 202*eps^4*x^4*y - 9304*eps^5*x^4*y - 
         1080*eps^6*x^4*y + 13536*eps^7*x^4*y + 36*y^2 + 252*eps*y^2 - 
         807*eps^2*y^2 - 3128*eps^3*y^2 + 4211*eps^4*y^2 + 11680*eps^5*y^2 - 
         6516*eps^6*y^2 - 12240*eps^7*y^2 + 24*x*y^2 + 190*eps*x*y^2 - 
         649*eps^2*x*y^2 - 2401*eps^3*x*y^2 + 4853*eps^4*x*y^2 + 
         7357*eps^5*x*y^2 - 11754*eps^6*x*y^2 - 792*eps^7*x*y^2 - 
         32*x^2*y^2 - 270*eps*x^2*y^2 + 469*eps^2*x^2*y^2 + 
         3702*eps^3*x^2*y^2 + 37*eps^4*x^2*y^2 - 17430*eps^5*x^2*y^2 - 
         7704*eps^6*x^2*y^2 + 31968*eps^7*x^2*y^2 + 32*x^3*y^2 + 
         70*eps*x^3*y^2 - 631*eps^2*x^3*y^2 - 657*eps^3*x^3*y^2 + 
         2973*eps^4*x^3*y^2 + 2475*eps^5*x^3*y^2 - 5454*eps^6*x^3*y^2 - 
         648*eps^7*x^3*y^2 + 76*x^4*y^2 + 434*eps*x^4*y^2 - 
         1302*eps^2*x^4*y^2 - 5908*eps^3*x^4*y^2 + 4562*eps^4*x^4*y^2 + 
         25934*eps^5*x^4*y^2 - 2700*eps^6*x^4*y^2 - 36144*eps^7*x^4*y^2 + 
         24*x^5*y^2 + 156*eps*x^5*y^2 - 360*eps^2*x^5*y^2 - 
         2276*eps^3*x^5*y^2 + 984*eps^4*x^5*y^2 + 10352*eps^5*x^5*y^2 + 
         288*eps^6*x^5*y^2 - 14976*eps^7*x^5*y^2 + 28*y^3 + 188*eps*y^3 - 
         713*eps^2*y^3 - 2118*eps^3*y^3 + 4097*eps^4*y^3 + 6902*eps^5*y^3 - 
         6912*eps^6*y^3 - 5472*eps^7*y^3 + 16*x*y^3 + 172*eps*x*y^3 + 
         58*eps^2*x*y^3 - 3780*eps^3*x*y^3 + 190*eps^4*x*y^3 + 
         17384*eps^5*x*y^3 - 4392*eps^6*x*y^3 - 16704*eps^7*x*y^3 + 
         16*x^2*y^3 + 58*eps*x^2*y^3 + 311*eps^2*x^2*y^3 - 
         2809*eps^3*x^2*y^3 - 1269*eps^4*x^2*y^3 + 14139*eps^5*x^2*y^3 - 
         1134*eps^6*x^2*y^3 - 14904*eps^7*x^2*y^3 + 88*x^3*y^3 + 
         452*eps*x^3*y^3 - 1652*eps^2*x^3*y^3 - 6188*eps^3*x^3*y^3 + 
         8996*eps^4*x^3*y^3 + 21592*eps^5*x^3*y^3 - 9864*eps^6*x^3*y^3 - 
         26928*eps^7*x^3*y^3 + 28*x^4*y^3 + 186*eps*x^4*y^3 - 
         594*eps^2*x^4*y^3 - 2442*eps^3*x^4*y^3 + 3638*eps^4*x^4*y^3 + 
         7080*eps^5*x^4*y^3 - 1800*eps^6*x^4*y^3 - 11232*eps^7*x^4*y^3 - 
         24*x^5*y^3 - 132*eps*x^5*y^3 + 468*eps^2*x^5*y^3 + 
         1700*eps^3*x^5*y^3 - 2108*eps^4*x^5*y^3 - 7120*eps^5*x^5*y^3 + 
         3600*eps^6*x^5*y^3 + 7488*eps^7*x^5*y^3 + 8*y^4 + 52*eps*y^4 - 
         224*eps^2*y^4 - 536*eps^3*y^4 + 1380*eps^4*y^4 + 1456*eps^5*y^4 - 
         2448*eps^6*y^4 - 576*eps^7*y^4 + 28*x*y^4 + 266*eps*x*y^4 + 
         126*eps^2*x*y^4 - 5718*eps^3*x*y^4 - 1666*eps^4*x*y^4 + 
         28036*eps^5*x*y^4 + 2016*eps^6*x*y^4 - 36000*eps^7*x*y^4 - 
         8*x^2*y^4 - 92*eps*x^2*y^4 + 520*eps^2*x^2*y^4 - 170*eps^3*x^2*y^4 - 
         1072*eps^4*x^2*y^4 - 238*eps^5*x^2*y^4 + 540*eps^6*x^2*y^4 + 
         1440*eps^7*x^2*y^4 + 12*x^3*y^4 + 26*eps*x^3*y^4 - 
         366*eps^2*x^3*y^4 - 474*eps^3*x^3*y^4 + 5194*eps^4*x^3*y^4 - 
         4960*eps^5*x^3*y^4 - 7848*eps^6*x^3*y^4 + 10080*eps^7*x^3*y^4 - 
         8*x^4*y^4 - 28*eps*x^4*y^4 + 212*eps^2*x^4*y^4 - 28*eps^3*x^4*y^4 - 
         92*eps^4*x^4*y^4 - 1272*eps^5*x^4*y^4 + 288*eps^6*x^4*y^4 + 
         1728*eps^7*x^4*y^4 + 16*x*y^5 + 136*eps*x*y^5 - 64*eps^2*x*y^5 - 
         2600*eps^3*x*y^5 - 144*eps^4*x*y^5 + 12256*eps^5*x*y^5 + 
         576*eps^6*x*y^5 - 16128*eps^7*x*y^5 - 32*x^2*y^5 - 240*eps*x^2*y^5 + 
         592*eps^2*x^2*y^5 + 3120*eps^3*x^2*y^5 - 1584*eps^4*x^2*y^5 - 
         14656*eps^5*x^2*y^5 + 1152*eps^6*x^2*y^5 + 19584*eps^7*x^2*y^5 + 
         16*x^3*y^5 + 104*eps*x^3*y^5 - 256*eps^2*x^3*y^5 - 
         1728*eps^3*x^3*y^5 + 2016*eps^4*x^3*y^5 + 5848*eps^5*x^3*y^5 - 
         3312*eps^6*x^3*y^5 - 5760*eps^7*x^3*y^5))/
       (eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*(-1 + 4*x*y)^3*
        (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 
      ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(1 + x + y)*
        (3 + 19*eps + 38*eps^2 + 24*eps^3 + 6*x + 38*eps*x + 76*eps^2*x + 
         48*eps^3*x + 3*x^2 + 19*eps*x^2 + 38*eps^2*x^2 + 24*eps^3*x^2 + 
         18*y + 104*eps*y + 198*eps^2*y + 120*eps^3*y + 24*x*y + 
         151*eps*x*y + 307*eps^2*x*y + 196*eps^3*x*y + 13*eps*x^2*y + 
         49*eps^2*x^2*y + 44*eps^3*x^2*y - 6*x^3*y - 34*eps*x^3*y - 
         60*eps^2*x^3*y - 32*eps^3*x^3*y + 27*y^2 + 145*eps*y^2 + 
         248*eps^2*y^2 + 128*eps^3*y^2 + 4*eps*x*y^2 - 28*eps^2*x*y^2 - 
         64*eps^3*x*y^2 - 51*x^2*y^2 - 364*eps*x^2*y^2 - 845*eps^2*x^2*y^2 - 
         628*eps^3*x^2*y^2 - 18*x^3*y^2 - 220*eps*x^3*y^2 - 
         634*eps^2*x^3*y^2 - 528*eps^3*x^3*y^2 - 32*eps*x^4*y^2 - 
         128*eps^2*x^4*y^2 - 128*eps^3*x^4*y^2 + 12*y^3 + 60*eps*y^3 + 
         88*eps^2*y^3 + 32*eps^3*y^3 - 16*x*y^3 - 56*eps*x*y^3 - 
         64*eps^2*x*y^3 - 24*eps^3*x*y^3 - 36*x^2*y^3 - 204*eps*x^2*y^3 - 
         356*eps^2*x^2*y^3 - 188*eps^3*x^2*y^3 + 24*x^3*y^3 + 
         128*eps*x^3*y^3 + 216*eps^2*x^3*y^3 + 112*eps^3*x^3*y^3 + 
         32*eps*x^4*y^3 + 96*eps^2*x^4*y^3 + 64*eps^3*x^4*y^3 + 
         32*eps*x*y^4 + 128*eps^2*x*y^4 + 128*eps^3*x*y^4 - 32*x^2*y^4 - 
         144*eps*x^2*y^4 - 176*eps^2*x^2*y^4 - 32*eps^3*x^2*y^4 - 
         16*eps^2*x^3*y^4 - 16*eps^3*x^3*y^4))/(eps^2*(1 + 2*eps)*(1 + 5*eps)*
        (2 + 5*eps)*(-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + 
          x*y + eps*x*y)^2)}}, 
    {{(-2*Sqrt[1 - 4*x*y]*(-4*eps^2 + 2*eps^3 + 70*eps^4 - 80*eps^5 - 
         216*eps^6 + 288*eps^7 - 12*eps^2*x + 6*eps^3*x + 210*eps^4*x - 
         240*eps^5*x - 648*eps^6*x + 864*eps^7*x - 12*eps^2*x^2 + 
         6*eps^3*x^2 + 210*eps^4*x^2 - 240*eps^5*x^2 - 648*eps^6*x^2 + 
         864*eps^7*x^2 - 4*eps^2*x^3 + 2*eps^3*x^3 + 70*eps^4*x^3 - 
         80*eps^5*x^3 - 216*eps^6*x^3 + 288*eps^7*x^3 - 8*eps^2*y + 
         4*eps^3*y + 140*eps^4*y - 160*eps^5*y - 432*eps^6*y + 576*eps^7*y + 
         16*x*y + 116*eps*x*y - 314*eps^2*x*y - 1616*eps^3*x*y + 
         1722*eps^4*x*y + 6332*eps^5*x*y - 3168*eps^6*x*y - 6336*eps^7*x*y + 
         36*x^2*y + 258*eps*x^2*y - 696*eps^2*x^2*y - 3570*eps^3*x^2*y + 
         3580*eps^4*x^2*y + 14248*eps^5*x^2*y - 6048*eps^6*x^2*y - 
         15264*eps^7*x^2*y + 24*x^3*y + 168*eps*x^3*y - 482*eps^2*x^3*y - 
         2276*eps^3*x^3*y + 2554*eps^4*x^3*y + 8860*eps^5*x^3*y - 
         4320*eps^6*x^3*y - 9216*eps^7*x^3*y + 4*x^4*y + 26*eps*x^4*y - 
         92*eps^2*x^4*y - 326*eps^3*x^4*y + 556*eps^4*x^4*y + 
         1104*eps^5*x^4*y - 1008*eps^6*x^4*y - 864*eps^7*x^4*y - 
         4*eps^2*y^2 + 2*eps^3*y^2 + 70*eps^4*y^2 - 80*eps^5*y^2 - 
         216*eps^6*y^2 + 288*eps^7*y^2 + 32*x*y^2 + 238*eps*x*y^2 - 
         609*eps^2*x*y^2 - 3336*eps^3*x*y^2 + 3149*eps^4*x*y^2 + 
         13278*eps^5*x*y^2 - 5040*eps^6*x*y^2 - 14688*eps^7*x*y^2 + 
         4*x^2*y^2 + 30*eps*x^2*y^2 - 96*eps^2*x^2*y^2 - 197*eps^3*x^2*y^2 - 
         304*eps^4*x^2*y^2 + 1925*eps^5*x^2*y^2 + 1026*eps^6*x^2*y^2 - 
         3528*eps^7*x^2*y^2 - 56*x^3*y^2 - 382*eps*x^3*y^2 + 
         1229*eps^2*x^3*y^2 + 5203*eps^3*x^3*y^2 - 8335*eps^4*x^3*y^2 - 
         17149*eps^5*x^3*y^2 + 15930*eps^6*x^3*y^2 + 12456*eps^7*x^3*y^2 - 
         20*x^4*y^2 - 106*eps*x^4*y^2 + 672*eps^2*x^4*y^2 + 
         962*eps^3*x^4*y^2 - 5608*eps^4*x^4*y^2 + 188*eps^5*x^4*y^2 + 
         12960*eps^6*x^4*y^2 - 9360*eps^7*x^4*y^2 + 8*x^5*y^2 + 
         68*eps*x^5*y^2 - 48*eps^2*x^5*y^2 - 1100*eps^3*x^5*y^2 - 
         656*eps^4*x^5*y^2 + 5904*eps^5*x^5*y^2 + 2880*eps^6*x^5*y^2 - 
         10368*eps^7*x^5*y^2 + 16*x*y^3 + 120*eps*x*y^3 - 304*eps^2*x*y^3 - 
         1684*eps^3*x*y^3 + 1572*eps^4*x*y^3 + 6688*eps^5*x*y^3 - 
         2448*eps^6*x*y^3 - 7488*eps^7*x*y^3 - 52*x^2*y^3 - 398*eps*x^2*y^3 + 
         1094*eps^2*x^2*y^3 + 5458*eps^3*x^2*y^3 - 6634*eps^4*x^2*y^3 - 
         19868*eps^5*x^2*y^3 + 11520*eps^6*x^2*y^3 + 19296*eps^7*x^2*y^3 - 
         16*x^3*y^3 - 96*eps*x^3*y^3 + 808*eps^2*x^3*y^3 - 
         246*eps^3*x^3*y^3 - 4096*eps^4*x^3*y^3 + 1754*eps^5*x^3*y^3 + 
         11340*eps^6*x^3*y^3 - 10656*eps^7*x^3*y^3 + 44*x^4*y^3 + 
         298*eps*x^4*y^3 - 622*eps^2*x^4*y^3 - 5034*eps^3*x^4*y^3 + 
         4682*eps^4*x^4*y^3 + 16448*eps^5*x^4*y^3 - 1512*eps^6*x^4*y^3 - 
         24480*eps^7*x^4*y^3 + 8*x^5*y^3 - 4*eps*x^5*y^3 - 
         324*eps^2*x^5*y^3 + 620*eps^3*x^5*y^3 + 2156*eps^4*x^5*y^3 - 
         5112*eps^5*x^5*y^3 - 1152*eps^6*x^5*y^3 + 5184*eps^7*x^5*y^3 - 
         16*x^2*y^4 - 136*eps*x^2*y^4 + 320*eps^2*x^2*y^4 + 
         1960*eps^3*x^2*y^4 - 2032*eps^4*x^2*y^4 - 7392*eps^5*x^2*y^4 + 
         4032*eps^6*x^2*y^4 + 6912*eps^7*x^2*y^4 + 32*x^3*y^4 + 
         240*eps*x^3*y^4 - 592*eps^2*x^3*y^4 - 3376*eps^3*x^3*y^4 + 
         2992*eps^4*x^3*y^4 + 12864*eps^5*x^3*y^4 - 2304*eps^6*x^3*y^4 - 
         17280*eps^7*x^3*y^4 - 16*x^4*y^4 - 104*eps*x^4*y^4 + 
         256*eps^2*x^4*y^4 + 1600*eps^3*x^4*y^4 - 1312*eps^4*x^4*y^4 - 
         6744*eps^5*x^4*y^4 + 2736*eps^6*x^4*y^4 + 6912*eps^7*x^4*y^4))/
       (eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*(-1 + 4*x*y)^3*
        (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 
      -(((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(-2*eps - 12*eps^2 - 
          16*eps^3 - 6*eps*x - 36*eps^2*x - 48*eps^3*x - 6*eps*x^2 - 
          36*eps^2*x^2 - 48*eps^3*x^2 - 2*eps*x^3 - 12*eps^2*x^3 - 
          16*eps^3*x^3 - 4*eps*y - 24*eps^2*y - 32*eps^3*y + 18*x*y + 
          114*eps*x*y + 240*eps^2*x*y + 160*eps^3*x*y + 42*x^2*y + 
          286*eps*x^2*y + 680*eps^2*x^2*y + 536*eps^3*x^2*y + 30*x^3*y + 
          214*eps*x^3*y + 544*eps^2*x^3*y + 464*eps^3*x^3*y + 6*x^4*y + 
          46*eps*x^4*y + 128*eps^2*x^4*y + 120*eps^3*x^4*y - 2*eps*y^2 - 
          12*eps^2*y^2 - 16*eps^3*y^2 + 39*x*y^2 + 257*eps*x*y^2 + 
          576*eps^2*x*y^2 + 432*eps^3*x*y^2 + 10*x^2*y^2 + 59*eps*x^2*y^2 + 
          165*eps^2*x^2*y^2 + 196*eps^3*x^2*y^2 - 71*x^3*y^2 - 
          496*eps*x^3*y^2 - 1153*eps^2*x^3*y^2 - 824*eps^3*x^3*y^2 - 
          42*x^4*y^2 - 312*eps*x^4*y^2 - 810*eps^2*x^4*y^2 - 
          668*eps^3*x^4*y^2 - 16*eps*x^5*y^2 - 80*eps^2*x^5*y^2 - 
          96*eps^3*x^5*y^2 + 20*x*y^3 + 132*eps*x*y^3 + 296*eps^2*x*y^3 + 
          224*eps^3*x*y^3 - 80*x^2*y^3 - 520*eps*x^2*y^3 - 
          1104*eps^2*x^2*y^3 - 760*eps^3*x^2*y^3 - 76*x^3*y^3 - 
          460*eps*x^3*y^3 - 1052*eps^2*x^3*y^3 - 860*eps^3*x^3*y^3 + 
          8*x^4*y^3 + 96*eps*x^4*y^3 + 216*eps^2*x^4*y^3 + 64*eps^3*x^4*y^3 + 
          48*eps^2*x^5*y^3 + 48*eps^3*x^5*y^3 - 32*x^2*y^4 - 
          224*eps*x^2*y^4 - 512*eps^2*x^2*y^4 - 384*eps^3*x^2*y^4 + 
          32*x^3*y^4 + 176*eps*x^3*y^4 + 272*eps^2*x^3*y^4 + 
          96*eps^3*x^3*y^4 + 16*eps*x^4*y^4 + 64*eps^2*x^4*y^4 + 
          48*eps^3*x^4*y^4))/(eps^2*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*
         (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
           eps*x*y)^2))}, {(2*Sqrt[1 - 4*x*y]*(2*eps + 5*eps^2 - 38*eps^3 - 
         65*eps^4 + 228*eps^5 + 180*eps^6 - 432*eps^7 + 8*eps*x + 
         20*eps^2*x - 152*eps^3*x - 260*eps^4*x + 912*eps^5*x + 720*eps^6*x - 
         1728*eps^7*x + 12*eps*x^2 + 30*eps^2*x^2 - 228*eps^3*x^2 - 
         390*eps^4*x^2 + 1368*eps^5*x^2 + 1080*eps^6*x^2 - 2592*eps^7*x^2 + 
         8*eps*x^3 + 20*eps^2*x^3 - 152*eps^3*x^3 - 260*eps^4*x^3 + 
         912*eps^5*x^3 + 720*eps^6*x^3 - 1728*eps^7*x^3 + 2*eps*x^4 + 
         5*eps^2*x^4 - 38*eps^3*x^4 - 65*eps^4*x^4 + 228*eps^5*x^4 + 
         180*eps^6*x^4 - 432*eps^7*x^4 + 4*eps*y + 6*eps^2*y - 74*eps^3*y - 
         60*eps^4*y + 376*eps^5*y + 144*eps^6*y - 576*eps^7*y + 12*x*y + 
         76*eps*x*y - 287*eps^2*x*y - 859*eps^3*x*y + 1483*eps^4*x*y + 
         3029*eps^5*x*y - 2178*eps^6*x*y - 3096*eps^7*x*y + 44*x^2*y + 
         260*eps*x^2*y - 1031*eps^2*x^2*y - 2977*eps^3*x^2*y + 
         5523*eps^4*x^2*y + 10247*eps^5*x^2*y - 8622*eps^6*x^2*y - 
         9576*eps^7*x^2*y + 60*x^3*y + 364*eps*x^3*y - 1311*eps^2*x^3*y - 
         4517*eps^3*x^3*y + 7071*eps^4*x^3*y + 16327*eps^5*x^3*y - 
         11358*eps^6*x^3*y - 15912*eps^7*x^3*y + 36*x^4*y + 232*eps*x^4*y - 
         707*eps^2*x^4*y - 3169*eps^3*x^4*y + 3805*eps^4*x^4*y + 
         12149*eps^5*x^4*y - 6282*eps^6*x^4*y - 12600*eps^7*x^4*y + 8*x^5*y + 
         56*eps*x^5*y - 134*eps^2*x^5*y - 844*eps^3*x^5*y + 714*eps^4*x^5*y + 
         3416*eps^5*x^5*y - 1224*eps^6*x^5*y - 3744*eps^7*x^5*y + 2*eps*y^2 - 
         3*eps^2*y^2 - 34*eps^3*y^2 + 75*eps^4*y^2 + 68*eps^5*y^2 - 
         252*eps^6*y^2 + 144*eps^7*y^2 + 40*x*y^2 + 256*eps*x*y^2 - 
         916*eps^2*x*y^2 - 3101*eps^3*x*y^2 + 5028*eps^4*x*y^2 + 
         10987*eps^5*x*y^2 - 8226*eps^6*x*y^2 - 10296*eps^7*x*y^2 + 
         84*x^2*y^2 + 598*eps*x^2*y^2 - 1676*eps^2*x^2*y^2 - 
         8307*eps^3*x^2*y^2 + 9574*eps^4*x^2*y^2 + 31765*eps^5*x^2*y^2 - 
         17766*eps^6*x^2*y^2 - 30600*eps^7*x^2*y^2 + 16*x^3*y^2 + 
         252*eps*x^3*y^2 + 48*eps^2*x^3*y^2 - 5369*eps^3*x^3*y^2 + 
         2052*eps^4*x^3*y^2 + 22191*eps^5*x^3*y^2 - 11610*eps^6*x^3*y^2 - 
         15768*eps^7*x^3*y^2 - 68*x^4*y^2 - 360*eps*x^4*y^2 + 
         1451*eps^2*x^4*y^2 + 3561*eps^3*x^4*y^2 - 4009*eps^4*x^4*y^2 - 
         15577*eps^5*x^4*y^2 - 4158*eps^6*x^4*y^2 + 31032*eps^7*x^4*y^2 - 
         48*x^5*y^2 - 352*eps*x^5*y^2 + 616*eps^2*x^5*y^2 + 
         5302*eps^3*x^5*y^2 - 568*eps^4*x^5*y^2 - 25194*eps^5*x^5*y^2 - 
         4932*eps^6*x^5*y^2 + 39312*eps^7*x^5*y^2 - 8*x^6*y^2 - 
         84*eps*x^6*y^2 - 24*eps^2*x^6*y^2 + 1612*eps^3*x^6*y^2 + 
         872*eps^4*x^6*y^2 - 8272*eps^5*x^6*y^2 - 2592*eps^6*x^6*y^2 + 
         12672*eps^7*x^6*y^2 - 4*eps^2*y^3 + 2*eps^3*y^3 + 70*eps^4*y^3 - 
         80*eps^5*y^3 - 216*eps^6*y^3 + 288*eps^7*y^3 + 44*x*y^3 + 
         308*eps*x*y^3 - 913*eps^2*x*y^3 - 4078*eps^3*x*y^3 + 
         4857*eps^4*x*y^3 + 15558*eps^5*x*y^3 - 7776*eps^6*x*y^3 - 
         16416*eps^7*x*y^3 + 4*x^2*y^3 + 114*eps*x^2*y^3 + 
         322*eps^2*x^2*y^3 - 3113*eps^3*x^2*y^3 - 1202*eps^4*x^2*y^3 + 
         15053*eps^5*x^2*y^3 - 2070*eps^6*x^2*y^3 - 14760*eps^7*x^2*y^3 - 
         104*x^3*y^3 - 610*eps*x^3*y^3 + 2863*eps^2*x^3*y^3 + 
         5095*eps^3*x^3*y^3 - 13165*eps^4*x^3*y^3 - 15449*eps^5*x^3*y^3 + 
         11898*eps^6*x^3*y^3 + 22536*eps^7*x^3*y^3 - 44*x^4*y^3 - 
         370*eps*x^4*y^3 + 1146*eps^2*x^4*y^3 + 3682*eps^3*x^4*y^3 - 
         3350*eps^4*x^4*y^3 - 16024*eps^5*x^4*y^3 - 720*eps^6*x^4*y^3 + 
         26064*eps^7*x^4*y^3 + 44*x^5*y^3 + 178*eps*x^5*y^3 - 
         954*eps^2*x^5*y^3 - 2274*eps^3*x^5*y^3 + 6638*eps^4*x^5*y^3 + 
         5064*eps^5*x^5*y^3 - 11304*eps^6*x^5*y^3 - 864*eps^7*x^5*y^3 + 
         24*x^6*y^3 + 132*eps*x^6*y^3 - 468*eps^2*x^6*y^3 - 
         1828*eps^3*x^6*y^3 + 2812*eps^4*x^6*y^3 + 6224*eps^5*x^6*y^3 - 
         4176*eps^6*x^6*y^3 - 6336*eps^7*x^6*y^3 + 16*x*y^4 + 120*eps*x*y^4 - 
         304*eps^2*x*y^4 - 1684*eps^3*x*y^4 + 1572*eps^4*x*y^4 + 
         6688*eps^5*x*y^4 - 2448*eps^6*x*y^4 - 7488*eps^7*x*y^4 - 
         52*x^2*y^4 - 366*eps*x^2*y^4 + 1270*eps^2*x^2*y^4 + 
         4290*eps^3*x^2*y^4 - 7050*eps^4*x^2*y^4 - 14556*eps^5*x^2*y^4 + 
         10368*eps^6*x^2*y^4 + 14688*eps^7*x^2*y^4 - 16*x^3*y^4 - 
         128*eps*x^3*y^4 + 696*eps^2*x^3*y^4 + 634*eps^3*x^3*y^4 - 
         3904*eps^4*x^3*y^4 - 742*eps^5*x^3*y^4 + 7884*eps^6*x^3*y^4 - 
         3744*eps^7*x^3*y^4 + 44*x^4*y^4 + 266*eps*x^4*y^4 - 
         798*eps^2*x^4*y^4 - 3834*eps^3*x^4*y^4 + 4634*eps^4*x^4*y^4 + 
         13232*eps^5*x^4*y^4 - 4104*eps^6*x^4*y^4 - 17568*eps^7*x^4*y^4 + 
         8*x^5*y^4 + 28*eps*x^5*y^4 - 212*eps^2*x^5*y^4 - 228*eps^3*x^5*y^4 + 
         1500*eps^4*x^5*y^4 - 520*eps^5*x^5*y^4 - 1440*eps^6*x^5*y^4 + 
         576*eps^7*x^5*y^4 - 16*x^2*y^5 - 136*eps*x^2*y^5 + 
         320*eps^2*x^2*y^5 + 1960*eps^3*x^2*y^5 - 2032*eps^4*x^2*y^5 - 
         7392*eps^5*x^2*y^5 + 4032*eps^6*x^2*y^5 + 6912*eps^7*x^2*y^5 + 
         32*x^3*y^5 + 240*eps*x^3*y^5 - 592*eps^2*x^3*y^5 - 
         3376*eps^3*x^3*y^5 + 2992*eps^4*x^3*y^5 + 12864*eps^5*x^3*y^5 - 
         2304*eps^6*x^3*y^5 - 17280*eps^7*x^3*y^5 - 16*x^4*y^5 - 
         104*eps*x^4*y^5 + 256*eps^2*x^4*y^5 + 1600*eps^3*x^4*y^5 - 
         1312*eps^4*x^4*y^5 - 6744*eps^5*x^4*y^5 + 2736*eps^6*x^4*y^5 + 
         6912*eps^7*x^4*y^5))/(eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*y*
        (-1 + 4*x*y)^3*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
          eps*x*y)^2), ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(1 + x + y)*
        (1 + 9*eps + 26*eps^2 + 24*eps^3 + 3*x + 27*eps*x + 78*eps^2*x + 
         72*eps^3*x + 3*x^2 + 27*eps*x^2 + 78*eps^2*x^2 + 72*eps^3*x^2 + 
         x^3 + 9*eps*x^3 + 26*eps^2*x^3 + 24*eps^3*x^3 + y + 7*eps*y + 
         14*eps^2*y + 8*eps^3*y + 7*x*y + 10*eps*x*y - 57*eps^2*x*y - 
         100*eps^3*x*y + 13*x^2*y - 3*eps*x^2*y - 208*eps^2*x^2*y - 
         304*eps^3*x^2*y + 9*x^3*y - 8*eps*x^3*y - 189*eps^2*x^3*y - 
         276*eps^3*x^3*y + 2*x^4*y - 2*eps*x^4*y - 52*eps^2*x^4*y - 
         80*eps^3*x^4*y - 2*eps*y^2 - 12*eps^2*y^2 - 16*eps^3*y^2 + 
         27*x*y^2 + 141*eps*x*y^2 + 232*eps^2*x*y^2 + 112*eps^3*x*y^2 + 
         38*x^2*y^2 + 287*eps*x^2*y^2 + 661*eps^2*x^2*y^2 + 
         476*eps^3*x^2*y^2 + 5*x^3*y^2 + 196*eps*x^3*y^2 + 
         707*eps^2*x^3*y^2 + 676*eps^3*x^3*y^2 - 6*x^4*y^2 + 52*eps*x^4*y^2 + 
         322*eps^2*x^4*y^2 + 392*eps^3*x^4*y^2 + 32*eps^2*x^5*y^2 + 
         64*eps^3*x^5*y^2 + 20*x*y^3 + 132*eps*x*y^3 + 296*eps^2*x*y^3 + 
         224*eps^3*x*y^3 - 48*x^2*y^3 - 232*eps*x^2*y^3 - 336*eps^2*x^2*y^3 - 
         120*eps^3*x^2*y^3 - 76*x^3*y^3 - 412*eps*x^3*y^3 - 
         716*eps^2*x^3*y^3 - 380*eps^3*x^3*y^3 - 24*x^4*y^3 - 
         160*eps*x^4*y^3 - 312*eps^2*x^4*y^3 - 176*eps^3*x^4*y^3 - 
         16*eps*x^5*y^3 - 48*eps^2*x^5*y^3 - 32*eps^3*x^5*y^3 - 32*x^2*y^4 - 
         224*eps*x^2*y^4 - 512*eps^2*x^2*y^4 - 384*eps^3*x^2*y^4 + 
         32*x^3*y^4 + 176*eps*x^3*y^4 + 272*eps^2*x^3*y^4 + 
         96*eps^3*x^3*y^4 + 16*eps*x^4*y^4 + 64*eps^2*x^4*y^4 + 
         48*eps^3*x^4*y^4))/(eps^2*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*y*
        (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
          eps*x*y)^2)}}}}, "PrecomputedChannelSidecar" -> 
  <|"Status" -> "ExactTermwiseChannelDecomposition", 
   "ChannelSidecarVersion" -> 1, "ChannelRootSourceOrder" -> {1, 2, 3}, 
   "ChannelRootSquares" -> {1 + 2*x + x^2 - 2*y + 2*x*y + y^2, 
     1 - 2*x + x^2 + 2*y + 2*x*y + y^2, 1 - 4*x*y}, "RootIndices" -> {3}, 
   "RootCount" -> 1, "RootSquares" -> {1 - 4*x*y}, 
   "ProcessedTermGraph" -> 
    {{{{{<|"Kind" -> "TopDiagonal", "Component" -> 1, "Mu" -> 1, "Row" -> 1, 
          "Column" -> 1, "Expression" -> -2/(1 + x), "Status" -> 
           "LeafChannelized", "RootIndices" -> {}, "RadicalBases" -> {}, 
          "GlobalChannels" -> {-2/(1 + x), 0, 0, 0, 0, 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "d1459c03fef2cc23854a52bb0b766de4a87276a950e698bd4ee9e35254b9da7f"\
|>}, {<|"Kind" -> "TopDiagonal", "Component" -> 1, "Mu" -> 1, "Row" -> 1, 
          "Column" -> 2, "Expression" -> (-2*y)/((1 + x)*(1 + x + y)), 
          "Status" -> "LeafChannelized", "RootIndices" -> {}, 
          "RadicalBases" -> {}, "GlobalChannels" -> 
           {(-2*y)/((1 + x)*(1 + x + y)), 0, 0, 0, 0, 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "170acaeace29203391cbce4ce3df723346106faeb9dd4d111a93265c35145fa6"\
|>}}, {{<|"Kind" -> "TopDiagonal", "Component" -> 1, "Mu" -> 1, "Row" -> 2, 
          "Column" -> 1, "Expression" -> (-1 - x)^(-1), 
          "Status" -> "LeafChannelized", "RootIndices" -> {}, 
          "RadicalBases" -> {}, "GlobalChannels" -> {(-1 - x)^(-1), 0, 0, 0, 
            0, 0, 0, 0}, "RoundTripExact" -> True, "LeafFingerprint" -> "e574\
1d1ede2bd342152b17ab9495417da094dd0ee6392f5644998870f76b93f3"|>}, 
        {<|"Kind" -> "TopDiagonal", "Component" -> 1, "Mu" -> 1, "Row" -> 2, 
          "Column" -> 2, "Expression" -> (-5 - 5*x - y)/
            ((1 + x)*(1 + x + y)), "Status" -> "LeafChannelized", 
          "RootIndices" -> {}, "RadicalBases" -> {}, "GlobalChannels" -> 
           {(-5 - 5*x - y)/((1 + x)*(1 + x + y)), 0, 0, 0, 0, 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "e2a3e3167aa67b641d7340f56ce3177453c871c2b20b38e65ad2d7c22f79a01f"\
|>}}}, {{{<|"Kind" -> "TopDiagonal", "Component" -> 1, "Mu" -> 2, "Row" -> 1, 
          "Column" -> 1, "Expression" -> -2/y, "Status" -> "LeafChannelized", 
          "RootIndices" -> {}, "RadicalBases" -> {}, "GlobalChannels" -> 
           {-2/y, 0, 0, 0, 0, 0, 0, 0}, "RoundTripExact" -> True, 
          "LeafFingerprint" -> 
           "7cad0f25421dc6c0d026867052c7b2e89634d5409f6977d60dc7c970406e0470"\
|>}, {<|"Kind" -> "TopDiagonal", "Component" -> 1, "Mu" -> 2, "Row" -> 1, 
          "Column" -> 2, "Expression" -> 2/(1 + x + y), 
          "Status" -> "LeafChannelized", "RootIndices" -> {}, 
          "RadicalBases" -> {}, "GlobalChannels" -> {2/(1 + x + y), 0, 0, 0, 
            0, 0, 0, 0}, "RoundTripExact" -> True, "LeafFingerprint" -> "0065\
1a38c8348de422ecde19897974e805584661f8f1a9f4672a68d5af00dd32"|>}}, 
       {{<|"Kind" -> "TopDiagonal", "Component" -> 1, "Mu" -> 2, "Row" -> 2, 
          "Column" -> 1, "Expression" -> y^(-1), "Status" -> 
           "LeafChannelized", "RootIndices" -> {}, "RadicalBases" -> {}, 
          "GlobalChannels" -> {y^(-1), 0, 0, 0, 0, 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "04a9f8f70f91a99d46cf1c152edce76ae3bded9c60ea35028fb24be449161226"\
|>}, {<|"Kind" -> "TopDiagonal", "Component" -> 1, "Mu" -> 2, "Row" -> 2, 
          "Column" -> 2, "Expression" -> (1 + x - 3*y)/(y*(1 + x + y)), 
          "Status" -> "LeafChannelized", "RootIndices" -> {}, 
          "RadicalBases" -> {}, "GlobalChannels" -> 
           {(1 + x - 3*y)/(y*(1 + x + y)), 0, 0, 0, 0, 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "90b45cab5107eadf0b29aef6e97d9ed0151ee480163ae8b2b8010d13b2983005"\
|>}}}}, {{{{<|"Kind" -> "BottomDiagonal", "Component" -> 2, "Mu" -> 1, 
          "Row" -> 1, "Column" -> 1, "Expression" -> (-2*(1 + 4*x*y))/
            (x*(-1 + 4*x*y)), "Status" -> "LeafChannelized", 
          "RootIndices" -> {}, "RadicalBases" -> {}, "GlobalChannels" -> 
           {(-2*(1 + 4*x*y))/(x*(-1 + 4*x*y)), 0, 0, 0, 0, 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "330a020a037db9ca9bb1f1b7bc4bfc1990b2daf4246666ffc8eef61656c92267"\
|>}, {<|"Kind" -> "BottomDiagonal", "Component" -> 2, "Mu" -> 1, "Row" -> 1, 
          "Column" -> 2, "Expression" -> -1/2*Sqrt[1 - 4*x*y]/
             (x*(-1 + 4*x*y)), "Status" -> "LeafChannelized", 
          "RootIndices" -> {3}, "RadicalBases" -> {1 - 4*x*y}, 
          "GlobalChannels" -> {0, 0, 0, 0, -1/2*1/(x*(-1 + 4*x*y)), 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "747af127b31b9f68ce6678efd7447e430d3ec4cae2eee888f4406e4d892c8b92"\
|>}}, {{<|"Kind" -> "BottomDiagonal", "Component" -> 2, "Mu" -> 1, 
          "Row" -> 2, "Column" -> 1, "Expression" -> -4/(x*Sqrt[1 - 4*x*y]), 
          "Status" -> "LeafChannelized", "RootIndices" -> {3}, 
          "RadicalBases" -> {1 - 4*x*y}, "GlobalChannels" -> 
           {0, 0, 0, 0, 4/(x*(-1 + 4*x*y)), 0, 0, 0}, "RoundTripExact" -> 
           True, "LeafFingerprint" -> 
           "deac5292e1494719d34a3fcd21df970baf4c3548d85178bd99063adcc2ea9f3a"\
|>}, {<|"Kind" -> "BottomDiagonal", "Component" -> 2, "Mu" -> 1, "Row" -> 2, 
          "Column" -> 2, "Expression" -> -x^(-1), "Status" -> 
           "LeafChannelized", "RootIndices" -> {}, "RadicalBases" -> {}, 
          "GlobalChannels" -> {-x^(-1), 0, 0, 0, 0, 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "91697a6f03eaaf4f97a12e8e232a15f5065758ce3d4a5c7ecea854fa686270cd"\
|>}}}, {{{<|"Kind" -> "BottomDiagonal", "Component" -> 2, "Mu" -> 2, 
          "Row" -> 1, "Column" -> 1, "Expression" -> (-2*(1 + 4*x*y))/
            (y*(-1 + 4*x*y)), "Status" -> "LeafChannelized", 
          "RootIndices" -> {}, "RadicalBases" -> {}, "GlobalChannels" -> 
           {(-2*(1 + 4*x*y))/(y*(-1 + 4*x*y)), 0, 0, 0, 0, 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "c9b77fc667b05b839f145332e94a429bbfc3786534b5d6252822485bc707284b"\
|>}, {<|"Kind" -> "BottomDiagonal", "Component" -> 2, "Mu" -> 2, "Row" -> 1, 
          "Column" -> 2, "Expression" -> -1/2*Sqrt[1 - 4*x*y]/
             (y*(-1 + 4*x*y)), "Status" -> "LeafChannelized", 
          "RootIndices" -> {3}, "RadicalBases" -> {1 - 4*x*y}, 
          "GlobalChannels" -> {0, 0, 0, 0, -1/2*1/(y*(-1 + 4*x*y)), 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "594508f6898ef9f4569e1d1c8d724b2197457d7d95eb8774f70bd2317011f85d"\
|>}}, {{<|"Kind" -> "BottomDiagonal", "Component" -> 2, "Mu" -> 2, 
          "Row" -> 2, "Column" -> 1, "Expression" -> -4/(y*Sqrt[1 - 4*x*y]), 
          "Status" -> "LeafChannelized", "RootIndices" -> {3}, 
          "RadicalBases" -> {1 - 4*x*y}, "GlobalChannels" -> 
           {0, 0, 0, 0, 4/(y*(-1 + 4*x*y)), 0, 0, 0}, "RoundTripExact" -> 
           True, "LeafFingerprint" -> 
           "e38a729236eac1d237a3708bcfb576058fdfd71645b9f8ccdab2ac9519c6d1de"\
|>}, {<|"Kind" -> "BottomDiagonal", "Component" -> 2, "Mu" -> 2, "Row" -> 2, 
          "Column" -> 2, "Expression" -> -y^(-1), "Status" -> 
           "LeafChannelized", "RootIndices" -> {}, "RadicalBases" -> {}, 
          "GlobalChannels" -> {-y^(-1), 0, 0, 0, 0, 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "0b5d9a69ac869e4ae4d1c7039ebf36433dd81c9dbf090b481b729335ee24e66c"\
|>}}}}, {{{{<|"SourceColumn" -> 21, "PrefixCoefficient" -> 
           ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps))/eps^3, 
          "SourceTerm" -> (-2*(-4*eps*y - 46*eps^2*y - 132*eps^3*y - 
              112*eps^4*y - 8*eps*x*y - 92*eps^2*x*y - 264*eps^3*x*y - 
              224*eps^4*x*y - 4*eps*x^2*y - 46*eps^2*x^2*y - 
              132*eps^3*x^2*y - 112*eps^4*x^2*y + 4*y^2 + 43*eps*y^2 + 
              75*eps^2*y^2 - 84*eps^3*y^2 - 192*eps^4*y^2 + 10*x*y^2 + 
              152*eps*x*y^2 + 686*eps^2*x*y^2 + 1164*eps^3*x*y^2 + 
              640*eps^4*x*y^2 + 8*x^2*y^2 + 159*eps*x^2*y^2 + 
              971*eps^2*x^2*y^2 + 2128*eps^3*x^2*y^2 + 1520*eps^4*x^2*y^2 + 
              2*x^3*y^2 + 50*eps*x^3*y^2 + 360*eps^2*x^3*y^2 + 
              880*eps^3*x^3*y^2 + 688*eps^4*x^3*y^2 + 8*y^3 + 99*eps*y^3 + 
              293*eps^2*y^3 + 232*eps^3*y^3 - 48*eps^4*y^3 + 16*x*y^3 + 
              280*eps*x*y^3 + 1596*eps^2*x*y^3 + 3388*eps^3*x*y^3 + 
              2352*eps^4*x*y^3 + 8*x^2*y^3 + 131*eps*x^2*y^3 + 
              864*eps^2*x^2*y^3 + 2177*eps^3*x^2*y^3 + 1772*eps^4*x^2*y^3 + 
              8*x^3*y^3 + 34*eps*x^3*y^3 - 234*eps^2*x^3*y^3 - 
              940*eps^3*x^3*y^3 - 824*eps^4*x^3*y^3 + 4*x^4*y^3 + 
              28*eps*x^4*y^3 - 40*eps^2*x^4*y^3 - 384*eps^3*x^4*y^3 - 
              448*eps^4*x^4*y^3 + 4*y^4 + 52*eps*y^4 + 172*eps^2*y^4 + 
              184*eps^3*y^4 + 32*eps^4*y^4 + 14*x*y^4 + 240*eps*x*y^4 + 
              1458*eps^2*x*y^4 + 3272*eps^3*x*y^4 + 2384*eps^4*x*y^4 - 
              4*x^2*y^4 - 88*eps*x^2*y^4 - 442*eps^2*x^2*y^4 - 
              854*eps^3*x^2*y^4 - 528*eps^4*x^2*y^4 + 6*x^3*y^4 + 
              36*eps*x^3*y^4 - 182*eps^2*x^3*y^4 - 1028*eps^3*x^3*y^4 - 
              1072*eps^4*x^3*y^4 - 4*x^4*y^4 - 24*eps*x^4*y^4 + 
              60*eps^2*x^4*y^4 + 304*eps^3*x^4*y^4 + 224*eps^4*x^4*y^4 + 
              8*x*y^5 + 120*eps*x*y^5 + 640*eps^2*x*y^5 + 1312*eps^3*x*y^5 + 
              896*eps^4*x*y^5 - 16*x^2*y^5 - 224*eps*x^2*y^5 - 
              944*eps^2*x^2*y^5 - 1696*eps^3*x^2*y^5 - 1088*eps^4*x^2*y^5 + 
              8*x^3*y^5 + 104*eps*x^3*y^5 + 440*eps^2*x^3*y^5 + 
              664*eps^3*x^3*y^5 + 320*eps^4*x^3*y^5))/((1 + 2*eps)*
             (1 + 5*eps)*(2 + 5*eps)*Sqrt[1 - 4*x*y]*(-1 + 4*x*y)^2*
             (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 
          "Expression" -> (-2*(-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*
             (-4*eps*y - 46*eps^2*y - 132*eps^3*y - 112*eps^4*y - 8*eps*x*y - 
              92*eps^2*x*y - 264*eps^3*x*y - 224*eps^4*x*y - 4*eps*x^2*y - 
              46*eps^2*x^2*y - 132*eps^3*x^2*y - 112*eps^4*x^2*y + 4*y^2 + 
              43*eps*y^2 + 75*eps^2*y^2 - 84*eps^3*y^2 - 192*eps^4*y^2 + 
              10*x*y^2 + 152*eps*x*y^2 + 686*eps^2*x*y^2 + 1164*eps^3*x*y^2 + 
              640*eps^4*x*y^2 + 8*x^2*y^2 + 159*eps*x^2*y^2 + 
              971*eps^2*x^2*y^2 + 2128*eps^3*x^2*y^2 + 1520*eps^4*x^2*y^2 + 
              2*x^3*y^2 + 50*eps*x^3*y^2 + 360*eps^2*x^3*y^2 + 
              880*eps^3*x^3*y^2 + 688*eps^4*x^3*y^2 + 8*y^3 + 99*eps*y^3 + 
              293*eps^2*y^3 + 232*eps^3*y^3 - 48*eps^4*y^3 + 16*x*y^3 + 
              280*eps*x*y^3 + 1596*eps^2*x*y^3 + 3388*eps^3*x*y^3 + 
              2352*eps^4*x*y^3 + 8*x^2*y^3 + 131*eps*x^2*y^3 + 
              864*eps^2*x^2*y^3 + 2177*eps^3*x^2*y^3 + 1772*eps^4*x^2*y^3 + 
              8*x^3*y^3 + 34*eps*x^3*y^3 - 234*eps^2*x^3*y^3 - 
              940*eps^3*x^3*y^3 - 824*eps^4*x^3*y^3 + 4*x^4*y^3 + 
              28*eps*x^4*y^3 - 40*eps^2*x^4*y^3 - 384*eps^3*x^4*y^3 - 
              448*eps^4*x^4*y^3 + 4*y^4 + 52*eps*y^4 + 172*eps^2*y^4 + 
              184*eps^3*y^4 + 32*eps^4*y^4 + 14*x*y^4 + 240*eps*x*y^4 + 
              1458*eps^2*x*y^4 + 3272*eps^3*x*y^4 + 2384*eps^4*x*y^4 - 
              4*x^2*y^4 - 88*eps*x^2*y^4 - 442*eps^2*x^2*y^4 - 
              854*eps^3*x^2*y^4 - 528*eps^4*x^2*y^4 + 6*x^3*y^4 + 
              36*eps*x^3*y^4 - 182*eps^2*x^3*y^4 - 1028*eps^3*x^3*y^4 - 
              1072*eps^4*x^3*y^4 - 4*x^4*y^4 - 24*eps*x^4*y^4 + 
              60*eps^2*x^4*y^4 + 304*eps^3*x^4*y^4 + 224*eps^4*x^4*y^4 + 
              8*x*y^5 + 120*eps*x*y^5 + 640*eps^2*x*y^5 + 1312*eps^3*x*y^5 + 
              896*eps^4*x*y^5 - 16*x^2*y^5 - 224*eps*x^2*y^5 - 
              944*eps^2*x^2*y^5 - 1696*eps^3*x^2*y^5 - 1088*eps^4*x^2*y^5 + 
              8*x^3*y^5 + 104*eps*x^3*y^5 + 440*eps^2*x^3*y^5 + 
              664*eps^3*x^3*y^5 + 320*eps^4*x^3*y^5))/(eps^3*(1 + 2*eps)*
             (1 + 5*eps)*(2 + 5*eps)*Sqrt[1 - 4*x*y]*(-1 + 4*x*y)^2*
             (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 
          "Kind" -> "DeferredBase", "Component" -> 3, "Mu" -> 1, "Row" -> 1, 
          "Column" -> 1, "GlobalColumn" -> 21, "Status" -> "LeafChannelized", 
          "RootIndices" -> {3}, "RadicalBases" -> {1 - 4*x*y}, 
          "GlobalChannels" -> {0, 0, 0, 0, (2*(8*eps*y + 40*eps^2*y - 226*
                eps^3*y - 322*eps^4*y + 1280*eps^5*y + 648*eps^6*y - 2016*
                eps^7*y + 16*eps*x*y + 80*eps^2*x*y - 452*eps^3*x*y - 644*
                eps^4*x*y + 2560*eps^5*x*y + 1296*eps^6*x*y - 4032*eps^7*x*
                y + 8*eps*x^2*y + 40*eps^2*x^2*y - 226*eps^3*x^2*y - 322*
                eps^4*x^2*y + 1280*eps^5*x^2*y + 648*eps^6*x^2*y - 2016*eps^7*
                x^2*y - 8*y^2 - 34*eps*y^2 + 301*eps^2*y^2 + 54*eps^3*y^2 - 
               1959*eps^4*y^2 + 1122*eps^5*y^2 + 3672*eps^6*y^2 - 3456*eps^7*
                y^2 - 20*x*y^2 - 174*eps*x*y^2 + 334*eps^2*x*y^2 + 2666*eps^3*
                x*y^2 - 1934*eps^4*x*y^2 - 10760*eps^5*x*y^2 + 3672*eps^6*x*
                y^2 + 11520*eps^7*x*y^2 - 16*x^2*y^2 - 214*eps*x^2*y^2 - 91*
                eps^2*x^2*y^2 + 4218*eps^3*x^2*y^2 + 1269*eps^4*x^2*y^2 - 
               20218*eps^5*x^2*y^2 - 2736*eps^6*x^2*y^2 + 27360*eps^7*x^2*
                y^2 - 4*x^3*y^2 - 74*eps*x^3*y^2 - 124*eps^2*x^3*y^2 + 1606*
                eps^3*x^3*y^2 + 1244*eps^4*x^3*y^2 - 8336*eps^5*x^3*y^2 - 
               2736*eps^6*x^3*y^2 + 12384*eps^7*x^3*y^2 - 16*y^3 - 94*eps*
                y^3 + 485*eps^2*y^3 + 816*eps^3*y^3 - 3017*eps^4*y^3 - 1614*
                eps^5*y^3 + 5472*eps^6*y^3 - 864*eps^7*y^3 - 32*x*y^3 - 352*
                eps*x*y^3 + 16*eps^2*x*y^3 + 6700*eps^3*x*y^3 + 1288*eps^4*x*
                y^3 - 32172*eps^5*x*y^3 - 2520*eps^6*x*y^3 + 42336*eps^7*x*
                y^3 - 16*x^2*y^3 - 158*eps*x^2*y^3 - 241*eps^2*x^2*y^3 + 3485*
                eps^3*x^2*y^3 + 3787*eps^4*x^2*y^3 - 20191*eps^5*x^2*y^3 - 
               8658*eps^6*x^2*y^3 + 31896*eps^7*x^2*y^3 - 16*x^3*y^3 + 36*eps*
                x^3*y^3 + 694*eps^2*x^3*y^3 - 1936*eps^3*x^3*y^3 - 3642*eps^4*
                x^3*y^3 + 10456*eps^5*x^3*y^3 + 5328*eps^6*x^3*y^3 - 14832*
                eps^7*x^3*y^3 - 8*x^4*y^3 - 4*eps*x^4*y^3 + 336*eps^2*x^4*
                y^3 - 436*eps^3*x^4*y^3 - 2512*eps^4*x^4*y^3 + 3824*eps^5*x^4*
                y^3 + 5184*eps^6*x^4*y^3 - 8064*eps^7*x^4*y^3 - 8*y^4 - 52*
                eps*y^4 + 224*eps^2*y^4 + 536*eps^3*y^4 - 1380*eps^4*y^4 - 
               1456*eps^5*y^4 + 2448*eps^6*y^4 + 576*eps^7*y^4 - 28*x*y^4 - 
               298*eps*x*y^4 - 174*eps^2*x*y^4 + 6182*eps^3*x*y^4 + 2722*
                eps^4*x*y^4 - 31108*eps^5*x*y^4 - 5472*eps^6*x*y^4 + 42912*
                eps^7*x*y^4 + 8*x^2*y^4 + 124*eps*x^2*y^4 - 152*eps^2*x^2*
                y^4 - 1734*eps^3*x^2*y^4 + 304*eps^4*x^2*y^4 + 8238*eps^5*x^2*
                y^4 - 1116*eps^6*x^2*y^4 - 9504*eps^7*x^2*y^4 - 12*x^3*y^4 + 
               6*eps*x^3*y^4 + 670*eps^2*x^3*y^4 - 1174*eps^3*x^3*y^4 - 5658*
                eps^4*x^3*y^4 + 10544*eps^5*x^3*y^4 + 10440*eps^6*x^3*y^4 - 
               19296*eps^7*x^3*y^4 + 8*x^4*y^4 - 4*eps*x^4*y^4 - 324*eps^2*
                x^4*y^4 + 748*eps^3*x^4*y^4 + 1452*eps^4*x^4*y^4 - 4216*eps^5*
                x^4*y^4 - 576*eps^6*x^4*y^4 + 4032*eps^7*x^4*y^4 - 16*x*y^5 - 
               136*eps*x*y^5 + 64*eps^2*x*y^5 + 2600*eps^3*x*y^5 + 144*eps^4*
                x*y^5 - 12256*eps^5*x*y^5 - 576*eps^6*x*y^5 + 16128*eps^7*x*
                y^5 + 32*x^2*y^5 + 240*eps*x^2*y^5 - 592*eps^2*x^2*y^5 - 3120*
                eps^3*x^2*y^5 + 1584*eps^4*x^2*y^5 + 14656*eps^5*x^2*y^5 - 
               1152*eps^6*x^2*y^5 - 19584*eps^7*x^2*y^5 - 16*x^3*y^5 - 104*
                eps*x^3*y^5 + 256*eps^2*x^3*y^5 + 1728*eps^3*x^3*y^5 - 2016*
                eps^4*x^3*y^5 - 5848*eps^5*x^3*y^5 + 3312*eps^6*x^3*y^5 + 
               5760*eps^7*x^3*y^5))/(eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*
              (-1 + 4*x*y)^3*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
                eps*x*y)^2), 0, 0, 0}, "RoundTripExact" -> True, 
          "LeafFingerprint" -> 
           "aed8dcc5b955aae0d3cf0ddeda18c4bafde19a6806399ad1a42b1c15690e18f3"\
|>}, {<|"SourceColumn" -> 22, "PrefixCoefficient" -> 
           ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps))/eps^3, 
          "SourceTerm" -> (eps*(6*eps*y + 20*eps^2*y + 16*eps^3*y + 
              12*eps*x*y + 40*eps^2*x*y + 32*eps^3*x*y + 6*eps*x^2*y + 
              20*eps^2*x^2*y + 16*eps^3*x^2*y - 11*y^2 - 43*eps*y^2 - 
              44*eps^2*y^2 - 28*x*y^2 - 172*eps*x*y^2 - 300*eps^2*x*y^2 - 
              136*eps^3*x*y^2 - 23*x^2*y^2 - 191*eps*x^2*y^2 - 
              400*eps^2*x^2*y^2 - 224*eps^3*x^2*y^2 - 6*x^3*y^2 - 
              62*eps*x^3*y^2 - 144*eps^2*x^3*y^2 - 88*eps^3*x^3*y^2 - 
              23*y^3 - 109*eps*y^3 - 152*eps^2*y^3 - 48*eps^3*y^3 - 
              28*x*y^3 - 240*eps*x*y^3 - 532*eps^2*x*y^3 - 336*eps^3*x*y^3 + 
              15*x^2*y^3 + 16*eps*x^2*y^3 - 175*eps^2*x^2*y^3 - 
              272*eps^3*x^2*y^3 + 14*x^3*y^3 + 128*eps*x^3*y^3 + 
              158*eps^2*x^3*y^3 - 52*eps^3*x^3*y^3 + 16*eps*x^4*y^3 + 
              16*eps^2*x^4*y^3 - 32*eps^3*x^4*y^3 - 12*y^4 - 60*eps*y^4 - 
              88*eps^2*y^4 - 32*eps^3*y^4 - 88*eps*x*y^4 - 320*eps^2*x*y^4 - 
              296*eps^3*x*y^4 + 36*x^2*y^4 + 172*eps*x^2*y^4 + 
              132*eps^2*x^2*y^4 - 132*eps^3*x^2*y^4 - 8*x^3*y^4 + 
              40*eps^2*x^3*y^4 - 32*eps^3*x^3*y^4 - 16*eps*x^4*y^4 + 
              16*eps^3*x^4*y^4 - 32*eps*x*y^5 - 128*eps^2*x*y^5 - 
              128*eps^3*x*y^5 + 32*x^2*y^5 + 144*eps*x^2*y^5 + 
              176*eps^2*x^2*y^5 + 32*eps^3*x^2*y^5 + 16*eps^2*x^3*y^5 + 
              16*eps^3*x^3*y^5))/((1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*
             (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
               eps*x*y)^2), "Expression" -> ((-1 + 2*eps)*(-2 + 3*eps)*
             (-1 + 3*eps)*(6*eps*y + 20*eps^2*y + 16*eps^3*y + 12*eps*x*y + 
              40*eps^2*x*y + 32*eps^3*x*y + 6*eps*x^2*y + 20*eps^2*x^2*y + 
              16*eps^3*x^2*y - 11*y^2 - 43*eps*y^2 - 44*eps^2*y^2 - 
              28*x*y^2 - 172*eps*x*y^2 - 300*eps^2*x*y^2 - 136*eps^3*x*y^2 - 
              23*x^2*y^2 - 191*eps*x^2*y^2 - 400*eps^2*x^2*y^2 - 
              224*eps^3*x^2*y^2 - 6*x^3*y^2 - 62*eps*x^3*y^2 - 
              144*eps^2*x^3*y^2 - 88*eps^3*x^3*y^2 - 23*y^3 - 109*eps*y^3 - 
              152*eps^2*y^3 - 48*eps^3*y^3 - 28*x*y^3 - 240*eps*x*y^3 - 
              532*eps^2*x*y^3 - 336*eps^3*x*y^3 + 15*x^2*y^3 + 
              16*eps*x^2*y^3 - 175*eps^2*x^2*y^3 - 272*eps^3*x^2*y^3 + 
              14*x^3*y^3 + 128*eps*x^3*y^3 + 158*eps^2*x^3*y^3 - 
              52*eps^3*x^3*y^3 + 16*eps*x^4*y^3 + 16*eps^2*x^4*y^3 - 
              32*eps^3*x^4*y^3 - 12*y^4 - 60*eps*y^4 - 88*eps^2*y^4 - 
              32*eps^3*y^4 - 88*eps*x*y^4 - 320*eps^2*x*y^4 - 
              296*eps^3*x*y^4 + 36*x^2*y^4 + 172*eps*x^2*y^4 + 
              132*eps^2*x^2*y^4 - 132*eps^3*x^2*y^4 - 8*x^3*y^4 + 
              40*eps^2*x^3*y^4 - 32*eps^3*x^3*y^4 - 16*eps*x^4*y^4 + 
              16*eps^3*x^4*y^4 - 32*eps*x*y^5 - 128*eps^2*x*y^5 - 
              128*eps^3*x*y^5 + 32*x^2*y^5 + 144*eps*x^2*y^5 + 
              176*eps^2*x^2*y^5 + 32*eps^3*x^2*y^5 + 16*eps^2*x^3*y^5 + 
              16*eps^3*x^3*y^5))/(eps^2*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*
             (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
               eps*x*y)^2), "Kind" -> "DeferredBase", "Component" -> 3, 
          "Mu" -> 1, "Row" -> 1, "Column" -> 2, "GlobalColumn" -> 22, 
          "Status" -> "LeafChannelized", "RootIndices" -> {}, 
          "RadicalBases" -> {}, "GlobalChannels" -> 
           {((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(6*eps*y + 20*eps^2*y + 
               16*eps^3*y + 12*eps*x*y + 40*eps^2*x*y + 32*eps^3*x*y + 6*eps*
                x^2*y + 20*eps^2*x^2*y + 16*eps^3*x^2*y - 11*y^2 - 43*eps*
                y^2 - 44*eps^2*y^2 - 28*x*y^2 - 172*eps*x*y^2 - 300*eps^2*x*
                y^2 - 136*eps^3*x*y^2 - 23*x^2*y^2 - 191*eps*x^2*y^2 - 400*
                eps^2*x^2*y^2 - 224*eps^3*x^2*y^2 - 6*x^3*y^2 - 62*eps*x^3*
                y^2 - 144*eps^2*x^3*y^2 - 88*eps^3*x^3*y^2 - 23*y^3 - 109*eps*
                y^3 - 152*eps^2*y^3 - 48*eps^3*y^3 - 28*x*y^3 - 240*eps*x*
                y^3 - 532*eps^2*x*y^3 - 336*eps^3*x*y^3 + 15*x^2*y^3 + 16*eps*
                x^2*y^3 - 175*eps^2*x^2*y^3 - 272*eps^3*x^2*y^3 + 14*x^3*
                y^3 + 128*eps*x^3*y^3 + 158*eps^2*x^3*y^3 - 52*eps^3*x^3*
                y^3 + 16*eps*x^4*y^3 + 16*eps^2*x^4*y^3 - 32*eps^3*x^4*y^3 - 
               12*y^4 - 60*eps*y^4 - 88*eps^2*y^4 - 32*eps^3*y^4 - 88*eps*x*
                y^4 - 320*eps^2*x*y^4 - 296*eps^3*x*y^4 + 36*x^2*y^4 + 172*
                eps*x^2*y^4 + 132*eps^2*x^2*y^4 - 132*eps^3*x^2*y^4 - 8*x^3*
                y^4 + 40*eps^2*x^3*y^4 - 32*eps^3*x^3*y^4 - 16*eps*x^4*y^4 + 
               16*eps^3*x^4*y^4 - 32*eps*x*y^5 - 128*eps^2*x*y^5 - 128*eps^3*
                x*y^5 + 32*x^2*y^5 + 144*eps*x^2*y^5 + 176*eps^2*x^2*y^5 + 32*
                eps^3*x^2*y^5 + 16*eps^2*x^3*y^5 + 16*eps^3*x^3*y^5))/
             (eps^2*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*(-1 + 4*x*y)^2*
              (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 0, 
            0, 0, 0, 0, 0, 0}, "RoundTripExact" -> True, "LeafFingerprint" -> 
           "2a299fdfff6c4a3d78a6973db10bff414d54ea15bffb3dd940583209ed7999af"\
|>}}, {{<|"SourceColumn" -> 21, "PrefixCoefficient" -> 
           ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps))/eps^3, 
          "SourceTerm" -> (-2*(1 + x + y)*(-2 - 29*eps - 135*eps^2 - 
              254*eps^3 - 168*eps^4 - 4*x - 58*eps*x - 270*eps^2*x - 
              508*eps^3*x - 336*eps^4*x - 2*x^2 - 29*eps*x^2 - 
              135*eps^2*x^2 - 254*eps^3*x^2 - 168*eps^4*x^2 - 8*y - 
              110*eps*y - 448*eps^2*y - 726*eps^3*y - 408*eps^4*y - 4*x*y - 
              58*eps*x*y - 197*eps^2*x*y - 187*eps^3*x*y + 20*eps^4*x*y + 
              12*x^2*y + 166*eps*x^2*y + 793*eps^2*x^2*y + 1607*eps^3*x^2*y + 
              1180*eps^4*x^2*y + 8*x^3*y + 114*eps*x^3*y + 542*eps^2*x^3*y + 
              1068*eps^3*x^3*y + 752*eps^4*x^3*y - 10*y^2 - 133*eps*y^2 - 
              485*eps^2*y^2 - 656*eps^3*y^2 - 272*eps^4*y^2 + 2*x*y^2 + 
              18*eps*x*y^2 + 44*eps^2*x*y^2 + 124*eps^3*x*y^2 + 
              208*eps^4*x*y^2 + 2*x^2*y^2 + 55*eps*x^2*y^2 + 266*eps^2*x^2*y^
                2 + 505*eps^3*x^2*y^2 + 388*eps^4*x^2*y^2 - 26*x^3*y^2 - 
              308*eps*x^3*y^2 - 1180*eps^2*x^3*y^2 - 1930*eps^3*x^3*y^2 - 
              1176*eps^4*x^3*y^2 - 12*x^4*y^2 - 156*eps*x^4*y^2 - 
              672*eps^2*x^4*y^2 - 1232*eps^3*x^4*y^2 - 832*eps^4*x^4*y^2 - 
              4*y^3 - 52*eps*y^3 - 172*eps^2*y^3 - 184*eps^3*y^3 - 
              32*eps^4*y^3 - 6*x*y^3 - 104*eps*x*y^3 - 690*eps^2*x*y^3 - 
              1576*eps^3*x*y^3 - 1104*eps^4*x*y^3 - 4*x^2*y^3 - 
              32*eps*x^2*y^3 - 150*eps^2*x^2*y^3 - 234*eps^3*x^2*y^3 - 
              112*eps^4*x^2*y^3 - 14*x^3*y^3 - 172*eps*x^3*y^3 - 
              578*eps^2*x^3*y^3 - 628*eps^3*x^3*y^3 - 208*eps^4*x^3*y^3 + 
              12*x^4*y^3 + 144*eps*x^4*y^3 + 540*eps^2*x^4*y^3 + 
              824*eps^3*x^4*y^3 + 416*eps^4*x^4*y^3 - 8*x*y^4 - 
              120*eps*x*y^4 - 640*eps^2*x*y^4 - 1312*eps^3*x*y^4 - 
              896*eps^4*x*y^4 + 16*x^2*y^4 + 224*eps*x^2*y^4 + 
              944*eps^2*x^2*y^4 + 1696*eps^3*x^2*y^4 + 1088*eps^4*x^2*y^4 - 
              8*x^3*y^4 - 104*eps*x^3*y^4 - 440*eps^2*x^3*y^4 - 
              664*eps^3*x^3*y^4 - 320*eps^4*x^3*y^4))/((1 + 2*eps)*
             (1 + 5*eps)*(2 + 5*eps)*Sqrt[1 - 4*x*y]*(-1 + 4*x*y)^2*
             (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 
          "Expression" -> (-2*(-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*
             (1 + x + y)*(-2 - 29*eps - 135*eps^2 - 254*eps^3 - 168*eps^4 - 
              4*x - 58*eps*x - 270*eps^2*x - 508*eps^3*x - 336*eps^4*x - 
              2*x^2 - 29*eps*x^2 - 135*eps^2*x^2 - 254*eps^3*x^2 - 
              168*eps^4*x^2 - 8*y - 110*eps*y - 448*eps^2*y - 726*eps^3*y - 
              408*eps^4*y - 4*x*y - 58*eps*x*y - 197*eps^2*x*y - 
              187*eps^3*x*y + 20*eps^4*x*y + 12*x^2*y + 166*eps*x^2*y + 
              793*eps^2*x^2*y + 1607*eps^3*x^2*y + 1180*eps^4*x^2*y + 
              8*x^3*y + 114*eps*x^3*y + 542*eps^2*x^3*y + 1068*eps^3*x^3*y + 
              752*eps^4*x^3*y - 10*y^2 - 133*eps*y^2 - 485*eps^2*y^2 - 
              656*eps^3*y^2 - 272*eps^4*y^2 + 2*x*y^2 + 18*eps*x*y^2 + 
              44*eps^2*x*y^2 + 124*eps^3*x*y^2 + 208*eps^4*x*y^2 + 
              2*x^2*y^2 + 55*eps*x^2*y^2 + 266*eps^2*x^2*y^2 + 
              505*eps^3*x^2*y^2 + 388*eps^4*x^2*y^2 - 26*x^3*y^2 - 
              308*eps*x^3*y^2 - 1180*eps^2*x^3*y^2 - 1930*eps^3*x^3*y^2 - 
              1176*eps^4*x^3*y^2 - 12*x^4*y^2 - 156*eps*x^4*y^2 - 
              672*eps^2*x^4*y^2 - 1232*eps^3*x^4*y^2 - 832*eps^4*x^4*y^2 - 
              4*y^3 - 52*eps*y^3 - 172*eps^2*y^3 - 184*eps^3*y^3 - 
              32*eps^4*y^3 - 6*x*y^3 - 104*eps*x*y^3 - 690*eps^2*x*y^3 - 
              1576*eps^3*x*y^3 - 1104*eps^4*x*y^3 - 4*x^2*y^3 - 
              32*eps*x^2*y^3 - 150*eps^2*x^2*y^3 - 234*eps^3*x^2*y^3 - 
              112*eps^4*x^2*y^3 - 14*x^3*y^3 - 172*eps*x^3*y^3 - 
              578*eps^2*x^3*y^3 - 628*eps^3*x^3*y^3 - 208*eps^4*x^3*y^3 + 
              12*x^4*y^3 + 144*eps*x^4*y^3 + 540*eps^2*x^4*y^3 + 
              824*eps^3*x^4*y^3 + 416*eps^4*x^4*y^3 - 8*x*y^4 - 
              120*eps*x*y^4 - 640*eps^2*x*y^4 - 1312*eps^3*x*y^4 - 
              896*eps^4*x*y^4 + 16*x^2*y^4 + 224*eps*x^2*y^4 + 
              944*eps^2*x^2*y^4 + 1696*eps^3*x^2*y^4 + 1088*eps^4*x^2*y^4 - 
              8*x^3*y^4 - 104*eps*x^3*y^4 - 440*eps^2*x^3*y^4 - 
              664*eps^3*x^3*y^4 - 320*eps^4*x^3*y^4))/(eps^3*(1 + 2*eps)*
             (1 + 5*eps)*(2 + 5*eps)*Sqrt[1 - 4*x*y]*(-1 + 4*x*y)^2*
             (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 
          "Kind" -> "DeferredBase", "Component" -> 3, "Mu" -> 1, "Row" -> 2, 
          "Column" -> 1, "GlobalColumn" -> 21, "Status" -> "LeafChannelized", 
          "RootIndices" -> {3}, "RadicalBases" -> {1 - 4*x*y}, 
          "GlobalChannels" -> {0, 0, 0, 0, (2*(4 + 32*eps - 53*eps^2 - 500*
                eps^3 + 157*eps^4 + 2244*eps^5 - 36*eps^6 - 3024*eps^7 + 12*
                x + 96*eps*x - 159*eps^2*x - 1500*eps^3*x + 471*eps^4*x + 
               6732*eps^5*x - 108*eps^6*x - 9072*eps^7*x + 12*x^2 + 96*eps*
                x^2 - 159*eps^2*x^2 - 1500*eps^3*x^2 + 471*eps^4*x^2 + 6732*
                eps^5*x^2 - 108*eps^6*x^2 - 9072*eps^7*x^2 + 4*x^3 + 32*eps*
                x^3 - 53*eps^2*x^3 - 500*eps^3*x^3 + 157*eps^4*x^3 + 2244*
                eps^5*x^3 - 36*eps^6*x^3 - 3024*eps^7*x^3 + 20*y + 148*eps*
                y - 371*eps^2*y - 2046*eps^3*y + 1651*eps^4*y + 8478*eps^5*
                y - 2088*eps^6*y - 10368*eps^7*y + 32*x*y + 244*eps*x*y - 676*
                eps^2*x*y - 3239*eps^3*x*y + 3612*eps^4*x*y + 12485*eps^5*x*
                y - 6030*eps^6*x*y - 13032*eps^7*x*y - 12*x^2*y - 80*eps*x^2*
                y - 57*eps^2*x^2*y + 1636*eps^3*x^2*y + 2069*eps^4*x^2*y - 
               9768*eps^5*x^2*y - 6876*eps^6*x^2*y + 18576*eps^7*x^2*y - 40*
                x^3*y - 300*eps*x^3*y + 430*eps^2*x^3*y + 4805*eps^3*x^3*y - 
               94*eps^4*x^3*y - 23079*eps^5*x^3*y - 4014*eps^6*x^3*y + 34776*
                eps^7*x^3*y - 16*x^4*y - 124*eps*x^4*y + 182*eps^2*x^4*y + 
               1976*eps^3*x^4*y - 202*eps^4*x^4*y - 9304*eps^5*x^4*y - 1080*
                eps^6*x^4*y + 13536*eps^7*x^4*y + 36*y^2 + 252*eps*y^2 - 807*
                eps^2*y^2 - 3128*eps^3*y^2 + 4211*eps^4*y^2 + 11680*eps^5*
                y^2 - 6516*eps^6*y^2 - 12240*eps^7*y^2 + 24*x*y^2 + 190*eps*x*
                y^2 - 649*eps^2*x*y^2 - 2401*eps^3*x*y^2 + 4853*eps^4*x*y^2 + 
               7357*eps^5*x*y^2 - 11754*eps^6*x*y^2 - 792*eps^7*x*y^2 - 32*
                x^2*y^2 - 270*eps*x^2*y^2 + 469*eps^2*x^2*y^2 + 3702*eps^3*
                x^2*y^2 + 37*eps^4*x^2*y^2 - 17430*eps^5*x^2*y^2 - 7704*eps^6*
                x^2*y^2 + 31968*eps^7*x^2*y^2 + 32*x^3*y^2 + 70*eps*x^3*y^2 - 
               631*eps^2*x^3*y^2 - 657*eps^3*x^3*y^2 + 2973*eps^4*x^3*y^2 + 
               2475*eps^5*x^3*y^2 - 5454*eps^6*x^3*y^2 - 648*eps^7*x^3*y^2 + 
               76*x^4*y^2 + 434*eps*x^4*y^2 - 1302*eps^2*x^4*y^2 - 5908*eps^3*
                x^4*y^2 + 4562*eps^4*x^4*y^2 + 25934*eps^5*x^4*y^2 - 2700*
                eps^6*x^4*y^2 - 36144*eps^7*x^4*y^2 + 24*x^5*y^2 + 156*eps*
                x^5*y^2 - 360*eps^2*x^5*y^2 - 2276*eps^3*x^5*y^2 + 984*eps^4*
                x^5*y^2 + 10352*eps^5*x^5*y^2 + 288*eps^6*x^5*y^2 - 14976*
                eps^7*x^5*y^2 + 28*y^3 + 188*eps*y^3 - 713*eps^2*y^3 - 2118*
                eps^3*y^3 + 4097*eps^4*y^3 + 6902*eps^5*y^3 - 6912*eps^6*
                y^3 - 5472*eps^7*y^3 + 16*x*y^3 + 172*eps*x*y^3 + 58*eps^2*x*
                y^3 - 3780*eps^3*x*y^3 + 190*eps^4*x*y^3 + 17384*eps^5*x*
                y^3 - 4392*eps^6*x*y^3 - 16704*eps^7*x*y^3 + 16*x^2*y^3 + 58*
                eps*x^2*y^3 + 311*eps^2*x^2*y^3 - 2809*eps^3*x^2*y^3 - 1269*
                eps^4*x^2*y^3 + 14139*eps^5*x^2*y^3 - 1134*eps^6*x^2*y^3 - 
               14904*eps^7*x^2*y^3 + 88*x^3*y^3 + 452*eps*x^3*y^3 - 1652*
                eps^2*x^3*y^3 - 6188*eps^3*x^3*y^3 + 8996*eps^4*x^3*y^3 + 
               21592*eps^5*x^3*y^3 - 9864*eps^6*x^3*y^3 - 26928*eps^7*x^3*
                y^3 + 28*x^4*y^3 + 186*eps*x^4*y^3 - 594*eps^2*x^4*y^3 - 2442*
                eps^3*x^4*y^3 + 3638*eps^4*x^4*y^3 + 7080*eps^5*x^4*y^3 - 
               1800*eps^6*x^4*y^3 - 11232*eps^7*x^4*y^3 - 24*x^5*y^3 - 132*
                eps*x^5*y^3 + 468*eps^2*x^5*y^3 + 1700*eps^3*x^5*y^3 - 2108*
                eps^4*x^5*y^3 - 7120*eps^5*x^5*y^3 + 3600*eps^6*x^5*y^3 + 
               7488*eps^7*x^5*y^3 + 8*y^4 + 52*eps*y^4 - 224*eps^2*y^4 - 536*
                eps^3*y^4 + 1380*eps^4*y^4 + 1456*eps^5*y^4 - 2448*eps^6*
                y^4 - 576*eps^7*y^4 + 28*x*y^4 + 266*eps*x*y^4 + 126*eps^2*x*
                y^4 - 5718*eps^3*x*y^4 - 1666*eps^4*x*y^4 + 28036*eps^5*x*
                y^4 + 2016*eps^6*x*y^4 - 36000*eps^7*x*y^4 - 8*x^2*y^4 - 92*
                eps*x^2*y^4 + 520*eps^2*x^2*y^4 - 170*eps^3*x^2*y^4 - 1072*
                eps^4*x^2*y^4 - 238*eps^5*x^2*y^4 + 540*eps^6*x^2*y^4 + 1440*
                eps^7*x^2*y^4 + 12*x^3*y^4 + 26*eps*x^3*y^4 - 366*eps^2*x^3*
                y^4 - 474*eps^3*x^3*y^4 + 5194*eps^4*x^3*y^4 - 4960*eps^5*x^3*
                y^4 - 7848*eps^6*x^3*y^4 + 10080*eps^7*x^3*y^4 - 8*x^4*y^4 - 
               28*eps*x^4*y^4 + 212*eps^2*x^4*y^4 - 28*eps^3*x^4*y^4 - 92*
                eps^4*x^4*y^4 - 1272*eps^5*x^4*y^4 + 288*eps^6*x^4*y^4 + 1728*
                eps^7*x^4*y^4 + 16*x*y^5 + 136*eps*x*y^5 - 64*eps^2*x*y^5 - 
               2600*eps^3*x*y^5 - 144*eps^4*x*y^5 + 12256*eps^5*x*y^5 + 576*
                eps^6*x*y^5 - 16128*eps^7*x*y^5 - 32*x^2*y^5 - 240*eps*x^2*
                y^5 + 592*eps^2*x^2*y^5 + 3120*eps^3*x^2*y^5 - 1584*eps^4*x^2*
                y^5 - 14656*eps^5*x^2*y^5 + 1152*eps^6*x^2*y^5 + 19584*eps^7*
                x^2*y^5 + 16*x^3*y^5 + 104*eps*x^3*y^5 - 256*eps^2*x^3*y^5 - 
               1728*eps^3*x^3*y^5 + 2016*eps^4*x^3*y^5 + 5848*eps^5*x^3*y^5 - 
               3312*eps^6*x^3*y^5 - 5760*eps^7*x^3*y^5))/
             (eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*(-1 + 4*x*y)^3*
              (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 0, 
            0, 0}, "RoundTripExact" -> True, "LeafFingerprint" -> "73203f44bf\
d0615676d6d91c990829fa292de9d14cd5b7220ac80991c632d33e"|>}, 
        {<|"SourceColumn" -> 22, "PrefixCoefficient" -> 
           ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps))/eps^3, 
          "SourceTerm" -> (eps*(1 + x + y)*(3 + 19*eps + 38*eps^2 + 
              24*eps^3 + 6*x + 38*eps*x + 76*eps^2*x + 48*eps^3*x + 3*x^2 + 
              19*eps*x^2 + 38*eps^2*x^2 + 24*eps^3*x^2 + 18*y + 104*eps*y + 
              198*eps^2*y + 120*eps^3*y + 24*x*y + 151*eps*x*y + 
              307*eps^2*x*y + 196*eps^3*x*y + 13*eps*x^2*y + 49*eps^2*x^2*y + 
              44*eps^3*x^2*y - 6*x^3*y - 34*eps*x^3*y - 60*eps^2*x^3*y - 
              32*eps^3*x^3*y + 27*y^2 + 145*eps*y^2 + 248*eps^2*y^2 + 
              128*eps^3*y^2 + 4*eps*x*y^2 - 28*eps^2*x*y^2 - 64*eps^3*x*y^2 - 
              51*x^2*y^2 - 364*eps*x^2*y^2 - 845*eps^2*x^2*y^2 - 
              628*eps^3*x^2*y^2 - 18*x^3*y^2 - 220*eps*x^3*y^2 - 
              634*eps^2*x^3*y^2 - 528*eps^3*x^3*y^2 - 32*eps*x^4*y^2 - 
              128*eps^2*x^4*y^2 - 128*eps^3*x^4*y^2 + 12*y^3 + 60*eps*y^3 + 
              88*eps^2*y^3 + 32*eps^3*y^3 - 16*x*y^3 - 56*eps*x*y^3 - 
              64*eps^2*x*y^3 - 24*eps^3*x*y^3 - 36*x^2*y^3 - 204*eps*x^2*y^
                3 - 356*eps^2*x^2*y^3 - 188*eps^3*x^2*y^3 + 24*x^3*y^3 + 
              128*eps*x^3*y^3 + 216*eps^2*x^3*y^3 + 112*eps^3*x^3*y^3 + 
              32*eps*x^4*y^3 + 96*eps^2*x^4*y^3 + 64*eps^3*x^4*y^3 + 
              32*eps*x*y^4 + 128*eps^2*x*y^4 + 128*eps^3*x*y^4 - 32*x^2*y^4 - 
              144*eps*x^2*y^4 - 176*eps^2*x^2*y^4 - 32*eps^3*x^2*y^4 - 
              16*eps^2*x^3*y^4 - 16*eps^3*x^3*y^4))/((1 + 2*eps)*(1 + 5*eps)*
             (2 + 5*eps)*(-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*
                y + x*y + eps*x*y)^2), "Expression" -> 
           ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(1 + x + y)*
             (3 + 19*eps + 38*eps^2 + 24*eps^3 + 6*x + 38*eps*x + 
              76*eps^2*x + 48*eps^3*x + 3*x^2 + 19*eps*x^2 + 38*eps^2*x^2 + 
              24*eps^3*x^2 + 18*y + 104*eps*y + 198*eps^2*y + 120*eps^3*y + 
              24*x*y + 151*eps*x*y + 307*eps^2*x*y + 196*eps^3*x*y + 
              13*eps*x^2*y + 49*eps^2*x^2*y + 44*eps^3*x^2*y - 6*x^3*y - 
              34*eps*x^3*y - 60*eps^2*x^3*y - 32*eps^3*x^3*y + 27*y^2 + 
              145*eps*y^2 + 248*eps^2*y^2 + 128*eps^3*y^2 + 4*eps*x*y^2 - 
              28*eps^2*x*y^2 - 64*eps^3*x*y^2 - 51*x^2*y^2 - 364*eps*x^2*y^
                2 - 845*eps^2*x^2*y^2 - 628*eps^3*x^2*y^2 - 18*x^3*y^2 - 
              220*eps*x^3*y^2 - 634*eps^2*x^3*y^2 - 528*eps^3*x^3*y^2 - 
              32*eps*x^4*y^2 - 128*eps^2*x^4*y^2 - 128*eps^3*x^4*y^2 + 
              12*y^3 + 60*eps*y^3 + 88*eps^2*y^3 + 32*eps^3*y^3 - 16*x*y^3 - 
              56*eps*x*y^3 - 64*eps^2*x*y^3 - 24*eps^3*x*y^3 - 36*x^2*y^3 - 
              204*eps*x^2*y^3 - 356*eps^2*x^2*y^3 - 188*eps^3*x^2*y^3 + 
              24*x^3*y^3 + 128*eps*x^3*y^3 + 216*eps^2*x^3*y^3 + 
              112*eps^3*x^3*y^3 + 32*eps*x^4*y^3 + 96*eps^2*x^4*y^3 + 
              64*eps^3*x^4*y^3 + 32*eps*x*y^4 + 128*eps^2*x*y^4 + 
              128*eps^3*x*y^4 - 32*x^2*y^4 - 144*eps*x^2*y^4 - 
              176*eps^2*x^2*y^4 - 32*eps^3*x^2*y^4 - 16*eps^2*x^3*y^4 - 
              16*eps^3*x^3*y^4))/(eps^2*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*
             (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
               eps*x*y)^2), "Kind" -> "DeferredBase", "Component" -> 3, 
          "Mu" -> 1, "Row" -> 2, "Column" -> 2, "GlobalColumn" -> 22, 
          "Status" -> "LeafChannelized", "RootIndices" -> {}, 
          "RadicalBases" -> {}, "GlobalChannels" -> 
           {((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(1 + x + y)*
              (3 + 19*eps + 38*eps^2 + 24*eps^3 + 6*x + 38*eps*x + 76*eps^2*
                x + 48*eps^3*x + 3*x^2 + 19*eps*x^2 + 38*eps^2*x^2 + 24*eps^3*
                x^2 + 18*y + 104*eps*y + 198*eps^2*y + 120*eps^3*y + 24*x*
                y + 151*eps*x*y + 307*eps^2*x*y + 196*eps^3*x*y + 13*eps*x^2*
                y + 49*eps^2*x^2*y + 44*eps^3*x^2*y - 6*x^3*y - 34*eps*x^3*
                y - 60*eps^2*x^3*y - 32*eps^3*x^3*y + 27*y^2 + 145*eps*y^2 + 
               248*eps^2*y^2 + 128*eps^3*y^2 + 4*eps*x*y^2 - 28*eps^2*x*y^2 - 
               64*eps^3*x*y^2 - 51*x^2*y^2 - 364*eps*x^2*y^2 - 845*eps^2*x^2*
                y^2 - 628*eps^3*x^2*y^2 - 18*x^3*y^2 - 220*eps*x^3*y^2 - 634*
                eps^2*x^3*y^2 - 528*eps^3*x^3*y^2 - 32*eps*x^4*y^2 - 128*
                eps^2*x^4*y^2 - 128*eps^3*x^4*y^2 + 12*y^3 + 60*eps*y^3 + 88*
                eps^2*y^3 + 32*eps^3*y^3 - 16*x*y^3 - 56*eps*x*y^3 - 64*eps^2*
                x*y^3 - 24*eps^3*x*y^3 - 36*x^2*y^3 - 204*eps*x^2*y^3 - 356*
                eps^2*x^2*y^3 - 188*eps^3*x^2*y^3 + 24*x^3*y^3 + 128*eps*x^3*
                y^3 + 216*eps^2*x^3*y^3 + 112*eps^3*x^3*y^3 + 32*eps*x^4*
                y^3 + 96*eps^2*x^4*y^3 + 64*eps^3*x^4*y^3 + 32*eps*x*y^4 + 
               128*eps^2*x*y^4 + 128*eps^3*x*y^4 - 32*x^2*y^4 - 144*eps*x^2*
                y^4 - 176*eps^2*x^2*y^4 - 32*eps^3*x^2*y^4 - 16*eps^2*x^3*
                y^4 - 16*eps^3*x^3*y^4))/(eps^2*(1 + 2*eps)*(1 + 5*eps)*
              (2 + 5*eps)*(-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 
                2*eps*y + x*y + eps*x*y)^2), 0, 0, 0, 0, 0, 0, 0}, 
          "RoundTripExact" -> True, "LeafFingerprint" -> 
           "6221bcc79519b67cd390be02298aac4a183423191fc5113b98f0a3090249975b"\
|>}}}, {{{<|"SourceColumn" -> 21, "PrefixCoefficient" -> 
           ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps))/eps^3, 
          "SourceTerm" -> (2*(2*eps^2 + 12*eps^3 + 16*eps^4 + 6*eps^2*x + 
              36*eps^3*x + 48*eps^4*x + 6*eps^2*x^2 + 36*eps^3*x^2 + 
              48*eps^4*x^2 + 2*eps^2*x^3 + 12*eps^3*x^3 + 16*eps^4*x^3 + 
              4*eps^2*y + 24*eps^3*y + 32*eps^4*y - 8*x*y - 110*eps*x*y - 
              450*eps^2*x*y - 704*eps^3*x*y - 352*eps^4*x*y - 18*x^2*y - 
              246*eps*x^2*y - 1008*eps^2*x^2*y - 1608*eps^3*x^2*y - 
              848*eps^4*x^2*y - 12*x^3*y - 162*eps*x^3*y - 650*eps^2*x^3*y - 
              1008*eps^3*x^3*y - 512*eps^4*x^3*y - 2*x^4*y - 26*eps*x^4*y - 
              96*eps^2*x^4*y - 128*eps^3*x^4*y - 48*eps^4*x^4*y + 
              2*eps^2*y^2 + 12*eps^3*y^2 + 16*eps^4*y^2 - 16*x*y^2 - 
              223*eps*x*y^2 - 929*eps^2*x*y^2 - 1504*eps^3*x*y^2 - 
              816*eps^4*x*y^2 - 2*x^2*y^2 - 28*eps*x^2*y^2 - 107*eps^2*x^2*y^
                2 - 237*eps^3*x^2*y^2 - 196*eps^4*x^2*y^2 + 28*x^3*y^2 + 
              373*eps*x^3*y^2 + 1432*eps^2*x^3*y^2 + 1923*eps^3*x^3*y^2 + 
              692*eps^4*x^3*y^2 + 10*x^4*y^2 + 118*eps*x^4*y^2 + 
              296*eps^2*x^4*y^2 - 60*eps^3*x^4*y^2 - 520*eps^4*x^4*y^2 - 
              4*x^5*y^2 - 60*eps*x^5*y^2 - 312*eps^2*x^5*y^2 - 
              704*eps^3*x^5*y^2 - 576*eps^4*x^5*y^2 - 8*x*y^3 - 
              112*eps*x*y^3 - 468*eps^2*x*y^3 - 760*eps^3*x*y^3 - 
              416*eps^4*x*y^3 + 26*x^2*y^3 + 368*eps*x^2*y^3 + 
              1494*eps^2*x^2*y^3 + 2248*eps^3*x^2*y^3 + 1072*eps^4*x^2*y^3 + 
              8*x^3*y^3 + 100*eps*x^3*y^3 + 138*eps^2*x^3*y^3 - 
              258*eps^3*x^3*y^3 - 592*eps^4*x^3*y^3 - 22*x^4*y^3 - 
              292*eps*x^4*y^3 - 1290*eps^2*x^4*y^3 - 2124*eps^3*x^4*y^3 - 
              1360*eps^4*x^4*y^3 - 4*x^5*y^3 - 24*eps*x^5*y^3 + 
              60*eps^2*x^5*y^3 + 368*eps^3*x^5*y^3 + 288*eps^4*x^5*y^3 + 
              8*x^2*y^4 + 120*eps*x^2*y^4 + 512*eps^2*x^2*y^4 + 
              800*eps^3*x^2*y^4 + 384*eps^4*x^2*y^4 - 16*x^3*y^4 - 
              224*eps*x^3*y^4 - 944*eps^2*x^3*y^4 - 1568*eps^3*x^3*y^4 - 
              960*eps^4*x^3*y^4 + 8*x^4*y^4 + 104*eps*x^4*y^4 + 
              440*eps^2*x^4*y^4 + 728*eps^3*x^4*y^4 + 384*eps^4*x^4*y^4))/
            ((1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*Sqrt[1 - 4*x*y]*
             (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
               eps*x*y)^2), "Expression" -> (2*(-1 + 2*eps)*(-2 + 3*eps)*
             (-1 + 3*eps)*(2*eps^2 + 12*eps^3 + 16*eps^4 + 6*eps^2*x + 
              36*eps^3*x + 48*eps^4*x + 6*eps^2*x^2 + 36*eps^3*x^2 + 
              48*eps^4*x^2 + 2*eps^2*x^3 + 12*eps^3*x^3 + 16*eps^4*x^3 + 
              4*eps^2*y + 24*eps^3*y + 32*eps^4*y - 8*x*y - 110*eps*x*y - 
              450*eps^2*x*y - 704*eps^3*x*y - 352*eps^4*x*y - 18*x^2*y - 
              246*eps*x^2*y - 1008*eps^2*x^2*y - 1608*eps^3*x^2*y - 
              848*eps^4*x^2*y - 12*x^3*y - 162*eps*x^3*y - 650*eps^2*x^3*y - 
              1008*eps^3*x^3*y - 512*eps^4*x^3*y - 2*x^4*y - 26*eps*x^4*y - 
              96*eps^2*x^4*y - 128*eps^3*x^4*y - 48*eps^4*x^4*y + 
              2*eps^2*y^2 + 12*eps^3*y^2 + 16*eps^4*y^2 - 16*x*y^2 - 
              223*eps*x*y^2 - 929*eps^2*x*y^2 - 1504*eps^3*x*y^2 - 
              816*eps^4*x*y^2 - 2*x^2*y^2 - 28*eps*x^2*y^2 - 107*eps^2*x^2*y^
                2 - 237*eps^3*x^2*y^2 - 196*eps^4*x^2*y^2 + 28*x^3*y^2 + 
              373*eps*x^3*y^2 + 1432*eps^2*x^3*y^2 + 1923*eps^3*x^3*y^2 + 
              692*eps^4*x^3*y^2 + 10*x^4*y^2 + 118*eps*x^4*y^2 + 
              296*eps^2*x^4*y^2 - 60*eps^3*x^4*y^2 - 520*eps^4*x^4*y^2 - 
              4*x^5*y^2 - 60*eps*x^5*y^2 - 312*eps^2*x^5*y^2 - 
              704*eps^3*x^5*y^2 - 576*eps^4*x^5*y^2 - 8*x*y^3 - 
              112*eps*x*y^3 - 468*eps^2*x*y^3 - 760*eps^3*x*y^3 - 
              416*eps^4*x*y^3 + 26*x^2*y^3 + 368*eps*x^2*y^3 + 
              1494*eps^2*x^2*y^3 + 2248*eps^3*x^2*y^3 + 1072*eps^4*x^2*y^3 + 
              8*x^3*y^3 + 100*eps*x^3*y^3 + 138*eps^2*x^3*y^3 - 
              258*eps^3*x^3*y^3 - 592*eps^4*x^3*y^3 - 22*x^4*y^3 - 
              292*eps*x^4*y^3 - 1290*eps^2*x^4*y^3 - 2124*eps^3*x^4*y^3 - 
              1360*eps^4*x^4*y^3 - 4*x^5*y^3 - 24*eps*x^5*y^3 + 
              60*eps^2*x^5*y^3 + 368*eps^3*x^5*y^3 + 288*eps^4*x^5*y^3 + 
              8*x^2*y^4 + 120*eps*x^2*y^4 + 512*eps^2*x^2*y^4 + 
              800*eps^3*x^2*y^4 + 384*eps^4*x^2*y^4 - 16*x^3*y^4 - 
              224*eps*x^3*y^4 - 944*eps^2*x^3*y^4 - 1568*eps^3*x^3*y^4 - 
              960*eps^4*x^3*y^4 + 8*x^4*y^4 + 104*eps*x^4*y^4 + 
              440*eps^2*x^4*y^4 + 728*eps^3*x^4*y^4 + 384*eps^4*x^4*y^4))/
            (eps^3*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*Sqrt[1 - 4*x*y]*
             (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
               eps*x*y)^2), "Kind" -> "DeferredBase", "Component" -> 3, 
          "Mu" -> 2, "Row" -> 1, "Column" -> 1, "GlobalColumn" -> 21, 
          "Status" -> "LeafChannelized", "RootIndices" -> {3}, 
          "RadicalBases" -> {1 - 4*x*y}, "GlobalChannels" -> 
           {0, 0, 0, 0, (-2*(-4*eps^2 + 2*eps^3 + 70*eps^4 - 80*eps^5 - 216*
                eps^6 + 288*eps^7 - 12*eps^2*x + 6*eps^3*x + 210*eps^4*x - 
               240*eps^5*x - 648*eps^6*x + 864*eps^7*x - 12*eps^2*x^2 + 6*
                eps^3*x^2 + 210*eps^4*x^2 - 240*eps^5*x^2 - 648*eps^6*x^2 + 
               864*eps^7*x^2 - 4*eps^2*x^3 + 2*eps^3*x^3 + 70*eps^4*x^3 - 80*
                eps^5*x^3 - 216*eps^6*x^3 + 288*eps^7*x^3 - 8*eps^2*y + 4*
                eps^3*y + 140*eps^4*y - 160*eps^5*y - 432*eps^6*y + 576*eps^7*
                y + 16*x*y + 116*eps*x*y - 314*eps^2*x*y - 1616*eps^3*x*y + 
               1722*eps^4*x*y + 6332*eps^5*x*y - 3168*eps^6*x*y - 6336*eps^7*
                x*y + 36*x^2*y + 258*eps*x^2*y - 696*eps^2*x^2*y - 3570*eps^3*
                x^2*y + 3580*eps^4*x^2*y + 14248*eps^5*x^2*y - 6048*eps^6*x^2*
                y - 15264*eps^7*x^2*y + 24*x^3*y + 168*eps*x^3*y - 482*eps^2*
                x^3*y - 2276*eps^3*x^3*y + 2554*eps^4*x^3*y + 8860*eps^5*x^3*
                y - 4320*eps^6*x^3*y - 9216*eps^7*x^3*y + 4*x^4*y + 26*eps*
                x^4*y - 92*eps^2*x^4*y - 326*eps^3*x^4*y + 556*eps^4*x^4*y + 
               1104*eps^5*x^4*y - 1008*eps^6*x^4*y - 864*eps^7*x^4*y - 4*
                eps^2*y^2 + 2*eps^3*y^2 + 70*eps^4*y^2 - 80*eps^5*y^2 - 216*
                eps^6*y^2 + 288*eps^7*y^2 + 32*x*y^2 + 238*eps*x*y^2 - 609*
                eps^2*x*y^2 - 3336*eps^3*x*y^2 + 3149*eps^4*x*y^2 + 13278*
                eps^5*x*y^2 - 5040*eps^6*x*y^2 - 14688*eps^7*x*y^2 + 4*x^2*
                y^2 + 30*eps*x^2*y^2 - 96*eps^2*x^2*y^2 - 197*eps^3*x^2*y^2 - 
               304*eps^4*x^2*y^2 + 1925*eps^5*x^2*y^2 + 1026*eps^6*x^2*y^2 - 
               3528*eps^7*x^2*y^2 - 56*x^3*y^2 - 382*eps*x^3*y^2 + 1229*eps^2*
                x^3*y^2 + 5203*eps^3*x^3*y^2 - 8335*eps^4*x^3*y^2 - 17149*
                eps^5*x^3*y^2 + 15930*eps^6*x^3*y^2 + 12456*eps^7*x^3*y^2 - 
               20*x^4*y^2 - 106*eps*x^4*y^2 + 672*eps^2*x^4*y^2 + 962*eps^3*
                x^4*y^2 - 5608*eps^4*x^4*y^2 + 188*eps^5*x^4*y^2 + 12960*
                eps^6*x^4*y^2 - 9360*eps^7*x^4*y^2 + 8*x^5*y^2 + 68*eps*x^5*
                y^2 - 48*eps^2*x^5*y^2 - 1100*eps^3*x^5*y^2 - 656*eps^4*x^5*
                y^2 + 5904*eps^5*x^5*y^2 + 2880*eps^6*x^5*y^2 - 10368*eps^7*
                x^5*y^2 + 16*x*y^3 + 120*eps*x*y^3 - 304*eps^2*x*y^3 - 1684*
                eps^3*x*y^3 + 1572*eps^4*x*y^3 + 6688*eps^5*x*y^3 - 2448*
                eps^6*x*y^3 - 7488*eps^7*x*y^3 - 52*x^2*y^3 - 398*eps*x^2*
                y^3 + 1094*eps^2*x^2*y^3 + 5458*eps^3*x^2*y^3 - 6634*eps^4*
                x^2*y^3 - 19868*eps^5*x^2*y^3 + 11520*eps^6*x^2*y^3 + 19296*
                eps^7*x^2*y^3 - 16*x^3*y^3 - 96*eps*x^3*y^3 + 808*eps^2*x^3*
                y^3 - 246*eps^3*x^3*y^3 - 4096*eps^4*x^3*y^3 + 1754*eps^5*x^3*
                y^3 + 11340*eps^6*x^3*y^3 - 10656*eps^7*x^3*y^3 + 44*x^4*
                y^3 + 298*eps*x^4*y^3 - 622*eps^2*x^4*y^3 - 5034*eps^3*x^4*
                y^3 + 4682*eps^4*x^4*y^3 + 16448*eps^5*x^4*y^3 - 1512*eps^6*
                x^4*y^3 - 24480*eps^7*x^4*y^3 + 8*x^5*y^3 - 4*eps*x^5*y^3 - 
               324*eps^2*x^5*y^3 + 620*eps^3*x^5*y^3 + 2156*eps^4*x^5*y^3 - 
               5112*eps^5*x^5*y^3 - 1152*eps^6*x^5*y^3 + 5184*eps^7*x^5*y^3 - 
               16*x^2*y^4 - 136*eps*x^2*y^4 + 320*eps^2*x^2*y^4 + 1960*eps^3*
                x^2*y^4 - 2032*eps^4*x^2*y^4 - 7392*eps^5*x^2*y^4 + 4032*
                eps^6*x^2*y^4 + 6912*eps^7*x^2*y^4 + 32*x^3*y^4 + 240*eps*x^3*
                y^4 - 592*eps^2*x^3*y^4 - 3376*eps^3*x^3*y^4 + 2992*eps^4*x^3*
                y^4 + 12864*eps^5*x^3*y^4 - 2304*eps^6*x^3*y^4 - 17280*eps^7*
                x^3*y^4 - 16*x^4*y^4 - 104*eps*x^4*y^4 + 256*eps^2*x^4*y^4 + 
               1600*eps^3*x^4*y^4 - 1312*eps^4*x^4*y^4 - 6744*eps^5*x^4*y^4 + 
               2736*eps^6*x^4*y^4 + 6912*eps^7*x^4*y^4))/
             (eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*(-1 + 4*x*y)^3*
              (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 0, 
            0, 0}, "RoundTripExact" -> True, "LeafFingerprint" -> "35ea585178\
3ece4d91f5981348733b01846f138a8d87477ce14f7a50d3c7e679"|>}, 
        {<|"SourceColumn" -> 22, "PrefixCoefficient" -> 
           ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps))/eps^3, 
          "SourceTerm" -> -((eps*(-2*eps - 12*eps^2 - 16*eps^3 - 6*eps*x - 36*
                eps^2*x - 48*eps^3*x - 6*eps*x^2 - 36*eps^2*x^2 - 48*eps^3*
                x^2 - 2*eps*x^3 - 12*eps^2*x^3 - 16*eps^3*x^3 - 4*eps*y - 24*
                eps^2*y - 32*eps^3*y + 18*x*y + 114*eps*x*y + 240*eps^2*x*
                y + 160*eps^3*x*y + 42*x^2*y + 286*eps*x^2*y + 680*eps^2*x^2*
                y + 536*eps^3*x^2*y + 30*x^3*y + 214*eps*x^3*y + 544*eps^2*
                x^3*y + 464*eps^3*x^3*y + 6*x^4*y + 46*eps*x^4*y + 128*eps^2*
                x^4*y + 120*eps^3*x^4*y - 2*eps*y^2 - 12*eps^2*y^2 - 16*eps^3*
                y^2 + 39*x*y^2 + 257*eps*x*y^2 + 576*eps^2*x*y^2 + 432*eps^3*
                x*y^2 + 10*x^2*y^2 + 59*eps*x^2*y^2 + 165*eps^2*x^2*y^2 + 196*
                eps^3*x^2*y^2 - 71*x^3*y^2 - 496*eps*x^3*y^2 - 1153*eps^2*x^3*
                y^2 - 824*eps^3*x^3*y^2 - 42*x^4*y^2 - 312*eps*x^4*y^2 - 810*
                eps^2*x^4*y^2 - 668*eps^3*x^4*y^2 - 16*eps*x^5*y^2 - 80*eps^2*
                x^5*y^2 - 96*eps^3*x^5*y^2 + 20*x*y^3 + 132*eps*x*y^3 + 296*
                eps^2*x*y^3 + 224*eps^3*x*y^3 - 80*x^2*y^3 - 520*eps*x^2*
                y^3 - 1104*eps^2*x^2*y^3 - 760*eps^3*x^2*y^3 - 76*x^3*y^3 - 
               460*eps*x^3*y^3 - 1052*eps^2*x^3*y^3 - 860*eps^3*x^3*y^3 + 8*
                x^4*y^3 + 96*eps*x^4*y^3 + 216*eps^2*x^4*y^3 + 64*eps^3*x^4*
                y^3 + 48*eps^2*x^5*y^3 + 48*eps^3*x^5*y^3 - 32*x^2*y^4 - 224*
                eps*x^2*y^4 - 512*eps^2*x^2*y^4 - 384*eps^3*x^2*y^4 + 32*x^3*
                y^4 + 176*eps*x^3*y^4 + 272*eps^2*x^3*y^4 + 96*eps^3*x^3*
                y^4 + 16*eps*x^4*y^4 + 64*eps^2*x^4*y^4 + 48*eps^3*x^4*y^4))/
             ((1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*(-1 + 4*x*y)^2*
              (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2)), 
          "Expression" -> -(((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*
              (-2*eps - 12*eps^2 - 16*eps^3 - 6*eps*x - 36*eps^2*x - 48*eps^3*
                x - 6*eps*x^2 - 36*eps^2*x^2 - 48*eps^3*x^2 - 2*eps*x^3 - 12*
                eps^2*x^3 - 16*eps^3*x^3 - 4*eps*y - 24*eps^2*y - 32*eps^3*
                y + 18*x*y + 114*eps*x*y + 240*eps^2*x*y + 160*eps^3*x*y + 42*
                x^2*y + 286*eps*x^2*y + 680*eps^2*x^2*y + 536*eps^3*x^2*y + 
               30*x^3*y + 214*eps*x^3*y + 544*eps^2*x^3*y + 464*eps^3*x^3*
                y + 6*x^4*y + 46*eps*x^4*y + 128*eps^2*x^4*y + 120*eps^3*x^4*
                y - 2*eps*y^2 - 12*eps^2*y^2 - 16*eps^3*y^2 + 39*x*y^2 + 257*
                eps*x*y^2 + 576*eps^2*x*y^2 + 432*eps^3*x*y^2 + 10*x^2*y^2 + 
               59*eps*x^2*y^2 + 165*eps^2*x^2*y^2 + 196*eps^3*x^2*y^2 - 71*
                x^3*y^2 - 496*eps*x^3*y^2 - 1153*eps^2*x^3*y^2 - 824*eps^3*
                x^3*y^2 - 42*x^4*y^2 - 312*eps*x^4*y^2 - 810*eps^2*x^4*y^2 - 
               668*eps^3*x^4*y^2 - 16*eps*x^5*y^2 - 80*eps^2*x^5*y^2 - 96*
                eps^3*x^5*y^2 + 20*x*y^3 + 132*eps*x*y^3 + 296*eps^2*x*y^3 + 
               224*eps^3*x*y^3 - 80*x^2*y^3 - 520*eps*x^2*y^3 - 1104*eps^2*
                x^2*y^3 - 760*eps^3*x^2*y^3 - 76*x^3*y^3 - 460*eps*x^3*y^3 - 
               1052*eps^2*x^3*y^3 - 860*eps^3*x^3*y^3 + 8*x^4*y^3 + 96*eps*
                x^4*y^3 + 216*eps^2*x^4*y^3 + 64*eps^3*x^4*y^3 + 48*eps^2*x^5*
                y^3 + 48*eps^3*x^5*y^3 - 32*x^2*y^4 - 224*eps*x^2*y^4 - 512*
                eps^2*x^2*y^4 - 384*eps^3*x^2*y^4 + 32*x^3*y^4 + 176*eps*x^3*
                y^4 + 272*eps^2*x^3*y^4 + 96*eps^3*x^3*y^4 + 16*eps*x^4*y^4 + 
               64*eps^2*x^4*y^4 + 48*eps^3*x^4*y^4))/(eps^2*(1 + 2*eps)*
              (1 + 5*eps)*(2 + 5*eps)*(-1 + 4*x*y)^2*(-1 - 2*eps - x - 
                2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2)), 
          "Kind" -> "DeferredBase", "Component" -> 3, "Mu" -> 2, "Row" -> 1, 
          "Column" -> 2, "GlobalColumn" -> 22, "Status" -> "LeafChannelized", 
          "RootIndices" -> {}, "RadicalBases" -> {}, "GlobalChannels" -> 
           {-(((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(-2*eps - 12*eps^2 - 
                16*eps^3 - 6*eps*x - 36*eps^2*x - 48*eps^3*x - 6*eps*x^2 - 
                36*eps^2*x^2 - 48*eps^3*x^2 - 2*eps*x^3 - 12*eps^2*x^3 - 
                16*eps^3*x^3 - 4*eps*y - 24*eps^2*y - 32*eps^3*y + 18*x*y + 
                114*eps*x*y + 240*eps^2*x*y + 160*eps^3*x*y + 42*x^2*y + 
                286*eps*x^2*y + 680*eps^2*x^2*y + 536*eps^3*x^2*y + 
                30*x^3*y + 214*eps*x^3*y + 544*eps^2*x^3*y + 464*eps^3*x^3*
                 y + 6*x^4*y + 46*eps*x^4*y + 128*eps^2*x^4*y + 120*eps^3*x^4*
                 y - 2*eps*y^2 - 12*eps^2*y^2 - 16*eps^3*y^2 + 39*x*y^2 + 
                257*eps*x*y^2 + 576*eps^2*x*y^2 + 432*eps^3*x*y^2 + 
                10*x^2*y^2 + 59*eps*x^2*y^2 + 165*eps^2*x^2*y^2 + 
                196*eps^3*x^2*y^2 - 71*x^3*y^2 - 496*eps*x^3*y^2 - 
                1153*eps^2*x^3*y^2 - 824*eps^3*x^3*y^2 - 42*x^4*y^2 - 
                312*eps*x^4*y^2 - 810*eps^2*x^4*y^2 - 668*eps^3*x^4*y^2 - 
                16*eps*x^5*y^2 - 80*eps^2*x^5*y^2 - 96*eps^3*x^5*y^2 + 
                20*x*y^3 + 132*eps*x*y^3 + 296*eps^2*x*y^3 + 224*eps^3*x*
                 y^3 - 80*x^2*y^3 - 520*eps*x^2*y^3 - 1104*eps^2*x^2*y^3 - 
                760*eps^3*x^2*y^3 - 76*x^3*y^3 - 460*eps*x^3*y^3 - 
                1052*eps^2*x^3*y^3 - 860*eps^3*x^3*y^3 + 8*x^4*y^3 + 
                96*eps*x^4*y^3 + 216*eps^2*x^4*y^3 + 64*eps^3*x^4*y^3 + 
                48*eps^2*x^5*y^3 + 48*eps^3*x^5*y^3 - 32*x^2*y^4 - 
                224*eps*x^2*y^4 - 512*eps^2*x^2*y^4 - 384*eps^3*x^2*y^4 + 
                32*x^3*y^4 + 176*eps*x^3*y^4 + 272*eps^2*x^3*y^4 + 
                96*eps^3*x^3*y^4 + 16*eps*x^4*y^4 + 64*eps^2*x^4*y^4 + 
                48*eps^3*x^4*y^4))/(eps^2*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*
               (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
                 eps*x*y)^2)), 0, 0, 0, 0, 0, 0, 0}, "RoundTripExact" -> 
           True, "LeafFingerprint" -> 
           "84910c46d6bc299bac457171bf3575e5e0a2bc0b9b3e4ac2abaa3bd1bcde1cd9"\
|>}}, {{<|"SourceColumn" -> 21, "PrefixCoefficient" -> 
           ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps))/eps^3, 
          "SourceTerm" -> (-2*(1 + x + y)*(-eps - 9*eps^2 - 26*eps^3 - 
              24*eps^4 - 3*eps*x - 27*eps^2*x - 78*eps^3*x - 72*eps^4*x - 
              3*eps*x^2 - 27*eps^2*x^2 - 78*eps^3*x^2 - 72*eps^4*x^2 - 
              eps*x^3 - 9*eps^2*x^3 - 26*eps^3*x^3 - 24*eps^4*x^3 - eps*y - 
              7*eps^2*y - 14*eps^3*y - 8*eps^4*y - 6*x*y - 73*eps*x*y - 
              242*eps^2*x*y - 287*eps^3*x*y - 92*eps^4*x*y - 16*x^2*y - 
              197*eps*x^2*y - 693*eps^2*x^2*y - 912*eps^3*x^2*y - 
              368*eps^4*x^2*y - 14*x^3*y - 179*eps*x^3*y - 688*eps^2*x^3*y - 
              1019*eps^3*x^3*y - 492*eps^4*x^3*y - 4*x^4*y - 54*eps*x^4*y - 
              230*eps^2*x^4*y - 380*eps^3*x^4*y - 208*eps^4*x^4*y + 
              2*eps^2*y^2 + 12*eps^3*y^2 + 16*eps^4*y^2 - 14*x*y^2 - 
              185*eps*x*y^2 - 709*eps^2*x*y^2 - 1040*eps^3*x*y^2 - 
              496*eps^4*x*y^2 - 12*x^2*y^2 - 190*eps*x^2*y^2 - 
              911*eps^2*x^2*y^2 - 1585*eps^3*x^2*y^2 - 836*eps^4*x^2*y^2 + 
              18*x^3*y^2 + 191*eps*x^3*y^2 + 526*eps^2*x^3*y^2 + 
              645*eps^3*x^3*y^2 + 452*eps^4*x^3*y^2 + 20*x^4*y^2 + 
              264*eps*x^4*y^2 + 1126*eps^2*x^4*y^2 + 2090*eps^3*x^4*y^2 + 
              1480*eps^4*x^4*y^2 + 4*x^5*y^2 + 68*eps*x^5*y^2 + 
              400*eps^2*x^5*y^2 + 912*eps^3*x^5*y^2 + 704*eps^4*x^5*y^2 - 
              8*x*y^3 - 112*eps*x*y^3 - 468*eps^2*x*y^3 - 760*eps^3*x*y^3 - 
              416*eps^4*x*y^3 + 18*x^2*y^3 + 232*eps*x^2*y^3 + 
              790*eps^2*x^2*y^3 + 1000*eps^3*x^2*y^3 + 432*eps^4*x^2*y^3 + 
              16*x^3*y^3 + 220*eps*x^3*y^3 + 730*eps^2*x^3*y^3 + 
              894*eps^3*x^3*y^3 + 368*eps^4*x^3*y^3 - 14*x^4*y^3 - 
              156*eps*x^4*y^3 - 594*eps^2*x^4*y^3 - 852*eps^3*x^4*y^3 - 
              400*eps^4*x^4*y^3 - 12*x^5*y^3 - 144*eps*x^5*y^3 - 
              540*eps^2*x^5*y^3 - 760*eps^3*x^5*y^3 - 352*eps^4*x^5*y^3 + 
              8*x^2*y^4 + 120*eps*x^2*y^4 + 512*eps^2*x^2*y^4 + 
              800*eps^3*x^2*y^4 + 384*eps^4*x^2*y^4 - 16*x^3*y^4 - 
              224*eps*x^3*y^4 - 944*eps^2*x^3*y^4 - 1568*eps^3*x^3*y^4 - 
              960*eps^4*x^3*y^4 + 8*x^4*y^4 + 104*eps*x^4*y^4 + 
              440*eps^2*x^4*y^4 + 728*eps^3*x^4*y^4 + 384*eps^4*x^4*y^4))/
            ((1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*y*Sqrt[1 - 4*x*y]*
             (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
               eps*x*y)^2), "Expression" -> (-2*(-1 + 2*eps)*(-2 + 3*eps)*
             (-1 + 3*eps)*(1 + x + y)*(-eps - 9*eps^2 - 26*eps^3 - 24*eps^4 - 
              3*eps*x - 27*eps^2*x - 78*eps^3*x - 72*eps^4*x - 3*eps*x^2 - 
              27*eps^2*x^2 - 78*eps^3*x^2 - 72*eps^4*x^2 - eps*x^3 - 
              9*eps^2*x^3 - 26*eps^3*x^3 - 24*eps^4*x^3 - eps*y - 7*eps^2*y - 
              14*eps^3*y - 8*eps^4*y - 6*x*y - 73*eps*x*y - 242*eps^2*x*y - 
              287*eps^3*x*y - 92*eps^4*x*y - 16*x^2*y - 197*eps*x^2*y - 
              693*eps^2*x^2*y - 912*eps^3*x^2*y - 368*eps^4*x^2*y - 
              14*x^3*y - 179*eps*x^3*y - 688*eps^2*x^3*y - 1019*eps^3*x^3*y - 
              492*eps^4*x^3*y - 4*x^4*y - 54*eps*x^4*y - 230*eps^2*x^4*y - 
              380*eps^3*x^4*y - 208*eps^4*x^4*y + 2*eps^2*y^2 + 
              12*eps^3*y^2 + 16*eps^4*y^2 - 14*x*y^2 - 185*eps*x*y^2 - 
              709*eps^2*x*y^2 - 1040*eps^3*x*y^2 - 496*eps^4*x*y^2 - 
              12*x^2*y^2 - 190*eps*x^2*y^2 - 911*eps^2*x^2*y^2 - 
              1585*eps^3*x^2*y^2 - 836*eps^4*x^2*y^2 + 18*x^3*y^2 + 
              191*eps*x^3*y^2 + 526*eps^2*x^3*y^2 + 645*eps^3*x^3*y^2 + 
              452*eps^4*x^3*y^2 + 20*x^4*y^2 + 264*eps*x^4*y^2 + 
              1126*eps^2*x^4*y^2 + 2090*eps^3*x^4*y^2 + 1480*eps^4*x^4*y^2 + 
              4*x^5*y^2 + 68*eps*x^5*y^2 + 400*eps^2*x^5*y^2 + 
              912*eps^3*x^5*y^2 + 704*eps^4*x^5*y^2 - 8*x*y^3 - 
              112*eps*x*y^3 - 468*eps^2*x*y^3 - 760*eps^3*x*y^3 - 
              416*eps^4*x*y^3 + 18*x^2*y^3 + 232*eps*x^2*y^3 + 
              790*eps^2*x^2*y^3 + 1000*eps^3*x^2*y^3 + 432*eps^4*x^2*y^3 + 
              16*x^3*y^3 + 220*eps*x^3*y^3 + 730*eps^2*x^3*y^3 + 
              894*eps^3*x^3*y^3 + 368*eps^4*x^3*y^3 - 14*x^4*y^3 - 
              156*eps*x^4*y^3 - 594*eps^2*x^4*y^3 - 852*eps^3*x^4*y^3 - 
              400*eps^4*x^4*y^3 - 12*x^5*y^3 - 144*eps*x^5*y^3 - 
              540*eps^2*x^5*y^3 - 760*eps^3*x^5*y^3 - 352*eps^4*x^5*y^3 + 
              8*x^2*y^4 + 120*eps*x^2*y^4 + 512*eps^2*x^2*y^4 + 
              800*eps^3*x^2*y^4 + 384*eps^4*x^2*y^4 - 16*x^3*y^4 - 
              224*eps*x^3*y^4 - 944*eps^2*x^3*y^4 - 1568*eps^3*x^3*y^4 - 
              960*eps^4*x^3*y^4 + 8*x^4*y^4 + 104*eps*x^4*y^4 + 
              440*eps^2*x^4*y^4 + 728*eps^3*x^4*y^4 + 384*eps^4*x^4*y^4))/
            (eps^3*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*y*Sqrt[1 - 4*x*y]*
             (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
               eps*x*y)^2), "Kind" -> "DeferredBase", "Component" -> 3, 
          "Mu" -> 2, "Row" -> 2, "Column" -> 1, "GlobalColumn" -> 21, 
          "Status" -> "LeafChannelized", "RootIndices" -> {3}, 
          "RadicalBases" -> {1 - 4*x*y}, "GlobalChannels" -> 
           {0, 0, 0, 0, (2*(2*eps + 5*eps^2 - 38*eps^3 - 65*eps^4 + 228*
                eps^5 + 180*eps^6 - 432*eps^7 + 8*eps*x + 20*eps^2*x - 152*
                eps^3*x - 260*eps^4*x + 912*eps^5*x + 720*eps^6*x - 1728*
                eps^7*x + 12*eps*x^2 + 30*eps^2*x^2 - 228*eps^3*x^2 - 390*
                eps^4*x^2 + 1368*eps^5*x^2 + 1080*eps^6*x^2 - 2592*eps^7*
                x^2 + 8*eps*x^3 + 20*eps^2*x^3 - 152*eps^3*x^3 - 260*eps^4*
                x^3 + 912*eps^5*x^3 + 720*eps^6*x^3 - 1728*eps^7*x^3 + 2*eps*
                x^4 + 5*eps^2*x^4 - 38*eps^3*x^4 - 65*eps^4*x^4 + 228*eps^5*
                x^4 + 180*eps^6*x^4 - 432*eps^7*x^4 + 4*eps*y + 6*eps^2*y - 
               74*eps^3*y - 60*eps^4*y + 376*eps^5*y + 144*eps^6*y - 576*
                eps^7*y + 12*x*y + 76*eps*x*y - 287*eps^2*x*y - 859*eps^3*x*
                y + 1483*eps^4*x*y + 3029*eps^5*x*y - 2178*eps^6*x*y - 3096*
                eps^7*x*y + 44*x^2*y + 260*eps*x^2*y - 1031*eps^2*x^2*y - 
               2977*eps^3*x^2*y + 5523*eps^4*x^2*y + 10247*eps^5*x^2*y - 8622*
                eps^6*x^2*y - 9576*eps^7*x^2*y + 60*x^3*y + 364*eps*x^3*y - 
               1311*eps^2*x^3*y - 4517*eps^3*x^3*y + 7071*eps^4*x^3*y + 16327*
                eps^5*x^3*y - 11358*eps^6*x^3*y - 15912*eps^7*x^3*y + 36*x^4*
                y + 232*eps*x^4*y - 707*eps^2*x^4*y - 3169*eps^3*x^4*y + 3805*
                eps^4*x^4*y + 12149*eps^5*x^4*y - 6282*eps^6*x^4*y - 12600*
                eps^7*x^4*y + 8*x^5*y + 56*eps*x^5*y - 134*eps^2*x^5*y - 844*
                eps^3*x^5*y + 714*eps^4*x^5*y + 3416*eps^5*x^5*y - 1224*eps^6*
                x^5*y - 3744*eps^7*x^5*y + 2*eps*y^2 - 3*eps^2*y^2 - 34*eps^3*
                y^2 + 75*eps^4*y^2 + 68*eps^5*y^2 - 252*eps^6*y^2 + 144*eps^7*
                y^2 + 40*x*y^2 + 256*eps*x*y^2 - 916*eps^2*x*y^2 - 3101*eps^3*
                x*y^2 + 5028*eps^4*x*y^2 + 10987*eps^5*x*y^2 - 8226*eps^6*x*
                y^2 - 10296*eps^7*x*y^2 + 84*x^2*y^2 + 598*eps*x^2*y^2 - 1676*
                eps^2*x^2*y^2 - 8307*eps^3*x^2*y^2 + 9574*eps^4*x^2*y^2 + 
               31765*eps^5*x^2*y^2 - 17766*eps^6*x^2*y^2 - 30600*eps^7*x^2*
                y^2 + 16*x^3*y^2 + 252*eps*x^3*y^2 + 48*eps^2*x^3*y^2 - 5369*
                eps^3*x^3*y^2 + 2052*eps^4*x^3*y^2 + 22191*eps^5*x^3*y^2 - 
               11610*eps^6*x^3*y^2 - 15768*eps^7*x^3*y^2 - 68*x^4*y^2 - 360*
                eps*x^4*y^2 + 1451*eps^2*x^4*y^2 + 3561*eps^3*x^4*y^2 - 4009*
                eps^4*x^4*y^2 - 15577*eps^5*x^4*y^2 - 4158*eps^6*x^4*y^2 + 
               31032*eps^7*x^4*y^2 - 48*x^5*y^2 - 352*eps*x^5*y^2 + 616*eps^2*
                x^5*y^2 + 5302*eps^3*x^5*y^2 - 568*eps^4*x^5*y^2 - 25194*
                eps^5*x^5*y^2 - 4932*eps^6*x^5*y^2 + 39312*eps^7*x^5*y^2 - 8*
                x^6*y^2 - 84*eps*x^6*y^2 - 24*eps^2*x^6*y^2 + 1612*eps^3*x^6*
                y^2 + 872*eps^4*x^6*y^2 - 8272*eps^5*x^6*y^2 - 2592*eps^6*x^6*
                y^2 + 12672*eps^7*x^6*y^2 - 4*eps^2*y^3 + 2*eps^3*y^3 + 70*
                eps^4*y^3 - 80*eps^5*y^3 - 216*eps^6*y^3 + 288*eps^7*y^3 + 44*
                x*y^3 + 308*eps*x*y^3 - 913*eps^2*x*y^3 - 4078*eps^3*x*y^3 + 
               4857*eps^4*x*y^3 + 15558*eps^5*x*y^3 - 7776*eps^6*x*y^3 - 
               16416*eps^7*x*y^3 + 4*x^2*y^3 + 114*eps*x^2*y^3 + 322*eps^2*
                x^2*y^3 - 3113*eps^3*x^2*y^3 - 1202*eps^4*x^2*y^3 + 15053*
                eps^5*x^2*y^3 - 2070*eps^6*x^2*y^3 - 14760*eps^7*x^2*y^3 - 
               104*x^3*y^3 - 610*eps*x^3*y^3 + 2863*eps^2*x^3*y^3 + 5095*
                eps^3*x^3*y^3 - 13165*eps^4*x^3*y^3 - 15449*eps^5*x^3*y^3 + 
               11898*eps^6*x^3*y^3 + 22536*eps^7*x^3*y^3 - 44*x^4*y^3 - 370*
                eps*x^4*y^3 + 1146*eps^2*x^4*y^3 + 3682*eps^3*x^4*y^3 - 3350*
                eps^4*x^4*y^3 - 16024*eps^5*x^4*y^3 - 720*eps^6*x^4*y^3 + 
               26064*eps^7*x^4*y^3 + 44*x^5*y^3 + 178*eps*x^5*y^3 - 954*eps^2*
                x^5*y^3 - 2274*eps^3*x^5*y^3 + 6638*eps^4*x^5*y^3 + 5064*
                eps^5*x^5*y^3 - 11304*eps^6*x^5*y^3 - 864*eps^7*x^5*y^3 + 24*
                x^6*y^3 + 132*eps*x^6*y^3 - 468*eps^2*x^6*y^3 - 1828*eps^3*
                x^6*y^3 + 2812*eps^4*x^6*y^3 + 6224*eps^5*x^6*y^3 - 4176*
                eps^6*x^6*y^3 - 6336*eps^7*x^6*y^3 + 16*x*y^4 + 120*eps*x*
                y^4 - 304*eps^2*x*y^4 - 1684*eps^3*x*y^4 + 1572*eps^4*x*y^4 + 
               6688*eps^5*x*y^4 - 2448*eps^6*x*y^4 - 7488*eps^7*x*y^4 - 52*
                x^2*y^4 - 366*eps*x^2*y^4 + 1270*eps^2*x^2*y^4 + 4290*eps^3*
                x^2*y^4 - 7050*eps^4*x^2*y^4 - 14556*eps^5*x^2*y^4 + 10368*
                eps^6*x^2*y^4 + 14688*eps^7*x^2*y^4 - 16*x^3*y^4 - 128*eps*
                x^3*y^4 + 696*eps^2*x^3*y^4 + 634*eps^3*x^3*y^4 - 3904*eps^4*
                x^3*y^4 - 742*eps^5*x^3*y^4 + 7884*eps^6*x^3*y^4 - 3744*eps^7*
                x^3*y^4 + 44*x^4*y^4 + 266*eps*x^4*y^4 - 798*eps^2*x^4*y^4 - 
               3834*eps^3*x^4*y^4 + 4634*eps^4*x^4*y^4 + 13232*eps^5*x^4*
                y^4 - 4104*eps^6*x^4*y^4 - 17568*eps^7*x^4*y^4 + 8*x^5*y^4 + 
               28*eps*x^5*y^4 - 212*eps^2*x^5*y^4 - 228*eps^3*x^5*y^4 + 1500*
                eps^4*x^5*y^4 - 520*eps^5*x^5*y^4 - 1440*eps^6*x^5*y^4 + 576*
                eps^7*x^5*y^4 - 16*x^2*y^5 - 136*eps*x^2*y^5 + 320*eps^2*x^2*
                y^5 + 1960*eps^3*x^2*y^5 - 2032*eps^4*x^2*y^5 - 7392*eps^5*
                x^2*y^5 + 4032*eps^6*x^2*y^5 + 6912*eps^7*x^2*y^5 + 32*x^3*
                y^5 + 240*eps*x^3*y^5 - 592*eps^2*x^3*y^5 - 3376*eps^3*x^3*
                y^5 + 2992*eps^4*x^3*y^5 + 12864*eps^5*x^3*y^5 - 2304*eps^6*
                x^3*y^5 - 17280*eps^7*x^3*y^5 - 16*x^4*y^5 - 104*eps*x^4*
                y^5 + 256*eps^2*x^4*y^5 + 1600*eps^3*x^4*y^5 - 1312*eps^4*x^4*
                y^5 - 6744*eps^5*x^4*y^5 + 2736*eps^6*x^4*y^5 + 6912*eps^7*
                x^4*y^5))/(eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*y*
              (-1 + 4*x*y)^3*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
                eps*x*y)^2), 0, 0, 0}, "RoundTripExact" -> True, 
          "LeafFingerprint" -> 
           "db75602a8f84f4c8f38a33bc6769229664d1c17bd5cad780c64c7fc0ad183b44"\
|>}, {<|"SourceColumn" -> 22, "PrefixCoefficient" -> 
           ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps))/eps^3, 
          "SourceTerm" -> (eps*(1 + x + y)*(1 + 9*eps + 26*eps^2 + 24*eps^3 + 
              3*x + 27*eps*x + 78*eps^2*x + 72*eps^3*x + 3*x^2 + 27*eps*x^2 + 
              78*eps^2*x^2 + 72*eps^3*x^2 + x^3 + 9*eps*x^3 + 26*eps^2*x^3 + 
              24*eps^3*x^3 + y + 7*eps*y + 14*eps^2*y + 8*eps^3*y + 7*x*y + 
              10*eps*x*y - 57*eps^2*x*y - 100*eps^3*x*y + 13*x^2*y - 
              3*eps*x^2*y - 208*eps^2*x^2*y - 304*eps^3*x^2*y + 9*x^3*y - 
              8*eps*x^3*y - 189*eps^2*x^3*y - 276*eps^3*x^3*y + 2*x^4*y - 
              2*eps*x^4*y - 52*eps^2*x^4*y - 80*eps^3*x^4*y - 2*eps*y^2 - 
              12*eps^2*y^2 - 16*eps^3*y^2 + 27*x*y^2 + 141*eps*x*y^2 + 
              232*eps^2*x*y^2 + 112*eps^3*x*y^2 + 38*x^2*y^2 + 
              287*eps*x^2*y^2 + 661*eps^2*x^2*y^2 + 476*eps^3*x^2*y^2 + 
              5*x^3*y^2 + 196*eps*x^3*y^2 + 707*eps^2*x^3*y^2 + 
              676*eps^3*x^3*y^2 - 6*x^4*y^2 + 52*eps*x^4*y^2 + 
              322*eps^2*x^4*y^2 + 392*eps^3*x^4*y^2 + 32*eps^2*x^5*y^2 + 
              64*eps^3*x^5*y^2 + 20*x*y^3 + 132*eps*x*y^3 + 296*eps^2*x*y^3 + 
              224*eps^3*x*y^3 - 48*x^2*y^3 - 232*eps*x^2*y^3 - 
              336*eps^2*x^2*y^3 - 120*eps^3*x^2*y^3 - 76*x^3*y^3 - 
              412*eps*x^3*y^3 - 716*eps^2*x^3*y^3 - 380*eps^3*x^3*y^3 - 
              24*x^4*y^3 - 160*eps*x^4*y^3 - 312*eps^2*x^4*y^3 - 
              176*eps^3*x^4*y^3 - 16*eps*x^5*y^3 - 48*eps^2*x^5*y^3 - 
              32*eps^3*x^5*y^3 - 32*x^2*y^4 - 224*eps*x^2*y^4 - 
              512*eps^2*x^2*y^4 - 384*eps^3*x^2*y^4 + 32*x^3*y^4 + 
              176*eps*x^3*y^4 + 272*eps^2*x^3*y^4 + 96*eps^3*x^3*y^4 + 
              16*eps*x^4*y^4 + 64*eps^2*x^4*y^4 + 48*eps^3*x^4*y^4))/
            ((1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*y*(-1 + 4*x*y)^2*
             (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 
          "Expression" -> ((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(1 + x + y)*
             (1 + 9*eps + 26*eps^2 + 24*eps^3 + 3*x + 27*eps*x + 78*eps^2*x + 
              72*eps^3*x + 3*x^2 + 27*eps*x^2 + 78*eps^2*x^2 + 72*eps^3*x^2 + 
              x^3 + 9*eps*x^3 + 26*eps^2*x^3 + 24*eps^3*x^3 + y + 7*eps*y + 
              14*eps^2*y + 8*eps^3*y + 7*x*y + 10*eps*x*y - 57*eps^2*x*y - 
              100*eps^3*x*y + 13*x^2*y - 3*eps*x^2*y - 208*eps^2*x^2*y - 
              304*eps^3*x^2*y + 9*x^3*y - 8*eps*x^3*y - 189*eps^2*x^3*y - 
              276*eps^3*x^3*y + 2*x^4*y - 2*eps*x^4*y - 52*eps^2*x^4*y - 
              80*eps^3*x^4*y - 2*eps*y^2 - 12*eps^2*y^2 - 16*eps^3*y^2 + 
              27*x*y^2 + 141*eps*x*y^2 + 232*eps^2*x*y^2 + 112*eps^3*x*y^2 + 
              38*x^2*y^2 + 287*eps*x^2*y^2 + 661*eps^2*x^2*y^2 + 
              476*eps^3*x^2*y^2 + 5*x^3*y^2 + 196*eps*x^3*y^2 + 
              707*eps^2*x^3*y^2 + 676*eps^3*x^3*y^2 - 6*x^4*y^2 + 
              52*eps*x^4*y^2 + 322*eps^2*x^4*y^2 + 392*eps^3*x^4*y^2 + 
              32*eps^2*x^5*y^2 + 64*eps^3*x^5*y^2 + 20*x*y^3 + 
              132*eps*x*y^3 + 296*eps^2*x*y^3 + 224*eps^3*x*y^3 - 
              48*x^2*y^3 - 232*eps*x^2*y^3 - 336*eps^2*x^2*y^3 - 
              120*eps^3*x^2*y^3 - 76*x^3*y^3 - 412*eps*x^3*y^3 - 
              716*eps^2*x^3*y^3 - 380*eps^3*x^3*y^3 - 24*x^4*y^3 - 
              160*eps*x^4*y^3 - 312*eps^2*x^4*y^3 - 176*eps^3*x^4*y^3 - 
              16*eps*x^5*y^3 - 48*eps^2*x^5*y^3 - 32*eps^3*x^5*y^3 - 
              32*x^2*y^4 - 224*eps*x^2*y^4 - 512*eps^2*x^2*y^4 - 
              384*eps^3*x^2*y^4 + 32*x^3*y^4 + 176*eps*x^3*y^4 + 
              272*eps^2*x^3*y^4 + 96*eps^3*x^3*y^4 + 16*eps*x^4*y^4 + 
              64*eps^2*x^4*y^4 + 48*eps^3*x^4*y^4))/(eps^2*(1 + 2*eps)*
             (1 + 5*eps)*(2 + 5*eps)*y*(-1 + 4*x*y)^2*
             (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 
          "Kind" -> "DeferredBase", "Component" -> 3, "Mu" -> 2, "Row" -> 2, 
          "Column" -> 2, "GlobalColumn" -> 22, "Status" -> "LeafChannelized", 
          "RootIndices" -> {}, "RadicalBases" -> {}, "GlobalChannels" -> 
           {((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(1 + x + y)*
              (1 + 9*eps + 26*eps^2 + 24*eps^3 + 3*x + 27*eps*x + 78*eps^2*
                x + 72*eps^3*x + 3*x^2 + 27*eps*x^2 + 78*eps^2*x^2 + 72*eps^3*
                x^2 + x^3 + 9*eps*x^3 + 26*eps^2*x^3 + 24*eps^3*x^3 + y + 7*
                eps*y + 14*eps^2*y + 8*eps^3*y + 7*x*y + 10*eps*x*y - 57*
                eps^2*x*y - 100*eps^3*x*y + 13*x^2*y - 3*eps*x^2*y - 208*
                eps^2*x^2*y - 304*eps^3*x^2*y + 9*x^3*y - 8*eps*x^3*y - 189*
                eps^2*x^3*y - 276*eps^3*x^3*y + 2*x^4*y - 2*eps*x^4*y - 52*
                eps^2*x^4*y - 80*eps^3*x^4*y - 2*eps*y^2 - 12*eps^2*y^2 - 16*
                eps^3*y^2 + 27*x*y^2 + 141*eps*x*y^2 + 232*eps^2*x*y^2 + 112*
                eps^3*x*y^2 + 38*x^2*y^2 + 287*eps*x^2*y^2 + 661*eps^2*x^2*
                y^2 + 476*eps^3*x^2*y^2 + 5*x^3*y^2 + 196*eps*x^3*y^2 + 707*
                eps^2*x^3*y^2 + 676*eps^3*x^3*y^2 - 6*x^4*y^2 + 52*eps*x^4*
                y^2 + 322*eps^2*x^4*y^2 + 392*eps^3*x^4*y^2 + 32*eps^2*x^5*
                y^2 + 64*eps^3*x^5*y^2 + 20*x*y^3 + 132*eps*x*y^3 + 296*eps^2*
                x*y^3 + 224*eps^3*x*y^3 - 48*x^2*y^3 - 232*eps*x^2*y^3 - 336*
                eps^2*x^2*y^3 - 120*eps^3*x^2*y^3 - 76*x^3*y^3 - 412*eps*x^3*
                y^3 - 716*eps^2*x^3*y^3 - 380*eps^3*x^3*y^3 - 24*x^4*y^3 - 
               160*eps*x^4*y^3 - 312*eps^2*x^4*y^3 - 176*eps^3*x^4*y^3 - 16*
                eps*x^5*y^3 - 48*eps^2*x^5*y^3 - 32*eps^3*x^5*y^3 - 32*x^2*
                y^4 - 224*eps*x^2*y^4 - 512*eps^2*x^2*y^4 - 384*eps^3*x^2*
                y^4 + 32*x^3*y^4 + 176*eps*x^3*y^4 + 272*eps^2*x^3*y^4 + 96*
                eps^3*x^3*y^4 + 16*eps*x^4*y^4 + 64*eps^2*x^4*y^4 + 48*eps^3*
                x^4*y^4))/(eps^2*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*y*
              (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
                eps*x*y)^2), 0, 0, 0, 0, 0, 0, 0}, "RoundTripExact" -> True, 
          "LeafFingerprint" -> 
           "ac651d94624db80597eecf5dcbdc6c5049b4042315736e30268a7b90359982b3"\
|>}}}}}, "ChannelStrip" -> 
    {{{{{-2/(1 + x), 0, 0, 0, 0, 0, 0, 0}, {(-2*y)/((1 + x)*(1 + x + y)), 0, 
         0, 0, 0, 0, 0, 0}}, {{(-1 - x)^(-1), 0, 0, 0, 0, 0, 0, 0}, 
        {(-5 - 5*x - y)/((1 + x)*(1 + x + y)), 0, 0, 0, 0, 0, 0, 0}}}, 
      {{{-2/y, 0, 0, 0, 0, 0, 0, 0}, {2/(1 + x + y), 0, 0, 0, 0, 0, 0, 0}}, 
       {{y^(-1), 0, 0, 0, 0, 0, 0, 0}, {(1 + x - 3*y)/(y*(1 + x + y)), 0, 0, 
         0, 0, 0, 0, 0}}}}, {{{{(-2*(1 + 4*x*y))/(x*(-1 + 4*x*y)), 0, 0, 0, 
         0, 0, 0, 0}, {0, 0, 0, 0, -1/2*1/(x*(-1 + 4*x*y)), 0, 0, 0}}, 
       {{0, 0, 0, 0, 4/(x*(-1 + 4*x*y)), 0, 0, 0}, {-x^(-1), 0, 0, 0, 0, 0, 
         0, 0}}}, {{{(-2*(1 + 4*x*y))/(y*(-1 + 4*x*y)), 0, 0, 0, 0, 0, 0, 0}, 
        {0, 0, 0, 0, -1/2*1/(y*(-1 + 4*x*y)), 0, 0, 0}}, 
       {{0, 0, 0, 0, 4/(y*(-1 + 4*x*y)), 0, 0, 0}, {-y^(-1), 0, 0, 0, 0, 0, 
         0, 0}}}}, 
     {{{{0, 0, 0, 0, (2*(8*eps*y + 40*eps^2*y - 226*eps^3*y - 322*eps^4*y + 
            1280*eps^5*y + 648*eps^6*y - 2016*eps^7*y + 16*eps*x*y + 
            80*eps^2*x*y - 452*eps^3*x*y - 644*eps^4*x*y + 2560*eps^5*x*y + 
            1296*eps^6*x*y - 4032*eps^7*x*y + 8*eps*x^2*y + 40*eps^2*x^2*y - 
            226*eps^3*x^2*y - 322*eps^4*x^2*y + 1280*eps^5*x^2*y + 
            648*eps^6*x^2*y - 2016*eps^7*x^2*y - 8*y^2 - 34*eps*y^2 + 
            301*eps^2*y^2 + 54*eps^3*y^2 - 1959*eps^4*y^2 + 1122*eps^5*y^2 + 
            3672*eps^6*y^2 - 3456*eps^7*y^2 - 20*x*y^2 - 174*eps*x*y^2 + 
            334*eps^2*x*y^2 + 2666*eps^3*x*y^2 - 1934*eps^4*x*y^2 - 
            10760*eps^5*x*y^2 + 3672*eps^6*x*y^2 + 11520*eps^7*x*y^2 - 
            16*x^2*y^2 - 214*eps*x^2*y^2 - 91*eps^2*x^2*y^2 + 
            4218*eps^3*x^2*y^2 + 1269*eps^4*x^2*y^2 - 20218*eps^5*x^2*y^2 - 
            2736*eps^6*x^2*y^2 + 27360*eps^7*x^2*y^2 - 4*x^3*y^2 - 
            74*eps*x^3*y^2 - 124*eps^2*x^3*y^2 + 1606*eps^3*x^3*y^2 + 
            1244*eps^4*x^3*y^2 - 8336*eps^5*x^3*y^2 - 2736*eps^6*x^3*y^2 + 
            12384*eps^7*x^3*y^2 - 16*y^3 - 94*eps*y^3 + 485*eps^2*y^3 + 
            816*eps^3*y^3 - 3017*eps^4*y^3 - 1614*eps^5*y^3 + 
            5472*eps^6*y^3 - 864*eps^7*y^3 - 32*x*y^3 - 352*eps*x*y^3 + 
            16*eps^2*x*y^3 + 6700*eps^3*x*y^3 + 1288*eps^4*x*y^3 - 
            32172*eps^5*x*y^3 - 2520*eps^6*x*y^3 + 42336*eps^7*x*y^3 - 
            16*x^2*y^3 - 158*eps*x^2*y^3 - 241*eps^2*x^2*y^3 + 
            3485*eps^3*x^2*y^3 + 3787*eps^4*x^2*y^3 - 20191*eps^5*x^2*y^3 - 
            8658*eps^6*x^2*y^3 + 31896*eps^7*x^2*y^3 - 16*x^3*y^3 + 
            36*eps*x^3*y^3 + 694*eps^2*x^3*y^3 - 1936*eps^3*x^3*y^3 - 
            3642*eps^4*x^3*y^3 + 10456*eps^5*x^3*y^3 + 5328*eps^6*x^3*y^3 - 
            14832*eps^7*x^3*y^3 - 8*x^4*y^3 - 4*eps*x^4*y^3 + 
            336*eps^2*x^4*y^3 - 436*eps^3*x^4*y^3 - 2512*eps^4*x^4*y^3 + 
            3824*eps^5*x^4*y^3 + 5184*eps^6*x^4*y^3 - 8064*eps^7*x^4*y^3 - 
            8*y^4 - 52*eps*y^4 + 224*eps^2*y^4 + 536*eps^3*y^4 - 
            1380*eps^4*y^4 - 1456*eps^5*y^4 + 2448*eps^6*y^4 + 
            576*eps^7*y^4 - 28*x*y^4 - 298*eps*x*y^4 - 174*eps^2*x*y^4 + 
            6182*eps^3*x*y^4 + 2722*eps^4*x*y^4 - 31108*eps^5*x*y^4 - 
            5472*eps^6*x*y^4 + 42912*eps^7*x*y^4 + 8*x^2*y^4 + 
            124*eps*x^2*y^4 - 152*eps^2*x^2*y^4 - 1734*eps^3*x^2*y^4 + 
            304*eps^4*x^2*y^4 + 8238*eps^5*x^2*y^4 - 1116*eps^6*x^2*y^4 - 
            9504*eps^7*x^2*y^4 - 12*x^3*y^4 + 6*eps*x^3*y^4 + 
            670*eps^2*x^3*y^4 - 1174*eps^3*x^3*y^4 - 5658*eps^4*x^3*y^4 + 
            10544*eps^5*x^3*y^4 + 10440*eps^6*x^3*y^4 - 19296*eps^7*x^3*y^4 + 
            8*x^4*y^4 - 4*eps*x^4*y^4 - 324*eps^2*x^4*y^4 + 
            748*eps^3*x^4*y^4 + 1452*eps^4*x^4*y^4 - 4216*eps^5*x^4*y^4 - 
            576*eps^6*x^4*y^4 + 4032*eps^7*x^4*y^4 - 16*x*y^5 - 
            136*eps*x*y^5 + 64*eps^2*x*y^5 + 2600*eps^3*x*y^5 + 
            144*eps^4*x*y^5 - 12256*eps^5*x*y^5 - 576*eps^6*x*y^5 + 
            16128*eps^7*x*y^5 + 32*x^2*y^5 + 240*eps*x^2*y^5 - 
            592*eps^2*x^2*y^5 - 3120*eps^3*x^2*y^5 + 1584*eps^4*x^2*y^5 + 
            14656*eps^5*x^2*y^5 - 1152*eps^6*x^2*y^5 - 19584*eps^7*x^2*y^5 - 
            16*x^3*y^5 - 104*eps*x^3*y^5 + 256*eps^2*x^3*y^5 + 
            1728*eps^3*x^3*y^5 - 2016*eps^4*x^3*y^5 - 5848*eps^5*x^3*y^5 + 
            3312*eps^6*x^3*y^5 + 5760*eps^7*x^3*y^5))/
          (eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*(-1 + 4*x*y)^3*
           (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 0, 0, 
         0}, {((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(6*eps*y + 20*eps^2*y + 
            16*eps^3*y + 12*eps*x*y + 40*eps^2*x*y + 32*eps^3*x*y + 
            6*eps*x^2*y + 20*eps^2*x^2*y + 16*eps^3*x^2*y - 11*y^2 - 
            43*eps*y^2 - 44*eps^2*y^2 - 28*x*y^2 - 172*eps*x*y^2 - 
            300*eps^2*x*y^2 - 136*eps^3*x*y^2 - 23*x^2*y^2 - 
            191*eps*x^2*y^2 - 400*eps^2*x^2*y^2 - 224*eps^3*x^2*y^2 - 
            6*x^3*y^2 - 62*eps*x^3*y^2 - 144*eps^2*x^3*y^2 - 
            88*eps^3*x^3*y^2 - 23*y^3 - 109*eps*y^3 - 152*eps^2*y^3 - 
            48*eps^3*y^3 - 28*x*y^3 - 240*eps*x*y^3 - 532*eps^2*x*y^3 - 
            336*eps^3*x*y^3 + 15*x^2*y^3 + 16*eps*x^2*y^3 - 
            175*eps^2*x^2*y^3 - 272*eps^3*x^2*y^3 + 14*x^3*y^3 + 
            128*eps*x^3*y^3 + 158*eps^2*x^3*y^3 - 52*eps^3*x^3*y^3 + 
            16*eps*x^4*y^3 + 16*eps^2*x^4*y^3 - 32*eps^3*x^4*y^3 - 12*y^4 - 
            60*eps*y^4 - 88*eps^2*y^4 - 32*eps^3*y^4 - 88*eps*x*y^4 - 
            320*eps^2*x*y^4 - 296*eps^3*x*y^4 + 36*x^2*y^4 + 
            172*eps*x^2*y^4 + 132*eps^2*x^2*y^4 - 132*eps^3*x^2*y^4 - 
            8*x^3*y^4 + 40*eps^2*x^3*y^4 - 32*eps^3*x^3*y^4 - 
            16*eps*x^4*y^4 + 16*eps^3*x^4*y^4 - 32*eps*x*y^5 - 
            128*eps^2*x*y^5 - 128*eps^3*x*y^5 + 32*x^2*y^5 + 
            144*eps*x^2*y^5 + 176*eps^2*x^2*y^5 + 32*eps^3*x^2*y^5 + 
            16*eps^2*x^3*y^5 + 16*eps^3*x^3*y^5))/(eps^2*(1 + 2*eps)*
           (1 + 5*eps)*(2 + 5*eps)*(-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - 
             y - 2*eps*y + x*y + eps*x*y)^2), 0, 0, 0, 0, 0, 0, 0}}, 
       {{0, 0, 0, 0, (2*(4 + 32*eps - 53*eps^2 - 500*eps^3 + 157*eps^4 + 
            2244*eps^5 - 36*eps^6 - 3024*eps^7 + 12*x + 96*eps*x - 
            159*eps^2*x - 1500*eps^3*x + 471*eps^4*x + 6732*eps^5*x - 
            108*eps^6*x - 9072*eps^7*x + 12*x^2 + 96*eps*x^2 - 
            159*eps^2*x^2 - 1500*eps^3*x^2 + 471*eps^4*x^2 + 6732*eps^5*x^2 - 
            108*eps^6*x^2 - 9072*eps^7*x^2 + 4*x^3 + 32*eps*x^3 - 
            53*eps^2*x^3 - 500*eps^3*x^3 + 157*eps^4*x^3 + 2244*eps^5*x^3 - 
            36*eps^6*x^3 - 3024*eps^7*x^3 + 20*y + 148*eps*y - 371*eps^2*y - 
            2046*eps^3*y + 1651*eps^4*y + 8478*eps^5*y - 2088*eps^6*y - 
            10368*eps^7*y + 32*x*y + 244*eps*x*y - 676*eps^2*x*y - 
            3239*eps^3*x*y + 3612*eps^4*x*y + 12485*eps^5*x*y - 
            6030*eps^6*x*y - 13032*eps^7*x*y - 12*x^2*y - 80*eps*x^2*y - 
            57*eps^2*x^2*y + 1636*eps^3*x^2*y + 2069*eps^4*x^2*y - 
            9768*eps^5*x^2*y - 6876*eps^6*x^2*y + 18576*eps^7*x^2*y - 
            40*x^3*y - 300*eps*x^3*y + 430*eps^2*x^3*y + 4805*eps^3*x^3*y - 
            94*eps^4*x^3*y - 23079*eps^5*x^3*y - 4014*eps^6*x^3*y + 
            34776*eps^7*x^3*y - 16*x^4*y - 124*eps*x^4*y + 182*eps^2*x^4*y + 
            1976*eps^3*x^4*y - 202*eps^4*x^4*y - 9304*eps^5*x^4*y - 
            1080*eps^6*x^4*y + 13536*eps^7*x^4*y + 36*y^2 + 252*eps*y^2 - 
            807*eps^2*y^2 - 3128*eps^3*y^2 + 4211*eps^4*y^2 + 
            11680*eps^5*y^2 - 6516*eps^6*y^2 - 12240*eps^7*y^2 + 24*x*y^2 + 
            190*eps*x*y^2 - 649*eps^2*x*y^2 - 2401*eps^3*x*y^2 + 
            4853*eps^4*x*y^2 + 7357*eps^5*x*y^2 - 11754*eps^6*x*y^2 - 
            792*eps^7*x*y^2 - 32*x^2*y^2 - 270*eps*x^2*y^2 + 
            469*eps^2*x^2*y^2 + 3702*eps^3*x^2*y^2 + 37*eps^4*x^2*y^2 - 
            17430*eps^5*x^2*y^2 - 7704*eps^6*x^2*y^2 + 31968*eps^7*x^2*y^2 + 
            32*x^3*y^2 + 70*eps*x^3*y^2 - 631*eps^2*x^3*y^2 - 
            657*eps^3*x^3*y^2 + 2973*eps^4*x^3*y^2 + 2475*eps^5*x^3*y^2 - 
            5454*eps^6*x^3*y^2 - 648*eps^7*x^3*y^2 + 76*x^4*y^2 + 
            434*eps*x^4*y^2 - 1302*eps^2*x^4*y^2 - 5908*eps^3*x^4*y^2 + 
            4562*eps^4*x^4*y^2 + 25934*eps^5*x^4*y^2 - 2700*eps^6*x^4*y^2 - 
            36144*eps^7*x^4*y^2 + 24*x^5*y^2 + 156*eps*x^5*y^2 - 
            360*eps^2*x^5*y^2 - 2276*eps^3*x^5*y^2 + 984*eps^4*x^5*y^2 + 
            10352*eps^5*x^5*y^2 + 288*eps^6*x^5*y^2 - 14976*eps^7*x^5*y^2 + 
            28*y^3 + 188*eps*y^3 - 713*eps^2*y^3 - 2118*eps^3*y^3 + 
            4097*eps^4*y^3 + 6902*eps^5*y^3 - 6912*eps^6*y^3 - 
            5472*eps^7*y^3 + 16*x*y^3 + 172*eps*x*y^3 + 58*eps^2*x*y^3 - 
            3780*eps^3*x*y^3 + 190*eps^4*x*y^3 + 17384*eps^5*x*y^3 - 
            4392*eps^6*x*y^3 - 16704*eps^7*x*y^3 + 16*x^2*y^3 + 
            58*eps*x^2*y^3 + 311*eps^2*x^2*y^3 - 2809*eps^3*x^2*y^3 - 
            1269*eps^4*x^2*y^3 + 14139*eps^5*x^2*y^3 - 1134*eps^6*x^2*y^3 - 
            14904*eps^7*x^2*y^3 + 88*x^3*y^3 + 452*eps*x^3*y^3 - 
            1652*eps^2*x^3*y^3 - 6188*eps^3*x^3*y^3 + 8996*eps^4*x^3*y^3 + 
            21592*eps^5*x^3*y^3 - 9864*eps^6*x^3*y^3 - 26928*eps^7*x^3*y^3 + 
            28*x^4*y^3 + 186*eps*x^4*y^3 - 594*eps^2*x^4*y^3 - 
            2442*eps^3*x^4*y^3 + 3638*eps^4*x^4*y^3 + 7080*eps^5*x^4*y^3 - 
            1800*eps^6*x^4*y^3 - 11232*eps^7*x^4*y^3 - 24*x^5*y^3 - 
            132*eps*x^5*y^3 + 468*eps^2*x^5*y^3 + 1700*eps^3*x^5*y^3 - 
            2108*eps^4*x^5*y^3 - 7120*eps^5*x^5*y^3 + 3600*eps^6*x^5*y^3 + 
            7488*eps^7*x^5*y^3 + 8*y^4 + 52*eps*y^4 - 224*eps^2*y^4 - 
            536*eps^3*y^4 + 1380*eps^4*y^4 + 1456*eps^5*y^4 - 
            2448*eps^6*y^4 - 576*eps^7*y^4 + 28*x*y^4 + 266*eps*x*y^4 + 
            126*eps^2*x*y^4 - 5718*eps^3*x*y^4 - 1666*eps^4*x*y^4 + 
            28036*eps^5*x*y^4 + 2016*eps^6*x*y^4 - 36000*eps^7*x*y^4 - 
            8*x^2*y^4 - 92*eps*x^2*y^4 + 520*eps^2*x^2*y^4 - 
            170*eps^3*x^2*y^4 - 1072*eps^4*x^2*y^4 - 238*eps^5*x^2*y^4 + 
            540*eps^6*x^2*y^4 + 1440*eps^7*x^2*y^4 + 12*x^3*y^4 + 
            26*eps*x^3*y^4 - 366*eps^2*x^3*y^4 - 474*eps^3*x^3*y^4 + 
            5194*eps^4*x^3*y^4 - 4960*eps^5*x^3*y^4 - 7848*eps^6*x^3*y^4 + 
            10080*eps^7*x^3*y^4 - 8*x^4*y^4 - 28*eps*x^4*y^4 + 
            212*eps^2*x^4*y^4 - 28*eps^3*x^4*y^4 - 92*eps^4*x^4*y^4 - 
            1272*eps^5*x^4*y^4 + 288*eps^6*x^4*y^4 + 1728*eps^7*x^4*y^4 + 
            16*x*y^5 + 136*eps*x*y^5 - 64*eps^2*x*y^5 - 2600*eps^3*x*y^5 - 
            144*eps^4*x*y^5 + 12256*eps^5*x*y^5 + 576*eps^6*x*y^5 - 
            16128*eps^7*x*y^5 - 32*x^2*y^5 - 240*eps*x^2*y^5 + 
            592*eps^2*x^2*y^5 + 3120*eps^3*x^2*y^5 - 1584*eps^4*x^2*y^5 - 
            14656*eps^5*x^2*y^5 + 1152*eps^6*x^2*y^5 + 19584*eps^7*x^2*y^5 + 
            16*x^3*y^5 + 104*eps*x^3*y^5 - 256*eps^2*x^3*y^5 - 
            1728*eps^3*x^3*y^5 + 2016*eps^4*x^3*y^5 + 5848*eps^5*x^3*y^5 - 
            3312*eps^6*x^3*y^5 - 5760*eps^7*x^3*y^5))/
          (eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*(-1 + 4*x*y)^3*
           (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 0, 0, 
         0}, {((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(1 + x + y)*
           (3 + 19*eps + 38*eps^2 + 24*eps^3 + 6*x + 38*eps*x + 76*eps^2*x + 
            48*eps^3*x + 3*x^2 + 19*eps*x^2 + 38*eps^2*x^2 + 24*eps^3*x^2 + 
            18*y + 104*eps*y + 198*eps^2*y + 120*eps^3*y + 24*x*y + 
            151*eps*x*y + 307*eps^2*x*y + 196*eps^3*x*y + 13*eps*x^2*y + 
            49*eps^2*x^2*y + 44*eps^3*x^2*y - 6*x^3*y - 34*eps*x^3*y - 
            60*eps^2*x^3*y - 32*eps^3*x^3*y + 27*y^2 + 145*eps*y^2 + 
            248*eps^2*y^2 + 128*eps^3*y^2 + 4*eps*x*y^2 - 28*eps^2*x*y^2 - 
            64*eps^3*x*y^2 - 51*x^2*y^2 - 364*eps*x^2*y^2 - 
            845*eps^2*x^2*y^2 - 628*eps^3*x^2*y^2 - 18*x^3*y^2 - 
            220*eps*x^3*y^2 - 634*eps^2*x^3*y^2 - 528*eps^3*x^3*y^2 - 
            32*eps*x^4*y^2 - 128*eps^2*x^4*y^2 - 128*eps^3*x^4*y^2 + 12*y^3 + 
            60*eps*y^3 + 88*eps^2*y^3 + 32*eps^3*y^3 - 16*x*y^3 - 
            56*eps*x*y^3 - 64*eps^2*x*y^3 - 24*eps^3*x*y^3 - 36*x^2*y^3 - 
            204*eps*x^2*y^3 - 356*eps^2*x^2*y^3 - 188*eps^3*x^2*y^3 + 
            24*x^3*y^3 + 128*eps*x^3*y^3 + 216*eps^2*x^3*y^3 + 
            112*eps^3*x^3*y^3 + 32*eps*x^4*y^3 + 96*eps^2*x^4*y^3 + 
            64*eps^3*x^4*y^3 + 32*eps*x*y^4 + 128*eps^2*x*y^4 + 
            128*eps^3*x*y^4 - 32*x^2*y^4 - 144*eps*x^2*y^4 - 
            176*eps^2*x^2*y^4 - 32*eps^3*x^2*y^4 - 16*eps^2*x^3*y^4 - 
            16*eps^3*x^3*y^4))/(eps^2*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*
           (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
             eps*x*y)^2), 0, 0, 0, 0, 0, 0, 0}}}, 
      {{{0, 0, 0, 0, (-2*(-4*eps^2 + 2*eps^3 + 70*eps^4 - 80*eps^5 - 
            216*eps^6 + 288*eps^7 - 12*eps^2*x + 6*eps^3*x + 210*eps^4*x - 
            240*eps^5*x - 648*eps^6*x + 864*eps^7*x - 12*eps^2*x^2 + 
            6*eps^3*x^2 + 210*eps^4*x^2 - 240*eps^5*x^2 - 648*eps^6*x^2 + 
            864*eps^7*x^2 - 4*eps^2*x^3 + 2*eps^3*x^3 + 70*eps^4*x^3 - 
            80*eps^5*x^3 - 216*eps^6*x^3 + 288*eps^7*x^3 - 8*eps^2*y + 
            4*eps^3*y + 140*eps^4*y - 160*eps^5*y - 432*eps^6*y + 
            576*eps^7*y + 16*x*y + 116*eps*x*y - 314*eps^2*x*y - 
            1616*eps^3*x*y + 1722*eps^4*x*y + 6332*eps^5*x*y - 
            3168*eps^6*x*y - 6336*eps^7*x*y + 36*x^2*y + 258*eps*x^2*y - 
            696*eps^2*x^2*y - 3570*eps^3*x^2*y + 3580*eps^4*x^2*y + 
            14248*eps^5*x^2*y - 6048*eps^6*x^2*y - 15264*eps^7*x^2*y + 
            24*x^3*y + 168*eps*x^3*y - 482*eps^2*x^3*y - 2276*eps^3*x^3*y + 
            2554*eps^4*x^3*y + 8860*eps^5*x^3*y - 4320*eps^6*x^3*y - 
            9216*eps^7*x^3*y + 4*x^4*y + 26*eps*x^4*y - 92*eps^2*x^4*y - 
            326*eps^3*x^4*y + 556*eps^4*x^4*y + 1104*eps^5*x^4*y - 
            1008*eps^6*x^4*y - 864*eps^7*x^4*y - 4*eps^2*y^2 + 2*eps^3*y^2 + 
            70*eps^4*y^2 - 80*eps^5*y^2 - 216*eps^6*y^2 + 288*eps^7*y^2 + 
            32*x*y^2 + 238*eps*x*y^2 - 609*eps^2*x*y^2 - 3336*eps^3*x*y^2 + 
            3149*eps^4*x*y^2 + 13278*eps^5*x*y^2 - 5040*eps^6*x*y^2 - 
            14688*eps^7*x*y^2 + 4*x^2*y^2 + 30*eps*x^2*y^2 - 
            96*eps^2*x^2*y^2 - 197*eps^3*x^2*y^2 - 304*eps^4*x^2*y^2 + 
            1925*eps^5*x^2*y^2 + 1026*eps^6*x^2*y^2 - 3528*eps^7*x^2*y^2 - 
            56*x^3*y^2 - 382*eps*x^3*y^2 + 1229*eps^2*x^3*y^2 + 
            5203*eps^3*x^3*y^2 - 8335*eps^4*x^3*y^2 - 17149*eps^5*x^3*y^2 + 
            15930*eps^6*x^3*y^2 + 12456*eps^7*x^3*y^2 - 20*x^4*y^2 - 
            106*eps*x^4*y^2 + 672*eps^2*x^4*y^2 + 962*eps^3*x^4*y^2 - 
            5608*eps^4*x^4*y^2 + 188*eps^5*x^4*y^2 + 12960*eps^6*x^4*y^2 - 
            9360*eps^7*x^4*y^2 + 8*x^5*y^2 + 68*eps*x^5*y^2 - 
            48*eps^2*x^5*y^2 - 1100*eps^3*x^5*y^2 - 656*eps^4*x^5*y^2 + 
            5904*eps^5*x^5*y^2 + 2880*eps^6*x^5*y^2 - 10368*eps^7*x^5*y^2 + 
            16*x*y^3 + 120*eps*x*y^3 - 304*eps^2*x*y^3 - 1684*eps^3*x*y^3 + 
            1572*eps^4*x*y^3 + 6688*eps^5*x*y^3 - 2448*eps^6*x*y^3 - 
            7488*eps^7*x*y^3 - 52*x^2*y^3 - 398*eps*x^2*y^3 + 
            1094*eps^2*x^2*y^3 + 5458*eps^3*x^2*y^3 - 6634*eps^4*x^2*y^3 - 
            19868*eps^5*x^2*y^3 + 11520*eps^6*x^2*y^3 + 19296*eps^7*x^2*y^3 - 
            16*x^3*y^3 - 96*eps*x^3*y^3 + 808*eps^2*x^3*y^3 - 
            246*eps^3*x^3*y^3 - 4096*eps^4*x^3*y^3 + 1754*eps^5*x^3*y^3 + 
            11340*eps^6*x^3*y^3 - 10656*eps^7*x^3*y^3 + 44*x^4*y^3 + 
            298*eps*x^4*y^3 - 622*eps^2*x^4*y^3 - 5034*eps^3*x^4*y^3 + 
            4682*eps^4*x^4*y^3 + 16448*eps^5*x^4*y^3 - 1512*eps^6*x^4*y^3 - 
            24480*eps^7*x^4*y^3 + 8*x^5*y^3 - 4*eps*x^5*y^3 - 
            324*eps^2*x^5*y^3 + 620*eps^3*x^5*y^3 + 2156*eps^4*x^5*y^3 - 
            5112*eps^5*x^5*y^3 - 1152*eps^6*x^5*y^3 + 5184*eps^7*x^5*y^3 - 
            16*x^2*y^4 - 136*eps*x^2*y^4 + 320*eps^2*x^2*y^4 + 
            1960*eps^3*x^2*y^4 - 2032*eps^4*x^2*y^4 - 7392*eps^5*x^2*y^4 + 
            4032*eps^6*x^2*y^4 + 6912*eps^7*x^2*y^4 + 32*x^3*y^4 + 
            240*eps*x^3*y^4 - 592*eps^2*x^3*y^4 - 3376*eps^3*x^3*y^4 + 
            2992*eps^4*x^3*y^4 + 12864*eps^5*x^3*y^4 - 2304*eps^6*x^3*y^4 - 
            17280*eps^7*x^3*y^4 - 16*x^4*y^4 - 104*eps*x^4*y^4 + 
            256*eps^2*x^4*y^4 + 1600*eps^3*x^4*y^4 - 1312*eps^4*x^4*y^4 - 
            6744*eps^5*x^4*y^4 + 2736*eps^6*x^4*y^4 + 6912*eps^7*x^4*y^4))/
          (eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*(-1 + 4*x*y)^3*
           (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 0, 0, 
         0}, {-(((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(-2*eps - 12*eps^2 - 
             16*eps^3 - 6*eps*x - 36*eps^2*x - 48*eps^3*x - 6*eps*x^2 - 
             36*eps^2*x^2 - 48*eps^3*x^2 - 2*eps*x^3 - 12*eps^2*x^3 - 
             16*eps^3*x^3 - 4*eps*y - 24*eps^2*y - 32*eps^3*y + 18*x*y + 
             114*eps*x*y + 240*eps^2*x*y + 160*eps^3*x*y + 42*x^2*y + 
             286*eps*x^2*y + 680*eps^2*x^2*y + 536*eps^3*x^2*y + 30*x^3*y + 
             214*eps*x^3*y + 544*eps^2*x^3*y + 464*eps^3*x^3*y + 6*x^4*y + 
             46*eps*x^4*y + 128*eps^2*x^4*y + 120*eps^3*x^4*y - 2*eps*y^2 - 
             12*eps^2*y^2 - 16*eps^3*y^2 + 39*x*y^2 + 257*eps*x*y^2 + 
             576*eps^2*x*y^2 + 432*eps^3*x*y^2 + 10*x^2*y^2 + 
             59*eps*x^2*y^2 + 165*eps^2*x^2*y^2 + 196*eps^3*x^2*y^2 - 
             71*x^3*y^2 - 496*eps*x^3*y^2 - 1153*eps^2*x^3*y^2 - 
             824*eps^3*x^3*y^2 - 42*x^4*y^2 - 312*eps*x^4*y^2 - 
             810*eps^2*x^4*y^2 - 668*eps^3*x^4*y^2 - 16*eps*x^5*y^2 - 
             80*eps^2*x^5*y^2 - 96*eps^3*x^5*y^2 + 20*x*y^3 + 132*eps*x*y^3 + 
             296*eps^2*x*y^3 + 224*eps^3*x*y^3 - 80*x^2*y^3 - 
             520*eps*x^2*y^3 - 1104*eps^2*x^2*y^3 - 760*eps^3*x^2*y^3 - 
             76*x^3*y^3 - 460*eps*x^3*y^3 - 1052*eps^2*x^3*y^3 - 
             860*eps^3*x^3*y^3 + 8*x^4*y^3 + 96*eps*x^4*y^3 + 
             216*eps^2*x^4*y^3 + 64*eps^3*x^4*y^3 + 48*eps^2*x^5*y^3 + 
             48*eps^3*x^5*y^3 - 32*x^2*y^4 - 224*eps*x^2*y^4 - 
             512*eps^2*x^2*y^4 - 384*eps^3*x^2*y^4 + 32*x^3*y^4 + 
             176*eps*x^3*y^4 + 272*eps^2*x^3*y^4 + 96*eps^3*x^3*y^4 + 
             16*eps*x^4*y^4 + 64*eps^2*x^4*y^4 + 48*eps^3*x^4*y^4))/
           (eps^2*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*(-1 + 4*x*y)^2*
            (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2)), 0, 
         0, 0, 0, 0, 0, 0}}, {{0, 0, 0, 0, 
         (2*(2*eps + 5*eps^2 - 38*eps^3 - 65*eps^4 + 228*eps^5 + 180*eps^6 - 
            432*eps^7 + 8*eps*x + 20*eps^2*x - 152*eps^3*x - 260*eps^4*x + 
            912*eps^5*x + 720*eps^6*x - 1728*eps^7*x + 12*eps*x^2 + 
            30*eps^2*x^2 - 228*eps^3*x^2 - 390*eps^4*x^2 + 1368*eps^5*x^2 + 
            1080*eps^6*x^2 - 2592*eps^7*x^2 + 8*eps*x^3 + 20*eps^2*x^3 - 
            152*eps^3*x^3 - 260*eps^4*x^3 + 912*eps^5*x^3 + 720*eps^6*x^3 - 
            1728*eps^7*x^3 + 2*eps*x^4 + 5*eps^2*x^4 - 38*eps^3*x^4 - 
            65*eps^4*x^4 + 228*eps^5*x^4 + 180*eps^6*x^4 - 432*eps^7*x^4 + 
            4*eps*y + 6*eps^2*y - 74*eps^3*y - 60*eps^4*y + 376*eps^5*y + 
            144*eps^6*y - 576*eps^7*y + 12*x*y + 76*eps*x*y - 287*eps^2*x*y - 
            859*eps^3*x*y + 1483*eps^4*x*y + 3029*eps^5*x*y - 
            2178*eps^6*x*y - 3096*eps^7*x*y + 44*x^2*y + 260*eps*x^2*y - 
            1031*eps^2*x^2*y - 2977*eps^3*x^2*y + 5523*eps^4*x^2*y + 
            10247*eps^5*x^2*y - 8622*eps^6*x^2*y - 9576*eps^7*x^2*y + 
            60*x^3*y + 364*eps*x^3*y - 1311*eps^2*x^3*y - 4517*eps^3*x^3*y + 
            7071*eps^4*x^3*y + 16327*eps^5*x^3*y - 11358*eps^6*x^3*y - 
            15912*eps^7*x^3*y + 36*x^4*y + 232*eps*x^4*y - 707*eps^2*x^4*y - 
            3169*eps^3*x^4*y + 3805*eps^4*x^4*y + 12149*eps^5*x^4*y - 
            6282*eps^6*x^4*y - 12600*eps^7*x^4*y + 8*x^5*y + 56*eps*x^5*y - 
            134*eps^2*x^5*y - 844*eps^3*x^5*y + 714*eps^4*x^5*y + 
            3416*eps^5*x^5*y - 1224*eps^6*x^5*y - 3744*eps^7*x^5*y + 
            2*eps*y^2 - 3*eps^2*y^2 - 34*eps^3*y^2 + 75*eps^4*y^2 + 
            68*eps^5*y^2 - 252*eps^6*y^2 + 144*eps^7*y^2 + 40*x*y^2 + 
            256*eps*x*y^2 - 916*eps^2*x*y^2 - 3101*eps^3*x*y^2 + 
            5028*eps^4*x*y^2 + 10987*eps^5*x*y^2 - 8226*eps^6*x*y^2 - 
            10296*eps^7*x*y^2 + 84*x^2*y^2 + 598*eps*x^2*y^2 - 
            1676*eps^2*x^2*y^2 - 8307*eps^3*x^2*y^2 + 9574*eps^4*x^2*y^2 + 
            31765*eps^5*x^2*y^2 - 17766*eps^6*x^2*y^2 - 30600*eps^7*x^2*y^2 + 
            16*x^3*y^2 + 252*eps*x^3*y^2 + 48*eps^2*x^3*y^2 - 
            5369*eps^3*x^3*y^2 + 2052*eps^4*x^3*y^2 + 22191*eps^5*x^3*y^2 - 
            11610*eps^6*x^3*y^2 - 15768*eps^7*x^3*y^2 - 68*x^4*y^2 - 
            360*eps*x^4*y^2 + 1451*eps^2*x^4*y^2 + 3561*eps^3*x^4*y^2 - 
            4009*eps^4*x^4*y^2 - 15577*eps^5*x^4*y^2 - 4158*eps^6*x^4*y^2 + 
            31032*eps^7*x^4*y^2 - 48*x^5*y^2 - 352*eps*x^5*y^2 + 
            616*eps^2*x^5*y^2 + 5302*eps^3*x^5*y^2 - 568*eps^4*x^5*y^2 - 
            25194*eps^5*x^5*y^2 - 4932*eps^6*x^5*y^2 + 39312*eps^7*x^5*y^2 - 
            8*x^6*y^2 - 84*eps*x^6*y^2 - 24*eps^2*x^6*y^2 + 
            1612*eps^3*x^6*y^2 + 872*eps^4*x^6*y^2 - 8272*eps^5*x^6*y^2 - 
            2592*eps^6*x^6*y^2 + 12672*eps^7*x^6*y^2 - 4*eps^2*y^3 + 
            2*eps^3*y^3 + 70*eps^4*y^3 - 80*eps^5*y^3 - 216*eps^6*y^3 + 
            288*eps^7*y^3 + 44*x*y^3 + 308*eps*x*y^3 - 913*eps^2*x*y^3 - 
            4078*eps^3*x*y^3 + 4857*eps^4*x*y^3 + 15558*eps^5*x*y^3 - 
            7776*eps^6*x*y^3 - 16416*eps^7*x*y^3 + 4*x^2*y^3 + 
            114*eps*x^2*y^3 + 322*eps^2*x^2*y^3 - 3113*eps^3*x^2*y^3 - 
            1202*eps^4*x^2*y^3 + 15053*eps^5*x^2*y^3 - 2070*eps^6*x^2*y^3 - 
            14760*eps^7*x^2*y^3 - 104*x^3*y^3 - 610*eps*x^3*y^3 + 
            2863*eps^2*x^3*y^3 + 5095*eps^3*x^3*y^3 - 13165*eps^4*x^3*y^3 - 
            15449*eps^5*x^3*y^3 + 11898*eps^6*x^3*y^3 + 22536*eps^7*x^3*y^3 - 
            44*x^4*y^3 - 370*eps*x^4*y^3 + 1146*eps^2*x^4*y^3 + 
            3682*eps^3*x^4*y^3 - 3350*eps^4*x^4*y^3 - 16024*eps^5*x^4*y^3 - 
            720*eps^6*x^4*y^3 + 26064*eps^7*x^4*y^3 + 44*x^5*y^3 + 
            178*eps*x^5*y^3 - 954*eps^2*x^5*y^3 - 2274*eps^3*x^5*y^3 + 
            6638*eps^4*x^5*y^3 + 5064*eps^5*x^5*y^3 - 11304*eps^6*x^5*y^3 - 
            864*eps^7*x^5*y^3 + 24*x^6*y^3 + 132*eps*x^6*y^3 - 
            468*eps^2*x^6*y^3 - 1828*eps^3*x^6*y^3 + 2812*eps^4*x^6*y^3 + 
            6224*eps^5*x^6*y^3 - 4176*eps^6*x^6*y^3 - 6336*eps^7*x^6*y^3 + 
            16*x*y^4 + 120*eps*x*y^4 - 304*eps^2*x*y^4 - 1684*eps^3*x*y^4 + 
            1572*eps^4*x*y^4 + 6688*eps^5*x*y^4 - 2448*eps^6*x*y^4 - 
            7488*eps^7*x*y^4 - 52*x^2*y^4 - 366*eps*x^2*y^4 + 
            1270*eps^2*x^2*y^4 + 4290*eps^3*x^2*y^4 - 7050*eps^4*x^2*y^4 - 
            14556*eps^5*x^2*y^4 + 10368*eps^6*x^2*y^4 + 14688*eps^7*x^2*y^4 - 
            16*x^3*y^4 - 128*eps*x^3*y^4 + 696*eps^2*x^3*y^4 + 
            634*eps^3*x^3*y^4 - 3904*eps^4*x^3*y^4 - 742*eps^5*x^3*y^4 + 
            7884*eps^6*x^3*y^4 - 3744*eps^7*x^3*y^4 + 44*x^4*y^4 + 
            266*eps*x^4*y^4 - 798*eps^2*x^4*y^4 - 3834*eps^3*x^4*y^4 + 
            4634*eps^4*x^4*y^4 + 13232*eps^5*x^4*y^4 - 4104*eps^6*x^4*y^4 - 
            17568*eps^7*x^4*y^4 + 8*x^5*y^4 + 28*eps*x^5*y^4 - 
            212*eps^2*x^5*y^4 - 228*eps^3*x^5*y^4 + 1500*eps^4*x^5*y^4 - 
            520*eps^5*x^5*y^4 - 1440*eps^6*x^5*y^4 + 576*eps^7*x^5*y^4 - 
            16*x^2*y^5 - 136*eps*x^2*y^5 + 320*eps^2*x^2*y^5 + 
            1960*eps^3*x^2*y^5 - 2032*eps^4*x^2*y^5 - 7392*eps^5*x^2*y^5 + 
            4032*eps^6*x^2*y^5 + 6912*eps^7*x^2*y^5 + 32*x^3*y^5 + 
            240*eps*x^3*y^5 - 592*eps^2*x^3*y^5 - 3376*eps^3*x^3*y^5 + 
            2992*eps^4*x^3*y^5 + 12864*eps^5*x^3*y^5 - 2304*eps^6*x^3*y^5 - 
            17280*eps^7*x^3*y^5 - 16*x^4*y^5 - 104*eps*x^4*y^5 + 
            256*eps^2*x^4*y^5 + 1600*eps^3*x^4*y^5 - 1312*eps^4*x^4*y^5 - 
            6744*eps^5*x^4*y^5 + 2736*eps^6*x^4*y^5 + 6912*eps^7*x^4*y^5))/
          (eps^3*(2 + 19*eps + 55*eps^2 + 50*eps^3)*y*(-1 + 4*x*y)^3*
           (-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + eps*x*y)^2), 0, 0, 
         0}, {((-1 + 2*eps)*(-2 + 3*eps)*(-1 + 3*eps)*(1 + x + y)*
           (1 + 9*eps + 26*eps^2 + 24*eps^3 + 3*x + 27*eps*x + 78*eps^2*x + 
            72*eps^3*x + 3*x^2 + 27*eps*x^2 + 78*eps^2*x^2 + 72*eps^3*x^2 + 
            x^3 + 9*eps*x^3 + 26*eps^2*x^3 + 24*eps^3*x^3 + y + 7*eps*y + 
            14*eps^2*y + 8*eps^3*y + 7*x*y + 10*eps*x*y - 57*eps^2*x*y - 
            100*eps^3*x*y + 13*x^2*y - 3*eps*x^2*y - 208*eps^2*x^2*y - 
            304*eps^3*x^2*y + 9*x^3*y - 8*eps*x^3*y - 189*eps^2*x^3*y - 
            276*eps^3*x^3*y + 2*x^4*y - 2*eps*x^4*y - 52*eps^2*x^4*y - 
            80*eps^3*x^4*y - 2*eps*y^2 - 12*eps^2*y^2 - 16*eps^3*y^2 + 
            27*x*y^2 + 141*eps*x*y^2 + 232*eps^2*x*y^2 + 112*eps^3*x*y^2 + 
            38*x^2*y^2 + 287*eps*x^2*y^2 + 661*eps^2*x^2*y^2 + 
            476*eps^3*x^2*y^2 + 5*x^3*y^2 + 196*eps*x^3*y^2 + 
            707*eps^2*x^3*y^2 + 676*eps^3*x^3*y^2 - 6*x^4*y^2 + 
            52*eps*x^4*y^2 + 322*eps^2*x^4*y^2 + 392*eps^3*x^4*y^2 + 
            32*eps^2*x^5*y^2 + 64*eps^3*x^5*y^2 + 20*x*y^3 + 132*eps*x*y^3 + 
            296*eps^2*x*y^3 + 224*eps^3*x*y^3 - 48*x^2*y^3 - 
            232*eps*x^2*y^3 - 336*eps^2*x^2*y^3 - 120*eps^3*x^2*y^3 - 
            76*x^3*y^3 - 412*eps*x^3*y^3 - 716*eps^2*x^3*y^3 - 
            380*eps^3*x^3*y^3 - 24*x^4*y^3 - 160*eps*x^4*y^3 - 
            312*eps^2*x^4*y^3 - 176*eps^3*x^4*y^3 - 16*eps*x^5*y^3 - 
            48*eps^2*x^5*y^3 - 32*eps^3*x^5*y^3 - 32*x^2*y^4 - 
            224*eps*x^2*y^4 - 512*eps^2*x^2*y^4 - 384*eps^3*x^2*y^4 + 
            32*x^3*y^4 + 176*eps*x^3*y^4 + 272*eps^2*x^3*y^4 + 
            96*eps^3*x^3*y^4 + 16*eps*x^4*y^4 + 64*eps^2*x^4*y^4 + 
            48*eps^3*x^4*y^4))/(eps^2*(1 + 2*eps)*(1 + 5*eps)*(2 + 5*eps)*y*
           (-1 + 4*x*y)^2*(-1 - 2*eps - x - 2*eps*x - y - 2*eps*y + x*y + 
             eps*x*y)^2), 0, 0, 0, 0, 0, 0, 0}}}}}, "LeafCount" -> 24, 
   "LeafRoundTripExact" -> True, "ChannelCount" -> 8, 
   "ComponentGradeSupport" -> {{0}, {0, 4}, {0, 4}}, 
   "ActiveGrades" -> {0, 4}, "ActiveGradeRank" -> 1, 
   "TermGraphFingerprint" -> 
    "a4d56f70adc2c0deee09644ca25b748cef6b2716294a1faf0903ff239e626ac3", 
   "ChannelEquationFingerprint" -> 
    "80b48992aabda060c6e03a27868a307d40d99148b45ac186bd43309764ca688d", 
   "SupportFingerprint" -> 
    "0a1c9c23ea8e7bec0c9d746a66d32b53a3c3d56deb84c273108738a89a73ddb7"|>|>
