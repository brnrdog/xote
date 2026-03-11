(function(){const i=document.createElement("link").relList;if(i&&i.supports&&i.supports("modulepreload"))return;for(const c of document.querySelectorAll('link[rel="modulepreload"]'))l(c);new MutationObserver(c=>{for(const a of c)if(a.type==="childList")for(const d of a.addedNodes)d.tagName==="LINK"&&d.rel==="modulepreload"&&l(d)}).observe(document,{childList:!0,subtree:!0});function r(c){const a={};return c.integrity&&(a.integrity=c.integrity),c.referrerPolicy&&(a.referrerPolicy=c.referrerPolicy),c.crossOrigin==="use-credentials"?a.credentials="include":c.crossOrigin==="anonymous"?a.credentials="omit":a.credentials="same-origin",a}function l(c){if(c.ep)return;c.ep=!0;const a=r(c);fetch(c.href,a)}})();let De={contents:0};function Le(){return De.contents=De.contents+1|0,De.contents}function Qt(n){return n===void 0?{BS_PRIVATE_NESTED_SOME_NONE:0}:n!==null&&n.BS_PRIVATE_NESTED_SOME_NONE!==void 0?{BS_PRIVATE_NESTED_SOME_NONE:n.BS_PRIVATE_NESTED_SOME_NONE+1|0}:n}function Xe(n){if(n!=null)return Qt(n)}function $(n){if(n===null||n.BS_PRIVATE_NESTED_SOME_NONE===void 0)return n;let i=n.BS_PRIVATE_NESTED_SOME_NONE;if(i!==0)return{BS_PRIVATE_NESTED_SOME_NONE:i-1|0}}function ot(n,i){return n!==void 0?$(n):i}function Zt(n,i,r){return n.reduce(r,i)}let E=new Map,ce=new Map,ue=new Map,y={contents:void 0},le=new Set,V={contents:!1},B={contents:!1};function $e(n){if(ce.get(n)===void 0){ce.set(n,new Set);return}}function en(n,i){let r=ce.get(n);if(r!==void 0){r.forEach(i);return}}function tn(n,i){let r=ce.get(n);if(r!==void 0){r.add(i);return}}function nn(n,i){let r=ce.get(n);if(r!==void 0){r.delete(i);return}}function sn(n){return Array.from(ot(ce.get(n),new Set).values())}function dt(n,i){let r=y.contents;y.contents=n;try{let l=i();return y.contents=r,l}catch(l){throw y.contents=r,l}}function rn(n){let i=y.contents;y.contents=void 0;try{let r=n();return y.contents=i,r}catch(r){throw y.contents=i,r}}function ln(n){let i=y.contents;return i!==void 0?i===n:!1}function cn(n){if(!V.contents){V.contents=!0;try{n(),V.contents=!1;return}catch(i){throw V.contents=!1,i}}}function an(n,i){$e(i);let r=ln(n),l=E.get(n);if(r&&l!==void 0&&!l.deps.has(i))return l.deps.add(i),tn(i,n)}function ae(n){n.deps.forEach(i=>nn(i,n.id)),n.deps.clear()}function on(n){let i=ue.get(n);if(i===void 0)return;ue.delete(n);let r=E.get(i);if(r!==void 0){ae(r),E.delete(i);return}}function ht(n){return Zt(n,0,(i,r)=>r>i?r:i)}function dn(n){let i=[];return n.deps.forEach(r=>en(r,l=>{if(l===n.id)return;let c=E.get(l);if(c===void 0)return;if(typeof c.kind=="object"){i.push(c.level);return}})),ht(i)+1|0}function hn(n){let i=[];return n.deps.forEach(r=>{let l=ue.get(r);if(l===void 0||l===n.id)return;let c=E.get(l);if(c!==void 0){i.push(c.level);return}}),ht(i)+1|0}function Te(n){return typeof n.kind=="object"?hn(n):dn(n)}function un(n,i){let r=E.get(n),l=E.get(i);if(r===void 0)return l!==void 0?1:0;if(l===void 0)return-1;let a=typeof r.kind=="object"?0:1,h=typeof l.kind=="object"?0:1,x=a-h|0;return x!==0?x:r.level-l.level|0}function xn(n){B.contents=!0,ae(n),dt(n.id,()=>{n.run(),B.contents=!1}),n.level=Te(n)}function ut(){for(;le.size>0;){let n=Array.from(le.values());le.clear(),n.sort(un),n.forEach(i=>{let r=E.get(i);if(r!==void 0)return xn(r)})}}function xt(n){if($e(n),sn(n).forEach(i=>{let r=E.get(i);if(r===void 0)return;let l=r.kind;if(typeof l=="object")return r.dirty?void 0:(r.dirty=!0,xt(l.VAL));le.add(i)}),le.size>0)return cn(ut)}function pt(n){let i=ue.get(n);if(i===void 0)return;let r=E.get(i);if(r!==void 0&&r.dirty){B.contents=!0,ae(r),dt(i,()=>{r.run(),r.dirty=!1,B.contents=!1}),r.level=Te(r);return}}function pn(n){let i=V.contents;V.contents=!0;try{let r=n();return i||(V.contents=!1,le.size>0&&ut()),r}catch(r){throw i||(V.contents=!1),r}}let mn=rn,gn=$e;function mt(n,i,r){let l=Le();return gn(l),{id:l,value:{contents:n},version:{contents:0},equals:ot(r,(c,a)=>c===a),name:i}}function fn(n){pt(n.id);let i=y.contents;return i!==void 0&&an(i,n.id),n.value.contents}function jn(n){return pt(n.id),n.value.contents}function gt(n,i){let r;try{r=!n.equals(n.value.contents,i)}catch{r=!0}if(r)return n.value.contents=i,n.version.contents=n.version.contents+1|0,xt(n.id)}function vn(n,i){gt(n,i(n.value.contents))}let Sn,bn,yn=pn,kn=mn;const wn=Object.freeze(Object.defineProperty({__proto__:null,Id:Sn,Scheduler:bn,batch:yn,get:fn,make:mt,peek:jn,set:gt,untrack:kn,update:vn},Symbol.toStringTag,{value:"Module"}));function ft(n,i,r,l){return{id:n,kind:i,run:r,deps:new Set,level:0,dirty:!0,name:l}}function Cn(n,i){let r=Le(),l={contents:void 0},a=ft(r,"Effect",()=>{let x=l.contents;x!==void 0&&x(),l.contents=n()},i);E.set(r,a),B.contents=!0,ae(a);let d=y.contents;y.contents=r;try{a.run(),B.contents=!1}catch(x){throw y.contents=d,B.contents=!1,x}return y.contents=d,a.level=Te(a),{dispose:()=>{let x=E.get(r);if(x===void 0)return;let S=l.contents;S!==void 0&&S(),ae(x),E.delete(r)}}}let Tn,_n,Rn;const En=Object.freeze(Object.defineProperty({__proto__:null,Id:Tn,Observer:_n,Scheduler:Rn,run:Cn},Symbol.toStringTag,{value:"Module"}));function An(n,i){let r=mt(void 0,i,void 0),l=Le(),c=()=>{let h=n();r.value.contents=h},a=ft(l,{NAME:"Computed",VAL:r.id},c,void 0);E.set(l,a),B.contents=!0,ae(a);let d=y.contents;y.contents=l;try{a.run(),a.dirty=!1,B.contents=!1}catch(h){throw y.contents=d,B.contents=!1,h}return y.contents=d,a.level=Te(a),ue.set(r.id,l),r}function In(n){on(n.id)}let Mn,Pn,Nn,Dn;const Xn=Object.freeze(Object.defineProperty({__proto__:null,Id:Mn,Observer:Nn,Scheduler:Dn,Signal:Pn,dispose:In,make:An},Symbol.toStringTag,{value:"Module"}));let g=wn,C=Xn,W=En;function On(n,i){let r=n.length,l=new Array(r),c=0;for(let a=0;a<r;++a){let d=n[a],h=i(d);h!==void 0&&(l[c]=$(h),c=c+1|0)}return l.length=c,l}function Ln(n,i){let r=0;for(;;){let l=r;if(l===n.length)return;let c=i(n[l]);if(c!==void 0)return c;r=l+1|0}}function $n(n){return On(n.split("/"),i=>{if(i!=="")return i.startsWith(":")?{TAG:"Param",_0:i.slice(1)}:{TAG:"Static",_0:i}})}function Un(n,i){let r=i.split("/").filter(a=>a!=="");if(n.length!==r.length)return"NoMatch";let l={};return n.every((a,d)=>{let h=r[d];return a.TAG==="Static"?h===a._0:(l[a._0]=h,!0)})?{TAG:"Match",_0:l}:"NoMatch"}function jt(n,i){return Un($n(n),i)}function Bn(n,i){delete n[i]}function Fn(n,i){return n!==void 0?$(n):i}function ee(n,i,r){switch(i){case"checked":n.checked=r==="true";return;case"disabled":n.disabled=r==="true";return;case"aria-expanded":case"aria-hidden":case"aria-selected":case"multiple":case"readonly":case"required":break;case"value":n.value=r;return;default:n.setAttribute(i,r);return}r==="true"?n.setAttribute(i,""):n.removeAttribute(i)}let Gn={setAttrOrProp:ee},Se={contents:void 0};function zn(){return{disposers:[],computeds:[]}}function te(n,i){let r=Se.contents;Se.contents=n;let l=i();return Se.contents=r,l}function ne(n,i){n.disposers.push(i)}function vt(n){n.disposers.forEach(i=>i.dispose()),n.computeds.forEach(i=>C.dispose(i))}function ie(n,i){n.__xote_owner__=i}function St(n){return Xe(n.__xote_owner__)}let Hn={currentOwner:Se,createOwner:zn,runWithOwner:te,addDisposer:ne,disposeOwner:vt,setOwner:ie,getOwner:St};function bt(n,i){return[n,{TAG:"Static",_0:i}]}function yt(n,i){return[n,{TAG:"SignalValue",_0:i}]}function kt(n,i){return[n,{TAG:"Compute",_0:i}]}let Wn={$$static:bt,signal:yt,computed:kt};function he(n){let i=St(n);i!==void 0&&vt(i),Array.from(n.childNodes||[]).forEach(he)}function H(n){switch(n.TAG){case"Element":let i=n.children,r=n.events,l=n.attrs,c=document.createElement(n.tag),a={disposers:[],computeds:[]};return ie(c,a),te(a,()=>{l.forEach(f=>{let w=f[1],P=f[0];switch(w.TAG){case"Static":return ee(c,P,w._0);case"SignalValue":let O=w._0;ee(c,P,g.peek(O));let L=W.run(()=>{ee(c,P,g.get(O))},void 0);return ne(a,L);case"Compute":let de=w._0;ee(c,P,de());let Z=W.run(()=>{ee(c,P,de())},void 0);return ne(a,Z)}}),r.forEach(f=>{c.addEventListener(f[0],f[1])}),i.forEach(f=>{let w=H(f);c.appendChild(w)})}),c;case"Text":return document.createTextNode(n._0);case"SignalText":let d=n._0,h=document.createTextNode(g.peek(d)),x={disposers:[],computeds:[]};return ie(h,x),te(x,()=>{let f=W.run(()=>{h.textContent=g.get(d)},void 0);ne(x,f)}),h;case"Fragment":let S=document.createDocumentFragment();return n._0.forEach(f=>{let w=H(f);S.appendChild(w)}),S;case"SignalFragment":let T=n._0,A={disposers:[],computeds:[]},R=document.createElement("div");return R.setAttribute("style","display: contents"),ie(R,A),te(A,()=>{let f=W.run(()=>{let w=g.get(T);Array.from(R.childNodes||[]).forEach(he),R.innerHTML="",w.forEach(O=>{let L=H(O);R.appendChild(L)})},void 0);ne(A,f)}),R;case"LazyComponent":let X={disposers:[],computeds:[]},pe=te(X,n._0),G=H(pe);return ie(G,X),G;case"KeyedList":let me=n.renderItem,Me=n.keyFn,Je=n.signal,Pe={disposers:[],computeds:[]},Ne=document.createComment(" keyed-list-start "),oe=document.createComment(" keyed-list-end ");ie(Ne,Pe);let q={},Vt=()=>{let f=oe.parentNode;if(f==null)return;let w=g.get(Je),P={};w.forEach(j=>{P[Me(j)]=j});let O=[];Object.keys(q).forEach(j=>{if(P[j]===void 0){O.push(j);return}}),O.forEach(j=>{let b=q[j];if(b!==void 0){he(b.element),b.element.remove(),Bn(q,j);return}});let L=[],de={};w.forEach(j=>{let b=Me(j),fe=q[b];if(fe!==void 0){if(fe.item!==j){de[b]=!0;let Jt=me(j),Yt=H(Jt),Qe={key:b,item:j,element:Yt};L.push(Qe),q[b]=Qe;return}L.push(fe);return}let qt=me(j),Kt=H(qt),Ye={key:b,item:j,element:Kt};L.push(Ye),q[b]=Ye});let Z={contents:Ne.nextSibling};L.forEach(j=>{let b=Z.contents;if(b==null){f.insertBefore(j.element,oe);return}if(b===oe){f.insertBefore(j.element,oe);return}if(b===j.element){Z.contents=b.nextSibling;return}Fn(de[j.key],!1)?(he(b),f.replaceChild(j.element,b),Z.contents=j.element.nextSibling):(f.insertBefore(j.element,b),Z.contents=j.element.nextSibling)})},ge=document.createDocumentFragment();return ge.appendChild(Ne),g.peek(Je).forEach(f=>{let w=Me(f),P=me(f),O=H(P),L={key:w,item:f,element:O};q[w]=L,ge.appendChild(O)}),ge.appendChild(oe),te(Pe,()=>{let f=W.run(()=>{Vt()},void 0);ne(Pe,f)}),ge}}let Vn={disposeElement:he,render:H};function qn(n){return{TAG:"Text",_0:n}}function Kn(n){return{TAG:"SignalText",_0:C.make(n,void 0)}}function Jn(n){return{TAG:"SignalText",_0:C.make(n,void 0)}}function Yn(n){return{TAG:"SignalText",_0:C.make(()=>n().toString(),void 0)}}function Qn(n){return{TAG:"SignalText",_0:C.make(()=>n().toString(),void 0)}}function Zn(n){return{TAG:"Text",_0:n.toString()}}function ei(n){return{TAG:"Text",_0:n.toString()}}function wt(n){return{TAG:"Fragment",_0:n}}function Ue(n){return{TAG:"SignalFragment",_0:n}}function ti(n,i){return{TAG:"SignalFragment",_0:C.make(()=>g.get(n).map(i),void 0)}}function ni(n,i,r){return{TAG:"KeyedList",signal:n,keyFn:i,renderItem:r}}function M(n,i,r,l,c){let a=i!==void 0?i:[].map(x=>x),d=r!==void 0?r:[].map(x=>x),h=l!==void 0?l:[].map(x=>x);return{TAG:"Element",tag:n,attrs:a,events:d,children:h}}function ii(n,i,r,l){return M("div",n,i,r)}function si(n,i,r,l){return M("span",n,i,r)}function ri(n,i,r,l){return M("button",n,i,r)}function li(n,i,r){return M("input",n,i,void 0)}function ci(n,i,r,l){return M("h1",n,i,r)}function ai(n,i,r,l){return M("h2",n,i,r)}function oi(n,i,r,l){return M("h3",n,i,r)}function di(n,i,r,l){return M("p",n,i,r)}function hi(n,i,r,l){return M("ul",n,i,r)}function ui(n,i,r,l){return M("li",n,i,r)}function Be(n,i,r,l){return M("a",n,i,r)}function xi(){return{TAG:"Text",_0:""}}function Ct(n,i){let r=H(n);i.appendChild(r)}function pi(n,i){let r=document.getElementById(i);if(r==null){console.error("Container element not found: "+i);return}else return Ct(n,r)}let F=bt,K=yt,_e=kt;const mi=Object.freeze(Object.defineProperty({__proto__:null,$$null:xi,Attributes:Wn,DOM:Gn,Reactivity:Hn,Render:Vn,a:Be,attr:F,button:ri,computedAttr:_e,div:ii,element:M,float:ei,fragment:wt,h1:ci,h2:ai,h3:oi,input:li,int:Zn,keyedList:ni,li:ui,list:ti,mount:Ct,mountById:pi,p:di,reactiveFloat:Qn,reactiveInt:Yn,reactiveString:Jn,signalAttr:K,signalFragment:Ue,span:si,text:qn,textSignal:Kn,ul:hi},Symbol.toStringTag,{value:"Module"}));function gi(){return Symbol.for("xote.router.state")}function I(){let n=globalThis[Symbol.for("xote.router.state")];if(n!==void 0)return n;let i={location:g.make({pathname:"/",search:"",hash:""},void 0,void 0),basePath:{contents:"/"},initialized:!1,popStateHandler:void 0};return globalThis[Symbol.for("xote.router.state")]=i,i}function fi(){return I().location}function ji(){return I().basePath}function J(n){if(!I().initialized)return console.warn("[Xote Router] "+n+" called before Router.init(). Make sure to call Router.init() at your app entry point. This may cause incorrect routing behavior.")}function Tt(n){if(n===""||n==="/")return"/";let i=n.startsWith("/")?n:"/"+n;return i.endsWith("/")?i.slice(0,i.length-1|0):i}function _t(n){let i=I().basePath.contents;return i==="/"?n:n===i?"/":n.startsWith(i+"/")?n.slice(i.length):n}function xe(n){let i=I().basePath.contents;return i==="/"?n:n==="/"?i:i+n}function Rt(){let n=window.scrollX||window.pageXOffset||0,i=window.scrollY||window.pageYOffset||0;return[n,i]}function Re(n,i){window.scrollTo(n,i)}function Et(n,i){return{scrollX:n,scrollY:i}}function Fe(){return{}}function At(n){let i=n&&n.scrollX,r=n&&n.scrollY;if(i!=null&&r!=null)return[i,r]}function It(){let n=Rt(),i=Et(n[0],n[1]),r=window.location.href;window.history.replaceState(i,"",r)}function Oe(){let n=window.location.pathname;return{pathname:_t(n),search:window.location.search,hash:window.location.hash}}function vi(n,i){let r=n!==void 0?n:"/",l=I(),c=Tt(r);if(l.basePath.contents=c,g.set(l.location,Oe()),l.initialized)return;let a=d=>{g.set(I().location,Oe());let h=window["history.state"];if(h==null)return;let x=At(h);if(x!==void 0)return Re(x[0],x[1])};l.popStateHandler=a,window.addEventListener("popstate",a),l.initialized=!0}function Ge(n,i,r,l){let c=i!==void 0?i:"",a=r!==void 0?r:"";J("Router.push()"),It();let d={pathname:n,search:c,hash:a},x=xe(n)+c+a;window.history.pushState(Fe(),"",x),g.set(I().location,d),Re(0,0)}function Si(n,i,r,l){let c=i!==void 0?i:"",a=r!==void 0?r:"";J("Router.replace()");let d={pathname:n,search:c,hash:a},x=xe(n)+c+a;window.history.replaceState(Fe(),"",x),g.set(I().location,d),Re(0,0)}function bi(n,i){return J("Router.route()"),Ue(C.make(()=>{let r=g.get(I().location),l=jt(n,r.pathname);return typeof l!="object"?[]:[i(l._0)]},void 0))}function yi(n){return J("Router.routes()"),Ue(C.make(()=>{let i=g.get(I().location),r=Ln(n,l=>{let c=jt(l.pattern,i.pathname);if(typeof c=="object")return l.render(c._0)});return r!==void 0?[r]:[]},void 0))}function ki(n,i,r,l){let c=i!==void 0?i:[],a=r!==void 0?r:[];J("Router.link()");let d=h=>{h.preventDefault(),Ge(n,void 0,void 0)};return Be(c.concat([F("href",xe(n))]),[["click",d]],a)}function Mt(n){return n&&typeof n=="object"&&"TAG"in n&&(n.TAG==="Static"||n.TAG==="Reactive")}function se(n,i){return Mt(i)?i.TAG==="Reactive"?K(n,i._0):F(n,i._0):typeof i=="function"?_e(n,i):typeof i=="object"?K(n,i):F(n,i)}function Pt(n){let i=[],r=n.class;r!==void 0&&i.push(se("class",$(r)));let l=n.id;l!==void 0&&i.push(se("id",$(l)));let c=n.style;c!==void 0&&i.push(se("style",$(c)));let a=n.target;a!==void 0&&i.push(se("target",$(a)));let d=n["aria-label"];return d!==void 0&&i.push(se("aria-label",$(d))),i}function Nt(n){let i=n.children;return i!==void 0?i.TAG==="Fragment"?i._0:[i]:[]}function be(n){J("Router.Link");let i=r=>{r.preventDefault(),Ge(n.to,void 0,void 0);let l=n.onClick;if(l!==void 0)return l(r)};return Be(Pt(n).concat([F("href",xe(n.to))]),[["click",i]],Nt(n))}function Ze(n,i,r){return be(n)}let wi={ReactiveProp:void 0,isReactiveProp:Mt,convertAttrValue:se,propsToAttrs:Pt,getChildren:Nt,make:be,jsx:be,jsxs:be,jsxKeyed:Ze,jsxsKeyed:Ze},Ci,Ti;const _i=Object.freeze(Object.defineProperty({__proto__:null,Component:Ci,Link:wi,Route:Ti,addBasePath:xe,basePath:ji,emptyHistoryState:Fe,getCurrentLocation:Oe,getGlobalState:I,getScrollFromState:At,getScrollPosition:Rt,getSymbolKey:gi,init:vi,link:ki,location:fi,makeHistoryState:Et,normalizeBasePath:Tt,push:Ge,replace:Si,route:bi,routes:yi,saveScrollPosition:It,scrollTo:Re,stripBasePath:_t,warnIfNotInitialized:J},Symbol.toStringTag,{value:"Module"}));function Ri(n){return n.TAG==="Reactive"?g.get(n._0):n._0}function Ei(n){return{TAG:"Static",_0:n}}function Ai(n){return{TAG:"Reactive",_0:n}}const Ii=Object.freeze(Object.defineProperty({__proto__:null,$$static:Ei,get:Ri,reactive:Ai},Symbol.toStringTag,{value:"Module"}));let Mi=g.Id,Pi=g.Scheduler,Ni=g.make,Di=g.get,Xi=g.peek,Oi=g.set,Li=g.update,$i=g.batch,Ui=g.untrack,o={Id:Mi,Scheduler:Pi,make:Ni,get:Di,peek:Xi,set:Oi,update:Li,batch:$i,untrack:Ui},Bi=C.Id,Fi=C.Signal,Gi=C.Observer,zi=C.Scheduler,Hi=C.make,Wi=C.dispose,D={Id:Bi,Signal:Fi,Observer:Gi,Scheduler:zi,make:Hi,dispose:Wi},Vi=W.Id,qi=W.Observer,Ki=W.Scheduler,Ji=W.run,Ee={Id:Vi,Observer:qi,Scheduler:Ki,run:Ji},t=mi,u=_i,je=Ii;function ke(n){let i=n.color,r=i!==void 0?i:"var(--text-accent)",l=n.size,c=l!==void 0?l.toString():"24";return t.element("div",[t.attr("style","width: "+c+"px; display: inline-flex;")],void 0,[t.element("svg",[t.attr("viewBox","0 0 37 52"),t.attr("fill","none"),t.attr("preserveAspectRatio","xMidYMid meet"),t.attr("style","color: "+r),t.attr("width","100%"),t.attr("height","100%")],void 0,[t.element("path",[t.attr("d","M18.4755 30.3333V26.3939M18.4755 30.3333L2.47549 42.9394M18.4755 30.3333V52"),t.attr("stroke","currentColor"),t.attr("stroke-width","8")],void 0,void 0,void 0),t.element("path",[t.attr("d","M18.4755 25.6061V21.6667L34.4755 9.06061"),t.attr("stroke","currentColor"),t.attr("stroke-width","8")],void 0,void 0,void 0),t.element("path",[t.attr("d","M18.4755 26.3939V23.4101V0"),t.attr("stroke","currentColor"),t.attr("stroke-width","8")],void 0,void 0,void 0),t.element("path",[t.attr("d","M18.4755 25.6061V28.5899V52"),t.attr("stroke","currentColor"),t.attr("stroke-width","8")],void 0,void 0,void 0),t.element("path",[t.attr("d","M34.4755 26L2.47549 26"),t.attr("stroke","currentColor"),t.attr("stroke-width","8")],void 0,void 0,void 0)],void 0)],void 0)}function p(n,i){return n(i)}let s=wt;function ze(n){return n&&typeof n=="object"&&"TAG"in n&&(n.TAG==="Static"||n.TAG==="Reactive")}function v(n,i){return ze(i)?i.TAG==="Reactive"?K(n,i._0):F(n,i._0):typeof i=="function"?_e(n,i):typeof i=="object"?K(n,i):F(n,i)}function z(n,i){if(ze(i)){if(i.TAG!=="Reactive")return F(n,i._0?"true":"false");let l=i._0,c=C.make(()=>g.get(l)?"true":"false",void 0);return K(n,c)}if(typeof i=="function")return _e(n,()=>i()?"true":"false");if(typeof i!="object")return F(n,i?"true":"false");let r=C.make(()=>g.get(i)?"true":"false",void 0);return K(n,r)}function m(n,i,r,l){if(i!==void 0){n.push(l(r,$(i)));return}}function re(n,i,r){if(i!==void 0){n.push(F(r,i.toString()));return}}function Dt(n){let i=[];m(i,n.id,"id",v),m(i,n.class,"class",v),m(i,n.style,"style",v),m(i,n.type,"type",v),m(i,n.name,"name",v),m(i,n.value,"value",v),m(i,n.placeholder,"placeholder",v),m(i,n.disabled,"disabled",z),m(i,n.checked,"checked",z),m(i,n.required,"required",z),m(i,n.readOnly,"readonly",z),re(i,n.maxLength,"maxlength"),re(i,n.minLength,"minlength"),m(i,n.min,"min",v),m(i,n.max,"max",v),m(i,n.step,"step",v),m(i,n.pattern,"pattern",v),m(i,n.autoComplete,"autocomplete",v),m(i,n.multiple,"multiple",z),m(i,n.accept,"accept",v),re(i,n.rows,"rows"),re(i,n.cols,"cols"),m(i,n.for,"for",v),m(i,n.href,"href",v),m(i,n.target,"target",v),m(i,n.src,"src",v),m(i,n.alt,"alt",v),m(i,n.width,"width",v),m(i,n.height,"height",v),m(i,n.role,"role",v),re(i,n.tabIndex,"tabindex"),m(i,n["aria-label"],"aria-label",v),m(i,n["aria-hidden"],"aria-hidden",z),m(i,n["aria-expanded"],"aria-expanded",z),m(i,n["aria-selected"],"aria-selected",z);let r=n.data;return r!==void 0&&Object.entries(r).forEach(([l,c])=>{i.push(v("data-"+l,c))}),i}function _(n,i,r){if(i!==void 0){n.push([r,$(i)]);return}}function Xt(n){let i=[];return _(i,n.onClick,"click"),_(i,n.onInput,"input"),_(i,n.onChange,"change"),_(i,n.onSubmit,"submit"),_(i,n.onFocus,"focus"),_(i,n.onBlur,"blur"),_(i,n.onKeyDown,"keydown"),_(i,n.onKeyUp,"keyup"),_(i,n.onMouseEnter,"mouseenter"),_(i,n.onMouseLeave,"mouseleave"),_(i,n.onMouseDown,"mousedown"),_(i,n.onMouseMove,"mousemove"),_(i,n.onMouseUp,"mouseup"),_(i,n.onContextMenu,"contextmenu"),i}function Ot(n){let i=n.children;return i!==void 0?i.TAG==="Fragment"?i._0:[i]:[]}function He(n,i){return{TAG:"Element",tag:n,attrs:Dt(i),events:Xt(i),children:Ot(i)}}let et=He;function tt(n,i,r,l){return He(n,i)}let e={isReactiveProp:ze,convertAttrValue:v,convertBoolAttrValue:z,addAttr:m,addIntAttr:re,propsToAttrs:Dt,addEvent:_,propsToEvents:Xt,getChildren:Ot,createElement:He,jsx:et,jsxs:et,jsxKeyed:tt,jsxsKeyed:tt};const Yi=[["path",{d:"M18 6 6 18"}],["path",{d:"m6 6 12 12"}]];const Qi=[["circle",{cx:"12",cy:"12",r:"4"}],["path",{d:"M12 2v2"}],["path",{d:"M12 20v2"}],["path",{d:"m4.93 4.93 1.41 1.41"}],["path",{d:"m17.66 17.66 1.41 1.41"}],["path",{d:"M2 12h2"}],["path",{d:"M20 12h2"}],["path",{d:"m6.34 17.66-1.41 1.41"}],["path",{d:"m19.07 4.93-1.41 1.41"}]];const Zi=[["rect",{width:"14",height:"14",x:"8",y:"8",rx:"2",ry:"2"}],["path",{d:"M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"}]];const es=[["circle",{cx:"12",cy:"12",r:"10"}],["path",{d:"M12 16v-4"}],["path",{d:"M12 8h.01"}]];const ts=[["path",{d:"M4 5h16"}],["path",{d:"M4 12h16"}],["path",{d:"M4 19h16"}]];const ns=[["path",{d:"M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401"}]];const is=[["path",{d:"M5 12h14"}],["path",{d:"M12 5v14"}]];const ss=[["path",{d:"M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z"}]];const rs=[["path",{d:"M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"}],["circle",{cx:"12",cy:"7",r:"4"}]];const ls=[["path",{d:"M20 6 9 17l-5-5"}]];const cs=[["path",{d:"M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5"}]];const as=[["path",{d:"M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"}],["path",{d:"M3 10a2 2 0 0 1 .709-1.528l7-6a2 2 0 0 1 2.582 0l7 6A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"}]];const os=[["path",{d:"M5 12h14"}]];const ds=[["path",{d:"M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6"}],["path",{d:"M3 6h18"}],["path",{d:"M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"}]];const hs=[["path",{d:"M15 22v-4a4.8 4.8 0 0 0-1-3.5c3 0 6-2 6-5.5.08-1.25-.27-2.48-1-3.5.28-1.15.28-2.35 0-3.5 0 0-1 0-3 1.5-2.64-.5-5.36-.5-8 0C6 2 5 2 5 2c-.3 1.15-.3 2.35 0 3.5A5.403 5.403 0 0 0 4 9c0 3.5 3 5.5 6 5.5-.39.49-.68 1.05-.85 1.65-.17.6-.22 1.23-.15 1.85v4"}],["path",{d:"M9 18c-4.51 2-5-2-7-2"}]];const us=[["path",{d:"M12 2v4"}],["path",{d:"m16.2 7.8 2.9-2.9"}],["path",{d:"M18 12h4"}],["path",{d:"m16.2 16.2 2.9 2.9"}],["path",{d:"M12 18v4"}],["path",{d:"m4.9 19.1 2.9-2.9"}],["path",{d:"M2 12h4"}],["path",{d:"m4.9 4.9 2.9 2.9"}]];const xs=[["path",{d:"M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z"}],["path",{d:"m15 5 4 4"}]];const ps=[["path",{d:"m21 21-4.34-4.34"}],["circle",{cx:"11",cy:"11",r:"8"}]];const ms=[["path",{d:"M12 3v12"}],["path",{d:"m17 8-5-5-5 5"}],["path",{d:"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"}]];const gs=[["path",{d:"M12 15V3"}],["path",{d:"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"}],["path",{d:"m7 10 5 5 5-5"}]];const fs=[["path",{d:"M9.671 4.136a2.34 2.34 0 0 1 4.659 0 2.34 2.34 0 0 0 3.319 1.915 2.34 2.34 0 0 1 2.33 4.033 2.34 2.34 0 0 0 0 3.831 2.34 2.34 0 0 1-2.33 4.033 2.34 2.34 0 0 0-3.319 1.915 2.34 2.34 0 0 1-4.659 0 2.34 2.34 0 0 0-3.32-1.915 2.34 2.34 0 0 1-2.33-4.033 2.34 2.34 0 0 0 0-3.831A2.34 2.34 0 0 1 6.35 6.051a2.34 2.34 0 0 0 3.319-1.915"}],["circle",{cx:"12",cy:"12",r:"3"}]];const js=[["path",{d:"m18 15-6-6-6 6"}]];const vs=[["path",{d:"m6 9 6 6 6-6"}]];const Ss=[["path",{d:"m15 18-6-6 6-6"}]];const bs=[["circle",{cx:"12",cy:"12",r:"10"}],["line",{x1:"12",x2:"12",y1:"8",y2:"12"}],["line",{x1:"12",x2:"12.01",y1:"16",y2:"16"}]];const ys=[["path",{d:"m9 18 6-6-6-6"}]];const ks=[["path",{d:"M15 3h6v6"}],["path",{d:"M10 14 21 3"}],["path",{d:"M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"}]];const ws=[["path",{d:"m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"}],["path",{d:"M12 9v4"}],["path",{d:"M12 17h.01"}]];function Lt(n){switch(n){case"Check":return ls;case"X":return Yi;case"ChevronDown":return vs;case"ChevronUp":return js;case"ChevronLeft":return Ss;case"ChevronRight":return ys;case"Search":return ps;case"Menu":return ts;case"Home":return as;case"User":return rs;case"Settings":return fs;case"Info":return es;case"AlertCircle":return bs;case"AlertTriangle":return ws;case"Loader":return us;case"Plus":return is;case"Minus":return os;case"Trash":return ds;case"Edit":return xs;case"Copy":return Zi;case"ExternalLink":return ks;case"Download":return gs;case"Upload":return ms;case"Heart":return cs;case"Star":return ss;case"Sun":return Qi;case"Moon":return ns;case"GitHub":return hs}}function $t(n){switch(n){case"Sm":return"16";case"Md":return"24";case"Lg":return"32";case"Xl":return"48"}}function Ut(n){return Object.entries(n).map(i=>i[0]+'="'+i[1]+'"').join(" ")}function Bt(n){return n.map(i=>{let r=i[0],l=Ut(i[1]);switch(r){case"circle":case"ellipse":case"line":case"path":case"polygon":case"polyline":case"rect":break;default:return""}return"<"+r+" "+l+' fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />'}).join("")}let ye={contents:0};function Cs(n,i){setTimeout(()=>{const r=document.getElementById(n);r&&!r.hasAttribute("data-svg-injected")&&(r.innerHTML=i,r.setAttribute("data-svg-injected","true"))},0)}function Ts(n){let i=n.color,r=n.class,l=n.size,c=l!==void 0?l:"Md",a=r!==void 0?r:je.$$static(""),d=i!==void 0?i:je.$$static("currentColor"),h=Lt(n.name),x=$t(c),S=Bt(h),T=D.make(()=>"basefn-icon "+je.get(a),void 0),A=D.make(()=>"color: "+je.get(d)+"; width: "+x+"px; height: "+x+"px; display: inline-flex;",void 0),R='<svg width="'+x+'" height="'+x+'" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style="width: 100%; height: 100%;">'+S+"</svg>";ye.contents=ye.contents+1|0;let X="basefn-icon-"+ye.contents.toString();return Cs(X,R),e.jsx("span",{id:X,class:T,style:A})}let _s=Ts;const Rs=Object.freeze(Object.defineProperty({__proto__:null,getIconData:Lt,iconIdCounter:ye,iconToSvgInner:Bt,make:_s,renderAttrs:Ut,sizeToPixels:$t},Symbol.toStringTag,{value:"Module"}));let we=o.make("Light",void 0,void 0);function We(n){return n==="Light"?"light":"dark"}function Ft(n){return n==="dark"?"Dark":"Light"}function Ve(n){(function(i){document.documentElement.classList.add("no-transitions"),document.documentElement.setAttribute("data-theme",i),document.documentElement.offsetHeight,requestAnimationFrame(()=>{document.documentElement.classList.remove("no-transitions")})})(We(n))}function Gt(n){(function(i){localStorage.setItem("basefn-theme",i)})(We(n))}function zt(){let n=localStorage.getItem("basefn-theme");return n!==void 0?Ft(n):"Light"}function Es(){let n=o.get(we),i;i=n==="Light"?"Dark":"Light",o.set(we,i),Ve(i),Gt(i)}function As(){let n=zt();o.set(we,n),Ve(n)}const Is=Object.freeze(Object.defineProperty({__proto__:null,applyTheme:Ve,currentTheme:we,init:As,loadThemePreference:zt,saveThemePreference:Gt,stringToTheme:Ft,themeToString:We,toggleTheme:Es},Symbol.toStringTag,{value:"Module"}));function Ms(n){let i=parseFloat(n);if(!isNaN(i))return i}function Ce(n){switch(n){case"Xs":return 480;case"Sm":return 640;case"Md":return 768;case"Lg":return 1024;case"Xl":return 1280;case"Xxl":return 1536}}function Y(n){return"(min-width: "+Ce(n).toString()+"px)"}function Q(n){return"(max-width: "+(Ce(n)-1|0).toString()+"px)"}function Ae(n,i){let r=Ce(n),l=Ce(i)-1|0;return"(min-width: "+r.toString()+"px) and (max-width: "+l.toString()+"px)"}Y("Xs");Y("Sm");Y("Md");Y("Lg");Y("Xl");Y("Xxl");Q("Xs");Q("Sm");Q("Md");Q("Lg");Q("Xl");Q("Xxl");Q("Sm");Ae("Sm","Md");Ae("Md","Lg");Ae("Lg","Xl");Ae("Xl","Xxl");Y("Xxl");let Ps=Is,k=Rs,nt=localStorage.getItem("xote-theme"),Ht=nt==null||nt!=="light"?"dark":"light";document.documentElement.setAttribute("data-theme",Ht);let qe=o.make(Ht,void 0,void 0);function Ns(){o.update(qe,n=>n==="dark"?"light":"dark")}Ee.run(()=>{let n=o.get(qe);document.documentElement.setAttribute("data-theme",n),localStorage.setItem("xote-theme",n),Ps.applyTheme(n==="dark"?"Dark":"Light")},void 0);let U=o.make(!1,void 0,void 0),it=o.make(!1,void 0,void 0),st=[{title:"Introduction",path:"/docs",section:"Getting Started"},{title:"Signals",path:"/docs/core-concepts/signals",section:"Core Concepts"},{title:"Computed",path:"/docs/core-concepts/computed",section:"Core Concepts"},{title:"Effects",path:"/docs/core-concepts/effects",section:"Core Concepts"},{title:"Batching",path:"/docs/core-concepts/batching",section:"Core Concepts"},{title:"Components Overview",path:"/docs/components/overview",section:"Components"},{title:"Router Overview",path:"/docs/router/overview",section:"Router"},{title:"Signals API",path:"/docs/api/signals",section:"API Reference"},{title:"React Comparison",path:"/docs/comparisons/react",section:"Comparisons"},{title:"Technical Overview",path:"/docs/technical-overview",section:"Advanced"}];function Ds(n){let i=o.make("",void 0,void 0),r=o.make(0,void 0,void 0),l=D.make(()=>{let h=o.get(i).toLowerCase();return h===""?st:st.filter(x=>x.title.toLowerCase().includes(h)?!0:x.section.toLowerCase().includes(h))},void 0),c=h=>{let x=h.target.value;o.set(i,x),o.set(r,0)},a=()=>{let h=o.peek(l),x=o.peek(r),S=h[x];if(S!==void 0)return u.push(S.path,void 0,void 0,void 0),o.set(U,!1),o.set(i,"")},d=h=>{switch(h.key){case"ArrowDown":h.preventDefault();let S=o.peek(l);return o.update(r,T=>T<(S.length-1|0)?T+1|0:T);case"ArrowUp":return h.preventDefault(),o.update(r,T=>T>0?T-1|0:0);case"Enter":return a();case"Escape":return o.set(U,!1),o.set(i,"");default:return}};return t.signalFragment(D.make(()=>o.get(U)?[t.element("div",[t.attr("class","search-overlay")],[["click",h=>{if((h.target.className||"").includes("search-overlay"))return o.set(U,!1),o.set(i,"")}]],[e.jsxs("div",{class:"search-modal",children:s([e.jsxs("div",{class:"search-input-wrapper",children:s([k.make({name:"Search",size:"Sm"}),t.input([t.attr("class","search-input"),t.attr("placeholder","Search documentation..."),t.attr("autofocus","true")],[["input",c],["keydown",d]],void 0),e.jsx("div",{class:"search-trigger-key",children:t.text("esc")})])}),e.jsx("div",{class:"search-results",children:t.signalFragment(D.make(()=>{let h=o.get(l),x=o.get(r);if(h.length===0)return[e.jsx("div",{class:"search-empty",children:t.text("No results found.")})];let S={contents:""},T={contents:0};return h.flatMap(A=>{let R=[];S.contents!==A.section&&(S.contents=A.section,R.push(e.jsx("div",{class:"search-group-label",children:t.text(A.section)})));let X=T.contents,G="search-result-item"+(X===x?" active":"");return R.push(t.element("div",[t.attr("class",G)],[["click",me=>{u.push(A.path,void 0,void 0,void 0),o.set(U,!1),o.set(i,"")}]],[e.jsx("div",{class:"search-result-title",children:t.text(A.title)})],void 0)),T.contents=X+1|0,R})},void 0))}),e.jsx("div",{class:"search-footer",children:t.text("Use arrow keys to navigate, Enter to select, Esc to close")})])})],void 0)]:[],void 0))}function Xs(n){return Ee.run(()=>{let i=()=>{let r=window.scrollY;o.set(it,r>10)};return window.addEventListener("scroll",i),()=>{window.removeEventListener("scroll",i)}},void 0),t.element("header",[t.computedAttr("class",()=>o.get(it)?"site-header scrolled":"site-header")],void 0,[e.jsxs("div",{class:"header-inner",children:s([e.jsxs("div",{class:"header-left",children:s([u.link("/",[t.attr("class","header-logo-link")],[p(ke,{color:"var(--text-accent)",size:20}),e.jsx("span",{class:"logo-text",children:t.text("xote")})],void 0),e.jsx("a",{class:"header-version",href:"https://www.npmjs.com/package/xote",target:"_blank",children:t.text("v4.15.1")}),e.jsxs("nav",{class:"header-nav",children:s([u.link("/docs",[t.attr("class","header-nav-link")],[t.text("Learn")],void 0),u.link("/docs/api/signals",[t.attr("class","header-nav-link")],[t.text("API Reference")],void 0),u.link("/demos",[t.attr("class","header-nav-link")],[t.text("Demos")],void 0)])})])}),e.jsxs("div",{class:"header-right",children:s([t.element("button",[t.attr("class","search-trigger")],[["click",i=>o.set(U,!0)]],[k.make({name:"Search",size:"Sm"}),e.jsx("span",{children:t.text("Search docs...")}),e.jsxs("div",{class:"search-trigger-keys",children:s([e.jsx("span",{class:"search-trigger-key",children:t.text("⌘")}),e.jsx("span",{class:"search-trigger-key",children:t.text("K")})])})],void 0),t.element("a",[t.attr("href","https://github.com/brnrdog/xote"),t.attr("target","_blank"),t.attr("class","header-icon-btn"),t.attr("title","GitHub")],void 0,[k.make({name:"GitHub",size:"Sm"})],void 0),t.element("button",[t.attr("class","header-icon-btn"),t.attr("title","Toggle theme")],[["click",i=>Ns()]],[t.signalFragment(D.make(()=>o.get(qe)==="dark"?[k.make({name:"Sun",size:"Sm"})]:[k.make({name:"Moon",size:"Sm"})],void 0))],void 0),t.element("button",[t.attr("class","header-icon-btn mobile-menu-btn"),t.attr("title","Menu")],[["click",i=>o.set(U,!0)]],[k.make({name:"Menu",size:"Sm"})],void 0)])})])})],void 0)}function Os(n){let i=new Date(Date.now()).getFullYear().toString();return e.jsx("footer",{class:"site-footer",children:e.jsxs("div",{class:"footer-inner",children:s([e.jsxs("div",{class:"footer-grid",children:s([e.jsxs("div",{class:"footer-brand",children:s([e.jsxs("div",{class:"footer-brand-logo",children:s([p(ke,{color:"var(--text-accent)",size:16}),e.jsx("span",{children:t.text("xote")})])}),e.jsx("p",{children:t.text("A lightweight UI library for ReScript with fine-grained reactivity powered by TC39 Signals.")})])}),e.jsxs("div",{class:"footer-col",children:s([e.jsx("h4",{children:t.text("Docs")}),e.jsxs("ul",{children:s([e.jsx("li",{children:u.link("/docs",void 0,[t.text("Getting Started")],void 0)}),e.jsx("li",{children:u.link("/docs/core-concepts/signals",void 0,[t.text("Core Concepts")],void 0)}),e.jsx("li",{children:u.link("/docs/api/signals",void 0,[t.text("API Reference")],void 0)})])})])}),e.jsxs("div",{class:"footer-col",children:s([e.jsx("h4",{children:t.text("Community")}),e.jsxs("ul",{children:s([e.jsx("li",{children:e.jsx("a",{href:"https://github.com/brnrdog/xote",target:"_blank",children:t.text("GitHub")})}),e.jsx("li",{children:e.jsx("a",{href:"https://www.npmjs.com/package/xote",target:"_blank",children:t.text("npm")})}),e.jsx("li",{children:u.link("/demos",void 0,[t.text("Demos")],void 0)})])})])}),e.jsxs("div",{class:"footer-col",children:s([e.jsx("h4",{children:t.text("More")}),e.jsxs("ul",{children:s([e.jsx("li",{children:e.jsx("a",{href:"https://rescript-lang.org/",target:"_blank",children:t.text("ReScript")})}),e.jsx("li",{children:e.jsx("a",{href:"https://github.com/tc39/proposal-signals",target:"_blank",children:t.text("TC39 Signals")})}),e.jsx("li",{children:e.jsx("a",{href:"https://github.com/pedrobslisboa/rescript-signals",target:"_blank",children:t.text("rescript-signals")})})])})])})])}),e.jsxs("div",{class:"footer-bottom",children:s([e.jsx("div",{children:t.text("Copyright © "+i+" Bernardo Gurgel. MIT License.")}),e.jsxs("div",{class:"footer-bottom-right",children:s([t.text("Built with "),p(ke,{color:"var(--text-accent)",size:14}),t.text(" xote")])})])})])})})}Ee.run(()=>{let n=i=>{let r=i.ctrlKey||i.metaKey,l=i.key;if(r&&l==="k")return i.preventDefault(),o.peek(U)?o.set(U,!1):o.set(U,!0)};return window.addEventListener("keydown",n),()=>{window.removeEventListener("keydown",n)}},void 0);function Ie(n){return e.jsxs("div",{children:s([p(Xs,{}),e.jsx("main",{id:"main-content",children:n.children}),p(Os,{}),p(Ds,{})])})}let Ke=[{label:"Getting Started",items:[{title:"Introduction",path:"/docs"}]},{label:"Core Concepts",items:[{title:"Signals",path:"/docs/core-concepts/signals"},{title:"Computed",path:"/docs/core-concepts/computed"},{title:"Effects",path:"/docs/core-concepts/effects"},{title:"Batching",path:"/docs/core-concepts/batching"}]},{label:"Components",items:[{title:"Overview",path:"/docs/components/overview"}]},{label:"Router",items:[{title:"Overview",path:"/docs/router/overview"}]},{label:"API Reference",items:[{title:"Signals",path:"/docs/api/signals"}]},{label:"Comparisons",items:[{title:"React",path:"/docs/comparisons/react"}]},{label:"Advanced",items:[{title:"Technical Overview",path:"/docs/technical-overview"}]}],ve=Ke.flatMap(n=>n.items);function Ls(n){let i=ve.findIndex(c=>c.path===n),r=i>0?ve[i-1|0]:void 0,l=i>=0&&i<(ve.length-1|0)?ve[i+1|0]:void 0;return[r,l]}function Wt(n){let i={contents:["",""]};return Ke.forEach(r=>{r.items.forEach(l=>{if(l.path===n){i.contents=[r.label,l.title];return}})}),i.contents}function $s(n){let i=n.currentPath;return e.jsx("aside",{class:"docs-sidebar",children:t.fragment(Ke.map(r=>e.jsxs("div",{class:"sidebar-section",children:s([e.jsx("div",{class:"sidebar-section-title",children:t.text(r.label)}),t.fragment(r.items.map(l=>{let a="sidebar-link"+(i===l.path?" active":"");return u.link(l.path,[t.attr("class",a)],[t.text(l.title)],void 0)}))])})))})}function Us(n){let i=Wt(n.currentPath),r=i[0];return e.jsxs("nav",{class:"docs-breadcrumb",children:s([u.link("/docs",void 0,[t.text("Docs")],void 0),r!==""&&r!=="Getting Started"?t.fragment([e.jsx("span",{class:"docs-breadcrumb-sep",children:t.text("/")}),e.jsx("span",{children:t.text(r)})]):t.fragment([]),e.jsx("span",{class:"docs-breadcrumb-sep",children:t.text("/")}),e.jsx("span",{class:"docs-breadcrumb-current",children:t.text(i[1])})])})}function Bs(n){let i=Ls(n.currentPath),r=i[1],l=i[0];return e.jsxs("div",{class:"docs-prev-next",children:s([l!==void 0?u.link(l.path,[t.attr("class","docs-prev-next-link")],[e.jsx("span",{class:"docs-prev-next-label",children:t.text("← Previous")}),e.jsx("span",{class:"docs-prev-next-title",children:t.text(l.title)})],void 0):e.jsx("div",{}),r!==void 0?u.link(r.path,[t.attr("class","docs-prev-next-link next")],[e.jsx("span",{class:"docs-prev-next-label",children:t.text("Next →")}),e.jsx("span",{class:"docs-prev-next-title",children:t.text(r.title)})],void 0):e.jsx("div",{})])})}function Fs(n){let i=o.make("",void 0,void 0);return e.jsxs("div",{class:"docs-feedback",children:s([t.text("Was this page helpful?"),t.element("button",[t.computedAttr("class",()=>"feedback-btn"+(o.get(i)==="yes"?" selected":"")),t.attr("title","Yes")],[["click",r=>o.set(i,"yes")]],[t.text("👍")],void 0),t.element("button",[t.computedAttr("class",()=>"feedback-btn"+(o.get(i)==="no"?" selected":"")),t.attr("title","No")],[["click",r=>o.set(i,"no")]],[t.text("👎")],void 0)])})}function Gs(n){return n.items.length===0?t.fragment([]):e.jsxs("aside",{class:"docs-toc",children:s([e.jsx("div",{class:"toc-title",children:t.text("On this page")}),t.fragment(n.items.map(i=>{let r="toc-link"+(i.level===3?" toc-link-h3":"");return e.jsx("a",{class:r,href:"#"+i.id,children:t.text(i.text)})}))])})}function N(n){let i=n.currentPath,r=Wt(i),l=n.pageTitle,c=l!==void 0?l:r[1],a=n.tocItems,d=a!==void 0?a:[],h=n.pageLead;return p(Ie,{children:e.jsxs("div",{class:"docs-layout",children:s([p($s,{currentPath:i}),e.jsxs("div",{class:"docs-main",children:s([p(Us,{currentPath:i}),e.jsx("h1",{class:"docs-page-title",children:t.text(c)}),h!==void 0?e.jsx("p",{class:"docs-page-lead",children:t.text(h)}):t.fragment([]),e.jsx("div",{class:"docs-content",children:n.content}),p(Bs,{currentPath:i}),p(Fs,{})])}),p(Gs,{items:d})])})})}let zs=["let","type","module","open","switch","if","else","true","false","and","or","rec","external","include","when"],Hs=["int","string","bool","float","array","option","unit"];function Ws(n){let i=n.split(`
`);return t.fragment(i.map((r,l)=>{let c=(l+1|0).toString(),a;if(r.trim().startsWith("//"))a=t.element("span",[t.attr("class","syntax-comment")],void 0,[t.text(r)],void 0);else{let d=r.split(" ");a=t.fragment(d.map((h,x)=>{let S=h.trim(),T=zs.some(G=>S===G?!0:S.startsWith(G+"(")),A=Hs.some(G=>S===G),R=S.startsWith('"')||S.startsWith("`"),X=Xe(S.match(/^[0-9]+$/))!==void 0||Xe(S.match(/^[0-9]+\.[0-9]+$/))!==void 0,pe=T?"syntax-keyword":A?"syntax-type":R?"syntax-string":X?"syntax-number":"syntax-text";return t.fragment([t.element("span",[t.attr("class",pe)],void 0,[t.text(h)],void 0),x<(d.length-1|0)?t.text(" "):t.fragment([])])}))}return t.element("div",[t.attr("class","syntax-line")],void 0,[t.element("span",[t.attr("class","syntax-line-number")],void 0,[t.text(c)],void 0),t.element("span",[t.attr("class","syntax-line-content")],void 0,[a],void 0)],void 0)}))}let Vs=[{title:"Fine-Grained Reactivity",description:"Direct DOM updates without a virtual DOM. Automatic dependency tracking means only what changed gets updated.",iconName:"Star",linkText:"Learn about Signals",linkTo:"/docs/core-concepts/signals"},{title:"Based on TC39 Signals",description:"Aligned with the TC39 Signals proposal. Build with patterns that will become native to JavaScript.",iconName:"Heart",linkText:"Read the spec",linkTo:"/docs/technical-overview"},{title:"Type-Safe by Default",description:"Built with ReScript's powerful type system. Catch bugs at compile time with sound types and pattern matching.",iconName:"Check",linkText:"View API Reference",linkTo:"/docs/api/signals"},{title:"Lightweight & Fast",description:"Minimal runtime overhead with no virtual DOM diffing. Components compile to efficient JavaScript.",iconName:"Download",linkText:void 0,linkTo:void 0},{title:"JSX Support",description:"Full ReScript JSX v4 support for declarative components. Familiar markup with type system safety.",iconName:"Edit",linkText:"Component docs",linkTo:"/docs/components/overview"},{title:"Client-Side Router",description:"Built-in signal-based router with pattern matching and dynamic routes — no extra dependencies.",iconName:"ExternalLink",linkText:"Router guide",linkTo:"/docs/router/overview"}];function qs(n){let i=n.feature,r=i.linkText,l=i.linkTo;return e.jsxs("div",{class:"feature-card",children:s([e.jsx("div",{class:"feature-card-icon",children:k.make({name:i.iconName,size:"Md"})}),e.jsx("h3",{children:t.text(i.title)}),e.jsx("p",{children:t.text(i.description)}),r!==void 0?l!==void 0?u.link(l,[t.attr("class","feature-card-link")],[t.text(r+" "),k.make({name:"ChevronRight",size:"Sm"})],void 0):t.fragment([]):t.fragment([])])})}function Ks(n){return e.jsx("section",{class:"hero",children:e.jsxs("div",{class:"hero-inner",children:s([e.jsxs("div",{class:"hero-logo",children:s([p(ke,{color:"var(--text-accent)",size:48}),e.jsx("span",{class:"hero-logo-text",children:t.text("xote")})])}),e.jsxs("h1",{children:s([t.text("Build reactive interfaces with "),e.jsx("em",{children:t.text("fine-grained signals")}),t.text(" and "),e.jsx("em",{children:t.text("sound types")})])}),e.jsx("p",{class:"hero-subtitle",children:t.text("Xote is a lightweight UI library for ReScript that combines signal-powered reactivity with a minimal component system. No virtual DOM, no diffing — just precise, efficient updates.")}),e.jsxs("div",{class:"hero-buttons",children:s([u.link("/docs",[t.attr("class","btn btn-primary")],[t.text("Get Started "),k.make({name:"ChevronRight",size:"Sm"})],void 0),e.jsxs("a",{class:"btn btn-ghost",href:"https://github.com/brnrdog/xote",target:"_blank",children:s([k.make({name:"GitHub",size:"Sm"}),t.text(" View on GitHub")])})])})])})})}function Js(n){return e.jsx("section",{class:"features-section",children:e.jsxs("div",{class:"features-inner",children:s([e.jsxs("div",{class:"features-heading",children:s([e.jsx("h2",{children:t.text("Everything you need for reactive UIs")}),e.jsx("p",{children:t.text("Powerful reactive primitives, a declarative component system, and type safety — all in a focused package.")})])}),e.jsx("div",{class:"features-grid",children:t.fragment(Vs.map(i=>p(qs,{feature:i})))})])})})}function Ys(n){let i=o.make(0,void 0,void 0),r=a=>o.update(i,d=>d+1|0),l=a=>o.update(i,d=>d-1|0),c=a=>o.set(i,0);return e.jsxs("div",{class:"counter-app",children:s([e.jsx("div",{class:"counter-display",children:t.textSignal(()=>o.get(i).toString())}),e.jsxs("div",{class:"counter-buttons",children:s([e.jsx("button",{class:"counter-btn",onClick:l,children:t.text("-")}),e.jsx("button",{class:"counter-btn counter-btn-reset",onClick:c,children:t.text("Reset")}),e.jsx("button",{class:"counter-btn",onClick:r,children:t.text("+")})])})])})}function Qs(n){let i=o.make(0,void 0,void 0),r=D.make(()=>o.get(i)*9/5+32,void 0),l=D.make(()=>o.get(i)+273.15,void 0),c=a=>{let d=a.target.value,h=Ms(d);if(h!==void 0)return o.set(i,h)};return e.jsxs("div",{class:"temp-app",children:s([e.jsxs("div",{class:"temp-input-group",children:s([e.jsx("label",{class:"temp-label",children:t.text("Celsius")}),t.input([t.attr("type","number"),t.attr("class","temp-input"),t.attr("placeholder","0")],[["input",c]],void 0)])}),e.jsxs("div",{class:"temp-results",children:s([e.jsxs("div",{class:"temp-result",children:s([e.jsx("span",{class:"temp-result-label",children:t.text("Fahrenheit")}),e.jsx("span",{class:"temp-result-value",children:t.textSignal(()=>o.get(r).toFixed(1))})])}),e.jsxs("div",{class:"temp-result",children:s([e.jsx("span",{class:"temp-result-label",children:t.text("Kelvin")}),e.jsx("span",{class:"temp-result-value",children:t.textSignal(()=>o.get(l).toFixed(1))})])})])})])})}function Zs(n){let i=o.make(!1,void 0,void 0),r=o.make(0,void 0,void 0);Ee.run(()=>{if(!o.get(i))return;let a=setInterval(()=>o.update(r,d=>d+1|0),1e3);return()=>{clearInterval(a)}},void 0);let l=a=>o.update(i,d=>!d),c=a=>{o.set(i,!1),o.set(r,0)};return e.jsxs("div",{class:"timer-app",children:s([e.jsx("div",{class:"timer-display",children:t.textSignal(()=>{let a=o.get(r),d=a/60|0,h=a%60;return d.toString().padStart(2,"0")+":"+h.toString().padStart(2,"0")})}),e.jsxs("div",{class:"timer-buttons",children:s([e.jsx("button",{class:"timer-btn timer-btn-primary",onClick:l,children:t.textSignal(()=>o.get(i)?"Pause":"Start")}),e.jsx("button",{class:"timer-btn",onClick:c,children:t.text("Reset")})])})])})}let rt=`open Xote

let make = () => {
  let count = Signal.make(0)

  let increment = (_evt) =>
    Signal.update(count, n => n + 1)

  let decrement = (_evt) =>
    Signal.update(count, n => n - 1)

  <div class="counter-app">
    <div class="counter-display">
      {Component.textSignal(() =>
        Signal.get(count)->Int.toString
      )}
    </div>
    <div class="counter-buttons">
      <button onClick={decrement}>
        {Component.text("-")}
      </button>
      <button onClick={increment}>
        {Component.text("+")}
      </button>
    </div>
  </div>
}`,lt=`open Xote

let make = () => {
  let celsius = Signal.make(0.0)

  // Computed values auto-update
  let fahrenheit = Computed.make(() =>
    Signal.get(celsius) *. 9.0 /. 5.0 +. 32.0
  )

  let kelvin = Computed.make(() =>
    Signal.get(celsius) +. 273.15
  )

  <div class="temp-app">
    <label> {Component.text("Celsius")} </label>
    {Component.input(
      ~attrs=[Component.attr("type", "number")],
      ~events=[("input", handleInput)],
      (),
    )}
    <span>
      {Component.textSignal(() =>
        Signal.get(fahrenheit)
          ->Float.toFixed(~digits=1)
      )}
    </span>
  </div>
}`,ct=`open Xote

let make = () => {
  let isRunning = Signal.make(false)
  let seconds = Signal.make(0)

  // Effect with cleanup callback
  let _ = Effect.run(() => {
    if Signal.get(isRunning) {
      let id = setInterval(
        () => Signal.update(seconds, s => s + 1),
        1000
      )
      // Cleanup: clear interval
      Some(() => clearInterval(id))
    } else {
      None
    }
  })

  <button onClick={toggleTimer}>
    {Component.textSignal(() =>
      Signal.get(isRunning)
        ? "Pause" : "Start"
    )}
  </button>
}`;function er(n){let i=o.make("counter",void 0,void 0),r=o.make(!1,void 0,void 0),l=c=>{let a=o.peek(i),d;switch(a){case"counter":d=rt;break;case"temperature":d=lt;break;default:d=ct}navigator.clipboard.writeText(d),o.set(r,!0),setTimeout(()=>o.set(r,!1),2e3)};return e.jsx("section",{class:"code-demo-section",children:e.jsxs("div",{class:"code-demo-inner",children:s([e.jsxs("div",{class:"code-demo-heading",children:s([e.jsx("h2",{children:t.text("Signals, Computeds, and Effects")}),e.jsx("p",{children:t.text("Three powerful building blocks for seamless reactivity. Your mental model stays simple and predictable.")})])}),e.jsxs("div",{class:"code-demo-container",children:s([e.jsxs("div",{class:"code-editor-pane",children:s([e.jsxs("div",{class:"code-editor-tabs",children:s([t.element("div",[t.computedAttr("class",()=>"code-editor-tab"+(o.get(i)==="counter"?" active":""))],[["click",c=>o.set(i,"counter")]],[t.text("Counter.res")],void 0),t.element("div",[t.computedAttr("class",()=>"code-editor-tab"+(o.get(i)==="temperature"?" active":""))],[["click",c=>o.set(i,"temperature")]],[t.text("Temperature.res")],void 0),t.element("div",[t.computedAttr("class",()=>"code-editor-tab"+(o.get(i)==="timer"?" active":""))],[["click",c=>o.set(i,"timer")]],[t.text("Timer.res")],void 0)])}),e.jsxs("div",{class:"code-editor-body",children:s([t.element("button",[t.computedAttr("class",()=>"code-copy-btn"+(o.get(r)?" copied":""))],[["click",l]],[t.signalFragment(D.make(()=>o.get(r)?[k.make({name:"Check",size:"Sm"}),t.text(" Copied")]:[k.make({name:"Copy",size:"Sm"}),t.text(" Copy")],void 0))],void 0),e.jsx("pre",{class:"code-editor-pre",children:e.jsx("code",{children:t.signalFragment(D.make(()=>{let c=o.get(i),a;switch(c){case"counter":a=rt;break;case"temperature":a=lt;break;default:a=ct}return[Ws(a)]},void 0))})})])})])}),e.jsxs("div",{class:"code-preview-pane",children:s([e.jsxs("div",{class:"code-preview-header",children:s([e.jsxs("div",{class:"browser-dots",children:s([e.jsx("span",{class:"browser-dot browser-dot-red"}),e.jsx("span",{class:"browser-dot browser-dot-yellow"}),e.jsx("span",{class:"browser-dot browser-dot-green"})])}),e.jsx("div",{class:"browser-url",children:t.text("localhost:5173")})])}),e.jsx("div",{class:"code-preview-body",children:t.signalFragment(D.make(()=>{switch(o.get(i)){case"counter":return[p(Ys,{})];case"temperature":return[p(Qs,{})];default:return[p(Zs,{})]}},void 0))})])})])})])})})}function tr(n){return e.jsx("section",{class:"community-section",children:e.jsxs("div",{class:"community-inner",children:s([e.jsx("h2",{children:t.text("Join the community")}),e.jsx("p",{children:t.text("Xote is open source and built for developers who value simplicity, type safety, and fine-grained reactivity.")}),e.jsxs("div",{class:"community-links",children:s([e.jsxs("a",{class:"btn btn-ghost",href:"https://github.com/brnrdog/xote",target:"_blank",children:s([k.make({name:"GitHub",size:"Sm"}),t.text(" GitHub")])}),e.jsxs("a",{class:"btn btn-ghost",href:"https://www.npmjs.com/package/xote",target:"_blank",children:s([k.make({name:"Download",size:"Sm"}),t.text(" npm")])}),u.link("/demos",[t.attr("class","btn btn-ghost")],[k.make({name:"Star",size:"Sm"}),t.text(" Demos")],void 0)])})])})})}function nr(n){return p(Ie,{children:t.fragment([p(Ks,{}),p(Js,{}),p(er,{}),p(tr,{})])})}function at(){return e.jsxs("div",{children:s([e.jsx("h1",{children:t.text("Getting Started")}),e.jsxs("p",{children:s([t.text("Welcome to Xote (pronounced "),t.text(") - a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system.")])}),e.jsx("h2",{children:t.text("What is Xote?")}),e.jsxs("p",{children:s([t.text("Xote provides a declarative component system and signal-based router built on top of "),e.jsx("a",{href:"https://github.com/brnrdog/rescript-signals",target:"_blank",children:t.text("rescript-signals")}),t.text(". It focuses on:")])}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Fine-grained reactivity: Direct DOM updates without a virtual DOM")}),e.jsx("li",{children:t.text("Automatic dependency tracking: No manual subscription management (powered by rescript-signals)")}),e.jsx("li",{children:t.text("Lightweight: Minimal runtime footprint")}),e.jsx("li",{children:t.text("Type-safe: Leverages ReScript's powerful type system")}),e.jsx("li",{children:t.text("JSX Support: Declarative component syntax with full ReScript type safety")})])}),e.jsx("h2",{children:t.text("Quick Example")}),e.jsx("p",{children:t.text("Here's a simple counter application to get you started:")}),e.jsx("h3",{children:t.text("Using JSX Syntax")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

// Create reactive state
let count = Signal.make(0)

// Event handler
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)

// Build the UI
let app = () => {
  <div>
    <h1> {Component.text("Counter")} </h1>
    <p>
      {Component.textSignal(() => "Count: " ++ Int.toString(Signal.get(count)))}
    </p>
    <button onClick={increment}>
      {Component.text("Increment")}
    </button>
  </div>
}

// Mount to the DOM
Component.mountById(app(), "app")`)})}),e.jsx("p",{children:t.text("When you click the button, the counter updates reactively - only the text node displaying the count is updated, not the entire component tree.")}),e.jsx("h2",{children:t.text("Core Concepts")}),e.jsx("p",{children:t.text("Xote re-exports reactive primitives from rescript-signals and adds UI features:")}),e.jsx("h3",{children:t.text("Reactive Primitives (from rescript-signals)")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([u.link("/docs/core-concepts/signals",void 0,[t.text("Signals")],void 0),t.text(": Reactive state containers that notify dependents when they change")])}),e.jsxs("li",{children:s([u.link("/docs/core-concepts/computed",void 0,[t.text("Computed Values")],void 0),t.text(": Derived values that automatically update when their dependencies change")])}),e.jsxs("li",{children:s([u.link("/docs/core-concepts/effects",void 0,[t.text("Effects")],void 0),t.text(": Side effects that re-run when dependencies change")])})])}),e.jsx("h3",{children:t.text("Xote Features")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([u.link("/docs/components/overview",void 0,[t.text("Components")],void 0),t.text(": Declarative UI builder with JSX support and fine-grained DOM updates")])}),e.jsx("li",{children:t.text("Router: Signal-based SPA navigation with pattern matching")})])}),e.jsx("h2",{children:t.text("Installation")}),e.jsx("p",{children:t.text("Get started with Xote in your ReScript project:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`npm install xote
# or
yarn add xote
# or
pnpm add xote`)})}),e.jsxs("p",{children:s([t.text("Then add it to your "),e.jsx("code",{children:t.text("rescript.json")}),t.text(":")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`{
  "bs-dependencies": ["xote"]
}`)})}),e.jsx("h2",{children:t.text("Next Steps")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([t.text("Learn about "),u.link("/docs/core-concepts/signals",void 0,[t.text("Signals")],void 0),t.text(" - the foundation of reactive state")])}),e.jsxs("li",{children:s([t.text("Explore "),u.link("/docs/components/overview",void 0,[t.text("Components")],void 0),t.text(" - building UIs with Xote")])}),e.jsxs("li",{children:s([t.text("Check out the "),u.link("/demos",void 0,[t.text("Demos")],void 0),t.text(" to see Xote in action")])}),e.jsxs("li",{children:s([t.text("Read the "),u.link("/docs/api/signals",void 0,[t.text("API Reference")],void 0),t.text(" for detailed documentation")])})])}),e.jsx("h2",{children:t.text("Philosophy")}),e.jsx("p",{children:t.text("Xote focuses on clarity, control, and performance. The goal is to offer precise, fine-grained updates and predictable behavior without a virtual DOM.")}),e.jsxs("p",{children:s([t.text("By building on "),e.jsx("a",{href:"https://github.com/pedrobslisboa/rescript-signals",target:"_blank",children:t.text("rescript-signals")}),t.text(" (which implements the "),e.jsx("a",{href:"https://github.com/tc39/proposal-signals",target:"_blank",children:t.text("TC39 Signals proposal")}),t.text("), Xote ensures your reactive code aligns with emerging JavaScript standards while providing ReScript-specific UI features.")])})])})}let ir=[{title:"Counter",description:"Simple reactive counter with signals and event handlers",path:"/demos/counter",source:"https://github.com/brnrdog/xote/blob/main/demos/CounterApp.res"},{title:"Todo List",description:"Complete todo app with filters, computed values, and reactive lists",path:"/demos/todo",source:"https://github.com/brnrdog/xote/blob/main/demos/TodoApp.res"},{title:"Color Mixer",description:"RGB color mixing with live preview, format conversions, and palette variations",path:"/demos/color-mixer",source:"https://github.com/brnrdog/xote/blob/main/demos/ColorMixerApp.res"},{title:"Reaction Game",description:"Reflex testing game with timers, statistics, and computed averages",path:"/demos/reaction-game",source:"https://github.com/brnrdog/xote/blob/main/demos/ReactionGame.res"},{title:"Solitaire",description:"Classic Klondike Solitaire with click-to-move gameplay and win detection",path:"/demos/solitaire",source:"https://github.com/brnrdog/xote/blob/main/demos/SolitaireGame.res"},{title:"Memory Match",description:"2-player memory matching game with 10 progressive levels and score tracking",path:"/demos/memory-match",source:"https://github.com/brnrdog/xote/blob/main/demos/MatchGame.res"},{title:"Functional Bookstore",description:"E-commerce app with routing, cart management, checkout flow, and absurd FP-themed books",path:"/demos/bookstore",source:"https://github.com/brnrdog/xote/blob/main/demos/BookstoreApp.res"}];function sr(n){let i=n.demo;return e.jsxs("div",{class:"demo-card",children:s([e.jsx("div",{class:"demo-card-header",children:e.jsx("h3",{children:t.text(i.title)})}),e.jsx("div",{class:"demo-card-body",children:e.jsx("p",{children:t.text(i.description)})}),e.jsxs("div",{class:"demo-card-footer",children:s([u.link(i.path,[t.attr("class","btn btn-primary")],[t.text("Try Demo "),k.make({name:"ChevronRight",size:"Sm"})],void 0),e.jsxs("a",{class:"btn btn-ghost",href:i.source,target:"_blank",children:s([k.make({name:"GitHub",size:"Sm"}),t.text(" Source")])})])})])})}function rr(n){return e.jsxs("div",{class:"alert-info",children:s([e.jsx("h4",{children:t.text("Running Demos Locally")}),e.jsx("p",{children:t.text("To run these demos on your machine:")}),e.jsxs("ol",{children:s([e.jsxs("li",{children:s([t.text("Clone: "),e.jsx("code",{children:t.text("git clone https://github.com/brnrdog/xote.git")})])}),e.jsxs("li",{children:s([t.text("Install: "),e.jsx("code",{children:t.text("npm install")})])}),e.jsxs("li",{children:s([t.text("Compile: "),e.jsx("code",{children:t.text("npm run res:dev")})])}),e.jsxs("li",{children:s([t.text("Dev server: "),e.jsx("code",{children:t.text("npm run dev")})])})])})])})}function lr(n){return p(Ie,{children:e.jsxs("div",{children:s([e.jsxs("section",{class:"demos-hero",children:s([e.jsx("h1",{children:t.text("Demos")}),e.jsx("p",{children:t.text("Interactive examples showcasing Xote's capabilities")})])}),e.jsxs("div",{class:"demos-container",children:s([p(rr,{}),e.jsx("div",{class:"demos-grid",children:t.fragment(ir.map(i=>p(sr,{demo:i})))})])})])})})}function cr(){return e.jsxs("div",{children:s([e.jsx("h1",{children:t.text("Router Overview")}),e.jsx("p",{children:t.text("Xote includes a built-in signal-based router for building single-page applications (SPAs). The router uses the browser's History API and provides both imperative and declarative navigation.")}),e.jsx("h2",{children:t.text("Features")}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Signal-based reactive routing")}),e.jsx("li",{children:t.text("Browser History API integration")}),e.jsx("li",{children:t.text("Pattern matching with dynamic parameters")}),e.jsx("li",{children:t.text("Imperative navigation (push/replace)")}),e.jsx("li",{children:t.text("Declarative routing components")}),e.jsx("li",{children:t.text("SPA navigation links (no page reload)")}),e.jsx("li",{children:t.text("Zero dependencies")})])}),e.jsx("h2",{children:t.text("Quick Start")}),e.jsx("h3",{children:t.text("1. Initialize the Router")}),e.jsxs("p",{children:s([t.text("Call "),e.jsx("code",{children:t.text("Router.init()")}),t.text(" once at application startup:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

Router.init()`)})}),e.jsx("p",{children:t.text("This sets the initial location from the browser URL and adds a popstate listener for back/forward button support.")}),e.jsx("h3",{children:t.text("2. Define Routes")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Router.routes()")}),t.text(" to define your application routes:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let app = () => {
  <div>
    {Router.routes([
      {
        pattern: "/",
        render: _params => <HomePage />
      },
      {
        pattern: "/about",
        render: _params => <AboutPage />
      },
      {
        pattern: "/users/:id",
        render: params => <UserPage userId={params->Dict.get("id")} />
      },
    ])}
  </div>
}

Component.mountById(app(), "app")`)})}),e.jsx("h3",{children:t.text("3. Navigate")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Router.push()")}),t.text(" or "),e.jsx("code",{children:t.text("Router.link()")}),t.text(" to navigate:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`// Imperative navigation
let goToAbout = (_evt: Dom.event) => {
  Router.push("/about", ())
}

// Declarative links
Router.link(
  ~to="/about",
  ~children=[Component.text("About")],
  ()
)`)})}),e.jsx("h2",{children:t.text("The Location Signal")}),e.jsxs("p",{children:s([e.jsx("code",{children:t.text("Router.location")}),t.text(" is a signal containing the current route information:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`type location = {
  pathname: string,  // e.g., "/users/123"
  search: string,    // e.g., "?sort=name"
  hash: string,      // e.g., "#section"
}`)})}),e.jsx("p",{children:t.text("Read it like any signal:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`Effect.run(() => {
  let currentLocation = Signal.get(Router.location)
  Console.log2("Current path:", currentLocation.pathname)
})`)})}),e.jsx("h2",{children:t.text("Route Patterns")}),e.jsx("p",{children:t.text("Patterns support static segments and dynamic parameters:")}),e.jsx("h3",{children:t.text("Static Routes")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`{pattern: "/", render: _params => <HomePage />}
{pattern: "/about", render: _params => <AboutPage />}
{pattern: "/contact", render: _params => <ContactPage />}`)})}),e.jsx("h3",{children:t.text("Dynamic Parameters")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text(":param")}),t.text(" syntax for dynamic segments:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`{pattern: "/users/:id", render: params =>
  switch params->Dict.get("id") {
  | Some(id) => <UserPage userId={id} />
  | None => <NotFoundPage />
  }
}

{pattern: "/posts/:postId/comments/:commentId", render: params => {
  let postId = params->Dict.get("postId")
  let commentId = params->Dict.get("commentId")
  <CommentPage postId={postId} commentId={commentId} />
}}`)})}),e.jsx("h2",{children:t.text("Navigation Methods")}),e.jsx("h3",{children:e.jsx("code",{children:t.text("Router.push()")})}),e.jsx("p",{children:t.text("Navigate to a new route with a new history entry:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`Router.push("/users/123", ())

// With query string
Router.push("/search", ~search="?q=xote", ())

// With hash
Router.push("/docs", ~hash="#installation", ())`)})}),e.jsx("h3",{children:e.jsx("code",{children:t.text("Router.replace()")})}),e.jsx("p",{children:t.text("Navigate without creating a new history entry:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text('Router.replace("/login", ())')})}),e.jsx("p",{children:t.text("This replaces the current history entry, so clicking the back button will skip this route.")}),e.jsx("h2",{children:t.text("Navigation Links")}),e.jsx("p",{children:t.text("Create links that navigate without page reload:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`Router.link(
  ~to="/about",
  ~children=[Component.text("About Us")],
  ()
)

// With attributes
Router.link(
  ~to="/users/123",
  ~attrs=[Component.attr("class", "user-link")],
  ~children=[Component.text("View User")],
  ()
)`)})}),e.jsx("h2",{children:t.text("Complete Example")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

// Initialize router
Router.init()

// Page components
let homePage = () => {
  <div>
    <h1> {Component.text("Home")} </h1>
    {Router.link(~to="/about", ~children=[Component.text("About")], ())}
  </div>
}

let aboutPage = () => {
  <div>
    <h1> {Component.text("About")} </h1>
    {Router.link(~to="/", ~children=[Component.text("Home")], ())}
  </div>
}

// Main app
let app = () => {
  <div>
    <nav>
      {Router.link(~to="/", ~children=[Component.text("Home")], ())}
      {Component.text(" | ")}
      {Router.link(~to="/about", ~children=[Component.text("About")], ())}
    </nav>
    <hr />
    {Router.routes([
      {pattern: "/", render: _params => homePage()},
      {pattern: "/about", render: _params => aboutPage()},
    ])}
  </div>
}

Component.mountById(app(), "app")`)})}),e.jsx("h2",{children:t.text("How It Works")}),e.jsxs("ol",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Initialization:")}),t.text(" Router.init() reads the current URL and sets up the location signal")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("History Integration:")}),t.text(" Listens to popstate events for back/forward navigation")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Pattern Matching:")}),t.text(" Routes use simple string-based matching with :param syntax")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Reactive Rendering:")}),t.text(" Route components are wrapped in SignalFragment + Computed")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Link Handling:")}),t.text(" Router.link() intercepts clicks and calls Router.push() instead of following the href")])})])}),e.jsx("h2",{children:t.text("Best Practices")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Initialize once:")}),t.text(" Call Router.init() at the top level, not in components")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Order routes carefully:")}),t.text(" More specific routes should come before generic ones")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Handle 404s:")}),t.text(" Add a catch-all route at the end for unmatched paths")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Use links for navigation:")}),t.text(" Prefer Router.link() over manual Router.push() calls")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Extract parameters safely:")}),t.text(" Use Option methods when accessing route parameters")])})])}),e.jsx("h2",{children:t.text("Next Steps")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([t.text("Try the "),u.link("/demos",void 0,[t.text("Demos")],void 0),t.text(" to see routing in action")])}),e.jsxs("li",{children:s([t.text("Learn about "),u.link("/docs/core-concepts/signals",void 0,[t.text("Signals")],void 0),t.text(" for reactive state")])}),e.jsxs("li",{children:s([t.text("Explore "),u.link("/docs/components/overview",void 0,[t.text("Components")],void 0),t.text(" for building UIs")])})])})])})}function ar(){return e.jsxs("div",{children:s([e.jsx("h1",{children:t.text("Effects")}),e.jsx("p",{children:t.text("Effects are functions that run side effects in response to reactive state changes. They automatically re-execute when any signal they depend on changes.")}),e.jsx("div",{class:"info-box",children:e.jsxs("p",{children:s([e.jsx("strong",{children:t.text("Info:")}),t.text(" Xote re-exports "),e.jsx("code",{children:t.text("Effect")}),t.text(" from "),e.jsx("a",{href:"https://github.com/pedrobslisboa/rescript-signals",target:"_blank",children:t.text("rescript-signals")}),t.text(". The API and behavior are provided by that library.")])})}),e.jsx("h2",{children:t.text("Creating Effects")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Effect.run()")}),t.text(" to create an effect. The effect function can optionally return a cleanup function:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

