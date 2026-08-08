//// Renders glemy's own `docs/development-plan.md` -- fetched into this
//// repo at build time, same pattern as `glemy_website/decisions` reads
//// `docs/decisions.jsonl` (see `.github/workflows/deploy.yml`). That
//// document opens by describing itself as "primarily a historical
//// record" now that its own roadmap has shipped, not a live plan --
//// this page keeps that framing intact (its own opening paragraph says
//// so) rather than relabeling it into something it isn't.

import gleam/list
import gleam/option
import gleam/regexp
import gleam/string
import glemy_website/layout
import lustre/element.{type Element}
import lustre/ssg/djot

/// `development-plan.md` has one real GitHub-flavored-Markdown pipe
/// table (`| # | Decision | Default | Status |`, its "Summary of
/// recommended defaults" section). `lustre_ssg`'s djot `Renderer` type
/// has no `table` field -- djot doesn't have GFM-style tables at all --
/// so feeding it through unmodified doesn't error, but does silently
/// mangle it: the whole table becomes one `<p>` of literal `|`
/// characters, and djot's smart-typography pass (on by default) turns
/// every `---`/`--` in the *separator row* into em/en-dashes, since
/// outside of a fenced code block or inline code span it can't tell
/// those apart from real prose punctuation (confirmed directly: exactly
/// 14 stray dashes appeared in the rendered output vs. the raw source,
/// disappearing entirely once this filter dropped the table's 11 pipe
/// lines). Stripping every line that starts with `|` removes exactly
/// that table (and only that table -- no other line in the source
/// starts with `|`) while leaving the real prose before and after it,
/// including the document's own closing summary paragraph, untouched.
pub fn strip_table_lines(markdown: String) -> String {
  markdown
  |> string.split("\n")
  |> list.filter(fn(line) { !string.starts_with(string.trim_start(line), "|") })
  |> string.join("\n")
}

/// `development-plan.md` is written in CommonMark, where `**text**`
/// means strong emphasis -- but djot's own strong-emphasis delimiter is
/// a single `*text*`. Confirmed directly against this renderer: fed
/// `**text**` unmodified, its parser matched the inner pair of stars as
/// a strong span and left the outer two as stray literal asterisks,
/// producing `*<strong>text</strong>*` in the real rendered output --
/// 36 of these in the source document, not a rare edge case. This
/// rewrites `**text**` to `*text*` before parsing so djot reads it as
/// intended.
///
/// Splits on the literal `"```"` fence delimiter first and only
/// converts the even-indexed (outside-a-fence) segments -- `**` inside
/// a code example is code, not markup, and shouldn't be touched (a
/// first version tried a per-line regex instead, which silently missed
/// every `**bold text**` span whose closing `**` wrapped onto the next
/// line, since Markdown paragraphs reflow across line breaks but a
/// per-line regex can't see across them; splitting on fences instead of
/// lines applies the regex to a whole paragraph at once, so multi-line
/// spans convert correctly too).
///
/// Backslash-escapes a span (`\*\*...\*\*`, rendering as literal `**`
/// text) instead of converting it, if it contains a backtick: confirmed
/// directly against this renderer that its emphasis matching doesn't
/// pair delimiters across an inline code span at all, single-asterisk
/// or double. That alone would be a minor, containable cosmetic
/// downgrade (a literal `**` instead of real bold) -- but *leaving the
/// asterisks unescaped* turned out to be worse than cosmetic: an
/// unpaired `**` doesn't just sit inertly as text, it stays live in
/// djot's delimiter-matching and can pair with a completely unrelated
/// `*emphasis*` span later in the same paragraph, corrupting it too
/// (reproduced directly: an unescaped, unpaired `**bold with `code`
/// inside**` on one list item silently ate into and mangled an
/// unrelated `*many*` on the *next* item). Escaping removes the
/// asterisks from delimiter-matching entirely, containing the damage to
/// exactly the one span that can't render as intended. Two sentences in
/// the current document hit this; a genuine upstream parser limitation,
/// not something a smarter regex here can work around.
pub fn convert_double_asterisk_bold(markdown: String) -> String {
  let assert Ok(bold_pattern) = regexp.from_string("\\*\\*([^*]+?)\\*\\*")

  let convert_segment = fn(segment: String) {
    regexp.match_map(bold_pattern, segment, fn(m) {
      case m.submatches {
        [option.Some(inner), ..] ->
          case string.contains(inner, "`") {
            True -> "\\*\\*" <> inner <> "\\*\\*"
            False -> "*" <> inner <> "*"
          }
        _ -> m.content
      }
    })
  }

  markdown
  |> string.split("```")
  |> list.index_map(fn(segment, index) {
    case index % 2 {
      0 -> convert_segment(segment)
      _ -> segment
    }
  })
  |> string.join("```")
}

pub fn view(base_url: String, plan_markdown: String) -> Element(a) {
  layout.page(
    base_url: base_url,
    path: "/roadmap",
    title: "Roadmap",
    description: "glemy's development plan, decision by decision, from first principles to the current preview game.",
    content: plan_markdown
      |> strip_table_lines
      |> convert_double_asterisk_bold
      |> djot.render(djot.default_renderer()),
  )
}
