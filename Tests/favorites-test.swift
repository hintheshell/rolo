import Foundation

@main
struct FavoritesTest {
    static func main() {
        var failures = 0

        func check(_ description: String, _ condition: @autoclosure () -> Bool) {
            if condition() {
                print("PASS  \(description)")
            } else {
                print("FAIL  \(description)")
                failures += 1
            }
        }

        // Ten digit keys is the ceiling: there is no ⌘10, so the eleventh favorite gets no chord.
        check("ten slots", FavoriteSlots.digits.count == 10)
        check("no digit repeats", Set(FavoriteSlots.digits).count == FavoriteSlots.digits.count)

        check("⌘1 is the first favorite", FavoriteSlots.index(for: "1") == 0)
        check("⌘9 is the ninth", FavoriteSlots.index(for: "9") == 8)
        check("⌘0 is the tenth, not the first", FavoriteSlots.index(for: "0") == 9)
        check("a letter is not a slot", FavoriteSlots.index(for: "a") == nil)

        check("expanded results have nine slots", FavoriteSlots.resultDigits.count == 9)
        check("result ⌘1 is the first entry", FavoriteSlots.resultIndex(for: "1") == 0)
        check("result ⌘9 is the ninth entry", FavoriteSlots.resultIndex(for: "9") == 8)
        check("result ⌘0 stays reserved for favorites", FavoriteSlots.resultIndex(for: "0") == nil)

        check("the first row shows 1", FavoriteSlots.digit(at: 0) == "1")
        check("the tenth row shows 0", FavoriteSlots.digit(at: 9) == "0")
        check("the eleventh row shows nothing", FavoriteSlots.digit(at: 10) == nil)
        check("a negative index shows nothing", FavoriteSlots.digit(at: -1) == nil)
        check("the ninth result shows 9", FavoriteSlots.resultDigit(at: 8) == "9")
        check("the tenth result has no digit", FavoriteSlots.resultDigit(at: 9) == nil)

        // The row overlay and the key handler must agree, or a row advertises another's chord.
        for index in FavoriteSlots.digits.indices {
            guard let digit = FavoriteSlots.digit(at: index) else {
                check("slot \(index) has a digit", false)
                continue
            }
            check("slot \(index) round-trips", FavoriteSlots.index(for: digit) == index)
        }

        for index in FavoriteSlots.resultDigits.indices {
            guard let digit = FavoriteSlots.resultDigit(at: index) else {
                check("result slot \(index) has a digit", false)
                continue
            }
            check("result slot \(index) round-trips", FavoriteSlots.resultIndex(for: digit) == index)
        }

        print(failures == 0 ? "\nALL PASSED" : "\n\(failures) failed")
        if failures > 0 { exit(1) }
    }
}
