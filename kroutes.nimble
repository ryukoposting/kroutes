# Package

version       = "0.1.1"
author        = "Evan Perry Grove"
description   = "Karax router with CSR and SSR support"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.10"
requires "karax >= 1.2.2"

task demo, "Run demo app":
  withDir "demo":
    exec "nim js -o:public/app.nim.js app"
    exec "nim c -r server"

task docgen, "Generate docs":
  rmDir "htmldocs"
  exec "nim doc --project --backend:js --index:on --outdir:htmldocs --git.url:https://github.com/ryukoposting/kroutes --git.commit:master src/kroutes.nim"

task docserve, "Serve docs":
  exec "python -m http.server 7029 --directory htmldocs"
