#if canImport(Darwin)
import Foundation
import HTTPURLSession

extension GovInfoClient {
  /// Creates an Apple client using the supplied URL session.
  ///
  /// `try GovInfoClient(configuration: GovInfoConfiguration(apiKey: key))` never reads a key itself.
  public init(
    clock: any Clock<Duration> = ContinuousClock(), configuration: GovInfoConfiguration,
    retryPolicy: RetryPolicy = .disabled, session: URLSession = .shared
  ) {
    self.init(
      clock: clock, configuration: configuration, retryPolicy: retryPolicy,
      transport: URLSessionTransport(session: session))
  }
}
#endif
