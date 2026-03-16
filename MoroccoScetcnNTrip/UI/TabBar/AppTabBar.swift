import SwiftUI

enum AppTab: CaseIterable {
    case journal
    case sketch
    case pattern
    case archive

    var title: String {
        switch self {
        case .journal:
            return "Journal"
        case .sketch:
            return "Sketch"
        case .pattern:
            return "Pattern"
        case .archive:
            return "Archive"
        }
    }

    var iconName: String {
        switch self {
        case .journal:
            return "tab_journal"
        case .sketch:
            return "tab_sketch"
        case .pattern:
            return "tab_pattern"
        case .archive:
            return "tab_archive"
        }
    }

}

struct AppTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabItem(for: tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(tabBarBackground)
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                .offset(x: -1, y: -1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 5)
    }

    private var tabBarBackground: some View {
        ZStack {
            Capsule()
                .fill(Color.white.opacity(0.95))
                .offset(x: -1, y: -1)

            Capsule()
                .fill(Color.appBackground)
        }
    }

    private func tabItem(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        let tintColor = isSelected ? Color.appBlue : Color.appGrayText

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                tabIcon(for: tab, tintColor: tintColor)

                Text(tab.title)
                    .appFont(.medium, size: 12)
                    .foregroundStyle(tintColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(selectedBackground(isSelected: isSelected))
        }
        .buttonStyle(.plain)
    }

    private func selectedBackground(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                Capsule().fill(Color.black.opacity(0.10))
            } else {
                Capsule().fill(Color.clear)
            }
        }
    }

    private func tabIcon(for tab: AppTab, tintColor: Color) -> some View {
        Image(tab.iconName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .foregroundStyle(tintColor)
    }
}

#Preview {
    AppTabBar(selectedTab: .constant(.journal))
        .padding()
}
