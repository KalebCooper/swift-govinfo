import Foundation

/// Official response bodies, with per-file source receipts beside them.
package enum Fixture: String, CaseIterable, Sendable {
  /// GET https://www.govinfo.gov/bulkdata/BILLSTATUS/119/hr/BILLSTATUS-119hr1.xml.
  case billStatus = "billstatus.xml"
  /// GET /collections.
  case collections = "collections.json"
  /// GET /packages/DCPD-202600542/summary.
  case dcpdCurrent = "dcpd-current.json"
  /// GET /packages/DCPD-200900009/summary.
  case dcpdHistorical = "dcpd-historical.json"
  /// GET https://www.govinfo.gov/metadata/pkg/DCPD-200900009/mods.xml.
  case dcpdMODS = "dcpd-mods.xml"
  /// GET /packages/FR-1936-03-14/summary.
  case frHistorical = "fr-historical.json"
  /// GET https://www.govinfo.gov/content/pkg/FR-1936-03-14/pdf/FR-1936-03-14.pdf.
  case frPDF = "fr.pdf"
  /// Official repository package-list example using the older numeric offset contract.
  case officialPackages = "official-packages.json"
  /// GET /packages/PPP-1929-book1/summary.
  case pppBook = "ppp-book.json"
  /// GET /packages/PPP-1929-book1/granules?offsetMark=*&pageSize=2.
  case pppGranules = "ppp-granules.json"
  /// GET https://www.govinfo.gov/content/pkg/PPP-2009-book1/xml/PPP-2009-book1.xml.
  case pppXML = "ppp.xml"
  /// Official quota failure during the recorded second WCPD page request.
  case quota = "wcpd-granules-next.json"
  /// GovInfo documentation example for the CPD relationship, not a live API response.
  case relatedCPD = "related-cpd-published.json"
  /// GovInfo documentation relationship directory, not a live API response.
  case relationships = "relationships-published.json"
  /// GET /packages/STATUTE-1/summary.
  case statute = "statute.json"
  /// GET /packages/WCPD-1993-01-11/summary.
  case wcpd = "wcpd.json"
  /// GET /packages/WCPD-1993-01-11/granules/WCPD-1993-01-11-Pg1/summary.
  case wcpdGranule = "wcpd-granule.json"
  /// GET /packages/WCPD-1993-01-11/granules?offsetMark=*&pageSize=2.
  case wcpdGranules = "wcpd-granules.json"

  package func data() throws -> Data {
    guard
      let url = Bundle.module.url(
        forResource: rawValue, withExtension: nil, subdirectory: "Fixtures")
    else {
      throw CocoaError(.fileNoSuchFile)
    }
    return try Data(contentsOf: url)
  }
}
