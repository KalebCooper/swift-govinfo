import Foundation
import SwiftGovInfoDocumentsModels
import SwiftGovInfoDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct ContentTests {
  @Test("BILLSTATUS retains bill identity and the complete source hierarchy")
  func billStatusRetainsBillIdentityAndTheCompleteSourceHierarchy() throws {
    let status = try BillStatus.decode(Fixture.billStatus.data())
    #expect(status.congress == "119")
    #expect(status.number == "1")
    #expect(status.type == "HR")
    #expect(status.version == "3.0.0")
    #expect(!status.bill.children(named: "actions").isEmpty)
    #expect(!status.bill.children(named: "relatedBills").isEmpty)
    #expect(status.bill.children(named: "updateDate").first?.text == "2026-05-08T14:41:30Z")
  }

  @Test("Collection discovery preserves null counts and open codes")
  func collectionDiscoveryPreservesNullCountsAndOpenCodes() throws {
    let directory = try JSONDecoder().decode(
      CollectionDirectory.self, from: Fixture.collections.data())
    let bills = try #require(directory.collections.first { $0.collectionCode == .bills })
    #expect(bills.granuleCount == nil)
    #expect(bills.fields["granuleCount"] == .null)
    #expect(directory.collections.contains { $0.collectionCode == .cpd })
    #expect(
      try JSONDecoder().decode(CollectionCode.self, from: Data("\"FUTURE\"".utf8)).rawValue
        == "FUTURE")
  }

  @Test("Collection directories preserve future fields and explicit null values")
  func directoryUnknownFieldsRoundTrip() throws {
    var fields = try JSONDecoder().decode(
      [String: JSONValue].self, from: Fixture.collections.data())
    fields["future"] = .object(["nullable": .null, "value": .string("source")])
    let directory = try JSONDecoder().decode(
      CollectionDirectory.self, from: JSONEncoder().encode(fields))
    #expect(directory.fields == fields)
    #expect(
      try JSONDecoder().decode([String: JSONValue].self, from: JSONEncoder().encode(directory))
        == fields)
  }

  @Test("Historical metadata and full document XML remain distinct")
  func historicalMetadataAndFullDocumentXMLRemainDistinct() throws {
    let mods = try GovInfoXML.decode(Fixture.dcpdMODS.data())
    let papers = try GovInfoXML.decode(Fixture.pppXML.data())
    #expect(mods.name == "mods")
    #expect(papers.name == "XML")
    #expect(papers.children(named: "president").first?.text.contains("Barack Obama") == true)
    #expect(RepresentationFormat.mods.isMetadata)
    #expect(!RepresentationFormat.xml.isMetadata)
    let book = try JSONDecoder().decode(DocumentMetadata.self, from: Fixture.pppBook.data())
    #expect(try book.representation(.html) == nil)
    #expect(try book.representation(.pdf)?.path == "/packages/PPP-1929-book1/pdf")
    #expect(try Fixture.frPDF.data().starts(with: Data("%PDF-".utf8)))
  }

  @Test("Modified and published queries validate dates and preserve date meaning")
  func modifiedAndPublishedQueriesValidateDatesAndPreserveDateMeaning() throws {
    let query = try PackageQuery(
      pageSize: 2,
      window: .modified(
        collection: .cpd, from: "2026-09-01T00:00:00Z", through: "2026-09-23T00:00:00Z"))
    #expect(
      Endpoint<PackagePage>.packages(matching: query).path
        == "/collections/CPD/2026-09-01T00:00:00Z/2026-09-23T00:00:00Z?offsetMark=*&pageSize=2")
    #expect(throws: GovInfoValidationError.invalidDateWindow) {
      try PackageQuery(
        window: .published(collections: [.cpd], from: "2025-02-29", through: "2026-01-01"))
    }
    let stored = DocumentRequest.packages(matching: query)
    #expect(stored.endpoint == .packages(matching: query))
  }

  @Test("XML limits reject deep trees and UTF-16 entity declarations")
  func xmlLimitsRejectDeepTreesAndOtherEncodings() throws {
    let nested = String(repeating: "<r>", count: 257) + String(repeating: "</r>", count: 257)
    #expect(throws: GovInfoDecodingError.limitExceeded) { try GovInfoXML.decode(Data(nested.utf8)) }
    let entities = "<!DOCTYPE r [<!ENTITY x 'expanded'>]><r>&x;</r>"
    let bytes = try #require(entities.data(using: .utf16LittleEndian))
    #expect(throws: GovInfoDecodingError.malformedXML) { try GovInfoXML.decode(bytes) }
    #expect(throws: GovInfoDecodingError.limitExceeded) {
      try GovInfoXML.decode(Data(repeating: 32, count: 16 * 1024 * 1024 + 1))
    }
  }

  @Test("XML rejects malformed documents and entity declarations")
  func xmlRejectsMalformedDocumentsAndEntityDeclarations() throws {
    for value in [
      "<billStatus>",
      "<!DOCTYPE billStatus [<!ENTITY x SYSTEM 'file:///etc/passwd'>]><billStatus>&x;</billStatus>",
      "<billStatus><bill/></billStatus>",
    ] {
      #expect(throws: GovInfoDecodingError.self) { try BillStatus.decode(Data(value.utf8)) }
    }
    let node = try GovInfoXML.decode(Data("<r a='1'>a<x/>b<![CDATA[c]]>&amp;</r>".utf8))
    #expect(node.text == "abc&")
    #expect(node.attributes == ["a": "1"])
    #expect(node.children.map(\.name) == ["x"])
    let namespaced = try GovInfoXML.decode(
      Data("<s:r xmlns:s='source'><s:empty/><s:zero>0</s:zero><s:future/></s:r>".utf8))
    #expect(namespaced.name == "s:r")
    #expect(namespaced.attributes["xmlns:s"] == "source")
    #expect(namespaced.children.map(\.text) == ["", "0", ""])
  }

}
