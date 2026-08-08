//// The shared page shell every page renders through: `<html>`/`<head>`
//// boilerplate, nav, footer. One place to change site-wide chrome
//// rather than every page repeating it.

import gleam/list
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

/// Wraps `content` in the full HTML document -- `<!doctype html>` is
/// added by `lustre/element`'s own `to_document_string` at the point
/// each page is actually rendered to a file (see `build.gleam`), not
/// here.
pub fn page(
  title title: String,
  description description: String,
  content content: List(Element(a)),
) -> Element(a) {
  html.html([attribute.lang("en")], [
    html.head(
      [],
      list.append(common_head_tags(title, description), [
        html.link([attribute.rel("stylesheet"), attribute.href("/style.css")]),
        favicon(),
      ]),
    ),
    html.body([], [nav(), html.main([attribute.class("site-main")], content), footer()]),
  ])
}

/// The `<meta charset>`/viewport/description/title tags every page
/// needs, `/play` (which builds its own full document rather than
/// going through `page` above -- see that module's own doc comment)
/// included. Doesn't include the stylesheet `<link>` or `favicon()`:
/// `page` always wants both, but keeping them separate here means a
/// future page with different needs isn't forced to take them too.
pub fn common_head_tags(
  title: String,
  description: String,
) -> List(Element(a)) {
  [
    html.meta([attribute.charset("utf-8")]),
    html.meta([
      attribute.name("viewport"),
      attribute.content("width=device-width, initial-scale=1"),
    ]),
    html.meta([attribute.name("description"), attribute.content(description)]),
    html.title([], title <> " — glemy"),
  ]
}

/// A plain red circle, inlined as a data URI so there's no extra
/// network request or binary asset file for one favicon -- `href`'s
/// `<`/`>`/`"` characters are HTML-entity-escaped by Lustre when this
/// gets serialized (standard, correct behavior: the browser's HTML
/// parser decodes them back before treating the result as a URL).
pub fn favicon() -> Element(a) {
  html.link([
    attribute.rel("icon"),
    attribute.href(
      "data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><circle cx=%2250%22 cy=%2250%22 r=%2245%22 fill=%22%23e63946%22/></svg>",
    ),
  ])
}

fn nav() -> Element(a) {
  html.header([attribute.class("site-header")], [
    html.nav([attribute.class("site-nav")], [
      html.a([attribute.href("/"), attribute.class("site-brand")], [
        html.text("glemy"),
      ]),
      html.div([attribute.class("site-nav-links")], [
        html.a([attribute.href("/")], [html.text("Home")]),
        html.a([attribute.href("/devlog")], [html.text("Devlog")]),
        html.a([attribute.href("/play")], [html.text("Play")]),
        html.a([attribute.href("https://github.com/recregt/glemy")], [
          html.text("GitHub"),
        ]),
      ]),
    ]),
  ])
}

fn footer() -> Element(a) {
  html.footer([attribute.class("site-footer")], [
    html.p([], [
      html.text("glemy is built in the open — every decision, including the "),
      html.a([attribute.href("https://github.com/recregt/glemy/blob/main/docs/decisions.jsonl")], [
        html.text("ones that didn't work"),
      ]),
      html.text(", is on the "),
      html.a([attribute.href("https://github.com/recregt/glemy")], [
        html.text("Devlog"),
      ]),
      html.text("."),
    ]),
  ])
}
