(* Optional epsilon-form transformations. This extends the existing
   FeynFacet context without resetting the general solver. *)
If[!MemberQ[$Packages,"FeynFacet`"],
 Get[FileNameJoin[{DirectoryName[ExpandFileName[$InputFileName]],"FeynFacet.m"}]]];
Begin["FeynFacet`Private`"];
If[!TrueQ[$feynFacetEpsilonFormLoaded],
 loadFeynFacetModules["EpsilonForm"];
 $feynFacetEpsilonFormLoaded=True;
 $feynFacetAdditionalLoadFiles=DeleteDuplicates[Append[$feynFacetAdditionalLoadFiles,
  FileNameJoin[{$feynFacetDirectory,"EpsilonForm.m"}]]]];
End[];
