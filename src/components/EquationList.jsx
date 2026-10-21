import EquationRow from './EquationRow.jsx';

export default function EquationList({ equations, sliders, onChange, onRemove, onToggle, onAdd, onSliderChange, playing, onTogglePlay }) {
  const sliderByName = Object.fromEntries((sliders || []).map((s) => [s.name, s]));
  return (
    <div className="eq-list-container glass-card">
      <div className="card-title">Equations</div>

      {equations.map((eq) => (
        <EquationRow
          key={eq.id}
          eq={eq}
          slider={sliderByName}
          onChange={onChange}
          onRemove={onRemove}
          onToggle={onToggle}
          onSliderChange={onSliderChange}
          playing={playing}
          onTogglePlay={onTogglePlay}
          showRemove={equations.length > 1}
        />
      ))}

      <button className="add-btn" onClick={onAdd}>+ Add equation</button>
    </div>
  );
}
