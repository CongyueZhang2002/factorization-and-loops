// Exact multivariate rational-function cancellation over Q.
// Protocol: uncompressed WXF {variable symbols, expression list}.
// Output uses only generated ASCII variable names and exact integer arithmetic.
#include <gmp.h>
#include <flint/fmpz_mpoly_q.h>
#include <flint/fmpz_mpoly.h>
#include <fstream>
#include <iostream>
#include <map>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>
#include <cstdint>
using namespace std;
fmpz_mpoly_ctx_t ctx;
struct Q {
 fmpz_mpoly_q_t x;
 Q(){fmpz_mpoly_q_init(x,ctx);fmpz_mpoly_q_zero(x,ctx);}
 ~Q(){fmpz_mpoly_q_clear(x,ctx);}
 Q(const Q&)=delete;Q&operator=(const Q&)=delete;
};
using R=unique_ptr<Q>;
string bytes;size_t at=0;map<string,size_t> variables;
void need(bool b,const string&m){if(!b)throw runtime_error(m);}
unsigned char token(){need(at<bytes.size(),"Unexpected end of WXF");return bytes[at++];}
uint64_t varint(){uint64_t n=0;int shift=0;unsigned char c;do{c=token();need(shift<63,"WXF length overflow");n|=uint64_t(c&127)<<shift;shift+=7;}while(c&128);return n;}
string symbol(){need(token()=='s',"Expected symbol");auto n=varint();need(n<=bytes.size()-at,"Symbol length");string s=bytes.substr(at,n);at+=n;return s;}
uint64_t list(){need(token()=='f',"Expected list");auto n=varint();need(symbol()=="List","Expected List head");return n;}
string integer(unsigned char t){
 if(t=='I'){auto n=varint();need(n<=bytes.size()-at,"Integer length");string s=bytes.substr(at,n);at+=n;return s;}
 int n=t=='C'?1:t=='j'?2:t=='i'?4:t=='L'?8:0;need(n!=0,"Exact integer required");
 uint64_t value=0;for(int k=0;k<n;k++)value|=uint64_t(token())<<(8*k);
 if(n<8&&(value>>(8*n-1)))value|=(~uint64_t(0))<<(8*n);
 return to_string(int64_t(value));
}
R read(int depth=0){
 need(depth<2048,"Expression nesting limit");
 unsigned char t=token();R out=make_unique<Q>();
 if(t=='s'){at--;string s=symbol();need(variables.count(s),"Undeclared variable "+s);fmpz_mpoly_q_gen(out->x,variables.at(s),ctx);return out;}
 if(t!='f'){string s=integer(t);fmpz_t z;fmpz_init(z);need(fmpz_set_str(z,s.c_str(),10)==0,"Invalid integer");fmpz_mpoly_q_set_fmpz(out->x,z,ctx);fmpz_clear(z);return out;}
 auto n=varint();string h=symbol();
 if(h=="Power"){
  need(n==2,"Power arity");R a=read(depth+1);long k=stol(integer(token()));
  need(k>=-100000&&k<=100000,"Exponent limit");
  if(k<0){need(!fmpz_mpoly_q_is_zero(a->x,ctx),"Zero denominator");fmpz_mpoly_q_inv(a->x,a->x,ctx);k=-k;}
  need(fmpz_mpoly_pow_ui(fmpz_mpoly_q_numref(out->x),fmpz_mpoly_q_numref(a->x),k,ctx),"Numerator power");
  need(fmpz_mpoly_pow_ui(fmpz_mpoly_q_denref(out->x),fmpz_mpoly_q_denref(a->x),k,ctx),"Denominator power");
  return out;
 }
 if(h=="Rational"){
  need(n==2,"Rational arity");R a=read(depth+1),b=read(depth+1);
  need(fmpz_mpoly_q_is_fmpz(a->x,ctx)&&fmpz_mpoly_q_is_fmpz(b->x,ctx),"Rational integers required");
  need(!fmpz_mpoly_q_is_zero(b->x,ctx),"Zero rational denominator");
  fmpz_mpoly_q_div(out->x,a->x,b->x,ctx);return out;
 }
 need(h=="Plus"||h=="Times","Unsupported expression head "+h);
 // Balanced addition avoids repeated copying of a large polynomial.
 vector<R> levels;
 auto combine=[&](R&a,const R&b){if(h=="Plus")fmpz_mpoly_q_add(a->x,a->x,b->x,ctx);else fmpz_mpoly_q_mul(a->x,a->x,b->x,ctx);};
 for(uint64_t j=0;j<n;j++){
  R a=read(depth+1);size_t level=0;
  while(level<levels.size()&&levels[level]){combine(a,levels[level]);levels[level].reset();level++;}
  if(level==levels.size())levels.push_back(move(a));else levels[level]=move(a);
 }
 if(h=="Times")fmpz_mpoly_q_one(out->x,ctx);
 for(auto&a:levels)if(a)combine(out,a);
 return out;
}
string polynomialText(const fmpz_mpoly_t p,vector<const char*>&names){
 if(fmpz_mpoly_is_zero(p,ctx))return "0";
 fmpz_mpoly_t content,primitive;fmpz_mpoly_init(content,ctx);fmpz_mpoly_init(primitive,ctx);
 fmpz_mpoly_term_content(content,p,ctx);
 need(fmpz_mpoly_divides(primitive,p,content,ctx),"Monomial content division");
 char*a=fmpz_mpoly_get_str_pretty(content,names.data(),ctx);
 char*b=fmpz_mpoly_get_str_pretty(primitive,names.data(),ctx);
 string result=fmpz_mpoly_is_one(content,ctx)?string(b):
   fmpz_mpoly_is_one(primitive,ctx)?string(a):"("+string(a)+")*("+string(b)+")";
 flint_free(a);flint_free(b);fmpz_mpoly_clear(content,ctx);fmpz_mpoly_clear(primitive,ctx);
 return result;
}
long valuation(const fmpz_mpoly_t p,slong variable){
 fmpz_mpoly_t m;fmpz_mpoly_init(m,ctx);fmpz_mpoly_term_content(m,p,ctx);
 long result=fmpz_mpoly_degree_si(m,variable,ctx);fmpz_mpoly_clear(m,ctx);return result;
}
R coefficient(const fmpz_mpoly_t p,slong variable,ulong exponent){
 R r=make_unique<Q>();
 fmpz_mpoly_get_coeff_vars_ui(fmpz_mpoly_q_numref(r->x),p,&variable,&exponent,1,ctx);
 return r;
}
vector<R> laurentCoefficients(const R&f,slong variable,long low,long high){
 vector<R> result;for(long k=low;k<=high;k++)result.push_back(make_unique<Q>());
 if(fmpz_mpoly_q_is_zero(f->x,ctx))return result;
 long a=valuation(fmpz_mpoly_q_numref(f->x),variable);
 long b=valuation(fmpz_mpoly_q_denref(f->x),variable),order=a-b;
 if(order>high)return result;
 long upper=high-order;need(upper<=1000,"Rational series order limit");
 vector<R> d,q;for(long j=0;j<=upper;j++)d.push_back(coefficient(fmpz_mpoly_q_denref(f->x),variable,b+j));
 need(!fmpz_mpoly_q_is_zero(d[0]->x,ctx),"Leading denominator coefficient is zero");
 for(long n=0;n<=upper;n++){
  R value=coefficient(fmpz_mpoly_q_numref(f->x),variable,a+n),product=make_unique<Q>();
  for(long j=1;j<=n;j++){
   fmpz_mpoly_q_mul(product->x,d[j]->x,q[n-j]->x,ctx);
   fmpz_mpoly_q_sub(value->x,value->x,product->x,ctx);
  }
  fmpz_mpoly_q_div(value->x,value->x,d[0]->x,ctx);q.push_back(move(value));
 }
 for(long k=low;k<=high;k++)if(k>=order)
  fmpz_mpoly_q_set(result[k-low]->x,q[k-order]->x,ctx);
 return result;
}
int main(int argc,char**argv){
 bool initialized=false;
 try {
  need(argc==3||argc==6,"Expected INPUT.wxf OUTPUT.wl [VARIABLE_INDEX LOW HIGH]");
  bool series=argc==6;long variable=series?stol(argv[3]):0,low=series?stol(argv[4]):0,high=series?stol(argv[5]):0;
  need(!series||(low<=high&&high-low<=1000),"Series range");
  ifstream input(argv[1],ios::binary);need(bool(input),"Input file missing");
  bytes.assign(istreambuf_iterator<char>(input),{});need(bytes.substr(0,2)=="8:","Uncompressed WXF required");at=2;
  need(list()==2,"Expected {variables,expressions}");auto nv=list();need(nv>=1&&nv<=256,"Variable count");
  vector<string> names;for(size_t i=0;i<nv;i++){string s=symbol();need(!variables.count(s),"Duplicate variable");variables[s]=i;names.push_back("x"+to_string(i));}
  need(!series||(variable>=0&&variable<(long)nv),"Series variable index");
  fmpz_mpoly_ctx_init(ctx,nv,ORD_LEX);initialized=true;
  vector<const char*> cNames;for(auto&s:names)cNames.push_back(s.c_str());
  auto count=list();need(count<=100000,"Expression count");
  ofstream output(argv[2]);need(bool(output),"Output file unavailable");output<<"{";
  for(size_t i=0;i<count;i++){
   R value=read();fmpz_mpoly_q_canonicalise(value->x,ctx);
   if(i)output<<",\n";
   if(series){
    auto coefficients=laurentCoefficients(value,variable,low,high);output<<"{";
    for(size_t j=0;j<coefficients.size();j++){
     if(j)output<<",";
     output<<"("<<polynomialText(fmpz_mpoly_q_numref(coefficients[j]->x),cNames)
       <<")/("<<polynomialText(fmpz_mpoly_q_denref(coefficients[j]->x),cNames)<<")";
    }output<<"}";
   }else{
    output<<"("<<polynomialText(fmpz_mpoly_q_numref(value->x),cNames)
      <<")/("<<polynomialText(fmpz_mpoly_q_denref(value->x),cNames)<<")";
   }
   cerr<<(series?"EXPANDED ":"CANCELLED ")<<i+1<<"/"<<count<<endl;
  }
  need(at==bytes.size(),"Trailing WXF data");output<<"}\n";output.close();need(bool(output),"Output write failed");
  fmpz_mpoly_ctx_clear(ctx);cout<<"PASS "<<count<<" exact rational expressions"<<endl;return 0;
 } catch(exception&e){if(initialized)fmpz_mpoly_ctx_clear(ctx);cerr<<e.what()<<endl;return 1;}
}
