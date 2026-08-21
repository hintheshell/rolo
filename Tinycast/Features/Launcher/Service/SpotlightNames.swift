import CoreServices
import Foundation

/// The names macOS exposes for an app through its metadata index.
enum SpotlightNames {
    /// `MDItem.h` exports no constant for this key, so it is named directly.
    private static let alternateNamesAttribute = "kMDItemAlternateNames"

    struct Metadata: Sendable {
        let displayName: String?
        let alternateNames: [String]
    }

    /// Empty when the path isn't indexed; Spotlight off is a thinner index, not a failure.
    nonisolated static func metadata(for url: URL) -> Metadata {
        guard let item = MDItemCreateWithURL(nil, url as CFURL) else {
            return Metadata(displayName: nil, alternateNames: [])
        }
        let displayNameAttribute: CFString = kMDItemDisplayName
        let alternateNamesAttribute = Self.alternateNamesAttribute as CFString
        let attributes = [displayNameAttribute, alternateNamesAttribute] as CFArray
        let values = MDItemCopyAttributes(item, attributes) as? [String: Any] ?? [:]
        return Metadata(
            displayName: values[displayNameAttribute as String] as? String,
            alternateNames: values[Self.alternateNamesAttribute] as? [String] ?? [])
    }

    /// ~0.8 ms per bundle, so a pass re-reads only bundles whose modification date moved.
    struct Cache: Sendable {
        private struct Entry: Sendable {
            let modified: Date?
            let metadata: Metadata
        }

        private let previous: [String: Entry]
        private var current: [String: Entry] = [:]

        init() { previous = [:] }

        /// Only bundles this pass asks about carry forward, so uninstalled apps fall out.
        init(reusing cache: Cache) { previous = cache.current }

        mutating func metadata(for url: URL) -> Metadata {
            let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey])
                .contentModificationDate
            if let cached = previous[url.path], cached.modified == modified {
                current[url.path] = cached
                return cached.metadata
            }
            let metadata = SpotlightNames.metadata(for: url)
            current[url.path] = Entry(modified: modified, metadata: metadata)
            return metadata
        }
    }
}
