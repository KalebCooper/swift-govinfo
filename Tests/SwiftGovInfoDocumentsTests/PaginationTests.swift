import Foundation
import HTTPCore
import HTTPTesting
import SwiftGovInfoDocuments
import SwiftGovInfoDocumentsModels
import SwiftGovInfoDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct PaginationTests {
  @Test("Granule traversal is lazy and independent and breaking early sends no second page")
  func granuleTraversalIsLazyAndIndependentAndBreakingEarlySendsNoSecondPage() async throws {
    let body = try Fixture.wcpdGranules.data()
    let transport = MockTransport(
      results: Array(repeating: .success(Response(body: body, status: .ok)), count: 2))
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
    let items = try client.granules(in: "WCPD-1993-01-11", pageSize: 2)
    var first = items.makeAsyncIterator()
    var second = items.makeAsyncIterator()
    #expect(transport.requests.isEmpty)
    #expect(try await first.next()?.granuleID == "WCPD-1993-01-11-Pg1")
    #expect(try await first.next()?.granuleID == "WCPD-1993-01-11-Pg1-2")
    #expect(transport.requests.count == 1)
    #expect(try await second.next()?.granuleID == "WCPD-1993-01-11-Pg1")
    #expect(transport.requests.count == 2)
  }

  @Test("Later-page failures send the exact next link and terminate the iterator")
  func laterPageFailuresSendTheExactNextLinkAndTerminateTheIterator() async throws {
    let body = try Fixture.wcpdGranules.data()
    let transport = MockTransport(results: [
      .success(Response(body: body, status: .ok)),
      .success(Response(body: try Fixture.quota.data(), status: .init(code: 429))),
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key", captureBody: true),
      transport: transport)
    var iterator = try client.granulePages(in: "WCPD-1993-01-11", pageSize: 2).makeAsyncIterator()
    let first = try await iterator.next()
    #expect(first?.body == body)
    do {
      _ = try await iterator.next(); Issue.record("Expected quota failure")
    } catch GovInfoError.httpStatus(let code, _) { #expect(code == 429) }
    #expect(try await iterator.next() == nil)
    let page = try JSONDecoder().decode(GranulePage.self, from: body)
    #expect(
      transport.last?.request.path
        == page.nextPage?.replacingOccurrences(of: "https://api.govinfo.gov", with: ""))
  }

  @Test("Malformed continuation fails before the page is yielded")
  func malformedContinuationFailsBeforeThePageIsYielded() async throws {
    for link in [
      "https://evil.example/x",
      "https://api.govinfo.gov/packages/WCPD-1993-01-11/granules?offsetMark=*&pageSize=2", "",
    ] {
      var fields = try JSONDecoder().decode(
        [String: JSONValue].self, from: Fixture.wcpdGranules.data())
      fields["nextPage"] = .string(link)
      let body = try JSONEncoder().encode(fields)
      let transport = MockTransport(results: [.success(Response(body: body, status: .ok))])
      let client = GovInfoClient(
        configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
      var iterator = try client.granulePages(in: "WCPD-1993-01-11", pageSize: 2).makeAsyncIterator()
      do {
        _ = try await iterator.next(); Issue.record("Expected invalid continuation")
      } catch {
        guard case GovInfoError.validation = error else { throw error }
      }
      #expect(try await iterator.next() == nil)
      #expect(transport.requests.count == 1)
    }
  }

  @Test("Zero-granule books finish after one page")
  func zeroGranuleBooksFinishAfterOnePage() async throws {
    let transport = MockTransport(results: [
      .success(Response(body: try Fixture.pppGranules.data(), status: .ok))
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
    var iterator = try client.granulePages(in: "PPP-1929-book1", pageSize: 2).makeAsyncIterator()
    #expect(try await iterator.next()?.value.count == 0)
    #expect(try await iterator.next() == nil)
    #expect(transport.requests.count == 1)
  }

}
