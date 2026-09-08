// Numerical evaluation of explicit iterated integrals. No DE construction.
// FLINT complex balls propagate arithmetic errors; quadrature truncation is
// controlled by the Wolfram caller. All indices are zero based in this protocol.
#include <flint/acb.h>
#include <flint/arf.h>
#include <flint/fmpq.h>
#include <omp.h>
#include <cmath>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <stdexcept>
#include <limits>

struct Balls {
    acb_ptr p; slong n;
    explicit Balls(slong count): p(_acb_vec_init(count)), n(count) {}
    ~Balls() { _acb_vec_clear(p,n); }
    Balls(const Balls&)=delete;
    acb_ptr operator[](slong i) { return p+i; }
};
struct Instruction {
    char op; std::vector<slong> args;
    std::string re,im,reError,imError;
};
static slong integer(std::istream& in, slong lower, slong upper) {
    slong v;
    if (!(in>>v) || v<lower || v>upper) throw std::runtime_error("Invalid integer in input");
    return v;
}
static void component(arb_t out, const std::string& value, const std::string& error, slong bits) {
    fmpq_t q; fmpq_init(q);
    if (fmpq_set_str(q,value.c_str(),10)!=0 || fmpz_is_zero(fmpq_denref(q))) {
        fmpq_clear(q); throw std::runtime_error("Invalid rational input");
    }
    fmpq_canonicalise(q); arb_set_fmpq(out,q,bits); fmpq_clear(q);
    if (error!="exact") {
        std::size_t end=0; long e=std::stol(error,&end);
        if(end!=error.size()) throw std::runtime_error("Invalid uncertainty");
        arb_add_error_2exp_si(out,e);
    }
}
static void number(acb_t out, std::istream& in, slong bits) {
    std::string re,im,er,ei;
    if(!(in>>re>>er>>im>>ei)) throw std::runtime_error("Truncated numerical input");
    component(acb_realref(out),re,er,bits);
    component(acb_imagref(out),im,ei,bits);
}
static void eval(acb_t out, const Instruction& op, acb_srcptr values, slong stride,
                 slong node, acb_srcptr constants, acb_srcptr point, acb_srcptr path,
                 acb_srcptr integrals, slong bits, slong index) {
    auto arg=[&](slong j) { return values+op.args[j]*stride+node; };
    switch(op.op) {
    case 'C': acb_set(out,constants+index); break;
    case 'X': acb_set(out,point+op.args[0]); break;
    case 'T': acb_set(out,path); break;
    case 'P': acb_const_pi(out,bits); break;
    case 'F': acb_set(out,integrals+op.args[0]*stride+node); break;
    case '+':
        acb_zero(out);
        for (slong j=0;j<(slong)op.args.size();++j) acb_add(out,out,arg(j),bits);
        break;
    case '*':
        acb_one(out);
        for (slong j=0;j<(slong)op.args.size();++j) acb_mul(out,out,arg(j),bits);
        break;
    case '^': acb_pow(out,arg(0),arg(1),bits); break;
    case 'L': acb_log(out,arg(0),bits); break;
    case 'E': acb_exp(out,arg(0),bits); break;
    case 'S': acb_sin(out,arg(0),bits); break;
    case 'O': acb_cos(out,arg(0),bits); break;
    case 'H': acb_atanh(out,arg(0),bits); break;
    case 'A': acb_atan(out,arg(0),bits); break;
    case 'B': acb_asin(out,arg(0),bits); break;
    case 'D': acb_acos(out,arg(0),bits); break;
    case 'U': acb_sinh(out,arg(0),bits); break;
    case 'V': acb_cosh(out,arg(0),bits); break;
    case 'W': acb_tanh(out,arg(0),bits); break;
    case 'J': acb_asinh(out,arg(0),bits); break;
    case 'Z': acb_acosh(out,arg(0),bits); break;
    default: acb_indeterminate(out);
    }
}
static void writeArf(const arf_t x) {
    fmpz_t man, exponent; fmpz_init(man); fmpz_init(exponent);
    arf_get_fmpz_2exp(man,exponent,x);
    char *m=fmpz_get_str(nullptr,10,man), *e=fmpz_get_str(nullptr,10,exponent);
    std::cout<<m<<' '<<e<<' ';
    flint_free(m);flint_free(e);fmpz_clear(man);fmpz_clear(exponent);
}
static void writeBall(const arb_t x) {
    writeArf(arb_midref(x));
    arf_t radius; arf_init(radius); arf_set_mag(radius,arb_radref(x));
    writeArf(radius); arf_clear(radius);
}
#ifndef FEYNFACET_NUMERICS_NO_MAIN
int main() {
    try {
        std::string magic; std::cin>>magic;
        if(magic!="FFNI1") throw std::runtime_error("Unsupported protocol");
        const slong bits=integer(std::cin,32,100000);
        const int threads=integer(std::cin,1,8);
        const slong count=integer(std::cin,2,2048), panels=integer(std::cin,1,100000);
        const slong size=integer(std::cin,0,10000000);
        const slong kernelEnd=integer(std::cin,0,size), nf=integer(std::cin,0,1000000);
        const slong nv=integer(std::cin,0,10000);
        if ((long double)size*count>100000000) throw std::runtime_error("Numerical allocation too large");
        std::vector<Instruction> program(size);
        Balls constants(size);
        for(slong i=0;i<size;++i) {
            auto& op=program[i];
            if(!(std::cin>>op.op)) throw std::runtime_error("Truncated program");
            if(op.op=='C') number(constants[i],std::cin,bits);
            else if(op.op=='X') op.args.push_back(integer(std::cin,0,nv-1));
            else if(op.op=='F') op.args.push_back(integer(std::cin,0,nf-1));
            else if(op.op!='T' && op.op!='P') {
                slong arity=integer(std::cin,1,1000000);
                if(std::string("+*^LESOHABDUVWJZ").find(op.op)==std::string::npos ||
                   (op.op=='^' && arity!=2) ||
                   (std::string("LESOHABDUVWJZ").find(op.op)!=std::string::npos && arity!=1))
                    throw std::runtime_error("Unsupported operation or arity");
                for(slong j=0;j<arity;++j) op.args.push_back(integer(std::cin,0,i-1));
            }
        }
        std::vector<slong> stops(nf), roots(nf);
        slong previous=kernelEnd;
        for(slong i=0;i<nf;++i) {
            stops[i]=integer(std::cin,previous,size);
            roots[i]=integer(std::cin,0,stops[i]-1);
            for(slong j=previous;j<stops[i];++j)
                if(program[j].op=='F' && program[j].args[0]>=i)
                    throw std::runtime_error("Forward integral dependency");
            previous=stops[i];
        }
        if(previous!=size) throw std::runtime_error("Unconsumed instructions");
        for(slong j=0;j<kernelEnd;++j)
            if(program[j].op=='F') throw std::runtime_error("Integral in kernel");
        Balls point(nv), nodes(count), weights(count), q(count*count), breaks(panels+1);
        for(slong i=0;i<nv;++i) number(point[i],std::cin,bits);
        for(slong i=0;i<count;++i) number(nodes[i],std::cin,bits);
        for(slong i=0;i<count;++i) number(weights[i],std::cin,bits);
        for(slong i=0;i<count*count;++i) number(q[i],std::cin,bits);
        for(slong i=0;i<=panels;++i) number(breaks[i],std::cin,bits);
        std::string trailing;
        if(std::cin>>trailing) throw std::runtime_error("Unexpected trailing input");
        // Reuse registers only after the last arithmetic use and any integral
        // sampling that consumes them. This keeps multiprecision memory bounded
        // by simultaneously needed expressions, not total instruction count.
        std::vector<slong> last(size), slots(size), freeSlots;
        std::vector<std::vector<slong>> expires(size);
        for(slong i=0;i<size;++i) last[i]=i;
        for(slong i=0;i<size;++i)
            if(std::string("+*^LESOHABDUVWJZ").find(program[i].op)!=std::string::npos)
                for(auto child:program[i].args) last[child]=std::max(last[child],i);
        for(slong i=0;i<nf;++i) last[roots[i]]=std::max(last[roots[i]],stops[i]-1);
        for(slong i=0;i<size;++i) expires[last[i]].push_back(i);
        slong slotCount=0;
        for(slong i=0;i<size;++i) {
            if(freeSlots.empty()) slots[i]=slotCount++;
            else {slots[i]=freeSlots.back();freeSlots.pop_back();}
            for(auto done:expires[i]) freeSlots.push_back(slots[done]);
        }
        for(auto& op:program)
            if(std::string("+*^LESOHABDUVWJZ").find(op.op)!=std::string::npos)
                for(auto& child:op.args) child=slots[child];
        Balls values(slotCount*count), integrals(nf*count), ends(nf), paths(count);
        Balls temp(3);
        omp_set_dynamic(0);
        for(slong panel=0;panel<panels;++panel) {
            acb_sub(temp[0],breaks[panel+1],breaks[panel],bits);
            for(slong k=0;k<count;++k) {
                acb_mul(paths[k],temp[0],nodes[k],bits);
                acb_add(paths[k],paths[k],breaks[panel],bits);
            }
            int bad=0;
            #pragma omp parallel for num_threads(threads) schedule(static) reduction(|:bad)
            for(slong k=0;k<count;++k) {
                for(slong i=0;i<kernelEnd;++i) {
                    eval(values[slots[i]*count+k],program[i],values.p,count,k,constants.p,point.p,
                         paths[k],integrals.p,bits,i);
                    if(!acb_is_finite(values[slots[i]*count+k])) {bad=1;break;}
                }
            }
            if(bad) throw std::runtime_error("Kernel arithmetic not finite");
            previous=kernelEnd;
            for(slong i=0;i<nf;++i) {
                for(slong j=previous;j<stops[i];++j)
                    for(slong k=0;k<count;++k)
                        eval(values[slots[j]*count+k],program[j],values.p,count,k,constants.p,point.p,
                             paths[k],integrals.p,bits,j);
                const acb_srcptr samples=values[slots[roots[i]]*count];
                for(slong k=0;k<count;++k) {
                    acb_dot(temp[1],nullptr,0,q[k*count],1,samples,1,count,bits);
                    acb_mul(temp[1],temp[1],temp[0],bits);
                    acb_add(integrals[i*count+k],ends[i],temp[1],bits);
                }
                acb_dot(temp[1],nullptr,0,weights.p,1,samples,1,count,bits);
                acb_mul(temp[1],temp[1],temp[0],bits);
                acb_add(ends[i],ends[i],temp[1],bits);
                if(!acb_is_finite(ends[i])) throw std::runtime_error("Integral arithmetic not finite");
                previous=stops[i];
            }
        }
        std::cout<<"FFNO1 "<<nf<<"\n";
        for(slong i=0;i<nf;++i) {
            writeBall(acb_realref(ends[i]));writeBall(acb_imagref(ends[i]));std::cout<<"\n";
        }
        return 0;
    } catch(const std::exception& error) {
        std::cerr<<error.what()<<"\n";return 1;
    }
}

#endif
