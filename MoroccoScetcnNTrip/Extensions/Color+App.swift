import SwiftUI

extension Color {
    init(hex: String, alpha: Double = 1) {
        let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hexString.count {
        case 3:
            (a, r, g, b) = (
                255,
                ((int >> 8) & 0xF) * 17,
                ((int >> 4) & 0xF) * 17,
                (int & 0xF) * 17
            )
        case 6:
            (a, r, g, b) = (
                255,
                (int >> 16) & 0xFF,
                (int >> 8) & 0xFF,
                int & 0xFF
            )
        case 8:
            (a, r, g, b) = (
                (int >> 24) & 0xFF,
                (int >> 16) & 0xFF,
                (int >> 8) & 0xFF,
                int & 0xFF
            )
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: (Double(a) / 255) * alpha
        )
    }

    static let appBackground = Color(hex: "EFEFF1")
    static let appBlue = Color(hex: "0088FF")
    static let appCyan = Color(hex: "0B9DEF")
    static let appBlack = Color(hex: "000000")
    static let appGrayText = Color(hex: "3F4044")
    static let appOrange = Color(hex: "FF7B00")
    static let appRed = Color(hex: "FF4000")
}
