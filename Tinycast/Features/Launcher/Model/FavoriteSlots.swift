import Foundation

/// Launcher digits: expanded results use ⌘1…⌘9; favorites retain ⌘0 for a tenth slot.
enum FavoriteSlots {
    static let digits: [Character] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    static let resultDigits = Array(digits.prefix(9))

    /// The favorite a digit launches, or nil when that key is not a slot.
    static func index(for digit: Character) -> Int? { digits.firstIndex(of: digit) }

    /// The digit shown on the row at `index`, or nil past the last slot.
    static func digit(at index: Int) -> Character? {
        digits.indices.contains(index) ? digits[index] : nil
    }

    /// Expanded launcher results use 1…9; 0 remains the compact/favorite tenth slot.
    static func resultIndex(for digit: Character) -> Int? { resultDigits.firstIndex(of: digit) }

    static func resultDigit(at index: Int) -> Character? {
        resultDigits.indices.contains(index) ? resultDigits[index] : nil
    }
}
