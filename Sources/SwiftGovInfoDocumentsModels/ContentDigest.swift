/// A digest of the complete bytes delivered to a streaming consumer.
///
/// A receipt is returned only after the source stream and every consumer write succeeded.
public struct ContentDigest: Hashable, Sendable {
  /// The lowercase SHA-256 hexadecimal digest.
  public let sha256: String
  /// Creates a SHA-256 digest value for a completed source body.
  public init(sha256: String) { self.sha256 = sha256 }
}
