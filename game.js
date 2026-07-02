'use strict';
/* ===================== 裂隙远征 · Pixel Tactics ===================== */
const COLS=14, ROWS=10, T=32, S=3;           // logical tile 32px, render scale 3
const cv=document.getElementById('game'), ctx=cv.getContext('2d');
cv.width=COLS*T*S; cv.height=ROWS*T*S;
ctx.setTransform(S,0,0,S,0,0); ctx.imageSmoothingEnabled=false;

/* ---------- tiny helpers ---------- */
const rnd=(a,b)=>a+Math.random()*(b-a);
const ri=(a,b)=>Math.floor(rnd(a,b+1));
const clamp=(v,a,b)=>v<a?a:v>b?b:v;
function mulberry(seed){return function(){seed|=0;seed=seed+0x6D2B79F5|0;let t=Math.imul(seed^seed>>>15,1|seed);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296;};}

/* ===================== MAP ===================== */
const MAP=[
 'MGGGFFWWGGGFGM',
 'GGFFGGWWGGFFGG',
 'GFFGGGWWGGGGFG',
 'GGGGRRRRRRGGGG',
 'FGGGGGWWGGFFGG',
 'FFGGFGWWGGGGFF',
 'GGGFGGWWGGGFFG',
 'GGGRRRRRRRRGGG',
 'GMGGGGFGGGGGMG',
 'MMGGFFGGFGGGMM'
];
const TERR={
 G:{name:'草地',cost:1,def:0,avoid:0,block:false},
 R:{name:'道路',cost:1,def:0,avoid:0,block:false},
 F:{name:'森林',cost:2,def:2,avoid:20,block:false},
 W:{name:'水域',cost:99,def:0,avoid:0,block:true},
 M:{name:'山岭',cost:99,def:0,avoid:0,block:true}
};
const tileAt=(x,y)=>MAP[y][x];
const terr=(x,y)=>TERR[tileAt(x,y)];
const inb=(x,y)=>x>=0&&y>=0&&x<COLS&&y<ROWS;

/* ===================== SPRITE FACTORY (procedural pixel art) ===================== */
// draw on a small canvas, then add a 1px dark outline, then cache. Crisp on upscale.
function px(g,x,y,c){g.fillStyle=c;g.fillRect(x,y,1,1);}
function rc(g,x,y,w,h,c){g.fillStyle=c;g.fillRect(x,y,w,h);}
function outline(cn,col){
 const g=cn.getContext('2d'),w=cn.width,h=cn.height;
 const src=g.getImageData(0,0,w,h),d=src.data;
 const out=g.createImageData(w,h),o=out.data;
 const A=(x,y)=>(x<0||y<0||x>=w||y>=h)?0:d[(y*w+x)*4+3];
 const cc=hex(col);
 for(let y=0;y<h;y++)for(let x=0;x<w;x++){
  const i=(y*w+x)*4;
  if(d[i+3]>0){o[i]=d[i];o[i+1]=d[i+1];o[i+2]=d[i+2];o[i+3]=d[i+3];}
  else if(A(x-1,y)||A(x+1,y)||A(x,y-1)||A(x,y+1)||A(x-1,y-1)||A(x+1,y-1)||A(x-1,y+1)||A(x+1,y+1)){
   o[i]=cc[0];o[i+1]=cc[1];o[i+2]=cc[2];o[i+3]=255;}
 }
 g.putImageData(out,0,0);
}
function hex(h){h=h.replace('#','');return [parseInt(h.slice(0,2),16),parseInt(h.slice(2,4),16),parseInt(h.slice(4,6),16)];}
function shade(hexc,f){const c=hex(hexc);return `rgb(${clamp(c[0]*f|0,0,255)},${clamp(c[1]*f|0,0,255)},${clamp(c[2]*f|0,0,255)})`;}

