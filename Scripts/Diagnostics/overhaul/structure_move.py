#!/usr/bin/env python3
"""Goal 3: generate (and optionally apply) the Private/ layer moves.
Usage: structure_move.py <worktree> [--apply]
Prints the git mv commands, the LoadOrder.wl manifest, and the test-path
rewrites; with --apply performs them."""
import os,sys,re,subprocess
W=sys.argv[1]; apply="--apply" in sys.argv
layers=[
 ("Core",["Core.wl","MultiquadraticAlgebra.wl","RationalMaterialization.wl"]),
 ("Process",["Process.wl","Topologies.wl","CanonicalFamilies.wl","DimensionalShift.wl","Collinear.wl"]),
 ("Reduction",["Reduction.wl","StreamingKira.wl","MasterIntegralAmFlow.wl","Simplification.wl","Assembly.wl","CoefficientStore.wl","Reconstruction.wl"]),
 ("Infrastructure",["TaskBroker.wl"]),
 ("Geometry",["TransportCharts.wl"]),
 ("EpsForm",["CanonicalBlocks.wl","EpsFormStrip.wl","BlockEquationDeferred.wl","FiniteFieldEpsForm.wl","FiniteFieldStripSolve.wl","EpsFormStripObstruction.wl","FamilyRegulatorFactor.wl","FamilyRowGauge.wl","FamilyRowGaugeResume.wl","FamilyCertificateModular.wl","MultiquadraticStripSolve.wl","MultiquadraticInstallation.wl","FiniteFieldGaugePullBack.wl","LibraEpsForm.wl","FamilyEpsForm.wl","DiagonalBlockEpsForm.wl"]),
 ("Transport",["MasterTransport.wl","BlockwiseTransport.wl","CanonicalWordTransport.wl","PathTransportException.wl","PathTransportNative.wl","ObservableTransport.wl","ObservableTransportFiniteField.wl"]),
]
priv=os.path.join(W,"FeynFacet","Private")
flat=set(f for f in os.listdir(priv) if f.endswith(".wl"))
present=set(flat)
for layer,fs in layers:
    d=os.path.join(priv,layer)
    if os.path.isdir(d): present|=set(f for f in os.listdir(d) if f.endswith(".wl"))
planned=set(f for _,fs in layers for f in fs)
print("# unplanned files:",sorted(present-planned)); print("# planned but absent:",sorted(planned-present))
cmds=[]
for layer,fs in layers:
    for f in fs:
        if f in flat: cmds.append(f"git mv FeynFacet/Private/{f} FeynFacet/Private/{layer}/{f}")
print("\n".join(cmds))
if apply:
    for layer,_ in layers: os.makedirs(os.path.join(priv,layer),exist_ok=True)
    for c in cmds: subprocess.run(c.split(),cwd=W,check=True)
    # test path rewrites
    for dp,_,fs in os.walk(os.path.join(W,"Tests")):
        for fn in fs:
            if not fn.endswith((".wls",".wl")): continue
            p=os.path.join(dp,fn); t=open(p).read(); u=t
            for layer,files in layers:
                for f in files:
                    u=re.sub(r'"Private",(\s*)"%s"'%re.escape(f), lambda m: '"Private", "%s",%s"%s"'%(layer,m.group(1),f), u)
            if u!=t: open(p,"w").write(u); print("rewrote",os.path.relpath(p,W))
    for dp,_,fs in os.walk(os.path.join(W,"Scripts")):
        for fn in fs:
            if not fn.endswith((".wls",".wl",".sh")): continue
            p=os.path.join(dp,fn); t=open(p,errors="replace").read(); u=t
            for layer,files in layers:
                for f in files:
                    u=re.sub(r'"Private",(\s*)"%s"'%re.escape(f), lambda m: '"Private", "%s",%s"%s"'%(layer,m.group(1),f), u)
                    u=u.replace('FeynFacet/Private/%s'%f,'FeynFacet/Private/%s/%s'%(layer,f))
            if u!=t: open(p,"w").write(u); print("rewrote",os.path.relpath(p,W))
print("# manifest FeynFacet/Private/LoadOrder.wl:")
print("{")
for layer,fs in layers:
    print(f'  "{layer}" -> {{' + ", ".join('"%s"'%f for f in fs if f in present) + "},")
print("}")
