//// Renders glemy's own `docs/decisions.jsonl` as a public devlog --
//// see `glemy_website/decisions` for why this reads the same log
//// rather than a separately hand-maintained blog.

import gleam/list
import glemy_website/decisions.{type ConsideredOption, type Decision}
import glemy_website/layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn index(all: List(Decision)) -> Element(a) {
  layout.page(
    title: "Devlog",
    description: "Every real architectural decision behind glemy, in order — including the ones that didn't work.",
    content: [
      html.section([attribute.class("devlog-index")], [
        html.h1([], [html.text("Devlog")]),
        html.p([attribute.class("devlog-intro")], [
          html.text(
            "This is glemy's real decision log, not a curated highlight reel — every entry states what was tried, what was rejected and why, and how the outcome was actually verified. Newest first.",
          ),
        ]),
        html.ol([attribute.class("devlog-list")], list.map(all, entry_summary)),
      ]),
    ],
  )
}

/// `lustre_ssg`'s `use_index_routes` (see `build.gleam`) only applies to
/// *static* routes -- confirmed directly by reading `ssg.gleam`'s own
/// `do_build`: the `Dynamic(path, pages)` case always writes
/// `<path>/<page>.html` regardless of that setting, unlike `Static`,
/// which branches on it. Every link to an individual entry needs the
/// literal `.html` suffix because of that asymmetry; `/devlog` itself
/// (a static route) does not.
fn entry_href(decision: Decision) -> String {
  "/devlog/" <> decision.id <> ".html"
}

fn entry_summary(decision: Decision) -> Element(a) {
  html.li([attribute.class("devlog-entry-summary")], [
    html.a([attribute.href(entry_href(decision))], [
      html.span([attribute.class("devlog-entry-id")], [
        html.text("#" <> decision.id),
      ]),
      html.span([attribute.class("devlog-entry-title")], [
        html.text(decision.title),
      ]),
    ]),
    html.span([attribute.class("devlog-entry-meta")], [
      html.text(decision.date <> " · " <> decision.category),
    ]),
  ])
}

pub fn entry(decision: Decision) -> Element(a) {
  layout.page(
    title: "#" <> decision.id <> " — " <> decision.title,
    description: decision.title,
    content: [
      html.article([attribute.class("devlog-entry")], [
        html.p([attribute.class("devlog-entry-back")], [
          html.a([attribute.href("/devlog")], [html.text("← All decisions")]),
        ]),
        html.p([attribute.class("devlog-entry-meta")], [
          html.text(
            "#"
            <> decision.id
            <> " · "
            <> decision.date
            <> " · "
            <> decision.status
            <> " · "
            <> decision.category,
          ),
        ]),
        html.h1([], [html.text(decision.title)]),
        prose_section("Context", decision.context),
        options_section(decision.options_considered),
        prose_section("Decision", decision.decision),
        prose_section("Verification", decision.verification),
        prose_section("Consequences", decision.consequences),
        references_section(decision.references),
      ]),
    ],
  )
}

fn prose_section(heading: String, body: String) -> Element(a) {
  html.section([attribute.class("devlog-section")], [
    html.h2([], [html.text(heading)]),
    html.p([], [html.text(body)]),
  ])
}

fn options_section(options: List(ConsideredOption)) -> Element(a) {
  case options {
    [] -> html.text("")
    _ ->
      html.section([attribute.class("devlog-section")], [
        html.h2([], [html.text("Options considered")]),
        html.dl(
          [attribute.class("devlog-options")],
          list.flat_map(options, fn(option) {
            [
              html.dt([attribute.class("devlog-option-" <> option.verdict)], [
                html.text(option.option <> " — " <> option.verdict),
              ]),
              html.dd([], [html.text(option.reason)]),
            ]
          }),
        ),
      ])
  }
}

fn references_section(references: List(String)) -> Element(a) {
  case references {
    [] -> html.text("")
    _ ->
      html.section([attribute.class("devlog-section")], [
        html.h2([], [html.text("References")]),
        html.ul(
          [attribute.class("devlog-references")],
          list.map(references, fn(reference) {
            html.li([], [
              html.a(
                [
                  attribute.href(
                    "https://github.com/recregt/glemy/blob/main/"
                    <> reference,
                  ),
                ],
                [html.text(reference)],
              ),
            ])
          }),
        ),
      ])
  }
}
