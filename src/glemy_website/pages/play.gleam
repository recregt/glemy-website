//// The games catalog (`glemy_website/game_card`'s `catalog`) -- Tiers
//// and Breakout today, shaped to hold more without a rewrite -- see
//// that module's own doc comment for why a growing catalog, not a
//// single embedded demo, is the actual design here.
////
//// Each card links straight to glemy's own real build output (copied
//// into the site's static assets under a content-hashed
//// `/play-demo-{stable,edge}-<hash>/` directory -- see
//// `.github/workflows/deploy.yml` and `build.gleam`) in a new tab,
//// rather than embedding it in an iframe on this page: the game is
//// its own genuinely self-contained, playable thing, not a preview of
//// one.

import glemy_website/game_card.{type DemoPaths}
import glemy_website/layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(
  base_url: String,
  style_hash: String,
  tiers_demo: DemoPaths,
  breakout_demo: DemoPaths,
) -> Element(a) {
  layout.page(
    base_url: base_url,
    path: "/play",
    title: "Games",
    description: "Games built with glemy, playable right now in your browser.",
    style_hash: style_hash,
    content: [
      html.section([attribute.class("games-index")], [
        html.h1([], [html.text("Games")]),
        html.p([attribute.class("games-intro")], [
          html.text(
            "Every game here is real, playable, and built on glemy -- proof the engine works, not a mockup of it. Requires a browser with WebGPU support.",
          ),
        ]),
        html.div(
          [attribute.class("game-card-list")],
          game_card.catalog(base_url, tiers_demo, breakout_demo),
        ),
      ]),
    ],
  )
}
