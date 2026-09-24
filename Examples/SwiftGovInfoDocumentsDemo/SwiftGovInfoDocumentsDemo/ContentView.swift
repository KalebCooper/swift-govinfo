import SwiftGovInfoDocuments
import SwiftGovInfoDocumentsModels
import SwiftUI

struct ContentView: View {
  @State private var apiKey = ""
  @State private var errorMessage: String?
  @State private var granules: [DocumentMetadata] = []
  @State private var isLoading = false
  @State private var metadata: DocumentMetadata?
  @State private var packageID = "PPP-1929-book1"

  var body: some View {
    NavigationStack {
      Form {
        Section("Official documents") {
          TextField("Package ID", text: $packageID)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
          SecureField("API.data.gov key", text: $apiKey)
          Button("Retrieve metadata and first granule page") {
            Task { await load() }
          }
          .disabled(apiKey.isEmpty || packageID.isEmpty || isLoading)
          if isLoading { ProgressView() }
        }
        if let errorMessage { Section { Text(errorMessage) } }
        if let metadata {
          Section("Metadata") {
            Text(metadata.title ?? "Untitled")
            LabeledContent("Published", value: metadata.dateIssued ?? "Unknown")
            LabeledContent("Modified", value: metadata.lastModified ?? "Unknown")
            LabeledContent("Pages", value: metadata.pages ?? "Unknown")
            Text(
              "Metadata describes the publication. A format link does not prove full-text availability."
            )
            .font(.caption)
          }
          Section("Granules") {
            if granules.isEmpty {
              Text(
                "No granules loaded. Historical books may be available only as complete volumes.")
            }
            ForEach(Array(granules.enumerated()), id: \.offset) { _, granule in
              Text(granule.title ?? granule.granuleID ?? "Untitled")
            }
          }
        }
      }
      .navigationTitle("GovInfo")
      .task { loadRecordedBook() }
    }
  }

  private func load() async {
    isLoading = true
    defer { isLoading = false }
    errorMessage = nil
    granules = []
    do {
      let client = GovInfoClient(configuration: try GovInfoConfiguration(apiKey: apiKey))
      metadata = try await client.package(packageID)
      var pages = try client.granulePages(in: packageID, pageSize: 20).makeAsyncIterator()
      granules = try await pages.next()?.value.granules ?? []
    } catch {
      errorMessage =
        "GovInfo could not complete this request. Check your key, package ID, and quota."
    }
  }

  private func loadRecordedBook() {
    guard metadata == nil, let url = Bundle.main.url(forResource: "ppp-book", withExtension: "json")
    else { return }
    do {
      metadata = try JSONDecoder().decode(DocumentMetadata.self, from: Data(contentsOf: url))
      print("Recorded GovInfo book loaded: \(metadata?.packageID ?? "unknown")")
    } catch {
      errorMessage = "The recorded example could not be read."
    }
  }
}
