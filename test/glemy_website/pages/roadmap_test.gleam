import gleeunit/should
import glemy_website/pages/roadmap

pub fn strip_table_lines_removes_pipe_rows_test() {
  let markdown =
    "# Heading

Some prose.

| # | Decision | Default | Status |
|---|----------|---------|--------|
| 1 | Deployment target | Browser-only | Approved |
| 2 | Bundler | None | Approved |

More prose after the table."

  roadmap.strip_table_lines(markdown)
  |> should.equal(
    "# Heading

Some prose.


More prose after the table.",
  )
}

pub fn strip_table_lines_leaves_prose_without_a_table_untouched_test() {
  let markdown = "# Heading\n\nJust prose, no table here.\n"

  roadmap.strip_table_lines(markdown)
  |> should.equal(markdown)
}

pub fn strip_table_lines_ignores_indented_pipe_characters_mid_line_test() {
  let markdown = "A line that mentions a `|` character mid-sentence, not at the start."

  roadmap.strip_table_lines(markdown)
  |> should.equal(markdown)
}

pub fn strip_table_lines_strips_leading_whitespace_before_a_pipe_test() {
  let markdown = "Prose.\n  | indented table row |\nMore prose."

  roadmap.strip_table_lines(markdown)
  |> should.equal("Prose.\nMore prose.")
}

pub fn convert_double_asterisk_bold_rewrites_to_single_asterisk_test() {
  roadmap.convert_double_asterisk_bold("**Question:** is this real?")
  |> should.equal("*Question:* is this real?")
}

pub fn convert_double_asterisk_bold_handles_multiple_spans_per_line_test() {
  roadmap.convert_double_asterisk_bold("**one** and **two**")
  |> should.equal("*one* and *two*")
}

pub fn convert_double_asterisk_bold_skips_fenced_code_blocks_test() {
  let markdown = "before\n```\nlet x = **ptr;\n```\n**after**"

  roadmap.convert_double_asterisk_bold(markdown)
  |> should.equal("before\n```\nlet x = **ptr;\n```\n*after*")
}

pub fn convert_double_asterisk_bold_escapes_a_span_containing_a_backtick_test() {
  roadmap.convert_double_asterisk_bold(
    "**The `flag` is load-bearing.** Rest of sentence.",
  )
  |> should.equal("\\*\\*The `flag` is load-bearing.\\*\\* Rest of sentence.")
}

pub fn convert_double_asterisk_bold_escaping_does_not_corrupt_a_later_unrelated_span_test() {
  let markdown =
    "1. **plain bold** normal text.
2. **bold with `code` inside**: more text
   with *unrelated emphasis* later on."

  roadmap.convert_double_asterisk_bold(markdown)
  |> should.equal(
    "1. *plain bold* normal text.
2. \\*\\*bold with `code` inside\\*\\*: more text
   with *unrelated emphasis* later on.",
  )
}

pub fn convert_double_asterisk_bold_handles_a_span_wrapped_onto_the_next_line_test() {
  let markdown = "**The flag is load-bearing, not\ndecorative.** The rest of the sentence."

  roadmap.convert_double_asterisk_bold(markdown)
  |> should.equal(
    "*The flag is load-bearing, not\ndecorative.* The rest of the sentence.",
  )
}
