import glemy_website/game_card
import glemy_website/layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(
  base_url: String,
  style_hash: String,
  play_demo_path: String,
) -> Element(a) {
  layout.page(
    base_url: base_url,
    path: "/",
    title: "Home",
    description: "glemy is a type-safe game engine written in Gleam, built to run any genre and proven one real game at a time.",
    style_hash: style_hash,
    content: [
      html.section([attribute.class("hero")], [
        html.h1([], [
          html.text("One engine. Every genre. No shortcuts on safety."),
        ]),
        html.p([attribute.class("hero-tagline")], [
          html.text(
            "glemy is a type-safe game engine written in Gleam — physics, rendering, and game rules checked by the compiler before they ever reach a player, the same code running on a server and in a browser. Most engines make you choose between moving fast and staying safe; glemy is built so you don't have to.",
          ),
        ]),
        html.div([attribute.class("hero-actions")], [
          html.a(
            [
              attribute.href(layout.url(base_url, "/play")),
              attribute.class("button button-primary"),
            ],
            [html.text("Play the games")],
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
      html.section([attribute.class("prose-section")], [
        html.h2([], [html.text("What glemy is")]),
        html.p([], [
          html.text(
            "glemy is a general-purpose game engine, not a game — even though the only way to see it working right now is to play one. It's being built to run whatever genre a real game actually needs: physics, rendering, input, and game rules that compile-check before they ever run, the same code executing identically on a server and in a browser.",
          ),
        ]),
        html.p([], [
          html.text(
            "That's a harder bar than it sounds. Most solo-built engines are really just one game's internals with the game-specific parts left in — reusable only by accident, if at all. glemy is built the other way around: genre-agnostic physics and rendering primitives at the core, with every game-specific rule — how pieces merge, what counts as a win, what the score means — kept out of that core and layered on top as data the engine reacts to, not logic it hardcodes.",
          ),
        ]),
      ]),
      html.section([attribute.class("prose-section")], [
        html.h2([], [html.text("Proven one real game at a time")]),
        html.p([], [
          html.text(
            "A game engine that's never shipped a game is a diagram, not an engine. glemy's first proof is Tiers, below — a Suika-style merge puzzler built specifically to stress-test the physics, the WebGPU renderer, and the game loop against a genre with real, well-understood mechanics to get right. It's not the destination. It's the evidence.",
          ),
        ]),
        html.div([attribute.class("game-card-list")], [
          game_card.tiers_card(base_url, play_demo_path),
        ]),
        html.p([], [
          html.text("More games, in different genres, are next — tracked, not just promised, in the "),
          html.a([attribute.href(layout.url(base_url, "/roadmap"))], [
            html.text("public roadmap"),
          ]),
          html.text("."),
        ]),
      ]),
      html.section([attribute.class("prose-section")], [
        html.h2([], [html.text("Why it's built this way")]),
        html.ul([attribute.class("goals-list")], [
          goal(
            "Bugs the compiler catches, not the player",
            "Physics, collision, and game rules are all pure, tested Gleam. The FFI boundary is kept as small as the platform genuinely requires — and no smaller a promise than that.",
          ),
          goal(
            "One codebase, two runtimes",
            "The exact same game logic runs on Erlang/BEAM and compiles to JavaScript for the browser. Nothing target-specific hides in the core.",
          ),
          goal(
            "Nothing hidden",
            "Every real decision — including the ones that didn't work — is logged and public on the devlog. No black-box roadmap, no surprise pivots.",
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
