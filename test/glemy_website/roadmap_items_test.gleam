import gleam/option.{None, Some}
import gleam/result
import glemy_website/roadmap_items.{RoadmapItem}

const sample_line = "{\"id\":\"RM-001\",\"phase\":1,\"phase_title\":\"Foundation\",\"title\":\"Example\",\"status\":\"completed\",\"description\":\"What it is.\",\"resolution\":\"Approved.\",\"decision_refs\":[\"0003\"],\"doc_refs\":[\"docs/technical-architecture.md#2.2\"]}"

pub fn parse_line_decodes_a_real_roadmap_item_shape_test() {
  let assert Ok(item) = roadmap_items.parse_line(sample_line)

  assert item
    == RoadmapItem(
      id: "RM-001",
      phase: 1,
      phase_title: "Foundation",
      title: "Example",
      status: "completed",
      description: "What it is.",
      resolution: Some("Approved."),
      decision_refs: ["0003"],
      doc_refs: ["docs/technical-architecture.md#2.2"],
    )
}

pub fn parse_line_decodes_a_null_resolution_test() {
  let line =
    "{\"id\":\"RM-002\",\"phase\":1,\"phase_title\":\"Foundation\",\"title\":\"Planned thing\",\"status\":\"planned\",\"description\":\"d\",\"resolution\":null,\"decision_refs\":[],\"doc_refs\":[]}"

  let assert Ok(item) = roadmap_items.parse_line(line)

  assert item.resolution == None
  assert item.decision_refs == []
  assert item.doc_refs == []
}

pub fn parse_line_fails_on_malformed_json_test() {
  assert result.is_error(roadmap_items.parse_line("not json"))
}

pub fn parse_all_preserves_file_order_test() {
  let first =
    "{\"id\":\"RM-001\",\"phase\":1,\"phase_title\":\"Foundation\",\"title\":\"First\",\"status\":\"completed\",\"description\":\"d\",\"resolution\":null,\"decision_refs\":[],\"doc_refs\":[]}"
  let second =
    "{\"id\":\"RM-002\",\"phase\":1,\"phase_title\":\"Foundation\",\"title\":\"Second\",\"status\":\"planned\",\"description\":\"d\",\"resolution\":null,\"decision_refs\":[],\"doc_refs\":[]}"
  let contents = first <> "\n" <> second <> "\n"

  let assert Ok([one, two]) = roadmap_items.parse_all(contents)

  assert one.title == "First"
  assert two.title == "Second"
}

pub fn parse_all_ignores_a_trailing_blank_line_test() {
  let line =
    "{\"id\":\"RM-001\",\"phase\":1,\"phase_title\":\"Foundation\",\"title\":\"Only\",\"status\":\"completed\",\"description\":\"d\",\"resolution\":null,\"decision_refs\":[],\"doc_refs\":[]}"

  let assert Ok([only]) = roadmap_items.parse_all(line <> "\n\n")

  assert only.title == "Only"
}
