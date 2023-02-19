## Utilities for server-side rendering.
## 
## The `goTo`, `goBack`, and `goForward` procs in this module will return a
## string of JS code that calls the corresponding `goTo`, `goBack`, and `goForward`
## procs on the client. This is useful if your server-rendered HTML needs to use
## event handlers.
## 

import std/strutils
import std/unicode

proc quoteJs(result: var string, s: string) =
  result &= '\''
  for r in runes(s):
    if size(r) == 1:
      let ch = char(int(r))
      case ch:
      of '\0':
        result &= "\\0"
      of '\'':
        result &= "\\'"
      of '\\':
        result &= "\\\\"
      of '\n':
        result &= "\\n"
      of '\r':
        result &= "\\r"
      of '\v':
        result &= "\\v"
      of '\t':
        result &= "\\t"
      of '\b':
        result &= "\\b"
      of '\f':
        result &= "\\f"
      of '\x20'..'\x26', '\x28'..'\x5b', '\x5d'..'\x7e':
        result &= ch
      else:
        result &= "\\x"
        result &= toHex(int(r), 2)
    elif size(r) == 2:
      result &= "\\u"
      result &= toHex(int(r), 4)
    else:
      result &= "\\u{"
      result &= toHex(int(r), size(r) * 2)
      result &= '}'
  result &= '\''

proc goTo*(path: string): string =
  ## Returns JS code that calls the KRoutes `goTo` proc.
  result = newStringOfCap(path.len() + 15)
  result &= "kroutesGoTo("
  result.quoteJs(path)
  result &= ')'

proc goBack*(n = 1): string =
  ## Returns JS code that calls the KRoutes `goBack` proc.
  result = newStringOfCap(abs(n div 10) + 15)
  result &= "kroutesGoBack("
  result &= $n
  result &= ')'

proc goForward*(n = 1): string =
  ## Returns JS code that calls the KRoutes `goForward` proc.
  result = newStringOfCap(abs(n div 10) + 18)
  result &= "kroutesGoForward("
  result &= $n
  result &= ')'
