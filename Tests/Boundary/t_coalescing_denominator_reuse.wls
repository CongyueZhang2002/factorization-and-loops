#!/usr/bin/env wolframscript
root=DirectoryName[ExpandFileName[$InputFileName],3];
Get[root<>"/Tests/TestKit.wl"];
Block[{Print},Get[root<>"/Addon/Load/LoadFACET.wl"]];
Clear[crZ,crE,crV];
crOld[m_]:=DeleteDuplicates@Flatten[Map[Function[expression,
 Select[First/@Rest[FactorList[Denominator[expression]]],
  !FreeQ[#,crZ]&&!FreeQ[#,crE]&&TrueQ[(#/.{crZ->0,crE->0})===0]&]],
 DeleteCases[Flatten[m],0]]];
crNew[m_]:=FeynFacet`Private`localNormalizeCoalescingDivisors[m,crZ,crE];
crMatrix=Table[{i/((crZ+crE)(1-crZ)),
 i/(crZ crE(crZ-crE crV)),0,i/(crZ^2+crE^2)}, {i,1,120}];
crBefore=First[AbsoluteTiming[crExpected=crOld[crMatrix]]];
crAfter=First[AbsoluteTiming[crActual=crNew[crMatrix]]];
FTAssert["deduplicated denominators preserve every coalescing divisor in order",
 crActual===crExpected];
FTAssert["pure coordinate/regulator poles and ordinary divisors remain excluded",
 !AnyTrue[crActual,MemberQ[{crZ,crE,1-crZ,crZ-1},#]&] && Length[crActual]===3];
FTAssert["no coalescing divisor is an explicit empty result",
 crNew[{{0,1/crE,1/crZ,1/(1-crZ)}}]==={}];
Print["Repeated denominators: ",Length[DeleteCases[Flatten[crMatrix],0]],
 "; distinct denominators: ",Length[DeleteDuplicates[Denominator/@DeleteCases[Flatten[crMatrix],0]]],
 "; old/new elapsed seconds: ",{crBefore,crAfter}];
FTReport[];
