import re,glob,os
ROOT="/home/maxzhang/factorization-and-loops"
IDENT=re.compile(r'(?<![A-Za-z0-9$`])([a-z][A-Za-z0-9]*)(?=\s*\[)')
def strip(s):
    out=[];i=0;d=0;n=len(s)
    while i<n:
        if d:
            if s.startswith("(*",i): d+=1;i+=2;continue
            if s.startswith("*)",i): d-=1;i+=2;continue
            i+=1;continue
        if s.startswith("(*",i): d+=1;i+=2;continue
        if s[i]=='"':
            j=i+1
            while j<n and s[j]!='"':
                if s[j]=="\\": j+=1
                j+=1
            out.append('""'); i=j+1;continue
        out.append(s[i]);i+=1
    return "".join(out)
live={f:strip(open(f,errors="replace").read()) for f in glob.glob(ROOT+"/FeynFacet/Private/*/*.wl")}
backup=" ".join(strip(open(f,errors="replace").read()) for f in glob.glob(ROOT+"/FeynFacet/Private_Backup/*.wl"))
livetext=" ".join(live.values())
def defined(name,text): return re.search(r'(^|\n)\s*'+re.escape(name)+r'\s*(\[|=(?!=)|:=|/:)',text) is not None
used=set()
for f,t in live.items(): used|=set(IDENT.findall(t))
cands=sorted(n for n in used if not defined(n,livetext) and defined(n,backup))
print("live calls to symbols now defined only in Private_Backup:",len(cands))
for n in cands:
    files=[os.path.relpath(f,ROOT) for f,t in live.items() if re.search(r'(?<![A-Za-z0-9$`])'+re.escape(n)+r'\s*\[',t)]
    print(f"  {n}: {files}")