let count = Signal.make(0)

Effect.run(() => {
  Console.log2("Count is now:", Signal.get(count))
  None // No cleanup needed
})
// Prints: "Count is now: 0"

Signal.set(count, 1)
// Prints: "Count is now: 1"`)})}),e.jsx("h2",{children:t.text("How Effects Work")}),e.jsxs("ol",{children:s([e.jsx("li",{children:t.text("The effect function runs immediately when created")}),e.jsx("li",{children:t.text("Any Signal.get() calls during execution are tracked as dependencies")}),e.jsx("li",{children:t.text("When a dependency changes, the effect re-runs")}),e.jsx("li",{children:t.text("Dependencies are re-tracked on every execution")}),e.jsx("li",{children:t.text("If a cleanup function was returned, it runs before re-execution")})])}),e.jsx("h2",{children:t.text("Cleanup Callbacks")}),e.jsx("p",{children:t.text("Effects can return an optional cleanup function that runs before the effect re-executes or when the effect is disposed:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

let url = Signal.make("https://api.example.com/data")

Effect.run(() => {
  let currentUrl = Signal.get(url)
  Console.log2("Fetching:", currentUrl)

  // Simulate an API call with AbortController
  let controller = AbortController.make()

  fetch(currentUrl, {signal: controller.signal})
    ->Promise.then(response => {
      Console.log("Data received")
      Promise.resolve()
    })
    ->ignore

  // Return cleanup function
  Some(() => {
    Console.log("Aborting previous request")
    controller.abort()
  })
})

