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
///
/// `base_path` prefixes every root-relative link/asset URL this page
/// emits -- see `url` below for why that's needed at all.
pub fn page(
  base_path base_path: String,
  title title: String,
  description description: String,
  content content: List(Element(a)),
) -> Element(a) {
  html.html([attribute.lang("en")], [
    html.head(
      [],
      list.append(common_head_tags(title, description), [
        html.link([
          attribute.rel("stylesheet"),
          attribute.href(url(base_path, "/style.css")),
        ]),
        favicon(),
      ]),
    ),
    html.body([], [
      nav(base_path),
      html.main([attribute.class("site-main")], content),
      footer(),
    ]),
  ])
}

/// Prefixes a root-relative `path` (always starting with `/`) with
/// `base_path`. Needed because GitHub Pages serves a project site (one
/// not on its own custom domain) under a `/<repo-name>` subpath rather
/// than the domain root -- a root-relative `href="/style.css"` resolves
/// against `https://recregt.github.io/`, not
/// `https://recregt.github.io/glemy-website/`, and 404s (confirmed live:
/// `curl -o /dev/null -w '%{http_code}' https://recregt.github.io/style.css`
/// returned 404, the `/glemy-website/style.css` equivalent 200).
/// `base_path` is read once at build time in `build.gleam` from the
/// `GLEMY_WEBSITE_BASE_PATH` env var (see `website_env_ffi.erl`) --
/// empty for local dev and any future custom domain, `/glemy-website`
/// for the current GitHub Pages URL.
pub fn url(base_path: String, path: String) -> String {
  base_path <> path
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

fn nav(base_path: String) -> Element(a) {
  html.header([attribute.class("site-header")], [
    html.nav([attribute.class("site-nav")], [
      html.a([attribute.href(url(base_path, "/")), attribute.class("site-brand")], [
        html.text("glemy"),
      ]),
      html.div([attribute.class("site-nav-links")], [
        html.a([attribute.href(url(base_path, "/"))], [html.text("Home")]),
        html.a([attribute.href(url(base_path, "/devlog"))], [html.text("Devlog")]),
        html.a([attribute.href(url(base_path, "/play"))], [html.text("Play")]),
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
