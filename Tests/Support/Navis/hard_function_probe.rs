// Validation wrapper. The two matrix-element modules are unmodified upstream files.
#![allow(dead_code)]
#[path = "__POL_SOURCE__"]
mod polarized;
#[path = "__UU_SOURCE__"]
mod unpolarized;

// Plain flavor containers satisfy the unused STRU interface without loading PDFs.
mod pdfs {
    #[derive(Default, Clone, Copy)]
    pub struct PartonDensities {
        pub up:f64, pub upb:f64, pub down:f64, pub downb:f64, pub strange:f64,
        pub charm:f64, pub bottom:f64, pub gluon:f64, pub photon:f64,
    }
    #[derive(Default, Clone, Copy)]
    pub struct FragmentationFunctions {
        pub u:f64, pub ub:f64, pub d:f64, pub db:f64, pub s:f64, pub sb:f64,
        pub c:f64, pub cb:f64, pub g:f64, pub photon:f64,
    }
}
use std::io::{self, BufRead};
fn main() {
    for line in io::stdin().lock().lines() {
        let line=line.expect("stdin");
        if line.trim().is_empty() { continue; }
        let a:Vec<f64>=line.split_whitespace().map(|s|s.parse().expect("number")).collect();
        assert_eq!(a.len(),9);
        let (j,v,w,s,mf,md,mr,nf,ca)=(a[0] as usize,a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8]);
        assert!((1..=16).contains(&j) && v>0. && v<1. && w>0. && w<1.);
        let cf=(ca*ca-1.)/(2.*ca);
        let pc=polarized::MeContext{ca,cf,nf,pi:std::f64::consts::PI,q2fac:mf,q2mu:mr,q2frag:md};
        let uc=unpolarized::MeContext{ca,cf,nf,q2fac:mf,q2mu:mr,q2frag:md};
        let pp=polarized::precalc(v,w,s,&pc);
        let up=unpolarized::precalc(v,w,s,&uc);
        let p0=polarized::avwpl(j,1.,v,s,&pc);
        let p1=polarized::avlo(j,1.,v,s,&pc);
        let u0=unpolarized::avwpl(j,1.,v,s,&uc);
        let u1=unpolarized::avlo(j,1.,v,s,&uc);
        let pr=polarized::struv(j,w,v,1.,s,&pc,&pp)
            +(polarized::avwpl(j,w,v,s,&pc)-p0)/(1.-w)
            +(polarized::avlo(j,w,v,s,&pc)-p1)*(1.-w).ln()/(1.-w);
        let ur=unpolarized::struv(j,w,v,1.,s,&uc,&up)+unpolarized::avgo(w,v)
            +(unpolarized::avwpl(j,w,v,s,&uc)-u0)/(1.-w)
            +(unpolarized::avlo(j,w,v,s,&uc)-u1)*(1.-w).ln()/(1.-w);
        let values=[unpolarized::avdel(j,v,s,&uc),u0,u1,ur,
            polarized::avdel(j,v,s,&pc),p0,p1,pr];
        assert!(values.iter().all(|x|x.is_finite()));
        for x in values { print!("{:.17e} ",x); }
        println!();
    }
}
