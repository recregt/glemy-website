# glemy-website

The source for [glemy](https://github.com/recregt/glemy)'s public
website: goals, devlog, and a live demo of the current preview game.

Deliberately a **separate repository** from `glemy` itself — see
glemy's `ARCHITECTURE.md` and `docs/decisions.jsonl` for the full,
researched reasoning (release-cadence mismatch, deployment-target
mismatch, and direct precedent from `bevyengine/bevy-website`,
`godotengine/godot-website`, `gleam-lang/website`, and
`raysan5/raylib.com`, all separate from their engine/compiler repos).

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
- The **live demo is glemy's own real build** (`gleam build --target
  javascript` + `index.html`, copied in at build time), not a
  reimplementation — linked from a game card on `/play` (opens in a new
  tab), not embedded in an iframe: it's a genuinely separate,
  self-contained, playable thing, and the catalog is shaped to hold
  more than one game as more genres land.
- **Built static assets are content-hashed** (`style.css` as a single
  file; glemy's whole demo build as one renamed directory, since its
  files import each other by relative path and a bundler-free build
  can't have per-file hashing rewrite those — see
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
# Fetch the devlog/roadmap content and build glemy's demo once, locally:
cp ../glemy/docs/decisions.jsonl decisions.jsonl
cp ../glemy/docs/development-plan.jsonl development-plan.jsonl
mkdir -p static/play-demo/build/dev
cp ../glemy/index.html static/play-demo/index.html
cp -r ../glemy/build/dev/javascript static/play-demo/build/dev/javascript

gleam deps download
gleam test
gleam run -m build   # generates ./dist -- internal links are root-relative
                      # by default (GLEMY_WEBSITE_BASE_URL unset), correct
                      # for local serving. Also content-hashes style.css
                      # (source at assets/style.css, not static/) and
                      # renames static/play-demo/ to static/play-demo-<hash>/
                      # in place -- rerunning without recopying the demo
                      # reuses whatever's already there.

# Serve it locally:
deno run --allow-net --allow-read jsr:@std/http/file-server dist
```

## Deployment

Fully automated — see `.github/workflows/deploy.yml`. Runs on every
push to `main`, once daily (glemy can change without a corresponding
push here, since the repos are separate), and on manual dispatch.