const SZ=24, CX=12;
function sprite(draw){
 const c=document.createElement('canvas');c.width=SZ;c.height=SZ;
 const g=c.getContext('2d');g.imageSmoothingEnabled=false;
 draw(g);
 outline(c,'#140f1d');
 return c;
}
// shared body: legs+torso. pal={skin,cloth,cloth2,metal,accent}
function body(g,pal,cloak){
 // legs
 rc(g,9,18,2,4,'#3b3348'); rc(g,13,18,2,4,'#3b3348');
 rc(g,9,21,2,1,'#241f30'); rc(g,13,21,2,1,'#241f30');
 if(cloak){ rc(g,7,12,10,8,pal.cloth2); }
 // torso
 rc(g,8,12,8,7,pal.cloth);
 rc(g,8,12,8,2,shade(pal.cloth,1.18));   // top highlight
 rc(g,14,14,2,5,shade(pal.cloth,0.72));  // right shade
 rc(g,11,12,2,7,pal.accent);             // center strip / tabard
 // shoulders
 rc(g,7,12,2,3,pal.metal); rc(g,15,12,2,3,shade(pal.metal,0.8));
 // head
 rc(g,9,6,6,6,pal.skin); rc(g,9,6,6,1,shade(pal.skin,1.12)); rc(g,14,7,1,5,shade(pal.skin,0.8));
 // eyes
 px(g,10,9,'#20141a'); px(g,13,9,'#20141a');
}
const SPR={};
function buildSprites(){
 // ---- Knight (blue) ----
 SPR.knight=sprite(g=>{
  const pal={skin:'#f0c39a',cloth:'#c9ccd6',cloth2:'#8a90a0',metal:'#e6e9f0',accent:'#3f6fc4'};
  body(g,pal,false);
  // helmet
  rc(g,8,4,8,4,'#c9ccd6'); rc(g,8,4,8,1,'#eef1f6'); rc(g,9,7,6,1,'#2a2436'); // visor
  rc(g,8,6,8,1,'#9aa0ae');
  rc(g,11,1,2,3,'#3f6fc4'); rc(g,11,1,2,1,'#6f95df'); // plume
  // shield (left)
  rc(g,4,12,4,7,'#3f6fc4'); rc(g,4,12,4,1,'#6f95df'); rc(g,5,14,2,3,'#e3b34a');
  // sword (right)
  rc(g,18,4,1,11,'#eef1f6'); rc(g,17,14,3,1,'#b9862e'); rc(g,18,15,1,2,'#7a5a1e');
 });
 // ---- Lancer / Guardian (teal) ----
 SPR.lancer=sprite(g=>{
  const pal={skin:'#e9b892',cloth:'#b7c2c0',cloth2:'#7f8c8a',metal:'#dfe7e4',accent:'#2f9b8e'};
  body(g,pal,false);
  rc(g,8,4,8,4,'#cfd8d5'); rc(g,8,4,8,1,'#eef4f2'); rc(g,9,7,6,1,'#2a2436');
  rc(g,10,1,4,2,'#2f9b8e');
  // spear (right, long)
  rc(g,18,1,1,17,'#9c6b34'); rc(g,17,1,3,3,'#eef4f2'); rc(g,18,0,1,2,'#cfd8d5');
  // small shield
  rc(g,5,13,3,5,'#2f9b8e'); rc(g,5,13,3,1,'#57c2b4');
 });
 // ---- Archer (green hood) ----
 SPR.archer=sprite(g=>{
  const pal={skin:'#f0c39a',cloth:'#4f7a44',cloth2:'#3c5c34',metal:'#6b8a5c',accent:'#8bbf6a'};
  body(g,pal,true);
  // hood
  rc(g,8,4,8,5,'#3c5c34'); rc(g,8,4,8,1,'#557a48'); rc(g,9,9,6,2,'#f0c39a'); // face under hood
  px(g,10,10,'#20141a'); px(g,13,10,'#20141a');
  // bow (left curve)
  rc(g,5,5,1,13,'#8a5a2e'); px(g,6,4,'#8a5a2e'); px(g,6,18,'#8a5a2e'); px(g,7,5,'#8a5a2e'); px(g,7,17,'#8a5a2e');
  rc(g,7,6,1,10,'#d8c48a'); // string
 });
 // ---- Mage (purple) ----
 SPR.mage=sprite(g=>{
  const pal={skin:'#f0c39a',cloth:'#6a49b0',cloth2:'#4c3488',metal:'#8a6bd0',accent:'#b48ce6'};
  // robe wider
  rc(g,7,12,10,9,'#6a49b0'); rc(g,7,12,10,2,'#8a6bd0'); rc(g,14,14,3,7,'#4c3488');
  rc(g,11,12,2,9,'#b48ce6');
  rc(g,9,6,6,6,pal.skin); rc(g,14,7,1,5,shade(pal.skin,0.8));
  px(g,10,9,'#20141a'); px(g,13,9,'#20141a');
  // wizard hat
  rc(g,8,5,8,2,'#4c3488'); rc(g,10,2,4,3,'#6a49b0'); rc(g,11,0,2,2,'#4c3488'); px(g,12,0,'#e3b34a');
  // staff + orb
  rc(g,18,3,1,15,'#8a5a2e'); rc(g,17,2,3,3,'#7fd8ff'); px(g,18,3,'#d8f6ff');
 });
 // ---- Cleric (white/gold) ----
 SPR.cleric=sprite(g=>{
  const pal={skin:'#f0c39a',cloth:'#eae6df',cloth2:'#c7c2b6',metal:'#e3b34a',accent:'#e3b34a'};
  rc(g,7,12,10,9,'#eae6df'); rc(g,7,12,10,2,'#fbf8f2'); rc(g,14,14,3,7,'#cbc5b6');
  rc(g,11,12,2,9,'#e3b34a');
  rc(g,9,6,6,6,pal.skin); rc(g,14,7,1,5,shade(pal.skin,0.8));
  px(g,10,9,'#20141a'); px(g,13,9,'#20141a');
  rc(g,8,4,8,4,'#f2eee6'); rc(g,8,4,8,1,'#ffffff'); // hood
  // staff with cross
  rc(g,18,3,1,15,'#cbb488'); rc(g,16,4,5,1,'#e3b34a'); rc(g,18,2,1,3,'#e3b34a');
 });
 // ---- Orc Grunt (green, club) ----
 SPR.grunt=sprite(g=>{
  const pal={skin:'#7cae4e',cloth:'#7a5236',cloth2:'#5c3e28',metal:'#9c7248',accent:'#b03a3a'};
  body(g,pal,false);
  // green skin overwrite head
  rc(g,9,6,6,6,'#7cae4e'); rc(g,9,6,6,1,'#93c563'); rc(g,14,7,1,5,'#5f8a3a');
  px(g,10,9,'#2a0d0d'); px(g,13,9,'#2a0d0d'); px(g,11,7,'#c94b4b'); // brow
  rc(g,9,11,6,1,'#5f8a3a'); px(g,10,11,'#eae0c0'); px(g,13,11,'#eae0c0'); // tusks
  // club (right)
  rc(g,17,5,2,8,'#7a5236'); rc(g,16,4,4,4,'#8a5f3e'); px(g,17,5,'#5c3e28');
 });
 // ---- Orc Brute (big, axe, red warpaint) ----
 SPR.brute=sprite(g=>{
  const pal={skin:'#6fa040',cloth:'#5c3a2c',cloth2:'#43291f',metal:'#8a5a3a',accent:'#c0392b'};
  // broad torso
  rc(g,6,12,12,8,'#5c3a2c'); rc(g,6,12,12,2,'#6f4735'); rc(g,15,14,3,6,'#43291f');
  rc(g,10,12,4,8,'#8a5a3a');
  rc(g,5,12,2,4,'#7cae4e'); rc(g,17,12,2,4,'#5f8a3a'); // arms
  rc(g,8,4,8,7,'#6fa040'); rc(g,8,4,8,1,'#86bf55'); rc(g,15,6,1,5,'#4f7a30');
  px(g,10,8,'#2a0d0d'); px(g,13,8,'#2a0d0d'); rc(g,9,6,6,1,'#c0392b'); // warpaint
  rc(g,9,10,6,1,'#4f7a30'); px(g,10,10,'#eae0c0'); px(g,13,10,'#eae0c0');
  rc(g,9,18,2,4,'#3b2a1e'); rc(g,13,18,2,4,'#3b2a1e');
  // big axe
  rc(g,18,3,1,14,'#7a5236'); rc(g,17,3,4,5,'#c9ccd6'); rc(g,20,4,1,3,'#9aa0ae');
 });
 // ---- Goblin Archer (small, bow, hood) ----
 SPR.goblin=sprite(g=>{
  const pal={skin:'#94c25a',cloth:'#5a4a2e',cloth2:'#3f3320',metal:'#7a6238',accent:'#8a2f2f'};
  rc(g,10,18,2,4,'#3b3020'); rc(g,13,18,1,4,'#3b3020');
  rc(g,9,13,7,6,'#5a4a2e'); rc(g,9,13,7,1,'#6f5c3a'); rc(g,13,15,3,4,'#3f3320');
  rc(g,9,7,6,6,'#94c25a'); rc(g,14,8,1,5,'#6f9a3f');
  px(g,10,10,'#2a0d0d'); px(g,13,10,'#2a0d0d');
  rc(g,8,5,8,4,'#3f3320'); rc(g,8,5,8,1,'#5a4a2e'); // hood
  rc(g,5,6,1,12,'#7a5230'); px(g,6,5,'#7a5230'); px(g,6,18,'#7a5230');
  rc(g,6,7,1,9,'#cbb98a');
 });
 // ---- Orc Shaman (purple robe, staff) ----
 SPR.shaman=sprite(g=>{
  rc(g,7,12,10,9,'#59346f'); rc(g,7,12,10,2,'#7a4c96'); rc(g,14,14,3,7,'#3f2350');
  rc(g,11,12,2,9,'#c05a9a');
  rc(g,9,6,6,6,'#7cae4e'); rc(g,14,7,1,5,'#5f8a3a');
  px(g,10,9,'#2a0d0d'); px(g,13,9,'#2a0d0d');
  rc(g,9,10,6,1,'#5f8a3a'); px(g,10,10,'#eae0c0'); px(g,13,10,'#eae0c0');
  rc(g,8,4,8,3,'#3f2350'); rc(g,9,3,6,2,'#59346f'); // headwrap
  rc(g,18,2,1,16,'#6b4a2e'); rc(g,17,1,3,3,'#8affc0'); px(g,18,2,'#d8ffe8'); // staff glow
 });
}

