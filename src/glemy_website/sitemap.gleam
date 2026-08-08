//// Builds `/sitemap.xml` (see `build.gleam`) from the site's real,
//// already-known route list -- every URL here corresponds to an actual
//// page `build.gleam` generates, kept in the same place so the two
//// can't silently drift apart.

import gleam/list
import glemy_website/decisions.{type Decision}
import glemy_website/pages/devlog
import lustre/attribute
import lustre/element.{type Element, element}

pub fn build(decisions: List(Decision), base_url: String) -> Element(a) {
  let categories =
    decisions
    |> list.map(fn(decision) { decision.category })
    |> list.unique

  let static_paths = ["/", "/devlog", "/play", "/roadmap"]
  let decision_paths = list.map(decisions, devlog.entry_path)
  let category_paths = list.map(categories, devlog.category_path)

  let urls = list.flatten([static_paths, decision_paths, category_paths])

  element(
    "urlset",
    [attribute.attribute("xmlns", "http://www.sitemaps.org/schemas/sitemap/0.9")],
    list.map(urls, fn(path) { url(base_url <> path) }),
  )
}

fn url(loc: String) -> Element(a) {
  element("url", [], [element("loc", [], [element.text(loc)])])
}
