//// The static site generator entry point. Run with `gleam run -m build`
//// (matching lustre_ssg's own documented convention) -- reads
//// `decisions.jsonl` and `development-plan.md` (both fetched from
//// glemy's own repo before this runs; see
//// `.github/workflows/deploy.yml`) from the project root, and
//// `static/` (glemy's live demo build gets copied into
//// `static/play-demo/` by the same workflow, before this runs) as the
//// one static-assets directory lustre_ssg supports per build.
////
//// Erlang target, like `glemy`'s own `tools/decisions` CLI: a one-off
//// build script has no need for a browser/JS runtime, and `erlang.halt`
//// gives an honest non-zero exit code on failure -- important since
//// this runs as a CI step that must actually fail the deploy, not just
//// print an error and continue.
////
//// Reads `GLEMY_WEBSITE_BASE_URL` (see `website_env_ffi.erl`) once and
//// threads it through every page: GitHub Pages serves a project site
//// under a `/<repo-name>` subpath rather than the domain root, so
//// internal links/assets need that prefix to resolve correctly
//// (confirmed live -- see `layout.url`'s doc comment for the exact
//// 404 this fixes). The same value, being a full absolute URL, is also
//// exactly what canonical/OpenGraph tags and the sitemap/Atom feed need.

import gleam/dict
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glemy_website/decisions.{type Decision}
import glemy_website/feed
import glemy_website/pages/devlog
import glemy_website/pages/home
import glemy_website/pages/play
import glemy_website/pages/roadmap
import glemy_website/sitemap
import lustre/element
import lustre/ssg
import simplifile

pub fn main() -> Nil {
  case run() {
    Ok(Nil) -> {
      io.println("Build succeeded.")
      Nil
    }
    Error(reason) -> {
      io.println_error("Build failed: " <> reason)
      halt(1)
    }
  }
}

fn run() -> Result(Nil, String) {
  use decisions <- result.try(load_decisions())
  use plan_markdown <- result.try(load_development_plan())

  let by_id =
    dict.from_list(list.map(decisions, fn(decision) { #(decision.id, decision) }))
  let by_category = list.group(decisions, fn(decision) { decision.category })
  let base_url = env_base_url()

  ssg.new("./dist")
  |> ssg.add_static_dir("./static")
  |> ssg.add_static_route("/", home.view(base_url))
  |> ssg.add_static_route("/devlog", devlog.index(decisions, base_url))
  |> ssg.add_dynamic_route("/devlog", by_id, devlog.entry(_, base_url))
  |> ssg.add_dynamic_route(
    "/devlog/category",
    by_category,
    category_page(_, base_url),
  )
  |> ssg.add_static_route("/play", play.view(base_url))
  |> ssg.add_static_route("/roadmap", roadmap.view(base_url, plan_markdown))
  |> ssg.add_static_xml("/sitemap", sitemap.build(decisions, base_url))
  |> ssg.add_static_xml("/feed", feed.build(decisions, base_url))
  |> ssg.add_static_asset("/robots.txt", robots_txt(base_url))
  |> ssg.use_index_routes
  |> ssg.build
  |> result.map_error(fn(error) {
    "lustre_ssg build error: " <> string.inspect(error)
  })
}

/// `by_category`'s dict value is `List(Decision)`, not the category
/// name itself -- but every decision in that list shares the same
/// `.category` by construction of `list.group`, so the first entry's
/// field is the category name. `list.group` never produces an empty
/// value list (a key only exists once something mapped to it), so this
/// case is exhaustive.
fn category_page(entries: List(Decision), base_url: String) -> element.Element(
  Nil,
) {
  let assert [first, ..] = entries
  devlog.category_page(first.category, entries, base_url)
}

fn robots_txt(base_url: String) -> String {
  "User-agent: *\nAllow: /\n\nSitemap: " <> base_url <> "/sitemap.xml\n"
}

fn load_decisions() -> Result(List(Decision), String) {
  use contents <- result.try(
    simplifile.read("./decisions.jsonl")
    |> result.map_error(fn(error) {
      "could not read decisions.jsonl: " <> string.inspect(error)
    }),
  )
  decisions.parse_all(contents)
}

fn load_development_plan() -> Result(String, String) {
  simplifile.read("./development-plan.md")
  |> result.map_error(fn(error) {
    "could not read development-plan.md: " <> string.inspect(error)
  })
}

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

/// See `website_env_ffi.erl` and `layout.url` for why this exists.
@external(erlang, "website_env_ffi", "base_url")
fn env_base_url() -> String