/* ===================== UNIT DEFS ===================== */
const DEF={
 knight:{n:'罗兰',role:'圣殿骑士',hp:30,atk:9,def:7,mov:4,rng:1,kind:'melee',dmg:'phys'},
 lancer:{n:'莲娜',role:'镇守枪兵',hp:27,atk:10,def:6,mov:4,rng:1,kind:'melee',dmg:'phys'},
 archer:{n:'埃尔温',role:'翠羽弓手',hp:21,atk:8,def:3,mov:4,rng:2,kind:'ranged',dmg:'phys'},
 mage:{n:'米瑞',role:'星炛法师',hp:18,atk:12,def:2,mov:3,rng:2,kind:'ranged',dmg:'magic'},
 cleric:{n:'克莱奥',role:'圣光祭司',hp:22,atk:5,def:4,mov:4,rng:1,heal:12,healRng:2,kind:'melee',dmg:'phys'},
 grunt:{n:'部族战士',role:'',hp:23,atk:8,def:3,mov:4,rng:1,kind:'melee',dmg:'phys'},
 brute:{n:'部族重拳',role:'',hp:36,atk:12,def:5,mov:3,rng:1,kind:'melee',dmg:'phys'},
 goblin:{n:'哥布林射手',role:'',hp:17,atk:8,def:2,mov:4,rng:2,kind:'ranged',dmg:'phys'},
 shaman:{n:'部族巫师',role:'',hp:19,atk:9,def:2,mov:4,rng:2,kind:'ranged',dmg:'magic'}
};
let units=[], uid=0;
function mk(type,side,x,y){const d=DEF[type];return {id:uid++,type,side,x,y,cx:x,cy:y,hp:d.hp,max:d.hp,disp:d.hp,def:d,moved:false,acted:false,dead:false,bob:Math.random()*6,flash:-9,lunge:null,deathAt:-9,fx:0,fy:0};}
function spawn(type,side,x,y){const u=mk(type,side,x,y);units.push(u);return u;}
function newGame(){
 uid=0;units=[];
 spawn('knight','ally',3,8);spawn('lancer','ally',4,8);
 spawn('archer','ally',2,9);spawn('mage','ally',3,9);spawn('cleric','ally',4,9);
 spawn('grunt','foe',10,1);spawn('grunt','foe',11,2);spawn('brute','foe',12,1);
 spawn('goblin','foe',10,0);spawn('shaman','foe',12,2);
 turn=1;phase='ally';sel=null;reach={};atkset={};healset={};busy=false;anim=null;
 particles=[];floaters=[];projectiles=[];shake=0;over=false;
 log=[];pushLog('部族入侵了黛金谷。守住桥口，击退他们！');
 setPhaseBanner('我方回合');
 updateUI();
}
const unitAt=(x,y)=>units.find(u=>!u.dead&&u.x===x&&u.y===y);

/* ===================== PATHFINDING (Dijkstra) ===================== */
function reachable(u){
 // returns {key:{cost,px,py}} tiles unit can stop on (empty), plus path reconstruction
 const dist={},prev={},best={};
 const K=(x,y)=>x+','+y;
 const pq=[[0,u.x,u.y]]; dist[K(u.x,u.y)]=0;
 while(pq.length){
  pq.sort((a,b)=>a[0]-b[0]); const [c,x,y]=pq.shift();
  if(c>dist[K(x,y)])continue;
  for(const[dx,dy]of[[1,0],[-1,0],[0,1],[0,-1]]){
   const nx=x+dx,ny=y+dy; if(!inb(nx,ny))continue;
   const t=terr(nx,ny); if(t.block)continue;
   const occ=unitAt(nx,ny); if(occ&&occ.side!==u.side)continue; // enemies block passage
   const nc=c+t.cost; if(nc>u.def.mov)continue;
   if(dist[K(nx,ny)]===undefined||nc<dist[K(nx,ny)]){dist[K(nx,ny)]=nc;prev[K(nx,ny)]=K(x,y);pq.push([nc,nx,ny]);}
  }
 }
 const res={};
 for(const k in dist){const[x,y]=k.split(',').map(Number);const occ=unitAt(x,y);
  if(occ&&occ.id!==u.id)continue; res[k]={cost:dist[k],x,y};}
 res._prev=prev; res._src=K(u.x,u.y);
 return res;
}
function pathTo(reach,x,y){
 const K=(x,y)=>x+','+y; let cur=K(x,y);const p=[];
 if(reach[cur]===undefined)return null;
 while(cur&&cur!==reach._src){const[cx,cy]=cur.split(',').map(Number);p.unshift({x:cx,y:cy});cur=reach._prev[cur];}
 return p;
}
function tilesInRange(x,y,rng){const a=[];for(let dy=-rng;dy<=rng;dy++)for(let dx=-rng;dx<=rng;dx++){const d=Math.abs(dx)+Math.abs(dy);if(d>=1&&d<=rng){const nx=x+dx,ny=y+dy;if(inb(nx,ny))a.push([nx,ny]);}}return a;}

/* ===================== COMBAT ===================== */
function calcDmg(atk,def){
 const tb=terr(def.x,def.y).def;
 let base=atk.def.atk+ri(0,2)-(def.def.def+tb);
 base=Math.max(1,base);
 const crit=Math.random()<0.12;
 if(crit)base=Math.round(base*1.6);
 return {dmg:base,crit};
}
function faceDir(a,b){const dx=b.x-a.x,dy=b.y-a.y;return Math.abs(dx)>Math.abs(dy)?[Math.sign(dx),0]:[0,Math.sign(dy)];}

