# glemy-website

The source for [glemy](https://github.com/recregt/glemy)'s public
website: goals, devlog, and a live demo catalog of its reference games
(Tiers, Breakout, Platformer — from
[glemy-games](https://github.com/recregt/glemy-games)).

Deliberately a **separate repository** from both `glemy` and
`glemy-games` — see glemy's `ARCHITECTURE.md` and `docs/decisions.jsonl`
for the full, researched reasoning (release-cadence mismatch,
deployment-target mismatch, and direct precedent from
`bevyengine/bevy-website`, `godotengine/godot-website`,
`gleam-lang/website`, and `raysan5/raylib.com`, all separate from their
engine/compiler repos).

## Stack

- **[`lustre_ssg`](https://github.com/lustre-labs/ssg)** — the official
  Gleam-native static site generator from the Lustre team. Chosen over
  a JS-ecosystem generator (Astro/Docusaurus/Hugo) to match glemy's own
  standing "maximize type safety, minimize dependencies" rule — the
  flagship precedent is `gleam.run` itself, which is written in Gleam.
- **GitHub Pages**, deployed via **GitHub Actions** — free, and the
  same setup `gleam.run` itself uses.
- The **devlog renders `glemy`'s own `docs/decisions.jsonl` directly**
  (fetched at build time, see `.github/workflows/deploy.yml`) rather
  than being a separately hand-maintained blog — glemy's decision log
  already is a structured, dated, reasoned record of what was built and
  why.
- The **live demo catalog is glemy-games' own real build** (`gleam
  build --target javascript` + each game's own HTML entry point, copied
  in at build time — building `glemy-games` transitively builds `glemy`
  too, via `glemy-games`' own Hex dependency on it), not a
  reimplementation — each game links from its own card on `/play`
  (opens in a new tab), not embedded in an iframe: a genuinely separate,
  self-contained, playable thing per game.
- **Two release channels per game** (`docs/technical-architecture.md`
  §3.4, RM-025): each game's card links a pinned "stable" build —
  `STABLE_GLEMY_GAMES_REF` (a `glemy-games` commit, auto-promoted once
  that commit's own CI passes, decision 0057) — and an "edge" build that
  always tracks `glemy-games`' default branch directly. Both are built
  and content-hashed independently every deploy.
- **Built static assets are content-hashed** (`style.css` as a single
  file; each game's whole demo build as one renamed directory per
  game/channel, since its files import each other by relative path and
  a bundler-free build can't have per-file hashing rewrite those — see
  `glemy_website/asset_hash` and `build.gleam`) — closes the risk of a
  visitor's browser serving a stale cached asset against a freshly
  deployed page during a deploy's several-second window
  (`docs/technical-architecture.md` §3.3, RM-024).
- The **roadmap renders `glemy`'s own `docs/development-plan.jsonl`
  directly** (also fetched at build time), same reasoning as the
  devlog — a status-tracked (`planned`/`in_progress`/`completed`/
  `deferred`/`superseded`) list of roadmap items, not prose. Structured
  data decoded the same way `decisions.jsonl` already is, rather than
  markdown piped through `lustre_ssg`'s djot renderer — an earlier,
  markdown-based version of this page hit real renderer limitations
  (no table support, `**bold**` vs. djot's `*bold*`) that structured
  data sidesteps entirely.
- The **devlog is filterable by category** (`/devlog/category/<name>`) —
  every `Decision` already carries one; tags aren't built into their own
  pages, since almost all of the 85 real tag values are used exactly
  once, so a dedicated page per tag has no value over the entry itself.
- **`/sitemap.xml`, `/robots.txt`, and `/feed.xml`** (an Atom feed of the
  20 most recent devlog entries, via `lustre_ssg`'s own `lustre/ssg/atom`
  helper) are generated at build time from the same real route/decision
  data, not hand-maintained separately.

## Note on the pinned `lustre_ssg` dependency

`gleam.toml` points `lustre_ssg` at a specific commit on
`lustre-labs/ssg`'s GitHub repo, not the Hex-published release.
Hex's published `0.11.0` hard-pins `jot = "4.0.0"`, whose code calls
`result.then` — a function current `gleam_stdlib` no longer has
(confirmed directly by reading `gleam_stdlib`'s own `result.gleam`).
The GitHub repo's `main` branch already fixes this (an unreleased
`0.12.0`, with `jot >= 8.0.0 and < 9.0.0`) — pinned to that exact
commit per Gleam's own documented preference for a commit SHA over a
branch reference. Safe to switch back to a plain Hex version constraint
once `0.12.0` (or later) is actually published.

## Local development

```sh
# Fetch the devlog/roadmap content from glemy, and build glemy-games'
# demos once, locally. Locally there's no separate "stable" checkout to
# build from, so both channels are just populated from the same local
# build -- the stable/edge distinction only means something in CI,
# where each channel is checked out from a genuinely different
# glemy-games ref.
cp ../glemy/docs/decisions.jsonl decisions.jsonl
cp ../glemy/docs/development-plan.jsonl development-plan.jsonl
(cd ../glemy-games && gleam deps download && gleam build --target javascript)
for channel in stable edge; do
  mkdir -p "static/play-demo-$channel/build/dev"
  cp ../glemy-games/index.html "static/play-demo-$channel/index.html"
  cp -r ../glemy-games/build/dev/javascript "static/play-demo-$channel/build/dev/javascript"
  mkdir -p "static/play-demo-breakout-$channel/build/dev"
  cp ../glemy-games/breakout.html "static/play-demo-breakout-$channel/index.html"
  cp -r ../glemy-games/build/dev/javascript "static/play-demo-breakout-$channel/build/dev/javascript"
  mkdir -p "static/play-demo-platformer-$channel/build/dev"
  cp ../glemy-games/platformer.html "static/play-demo-platformer-$channel/index.html"
  cp -r ../glemy-games/build/dev/javascript "static/play-demo-platformer-$channel/build/dev/javascript"
done

gleam deps download
gleam test
gleam run -m build   # generates ./dist -- internal links are root-relative
                      # by default (GLEMY_WEBSITE_BASE_URL unset), correct
                      # for local serving. Also content-hashes style.css
                      # (source at assets/style.css, not static/) and
                      # renames static/play-demo-{stable,edge}/ to
                      # static/play-demo-{stable,edge}-<hash>/ in place --
                      # rerunning without recopying the demo reuses
                      # whatever's already there.

# Serve it locally:
deno run --allow-net --allow-read jsr:@std/http/file-server dist
```

## Deployment

Fully automated — see `.github/workflows/deploy.yml`. Runs on every
push to `main`, once daily (`glemy`/`glemy-games` can change without a
corresponding push here, since all three repos are separate), and on
manual dispatch. Checks out `glemy` once (for devlog/roadmap content
only) and `glemy-games` twice (edge and stable); building `glemy-games`
transitively builds `glemy` too, via its own Hex dependency.

## Promoting a new stable build

Automatic, not manual (decision 0057; see
`.github/workflows/promote-stable.yml`): an hourly scheduled job polls
`glemy-games`' own CI and, once a `main` commit's own `gleam build`/
`gleam test` (both targets) actually pass, bumps `STABLE_GLEMY_GAMES_REF`
(repo root, one line — the `glemy-games` commit the public-facing
`/play` demos are currently pinned to) to that commit and dispatches
`deploy.yml` directly. Never promotes an untested or failing commit.

A manual promotion is still possible if needed (e.g. to roll back to an
earlier known-good commit ahead of the next scheduled poll):

```sh
echo "<glemy-games commit sha>" > STABLE_GLEMY_GAMES_REF
git commit -am "Promote glemy-games <short sha> to the stable demo channel"
git push
```

The next deploy checks out `glemy-games` at that ref for the stable
build (the edge build, and devlog/roadmap content from `glemy`, always
track each repo's own default branch regardless). Never edit this file
without committing it — an uncommitted change has no effect once the
next CI run does a fresh checkout.
