//// Renders glemy's own `docs/development-plan.jsonl` -- see
//// `glemy_website/roadmap_items` for why this reads structured data
//// rather than the prose `docs/development-plan.md` (which is schema
//// documentation for the `.jsonl` file, not roadmap content itself).
//// Rendering real Lustre HTML directly from typed data, the same
//// pattern `glemy_website/pages/devlog` already uses, avoids the
//// markdown-renderer quirks (table support, `**bold**` syntax,
//// heading/paragraph adjacency) a previous, djot-based version of this
//// page had to work around.

import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/string
import glemy_website/layout
import glemy_website/roadmap_items.{type RoadmapItem}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(base_url: String, items: List(RoadmapItem)) -> Element(a) {
  let phases =
    items
    |> list.map(fn(item) { item.phase })
    |> list.unique
    |> list.sort(int.compare)

  layout.page(
    base_url: base_url,
    path: "/roadmap",
    title: "Roadmap",
    description: "glemy's living, status-tracked development roadmap -- what's planned, in progress, resolved, or deferred, and why.",
    content: [
      html.section([attribute.class("roadmap-index")], [
        html.h1([], [html.text("Roadmap")]),
        html.p([attribute.class("roadmap-intro")], [
          html.text(
            "Every item here is permanent once written -- only its status changes over time. See the ",
          ),
          html.a(
            [
              attribute.href(
                "https://github.com/recregt/glemy/blob/main/docs/development-plan.md",
              ),
            ],
            [html.text("schema and process documentation")],
          ),
          html.text(" for the full editing discipline."),
        ]),
        ..list.map(phases, phase_section(_, items, base_url))
      ]),
    ],
  )
}

fn phase_section(
  phase: Int,
  all_items: List(RoadmapItem),
  base_url: String,
) -> Element(a) {
  let items = list.filter(all_items, fn(item) { item.phase == phase })
  let assert [first, ..] = items

  html.div([attribute.class("roadmap-phase")], [
    html.h2([], [
      html.text("Phase " <> int.to_string(phase) <> " — " <> first.phase_title),
    ]),
    html.ol(
      [attribute.class("roadmap-item-list")],
      list.map(items, item_view(_, base_url)),
    ),
  ])
}

fn item_view(item: RoadmapItem, base_url: String) -> Element(a) {
  html.li([attribute.class("roadmap-item")], [
    html.div([attribute.class("roadmap-item-header")], [
      html.span([attribute.class("roadmap-item-id")], [html.text(item.id)]),
      html.h3([], inline_code(item.title)),
      status_badge(item.status),
    ]),
    html.p(
      [attribute.class("roadmap-item-description")],
      inline_code(item.description),
    ),
    resolution_line(item, base_url),
  ])
}

/// Splits `text` on backtick pairs, wrapping the odd-indexed segments
/// (the code spans) in `<code>` -- item titles/descriptions are
/// hand-written with backtick-quoted identifiers (`` `pe` ``,
/// `` `GameEvent` ``) but this module deliberately doesn't parse
/// markdown at all otherwise (see this module's own doc comment for
/// why), so this is a narrow, bounded exception for exactly one piece
/// of inline formatting, not a step back toward a general parser.
fn inline_code(text: String) -> List(Element(a)) {
  text
  |> string.split("`")
  |> list.index_map(fn(segment, index) {
    case index % 2 {
      0 -> html.text(segment)
      _ -> html.code([], [html.text(segment)])
    }
  })
}

fn status_badge(status: String) -> Element(a) {
  html.span(
    [attribute.class("roadmap-status roadmap-status-" <> status)],
    [html.text(status_label(status))],
  )
}

fn status_label(status: String) -> String {
  case status {
    "planned" -> "Planned"
    "in_progress" -> "In Progress"
    "completed" -> "Completed"
    "deferred" -> "Deferred"
    "superseded" -> "Superseded"
    other -> other
  }
}

fn resolution_line(item: RoadmapItem, base_url: String) -> Element(a) {
  case item.resolution, item.decision_refs, item.doc_refs {
    option.None, [], [] -> html.text("")
    resolution, decision_refs, doc_refs ->
      html.p(
        [attribute.class("roadmap-item-resolution")],
        list.flatten([
          resolution_text(resolution),
          list.map(decision_refs, decision_ref_link(_, base_url)),
          list.map(doc_refs, doc_ref_link),
        ]),
      )
  }
}

fn resolution_text(resolution: Option(String)) -> List(Element(a)) {
  case resolution {
    option.Some(text) -> list.append(inline_code(text), [html.text(" ")])
    option.None -> []
  }
}

fn decision_ref_link(id: String, base_url: String) -> Element(a) {
  html.a(
    [
      attribute.href(layout.url(base_url, "/devlog/" <> id <> ".html")),
      attribute.class("roadmap-ref"),
    ],
    [html.text("decision " <> id)],
  )
}

fn doc_ref_link(reference: String) -> Element(a) {
  case string.starts_with(reference, "docs/") {
    True ->
      html.a(
        [
          attribute.href(
            "https://github.com/recregt/glemy/blob/main/" <> reference,
          ),
          attribute.class("roadmap-ref"),
        ],
        [html.text(reference)],
      )
    False -> html.span([attribute.class("roadmap-ref")], [html.text(reference)])
  }
}