function wait(ms){return new Promise(r=>timers.push({at:clock+ms,r}));}
let timers=[];

async function strike(a,d){ // a attacks d (a already adjacent/in range)
 const dir=faceDir(a,d);
 // dodge?
 const dodge=Math.random()<(terr(d.x,d.y).avoid/100);
 a.lunge={dx:dir[0],dy:dir[1],at:clock,dur:a.def.kind==='ranged'?0:220};
 if(a.def.kind==='ranged'){
  spawnProjectile(a,d); await wait(260);
 }else{ await wait(150); }
 // impact
 if(dodge){
  floater(d,'闪避','#cfe8ff'); sparks(d,'#cfe8ff',8);
 }else{
  const {dmg,crit}=calcDmg(a,d);
  d.hp=Math.max(0,d.hp-dmg); d.flash=clock; shake=crit?7:4.5;
  hitFx(a,d,crit); floater(d,(crit?'':'')+dmg,crit?'#ffd75e':'#ff6a5a',crit);
  if(crit)floater(d,'暴击!','#ffd75e',true,-16);
  pushLog(`${a.def.n} → ${d.def.n}，造成 ${dmg} 伤害${crit?'（暴击）':''}。`);
 }
 a.lunge=null;
 await wait(300);
 if(d.hp<=0){ die(d); await wait(260); }
}
async function heal(a,d){
 a.lunge={dx:0,dy:-1,at:clock,dur:200}; await wait(160);
 const amt=Math.min(d.max-d.hp,a.def.heal); d.hp+=amt;
 healFx(d); floater(d,'+'+amt,'#7be6a0'); pushLog(`${a.def.n} 为 ${d.def.n} 恢复 ${amt} 生命。`);
 a.lunge=null; await wait(340);
}
function die(u){u.dead=true;u.deathAt=clock;puff(u);pushLog(`${u.def.n} 倒下了。`);shake=Math.max(shake,5);}

/* ===================== EFFECTS ===================== */
let particles=[],floaters=[],projectiles=[],shake=0;
function cxpx(u){return (u.cx+0.5)*T;} function cypx(u){return (u.cy+0.5)*T;}
function sparks(u,col,n){for(let i=0;i<n;i++){const a=rnd(0,Math.PI*2),s=rnd(0.5,2.6);particles.push({x:cxpx(u),y:cypx(u)-4,vx:Math.cos(a)*s,vy:Math.sin(a)*s-1,life:0,max:rnd(300,600),col,sz:ri(1,2),g:0.06});}}
function hitFx(a,d,crit){
 const col=a.def.dmg==='magic'?'#c79bff':'#fff2c8';
 if(a.def.dmg==='magic'){ for(let i=0;i<18;i++){const ang=rnd(0,Math.PI*2),s=rnd(1,3.4);particles.push({x:cxpx(d),y:cypx(d)-4,vx:Math.cos(ang)*s,vy:Math.sin(ang)*s,life:0,max:rnd(360,680),col:i%2?'#c79bff':'#7fd8ff',sz:ri(1,3),g:0.01});} ring(d,'#b48ce6'); }
 else { const dir=faceDir(a,d); for(let i=0;i<12;i++){const s=rnd(1,3);particles.push({x:cxpx(d)-dir[0]*4,y:cypx(d)-6,vx:dir[0]*rnd(1,3)+rnd(-1,1),vy:rnd(-2.4,0.4),life:0,max:rnd(260,520),col:i%3?'#ffd9a0':'#ff8a5a',sz:ri(1,2),g:0.12});} slash(d,dir); }
 if(crit)ring(d,'#ffd75e');
}
function healFx(u){for(let i=0;i<16;i++){particles.push({x:cxpx(u)+rnd(-7,7),y:cypx(u)+rnd(0,8),vx:rnd(-0.3,0.3),vy:rnd(-1.6,-0.7),life:0,max:rnd(500,900),col:i%2?'#8ff0b0':'#eaffef',sz:ri(1,2),g:-0.006});}ring(u,'#5fbf7a');}
function puff(u){for(let i=0;i<22;i++){const a=rnd(0,Math.PI*2),s=rnd(0.4,2.6);particles.push({x:cxpx(u),y:cypx(u)-4,vx:Math.cos(a)*s,vy:Math.sin(a)*s-0.6,life:0,max:rnd(400,820),col:i%3===0?(u.side==='foe'?'#8fbf5a':'#8fb0e0'):'#6a5f7e',sz:ri(1,3),g:0.05});}}
function ring(u,col){particles.push({ring:true,x:cxpx(u),y:cypx(u)-3,r:2,life:0,max:340,col});}
function slash(u,dir){particles.push({slash:true,x:cxpx(u),y:cypx(u)-4,dir,life:0,max:200,col:'#ffffff'});}
function floater(u,text,col,big,off){floaters.push({x:cxpx(u),y:cypx(u)-14+(off||0),text:text+'',col,big:!!big,at:clock});}
function spawnProjectile(a,d){const type=a.def.dmg==='magic'?'orb':'arrow';projectiles.push({x0:cxpx(a),y0:cypx(a)-4,x1:cxpx(d),y1:cypx(d)-4,at:clock,dur:230,type,ang:Math.atan2(cypx(d)-cypx(a),cxpx(d)-cxpx(a))});}

