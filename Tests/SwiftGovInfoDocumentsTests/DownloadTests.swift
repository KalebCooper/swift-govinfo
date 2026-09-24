import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftGovInfoDocuments
import SwiftGovInfoDocumentsModels
import SwiftGovInfoDocumentsTestSupport
import Synchronization
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct DownloadTests {
  @Test("A failing consumer cannot receive a completed download receipt")
  func aFailingConsumerCannotReceiveACompletedDownloadReceipt() async throws {
    enum SinkError: Error { case failed }
    let transport = MockTransport(answers: [
      .success(MockTransport.Answer(chunks: [Data("a".utf8), Data("b".utf8)]))
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
    let endpoint = try #require(Endpoint<DocumentContent>(path: "/packages/x/pdf"))
    do {
      _ = try await client.download(endpoint) { _ in throw SinkError.failed }
      Issue.record("Expected consumer failure")
    } catch {
      guard case GovInfoError.consumerFailure = error else { throw error }
    }
  }

  @Test("A streamed representation returns a SHA-256 receipt for exactly the consumed bytes")
  func aStreamedRepresentationReturnsASHA256ReceiptForExactlyTheConsumedBytes() async throws {
    let data = try Fixture.frPDF.data()
    let transport = MockTransport(answers: [
      .success(MockTransport.Answer(chunks: [data.prefix(100), data.dropFirst(100)]))
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key", captureBody: true),
      transport: transport)
    let endpoint = try #require(
      Endpoint<DocumentContent>(
        accept: "application/pdf",
        link: URL(
          string: "https://www.govinfo.gov/content/pkg/FR-1936-03-14/pdf/FR-1936-03-14.pdf")!))
    let consumed = Mutex(Data())
    let receipt = try await client.download(for: .representation(endpoint)) { chunk in
      consumed.withLock { $0.append(chunk) }
    }
    #expect(consumed.withLock { $0 } == data)
    #expect(receipt.byteCount == 3256897)
    #expect(receipt.body == nil)
    #expect(
      receipt.value.sha256 == "8d77ce0271b7919147b5c879bcd3fd637b0fc576a93cdf7ddf17b092f89cd415")
    #expect(transport.requests.count == 1)
    #expect(transport.last?.request.headerFields[HTTPField.Name("X-Api-Key")!] == nil)
  }

  @Test("Streamed format mismatches cannot produce a successful receipt")
  func formatMismatchCannotProduceAReceipt() async throws {
    for media in ["application/pdf", "application/xml", "application/zip"] {
      let transport = MockTransport(answers: [
        .success(
          MockTransport.Answer(chunks: [Data("<html>".utf8), Data("unavailable</html>".utf8)]))
      ])
      let client = GovInfoClient(
        configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
      let endpoint = try #require(Endpoint<DocumentContent>(accept: media, path: "/packages/x/pdf"))
      do {
        _ = try await client.download(endpoint) { _ in }
        Issue.record("Expected a format mismatch")
      } catch {
        guard case GovInfoError.unexpectedContent = error else { throw error }
      }
    }
  }

  @Test("Cancellation during consumption cannot produce a successful receipt")
  func midstreamCancellationCannotProduceAReceipt() async throws {
    let transport = MockTransport(answers: [
      .success(MockTransport.Answer(chunks: [Data("a".utf8), Data("b".utf8)]))
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
    let endpoint = try #require(Endpoint<DocumentContent>(path: "/packages/x/pdf"))
    let (started, signal) = AsyncStream<Void>.makeStream()
    let (resume, release) = AsyncStream<Void>.makeStream()
    let task = Task<Void, any Error> {
      do {
        _ = try await client.download(endpoint) { _ in
          signal.yield()
          for await _ in resume { break }
        }
        Issue.record("Expected cancellation")
      } catch {
        guard case GovInfoError.transport(.cancelled) = error else { throw error }
      }
    }
    for await _ in started { break }
    task.cancel()
    release.finish()
    signal.finish()
    try await task.value
    #expect(transport.requests.count == 1)
  }

}