// When url changes, the cleanup function runs first,
// then the effect re-executes with the new URL
Signal.set(url, "https://api.example.com/other-data")`)})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Key points about cleanup:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Return None when no cleanup is needed")}),e.jsx("li",{children:t.text("Return Some(cleanupFn) to register cleanup")}),e.jsx("li",{children:t.text("Cleanup runs before the effect re-executes")}),e.jsx("li",{children:t.text("Cleanup runs when the effect is disposed via dispose()")}),e.jsx("li",{children:t.text("Cleanup is useful for canceling requests, clearing timers, removing event listeners, etc.")})])}),e.jsx("h2",{children:t.text("Common Use Cases")}),e.jsx("h3",{children:t.text("Timers with Cleanup")}),e.jsx("p",{children:t.text("Properly clean up timers:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let interval = Signal.make(1000)

Effect.run(() => {
  let ms = Signal.get(interval)

  let timerId = setInterval(() => {
    Console.log("Tick")
  }, ms)

  // Clear timer when interval changes or effect disposes
  Some(() => {
    clearInterval(timerId)
  })
})`)})}),e.jsx("h3",{children:t.text("Logging and Debugging")}),e.jsx("p",{children:t.text("Track state changes for debugging:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let user = Signal.make({id: 1, name: "Alice"})

Effect.run(() => {
  let currentUser = Signal.get(user)
  Console.log2("User changed:", currentUser)
  None // No cleanup needed
})`)})}),e.jsx("h3",{children:t.text("Synchronization")}),e.jsx("p",{children:t.text("Sync reactive state with external systems:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let settings = Signal.make({theme: "dark", language: "en"})

Effect.run(() => {
  let current = Signal.get(settings)
  // Save to localStorage
  LocalStorage.setItem("settings", JSON.stringify(current))
  None // No cleanup needed
})`)})}),e.jsx("h2",{children:t.text("Disposing Effects")}),e.jsx("p",{children:t.text("Effect.run() returns a disposer object with a dispose() method to stop the effect. When disposed, any registered cleanup function is called:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)

let disposer = Effect.run(() => {
  Console.log(Signal.get(count))
  None // No cleanup needed
})

Signal.set(count, 1) // Effect runs
Signal.set(count, 2) // Effect runs

disposer.dispose() // Stop the effect

Signal.set(count, 3) // Effect does NOT run`)})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("With cleanup:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let disposer = Effect.run(() => {
  let timerId = setInterval(() => Console.log("Tick"), 1000)

  // Cleanup function
  Some(() => {
    clearInterval(timerId)
    Console.log("Timer cleared")
  })
})

// Later...
disposer.dispose() // Runs cleanup, prints "Timer cleared"`)})}),e.jsx("h2",{children:t.text("Dynamic Dependencies")}),e.jsx("p",{children:t.text("Effects re-track dependencies on each execution, adapting to conditional logic:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let showDetails = Signal.make(false)
let name = Signal.make("Alice")
let age = Signal.make(30)

Effect.run(() => {
  Console.log(Signal.get(name))

  if Signal.get(showDetails) {
    Console.log2("Age:", Signal.get(age))
  }

  None // No cleanup needed
})

// Initially depends on: name, showDetails
// After setting showDetails to true, depends on: name, showDetails, age`)})}),e.jsx("h2",{children:t.text("Avoiding Dependencies")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Signal.peek()")}),t.text(" to read signals without creating dependencies:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)
let debug = Signal.make(true)

Effect.run(() => {
  Console.log2("Count:", Signal.get(count))

  // Read debug flag without depending on it
  if Signal.peek(debug) {
    Console.log("Debug mode is on")
  }

  None // No cleanup needed
})`)})}),e.jsx("h2",{children:t.text("Example: Auto-save")}),e.jsx("p",{children:t.text("Here's a practical example of an auto-save effect with proper cleanup:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

type draft = {
  title: string,
  content: string,
}

let draft = Signal.make({
  title: "",
  content: "",
})

let saveStatus = Signal.make("Saved")

// Auto-save effect with debouncing and cleanup
Effect.run(() => {
  let current = Signal.get(draft)

  Signal.set(saveStatus, "Unsaved changes...")

  // Save after 1 second of no changes
  let timeoutId = setTimeout(() => {
    // Save to server
    saveToServer(current)
    Signal.set(saveStatus, "Saved")
  }, 1000)

  // Clean up timeout when draft changes again
  Some(() => {
    clearTimeout(timeoutId)
  })
})`)})}),e.jsx("h2",{children:t.text("Best Practices")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Keep effects focused:")}),t.text(" Each effect should do one thing")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Clean up resources:")}),t.text(" Return cleanup functions for timers, listeners, subscriptions, etc.")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Dispose effects:")}),t.text(" Use the disposer when effects are no longer needed (e.g., component unmount)")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Avoid infinite loops:")}),t.text(" Don't set signals that the effect depends on (unless using equality checks)")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Use for side effects only:")}),t.text(" Effects should not compute values (use Computed instead)")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Return None when no cleanup needed:")}),t.text(" Be explicit about cleanup needs")])})])}),e.jsx("h2",{children:t.text("Effects vs Computed")}),e.jsxs("table",{children:s([e.jsx("thead",{children:e.jsxs("tr",{children:s([e.jsx("th",{children:t.text("Feature")}),e.jsx("th",{children:t.text("Effect")}),e.jsx("th",{children:t.text("Computed")})])})}),e.jsxs("tbody",{children:s([e.jsxs("tr",{children:s([e.jsx("td",{children:t.text("Purpose")}),e.jsx("td",{children:t.text("Side effects")}),e.jsx("td",{children:t.text("Derive values")})])}),e.jsxs("tr",{children:s([e.jsx("td",{children:t.text("Returns")}),e.jsx("td",{children:t.text("Disposer")}),e.jsx("td",{children:t.text("Signal")})])}),e.jsxs("tr",{children:s([e.jsx("td",{children:t.text("When runs")}),e.jsx("td",{children:t.text("Immediately and on changes")}),e.jsx("td",{children:t.text("Immediately and on changes")})])}),e.jsxs("tr",{children:s([e.jsx("td",{children:t.text("Result")}),e.jsx("td",{children:t.text("None (performs actions)")}),e.jsx("td",{children:t.text("New reactive value")})])})])})])}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("strong",{children:t.text("Computed")}),t.text(" for pure calculations, "),e.jsx("strong",{children:t.text("Effects")}),t.text(" for side effects.")])}),e.jsx("h2",{children:t.text("Next Steps")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([t.text("Learn about "),u.link("/docs/core-concepts/batching",void 0,[t.text("Batching")],void 0),t.text(" to optimize multiple updates")])}),e.jsxs("li",{children:s([t.text("See how effects work in "),u.link("/docs/components/overview",void 0,[t.text("Components")],void 0)])}),e.jsxs("li",{children:s([t.text("Try the "),u.link("/demos",void 0,[t.text("Demos")],void 0),t.text(" to see effects in action")])})])})])})}function or(){return e.jsxs("div",{children:s([e.jsx("h1",{children:t.text("Signals")}),e.jsx("p",{children:t.text("Signals are the foundation of reactive state in Xote. A signal is a reactive state container that automatically notifies its dependents when its value changes.")}),e.jsx("div",{class:"info-box",children:e.jsxs("p",{children:s([e.jsx("strong",{children:t.text("Info:")}),t.text(" Xote re-exports "),e.jsx("code",{children:t.text("Signal")}),t.text(", "),e.jsx("code",{children:t.text("Computed")}),t.text(", and "),e.jsx("code",{children:t.text("Effect")}),t.text(" from "),e.jsx("a",{href:"https://github.com/pedrobslisboa/rescript-signals",target:"_blank",children:t.text("rescript-signals")}),t.text(". The API and behavior are provided by that library.")])})}),e.jsx("h2",{children:t.text("Creating Signals")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Signal.make()")}),t.text(" to create a new signal with an initial value:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

let count = Signal.make(0)
let name = Signal.make("Alice")
let isActive = Signal.make(true)`)})}),e.jsx("h2",{children:t.text("Reading Signal Values")}),e.jsx("h3",{children:e.jsx("code",{children:t.text("Signal.get()")})}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Signal.get()")}),t.text(" to read a signal's value. When called inside a tracking context (like an effect or computed value), it automatically registers the signal as a dependency:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(5)
let value = Signal.get(count) // Returns 5`)})}),e.jsx("h3",{children:e.jsx("code",{children:t.text("Signal.peek()")})}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Signal.peek()")}),t.text(" to read a signal's value without creating a dependency:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(5)

Effect.run(() => {
  // This creates a dependency
  let current = Signal.get(count)

  // This does NOT create a dependency
  let peeked = Signal.peek(count)

  Console.log2("Current:", current)
  Console.log2("Peeked:", peeked)
})`)})}),e.jsx("h2",{children:t.text("Updating Signals")}),e.jsx("h3",{children:e.jsx("code",{children:t.text("Signal.set()")})}),e.jsx("p",{children:t.text("Replace a signal's value entirely:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)
Signal.set(count, 10) // count is now 10`)})}),e.jsx("h3",{children:e.jsx("code",{children:t.text("Signal.update()")})}),e.jsx("p",{children:t.text("Update a signal based on its current value:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)
Signal.update(count, n => n + 1) // count is now 1
Signal.update(count, n => n * 2) // count is now 2`)})}),e.jsx("h2",{children:t.text("Important Behaviors")}),e.jsx("h3",{children:t.text("Structural Equality Check")}),e.jsxs("p",{children:s([t.text("Signals use structural equality ("),e.jsx("code",{children:t.text("==")}),t.text(") to check if a value has changed. If the new value equals the old value, dependents are not notified:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(5)

Effect.run(() => {
  Console.log(Signal.get(count))
})

Signal.set(count, 5) // Effect does NOT run - value didn't change
Signal.set(count, 6) // Effect runs - value changed`)})}),e.jsx("p",{children:t.text("This prevents unnecessary updates and helps avoid accidental infinite loops in reactive code.")}),e.jsx("h3",{children:t.text("Automatic Dependency Tracking")}),e.jsxs("p",{children:s([t.text("When you call "),e.jsx("code",{children:t.text("Signal.get()")}),t.text(" inside a tracking context, the dependency is automatically registered:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

// This computed automatically depends on both firstName and lastName
let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)`)})}),e.jsx("h2",{children:t.text("Example: Counter")}),e.jsx("p",{children:t.text("Here's a complete example showing signals in action:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}

let decrement = (_evt: Dom.event) => {
  Signal.update(count, n => n - 1)
}

let reset = (_evt: Dom.event) => {
  Signal.set(count, 0)
}

let app = () => {
  <div>
    <h1>
      {Component.textSignal(() => "Count: " ++ Int.toString(Signal.get(count)))}
    </h1>
    <button onClick={increment}>
      {Component.text("+")}
    </button>
    <button onClick={decrement}>
      {Component.text("-")}
    </button>
    <button onClick={reset}>
      {Component.text("Reset")}
    </button>
  </div>
}

Component.mountById(app(), "app")`)})}),e.jsx("h2",{children:t.text("Best Practices")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Keep signals focused:")}),t.text(" Each signal should represent a single piece of state")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Use peek() to avoid dependencies:")}),t.text(" When you need to read a value without tracking, use peek()")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Prefer update() over get() + set():")}),t.text(" It's more concise and clearer in intent")])})])}),e.jsx("h2",{children:t.text("Next Steps")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([t.text("Learn about "),u.link("/docs/core-concepts/computed",void 0,[t.text("Computed Values")],void 0),t.text(" for derived state")])}),e.jsxs("li",{children:s([t.text("Understand "),u.link("/docs/core-concepts/effects",void 0,[t.text("Effects")],void 0),t.text(" for side effects")])}),e.jsxs("li",{children:s([t.text("See the "),u.link("/docs/api/signals",void 0,[t.text("API Reference")],void 0),t.text(" for complete signal API")])})])})])})}function dr(){return e.jsxs("div",{children:s([e.jsx("h1",{children:t.text("Batching Updates")}),e.jsx("p",{children:t.text("Batching allows you to group multiple signal updates together, ensuring that observers (effects and computed values) run only once after all updates complete, rather than after each individual update.")}),e.jsx("div",{class:"info-box",children:e.jsxs("p",{children:s([e.jsx("strong",{children:t.text("Info:")}),t.text(" Batching is available through "),e.jsx("code",{children:t.text("Signal.batch")}),t.text(" which is re-exported from "),e.jsx("a",{href:"https://github.com/pedrobslisboa/rescript-signals",target:"_blank",children:t.text("rescript-signals")}),t.text(".")])})}),e.jsx("h2",{children:t.text("Why Batch?")}),e.jsx("p",{children:t.text("Without batching, each signal update triggers observers immediately:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)