/* ===================== TERRAIN RENDER (static offscreen) ===================== */
const mapC=document.createElement('canvas');mapC.width=COLS*T;mapC.height=ROWS*T;
function drawTerrain(){
 const g=mapC.getContext('2d');g.imageSmoothingEnabled=false;
 for(let y=0;y<ROWS;y++)for(let x=0;x<COLS;x++){
  const ch=MAP[y][x],ox=x*T,oy=y*T,rng=mulberry(x*131+y*977+7);
  if(ch==='W'){ base(g,ox,oy,'#3f74c4');
   for(let i=0;i<T;i+=4){for(let j=0;j<T;j+=2){if(rng()<0.5){g.fillStyle=rng()<0.5?'#356 0a8'.replace(' ',''):'#4a80cf';g.fillRect(ox+i,oy+j,2,1);}}}
  } else if(ch==='M'){ base(g,ox,oy,'#7f8590');
   g.fillStyle='#9aa0ab';for(let i=0;i<40;i++){const px_=ox+ri(0,31),py=oy+ri(0,31);g.fillRect(px_,py,ri(1,3),ri(1,2));}
   g.fillStyle='#63687340'.slice(0,7);for(let i=0;i<30;i++){g.fillRect(ox+ri(0,31),oy+ri(0,31),1,1);}
   // peak
   g.fillStyle='#6b7079';g.beginPath();g.moveTo(ox+16,oy+6);g.lineTo(ox+26,oy+26);g.lineTo(ox+6,oy+26);g.closePath();g.fill();
   g.fillStyle='#eef3f8';g.beginPath();g.moveTo(ox+16,oy+6);g.lineTo(ox+20,oy+13);g.lineTo(ox+12,oy+13);g.closePath();g.fill();
  } else {
   base(g,ox,oy,'#5aa251'); // grass base for G/F/R
   for(let i=0;i<26;i++){const px_=ox+ri(0,31),py=oy+ri(0,31);g.fillStyle=rng()<0.5?'#69b25c':'#4f9048';g.fillRect(px_,py,1,1);}
   if(rng()<0.4){g.fillStyle=rng()<0.5?'#e8d24a':'#e56aa0';g.fillRect(ox+ri(3,28),oy+ri(3,28),1,1);}
   if(ch==='R'){ base(g,ox,oy,'#c2a878');
    g.fillStyle='#b09562';for(let i=0;i<22;i++)g.fillRect(ox+ri(0,31),oy+ri(0,31),ri(1,2),1);
    g.fillStyle='#a2895580'.slice(0,7);for(let i=0;i<T;i+=8)g.fillRect(ox,oy+i,T,1);
   }
   if(ch==='F'){ // tree
    g.fillStyle='#6b4a2e';g.fillRect(ox+15,oy+18,3,8);
    for(const[tx,ty,r,c]of[[16,12,9,'#357a3b'],[16,10,7,'#3f8b45'],[13,9,4,'#57a85a'],[19,13,4,'#2c6b34']]){g.fillStyle=c;g.beginPath();g.arc(ox+tx,oy+ty,r,0,7);g.fill();}
   }
  }
 }
 // grid lines
 g.strokeStyle='rgba(0,0,0,0.13)';g.lineWidth=1;
 for(let x=0;x<=COLS;x++){g.beginPath();g.moveTo(x*T+.5,0);g.lineTo(x*T+.5,ROWS*T);g.stroke();}
 for(let y=0;y<=ROWS;y++){g.beginPath();g.moveTo(0,y*T+.5);g.lineTo(COLS*T,y*T+.5);g.stroke();}
}
function base(g,ox,oy,c){g.fillStyle=c;g.fillRect(ox,oy,T,T);}

/* ===================== GAME STATE ===================== */
let turn=1,phase='ally',sel=null,reach={},atkset={},healset={},busy=false,anim=null,over=false;
let log=[],hover=null;
function pushLog(s){log.push(s);if(log.length>30)log.shift();const el=document.getElementById('log');el.innerHTML=log.slice(-8).map(l=>`<div class="l">${l}</div>`).join('');el.scrollTop=el.scrollHeight;}

/* ===================== INPUT ===================== */
function toTile(ev){const r=cv.getBoundingClientRect();const x=(ev.clientX-r.left)/r.width*COLS;const y=(ev.clientY-r.top)/r.height*ROWS;return {x:Math.floor(x),y:Math.floor(y)};}
cv.addEventListener('mousemove',e=>{const t=toTile(e);hover=inb(t.x,t.y)?t:null;});
cv.addEventListener('mouseleave',()=>hover=null);
cv.addEventListener('click',async e=>{
 if(busy||over||phase!=='ally')return;
 const {x,y}=toTile(e); if(!inb(x,y))return;
 const u=unitAt(x,y);
 const K=x+','+y;
 if(sel){
  // attack target?
  if(atkset[K]&&u&&u.side==='foe'){ await doMoveAttack(sel,u); return; }
  if(healset[K]&&u&&u.side==='ally'&&u!==sel){ await doMoveHeal(sel,u); return; }
  if(reach[K]&&(!u||u===sel)){ await moveOnly(sel,x,y); return; }
  // clicked another own unit -> switch
  if(u&&u.side==='ally'&&!u.acted){ select(u); return; }
  clearSel(); return;
 }
 if(u&&u.side==='ally'&&!u.acted){ select(u); }
});
document.getElementById('endBtn').onclick=()=>{ if(!busy&&!over&&phase==='ally')endTurn(); };
document.getElementById('waitBtn').onclick=()=>{ if(sel&&!busy){ sel.acted=true; sel.moved=true; clearSel(); checkTurnEnd(); } };
document.getElementById('ovBtn').onclick=()=>{ document.getElementById('overlay').style.display='none'; newGame(); };
// right-click / Esc cancels a not-yet-moved selection; Enter ends the turn
cv.addEventListener('contextmenu',e=>{ e.preventDefault(); if(!busy&&!over&&sel&&!sel.moved)clearSel(); });
window.addEventListener('keydown',e=>{ if(busy||over)return; if(e.key==='Escape'){ if(sel&&!sel.moved)clearSel(); } else if(e.key==='Enter'&&phase==='ally'){ endTurn(); } });

function select(u){
 sel=u;
 if(u.moved){ reach={}; computeThreatFrom(u,u.x,u.y); } // already moved: act only, no second move
 else { reach=reachable(u); computeThreat(u); }
 updateUI();
}
function computeThreat(u){
 atkset={};healset={};
 for(const k in reach){ if(k[0]==='_')continue; const [x,y]=k.split(',').map(Number);
  // from this stand tile, what can be hit
  for(const[tx,ty]of tilesInRange(x,y,u.def.rng)){ const tgt=unitAt(tx,ty); if(tgt&&tgt.side==='foe')atkset[tx+','+ty]=true; }
  if(u.def.heal)for(const[tx,ty]of tilesInRange(x,y,u.def.healRng)){ const tgt=unitAt(tx,ty); if(tgt&&tgt.side==='ally'&&tgt!==u&&tgt.hp<tgt.max)healset[tx+','+ty]=true; }
 }
}
function computeThreatFrom(u,x,y){ // attack/heal targets from a single tile (post-move)
 atkset={};healset={};
 for(const[tx,ty]of tilesInRange(x,y,u.def.rng)){ const t=unitAt(tx,ty); if(t&&t.side==='foe')atkset[tx+','+ty]=true; }
 if(u.def.heal)for(const[tx,ty]of tilesInRange(x,y,u.def.healRng)){ const t=unitAt(tx,ty); if(t&&t.side==='ally'&&t!==u&&t.hp<t.max)healset[tx+','+ty]=true; }
}
function clearSel(){sel=null;reach={};atkset={};healset={};updateUI();}

