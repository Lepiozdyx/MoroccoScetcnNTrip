import SwiftUI

struct MainShellView: View {
    @State private var selectedTab: AppTab = .journal

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.appBackground
                .ignoresSafeArea()

            currentScreen
                .padding(.bottom, 92)

            AppTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(Color.clear)
        }
    }

    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .journal:
            JournalEntriesScreen()
        case .sketch:
            SketchScreen()
        case .pattern:
            PatternScreen()
        case .archive:
            ArchiveScreen()
        }
    }
}

#Preview {
    MainShellView()
        .environmentObject(AppDataStore())
}
