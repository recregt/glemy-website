import glemy_website/layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(base_url: String) -> Element(a) {
  layout.page(
    base_url: base_url,
    path: "/",
    title: "Home",
    description: "glemy is a Gleam game engine, developed in the open — currently previewed by a Suika-style merge puzzler.",
    content: [
      html.section([attribute.class("hero")], [
        html.h1([], [html.text("glemy")]),
        html.p([attribute.class("hero-tagline")], [
          html.text(
            "A type-safe game engine, built in Gleam — physics, rendering, and game logic that run identically on the BEAM and in the browser.",
          ),
        ]),
        html.div([attribute.class("hero-actions")], [
          html.a(
            [
              attribute.href(layout.url(base_url, "/play")),
              attribute.class("button button-primary"),
            ],
            [html.text("Play the current preview")],
          ),
          html.a(
            [
              attribute.href(layout.url(base_url, "/devlog")),
              attribute.class("button"),
            ],
            [html.text("Read the devlog")],
          ),
        ]),
      ]),
      html.section([attribute.class("goals")], [
        html.h2([], [html.text("What glemy is for")]),
        html.p([], [
          html.text(
            "glemy isn't a game — it's the engine underneath one, developed against a real game as its own proving ground rather than designed in the abstract. The current preview is a Suika-style merge puzzler, built to shake out the engine's physics, rendering, and game-loop architecture against a genre with real, well-understood mechanics to get right.",
          ),
        ]),
        html.ul([attribute.class("goals-list")], [
          goal(
            "Type safety end to end",
            "Every layer — physics, collision, game rules — is pure, tested Gleam. FFI is kept minimal and deliberately isolated to what genuinely can't be expressed any other way.",
          ),
          goal(
            "One codebase, two targets",
            "The same game logic runs on Erlang/BEAM and compiles to JavaScript for the browser — nothing target-specific leaks into the core.",
          ),
          goal(
            "Built and verified in the open",
            "Every real architectural decision — including the ones that didn't work — is logged, reasoned about, and public. See the Devlog.",
          ),
          goal(
            "Genre-agnostic, proven against a real genre",
            "The merge-puzzler preview isn't the destination — it's how the engine's actual generality gets tested, one real game at a time.",
          ),
        ]),
      ]),
    ],
  )
}

fn goal(title: String, description: String) -> Element(a) {
  html.li([], [
    html.h3([], [html.text(title)]),
    html.p([], [html.text(description)]),
  ])
}
