import gleam/string
import glemy_website/asset_hash

pub fn hash_is_deterministic_test() {
  let a = asset_hash.hash(<<"same content":utf8>>)
  let b = asset_hash.hash(<<"same content":utf8>>)
  assert a == b
}

pub fn hash_differs_for_different_content_test() {
  let a = asset_hash.hash(<<"content a":utf8>>)
  let b = asset_hash.hash(<<"content b":utf8>>)
  assert a != b
}

pub fn hash_is_eight_lowercase_hex_characters_test() {
  let digest = asset_hash.hash(<<"anything":utf8>>)
  assert digest == string.lowercase(digest)
  assert string.length(digest) == 8
}

pub fn hash_matches_the_known_sha256_of_hello_test() {
  // A well-known, independently verifiable SHA-256 digest
  // (sha256("hello") = 2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa74
  // 25e73043362938b9824), truncated to this module's 8-character
  // length -- pins the algorithm/encoding/truncation together against
  // a real external reference, not just internal self-consistency.
  assert asset_hash.hash(<<"hello":utf8>>) == "2cf24dba"
}

pub fn hashed_filename_inserts_hash_before_the_extension_test() {
  assert asset_hash.hashed_filename("style.css", "a1b2c3d4")
    == "style.a1b2c3d4.css"
}

pub fn hashed_filename_handles_a_multi_dot_name_test() {
  assert asset_hash.hashed_filename("archive.tar.gz", "deadbeef")
    == "archive.deadbeef.tar.gz"
}

pub fn hashed_filename_appends_when_there_is_no_extension_test() {
  assert asset_hash.hashed_filename("Makefile", "cafef00d")
    == "Makefile.cafef00d"
}
