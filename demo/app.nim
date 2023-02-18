include karax/prelude
import kroutes
import std/[strformat, tables, strutils, sugar]
import karax/localstorage

type MyRouter = ref object of Router

const LipsumKey = cstring("lipsum")
const Lipsum = [
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam at orci tellus. Nam ornare justo velit, id volutpat leo semper eget. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec sit amet metus id tortor varius rutrum vitae id metus. Donec porta imperdiet suscipit. Fusce sit amet rhoncus neque. Maecenas commodo sagittis tempor. Integer aliquam, tortor ac mattis varius, nisl quam pellentesque lacus, eget maximus quam sapien id nibh. Cras maximus, urna vitae iaculis ullamcorper, magna ipsum ullamcorper libero, in volutpat massa eros sodales orci. Pellentesque vehicula, diam nec venenatis dapibus, diam risus elementum tortor, sed dignissim purus leo vel leo.",
  "Praesent velit nisi, tincidunt in mollis et, laoreet ut nulla. Aliquam erat volutpat. Sed fermentum gravida nulla, eu aliquet quam vulputate id. Nullam laoreet accumsan lobortis. Aliquam mattis facilisis orci. Maecenas id sodales turpis. Nulla felis lacus, condimentum eu tellus sed, pellentesque lobortis elit. Mauris pretium risus quis enim vulputate, at viverra ipsum tincidunt. Fusce ac odio in metus pellentesque rhoncus. Nam a pulvinar diam, blandit pellentesque purus. Curabitur eros enim, consequat non fringilla eget, feugiat ut ipsum. Etiam eget mattis turpis, et mattis tellus. Fusce a dignissim odio. Aliquam molestie enim eget nunc blandit, id pretium lacus dapibus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Etiam convallis, odio in faucibus tempus, erat nunc mattis felis, finibus sodales massa nibh eget orci.",
  "Sed ultrices sed urna sed sagittis. Morbi eget tempus odio. Quisque commodo bibendum lacinia. Vestibulum fringilla lorem eu tellus dapibus, nec interdum purus sodales. Donec rutrum augue est, id interdum velit suscipit vulputate. Cras aliquam pulvinar est vel feugiat. Nulla pulvinar, nunc sit amet condimentum mattis, risus metus aliquet nibh, eu consectetur lacus augue eu tellus. Aliquam vel sem magna. Donec dictum varius sapien, non convallis massa rutrum in. In laoreet quis felis a viverra. Aliquam euismod varius pellentesque. Donec nisi purus, vestibulum aliquam urna sit amet, placerat dictum elit. Nunc consequat metus risus, vitae ornare lectus tempor id. Donec et porttitor dui. Donec lectus diam, finibus ac aliquet elementum, elementum nec orci.",
  "Aenean vel turpis vitae nisi venenatis ultrices eget non diam. Aliquam a pharetra elit. Quisque consectetur leo vel lorem mollis luctus. Proin quis tincidunt nulla. Sed commodo ac risus sit amet ultricies. Integer vestibulum, lacus tempus condimentum pretium, quam ex egestas quam, a imperdiet dolor velit id eros. Aenean sit amet eleifend eros. Ut nec sapien molestie, tincidunt sapien id, varius diam. Aenean tortor tortor, efficitur quis sodales a, pharetra nec turpis. Fusce at velit eros. Cras placerat nibh lectus, quis tincidunt nisl ullamcorper nec. Nulla vel libero nec erat luctus egestas. Nullam sed fermentum quam. Nullam at libero nulla. Maecenas at felis nisi.",
  "Nullam in elementum ante. Proin ut eleifend turpis. Quisque sollicitudin ornare ligula at auctor. Pellentesque blandit in nulla sed viverra. Sed rutrum lacus vitae magna vestibulum, maximus consequat magna venenatis. Phasellus a magna non nulla posuere commodo. Sed accumsan mauris venenatis nisi aliquet, eu pellentesque augue sodales. Sed id dolor dictum, mattis sem ac, dictum ex. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.",
  "Vivamus justo purus, tincidunt eget metus sed, porttitor molestie arcu. Donec vitae convallis arcu, feugiat maximus massa. Morbi sed congue erat. Aenean nunc nisl, placerat sed metus nec, aliquet consectetur elit. Phasellus euismod, ipsum et congue fermentum, orci odio condimentum arcu, nec lacinia odio mauris at nisi. Nullam ullamcorper imperdiet sapien, rutrum ornare tortor ornare eu. Mauris condimentum id ex sit amet dictum. Vivamus sit amet posuere tortor. Curabitur feugiat id nunc id eleifend. Cras non enim enim. Nullam venenatis ultrices sem, non suscipit mauris. Fusce lacus massa, lobortis quis vulputate eget, tempor a ipsum. Aenean libero lorem, venenatis vitae pretium in, aliquam eu nisl.",
  "Sed quis nunc posuere, tempor augue luctus, mollis nulla. Nam efficitur hendrerit massa vitae ornare. Vestibulum semper erat justo, ac facilisis neque fermentum fringilla. Nulla nec magna dignissim augue convallis lacinia vitae et ipsum. Maecenas et velit eu est pulvinar vehicula. In ante quam, porttitor nec porttitor id, varius sed turpis. Nulla gravida blandit pulvinar. Vivamus ac porta urna, a finibus nisl. Aliquam erat volutpat. Integer ornare orci in fermentum vulputate. Aenean ac turpis tristique orci rhoncus tempus vitae sagittis odio. Nullam rhoncus accumsan lobortis. Nunc convallis, arcu vitae volutpat tincidunt, felis sapien hendrerit ligula, id luctus nisl quam in dolor. Donec dignissim erat id lacus tincidunt eleifend. Donec bibendum, diam vitae consectetur egestas, ex dui ullamcorper lectus, id interdum libero velit ac ex. Curabitur laoreet pulvinar sapien, sit amet convallis urna accumsan in.",
  "Morbi quis tortor a dolor congue suscipit. Curabitur vitae elementum ex. Pellentesque pretium neque vel enim vehicula vehicula eu eget ante. Etiam diam turpis, molestie et efficitur porttitor, vehicula sit amet nibh. In luctus urna id mi sollicitudin ullamcorper. Pellentesque id finibus orci. Curabitur maximus odio in urna semper, eget lacinia augue consequat. Integer at sem sit amet sapien congue tristique.",
  "Vestibulum ligula mi, ultricies in pretium eget, molestie eget est. In quis tempor turpis, sed molestie tellus. Nullam velit sem, scelerisque quis finibus vitae, tristique vel nisi. Curabitur cursus sollicitudin rhoncus. Donec mollis felis sed sagittis facilisis. Nunc maximus leo eu tortor molestie viverra. Etiam at facilisis augue. Donec hendrerit risus vel lacinia consectetur. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Proin leo neque, auctor nec suscipit vitae, commodo sit amet odio. Fusce quis imperdiet erat. Donec posuere lacus eu lacinia pellentesque. Nulla dictum velit et mi laoreet, nec mattis mi bibendum. Ut in scelerisque purus. Mauris fermentum interdum diam, ac aliquet odio commodo a. Mauris vel pellentesque est, a elementum risus.",
  "Vestibulum quis tortor nibh. Ut molestie diam et pharetra auctor. Curabitur in leo dapibus, interdum leo sit amet, porttitor nulla. In hac habitasse platea dictumst. Maecenas ac sapien sed velit ultrices dignissim. Aenean fermentum justo a sapien tincidunt sollicitudin. In tempor, sapien faucibus laoreet blandit, arcu urna dignissim quam, id bibendum ipsum ipsum nec velit. Vestibulum dignissim quam et libero accumsan dictum. "
]