Effect.run(() => {
  Console.log(Signal.get(fullName))
  None
})

// Without batching
Signal.set(firstName, "Jane")  // Logs: "Jane Doe"
Signal.set(lastName, "Smith")  // Logs: "Jane Smith"
// Effect runs twice, computed recalculates twice`)})}),e.jsx("p",{children:t.text("With batching, observers run once after all updates:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`Signal.batch(() => {
  Signal.set(firstName, "Jane")  // Queued
  Signal.set(lastName, "Smith")  // Queued
})
// Logs: "Jane Smith" (only once)
// Effect runs once, computed recalculates once`)})}),e.jsx("h2",{children:t.text("Using Signal.batch()")}),e.jsx("p",{children:t.text("Wrap multiple signal updates in a batch:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

let x = Signal.make(0)
let y = Signal.make(0)

Effect.run(() => {
  Console.log2("Position:", (Signal.get(x), Signal.get(y)))
  None
})

// Update both coordinates together
Signal.batch(() => {
  Signal.set(x, 10)
  Signal.set(y, 20)
})
// Logs only once: "Position: (10, 20)"`)})}),e.jsx("h2",{children:t.text("How Batching Works")}),e.jsxs("ol",{children:s([e.jsx("li",{children:t.text("When Signal.batch() is called, a batching flag is set")}),e.jsx("li",{children:t.text("Signal updates queue their observers instead of running them immediately")}),e.jsx("li",{children:t.text("When the batch function completes, all queued observers run")}),e.jsx("li",{children:t.text("Each observer runs only once, even if multiple dependencies changed")})])}),e.jsx("h2",{children:t.text("Example: Form Updates")}),e.jsx("p",{children:t.text("Batching is especially useful when updating related state:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`type formData = {
  name: string,
  email: string,
  age: int,
}

