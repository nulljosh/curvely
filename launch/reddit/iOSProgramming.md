Note: use "Show and Tell" flair. Weekly self-promo thread is the safer route if standalone posts get removed.

Title: Show and Tell: SwiftUI graphing calculator, native on iPhone, iPad and Mac from one target

Body:
Curvely is a graphing calculator, rewritten from a WKWebView shell to native SwiftUI after App Review flagged the wrapped version as incomplete. One target covers iOS, iPadOS and macOS through supportedDestinations. The math parser is a hand-written recursive-descent evaluator (App/Expression.swift), verified against mathjs across 3,636 sample points to make sure the native app and the web build agree.

The part I'm proudest of is implicit equations. x^2 + y^2 = 25 doesn't fit y = f(x), so it's traced with marching squares over a coarse pixel grid, ported line for line from the JS version into Swift so both platforms draw the same curve. Canvas export goes through ImageRenderer and ShareLink, no UIActivityViewController branch needed for macOS.

$0.99 on the App Store, free on the web. Happy to talk through the parser or the rendering approach if anyone's curious.
