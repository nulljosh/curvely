// CDP walk of the web app: every control, once. Needs Chrome and a served dist/ (python3 -m http.server 4173 -d dist).
// usage: node scripts/qa-web.mjs [base-url]
import { spawn } from 'node:child_process';
const BASE = (process.argv[2] || 'http://localhost:4173') + '/app/';
const chrome = spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', ['--headless=new', '--disable-gpu', '--remote-debugging-port=9333', '--user-data-dir=/tmp/qa-chrome', 'about:blank'], { stdio: 'ignore' });
await new Promise(r => setTimeout(r, 2500));
const tabs = await (await fetch('http://localhost:9333/json')).json();
const ws = new WebSocket(tabs.find(t => t.type === 'page').webSocketDebuggerUrl);
await new Promise(r => ws.onopen = r);
let id = 0; const pend = new Map();
ws.onmessage = m => { const d = JSON.parse(m.data); if (d.id && pend.has(d.id)) { pend.get(d.id)(d); pend.delete(d.id); } };
const send = (method, params = {}) => new Promise(r => { const i = ++id; pend.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
const ev = async (expr) => { const r = await send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true }); if (r.result.exceptionDetails) throw new Error(JSON.stringify(r.result.exceptionDetails.exception?.description)); return r.result.result.value; };
const sleep = ms => new Promise(r => setTimeout(r, ms));
let fails = 0; const ok = (name, cond, extra = '') => { console.log((cond ? 'PASS ' : 'FAIL ') + name + (extra ? '  ' + extra : '')); if (!cond) fails++; };
const type = (i, v) => ev(`(()=>{const el=document.querySelectorAll('.eq-input')[${i}];const set=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value').set;set.call(el,${JSON.stringify(v)});el.dispatchEvent(new Event('input',{bubbles:true}));})()`);
const click = (sel, text) => ev(`(()=>{const b=[...document.querySelectorAll(${JSON.stringify(sel)})].find(b=>!${JSON.stringify(text)}||b.textContent.trim()===${JSON.stringify(text)});b.click();return true})()`);
const count = sel => ev(`document.querySelectorAll(${JSON.stringify(sel)}).length`);
// colored (non-gray) pixels on the canvas = a drawn curve
const curvePx = () => ev(`(()=>{const c=document.querySelector('canvas');const x=c.getContext('2d');const d=x.getImageData(0,0,c.width,c.height).data;let n=0;for(let i=0;i<d.length;i+=4){if(Math.abs(d[i]-d[i+2])>60)n++}return n})()`);

await send('Page.enable'); await send('Page.navigate', { url: BASE }); await sleep(2500);
ok('loads with 2 equations', await count('.eq-input') === 2);
ok('fonts: Curvely Sans loaded', await ev(`document.fonts.check('16px "Curvely Sans"')`));
const base = await curvePx(); ok('curves drawn on canvas', base > 500, 'px=' + base);
await sleep(400); const settled = await curvePx(); // key point dots land after the view settles
await click('.dot-btn'); await sleep(400); const hiddenPx = await curvePx(); ok('dot hides its curve', hiddenPx < settled, `px=${hiddenPx}`);
await click('.dot-btn'); await sleep(400); ok('dot shows it again', await curvePx() === settled);
ok('key points drawn', await ev(`(()=>{const c=document.querySelector('canvas');const d=c.getContext('2d').getImageData(0,0,c.width,c.height).data;let n=0;for(let i=0;i<d.length;i+=4){const g=d[i];if(Math.abs(d[i]-d[i+1])<8&&Math.abs(d[i]-d[i+2])<8&&g>60&&g<200)n++}return n})()`) > 0);
await click('.add-btn'); await sleep(100); ok('add equation -> 3 rows', await count('.eq-input') === 3);
await click('.chip', 'y > x^2'); await sleep(100); ok('quick example chip adds a row', await count('.eq-input') === 4 && await ev(`document.querySelectorAll('.eq-input')[3].value`) === 'y > x^2');
await type(2, 'a=3'); await sleep(200); ok('a=3 makes a slider', await count('input[type=range]') === 1);
const v0 = await ev(`document.querySelector('input[type=range]').value`);
await click('.play-btn'); await sleep(600); const v1 = await ev(`document.querySelector('input[type=range]').value`);
ok('play moves the slider', v1 !== v0, `${v0} -> ${v1}`);
await click('.play-btn'); await sleep(300); const v2 = await ev(`document.querySelector('input[type=range]').value`); await sleep(300);
ok('pause stops it', await ev(`document.querySelector('input[type=range]').value`) === v2);
await type(2, 'x^2+y^2=4'); await sleep(700); ok('implicit circle has no error', await count('.eq-input.bad') === 0);
await type(2, 'sin('); await sleep(900); ok('invalid expression flagged', await count('.eq-input.bad') === 1);
await type(2, '2*x+1'); await sleep(900); ok('fixing it clears the flag', await count('.eq-input.bad') === 0);
const before = await curvePx(); await type(0, '3*x'); await sleep(200); ok('editing redraws', await curvePx() > 0);
await click('.rm-btn'); await sleep(100); ok('remove drops a row', await count('.eq-input') === 3);
const before2 = await count('.eq-input'); await click('.pattern-tab', 'Flowers'); await sleep(100); await click('.chip', 'Seed of life'); await sleep(900);
ok('a pattern adds its rows', await count('.eq-input') === before2 + 3);
ok('pattern rows read cleanly', await count('.eq-input.bad') === 0);
// pan + wheel zoom change the canvas
const snap1 = await ev(`document.querySelector('canvas').toDataURL().length`);
await ev(`document.querySelector('canvas').dispatchEvent(new WheelEvent('wheel',{deltaY:-300,clientX:400,clientY:300,bubbles:true,cancelable:true}))`); await sleep(200);
ok('wheel zoom redraws', await ev(`document.querySelector('canvas').toDataURL().length`) !== snap1);
// glass present
ok('sidebar is glass', await ev(`getComputedStyle(document.querySelector('.sidebar-pane')).backdropFilter.includes('blur')`));
// phone drawer
await send('Emulation.setDeviceMetricsOverride', { width: 390, height: 844, deviceScaleFactor: 2, mobile: true }); await sleep(400);
ok('phone: handle visible', await ev(`getComputedStyle(document.querySelector('.panel-handle')).display`) !== 'none');
await click('.panel-handle'); await sleep(200); ok('phone: handle collapses panel', await ev(`document.querySelector('.sidebar-pane').classList.contains('collapsed')`));
await click('.panel-handle'); await sleep(200); ok('phone: handle reopens', !(await ev(`document.querySelector('.sidebar-pane').classList.contains('collapsed')`)));
ok('phone: no horizontal scroll', await ev(`document.documentElement.scrollWidth <= innerWidth`));
console.log(fails ? `\n${fails} FAILED` : '\nall passed'); chrome.kill(); process.exit(fails ? 1 : 0);
