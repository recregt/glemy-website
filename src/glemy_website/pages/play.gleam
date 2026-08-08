//// The live demo page. Embeds glemy's own real build output (copied
//// into the site's static assets at `/play-demo/` -- see
//// `.github/workflows/deploy.yml`) via an iframe, rather than trying to
//// reconstruct glemy's own `index.html`/canvas setup as Lustre markup:
//// the demo is its own genuinely self-contained HTML document (own
//// script tags, own WebGPU canvas), and duplicating that structure
//// here would just be a second place for it to drift out of sync with
//// glemy's real `index.html`.

import glemy_website/layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(base_url: String) -> Element(a) {
  layout.page(
    base_url: base_url,
    path: "/play",
    title: "Play",
    description: "Play glemy's current preview live, right in your browser.",
    content: [
      html.section([attribute.class("play-main")], [
        html.h1([], [html.text("Play the current preview")]),
        html.p([], [
          html.text(
            "This is glemy's own real build, running live — a Suika-style merge puzzler, the current proving ground for the engine's physics and rendering. Requires a browser with WebGPU support.",
          ),
        ]),
        html.iframe([
          attribute.class("play-frame"),
          attribute.src(layout.url(base_url, "/play-demo/index.html")),
          attribute.attribute("loading", "lazy"),
        ]),
        html.p([attribute.class("play-open-tab")], [
          html.a(
            [
              attribute.href(layout.url(base_url, "/play-demo/index.html")),
              attribute.target("_blank"),
            ],
            [html.text("Open in new tab ↗")],
          ),
        ]),
      ]),
    ],
  )
}
