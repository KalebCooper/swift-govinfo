/// Invalid request values or provider continuation metadata.
///
/// These failures occur before following a link or yielding a malformed page.
public enum GovInfoValidationError: Error, Equatable, Sendable {
  /// The date range is malformed, reversed, or contains an impossible date.
  case invalidDateWindow
  /// The identifier is empty or cannot form one path segment.
  case invalidIdentifier
  /// The link changes origin, route, filters, or includes credentials or fragments.
  case invalidLink
  /// A page size is outside 1 through 1,000.
  case invalidPageSize
  /// A paginated response omitted its continuation field.
  case missingContinuation
  /// A cursor is empty, missing, or repeated in this traversal.
  case repeatedContinuation
}
