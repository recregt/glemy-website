//// Reads glemy's own `docs/decisions.jsonl` (fetched into this repo at
//// build time — see `.github/workflows/deploy.yml` — as
//// `decisions.jsonl` at the project root) for the devlog page.
////
//// Deliberately a *separate, simpler* decoder from glemy's own
//// `tools/decisions/src/decisions/schema.gleam`, not a shared/vendored
//// copy of it: that schema exists to make a `Decision` value
//// impossible to construct except through real validation (a strict
//// `Id`, a real calendar `Date`, no way to get a value past the
//// decoder without every field present and well-typed) — the right
//// job for a tool that *writes* new entries. This module only ever
//// *reads* already-written, already-valid entries to render them, so
//// `id`/`date`/`status`/`verdict` stay plain `String`s here rather than
//// pulling in glemy's own opaque `Id`/`Date` types (which aren't
//// published anywhere this repo could depend on without vendoring
//// them) — a decode failure on genuinely malformed JSON still fails
//// the site build loudly, which is the property that actually matters
//// for a read-only consumer.

import gleam/dynamic/decode.{type Decoder}
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string

pub type ConsideredOption {
  ConsideredOption(option: String, verdict: String, reason: String)
}

pub type Decision {
  Decision(
    id: String,
    date: String,
    title: String,
    status: String,
    category: String,
    tags: List(String),
    context: String,
    options_considered: List(ConsideredOption),
    decision: String,
    verification: String,
    consequences: String,
    supersedes: Option(String),
    superseded_by: Option(String),
    references: List(String),
  )
}

fn considered_option_decoder() -> Decoder(ConsideredOption) {
  use option <- decode.field("option", decode.string)
  use verdict <- decode.field("verdict", decode.string)
  use reason <- decode.field("reason", decode.string)
  decode.success(ConsideredOption(option:, verdict:, reason:))
}

fn decision_decoder() -> Decoder(Decision) {
  use id <- decode.field("id", decode.string)
  use date <- decode.field("date", decode.string)
  use title <- decode.field("title", decode.string)
  use status <- decode.field("status", decode.string)
  use category <- decode.field("category", decode.string)
  use tags <- decode.field("tags", decode.list(decode.string))
  use context <- decode.field("context", decode.string)
  use options_considered <- decode.field(
    "options_considered",
    decode.list(considered_option_decoder()),
  )
  use decision <- decode.field("decision", decode.string)
  use verification <- decode.field("verification", decode.string)
  use consequences <- decode.field("consequences", decode.string)
  use supersedes <- decode.field("supersedes", decode.optional(decode.string))
  use superseded_by <- decode.field(
    "superseded_by",
    decode.optional(decode.string),
  )
  use references <- decode.field("references", decode.list(decode.string))
  decode.success(Decision(
    id:,
    date:,
    title:,
    status:,
    category:,
    tags:,
    context:,
    options_considered:,
    decision:,
    verification:,
    consequences:,
    supersedes:,
    superseded_by:,
    references:,
  ))
}

/// Parses one JSONL line into a `Decision`. `docs/decisions.jsonl` is
/// one compact-JSON object per line (see glemy's own
/// `tools/decisions/src/decisions/schema.gleam`'s `to_jsonl_line`,
/// which is what actually produced every line this ever reads), so
/// splitting on newlines and decoding each independently is exactly
/// right — there's no enclosing array to parse instead.
pub fn parse_line(line: String) -> Result(Decision, String) {
  json.parse(line, decision_decoder())
  |> result.map_error(fn(error) {
    "malformed decision entry: " <> string.inspect(error)
  })
}

/// Parses a whole `decisions.jsonl` file's contents, newest decision
/// first (the order a devlog should read in) — the file itself is
/// append-only in ID order, so reversing it is enough, no separate sort
/// needed. Fails on the *first* malformed line rather than silently
/// skipping it: a corrupt devlog entry is a build-time bug worth
/// stopping on, not something to render around.
pub fn parse_all(contents: String) -> Result(List(Decision), String) {
  contents
  |> string.split("\n")
  |> list.filter(fn(line) { line != "" })
  |> list.try_map(parse_line)
  |> result.map(list.reverse)
}
