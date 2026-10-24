import Foundation

public enum CairnLabel {
    public static func text(total: Int, today: Int) -> String {
        guard total > 0 else { return "Cairn · no stones yet" }
        let stones = total == 1 ? "stone" : "stones"
        return "Cairn · \(total.formatted(.number.locale(Locale(identifier: "en_US")))) \(stones) · \(today) today"
    }
}
