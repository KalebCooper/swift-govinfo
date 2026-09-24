#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A JSON value preserving provider fields, explicit nulls, and array order.
///
/// Read `record.fields["newField"]` when a collection adds metadata not yet named by this package.
public enum JSONValue: Codable, Hashable, Sendable {
  /// An ordered JSON array.
  case array([JSONValue])
  /// A Boolean value.
  case bool(Bool)
  /// An explicit null, distinct from an absent dictionary key.
  case null
  /// A decimal JSON number. Original numeric spelling remains in response bytes.
  case number(Decimal)
  /// An object retaining every key.
  case object([String: JSONValue])
  /// An unmodified string.
  case string(String)

  /// Decodes a JSON value without dropping unknown fields.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let value = try? container.decode(Bool.self) {
      self = .bool(value)
    } else if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let value = try? container.decode(Decimal.self) {
      self = .number(value)
    } else if let value = try? container.decode([JSONValue].self) {
      self = .array(value)
    } else {
      self = .object(try container.decode([String: JSONValue].self))
    }
  }

  /// Encodes the value, retaining explicit nulls.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .array(let value): try container.encode(value)
    case .bool(let value): try container.encode(value)
    case .null: try container.encodeNil()
    case .number(let value): try container.encode(value)
    case .object(let value): try container.encode(value)
    case .string(let value): try container.encode(value)
    }
  }

  /// The string when this is a string value, otherwise nil.
  public var string: String? {
    if case .string(let value) = self { return value }
    return nil
  }
}