let form = Signal.make({
  name: "",
  email: "",
  age: 0,
})

let errors = Computed.make(() => {
  let data = Signal.get(form)
  let errors = []

  if String.length(data.name) == 0 {
    errors->Array.push("Name is required")
  }
  if String.length(data.email) == 0 {
    errors->Array.push("Email is required")
  }
  if data.age < 18 {
    errors->Array.push("Must be 18 or older")
  }

  errors
})

// Update form fields together
let handleSubmit = () => {
  Signal.batch(() => {
    Signal.update(form, f => {...f, name: "Alice"})
    Signal.update(form, f => {...f, email: "alice@example.com"})
    Signal.update(form, f => {...f, age: 25})
  })
  // Validation runs once after all updates
}`)})}),e.jsx("h2",{children:t.text("Nested Batches")}),e.jsx("p",{children:t.text("Batches can be nested. The observers run when the outermost batch completes:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)

Effect.run(() => {
  Console.log(Signal.get(count))
  None
})

Signal.batch(() => {
  Signal.set(count, 1)

  Signal.batch(() => {
    Signal.set(count, 2)
  })
  // No effect runs yet

  Signal.set(count, 3)
})
// Effect runs once: logs "3"`)})}),e.jsx("h2",{children:t.text("Returning Values from Batches")}),e.jsxs("p",{children:s([e.jsx("code",{children:t.text("Signal.batch()")}),t.text(" returns the result of the batch function:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let result = Signal.batch(() => {
  Signal.set(count, 10)
  Signal.set(name, "Alice")
  "Success"
})

Console.log(result) // "Success"`)})}),e.jsx("h2",{children:t.text("When to Use Batching")}),e.jsx("p",{children:t.text("Use batching when:")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Updating multiple related signals:")}),t.text(" Form state, coordinates, settings")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Performing complex state transitions:")}),t.text(" Multi-step updates that should appear atomic")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Optimizing performance:")}),t.text(" Reducing unnecessary recomputations")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Maintaining consistency:")}),t.text(" Ensuring observers see a consistent state")])})])}),e.jsx("p",{children:t.text("Don't batch when:")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Single signal updates:")}),t.text(" No benefit from batching")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Updates need to be visible immediately:")}),t.text(" Rare, but sometimes intermediate states matter")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Debugging:")}),t.text(" Batching can make it harder to trace state changes")])})])}),e.jsx("h2",{children:t.text("Example: Animation")}),e.jsx("p",{children:t.text("Batching is useful for coordinated updates in animations:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let x = Signal.make(0)
let y = Signal.make(0)
let rotation = Signal.make(0)
let scale = Signal.make(1.0)

let animationFrame = () => {
  Signal.batch(() => {
    Signal.update(x, v => v + 1)
    Signal.update(y, v => v + 2)
    Signal.update(rotation, v => v + 5)
    Signal.update(scale, v => v *. 1.01)
  })
  // All transform properties update together
}

let intervalId = setInterval(animationFrame, 16) // ~60fps`)})}),e.jsx("h2",{children:t.text("Performance Considerations")}),e.jsx("p",{children:t.text("Batching provides benefits when:")}),e.jsxs("ol",{children:s([e.jsx("li",{children:t.text("Multiple signals feed into the same computed/effect")}),e.jsx("li",{children:t.text("Computed values have expensive calculations")}),e.jsx("li",{children:t.text("Effects perform costly side effects (DOM updates, network requests)")})])}),e.jsx("p",{children:t.text("In simple cases, batching overhead might not be worth it:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`// Simple case: batching adds minimal benefit
let count = Signal.make(0)

Signal.batch(() => {
  Signal.set(count, 1)
}) // Overhead not worth it for single update`)})}),e.jsx("h2",{children:t.text("Best Practices")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Batch related updates:")}),t.text(" Group changes that logically belong together")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Keep batches small:")}),t.text(" Don't batch unrelated updates")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Batch at the right level:")}),t.text(" Batch where updates originate, not deep in the stack")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Document batching:")}),t.text(" Comment why batching is needed if it's not obvious")])})])}),e.jsx("h2",{children:t.text("Example: Shopping Cart")}),e.jsx("p",{children:t.text("Here's a complete example showing effective batching:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`type item = {id: int, quantity: int}
type cart = {
  items: array<item>,
  discountCode: option<string>,
  shippingMethod: string,
}

let cart = Signal.make({
  items: [],
  discountCode: None,
  shippingMethod: "standard",
})

let addItem = (id: int, quantity: int) => {
  Signal.batch(() => {
    Signal.update(cart, c => {
      ...c,
      items: Array.concat(c.items, [{id, quantity}])
    })

    // Clear discount if cart changes
    Signal.update(cart, c => {...c, discountCode: None})
  })
}

let applyDiscount = (code: string) => {
  Signal.batch(() => {
    Signal.update(cart, c => {...c, discountCode: Some(code)})
    Signal.update(cart, c => {...c, shippingMethod: "express"})
  })
}`)})}),e.jsx("h2",{children:t.text("Next Steps")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([t.text("See how batching works with "),u.link("/docs/core-concepts/effects",void 0,[t.text("Effects")],void 0)])}),e.jsxs("li",{children:s([t.text("Learn about "),u.link("/docs/components/overview",void 0,[t.text("Components")],void 0),t.text(" which benefit from batching")])}),e.jsxs("li",{children:s([t.text("Try the "),u.link("/demos",void 0,[t.text("Demos")],void 0),t.text(" to see batching in action")])})])})])})}function hr(){return e.jsxs("div",{children:s([e.jsx("h1",{children:t.text("Computed Values")}),e.jsx("p",{children:t.text("Computed values are derived signals that automatically recalculate when their dependencies change. They're perfect for deriving state from other reactive sources.")}),e.jsx("div",{class:"info-box",children:e.jsxs("p",{children:s([e.jsx("strong",{children:t.text("Info:")}),t.text(" Xote re-exports "),e.jsx("code",{children:t.text("Computed")}),t.text(" from "),e.jsx("a",{href:"https://github.com/pedrobslisboa/rescript-signals",target:"_blank",children:t.text("rescript-signals")}),t.text(". The API and behavior are provided by that library.")])})}),e.jsx("p",{children:t.text("Test")}),e.jsx("h2",{children:t.text("Creating Computed Values")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Computed.make()")}),t.text(" with a function that computes the derived value. It returns the computed signal:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

// Automatically updates when firstName or lastName changes
let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)

// Read the computed value directly from the signal
Console.log(Signal.get(fullName)) // "John Doe"`)})}),e.jsx("h2",{children:t.text("How Computed Values Work")}),e.jsx("p",{children:t.text("Computed values are push-based (eager), not pull-based (lazy):")}),e.jsxs("ol",{children:s([e.jsx("li",{children:t.text("When created, the computation runs immediately to establish dependencies")}),e.jsx("li",{children:t.text("When any dependency changes, the computed automatically recalculates")}),e.jsx("li",{children:t.text("The new value is pushed to a backing signal")}),e.jsx("li",{children:t.text("Any observers of the computed are notified")})])}),e.jsx("p",{children:t.text("This means computed values are always up-to-date, but they may recalculate even if their value is never read.")}),e.jsx("h2",{children:t.text("Reading Computed Values")}),e.jsxs("p",{children:s([t.text("Computed values return a signal that can be read with "),e.jsx("code",{children:t.text("Signal.get()")}),t.text(":")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(5)
let doubled = Computed.make(() => Signal.get(count) * 2)

Console.log(Signal.get(doubled)) // Prints: 10

Signal.set(count, 10)
Console.log(Signal.get(doubled)) // Prints: 20`)})}),e.jsx("h2",{children:t.text("Automatic Disposal")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Computed values automatically dispose when they lose all subscribers - you don't need to manually call Computed.dispose() in most cases!")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

// Create an effect that subscribes to doubled
let disposer = Effect.run(() => {
  Console.log(Signal.get(doubled))  // doubled has 1 subscriber
  None
})

Signal.set(count, 5)  // doubled recomputes and logs

// Dispose the effect
disposer.dispose()
// ↑ doubled now has 0 subscribers - automatically disposed! ✨

Signal.set(count, 10)
// doubled doesn't recompute anymore (it was auto-disposed)`)})}),e.jsx("p",{children:t.text("This works seamlessly with Components:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let app = () => {
  let count = Signal.make(0)
  let doubled = Computed.make(() => Signal.get(count) * 2)

  <div>
    {Component.textSignal(() => Signal.get(doubled)->Int.toString)}
  </div>
}

// When the component unmounts:
// 1. The textSignal effect is disposed
// 2. doubled loses its last subscriber
// 3. doubled is automatically disposed ✨`)})}),e.jsx("h3",{children:t.text("Manual Disposal (Optional)")}),e.jsx("p",{children:t.text("You can still manually dispose computeds when needed:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

// Use it...
Console.log(Signal.get(doubled))

// Manually dispose when done
Computed.dispose(doubled)`)})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Manual disposal is useful when:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("You want explicit control over lifecycle")}),e.jsx("li",{children:t.text("The computed has no subscribers but you want to stop it anyway")}),e.jsx("li",{children:t.text("You're managing complex dependency graphs manually")})])}),e.jsx("h2",{children:t.text("Chaining Computed Values")}),e.jsx("p",{children:t.text("You can create computed values that depend on other computed values:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let price = Signal.make(100)
let quantity = Signal.make(3)

let subtotal = Computed.make(() =>
  Signal.get(price) * Signal.get(quantity)
)

let tax = Computed.make(() =>
  Signal.get(subtotal) * 0.1
)

let total = Computed.make(() =>
  Signal.get(subtotal) + Signal.get(tax)
)

Console.log(Signal.get(total)) // 330

Signal.set(quantity, 5)
Console.log(Signal.get(total)) // 550`)})}),e.jsx("h2",{children:t.text("Computed vs Manual Updates")}),e.jsx("p",{children:t.text("Instead of manually updating derived state:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`// ❌ Manual (error-prone)
let count = Signal.make(0)
let doubled = Signal.make(0)

let increment = () => {
  Signal.update(count, n => n + 1)
  Signal.set(doubled, Signal.get(count) * 2) // Easy to forget!
}`)})}),e.jsx("p",{children:t.text("Use computed values for automatic updates:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`// ✅ Automatic (safe)
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

let increment = () => {
  Signal.update(count, n => n + 1)
  // doubled automatically updates!
}`)})}),e.jsx("h2",{children:t.text("Dynamic Dependencies")}),e.jsx("p",{children:t.text("Computed values re-track dependencies on every execution, so they adapt to control flow:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let useMetric = Signal.make(true)
let celsius = Signal.make(20)
let fahrenheit = Signal.make(68)

let temperature = Computed.make(() => {
  if Signal.get(useMetric) {
    Signal.get(celsius)
  } else {
    Signal.get(fahrenheit)
  }
})

Console.log(Signal.get(temperature)) // 20

// Initially depends on: useMetric, celsius
Signal.set(useMetric, false)
// Now depends on: useMetric, fahrenheit
Console.log(Signal.get(temperature)) // 68`)})}),e.jsx("h2",{children:t.text("Best Practices")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Keep computations pure:")}),t.text(" Computed functions should not have side effects")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Use for derived state:")}),t.text(" Any value that can be calculated from other signals should be a computed")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Avoid expensive operations:")}),t.text(" Computed values recalculate eagerly, so keep them fast")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Don't nest effects:")}),t.text(" Computed values should not call Effect.run() internally")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Trust auto-disposal:")}),t.text(" In most cases, computeds will automatically clean up when their subscribers are disposed. Manual disposal is rarely needed")])})])}),e.jsx("h2",{children:t.text("Important Notes")}),e.jsx("h3",{children:t.text("Cascading Auto-Disposal")}),e.jsx("p",{children:t.text("Auto-disposal can cascade through chains of computeds:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)
let quadrupled = Computed.make(() => Signal.get(doubled) * 2)

