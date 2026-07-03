'use strict';
/* ==================== 裂隙远征 · 状态/回合/AI/输入/启动（依赖 rules.js + render.js） ==================== */
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
 else { reach=reachable(u,unitAt); computeThreat(u); }
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
  const rc_=reachable(e,unitAt); const cands=[];
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
function setPhaseBanner(txt){ const b=document.getElementById('banner');const bb=/** @type {HTMLElement} */(b.querySelector('.b'));bb.textContent=txt;
 bb.style.color=txt.includes('我方')?'#8fb6f0':'#f0a08f';
 b.classList.add('show'); clearTimeout(bannerTimer); bannerTimer=setTimeout(()=>b.classList.remove('show'),1100);
}

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
