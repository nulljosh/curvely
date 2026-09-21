Note: no karma/flair gate. Frame as "I built X to solve Y", not an ad.

Title: I built a canvas-based graphing calculator to solve implicit equations without a charting library

Body:
Wanted a grapher that felt instant and didn't need a backend. Curvely plots on raw HTML Canvas rather than a charting library, since those target bar and line charts, not a continuous function with pan and zoom on ref-held transform state so dragging doesn't re-render React every frame.

The harder problem was implicit equations, things like x^2 + y^2 = 25 that don't reduce to y = f(x). Solved it with marching squares: sample the equation across a coarse grid, check each cell for a sign change, linearly interpolate the crossing point on each edge, connect the crossings into segments. It runs client-side with mathjs doing the expression evaluation.

There's also a stateless HTTP API and an MCP endpoint if you want to evaluate or sample equations from code. Free on the web at curvely.heyitsmejosh.com, source on GitHub. Feedback on the rendering approach welcome.
