//// The games catalog. One entry today (`glemy_website/game_card`'s
//// `catalog`), shaped to hold more without a rewrite -- see that
//// module's own doc comment for why a growing catalog, not a single
//// embedded demo, is the actual design here.
////
//// Each card links straight to glemy's own real build output (copied
//// into the site's static assets at `/play-demo/` -- see
//// `.github/workflows/deploy.yml`) in a new tab, rather than embedding
//// it in an iframe on this page: the game is its own genuinely
//// self-contained, playable thing, not a preview of one.

import glemy_website/game_card
import glemy_website/layout
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn view(base_url: String) -> Element(a) {
  layout.page(
    base_url: base_url,
    path: "/play",
    title: "Games",
    description: "Games built with glemy, playable right now in your browser.",
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
          game_card.catalog(base_url),
        ),
      ]),
    ],
  )
}
