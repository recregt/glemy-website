//// The live demo page. Embeds glemy's own real build output (copied
//// into the site's static assets at `/play-demo/` -- see
//// `.github/workflows/deploy.yml`) via an iframe, rather than trying to
//// reconstruct glemy's own `index.html`/canvas setup as Lustre markup:
//// the demo is its own genuinely self-contained HTML document (own
//// script tags, own WebGPU canvas), and duplicating that structure
//// here would just be a second place for it to drift out of sync with
//// glemy's real `index.html`.

import gleam/list
import glemy_website/layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view() -> Element(a) {
  html.html([attribute.lang("en")], [
    html.head(
      [],
      list.append(
        layout.common_head_tags(
          "Play",
          "Play glemy's current preview live, right in your browser.",
        ),
        [
          html.link([attribute.rel("stylesheet"), attribute.href("/style.css")]),
          layout.favicon(),
        ],
      ),
    ),
    html.body([], [
      html.header([attribute.class("site-header")], [
        html.nav([attribute.class("site-nav")], [
          html.a([attribute.href("/"), attribute.class("site-brand")], [
            html.text("glemy"),
          ]),
          html.div([attribute.class("site-nav-links")], [
            html.a([attribute.href("/")], [html.text("Home")]),
            html.a([attribute.href("/devlog")], [html.text("Devlog")]),
            html.a(
              [attribute.href("/play-demo/index.html"), attribute.target("_blank")],
              [html.text("Open in new tab ↗")],
            ),
          ]),
        ]),
      ]),
      html.main([attribute.class("site-main play-main")], [
        html.h1([], [html.text("Play the current preview")]),
        html.p([], [
          html.text(
            "This is glemy's own real build, running live — a Suika-style merge puzzler, the current proving ground for the engine's physics and rendering. Requires a browser with WebGPU support.",
          ),
        ]),
        html.iframe([
          attribute.class("play-frame"),
          attribute.src("/play-demo/index.html"),
          attribute.attribute("loading", "lazy"),
        ]),
      ]),
    ]),
  ])
}
