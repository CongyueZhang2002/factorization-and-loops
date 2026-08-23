root = DirectoryName[DirectoryName[ExpandFileName[$InputFileName]]];
Get[FileNameJoin[{root, "Addon", "Load", "LoadFACET.wl"}]];

v = Symbol["Global`v"];
w = Symbol["Global`w"];
eps = Symbol["Global`eps"];

transformation = {{v, 0}, {0, 1}};
inverse = {{1/v, 0}, {0, 1}};
epsilonForm = {
  {{eps/v, 0}, {0, 0}},
  {{0, 0}, {0, -eps/(1 - w)}}
};
system = <|
  "Family" -> "SyntheticCertification",
  "Av" -> {{(1 + eps)/v, 0}, {0, 0}},
  "Aw" -> {{0, 0}, {0, -eps/(1 - w)}}
|>;
record = <|
  "Family" -> "SyntheticCertification",
  "Status" -> "CleanedUp",
  "Frame" -> "SourceVW",
  "Chart" -> "source (v,w)",
  "Variables" -> {v, w},
  "Regulator" -> eps,
  "Ranges" -> {{1}, {2}},
  "TTotal" -> transformation,
  "TTotalInverse" -> inverse,
  "EpsFormX" -> epsilonForm[[1]],
  "EpsFormY" -> epsilonForm[[2]]
|>;

certified = FeynFacet`CertifyFamilyEpsilonForm[record, system];
broken = FeynFacet`CertifyFamilyEpsilonForm[
  ReplacePart[record, {"EpsFormX", 1, 1} -> 2 eps/v], system];

tests = <|
  "CertifiedStatus" -> certified["Status"] === "ExactEpsilonForm",
  "ExactPredicate" -> FeynFacet`ExactFamilyEpsilonFormQ[certified],
  "Inverse" -> certified["TTotalInvertible"],
  "Gauge" -> certified["GaugeIdentity"],
  "Flat" -> certified["Flatness"],
  "DLog" -> certified["Checks", "DLog"],
  "SourceFrameRecognized" ->
    certified["ChartCertificate", "Frame"] === "SourceVariables",
  "BrokenGaugeRejected" ->
    broken["Status"] === "EpsilonFormCertificationFailed" &&
      ! FeynFacet`ExactFamilyEpsilonFormQ[broken]
|>;

Print[InputForm[tests]];
If[! And @@ Values[tests], Exit[1]];
