// Batch evaluation of explicit GPLs through GiNaC.
// Input: FFGPL1 decimal_digits count, then weight, complex endpoint,
// and weight complex letters. Each complex number is four integer tokens:
// real numerator/denominator, imaginary numerator/denominator.
#include <ginac/ginac.h>
#include <iostream>
#include <sstream>
#include <string>
#include <map>
#include <stdexcept>
#include <cctype>
using namespace GiNaC;
static std::string integer_token() {
    std::string s;
    if (!(std::cin >> s) || s.empty() || s.size()>1000000)
        throw std::runtime_error("invalid integer token");
    size_t k=(s[0]=='-'||s[0]=='+')?1:0;
    if(k==s.size()) throw std::runtime_error("invalid integer token");
    for(;k<s.size();++k) if(!std::isdigit(static_cast<unsigned char>(s[k])))
        throw std::runtime_error("noninteger token");
    return s;
}
static ex rational_input() {
    numeric p(integer_token().c_str());
    numeric q(integer_token().c_str());
    if(q.is_zero()) throw std::runtime_error("zero denominator");
    return p/q;
}
static ex complex_input() {
    ex re=rational_input(), im=rational_input();
    return re+I*im;
}
int main() {
    try {
        std::string magic; int digits,count,prescription=0;
        if(!(std::cin>>magic>>digits>>count)||(magic!="FFGPL1"&&magic!="FFGPL2")||
           digits<20||digits>10000||count<0||count>1000000)
            throw std::runtime_error("invalid header");
        if(magic=="FFGPL2" && (!(std::cin>>prescription)||prescription < -1||prescription > 1))
            throw std::runtime_error("invalid real-letter prescription");
        Digits=digits;
        std::map<ex,ex,ex_is_less> cache;
        std::cout<<magic<<" "<<count<<"\n";
        for(int i=0;i<count;++i) {
            int weight;
            if(!(std::cin>>weight)||weight<0||weight>100)
                throw std::runtime_error("invalid weight");
            ex endpoint=complex_input(); lst letters;
            for(int j=0;j<weight;++j) letters.append(complex_input());
            ex key=lst{letters,endpoint};
            auto hit=cache.find(key);
            ex value;
            if(hit!=cache.end()) value=hit->second;
            else {
                bool endpoint_zeta=weight>1 && endpoint.is_equal(1) && letters.op(0).is_equal(1);
                for(int j=1;j<weight && endpoint_zeta;++j)
                    endpoint_zeta=letters.op(j).is_zero();
                if(weight==0) value=1;
                else if(endpoint_zeta) value=(pow(-1,weight)*zeta(weight)).evalf();
                else if(prescription==0) value=G(letters,endpoint).evalf();
                else {
                    lst signs;
                    for(int j=0;j<weight;++j) signs.append(numeric(prescription));
                    value=G(letters,signs,endpoint).evalf();
                }
                if(!is_a<numeric>(value))
                    throw std::runtime_error("GPL did not evaluate to a finite number");
                cache.emplace(key,value);
            }
            ex real=value.real_part().evalf(), imag=value.imag_part().evalf();
            if(!is_a<numeric>(real)||!is_a<numeric>(imag))
                throw std::runtime_error("non-numeric component");
            std::cout<<real<<" "<<imag<<"\n";
        }
        std::string extra;
        if(std::cin>>extra) throw std::runtime_error("unexpected input after final GPL");
        return 0;
    } catch(const std::exception& e) {
        std::cerr<<"GPL evaluation failed: "<<e.what()<<"\n";
        return 2;
    }
}
