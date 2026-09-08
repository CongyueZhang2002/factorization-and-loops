// Numerical Frobenius initialization and ordinary Taylor steps for an
// epsilon-regular rational Fuchsian system. The symbolic solution is unchanged.
#define FEYNFACET_NUMERICS_NO_MAIN
#include "finite_integrals.cpp"
#include <flint/acb_poly.h>
#include <flint/gr.h>
#include <omp.h>
#include <memory>

struct PolynomialList {
    std::vector<acb_poly_struct> data;
    explicit PolynomialList(slong n):data(n) {for(auto& p:data) acb_poly_init(&p);}
    ~PolynomialList(){for(auto& p:data) acb_poly_clear(&p);}
    acb_poly_struct* operator[](slong i){return &data[i];}
};
struct RationalEntry {
    slong row=0,col=0;
    std::unique_ptr<PolynomialList> numerator,denominator;
};
// Reuse the actual dyadic midpoint and radius of a preceding native step.
// Converting them to a decimal precision and back at every step unnecessarily
// enlarges the radius. mag_set rounds upwards; no uncertainty is discarded.
static void readBall(arb_t out, std::istream& in) {
    fmpz_t fields[4];
    for (auto& field : fields) fmpz_init(field);
    bool valid = true;
    for (auto& field : fields) {
        std::string token;
        if (!(in >> token) || fmpz_set_str(field, token.c_str(), 10) != 0) {
            valid = false;
            break;
        }
    }
    if (valid && fmpz_sgn(fields[2]) >= 0) {
        arf_set_fmpz_2exp(arb_midref(out), fields[0], fields[1]);
        mag_set_fmpz_2exp_fmpz(arb_radref(out), fields[2], fields[3]);
    } else {
        valid = false;
    }
    for (auto& field : fields) fmpz_clear(field);
    if (!valid) throw std::runtime_error("Invalid native coefficient ball");
}
int main(){
 try{
    std::string magic;std::cin>>magic;
    if(magic!="FFFR1" && magic!="FFFR2") throw std::runtime_error("Unsupported Frobenius protocol");
    const bool nativeSeeds = magic == "FFFR2";
    slong bits=integer(std::cin,32,100000),threads=integer(std::cin,1,8);
    slong order=integer(std::cin,8,256),width=integer(std::cin,0,64);
    slong dim=integer(std::cin,1,10000),count=integer(std::cin,0,100000);
    slong nil=integer(std::cin,1,100),mode=integer(std::cin,0,1);
    slong logs=mode==0?nil*(width+1):1, stride=order+1;
    if((long double)(width+1)*logs*stride*dim>50000000 ||
       (long double)count*(width+1)*stride>30000000)
        throw std::runtime_error("Frobenius allocation too large");
    omp_set_num_threads(threads);
    // FLINT 3.0.x initializes the complex-ball method table lazily, using
    // an unsynchronized shared flag. Taylor shifts on different entries
    // must not race during that first initialization.
    gr_ctx_t context;
    gr_ctx_init_complex_acb(context,bits);
    gr_ctx_clear(context);
    Balls center(1),delta(1),temp(1);
    number(center[0],std::cin,bits);number(delta[0],std::cin,bits);
    std::vector<RationalEntry> entries(count);
    std::vector<std::vector<slong>> rows(dim);
    for(slong i=0;i<count;++i){
        auto& en=entries[i];
        en.row=integer(std::cin,0,dim-1);en.col=integer(std::cin,0,dim-1);
        rows[en.row].push_back(i);
        en.numerator=std::make_unique<PolynomialList>(width+1);
        en.denominator=std::make_unique<PolynomialList>(width+1);
        for(int which=0;which<2;++which){
            slong terms=integer(std::cin,0,100000);
            auto& polys=which?*en.denominator:*en.numerator;
            for(slong j=0;j<terms;++j){
                slong zp=integer(std::cin,0,1000),ep=integer(std::cin,0,1000);
                number(temp[0],std::cin,bits);
                if(ep<=width) acb_poly_set_coeff_acb(polys[ep],zp+(mode==1&&which==1?1:0),temp[0]);
            }
        }
    }
    Balls seeds((width+1)*dim);
    for(slong k=0;k<=width;++k)for(slong i=0;i<dim;++i) {
        if (nativeSeeds) {
            readBall(acb_realref(seeds[k*dim+i]), std::cin);
            readBall(acb_imagref(seeds[k*dim+i]), std::cin);
        } else {
            number(seeds[k*dim+i],std::cin,bits);
        }
    }
    std::string trailing;if(std::cin>>trailing)throw std::runtime_error("Trailing input");
    Balls matrix(count*(width+1)*stride);
    auto b=[&](slong i,slong q,slong m){return matrix[(i*(width+1)+q)*stride+m];};
    int bad=0;
    std::string failure;
    #pragma omp parallel for schedule(dynamic)
    for(slong i=0;i<count;++i){
        auto& en=entries[i];PolynomialList quotient(width+1),work(2);
        Balls scalar(2);
        // Ordinary steps use s in [0,1], z=center+delta*s and d/ds=delta*d/dz.
        if(mode==1)for(slong q=0;q<=width;++q)for(int which=0;which<2;++which){
            auto pol=which?(*en.denominator)[q]:(*en.numerator)[q];
            acb_poly_taylor_shift(pol,pol,center[0],bits);
            acb_one(scalar[0]);
            for(slong m=0;m<acb_poly_length(pol);++m){
                acb_poly_get_coeff_acb(scalar[1],pol,m);
                acb_mul(scalar[1],scalar[1],scalar[0],bits);
                acb_poly_set_coeff_acb(pol,m,scalar[1]);
                acb_mul(scalar[0],scalar[0],delta[0],bits);
            }
            if(which==0)acb_poly_scalar_mul(pol,pol,delta[0],bits);
        }
        acb_poly_get_coeff_acb(scalar[0],(*en.denominator)[0],0);
        if(acb_contains_zero(scalar[0])){
            #pragma omp atomic write
            bad=1;
            #pragma omp critical
            {
                if(failure.empty()){
                    failure=std::string(!acb_is_finite(scalar[0])?"NonfiniteConnectionExpansion":acb_is_zero(scalar[0])?
                        "ConnectionExpansionAtPole":"ConnectionExpansionPrecisionInsufficient")+
                        " row="+std::to_string(en.row+1)+" column="+std::to_string(en.col+1);
                    std::cerr<<failure<<" denominator=";
                    acb_fprintd(stderr,scalar[0],20);std::cerr<<"\n";
                }
            }
            continue;
        }
        for(slong q=0;q<=width;++q){
            acb_poly_set(work[0],(*en.numerator)[q]);
            for(slong j=1;j<=q;++j){
                acb_poly_mullow(work[1],(*en.denominator)[j],quotient[q-j],stride,bits);
                acb_poly_sub(work[0],work[0],work[1],bits);
            }
            acb_poly_div_series(quotient[q],work[0],(*en.denominator)[0],stride,bits);
            for(slong m=0;m<stride;++m){
                acb_poly_get_coeff_acb(b(i,q,m),quotient[q],m);
                if(!acb_is_finite(b(i,q,m))){
                    #pragma omp atomic write
                    bad=1;
                }
            }
        }
    }
    if(bad)throw std::runtime_error(failure.empty()?
        "Joint rational connection expansion is not finite":failure);
    Balls coefficients((width+1)*logs*stride*dim);
    auto p=[&](slong k,slong l,slong n,slong i){
        return coefficients[((k*logs+l)*stride+n)*dim+i];
    };
    for(slong k=0;k<=width;++k)for(slong i=0;i<dim;++i)
        acb_set(p(k,0,0,i),seeds[k*dim+i]);
    if(mode==0){
        // At z^0: d_L P_k = R0 P_k + sum_{q>0} Rq P_{k-q}.
        for(slong k=0;k<=width;++k)for(slong l=0;l<nil*(k+1)-1;++l){
            #pragma omp parallel for schedule(static)
            for(slong i=0;i<dim;++i){
                for(slong ix:rows[i])for(slong q=0;q<=k;++q){
                    if(l>=nil*(k-q+1))continue;
                    acb_addmul(p(k,l+1,0,i),b(ix,q,0),p(k-q,l,0,entries[ix].col),bits);
                }
                acb_div_ui(p(k,l+1,0,i),p(k,l+1,0,i),l+1,bits);
            }
        }
        Balls rhs(logs*dim),v(dim),next(dim),power(dim),sum(dim);
        for(slong n=1;n<=order;++n){
            for(slong k=0;k<=width;++k){
                slong length=nil*(k+1);
                for(slong i=0;i<logs*dim;++i)acb_zero(rhs[i]);
                #pragma omp parallel for schedule(dynamic)
                for(slong i=0;i<dim;++i){
                    Balls dot(1);
                    for(slong ix:rows[i])for(slong q=0;q<=k;++q){
                        slong lim=nil*(k-q+1),j=entries[ix].col;
                        for(slong l=0;l<lim;++l){
                            acb_dot(dot[0],nullptr,0,b(ix,q,1),1,p(k-q,l,n-1,j),-dim,n,bits);
                            acb_add(rhs[l*dim+i],rhs[l*dim+i],dot[0],bits);
                            if(q>0)acb_addmul(rhs[l*dim+i],b(ix,q,0),p(k-q,l,n,j),bits);
                        }
                    }
                }
                for(slong i=0;i<dim;++i)acb_zero(next[i]);
                for(slong l=length-1;l>=0;--l){
                    for(slong i=0;i<dim;++i){
                        acb_mul_ui(v[i],next[i],l+1,bits);
                        acb_sub(v[i],rhs[l*dim+i],v[i],bits);
                        acb_div_ui(power[i],v[i],n,bits);acb_set(sum[i],power[i]);
                    }
                    // (n I-R0)^-1 = sum R0^j/n^(j+1), using exact nilpotency.
                    for(slong it=1;it<nil;++it){
                        #pragma omp parallel for schedule(static)
                        for(slong i=0;i<dim;++i){
                            acb_zero(v[i]);
                            for(slong ix:rows[i])acb_addmul(v[i],b(ix,0,0),power[entries[ix].col],bits);
                            acb_div_ui(v[i],v[i],n,bits);
                        }
                        for(slong i=0;i<dim;++i){acb_set(power[i],v[i]);acb_add(sum[i],sum[i],power[i],bits);}
                    }
                    for(slong i=0;i<dim;++i){acb_set(next[i],sum[i]);acb_set(p(k,l,n,i),sum[i]);}
                }
            }
            std::cerr<<"normal_order="<<n<<"\n";
        }
    }else{
        for(slong n=0;n<order;++n){
            #pragma omp parallel for schedule(dynamic)
            for(slong i=0;i<dim;++i){
                Balls dot(1);
                for(slong k=0;k<=width;++k){
                    for(slong ix:rows[i])for(slong q=0;q<=k;++q){
                        acb_dot(dot[0],nullptr,0,b(ix,q,0),1,p(k-q,0,n,entries[ix].col),-dim,n+1,bits);
                        acb_add(p(k,0,n+1,i),p(k,0,n+1,i),dot[0],bits);
                    }
                    acb_div_ui(p(k,0,n+1,i),p(k,0,n+1,i),n+1,bits);
                }
            }
        }
    }
    Balls logarithm(1),value(1),lower(1),poly(1),point(1);
    if(mode==0){acb_log(logarithm[0],delta[0],bits);acb_set(point[0],delta[0]);}
    else{acb_zero(logarithm[0]);acb_one(point[0]);}
    std::cout<<"FFFO1 "<<dim<<' '<<width<<' '<<order<<"\n";
    for(slong k=0;k<=width;++k)for(slong i=0;i<dim;++i){
        acb_zero(value[0]);acb_zero(lower[0]);
        for(slong n=order;n>=0;--n){
            acb_zero(poly[0]);
            for(slong l=(mode==0?nil*(k+1):1)-1;l>=0;--l){
                acb_mul(poly[0],poly[0],logarithm[0],bits);
                acb_add(poly[0],poly[0],p(k,l,n,i),bits);
            }
            acb_mul(value[0],value[0],point[0],bits);acb_add(value[0],value[0],poly[0],bits);
            acb_mul(lower[0],lower[0],point[0],bits);
            if(n>order-8)acb_add(lower[0],lower[0],poly[0],bits);
        }
        if(!acb_is_finite(value[0]))throw std::runtime_error("Nonfinite Frobenius result");
        writeBall(acb_realref(value[0]));writeBall(acb_imagref(value[0]));
        writeBall(acb_realref(lower[0]));writeBall(acb_imagref(lower[0]));std::cout<<"\n";
    }
    return 0;
 }catch(const std::exception& ex){std::cerr<<ex.what()<<"\n";return 1;}
}
