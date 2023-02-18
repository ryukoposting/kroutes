KRoutes is a client-side router for [karax](https://github.com/karaxnim/karax).

# Features

- Easy to retrofit into existing Karax apps.
- Support for both client-side and server-side HTML rendering.
- Extensibility via method overloading.
- Utility procs for site navigation.
- Routing with path parameters.
- Optional RAM-cached SSR responses to reduce server load.
- Only one dependency: Karax (which you're using anyway, if you're using this package!)

# Simple Example

```nim
include karax/prelude
import kroutes

let router = newRouter()

router.addRoute("/") do (ctx: Context) -> VNode:
  buildHtml(main):
    button(onclick = goto("/clicked")): text "Click the button."
    button(onclick = goto("/blog_post")): text "Go to the blog post."

router.addRoute("/clicked") do (ctx: Context) -> VNode:
  buildHtml(main):
    text "You clicked the button!"
    button(onclick = goBack()): text "Go back."

router.addSsrRoue("/blog_post")

setRenderer(router)
```

# Demo app

The `demo/` directory contains a simple web app using [Prologue](https://planety.github.io/prologue/), [Karax](https://github.com/karaxnim/karax), and KRoutes. It uses both client-side and server-side rendering.
