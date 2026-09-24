/// Explicit GovInfo credentials and bounded response policy.
///
/// The library never reads an environment variable, logs a key, or adds a key to a URL.
public struct GovInfoConfiguration: Sendable {
  let apiKey: String
  /// Whether receipts retain the complete body used to decode each response.
  public let captureBody: Bool
  /// Maximum buffered response size in bytes; defaults to 16 MiB.
  public let maximumResponseBytes: Int

  /// Creates configuration with a caller-supplied API.data.gov key.
  /// - Throws: `GovInfoError.invalidCredentials` for empty or control-containing credentials,
  ///   or `GovInfoError.bodyTooLarge` for a nonpositive limit.
  public init(
    apiKey: String, captureBody: Bool = false, maximumResponseBytes: Int = 16 * 1024 * 1024
  ) throws(GovInfoError) {
    guard !apiKey.isEmpty,
      !apiKey.unicodeScalars.contains(where: { $0.properties.generalCategory == .control })
    else {
      throw .invalidCredentials
    }
    guard maximumResponseBytes > 0 else { throw .bodyTooLarge }
    self.apiKey = apiKey
    self.captureBody = captureBody
    self.maximumResponseBytes = maximumResponseBytes
  }
}
