import { useRef, useEffect, useCallback, useState } from 'react';
import { isAsymptoteJump } from '../utils/evaluate.js';

function graphColors() {
  const dark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  return {
    grid: dark ? 'rgba(232,232,240,0.07)' : 'rgba(37,42,73,0.07)',
    axis: dark ? 'rgba(232,232,240,0.3)' : 'rgba(37,42,73,0.3)',
    label: dark ? 'rgba(232,232,240,0.5)' : 'rgba(37,42,73,0.5)',
    bg: dark ? '#0d0c0b' : '#faf7f4',
  };
}

const MIN_SCALE = 10;
const MAX_SCALE = 400;
const DEFAULT_SCALE = 60;
const clampScale = (s) => Math.min(MAX_SCALE, Math.max(MIN_SCALE, s));

export default function Graph({ equations }) {
  const canvasRef = useRef(null);
  const transform = useRef({ scale: DEFAULT_SCALE, ox: 0, oy: 0 });
  const drag = useRef(null);
  const pinch = useRef(null);
  const lastTap = useRef(0);
  const [zoomPct, setZoomPct] = useState(100);

  const draw = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const W = canvas.offsetWidth;
    const H = canvas.offsetHeight;
    const { scale, ox, oy } = transform.current;
    const cx = W / 2 + ox;
    const cy = H / 2 + oy;

    const colors = graphColors();
    ctx.fillStyle = colors.bg;
    ctx.fillRect(0, 0, W, H);

    // grid
    const step = scale;
    const startX = ((cx % step) - step) % step;
    const startY = ((cy % step) - step) % step;

    ctx.strokeStyle = colors.grid;
    ctx.lineWidth = 1;
    for (let x = startX; x < W; x += step) {
      ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke();
    }
    for (let y = startY; y < H; y += step) {
      ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke();
    }

    // axes
    ctx.strokeStyle = colors.axis;
    ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.moveTo(0, cy); ctx.lineTo(W, cy); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(cx, 0); ctx.lineTo(cx, H); ctx.stroke();

    // axis labels
    ctx.fillStyle = colors.label;
    ctx.font = '11px -apple-system, BlinkMacSystemFont, "Helvetica Neue", Helvetica, system-ui, sans-serif';
    ctx.textAlign = 'center';
    const labelStep = Math.round(Math.max(1, 80 / scale));
    for (let x = startX; x < W; x += step) {
      const val = Math.round((x - cx) / scale / labelStep) * labelStep;
      if (val !== 0) ctx.fillText(val, x, cy + 14);
    }
    ctx.textAlign = 'right';
    for (let y = startY; y < H; y += step) {
      const val = -Math.round((y - cy) / scale / labelStep) * labelStep;
      if (val !== 0) ctx.fillText(val, cx - 6, y + 4);
    }

    // curves
    equations.forEach(({ fn, color }) => {
      if (!fn) return;
      ctx.strokeStyle = color;
      ctx.lineWidth = 2.2;
      ctx.lineJoin = 'round';
      ctx.beginPath();
      let penDown = false;
      let prevY = 0;
      for (let px = 0; px < W; px++) {
        const x = (px - cx) / scale;
        let y;
        try { y = fn(x); } catch { penDown = false; continue; }
        if (!isFinite(y)) { penDown = false; continue; }
        const py = cy - y * scale;
        if (penDown && isAsymptoteJump(prevY, y, scale, H)) penDown = false;
        if (!penDown) { ctx.moveTo(px, py); penDown = true; }
        else ctx.lineTo(px, py);
        prevY = y;
      }
      ctx.stroke();
    });
  }, [equations]);

  // resize observer
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const sync = () => {
      canvas.width = canvas.offsetWidth * devicePixelRatio;
      canvas.height = canvas.offsetHeight * devicePixelRatio;
      canvas.style.width = canvas.offsetWidth + 'px';
      canvas.style.height = canvas.offsetHeight + 'px';
      const ctx = canvas.getContext('2d');
      ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);
      draw();
    };
    const ro = new ResizeObserver(sync);
    ro.observe(canvas);
    sync();
    return () => ro.disconnect();
  }, [draw]);

  useEffect(() => { draw(); }, [draw]);

  // graphColors() reads prefers-color-scheme at draw time, but nothing triggered
  // a draw when the system appearance changed -- the graph kept the old
  // background until a pan/zoom/resize happened to force one.
  useEffect(() => {
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    mq.addEventListener('change', draw);
    return () => mq.removeEventListener('change', draw);
  }, [draw]);

  const syncReadout = useCallback(() => {
    setZoomPct(Math.round(transform.current.scale / DEFAULT_SCALE * 100));
  }, []);

  // zoom keeping the graph point under (px,py) fixed on screen
  const zoomAbout = useCallback((factor, px, py) => {
    const t = transform.current;
    const newScale = clampScale(t.scale * factor);
    const ratio = newScale / t.scale;
    if (ratio === 1) return;
    const canvas = canvasRef.current;
    const W = canvas.offsetWidth, H = canvas.offsetHeight;
    const cx = W / 2 + t.ox;
    const cy = H / 2 + t.oy;
    // keep (px,py) anchored: new center offset so the world point stays put
    t.ox = px - W / 2 - (px - cx) * ratio;
    t.oy = py - H / 2 - (py - cy) * ratio;
    t.scale = newScale;
    draw();
    syncReadout();
  }, [draw, syncReadout]);

  const zoomBy = useCallback((factor) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    zoomAbout(factor, canvas.offsetWidth / 2, canvas.offsetHeight / 2);
  }, [zoomAbout]);

  const resetView = useCallback(() => {
    transform.current = { scale: DEFAULT_SCALE, ox: 0, oy: 0 };
    draw();
    syncReadout();
  }, [draw, syncReadout]);

  // scroll zoom about cursor
  const onWheel = useCallback((e) => {
    e.preventDefault();
    const rect = e.currentTarget.getBoundingClientRect();
    const factor = e.deltaY < 0 ? 1.1 : 0.9;
    zoomAbout(factor, e.clientX - rect.left, e.clientY - rect.top);
  }, [zoomAbout]);

  // pan
  const onMouseDown = useCallback((e) => {
    drag.current = { x: e.clientX, y: e.clientY, ox: transform.current.ox, oy: transform.current.oy };
  }, []);
  const onMouseMove = useCallback((e) => {
    if (!drag.current) return;
    transform.current.ox = drag.current.ox + (e.clientX - drag.current.x);
    transform.current.oy = drag.current.oy + (e.clientY - drag.current.y);
    draw();
  }, [draw]);
  const onMouseUp = useCallback(() => { drag.current = null; }, []);

  // touch: single-finger pan, two-finger pinch zoom
  const dist = (a, b) => Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY);

  const onTouchStart = useCallback((e) => {
    if (e.touches.length === 1) {
      const t = e.touches[0];
      drag.current = { x: t.clientX, y: t.clientY, ox: transform.current.ox, oy: transform.current.oy };
      pinch.current = null;
    } else if (e.touches.length === 2) {
      drag.current = null;
      pinch.current = { d: dist(e.touches[0], e.touches[1]) };
    }
  }, []);
  const onTouchMove = useCallback((e) => {
    if (pinch.current && e.touches.length === 2) {
      e.preventDefault();
      const rect = e.currentTarget.getBoundingClientRect();
      const midX = (e.touches[0].clientX + e.touches[1].clientX) / 2 - rect.left;
      const midY = (e.touches[0].clientY + e.touches[1].clientY) / 2 - rect.top;
      const d = dist(e.touches[0], e.touches[1]);
      if (pinch.current.d > 0) zoomAbout(d / pinch.current.d, midX, midY);
      pinch.current.d = d;
    } else if (drag.current && e.touches.length === 1) {
      e.preventDefault();
      const t = e.touches[0];
      transform.current.ox = drag.current.ox + (t.clientX - drag.current.x);
      transform.current.oy = drag.current.oy + (t.clientY - drag.current.y);
      draw();
    }
  }, [draw, zoomAbout]);
  const onTouchEnd = useCallback(() => {
    pinch.current = null;
    drag.current = null;
    const now = Date.now();
    if (now - lastTap.current < 300) { resetView(); lastTap.current = 0; }
    else lastTap.current = now;
  }, [resetView]);

  return (
    <div style={{ position: 'absolute', inset: 0 }}>
      <canvas
        ref={canvasRef}
        style={{ width: '100%', height: '100%', display: 'block', cursor: 'crosshair', touchAction: 'none' }}
        onWheel={onWheel}
        onMouseDown={onMouseDown}
        onMouseMove={onMouseMove}
        onMouseUp={onMouseUp}
        onMouseLeave={onMouseUp}
        onDoubleClick={resetView}
        onTouchStart={onTouchStart}
        onTouchMove={onTouchMove}
        onTouchEnd={onTouchEnd}
      />
      <div className="zoom-cluster">
        <span className="zoom-readout">{zoomPct}%</span>
        <button className="zoom-btn" aria-label="Zoom in" onClick={() => zoomBy(1.3)}>+</button>
        <button className="zoom-btn" aria-label="Zoom out" onClick={() => zoomBy(1 / 1.3)}>&minus;</button>
        <button className="zoom-btn zoom-reset" aria-label="Reset view" onClick={resetView}>&#x2302;</button>
      </div>
    </div>
  );
}
