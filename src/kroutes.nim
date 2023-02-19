## `kroutes` is a router for Karax. It supports both client-side and server-side rendering.
## 
## # Example
## 
## A more complex example is available `here.<https://github.com/ryukoposting/kroutes/tree/master/demo>`_
## 
## .. code-block:: nim
##   include karax/prelude
##   import kroutes
## 
##   let router = newRouter()
## 
##   router.addRoute("/") do (ctx: Context) -> VNode:
##     buildHtml(main):
##       button(onclick = goto("/clicked")): text "Click the button."
##       button(onclick = goto("/blog_post")): text "Go to the blog post."
## 
##   router.addRoute("/clicked") do (ctx: Context) -> VNode:
##     buildHtml(main):
##       text "You clicked the button!"
##       button(onclick = goBack()): text "Go back."
## 
##   router.addSsrRoue("/blog_post")
## 
##   setRenderer(router)
## 

when not defined(js):
  {.error: "kroutes only works on the JS backend!".}


import karax/[karax, karaxdsl, vdom, kajax, kdom]
import std/[sugar, strutils, strformat, tables, uri]

type
  Router* = ref object of RootObj
    root: RouteNode
    ssrBaseUri: Uri

  Context* = object ##\
    ## When `Router` calls a rendering function, it provides this `Context` object.
    ## - `params` contains any path parameters that were part of the route.
    ## - `path` is the path itself.
    ## - `query` contains every key-value pair in the query string, in the same order as
    ##   they appeared in the query string.
    ## - `anchor` contains the URL anchor, if any.
    ## 
    ## Example: if the router was given this route:
    ## 
    ## ```"/foo/{bar}"```
    ## And the user navigated to this path:
    ## ```"/foo/helloworld#thingy?one=two&three=four```
    ## 
    ## The corresponding context object would look like this:
    ## ```
    ## params = {
    ##   "bar": "helloworld"
    ## }
    ## path = "/foo/helloworld"
    ## query = [
    ##   ("one", "two"),
    ##   ("three", "four")
    ## ]
    ## anchor = "thingy"
    ## ```
    params*: TableRef[string,string]
    path*: string
    query*: seq[tuple[key, value: string]]
    anchor*: string

  RouteNodeKind* = enum
    routeKindLiteralPath,
    routeKindParameter,
    routeKindWildcard,
    routeKindRoot,
    routeKindTerminal,
    routeKindSsrTerminal

  RouteNode* = object
    children*: seq[RouteNode]
    case kind*: RouteNodeKind
    of routeKindLiteralPath:
      part*: string
    of routeKindParameter:
      param*: string
    of routeKindTerminal:
      renderer*: RouteRenderer
    of routeKindSsrTerminal:
      useCache: bool
      cache: TableRef[string,cstring]
    of routeKindRoot, routeKindWildcard:
      discard

  RouteRenderer* = proc(ctx: Context): VNode {.closure.} ##\
    ## A `RouteRenderer` function is called by the router to redraw the page.

  HistoryShim {.importc.} = ref object

proc newRouter*(ssrPath = "/ssr"): Router =
  ## Create a new instance of `Router`.
  ## 
  ## `ssrPath` is the base path that will be used by SSR rendering requests. If you are
  ## not using SSR routes, you can safely ignore `ssrPath`.
  new result
  result.ssrBaseUri = parseUri(ssrPath)
  result.root = RouteNode(
    kind: routeKindRoot
  )

proc newRouter*[T: Router](_: typedesc[T], ssrPath = "/ssr"): T =
  ## Create a new instance of a `Router` subclass.
  ## 
  ## `ssrPath` is the base path that will be used by SSR rendering requests. If you are
  ## not using SSR routes, you can safely ignore `ssrPath`.
  new result
  result.ssrBaseUri = parseUri(ssrPath)
  result.root = RouteNode(
    kind: routeKindRoot
  )

method rendererRoot*(router: Router, content: VNode, ctx: Context): VNode {.base.} =
  ## Override this method to wrap or replace the rendered content.
  ## Consider overriding this function if your webapp has sidebars, a sticky header,
  ## or other content that is the the same regardless of the route.
  return content

method noMatchingRoute*(router: Router, ctx: Context): VNode {.base.} =
  ## If the router cannot find a matching route to the current path, it renders
  ## this content instead. The base method renders the following HTML:
  ## 
  ## ```
  ## <div>
  ##   <p>Error: Not Found - no route to {ctx.path}</p>
  ## </div>
  ## ```
  buildHtml(tdiv):
    p: text fmt"Error: Not Found - no route to '{ctx.path}'"

