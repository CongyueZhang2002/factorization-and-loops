// Sparse ordinary-point Taylor recurrence for a closed epsilon-coefficient DE.
#define FEYNFACET_NUMERICS_NO_MAIN
#include "finite_integrals.cpp"
#include <flint/acb_poly.h>
struct Polys {
    std::vector<acb_poly_struct> p;
    explicit Polys(slong n):p(n) { for(auto& v:p) acb_poly_init(&v); }
    ~Polys() { for(auto& v:p) acb_poly_clear(&v); }
    acb_poly_struct* operator[](slong i) { return &p[i]; }
};
int main() {
    try {
        std::string magic;std::cin>>magic;
        if(magic!="FFNT1") throw std::runtime_error("Unsupported Taylor protocol");
        const slong bits=integer(std::cin,32,100000), degree=integer(std::cin,1,512);
        const slong dimension=integer(std::cin,1,100000), entries=integer(std::cin,0,10000000);
        if((long double)dimension*(degree+1)>10000000 ||
           (long double)entries*degree>50000000) throw std::runtime_error("Taylor allocation too large");
        std::vector<slong> row(entries),col(entries);
        Balls b(entries*degree), values((degree+1)*dimension), temporary(1);
        Polys polynomials(3);
        for(slong i=0;i<entries;++i) {
            row[i]=integer(std::cin,0,dimension-1);col[i]=integer(std::cin,0,dimension-1);
            slong numerator=integer(std::cin,1,100000),denominator=integer(std::cin,1,100000);
            acb_poly_zero(polynomials[0]);acb_poly_zero(polynomials[1]);
            for(slong j=0;j<numerator;++j) {
                number(temporary[0],std::cin,bits);
                acb_poly_set_coeff_acb(polynomials[0],j,temporary[0]);
            }
            for(slong j=0;j<denominator;++j) {
                number(temporary[0],std::cin,bits);
                acb_poly_set_coeff_acb(polynomials[1],j,temporary[0]);
            }
            acb_poly_div_series(polynomials[2],polynomials[0],polynomials[1],degree,bits);
            for(slong j=0;j<degree;++j) {
                acb_poly_get_coeff_acb(b[i*degree+j],polynomials[2],j);
                if(!acb_is_finite(b[i*degree+j])) throw std::runtime_error("Connection singular at Taylor center");
            }
        }
        for(slong j=0;j<dimension;++j) number(values[j],std::cin,bits);
        std::string trailing;if(std::cin>>trailing) throw std::runtime_error("Unexpected trailing input");
        for(slong n=0;n<degree;++n) {
            for(slong i=0;i<entries;++i) {
                acb_dot(temporary[0],nullptr,0,b[i*degree],1,values[n*dimension+col[i]],
                        -dimension,n+1,bits);
                acb_add(values[(n+1)*dimension+row[i]],values[(n+1)*dimension+row[i]],temporary[0],bits);
            }
            for(slong j=0;j<dimension;++j) {
                acb_div_ui(values[(n+1)*dimension+j],values[(n+1)*dimension+j],n+1,bits);
                if(!acb_is_finite(values[(n+1)*dimension+j])) throw std::runtime_error("Taylor arithmetic not finite");
            }
        }
        std::cout<<"FFTO1 "<<dimension<<' '<<degree<<"\n";
        for(slong j=0;j<dimension;++j) for(slong n=0;n<=degree;++n) {
            writeBall(acb_realref(values[n*dimension+j]));
            writeBall(acb_imagref(values[n*dimension+j]));std::cout<<"\n";
        }
        return 0;
    } catch(const std::exception& error) {std::cerr<<error.what()<<"\n";return 1;}
}
