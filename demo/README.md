This is the `kroutes` demo application!

# Files
- app.nim: The client-side app - this is where you can see `kroutes` in action.
- server.nim: The server. The server includes a wildcard that directs most routes to the webapp itself, where `kroutes` does the routing and rendering. The server also includes an endpoint used for SSR.
- public/ contains the base HTML and CSS used by the demo app. After compiling app.nim, it will also contain the demo app's JS code.

# Prerequisites

Install `prologue` from Nimble: `nimble install prologue`

# Compiling/Running

`nim js -o:public/app.nim.js app`

`nim c -r server`
