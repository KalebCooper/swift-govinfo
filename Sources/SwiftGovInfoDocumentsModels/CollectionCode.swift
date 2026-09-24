/// An open GovInfo collection identifier, including summary-specific WCPD and DCPD codes.
///
/// Use `.cpd` for discovery; package summaries may report `.dcpd` or `.wcpd`.
public struct CollectionCode: Codable, Hashable, RawRepresentable, Sendable {
  /// The source identifier, without normalization.
  public let rawValue: String

  /// Congressional bills.
  public static let bills = Self(rawValue: "BILLS")
  /// Congressional bill status XML.
  public static let billStatus = Self(rawValue: "BILLSTATUS")
  /// Compilation of Presidential Documents discovery collection.
  public static let cpd = Self(rawValue: "CPD")
  /// Daily Compilation of Presidential Documents summary code.
  public static let dcpd = Self(rawValue: "DCPD")
  /// Federal Register.
  public static let fr = Self(rawValue: "FR")
  /// Public Papers of the Presidents.
  public static let ppp = Self(rawValue: "PPP")
  /// Statutes at Large.
  public static let statute = Self(rawValue: "STATUTE")
  /// Weekly Compilation of Presidential Documents summary code.
  public static let wcpd = Self(rawValue: "WCPD")

  /// Creates a known or future collection identifier.
  public init(rawValue: String) { self.rawValue = rawValue }
  /// Decodes the provider's string identifier.
  public init(from decoder: any Decoder) throws {
    self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
  }
  /// Encodes the identifier as a string.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
