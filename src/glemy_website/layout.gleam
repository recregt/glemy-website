//// The shared page shell every page renders through: `<html>`/`<head>`
//// boilerplate, nav, footer. One place to change site-wide chrome
//// rather than every page repeating it.

import gleam/list
import gleam/uri
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/ssg/opengraph

/// Wraps `content` in the full HTML document -- `<!doctype html>` is
/// added by `lustre/element`'s own `to_document_string` at the point
/// each page is actually rendered to a file (see `build.gleam`), not
/// here.
///
/// `base_url` prefixes every link/asset URL this page emits, and
/// `path` is this page's own route (e.g. `/devlog/0041.html`) --
/// together they're `url(base_url, path)` (see below), used both for
/// internal navigation and for this page's canonical/OpenGraph URL.
pub fn page(
  base_url base_url: String,
  path path: String,
  title title: String,
  description description: String,
  content content: List(Element(a)),
) -> Element(a) {
  html.html([attribute.lang("en")], [
    html.head(
      [],
      list.append(common_head_tags(base_url, path, title, description), [
        html.link([
          attribute.rel("stylesheet"),
          attribute.href(url(base_url, "/style.css")),
        ]),
        favicon(),
      ]),
    ),
    html.body([], [
      nav(base_url),
      html.main([attribute.class("site-main")], content),
      footer(),
    ]),
  ])
}

/// Prefixes `path` (always starting with `/`) with `base_url`. Every
/// internal link/asset in this site goes through this, using a fully
/// *absolute* URL rather than a root-relative one (`href="/style.css"`)
/// -- needed because GitHub Pages serves a project site (one not on its
/// own custom domain) under a `/<repo-name>` subpath rather than the
/// domain root, so a root-relative href resolves against
/// `https://recregt.github.io/`, not
/// `https://recregt.github.io/glemy-website/`, and 404s (confirmed
/// live: `curl -o /dev/null -w '%{http_code}'
/// https://recregt.github.io/style.css` returned 404, the
/// `/glemy-website/style.css` equivalent 200). Using the same absolute
/// `base_url` everywhere also means it's already exactly what
/// canonical/OpenGraph tags and the sitemap/Atom feed need -- no second
/// "is this an internal link or an SEO tag" distinction to maintain.
/// `base_url` is read once at build time in `build.gleam` from the
/// `GLEMY_WEBSITE_BASE_URL` env var (see `website_env_ffi.erl`) --
/// empty for local dev (falls back to plain root-relative paths, still
/// correct there), `actions/configure-pages`' own `base_url` output
/// (e.g. `https://recregt.github.io/glemy-website`) in CI.
pub fn url(base_url: String, path: String) -> String {
  base_url <> path
}

/// The `<meta charset>`/viewport/description/title/canonical/OpenGraph
/// tags every page needs, `/play` (which builds its own full document
/// rather than going through `page` above -- see that module's own doc
/// comment) included. Doesn't include the stylesheet `<link>` or
/// `favicon()`: `page` always wants both, but keeping them separate
/// here means a future page with different needs isn't forced to take
/// them too.
pub fn common_head_tags(
  base_url: String,
  path: String,
  title: String,
  description: String,
) -> List(Element(a)) {
  let full_title = title <> " — glemy"
  let canonical = url(base_url, path)
  // `opengraph.url` wants a parsed `Uri`, not a raw string. `uri.parse`
  // is permissive enough to never fail on a well-formed absolute URL or
  // a plain root-relative path (the local-dev / empty-`base_url` case),
  // so an assert here is the same "malformed build input should fail
  // loudly" stance the rest of this build script already takes.
  let assert Ok(canonical_uri) = uri.parse(canonical)
  [
    html.meta([attribute.charset("utf-8")]),
    html.meta([
      attribute.name("viewport"),
      attribute.content("width=device-width, initial-scale=1"),
    ]),
    html.meta([attribute.name("description"), attribute.content(description)]),
    html.title([], full_title),
    html.link([attribute.rel("canonical"), attribute.href(canonical)]),
    html.link([
      attribute.rel("alternate"),
      attribute.type_("application/atom+xml"),
      attribute.title("glemy devlog"),
      attribute.href(url(base_url, "/feed.xml")),
    ]),
    opengraph.site_name("glemy"),
    opengraph.title(full_title),
    opengraph.description(description),
    opengraph.website(),
    opengraph.url(canonical_uri),
    html.meta([
      attribute.name("twitter:card"),
      attribute.content("summary"),
    ]),
    html.meta([attribute.name("twitter:title"), attribute.content(full_title)]),
    html.meta([
      attribute.name("twitter:description"),
      attribute.content(description),
    ]),
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

fn nav(base_url: String) -> Element(a) {
  html.header([attribute.class("site-header")], [
    html.nav([attribute.class("site-nav")], [
      html.a([attribute.href(url(base_url, "/")), attribute.class("site-brand")], [
        html.text("glemy"),
      ]),
      html.div([attribute.class("site-nav-links")], [
        html.a([attribute.href(url(base_url, "/"))], [html.text("Home")]),
        html.a([attribute.href(url(base_url, "/devlog"))], [html.text("Devlog")]),
        html.a([attribute.href(url(base_url, "/roadmap"))], [html.text("Roadmap")]),
        html.a([attribute.href(url(base_url, "/play"))], [html.text("Games")]),
        html.a([attribute.href("https://github.com/recregt/glemy")], [
          html.text("GitHub"),
        ]),
      ]),
    ]),
  ])
}

fn footer() -> Element(a) {
  html.footer([attribute.class("site-footer")], [
    html.p([attribute.class("site-footer-tagline")], [
      html.text("One engine. Every genre. Nothing hidden."),
    ]),
    html.p([], [
      html.text("Every decision — including the "),
      html.a([attribute.href("https://github.com/recregt/glemy/blob/main/docs/decisions.jsonl")], [
        html.text("ones that didn't work"),
      ]),
      html.text(" — is public on the "),
      html.a([attribute.href("https://github.com/recregt/glemy")], [
        html.text("Devlog"),
      ]),
      html.text(". No closed roadmap, no surprise pivots."),
    ]),
  ])
}
