// Ready-made graphs, one tap each, grouped for the Patterns card.
// ios/App/Patterns.swift is generated from this file: node scripts/gen-patterns.mjs
// Each pattern uses its own list and slider names so two patterns can share a graph.
export const PATTERNS = [
  // Spirals
  { category: 'Spirals', name: 'Golden spiral', rows: ['r = phi^(2theta/pi) {-4pi < theta < 2pi}'] },
  { category: 'Spirals', name: 'Archimedean', rows: ['r = 0.3theta {0 < theta < 8pi}'] },
  { category: 'Spirals', name: "Fermat's spiral", rows: ['r = 0.8sqrt(theta) {0 < theta < 8pi}', 'r = -0.8sqrt(theta) {0 < theta < 8pi}'] },
  { category: 'Spirals', name: 'Hyperbolic', rows: ['r = 3/theta {0.4 < theta < 10pi}'] },
  { category: 'Spirals', name: 'Lituus', rows: ['r = 2/sqrt(theta) {0.1 < theta < 10pi}'] },
  { category: 'Spirals', name: 'Logarithmic', rows: ['r = 0.2e^(0.18theta) {0 < theta < 6pi}'] },
  { category: 'Spirals', name: 'Snail shell', rows: ['shell = [1...80]', '(0.05shell cos(0.45shell), 0.05shell sin(0.45shell))'] },
  { category: 'Spirals', name: 'Galaxy', rows: ['arm = [1...220]', '(0.016arm cos(0.09arm), 0.016arm sin(0.09arm))', '(-0.016arm cos(0.09arm), -0.016arm sin(0.09arm))'] },

  // Flowers
  { category: 'Flowers', name: 'Flower of life', rows: [
    'x^2 + y^2 = 2.25',
    'petal = [0...5]',
    '(x - 1.5cos(petal pi/3))^2 + (y - 1.5sin(petal pi/3))^2 = 2.25',
    '(x - 3cos(petal pi/3))^2 + (y - 3sin(petal pi/3))^2 = 2.25',
    '(x - 2.598cos(petal pi/3 + pi/6))^2 + (y - 2.598sin(petal pi/3 + pi/6))^2 = 2.25',
    'x^2 + y^2 = 20.25',
  ] },
  { category: 'Flowers', name: 'Seed of life', rows: ['x^2 + y^2 = 2.25', 'seed = [0...5]', '(x - 1.5cos(seed pi/3))^2 + (y - 1.5sin(seed pi/3))^2 = 2.25'] },
  { category: 'Flowers', name: 'Sunflower', rows: ['n = [1...300]', '(0.2 sqrt(n) cos(2pi n/phi^2), 0.2 sqrt(n) sin(2pi n/phi^2))'] },
  { category: 'Flowers', name: 'Rose', rows: ['k = 4 {1 < k < 9}', 'r = 3cos(k theta)'] },
  { category: 'Flowers', name: 'Four petals', rows: ['r = 3cos(2theta)'] },
  { category: 'Flowers', name: 'Eight petals', rows: ['r = 3sin(4theta)'] },
  { category: 'Flowers', name: 'Five-two rose', rows: ['r = 3cos(2.5theta) {0 < theta < 4pi}'] },
  { category: 'Flowers', name: 'Daisy', rows: ['r = 2 + 0.6cos(12theta)', 'r = 0.8'] },
  { category: 'Flowers', name: 'Starfish', rows: ['r = 2 + 0.9sin(5theta)'] },
  { category: 'Flowers', name: 'Clover', rows: ['r = 3abs(cos(2theta))'] },
  { category: 'Flowers', name: 'Butterfly', rows: ['r = e^sin(theta) - 2cos(4theta) + sin((2theta - pi)/24)^5 {0 < theta < 12pi}'] },

  // Hearts
  { category: 'Hearts', name: 'Heart', rows: ['(sin(t)^3 * 2, (13cos(t) - 5cos(2t) - 2cos(3t) - cos(4t))/8)'] },
  { category: 'Hearts', name: 'Polar heart', rows: ['r = 1.5 - 1.5sin(theta)'] },
  { category: 'Hearts', name: 'Implicit heart', rows: ['((x/2)^2 + (y/2)^2 - 1)^3 = (x/2)^2 (y/2)^3'] },
  { category: 'Hearts', name: 'Filled heart', rows: ['((x/2)^2 + (y/2)^2 - 1)^3 < (x/2)^2 (y/2)^3'] },
  { category: 'Hearts', name: 'Infinity', rows: ['(x^2 + y^2)^2 = 8(x^2 - y^2)'] },

  // Classic curves
  { category: 'Classics', name: 'Cardioid', rows: ['r = 2 + 2cos(theta)'] },
  { category: 'Classics', name: 'Limaçon', rows: ['r = 1 + 2cos(theta)'] },
  { category: 'Classics', name: 'Astroid', rows: ['(3cos(t)^3, 3sin(t)^3)'] },
  { category: 'Classics', name: 'Deltoid', rows: ['(2cos(t) + cos(2t), 2sin(t) - sin(2t))'] },
  { category: 'Classics', name: 'Nephroid', rows: ['(1.5cos(t) - 0.5cos(3t), 1.5sin(t) - 0.5sin(3t))'] },
  { category: 'Classics', name: 'Cycloid', rows: ['(0.5(t - sin(t)), 0.5(1 - cos(t))) {-6pi < t < 6pi}'] },
  { category: 'Classics', name: 'Witch of Agnesi', rows: ['8/(x^2 + 4)'] },
  { category: 'Classics', name: 'Folium', rows: ['x^3 + y^3 = 6x y'] },
  { category: 'Classics', name: 'Catenary', rows: ['2cosh(x/2) - 2'] },
  { category: 'Classics', name: 'Cissoid', rows: ['y^2 (2 - x) = x^3'] },
  { category: 'Classics', name: 'Trefoil', rows: ['(sin(t) + 2sin(2t), cos(t) - 2cos(2t))'] },
  { category: 'Classics', name: 'Tractrix', rows: ['(t - tanh(t), 1/cosh(t)) {-4 < t < 4}'] },
  { category: 'Classics', name: 'Squircle', rows: ['x^4 + y^4 = 16'] },
  { category: 'Classics', name: 'Five-point star', rows: ['(2.4cos(t) + 0.6cos(4t), 2.4sin(t) - 0.6sin(4t))'] },
  { category: 'Classics', name: 'Cassini ovals', rows: ['((x - 2)^2 + y^2)((x + 2)^2 + y^2) = [12, 16, 20, 30]'] },

  // Lissajous and harmonographs
  { category: 'Lissajous', name: 'Lissajous', rows: ['a = 3 {1 < a < 8}', 'b = 2 {1 < b < 8}', '(3sin(a t), 3sin(b t))'] },
  { category: 'Lissajous', name: 'Three-four', rows: ['(3sin(3t + pi/2), 3sin(4t))'] },
  { category: 'Lissajous', name: 'Five-four', rows: ['(3sin(5t), 3sin(4t))'] },
  { category: 'Lissajous', name: 'Bowditch knot', rows: ['(3sin(2t), 3sin(3t))'] },
  { category: 'Lissajous', name: 'Harmonograph', rows: ['(3e^(-0.04t) sin(2t), 3e^(-0.04t) sin(3t + 1)) {0 < t < 20pi}'] },
  { category: 'Lissajous', name: 'Drifting phase', rows: ['p = 0 {0 < p < 6.28}', '(3sin(3t + p), 3sin(2t))'] },

  // Spirographs
  { category: 'Spirographs', name: 'Spirograph', rows: ['(2cos(t) + 2.5cos(2t/3), 2sin(t) - 2.5sin(2t/3)) {0 < t < 6pi}'] },
  { category: 'Spirographs', name: 'Inner flower', rows: ['(2cos(t) + 1.5cos(3t), 2sin(t) - 1.5sin(3t))'] },
  { category: 'Spirographs', name: 'Epitrochoid', rows: ['(2.5cos(t) - 1.2cos(5t), 2.5sin(t) - 1.2sin(5t))'] },
  { category: 'Spirographs', name: 'Gear', rows: ['(2.6cos(t) - 0.3cos(9t), 2.6sin(t) - 0.3sin(9t))'] },
  { category: 'Spirographs', name: 'Starburst', rows: ['(2cos(t) + 1.2cos(2.5t), 2sin(t) - 1.2sin(2.5t)) {0 < t < 4pi}'] },
  { category: 'Spirographs', name: 'Lace', rows: ['(2cos(t) + cos(7t/3), 2sin(t) - sin(7t/3)) {0 < t < 6pi}'] },

  // Waves
  { category: 'Waves', name: 'Sine fan', rows: ['sin(x + [0...7]/4)'] },
  { category: 'Waves', name: 'Damped wave', rows: ['e^(-x/4) sin(3x)', 'e^(-x/4)', '-e^(-x/4)'] },
  { category: 'Waves', name: 'Beats', rows: ['sin(8x) + sin(9x)'] },
  { category: 'Waves', name: 'Square wave', rows: ['(4/pi)(sin(x) + sin(3x)/3 + sin(5x)/5 + sin(7x)/7 + sin(9x)/9)'] },
  { category: 'Waves', name: 'Sawtooth', rows: ['(2/pi)(sin(x) - sin(2x)/2 + sin(3x)/3 - sin(4x)/4 + sin(5x)/5 - sin(6x)/6)'] },
  { category: 'Waves', name: 'Triangle wave', rows: ['(2/pi) asin(sin(x))'] },
  { category: 'Waves', name: 'Standing wave', rows: ['w = 0 {0 < w < 6.28}', '2sin(2x) cos(w)'] },
  { category: 'Waves', name: 'Chirp', rows: ['sin(x^2)'] },
  { category: 'Waves', name: 'AM radio', rows: ['(1 + 0.6sin(x/2)) sin(8x)'] },
  { category: 'Waves', name: 'Sinc', rows: ['3sin(2x)/(2x)'] },

  // Functions
  { category: 'Functions', name: 'Bell curve', rows: ['3e^(-x^2/2)'] },
  { category: 'Functions', name: 'Logistic', rows: ['4/(1 + e^(-2x))'] },
  { category: 'Functions', name: 'Parabola family', rows: ['x^2/2 + [-3...1]'] },
  { category: 'Functions', name: 'e, ln and y = x', rows: ['e^x', 'ln(x)', 'x'] },
  { category: 'Functions', name: 'Bouncing ball', rows: ['3abs(sin(x)) e^(-x/6) {x > 0}'] },
  { category: 'Functions', name: 'Staircase', rows: ['floor(x)'] },
  { category: 'Functions', name: 'Tangent', rows: ['tan(x)'] },
  { category: 'Functions', name: 'Cubic and slope', rows: ['f(x) = x^3/3 - x', "f'(x)"] },

  // Dots
  { category: 'Dots', name: 'Circle of dots', rows: ['c = [0...23]', '(3cos(c pi/12), 3sin(c pi/12))'] },
  { category: 'Dots', name: 'Sine dots', rows: ['d = [-30...30]', '(d/5, 2sin(d/5))'] },
  { category: 'Dots', name: 'Fibonacci', rows: ['[(1, 0.5), (2, 0.5), (3, 1), (4, 1.5), (5, 2.5), (6, 4), (7, 6.5)]'] },
  { category: 'Dots', name: 'Parabola dots', rows: ['q = [-10...10]', '(q/3, (q/3)^2/2)'] },

  // Regions
  { category: 'Regions', name: 'Checkerboard', rows: ['sin(x) sin(y) > 0'] },
  { category: 'Regions', name: 'Ring', rows: ['abs(x^2 + y^2 - 5) < 3'] },
  { category: 'Regions', name: 'Diamond', rows: ['abs(x) + abs(y) <= 3'] },
  { category: 'Regions', name: 'Venn diagram', rows: ['(x + 1)^2 + y^2 < 4', '(x - 1)^2 + y^2 < 4'] },
  { category: 'Regions', name: 'Hills', rows: ['y < sin(x) + 0.5sin(3x) - 1'] },
  { category: 'Regions', name: 'Polka dots', rows: ['sin(2x) sin(2y) > 0.6'] },
  { category: 'Regions', name: 'Ripples', rows: ['sin(x^2 + y^2) > 0'] },

  // Implicit art
  { category: 'Implicit', name: 'Hyperbolas', rows: ['x^2 - y^2 = [1...4]'] },
  { category: 'Implicit', name: 'Rings', rows: ['cos(x^2 + y^2) = 0'] },
  { category: 'Implicit', name: 'Tiles', rows: ['sin(x) + sin(y) = 0'] },
  { category: 'Implicit', name: 'Circles', rows: ['x^2 + y^2 = [1...5]^2'] },
  { category: 'Implicit', name: 'Waves', rows: ['sin(x) = cos(y)'] },
];

export const PATTERN_CATEGORIES = [...new Set(PATTERNS.map((p) => p.category))];
