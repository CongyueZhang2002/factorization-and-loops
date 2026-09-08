(* Installation paths and explicit module loading. *)
$feynFacetRoot = DirectoryName[$feynFacetDirectory];
$feynFacetAddonRoot = If[StringQ[Global`$FACETAddonRoot], Global`$FACETAddonRoot, $feynFacetRoot];
$feynFacetLoader = If[StringQ[Global`$FACETLoader], Global`$FACETLoader,
 FileNameJoin[{$feynFacetAddonRoot, "Addon", "Load", "LoadFACET.wl"}]];
$feynFacetManifestFile = FileNameJoin[{$feynFacetDirectory, "Kernel", "Modules.wl"}];
$feynFacetModules = Get[$feynFacetManifestFile];
If[! AssociationQ[$feynFacetModules] ||
 ! AllTrue[{"Public","Symbolic","EpsilonForm","Solution","SolutionData"},
   KeyExistsQ[$feynFacetModules,#] && MatchQ[$feynFacetModules[#],{__String}]&],
 Print["FeynFacet: invalid module manifest"]; Abort[]];
$feynFacetModulePaths = Flatten[Values[$feynFacetModules]];
If[!DuplicateFreeQ[$feynFacetModulePaths] ||
 AnyTrue[$feynFacetModulePaths,StringStartsQ[#,"/"] || MemberQ[FileNameSplit[#],".."]&],
 Print["FeynFacet: duplicate or escaping module path"]; Abort[]];
$feynFacetModuleIndex = AssociationMap[
 FileNameJoin[{$feynFacetDirectory,#}]&, $feynFacetModulePaths];
feynFacetModuleFile[path_String] := Lookup[$feynFacetModuleIndex,path,$Failed];
$feynFacetModuleFiles = Values[$feynFacetModuleIndex];
(* Only the requested profiles must be installed. Optional mathematics
   and standalone numerical modules are checked when their entry is used. *)
$feynFacetSourceFiles = Join[
 FileNameJoin[{$feynFacetDirectory,#}]& /@ {"FeynFacet.m","Kernel/Loader.wl","Kernel/Modules.wl","Kernel/Formatting.wl"},
 feynFacetModuleFile /@ Flatten[Lookup[$feynFacetModules,{"Public","Symbolic","SolutionData"}]]];
loadFeynFacetModules[profile_String] := Scan[
 Function[path,With[{file=feynFacetModuleFile[path]},
  If[!StringQ[file] || !FileExistsQ[file],
   Print["FeynFacet: missing module ",path];Abort[]];
  If[Check[Get[file],$Failed,{Get::noopen,Syntax::sntx,Syntax::sntxf,Syntax::sntxi}]===$Failed,Abort[]]]],
 $feynFacetModules[profile]];
$feynFacetEpsilonFormLoaded = False;

(* Explicit optional entry files inherited by worker kernels. *)
$feynFacetAdditionalLoadFiles = {};
