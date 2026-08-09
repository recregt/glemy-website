//// A reusable game-card component: icon, name, tagline, and a
//// prominent "play now" button that opens the actual build in a new
//// tab -- used on both the homepage (as a product teaser) and
//// `/play` (the full catalog, see `glemy_website/pages/play`).
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

/// The two release channels a game's live demo is published under
/// (`docs/technical-architecture.md` §3.4, RM-025): `stable` is a
/// pinned build, only updated by a deliberate commit to
/// `STABLE_GLEMY_REF`, not automatically by every glemy push; `edge`
/// always tracks glemy's default branch directly. Both are
/// content-hashed directory paths (e.g. `/play-demo-stable-a1b2c3d4`),
/// computed in `build.gleam` -- see `asset_hash` and RM-024 for why a
/// whole directory, not each file inside it, gets hashed as one unit.
pub type DemoPaths {
  DemoPaths(stable: String, edge: String)
}

fn demo_url(base_url: String, demo_path: String) -> String {
  base_url <> demo_path <> "/index.html"
}

pub fn tiers_card(base_url: String, demo: DemoPaths) -> Element(a) {
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
      html.div([attribute.class("game-card-actions")], [
        html.a(
          [
            attribute.href(demo_url(base_url, demo.stable)),
            attribute.target("_blank"),
            attribute.class("button button-primary game-card-play"),
          ],
          [html.text("Play Tiers ↗")],
        ),
        html.a(
          [
            attribute.href(demo_url(base_url, demo.edge)),
            attribute.target("_blank"),
            attribute.class("game-card-edge-link"),
          ],
          [html.text("Try the latest build (edge) ↗")],
        ),
      ]),
    ]),
  ])
}

/// The full catalog -- today, one card. Kept as its own function so a
/// second game is a second entry in this list, not a restructure of
/// whatever page renders it.
pub fn catalog(base_url: String, demo: DemoPaths) -> List(Element(a)) {
  [tiers_card(base_url, demo)]
}
