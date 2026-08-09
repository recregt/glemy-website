//// The static site generator entry point. Run with `gleam run -m build`
//// (matching lustre_ssg's own documented convention) -- reads
//// `decisions.jsonl` and `development-plan.jsonl` (both fetched from
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

import gleam/bit_array
import gleam/dict
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glemy_website/asset_hash
import glemy_website/decisions.{type Decision}
import glemy_website/feed
import glemy_website/game_card
import glemy_website/pages/devlog
import glemy_website/pages/home
import glemy_website/pages/play
import glemy_website/pages/roadmap
import glemy_website/roadmap_items.{type RoadmapItem}
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
  use roadmap_entries <- result.try(load_roadmap_items())
  use #(style_hash, style_content) <- result.try(load_style_asset())
  use stable_path <- result.try(prepare_play_demo_dir("play-demo-stable"))
  use edge_path <- result.try(prepare_play_demo_dir("play-demo-edge"))

  let by_id =
    dict.from_list(list.map(decisions, fn(decision) { #(decision.id, decision) }))
  let by_category = list.group(decisions, fn(decision) { decision.category })
  let base_url = env_base_url()
  let style_filename = asset_hash.hashed_filename("style.css", style_hash)
  let demo = game_card.DemoPaths(stable: stable_path, edge: edge_path)

  ssg.new("./dist")
  |> ssg.add_static_dir("./static")
  |> ssg.add_static_asset("/" <> style_filename, style_content)
  |> ssg.add_static_route("/", home.view(base_url, style_hash, demo))
  |> ssg.add_static_route(
    "/devlog",
    devlog.index(decisions, base_url, style_hash),
  )
  |> ssg.add_dynamic_route("/devlog", by_id, devlog.entry(_, base_url, style_hash))
  |> ssg.add_dynamic_route(
    "/devlog/category",
    by_category,
    category_page(_, base_url, style_hash),
  )
  |> ssg.add_static_route("/play", play.view(base_url, style_hash, demo))
  |> ssg.add_static_route(
    "/roadmap",
    roadmap.view(base_url, roadmap_entries, style_hash),
  )
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
fn category_page(
  entries: List(Decision),
  base_url: String,
  style_hash: String,
) -> element.Element(Nil) {
  let assert [first, ..] = entries
  devlog.category_page(first.category, entries, base_url, style_hash)
}

/// Reads `assets/style.css` (the committed source -- not `static/`,
/// which `add_static_dir` copies verbatim under its existing name; this
/// file needs to be published under a *different*, content-derived
/// name instead, so it can't live somewhere that would also get copied
/// under its original one) and returns its content hash alongside its
/// content, so both the filename (`asset_hash.hashed_filename`) and the
/// actual published bytes come from the same read.
fn load_style_asset() -> Result(#(String, String), String) {
  use content <- result.try(
    simplifile.read("./assets/style.css")
    |> result.map_error(fn(error) {
      "could not read assets/style.css: " <> string.inspect(error)
    }),
  )
  Ok(#(asset_hash.hash(bit_array.from_string(content)), content))
}

/// Content-hashes one of glemy's real build outputs (copied into
/// `static/<base_name>/` before this runs, e.g.
/// `static/play-demo-stable/` or `static/play-demo-edge/` -- see
/// `.github/workflows/deploy.yml`, RM-025) as one unit, renaming the
/// whole directory to `static/<base_name>-<hash>/` rather than hashing
/// each file inside it individually: this is a bundler-free, raw-ESM
/// build (decision 0003) whose files import each other by relative
/// path, so renaming files individually would break those imports,
/// while renaming the *directory* they're all already inside changes
/// nothing about how they refer to each other. Returns the published
/// path segment (e.g. `/play-demo-stable-a1b2c3d4`) for `game_card` to
/// build real links from.
///
/// Tolerant of the demo not being freshly copied in this run: if
/// `static/<base_name>` (the unhashed name the copy step always uses)
/// no longer exists -- already renamed by a prior local build that
/// reused the same `static/` directory without recopying -- this looks
/// for whatever `<base_name>-*` directory is already there instead of
/// failing, and falls back to the plain, unhashed `/<base_name>` if
/// neither exists at all (a partial local build not exercising the
/// live demo shouldn't fail the whole site build over it -- the link
/// simply 404s until the demo is actually copied in, matching this
/// project's behavior before content-hashing existed).
fn prepare_play_demo_dir(base_name: String) -> Result(String, String) {
  let unhashed_dir = "./static/" <> base_name
  case simplifile.is_directory(unhashed_dir) {
    Ok(True) -> {
      use files <- result.try(
        simplifile.get_files(in: unhashed_dir)
        |> result.map_error(fn(error) {
          "could not list static/" <> base_name <> ": " <> string.inspect(error)
        }),
      )
      use contents <- result.try(
        list.sort(files, string.compare)
        |> list.try_map(fn(path) {
          simplifile.read_bits(path)
          |> result.map_error(fn(error) {
            "could not read " <> path <> ": " <> string.inspect(error)
          })
        }),
      )
      let hash = asset_hash.hash(bit_array.concat(contents))
      let hashed_dir = "./static/" <> base_name <> "-" <> hash
      use _ <- result.try(
        simplifile.rename(at: unhashed_dir, to: hashed_dir)
        |> result.map_error(fn(error) {
          "could not rename static/"
          <> base_name
          <> " to "
          <> hashed_dir
          <> ": "
          <> string.inspect(error)
        }),
      )
      Ok("/" <> base_name <> "-" <> hash)
    }
    _ -> Ok(discover_or_default_play_demo_path(base_name))
  }
}

fn discover_or_default_play_demo_path(base_name: String) -> String {
  case simplifile.read_directory("./static") {
    Ok(entries) ->
      case list.find(entries, string.starts_with(_, base_name <> "-")) {
        Ok(name) -> "/" <> name
        Error(_) -> "/" <> base_name
      }
    Error(_) -> "/" <> base_name
  }
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

fn load_roadmap_items() -> Result(List(RoadmapItem), String) {
  use contents <- result.try(
    simplifile.read("./development-plan.jsonl")
    |> result.map_error(fn(error) {
      "could not read development-plan.jsonl: " <> string.inspect(error)
    }),
  )
  roadmap_items.parse_all(contents)
}

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

/// See `website_env_ffi.erl` and `layout.url` for why this exists.
@external(erlang, "website_env_ffi", "base_url")
fn env_base_url() -> String
