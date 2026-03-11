import SwiftUI
import UIKit

struct JournalEntriesScreen: View {
    @EnvironmentObject private var dataStore: AppDataStore
    @State private var isPresentingNewEntry = false
    @State private var selectedEntryID: UUID?
    @State private var isShowingDetails = false

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 6)

            if dataStore.entries.isEmpty {
                Spacer()

                VStack(spacing: 2) {
                    Text("No entries yet")
                        .appFont(.semibold, size: 17)
                        .foregroundStyle(Color.appBlack)

                    Text("Start your first journey")
                        .appFont(.regular, size: 17)
                        .foregroundStyle(Color(hex: "787878"))
                }

                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(dataStore.entries) { entry in
                            entryCard(entry)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .fullScreenCover(isPresented: $isPresentingNewEntry) {
            NewEntryScreen()
                .environmentObject(dataStore)
        }
        .navigationDestination(isPresented: $isShowingDetails) {
            if let selectedEntryID {
                PlaceDetailsScreen(entryID: selectedEntryID)
            } else {
                EmptyView()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: 40, height: 40)

            Spacer()

            Text("All Entries")
                .appFont(.semibold, size: 17)
                .foregroundStyle(Color.appBlack)

            Spacer()

            Button(action: { isPresentingNewEntry = true }) {
                Text("+")
                    .appFont(.regular, size: 36)
                    .foregroundStyle(Color.appBlack)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 42)
    }

    private func entryCard(_ entry: JournalEntry) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(moodEmoji(entry.mood))
                        .appFont(.regular, size: 18)
                    Text(entry.city.title)
                        .appFont(.semibold, size: 17)
                        .foregroundStyle(Color.appBlack)
                }

                Text(dateText(entry.date))
                    .appFont(.regular, size: 17)
                    .foregroundStyle(Color(hex: "77777C"))

                Spacer(minLength: 0)

                Button {
                    selectedEntryID = entry.id
                    isShowingDetails = true
                } label: {
                    HStack(spacing: 8) {
                        Text("VIEW")
                            .appFont(.semibold, size: 18)
                        Text("→")
                            .appFont(.semibold, size: 20)
                    }
                    .foregroundStyle(Color.appBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color(hex: "B8D9F8"))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, alignment: .leading)

            entryPhoto(entry)
                .frame(width: 126)
                .frame(maxHeight: .infinity)
                .clipped()
        }
        .frame(height: 152)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.white)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.appBlue.opacity(0.20), radius: 10, x: 0, y: 4)
    }

    private func moodEmoji(_ mood: Mood) -> String {
        switch mood {
        case .inspired:
            return "✨"
        case .calm:
            return "😌"
        case .happy:
            return "😊"
        case .excited:
            return "🤩"
        }
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }

    private func entryPhoto(_ entry: JournalEntry) -> some View {
        Group {
            if let image = imageForEntry(entry) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color(hex: "88B5D9"), Color(hex: "5B7994")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .clipShape(RightRoundedRectangle(radius: 32))
    }

    private func imageForEntry(_ entry: JournalEntry) -> UIImage? {
        if let first = entry.photos.first {
            return imageFromReference(first.reference)
        }
        return nil
    }

    private func imageFromReference(_ reference: String) -> UIImage? {
        if let image = UIImage(named: reference) {
            return image
        }

        if FileManager.default.fileExists(atPath: reference),
           let image = UIImage(contentsOfFile: reference) {
            return image
        }

        if let url = URL(string: reference), url.isFileURL,
           FileManager.default.fileExists(atPath: url.path),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }

        if let decoded = reference.removingPercentEncoding,
           FileManager.default.fileExists(atPath: decoded),
           let image = UIImage(contentsOfFile: decoded) {
            return image
        }

        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let docsURL {
            let localPath = docsURL.appendingPathComponent((reference as NSString).lastPathComponent).path
            if FileManager.default.fileExists(atPath: localPath),
               let image = UIImage(contentsOfFile: localPath) {
                return image
            }
        }

        return nil
    }
}

private struct RightRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topRight, .bottomRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    JournalEntriesScreen()
        .environmentObject(AppDataStore())
}
