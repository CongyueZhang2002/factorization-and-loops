
$HistoryLength=0;root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];Get[root<>"/FeynFacet/Algebra/PowerSubstitutions.wl"];
FTTest`FTAssert["even coupling powers including inverse powers",
 And@@Table[FeynFacet`SubstituteScalarPowers[g^(2n),{g^2->a}]===a^n,{n,-3,3}]];
FTTest`FTAssert["unpaired powers retain their scalar base",
 And@@Table[Factor[FeynFacet`SubstituteScalarPowers[g^(2n+1),{g^2->a}]-a^n g]===0,{n,-3,3}]];
FTTest`FTAssert["function-valued coupling does not change numeric coefficients",
 FeynFacet`SubstituteScalarPowers[4c["g"]^4+2c["g"]^2+7,{c["g"]^2->a}]===4a^2+2a+7];
FTTest`FTAssert["declared substitutions retain their sequential meaning",
 FeynFacet`SubstituteScalarPowers[g^4+z,{g^2->a,a->b,z->c}]===b^2+c];
FTTest`FTReport[];
