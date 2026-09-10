"""Reproduce exact analytic P1 definitions from the pinned APFEL++ sources.
Only the P1 classes are read. P2 approximations are deliberately excluded.
This is a developer regeneration tool; production reads the retained WL module.
"""
from pathlib import Path
from fractions import Fraction
import re
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/"External/References/SIDIS/APFEL_Splitting"
DEST=ROOT/"FeynFacet/Physics/NLOSplittingFunctions.wl"

def expression(text):
    text=re.sub(r"\b(\d+\.\d*)\b",lambda m: "("+str(Fraction(m[0]))+")",text)
    # A trailing decimal point before whitespace is an exact rational too.
    text=re.sub(r"\b(\d+)\.(?!\d)",r"\1",text)
    text=text.replace("_a2g","softG").replace("_a2","softQ").replace("_nf","nf")
    text=re.sub(r"\b(CA|CF|TR)\b",lambda m:m[0].lower(),text)
    text=re.sub(r"\bPi2\b","Pi^2",text)
    text=re.sub(r"\bzeta([23])\b",r"Zeta[\1]",text)
    text=re.sub(r"\blog\s*\(","Log(",text)
    text=re.sub(r"\bdilog\s*\(","PolyLog(2,",text)
    text=re.sub(r"\bpow\s*\(","Power(",text)
    # Replace only parentheses belonging to named function calls.
    out=[];stack=[]
    for i,c in enumerate(text):
        if c=="(":
            named=bool(re.search(r"(Log|PolyLog|Power)$","".join(out)))
            stack.append(named);out.append("[" if named else "(")
        elif c==")":
            out.append("]" if stack.pop() else ")")
        else:out.append(c)
    if stack:raise ValueError("Unbalanced function expression")
    return "".join(out).strip()

def source_body(text, cls, method):
    m=re.search(r"double "+cls+r"::"+method+r"\(double const& x\) const\s*\{(.*?)\n  \}",text,re.S)
    return m[1] if m else None

def wolfram_body(body,restore):
    declarations=re.findall(r"const double\s+(\w+)\s*=\s*(.*?);",body,re.S)
    answer=re.search(r"return\s+(.*?);",body,re.S)[1]
    # Explicit restoration follows each color/flavor channel, not one global nf rule.
    def convert(t):
        t=expression(t)
        if restore=="closed":t=re.sub(r"\bnf\b","(2 tr nf)",t)
        return t
    names=[n for n,_ in declarations]
    lines=[f" {n}={convert(t)};" for n,t in declarations]
    result=convert(answer)
    if restore=="gluonToQuark":result="2 tr ("+result.replace("nf","(2 tr nf)")+")"
    return "Module[{"+",".join(names)+"},\n"+"\n".join(lines)+"\n "+result+"\n]"

def generate():
    definitions=[]
    groups=[("SpaceLike","U","splittingfunctionsunp_sl.cc","P1"),
            ("TimeLike","U","splittingfunctionsunp_tl.cc","P1T"),
            ("SpaceLike","L","splittingfunctionspol_sl.cc","P1pol")]
    for evolution,spin,file,prefix in groups:
        text=(SOURCE/file).read_text()
        for channel in ["nsp","nsm","ps","qg","gq","gg"]:
            cls=prefix+channel
            if spin=="L" and channel in ("nsp","nsm"):
                opposite="nsm" if channel=="nsp" else "nsp"
                definitions.append(f'splittingNLORegular["{evolution}","{spin}","{channel}",x_,ca_,cf_,tr_,nf_]:=\n splittingNLORegular["SpaceLike","U","{opposite}",x,ca,cf,tr,nf];')
                continue
            body=source_body(text,cls,"Regular")
            if body is None:raise ValueError(cls)
            restore="closed" if spin=="U" else "explicit"
            if evolution=="TimeLike" and channel=="qg":restore="explicit"
            if evolution=="TimeLike" and channel=="gq":restore="gluonToQuark"
            converted=wolfram_body(body,restore)
            soft="-80 cf tr nf/9+(268/9-8 Zeta[2])ca cf"
            softg="-80 ca tr nf/9+(268/9-8 Zeta[2])ca^2"
            converted=converted.replace("softQ","("+soft+")").replace("softG","("+softg+")")
            definitions.append(f'splittingNLORegular["{evolution}","{spin}","{channel}",x_,ca_,cf_,tr_,nf_]:=\n {converted};')
    header="""(* Exact analytic NLO spacelike UU/LL and timelike UU splitting functions.
   Reproduced from APFEL++ commit 27deaec493d95bad0686b3b1c91fbbc910c891ff.
   Universal kernels only; no SIDIS coefficient functions are used.
   Tests/Support/translate_apfel_nlo_splitting.py reproduces these definitions.
   Sources and the GPL-3.0 license are in External/References/SIDIS/APFEL_Splitting.
   The retained base expressions use alpha_s/(4 Pi), converted at the public
   boundary. Singlet multiplicities are removed for individual species.
   Closed quark loops carry TR nf. Pure singlets and g->q carry TR; the
   timelike q->g singlet factor 2 nf is a multiplicity and carries no TR. *)
BeginPackage["FeynFacet§"];
NextToLeadingSplittingKernel::usage="NextToLeadingSplittingKernel[daughter,parent,spin,x,parameters,evolution] returns individual-species P^(1) in a=alpha_s/(2 Pi), with explicit delta/plus/regular coefficients. Evolution is SpaceLike (UU/LL) or TimeLike (UU). Labels always mean physical daughter <- parent; a fragmentation matrix has parent as its row. LL is the conventional helicity MSbar scheme.";
Begin["§Private§"];
"""
    api="""
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
"""
    DEST.write_text((header+"\n\n".join(definitions)+"\n"+api).replace("§",chr(96)))
if __name__=="__main__":generate()
