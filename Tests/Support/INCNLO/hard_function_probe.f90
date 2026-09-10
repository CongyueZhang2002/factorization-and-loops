program incnlo_check
 implicit none
 real(8) :: pi,gs,gv,gw,n,gtr,cf,pt2,vc,m,mp,mu,al,cq,v1,v2,v3,v4
 real(8) :: v,w,s,mf2,md2,mr2,nf,delta,plus0,plus1,regular,wp,lp
 integer :: iflag,ichoi,j0,jmar,ipt,ios
 character(len=16) :: channel_argument
 real(8), external :: avdel,avwpl,avlo,struv,avgo
 common /cons/ pi,gs,gv,gw,n,gtr,cf,pt2,vc
 common /hascale/ m,mp,mu
 common /orde/ iflag,ichoi,al,cq,v1,v2,v3,v4
 common /edf/ j0
 common /valu/ jmar,ipt
 pi=acos(-1d0);gs=1d0;gv=0d0;gw=0d0;pt2=1d0
 n=3d0;cf=4d0/3d0;vc=n*n-1d0
 v1=vc*vc/n;v2=vc/n;v3=(n**4-1d0)/(2d0*n*n);v4=vc*vc/(2d0*n*n)
 ! Original param.f fixes ZAL=1; pioincl.f calls FICT, fixing CQ=0.
 ! cdel.f documents JMAR=0 or 2 as the conversion to MSbar.
 al=1d0;cq=0d0;jmar=0;ipt=0;j0=1;iflag=1;ichoi=2
 call get_command_argument(1,channel_argument)
 if(len_trim(channel_argument)>0) then
  read(channel_argument,*,iostat=ios) j0
  if(ios/=0 .or. j0<1 .or. j0>16) stop 2
 end if
 do
  read(*,*,iostat=ios) v,w,s,mf2,md2,mr2,nf
  if(ios/=0) exit
  m=sqrt(mf2);mp=sqrt(md2);mu=sqrt(mr2);gtr=nf/2d0
  delta=avdel(v,s);plus0=avwpl(1d0,v,s);plus1=avlo(1d0,v,s)
  wp=avwpl(w,v,s);lp=avlo(w,v,s)
  regular=struv(w,v,1d0,s)+avgo(w,v)+(wp-plus0)/(1d0-w) &
     +(lp-plus1)*log(1d0-w)/(1d0-w)
  write(*,'(4(es26.17e3,1x))') delta,plus0,plus1,regular
 end do
end program incnlo_check
