import Foundation
import SwiftGovInfoDocumentsModels
import SwiftGovInfoDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct MetadataTests {
  @Test("Book-only packages retain pages and an empty granule inventory")
  func bookOnlyPackagesRetainPagesAndAnEmptyGranuleInventory() throws {
    let book = try JSONDecoder().decode(DocumentMetadata.self, from: Fixture.pppBook.data())
    let page = try JSONDecoder().decode(GranulePage.self, from: Fixture.pppGranules.data())
    #expect(book.packageID == "PPP-1929-book1")
    #expect(book.pages == "870")
    #expect(book.download?["txtLink"] == nil)
    #expect(page.count == 0)
    #expect(page.items.isEmpty)
    #expect(page.hasNextPage)
    #expect(page.fields["offset"] == .null)
  }

  @Test(
    "Current and historical metadata round trips without dropping source fields",
    arguments: [
      Fixture.dcpdCurrent, .dcpdHistorical, .frHistorical, .pppBook, .statute, .wcpd, .wcpdGranule,
    ])
  func currentAndHistoricalMetadataRoundTripsWithoutDroppingSourceFields(fixture: Fixture) throws {
    let bytes = try fixture.data()
    let metadata = try JSONDecoder().decode(DocumentMetadata.self, from: bytes)
    let original = try JSONDecoder().decode(JSONValue.self, from: bytes)
    let encoded = try JSONEncoder().encode(metadata)
    #expect(try JSONDecoder().decode(JSONValue.self, from: encoded) == original)
  }

  @Test("Endpoints reject credential-bearing and cross-origin links")
  func endpointsRejectCredentialBearingAndCrossOriginLinks() throws {
    for value in [
      "http://api.govinfo.gov/packages/x", "https://evil.example/packages/x",
      "https://user@api.govinfo.gov/x", "https://api.govinfo.gov/x#f",
      "https://api.govinfo.gov/x?api_key=secret", "https://api.govinfo.gov/%2e%2e/x",
      "https://api.govinfo.gov:444/x",
    ] {
      #expect(Endpoint<DocumentMetadata>(link: try #require(URL(string: value))) == nil)
    }
    #expect(Endpoint<DocumentMetadata>(path: "//evil.example/x") == nil)
    #expect(throws: GovInfoValidationError.invalidPageSize) {
      try Endpoint<GranulePage>.granules(in: "x", pageSize: 1001)
    }
    #expect(throws: GovInfoValidationError.invalidIdentifier) {
      try Endpoint<DocumentMetadata>.package("")
    }
  }

  @Test("Publication and modification dates remain distinct")
  func publicationAndModificationDatesRemainDistinct() throws {
    let current = try JSONDecoder().decode(DocumentMetadata.self, from: Fixture.dcpdCurrent.data())
    #expect(current.collectionCode == .dcpd)
    #expect(current.dateIssued == "2026-08-14")
    #expect(current.lastModified == "2026-09-22T22:20:15Z")
    let statute = try JSONDecoder().decode(DocumentMetadata.self, from: Fixture.statute.data())
    #expect(statute.dateIssued == "1845-03-03")
    #expect(statute.fields["congress"] == .string("28"))
    #expect(statute.volume == "1")
  }

  @Test("Stored and consumer-defined request factories infer their response type")
  func storedAndConsumerDefinedRequestFactoriesInferTheirResponseType() throws {
    let request = try DocumentRequest.package("PPP-1929-book1")
    let custom = try DocumentRequest.hooverBook()
    #expect(request == custom)
    #expect(request.endpoint.path == "/packages/PPP-1929-book1/summary")
  }
}

extension DocumentRequest where Response == DocumentMetadata {
  fileprivate static func hooverBook() throws(GovInfoValidationError) -> Self {
    try .package("PPP-1929-book1")
  }

}
