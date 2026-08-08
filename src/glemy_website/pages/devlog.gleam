//// Renders glemy's own `docs/decisions.jsonl` as a public devlog --
//// see `glemy_website/decisions` for why this reads the same log
//// rather than a separately hand-maintained blog.
////
//// Every `Decision` already carries a `category` (10 distinct values
//// across the 41 real entries at the time this was added -- checked
//// directly, not assumed) and `tags` (85 distinct values, the vast
//// majority used exactly once). Category has the right cardinality for
//// real filtering; tags don't -- a dedicated page for a tag with one
//// entry has no value over just reading that entry, so tags are shown
//// as plain visible metadata on each entry, not built out into their
//// own filterable pages.

import gleam/int
import gleam/list
import gleam/string
import glemy_website/decisions.{type ConsideredOption, type Decision}
import glemy_website/layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn index(all: List(Decision), base_url: String) -> Element(a) {
  layout.page(
    base_url: base_url,
    path: "/devlog",
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
        category_filter_bar(all, base_url),
        html.ol(
          [attribute.class("devlog-list")],
          list.map(all, entry_summary(_, base_url)),
        ),
      ]),
    ],
  )
}

/// One `category_page` per distinct category, keyed by the category
/// string itself -- see `build.gleam`, which groups decisions by
/// `.category` via `list.group` before wiring this up as a dynamic
/// route.
pub fn category_page(
  category: String,
  entries: List(Decision),
  base_url: String,
) -> Element(a) {
  layout.page(
    base_url: base_url,
    path: category_path(category),
    title: "Devlog: " <> category,
    description: "Every "
      <> category
      <> " decision behind glemy ("
      <> int.to_string(list.length(entries))
      <> " entries).",
    content: [
      html.section([attribute.class("devlog-index")], [
        html.p([attribute.class("devlog-entry-back")], [
          html.a([attribute.href(layout.url(base_url, "/devlog"))], [
            html.text("← All decisions"),
          ]),
        ]),
        html.h1([], [html.text("Category: " <> category)]),
        html.ol(
          [attribute.class("devlog-list")],
          list.map(entries, entry_summary(_, base_url)),
        ),
      ]),
    ],
  )
}

/// `lustre_ssg`'s `add_dynamic_route` derives each generated filename
/// from the dict key via its own private `routify` (lowercase, collapse
/// whitespace to hyphens) -- not exported, so this has to reproduce it.
/// Safe here specifically because every real category value is already
/// a single lowercase, hyphenated token with no whitespace (confirmed
/// directly against `docs/decisions.jsonl`: "architecture",
/// "testing-infrastructure", "bug-fix", etc.) -- `string.lowercase`
/// alone matches `routify`'s output exactly for all of them. A future
/// category containing spaces would need to already be written
/// pre-hyphenated to keep matching, same as the existing convention.
fn category_slug(category: String) -> String {
  string.lowercase(category)
}

pub fn category_path(category: String) -> String {
  "/devlog/category/" <> category_slug(category) <> ".html"
}

fn category_href(category: String, base_url: String) -> String {
  layout.url(base_url, category_path(category))
}

fn category_filter_bar(all: List(Decision), base_url: String) -> Element(a) {
  let categories =
    all
    |> list.map(fn(decision) { decision.category })
    |> list.unique
    |> list.sort(string.compare)

  html.nav([attribute.class("devlog-category-filter")], [
    html.span([attribute.class("devlog-category-filter-label")], [
      html.text("Filter by category:"),
    ]),
    ..list.map(categories, fn(category) {
      let count =
        list.count(all, fn(decision) { decision.category == category })
      html.a(
        [
          attribute.href(category_href(category, base_url)),
          attribute.class("devlog-category-pill"),
        ],
        [
          html.text(category),
          html.span([attribute.class("devlog-category-count")], [
            html.text(" " <> int.to_string(count)),
          ]),
        ],
      )
    })
  ])
}

/// `lustre_ssg`'s `use_index_routes` (see `build.gleam`) only applies to
/// *static* routes -- confirmed directly by reading `ssg.gleam`'s own
/// `do_build`: the `Dynamic(path, pages)` case always writes
/// `<path>/<page>.html` regardless of that setting, unlike `Static`,
/// which branches on it. Every link to an individual entry needs the
/// literal `.html` suffix because of that asymmetry; `/devlog` itself
/// (a static route) does not.
pub fn entry_path(decision: Decision) -> String {
  "/devlog/" <> decision.id <> ".html"
}

fn entry_href(decision: Decision, base_url: String) -> String {
  layout.url(base_url, entry_path(decision))
}

fn entry_summary(decision: Decision, base_url: String) -> Element(a) {
  html.li([attribute.class("devlog-entry-summary")], [
    html.a([attribute.href(entry_href(decision, base_url))], [
      html.span([attribute.class("devlog-entry-id")], [
        html.text("#" <> decision.id),
      ]),
      html.span([attribute.class("devlog-entry-title")], [
        html.text(decision.title),
      ]),
    ]),
    html.span([attribute.class("devlog-entry-meta")], [
      html.text(decision.date <> " · "),
      html.a(
        [
          attribute.href(category_href(decision.category, base_url)),
          attribute.class("devlog-category-pill"),
        ],
        [html.text(decision.category)],
      ),
    ]),
  ])
}

pub fn entry(decision: Decision, base_url: String) -> Element(a) {
  layout.page(
    base_url: base_url,
    path: entry_path(decision),
    title: "#" <> decision.id <> " — " <> decision.title,
    description: decision.title,
    content: [
      html.article([attribute.class("devlog-entry")], [
        html.p([attribute.class("devlog-entry-back")], [
          html.a([attribute.href(layout.url(base_url, "/devlog"))], [
            html.text("← All decisions"),
          ]),
        ]),
        html.p([attribute.class("devlog-entry-meta")], [
          html.text(
            "#"
            <> decision.id
            <> " · "
            <> decision.date
            <> " · "
            <> decision.status
            <> " · ",
          ),
          html.a(
            [
              attribute.href(category_href(decision.category, base_url)),
              attribute.class("devlog-category-pill"),
            ],
            [html.text(decision.category)],
          ),
        ]),
        html.h1([], [html.text(decision.title)]),
        tags_section(decision.tags),
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

fn tags_section(tags: List(String)) -> Element(a) {
  case tags {
    [] -> html.text("")
    _ ->
      html.p(
        [attribute.class("devlog-tags")],
        list.map(tags, fn(tag) {
          html.span([attribute.class("devlog-tag")], [html.text(tag)])
        }),
      )
  }
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
