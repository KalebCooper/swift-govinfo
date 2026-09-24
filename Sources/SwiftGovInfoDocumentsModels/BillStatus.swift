#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#if canImport(FoundationXML)
import FoundationXML
#endif

/// A BILLSTATUS XML document with typed bill identity and the complete parsed source tree.
///
/// `try BillStatus.decode(bytes)` preserves actions, law citations, relationships, unknown elements,
/// and source ordering. It does not infer comprehensive legal status or merge another publisher's data.
public struct BillStatus: GovInfoSourceDecodable, Hashable, Sendable {
  /// The bill element, including every action and relationship.
  public let bill: GovInfoXMLNode
  /// The source Congress identifier as text.
  public let congress: String
  /// The source bill number as text.
  public let number: String
  /// The complete billStatus root.
  public let root: GovInfoXMLNode
  /// The source bill type, including future values.
  public let type: String
  /// The source XML version, when present.
  public var version: String? { root.children(named: "version").first?.text }

  /// Decodes bounded UTF-8 BILLSTATUS XML with external entities and DTDs prohibited.
  /// - Throws: `GovInfoDecodingError` for malformed XML, limits, root, or missing bill identity.
  public static func decode(_ data: Data) throws(GovInfoDecodingError) -> Self {
    let root = try GovInfoXML.decode(data)
    guard root.name == "billStatus" else { throw .unexpectedRoot }
    guard let bill = root.children(named: "bill").first,
      let congress = bill.children(named: "congress").first?.text, !congress.isEmpty,
      let number = bill.children(named: "number").first?.text, !number.isEmpty,
      let type = bill.children(named: "type").first?.text, !type.isEmpty
    else { throw .missingBillIdentity }
    return Self(bill: bill, congress: congress, number: number, root: root, type: type)
  }
}

/// A source-specific decoding failure without platform parser objects.
public enum GovInfoDecodingError: Error, Equatable, Sendable {
  /// Input exceeds the byte, node, or nesting limit.
  case limitExceeded
  /// XML is malformed, has declarations of entities, or is not UTF-8.
  case malformedXML
  /// A BILLSTATUS document is missing its required bill identity.
  case missingBillIdentity
  /// The document root is not the requested source format.
  case unexpectedRoot
}

/// A pure decoder for a source representation that is not JSON.
///
/// Consumers can implement this protocol for another documented GovInfo format.
public protocol GovInfoSourceDecodable: Sendable {
  /// Decodes one bounded source body without I/O.
  /// - Throws: `GovInfoDecodingError` when source validation fails.
  static func decode(_ data: Data) throws(GovInfoDecodingError) -> Self
}

/// A bounded XML reader for official document and metadata representations.
///
/// This is an XML tree reader, not a mapping from arbitrary XML into Codable.
public enum GovInfoXML {
  /// Decodes UTF-8 XML up to 16 MiB, 256 nested elements, and 250,000 elements.
  /// - Throws: `GovInfoDecodingError` for malformed input, DTDs, entities, or exceeded limits.
  public static func decode(_ data: Data) throws(GovInfoDecodingError) -> GovInfoXMLNode {
    guard data.count <= 16 * 1024 * 1024 else { throw .limitExceeded }
    guard let source = String(data: data, encoding: .utf8),
      !source.contains("\u{0}"), !source.contains("<!DOCTYPE"), !source.contains("<!ENTITY")
    else { throw .malformedXML }
    let parser = XMLParser(data: data)
    parser.shouldResolveExternalEntities = false
    let delegate = XMLTreeDelegate()
    parser.delegate = delegate
    guard parser.parse(), let root = delegate.root else {
      throw delegate.exceededLimit ? .limitExceeded : .malformedXML
    }
    return root
  }
}

/// An ordered XML element retaining attributes, text, CDATA text, and child elements.
///
/// Byte-exact spelling, comments, and processing instructions remain in the source receipt.
public struct GovInfoXMLNode: Hashable, Sendable {
  /// A child element or text segment in source order.
  public indirect enum Content: Hashable, Sendable {
    /// A nested element.
    case element(GovInfoXMLNode)
    /// Text or CDATA text, without whitespace normalization.
    case text(String)
  }

  /// Attributes keyed by their source names.
  public let attributes: [String: String]
  /// Mixed content in source order.
  public let content: [Content]
  /// The source element name, including its prefix when present.
  public let name: String

  /// Creates an XML element value.
  public init(attributes: [String: String], content: [Content], name: String) {
    self.attributes = attributes
    self.content = content
    self.name = name
  }

  /// Immediate child elements in source order.
  public var children: [Self] {
    content.compactMap {
      if case .element(let value) = $0 { return value }; return nil
    }
  }

  /// Concatenated descendant text, retaining whitespace.
  public var text: String {
    content.map {
      switch $0 {
      case .element(let value): value.text;
      case .text(let value): value
      }
    }.joined()
  }

  /// Finds immediate children with the given source name.
  public func children(named name: String) -> [Self] { children.filter { $0.name == name } }
}

#if canImport(ObjectiveC)
private typealias XMLDelegateBase = NSObject
#else
private class XMLDelegateBase {}
#endif

private final class XMLTreeDelegate: XMLDelegateBase, XMLParserDelegate {
  var exceededLimit = false
  var nodes = 0
  var root: GovInfoXMLNode?
  var stack: [(attributes: [String: String], content: [GovInfoXMLNode.Content], name: String)] = []

  func parser(
    _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    guard let element = stack.popLast() else { parser.abortParsing(); return }
    let node = GovInfoXMLNode(
      attributes: element.attributes, content: element.content, name: element.name)
    if stack.isEmpty { root = node } else { stack[stack.count - 1].content.append(.element(node)) }
  }

  func parser(
    _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]
  ) {
    nodes += 1
    guard stack.count < 256, nodes <= 250_000 else {
      exceededLimit = true; parser.abortParsing(); return
    }
    stack.append((attributeDict, [], elementName))
  }

  func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
    guard let text = String(data: CDATABlock, encoding: .utf8) else {
      parser.abortParsing(); return
    }
    append(text)
  }

  func parser(_ parser: XMLParser, foundCharacters string: String) { append(string) }

  private func append(_ text: String) {
    guard !stack.isEmpty else { return }
    stack[stack.count - 1].content.append(.text(text))
  }
}
