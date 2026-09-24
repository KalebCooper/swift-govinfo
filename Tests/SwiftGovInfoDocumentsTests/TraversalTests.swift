import Foundation
import HTTPCore
import HTTPTesting
import SwiftGovInfoDocuments
import SwiftGovInfoDocumentsModels
import SwiftGovInfoDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct TraversalTests {
  @Test("Cancellation while a granule page is buffered ends iteration without sending")
  func cancellationWhileAGranulePageIsBufferedEndsIterationWithoutSending() async throws {
    let transport = MockTransport(results: [
      .success(Response(body: try Fixture.wcpdGranules.data(), status: .ok))
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
    let (started, signal) = AsyncStream<Void>.makeStream()
    let (resume, release) = AsyncStream<Void>.makeStream()
    let task = Task {
      var iterator = try client.granules(in: "WCPD-1993-01-11", pageSize: 2).makeAsyncIterator()
      _ = try await iterator.next()
      signal.yield()
      for await _ in resume { break }
      do {
        _ = try await iterator.next(); Issue.record("Expected buffered cancellation")
      } catch {
        guard case GovInfoError.transport(.cancelled) = error else { throw error }
      }
      #expect(try await iterator.next() == nil)
    }
    for await _ in started { break }
    task.cancel()
    release.finish()
    signal.finish()
    try await task.value
    #expect(transport.requests.count == 1)
  }

  @Test("Cursor cycles are rejected even when the provider reorders query parameters")
  func cursorCyclesTerminateWithoutAThirdSend() async throws {
    let first = try Fixture.wcpdGranules.data()
    var second = try JSONDecoder().decode([String: JSONValue].self, from: first)
    second["nextPage"] = .string(
      "https://api.govinfo.gov/packages/WCPD-1993-01-11/granules?pageSize=2&offsetMark=*")
    let transport = MockTransport(results: [
      .success(Response(body: first, status: .ok)),
      .success(Response(body: try JSONEncoder().encode(second), status: .ok)),
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
    var pages = try client.granulePages(in: "WCPD-1993-01-11", pageSize: 2).makeAsyncIterator()
    #expect(try await pages.next() != nil)
    do {
      _ = try await pages.next(); Issue.record("Expected a cursor cycle")
    } catch {
      guard case GovInfoError.validation(.repeatedContinuation) = error else { throw error }
    }
    #expect(try await pages.next() == nil)
    #expect(transport.requests.count == 2)
  }

  @Test("Custom endpoint page requests never follow provider links")
  func customEndpointPageRequestsNeverFollowProviderLinks() async throws {
    let transport = MockTransport(results: [
      .success(Response(body: try Fixture.wcpdGranules.data(), status: .ok))
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
    let request = DocumentRequest(
      endpoint: try Endpoint<GranulePage>.granules(in: "WCPD-1993-01-11", pageSize: 2))
    var pages = client.pages(for: request).makeAsyncIterator()
    #expect(try await pages.next() != nil)
    #expect(try await pages.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test("Missing continuation and changed filters are failures")
  func missingContinuationAndChangedFiltersAreFailures() async throws {
    for link in [
      nil, "https://api.govinfo.gov/packages/WCPD-1993-01-11/granules?offsetMark=new&pageSize=3",
    ] as [String?] {
      var fields = try JSONDecoder().decode(
        [String: JSONValue].self, from: Fixture.wcpdGranules.data())
      fields["nextPage"] = link.map(JSONValue.string)
      let transport = MockTransport(results: [
        .success(Response(body: try JSONEncoder().encode(fields), status: .ok))
      ])
      let client = GovInfoClient(
        configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
      var pages = try client.granulePages(in: "WCPD-1993-01-11", pageSize: 2).makeAsyncIterator()
      do {
        _ = try await pages.next(); Issue.record("Expected invalid continuation")
      } catch {
        guard case GovInfoError.validation = error else { throw error }
      }
      #expect(try await pages.next() == nil)
    }
  }

  @Test("Package discovery shares typed execution and keeps capture optional")
  func packageDiscoverySharesTypedExecutionAndKeepsCaptureOptional() async throws {
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.officialPackages.data())
    // The published historical envelope supplies source items; only continuation is made terminal.
    fields["nextPage"] = .null
    let body = try JSONEncoder().encode(fields)
    for window in [
      PackageQuery.Window.modified(
        collection: .bills, from: "2018-01-01T00:00:00Z", through: "2018-12-31T00:00:00Z"),
      .published(collections: [.bills], from: "2018-01-01", through: "2018-12-31"),
    ] {
      let query = try PackageQuery(window: window)
      let request = DocumentRequest.packages(matching: query)
      let transport = MockTransport(
        results: Array(repeating: .success(Response(body: body, status: .ok)), count: 4))
      let client = GovInfoClient(
        configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
      var pages = client.packagePages(matching: query).makeAsyncIterator()
      #expect(transport.requests.isEmpty)
      let page = try #require(try await pages.next())
      #expect(page.body == nil)
      #expect(page.byteCount == body.count)
      #expect(try await pages.next() == nil)
      #expect(try await client.value(for: request) == page.value)
      #expect(try await client.send(request.endpoint) == page.value)
      var packages = client.packages(matching: query).makeAsyncIterator()
      #expect(try await packages.next() == page.value.items.first)
      #expect(transport.requests.count == 4)
      #expect(transport.requests.allSatisfy { $0.request.path == request.endpoint.path })
    }
  }

  @Test("Successful continuation preserves duplicate items and records the actual second URL")
  func successfulContinuationPreservesDuplicateItemsAndRecordsTheActualSecondURL() async throws {
    let first = try Fixture.wcpdGranules.data()
    var terminal = try JSONDecoder().decode([String: JSONValue].self, from: first)
    // Only terminal metadata is changed; the original source items intentionally appear twice.
    terminal["nextPage"] = .null
    let second = try JSONEncoder().encode(terminal)
    let transport = MockTransport(results: [
      .success(Response(body: first, status: .ok)), .success(Response(body: second, status: .ok)),
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key", captureBody: true),
      transport: transport)
    var pages = try client.granulePages(in: "WCPD-1993-01-11", pageSize: 2).makeAsyncIterator()
    let a = try #require(try await pages.next())
    let b = try #require(try await pages.next())
    #expect(a.value.items == b.value.items)
    #expect(b.body == second)
    #expect(b.url.absoluteString == a.value.nextPage)
    #expect(try await pages.next() == nil)
    #expect(transport.requests.count == 2)
  }

}
