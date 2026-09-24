import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftGovInfoDocuments
import SwiftGovInfoDocumentsModels
import SwiftGovInfoDocumentsTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct ContentClientTests {
  @Test(
    "BILLSTATUS request levels decode the same bytes without sending API credentials to content")
  func billStatusRequestLevelsDecodeTheSameBytesWithoutSendingAPICredentialsToContent() async throws
  {
    let data = try Fixture.billStatus.data()
    let transport = MockTransport(
      results: Array(
        repeating: .success(
          Response(body: data, headers: [.contentType: "application/xml"], status: .ok)), count: 3))
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key", captureBody: true),
      transport: transport)
    let url = try #require(
      URL(string: "https://www.govinfo.gov/bulkdata/BILLSTATUS/119/hr/BILLSTATUS-119hr1.xml"))
    let direct = try await client.billStatus(at: url)
    let reusable = try await client.value(for: .billStatus(at: url))
    let response = try await client.response(for: .billStatus(at: url))
    #expect(direct == reusable && reusable == response.value)
    #expect(response.body == data)
    #expect(response.headers["content-type"] == "application/xml")
    #expect(transport.requests.count == 3)
    #expect(transport.last?.request.authority == "www.govinfo.gov")
    #expect(transport.last?.request.headerFields[HTTPField.Name("X-Api-Key")!] == nil)
  }

  @Test("Collection discovery uses equivalent typed operations")
  func collectionDiscoveryUsesEquivalentTypedOperations() async throws {
    let bytes = try Fixture.collections.data()
    let transport = MockTransport(
      results: Array(repeating: .success(Response(body: bytes, status: .ok)), count: 3))
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key"), transport: transport)
    let first = try await client.collections()
    let second = try await client.value(for: .collections)
    let third = try await client.send(.collections)
    #expect(first == second && second == third)
    #expect(transport.requests.count == 3)
  }

  @Test("Response limits stop buffered execution before returning partial values")
  func responseLimitsStopBufferedExecutionBeforeReturningPartialValues() async throws {
    let transport = MockTransport(answers: [
      .success(
        MockTransport.Answer(chunks: [Data(repeating: 1, count: 10), Data(repeating: 2, count: 10)])
      )
    ])
    let client = GovInfoClient(
      configuration: try GovInfoConfiguration(apiKey: "test-key", maximumResponseBytes: 15),
      transport: transport)
    do {
      _ = try await client.package("x"); Issue.record("Expected size failure")
    } catch {
      guard case GovInfoError.bodyTooLarge = error else { throw error }
    }
    #expect(transport.requests.count == 1)
  }

}
