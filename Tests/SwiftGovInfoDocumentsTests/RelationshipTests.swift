import Foundation
import HTTPCore
import HTTPTesting
import SwiftGovInfoDocuments
import SwiftGovInfoDocumentsModels
import SwiftGovInfoDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct RelationshipTests {
  @Test("An old numeric-offset recording decodes but is never mistaken for a current cursor")
  func anOldNumericOffsetRecordingDecodesButIsNeverMistakenForACurrentCursor() throws {
    let page = try JSONDecoder().decode(PackagePage.self, from: Fixture.officialPackages.data())
    #expect(page.count == 197925)
    #expect(page.packages.first?.packageID == "BILLS-115hr4403rh")
    let endpoint = try #require(
      Endpoint<PackagePage>(
        path: "/collections/BILLS/2018-01-01T00:00:00Z/?offsetMark=*&pageSize=100"))
    #expect(throws: GovInfoValidationError.repeatedContinuation) {
      try endpoint.continuation(after: page)
    }
  }

  @Test("Published relationships retain their source meaning and linked documents")
  func publishedRelationshipsRetainTheirSourceMeaningAndLinkedDocuments() async throws {
    let directoryData = try Fixture.relationships.data()
    let relatedData = try Fixture.relatedCPD.data()
    let transport = MockTransport(results: [
      .success(Response(body: directoryData, status: .ok)),
      .success(Response(body: relatedData, status: .ok)),
      .success(Response(body: directoryData, status: .ok)),
      .success(Response(body: relatedData, status: .ok)),
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
    let directory = try await client.relationships(for: "BILLS-114hr34enr")
    let cpd = try #require(directory.relationships.first { $0.collection == .cpd })
    #expect(cpd.relationship == "Presidential Signing Statements and Remarks")
    let related = try await client.relatedDocuments(at: cpd.relationshipLink)
    #expect(related.relatedID == "BILLS-114hr34enr")
    #expect(related.results.first?.packageID == "DCPD-201600845")
    #expect(related.results.first?.dateIssued == "2016-12-13")
    #expect(try await client.value(for: .relationships(for: "BILLS-114hr34enr")) == directory)
    #expect(try await client.send(.relatedDocuments(at: cpd.relationshipLink)) == related)
    #expect(transport.requests.count == 4)
  }

}
