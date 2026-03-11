
import SwiftUI

extension Font {
    enum AppWeight {
        case regular
        case medium
        case semibold
        case bold

        fileprivate var swiftUIWeight: Font.Weight {
            switch self {
            case .regular:
                return .regular
            case .medium:
                return .medium
            case .semibold:
                return .semibold
            case .bold:
                return .bold
            }
        }
    }

    static func sfPro(_ weight: AppWeight, size: CGFloat) -> Font {
        .system(size: size, weight: weight.swiftUIWeight, design: .default)
    }
}

extension View {
    
    func appFont(_ weight: Font.AppWeight, size: CGFloat) -> some View {
        self
            .font(.sfPro(weight, size: size))
            .dynamicTypeSize(.medium)
    }
}