let disposer = Effect.run(() => {
  Console.log(Signal.get(quadrupled))
  None
})

// Dependency chain: count → doubled → quadrupled → effect

disposer.dispose()
// Effect disposed → quadrupled has 0 subscribers → auto-dispose quadrupled
// → doubled has 0 subscribers → auto-dispose doubled ✨`)})}),e.jsx("p",{children:t.text("This ensures the entire chain is cleaned up automatically when the leaf subscriber is removed!")}),e.jsx("h3",{children:t.text("Push-based, Not Lazy")}),e.jsx("p",{children:t.text("Unlike some reactive systems, Xote's computed values are eager:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)
let expensive = Computed.make(() => {
  Console.log("Computing...")
  Signal.get(count) * 2
})

// "Computing..." is logged immediately

Signal.set(count, 5)
// "Computing..." is logged again, even if we never read 'expensive'`)})}),e.jsx("h2",{children:t.text("Next Steps")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([t.text("Learn about "),u.link("/docs/core-concepts/effects",void 0,[t.text("Effects")],void 0),t.text(" for side effects")])}),e.jsxs("li",{children:s([t.text("Understand "),u.link("/docs/core-concepts/batching",void 0,[t.text("Batching")],void 0),t.text(" for grouping updates")])}),e.jsxs("li",{children:s([t.text("See "),u.link("/docs/components/overview",void 0,[t.text("Components")],void 0),t.text(" to use computed values in UIs")])})])})])})}function ur(){return e.jsxs("div",{children:s([e.jsx("h1",{children:t.text("Signal API Reference")}),e.jsx("p",{children:t.text("Complete API documentation for Xote signals.")}),e.jsx("h2",{children:t.text("Type")}),e.jsx("pre",{children:e.jsx("code",{children:t.text("type t<'a>")})}),e.jsxs("p",{children:s([t.text("A signal is an opaque type representing a reactive state container. The type parameter "),e.jsx("code",{children:t.text("'a")}),t.text(" is the type of value the signal holds.")])}),e.jsx("h2",{children:t.text("Functions")}),e.jsx("h3",{children:e.jsx("code",{children:t.text("make")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text("let make: 'a => t<'a>")})}),e.jsx("p",{children:t.text("Creates a new signal with an initial value.")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Parameters:")})}),e.jsx("ul",{children:e.jsxs("li",{children:s([e.jsx("code",{children:t.text("initialValue: 'a")}),t.text(" - The initial value for the signal")])})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Returns:")})}),e.jsx("ul",{children:e.jsxs("li",{children:s([e.jsx("code",{children:t.text("t<'a>")}),t.text(" - A new signal")])})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Example:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)
let name = Signal.make("Alice")
let items = Signal.make([1, 2, 3])`)})}),e.jsx("hr",{}),e.jsx("h3",{children:e.jsx("code",{children:t.text("get")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text("let get: t<'a> => 'a")})}),e.jsx("p",{children:t.text("Reads the current value from a signal. When called inside a tracking context (effect or computed), automatically registers the signal as a dependency.")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Parameters:")})}),e.jsx("ul",{children:e.jsxs("li",{children:s([e.jsx("code",{children:t.text("signal: t<'a>")}),t.text(" - The signal to read from")])})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Returns:")})}),e.jsx("ul",{children:e.jsxs("li",{children:s([e.jsx("code",{children:t.text("'a")}),t.text(" - The current value")])})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Example:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(5)
let value = Signal.get(count) // Returns 5

Effect.run(() => {
  // Creates a dependency on count
  Console.log(Signal.get(count))
  None
})`)})}),e.jsxs("p",{children:s([e.jsx("strong",{children:t.text("Note:")}),t.text(" Always creates a dependency when called in a tracking context. Use "),e.jsx("code",{children:t.text("peek()")}),t.text(" to read without tracking.")])}),e.jsx("hr",{}),e.jsx("h3",{children:e.jsx("code",{children:t.text("peek")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text("let peek: t<'a> => 'a")})}),e.jsxs("p",{children:s([t.text("Reads the current value from a signal "),e.jsx("strong",{children:t.text("without")}),t.text(" creating a dependency, even in tracking contexts.")])}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Parameters:")})}),e.jsx("ul",{children:e.jsxs("li",{children:s([e.jsx("code",{children:t.text("signal: t<'a>")}),t.text(" - The signal to read from")])})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Returns:")})}),e.jsx("ul",{children:e.jsxs("li",{children:s([e.jsx("code",{children:t.text("'a")}),t.text(" - The current value")])})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Example:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(5)

Effect.run(() => {
  // Does NOT create a dependency
  let value = Signal.peek(count)
  Console.log(value)
  None
})

Signal.set(count, 10) // Effect will NOT re-run`)})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Use cases:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Reading signals in effects without creating dependencies")}),e.jsx("li",{children:t.text("Debugging (logging signal values without tracking)")}),e.jsx("li",{children:t.text("Reading configuration values that don't need to trigger updates")})])}),e.jsx("hr",{}),e.jsx("h3",{children:e.jsx("code",{children:t.text("set")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text("let set: (t<'a>, 'a) => unit")})}),e.jsx("p",{children:t.text("Sets a new value for the signal and notifies all dependent observers if the value has changed.")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Parameters:")})}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("code",{children:t.text("signal: t<'a>")}),t.text(" - The signal to update")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("value: 'a")}),t.text(" - The new value")])})])}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Returns:")})}),e.jsx("ul",{children:e.jsx("li",{children:e.jsx("code",{children:t.text("unit")})})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Example:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)
Signal.set(count, 10) // count is now 10, observers notified

Signal.set(count, 10) // Same value - no notification`)})}),e.jsxs("p",{children:s([e.jsx("strong",{children:t.text("Equality Check:")}),t.text(" Uses structural equality ("),e.jsx("code",{children:t.text("===")}),t.text(") to check if the value has changed. Only notifies dependent observers if the new value differs from the current value. This prevents unnecessary recomputations and helps avoid infinite loops when effects write back to their dependencies.")])}),e.jsxs("p",{children:s([e.jsx("strong",{children:t.text("Note:")}),t.text(" Custom equality functions can be provided via "),e.jsx("code",{children:t.text("Signal.make(value, ~equals=...)")}),t.text(".")])}),e.jsx("hr",{}),e.jsx("h3",{children:e.jsx("code",{children:t.text("update")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text("let update: (t<'a>, 'a => 'a) => unit")})}),e.jsx("p",{children:t.text("Updates a signal's value based on its current value.")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Parameters:")})}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("code",{children:t.text("signal: t<'a>")}),t.text(" - The signal to update")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("fn: 'a => 'a")}),t.text(" - Function that receives the current value and returns the new value")])})])}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Returns:")})}),e.jsx("ul",{children:e.jsx("li",{children:e.jsx("code",{children:t.text("unit")})})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Example:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)
Signal.update(count, n => n + 1) // count is now 1
Signal.update(count, n => n * 2) // count is now 2

let items = Signal.make([1, 2, 3])
Signal.update(items, arr => Array.concat(arr, [4, 5])) // [1, 2, 3, 4, 5]`)})}),e.jsxs("p",{children:s([e.jsx("strong",{children:t.text("Note:")}),t.text(" Equivalent to "),e.jsx("code",{children:t.text("Signal.set(signal, fn(Signal.get(signal)))")}),t.text(" but more concise.")])}),e.jsx("hr",{}),e.jsx("h3",{children:e.jsx("code",{children:t.text("batch")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text("let batch: (unit => 'a) => 'a")})}),e.jsx("p",{children:t.text("Groups multiple signal updates together, ensuring observers run only once after all updates complete.")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Parameters:")})}),e.jsx("ul",{children:e.jsxs("li",{children:s([e.jsx("code",{children:t.text("fn: unit => 'a")}),t.text(" - Function containing signal updates")])})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Returns:")})}),e.jsx("ul",{children:e.jsxs("li",{children:s([e.jsx("code",{children:t.text("'a")}),t.text(" - The return value of the function")])})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Example:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`Signal.batch(() => {
  Signal.set(firstName, "Jane")
  Signal.set(lastName, "Smith")
})
// Observers run once with both updates`)})}),e.jsx("hr",{}),e.jsx("h3",{children:e.jsx("code",{children:t.text("untrack")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text("let untrack: (unit => 'a) => 'a")})}),e.jsx("p",{children:t.text("Executes a function without tracking any signal dependencies.")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Parameters:")})}),e.jsx("ul",{children:e.jsxs("li",{children:s([e.jsx("code",{children:t.text("fn: unit => 'a")}),t.text(" - Function to execute untracked")])})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Returns:")})}),e.jsx("ul",{children:e.jsxs("li",{children:s([e.jsx("code",{children:t.text("'a")}),t.text(" - The return value of the function")])})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Example:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`Effect.run(() => {
  let tracked = Signal.get(count)

  Signal.untrack(() => {
    let untracked = Signal.get(otherSignal) // Not tracked
  })

  None
})`)})}),e.jsx("hr",{}),e.jsx("h2",{children:t.text("Examples")}),e.jsx("h3",{children:t.text("Basic Usage")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

let count = Signal.make(0)

// Read
Console.log(Signal.get(count)) // 0

// Update
Signal.set(count, 5)
Console.log(Signal.get(count)) // 5

// Update based on current value
Signal.update(count, n => n + 1)
Console.log(Signal.get(count)) // 6`)})}),e.jsx("h3",{children:t.text("With Effects")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)

Effect.run(() => {
  Console.log2("Count changed:", Signal.get(count))
  None
})

Signal.set(count, 1) // Logs: "Count changed: 1"
Signal.set(count, 2) // Logs: "Count changed: 2"`)})}),e.jsx("h3",{children:t.text("With Computed")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(5)
let doubled = Computed.make(() => Signal.get(count) * 2)

Console.log(Signal.get(doubled)) // 10

Signal.set(count, 10)
Console.log(Signal.get(doubled)) // 20`)})}),e.jsx("h3",{children:t.text("Complex State")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`type user = {
  id: int,
  name: string,
  email: string,
}