function bestStand(u,tx,ty,rng){ // reachable tile within rng of (tx,ty), min cost
 let best=null,bc=1e9;
 // current tile is always a candidate — covers units that already moved (reach cleared)
 if(Math.abs(u.x-tx)+Math.abs(u.y-ty)<=rng){best={x:u.x,y:u.y};bc=0;}
 for(const k in reach){ if(k[0]==='_')continue; const[x,y]=k.split(',').map(Number);
  if(Math.abs(x-tx)+Math.abs(y-ty)<=rng){ if(reach[k].cost<bc){bc=reach[k].cost;best={x,y};} } }
 return best;
}
async function animMove(u,x,y){
 const path=pathTo(reach,x,y); if(!path||!path.length){u.x=x;u.y=y;u.cx=x;u.cy=y;return;}
 busy=true;
 for(const step of path){ u.anim={fx:u.cx,fy:u.cy,tx:step.x,ty:step.y,at:clock,dur:110}; await wait(110); u.cx=step.x;u.cy=step.y;u.anim=null; }
 u.x=x;u.y=y;u.cx=x;u.cy=y;
}
async function moveOnly(u,x,y){ busy=true;clearHi(); await animMove(u,x,y); u.moved=true;
 reach={}; computeThreatFrom(u,x,y); busy=false; // moved: can only act from here, no second move
 if(Object.keys(atkset).length||Object.keys(healset).length){ updateUI('选择目标攻击/治疗，或“原地待命”。'); }
 else { u.acted=true; clearSel(); checkTurnEnd(); }
}
async function doMoveAttack(u,tgt){
 const st=bestStand(u,tgt.x,tgt.y,u.def.rng); if(!st)return; busy=true;clearHi();
 await animMove(u,st.x,st.y);
 await strike(u,tgt);
 if(!tgt.dead){ const dist=Math.abs(u.x-tgt.x)+Math.abs(u.y-tgt.y); if(dist<=tgt.def.rng&&!u.dead){ await strike(tgt,u); } }
 u.acted=true;u.moved=true;busy=false;clearSel();
 if(!checkWin())checkTurnEnd();
}
async function doMoveHeal(u,tgt){
 const st=bestStand(u,tgt.x,tgt.y,u.def.healRng); if(!st)return; busy=true;clearHi();
 await animMove(u,st.x,st.y); await heal(u,tgt);
 u.acted=true;u.moved=true;busy=false;clearSel();checkTurnEnd();
}
function clearHi(){reach={};atkset={};healset={};}

/* ===================== TURN FLOW ===================== */
function checkTurnEnd(){ if(phase==='ally'&&units.filter(u=>u.side==='ally'&&!u.dead).every(u=>u.acted)){ endTurn(); } }
async function endTurn(){
 if(phase==='ally'){ phase='foe'; setPhaseBanner('敌方回合'); updateUI(); await wait(700); await enemyTurn(); if(over)return;
  units.forEach(u=>{if(u.side==='foe'){u.acted=false;u.moved=false;}}); phase='ally'; turn++; units.forEach(u=>{if(u.side==='ally'){u.acted=false;u.moved=false;}}); setPhaseBanner('我方回合'); updateUI();
 }
}
function distField(){ // multi-source dijkstra from ally tiles (approach routing for AI)
 const D={},K=(x,y)=>x+','+y,pq=[];
 units.filter(u=>u.side==='ally'&&!u.dead).forEach(u=>{D[K(u.x,u.y)]=0;pq.push([0,u.x,u.y]);});
 while(pq.length){pq.sort((a,b)=>a[0]-b[0]);const[c,x,y]=pq.shift();if(c>D[K(x,y)])continue;
  for(const[dx,dy]of[[1,0],[-1,0],[0,1],[0,-1]]){const nx=x+dx,ny=y+dy;if(!inb(nx,ny))continue;const t=terr(nx,ny);if(t.block)continue;const occ=unitAt(nx,ny);if(occ&&occ.side==='foe')continue;const nc=c+t.cost;if(D[K(nx,ny)]===undefined||nc<D[K(nx,ny)]){D[K(nx,ny)]=nc;pq.push([nc,nx,ny]);}}}
 return D;
}
async function enemyTurn(){
 const foes=units.filter(u=>u.side==='foe'&&!u.dead);
 for(const e of foes){ if(e.dead)continue; await wait(220);
  const rc_=reachable(e); const cands=[];
  for(const k in rc_){if(k[0]==='_')continue;const[x,y]=k.split(',').map(Number);cands.push({x,y,cost:rc_[k].cost});}
  cands.push({x:e.x,y:e.y,cost:0});
  // find attack option
  let bestAtk=null;
  for(const c of cands){ for(const[tx,ty]of tilesInRange(c.x,c.y,e.def.rng)){ const t=unitAt(tx,ty); if(t&&t.side==='ally'){
    const proj=Math.max(1,e.def.atk-(t.def.def+terr(t.x,t.y).def)); const kill=proj>=t.hp;
    const score=(kill?1000:0)+proj*4-(t.hp)-c.cost*0.1 + (t.def.def<4?5:0);
    if(!bestAtk||score>bestAtk.score)bestAtk={score,stand:c,tgt:t};
  }}}
  sel=e; // for path reconstruction via reach
  reach=rc_;
  if(bestAtk){ if(bestAtk.stand.x!==e.x||bestAtk.stand.y!==e.y)await animMove(e,bestAtk.stand.x,bestAtk.stand.y);
   await strike(e,bestAtk.tgt);
   if(!bestAtk.tgt.dead){const d=Math.abs(e.x-bestAtk.tgt.x)+Math.abs(e.y-bestAtk.tgt.y);if(d<=bestAtk.tgt.def.rng&&!e.dead)await strike(bestAtk.tgt,e);}
  } else { // approach
   const D=distField();let best=null,bv=1e9;
   for(const c of cands){const v=D[c.x+','+c.y];if(v!==undefined&&v<bv){bv=v;best=c;}else if(v===bv&&best&&c.cost<best.cost)best=c;}
   if(best&&(best.x!==e.x||best.y!==e.y))await animMove(e,best.x,best.y);
  }
  sel=null;reach={};
  if(checkWin())return;
 }
}
function checkWin(){
 const allies=units.filter(u=>u.side==='ally'&&!u.dead);
 const foes=units.filter(u=>u.side==='foe'&&!u.dead);
 if(foes.length===0){ endGame(true); return true; }
 if(allies.length===0){ endGame(false); return true; }
 return false;
}
function endGame(win){ over=true;busy=false; const o=document.getElementById('overlay');
 document.getElementById('ovT').textContent=win?'胜 利':'战 败';
 document.getElementById('ovT').style.color=win?'#e3b34a':'#d75c5c';
 document.getElementById('ovP').textContent=win?'部族被逐出黛金谷。黛金谷安宁了。':'防线崩溃了……再试一次吧。';
 o.style.display='flex';
}
let bannerTimer=null;
function setPhaseBanner(txt){ const b=document.getElementById('banner');b.querySelector('.b').textContent=txt;
 b.querySelector('.b').style.color=txt.includes('我方')?'#8fb6f0':'#f0a08f';
 b.classList.add('show'); clearTimeout(bannerTimer); bannerTimer=setTimeout(()=>b.classList.remove('show'),1100);
}

