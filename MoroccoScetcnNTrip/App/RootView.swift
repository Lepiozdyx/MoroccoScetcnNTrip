import SwiftUI

struct RootView: View {
    @StateObject private var dataStore = AppDataStore()

    var body: some View {
        NavigationStack {
            MainShellView()
                .toolbar(.hidden, for: .navigationBar)
                .preferredColorScheme(.light)
                .dynamicTypeSize(.medium)
        }
        .environmentObject(dataStore)
    }
}

#Preview {
    RootView()
}