let user = Signal.make({
  id: 1,
  name: "Alice",
  email: "alice@example.com",
})

// Update specific fields
Signal.update(user, u => {...u, name: "Alice Smith"})
Signal.update(user, u => {...u, email: "alice.smith@example.com"})`)})}),e.jsx("h3",{children:t.text("Array Operations")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let todos = Signal.make([])

// Add item
Signal.update(todos, arr => Array.concat(arr, ["Buy milk"]))

// Remove item
Signal.update(todos, arr => Array.filter(arr, item => item != "Buy milk"))

// Update item
Signal.update(todos, arr =>
  Array.map(arr, item =>
    item == "Buy milk" ? "Buy oat milk" : item
  )
)`)})}),e.jsx("h2",{children:t.text("Notes")}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Signals use structural equality checks by default - only notify dependents when the value actually changes")}),e.jsxs("li",{children:s([t.text("Use "),e.jsx("code",{children:t.text("peek()")}),t.text(" to avoid creating dependencies in effects")])}),e.jsx("li",{children:t.text("Signals work with any type: primitives, records, arrays, etc.")}),e.jsxs("li",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Signal.batch()")}),t.text(" to group multiple updates")])}),e.jsx("li",{children:t.text("The equality check prevents accidental infinite loops and unnecessary recomputations")})])}),e.jsx("h2",{children:t.text("See Also")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([u.link("/docs/core-concepts/signals",void 0,[t.text("Signals Guide")],void 0),t.text(" - Conceptual overview")])}),e.jsxs("li",{children:s([u.link("/docs/core-concepts/computed",void 0,[t.text("Computed Guide")],void 0),t.text(" - Derived values")])}),e.jsxs("li",{children:s([u.link("/docs/core-concepts/effects",void 0,[t.text("Effects Guide")],void 0),t.text(" - Side effects")])}),e.jsxs("li",{children:s([u.link("/docs/core-concepts/batching",void 0,[t.text("Batching Guide")],void 0),t.text(" - Batching updates")])})])})])})}function xr(){return e.jsxs("div",{children:s([e.jsx("h1",{children:t.text("Components Overview")}),e.jsx("p",{children:t.text("Xote provides a lightweight component system for building reactive UIs. Components are functions that return virtual nodes, which are then rendered to the DOM.")}),e.jsx("p",{children:t.text("Xote supports two syntax styles for building components:")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("JSX Syntax:")}),t.text(" Modern, declarative JSX syntax (recommended)")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Function API:")}),t.text(" Explicit function calls with labeled parameters")])})])}),e.jsx("h2",{children:t.text("What are Components?")}),e.jsxs("p",{children:s([t.text("In Xote, a component is simply a function that returns a "),e.jsx("code",{children:t.text("Component.node")}),t.text(":")])}),e.jsx("h3",{children:t.text("JSX Syntax")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

let greeting = () => {
  <div>
    <h1> {Component.text("Hello, Xote!")} </h1>
  </div>
}`)})}),e.jsx("h3",{children:t.text("Function API")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

let greeting = () => {
  Component.div(
    ~children=[
      Component.h1(~children=[Component.text("Hello, Xote!")], ())
    ],
    ()
  )
}`)})}),e.jsx("h2",{children:t.text("JSX Configuration")}),e.jsxs("p",{children:s([t.text("To use JSX syntax, configure your "),e.jsx("code",{children:t.text("rescript.json")}),t.text(":")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`{
  "jsx": {
    "version": 4,
    "module": "Xote__JSX"
  }
}`)})}),e.jsx("h2",{children:t.text("Text Nodes")}),e.jsx("h3",{children:t.text("Static Text")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Component.text()")}),t.text(" for static text:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`<div>
  {Component.text("This text never changes")}
</div>`)})}),e.jsx("h3",{children:t.text("Reactive Text")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Component.textSignal()")}),t.text(" for text that updates with signals:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)

<div>
  {Component.textSignal(() =>
    "Count: " ++ Int.toString(Signal.get(count))
  )}
</div>`)})}),e.jsxs("p",{children:s([t.text("The function is tracked, so the text automatically updates when "),e.jsx("code",{children:t.text("count")}),t.text(" changes.")])}),e.jsx("h2",{children:t.text("Attributes")}),e.jsx("h3",{children:t.text("JSX Props")}),e.jsx("p",{children:t.text("JSX elements support common HTML attributes:")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("code",{children:t.text("class")}),t.text(" - CSS classes (note: "),e.jsx("code",{children:t.text("class")}),t.text(", not "),e.jsx("code",{children:t.text("className")}),t.text(")")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("id")}),t.text(" - Element ID")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("style")}),t.text(" - Inline styles")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("type_")}),t.text(" - Input type (with underscore to avoid keyword conflict)")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("value")}),t.text(" - Input value")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("placeholder")}),t.text(" - Input placeholder")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("disabled")}),t.text(" - Boolean disabled state")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("checked")}),t.text(" - Boolean checked state")])})])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`<button
  class="btn btn-primary"
  type_="button"
  disabled={true}>
  {Component.text("Submit")}
</button>`)})}),e.jsx("h3",{children:t.text("Static Attributes (Function API)")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`Component.button(
  ~attrs=[
    Component.attr("class", "btn btn-primary"),
    Component.attr("type", "button"),
    Component.attr("disabled", "true"),
  ],
  ()
)`)})}),e.jsx("h3",{children:t.text("Reactive Attributes")}),e.jsx("p",{children:t.text("Function API supports reactive attributes:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let isActive = Signal.make(false)

Component.div(
  ~attrs=[
    Component.computedAttr("class", () =>
      Signal.get(isActive) ? "active" : "inactive"
    )
  ],
  ()
)`)})}),e.jsx("h2",{children:t.text("Event Handlers")}),e.jsx("h3",{children:t.text("JSX Event Props")}),e.jsx("p",{children:t.text("JSX elements support common event handlers:")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("code",{children:t.text("onClick")}),t.text(" - Click events")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("onInput")}),t.text(" - Input events")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("onChange")}),t.text(" - Change events")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("onSubmit")}),t.text(" - Form submit events")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("onFocus")}),t.text(", "),e.jsx("code",{children:t.text("onBlur")}),t.text(" - Focus events")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("onKeyDown")}),t.text(", "),e.jsx("code",{children:t.text("onKeyUp")}),t.text(" - Keyboard events")])})])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}

<button onClick={increment}>
  {Component.text("+1")}
