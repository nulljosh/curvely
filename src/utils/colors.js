export const COLORS = [
  '#0071e3',
  '#ff453a',
  '#30d158',
  '#ffd60a',
  '#a2845e',
  '#ff9f0a',
  '#8e8e93',
  '#ff375f',
];

export function colorAt(index) {
  return COLORS[index % COLORS.length];
}
