// Writes ios/App/Patterns.swift from src/utils/patterns.js, so the apps and the web share one list.
// usage: node scripts/gen-patterns.mjs
import { writeFileSync } from 'node:fs';
import { PATTERNS } from '../src/utils/patterns.js';

const str = (s) => JSON.stringify(s); // a JSON string is a valid Swift string literal here
const lines = PATTERNS.map((p) =>
  `    Pattern(category: ${str(p.category)}, name: ${str(p.name)}, rows: [${p.rows.map(str).join(', ')}]),`);
writeFileSync(new URL('../ios/App/Patterns.swift', import.meta.url), `// Ready-made graphs, one tap each, grouped for the Patterns card.
// Generated from src/utils/patterns.js by scripts/gen-patterns.mjs. Edit that file, not this one.

struct Pattern {
    let category: String
    let name: String
    let rows: [String]
}

let patterns: [Pattern] = [
${lines.join('\n')}
]

/// Categories in the order they first appear.
let patternCategories: [String] = patterns.reduce(into: []) { if !$0.contains($1.category) { $0.append($1.category) } }
`);
console.log(`wrote ${PATTERNS.length} patterns`);