method postRender*(router: Router) {.base.} =
  ## This method is called each time Karax finishes redrawing the page.
  ## The base version of this method does nothing.
  discard

method ssrLoading*(router: Router, ctx: Context): VNode {.base.} =
  ## The HTML rendered by this method will be displayed while an SSR request is in progress.
  ## If you are not using SSR routes, you can safely ignore this method.
  ## 
  ## The base method renders the following HTML:
  ## ```
  ## <div>
  ##   <p>Loading...</p>
  ## </div>
  ## ```
  buildHtml(tdiv):
    p: text "Loading..."

var history {.importc, nodecl.}: History

proc pushState(history: History, options: HistoryShim, title: cstring, path: cstring) {.importcpp.}
proc pushState(history: History, path: cstring) = history.pushState(HistoryShim(), cstring(""), path)
# proc state(history: History): HistoryShim {.importjs: "#.state".}

proc goTo*(path: string) =
  ## Route the user to another page.
  ## 
  ## This function can be called from plain JS code by calling `kroutesGoTo`.
  let currentPath = $kdom.window.location.pathname
  if currentPath != path:
    history.pushState(cstring(path))
  else:
    discard

proc goBack*(n = 1) =
  ## Navigate backwards by N pages.
  ## 
  ## This function can be called from plain JS code by calling `kroutesGoBack`.
  history.go(-n)

proc goForward*(n = 1) =
  ## Navigate forward by N pages.
  ## 
  ## This function can be called from plain JS code by calling `kroutesGoForward`.
  history.go(n)

proc kroutesGoTo(path: cstring) {.exportc.} =
  goTo($path)
  redraw()

proc kroutesGoBack(n: int) {.exportc.} =
  goBack(n)
  redraw()

proc kroutesGoForward(n: int) {.exportc.} =
  goForward(n)
  redraw()

proc addRouteInner(parent: var RouteNode, path: openArray[string], renderer: RouteRenderer = nil, useCache=false) =
  if path.len == 0 and not renderer.isNil:
    parent.children.add RouteNode(
      kind: routeKindTerminal,
      renderer: renderer
    )
  elif path.len == 0 and renderer.isNil:
    parent.children.add RouteNode(
      kind: routeKindSsrTerminal,
      cache: newTable[string,cstring](),
      useCache: useCache
    )
  elif path[0] == "*":
    # try to find an existing, identical node
    for sibling in parent.children.mitems:
      if sibling.kind == routeKindWildcard:
        sibling.addRouteInner(path[1..^1], renderer, useCache)
        return
    # create a new node
    var newNode = RouteNode(
      kind: routeKindWildcard
    )
    newNode.addRouteInner(path[1..^1], renderer, useCache)
    parent.children.add newNode
  elif path[0].startsWith('{'):
    let param = path[0][1..^2]
    # try to find an existing, identical node
    for sibling in parent.children.mitems:
      if sibling.kind == routeKindParameter and sibling.param == param:
        sibling.addRouteInner(path[1..^1], renderer, useCache)
        return
    # create a new node
    var newNode = RouteNode(
      kind: routeKindParameter,
      param: path[0][1..^2]
    )
    newNode.addRouteInner(path[1..^1], renderer, useCache)
    parent.children.add newNode
  else:
    # try to find an existing, identical node
    for sibling in parent.children.mitems:
      if sibling.kind == routeKindLiteralPath and sibling.part == path[0]:
        sibling.addRouteInner(path[1..^1], renderer, useCache)
        return
    # create a new node
    var newNode = RouteNode(
      kind: routeKindLiteralPath,
      part: path[0]
    )
    newNode.addRouteInner(path[1..^1], renderer, useCache)
    parent.children.add newNode

const PathChars = {'a'..'z', 'A'..'Z', '0'..'9', '-', '_', '.', '~', ':', '@', '!', '(', ')'}

proc parsePath(path: string): seq[string] =
  for part in path.split('/'):
    if part.len == 0: continue

    let partIsValid =
      part == "*" or
      part.startsWith('{') and part.endsWith('}') and part[1..^2].allCharsInSet(PathChars) or
      part.allCharsInSet(PathChars)

    if not partIsValid:
      raise ValueError.newException(fmt"Invalid router path component '{part}'")

    result.add part