proc getLipsum: int =
  if not hasItem(LipsumKey):
    setItem(LipsumKey, cstring("0"))
  result = parseInt(getItem(LipsumKey))

proc lipsumUp =
  let x = getLipsum()
  if x < high(Lipsum):
    setItem(LipsumKey, cstring($(x + 1)))

proc lipsumDown =
  let x = getLipsum()
  if x > low(Lipsum):
    setItem(LipsumKey, cstring($(x - 1)))

method rendererRoot*(router: MyRouter, content: VNode, ctx: Context): VNode =
  buildHtml(body):
    header:
      h1: text fmt"KRouter Demo"
      nav:
        button(onclick = goto("/")):
          text "Home"
        button(onclick = goto("/about")):
          text "About"
    content
    footer:
      p: text "Copyright (c) 2023 Evan Perry Grove"

let app = newRouter(MyRouter)

app.addRoute("/") do (ctx: Context) -> VNode:
  let lipsumText = Lipsum[getLipsum()]
  buildHtml(main):
    h1:
      text "Lorem Ipsum"
    p:
      text lipsumText
    tdiv(class="next-prev-buttons"):
      button(onclick = () => lipsumDown()):
        text "Previous"
      p:
        text fmt"{getLipsum() + 1} / {len(Lipsum)}"
      button(onclick = () => lipsumUp()):
        text "Next"

app.addSsrRoute("/about")

setRenderer(app)
