(function dartProgram(){function copyProperties(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
b[r]=a[r]}}function mixinPropertiesHard(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
if(!b.hasOwnProperty(r)){b[r]=a[r]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var t=function(){}
t.prototype={p:{}}
var s=new t()
if(!(Object.getPrototypeOf(s)&&Object.getPrototypeOf(s).p===t.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var r=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(r))return true}}catch(q){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var t=Object.create(b.prototype)
copyProperties(a.prototype,t)
a.prototype=t}}function inheritMany(a,b){for(var t=0;t<b.length;t++){inherit(b[t],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){var s=d()
if(a[b]!==t){A.pR(b)}a[b]=s}var r=a[b]
a[c]=function(){return r}
return r}}function makeConstList(a,b){if(b!=null)A.QI(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var t=0;t<a.length;++t){convertToFastObject(a[t])}}var y=0
function instanceTearOffGetter(a,b){var t=null
return a?function(c){if(t===null)t=A.qm(b)
return new t(c,this)}:function(){if(t===null)t=A.qm(b)
return new t(this,null)}}function staticTearOffGetter(a){var t=null
return function(){if(t===null)t=A.qm(a).prototype
return t}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var t=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var s=staticTearOffGetter(t)
a[b]=s}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var t=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var s=instanceTearOffGetter(c,t)
a[b]=s}function setOrUpdateInterceptorsByTag(a){var t=v.interceptorsByTag
if(!t){v.interceptorsByTag=a
return}copyProperties(a,t)}function setOrUpdateLeafTags(a){var t=v.leafTags
if(!t){v.leafTags=a
return}copyProperties(a,t)}function updateTypes(a){var t=v.types
var s=t.length
t.push.apply(t,a)
return s}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var t=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},s=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:t(0,0,null,["$0"],0),_instance_1u:t(0,1,null,["$1"],0),_instance_2u:t(0,2,null,["$2"],0),_instance_0i:t(1,0,null,["$0"],0),_instance_1i:t(1,1,null,["$1"],0),_instance_2i:t(1,2,null,["$2"],0),_static_0:s(0,null,["$0"],0),_static_1:s(1,null,["$1"],0),_static_2:s(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
py(a,b){var t=A.QI(a,b.C("jd<0>"))
t.$flags=1
return t},
dD(a){if(typeof a=="string")return J.Dr.prototype
if(a==null)return a
if(Array.isArray(a))return J.jd.prototype
if(!(a instanceof A.Mh))return J.kd.prototype
return a},
ia(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.im.prototype
return J.kD.prototype}if(typeof a=="string")return J.Dr.prototype
if(a==null)return J.CD.prototype
if(typeof a=="boolean")return J.yE.prototype
if(Array.isArray(a))return J.jd.prototype
if(typeof a=="function")return J.c5.prototype
if(typeof a=="object"){if(a instanceof A.Mh){return a}else{return J.MF.prototype}}if(!(a instanceof A.Mh))return J.kd.prototype
return a},
lG(a){if(a==null)return a
if(Array.isArray(a))return J.jd.prototype
if(!(a instanceof A.Mh))return J.kd.prototype
return a},
Kg(a,b){if(typeof b==="number")if(Array.isArray(a))if(b>>>0===b&&b<a.length)return a[b]
return J.lG(a).WH(a,b)},
Md(a){return J.dD(a).gl0(a)},
TP(a){return J.ia(a).gbx(a)},
Wo(a,b){return J.lG(a).i(a,b)},
a3(a){return J.ia(a)["["](a)},
aX(a){return J.dD(a).gkF(a)},
cf(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.ia(a).DN(a,b)},
jg(a){return J.ia(a).giO(a)},
kg(a,b){return J.lG(a).Zv(a,b)},
x5(a){return J.lG(a).gkz(a)},
vB:function vB(){},
yE:function yE(){},
CD:function CD(){},
MF:function MF(){},
zh:function zh(){},
iC:function iC(){},
kd:function kd(){},
c5:function c5(){},
jd:function jd(a){this.$ti=a},
BC:function BC(){},
Po:function Po(a){this.$ti=a},
m1:function m1(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
qI:function qI(){},
im:function im(){},
kD:function kD(){},
Dr:function Dr(){}},A={FK:function FK(){},
GJ(a,b,c){if(u.Q.b(a))return new A.ol(a,b.C("@<0>").K(c).C("ol<1,2>"))
return new A.Zy(a,b.C("@<0>").K(c).C("Zy<1,2>"))},
yc(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
qL(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
ks(a){var t,s
for(t=$.xg.length,s=0;s<t;++s)if(a===$.xg[s])return!0
return!1},
K1(a,b,c,d){if(u.Q.b(a))return new A.xy(a,b,c.C("@<0>").K(d).C("xy<1,2>"))
return new A.i1(a,b,c.C("@<0>").K(d).C("i1<1,2>"))},
Wp(){return new A.lj("No element")},
BR:function BR(){},
Cf:function Cf(a,b){this.a=a
this.$ti=b},
Zy:function Zy(a,b){this.a=a
this.$ti=b},
ol:function ol(a,b){this.a=a
this.$ti=b},
by:function by(a,b){this.a=a
this.$ti=b},
aA:function aA(a,b){this.a=a
this.b=b},
oB:function oB(a){this.a=a},
n:function n(a){this.a=a},
zl:function zl(){},
bQ:function bQ(){},
aL:function aL(){},
a7:function a7(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
i1:function i1(a,b,c){this.a=a
this.b=b
this.$ti=c},
xy:function xy(a,b,c){this.a=a
this.b=b
this.$ti=c},
MH:function MH(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
A8:function A8(a,b,c){this.a=a
this.b=b
this.$ti=c},
oi:function oi(a,b,c){this.a=a
this.b=b
this.$ti=c},
SO:function SO(a,b,c){this.a=a
this.b=b
this.$ti=c},
ax(a,b,c){var t,s,r,q,p,o,n,m=A.PW(a.gv(),!0,b),l=m.length,k=0
for(;;){if(!(k<l)){t=!0
break}s=m[k]
if(typeof s!="string"||"__proto__"===s){t=!1
break}++k}if(t){r={}
for(q=0,k=0;k<m.length;m.length===l||(0,A.lk)(m),++k,q=p){s=m[k]
c.a(a.WH(0,s))
p=q+1
r[s]=q}o=A.PW(a.gUQ(),!0,c)
n=new A.LP(r,o,b.C("@<0>").K(c).C("LP<1,2>"))
n.$keys=m
return n}return new A.PD(A.T6(a,b,c),b.C("@<0>").K(c).C("PD<1,2>"))},
NQ(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
J(a){var t
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
t=J.a3(a)
return t},
eQ(a){var t,s=$.xu
if(s==null)s=$.xu=Symbol("identityHashCode")
t=a[s]
if(t==null){t=Math.random()*0x3fffffff|0
a[s]=t}return t},
lh(a){var t,s,r,q
if(a instanceof A.Mh)return A.dm(A.zK(a),null)
t=J.ia(a)
if(t===B.Ok||t===B.Ub||u.cr.b(a)){s=B.O4(a)
if(s!=="Object"&&s!=="")return s
r=a.constructor
if(typeof r=="function"){q=r.name
if(typeof q=="string"&&q!=="Object"&&q!=="")return q}}return A.dm(A.zK(a),null)},
ik(a){var t,s,r
if(a==null||typeof a=="number"||A.rQ(a))return J.a3(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.Tp)return a["["](0)
if(a instanceof A.S5)return a.k(!0)
t=$.Ve()
for(s=0;s<1;++s){r=t[s].R(a)
if(r!=null)return r}return"Instance of '"+A.lh(a)+"'"},
Lw(a){var t
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){t=a-65536
return String.fromCharCode((B.jn.wG(t,10)|55296)>>>0,t&1023|56320)}throw A.b(A.TE(a,0,1114111,null,null))},
OH(a,b){if(a==null)J.aX(a)
throw A.b(A.HY(a,b))},
HY(a,b){var t,s="index"
if(!A.ok(b))return new A.AT(!0,b,s,null)
t=J.aX(a)
if(b<0||b>=t)return A.xF(b,t,a,s)
return A.O7(b,s)},
b(a){return A.x(a,new Error())},
x(a,b){var t
if(a==null)a=new A.Ez()
b.dartException=a
t=A.Ju
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:t})
b.name=""}else b.toString=t
return b},
Ju(){return J.a3(this.dartException)},
v(a,b){throw A.x(a,b==null?new Error():b)},
cW(a,b,c){var t
if(b==null)b=0
if(c==null)c=0
t=Error()
A.v(A.Bi(a,b,c),t)},
Bi(a,b,c){var t,s,r,q,p,o,n,m,l
if(typeof b=="string")t=b
else{s="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
r=s.length
q=b
if(q>r){c=q/r|0
q%=r}t=s[q]}p=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
o=u.j.b(a)?"list":"ByteData"
n=a.$flags|0
m="a "
if((n&4)!==0)l="constant "
else if((n&2)!==0){l="unmodifiable "
m="an "}else l=(n&1)!==0?"fixed-length ":""
return new A.ub("'"+t+"': Cannot "+p+" "+m+l+o)},
lk(a){throw A.b(A.a4(a))},
cM(a){var t,s,r,q,p,o
a=A.eA(a.replace(String({}),"$receiver$"))
t=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(t==null)t=A.QI([],u.s)
s=t.indexOf("\\$arguments\\$")
r=t.indexOf("\\$argumentsExpr\\$")
q=t.indexOf("\\$expr\\$")
p=t.indexOf("\\$method\\$")
o=t.indexOf("\\$receiver\\$")
return new A.Zr(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),s,r,q,p,o)},
S7(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(t){return t.message}}(a)},
Mj(a){return function($expr$){try{$expr$.$method$}catch(t){return t.message}}(a)},
T3(a,b){var t=b==null,s=t?null:b.method
return new A.az(a,s,t?null:b.receiver)},
Ru(a){if(a==null)return new A.te(a)
if(typeof a!=="object")return a
if("dartException" in a)return A.tW(a,a.dartException)
return A.tl(a)},
tW(a,b){if(u.C.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
tl(a){var t,s,r,q,p,o,n,m,l,k,j,i,h
if(!("message" in a))return a
t=a.message
if("number" in a&&typeof a.number=="number"){s=a.number
r=s&65535
if((B.jn.wG(s,16)&8191)===10)switch(r){case 438:return A.tW(a,A.T3(A.J(t)+" (Error "+r+")",null))
case 445:case 5007:A.J(t)
return A.tW(a,new A.W0())}}if(a instanceof TypeError){q=$.Sn()
p=$.lq()
o=$.N9()
n=$.iI()
m=$.UN()
l=$.Zh()
k=$.rN()
$.c3()
j=$.HK()
i=$.r1()
h=q.qS(t)
if(h!=null)return A.tW(a,A.T3(A.Bt(t),h))
else{h=p.qS(t)
if(h!=null){h.method="call"
return A.tW(a,A.T3(A.Bt(t),h))}else if(o.qS(t)!=null||n.qS(t)!=null||m.qS(t)!=null||l.qS(t)!=null||k.qS(t)!=null||n.qS(t)!=null||j.qS(t)!=null||i.qS(t)!=null){A.Bt(t)
return A.tW(a,new A.W0())}}return A.tW(a,new A.vV(typeof t=="string"?t:""))}if(a instanceof RangeError){if(typeof t=="string"&&t.indexOf("call stack")!==-1)return new A.VS()
t=function(b){try{return String(b)}catch(g){}return null}(a)
return A.tW(a,new A.AT(!1,null,null,typeof t=="string"?t.replace(/^RangeError:\s*/,""):t))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof t=="string"&&t==="too much recursion")return new A.VS()
return a},
CU(a){if(a==null)return J.jg(a)
if(typeof a=="object")return A.eQ(a)
return J.jg(a)},
HP(a){if(typeof a=="number")return B.CD.giO(a)
if(a instanceof A.lY)return A.eQ(a)
if(a instanceof A.S5)return a.giO(a)
return A.CU(a)},
B7(a,b){var t,s,r,q=a.length
for(t=0;t<q;t=r){s=t+1
r=s+1
b.Y(0,a[t],a[s])}return b},
iA(a1){var t,s,r,q,p,o,n,m,l,k,j=a1.co,i=a1.iS,h=a1.iI,g=a1.nDA,f=a1.aI,e=a1.fs,d=a1.cs,c=e[0],b=d[0],a=j[c],a0=a1.fT
a0.toString
t=i?Object.create(new A.zx().constructor.prototype):Object.create(new A.rT(null,null).constructor.prototype)
t.$initialize=t.constructor
s=i?function static_tear_off(){this.$initialize()}:function tear_off(a2,a3){this.$initialize(a2,a3)}
t.constructor=s
s.prototype=t
t.$_name=c
t.$_target=a
r=!i
if(r)q=A.bx(c,a,h,g)
else{t.$static_name=c
q=a}t.$S=A.fm(a0,i,h)
t[b]=q
for(p=q,o=1;o<e.length;++o){n=e[o]
if(typeof n=="string"){m=j[n]
l=n
n=m}else l=""
k=d[o]
if(k!=null){if(r)n=A.bx(l,n,h,g)
t[k]=n}if(o===f)p=n}t.$C=p
t.$R=a1.rC
t.$D=a1.dV
return s},
fm(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.b("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.Tn)}throw A.b("Error in functionType of tearoff")},
vq(a,b,c,d){var t=A.yS
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,t)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,t)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,t)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,t)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,t)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,t)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,t)}},
bx(a,b,c,d){if(c)return A.Hf(a,b,d)
return A.vq(b.length,d,a,b)},
Z4(a,b,c,d){var t=A.yS,s=A.AO
switch(b?-1:a){case 0:throw A.b(new A.Eq("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,s,t)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,s,t)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,s,t)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,s,t)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,s,t)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,s,t)
default:return function(e,f,g){return function(){var r=[g(this)]
Array.prototype.push.apply(r,arguments)
return e.apply(f(this),r)}}(d,s,t)}},
Hf(a,b,c){var t,s
if($.Al==null)$.Al=A.L4("interceptor")
if($.i0==null)$.i0=A.L4("receiver")
t=b.length
s=A.Z4(t,c,a,b)
return s},
qm(a){return A.iA(a)},
Tn(a,b){return A.cE(v.typeUniverse,A.zK(a.a),b)},
yS(a){return a.a},
AO(a){return a.b},
L4(a){var t,s,r,q=new A.rT("receiver","interceptor"),p=Object.getOwnPropertyNames(q)
p.$flags=1
t=p
for(p=t.length,s=0;s<p;++s){r=t[s]
if(q[r]===a)return r}throw A.b(A.q("Field name "+a+" not found."))},
Yg(a){return v.getIsolateTag(a)},
Wk(a,b){var t=b.length,s=v.rttc[""+t+";"+a]
if(s==null)return null
if(t===0)return s
if(t===s.length)return s.apply(null,b)
return s(b)},
eA(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
LN:function LN(a,b){this.a=a
this.b=b},
PD:function PD(a,b){this.a=a
this.$ti=b},
ys:function ys(){},
hN:function hN(a,b,c){this.a=a
this.b=b
this.c=c},
LP:function LP(a,b,c){this.a=a
this.b=b
this.$ti=c},
Ku:function Ku(a,b){this.a=a
this.$ti=b},
vI:function vI(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
kz:function kz(a,b){this.a=a
this.$ti=b},
rY:function rY(){},
Zr:function Zr(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
W0:function W0(){},
az:function az(a,b,c){this.a=a
this.b=b
this.c=c},
vV:function vV(a){this.a=a},
te:function te(a){this.a=a},
Tp:function Tp(){},
Ay:function Ay(){},
E1:function E1(){},
lc:function lc(){},
zx:function zx(){},
rT:function rT(a,b){this.a=a
this.b=b},
Eq:function Eq(a){this.a=a},
N5:function N5(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
EM:function EM(a){this.a=a},
vh:function vh(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
Gp:function Gp(a,b){this.a=a
this.$ti=b},
N6:function N6(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
GP:function GP(a,b){this.a=a
this.$ti=b},
Gf:function Gf(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
C5:function C5(a,b){this.a=a
this.$ti=b},
HQ:function HQ(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
cL:function cL(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
S5:function S5(){},
nz:function nz(){},
xZ(a,b){var t=b.c
return t==null?b.c=A.Q2(a,"b8",[b.x]):t},
Q1(a){var t=a.w
if(t===6||t===7)return A.Q1(a.x)
return t===11||t===12},
mD(a){return a.as},
q7(a){return A.E(v.typeUniverse,a,!1)},
PL(a0,a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a1.w
switch(a){case 5:case 1:case 2:case 3:case 4:return a1
case 6:t=a1.x
s=A.PL(a0,t,a2,a3)
if(s===t)return a1
return A.Bc(a0,s,!0)
case 7:t=a1.x
s=A.PL(a0,t,a2,a3)
if(s===t)return a1
return A.f(a0,s,!0)
case 8:r=a1.y
q=A.bZ(a0,r,a2,a3)
if(q===r)return a1
return A.Q2(a0,a1.x,q)
case 9:p=a1.x
o=A.PL(a0,p,a2,a3)
n=a1.y
m=A.bZ(a0,n,a2,a3)
if(o===p&&m===n)return a1
return A.ap(a0,o,m)
case 10:l=a1.x
k=a1.y
j=A.bZ(a0,k,a2,a3)
if(j===k)return a1
return A.a(a0,l,j)
case 11:i=a1.x
h=A.PL(a0,i,a2,a3)
g=a1.y
f=A.qT(a0,g,a2,a3)
if(h===i&&f===g)return a1
return A.d(a0,h,f)
case 12:e=a1.y
a3+=e.length
d=A.bZ(a0,e,a2,a3)
p=a1.x
o=A.PL(a0,p,a2,a3)
if(d===e&&o===p)return a1
return A.DS(a0,o,d,!0)
case 13:c=a1.x
if(c<a3)return a1
b=a2[c-a3]
if(b==null)return a1
return b
default:throw A.b(A.h("Attempted to substitute unexpected RTI kind "+a))}},
bZ(a,b,c,d){var t,s,r,q,p=b.length,o=A.vU(p)
for(t=!1,s=0;s<p;++s){r=b[s]
q=A.PL(a,r,c,d)
if(q!==r)t=!0
o[s]=q}return t?o:b},
vO(a,b,c,d){var t,s,r,q,p,o,n=b.length,m=A.vU(n)
for(t=!1,s=0;s<n;s+=3){r=b[s]
q=b[s+1]
p=b[s+2]
o=A.PL(a,p,c,d)
if(o!==p)t=!0
m.splice(s,3,r,q,o)}return t?m:b},
qT(a,b,c,d){var t,s=b.a,r=A.bZ(a,s,c,d),q=b.b,p=A.bZ(a,q,c,d),o=b.c,n=A.vO(a,o,c,d)
if(r===s&&p===q&&n===o)return b
t=new A.G()
t.a=r
t.b=p
t.c=n
return t},
QI(a,b){a[v.arrayRti]=b
return a},
JS(a){var t=a.$S
if(t!=null){if(typeof t=="number")return A.Bp(t)
return a.$S()}return null},
Ue(a,b){var t
if(A.Q1(b))if(a instanceof A.Tp){t=A.JS(a)
if(t!=null)return t}return A.zK(a)},
zK(a){if(a instanceof A.Mh)return A.Lh(a)
if(Array.isArray(a))return A.t6(a)
return A.VU(J.ia(a))},
t6(a){var t=a[v.arrayRti],s=u.o
if(t==null)return s
if(t.constructor!==s.constructor)return s
return t},
Lh(a){var t=a.$ti
return t!=null?t:A.VU(a)},
VU(a){var t=a.constructor,s=t.$ccache
if(s!=null)return s
return A.r9(a,t)},
r9(a,b){var t=a instanceof A.Tp?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,s=A.ai(v.typeUniverse,t.name)
b.$ccache=s
return s},
Bp(a){var t,s=v.types,r=s[a]
if(typeof r=="string"){t=A.E(v.typeUniverse,r,!1)
s[a]=t
return t}return r},
RW(a){return A.Kx(A.Lh(a))},
l(a){var t
if(a instanceof A.S5)return a.J()
t=a instanceof A.Tp?A.JS(a):null
if(t!=null)return t
if(u.bW.b(a))return J.TP(a).a
if(Array.isArray(a))return A.t6(a)
return A.zK(a)},
Kx(a){var t=a.r
return t==null?a.r=new A.lY(a):t},
Mi(a,b){var t,s,r=b,q=r.length
if(q===0)return u.cD
if(0>=q)return A.OH(r,0)
t=A.cE(v.typeUniverse,A.l(r[0]),"@<0>")
for(s=1;s<q;++s){if(!(s<r.length))return A.OH(r,s)
t=A.v5(v.typeUniverse,t,A.l(r[s]))}return A.cE(v.typeUniverse,t,a)},
xq(a){return A.Kx(A.E(v.typeUniverse,a,!1))},
JJ(a){var t=this
t.b=A.fr(t)
return t.b(a)},
fr(a){var t,s,r,q,p
if(a===u.K)return A.ke
if(A.cc(a))return A.Iw
t=a.w
if(t===6)return A.AQ
if(t===1)return A.JY
if(t===7)return A.fg
s=A.U5(a)
if(s!=null)return s
if(t===8){r=a.x
if(a.y.every(A.cc)){a.f="$i"+r
if(r==="zM")return A.yM
if(a===u.m)return A.xD
return A.t4}}else if(t===10){q=A.Wk(a.x,a.y)
p=q==null?A.JY:q
return p==null?A.Ti(p):p}return A.YO},
U5(a){if(a.w===8){if(a===u.S)return A.ok
if(a===u.i||a===u.H)return A.KH
if(a===u.N)return A.MM
if(a===u.y)return A.rQ}return null},
Au(a){var t=this,s=A.Oz
if(A.cc(t))s=A.hn
else if(t===u.K)s=A.Ti
else if(A.lR(t)){s=A.l4
if(t===u.I)s=A.Uc
else if(t===u.x)s=A.k
else if(t===u.cG)s=A.M4
else if(t===u.ae)s=A.cU
else if(t===u.dd)s=A.Qk
else if(t===u.aQ)s=A.wI}else if(t===u.S)s=A.IZ
else if(t===u.N)s=A.Bt
else if(t===u.y)s=A.p8
else if(t===u.H)s=A.z5
else if(t===u.i)s=A.rV
else if(t===u.m)s=A.AN
t.a=s
return t.a(a)},
YO(a){var t=this
if(a==null)return A.lR(t)
return A.t1(v.typeUniverse,A.Ue(a,t),t)},
AQ(a){if(a==null)return!0
return this.x.b(a)},
t4(a){var t,s=this
if(a==null)return A.lR(s)
t=s.f
if(a instanceof A.Mh)return!!a[t]
return!!J.ia(a)[t]},
yM(a){var t,s=this
if(a==null)return A.lR(s)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
t=s.f
if(a instanceof A.Mh)return!!a[t]
return!!J.ia(a)[t]},
xD(a){var t=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.Mh)return!!a[t.f]
return!0}if(typeof a=="function")return!0
return!1},
Vl(a){if(typeof a=="object"){if(a instanceof A.Mh)return u.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
Oz(a){var t=this
if(a==null){if(A.lR(t))return a}else if(t.b(a))return a
throw A.x(A.fT(a,t),new Error())},
l4(a){var t=this
if(a==null||t.b(a))return a
throw A.x(A.fT(a,t),new Error())},
fT(a,b){return new A.iM("TypeError: "+A.p(a,A.dm(b,null)))},
p(a,b){return A.u(a)+": type '"+A.dm(A.l(a),null)+"' is not a subtype of type '"+b+"'"},
z(a,b){return new A.iM("TypeError: "+A.p(a,b))},
fg(a){var t=this
return t.x.b(a)||A.xZ(v.typeUniverse,t).b(a)},
ke(a){return a!=null},
Ti(a){if(a!=null)return a
throw A.x(A.z(a,"Object"),new Error())},
Iw(a){return!0},
hn(a){return a},
JY(a){return!1},
rQ(a){return!0===a||!1===a},
p8(a){if(!0===a)return!0
if(!1===a)return!1
throw A.x(A.z(a,"bool"),new Error())},
M4(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.x(A.z(a,"bool?"),new Error())},
rV(a){if(typeof a=="number")return a
throw A.x(A.z(a,"double"),new Error())},
Qk(a){if(typeof a=="number")return a
if(a==null)return a
throw A.x(A.z(a,"double?"),new Error())},
ok(a){return typeof a=="number"&&Math.floor(a)===a},
IZ(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.x(A.z(a,"int"),new Error())},
Uc(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.x(A.z(a,"int?"),new Error())},
KH(a){return typeof a=="number"},
z5(a){if(typeof a=="number")return a
throw A.x(A.z(a,"num"),new Error())},
cU(a){if(typeof a=="number")return a
if(a==null)return a
throw A.x(A.z(a,"num?"),new Error())},
MM(a){return typeof a=="string"},
Bt(a){if(typeof a=="string")return a
throw A.x(A.z(a,"String"),new Error())},
k(a){if(typeof a=="string")return a
if(a==null)return a
throw A.x(A.z(a,"String?"),new Error())},
AN(a){if(A.Vl(a))return a
throw A.x(A.z(a,"JSObject"),new Error())},
wI(a){if(a==null)return a
if(A.Vl(a))return a
throw A.x(A.z(a,"JSObject?"),new Error())},
io(a,b){var t,s,r
for(t="",s="",r=0;r<a.length;++r,s=", ")t+=s+A.dm(a[r],b)
return t},
wT(a,b){var t,s,r,q,p,o,n=a.x,m=a.y
if(""===n)return"("+A.io(m,b)+")"
t=m.length
s=n.split(",")
r=s.length-t
for(q="(",p="",o=0;o<t;++o,p=", "){q+=p
if(r===0)q+="{"
q+=A.dm(m[o],b)
if(r>=0)q+=" "+s[r];++r}return q+"})"},
bI(a2,a3,a4){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=", ",a1=null
if(a4!=null){t=a4.length
if(a3==null)a3=A.QI([],u.s)
else a1=a3.length
s=a3.length
for(r=t;r>0;--r)B.Nm.i(a3,"T"+(s+r))
for(q=u.X,p="<",o="",r=0;r<t;++r,o=a0){n=a3.length
m=n-1-r
if(!(m>=0))return A.OH(a3,m)
p=p+o+a3[m]
l=a4[r]
k=l.w
if(!(k===2||k===3||k===4||k===5||l===q))p+=" extends "+A.dm(l,a3)}p+=">"}else p=""
q=a2.x
j=a2.y
i=j.a
h=i.length
g=j.b
f=g.length
e=j.c
d=e.length
c=A.dm(q,a3)
for(b="",a="",r=0;r<h;++r,a=a0)b+=a+A.dm(i[r],a3)
if(f>0){b+=a+"["
for(a="",r=0;r<f;++r,a=a0)b+=a+A.dm(g[r],a3)
b+="]"}if(d>0){b+=a+"{"
for(a="",r=0;r<d;r+=3,a=a0){b+=a
if(e[r+1])b+="required "
b+=A.dm(e[r+2],a3)+" "+e[r]}b+="}"}if(a1!=null){a3.toString
a3.length=a1}return p+"("+b+") => "+c},
dm(a,b){var t,s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){t=a.x
s=A.dm(t,b)
r=t.w
return(r===11||r===12?"("+s+")":s)+"?"}if(m===7)return"FutureOr<"+A.dm(a.x,b)+">"
if(m===8){q=A.o3(a.x)
p=a.y
return p.length>0?q+("<"+A.io(p,b)+">"):q}if(m===10)return A.wT(a,b)
if(m===11)return A.bI(a,b,null)
if(m===12)return A.bI(a.x,b,a.y)
if(m===13){o=a.x
n=b.length
o=n-1-o
if(!(o>=0&&o<n))return A.OH(b,o)
return b[o]}return"?"},
o3(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
Qo(a,b){var t=a.tR[b]
while(typeof t=="string")t=a.tR[t]
return t},
ai(a,b){var t,s,r,q,p,o=a.eT,n=o[b]
if(n==null)return A.E(a,b,!1)
else if(typeof n=="number"){t=n
s=A.m(a,5,"#")
r=A.vU(t)
for(q=0;q<t;++q)r[q]=s
p=A.Q2(a,b,r)
o[b]=p
return p}else return n},
xb(a,b){return A.Ix(a.tR,b)},
FF(a,b){return A.Ix(a.eT,b)},
E(a,b,c){var t,s=a.eC,r=s.get(b)
if(r!=null)return r
t=A.i(A.o(a,null,b,!1))
s.set(b,t)
return t},
cE(a,b,c){var t,s,r=b.z
if(r==null)r=b.z=new Map()
t=r.get(c)
if(t!=null)return t
s=A.i(A.o(a,b,c,!0))
r.set(c,s)
return s},
v5(a,b,c){var t,s,r,q=b.Q
if(q==null)q=b.Q=new Map()
t=c.as
s=q.get(t)
if(s!=null)return s
r=A.ap(a,b,c.w===9?c.y:[c])
q.set(t,r)
return r},
BD(a,b){b.a=A.Au
b.b=A.JJ
return b},
m(a,b,c){var t,s,r=a.eC.get(c)
if(r!=null)return r
t=new A.Jc(null,null)
t.w=b
t.as=c
s=A.BD(a,t)
a.eC.set(c,s)
return s},
Bc(a,b,c){var t,s=b.as+"?",r=a.eC.get(s)
if(r!=null)return r
t=A.ll(a,b,s,c)
a.eC.set(s,t)
return t},
ll(a,b,c,d){var t,s,r
if(d){t=b.w
s=!0
if(!A.cc(b))if(!(b===u.b||b===u.T))if(t!==6)s=t===7&&A.lR(b.x)
if(s)return b
else if(t===1)return u.b}r=new A.Jc(null,null)
r.w=6
r.x=b
r.as=c
return A.BD(a,r)},
f(a,b,c){var t,s=b.as+"/",r=a.eC.get(s)
if(r!=null)return r
t=A.eV(a,b,s,c)
a.eC.set(s,t)
return t},
eV(a,b,c,d){var t,s
if(d){t=b.w
if(A.cc(b)||b===u.K)return b
else if(t===1)return A.Q2(a,"b8",[b])
else if(b===u.b||b===u.T)return u.bc}s=new A.Jc(null,null)
s.w=7
s.x=b
s.as=c
return A.BD(a,s)},
H(a,b){var t,s,r=""+b+"^",q=a.eC.get(r)
if(q!=null)return q
t=new A.Jc(null,null)
t.w=13
t.x=b
t.as=r
s=A.BD(a,t)
a.eC.set(r,s)
return s},
Ux(a){var t,s,r,q=a.length
for(t="",s="",r=0;r<q;++r,s=",")t+=s+a[r].as
return t},
S4(a){var t,s,r,q,p,o=a.length
for(t="",s="",r=0;r<o;r+=3,s=","){q=a[r]
p=a[r+1]?"!":":"
t+=s+q+p+a[r+2].as}return t},
Q2(a,b,c){var t,s,r,q=b
if(c.length>0)q+="<"+A.Ux(c)+">"
t=a.eC.get(q)
if(t!=null)return t
s=new A.Jc(null,null)
s.w=8
s.x=b
s.y=c
if(c.length>0)s.c=c[0]
s.as=q
r=A.BD(a,s)
a.eC.set(q,r)
return r},
ap(a,b,c){var t,s,r,q,p,o
if(b.w===9){t=b.x
s=b.y.concat(c)}else{s=c
t=b}r=t.as+(";<"+A.Ux(s)+">")
q=a.eC.get(r)
if(q!=null)return q
p=new A.Jc(null,null)
p.w=9
p.x=t
p.y=s
p.as=r
o=A.BD(a,p)
a.eC.set(r,o)
return o},
a(a,b,c){var t,s,r="+"+(b+"("+A.Ux(c)+")"),q=a.eC.get(r)
if(q!=null)return q
t=new A.Jc(null,null)
t.w=10
t.x=b
t.y=c
t.as=r
s=A.BD(a,t)
a.eC.set(r,s)
return s},
d(a,b,c){var t,s,r,q,p,o=b.as,n=c.a,m=n.length,l=c.b,k=l.length,j=c.c,i=j.length,h="("+A.Ux(n)
if(k>0){t=m>0?",":""
h+=t+"["+A.Ux(l)+"]"}if(i>0){t=m>0?",":""
h+=t+"{"+A.S4(j)+"}"}s=o+(h+")")
r=a.eC.get(s)
if(r!=null)return r
q=new A.Jc(null,null)
q.w=11
q.x=b
q.y=c
q.as=s
p=A.BD(a,q)
a.eC.set(s,p)
return p},
DS(a,b,c,d){var t,s=b.as+("<"+A.Ux(c)+">"),r=a.eC.get(s)
if(r!=null)return r
t=A.hw(a,b,c,s,d)
a.eC.set(s,t)
return t},
hw(a,b,c,d,e){var t,s,r,q,p,o,n,m
if(e){t=c.length
s=A.vU(t)
for(r=0,q=0;q<t;++q){p=c[q]
if(p.w===1){s[q]=p;++r}}if(r>0){o=A.PL(a,b,s,0)
n=A.bZ(a,c,s,0)
return A.DS(a,o,n,c!==n)}}m=new A.Jc(null,null)
m.w=12
m.x=b
m.y=c
m.as=d
return A.BD(a,m)},
o(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
i(a){var t,s,r,q,p,o,n,m=a.r,l=a.s
for(t=m.length,s=0;s<t;){r=m.charCodeAt(s)
if(r>=48&&r<=57)s=A.A(s+1,r,m,l)
else if((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124)s=A.t(a,s,m,l,!1)
else if(r===46)s=A.t(a,s,m,l,!0)
else{++s
switch(r){case 44:break
case 58:l.push(!1)
break
case 33:l.push(!0)
break
case 59:l.push(A.B(a.u,a.e,l.pop()))
break
case 94:l.push(A.H(a.u,l.pop()))
break
case 35:l.push(A.m(a.u,5,"#"))
break
case 64:l.push(A.m(a.u,2,"@"))
break
case 126:l.push(A.m(a.u,3,"~"))
break
case 60:l.push(a.p)
a.p=l.length
break
case 62:A.r(a,l)
break
case 38:A.I(a,l)
break
case 63:q=a.u
l.push(A.Bc(q,A.B(q,a.e,l.pop()),a.n))
break
case 47:q=a.u
l.push(A.f(q,A.B(q,a.e,l.pop()),a.n))
break
case 40:l.push(-3)
l.push(a.p)
a.p=l.length
break
case 41:A.M(a,l)
break
case 91:l.push(a.p)
a.p=l.length
break
case 93:p=l.splice(a.p)
A.c(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-1)
break
case 123:l.push(a.p)
a.p=l.length
break
case 125:p=l.splice(a.p)
A.y(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-2)
break
case 43:o=m.indexOf("(",s)
l.push(m.substring(s,o))
l.push(-4)
l.push(a.p)
a.p=l.length
s=o+1
break
default:throw"Bad character "+r}}}n=l.pop()
return A.B(a.u,a.e,n)},
A(a,b,c,d){var t,s,r=b-48
for(t=c.length;a<t;++a){s=c.charCodeAt(a)
if(!(s>=48&&s<=57))break
r=r*10+(s-48)}d.push(r)
return a},
t(a,b,c,d,e){var t,s,r,q,p,o,n=b+1
for(t=c.length;n<t;++n){s=c.charCodeAt(n)
if(s===46){if(e)break
e=!0}else{if(!((((s|32)>>>0)-97&65535)<26||s===95||s===36||s===124))r=s>=48&&s<=57
else r=!0
if(!r)break}}q=c.substring(b,n)
if(e){t=a.u
p=a.e
if(p.w===9)p=p.x
o=A.Qo(t,p.x)[q]
if(o==null)A.v('No "'+q+'" in "'+A.mD(p)+'"')
d.push(A.cE(t,p,o))}else d.push(q)
return n},
r(a,b){var t,s=a.u,r=A.j(a,b),q=b.pop()
if(typeof q=="string")b.push(A.Q2(s,q,r))
else{t=A.B(s,a.e,q)
switch(t.w){case 11:b.push(A.DS(s,t,r,a.n))
break
default:b.push(A.ap(s,t,r))
break}}},
M(a,b){var t,s,r,q=a.u,p=b.pop(),o=null,n=null
if(typeof p=="number")switch(p){case-1:o=b.pop()
break
case-2:n=b.pop()
break
default:b.push(p)
break}else b.push(p)
t=A.j(a,b)
p=b.pop()
switch(p){case-3:p=b.pop()
if(o==null)o=q.sEA
if(n==null)n=q.sEA
s=A.B(q,a.e,p)
r=new A.G()
r.a=t
r.b=o
r.c=n
b.push(A.d(q,s,r))
return
case-4:b.push(A.a(q,b.pop(),t))
return
default:throw A.b(A.h("Unexpected state under `()`: "+A.J(p)))}},
I(a,b){var t=b.pop()
if(0===t){b.push(A.m(a.u,1,"0&"))
return}if(1===t){b.push(A.m(a.u,4,"1&"))
return}throw A.b(A.h("Unexpected extended operation "+A.J(t)))},
j(a,b){var t=b.splice(a.p)
A.c(a.u,a.e,t)
a.p=b.pop()
return t},
B(a,b,c){if(typeof c=="string")return A.Q2(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.TV(a,b,c)}else return c},
c(a,b,c){var t,s=c.length
for(t=0;t<s;++t)c[t]=A.B(a,b,c[t])},
y(a,b,c){var t,s=c.length
for(t=2;t<s;t+=3)c[t]=A.B(a,b,c[t])},
TV(a,b,c){var t,s,r=b.w
if(r===9){if(c===0)return b.x
t=b.y
s=t.length
if(c<=s)return t[c-1]
c-=s
b=b.x
r=b.w}else if(c===0)return b
if(r!==8)throw A.b(A.h("Indexed base must be an interface type"))
t=b.y
if(c<=t.length)return t[c-1]
throw A.b(A.h("Bad index "+c+" for "+b["["](0)))},
t1(a,b,c){var t,s=b.d
if(s==null)s=b.d=new Map()
t=s.get(c)
if(t==null){t=A.We(a,b,null,c,null)
s.set(c,t)}return t},
We(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j
if(b===d)return!0
if(A.cc(d))return!0
t=b.w
if(t===4)return!0
if(A.cc(b))return!1
if(b.w===1)return!0
s=t===13
if(s)if(A.We(a,c[b.x],c,d,e))return!0
r=d.w
q=u.b
if(b===q||b===u.T){if(r===7)return A.We(a,b,c,d.x,e)
return d===q||d===u.T||r===6}if(d===u.K){if(t===7)return A.We(a,b.x,c,d,e)
return t!==6}if(t===7){if(!A.We(a,b.x,c,d,e))return!1
return A.We(a,A.xZ(a,b),c,d,e)}if(t===6)return A.We(a,q,c,d,e)&&A.We(a,b.x,c,d,e)
if(r===7){if(A.We(a,b,c,d.x,e))return!0
return A.We(a,b,c,A.xZ(a,d),e)}if(r===6)return A.We(a,b,c,q,e)||A.We(a,b,c,d.x,e)
if(s)return!1
q=t!==11
if((!q||t===12)&&d===u.Z)return!0
p=t===10
if(p&&d===u.cY)return!0
if(r===12){if(b===u.L)return!0
if(t!==12)return!1
o=b.y
n=d.y
m=o.length
if(m!==n.length)return!1
c=c==null?o:o.concat(c)
e=e==null?n:n.concat(e)
for(l=0;l<m;++l){k=o[l]
j=n[l]
if(!A.We(a,k,c,j,e)||!A.We(a,j,e,k,c))return!1}return A.bO(a,b.x,c,d.x,e)}if(r===11){if(b===u.L)return!0
if(q)return!1
return A.bO(a,b,c,d,e)}if(t===8){if(r!==8)return!1
return A.pG(a,b,c,d,e)}if(p&&r===10)return A.b6(a,b,c,d,e)
return!1},
bO(a2,a3,a4,a5,a6){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
if(!A.We(a2,a3.x,a4,a5.x,a6))return!1
t=a3.y
s=a5.y
r=t.a
q=s.a
p=r.length
o=q.length
if(p>o)return!1
n=o-p
m=t.b
l=s.b
k=m.length
j=l.length
if(p+k<o+j)return!1
for(i=0;i<p;++i){h=r[i]
if(!A.We(a2,q[i],a6,h,a4))return!1}for(i=0;i<n;++i){h=m[i]
if(!A.We(a2,q[p+i],a6,h,a4))return!1}for(i=0;i<j;++i){h=m[n+i]
if(!A.We(a2,l[i],a6,h,a4))return!1}g=t.c
f=s.c
e=g.length
d=f.length
for(c=0,b=0;b<d;b+=3){a=f[b]
for(;;){if(c>=e)return!1
a0=g[c]
c+=3
if(a<a0)return!1
a1=g[c-2]
if(a0<a){if(a1)return!1
continue}h=f[b+1]
if(a1&&!h)return!1
h=g[c-1]
if(!A.We(a2,f[b+2],a6,h,a4))return!1
break}}while(c<e){if(g[c+1])return!1
c+=3}return!0},
pG(a,b,c,d,e){var t,s,r,q,p,o=b.x,n=d.x
while(o!==n){t=a.tR[o]
if(t==null)return!1
if(typeof t=="string"){o=t
continue}s=t[n]
if(s==null)return!1
r=s.length
q=r>0?new Array(r):v.typeUniverse.sEA
for(p=0;p<r;++p)q[p]=A.cE(a,b,s[p])
return A.SW(a,q,null,c,d.y,e)}return A.SW(a,b.y,null,c,d.y,e)},
SW(a,b,c,d,e,f){var t,s=b.length
for(t=0;t<s;++t)if(!A.We(a,b[t],d,e[t],f))return!1
return!0},
b6(a,b,c,d,e){var t,s=b.y,r=d.y,q=s.length
if(q!==r.length)return!1
if(b.x!==d.x)return!1
for(t=0;t<q;++t)if(!A.We(a,s[t],c,r[t],e))return!1
return!0},
lR(a){var t=a.w,s=!0
if(!(a===u.b||a===u.T))if(!A.cc(a))if(t!==6)s=t===7&&A.lR(a.x)
return s},
cc(a){var t=a.w
return t===2||t===3||t===4||t===5||a===u.X},
Ix(a,b){var t,s,r=Object.keys(b),q=r.length
for(t=0;t<q;++t){s=r[t]
a[s]=b[s]}},
vU(a){return a>0?new Array(a):v.typeUniverse.sEA},
Jc:function Jc(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
G:function G(){this.c=this.b=this.a=null},
lY:function lY(a){this.a=a},
u9:function u9(){},
iM:function iM(a){this.a=a},
y7(a,b,c){return 0},
GV:function GV(a,b){var _=this
_.a=a
_.e=_.d=_.c=_.b=null
_.$ti=b},
q4:function q4(a,b){this.a=a
this.$ti=b},
L5(a,b){return new A.N5(a.C("@<0>").K(b).C("N5<1,2>"))},
EF(a,b,c){return b.C("@<0>").K(c).C("Fo<1,2>").a(A.B7(a,new A.N5(b.C("@<0>").K(c).C("N5<1,2>"))))},
Fl(a,b){return new A.N5(a.C("@<0>").K(b).C("N5<1,2>"))},
Ls(a){return new A.PZ(a.C("PZ<0>"))},
r2(a){return new A.PZ(a.C("PZ<0>"))},
pq(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
T6(a,b,c){var t=A.L5(b,c)
a.U(0,new A.EH(t,b,c))
return t},
qC(a,b,c){var t=A.L5(b,c)
t.A(0,a)
return t},
nO(a){var t,s
if(A.ks(a))return"{...}"
t=new A.Rn("")
try{s={}
B.Nm.i($.xg,a)
t.a+="{"
s.a=!0
a.U(0,new A.ra(s,t))
t.a+="}"}finally{if(0>=$.xg.length)return A.OH($.xg,-1)
$.xg.pop()}s=t.a
return s.charCodeAt(0)==0?s:s},
PZ:function PZ(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
bn:function bn(a){this.a=a
this.b=null},
lm:function lm(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
EH:function EH(a,b,c){this.a=a
this.b=b
this.c=c},
il:function il(){},
mb:function mb(a){this.a=a},
ra:function ra(a,b){this.a=a
this.b=b},
wU:function wU(a,b){this.a=a
this.$ti=b},
Uq:function Uq(a,b,c){var _=this
_.a=a
_.b=b
_.c=null
_.$ti=c},
KP:function KP(){},
Pn:function Pn(){},
Gj:function Gj(a,b){this.a=a
this.$ti=b},
Vj:function Vj(){},
Xv:function Xv(){},
RU:function RU(){},
BS(a,b){var t,s,r,q=null
try{q=JSON.parse(a)}catch(s){t=A.Ru(s)
r=A.rr(String(t))
throw A.b(r)}r=A.Qe(q)
return r},
Qe(a){var t
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new A.uw(a,Object.create(null))
for(t=0;t<a.length;++t)a[t]=A.Qe(a[t])
return a},
Gy(a,b,c){return new A.Ud(a,b)},
tp(a){return a.Lt()},
Ug(a,b){return new A.Gs(a,[],A.Cy())},
uX(a,b,c){var t,s=new A.Rn(""),r=A.Ug(s,b)
r.QD(a)
t=s.a
return t.charCodeAt(0)==0?t:t},
uw:function uw(a,b){this.a=a
this.b=b
this.c=null},
FE:function FE(a){this.a=a},
i8:function i8(a){this.a=a},
Uk:function Uk(){},
ze:function ze(){},
Ud:function Ud(a,b){this.a=a
this.b=b},
K8:function K8(a,b){this.a=a
this.b=b},
D4:function D4(){},
oj:function oj(a){this.b=a},
Mx:function Mx(a){this.a=a},
Sh:function Sh(){},
ti:function ti(a,b){this.a=a
this.b=b},
Gs:function Gs(a,b,c){this.c=a
this.a=b
this.b=c},
O8(a,b,c){var t
if(a<0||a>4294967295)A.v(A.TE(a,0,4294967295,"length",null))
t=J.py(new Array(a),c)
return t},
PW(a,b,c){var t,s=A.QI([],c.C("jd<0>"))
for(t=J.x5(a);t.G();)B.Nm.i(s,c.a(t.gl()))
if(b)return s
s.$flags=1
return s},
ev(a,b){var t,s
if(Array.isArray(a))return A.QI(a.slice(0),b.C("jd<0>"))
t=A.QI([],b.C("jd<0>"))
for(s=J.x5(a);s.G();)B.Nm.i(t,s.gl())
return t},
AF(a,b){var t=A.PW(a,!1,b)
t.$flags=3
return t},
vg(a,b,c){var t=J.x5(b)
if(!t.G())return a
if(c.length===0){do a+=A.J(t.gl())
while(t.G())}else{a+=A.J(t.gl())
while(t.G())a=a+c+A.J(t.gl())}return a},
u(a){if(typeof a=="number"||A.rQ(a)||a==null)return J.a3(a)
if(typeof a=="string")return JSON.stringify(a)
return A.ik(a)},
h(a){return new A.C6(a)},
q(a){return new A.AT(!1,null,null,a)},
C3(a){var t=null
return new A.bJ(t,t,!1,t,t,a)},
O7(a,b){return new A.bJ(null,null,!0,a,b,"Value not in range")},
TE(a,b,c,d,e){return new A.bJ(b,c,!0,a,d,"Invalid value")},
jB(a,b,c){if(0>a||a>c)throw A.b(A.TE(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.b(A.TE(b,a,c,"end",null))
return b}return c},
k1(a,b){return a},
xF(a,b,c,d){return new A.eY(b,!0,a,d,"Index out of range")},
u0(a){return new A.ub(a)},
PV(a){return new A.lj(a)},
a4(a){return new A.UV(a)},
rr(a){return new A.aE(a)},
Sd(a,b,c){var t,s
if(A.ks(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}t=A.QI([],u.s)
B.Nm.i($.xg,a)
try{A.Vr(a,t)}finally{if(0>=$.xg.length)return A.OH($.xg,-1)
$.xg.pop()}s=A.vg(b,u.bi.a(t),", ")+c
return s.charCodeAt(0)==0?s:s},
tA(a,b,c){var t,s
if(A.ks(a))return b+"..."+c
t=new A.Rn(b)
B.Nm.i($.xg,a)
try{s=t
s.a=A.vg(s.a,a,", ")}finally{if(0>=$.xg.length)return A.OH($.xg,-1)
$.xg.pop()}t.a+=c
s=t.a
return s.charCodeAt(0)==0?s:s},
Vr(a,b){var t,s,r,q,p,o,n,m=a.gkz(a),l=0,k=0
for(;;){if(!(l<80||k<3))break
if(!m.G())return
t=A.J(m.gl())
B.Nm.i(b,t)
l+=t.length+2;++k}if(!m.G()){if(k<=5)return
if(0>=b.length)return A.OH(b,-1)
s=b.pop()
if(0>=b.length)return A.OH(b,-1)
r=b.pop()}else{q=m.gl();++k
if(!m.G()){if(k<=4){B.Nm.i(b,A.J(q))
return}s=A.J(q)
if(0>=b.length)return A.OH(b,-1)
r=b.pop()
l+=s.length+2}else{p=m.gl();++k
for(;m.G();q=p,p=o){o=m.gl();++k
if(k>100){for(;;){if(!(l>75&&k>3))break
if(0>=b.length)return A.OH(b,-1)
l-=b.pop().length+2;--k}B.Nm.i(b,"...")
return}}r=A.J(q)
s=A.J(p)
l+=s.length+r.length+4}}if(k>b.length+2){l+=5
n="..."}else n=null
for(;;){if(!(l>80&&b.length>3))break
if(0>=b.length)return A.OH(b,-1)
l-=b.pop().length+2
if(n==null){l+=5
n="..."}}if(n!=null)B.Nm.i(b,n)
B.Nm.i(b,r)
B.Nm.i(b,s)},
bE(a,b,c,d,e){return new A.by(a,b.C("@<0>").K(c).K(d).K(e).C("by<1,2,3,4>"))},
f5(a,b,c,d,e,f,g){var t
if(B.zt===c){t=J.jg(a)
b=J.jg(b)
return A.qL(A.yc(A.yc($.t8(),t),b))}if(B.zt===d){t=J.jg(a)
b=J.jg(b)
c=J.jg(c)
return A.qL(A.yc(A.yc(A.yc($.t8(),t),b),c))}if(B.zt===e){t=J.jg(a)
b=J.jg(b)
c=J.jg(c)
d=J.jg(d)
return A.qL(A.yc(A.yc(A.yc(A.yc($.t8(),t),b),c),d))}if(B.zt===f){t=J.jg(a)
b=J.jg(b)
c=J.jg(c)
d=J.jg(d)
e=J.jg(e)
return A.qL(A.yc(A.yc(A.yc(A.yc(A.yc($.t8(),t),b),c),d),e))}if(B.zt===g){t=J.jg(a)
b=J.jg(b)
c=J.jg(c)
d=J.jg(d)
e=J.jg(e)
f=J.jg(f)
return A.qL(A.yc(A.yc(A.yc(A.yc(A.yc(A.yc($.t8(),t),b),c),d),e),f))}t=J.jg(a)
b=J.jg(b)
c=J.jg(c)
d=J.jg(d)
e=J.jg(e)
f=J.jg(f)
g=J.jg(g)
g=A.qL(A.yc(A.yc(A.yc(A.yc(A.yc(A.yc(A.yc($.t8(),t),b),c),d),e),f),g))
return g},
df(a){var t,s,r=$.t8()
for(t=a.length,s=0;s<a.length;a.length===t||(0,A.lk)(a),++s)r=A.yc(r,J.jg(a[s]))
return A.qL(r)},
ck:function ck(){},
Ge:function Ge(){},
C6:function C6(a){this.a=a},
Ez:function Ez(){},
AT:function AT(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
bJ:function bJ(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
eY:function eY(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
ub:function ub(a){this.a=a},
lj:function lj(a){this.a=a},
UV:function UV(a){this.a=a},
VS:function VS(){},
aE:function aE(a){this.a=a},
cX:function cX(){},
Yh:function Yh(a,b,c){this.a=a
this.b=b
this.$ti=c},
c8:function c8(){},
Mh:function Mh(){},
Rn:function Rn(a){this.a=a},
vY:function vY(){this.b=this.a=0},
rw(a){var t=B.W9.WH(0,a)
if(t!=null)return t
return B.Nm.Qk(B.x0,new A.DO(a),new A.Ax(a))},
QB:function QB(a,b,c){this.c=a
this.a=b
this.b=c},
DO:function DO(a){this.a=a},
Ax:function Ax(a){this.a=a},
yZ(a){return B.Nm.Qk(B.H2,new A.rg(a),new A.Nj(a))},
tN:function tN(a,b){this.a=a
this.b=b},
rg:function rg(a){this.a=a},
Nj:function Nj(a){this.a=a},
vr:function vr(a){this.a=a},
If:function If(a,b){this.a=a
this.b=b},
YE:function YE(a,b){this.a=a
this.b=b},
ts(a){var t=2147483648,s=a.fy,r=new A.vY()
r.L(((B.jn.h(s,t)^a.dy*2654435761&2147483647)>>>0)+B.jn.B(s,t)*2147483648)
return r},
yV(a,b,c){var t,s,r,q=a.WH(0,b)
if(q==null||!B.Nm.tg(q,c.b))return a
t=A.qC(a,u.N,u.a)
s=A.t6(q)
r=s.C("oi<1>")
s=A.ev(new A.oi(q,s.C("a0(1)").a(new A.XY(c)),r),r.C("cX.E"))
t.Y(0,b,s)
return t},
Mm:function Mm(){},
lZ:function lZ(){},
FZ:function FZ(a){this.a=a},
Pp:function Pp(){},
Ul:function Ul(){},
He:function He(){},
mB:function mB(){},
os:function os(){},
XY:function XY(a){this.a=a},
vL(a){var t
A:{if(a instanceof A.ry){t="CardPlayedEvent"
break A}if(a instanceof A.M7){t="CardsDrawnEvent"
break A}if(a instanceof A.Pt){t="TurnSkippedEvent"
break A}if(a instanceof A.Cx){t="ChainGrewEvent"
break A}if(a instanceof A.O3){t="ChainResolvedEvent"
break A}if(a instanceof A.E4){t="ChainBlockedEvent"
break A}if(a instanceof A.GE){t="LastCardDeclaredEvent"
break A}if(a instanceof A.Mw){t="SuitChoiceRequestedEvent"
break A}if(a instanceof A.wz){t="SuitChosenEvent"
break A}if(a instanceof A.oN){t="DeckRecycledEvent"
break A}if(a instanceof A.hc){t="TurnChangedEvent"
break A}if(a instanceof A.H0){t="RoundStartedEvent"
break A}if(a instanceof A.Gt){t="RoundEndedEvent"
break A}if(a instanceof A.GO){t="Exact101Event"
break A}if(a instanceof A.fM){t="PlayerEliminatedEvent"
break A}if(a instanceof A.bG){t="MatchEndedEvent"
break A}if(a instanceof A.qv){t="PlayerForfeitedEvent"
break A}t=null}return t},
LE:function LE(){},
ry:function ry(){},
M7:function M7(){},
Pt:function Pt(){},
Cx:function Cx(){},
O3:function O3(){},
E4:function E4(){},
GE:function GE(){},
Mw:function Mw(){},
wz:function wz(){},
oN:function oN(){},
hc:function hc(){},
H0:function H0(){},
Gt:function Gt(){},
GO:function GO(){},
fM:function fM(){},
bG:function bG(){},
qv:function qv(){},
OP(a,b){return new A.xk(a,b)},
ed:function ed(a,b){this.a=a
this.b=b},
xz:function xz(){},
dK:function dK(a,b){this.a=a
this.b=b},
KY:function KY(a){this.a=a},
xk:function xk(a,b){this.a=a
this.b=b},
ON:function ON(a,b,c,d){var _=this
_.a=a
_.c=b
_.d=c
_.e=d},
F2:function F2(a){this.a=a},
qR:function qR(a){this.a=a},
aF(a){var t,s,r="chosenSuit",q=A.k(a.WH(0,"type")),p=A.k(a.WH(0,"playerId"))
if(p==null)p=""
t=A.cU(a.WH(0,"baseVersion"))
s=t==null?null:B.CD.yu(t)
switch(q){case"playCard":t=A.SZ(a.WH(0,"card"))
return new A.e3(t,a.WH(0,r)==null?null:A.yZ(A.Bt(a.WH(0,r))),p,s)
case"drawCard":return new A.N3(p,s)
case"chooseSuit":return new A.OA(A.yZ(A.Bt(a.WH(0,"suit"))),p,s)
case"pass":return new A.ew(p,s)
case"startNextRound":return new A.wa(p,s)
case"forfeit":return new A.hP(p,s)
case"declareLastCard":return new A.eK(p,s)}throw A.b(A.rr("Unknown action type: "+A.J(q)))},
a2:function a2(){},
e3:function e3(a,b,c,d){var _=this
_.c=a
_.d=b
_.a=c
_.b=d},
N3:function N3(a,b){this.a=a
this.b=b},
OA:function OA(a,b,c){this.c=a
this.a=b
this.b=c},
ew:function ew(a,b){this.a=a
this.b=b},
wa:function wa(a,b){this.a=a
this.b=b},
hP:function hP(a,b){this.a=a
this.b=b},
eK:function eK(a,b){this.a=a
this.b=b},
er(a,b){return new A.bd(a,b)},
D0(a){var t,s=a.split("_"),r=s.length
if(r!==2)throw A.b(A.rr("Malformed card token: "+a))
if(0>=r)return A.OH(s,0)
t=A.yZ(s[0])
if(1>=r)return A.OH(s,1)
return new A.bd(t,A.rw(s[1]))},
SZ(a){var t,s,r
if(typeof a=="string")return A.D0(a)
if(u.f.b(a)){t=a.WH(0,"suit")
s=a.WH(0,"rank")
if(typeof t=="string"&&typeof s=="string")return new A.bd(A.yZ(t),A.rw(s))
r=a.WH(0,"id")
if(typeof r=="string")return A.D0(r)}throw A.b(A.rr("Malformed card json: "+A.J(a)))},
bd:function bd(a,b){this.a=a
this.b=b},
Y1(a){var t,s,r,q,p,o,n,m,l=null,k="difficulty",j="personality",i=A.Bt(a.WH(0,"id")),h=A.Bt(a.WH(0,"name")),g=A.k(a.WH(0,"type"))
g=A.VG(g==null?"bot":g)
t=A.k(a.WH(0,"avatarId"))
if(t==null)t="marco"
s=a.WH(0,k)==null?l:A.mX(A.Bt(a.WH(0,k)))
r=a.WH(0,j)==null?l:A.X1(A.Bt(a.WH(0,j)))
q=A.cU(a.WH(0,"score"))
q=q==null?l:B.CD.yu(q)
if(q==null)q=0
p=A.M4(a.WH(0,"eliminated"))
o=u.g.a(a.WH(0,"hand"))
if(o==null)o=B.dn
n=A.t6(o)
m=n.C("A8<1,bd>")
o=A.ev(new A.A8(o,n.C("bd(1)").a(new A.pn()),m),m.C("aL.E"))
if(u.j.b(a.WH(0,"hand")))n=l
else{n=A.cU(a.WH(0,"handCount"))
n=n==null?l:B.CD.yu(n)}return new A.Ee(i,h,g,t,s,r,q,p===!0,A.AF(o,u.U),n)},
ET(a,b){var t,s,r,q=a.length,p=b.length
if(q!==p)return!1
for(t=0;t<q;++t){s=a[t]
if(!(t<p))return A.OH(b,t)
r=b[t]
if(s!==r)s=r.a===s.a&&r.b===s.b
else s=!0
if(!s)return!1}return!0},
Ee:function Ee(a,b,c,d,e,f,g,h,i,j){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j},
Na:function Na(){},
pn:function pn(){},
RN(a){return B.Nm.Qk(B.le,new A.Nc(a),new A.YA())},
ul(a){return B.Nm.Qk(B.OI,new A.Sq(a),new A.o2())},
P0(a){return B.Nm.Qk(B.Y2,new A.LF(a),new A.QW())},
MR(a){return B.Nm.Qk(B.hn,new A.Ff(a),new A.Ij())},
L8(b0){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4=null,a5="nineBlockMode",a6="starterCardPolicy",a7="roundStarterPolicy",a8="initialDirection",a9=b0.WH(0,"scoreValues")
if(u.f.b(a9)){t=A.Fl(u.c,u.S)
for(s=0;s<10;++s){r=B.x0[s]
q=r.b
if(a9.NZ(q))t.Y(0,r,B.CD.yu(A.z5(a9.WH(0,q))))
else if(a9.NZ(A.Ie(r)))t.Y(0,r,B.CD.yu(A.z5(a9.WH(0,A.Ie(r)))))}p=t}else p=B.IY
t=A.cU(b0.WH(0,"minPlayers"))
t=t==null?a4:B.CD.yu(t)
if(t==null)t=2
q=A.cU(b0.WH(0,"maxPlayers"))
q=q==null?a4:B.CD.yu(q)
if(q==null)q=4
o=A.cU(b0.WH(0,"startingHandSize"))
o=o==null?a4:B.CD.yu(o)
if(o==null)o=5
n=A.M4(b0.WH(0,"allowVoluntaryDraw"))
m=A.M4(b0.WH(0,"playDrawnCardImmediately"))
l=A.M4(b0.WH(0,"restrictPlayToDrawnCard"))
k=A.M4(b0.WH(0,"stackDrawTwos"))
j=A.M4(b0.WH(0,"wildNineCanAlwaysPlay"))
i=b0.WH(0,a5)==null?B.cq:A.RN(A.Bt(b0.WH(0,a5)))
h=A.M4(b0.WH(0,"nineBlockChangesSuit"))
g=A.M4(b0.WH(0,"exact101ResetsToZero"))
f=A.M4(b0.WH(0,"eliminateAbove101"))
e=A.cU(b0.WH(0,"targetScore"))
e=e==null?a4:B.CD.yu(e)
if(e==null)e=101
d=A.M4(b0.WH(0,"mustDrawBeforePassing"))
c=A.cU(b0.WH(0,"drawTwoPenalty"))
c=c==null?a4:B.CD.yu(c)
if(c==null)c=2
b=A.M4(b0.WH(0,"pendingPenaltyAppliesAfterWin"))
a=b0.WH(0,a6)==null?B.WJ:A.ul(A.Bt(b0.WH(0,a6)))
a0=b0.WH(0,a7)==null?B.nk:A.P0(A.Bt(b0.WH(0,a7)))
a1=b0.WH(0,a8)==null?B.Up:A.MR(A.Bt(b0.WH(0,a8)))
a2=A.cU(b0.WH(0,"turnTimeLimitSeconds"))
a2=a2==null?a4:B.CD.yu(a2)
a3=A.M4(b0.WH(0,"requireLastCardDeclaration"))
return new A.k7(t,q,o,n!==!1,m!==!1,l===!0,k!==!1,j!==!1,i,h!==!1,g!==!1,f!==!1,e,d!==!1,c,b===!0,a,a0,a1,a2,a3!==!1,p)},
Ie(a){var t
A:{if(B.Mf===a){t="ace"
break A}if(B.GO===a){t="two"
break A}if(B.VV===a){t="three"
break A}if(B.S8===a){t="four"
break A}if(B.mh===a){t="five"
break A}if(B.pc===a){t="six"
break A}if(B.Sp===a){t="seven"
break A}t=a.b
break A}return t},
z0:function z0(a,b){this.a=a
this.b=b},
Nc:function Nc(a){this.a=a},
YA:function YA(){},
uj:function uj(a,b){this.a=a
this.b=b},
Sq:function Sq(a){this.a=a},
o2:function o2(){},
Sv:function Sv(a,b){this.a=a
this.b=b},
LF:function LF(a){this.a=a},
QW:function QW(){},
Br:function Br(a,b){this.a=a
this.b=b},
Ff:function Ff(a){this.a=a},
Ij:function Ij(){},
k7:function k7(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,a0,a1){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o
_.ay=p
_.ch=q
_.CW=r
_.cx=s
_.cy=t
_.db=a0
_.dx=a1},
kS(a){return B.Nm.Qk(B.i1,new A.ZL(a),new A.Ko())},
B8(a){return B.Nm.Qk(B.bP,new A.Aj(a),new A.WB(a))},
ab(a,b,c,d,e,f,g,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6){var t,s,r,q,p,o,n,m=A.AF(b4,u.u),l=u.U,k=A.AF(a0,l),j=A.AF(g,l),i=b9==null?A.Nq(0,0,0,B.Dx,0,0,B.WD,B.WD,0):b9,h=A.AF(a5,u.n)
l=A.AF(b3,l)
t=u.N
s=A.ax(a2,t,u.S)
r=u.z
r=A.Fl(r,r)
for(q=c5.gPu(),q=q.gkz(q);q.G();){p=q.gl()
o=p.a
n=A.PW(p.b,!1,t)
n.$flags=3
r.Y(0,o,n)}return new A.cw(a3,b0,b7,m,b5,d,e,f,k,j,a,b2,b,c0,c6,b6,c2,a4,b1,a8,a1,a7,c4,c3,c1,b8,a6,c,i,h,l,s,A.ax(r,t,u.a),a9)},
ac(c2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6=null,b7="drawPile",b8="drawnCard",b9=new A.kj(),c0=u.g,c1=c0.a(c2.WH(0,"players"))
if(c1==null)c1=B.dn
t=A.t6(c1)
s=t.C("A8<1,Ee>")
r=A.ev(new A.A8(c1,t.C("Ee(1)").a(new A.da()),s),s.C("aL.E"))
if(r.length<2)throw A.b(B.Qd)
c1=A.t6(r)
if(new A.A8(r,c1.C("qU(1)").a(new A.Lr()),c1.C("A8<1,qU>")).zH(0).a!==r.length)throw A.b(B.fi)
q=b9.$1(c2.WH(0,"discardPile"))
if(q.length===0)throw A.b(B.WG)
c1=A.cU(c2.WH(0,"currentSeat"))
p=c1==null?b6:B.CD.yu(c1)
if(p==null)p=0
if(p<0||p>=r.length)throw A.b(B.OB)
c1=A.cU(c2.WH(0,"dealerSeat"))
o=c1==null?b6:B.CD.yu(c1)
if(o==null)o=0
n=o>=0&&o<r.length?o:0
m=c2.WH(0,"activeSuit")
if(typeof m!="string")throw A.b(B.N7)
l=c2.WH(0,"lastAction")
k=c2.WH(0,"lastRoundResult")
c1=A.k(c2.WH(0,"gameId"))
if(c1==null)c1=""
t=A.k(c2.WH(0,"mode"))
t=A.kS(t==null?"vsComputer":t)
s=u.V
j=s.a(c2.WH(0,"rules"))
j=j==null?b6:j.tY(0,u.N,u.z)
if(j==null)j=B.CM
i=A.cU(c2.WH(0,"schema"))
i=i==null?b6:B.CD.yu(i)
j=A.L8(A.R0(j,i==null?1:i))
i=A.cU(c2.WH(0,"round"))
i=i==null?b6:B.CD.yu(i)
if(i==null)i=1
h=A.k(c2.WH(0,"direction"))
h=A.MR(h==null?"clockwise":h)
g=b9.$1(c2.WH(0,b7))
f=A.yZ(m)
e=A.cU(c2.WH(0,"pendingDrawCount"))
e=e==null?b6:B.CD.yu(e)
if(e==null)e=0
d=A.cU(c2.WH(0,"chainLength"))
d=d==null?b6:B.CD.yu(d)
if(d==null)d=0
c=A.k(c2.WH(0,"status"))
c=A.B8(c==null?"awaitingAction":c)
b=A.k(c2.WH(0,"winnerId"))
a=A.k(c2.WH(0,"roundWinnerId"))
a0=A.cU(c2.WH(0,"turnNumber"))
a0=a0==null?b6:B.CD.yu(a0)
if(a0==null)a0=0
a1=A.M4(c2.WH(0,"hasDrawnThisTurn"))
a2=A.M4(c2.WH(0,"penaltyResolvedThisTurn"))
a3=A.k(c2.WH(0,"lastCardDeclaredBy"))
a4=c2.WH(0,b8)==null?b6:A.SZ(c2.WH(0,b8))
a5=u.f
a6=a5.b(l)?A.aF(l.tY(0,u.N,u.z)):b6
a7=A.cU(c2.WH(0,"version"))
a7=a7==null?b6:B.CD.yu(a7)
if(a7==null)a7=0
a8=A.cU(c2.WH(0,"turnStartedAt"))
a8=a8==null?b6:B.CD.yu(a8)
a9=A.cU(c2.WH(0,"turnDeadlineAt"))
a9=a9==null?b6:B.CD.yu(a9)
b0=A.cU(c2.WH(0,"seed"))
b0=b0==null?b6:B.CD.yu(b0)
if(b0==null)b0=0
b1=A.M4(c2.WH(0,"isDailyChallenge"))
if(u.j.b(c2.WH(0,b7)))b2=b6
else{b2=A.cU(c2.WH(0,"drawPileCount"))
b2=b2==null?b6:B.CD.yu(b2)}b3=s.a(c2.WH(0,"stats"))
b3=b3==null?b6:b3.tY(0,u.N,u.z)
b3=A.G0(b3==null?B.CM:b3)
c0=c0.a(c2.WH(0,"history"))
if(c0==null)c0=B.dn
b4=A.t6(c0)
b5=b4.C("A8<1,pO>")
c0=A.ev(new A.A8(c0,b4.C("pO(1)").a(new A.QU()),b5),b5.C("aL.E"))
b9=b9.$1(c2.WH(0,"playedCards"))
b4=s.a(c2.WH(0,"drawsByPlayer"))
if(b4==null)b4=B.WO
b5=u.N
b4=b4.eh(0,new A.Cp(),b5,u.S)
s=s.a(c2.WH(0,"voidSuits"))
if(s==null)s=B.WO
s=s.eh(0,new A.AU(),b5,u.a)
a5=a5.b(k)?A.cn(k.tY(0,b5,u.z)):b6
return A.ab(f,d,b2,p,n,h,q,g,a4,b4,c1,a1===!0,c0,b1===!0,a6,a3,a5,t,a2===!0,e,b9,r,i,a,j,b0,b3,c,a9,a0,a8,a7,s,b)},
R0(a,b){var t,s,r="scoreValues"
if(b>2)return a
t=a.WH(0,r)
if(!u.f.b(t))return a
if(!B.yY.gPu().rb(0,new A.FQ(t)))return a
s=A.qC(a,u.N,u.z)
s.Rz(0,r)
return s},
kQ:function kQ(a,b){this.a=a
this.b=b},
ZL:function ZL(a){this.a=a},
Ko:function Ko(){},
am:function am(a,b){this.a=a
this.b=b},
Aj:function Aj(a){this.a=a},
WB:function WB(a){this.a=a},
cw:function cw(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o
_.ay=p
_.ch=q
_.CW=r
_.cx=s
_.cy=t
_.db=a0
_.dx=a1
_.dy=a2
_.fr=a3
_.fx=a4
_.fy=a5
_.go=a6
_.id=a7
_.k1=a8
_.k2=a9
_.k3=b0
_.k4=b1
_.ok=b2
_.p1=b3},
Wn:function Wn(a){this.a=a},
yt:function yt(){},
ZT:function ZT(){},
wp:function wp(){},
zU:function zU(){},
dQ:function dQ(){},
EG:function EG(){},
kj:function kj(){},
On:function On(){},
da:function da(){},
Lr:function Lr(){},
QU:function QU(){},
Cp:function Cp(){},
AU:function AU(){},
n8:function n8(){},
FQ:function FQ(a){this.a=a},
SV(a){var t,s,r=B.Nm.Qk(B.hL,new A.T2(a),new A.zF()),q=A.k(a.WH(0,"p"))
if(q==null)q=""
t=a.WH(0,"c")==null?null:A.D0(A.Bt(a.WH(0,"c")))
s=A.cU(a.WH(0,"n"))
s=s==null?null:B.CD.yu(s)
return new A.pO(r,q,t,s,a.WH(0,"s")==null?null:A.yZ(A.Bt(a.WH(0,"s"))))},
eZ:function eZ(a,b){this.a=a
this.b=b},
pO:function pO(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
T2:function T2(a){this.a=a},
zF:function zF(){},
Nq(a,b,c,d,e,f,g,h,i){var t,s,r,q,p=u.N,o=u.S,n=A.ax(g,p,o),m=u.z
m=A.Fl(m,m)
for(t=d.gPu(),t=t.gkz(t);t.G();){s=t.gl()
r=s.a
q=A.PW(s.b,!1,p)
q.$flags=3
m.Y(0,r,q)}return new A.YS(c,a,i,e,f,b,n,A.ax(m,p,u.a),A.ax(h,p,o))},
G0(a){var t,s,r,q,p,o,n,m,l,k,j=null,i=A.cU(a.WH(0,"cardsPlayed"))
i=i==null?j:B.CD.yu(i)
if(i==null)i=0
t=A.cU(a.WH(0,"acesPlayed"))
t=t==null?j:B.CD.yu(t)
if(t==null)t=0
s=A.cU(a.WH(0,"twosPlayed"))
s=s==null?j:B.CD.yu(s)
if(s==null)s=0
r=A.cU(a.WH(0,"longestChain"))
r=r==null?j:B.CD.yu(r)
if(r==null)r=0
q=A.cU(a.WH(0,"resets101"))
q=q==null?j:B.CD.yu(q)
if(q==null)q=0
p=A.cU(a.WH(0,"bestComeback"))
p=p==null?j:B.CD.yu(p)
if(p==null)p=0
o=u.V
n=o.a(a.WH(0,"roundsWon"))
if(n==null)n=B.WO
m=u.N
l=u.S
n=n.eh(0,new A.GH(),m,l)
k=o.a(a.WH(0,"cavalloSuits"))
if(k==null)k=B.WO
k=k.eh(0,new A.Pe(),m,u.a)
o=o.a(a.WH(0,"suitsPlayed"))
if(o==null)o=B.WO
return A.Nq(t,p,i,k,r,q,n,o.eh(0,new A.us(),m,l),s)},
YS:function YS(a,b,c,d,e,f,g,h,i){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i},
GH:function GH(){},
Pe:function Pe(){},
DC:function DC(){},
us:function us(){},
VG(a){return B.Nm.Qk(B.ej,new A.LL(a),new A.JX())},
mX(a){return B.Nm.Qk(B.pP,new A.JA(a),new A.Bv())},
X1(a){return B.Nm.Qk(B.TL,new A.mc(a),new A.qa())},
j6:function j6(a,b){this.a=a
this.b=b},
LL:function LL(a){this.a=a},
JX:function JX(){},
P6:function P6(a,b){this.a=a
this.b=b},
JA:function JA(a){this.a=a},
Bv:function Bv(){},
Y8:function Y8(a,b){this.a=a
this.b=b},
mc:function mc(a){this.a=a},
qa:function qa(){},
cn(a){var t,s,r=B.CD.yu(A.z5(a.WH(0,"roundNumber"))),q=A.Bt(a.WH(0,"winnerId")),p=A.Bt(a.WH(0,"winnerName")),o=u.g.a(a.WH(0,"rows"))
if(o==null)o=B.dn
t=A.t6(o)
s=t.C("A8<1,cJ>")
o=A.ev(new A.A8(o,t.C("cJ(1)").a(new A.iO()),s),s.C("aL.E"))
t=A.M4(a.WH(0,"matchOver"))
return new A.HO(r,q,p,o,t===!0,A.k(a.WH(0,"matchWinnerId")))},
cJ:function cJ(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
HO:function HO(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
DR:function DR(){},
iO:function iO(){},
uR(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=null
try{t=u.P.a(B.Ct.p(a,e))
s=A.QI([],u.R)
for(l=u.j.a(J.Kg(t,"players")),k=l.length,j=u.f,i=u.N,h=u.z,g=0;g<l.length;l.length===k||(0,A.lk)(l),++g){r=l[g]
J.Wo(s,A.Y1(j.a(r).tY(0,i,h)))}q=s
s=u.V.a(J.Kg(t,"rules"))
p=A.L8((s==null?B.WO:s).tY(0,i,h))
s=A.Bt(J.Kg(t,"gameId"))
l=A.k(J.Kg(t,"mode"))
l=A.kS(l==null?"passAndPlay":l)
k=B.CD.yu(A.z5(J.Kg(t,"seed")))
j=A.cU(J.Kg(t,"startingSeat"))
j=j==null?e:B.CD.yu(j)
if(j==null)j=0
h=A.cU(J.Kg(t,"now"))
h=h==null?e:B.CD.yu(h)
o=B.Zt.r2(s,l,h,q,p,k,j)
i=B.Ct.O(A.EF(["ok",!0,"state",o.Lt()],i,u.K),e)
return i}catch(f){s=A.Ru(f)
if(s instanceof A.xk){n=s
return B.Ct.O(A.EF(["ok",!1,"failure",n.a.b,"message",n.b],u.N,u.K),e)}else if(s instanceof A.aE){m=s
return B.Ct.O(A.EF(["ok",!1,"failure","invalidState","message",m.a],u.N,u.K),e)}else throw f}},
Fw(a,b,c){var t,s,r,q,p,o,n,m,l=null,k=null,j=null
try{s=u.P
k=A.ac(s.a(B.Ct.p(a,l)))
j=A.aF(s.a(B.Ct.p(b,l)))}catch(r){s=A.Ru(r)
if(s instanceof A.aE){t=s
return B.Ct.O(A.EF(["ok",!1,"failure","invalidState","message",t.a],u.N,u.K),l)}else throw r}q=B.Zt.vv(k,j,c)
A:{if(q instanceof A.dK){p=q.b
s=q.a.Lt()
o=A.QI([],u.s)
for(n=p.length,m=0;m<n;++m)o.push(A.vL(p[m]))
s=B.Ct.O(A.EF(["ok",!0,"state",s,"events",o],u.N,u.K),l)
break A}if(q instanceof A.KY){s=B.Ct.O(A.EF(["ok",!1,"failure",q.a.b],u.N,u.K),l)
break A}s=l}return s},
cA(a,b){var t,s,r,q,p,o=null
try{q=u.P
t=A.ac(q.a(B.Ct.p(a,o)))
s=A.aF(q.a(B.Ct.p(b,o)))
q=B.Zt.W(t,s)
q=B.Ct.O(A.EF(["failure",q==null?o:q.b],u.N,u.x),o)
return q}catch(p){q=A.Ru(p)
if(q instanceof A.aE){r=q
q=u.N
return B.Ct.O(A.EF(["failure","invalidState","message",r.a],q,q),o)}else throw p}},
YB(a,b){var t,s,r,q,p,o,n,m,l,k,j,i,h,g=null
try{t=A.ac(u.P.a(B.Ct.p(a,g)))
if(t.at!==B.qg){o=t
n=o.d
o=o.f
if(!(o>=0&&o<n.length))return A.OH(n,o)
m=n[o].a===b}else m=!1
s=m
r=A.QI([],u.s)
for(o=B.Zt.F(t,b),n=o.length,l=0;l<o.length;o.length===n||(0,A.lk)(o),++l){q=o[l]
k=q
J.Wo(r,k.a.b+"_"+k.b.b)}if(s){o=u.A.a(t)
n=o.d
k=o.f
if(!(k>=0&&k<n.length))return A.OH(n,k)
k=B.Zt.W(o,new A.N3(n[k].a,g))==null
o=k}else o=!1
if(s){n=u.A.a(t)
k=n.d
j=n.f
if(!(j>=0&&j<k.length))return A.OH(k,j)
j=B.Zt.W(n,new A.ew(k[j].a,g))==null
n=j}else n=!1
k=!1
if(s){j=u.A.a(t)
if(j.at===B.vc)if(j.Q>0){k=j.d
i=j.f
if(!(i>=0&&i<k.length))return A.OH(k,i)
i=B.Zt.F(j,k[i].a).length===0
k=i}}k=B.Ct.O(A.EF(["cards",r,"canDraw",o,"canPass",n,"mustTakePenalty",k],u.N,u.K),g)
return k}catch(h){r=A.Ru(h)
if(r instanceof A.aE){p=r
r=u.N
return B.Ct.O(A.EF(["failure","invalidState","message",p.a],r,r),g)}else throw h}},
E2(){var t,s,r="Attempting to rewrap a JS function.",q=v.G,p=new A.e()
if(typeof p=="function")A.v(A.q(r))
t=function(a,b){return function(c){return a(b,c,arguments.length)}}(A.K,p)
s=$.C()
t[s]=p
q.gioco101CreateGame=t
p=new A.L()
if(typeof p=="function")A.v(A.q(r))
t=function(a,b){return function(c,d,e){return a(b,c,d,e,arguments.length)}}(A.w,p)
t[s]=p
q.gioco101ApplyAction=t
q.gioco101Validate=A.F(new A.em())
q.gioco101Playable=A.F(new A.Lb())
p=new A.QA()
if(typeof p=="function")A.v(A.q(r))
t=function(a,b){return function(){return a(b)}}(A.D,p)
t[s]=p
q.gioco101EngineVersion=t},
e:function e(){},
L:function L(){},
em:function em(){},
Lb:function Lb(){},
QA:function QA(){},
pR(a){throw A.x(new A.n("Field '"+a+"' has been assigned during initialization."),new Error())},
F(a){var t
if(typeof a=="function")throw A.b(A.q("Attempting to rewrap a JS function."))
t=function(b,c){return function(d,e){return b(c,d,e,arguments.length)}}(A.Ib,a)
t[$.C()]=a
return t},
D(a){return u.Z.a(a).$0()},
K(a,b,c){u.Z.a(a)
if(A.IZ(c)>=1)return a.$1(b)
return a.$0()},
Ib(a,b,c,d){u.Z.a(a)
A.IZ(d)
if(d>=2)return a.$2(b,c)
if(d===1)return a.$1(b)
return a.$0()},
w(a,b,c,d,e){u.Z.a(a)
A.IZ(e)
if(e>=3)return a.$3(b,c,d)
if(e===2)return a.$2(b,c)
if(e===1)return a.$1(b)
return a.$0()},
tJ(a,b){var t,s,r,q
for(t=a.length-1;t>0;--t){s=b.j1(t+1)
r=a.length
if(!(t<r))return A.OH(a,t)
q=a[t]
if(!(s>=0&&s<r))return A.OH(a,s)
a[t]=a[s]
a[s]=q}return a}},B={}
var w=[A,J,B]
var $={}
A.FK.prototype={}
J.vB.prototype={
DN(a,b){return a===b},
giO(a){return A.eQ(a)},
"["(a){return"Instance of '"+A.lh(a)+"'"},
gbx(a){return A.Kx(A.VU(this))}}
J.yE.prototype={
"["(a){return String(a)},
giO(a){return a?519018:218159},
gbx(a){return A.Kx(u.y)},
$iy5:1,
$ia0:1}
J.CD.prototype={
DN(a,b){return null==b},
"["(a){return"null"},
giO(a){return 0},
$iy5:1}
J.MF.prototype={$ivm:1}
J.zh.prototype={
giO(a){return 0},
gbx(a){return B.Nu},
"["(a){return String(a)}}
J.iC.prototype={}
J.kd.prototype={}
J.c5.prototype={
"["(a){var t=a[$.wQ()]
if(t==null)t=a[$.C()]
if(t==null)return this.u(a)
return"JavaScript function for "+J.a3(t)},
$ifK:1}
J.jd.prototype={
i(a,b){A.t6(a).c.a(b)
a.$flags&1&&A.cW(a,29)
a.push(b)},
Rz(a,b){var t
a.$flags&1&&A.cW(a,"remove",1)
for(t=0;t<a.length;++t)if(J.cf(a[t],b)){a.splice(t,1)
return!0}return!1},
A(a,b){A.t6(a).C("cX<1>").a(b)
a.$flags&1&&A.cW(a,"addAll",2)
this.Kh(a,b)
return},
Kh(a,b){var t,s
u.o.a(b)
t=b.length
if(t===0)return
if(a===b)throw A.b(A.a4(a))
for(s=0;s<t;++s)a.push(b[s])},
N0(a,b,c,d){var t,s,r
d.a(b)
A.t6(a).K(d).C("1(1,2)").a(c)
t=a.length
for(s=b,r=0;r<t;++r){s=c.$2(s,a[r])
if(a.length!==t)throw A.b(A.a4(a))}return s},
Qk(a,b,c){var t,s,r,q=A.t6(a)
q.C("a0(1)").a(b)
q.C("1()?").a(c)
t=a.length
for(s=0;s<t;++s){r=a[s]
if(b.$1(r))return r
if(a.length!==t)throw A.b(A.a4(a))}q=c.$0()
return q},
Zv(a,b){if(!(b<a.length))return A.OH(a,b)
return a[b]},
aM(a,b,c){if(b<0||b>a.length)throw A.b(A.TE(b,0,a.length,"start",null))
if(c==null)c=a.length
else if(c<b||c>a.length)throw A.b(A.TE(c,b,a.length,"end",null))
if(b===c)return A.QI([],A.t6(a))
return A.QI(a.slice(b,c),A.t6(a))},
Jk(a,b){return this.aM(a,b,null)},
gFV(a){if(a.length>0)return a[0]
throw A.b(A.Wp())},
grZ(a){var t=a.length
if(t>0)return a[t-1]
throw A.b(A.Wp())},
Vr(a,b){var t,s
A.t6(a).C("a0(1)").a(b)
t=a.length
for(s=0;s<t;++s){if(b.$1(a[s]))return!0
if(a.length!==t)throw A.b(A.a4(a))}return!1},
tg(a,b){var t
for(t=0;t<a.length;++t)if(J.cf(a[t],b))return!0
return!1},
gl0(a){return a.length===0},
"["(a){return A.tA(a,"[","]")},
gkz(a){return new J.m1(a,a.length,A.t6(a).C("m1<1>"))},
giO(a){return A.eQ(a)},
gkF(a){return a.length},
Y(a,b,c){A.t6(a).c.a(c)
a.$flags&2&&A.cW(a)
if(!(b>=0&&b<a.length))throw A.b(A.HY(a,b))
a[b]=c},
aT(a,b){var t
A.t6(a).C("a0(1)").a(b)
if(0>=a.length)return-1
for(t=0;t<a.length;++t)if(b.$1(a[t]))return t
return-1},
WN(a,b){var t,s
A.t6(a).C("a0(1)").a(b)
t=a.length-1
if(t<0)return-1
for(s=t;s>=0;--s){if(!(s<a.length))return A.OH(a,s)
if(b.$1(a[s]))return s}return-1},
gbx(a){return A.Kx(A.t6(a))},
$ibQ:1,
$icX:1,
$izM:1}
J.BC.prototype={
R(a){var t,s,r
if(!Array.isArray(a))return null
t=a.$flags|0
if((t&4)!==0)s="const, "
else if((t&2)!==0)s="unmodifiable, "
else s=(t&1)!==0?"fixed, ":""
r="Instance of '"+A.lh(a)+"'"
if(s==="")return r
return r+" ("+s+"length: "+a.length+")"}}
J.Po.prototype={}
J.m1.prototype={
gl(){var t=this.d
return t==null?this.$ti.c.a(t):t},
G(){var t,s=this,r=s.a,q=r.length
if(s.b!==q){r=A.lk(r)
throw A.b(r)}t=s.c
if(t>=q){s.d=null
return!1}s.d=r[t]
s.c=t+1
return!0},
$iAn:1}
J.qI.prototype={
yu(a){var t
if(a>=-2147483648&&a<=2147483647)return a|0
if(isFinite(a)){t=a<0?Math.ceil(a):Math.floor(a)
return t+0}throw A.b(A.u0(""+a+".toInt()"))},
"["(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
giO(a){var t,s,r,q,p=a|0
if(a===p)return p&536870911
t=Math.abs(a)
s=Math.log(t)/0.6931471805599453|0
r=Math.pow(2,s)
q=t<1?t/r:r/t
return((q*9007199254740992|0)+(q*3542243181176521|0))*599197+s*1259&536870911},
h(a,b){var t=a%b
if(t===0)return 0
if(t>0)return t
return t+b},
B(a,b){return(a|0)===a?a/b|0:this.P(a,b)},
P(a,b){var t=a/b
if(t>=-2147483648&&t<=2147483647)return t|0
if(t>0){if(t!==1/0)return Math.floor(t)}else if(t>-1/0)return Math.ceil(t)
throw A.b(A.u0("Result of truncating division is "+A.J(t)+": "+A.J(a)+" ~/ "+b))},
wG(a,b){var t
if(a>0)t=this.Uh(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
Uh(a,b){return b>31?0:a>>>b},
gbx(a){return A.Kx(u.H)},
$iCP:1,
$ilf:1}
J.im.prototype={
gbx(a){return A.Kx(u.S)},
$iy5:1,
$iKN:1}
J.kD.prototype={
gbx(a){return A.Kx(u.i)},
$iy5:1}
J.Dr.prototype={
Nj(a,b,c){return a.substring(b,A.jB(b,c,a.length))},
"["(a){return a},
giO(a){var t,s,r
for(t=a.length,s=0,r=0;r<t;++r){s=s+a.charCodeAt(r)&536870911
s=s+((s&524287)<<10)&536870911
s^=s>>6}s=s+((s&67108863)<<3)&536870911
s^=s>>11
return s+((s&16383)<<15)&536870911},
gbx(a){return A.Kx(u.N)},
gkF(a){return a.length},
$iy5:1,
$iqU:1}
A.BR.prototype={
gkz(a){var t=this.a
return new A.Cf(t.gkz(t),A.Lh(this).C("Cf<1,2>"))},
gkF(a){var t=this.a
return t.gkF(t)},
gl0(a){var t=this.a
return t.gl0(t)},
tg(a,b){return this.a.tg(0,b)},
"["(a){return this.a["["](0)}}
A.Cf.prototype={
G(){return this.a.G()},
gl(){return this.$ti.y[1].a(this.a.gl())},
$iAn:1}
A.Zy.prototype={}
A.ol.prototype={$ibQ:1}
A.by.prototype={
tY(a,b,c){return new A.by(this.a,this.$ti.C("@<1,2>").K(b).K(c).C("by<1,2,3,4>"))},
NZ(a){return this.a.NZ(a)},
WH(a,b){return this.$ti.C("4?").a(this.a.WH(0,b))},
U(a,b){this.a.U(0,new A.aA(this,this.$ti.C("~(3,4)").a(b)))},
gv(){var t=this.$ti
return A.GJ(this.a.gv(),t.c,t.y[2])},
gUQ(){var t=this.$ti
return A.GJ(this.a.gUQ(),t.y[1],t.y[3])},
gkF(a){var t=this.a
return t.gkF(t)},
gl0(a){var t=this.a
return t.gl0(t)},
gPu(){return this.a.gPu().E2(0,new A.oB(this),this.$ti.C("Yh<3,4>"))}}
A.aA.prototype={
$2(a,b){var t=this.a.$ti
t.c.a(a)
t.y[1].a(b)
this.b.$2(t.y[2].a(a),t.y[3].a(b))},
$S(){return this.a.$ti.C("~(1,2)")}}
A.oB.prototype={
$1(a){var t=this.a.$ti
t.C("Yh<1,2>").a(a)
return new A.Yh(t.y[2].a(a.a),t.y[3].a(a.b),t.C("Yh<3,4>"))},
$S(){return this.a.$ti.C("Yh<3,4>(Yh<1,2>)")}}
A.n.prototype={
"["(a){return"LateInitializationError: "+this.a}}
A.zl.prototype={}
A.bQ.prototype={}
A.aL.prototype={
gkz(a){var t=this
return new A.a7(t,t.gkF(t),A.Lh(t).C("a7<aL.E>"))},
gl0(a){return this.gkF(this)===0},
tg(a,b){var t,s=this,r=s.gkF(s)
for(t=0;t<r;++t){if(J.cf(s.Zv(0,t),b))return!0
if(r!==s.gkF(s))throw A.b(A.a4(s))}return!1},
rb(a,b){var t,s,r=this
A.Lh(r).C("a0(aL.E)").a(b)
t=r.gkF(r)
for(s=0;s<t;++s){if(!b.$1(r.Zv(0,s)))return!1
if(t!==r.gkF(r))throw A.b(A.a4(r))}return!0},
E2(a,b,c){var t=A.Lh(this)
return new A.A8(this,t.K(c).C("1(aL.E)").a(b),t.C("@<aL.E>").K(c).C("A8<1,2>"))},
zH(a){var t,s=this,r=A.Ls(A.Lh(s).C("aL.E"))
for(t=0;t<s.gkF(s);++t)r.i(0,s.Zv(0,t))
return r}}
A.a7.prototype={
gl(){var t=this.d
return t==null?this.$ti.c.a(t):t},
G(){var t,s=this,r=s.a,q=r.gkF(r)
if(s.b!==q)throw A.b(A.a4(r))
t=s.c
if(t>=q){s.d=null
return!1}s.d=r.Zv(0,t);++s.c
return!0},
$iAn:1}
A.i1.prototype={
gkz(a){return new A.MH(J.x5(this.a),this.b,A.Lh(this).C("MH<1,2>"))},
gkF(a){return J.aX(this.a)},
gl0(a){return J.Md(this.a)}}
A.xy.prototype={$ibQ:1}
A.MH.prototype={
G(){var t=this,s=t.b
if(s.G()){t.a=t.c.$1(s.gl())
return!0}t.a=null
return!1},
gl(){var t=this.a
return t==null?this.$ti.y[1].a(t):t},
$iAn:1}
A.A8.prototype={
gkF(a){return J.aX(this.a)},
Zv(a,b){return this.b.$1(J.kg(this.a,b))}}
A.oi.prototype={
gkz(a){var t=this.a
return new A.SO(new J.m1(t,t.length,A.t6(t).C("m1<1>")),this.b,this.$ti.C("SO<1>"))}}
A.SO.prototype={
G(){var t,s,r,q
for(t=this.a,s=this.b,r=t.$ti.c;t.G();){q=t.d
if(s.$1(q==null?r.a(q):q))return!0}return!1},
gl(){var t=this.a,s=t.d
return s==null?t.$ti.c.a(s):s},
$iAn:1}
A.LN.prototype={$r:"+(1,2)",$s:1}
A.PD.prototype={}
A.ys.prototype={
tY(a,b,c){var t=A.Lh(this)
return A.bE(this,t.c,t.y[1],b,c)},
gl0(a){return this.gkF(this)===0},
"["(a){return A.nO(this)},
gPu(){return new A.q4(this.q4(),A.Lh(this).C("q4<Yh<1,2>>"))},
q4(){var t=this
return function(){var s=0,r=1,q=[],p,o,n,m,l
return function $async$gPu(a,b,c){if(b===1){q.push(c)
s=r}for(;;)switch(s){case 0:p=t.gv(),p=p.gkz(p),o=A.Lh(t),n=o.y[1],o=o.C("Yh<1,2>")
case 2:if(!p.G()){s=3
break}m=p.gl()
l=t.WH(0,m)
s=4
return a.b=new A.Yh(m,l==null?n.a(l):l,o),1
case 4:s=2
break
case 3:return 0
case 1:return a.c=q.at(-1),3}}}},
eh(a,b,c,d){var t=A.Fl(c,d)
this.U(0,new A.hN(this,A.Lh(this).K(c).K(d).C("Yh<1,2>(3,4)").a(b),t))
return t},
$iT8:1}
A.hN.prototype={
$2(a,b){var t=A.Lh(this.a),s=this.b.$2(t.c.a(a),t.y[1].a(b))
this.c.Y(0,s.a,s.b)},
$S(){return A.Lh(this.a).C("~(1,2)")}}
A.LP.prototype={
gkF(a){return this.b.length},
gM(){var t=this.$keys
if(t==null){t=Object.keys(this.a)
this.$keys=t}return t},
NZ(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
WH(a,b){if(!this.NZ(b))return null
return this.b[this.a[b]]},
U(a,b){var t,s,r,q
this.$ti.C("~(1,2)").a(b)
t=this.gM()
s=this.b
for(r=t.length,q=0;q<r;++q)b.$2(t[q],s[q])},
gv(){return new A.Ku(this.gM(),this.$ti.C("Ku<1>"))},
gUQ(){return new A.Ku(this.b,this.$ti.C("Ku<2>"))}}
A.Ku.prototype={
gkF(a){return this.a.length},
gl0(a){return 0===this.a.length},
gkz(a){var t=this.a
return new A.vI(t,t.length,this.$ti.C("vI<1>"))}}
A.vI.prototype={
gl(){var t=this.d
return t==null?this.$ti.c.a(t):t},
G(){var t=this,s=t.c
if(s>=t.b){t.d=null
return!1}t.d=t.a[s]
t.c=s+1
return!0},
$iAn:1}
A.kz.prototype={
Ag(){var t=this,s=t.$map
if(s==null){s=new A.cL(t.$ti.C("cL<1,2>"))
A.B7(t.a,s)
t.$map=s}return s},
NZ(a){return this.Ag().NZ(a)},
WH(a,b){return this.Ag().WH(0,b)},
U(a,b){this.$ti.C("~(1,2)").a(b)
this.Ag().U(0,b)},
gv(){var t=this.Ag()
return new A.Gp(t,A.Lh(t).C("Gp<1>"))},
gUQ(){var t=this.Ag()
return new A.GP(t,A.Lh(t).C("GP<2>"))},
gkF(a){return this.Ag().a}}
A.rY.prototype={}
A.Zr.prototype={
qS(a){var t,s,r=this,q=new RegExp(r.a).exec(a)
if(q==null)return null
t=Object.create(null)
s=r.b
if(s!==-1)t.arguments=q[s+1]
s=r.c
if(s!==-1)t.argumentsExpr=q[s+1]
s=r.d
if(s!==-1)t.expr=q[s+1]
s=r.e
if(s!==-1)t.method=q[s+1]
s=r.f
if(s!==-1)t.receiver=q[s+1]
return t}}
A.W0.prototype={
"["(a){return"Null check operator used on a null value"}}
A.az.prototype={
"["(a){var t,s=this,r="NoSuchMethodError: method not found: '",q=s.b
if(q==null)return"NoSuchMethodError: "+s.a
t=s.c
if(t==null)return r+q+"' ("+s.a+")"
return r+q+"' on '"+t+"' ("+s.a+")"}}
A.vV.prototype={
"["(a){var t=this.a
return t.length===0?"Error":"Error: "+t}}
A.te.prototype={
"["(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.Tp.prototype={
"["(a){var t=this.constructor,s=t==null?null:t.name
return"Closure '"+A.NQ(s==null?"unknown":s)+"'"},
gbx(a){var t=A.JS(this)
return A.Kx(t==null?A.zK(this):t)},
$ifK:1,
gKu(){return this},
$C:"$1",
$R:1,
$D:null}
A.Ay.prototype={$C:"$0",$R:0}
A.E1.prototype={$C:"$2",$R:2}
A.lc.prototype={}
A.zx.prototype={
"["(a){var t=this.$static_name
if(t==null)return"Closure of unknown static method"
return"Closure '"+A.NQ(t)+"'"}}
A.rT.prototype={
DN(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.rT))return!1
return this.$_target===b.$_target&&this.a===b.a},
giO(a){return(A.CU(this.a)^A.eQ(this.$_target))>>>0},
"["(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.lh(this.a)+"'")}}
A.Eq.prototype={
"["(a){return"RuntimeError: "+this.a}}
A.N5.prototype={
gkF(a){return this.a},
gl0(a){return this.a===0},
gv(){return new A.Gp(this,A.Lh(this).C("Gp<1>"))},
gUQ(){return new A.GP(this,A.Lh(this).C("GP<2>"))},
gPu(){return new A.C5(this,A.Lh(this).C("C5<1,2>"))},
NZ(a){var t,s
if(typeof a=="string"){t=this.b
if(t==null)return!1
return t[a]!=null}else{s=this.CX(a)
return s}},
CX(a){var t=this.d
if(t==null)return!1
return this.X(t[this.xi(a)],a)>=0},
A(a,b){A.Lh(this).C("T8<1,2>").a(b).U(0,new A.EM(this))},
WH(a,b){var t,s,r,q,p=null
if(typeof b=="string"){t=this.b
if(t==null)return p
s=t[b]
r=s==null?p:s.b
return r}else if(typeof b=="number"&&(b&0x3fffffff)===b){q=this.c
if(q==null)return p
s=q[b]
r=s==null?p:s.b
return r}else return this.aa(b)},
aa(a){var t,s,r=this.d
if(r==null)return null
t=r[this.xi(a)]
s=this.X(t,a)
if(s<0)return null
return t[s].b},
Y(a,b,c){var t,s,r=this,q=A.Lh(r)
q.c.a(b)
q.y[1].a(c)
if(typeof b=="string"){t=r.b
r.m(t==null?r.b=r.j():t,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){s=r.c
r.m(s==null?r.c=r.j():s,b,c)}else r.T(b,c)},
T(a,b){var t,s,r,q,p=this,o=A.Lh(p)
o.c.a(a)
o.y[1].a(b)
t=p.d
if(t==null)t=p.d=p.j()
s=p.xi(a)
r=t[s]
if(r==null)t[s]=[p.x4(a,b)]
else{q=p.X(r,a)
if(q>=0)r[q].b=b
else r.push(p.x4(a,b))}},
Rz(a,b){var t=this.H4(this.b,b)
return t},
U(a,b){var t,s,r=this
A.Lh(r).C("~(1,2)").a(b)
t=r.e
s=r.r
while(t!=null){b.$2(t.a,t.b)
if(s!==r.r)throw A.b(A.a4(r))
t=t.c}},
m(a,b,c){var t,s=A.Lh(this)
s.c.a(b)
s.y[1].a(c)
t=a[b]
if(t==null)a[b]=this.x4(b,c)
else t.b=c},
H4(a,b){var t
if(a==null)return null
t=a[b]
if(t==null)return null
this.GS(t)
delete a[b]
return t.b},
GY(){this.r=this.r+1&1073741823},
x4(a,b){var t=this,s=A.Lh(t),r=new A.vh(s.c.a(a),s.y[1].a(b))
if(t.e==null)t.e=t.f=r
else{s=t.f
s.toString
r.d=s
t.f=s.c=r}++t.a
t.GY()
return r},
GS(a){var t=this,s=a.d,r=a.c
if(s==null)t.e=r
else s.c=r
if(r==null)t.f=s
else r.d=s;--t.a
t.GY()},
xi(a){return J.jg(a)&1073741823},
X(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.cf(a[s].a,b))return s
return-1},
"["(a){return A.nO(this)},
j(){var t=Object.create(null)
t["<non-identifier-key>"]=t
delete t["<non-identifier-key>"]
return t},
$iFo:1}
A.EM.prototype={
$2(a,b){var t=this.a,s=A.Lh(t)
t.Y(0,s.c.a(a),s.y[1].a(b))},
$S(){return A.Lh(this.a).C("~(1,2)")}}
A.vh.prototype={}
A.Gp.prototype={
gkF(a){return this.a.a},
gl0(a){return this.a.a===0},
gkz(a){var t=this.a
return new A.N6(t,t.r,t.e,this.$ti.C("N6<1>"))},
tg(a,b){return this.a.NZ(b)}}
A.N6.prototype={
gl(){return this.d},
G(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.b(A.a4(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.a
s.c=t.c
return!0}},
$iAn:1}
A.GP.prototype={
gkF(a){return this.a.a},
gl0(a){return this.a.a===0},
gkz(a){var t=this.a
return new A.Gf(t,t.r,t.e,this.$ti.C("Gf<1>"))}}
A.Gf.prototype={
gl(){return this.d},
G(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.b(A.a4(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=t.b
s.c=t.c
return!0}},
$iAn:1}
A.C5.prototype={
gkF(a){return this.a.a},
gl0(a){return this.a.a===0},
gkz(a){var t=this.a
return new A.HQ(t,t.r,t.e,this.$ti.C("HQ<1,2>"))}}
A.HQ.prototype={
gl(){var t=this.d
t.toString
return t},
G(){var t,s=this,r=s.a
if(s.b!==r.r)throw A.b(A.a4(r))
t=s.c
if(t==null){s.d=null
return!1}else{s.d=new A.Yh(t.a,t.b,s.$ti.C("Yh<1,2>"))
s.c=t.c
return!0}},
$iAn:1}
A.cL.prototype={
xi(a){return A.HP(a)&1073741823},
X(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.cf(a[s].a,b))return s
return-1}}
A.S5.prototype={
gbx(a){return A.Kx(this.J())},
J(){return A.Mi(this.$r,this.n())},
"["(a){return this.k(!1)},
k(a){var t,s,r,q,p,o=this.D(),n=this.n(),m=(a?"Record ":"")+"("
for(t=o.length,s="",r=0;r<t;++r,s=", "){m+=s
q=o[r]
if(typeof q=="string")m=m+q+": "
if(!(r<n.length))return A.OH(n,r)
p=n[r]
m=a?m+A.ik(p):m+A.J(p)}m+=")"
return m.charCodeAt(0)==0?m:m},
D(){var t,s=this.$s
while($.lb.length<=s)B.Nm.i($.lb,null)
t=$.lb[s]
if(t==null){t=this.t()
B.Nm.Y($.lb,s,t)}return t},
t(){var t,s,r,q=this.$r,p=q.indexOf("("),o=q.substring(1,p),n=q.substring(p),m=n==="()"?0:n.replace(/[^,]/g,"").length+1,l=A.QI(new Array(m),u.G)
for(t=0;t<m;++t)l[t]=t
if(o!==""){s=o.split(",")
t=s.length
for(r=m;t>0;){--r;--t
B.Nm.Y(l,r,s[t])}}return A.AF(l,u.K)}}
A.nz.prototype={
n(){return[this.a,this.b]},
DN(a,b){if(b==null)return!1
return b instanceof A.nz&&this.$s===b.$s&&J.cf(this.a,b.a)&&J.cf(this.b,b.b)},
giO(a){return A.f5(this.$s,this.a,this.b,B.zt,B.zt,B.zt,B.zt)}}
A.Jc.prototype={
C(a){return A.cE(v.typeUniverse,this,a)},
K(a){return A.v5(v.typeUniverse,this,a)}}
A.G.prototype={}
A.lY.prototype={
"["(a){return A.dm(this.a,null)}}
A.u9.prototype={
"["(a){return this.a}}
A.iM.prototype={}
A.GV.prototype={
gl(){var t=this.b
return t==null?this.$ti.c.a(t):t},
zI(a,b){var t,s,r
a=A.IZ(a)
b=b
t=this.a
for(;;)try{s=t(this,a,b)
return s}catch(r){b=r
a=1}},
G(){var t,s,r,q,p=this,o=null,n=0
for(;;){t=p.d
if(t!=null)try{if(t.G()){p.b=t.gl()
return!0}else p.d=null}catch(s){o=s
n=1
p.d=null}r=p.zI(n,o)
if(1===r)return!0
if(0===r){p.b=null
q=p.e
if(q==null||q.length===0){p.a=A.y7
return!1}if(0>=q.length)return A.OH(q,-1)
p.a=q.pop()
n=0
o=null
continue}if(2===r){n=0
o=null
continue}if(3===r){o=p.c
p.c=null
q=p.e
if(q==null||q.length===0){p.b=null
p.a=A.y7
throw o
return!1}if(0>=q.length)return A.OH(q,-1)
p.a=q.pop()
n=1
continue}throw A.b(A.PV("sync*"))}return!1},
eH(a){var t,s,r=this
if(a instanceof A.q4){t=a.a()
s=r.e
if(s==null)s=r.e=[]
B.Nm.i(s,r.a)
r.a=t
return 2}else{r.d=J.x5(a)
return 2}},
$iAn:1}
A.q4.prototype={
gkz(a){return new A.GV(this.a(),this.$ti.C("GV<1>"))}}
A.PZ.prototype={
gkz(a){var t=this,s=new A.lm(t,t.r,A.Lh(t).C("lm<1>"))
s.c=t.e
return s},
gkF(a){return this.a},
gl0(a){return this.a===0},
i(a,b){var t,s,r=this
A.Lh(r).c.a(b)
if(typeof b=="string"&&b!=="__proto__"){t=r.b
return r.cW(t==null?r.b=A.pq():t,b)}else if(typeof b=="number"&&(b&1073741823)===b){s=r.c
return r.cW(s==null?r.c=A.pq():s,b)}else return r.B7(b)},
B7(a){var t,s,r,q=this
A.Lh(q).c.a(a)
t=q.d
if(t==null)t=q.d=A.pq()
s=q.rk(a)
r=t[s]
if(r==null)t[s]=[q.dg(a)]
else{if(q.DF(r,a)>=0)return!1
r.push(q.dg(a))}return!0},
cW(a,b){A.Lh(this).c.a(b)
if(u.c8.a(a[b])!=null)return!1
a[b]=this.dg(b)
return!0},
dg(a){var t=this,s=new A.bn(A.Lh(t).c.a(a))
if(t.e==null)t.e=t.f=s
else t.f=t.f.b=s;++t.a
t.r=t.r+1&1073741823
return s},
rk(a){return J.jg(a)&1073741823},
DF(a,b){var t,s
if(a==null)return-1
t=a.length
for(s=0;s<t;++s)if(J.cf(a[s].a,b))return s
return-1}}
A.bn.prototype={}
A.lm.prototype={
gl(){var t=this.d
return t==null?this.$ti.c.a(t):t},
G(){var t=this,s=t.c,r=t.a
if(t.b!==r.r)throw A.b(A.a4(r))
else if(s==null){t.d=null
return!1}else{t.d=t.$ti.C("1?").a(s.a)
t.c=s.b
return!0}},
$iAn:1}
A.EH.prototype={
$2(a,b){this.a.Y(0,this.b.a(a),this.c.a(b))},
$S:17}
A.il.prototype={
tY(a,b,c){var t=A.Lh(this)
return A.bE(this,t.C("il.K"),t.C("il.V"),b,c)},
U(a,b){var t,s,r,q=A.Lh(this)
q.C("~(il.K,il.V)").a(b)
for(t=this.gv(),t=t.gkz(t),q=q.C("il.V");t.G();){s=t.gl()
r=this.WH(0,s)
b.$2(s,r==null?q.a(r):r)}},
gPu(){return this.gv().E2(0,new A.mb(this),A.Lh(this).C("Yh<il.K,il.V>"))},
eh(a,b,c,d){var t,s,r,q,p,o=A.Lh(this)
o.K(c).K(d).C("Yh<1,2>(il.K,il.V)").a(b)
t=A.Fl(c,d)
for(s=this.gv(),s=s.gkz(s),o=o.C("il.V");s.G();){r=s.gl()
q=this.WH(0,r)
p=b.$2(r,q==null?o.a(q):q)
t.Y(0,p.a,p.b)}return t},
NZ(a){return this.gv().tg(0,a)},
gkF(a){var t=this.gv()
return t.gkF(t)},
gl0(a){var t=this.gv()
return t.gl0(t)},
gUQ(){return new A.wU(this,A.Lh(this).C("wU<il.K,il.V>"))},
"["(a){return A.nO(this)},
$iT8:1}
A.mb.prototype={
$1(a){var t=this.a,s=A.Lh(t)
s.C("il.K").a(a)
t=t.WH(0,a)
if(t==null)t=s.C("il.V").a(t)
return new A.Yh(a,t,s.C("Yh<il.K,il.V>"))},
$S(){return A.Lh(this.a).C("Yh<il.K,il.V>(il.K)")}}
A.ra.prototype={
$2(a,b){var t,s=this.a
if(!s.a)this.b.a+=", "
s.a=!1
s=this.b
t=A.J(a)
s.a=(s.a+=t)+": "
t=A.J(b)
s.a+=t},
$S:5}
A.wU.prototype={
gkF(a){var t=this.a
return t.gkF(t)},
gl0(a){var t=this.a
return t.gl0(t)},
gkz(a){var t=this.a,s=t.gv()
return new A.Uq(s.gkz(s),t,this.$ti.C("Uq<1,2>"))}}
A.Uq.prototype={
G(){var t=this,s=t.a
if(s.G()){t.c=t.b.WH(0,s.gl())
return!0}t.c=null
return!1},
gl(){var t=this.c
return t==null?this.$ti.y[1].a(t):t},
$iAn:1}
A.KP.prototype={}
A.Pn.prototype={
tY(a,b,c){return this.a.tY(0,b,c)},
WH(a,b){return this.a.WH(0,b)},
NZ(a){return this.a.NZ(a)},
U(a,b){this.a.U(0,A.Lh(this).C("~(1,2)").a(b))},
gl0(a){var t=this.a
return t.gl0(t)},
gkF(a){var t=this.a
return t.gkF(t)},
gv(){return this.a.gv()},
"["(a){return this.a["["](0)},
gUQ(){return this.a.gUQ()},
gPu(){return this.a.gPu()},
eh(a,b,c,d){return this.a.eh(0,A.Lh(this).K(c).K(d).C("Yh<1,2>(3,4)").a(b),c,d)},
$iT8:1}
A.Gj.prototype={
tY(a,b,c){return new A.Gj(this.a.tY(0,b,c),b.C("@<0>").K(c).C("Gj<1,2>"))}}
A.Vj.prototype={
gl0(a){return this.a===0},
"["(a){return A.tA(this,"{","}")},
$ibQ:1,
$icX:1}
A.Xv.prototype={}
A.RU.prototype={}
A.uw.prototype={
WH(a,b){var t,s=this.b
if(s==null)return this.c.WH(0,b)
else if(typeof b!="string")return null
else{t=s[b]
return typeof t=="undefined"?this.fb(b):t}},
gkF(a){return this.b==null?this.c.a:this.Cf().length},
gl0(a){return this.gkF(0)===0},
gv(){if(this.b==null){var t=this.c
return new A.Gp(t,A.Lh(t).C("Gp<1>"))}return new A.i8(this)},
gUQ(){var t,s=this
if(s.b==null){t=s.c
return new A.GP(t,A.Lh(t).C("GP<2>"))}return A.K1(s.Cf(),new A.FE(s),u.N,u.z)},
NZ(a){if(this.b==null)return this.c.NZ(a)
if(typeof a!="string")return!1
return Object.prototype.hasOwnProperty.call(this.a,a)},
U(a,b){var t,s,r,q,p=this
u.cQ.a(b)
if(p.b==null)return p.c.U(0,b)
t=p.Cf()
for(s=0;s<t.length;++s){r=t[s]
q=p.b[r]
if(typeof q=="undefined"){q=A.Qe(p.a[r])
p.b[r]=q}b.$2(r,q)
if(t!==p.c)throw A.b(A.a4(p))}},
Cf(){var t=u.g.a(this.c)
if(t==null)t=this.c=A.QI(Object.keys(this.a),u.s)
return t},
fb(a){var t
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
t=A.Qe(this.a[a])
return this.b[a]=t}}
A.FE.prototype={
$1(a){return this.a.WH(0,A.Bt(a))},
$S:11}
A.i8.prototype={
gkF(a){return this.a.gkF(0)},
Zv(a,b){var t=this.a
if(t.b==null)t=t.gv().Zv(0,b)
else{t=t.Cf()
if(!(b<t.length))return A.OH(t,b)
t=t[b]}return t},
gkz(a){var t=this.a
if(t.b==null){t=t.gv()
t=t.gkz(t)}else{t=t.Cf()
t=new J.m1(t,t.length,A.t6(t).C("m1<1>"))}return t},
tg(a,b){return this.a.NZ(b)}}
A.Uk.prototype={}
A.ze.prototype={}
A.Ud.prototype={
"["(a){var t=A.u(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+t}}
A.K8.prototype={
"["(a){return"Cyclic error in JSON stringify"}}
A.D4.prototype={
p(a,b){var t=A.BS(a,this.gHe().a)
return t},
O(a,b){var t=A.uX(a,this.gZE().b,null)
return t},
gZE(){return B.nX},
gHe(){return B.A3}}
A.oj.prototype={}
A.Mx.prototype={}
A.Sh.prototype={
RT(a){var t,s,r,q,p,o,n=a.length
for(t=this.c,s=0,r=0;r<n;++r){q=a.charCodeAt(r)
if(q>92){if(q>=55296){p=q&64512
if(p===55296){o=r+1
o=!(o<n&&(a.charCodeAt(o)&64512)===56320)}else o=!1
if(!o)if(p===56320){p=r-1
p=!(p>=0&&(a.charCodeAt(p)&64512)===55296)}else p=!1
else p=!0
if(p){if(r>s)t.a+=B.xB.Nj(a,s,r)
s=r+1
p=A.Lw(92)
t.a+=p
p=A.Lw(117)
t.a+=p
p=A.Lw(100)
t.a+=p
p=q>>>8&15
p=A.Lw(p<10?48+p:87+p)
t.a+=p
p=q>>>4&15
p=A.Lw(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.Lw(p<10?48+p:87+p)
t.a+=p}}continue}if(q<32){if(r>s)t.a+=B.xB.Nj(a,s,r)
s=r+1
p=A.Lw(92)
t.a+=p
switch(q){case 8:p=A.Lw(98)
t.a+=p
break
case 9:p=A.Lw(116)
t.a+=p
break
case 10:p=A.Lw(110)
t.a+=p
break
case 12:p=A.Lw(102)
t.a+=p
break
case 13:p=A.Lw(114)
t.a+=p
break
default:p=A.Lw(117)
t.a+=p
p=A.Lw(48)
t.a=(t.a+=p)+p
p=q>>>4&15
p=A.Lw(p<10?48+p:87+p)
t.a+=p
p=q&15
p=A.Lw(p<10?48+p:87+p)
t.a+=p
break}}else if(q===34||q===92){if(r>s)t.a+=B.xB.Nj(a,s,r)
s=r+1
p=A.Lw(92)
t.a+=p
p=A.Lw(q)
t.a+=p}}if(s===0)t.a+=a
else if(s<n)t.a+=B.xB.Nj(a,s,n)},
Jn(a){var t,s,r,q
for(t=this.a,s=t.length,r=0;r<s;++r){q=t[r]
if(a==null?q==null:a===q)throw A.b(new A.K8(a,null))}B.Nm.i(t,a)},
QD(a){var t,s,r,q,p=this
if(p.tM(a))return
p.Jn(a)
try{t=p.b.$1(a)
if(!p.tM(t)){r=A.Gy(a,null,p.gVK())
throw A.b(r)}r=p.a
if(0>=r.length)return A.OH(r,-1)
r.pop()}catch(q){s=A.Ru(q)
r=A.Gy(a,s,p.gVK())
throw A.b(r)}},
tM(a){var t,s,r=this
if(typeof a=="number"){if(!isFinite(a))return!1
r.c.a+=B.CD["["](a)
return!0}else if(a===!0){r.c.a+="true"
return!0}else if(a===!1){r.c.a+="false"
return!0}else if(a==null){r.c.a+="null"
return!0}else if(typeof a=="string"){t=r.c
t.a+='"'
r.RT(a)
t.a+='"'
return!0}else if(u.j.b(a)){r.Jn(a)
r.lK(a)
t=r.a
if(0>=t.length)return A.OH(t,-1)
t.pop()
return!0}else if(u.f.b(a)){r.Jn(a)
s=r.jw(a)
t=r.a
if(0>=t.length)return A.OH(t,-1)
t.pop()
return s}else return!1},
lK(a){var t,s,r=this.c
r.a+="["
t=a.length
if(t!==0){if(0>=t)return A.OH(a,0)
this.QD(a[0])
for(s=1;s<a.length;++s){r.a+=","
this.QD(a[s])}}r.a+="]"},
jw(a){var t,s,r,q,p,o,n=this,m={}
if(a.gl0(a)){n.c.a+="{}"
return!0}t=a.gkF(a)*2
s=A.O8(t,null,u.X)
r=m.a=0
m.b=!0
a.U(0,new A.ti(m,s))
if(!m.b)return!1
q=n.c
q.a+="{"
for(p='"';r<t;r+=2,p=',"'){q.a+=p
n.RT(A.Bt(s[r]))
q.a+='":'
o=r+1
if(!(o<t))return A.OH(s,o)
n.QD(s[o])}q.a+="}"
return!0}}
A.ti.prototype={
$2(a,b){var t,s
if(typeof a!="string")this.a.b=!1
t=this.b
s=this.a
B.Nm.Y(t,s.a++,a)
B.Nm.Y(t,s.a++,b)},
$S:5}
A.Gs.prototype={
gVK(){var t=this.c.a
return t.charCodeAt(0)==0?t:t}}
A.ck.prototype={
"["(a){return this.q()}}
A.Ge.prototype={}
A.C6.prototype={
"["(a){var t=this.a
if(t!=null)return"Assertion failed: "+A.u(t)
return"Assertion failed"}}
A.Ez.prototype={}
A.AT.prototype={
gZ(){return"Invalid argument"+(!this.a?"(s)":"")},
gN(){return""},
"["(a){var t=this,s=t.c,r=s==null?"":" ("+s+")",q=t.d,p=q==null?"":": "+q,o=t.gZ()+r+p
if(!t.a)return o
return o+t.gN()+": "+A.u(t.gE())},
gE(){return this.b}}
A.bJ.prototype={
gE(){return A.cU(this.b)},
gZ(){return"RangeError"},
gN(){var t,s=this.e,r=this.f
if(s==null)t=r!=null?": Not less than or equal to "+A.J(r):""
else if(r==null)t=": Not greater than or equal to "+A.J(s)
else if(r>s)t=": Not in inclusive range "+A.J(s)+".."+A.J(r)
else t=r<s?": Valid value range is empty":": Only valid value is "+A.J(s)
return t}}
A.eY.prototype={
gE(){return A.IZ(this.b)},
gZ(){return"RangeError"},
gN(){if(A.IZ(this.b)<0)return": index must not be negative"
var t=this.f
if(t===0)return": no indices are valid"
return": index should be less than "+t},
gkF(a){return this.f}}
A.ub.prototype={
"["(a){return"Unsupported operation: "+this.a}}
A.lj.prototype={
"["(a){return"Bad state: "+this.a}}
A.UV.prototype={
"["(a){var t=this.a
if(t==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.u(t)+"."}}
A.VS.prototype={
"["(a){return"Stack Overflow"},
$iGe:1}
A.aE.prototype={
"["(a){var t=this.a,s=""!==t?"FormatException: "+t:"FormatException"
return s}}
A.cX.prototype={
E2(a,b,c){var t=A.Lh(this)
return A.K1(this,t.K(c).C("1(cX.E)").a(b),t.C("cX.E"),c)},
tg(a,b){var t
for(t=this.gkz(this);t.G();)if(J.cf(t.gl(),b))return!0
return!1},
rb(a,b){var t
A.Lh(this).C("a0(cX.E)").a(b)
for(t=this.gkz(this);t.G();)if(!b.$1(t.gl()))return!1
return!0},
gkF(a){var t,s=this.gkz(this)
for(t=0;s.G();)++t
return t},
gl0(a){return!this.gkz(this).G()},
Zv(a,b){var t,s
A.k1(b,"index")
t=this.gkz(this)
for(s=b;t.G();){if(s===0)return t.gl();--s}throw A.b(A.xF(b,b-s,this,"index"))},
"["(a){return A.Sd(this,"(",")")}}
A.Yh.prototype={
"["(a){return"MapEntry("+A.J(this.a)+": "+A.J(this.b)+")"}}
A.c8.prototype={
giO(a){return A.Mh.prototype.giO.call(this,0)},
"["(a){return"null"}}
A.Mh.prototype={$iMh:1,
DN(a,b){return this===b},
giO(a){return A.eQ(this)},
"["(a){return"Instance of '"+A.lh(this)+"'"},
gbx(a){return A.RW(this)},
toString(){return this["["](this)}}
A.Rn.prototype={
gkF(a){return this.a.length},
"["(a){var t=this.a
return t.charCodeAt(0)==0?t:t},
$iBL:1}
A.vY.prototype={
L(a){var t,s,r,q,p,o,n,m=this,l=4294967296,k=a<0?-1:0
do{t=a>>>0
a=B.jn.B(a-t,l)
s=a>>>0
a=B.jn.B(a-s,l)
r=(~t>>>0)+(t<<21>>>0)
q=r>>>0
s=(~s>>>0)+((s<<21|t>>>11)>>>0)+B.jn.B(r-q,l)>>>0
r=((q^(q>>>24|s<<8))>>>0)*265
t=r>>>0
s=((s^s>>>24)>>>0)*265+B.jn.B(r-t,l)>>>0
r=((t^(t>>>14|s<<18))>>>0)*21
t=r>>>0
s=((s^s>>>14)>>>0)*21+B.jn.B(r-t,l)>>>0
t=(t^(t>>>28|s<<4))>>>0
s=(s^s>>>28)>>>0
r=(t<<31>>>0)+t
q=r>>>0
p=B.jn.B(r-q,l)
r=m.a*1037
o=m.a=r>>>0
n=m.b*1037+B.jn.B(r-o,l)>>>0
m.b=n
o=(o^q)>>>0
m.a=o
p=(n^s+((s<<31|t>>>1)>>>0)+p>>>0)>>>0
m.b=p}while(a!==k)
if(p===0&&o===0)m.a=23063
m.S()
m.S()
m.S()
m.S()},
S(){var t=this,s=t.a,r=4294901760*s,q=r>>>0,p=55905*s,o=p>>>0,n=o+q+t.b
s=n>>>0
t.a=s
t.b=B.jn.B(p-o+(r-q)+(n-s),4294967296)>>>0},
j1(a){var t,s,r,q=this
if(a<=0||a>4294967296)throw A.b(A.C3("max must be in range 0 < max \u2264 2^32, was "+a))
t=a-1
if((a&t)>>>0===0){q.S()
return(q.a&t)>>>0}do{q.S()
s=q.a
r=s%a}while(s-r+a>=4294967296)
return r}}
A.QB.prototype={
q(){return"CardRank."+this.b}}
A.DO.prototype={
$1(a){return u.c.a(a).b===this.a},
$S:47}
A.Ax.prototype={
$0(){return A.v(A.rr("Unknown rank key: "+this.a))},
$S:6}
A.tN.prototype={
q(){return"CardSuit."+this.b}}
A.rg.prototype={
$1(a){return u.D.a(a).b===this.a},
$S:31}
A.Nj.prototype={
$0(){return A.v(A.rr("Unknown suit key: "+this.a))},
$S:6}
A.vr.prototype={
QT(a,b){var t
if(b.Q>0){t=a.b
if(t===B.GO)return this.a.r
if(t===B.TJ)return this.a.x!==B.J6
return!1}t=a.b
if(t===B.TJ&&this.a.w)return!0
if(a.a===b.z)return!0
if(t===B.Nm.grZ(b.y).b)return!0
return!1},
ku(a,b){var t,s
u.v.a(a)
t=A.t6(a)
s=t.C("oi<1>")
t=A.ev(new A.oi(a,t.C("a0(1)").a(new A.If(this,b)),s),s.C("cX.E"))
t.$flags=1
return t},
H(a,b){return B.Nm.Vr(u.v.a(a),new A.YE(this,b))},
Xk(a,b,c){if(a.b!==B.TJ)return!1
if(b&&!this.a.y)return!1
return!0}}
A.If.prototype={
$1(a){return this.a.QT(u.U.a(a),this.b)},
$S:2}
A.YE.prototype={
$1(a){return this.a.QT(u.U.a(a),this.b)},
$S:2}
A.Mm.prototype={
r2(a,b,c,d,e,f,g){var t,s,r,q,p,o,n=null
u.w.a(d)
t=Math.max(2,e.a)
s=Math.min(4,e.b)
r=d.length
if(r<t||r>s)throw A.b(A.OP(B.BU,"Need "+A.J(t)+"\u2013"+A.J(s)+" players, got "+r))
q=A.r2(u.N)
for(p=0;o=d.length,p<o;d.length===r||(0,A.lk)(d),++p){o=d[p].a
if(o.length===0||!q.i(0,o))throw A.b(A.OP(B.UR,'Player id "'+o+'" is empty or duplicated'))}r=e.c
if(r<1||r*o+1>40)throw A.b(B.yN)
if(e.ax<0||e.as<1)throw A.b(B.ob)
if(g<0||g>=o)throw A.b(A.OP(B.BU,"startingSeat "+g+" is not a seat"))
r=A.QI([],u.R)
for(o=d.length,p=0;p<d.length;d.length===o||(0,A.lk)(d),++p)r.push(d[p].O5(B.xD))
return this.Xj(this.j8(A.ab(B.a7,0,n,g,g,e.cx,A.QI([B.Nm.gFV($.Sj())],u.Y),B.xD,n,B.WD,a,!1,B.iH,!1,n,n,n,b,!1,0,B.xD,r,1,n,e,f,n,B.vc,n,0,n,0,B.Dx,n),g),c,n)},
F(a,b){var t,s,r,q
if(a.at!==B.vc)return B.xD
t=a.d
s=a.f
if(!(s>=0&&s<t.length))return A.OH(t,s)
if(t[s].a!==b)return B.xD
r=a.FI(b)
if(r==null||r.w)return B.xD
t=a.c
if(t.f&&a.CW&&!a.cx){s=a.db
q=s==null?B.xD:A.QI([s],u.Y)}else q=r.x
return new A.vr(t).ku(q,a)},
ZN(a,b){var t,s,r
if(!a.c.db)return!1
t=a.at
if(t!==B.qg)s=t===B.Jz
else s=!0
if(s)return!1
if(t!==B.vc)return!1
t=a.d
s=a.f
if(!(s>=0&&s<t.length))return A.OH(t,s)
if(t[s].a!==b)return!1
r=a.FI(b)
if(r==null||r.w)return!1
if(r.x.length!==2)return!1
if(a.cy===b)return!1
return this.F(a,b).length!==0},
WA(a,b){var t
if(!a.c.db)return!1
t=a.FI(b)
if(t==null)return!1
return t.x.length===2&&a.cy!==b},
W(a,b){var t,s,r,q,p,o,n,m,l=null,k=a.at
if(k===B.qg)return B.GL
if(a.y.length!==0){t=a.f
t=t<0||t>=a.d.length}else t=!0
if(t)return B.oC
t=b.b
if(t!=null&&t!==a.dy)return B.VE
t=b.a
s=a.FI(t)
if(b instanceof A.wa){if(s==null&&t!=="system")return B.HJ
if(k!==B.Jz)return B.iY
return l}if(s==null||s.w)return B.HJ
if(b instanceof A.hP)return l
if(k===B.Jz)return B.F5
t=s.a
r=a.d
q=a.f
if(!(q>=0&&q<r.length))return A.OH(r,q)
if(t!==r[q].a)return B.ug
p=k===B.cT
o=a.c
n=new A.vr(o)
k=b instanceof A.e3
m=k?b.c:l
if(k){if(p)return B.Jn
if(!B.Nm.tg(s.x,m))return B.tA
if(!n.QT(m,a))return B.wH
if(o.f&&a.CW&&!a.cx&&!J.cf(a.db,m))return B.wH
if(this.WA(a,t))return B.Ti
return l}if(b instanceof A.N3){if(p)return B.Jn
if(a.Q>0)return l
if(a.CW)return B.u3
if(!o.d&&n.H(s.x,a))return B.u3
return l}if(b instanceof A.OA){if(!p)return B.Ip
return l}if(b instanceof A.ew){if(p)return B.Jn
if(a.Q>0)return B.v1
if(o.at&&!a.CW)return B.v1
return l}if(b instanceof A.eK){if(p)return B.Jn
if(!this.ZN(a,t))return B.Od
return l}},
vv(a,b,c){var t,s,r,q=this,p=null,o=q.W(a,b)
if(o!=null)return new A.KY(o)
t=A.QI([],u.c4)
A:{if(b instanceof A.e3){s=q.Jc(a,b,t)
break A}if(b instanceof A.N3){s=q.Qn(a,b,t)
break A}if(b instanceof A.OA){s=q.uz(a,b.a,b.c,u.F.a(t))
break A}if(b instanceof A.ew){s=q.zV(a,1,t)
break A}if(b instanceof A.eK){B.Nm.i(u.F.a(t),new A.GE())
s=b.a
s=a.Sm(s).Bq(new A.pO(B.vp,s,p,p,p))
break A}if(b instanceof A.wa){s=q.PE(a,t)
break A}if(b instanceof A.hP){s=q.MZ(a,b,t)
break A}s=p}r=q.Xj(s.p6(b,a.dy+1),c,a)
a.goF()
return new A.dK(r,A.AF(t,u.J))},
Jc(a3,a4,a5){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=this,a2=null
u.d.a(a4)
u.F.a(a5)
t=a3.d
s=a3.f
if(!(s>=0&&s<t.length))return A.OH(t,s)
r=t[s]
q=a4.c
p=a3.c
s=u.U
o=A.ev(r.x,s)
B.Nm.Rz(o,q)
t=r.a
n=q.a
m=A.yV(a3.ok,t,n)
l=a3.hL(r.O5(o))
k=A.ev(a3.y,s)
k.push(q)
s=A.ev(a3.k3,s)
s.push(q)
j=q.b
i=j===B.TJ
h=i?a3.z:n
g=a3.k1
g=g.Uw(g.a+1)
f=g.x
e=A.qC(f,u.N,u.S)
n=n.b
f=f.WH(0,n)
e.Y(0,n,(f==null?0:f)+1)
d=l.ri(h,!0,k,s,g.OP(e),m).Bq(new A.pO(B.tP,t,q,a2,a2))
B.Nm.i(a5,new A.ry())
s=o.length
c=a3.Q>0
n=j===B.Mf
b=!1
if(n){l=d.k1
d=d.Al(l.Cy(l.b+1))}else if(j===B.GO){a=d.as+1
l=d.k1
d=d.Cu(a,d.Q+p.ax,l.En(Math.max(l.d,a),l.c+1))
B.Nm.i(a5,new A.Cx())}else{b=i&&c
if(b){B.Nm.i(a5,new A.E4())
d=d.Bq(new A.pO(B.u5,t,q,d.Q,a2))
if(p.x===B.cq)d=d.TO(0,0)}}if(s===0)return a1.lA(d,t,a5,q)
if(i){if(!new A.vr(d.c).Xk(q,b,!1))return a1.zV(d,1,a5)
s=a4.d
if(s!=null)return a1.uz(d,t,s,a5)
B.Nm.i(a5,new A.Mw())
return d.Tr(B.cT)}if(n){a0=a1.Vt(d,d.f,1)
t=d.d
if(!(a0>=0&&a0<t.length))return A.OH(t,a0)
d=d.Bq(new A.pO(B.kI,t[a0].a,a2,a2,a2))
B.Nm.i(a5,new A.Pt())
return a1.zV(d,2,a5)}return a1.zV(d,1,a5)},
uz(a,b,c,d){var t,s,r,q,p,o
u.F.a(d)
t=a.k1
s=t.w
r=s.WH(0,b)
if(r==null)r=B.hU
q=u.N
p=A.ev(r,q)
r=c.b
if(!B.Nm.tg(p,r))B.Nm.i(p,r)
s=A.qC(s,q,u.a)
s.Y(0,b,p)
o=a.Bg(c,t.t9(s),B.vc).Bq(new A.pO(B.l2,b,null,null,c))
B.Nm.i(d,new A.wz())
return this.zV(o,1,d)},
Qn(a,b,c){var t,s,r,q,p,o,n,m,l,k,j,i,h=this,g=null
u.r.a(b)
u.F.a(c)
t=a.d
s=a.f
if(!(s>=0&&s<t.length))return A.OH(t,s)
r=t[s]
q=a.c
t=a.Q
if(t>0){s=r.a
p=h.ug(a,s,t,c)
o=p.a.iN(0,!0,!0,!0,!0,0,B.vc).Bq(new A.pO(B.Dc,s,g,p.b.length,g))
B.Nm.i(c,new A.M7())
B.Nm.i(c,new A.O3())
return o}if(!new A.vr(q).H(r.x,a)){t=a.ok
s=r.a
n=t.WH(0,s)
if(n==null)n=B.hU
m=u.N
l=A.ev(n,m)
n=a.z.b
if(!B.Nm.tg(l,n))B.Nm.i(l,n)
t=A.qC(t,m,u.a)
t.Y(0,s,l)
o=a.BH(t)}else o=a
t=r.a
k=h.ug(o,t,1,c)
j=k.b
o=k.a.i4(!0,!0).Bq(new A.pO(B.CS,t,g,j.length,g))
B.Nm.i(c,new A.M7())
if(j.length===0)return h.zV(o,1,c)
i=B.Nm.gFV(j)
if(q.e&&new A.vr(o.c).QT(i,o))return o.cc(i)
return h.zV(o,1,c)},
ug(a,b,c,d){var t,s,r,q,p,o,n,m,l,k
u.F.a(d)
t=u.U
s=A.ev(a.x,t)
r=a.y
q=u.Y
p=A.QI([],q)
for(o=!1,n=0;n<c;++n){if(s.length===0){if(r.length<=1||o)break
m=B.Nm.grZ(r)
s=A.tJ(B.Nm.aM(r,0,r.length-1),A.ts(a))
r=A.QI([m],q)
B.Nm.i(d,new A.oN())
a=a.Bq(new A.pO(B.o0,"",null,s.length,null))
o=!0}if(s.length===0)break
if(0<0||0>=s.length)return A.OH(s,-1)
B.Nm.i(p,s.pop())}if(p.length===0)return new A.LN(a,p)
l=a.FI(b)
t=A.ev(l.x,t)
B.Nm.A(t,p)
t=a.hL(l.O5(t))
q=a.k4
k=A.qC(q,u.N,u.S)
q=q.WH(0,b)
if(q==null)q=0
k.Y(0,b,q+p.length)
return new A.LN(t.Pd(r,s,k),p)},
Vt(a,b,c){var t,s,r=a.d,q=r.length,p=q*(c+2),o=a.w,n=b,m=0,l=0
for(;;){if(m<c){t=l+1
s=l<p
l=t}else s=!1
if(!s)break
n=B.jn.h(n+(o===B.Up?1:-1)+q,q)
if(!r[n].w)++m}return n},
zV(a,b,c){var t,s,r
u.F.a(c)
t=a.at
if(t===B.Jz||t===B.qg)return a
s=a.uD(!0,!0,this.Vt(a,a.f,b),!1,!1,B.vc,a.ch+1)
t=s.d
r=s.f
if(!(r>=0&&r<t.length))return A.OH(t,r)
B.Nm.i(c,new A.hc())
return s},
lA(a,a0,a1,a2){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b=this
u.F.a(a1)
t=a.Q
if(t>0){if(a.c.ay){s=a.d
r=b.Vt(a,a.f,1)
if(!(r>=0&&r<s.length))return A.OH(s,r)
q=b.ug(a,s[r].a,t,a1).a
B.Nm.i(a1,new A.M7())
p=q}else p=a
p=p.TO(0,0)}else p=a
o=new A.F2(p.c)
n=A.QI([],u.bL)
m=A.QI([],u.s)
l=A.QI([],u.R)
t=p.k1
s=t.r
r=A.qC(s,u.N,u.S)
s=s.WH(0,a0)
r.Y(0,a0,(s==null?0:s)+1)
k=t.jb(r)
for(t=p.d,s=t.length,j=0;j<s;++j){i=t[j]
if(i.w){B.Nm.i(l,i)
continue}r=i.a
h=r===a0?0:o.dK(i.x)
g=o.iW(h,i.r)
f=g.c
e=g.e
B.Nm.i(l,i.iL(e,f))
d=g.d
if(d){k=k.l1(k.e+1)
B.Nm.i(a1,new A.GO())}if(e)B.Nm.i(m,r)
B.Nm.i(n,new A.cJ(r,i.b,i.x.length,h,g.a,f,d,e))}k=k.no(Math.max(k.f,b.VL(l)))
for(t=m.length,j=0;j<m.length;m.length===t||(0,A.lk)(m),++j)B.Nm.i(a1,new A.fM())
p=p.l9(l,a0,k,B.Jz)
c=b.lB(p)
if(c!=null)p=p.aP(B.qg,c)
p=p.Qr(new A.HO(p.e,a0,p.FI(a0).b,n,p.at===B.qg,p.ax)).Bq(new A.pO(B.pk,a0,a2,null,null))
B.Nm.i(a1,new A.Gt())
if(p.at===B.qg){p.ax.toString
B.Nm.i(a1,new A.bG())}return p},
VL(a){var t,s,r,q,p,o,n,m,l
u.w.a(a)
for(t=a.length,s=0,r=0;r<t;++r){q=a[r]
if(q.w)continue
for(p=q.a,o=1073741824,n=0;n<t;++n){m=a[n]
if(m.a===p||m.w)continue
l=m.r
if(l<o)o=l}if(o===1073741824)continue
s=Math.max(s,q.r-o)}return s},
lB(a){var t,s,r,q,p=a.c
if(p.Q){t=a.d
s=A.t6(t)
r=s.C("oi<1>")
q=A.ev(new A.oi(t,s.C("a0(1)").a(new A.lZ()),r),r.C("cX.E"))
s=q.length
if(s===1)return B.Nm.gFV(q).a
if(s===0)return this.T0(t).a
return null}t=a.d
if(B.Nm.Vr(t,new A.FZ(p)))return this.T0(t).a
return null},
T0(a){var t,s,r,q
u.w.a(a)
t=B.Nm.gFV(a)
for(s=a.length,r=0;r<s;++r){q=a[r]
if(q.r<t.r)t=q}return t},
PE(a,b){var t,s,r,q,p,o,n,m
u.F.a(b)
t=a.ay
s=t==null?-1:a.Us(t)
switch(a.c.CW.a){case 0:r=s
break
case 1:r=s<0?-1:this.Vt(a,s,1)
break
default:r=null}if(typeof r!=="number")return r.J7()
if(r>=0){t=a.d
if(!(r>=0&&r<t.length))return A.OH(t,r)
t=t[r].w}else t=!0
if(t){r=B.Nm.aT(a.d,new A.Pp())
if(r<0)r=0}q=this.Vt(a,a.r,1)
t=A.QI([],u.R)
for(p=a.d,o=p.length,n=0;n<o;++n)t.push(p[n].O5(B.xD))
m=this.j8(a.tn(!0,!0,q,t,a.e+1),r)
t=m.d
p=m.f
if(!(p>=0&&p<t.length))return A.OH(t,p)
B.Nm.i(b,new A.H0())
B.Nm.i(b,new A.hc())
return m},
MZ(a,b,c){var t,s,r,q,p,o,n,m
u.E.a(b)
u.F.a(c)
t=a.FI(b.a)
s=t.a
r=a.Us(s)
q=a.hL(t.Th(!0,B.xD))
p=t.x
o=A.ev(p,u.U)
B.Nm.A(o,a.x)
n=q.pj(a.cy===s,o).Bq(new A.pO(B.yn,s,null,p.length,null))
B.Nm.i(c,new A.qv())
B.Nm.i(c,new A.fM())
s=n.d
q=A.t6(s)
p=q.C("oi<1>")
m=A.ev(new A.oi(s,q.C("a0(1)").a(new A.Ul()),p),p.C("cX.E"))
q=m.length
if(q<=1){n=n.ig(0,0,B.qg,(q===0?this.T0(s):B.Nm.gFV(m)).a)
B.Nm.i(c,new A.bG())
return n}s=n.at
if(s===B.Jz||s===B.qg)return n
if(r!==a.f)return n
return this.zV(n.Ye(0,0,B.vc),1,c)},
j8(a,b){var t,s,r,q,p,o,n,m,l,k,j,i,h,g=a.c,f=A.ts(a),e=A.ev($.Sj(),u.U),d=A.tJ(e,f)
f=A.Fl(u.N,u.v)
for(e=a.d,t=e.length,s=u.Y,r=0;r<t;++r)f.Y(0,e[r].a,A.QI([],s))
q=A.t6(e)
p=q.C("oi<1>")
o=A.ev(new A.oi(e,q.C("a0(1)").a(new A.He()),p),p.C("cX.E"))
for(q=g.c,n=0;n<q;++n)for(p=o.length,r=0;r<o.length;o.length===p||(0,A.lk)(o),++r){m=o[r]
if(d.length===0)break
l=f.WH(0,m.a)
l.toString
if(0>=d.length)return A.OH(d,-1)
B.Nm.i(l,d.pop())}k=d.length-1
if(g.ch===B.WJ){j=B.Nm.WN(d,new A.mB())
if(j>=0)k=j}d.$flags&1&&A.cW(d,"removeAt",1)
if(k<0||k>=d.length)A.v(A.O7(k,null))
i=d.splice(k,1)[0]
q=!0
if(b>=0)if(b<t){if(!(b>=0&&b<t))return A.OH(e,b)
q=e[b].w}if(q){h=B.Nm.aT(e,new A.os())
if(h<0)h=0}else h=b
q=A.QI([],u.R)
for(r=0;r<t;++r){m=e[r]
q.push(m.O5(f.WH(0,m.a)))}f=A.QI([i],s)
return a.iG(i.a,0,!0,!0,h,f,d,B.WD,!1,!1,0,B.xD,q,B.vc,0,B.Dx)},
Xj(a,b,c){var t,s,r=!0
if(c!=null)if(a.ch===c.ch){if(a.e===c.e)if(a.f===c.f)t=a.cx&&!c.cx
else t=r
else t=r
r=t}if(!r)return a
if(b==null)return a.zo(!0)
s=a.c.cy
return a.eq(!1,s==null?null:b+s*1000,b)}}
A.lZ.prototype={
$1(a){return!u.u.a(a).w},
$S:0}
A.FZ.prototype={
$1(a){return u.u.a(a).r>this.a.as},
$S:0}
A.Pp.prototype={
$1(a){return!u.u.a(a).w},
$S:0}
A.Ul.prototype={
$1(a){return!u.u.a(a).w},
$S:0}
A.He.prototype={
$1(a){return!u.u.a(a).w},
$S:0}
A.mB.prototype={
$1(a){var t=u.U.a(a).b
return!(t===B.Mf||t===B.GO||t===B.TJ)},
$S:2}
A.os.prototype={
$1(a){return!u.u.a(a).w},
$S:0}
A.XY.prototype={
$1(a){return A.Bt(a)!==this.a.b},
$S:50}
A.LE.prototype={}
A.ry.prototype={}
A.M7.prototype={}
A.Pt.prototype={}
A.Cx.prototype={}
A.O3.prototype={}
A.E4.prototype={}
A.GE.prototype={}
A.Mw.prototype={}
A.wz.prototype={}
A.oN.prototype={}
A.hc.prototype={}
A.H0.prototype={}
A.Gt.prototype={}
A.GO.prototype={}
A.fM.prototype={}
A.bG.prototype={}
A.qv.prototype={}
A.ed.prototype={
q(){return"GameFailure."+this.b}}
A.xz.prototype={}
A.dK.prototype={}
A.KY.prototype={
"["(a){return"ActionRejected("+this.a.b+")"}}
A.xk.prototype={
"["(a){return"GameSetupException("+this.a.b+"): "+this.b}}
A.ON.prototype={}
A.F2.prototype={
dK(a){return B.Nm.N0(u.v.a(a),0,new A.qR(this),u.S)},
iW(a,b){var t=b+a,s=this.a
if(s.z&&t===s.as)return new A.ON(b,0,!0,!1)
if(t>s.as&&s.Q)return new A.ON(b,t,!1,!0)
return new A.ON(b,t,!1,!1)}}
A.qR.prototype={
$2(a,b){return A.IZ(a)+this.a.a.QP(u.U.a(b).b)},
$S:32}
A.a2.prototype={
Lt(){var t,s=this,r=A.Fl(u.N,u.z)
r.Y(0,"type",s.gt5())
r.Y(0,"playerId",s.a)
t=s.b
if(t!=null)r.Y(0,"baseVersion",t)
r.A(0,s.I())
return r},
DN(a,b){var t,s=this
if(b==null)return!1
if(s!==b)t=J.TP(b)===A.RW(s)&&b instanceof A.a2&&b.a===s.a&&b.b==s.b&&s.V(b)
else t=!0
return t},
giO(a){var t=this
return A.f5(t.gt5(),t.a,t.b,t.gnb(),B.zt,B.zt,B.zt)},
"["(a){return A.nO(this.Lt())}}
A.e3.prototype={
gt5(){return"playCard"},
I(){var t=A.Fl(u.N,u.z),s=this.c
t.Y(0,"card",s.a.b+"_"+s.b.b)
s=this.d
if(s!=null)t.Y(0,"chosenSuit",s.b)
return t},
V(a){return a instanceof A.e3&&a.c.DN(0,this.c)&&a.d==this.d},
gnb(){return A.f5(this.c,this.d,B.zt,B.zt,B.zt,B.zt,B.zt)}}
A.N3.prototype={
gt5(){return"drawCard"},
I(){return B.CM},
V(a){return a instanceof A.N3},
gnb(){return 0}}
A.OA.prototype={
gt5(){return"chooseSuit"},
I(){return A.EF(["suit",this.c.b],u.N,u.z)},
V(a){return a instanceof A.OA&&a.c===this.c},
gnb(){return A.eQ(this.c)}}
A.ew.prototype={
gt5(){return"pass"},
I(){return B.CM},
V(a){return a instanceof A.ew},
gnb(){return 0}}
A.wa.prototype={
gt5(){return"startNextRound"},
I(){return B.CM},
V(a){return a instanceof A.wa},
gnb(){return 0}}
A.hP.prototype={
gt5(){return"forfeit"},
I(){return B.CM},
V(a){return a instanceof A.hP},
gnb(){return 0}}
A.eK.prototype={
gt5(){return"declareLastCard"},
I(){return B.CM},
V(a){return a instanceof A.eK},
gnb(){return 0}}
A.bd.prototype={
Lt(){var t=this.a.b,s=this.b.b
return A.EF(["id",t+"_"+s,"suit",t,"rank",s],u.N,u.z)},
DN(a,b){var t
if(b==null)return!1
if(this!==b)t=b instanceof A.bd&&b.a===this.a&&b.b===this.b
else t=!0
return t},
giO(a){return A.f5(this.a,this.b,B.zt,B.zt,B.zt,B.zt,B.zt)},
"["(a){return this.a.b+"_"+this.b.b}}
A.Ee.prototype={
EC(a,b,c){var t,s,r,q,p=this
u.t.a(b)
t=c==null?p.r:c
s=a==null?p.w:a
r=b==null
q=r?p.x:b
r=r?p.y:null
return new A.Ee(p.a,p.b,p.c,p.d,p.e,p.f,t,s,A.AF(q,u.U),r)},
Th(a,b){return this.EC(a,b,null)},
O5(a){return this.EC(null,a,null)},
iL(a,b){return this.EC(a,null,b)},
Lt(){var t,s,r,q=this,p=A.Fl(u.N,u.z)
p.Y(0,"id",q.a)
p.Y(0,"name",q.b)
p.Y(0,"type",q.c.b)
p.Y(0,"avatarId",q.d)
t=q.e
p.Y(0,"difficulty",t==null?null:t.b)
t=q.f
p.Y(0,"personality",t==null?null:t.b)
p.Y(0,"score",q.r)
p.Y(0,"eliminated",q.w)
t=q.x
s=A.t6(t)
r=s.C("A8<1,qU>")
t=A.ev(new A.A8(t,s.C("qU(1)").a(new A.Na()),r),r.C("aL.E"))
p.Y(0,"hand",t)
t=q.y
if(t!=null)p.Y(0,"handCount",t)
return p},
DN(a,b){var t,s=this
if(b==null)return!1
if(s!==b)t=b instanceof A.Ee&&b.a===s.a&&b.b===s.b&&b.c===s.c&&b.d===s.d&&b.e==s.e&&b.f==s.f&&b.r===s.r&&b.w===s.w&&b.y==s.y&&A.ET(b.x,s.x)
else t=!0
return t},
giO(a){var t=this
return A.f5(t.a,t.b,t.c,t.r,t.w,A.df(t.x),B.zt)},
"["(a){return"GamePlayer("+this.a+", score: "+this.r+", hand: "+A.J(this.x)+")"}}
A.Na.prototype={
$1(a){u.U.a(a)
return a.a.b+"_"+a.b.b},
$S:1}
A.pn.prototype={
$1(a){return A.SZ(a)},
$S:8}
A.z0.prototype={
q(){return"NineBlockMode."+this.b}}
A.Nc.prototype={
$1(a){return u.aX.a(a).b===this.a},
$S:12}
A.YA.prototype={
$0(){return B.cq},
$S:13}
A.uj.prototype={
q(){return"StarterCardPolicy."+this.b}}
A.Sq.prototype={
$1(a){return u._.a(a).b===this.a},
$S:14}
A.o2.prototype={
$0(){return B.WJ},
$S:15}
A.Sv.prototype={
q(){return"RoundStarterPolicy."+this.b}}
A.LF.prototype={
$1(a){return u.ak.a(a).b===this.a},
$S:16}
A.QW.prototype={
$0(){return B.nk},
$S:10}
A.Br.prototype={
q(){return"TurnDirection."+this.b}}
A.Ff.prototype={
$1(a){return u.bf.a(a).b===this.a},
$S:18}
A.Ij.prototype={
$0(){return B.Up},
$S:19}
A.k7.prototype={
QP(a){var t=this.dx.WH(0,a)
return t==null?a.c:t},
Lt(){var t,s,r,q=this,p=u.N,o=A.Fl(p,u.I)
for(t=q.dx,s=0;s<10;++s){r=B.x0[s]
if(t.NZ(r))o.Y(0,r.b,t.WH(0,r))}return A.EF(["minPlayers",q.a,"maxPlayers",q.b,"startingHandSize",q.c,"allowVoluntaryDraw",q.d,"playDrawnCardImmediately",q.e,"restrictPlayToDrawnCard",q.f,"stackDrawTwos",q.r,"wildNineCanAlwaysPlay",q.w,"nineBlockMode",q.x.b,"nineBlockChangesSuit",q.y,"exact101ResetsToZero",q.z,"eliminateAbove101",q.Q,"targetScore",q.as,"mustDrawBeforePassing",q.at,"drawTwoPenalty",q.ax,"pendingPenaltyAppliesAfterWin",q.ay,"starterCardPolicy",q.ch.b,"roundStarterPolicy",q.CW.b,"initialDirection",q.cx.b,"turnTimeLimitSeconds",q.cy,"requireLastCardDeclaration",q.db,"scoreValues",o],p,u.z)},
DN(a,b){var t,s,r,q,p,o,n=this
if(b==null)return!1
if(n===b)return!0
if(!(b instanceof A.k7))return!1
if(b.a!==n.a||b.b!==n.b||b.c!==n.c||b.d!==n.d||b.e!==n.e||b.f!==n.f||b.r!==n.r||b.w!==n.w||b.x!==n.x||b.y!==n.y||b.z!==n.z||b.Q!==n.Q||b.as!==n.as||b.at!==n.at||b.ax!==n.ax||b.ay!==n.ay||b.ch!==n.ch||b.CW!==n.CW||b.cx!==n.cx||b.cy!=n.cy||b.db!==n.db)return!1
for(t=n.dx,s=b.dx,r=0;r<10;++r){q=B.x0[r]
p=s.WH(0,q)
if(p==null)p=q.c
o=t.WH(0,q)
if(p!==(o==null?q.c:o))return!1}return!0},
giO(a){var t=this
return A.f5(t.c,t.r,t.x,t.as,t.ax,t.Q,t.z)}}
A.kQ.prototype={
q(){return"GameMode."+this.b}}
A.ZL.prototype={
$1(a){return u.l.a(a).b===this.a},
$S:20}
A.Ko.prototype={
$0(){return B.AF},
$S:21}
A.am.prototype={
q(){return"GameStatus."+this.b}}
A.Aj.prototype={
$1(a){return u.M.a(a).b===this.a},
$S:22}
A.WB.prototype={
$0(){return this.a==="matchOver"?B.qg:B.vc},
$S:23}
A.cw.prototype={
FI(a){var t,s,r,q
for(t=this.d,s=t.length,r=0;r<s;++r){q=t[r]
if(q.a===a)return q}return null},
Us(a){return B.Nm.aT(this.d,new A.Wn(a))},
goF(){return this.x.length+this.y.length+B.Nm.N0(this.d,0,new A.yt(),u.S)},
Xe(b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8=this,a9=null
u.b0.a(d1)
t=u.t
t.a(c0)
t.a(b9)
u.aI.a(c4)
t.a(d0)
u.h.a(c2)
u.k.a(e0)
t=d1==null?a8.d:d1
s=d2==null?a8.e:d2
r=b7==null?a8.f:b7
q=b8==null?a8.r:b8
p=c0==null
o=p?a8.x:c0
n=b9==null?a8.y:b9
m=b0==null?a8.z:b0
l=c9==null?a8.Q:c9
k=b1==null?a8.as:b1
j=d5==null?a8.at:d5
i=e1==null?a8.ax:e1
if(b5)h=a9
else h=d3==null?a8.ay:d3
g=d7==null?a8.ch:d7
f=c3==null?a8.CW:c3
e=c8==null?a8.cx:c8
if(b3)d=a9
else d=c6==null?a8.cy:c6
if(b2)c=a9
else c=c1==null?a8.db:c1
b=c5==null?a8.dx:c5
a=d9==null?a8.dy:d9
if(b6)a0=a9
else a0=d8==null?a8.fr:d8
if(b6)a1=a9
else a1=d6==null?a8.fx:d6
p=p?a8.id:a9
a2=d4==null?a8.k1:d4
a3=c4==null?a8.k2:c4
a4=d0==null?a8.k3:d0
a5=c2==null?a8.k4:c2
a6=e0==null?a8.ok:e0
if(b4)a7=a9
else a7=c7==null?a8.p1:c7
return A.ab(m,k,p,r,q,a8.w,n,o,c,a5,a8.a,f,a3,a8.go,b,d,a7,a8.b,e,l,a4,t,s,h,a8.c,a8.fy,a2,j,a1,g,a0,a,a6,i)},
Sm(a){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,a,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t)},
p6(a,b){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,a,t,t,t,t,t,t,t,t,t,t,t,t,t,b,t,t)},
zo(a){var t=null
return this.Xe(t,t,!1,!1,!1,!1,a,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t)},
eq(a,b,c){var t=null
return this.Xe(t,t,!1,!1,!1,!1,a,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,b,t,c,t,t,t)},
pj(a,b){var t=null
return this.Xe(t,t,!1,a,!1,!1,!1,t,t,t,b,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t)},
ig(a,b,c,d){var t=null
return this.Xe(t,a,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,t,t,b,t,t,t,t,t,c,t,t,t,t,t,d)},
Ye(a,b,c){var t=null
return this.Xe(t,a,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,t,t,b,t,t,t,t,t,c,t,t,t,t,t,t)},
r6(a){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,t,t,t,t,a,t,t,t,t,t,t,t,t,t,t)},
tn(a,b,c,d,e){var t=null
return this.Xe(t,t,!1,!1,a,b,!1,t,c,t,t,t,t,t,t,t,t,t,t,t,t,d,e,t,t,t,t,t,t,t,t,t)},
iG(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p){var t=null
return this.Xe(a,b,c,d,!1,!1,!1,e,t,f,g,t,h,i,t,t,t,t,j,k,l,m,t,t,t,n,t,o,t,t,p,t)},
HC(a){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,a,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t)},
uD(a,b,c,d,e,f,g){var t=null
return this.Xe(t,t,a,b,!1,!1,!1,c,t,t,t,t,t,d,t,t,t,t,e,t,t,t,t,t,t,f,t,g,t,t,t,t)},
Bg(a,b,c){var t=null
return this.Xe(a,t,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,b,c,t,t,t,t,t,t)},
iN(a,b,c,d,e,f,g){var t=null
return this.Xe(t,a,b,c,!1,!1,!1,t,t,t,t,t,t,d,t,t,t,t,e,f,t,t,t,t,t,g,t,t,t,t,t,t)},
BH(a){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,a,t)},
i4(a,b){var t=null
return this.Xe(t,t,!1,a,!1,!1,!1,t,t,t,t,t,t,b,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t)},
cc(a){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,t,t,a,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t)},
Pd(a,b,c){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,a,b,t,c,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t)},
ri(a,b,c,d,e,f){var t=null
return this.Xe(a,t,b,!1,!1,!1,!1,t,t,c,t,t,t,t,t,t,t,t,t,t,d,t,t,t,e,t,t,t,t,t,f,t)},
Al(a){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,a,t,t,t,t,t,t,t)},
Cu(a,b,c){var t=null
return this.Xe(t,a,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,t,t,b,t,t,t,t,c,t,t,t,t,t,t,t)},
TO(a,b){var t=null
return this.Xe(t,a,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,t,t,b,t,t,t,t,t,t,t,t,t,t,t,t)},
Tr(a){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,a,t,t,t,t,t,t)},
l9(a,b,c,d){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,t,t,t,t,a,t,b,c,d,t,t,t,t,t,t)},
aP(a,b){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,a,t,t,t,t,t,b)},
Qr(a){var t=null
return this.Xe(t,t,!1,!1,!1,!1,!1,t,t,t,t,t,t,t,t,t,t,a,t,t,t,t,t,t,t,t,t,t,t,t,t,t)},
hL(a){var t,s,r,q,p,o=A.QI([],u.R)
for(t=this.d,s=t.length,r=a.a,q=0;q<s;++q){p=t[q]
o.push(p.a===r?a:p)}return this.r6(o)},
Bq(a){var t,s=A.ev(this.k2,u.n)
s.push(a)
t=s.length
return this.HC(t>40?B.Nm.Jk(s,t-40):s)},
Lt(){var t,s,r,q=this,p=A.Fl(u.N,u.z)
p.Y(0,"schema",3)
p.Y(0,"gameId",q.a)
p.Y(0,"mode",q.b.b)
p.Y(0,"rules",q.c.Lt())
t=q.d
s=A.t6(t)
r=s.C("A8<1,T8<qU,@>>")
t=A.ev(new A.A8(t,s.C("T8<qU,@>(1)").a(new A.ZT()),r),r.C("aL.E"))
p.Y(0,"players",t)
p.Y(0,"round",q.e)
p.Y(0,"currentSeat",q.f)
p.Y(0,"dealerSeat",q.r)
p.Y(0,"direction",q.w.b)
t=q.x
s=A.t6(t)
r=s.C("A8<1,qU>")
t=A.ev(new A.A8(t,s.C("qU(1)").a(new A.wp()),r),r.C("aL.E"))
p.Y(0,"drawPile",t)
t=q.y
s=A.t6(t)
r=s.C("A8<1,qU>")
t=A.ev(new A.A8(t,s.C("qU(1)").a(new A.zU()),r),r.C("aL.E"))
p.Y(0,"discardPile",t)
p.Y(0,"activeSuit",q.z.b)
p.Y(0,"pendingDrawCount",q.Q)
p.Y(0,"chainLength",q.as)
p.Y(0,"status",q.at.b)
p.Y(0,"winnerId",q.ax)
p.Y(0,"roundWinnerId",q.ay)
p.Y(0,"turnNumber",q.ch)
p.Y(0,"hasDrawnThisTurn",q.CW)
p.Y(0,"penaltyResolvedThisTurn",q.cx)
p.Y(0,"lastCardDeclaredBy",q.cy)
t=q.db
p.Y(0,"drawnCard",t==null?null:t.a.b+"_"+t.b.b)
t=q.dx
p.Y(0,"lastAction",t==null?null:t.Lt())
p.Y(0,"version",q.dy)
p.Y(0,"turnStartedAt",q.fr)
p.Y(0,"turnDeadlineAt",q.fx)
p.Y(0,"seed",q.fy)
p.Y(0,"isDailyChallenge",q.go)
t=q.id
if(t!=null)p.Y(0,"drawPileCount",t)
p.Y(0,"stats",q.k1.Lt())
t=q.k2
s=A.t6(t)
r=s.C("A8<1,T8<qU,@>>")
t=A.ev(new A.A8(t,s.C("T8<qU,@>(1)").a(new A.dQ()),r),r.C("aL.E"))
p.Y(0,"history",t)
t=q.k3
s=A.t6(t)
r=s.C("A8<1,qU>")
t=A.ev(new A.A8(t,s.C("qU(1)").a(new A.EG()),r),r.C("aL.E"))
p.Y(0,"playedCards",t)
p.Y(0,"drawsByPlayer",q.k4)
p.Y(0,"voidSuits",q.ok)
t=q.p1
p.Y(0,"lastRoundResult",t==null?null:t.Lt())
return p},
"["(a){var t=this
return"GameState(v"+t.dy+" r"+t.e+" "+t.at.b+" seat="+t.f+" dealer="+t.r+" top="+B.Nm.grZ(t.y)["["](0)+" suit="+t.z.b+" pending="+t.Q+")"}}
A.Wn.prototype={
$1(a){return u.u.a(a).a===this.a},
$S:0}
A.yt.prototype={
$2(a,b){return A.IZ(a)+u.u.a(b).x.length},
$S:24}
A.ZT.prototype={
$1(a){return u.u.a(a).Lt()},
$S:25}
A.wp.prototype={
$1(a){u.U.a(a)
return a.a.b+"_"+a.b.b},
$S:1}
A.zU.prototype={
$1(a){u.U.a(a)
return a.a.b+"_"+a.b.b},
$S:1}
A.dQ.prototype={
$1(a){return u.n.a(a).Lt()},
$S:26}
A.EG.prototype={
$1(a){u.U.a(a)
return a.a.b+"_"+a.b.b},
$S:1}
A.kj.prototype={
$1(a){var t,s,r
u.g.a(a)
t=a==null?B.dn:a
s=A.t6(t)
r=s.C("A8<1,bd>")
t=A.ev(new A.A8(t,s.C("bd(1)").a(new A.On()),r),r.C("aL.E"))
return t},
$S:27}
A.On.prototype={
$1(a){return A.SZ(a)},
$S:8}
A.da.prototype={
$1(a){return A.Y1(u.f.a(a).tY(0,u.N,u.z))},
$S:28}
A.Lr.prototype={
$1(a){return u.u.a(a).a},
$S:29}
A.QU.prototype={
$1(a){return A.SV(u.f.a(a).tY(0,u.N,u.z))},
$S:30}
A.Cp.prototype={
$2(a,b){return new A.Yh(A.Bt(a),B.CD.yu(A.z5(b)),u.O)},
$S:3}
A.AU.prototype={
$2(a,b){var t,s,r
A.Bt(a)
u.g.a(b)
t=b==null?B.dn:b
s=A.t6(t)
r=s.C("A8<1,qU>")
t=A.ev(new A.A8(t,s.C("qU(1)").a(new A.n8()),r),r.C("aL.E"))
return new A.Yh(a,t,u.q)},
$S:9}
A.n8.prototype={
$1(a){return A.Bt(a)},
$S:7}
A.FQ.prototype={
$1(a){var t
u.bX.a(a)
t=A.cU(this.a.WH(0,a.a.b))
t=t==null?null:B.CD.yu(t)
return t===a.b},
$S:34}
A.eZ.prototype={
q(){return"HistoryEntryType."+this.b}}
A.pO.prototype={
Lt(){var t,s=this,r=A.Fl(u.N,u.z)
r.Y(0,"t",s.a.b)
r.Y(0,"p",s.b)
t=s.c
if(t!=null)r.Y(0,"c",t.a.b+"_"+t.b.b)
t=s.d
if(t!=null)r.Y(0,"n",t)
t=s.e
if(t!=null)r.Y(0,"s",t.b)
return r},
DN(a,b){var t,s=this
if(b==null)return!1
if(s!==b)t=b instanceof A.pO&&b.a===s.a&&b.b===s.b&&J.cf(b.c,s.c)&&b.d==s.d&&b.e==s.e
else t=!0
return t},
giO(a){var t=this
return A.f5(t.a,t.b,t.c,t.d,t.e,B.zt,B.zt)}}
A.T2.prototype={
$1(a){return u.W.a(a).b===this.a.WH(0,"t")},
$S:35}
A.zF.prototype={
$0(){return B.tP},
$S:36}
A.YS.prototype={
Sw(a,b,c,d,e,f,g,h,i){var t,s,r,q,p,o,n,m=this,l=u.h
l.a(g)
u.k.a(d)
l.a(h)
l=c==null?m.a:c
t=a==null?m.b:a
s=i==null?m.c:i
r=e==null?m.d:e
q=f==null?m.e:f
p=b==null?m.f:b
o=g==null?m.r:g
n=d==null?m.w:d
return A.Nq(t,p,l,n,r,q,o,h==null?m.x:h,s)},
t9(a){var t=null
return this.Sw(t,t,t,a,t,t,t,t,t)},
Uw(a){var t=null
return this.Sw(t,t,a,t,t,t,t,t,t)},
OP(a){var t=null
return this.Sw(t,t,t,t,t,t,t,a,t)},
Cy(a){var t=null
return this.Sw(a,t,t,t,t,t,t,t,t)},
En(a,b){var t=null
return this.Sw(t,t,t,t,a,t,t,t,b)},
jb(a){var t=null
return this.Sw(t,t,t,t,t,t,a,t,t)},
l1(a){var t=null
return this.Sw(t,t,t,t,t,a,t,t,t)},
no(a){var t=null
return this.Sw(t,a,t,t,t,t,t,t,t)},
Lt(){var t=this
return A.EF(["cardsPlayed",t.a,"acesPlayed",t.b,"twosPlayed",t.c,"longestChain",t.d,"resets101",t.e,"bestComeback",t.f,"roundsWon",t.r,"cavalloSuits",t.w,"suitsPlayed",t.x],u.N,u.z)}}
A.GH.prototype={
$2(a,b){return new A.Yh(A.Bt(a),B.CD.yu(A.z5(b)),u.O)},
$S:3}
A.Pe.prototype={
$2(a,b){var t,s,r
A.Bt(a)
u.g.a(b)
t=b==null?B.dn:b
s=A.t6(t)
r=s.C("A8<1,qU>")
t=A.ev(new A.A8(t,s.C("qU(1)").a(new A.DC()),r),r.C("aL.E"))
return new A.Yh(a,t,u.q)},
$S:9}
A.DC.prototype={
$1(a){return A.Bt(a)},
$S:7}
A.us.prototype={
$2(a,b){return new A.Yh(A.Bt(a),B.CD.yu(A.z5(b)),u.O)},
$S:3}
A.j6.prototype={
q(){return"PlayerType."+this.b}}
A.LL.prototype={
$1(a){return u.bq.a(a).b===this.a},
$S:37}
A.JX.prototype={
$0(){return B.oN},
$S:38}
A.P6.prototype={
q(){return"BotDifficulty."+this.b}}
A.JA.prototype={
$1(a){return u.e.a(a).b===this.a},
$S:39}
A.Bv.prototype={
$0(){return B.J1},
$S:40}
A.Y8.prototype={
q(){return"BotPersonality."+this.b}}
A.mc.prototype={
$1(a){return u.B.a(a).b===this.a},
$S:41}
A.qa.prototype={
$0(){return B.QQ},
$S:42}
A.cJ.prototype={
Lt(){var t=this
return A.EF(["playerId",t.a,"name",t.b,"cardsLeft",t.c,"penalty",t.d,"previousScore",t.e,"newScore",t.f,"hitExact101",t.r,"eliminated",t.w],u.N,u.z)}}
A.HO.prototype={
Lt(){var t=this,s=t.d,r=A.t6(s),q=r.C("A8<1,T8<qU,@>>")
s=A.ev(new A.A8(s,r.C("T8<qU,@>(1)").a(new A.DR()),q),q.C("aL.E"))
return A.EF(["roundNumber",t.a,"winnerId",t.b,"winnerName",t.c,"rows",s,"matchOver",t.e,"matchWinnerId",t.f],u.N,u.z)}}
A.DR.prototype={
$1(a){return u.ct.a(a).Lt()},
$S:43}
A.iO.prototype={
$1(a){var t,s,r,q,p,o,n,m
u.P.a(a)
t=A.Bt(a.WH(0,"playerId"))
s=A.Bt(a.WH(0,"name"))
r=B.CD.yu(A.z5(a.WH(0,"cardsLeft")))
q=B.CD.yu(A.z5(a.WH(0,"penalty")))
p=B.CD.yu(A.z5(a.WH(0,"previousScore")))
o=B.CD.yu(A.z5(a.WH(0,"newScore")))
n=A.M4(a.WH(0,"hitExact101"))
m=A.M4(a.WH(0,"eliminated"))
return new A.cJ(t,s,r,q,p,o,n===!0,m===!0)},
$S:44}
A.e.prototype={
$1(a){return A.uR(A.Bt(a))},
$S:45}
A.L.prototype={
$3(a,b,c){A.Bt(a)
A.Bt(b)
A.Qk(c)
return A.Fw(a,b,c==null?null:A.IZ(c))},
$S:46}
A.em.prototype={
$2(a,b){return A.cA(A.Bt(a),A.Bt(b))},
$S:4}
A.Lb.prototype={
$2(a,b){return A.YB(A.Bt(a),A.Bt(b))},
$S:4}
A.QA.prototype={
$0(){return"gioco101-engine/schema3"},
$S:48};(function aliases(){var t=J.zh.prototype
t.u=t["["]})();(function installTearOffs(){var t=hunkHelpers._static_1
t(A,"Cy","tp",49)
t(A,"xo","ts",33)})();(function inheritance(){var t=hunkHelpers.mixin,s=hunkHelpers.inherit,r=hunkHelpers.inheritMany
s(A.Mh,null)
r(A.Mh,[A.FK,J.vB,A.rY,J.m1,A.cX,A.Cf,A.il,A.Tp,A.Ge,A.zl,A.a7,A.MH,A.SO,A.S5,A.Pn,A.ys,A.vI,A.Zr,A.te,A.vh,A.N6,A.Gf,A.HQ,A.Jc,A.G,A.lY,A.GV,A.Vj,A.bn,A.lm,A.Uq,A.KP,A.Uk,A.ze,A.Sh,A.ck,A.VS,A.aE,A.Yh,A.c8,A.Rn,A.vY,A.vr,A.Mm,A.LE,A.xz,A.xk,A.ON,A.F2,A.a2,A.bd,A.Ee,A.k7,A.cw,A.pO,A.YS,A.cJ,A.HO])
r(J.vB,[J.yE,J.CD,J.MF,J.qI,J.Dr])
r(J.MF,[J.zh,J.jd])
r(J.zh,[J.iC,J.kd,J.c5])
s(J.BC,A.rY)
s(J.Po,J.jd)
r(J.qI,[J.im,J.kD])
r(A.cX,[A.BR,A.bQ,A.i1,A.oi,A.Ku,A.q4])
s(A.Zy,A.BR)
s(A.ol,A.Zy)
r(A.il,[A.by,A.N5,A.uw])
r(A.Tp,[A.E1,A.oB,A.Ay,A.lc,A.mb,A.FE,A.DO,A.rg,A.If,A.YE,A.lZ,A.FZ,A.Pp,A.Ul,A.He,A.mB,A.os,A.XY,A.Na,A.pn,A.Nc,A.Sq,A.LF,A.Ff,A.ZL,A.Aj,A.Wn,A.ZT,A.wp,A.zU,A.dQ,A.EG,A.kj,A.On,A.da,A.Lr,A.QU,A.n8,A.FQ,A.T2,A.DC,A.LL,A.JA,A.mc,A.DR,A.iO,A.e,A.L])
r(A.E1,[A.aA,A.hN,A.EM,A.EH,A.ra,A.ti,A.qR,A.yt,A.Cp,A.AU,A.GH,A.Pe,A.us,A.em,A.Lb])
r(A.Ge,[A.n,A.Ez,A.az,A.vV,A.Eq,A.u9,A.Ud,A.C6,A.AT,A.ub,A.lj,A.UV])
r(A.bQ,[A.aL,A.Gp,A.GP,A.C5,A.wU])
s(A.xy,A.i1)
r(A.aL,[A.A8,A.i8])
s(A.nz,A.S5)
s(A.LN,A.nz)
s(A.RU,A.Pn)
s(A.Gj,A.RU)
s(A.PD,A.Gj)
r(A.ys,[A.LP,A.kz])
s(A.W0,A.Ez)
r(A.lc,[A.zx,A.rT])
s(A.cL,A.N5)
s(A.iM,A.u9)
s(A.Xv,A.Vj)
s(A.PZ,A.Xv)
s(A.K8,A.Ud)
s(A.D4,A.Uk)
r(A.ze,[A.oj,A.Mx])
s(A.Gs,A.Sh)
r(A.AT,[A.bJ,A.eY])
r(A.ck,[A.QB,A.tN,A.ed,A.z0,A.uj,A.Sv,A.Br,A.kQ,A.am,A.eZ,A.j6,A.P6,A.Y8])
r(A.Ay,[A.Ax,A.Nj,A.YA,A.o2,A.QW,A.Ij,A.Ko,A.WB,A.zF,A.JX,A.Bv,A.qa,A.QA])
r(A.LE,[A.ry,A.M7,A.Pt,A.Cx,A.O3,A.E4,A.GE,A.Mw,A.wz,A.oN,A.hc,A.H0,A.Gt,A.GO,A.fM,A.bG,A.qv])
r(A.xz,[A.dK,A.KY])
r(A.a2,[A.e3,A.N3,A.OA,A.ew,A.wa,A.hP,A.eK])
t(A.RU,A.KP)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{KN:"int",CP:"double",lf:"num",qU:"String",a0:"bool",c8:"Null",zM:"List",Mh:"Object",T8:"Map",vm:"JSObject"},mangledNames:{},types:["a0(Ee)","qU(bd)","a0(bd)","Yh<qU,KN>(@,@)","qU(qU,qU)","~(Mh?,Mh?)","0&()","qU(@)","bd(@)","Yh<qU,zM<qU>>(@,@)","Sv()","@(qU)","a0(z0)","z0()","a0(uj)","uj()","a0(Sv)","~(@,@)","a0(Br)","Br()","a0(kQ)","kQ()","a0(am)","am()","KN(KN,Ee)","T8<qU,@>(Ee)","T8<qU,@>(pO)","zM<bd>(Mh?)","Ee(@)","qU(Ee)","pO(@)","a0(tN)","KN(KN,bd)","fL(cw)","a0(Yh<QB,KN>)","a0(eZ)","eZ()","a0(j6)","j6()","a0(P6)","P6()","a0(Y8)","Y8()","T8<qU,@>(cJ)","cJ(@)","qU(qU)","qU(qU,qU,CP?)","a0(QB)","qU()","@(@)","a0(qU)"],arrayRti:Symbol("$ti"),rttc:{"2;":(a,b)=>c=>c instanceof A.LN&&a.b(c.a)&&b.b(c.b)}}
A.xb(v.typeUniverse,JSON.parse('{"c5":"zh","iC":"zh","kd":"zh","yE":{"a0":[],"y5":[]},"CD":{"y5":[]},"MF":{"vm":[]},"zh":{"vm":[]},"jd":{"zM":["1"],"bQ":["1"],"vm":[],"cX":["1"]},"BC":{"rY":[]},"Po":{"jd":["1"],"zM":["1"],"bQ":["1"],"vm":[],"cX":["1"]},"m1":{"An":["1"]},"qI":{"CP":[],"lf":[]},"im":{"CP":[],"KN":[],"lf":[],"y5":[]},"kD":{"CP":[],"lf":[],"y5":[]},"Dr":{"qU":[],"y5":[]},"BR":{"cX":["2"]},"Cf":{"An":["2"]},"Zy":{"BR":["1","2"],"cX":["2"],"cX.E":"2"},"ol":{"Zy":["1","2"],"BR":["1","2"],"bQ":["2"],"cX":["2"],"cX.E":"2"},"by":{"il":["3","4"],"T8":["3","4"],"il.K":"3","il.V":"4"},"n":{"Ge":[]},"bQ":{"cX":["1"]},"aL":{"bQ":["1"],"cX":["1"]},"a7":{"An":["1"]},"i1":{"cX":["2"],"cX.E":"2"},"xy":{"i1":["1","2"],"bQ":["2"],"cX":["2"],"cX.E":"2"},"MH":{"An":["2"]},"A8":{"aL":["2"],"bQ":["2"],"cX":["2"],"aL.E":"2","cX.E":"2"},"oi":{"cX":["1"],"cX.E":"1"},"SO":{"An":["1"]},"LN":{"nz":[],"S5":[]},"PD":{"Gj":["1","2"],"RU":["1","2"],"Pn":["1","2"],"KP":["1","2"],"T8":["1","2"]},"ys":{"T8":["1","2"]},"LP":{"ys":["1","2"],"T8":["1","2"]},"Ku":{"cX":["1"],"cX.E":"1"},"vI":{"An":["1"]},"kz":{"ys":["1","2"],"T8":["1","2"]},"W0":{"Ge":[]},"az":{"Ge":[]},"vV":{"Ge":[]},"Tp":{"fK":[]},"Ay":{"fK":[]},"E1":{"fK":[]},"lc":{"fK":[]},"zx":{"fK":[]},"rT":{"fK":[]},"Eq":{"Ge":[]},"N5":{"il":["1","2"],"Fo":["1","2"],"T8":["1","2"],"il.K":"1","il.V":"2"},"Gp":{"bQ":["1"],"cX":["1"],"cX.E":"1"},"N6":{"An":["1"]},"GP":{"bQ":["1"],"cX":["1"],"cX.E":"1"},"Gf":{"An":["1"]},"C5":{"bQ":["Yh<1,2>"],"cX":["Yh<1,2>"],"cX.E":"Yh<1,2>"},"HQ":{"An":["Yh<1,2>"]},"cL":{"N5":["1","2"],"il":["1","2"],"Fo":["1","2"],"T8":["1","2"],"il.K":"1","il.V":"2"},"nz":{"S5":[]},"u9":{"Ge":[]},"iM":{"Ge":[]},"GV":{"An":["1"]},"q4":{"cX":["1"],"cX.E":"1"},"PZ":{"Vj":["1"],"bQ":["1"],"cX":["1"]},"lm":{"An":["1"]},"il":{"T8":["1","2"]},"wU":{"bQ":["2"],"cX":["2"],"cX.E":"2"},"Uq":{"An":["2"]},"Pn":{"T8":["1","2"]},"Gj":{"RU":["1","2"],"Pn":["1","2"],"KP":["1","2"],"T8":["1","2"]},"Vj":{"bQ":["1"],"cX":["1"]},"Xv":{"Vj":["1"],"bQ":["1"],"cX":["1"]},"uw":{"il":["qU","@"],"T8":["qU","@"],"il.K":"qU","il.V":"@"},"i8":{"aL":["qU"],"bQ":["qU"],"cX":["qU"],"aL.E":"qU","cX.E":"qU"},"Ud":{"Ge":[]},"K8":{"Ge":[]},"CP":{"lf":[]},"KN":{"lf":[]},"zM":{"bQ":["1"],"cX":["1"]},"C6":{"Ge":[]},"Ez":{"Ge":[]},"AT":{"Ge":[]},"bJ":{"Ge":[]},"eY":{"Ge":[]},"ub":{"Ge":[]},"lj":{"Ge":[]},"UV":{"Ge":[]},"VS":{"Ge":[]},"Rn":{"BL":[]},"ry":{"LE":[]},"M7":{"LE":[]},"Pt":{"LE":[]},"Cx":{"LE":[]},"O3":{"LE":[]},"E4":{"LE":[]},"GE":{"LE":[]},"Mw":{"LE":[]},"wz":{"LE":[]},"oN":{"LE":[]},"hc":{"LE":[]},"H0":{"LE":[]},"Gt":{"LE":[]},"GO":{"LE":[]},"fM":{"LE":[]},"bG":{"LE":[]},"qv":{"LE":[]},"e3":{"a2":[]},"N3":{"a2":[]},"OA":{"a2":[]},"ew":{"a2":[]},"wa":{"a2":[]},"hP":{"a2":[]},"eK":{"a2":[]}}'))
A.FF(v.typeUniverse,JSON.parse('{"Xv":1,"Uk":2,"ze":2}'))
var u=(function rtii(){var t=A.q7
return{e:t("P6"),B:t("Y8"),c:t("QB"),D:t("tN"),r:t("N3"),Q:t("bQ<@>"),C:t("Ge"),E:t("hP"),Z:t("fK"),U:t("bd"),J:t("LE"),l:t("kQ"),u:t("Ee"),A:t("cw"),M:t("am"),p:t("kz<QB,KN>"),n:t("pO"),W:t("eZ"),bi:t("cX<@>"),Y:t("jd<bd>"),c4:t("jd<LE>"),R:t("jd<Ee>"),G:t("jd<Mh>"),bL:t("jd<cJ>"),s:t("jd<qU>"),o:t("jd<@>"),T:t("CD"),m:t("vm"),L:t("c5"),v:t("zM<bd>"),F:t("zM<LE>"),w:t("zM<Ee>"),a:t("zM<qU>"),j:t("zM<@>"),bX:t("Yh<QB,KN>"),O:t("Yh<qU,KN>"),q:t("Yh<qU,zM<qU>>"),P:t("T8<qU,@>"),f:t("T8<@,@>"),aX:t("z0"),b:t("c8"),K:t("Mh"),d:t("e3"),ct:t("cJ"),bq:t("j6"),cY:t("VY"),cD:t("+()"),ak:t("Sv"),_:t("uj"),N:t("qU"),bW:t("y5"),bf:t("Br"),cr:t("kd"),y:t("a0"),i:t("CP"),z:t("@"),S:t("KN"),bc:t("b8<c8>?"),aQ:t("vm?"),t:t("zM<bd>?"),b0:t("zM<Ee>?"),aI:t("zM<pO>?"),g:t("zM<@>?"),h:t("T8<qU,KN>?"),V:t("T8<@,@>?"),k:t("T8<qU,zM<qU>>?"),X:t("Mh?"),x:t("qU?"),c8:t("bn?"),cG:t("a0?"),dd:t("CP?"),I:t("KN?"),ae:t("lf?"),H:t("lf"),cQ:t("~(qU,@)")}})();(function constants(){var t=hunkHelpers.makeConstList
B.Ok=J.vB.prototype
B.Nm=J.jd.prototype
B.jn=J.im.prototype
B.CD=J.qI.prototype
B.xB=J.Dr.prototype
B.Ub=J.MF.prototype
B.J1=new A.P6(1,"normal")
B.QQ=new A.Y8(3,"calm")
B.Zt=new A.Mm()
B.O4=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.Ct=new A.D4()
B.zt=new A.zl()
B.Mf=new A.QB(1,0,"asso")
B.GO=new A.QB(2,1,"due")
B.VV=new A.QB(3,2,"tre")
B.S8=new A.QB(4,3,"quattro")
B.mh=new A.QB(5,4,"cinque")
B.pc=new A.QB(6,5,"sei")
B.Sp=new A.QB(7,6,"sette")
B.TJ=new A.QB(9,8,"cavallo")
B.a7=new A.tN(0,"denari")
B.WG=new A.aE("Empty discard pile")
B.N7=new A.aE("Missing active suit")
B.Qd=new A.aE("A match needs at least two seats")
B.OB=new A.aE("Turn cursor points outside the table")
B.fi=new A.aE("Duplicate player id")
B.ug=new A.ed(0,"notPlayersTurn")
B.tA=new A.ed(1,"cardNotOwned")
B.iY=new A.ed(10,"roundNotOver")
B.VE=new A.ed(11,"staleState")
B.oC=new A.ed(12,"invalidState")
B.Ti=new A.ed(13,"lastCardDeclarationRequired")
B.Od=new A.ed(14,"lastCardDeclarationNotAllowed")
B.BU=new A.ed(15,"invalidPlayerCount")
B.UR=new A.ed(16,"duplicatePlayer")
B.wH=new A.ed(2,"illegalCard")
B.v1=new A.ed(3,"drawRequired")
B.u3=new A.ed(4,"drawNotAllowed")
B.Jn=new A.ed(5,"suitSelectionRequired")
B.Ip=new A.ed(6,"suitSelectionNotPending")
B.HJ=new A.ed(7,"invalidPlayer")
B.GL=new A.ed(8,"gameFinished")
B.F5=new A.ed(9,"roundOver")
B.AF=new A.kQ(0,"vsComputer")
B.cq=new A.z0(1,"cancel")
B.WJ=new A.uj(0,"avoidActionCards")
B.nk=new A.Sv(0,"previousRoundWinner")
B.Up=new A.Br(0,"clockwise")
B.EY=new A.QB(8,7,"fante")
B.TH=new A.QB(10,9,"re")
B.IY=new A.kz([B.Mf,1,B.GO,2,B.VV,3,B.S8,4,B.mh,5,B.pc,6,B.Sp,7,B.EY,25,B.TJ,25,B.TH,10],u.p)
B.GX=new A.k7(2,4,5,!0,!0,!1,!0,!0,B.cq,!0,!0,!0,101,!0,2,!1,B.WJ,B.nk,B.Up,null,!0,B.IY)
B.zy=new A.ed(17,"invalidRules")
B.yN=new A.xk(B.zy,"startingHandSize does not fit the 40-card deck")
B.ob=new A.xk(B.zy,"drawTwoPenalty must be >= 0 and targetScore >= 1")
B.vc=new A.am(0,"awaitingAction")
B.cT=new A.am(1,"awaitingSuitChoice")
B.Jz=new A.am(2,"roundOver")
B.qg=new A.am(3,"finished")
B.tP=new A.eZ(0,"play")
B.CS=new A.eZ(1,"draw")
B.Dc=new A.eZ(2,"penaltyDraw")
B.kI=new A.eZ(3,"skip")
B.l2=new A.eZ(4,"suitChosen")
B.u5=new A.eZ(5,"chainBlocked")
B.vp=new A.eZ(6,"lastCardDeclared")
B.o0=new A.eZ(7,"recycle")
B.pk=new A.eZ(8,"roundEnd")
B.yn=new A.eZ(9,"forfeit")
B.A3=new A.Mx(null)
B.nX=new A.oj(null)
B.hL=t([B.tP,B.CS,B.Dc,B.kI,B.l2,B.u5,B.vp,B.o0,B.pk,B.yn],A.q7("jd<eZ>"))
B.bP=t([B.vc,B.cT,B.Jz,B.qg],A.q7("jd<am>"))
B.J6=new A.z0(0,"disabled")
B.Lf=new A.z0(2,"passOn")
B.le=t([B.J6,B.cq,B.Lf],A.q7("jd<z0>"))
B.bB=new A.kQ(1,"passAndPlay")
B.i1=t([B.AF,B.bB],A.q7("jd<kQ>"))
B.nt=new A.j6(0,"humanLocal")
B.oN=new A.j6(1,"bot")
B.ej=t([B.nt,B.oN],A.q7("jd<j6>"))
B.dm=new A.Br(1,"counterClockwise")
B.hn=t([B.Up,B.dm],A.q7("jd<Br>"))
B.x0=t([B.Mf,B.GO,B.VV,B.S8,B.mh,B.pc,B.Sp,B.EY,B.TJ,B.TH],A.q7("jd<QB>"))
B.r3=new A.uj(1,"anyCard")
B.OI=t([B.WJ,B.r3],A.q7("jd<uj>"))
B.Da=new A.P6(0,"easy")
B.Rx=new A.P6(2,"hard")
B.pP=t([B.Da,B.J1,B.Rx],A.q7("jd<P6>"))
B.xD=t([],u.Y)
B.iH=t([],A.q7("jd<pO>"))
B.hU=t([],u.s)
B.dn=t([],u.o)
B.U0=new A.Sv(1,"seatAfterPreviousWinner")
B.Y2=t([B.nk,B.U0],A.q7("jd<Sv>"))
B.l4=new A.tN(1,"coppe")
B.QK=new A.tN(2,"spade")
B.vF=new A.tN(3,"bastoni")
B.H2=t([B.a7,B.l4,B.QK,B.vF],A.q7("jd<tN>"))
B.nh=new A.Y8(0,"aggressive")
B.mf=new A.Y8(1,"tactical")
B.pV=new A.Y8(2,"risky")
B.TL=t([B.nh,B.mf,B.pV,B.QQ],A.q7("jd<Y8>"))
B.yY=new A.kz([B.Mf,1,B.GO,2,B.VV,3,B.S8,4,B.mh,5,B.pc,6,B.Sp,7,B.EY,8,B.TJ,9,B.TH,10],u.p)
B.p6={}
B.Dx=new A.LP(B.p6,[],A.q7("LP<qU,zM<qU>>"))
B.WD=new A.LP(B.p6,[],A.q7("LP<qU,KN>"))
B.CM=new A.LP(B.p6,[],A.q7("LP<qU,@>"))
B.WO=new A.LP(B.p6,[],A.q7("LP<@,@>"))
B.jY={ace:0,two:1,three:2,four:3,five:4,six:5,seven:6}
B.W9=new A.LP(B.jY,[B.Mf,B.GO,B.VV,B.S8,B.mh,B.pc,B.Sp],A.q7("LP<qU,QB>"))
B.Nu=A.xq("vm")
B.h0=A.xq("Mh")})();(function staticFields(){$.xg=A.QI([],u.G)
$.xu=null
$.i0=null
$.Al=null
$.lb=A.QI([],A.q7("jd<zM<Mh>?>"))})();(function lazyInitializers(){var t=hunkHelpers.lazyFinal
t($,"fa","wQ",()=>A.Yg("_$dart_dartClosure"))
t($,"cK","C",()=>A.Yg("_$dart_dartClosure_dartJSInterop"))
t($,"hJ","Ve",()=>A.QI([new J.BC()],A.q7("jd<rY>")))
t($,"U2","Sn",()=>A.cM(A.S7({
toString:function(){return"$receiver$"}})))
t($,"NJ","lq",()=>A.cM(A.S7({$method$:null,
toString:function(){return"$receiver$"}})))
t($,"Re","N9",()=>A.cM(A.S7(null)))
t($,"fN","iI",()=>A.cM(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"qi","UN",()=>A.cM(A.S7(void 0)))
t($,"rZ","Zh",()=>A.cM(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(s){return s.message}}()))
t($,"BX","rN",()=>A.cM(A.Mj(null)))
t($,"tt","c3",()=>A.cM(function(){try{null.$method$}catch(s){return s.message}}()))
t($,"dt","HK",()=>A.cM(A.Mj(void 0)))
t($,"A7","r1",()=>A.cM(function(){try{(void 0).$method$}catch(s){return s.message}}()))
t($,"X0","t8",()=>A.CU(B.h0))
t($,"WO","Sj",()=>{var s,r,q,p=A.QI([],u.Y)
for(s=0;s<4;++s){r=B.H2[s]
for(q=0;q<10;++q)p.push(A.er(r,B.x0[q]))}return A.AF(p,u.U)})})();(function nativeSupport(){!function(){var t=function(a){var n={}
n[a]=1
return Object.keys(hunkHelpers.convertToFastObject(n))[0]}
v.getIsolateTag=function(a){return t("___dart_"+a+v.isolateTag)}
var s="___dart_isolate_tags_"
var r=Object[s]||(Object[s]=Object.create(null))
var q="_ZxYxX"
for(var p=0;;p++){var o=t(q+"_"+p+"_")
if(!(o in r)){r[o]=1
v.isolateTag=o
break}}}()
hunkHelpers.setOrUpdateInterceptorsByTag({})
hunkHelpers.setOrUpdateLeafTags({})})()
Function.prototype.$0=function(){return this()}
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$2$0=function(){return this()}
Function.prototype.$2$1=function(a){return this(a)}
Function.prototype.$1$1=function(a){return this(a)}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var t=document.scripts
function onLoad(b){for(var r=0;r<t.length;++r){t[r].removeEventListener("load",onLoad,false)}a(b.target)}for(var s=0;s<t.length;++s){t[s].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var t=A.E2
if(typeof dartMainRunner==="function"){dartMainRunner(t,[])}else{t([])}})})()