import gleam/option.{None, Some}
import gleam/result
import glemy_website/decisions.{ConsideredOption, Decision}

const sample_line = "{\"id\":\"0001\",\"date\":\"2026-08-07\",\"title\":\"Example\",\"status\":\"accepted\",\"category\":\"architecture\",\"tags\":[\"a\",\"b\"],\"context\":\"Why this came up.\",\"options_considered\":[{\"option\":\"Do nothing\",\"verdict\":\"rejected\",\"reason\":\"Not good enough.\"},{\"option\":\"Do the thing\",\"verdict\":\"chosen\",\"reason\":\"Good enough.\"}],\"decision\":\"Did the thing.\",\"verification\":\"Checked it worked.\",\"consequences\":\"Things are different now.\",\"supersedes\":null,\"superseded_by\":null,\"references\":[\"src/thing.gleam\"]}"

pub fn parse_line_decodes_a_real_decision_shape_test() {
  let assert Ok(decision) = decisions.parse_line(sample_line)

  assert decision
    == Decision(
      id: "0001",
      date: "2026-08-07",
      title: "Example",
      status: "accepted",
      category: "architecture",
      tags: ["a", "b"],
      context: "Why this came up.",
      options_considered: [
        ConsideredOption(
          option: "Do nothing",
          verdict: "rejected",
          reason: "Not good enough.",
        ),
        ConsideredOption(
          option: "Do the thing",
          verdict: "chosen",
          reason: "Good enough.",
        ),
      ],
      decision: "Did the thing.",
      verification: "Checked it worked.",
      consequences: "Things are different now.",
      supersedes: None,
      superseded_by: None,
      references: ["src/thing.gleam"],
    )
}

pub fn parse_line_decodes_supersedes_and_superseded_by_when_present_test() {
  let line =
    "{\"id\":\"0002\",\"date\":\"2026-08-08\",\"title\":\"Later\",\"status\":\"accepted\",\"category\":\"x\",\"tags\":[],\"context\":\"c\",\"options_considered\":[],\"decision\":\"d\",\"verification\":\"v\",\"consequences\":\"e\",\"supersedes\":\"0001\",\"superseded_by\":\"0003\",\"references\":[]}"

  let assert Ok(decision) = decisions.parse_line(line)

  assert decision.supersedes == Some("0001")
  assert decision.superseded_by == Some("0003")
}

pub fn parse_line_fails_on_malformed_json_test() {
  assert result.is_error(decisions.parse_line("not json"))
}

pub fn parse_all_returns_newest_decision_first_test() {
  let first =
    "{\"id\":\"0001\",\"date\":\"2026-08-07\",\"title\":\"First\",\"status\":\"accepted\",\"category\":\"x\",\"tags\":[],\"context\":\"c\",\"options_considered\":[],\"decision\":\"d\",\"verification\":\"v\",\"consequences\":\"e\",\"supersedes\":null,\"superseded_by\":null,\"references\":[]}"
  let second =
    "{\"id\":\"0002\",\"date\":\"2026-08-08\",\"title\":\"Second\",\"status\":\"accepted\",\"category\":\"x\",\"tags\":[],\"context\":\"c\",\"options_considered\":[],\"decision\":\"d\",\"verification\":\"v\",\"consequences\":\"e\",\"supersedes\":null,\"superseded_by\":null,\"references\":[]}"
  let contents = first <> "\n" <> second <> "\n"

  let assert Ok([newest, oldest]) = decisions.parse_all(contents)

  assert newest.title == "Second"
  assert oldest.title == "First"
}

pub fn parse_all_ignores_a_trailing_blank_line_test() {
  let line =
    "{\"id\":\"0001\",\"date\":\"2026-08-07\",\"title\":\"Only\",\"status\":\"accepted\",\"category\":\"x\",\"tags\":[],\"context\":\"c\",\"options_considered\":[],\"decision\":\"d\",\"verification\":\"v\",\"consequences\":\"e\",\"supersedes\":null,\"superseded_by\":null,\"references\":[]}"

  let assert Ok([only]) = decisions.parse_all(line <> "\n\n")

  assert only.title == "Only"
}
