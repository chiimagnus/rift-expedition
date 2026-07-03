'use strict';
/* ==================== 裂隙远征 · 纯规则/数据层（DOM 无关，可被 node:test 引用） ==================== */
const COLS=14, ROWS=10, T=32, S=3;           // logical tile 32px, render scale 3
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
/* ===================== PATHFINDING (Dijkstra) ===================== */
function reachable(u,occAt){
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
   const occ=occAt(nx,ny); if(occ&&occ.side!==u.side)continue; // enemies block passage
   const nc=c+t.cost; if(nc>u.def.mov)continue;
   if(dist[K(nx,ny)]===undefined||nc<dist[K(nx,ny)]){dist[K(nx,ny)]=nc;prev[K(nx,ny)]=K(x,y);pq.push([nc,nx,ny]);}
  }
 }
 const res={};
 for(const k in dist){const[x,y]=k.split(',').map(Number);const occ=occAt(x,y);
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

/* ponytail: 仅为 node:test 暴露纯逻辑；浏览器端这些符号本就是全局，此赋值无副作用 */
/** @type {any} */(globalThis).RiftRules = { COLS, ROWS, T, S, rnd, ri, clamp, mulberry, MAP, TERR, tileAt, terr, inb, DEF, tilesInRange, faceDir, calcDmg, reachable, pathTo };
