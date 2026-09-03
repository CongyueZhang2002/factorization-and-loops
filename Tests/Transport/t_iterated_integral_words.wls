#!/usr/bin/env wolframscript

root = DirectoryName[ExpandFileName[$InputFileName], 3];
Get[FileNameJoin[{root, "Tests", "TestKit.wl"}]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

u = Symbol["Global`wordU"];
q = u^2 - 1;
curve = u^4 + 2 u + 3;
rootRules = {
  TransportAlgebraicRoot[{-1, 0, 1}, 1] -> -1,
  TransportAlgebraicRoot[{-1, 0, 1}, 2] -> 1
};

gpl = ExpandTransportWordLetters[{{"GPLFactor", q, 1}}, u];
gplKernel = Total[(#[[1]] TransportLetterKernel[First[#[[2]]], u] &) /@
    (gpl["Terms"] /. rootRules)];
FTAssert["one requested polynomial GPL letter splits into marked points and reconstructs its kernel",
  gpl["Status"] === "TransportWordExpanded" &&
  Length[gpl["Terms"]] === 2 &&
  Together[gplKernel - u/q] === 0];

elliptic = ExpandTransportWordLetters[
  {{"E4Factor", q, 0}}, u, curve];
ellipticKernel = Total[(#[[1]]
      TransportLetterKernel[First[#[[2]]], u, curve] &) /@
    (elliptic["Terms"] /. rootRules)];
FTAssert["the elliptic factor expansion uses the normalized E4 pole and reconstructs du/(q Y)",
  elliptic["Status"] === "TransportWordExpanded" &&
  Length[elliptic["Terms"]] === 2 &&
  Together[ellipticKernel - 1/(q Sqrt[curve])] === 0];

definitions = <|{"Composite", 1} -> {
  {2, {"GPLFactor", q, 0}},
  {-1, {"E4Omega0"}}
}|>;
expanded = ExpandTransportWordLetters[
  {{"Composite", 1}, {"GPLPole", 3}}, u, curve, definitions];
FTAssert["composite definitions and marked-point expansion are applied only to the requested word",
  expanded["Status"] === "TransportWordExpanded" &&
  Length[expanded["Terms"]] === 3 &&
  AllTrue[expanded["Terms"], Length[#[[2]]] === 2 &]];

shift = Coefficient[curve, u, 3]/(2 Coefficient[curve, u, 4]);
FTAssert["the quartic cohomology kernels follow the E4 basis convention",
  Together[TransportLetterKernel[{"E4Eta2"}, u, curve] -
      (u^2 + shift u)/Sqrt[curve]] === 0 &&
  TransportLetterKernel[{"E4Omega0"}, u, curve] === 1/Sqrt[curve] &&
  TransportLetterKernel[{"E4OmegaInf"}, u, curve] === u/Sqrt[curve]];

FTAssert["singular factor inputs fail typed before marked-point expansion",
  ExpandTransportWordLetters[{{"GPLFactor", (u - 1)^2, 0}}, u]["Status"] ===
    "TransportLetterNotSupported" &&
  ExpandTransportWordLetters[{{"E4Factor", curve, 0}}, u, curve]["Status"] ===
    "TransportLetterNotSupported"];

FTSummary[];
