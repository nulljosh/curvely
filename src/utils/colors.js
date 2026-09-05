// clrs.cc palette (teal/purple/fuchsia skipped, house rule)
export const COLORS = [
  '#0074D9', // blue
  '#FF4136', // red
  '#2ECC40', // green
  '#FFDC00', // yellow
  '#FF851B', // orange
  '#3D9970', // olive
  '#AAAAAA', // gray
  '#001f3f', // navy
];

export function colorAt(index) {
  const n = COLORS.length;
  const i = Number.isInteger(index) ? index : 0;
  return COLORS[((i % n) + n) % n];
}
