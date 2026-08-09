//// A reusable game-card component: icon, name, tagline, and a
//// prominent "play now" button that opens the actual build in a new
//// tab -- used on both the homepage (as a product teaser) and
//// `/games` (the full catalog, see `glemy_website/pages/games`).
//// Deliberately built to hold more than one card even though the
//// catalog has exactly one entry today: more games, in different
//// genres, are the actual test of whether `glemy` generalizes (see
//// `docs/technical-architecture.md` §2.3), so this component -- and
//// the page it's used on -- are shaped for that from the start rather
//// than needing a rewrite when the second game lands.
////
//// The icon is three circles in glemy's own real tier-progression
//// palette (`pe/tier.gleam`'s `color(0)`, `color(2)`, `color(4)` --
//// the exact RGB values a player sees on screen, not a generic stock
//// icon standing in for the game) at increasing radii, evoking the
//// actual mechanic: small tiers merge into bigger ones.

import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg

pub fn icon() -> Element(a) {
  svg.svg(
    [
      attribute("viewBox", "0 0 100 100"),
      attribute.class("game-card-icon"),
      attribute("aria-hidden", "true"),
    ],
    [
      svg.circle([
        attribute("cx", "50"),
        attribute("cy", "84"),
        attribute("r", "13"),
        attribute("fill", "rgb(255, 0, 0)"),
      ]),
      svg.circle([
        attribute("cx", "50"),
        attribute("cy", "53"),
        attribute("r", "19"),
        attribute("fill", "rgb(255, 255, 0)"),
      ]),
      svg.circle([
        attribute("cx", "50"),
        attribute("cy", "26"),
        attribute("r", "24"),
        attribute("fill", "rgb(0, 77, 255)"),
      ]),
    ],
  )
}

pub fn tiers_card(base_url: String) -> Element(a) {
  html.div([attribute.class("game-card")], [
    icon(),
    html.div([attribute.class("game-card-body")], [
      html.h3([], [html.text("Tiers")]),
      html.p([attribute.class("game-card-tagline")], [
        html.text("Drop. Merge. Climb. Don't let it overflow."),
      ]),
      html.p([attribute.class("game-card-description")], [
        html.text(
          "A Suika-style merge puzzler and glemy's proving ground: drop circles, merge same-tier pairs into the next size up, keep the stack under control. Runs live via WebGPU, right in your browser.",
        ),
      ]),
      html.a(
        [
          attribute.href(base_url <> "/play-demo/index.html"),
          attribute.target("_blank"),
          attribute.class("button button-primary game-card-play"),
        ],
        [html.text("Play Tiers ↗")],
      ),
    ]),
  ])
}

/// The full catalog -- today, one card. Kept as its own function so a
/// second game is a second entry in this list, not a restructure of
/// whatever page renders it.
pub fn catalog(base_url: String) -> List(Element(a)) {
  [tiers_card(base_url)]
}
