//// The static site generator entry point. Run with `gleam run -m build`
//// (matching lustre_ssg's own documented convention) -- reads
//// `decisions.jsonl` (fetched from glemy's own repo before this runs;
//// see `.github/workflows/deploy.yml`) from the project root, and
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
//// Reads `GLEMY_WEBSITE_BASE_PATH` (see `website_env_ffi.erl`) once and
//// threads it through every page: GitHub Pages serves a project site
//// under a `/<repo-name>` subpath rather than the domain root, so
//// root-relative links/assets need that prefix to resolve correctly
//// (confirmed live -- see `layout.url`'s doc comment for the exact
//// 404 this fixes).

import gleam/dict
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import glemy_website/decisions.{type Decision}
import glemy_website/pages/devlog
import glemy_website/pages/home
import glemy_website/pages/play
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

  let by_id =
    dict.from_list(list.map(decisions, fn(decision) { #(decision.id, decision) }))
  let base_path = env_base_path()

  ssg.new("./dist")
  |> ssg.add_static_dir("./static")
  |> ssg.add_static_route("/", home.view(base_path))
  |> ssg.add_static_route("/devlog", devlog.index(decisions, base_path))
  |> ssg.add_dynamic_route("/devlog", by_id, devlog.entry(_, base_path))
  |> ssg.add_static_route("/play", play.view(base_path))
  |> ssg.use_index_routes
  |> ssg.build
  |> result.map_error(fn(error) {
    "lustre_ssg build error: " <> string.inspect(error)
  })
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

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

/// See `website_env_ffi.erl` and `layout.url` for why this exists.
@external(erlang, "website_env_ffi", "base_path")
fn env_base_path() -> String