proc addRoute*(router: Router, path: string, renderer: RouteRenderer) =
  ## Create a route.
  ## 
  ## The `path` string works the same way as many routers:
  ## 
  ## - Path parameters are specified using `{this}` syntax.
  ## - Wildcards are specified by an asterisk, and they match one path component.
  ## 
  ## Here are some examples of valid path strings:
  ## 
  ## - `"/"`
  ## - `"/profile/{userid}"`
  ## - `"/workspace/{workspace_id}/user/{user_id}"`
  ## - `"/thing/*"`
  ## 
  ## Support for wildcards will be added in the future.
  assert not renderer.isNil
  let parts = parsePath(path)
  addRouteInner(router.root, parts, renderer)

proc addSsrRoute*(router: Router, path: string, useCache=true) =
  ## Create an SSR route.
  ## 
  ## For info about paths, refer to the `addRoute<#addRoute,Router,string,RouteRenderer>`_.
  ## 
  ## When an SSR route is accessed, the router will send an AJAX request to the server.
  ## The response to the AJAX request should be HTML, which will then be rendered by
  ## the client. If this AJAX request should be re-sent every time the page is accessed,
  ## set `useCache` to false.
  ## 
  ## By default, the AJAX request will have the path `/ssr/{clientPath}`. This can be
  ## changed by providing a different value for `ssrPath` when calling `newRouter`.
  ## The AJAX request will include the client's anchor and query string.
  let parts = parsePath(path)
  addRouteInner(router.root, parts, useCache=useCache)

proc getSsrRequestUri(router: Router, ctx: Context): Uri =
  result = router.ssrBaseUri
  result.query = encodeQuery(ctx.query)
  result.path &= ctx.path
  result.anchor = ctx.anchor

proc kroutesRenderer(routerData: RouterData, router: Router): VNode =
  proc renderInner(node: RouteNode, path: seq[string], ctx: var Context): VNode =
    case node.kind:
    of routeKindRoot:
      for child in node.children:
        result = renderInner(child, path, ctx)
        if not result.isNil: return
    of routeKindLiteralPath:
      if path.len == 0 or node.part != path[0]:
        return nil
      else:
        for child in node.children:
          result = renderInner(child, path[1..^1], ctx)
          if not result.isNil: return
    of routeKindParameter:
      if path.len == 0:
        return nil
      else:
        ctx.params[node.param] = path[0]
        for child in node.children:
          result = renderInner(child, path[1..^1], ctx)
          if not result.isNil: return
    of routeKindWildcard:
      if path.len == 0:
        return nil
      else:
        for child in node.children:
          result = renderInner(child, path[1..^1], ctx)
          if not result.isNil: return
    of routeKindTerminal:
      if path.len == 0:
        return node.renderer(ctx)
      else:
        return nil
    of routeKindSsrTerminal:
      # TODO: there *must* be a more efficient approach to this.
      let url = $router.getSsrRequestUri(ctx)
      if node.cache.hasKey(url):
        result = verbatim(node.cache[url])
        if not node.useCache:
          echo "clearing: ", url
          node.cache.del url
      else:
        result = router.ssrLoading(ctx)
        var headers: seq[(cstring,cstring)]
        proc ajaxCallback(httpStatus: int, response: cstring) =
          node.cache[url] = response
          redraw()
        ajaxGet(url=cstring(url), headers=headers, doRedraw=false, cont=ajaxCallback)

  let href = parseUri($kdom.window.location.href)
  var pathParts: seq[string]
  for part in href.path.split('/'):
    if part.len == 0: continue
    pathParts.add part

  let query = collect:
    for q in href.query.decodeQuery():
      q

  var ctx = Context(
    params: newTable[string,string](),
    query: query,
    anchor: $routerData.hashPart,
    path: href.path
  )

  var content = renderInner(router.root, pathParts, ctx)
  if content.isNil:
    content = router.noMatchingRoute(ctx)

  result = router.rendererRoot(content, ctx)

proc setRenderer*(router: Router, root: cstring = "ROOT") =
  ## Set Karax's renderer to a `Router`. To use your `Router`, call this function
  ## instead of Karax's `setRouter` implementation.
  window.addEventListener(cstring("DOMContentLoaded")) do (_: Event):
    proc renderer(data: RouterData): VNode = kroutesRenderer(data, router)
    proc postRender(data: RouterData) = router.postRender()

    window.addEventListener(cstring("popstate")) do (ev: Event):
      redraw()

    setRenderer(
      renderer = renderer,
      root = root,
      clientPostRenderCallback = postRender
    )
