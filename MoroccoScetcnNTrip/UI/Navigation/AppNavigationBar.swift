import SwiftUI
import UIKit

enum AppNavigationBarStyle {
    case titleOnly
    case titleWithPlus
    case titleWithEdit
    case titleWithEditAndPlus
}

struct AppNavigationBar: View {
    let title: String
    let style: AppNavigationBarStyle
    var showsBackButton: Bool = false
    var backImageName: String = "nav_back"
    var plusImageName: String = "nav_plus"
    var editImageName: String = "nav_edit"
    var onBack: (() -> Void)?
    var onPlus: (() -> Void)?
    var onEdit: (() -> Void)?

    var body: some View {
        ZStack {
            Text(title)
                .appFont(.semibold, size: 17)
                .foregroundStyle(.black)

            HStack(spacing: 0) {
                if showsBackButton {
                    iconButton(imageName: backImageName, action: onBack)
                } else {
                    Color.clear
                        .frame(width: 40, height: 40)
                }

                Spacer()

                HStack(spacing: 12) {
                    switch style {
                    case .titleOnly:
                        EmptyView()
                    case .titleWithPlus:
                        iconButton(imageName: plusImageName, action: onPlus)
                    case .titleWithEdit:
                        iconButton(imageName: editImageName, action: onEdit)
                    case .titleWithEditAndPlus:
                        iconButton(imageName: editImageName, action: onEdit)
                        iconButton(imageName: plusImageName, action: onPlus)
                    }
                }
            }
        }
        .frame(height: 42)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func iconButton(imageName: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            navIcon(imageName: imageName)
                .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func navIcon(imageName: String) -> some View {
        if let icon = UIImage(named: imageName) {
            Image(uiImage: icon)
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
        } else {
            Image(systemName: fallbackSystemName(for: imageName))
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(Color.appBlack)
        }
    }

    private func fallbackSystemName(for imageName: String) -> String {
        switch imageName {
        case "__system_back__":
            return "chevron.left"
        case "__system_edit__":
            return "square.and.pencil"
        case "__system_plus__":
            return "plus"
        case "nav_back":
            return "chevron.left"
        case "nav_edit":
            return "square.and.pencil"
        case "nav_plus":
            return "plus"
        default:
            return "circle"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AppNavigationBar(title: "Journal", style: .titleOnly)
        AppNavigationBar(title: "Sketch", style: .titleWithPlus)
        AppNavigationBar(title: "Journal", style: .titleWithEdit, showsBackButton: true)
        AppNavigationBar(title: "Pattern", style: .titleWithEditAndPlus, showsBackButton: true)
    }
    .padding(.top, 20)
}
