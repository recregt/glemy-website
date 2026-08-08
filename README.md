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
  reimplementation — embedded via an iframe at `/play`, since it's a
  genuinely separate, self-contained HTML document.

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
# Fetch the devlog content and build glemy's demo once, locally:
cp ../glemy/docs/decisions.jsonl decisions.jsonl
mkdir -p static/play-demo/build/dev
cp ../glemy/index.html static/play-demo/index.html
cp -r ../glemy/build/dev/javascript static/play-demo/build/dev/javascript

gleam deps download
gleam test
gleam run -m build   # generates ./dist

# Serve it locally:
deno run --allow-net --allow-read jsr:@std/http/file-server dist
```

## Deployment

Fully automated — see `.github/workflows/deploy.yml`. Runs on every
push to `main`, once daily (glemy can change without a corresponding
push here, since the repos are separate), and on manual dispatch.
