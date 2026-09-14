import { useState, useEffect } from 'react';
import { evaluate, parseSlider } from '../utils/evaluate.js';

export default function EquationRow({ eq, slider, onChange, onRemove, onSliderChange, showRemove }) {
  const [invalid, setInvalid] = useState(false);
  useEffect(() => {
    const t = setTimeout(() => {
      try {
        const { fn, error } = evaluate(eq.expr);
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
        <div style={{
          width: 12, height: 12, borderRadius: '50%',
          background: eq.color, flexShrink: 0,
          boxShadow: `0 0 6px ${eq.color}88`,
        }} />
        <input
          value={eq.expr}
          onChange={(e) => onChange(eq.id, e.target.value)}
          placeholder="y = x^2"
          spellCheck={false}
          inputMode="text"
          className="eq-input"
          style={{
            flex: 1,
            background: 'var(--bg2)',
            border: `1px solid ${(eq.error || invalid) ? 'rgba(220,53,69,0.6)' : 'var(--border)'}`,
            borderRadius: 10,
            padding: '8px 12px',
            color: 'var(--text)',
            fontSize: 16,
            minHeight: 44,
            fontFamily: '-apple-system, BlinkMacSystemFont, "Helvetica Neue", Helvetica, sans-serif',
            outline: 'none',
            transition: 'border-color 0.15s',
          }}
          onFocus={(e) => {
            if (!eq.error && !invalid) e.target.style.borderColor = 'var(--accent)';
          }}
          onBlur={(e) => {
            e.target.style.borderColor = (eq.error || invalid) ? 'rgba(220,53,69,0.6)' : 'var(--border)';
          }}
        />
        {showRemove && (
          <button
            onClick={() => onRemove(eq.id)}
            style={{
              background: 'none', border: 'none', color: 'var(--text-secondary)',
              cursor: 'pointer', fontSize: 18, lineHeight: 1, padding: '0 2px',
              flexShrink: 0, minHeight: 44, minWidth: 44,
            }}
          >×</button>
        )}
      </div>
      {eq.error && (
        <div style={{
          marginTop: 4, marginLeft: 20,
          fontSize: 11, color: 'rgba(220,53,69,0.85)',
          fontFamily: '-apple-system, BlinkMacSystemFont, "Helvetica Neue", Helvetica, sans-serif',
        }}>{eq.error}</div>
      )}
      {invalid && !eq.error && (
        <span style={{ fontSize: '0.7rem', color: '#e55', marginTop: 2, marginLeft: 20, display: 'block' }}>invalid expression</span>
      )}
      {sliderState != null && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6, marginLeft: 20 }}>
          <input
            type="range"
            min={Math.min(-10, sliderState.value - 5)}
            max={Math.max(10, sliderState.value + 5)}
            step={0.1}
            value={sliderState.value}
            onChange={(e) => onSliderChange(sliderDef.name, Number(e.target.value))}
            style={{ flex: 1, accentColor: eq.color }}
          />
          <span style={{
            fontSize: 12, color: 'var(--text-secondary)', minWidth: 40, textAlign: 'right',
            fontFamily: '-apple-system, BlinkMacSystemFont, "Helvetica Neue", Helvetica, sans-serif',
          }}>{sliderState.value.toFixed(1)}</span>
        </div>
      )}
    </div>
  );
}
