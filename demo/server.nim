import prologue
import prologue/middlewares/staticfile
import karax/[karaxdsl, vdom]
import kroutes/kroutes_static

proc frontend(ctx: Context) {.async.} =
  await ctx.staticFileResponse("app.html", "public")

proc about(ctx: Context) {.async.} =
  await sleepAsync(1000) # make it a little laggy, so the user sees the loading screen

  let vnode = buildHtml(main):
    h1:
      text "About"
    p:
      text "This content was rendered by the server. Cool, right?"
    p:
      text """Don't worry - it's not slow. The server intentionally
      delayed its response so that you could see the loading message."""
    p:
      text """The way this works is quite simple. First, KRoutes made
      an AJAX request to the endpoint """
      code: text "/ssr/about"
      text """. While it waited for the server to respond, it rendered
      a loading message. You can customize the loading message by
      changing the """
      code: text "ssrLoading"
      text """ method. Once the server responded, KRoutes replaced the
      loading prompt with the HTML it received from the server. That's
      all there is to it!"""
    p:
      text """KRoutes has now cached this content, as well. It will
      reload if you refresh the page, but if you navigate to another
      page on the site, then use your browser's back/forward buttons
      to return to this page, you'll notice that the loading message
      doesn't show up."""

  resp htmlResponse($vnode)

let settings = newSettings(appName = "kroutes demo")
var app = newApp(settings = settings)

app.use staticFileMiddleware("public")
app.get("/ssr/about", about)
app.get("/*$", frontend)
app.run()
