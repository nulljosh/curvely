import { useState, useCallback, useMemo, useEffect, useRef } from 'react';
import Graph from './components/Graph.jsx';
import EquationList from './components/EquationList.jsx';
import { evaluate, parseSlider, buildScope } from './utils/evaluate.js';
import { colorAt } from './utils/colors.js';
import { parseListDef, expandRow, evaluateRow } from './utils/lists.js';
import { useWebMCP } from './lib/webmcp.js';
import { PATTERNS, PATTERN_CATEGORIES } from './utils/patterns.js';

let nextId = 3;

function makeEq(id, expr = '') {
  return { id, expr, ...evaluateRow(expr), color: colorAt(id - 1) };
}

const INITIAL = [
  makeEq(1, 'x^2'),
  makeEq(2, 'sin(x)'),
];

export default function App() {
  const [equations, setEquations] = useState(INITIAL);
  const [sliderValues, setSliderValues] = useState({});
  const [panelCollapsed, setPanelCollapsed] = useState(false);
  const [patternCategory, setPatternCategory] = useState(PATTERN_CATEGORIES[0]);
  const [playing, setPlaying] = useState({}); // slider name -> true while its play button is on

  // `a = 3` rows drive a slider instead of plotting a curve. Value defaults from
  // the row's own number but a dragged value overrides it until the row is edited.
  const sliders = useMemo(() => equations
    .map((eq) => parseSlider(eq.expr))
    .filter(Boolean)
    .map((s) => ({ ...s, value: sliderValues[s.name] ?? s.value })), [equations, sliderValues]);

  const sliderScope = useMemo(() => buildScope(
    equations.map((eq) => eq.expr),
    Object.fromEntries(sliders.map((s) => [s.name, s.value])),
  ), [equations, sliders]);

  // A row that uses a list draws once per element; each copy binds the list to one value.
  // ponytail: the bound values are spread into the scope per evaluation, fine for lists of a few hundred.
  const curves = useMemo(() => {
    const lists = Object.fromEntries(equations.map((eq) => parseListDef(eq.expr)).filter(Boolean).map((l) => [l.name, l.items]));
    const bind = (c, b) => ({
      ...c,
      fn: c.fn && ((x, s) => c.fn(x, { ...s, ...b })),
      implicitFn: c.implicitFn && ((x, y, s) => c.implicitFn(x, y, { ...s, ...b })),
      paramFn: c.paramFn && ((t, s) => c.paramFn(t, { ...s, ...b })),
      pointFn: c.pointFn && ((s) => c.pointFn({ ...s, ...b })),
    });
    return equations
      .filter((eq) => !eq.hidden && !parseSlider(eq.expr))
      .flatMap((eq) => {
        const { source, binds } = expandRow(eq.expr, lists);
        if (binds.length === 1 && !Object.keys(binds[0]).length) return [eq];
        const compiled = { ...eq, ...evaluate(source) };
        return binds.map((b) => bind(compiled, b));
      });
  }, [equations]);

  // Play sweeps a slider from one end of its range to the other and back.
  const SWEEP_SECONDS = 4;
  const slidersRef = useRef(sliders);
  slidersRef.current = sliders;
  useEffect(() => {
    const names = Object.keys(playing).filter((n) => playing[n]);
    if (!names.length) return undefined;
    const dir = {};
    let last = performance.now();
    let raf = requestAnimationFrame(function tick(now) {
      const dt = Math.min(0.1, (now - last) / 1000);
      last = now;
      setSliderValues((prev) => {
        const next = { ...prev };
        for (const n of names) {
          const s = slidersRef.current.find((x) => x.name === n);
          if (!s) continue;
          let v = (prev[n] ?? s.value) + (dir[n] ?? 1) * (s.max - s.min) * dt / SWEEP_SECONDS;
          if (v >= s.max) { v = s.max; dir[n] = -1; } else if (v <= s.min) { v = s.min; dir[n] = 1; }
          next[n] = v;
        }
        return next;
      });
      raf = requestAnimationFrame(tick);
    });
    return () => cancelAnimationFrame(raf);
  }, [playing]);

  const handleTogglePlay = useCallback((name) => setPlaying((p) => ({ ...p, [name]: !p[name] })), []);

  const handleSliderChange = useCallback((name, value) => {
    setSliderValues((prev) => ({ ...prev, [name]: value }));
  }, []);

  const handleChange = useCallback((id, expr) => {
    setEquations((prev) =>
      prev.map((eq) => eq.id === id ? { ...eq, expr, fn: null, implicitFn: null, paramFn: null, pointFn: null, inequality: null, ...evaluateRow(expr) } : eq)
    );
  }, []);

  const handleToggle = useCallback((id) => {
    setEquations((prev) => prev.map((eq) => eq.id === id ? { ...eq, hidden: !eq.hidden } : eq));
  }, []);

  const handleRemove = useCallback((id) => {
    setEquations((prev) => prev.filter((eq) => eq.id !== id));
  }, []);

  const handleAdd = useCallback((expr = '') => {
    const id = nextId++;
    setEquations((prev) => [...prev, makeEq(id, expr)]);
    return id;
  }, []);

  useWebMCP({
    equations,
    addEquation: handleAdd,
    changeEquation: handleChange,
    removeEquation: handleRemove,
  });

  return (
    <div style={{
      height: '100dvh',
      background: 'var(--bg)',
      display: 'flex',
      flexDirection: 'column',
      fontFamily: 'var(--font)',
      color: 'var(--text)',
      overflow: 'hidden',
    }}>
      <div className="main-layout">
        <div className="graph-pane">
          <Graph equations={curves} sliders={sliderScope} />
        </div>

        <div className={`sidebar-pane glass${panelCollapsed ? ' collapsed' : ''}`}>
          <button
            className="panel-handle"
            aria-label={panelCollapsed ? 'Show equations' : 'Hide equations'}
            aria-expanded={!panelCollapsed}
            onClick={() => setPanelCollapsed((c) => !c)}
          >{panelCollapsed ? '\u25B4' : '\u25BE'}</button>
          <EquationList
            equations={equations}
            sliders={sliders}
            onChange={handleChange}
            onRemove={handleRemove}
            onToggle={handleToggle}
            onAdd={() => handleAdd()}
            onSliderChange={handleSliderChange}
            playing={playing}
            onTogglePlay={handleTogglePlay}
          />

          <div className="glass-card" style={{ marginTop: 12 }}>
            <div className="card-title">Quick examples</div>
            {['x^2', 'sin(x)', 'x^3-x', 'x^2+y^2=4', 'y > x^2', 'r = 1+cos(theta)', '(cos(t), sin(t))', '(1, 2)'].map((ex) => (
              <button key={ex} className="chip" onClick={() => handleAdd(ex)}>{ex}</button>
            ))}
          </div>

          <div className="glass-card" style={{ marginTop: 12 }}>
            <div className="card-title">Patterns</div>
            <div className="pattern-tabs" role="group" aria-label="Pattern categories">
              {PATTERN_CATEGORIES.map((c) => (
                <button key={c} aria-pressed={c === patternCategory} className="pattern-tab" onClick={() => setPatternCategory(c)}>{c}</button>
              ))}
            </div>
            {PATTERNS.filter((p) => p.category === patternCategory).map((p) => (
              <button key={p.name} className="chip" onClick={() => p.rows.forEach((row) => handleAdd(row))}>{p.name}</button>
            ))}
          </div>
        </div>
      </div>

    </div>
  );
}
