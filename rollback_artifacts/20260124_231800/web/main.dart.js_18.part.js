((a,b)=>{a[b]=a[b]||{}})(self,"$__dart_deferred_initializers__")
$__dart_deferred_initializers__.current=function(a,b,c,$){var A,B,C={
bEM(){return new C.zN(null)},
zN:function zN(d){this.a=d},
aKK:function aKK(){},
aKJ:function aKJ(d){this.a=d}},D
A=c[0]
B=c[2]
C=a.updateHolder(c[11],C)
D=c[29]
C.zN.prototype={
h3(d,e){var x,w,v,u=null,t="[DEFAULT]",s=$.aF,r=(s==null?$.aF=$.bX():s).bE(t)
s=$.cp()
A.b7(r,s,!0)
x=A.kV(new A.bJ(r)).gd7()
if(x==null)return A.cO(A.f4(u,u,u,!0,!0,u,u,1,u,u,u,!1,u,!1,u,u,u,u,!0,u,u,u,u,u,D.Hk,u,u,u,1,u,!0),u,D.Mm,u,u)
w=A.f4(u,u,u,!0,!0,u,u,1,u,u,u,!1,u,!1,u,u,u,u,!0,u,u,u,u,u,D.Hk,u,u,u,1,u,!0)
v=$.aF
r=(v==null?$.aF=$.bX():v).bE(t)
A.b7(r,s,!0)
return A.cO(w,u,A.lk(new C.aKK(),A.eW(new A.bJ(r)).af("withdrawals").ew(0,"userId",x.a.c.a.a).f3("createdAt",!0).eA(),y.g),u,u)}}
var z=a.updateTypes([])
C.aKK.prototype={
$2(d,e){var x,w=null,v=e.c
if(v!=null)return A.bY(A.B("Error: "+A.i(v),w,w,w,w,w,w,w,w),w,w)
if(e.a===B.d8)return B.bK
v=e.b
x=v==null?w:v.gce()
if(x==null)x=A.b([],y.l)
v=x.length
if(v===0)return D.MJ
return A.eP(w,new C.aKJ(x),v,B.O,B.E)},
$S:79}
C.aKJ.prototype={
$2(d,e){var x,w,v,u,t,s,r=null,q=this.a[e].dZ(0)
q.toString
y.i.a(q)
x=A.ab(q.h(0,"status"))
if(x==null)x="pending"
w=A.dV(q.h(0,"amount"))
if(w==null)w=0
v=A.ab(q.h(0,"email"))
if(v==null)v=""
u=y.p.a(q.h(0,"createdAt"))
q=x==="completed"
if(q)t=B.eY
else t=x==="rejected"?B.uo:D.Vb
if(q)q=B.aU
else q=x==="rejected"?B.bn:B.cF
q=A.cM(t,q,r,r,r)
t=A.B("$"+w,r,r,r,r,r,r,r,r)
s=A.b([A.B("Email: "+v,r,r,r,r,r,r,r,r),A.B("Status: "+x.toUpperCase(),r,r,r,r,r,r,r,r)],y.e)
if(u!=null)s.push(A.B("Date: "+B.c.al(A.f7(u.geQ()).l(0),0,10),r,r,r,r,r,r,r,r))
return A.h2(A.h8(!1,r,r,r,!0,r,r,!0,!0,q,r,r,!1,r,r,r,A.aa(s,B.I,B.j,B.h,0,B.m),r,t,r,r,r),r,r,B.bO,r)},
$S:82};(function inheritance(){var x=a.inherit,w=a.inheritMany
x(C.zN,A.t8)
w(A.kN,[C.aKK,C.aKJ])})()
A.o3(b.typeUniverse,JSON.parse('{"zN":{"Q":[],"d":[]}}'))
var y={l:A.T("C<e_<v?>>"),e:A.T("C<d>"),i:A.T("a7<o,@>"),g:A.T("eQ<v?>"),p:A.T("fd?")};(function constants(){D.ajb=new A.S("Not authenticated",null,null,null,null,null,null,null,null,null,null)
D.Mm=new A.cT(B.R,null,null,D.ajb,null)
D.ajc=new A.S("No withdrawal history",null,null,null,null,null,null,null,null,null,null)
D.MJ=new A.cT(B.R,null,null,D.ajc,null)
D.Vb=new A.aX(58500,"MaterialIcons",!1)
D.Hk=new A.S("Withdrawal History",null,null,null,null,null,null,null,null,null,null)})()};
(a=>{a["8lbBxOU3RscgZo3/2W9t1Q8Z+R8="]=a.current})($__dart_deferred_initializers__);