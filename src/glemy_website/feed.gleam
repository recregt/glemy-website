//// Builds the devlog's Atom feed (`/feed.xml`, see `build.gleam`) from
//// the same real `Decision` list the devlog pages themselves render --
//// same "one real source of truth" pattern as everything else in this
//// module, not a separately maintained feed.

import gleam/list
import glemy_website/decisions.{type Decision}
import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/ssg/atom

/// Most recently updated decision first, same order the source data is
/// already in -- Atom feeds are conventionally capped to a recent
/// window, not the entire history (`decisions.jsonl` has 41 entries and
/// growing).
const entry_limit = 20

pub fn build(decisions: List(Decision), base_url: String) -> Element(a) {
  let recent = list.take(decisions, entry_limit)
  let feed_url = base_url <> "/feed.xml"
  let devlog_url = base_url <> "/devlog"

  atom.feed([attribute("xml:lang", "en")], [
    atom.title([], "glemy devlog"),
    atom.subtitle(
      [],
      "Every real architectural decision behind glemy, in order.",
    ),
    atom.id([], base_url <> "/"),
    atom.link([
      attribute.rel("self"),
      attribute("type", "application/atom+xml"),
      attribute.href(feed_url),
    ]),
    atom.link([attribute.rel("alternate"), attribute.href(devlog_url)]),
    atom.updated([], updated_timestamp(recent)),
    atom.author([], [atom.name([], "glemy")]),
    ..list.map(recent, entry(_, base_url))
  ])
}

fn updated_timestamp(recent: List(Decision)) -> String {
  case recent {
    [most_recent, ..] -> iso_timestamp(most_recent.date)
    [] -> iso_timestamp("1970-01-01")
  }
}

/// `Decision.date` is a plain `"YYYY-MM-DD"` string (see
/// `glemy_website/decisions` -- no time-of-day is tracked for a
/// decision), so midnight UTC is the honest, simplest ISO 8601
/// timestamp to report.
fn iso_timestamp(date: String) -> String {
  date <> "T00:00:00Z"
}

fn entry(decision: Decision, base_url: String) -> Element(a) {
  let url = base_url <> "/devlog/" <> decision.id <> ".html"
  let updated = iso_timestamp(decision.date)

  atom.entry([], [
    atom.id([], url),
    atom.title([], "#" <> decision.id <> " — " <> decision.title),
    atom.link([attribute.href(url)]),
    atom.updated([], updated),
    atom.published([], updated),
    atom.summary([], decision.decision),
  ])
}
