Note: no karma/flair gate, public post fine any time. Tell the build story, no bare link.

Title: I built a graphing calculator that traces implicit equations with marching squares

Body:
I needed a grapher for Pre-Calc that opened instantly, worked offline, and didn't ask for an account. Most simple graphers only handle y = f(x), so anything like x^2 + y^2 = 25 doesn't plot. I ended up writing a marching squares tracer: sample the equation across a coarse grid, check each cell for a sign change, interpolate where the curve crosses an edge, connect the crossings into segments. Same algorithm in JavaScript for the web build and in Swift for iOS and Mac.

Everything computes on the device, nothing is sent anywhere. It's $0.99 on the App Store, free on the web at curvely.heyitsmejosh.com. Source is on GitHub. Would love feedback, especially on where the curve tracing looks wrong near asymptotes.
