// Curvely landing: the art is the app's own output. Every curve is generated here, so there is nothing to fetch.
(function () {
  document.documentElement.classList.add('js');
  var NS = 'http://www.w3.org/2000/svg';
  var FN = {
    sin: function (x) { return Math.sin(x * 3); },
    parab: function (x) { return x * x * 2 - 1; },
    cos: function (x) { return Math.cos(x * 4) * 0.7; },
    tanh: function (x) { return Math.tanh(x * 4); },
    damp: function (x) { return Math.sin(x * 9) / (Math.abs(x) * 4 + 1); },
    cubic: function (x) { return x * x * x * 1.5; },
    abs: function (x) { return Math.abs(x) * 2 - 1; },
    beat: function (x) { return Math.sin(x * 2) + Math.cos(x * 5) * 0.3; },
    exp: function (x) { return Math.exp(x) * 0.4 - 1; }
  };
  function el(tag, attrs) { var e = document.createElementNS(NS, tag); for (var k in attrs) e.setAttribute(k, attrs[k]); return e; }
  // One SVG: a faint grid and axes, then each named curve, stretched to the box.
  function plot(names) {
    var svg = el('svg', { viewBox: '-1 -1 2 2', preserveAspectRatio: 'none', 'aria-hidden': 'true' });
    for (var g = -0.8; g < 1; g += 0.4) {
      svg.appendChild(el('path', { d: 'M' + g + ' -1V1M-1 ' + g + 'H1', fill: 'none', stroke: 'currentColor', 'stroke-width': 1, 'stroke-opacity': 0.25, 'vector-effect': 'non-scaling-stroke' }));
    }
    svg.appendChild(el('path', { d: 'M0 -1V1M-1 0H1', fill: 'none', stroke: 'currentColor', 'stroke-width': 2, 'stroke-opacity': 0.6, 'vector-effect': 'non-scaling-stroke' }));
    names.forEach(function (n) {
      var d = '';
      for (var i = 0; i <= 240; i++) {
        var x = -1 + i / 120, y = FN[n](x);
        if (!isFinite(y)) { d = ''; continue; }
        y = Math.max(-1.2, Math.min(1.2, y));
        d += (d ? 'L' : 'M') + x.toFixed(3) + ' ' + (-y).toFixed(3);
      }
      svg.appendChild(el('path', { d: d, fill: 'none', stroke: 'currentColor', 'stroke-width': 3, 'stroke-linecap': 'round', 'vector-effect': 'non-scaling-stroke' }));
    });
    return svg;
  }
  document.querySelectorAll('[data-curves]').forEach(function (box) { box.appendChild(plot(box.dataset.curves.split(' '))); });

  // the light on Apollo follows the pointer; with no pointer it rests where the face is
  var spot = document.getElementById('spot');
  if (spot) spot.parentNode.addEventListener('pointermove', function (e) {
    var r = spot.getBoundingClientRect();
    spot.style.setProperty('--mx', (e.clientX - r.left) + 'px'); spot.style.setProperty('--my', (e.clientY - r.top) + 'px');
  });

  var still = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!still && 'IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('in-view'); io.unobserve(e.target); } });
    }, { threshold: 0.15 });
    document.querySelectorAll('.reveal').forEach(function (n) { io.observe(n); });
  } else document.querySelectorAll('.reveal').forEach(function (n) { n.classList.add('in-view'); });
})();