/* ===================== UI PANEL ===================== */
const pC=document.createElement('canvas');pC.width=SZ;pC.height=SZ;
function updateUI(hint){
 document.getElementById('turnNo').textContent=turn;
 const chip=document.getElementById('phaseChip');chip.textContent=phase==='ally'?'我方回合':'敌方回合';chip.style.color=phase==='ally'?'#8fb6f0':'#f0a08f';
 if(hint)document.getElementById('hint').textContent=hint;
 else document.getElementById('hint').textContent= sel?'蓝格移动 · 红格攻击 · 点自己原地待命':'点击我方单位选中。存活单位：'+units.filter(u=>u.side==='ally'&&!u.dead).length+' · 敌人：'+units.filter(u=>u.side==='foe'&&!u.dead).length;
 const b=document.getElementById('unitBody');
 const u=sel|| (hover&&unitAt(hover.x,hover.y));
 if(!u){b.innerHTML='<div class="empty">鼠标悬停或选中单位查看详情</div>';return;}
 const pg=pC.getContext('2d');pg.clearRect(0,0,SZ,SZ);pg.imageSmoothingEnabled=false;pg.drawImage(SPR[u.type],0,0);
 const port=pC.toDataURL();
 const hpPct=Math.max(0,u.hp/u.max*100);
 const col=u.side==='ally'?'linear-gradient(90deg,#5fbf7a,#8fe0a0)':'linear-gradient(90deg,#d75c5c,#e88)';
 const tb=terr(u.x,u.y);
 b.innerHTML=`<div class="unitHead"><img id="portrait" src="${port}"><div><div class="uname">${u.def.n}</div><div class="urole">${u.def.role||(u.side==='foe'?'敌 · 部族':'')} · ${u.def.kind==='ranged'?'远程':'近战'}${u.def.dmg==='magic'?'·魔法':''}</div>`+
  `<div class="hpwrap"><div class="hpbar"><div class="hpfill" style="width:${hpPct}%;background:${col}"></div></div><div class="hptext"><span>HP</span><span>${u.hp}/${u.max}</span></div></div></div></div>`+
  `<div class="stats"><div class="stat"><span>攻击 ATK</span><b>${u.def.atk}</b></div><div class="stat"><span>防御 DEF</span><b>${u.def.def}</b></div>`+
  `<div class="stat"><span>移动 MOV</span><b>${u.def.mov}</b></div><div class="stat"><span>射程 RNG</span><b>${u.def.rng}${u.def.heal?' · 治'+u.def.heal:''}</b></div>`+
  `<div class="stat" style="grid-column:1/3"><span>地形 ${tb.name}</span><b>防+${tb.def} · 闪避 ${tb.avoid}%</b></div></div>`;
}

