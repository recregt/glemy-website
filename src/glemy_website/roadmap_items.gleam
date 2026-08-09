//// Reads glemy's own `docs/development-plan.jsonl` (fetched into this
//// repo at build time — see `.github/workflows/deploy.yml` — as
//// `development-plan.jsonl` at the project root) for the roadmap page.
////
//// Deliberately a *separate, simpler* decoder from a hypothetical
//// stricter writer-side schema, matching the same reasoning
//// `glemy_website/decisions` already documents: this module only ever
//// *reads* already-written, already-valid entries to render them, so
//// every field stays a plain `String`/`Int` rather than an opaque
//// validated type — a decode failure on genuinely malformed JSON still
//// fails the site build loudly, which is the property that actually
//// matters for a read-only consumer.

import gleam/dynamic/decode.{type Decoder}
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string

pub type RoadmapItem {
  RoadmapItem(
    id: String,
    phase: Int,
    phase_title: String,
    title: String,
    status: String,
    description: String,
    resolution: Option(String),
    decision_refs: List(String),
    doc_refs: List(String),
  )
}

fn roadmap_item_decoder() -> Decoder(RoadmapItem) {
  use id <- decode.field("id", decode.string)
  use phase <- decode.field("phase", decode.int)
  use phase_title <- decode.field("phase_title", decode.string)
  use title <- decode.field("title", decode.string)
  use status <- decode.field("status", decode.string)
  use description <- decode.field("description", decode.string)
  use resolution <- decode.field("resolution", decode.optional(decode.string))
  use decision_refs <- decode.field(
    "decision_refs",
    decode.list(decode.string),
  )
  use doc_refs <- decode.field("doc_refs", decode.list(decode.string))
  decode.success(RoadmapItem(
    id:,
    phase:,
    phase_title:,
    title:,
    status:,
    description:,
    resolution:,
    decision_refs:,
    doc_refs:,
  ))
}

/// Parses one JSONL line into a `RoadmapItem`. `docs/development-plan.jsonl`
/// is one compact-JSON object per line, hand-written directly against
/// the schema documented in glemy's own `docs/development-plan.md` (no
/// writer-side CLI tool exists for this file yet), so splitting on
/// newlines and decoding each independently is exactly right — there's
/// no enclosing array to parse instead.
pub fn parse_line(line: String) -> Result(RoadmapItem, String) {
  json.parse(line, roadmap_item_decoder())
  |> result.map_error(fn(error) {
    "malformed roadmap item: " <> string.inspect(error)
  })
}

/// Parses a whole `development-plan.jsonl` file's contents, in the
/// file's own written order (`id` order — the roadmap page groups by
/// phase and doesn't need a different sort). Fails on the *first*
/// malformed line rather than silently skipping it: a corrupt roadmap
/// entry is a build-time bug worth stopping on, not something to
/// render around.
pub fn parse_all(contents: String) -> Result(List(RoadmapItem), String) {
  contents
  |> string.split("\n")
  |> list.filter(fn(line) { line != "" })
  |> list.try_map(parse_line)
}
