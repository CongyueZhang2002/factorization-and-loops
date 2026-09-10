"""Compile the pinned upstream P1 C++ formulas verbatim for independent fixtures."""
from pathlib import Path
import re,subprocess,tempfile,json
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/"External/References/SIDIS/APFEL_Splitting"
def main():
    declarations=[];blocks=[];names=[]
    for filename in ["splittingfunctionsunp_sl.cc","splittingfunctionsunp_tl.cc","splittingfunctionspol_sl.cc"]:
        text=(SOURCE/filename).read_text()
        first=re.search(r"\n  P1\w*::P1",text).start()
        tail=text[first:];last=re.search(r"\n  P2\w*::P2",tail)
        body=tail[:last.start()] if last else tail[:tail.rfind("}")]
        blocks.append(body)
        for m in re.finditer(r"\n  (P1\w*)::\1\(int const& nf\):\s*(\w+)\(",body):
            name,base=m.groups();names.append(name)
            methods=[method for method in ["Regular","Singular","Local"] if f"double {name}::{method}(" in body]
            fields="protected: int _nf; double _a2=0,_a2g=0;" if base=="Expression" else ""
            declarations.append(f"class {name}: public {base} {{ {fields} public: {name}(int const& nf); "+
             " ".join(f"double {method}(double const& x) const override;" for method in methods)+" };")
    prefix=r"""
#include <gsl/gsl_sf_dilog.h>
#include <iostream>
#include <iomanip>
#include <cmath>
using namespace std;
const double CA=3,CF=4.0/3,TR=0.5,Pi2=acos(-1)*acos(-1),zeta2=Pi2/6,zeta3=1.2020569031595942854;
double dilog(double x){return gsl_sf_dilog(x);}
struct Expression {virtual double Regular(double const&) const{return 0;} virtual double Singular(double const&) const{return 0;} virtual double Local(double const&) const{return 0;}};
"""
    maincode='int main(){cout<<setprecision(17);for(int nf:{3,5}){for(double x:{0.17,0.43,0.79}){\n'
    for name in names:
        maincode+=f'{{{name} p(nf); cout<<"{name} "<<nf<<" "<<x<<" "<<p.Regular(x)<<" "<<p.Singular(x)<<" "<<p.Local(x)<<"\\n";}}\n'
    maincode+='}}}\n'
    with tempfile.TemporaryDirectory(prefix="feynfacet-apfel-") as d:
        cpp=Path(d)/"reference.cc";exe=Path(d)/"reference"
        cpp.write_text(prefix+"\n".join(declarations+blocks)+"\n"+maincode)
        subprocess.run(["g++","-O2",str(cpp),"-lgsl","-lgslcblas","-o",str(exe)],check=True)
        output=subprocess.check_output([str(exe)],text=True)
    rows=[]
    for line in output.splitlines():
        name,nf,x,regular,singular,local=line.split()
        rows.append(dict(Class=name,FlavorCount=int(nf),X=float(x),Regular=float(regular),Singular=float(singular),Local=float(local)))
    (ROOT/"Tests/Support/APFELNLOSplittingReferences.json").write_text(json.dumps(rows,indent=2)+"\n")
    print(len(rows),"upstream C++ reference rows")
if __name__=="__main__":main()