/* ===================== RENDER LOOP ===================== */
let clock=0,last=performance.now();
function upos(u){ if(u.anim){const t=clamp((clock-u.anim.at)/u.anim.dur,0,1);return {x:u.anim.fx+(u.anim.tx-u.anim.fx)*t,y:u.anim.fy+(u.anim.ty-u.anim.fy)*t};} return {x:u.cx,y:u.cy};}
function render(){
 ctx.clearRect(0,0,COLS*T,ROWS*T);
 let sx=0,sy=0; if(shake>0.2){sx=rnd(-shake,shake);sy=rnd(-shake,shake);}
 ctx.save();ctx.translate(sx,sy);
 ctx.drawImage(mapC,0,0);
 // water shimmer
 for(let y=0;y<ROWS;y++)for(let x=0;x<COLS;x++)if(MAP[y][x]==='W'){
  const ph=(clock/500+x*0.7+y*0.9);
  ctx.fillStyle='rgba(255,255,255,0.10)';
  for(let i=0;i<3;i++){const yy=y*T+((i*10+ (Math.sin(ph+i)*4+6))%T);ctx.fillRect(x*T+2,y*T+((yy)%T),T-4,1);}
 }
 // range overlays
 drawOverlay(reach,'rgba(70,130,220,0.42)','rgba(120,170,240,0.9)');
 drawSet(healset,'rgba(70,200,120,0.4)','rgba(120,230,160,0.9)');
 drawSet(atkset,'rgba(220,70,70,0.42)','rgba(240,120,120,0.95)');
 // hover
 if(hover&&!over){ctx.strokeStyle='rgba(255,255,255,0.85)';ctx.lineWidth=1.4;ctx.strokeRect(hover.x*T+1,hover.y*T+1,T-2,T-2);}
 // selected pulse ring under unit
 if(sel){const p=upos(sel);const pr=3+Math.sin(clock/180)*1.5;ctx.strokeStyle='rgba(227,179,74,0.9)';ctx.lineWidth=2;ctx.beginPath();ctx.ellipse((p.x+0.5)*T,(p.y+0.9)*T,10+pr,5+pr*0.5,0,0,7);ctx.stroke();}
 // units sorted by y
 const us=units.filter(u=>!u.dead||clock-u.deathAt<420).sort((a,b)=>(a.cy-b.cy)||(a.id-b.id));
 for(const u of us)drawUnit(u);
 // projectiles
 for(const p of projectiles){const t=clamp((clock-p.at)/p.dur,0,1);const x=p.x0+(p.x1-p.x0)*t,y=p.y0+(p.y1-p.y0)*t-Math.sin(t*Math.PI)*6;
  if(p.type==='arrow'){ctx.save();ctx.translate(x,y);ctx.rotate(p.ang);ctx.fillStyle='#d8c48a';ctx.fillRect(-5,-0.5,10,1.4);ctx.fillStyle='#e56458';ctx.fillRect(4,-1,2,2);ctx.restore();}
  else{ctx.fillStyle='#c79bff';ctx.beginPath();ctx.arc(x,y,3.2,0,7);ctx.fill();ctx.fillStyle='#eadcff';ctx.beginPath();ctx.arc(x,y,1.4,0,7);ctx.fill();}
 }
 // particles
 for(const p of particles){const a=1-p.life/p.max;
  if(p.ring){const rr=p.r+ (p.life/p.max)*13;ctx.strokeStyle=p.col;ctx.globalAlpha=a*0.9;ctx.lineWidth=1.6;ctx.beginPath();ctx.arc(p.x,p.y,rr,0,7);ctx.stroke();ctx.globalAlpha=1;}
  else if(p.slash){const t=p.life/p.max;ctx.save();ctx.globalAlpha=(1-t)*0.9;ctx.strokeStyle='#ffffff';ctx.lineWidth=2.2;ctx.beginPath();ctx.arc(p.x+p.dir[0]*4,p.y,10,-1+t*2.4,0.6+t*2.4);ctx.stroke();ctx.restore();ctx.globalAlpha=1;}
  else{ctx.globalAlpha=Math.max(0,a);ctx.fillStyle=p.col;ctx.fillRect(p.x-p.sz/2,p.y-p.sz/2,p.sz,p.sz);ctx.globalAlpha=1;}
 }
 // floaters
 for(const f of floaters){const t=(clock-f.at)/900;const y=f.y-t*22;ctx.globalAlpha=clamp(1-t,0,1);
  ctx.font=(f.big?'bold 11px':'bold 9px')+' "Trebuchet MS",sans-serif';ctx.textAlign='center';
  ctx.lineWidth=3;ctx.strokeStyle='rgba(0,0,0,0.7)';ctx.strokeText(f.text,f.x,y);ctx.fillStyle=f.col;ctx.fillText(f.text,f.x,y);ctx.globalAlpha=1;}
 ctx.restore();
}
function drawOverlay(set,fill,stroke){for(const k in set){if(k[0]==='_')continue;const[x,y]=k.split(',').map(Number);ctx.fillStyle=fill;ctx.fillRect(x*T+2,y*T+2,T-4,T-4);ctx.strokeStyle=stroke;ctx.lineWidth=1;ctx.strokeRect(x*T+2.5,y*T+2.5,T-5,T-5);}}
function drawSet(set,fill,stroke){for(const k in set){const[x,y]=k.split(',').map(Number);ctx.fillStyle=fill;ctx.fillRect(x*T+2,y*T+2,T-4,T-4);ctx.strokeStyle=stroke;ctx.lineWidth=1.2;ctx.strokeRect(x*T+2.5,y*T+2.5,T-5,T-5);}}
function drawUnit(u){
 const p=upos(u);const bob=u.anim?0:Math.sin(clock/300+u.bob)*1.1;
 let lx=0,ly=0; if(u.lunge){const t=clamp((clock-u.lunge.at)/u.lunge.dur,0,1);const k=Math.sin(t*Math.PI);lx=u.lunge.dx*4*k;ly=u.lunge.dy*4*k;}
 const dead=u.dead; const da=dead?clamp(1-(clock-u.deathAt)/420,0,1):1;
 const bx=p.x*T+(T-SZ)/2+lx, by=p.y*T+(T-SZ)/2-6+bob+ly;
 // shadow
 ctx.globalAlpha=0.28*da;ctx.fillStyle='#000';ctx.beginPath();ctx.ellipse((p.x+0.5)*T,(p.y+0.92)*T,9,4,0,0,7);ctx.fill();ctx.globalAlpha=1;
 // team ground disc
 if(!dead){ctx.globalAlpha=0.9;ctx.strokeStyle=u.side==='ally'?'rgba(91,141,217,0.8)':'rgba(215,92,92,0.8)';ctx.lineWidth=1.4;ctx.beginPath();ctx.ellipse((p.x+0.5)*T,(p.y+0.9)*T,8,3.5,0,0,7);ctx.stroke();ctx.globalAlpha=1;}
 ctx.globalAlpha=da;
 if(dead){ctx.save();ctx.globalAlpha=da;ctx.translate((p.x+0.5)*T,by+SZ/2);ctx.scale(1,1);ctx.drawImage(SPR[u.type],-SZ/2,-SZ/2);ctx.restore();ctx.globalAlpha=1;return;}
 ctx.drawImage(SPR[u.type],Math.round(bx),Math.round(by));
 // flash
 if(clock-u.flash<160){ctx.globalAlpha=(1-(clock-u.flash)/160)*0.85;ctx.globalCompositeOperation='lighter';ctx.drawImage(tintWhite(u.type),Math.round(bx),Math.round(by));ctx.globalCompositeOperation='source-over';ctx.globalAlpha=1;}
 // acted dim
 if(u.acted&&u.side==='ally'){ctx.globalAlpha=0.4;ctx.fillStyle='#2a3550';ctx.globalCompositeOperation='multiply';ctx.fillRect(Math.round(bx)+6,Math.round(by)+4,SZ-12,SZ-6);ctx.globalCompositeOperation='source-over';ctx.globalAlpha=1;}
 // HP bar
 u.disp+=(u.hp-u.disp)*0.2;
 const bw=20,bhx=(p.x+0.5)*T-bw/2,bhy=p.y*T+1;
 ctx.fillStyle='rgba(0,0,0,0.65)';ctx.fillRect(bhx-1,bhy-1,bw+2,4.5);
 ctx.fillStyle='#1a1420';ctx.fillRect(bhx,bhy,bw,2.5);
 const pct=clamp(u.disp/u.max,0,1);
 ctx.fillStyle=u.side==='ally'?(pct>0.5?'#5fbf7a':pct>0.25?'#e3b34a':'#d75c5c'):'#d75c5c';
 ctx.fillRect(bhx,bhy,bw*pct,2.5);
 ctx.globalAlpha=1;
}
const tintCache={};
function tintWhite(type){ if(tintCache[type])return tintCache[type]; const c=document.createElement('canvas');c.width=SZ;c.height=SZ;const g=c.getContext('2d');g.drawImage(SPR[type],0,0);g.globalCompositeOperation='source-in';g.fillStyle='#fff';g.fillRect(0,0,SZ,SZ);tintCache[type]=c;return c;}

/* ===================== MAIN LOOP ===================== */
function frame(now){
 const dt=Math.min(50,now-last);last=now;clock+=dt;
 // timers
 for(let i=timers.length-1;i>=0;i--){if(timers[i].at<=clock){timers[i].r();timers.splice(i,1);}}
 // particles
 for(let i=particles.length-1;i>=0;i--){const p=particles[i];p.life+=dt;if(!p.ring&&!p.slash){p.x+=p.vx;p.y+=p.vy;p.vy+=p.g||0;}if(p.life>=p.max)particles.splice(i,1);}
 for(let i=floaters.length-1;i>=0;i--)if(clock-floaters[i].at>900)floaters.splice(i,1);
 for(let i=projectiles.length-1;i>=0;i--)if(clock-projectiles[i].at>projectiles[i].dur)projectiles.splice(i,1);
 shake*=0.86;
 render();
 if(clock%6<dt)updateUI(sel?document.getElementById('hint').textContent:undefined);
 requestAnimationFrame(frame);
}

/* ===================== BOOT ===================== */
buildSprites();drawTerrain();newGame();
requestAnimationFrame(frame);
