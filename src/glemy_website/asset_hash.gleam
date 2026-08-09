//// A short, deterministic content hash for cache-busting build output
//// filenames -- see `docs/technical-architecture.md` §3.3, RM-024.
////
//// Pure and file-I/O-free on purpose: everything that actually reads a
//// file or directory lives in `build.gleam`, so this module's only
//// job -- turning bytes into a short, stable hex string -- is fully
//// unit-testable without touching the filesystem.
////
//// SHA-256 via `gleam_crypto` (an official `gleam-lang` package,
//// dual-target) rather than a hand-rolled Erlang `:crypto` FFI call --
//// no cryptographic property is actually needed here (a fast, non-
//// cryptographic hash would do), but a real, already-typed, already-
//// trusted library beats new raw FFI for something this small.

import gleam/bit_array
import gleam/crypto
import gleam/string

/// How many hex characters of the digest to keep -- 8 (32 bits) is
/// standard practice for content-hashed build filenames (matches, e.g.,
/// Webpack's own default `contenthash` length) and is vastly more
/// collision-resistant than this site's asset count could ever need.
const digest_length = 8

/// ```gleam
/// hash(<<"hello":utf8>>)
/// // -> "2cf24dba"
/// ```
pub fn hash(data: BitArray) -> String {
  crypto.hash(crypto.Sha256, data)
  |> bit_array.base16_encode
  |> string.lowercase
  |> string.slice(0, digest_length)
}

/// Inserts `hash` between a filename and its extension --
/// `hashed_filename("style.css", "a1b2c3d4")` -> `"style.a1b2c3d4.css"`.
/// Assumes exactly one `.` (every real filename this site hashes has
/// one); a name with no `.` gets the hash appended instead of inserted,
/// which is still a valid, still-unique filename, just not the
/// conventional shape -- not worth a more general implementation for a
/// case this codebase never actually produces.
pub fn hashed_filename(filename: String, hash: String) -> String {
  case string.split(filename, ".") {
    [name, ..rest] if rest != [] ->
      name <> "." <> hash <> "." <> string.join(rest, ".")
    _ -> filename <> "." <> hash
  }
}
