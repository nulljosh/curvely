import EquationRow from './EquationRow.jsx';

export default function EquationList({ equations, sliders, onChange, onRemove, onAdd, onSliderChange }) {
  const sliderByName = Object.fromEntries((sliders || []).map((s) => [s.name, s]));
  return (
    <div className="eq-list-container" style={{
      background: 'var(--bg)',
      border: '1px solid var(--border)',
      borderRadius: 16,
      padding: '16px 16px 12px',
      display: 'flex',
      flexDirection: 'column',
    }}>
      <div style={{
        fontSize: 11, fontWeight: 600, letterSpacing: '0.08em',
        textTransform: 'uppercase', color: 'var(--text-secondary)',
        marginBottom: 12,
      }}>Equations</div>

      {equations.map((eq) => (
        <EquationRow
          key={eq.id}
          eq={eq}
          slider={sliderByName}
          onChange={onChange}
          onRemove={onRemove}
          onSliderChange={onSliderChange}
          showRemove={equations.length > 1}
        />
      ))}

      <button
        onClick={onAdd}
        style={{
          marginTop: 4,
          background: 'rgba(255,133,27,0.1)',
          border: '1px solid rgba(255,133,27,0.35)',
          borderRadius: 10,
          color: 'var(--accent)',
          fontSize: 13,
          fontFamily: 'var(--font)',
          padding: '7px 0',
          minHeight: 44,
          cursor: 'pointer',
          transition: 'background 0.15s',
        }}
        onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255,133,27,0.2)'}
        onMouseLeave={(e) => e.currentTarget.style.background = 'rgba(255,133,27,0.1)'}
      >+ Add equation</button>
    </div>
  );
}
