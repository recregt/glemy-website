//// A reusable game-card component: icon, name, tagline, and a
//// prominent "play now" button that opens the actual build in a new
//// tab -- used on both the homepage (as a product teaser) and
//// `/play` (the full catalog, see `glemy_website/pages/play`).
//// `game_card` itself takes every per-game detail (icon, name,
//// tagline, description, demo paths) as a parameter -- generalized
//// from a Tiers-only `tiers_card` once Breakout (glemy's second
//// reference game, decisions 0052/0053) became a second real caller,
//// per this project's own standing "generalize at the second real
//// caller, not before" discipline (mirrors the same rule glemy's own
//// ARCHITECTURE.md/decisions.jsonl apply throughout).
////
//// Each game's icon is built from that game's own real on-screen
//// colors, not a generic stock icon standing in for it: Tiers' three
//// circles are `pe/tier.gleam`'s real `color(0)`/`color(2)`/`color(4)`
//// palette at increasing radii (small tiers merge into bigger ones);
//// Breakout's paddle/ball/bricks are the exact `#5af`/white/`#fa5`
//// colors `breakout.html`'s own CSS and `games/breakout.ball_color`
//// use; Platformer's platforms/goal/player are the exact `#8a5`/`#fd5`
//// colors `platformer.html`'s own CSS and `games/platformer.player_color`
//// use.

import lustre/attribute.{attribute}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/svg

pub fn tiers_icon() -> Element(a) {
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

pub fn breakout_icon() -> Element(a) {
  svg.svg(
    [
      attribute("viewBox", "0 0 100 100"),
      attribute.class("game-card-icon"),
      attribute("aria-hidden", "true"),
    ],
    [
      svg.rect([
        attribute("x", "13"),
        attribute("y", "16"),
        attribute("width", "30"),
        attribute("height", "13"),
        attribute("fill", "rgb(255, 170, 85)"),
      ]),
      svg.rect([
        attribute("x", "57"),
        attribute("y", "16"),
        attribute("width", "30"),
        attribute("height", "13"),
        attribute("fill", "rgb(255, 170, 85)"),
      ]),
      svg.circle([
        attribute("cx", "50"),
        attribute("cy", "50"),
        attribute("r", "8"),
        attribute("fill", "rgb(255, 255, 255)"),
      ]),
      svg.rect([
        attribute("x", "33"),
        attribute("y", "78"),
        attribute("width", "34"),
        attribute("height", "10"),
        attribute("rx", "2"),
        attribute("fill", "rgb(85, 170, 255)"),
      ]),
    ],
  )
}

pub fn platformer_icon() -> Element(a) {
  svg.svg(
    [
      attribute("viewBox", "0 0 100 100"),
      attribute.class("game-card-icon"),
      attribute("aria-hidden", "true"),
    ],
    [
      svg.rect([
        attribute("x", "8"),
        attribute("y", "78"),
        attribute("width", "38"),
        attribute("height", "12"),
        attribute("fill", "rgb(136, 170, 85)"),
      ]),
      svg.rect([
        attribute("x", "40"),
        attribute("y", "50"),
        attribute("width", "32"),
        attribute("height", "12"),
        attribute("fill", "rgb(136, 170, 85)"),
      ]),
      svg.rect([
        attribute("x", "70"),
        attribute("y", "18"),
        attribute("width", "24"),
        attribute("height", "12"),
        attribute("fill", "rgb(255, 221, 85)"),
      ]),
      svg.circle([
        attribute("cx", "22"),
        attribute("cy", "70"),
        attribute("r", "8"),
        attribute("fill", "rgb(51, 255, 77)"),
      ]),
    ],
  )
}

/// The two release channels a game's live demo is published under
/// (`docs/technical-architecture.md` §3.4, RM-025): `stable` is a
/// pinned build, promoted automatically once a glemy commit's own CI
/// passes (decision 0057 -- superseded the original manual-only
/// promotion), never an untested or failing one; `edge` always tracks
/// glemy's default branch directly. Both are content-hashed directory
/// paths (e.g. `/play-demo-stable-a1b2c3d4`), computed in `build.gleam`
/// -- see `asset_hash` and RM-024 for why a whole directory, not each
/// file inside it, gets hashed as one unit.
pub type DemoPaths {
  DemoPaths(stable: String, edge: String)
}

fn demo_url(base_url: String, demo_path: String) -> String {
  base_url <> demo_path <> "/index.html"
}

/// One game's card, fully parameterized: every caller supplies its own
/// icon, name, tagline, description, and demo paths -- see this
/// module's own doc comment for why this is generalized rather than
/// each game hand-rolling its own near-identical markup.
pub fn game_card(
  base_url: String,
  demo: DemoPaths,
  icon: Element(a),
  name: String,
  tagline: String,
  description: String,
) -> Element(a) {
  html.div([attribute.class("game-card")], [
    icon,
    html.div([attribute.class("game-card-body")], [
      html.h3([], [html.text(name)]),
      html.p([attribute.class("game-card-tagline")], [html.text(tagline)]),
      html.p([attribute.class("game-card-description")], [
        html.text(description),
      ]),
      html.div([attribute.class("game-card-actions")], [
        html.a(
          [
            attribute.href(demo_url(base_url, demo.stable)),
            attribute.target("_blank"),
            attribute.class("button button-primary game-card-play"),
          ],
          [html.text("Play " <> name <> " ↗")],
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

pub fn tiers_card(base_url: String, demo: DemoPaths) -> Element(a) {
  game_card(
    base_url,
    demo,
    tiers_icon(),
    "Tiers",
    "Drop. Merge. Climb. Don't let it overflow.",
    "A Suika-style merge puzzler and glemy's proving ground: drop circles, merge same-tier pairs into the next size up, keep the stack under control. Runs live via WebGPU, right in your browser.",
  )
}

pub fn breakout_card(base_url: String, demo: DemoPaths) -> Element(a) {
  game_card(
    base_url,
    demo,
    breakout_icon(),
    "Breakout",
    "Bounce. Break. Clear the board.",
    "A Breakout/Arkanoid-style paddle-and-brick game and glemy's second reference game, built to prove the engine's physics and rendering generalize past one genre. Steer the paddle, keep the ball alive, clear every brick. Runs live via WebGPU, right in your browser.",
  )
}

pub fn platformer_card(base_url: String, demo: DemoPaths) -> Element(a) {
  game_card(
    base_url,
    demo,
    platformer_icon(),
    "Platformer",
    "Jump. Climb. Reach the goal.",
    "glemy's third reference game, built specifically to test whether one wall/landing physics policy could serve every genre -- it can't (confirmed a third distinct way, decisions 0052/0058/0059/0060). Move, jump, and climb a platform staircase to the goal. Runs live via WebGPU, right in your browser.",
  )
}

/// The full catalog. Each game supplies its own `DemoPaths` (stable/edge
/// are built independently per game -- see `build.gleam`'s
/// `prepare_play_demo_dir` calls), so a fourth game is a fourth
/// parameter and a fourth list entry, not a restructure of whatever
/// page renders this -- confirmed by this third real addition needing
/// no changes to `game_card` itself, only a new call site.
pub fn catalog(
  base_url: String,
  tiers_demo: DemoPaths,
  breakout_demo: DemoPaths,
  platformer_demo: DemoPaths,
) -> List(Element(a)) {
  [
    tiers_card(base_url, tiers_demo),
    breakout_card(base_url, breakout_demo),
    platformer_card(base_url, platformer_demo),
  ]
}
