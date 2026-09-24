import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftGovInfoDocuments
import SwiftGovInfoDocumentsModels
import SwiftGovInfoDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct ClientTests {
  @Test("A consumer-defined endpoint decodes its own response")
  func aConsumerDefinedEndpointDecodesItsOwnResponse() async throws {
    struct ConsumerSummary: Decodable, Sendable { let packageId: String }
    let transport = MockTransport(results: [
      .success(Response(body: try Fixture.pppBook.data(), status: .ok))
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
    let endpoint = try #require(Endpoint<ConsumerSummary>(path: "/packages/PPP-1929-book1/summary"))
    let result = try await client.value(for: DocumentRequest(endpoint: endpoint))
    #expect(result.packageId == "PPP-1929-book1")
  }

  @Test("All request levels retrieve the same metadata with one authenticated send each")
  func allRequestLevelsRetrieveTheSameMetadataWithOneAuthenticatedSendEach() async throws {
    let body = try Fixture.pppBook.data()
    let transport = MockTransport(
      results: Array(repeating: .success(Response(body: body, status: .ok)), count: 4))
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key", captureBody: true),
      transport: transport)
    let first = try await client.package("PPP-1929-book1")
    let second = try await client.value(for: .package("PPP-1929-book1"))
    let third = try await client.send(.package("PPP-1929-book1"))
    let receipt = try await client.response(for: .package("PPP-1929-book1"))
    #expect(first == second && second == third && third == receipt.value)
    #expect(receipt.body == body)
    #expect(receipt.byteCount == body.count)
    #expect(receipt.status == 200)
    #expect(transport.requests.count == 4)
    #expect(transport.last?.request.path == "/packages/PPP-1929-book1/summary")
    #expect(transport.last?.request.headerFields[HTTPField.Name("X-Api-Key")!] == "test-key")
    #expect(!receipt.url.absoluteString.contains("test-key"))
  }

  @Test("Cancelled requests send nothing")
  func cancelledRequestsSendNothing() async throws {
    let transport = MockTransport()
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
    let (resume, release) = AsyncStream<Void>.makeStream()
    let task = Task {
      for await _ in resume { break }
      do {
        _ = try await client.package("x"); Issue.record("Expected cancellation")
      } catch {
        guard case GovInfoError.transport(.cancelled) = error else { throw error }
      }
    }
    task.cancel()
    release.finish()
    try await task.value
    #expect(transport.requests.isEmpty)
  }

  @Test("Redirects and quota failures retain response headers without following links")
  func redirectsAndQuotaFailuresRetainResponseHeadersWithoutFollowingLinks() async throws {
    for status in [302, 429, 503] {
      let transport = MockTransport(results: [
        .success(
          Response(
            body: try Fixture.quota.data(),
            headers: [.location: "https://evil.example/", .retryAfter: "30"],
            status: .init(code: status)))
      ])
      let client = GovInfoClient(
        configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
      do {
        _ = try await client.package("x"); Issue.record("Expected HTTP failure")
      } catch GovInfoError.httpStatus(let code, let headers) {
        #expect(code == status)
        #expect(headers["retry-after"] == "30")
      }
      #expect(transport.requests.count == 1)
    }
  }

}
