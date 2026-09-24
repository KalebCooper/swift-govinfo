import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftGovInfoDocuments
import SwiftGovInfoDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct RetryTests {
  @Test("An opted-in retry honors Retry-After at one networking layer")
  func anOptedInRetryHonorsRetryAfterAtOneNetworkingLayer() async throws {
    let clock = RecordingClock()
    let transport = MockTransport(results: [
      .success(Response(headers: [.retryAfter: "30"], status: .serviceUnavailable)),
      .success(Response(body: try Fixture.pppBook.data(), status: .ok)),
    ])
    let policy = RetryPolicy(
      backoff: BackoffSchedule(delays: [.seconds(1)]), maxAttempts: 2,
      retryable: { $0.failure.statusCode == 503 })
    let client = GovInfoClient(
      clock: clock, configuration: try GovInfoConfiguration(apiKey: "test-key"),
      retryPolicy: policy, transport: transport)
    let task = Task { try await client.package("PPP-1929-book1") }
    await clock.waitForPendingSleep()
    #expect(transport.requests.count == 1)
    clock.advanceAll()
    #expect(try await task.value.packageID == "PPP-1929-book1")
    #expect(clock.sleeps == [.seconds(30)])
    #expect(transport.requests.count == 2)
  }

}
