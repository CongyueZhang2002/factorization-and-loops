(* Registry seeding: canonicalizing a grid against an existing registry
   keeps the seeded family names and numbering.

   Acceptance criteria:
   A. Re-canonicalizing the regenerated NLO pairs seeded from the
      existing UU_08_10_canonical registry yields zero new families and
      the identical family names.
   B. The seeded registry fingerprint extends the seed (SeededFingerprint
      recorded; family count unchanged here).
   C. The seeded artifacts equal the unseeded canonical artifacts after
      dropping Created and ResultDirectory.
   D. A sector-partition mismatch is rejected (ghost-card artifacts
      against the NLO seed). *)

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

sourcePairs = Sort @ FileNames[
  "F*_C*.wl",
  FileNameJoin[{root, "ppHX_NLO", "Results", "UU_08_10_10x10_regen", "Pairs"}]
];
seedDirectory = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_10_canonical"
}];
outputDirectory = FileNameJoin[{
  root, "ppHX_NLO", "Results", "UU_08_10_seedtest"
}];

seeded = FeynFacet`Private`CanonicalizePairArtifacts[
  sourcePairs,
  outputDirectory,
  "SeedRegistry" -> seedDirectory
];

FTTest`FTAssert["A1. seeded canonicalization completes",
  AssociationQ[seeded]];
FTTest`FTAssert["A2. zero new families beyond the seed",
  AssociationQ[seeded] &&
    seeded["Manifest"]["NewFamilyCount"] === 0 &&
    seeded["FamilyCount"] === 11];
FTTest`FTAssert["A3. identical family names as the seed",
  AssociationQ[seeded] &&
    Sort[SymbolName /@ Lookup[seeded["Families"], "Name"]] ===
      Sort[Table["CF" <> ToString[i], {i, 11}]]];

FTTest`FTAssert["B. the seed fingerprint is recorded",
  AssociationQ[seeded] &&
    StringQ[seeded["Manifest"]["SeededFingerprint"]] &&
    seeded["Manifest"]["SeededFamilyCount"] === 11];

referenceFiles = Sort @ FileNames[
  "F*_C*.wl", FileNameJoin[{seedDirectory, "Pairs"}]
];
seededFiles = Sort @ FileNames[
  "F*_C*.wl", FileNameJoin[{outputDirectory, "Pairs"}]
];
dropKeys = {"Created", "ResultDirectory"};
identical = Length[referenceFiles] === Length[seededFiles] &&
  And @@ MapThread[
    SameQ[
      KeyDrop[Get[#1], dropKeys],
      KeyDrop[Get[#2], dropKeys]
    ] &,
    {referenceFiles, seededFiles}
  ];
FTTest`FTAssert["C. seeded artifacts equal the unseeded canonical set",
  identical];

ghostPairs = Take[
  Sort @ FileNames[
    "F*_C*.wl",
    FileNameJoin[{
      root, "ppHX_NNLO_DoubleReal", "Results", "UU_Ghost_08_10_1", "Pairs"
    }]
  ],
  UpTo[2]
];
mismatch = Quiet @ FeynFacet`Private`CanonicalizePairArtifacts[
  ghostPairs,
  FileNameJoin[{root, "ppHX_NLO", "Results", "UU_08_10_seedtest_bad"}],
  "SeedRegistry" -> seedDirectory
];
FTTest`FTAssert["D. sector-partition mismatch is rejected",
  mismatch === $Failed];

FTTest`FTReport[];