</button>`)})}),e.jsx("h2",{children:t.text("Lists")}),e.jsx("h3",{children:t.text("Simple Lists (Non-Keyed)")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Component.list()")}),t.text(" for simple lists where the entire list re-renders on any change:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let items = Signal.make(["Apple", "Banana", "Cherry"])

<ul>
  {Component.list(items, item =>
    <li> {Component.text(item)} </li>
  )}
</ul>`)})}),e.jsxs("p",{children:s([e.jsx("strong",{children:t.text("Note:")}),t.text(" Simple lists re-render completely when the array changes (no diffing). For better performance, use keyed lists.")])}),e.jsx("h3",{children:t.text("Keyed Lists (Efficient Reconciliation)")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("Component.listKeyed()")}),t.text(" for efficient list rendering with DOM element reuse:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`type todo = {id: int, text: string, completed: bool}
let todos = Signal.make([
  {id: 1, text: "Buy milk", completed: false},
  {id: 2, text: "Walk dog", completed: true},
])

<ul>
  {Component.listKeyed(
    todos,
    todo => todo.id->Int.toString,  // Key extractor
    todo => <li> {Component.text(todo.text)} </li>  // Renderer
  )}
</ul>`)})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Benefits of keyed lists:")})}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Reuses DOM elements")}),t.text(" - Only updates what changed")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Preserves component state")}),t.text(" - When list items move position")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Better performance")}),t.text(" - Fewer DOM operations for large lists")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Efficient reconciliation")}),t.text(" - Adds/removes/moves only necessary elements")])})])}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Best practices:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Always use unique, stable keys (like database IDs)")}),e.jsx("li",{children:t.text("Don't use array indices as keys")}),e.jsx("li",{children:t.text("Keys should be strings")}),e.jsx("li",{children:t.text("Use listKeyed for any list that can be reordered, filtered, or modified")})])}),e.jsx("h2",{children:t.text("Mounting to the DOM")}),e.jsxs("p",{children:s([t.text("Use "),e.jsx("code",{children:t.text("mountById")}),t.text(" to attach your component to an existing DOM element:")])}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let app = () => {
  <div> {Component.text("Hello, World!")} </div>
}

Component.mountById(app(), "app")`)})}),e.jsx("h2",{children:t.text("Example: Counter Component")}),e.jsx("p",{children:t.text("Here's a complete counter component using JSX:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

type counterProps = {initialValue: int}

let counter = (props: counterProps) => {
  let count = Signal.make(props.initialValue)

  let increment = (_evt: Dom.event) => {
    Signal.update(count, n => n + 1)
  }

  let decrement = (_evt: Dom.event) => {
    Signal.update(count, n => n - 1)
  }

  <div class="counter">
    <h2>
      {Component.textSignal(() =>
        "Count: " ++ Int.toString(Signal.get(count))
      )}
    </h2>
    <div class="controls">
      <button onClick={decrement}>
        {Component.text("-")}
      </button>
      <button onClick={increment}>
        {Component.text("+")}
      </button>
    </div>
  </div>
}

// Use the component
let app = counter({initialValue: 10})
Component.mountById(app, "app")`)})}),e.jsx("h2",{children:t.text("Best Practices")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Keep components small:")}),t.text(" Each component should do one thing well")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Use signals for local state:")}),t.text(" Create signals inside components for component-specific state")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Pass data via props:")}),t.text(" Use record types for component parameters")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Compose components:")}),t.text(" Build complex UIs from simple, reusable components")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Choose the right list type:")}),t.text(" Use "),e.jsx("code",{children:t.text("listKeyed")}),t.text(" for dynamic lists, "),e.jsx("code",{children:t.text("list")}),t.text(" for simple static lists")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Use class not className:")}),t.text(" In JSX, use the "),e.jsx("code",{children:t.text("class")}),t.text(" prop for CSS classes")])})])}),e.jsx("h2",{children:t.text("Next Steps")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([t.text("Try the "),u.link("/demos",void 0,[t.text("Demos")],void 0),t.text(" to see components in action")])}),e.jsxs("li",{children:s([t.text("Learn about "),u.link("/docs/router/overview",void 0,[t.text("Routing")],void 0),t.text(" for building SPAs")])}),e.jsxs("li",{children:s([t.text("Explore the "),u.link("/docs/api/signals",void 0,[t.text("API Reference")],void 0),t.text(" for detailed documentation")])})])})])})}function pr(){return e.jsxs("div",{children:s([e.jsx("h1",{children:t.text("Comparing Xote with React")}),e.jsx("p",{children:t.text("This guide compares Xote with React to help you understand the differences in philosophy, API design, and when to choose each framework.")}),e.jsx("h2",{children:t.text("Philosophy")}),e.jsxs("table",{children:s([e.jsx("thead",{children:e.jsxs("tr",{children:s([e.jsx("th",{children:t.text("Aspect")}),e.jsx("th",{children:t.text("React")}),e.jsx("th",{children:t.text("Xote")})])})}),e.jsxs("tbody",{children:s([e.jsxs("tr",{children:s([e.jsx("td",{children:e.jsx("strong",{children:t.text("Reactivity")})}),e.jsx("td",{children:t.text("Virtual DOM diffing and reconciliation")}),e.jsx("td",{children:t.text("Fine-grained reactivity with signals")})])}),e.jsxs("tr",{children:s([e.jsx("td",{children:e.jsx("strong",{children:t.text("Updates")})}),e.jsx("td",{children:t.text("Re-render component trees on state change")}),e.jsx("td",{children:t.text("Direct DOM updates at the signal level")})])}),e.jsxs("tr",{children:s([e.jsx("td",{children:e.jsx("strong",{children:t.text("State")})}),e.jsx("td",{children:t.text("useState, useReducer hooks")}),e.jsx("td",{children:t.text("Signal primitives (Signal, Computed, Effect)")})])}),e.jsxs("tr",{children:s([e.jsx("td",{children:e.jsx("strong",{children:t.text("Side Effects")})}),e.jsx("td",{children:t.text("useEffect hook with dependency array")}),e.jsx("td",{children:t.text("Effect.run with automatic dependency tracking")})])}),e.jsxs("tr",{children:s([e.jsx("td",{children:e.jsx("strong",{children:t.text("Ecosystem")})}),e.jsx("td",{children:t.text("Massive: thousands of libraries and tools")}),e.jsx("td",{children:t.text("Minimal: focused on core reactivity")})])}),e.jsxs("tr",{children:s([e.jsx("td",{children:e.jsx("strong",{children:t.text("Bundle Size")})}),e.jsx("td",{children:t.text("~45KB (React + ReactDOM minified)")}),e.jsx("td",{children:t.text("~8KB (Xote + rescript-signals minified)")})])})])})])}),e.jsx("h2",{children:t.text("Code Comparison: Counter Example")}),e.jsx("h3",{children:t.text("React Version")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`import { useState } from 'react';

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <h1>Count: {count}</h1>
      <button onClick={() => setCount(count + 1)}>
        Increment
      </button>
    </div>
  );
}`)})}),e.jsx("h3",{children:t.text("Xote Version")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`open Xote

let counter = () => {
  let count = Signal.make(0)

  <div>
    <h1>
      {Component.textSignal(() =>
        "Count: " ++ Int.toString(Signal.get(count))
      )}
    </h1>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {Component.text("Increment")}
    </button>
  </div>
}`)})}),e.jsx("h2",{children:t.text("Key Differences")}),e.jsx("h3",{children:t.text("1. Reactivity Model")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("React:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Re-renders entire component on state change")}),e.jsx("li",{children:t.text("Virtual DOM diffing determines what changed")}),e.jsx("li",{children:t.text("Batches updates automatically")}),e.jsx("li",{children:t.text("May re-render child components unnecessarily")})])}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Xote:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Updates only the specific DOM nodes that depend on changed signals")}),e.jsx("li",{children:t.text("No virtual DOM - direct DOM manipulation")}),e.jsx("li",{children:t.text("Synchronous updates by default")}),e.jsx("li",{children:t.text("Minimal overhead per update")})])}),e.jsx("h3",{children:t.text("2. Side Effects and Dependencies")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("React useEffect:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`// React - Manual dependency array
useEffect(() => {
  console.log("Count changed:", count);
}, [count]); // Must manually specify dependencies`)})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Xote Effect:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`// Xote - Automatic dependency tracking
Effect.run(() => {
  Console.log2("Count changed:", Signal.get(count))
  None // No dependencies needed - automatically tracked!
})`)})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Key difference:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("React requires manual dependency arrays - risk of stale closures and bugs")}),e.jsx("li",{children:t.text("Xote automatically tracks dependencies during execution - no arrays needed")})])}),e.jsx("h3",{children:t.text("3. Derived State")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("React useMemo:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`// React - Must specify dependencies
const doubled = useMemo(() => count * 2, [count]);`)})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Xote Computed:")})}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`// Xote - Automatic tracking
let doubled = Computed.make(() => Signal.get(count) * 2)`)})}),e.jsx("h3",{children:t.text("4. Component Lifecycle")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("React:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Components are functions that re-execute on every render")}),e.jsx("li",{children:t.text("Hooks must follow rules of hooks (order matters)")}),e.jsx("li",{children:t.text("useEffect cleanup functions for teardown")})])}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Xote:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Components are functions that execute once")}),e.jsx("li",{children:t.text("Signals/effects created inside persist")}),e.jsx("li",{children:t.text("Effect cleanup via Some(cleanupFn) return values")})])}),e.jsx("h2",{children:t.text("Code Comparison: Todo List")}),e.jsx("h3",{children:t.text("React Version")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`function TodoList() {
  const [todos, setTodos] = useState([]);
  const [input, setInput] = useState("");

  const addTodo = () => {
    setTodos([...todos, input]);
    setInput("");
  };

  return (
    <div>
      <input
        value={input}
        onChange={(e) => setInput(e.target.value)}
      />
      <button onClick={addTodo}>Add</button>
      <ul>
        {todos.map((todo, i) => (
          <li key={i}>{todo}</li>
        ))}
      </ul>
    </div>
  );
}`)})}),e.jsx("h3",{children:t.text("Xote Version")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`let todoList = () => {
  let todos = Signal.make([])
  let input = Signal.make("")

  let addTodo = _ => {
    Signal.update(todos, arr => Array.concat(arr, [Signal.peek(input)]))
    Signal.set(input, "")
  }

  <div>
    <input
      value={Signal.peek(input)}
      onInput={evt => {
        let value = %raw(\`evt.target.value\`)
        Signal.set(input, value)
      }}
    />
    <button onClick={addTodo}>
      {Component.text("Add")}
    </button>
    <ul>
      {Component.list(todos, todo =>
        <li> {Component.text(todo)} </li>
      )}
    </ul>
  </div>
}`)})}),e.jsx("h2",{children:t.text("When to Choose React")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Large ecosystem needed:")}),t.text(" Need access to thousands of React libraries, UI components, and tools")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Team experience:")}),t.text(" Team is already proficient in React and JavaScript/TypeScript")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Server-side rendering:")}),t.text(" Need Next.js or other mature SSR solutions")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Mobile apps:")}),t.text(" Want to use React Native for cross-platform development")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Hiring:")}),t.text(" Easier to find React developers in the job market")])})])}),e.jsx("h2",{children:t.text("When to Choose Xote")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Fine-grained reactivity:")}),t.text(" Need precise, efficient updates without virtual DOM overhead")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Type safety:")}),t.text(" Want ReScript's powerful type system and compiler guarantees")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Small bundle size:")}),t.text(" Every kilobyte counts for your use case")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Learning signals:")}),t.text(" Want to explore signal-based reactivity aligned with TC39 proposal")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Functional programming:")}),t.text(" Prefer ReScript's functional approach over JavaScript")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Minimal dependencies:")}),t.text(" Want a focused library without a large ecosystem dependency")])})])}),e.jsx("h2",{children:t.text("Performance Comparison")}),e.jsx("h3",{children:t.text("React")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Pros:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Highly optimized virtual DOM diffing")}),e.jsx("li",{children:t.text("Automatic batching of updates in React 18+")}),e.jsx("li",{children:t.text("Concurrent rendering features")}),e.jsx("li",{children:t.text("Memo and useMemo for optimization")})])}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Cons:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Virtual DOM overhead for all updates")}),e.jsx("li",{children:t.text("Re-renders can cascade through component tree")}),e.jsx("li",{children:t.text("Requires manual optimization (React.memo, useMemo)")}),e.jsx("li",{children:t.text("Larger bundle size")})])}),e.jsx("h3",{children:t.text("Xote")}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Pros:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Direct DOM updates - no virtual DOM overhead")}),e.jsx("li",{children:t.text("Fine-grained reactivity - only affected nodes update")}),e.jsx("li",{children:t.text("No unnecessary component re-renders")}),e.jsx("li",{children:t.text("Smaller bundle size (~5x smaller)")})])}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Cons:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("List updates replace all children (no diffing/reconciliation)")}),e.jsx("li",{children:t.text("Less battle-tested than React")}),e.jsx("li",{children:t.text("Smaller community and fewer optimization resources")})])}),e.jsx("h2",{children:t.text("Migration Considerations")}),e.jsx("h3",{children:t.text("From React to Xote")}),e.jsx("p",{children:t.text("Key concepts that map over:")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("code",{children:t.text("useState")}),t.text(" → "),e.jsx("code",{children:t.text("Signal.make")})])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("useMemo")}),t.text(" → "),e.jsx("code",{children:t.text("Computed.make")})])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("useEffect")}),t.text(" → "),e.jsx("code",{children:t.text("Effect.run")})])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("JSX")}),t.text(" → "),e.jsx("code",{children:t.text("Xote JSX (similar syntax)")})])})])}),e.jsx("p",{children:t.text("Challenges:")}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Learning ReScript syntax and type system")}),e.jsx("li",{children:t.text("Different mental model (signals vs. re-renders)")}),e.jsx("li",{children:t.text("No direct equivalent for many React libraries")}),e.jsx("li",{children:t.text("Need to rethink component composition patterns")})])}),e.jsx("h2",{children:t.text("Conclusion")}),e.jsx("p",{children:t.text("React and Xote take fundamentally different approaches to reactivity. React's virtual DOM and re-rendering model is mature, well-understood, and backed by a massive ecosystem. Xote's signal-based fine-grained reactivity offers performance benefits and a simpler mental model, but with a smaller ecosystem.")}),e.jsx("p",{children:t.text("Choose React if you need the ecosystem, tooling, and community. Choose Xote if you value type safety, minimal bundle size, and want to explore signal-based reactivity with ReScript.")}),e.jsx("h2",{children:t.text("Further Reading")}),e.jsxs("ul",{children:s([e.jsx("li",{children:u.link("/docs/core-concepts/signals",void 0,[t.text("Xote Signals Guide")],void 0)}),e.jsx("li",{children:u.link("/docs/components/overview",void 0,[t.text("Xote Components")],void 0)}),e.jsx("li",{children:e.jsx("a",{href:"https://react.dev",target:"_blank",children:t.text("React Documentation")})}),e.jsx("li",{children:e.jsx("a",{href:"https://github.com/tc39/proposal-signals",target:"_blank",children:t.text("TC39 Signals Proposal")})})])})])})}function mr(){return e.jsxs("div",{children:s([e.jsx("h1",{children:t.text("Technical Overview")}),e.jsx("p",{children:t.text("This document describes the architecture of Xote, a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system.")}),e.jsx("div",{class:"info-box",children:e.jsxs("p",{children:s([e.jsx("strong",{children:t.text("Note:")}),t.text(" Xote v3.0+ uses rescript-signals for all reactive primitives (Signal, Computed, Effect). This overview focuses on Xote-specific features: Components, Router, and JSX support.")])})}),e.jsx("h2",{children:t.text("Architecture Overview")}),e.jsx("h3",{children:t.text("Module Structure")}),e.jsx("p",{children:t.text("Xote is organized into focused modules:")}),e.jsx("ul",{children:e.jsx("li",{children:e.jsx("strong",{children:t.text("Reactive Primitives (from rescript-signals):")})})}),e.jsxs("p",{children:s([t.text("  - "),e.jsx("code",{children:t.text("Signal")}),t.text(" - Reactive state cells")])}),e.jsxs("p",{children:s([t.text("  - "),e.jsx("code",{children:t.text("Computed")}),t.text(" - Derived values that auto-update")])}),e.jsxs("p",{children:s([t.text("  - "),e.jsx("code",{children:t.text("Effect")}),t.text(" - Side effects that re-run on changes")])}),e.jsx("ul",{children:e.jsx("li",{children:e.jsx("strong",{children:t.text("Xote Modules:")})})}),e.jsxs("p",{children:s([t.text("  - "),e.jsx("code",{children:t.text("Xote__Component")}),t.text(" - Component system and virtual DOM")])}),e.jsxs("p",{children:s([t.text("  - "),e.jsx("code",{children:t.text("Xote__JSX")}),t.text(" - Generic JSX v4 implementation")])}),e.jsxs("p",{children:s([t.text("  - "),e.jsx("code",{children:t.text("Xote__Router")}),t.text(" - Signal-based routing")])}),e.jsxs("p",{children:s([t.text("  - "),e.jsx("code",{children:t.text("Xote__Route")}),t.text(" - Route matching utilities")])}),e.jsxs("p",{children:s([t.text("  - "),e.jsx("code",{children:t.text("Xote.res")}),t.text(" - Public API surface")])}),e.jsx("h2",{children:t.text("Reactivity Model")}),e.jsxs("p",{children:s([t.text("All reactive behavior is provided by "),e.jsx("a",{href:"https://github.com/pedrobslisboa/rescript-signals",target:"_blank",children:t.text("rescript-signals")}),t.text(":")])}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Dependency Tracking:")}),t.text(" When an observer (effect or computed) runs, any Signal.get calls register the signal as a dependency")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Scheduling:")}),t.text(" When Signal.set is called, all dependent observers are scheduled and run synchronously")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Push-based Computeds:")}),t.text(" Computeds eagerly recompute when dependencies change and push results to their backing signal")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Structural Equality:")}),t.text(" Signals use structural equality (==) to check if values have changed, preventing unnecessary updates")])})])}),e.jsx("h2",{children:t.text("Component System")}),e.jsx("h3",{children:t.text("Virtual Node Types")}),e.jsx("p",{children:t.text("Xote uses several node types to represent UI elements:")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Element:")}),t.text(" Standard DOM elements (div, button, input, etc.)")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Text:")}),t.text(" Static text nodes")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("SignalText:")}),t.text(" Reactive text that updates when signals change")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Fragment:")}),t.text(" Groups multiple nodes without a wrapper element")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("SignalFragment:")}),t.text(" Reactive fragment that re-renders when a signal changes")])})])}),e.jsx("h3",{children:t.text("Rendering Behavior")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("SignalText:")}),t.text(" Creates a DOM text node and sets up an effect that updates textContent when the signal changes")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("SignalFragment:")}),t.text(" Uses a container element with display: contents and replaces all children when the signal changes (no diffing)")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Lists:")}),t.text(" Implemented as a computed signal + SignalFragment, so the entire list rerenders on any array change")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Reactive attributes:")}),t.text(" Set up effects that update the DOM attribute when the signal/computed value changes")])})])}),e.jsx("h2",{children:t.text("JSX Support")}),e.jsx("p",{children:t.text("Xote supports ReScript's generic JSX v4 for declarative component syntax:")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`{
  "jsx": {
    "version": 4,
    "module": "Xote__JSX"
  }
}`)})}),e.jsx("p",{children:e.jsx("strong",{children:t.text("Features:")})}),e.jsxs("ul",{children:s([e.jsx("li",{children:t.text("Lowercase tags for HTML elements")}),e.jsx("li",{children:t.text("Props support for common attributes and events")}),e.jsx("li",{children:t.text("Children passed via JSX syntax")}),e.jsx("li",{children:t.text("Component functions called with props objects")})])}),e.jsx("h2",{children:t.text("Router Architecture")}),e.jsx("h3",{children:t.text("Route Matching")}),e.jsx("p",{children:t.text("Pattern-based string matching with :param syntax:")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("code",{children:t.text("parsePattern(pattern)")}),t.text(" converts patterns like /users/:id into segment arrays")])}),e.jsxs("li",{children:s([e.jsx("code",{children:t.text("matchPath(pattern, pathname)")}),t.text(" returns Match(params) or NoMatch")])}),e.jsx("li",{children:t.text("Parameters returned as Dict.t<string>")})])}),e.jsx("h3",{children:t.text("Router State")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Location signal:")}),t.text(" "),e.jsx("code",{children:t.text("Router.location")}),t.text(" contains {pathname, search, hash}")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("History API integration:")}),t.text(" Listens to popstate events for back/forward buttons")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Declarative routing:")}),t.text(" Uses SignalFragment + Computed for reactive rendering")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Navigation links:")}),t.text(" Intercepts clicks to prevent page reload")])})])}),e.jsx("h2",{children:t.text("Execution Characteristics")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Push-based:")}),t.text(" Signals push notifications to observers; computeds eagerly push into their backing signal")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Auto-tracked:")}),t.text(" Observers re-track dependencies on every run")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Synchronous:")}),t.text(" Updates run synchronously by default")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Exception safe:")}),t.text(" Scheduler wrapped in try/catch to ensure tracking state is restored")])})])}),e.jsx("h2",{children:t.text("Relation to TC39 Signals Proposal")}),e.jsxs("p",{children:s([t.text("Xote's reactive primitives (via rescript-signals) are inspired by the "),e.jsx("a",{href:"https://github.com/tc39/proposal-signals",target:"_blank",children:t.text("TC39 Signals proposal")}),t.text(":")])}),e.jsx("ul",{children:e.jsx("li",{children:e.jsx("strong",{children:t.text("Aligned concepts:")})})}),e.jsx("p",{children:t.text("  - Automatic dependency tracking on read")}),e.jsx("p",{children:t.text("  - Observer-based recomputation and re-tracking")}),e.jsx("p",{children:t.text("  - Structural equality checks")}),e.jsx("ul",{children:e.jsx("li",{children:e.jsx("strong",{children:t.text("Key differences:")})})}),e.jsx("p",{children:t.text("  - Computeds are push-based (eager) rather than pull-based (lazy) as in the proposal")}),e.jsx("p",{children:t.text("  - Synchronous scheduling rather than microtask-based")}),e.jsx("p",{children:t.text("  - Effects can return cleanup callbacks (Some/None pattern)")}),e.jsx("h2",{children:t.text("API Summary")}),e.jsx("h3",{children:t.text("Reactive Primitives")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`Signal.make : 'a => t<'a>
Signal.get : t<'a> => 'a
Signal.peek : t<'a> => 'a
Signal.set : (t<'a>, 'a) => unit
Signal.update : (t<'a>, 'a => 'a) => unit

Computed.make : (unit => 'a) => t<'a>
Computed.dispose : t<'a> => unit

Effect.run : (unit => option<unit => unit>) => {dispose: unit => unit}`)})}),e.jsx("h3",{children:t.text("Component Helpers")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`Component.text : string => node
Component.textSignal : (unit => string) => node
Component.list : (t<array<'a>>, 'a => node) => node
Component.listKeyed : (t<array<'a>>, 'a => string, 'a => node) => node
Component.mount : (node, Dom.element) => unit
Component.mountById : (node, string) => unit`)})}),e.jsx("h3",{children:t.text("Router Helpers")}),e.jsx("pre",{children:e.jsx("code",{children:t.text(`Router.init : unit => unit
Router.location : t<{pathname: string, search: string, hash: string}>
Router.push : (string, ~search: string=?, ~hash: string=?, unit) => unit
Router.replace : (string, ~search: string=?, ~hash: string=?, unit) => unit
Router.routes : array<{pattern: string, render: params => node}> => node
Router.link : (~to: string, ~attrs: array=?, ~children: array=?, unit) => node`)})}),e.jsx("h2",{children:t.text("Best Practices")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Trust auto-disposal:")}),t.text(" Computeds auto-dispose when subscribers drop to zero")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Use structural equality:")}),t.text(" Signal.set only notifies if values differ")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Prefer JSX:")}),t.text(" More concise and familiar syntax")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Keep components small:")}),t.text(" Each component should do one thing well")])}),e.jsxs("li",{children:s([e.jsx("strong",{children:t.text("Use keyed lists:")}),t.text(" For efficient reconciliation of dynamic lists")])})])}),e.jsx("h2",{children:t.text("Next Steps")}),e.jsxs("ul",{children:s([e.jsxs("li",{children:s([t.text("Explore the "),u.link("/docs/core-concepts/signals",void 0,[t.text("Core Concepts")],void 0),t.text(" for reactive primitives")])}),e.jsxs("li",{children:s([t.text("Learn about "),u.link("/docs/components/overview",void 0,[t.text("Components")],void 0),t.text(" for building UIs")])}),e.jsxs("li",{children:s([t.text("Check out "),e.jsx("a",{href:"https://github.com/pedrobslisboa/rescript-signals",target:"_blank",children:t.text("rescript-signals")}),t.text(" for reactive implementation details")])})])})])})}u.init(void 0,void 0);function gr(n){return p(Ie,{children:e.jsxs("div",{class:"not-found",children:s([e.jsx("h1",{children:t.text("404")}),e.jsx("p",{children:t.text("The page you're looking for doesn't exist.")}),u.link("/",[t.attr("class","btn btn-primary")],[t.text("Go Home")],void 0)])})})}function fr(n){return u.routes([{pattern:"/",render:i=>p(nr,{})},{pattern:"/demos",render:i=>p(lr,{})},{pattern:"/docs",render:i=>p(N,{currentPath:"/docs",content:at(),pageTitle:"Introduction",pageLead:"Get started with Xote, a lightweight reactive UI library for ReScript."})},{pattern:"/docs/",render:i=>p(N,{currentPath:"/docs",content:at(),pageTitle:"Introduction",pageLead:"Get started with Xote, a lightweight reactive UI library for ReScript."})},{pattern:"/docs/core-concepts/signals",render:i=>p(N,{currentPath:"/docs/core-concepts/signals",content:or(),pageTitle:"Signals",pageLead:"Reactive state cells that form the foundation of Xote's reactivity model.",tocItems:[{text:"Creating Signals",id:"creating-signals",level:2},{text:"Reading Values",id:"reading-values",level:2},{text:"Updating Signals",id:"updating-signals",level:2},{text:"Structural Equality",id:"structural-equality",level:2}]})},{pattern:"/docs/core-concepts/computed",render:i=>p(N,{currentPath:"/docs/core-concepts/computed",content:hr(),pageTitle:"Computed",pageLead:"Derived signals that automatically recompute when their dependencies change."})},{pattern:"/docs/core-concepts/effects",render:i=>p(N,{currentPath:"/docs/core-concepts/effects",content:ar(),pageTitle:"Effects",pageLead:"Side effects that run when their dependencies change, with automatic cleanup."})},{pattern:"/docs/core-concepts/batching",render:i=>p(N,{currentPath:"/docs/core-concepts/batching",content:dr(),pageTitle:"Batching",pageLead:"Group multiple signal updates to run observers only once."})},{pattern:"/docs/components/overview",render:i=>p(N,{currentPath:"/docs/components/overview",content:xr(),pageTitle:"Components",pageLead:"The Xote component system for building reactive user interfaces."})},{pattern:"/docs/router/overview",render:i=>p(N,{currentPath:"/docs/router/overview",content:cr(),pageTitle:"Router",pageLead:"Signal-based client-side router with pattern matching and dynamic routes."})},{pattern:"/docs/api/signals",render:i=>p(N,{currentPath:"/docs/api/signals",content:ur(),pageTitle:"Signals API",pageLead:"Complete API reference for Signal, Computed, and Effect."})},{pattern:"/docs/comparisons/react",render:i=>p(N,{currentPath:"/docs/comparisons/react",content:pr(),pageTitle:"React Comparison",pageLead:"How Xote's reactivity model compares to React's component model."})},{pattern:"/docs/technical-overview",render:i=>p(N,{currentPath:"/docs/technical-overview",content:mr(),pageTitle:"Technical Overview",pageLead:"Deep dive into Xote's architecture, scheduling, and reactivity internals."})},{pattern:"*",render:i=>p(gr,{})}])}t.mountById(p(fr,{}),"app");
