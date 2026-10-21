import { useState, useEffect } from 'react';
import { parseSlider } from '../utils/evaluate.js';
import { evaluateRow } from '../utils/lists.js';

export default function EquationRow({ eq, slider, onChange, onRemove, onToggle, onSliderChange, playing, onTogglePlay, showRemove }) {
  const [invalid, setInvalid] = useState(false);
  useEffect(() => {
    const t = setTimeout(() => {
      try {
        const { fn, error } = evaluateRow(eq.expr);
        setInvalid(fn === null && !!error);
      } catch {
        setInvalid(true);
      }
    }, 500);
    return () => clearTimeout(t);
  }, [eq.expr]);

  const sliderDef = parseSlider(eq.expr);
  const sliderState = sliderDef && slider?.[sliderDef.name];

  return (
    <div style={{ marginBottom: 10 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <button
          className="dot-btn"
          aria-label={eq.hidden ? 'Show on graph' : 'Hide from graph'}
          aria-pressed={!eq.hidden}
          onClick={() => onToggle(eq.id)}
        >
          <span style={{
            display: 'block', width: 12, height: 12, borderRadius: '50%', boxSizing: 'border-box',
            background: eq.hidden ? 'transparent' : eq.color, border: `2px solid ${eq.color}`,
          }} />
        </button>
        <input
          value={eq.expr}
          onChange={(e) => onChange(eq.id, e.target.value)}
          placeholder="y = x^2"
          spellCheck={false}
          inputMode="text"
          className={`eq-input${(eq.error || invalid) ? ' bad' : ''}`}
        />
        {showRemove && (
          <button
            className="rm-btn"
            aria-label="Remove equation"
            onClick={() => onRemove(eq.id)}
          >×</button>
        )}
      </div>
      {eq.error && (
        <div style={{
          marginTop: 4, marginLeft: 20,
          fontSize: 11, color: 'rgba(220,53,69,0.85)',
          fontFamily: 'var(--font)',
        }}>{eq.error}</div>
      )}
      {invalid && !eq.error && (
        <span style={{ fontSize: '0.7rem', color: '#e55', marginTop: 2, marginLeft: 20, display: 'block' }}>invalid expression</span>
      )}
      {sliderState != null && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6, marginLeft: 20 }}>
          <button
            className="play-btn"
            aria-label={playing?.[sliderDef.name] ? `Pause ${sliderDef.name}` : `Play ${sliderDef.name}`}
            aria-pressed={!!playing?.[sliderDef.name]}
            onClick={() => onTogglePlay(sliderDef.name)}
          >
            <svg width="12" height="12" viewBox="0 0 12 12" aria-hidden="true" fill="currentColor">
              {playing?.[sliderDef.name]
                ? <><rect x="2" y="1" width="3" height="10" rx="1" /><rect x="7" y="1" width="3" height="10" rx="1" /></>
                : <path d="M3 1.5v9a.5.5 0 0 0 .77.42l7-4.5a.5.5 0 0 0 0-.84l-7-4.5A.5.5 0 0 0 3 1.5z" />}
            </svg>
          </button>
          <input
            type="range"
            min={sliderState.min}
            max={sliderState.max}
            step="any"
            value={sliderState.value}
            onChange={(e) => onSliderChange(sliderDef.name, Number(e.target.value))}
            style={{ flex: 1, accentColor: eq.color }}
          />
          <span style={{
            fontSize: 12, color: 'var(--text-secondary)', minWidth: 40, textAlign: 'right',
            fontFamily: 'var(--font)',
          }}>{Number(sliderState.value.toFixed(2))}</span>
        </div>
      )}
    </div>
  );
}
