import SwiftUI
import UIKit
import AVFAudio

struct PlaceDetailsScreen: View {
    let entryID: UUID

    @EnvironmentObject private var dataStore: AppDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var selectedPhotoIndex = 0
    @State private var isHighlightExpanded = false
    @State private var isLearnedExpanded = false
    @State private var isDeleteConfirmationPresented = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isAudioPlaying = false
    @State private var audioProgress: Double = 0
    @State private var audioDuration: TimeInterval = 0
    @State private var audioProgressTimer: Timer?

    var body: some View {
        Group {
            if let entry = dataStore.entries.first(where: { $0.id == entryID }) {
                content(entry)
            } else {
                Text("Entry not found")
                    .appFont(.regular, size: 17)
                    .foregroundStyle(Color.appGrayText)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: entryID) { _ in
            selectedPhotoIndex = 0
            isHighlightExpanded = false
            isLearnedExpanded = false
            stopAudio()
        }
        .confirmationDialog("Delete this entry?", isPresented: $isDeleteConfirmationPresented, titleVisibility: .visible) {
            Button("Delete Entry", role: .destructive) {
                deleteEntry()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onDisappear {
            stopAudio()
        }
    }

    private func content(_ entry: JournalEntry) -> some View {
        VStack(spacing: 10) {
            AppNavigationBar(
                title: "Place Details",
                style: .titleWithEdit,
                showsBackButton: true,
                backImageName: "__system_back__",
                editImageName: "__system_edit__",
                onBack: { dismiss() },
                onEdit: { isEditing = true }
            )
            .padding(.top, 2)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    topImage(entry)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.city.title)
                            .appFont(.bold, size: 34)
                            .foregroundStyle(Color.appBlack)
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color(hex: "6D6D73"))
                            Text(longDate(entry.date))
                                .appFont(.regular, size: 17)
                                .foregroundStyle(Color(hex: "6D6D73"))
                        }
                    }

                    chipsRow(entry)

                    sectionTitle("Notes", asset: "icon_notes_custom")
                    noteCard(entry)

                    if entry.audio != nil {
                        sectionTitle("Ambience", asset: "icon_ambience_custom")
                        audioCard(entry)
                    }

                    sectionTitle("Reflections", asset: "icon_reflections_custom")
                    reflectionsCard(entry)

                    deleteButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .fullScreenCover(isPresented: $isEditing) {
            NewEntryScreen(entry: entry)
                .environmentObject(dataStore)
        }
    }

    private func topImage(_ entry: JournalEntry) -> some View {
        let images = entryImages(entry)

        return ZStack(alignment: .bottom) {
            if images.isEmpty {
                LinearGradient(
                    colors: [Color(hex: "88B5D9"), Color(hex: "5B7994")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            if images.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<images.count, id: \.self) { index in
                        Circle()
                            .fill(index == selectedPhotoIndex ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(height: 176)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func chipsRow(_ entry: JournalEntry) -> some View {
        HStack(spacing: 8) {
            if let t = entry.temperatureC {
                chip("+\(t)°")
            }
            chip("\(moodEmoji(entry.mood)) \(moodText(entry.mood))")
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .appFont(.semibold, size: 17)
            .foregroundStyle(Color.appBlue)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Capsule().fill(Color(hex: "BFE0FF")))
    }

    private func sectionTitle(_ title: String, asset: String) -> some View {
        HStack(spacing: 6) {
            assetIcon(asset, size: 18)
                .foregroundStyle(Color.appBlue)
            Text(title)
                .appFont(.semibold, size: 24)
                .foregroundStyle(Color.appBlack)
        }
    }

    private func noteCard(_ entry: JournalEntry) -> some View {
        Text(entry.notes.first?.text ?? "No notes yet")
            .appFont(.medium, size: 17)
            .italic()
            .foregroundStyle(Color(hex: "6E6E73"))
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
    }

    private func audioCard(_ entry: JournalEntry) -> some View {
        HStack(spacing: 12) {
            Button {
                toggleAudio(entry)
            } label: {
                Circle()
                    .fill(Color(hex: "FF8B00"))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: isAudioPlaying ? "pause.fill" : "play.fill")
                            .foregroundStyle(Color.white)
                            .offset(x: isAudioPlaying ? 0 : 1)
                    )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(audioTitle(entry))
                    .appFont(.medium, size: 15)
                    .foregroundStyle(Color.appBlack)

                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: "D5D5D9")).frame(height: 4)
                    Capsule().fill(Color.appBlue).frame(width: CGFloat(audioProgress) * 220, height: 4)
                }

                HStack {
                    Text(timeString(audioPlayer?.currentTime ?? 0))
                    Spacer()
                    Text(timeString(audioDuration > 0 ? audioDuration : (entry.audio?.duration ?? 0)))
                }
                .appFont(.regular, size: 11)
                .foregroundStyle(Color(hex: "8A8A90"))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white))
    }

    private func reflectionsCard(_ entry: JournalEntry) -> some View {
        VStack(spacing: 8) {
            disclosureRow(
                title: "What surprised me?",
                text: entry.reflection?.whatWasTheHighlightOfYourDay ?? "No highlight yet.",
                isExpanded: isHighlightExpanded,
                action: { isHighlightExpanded.toggle() }
            )

            disclosureRow(
                title: "Memorable moment",
                text: entry.reflection?.oneThingYouLearnedToday ?? "No notes yet.",
                isExpanded: isLearnedExpanded,
                action: { isLearnedExpanded.toggle() }
            )
        }
    }

    private func disclosureRow(
        title: String,
        text: String,
        isExpanded: Bool,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: action) {
                HStack {
                    Text(title)
                        .appFont(.medium, size: 16)
                        .foregroundStyle(Color.appBlack)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(Color.appBlack)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(text)
                    .appFont(.regular, size: 15)
                    .foregroundStyle(Color(hex: "6D6D73"))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white))
    }

    private var deleteButton: some View {
        Button {
            isDeleteConfirmationPresented = true
        } label: {
            Text("Delete Entry")
                .appFont(.semibold, size: 17)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.appRed)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    private func assetIcon(_ name: String, size: CGFloat) -> some View {
        Group {
            if let icon = UIImage(named: name) {
                Image(uiImage: icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .frame(width: size, height: size)
    }

    private func entryImages(_ entry: JournalEntry) -> [UIImage] {
        entry.photos.compactMap { imageFromReference($0.reference) }
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

    private func audioTitle(_ entry: JournalEntry) -> String {
        "\(entry.city.title) - \(longDate(entry.date))"
    }

    private func moodEmoji(_ mood: Mood) -> String {
        switch mood {
        case .inspired: return "✨"
        case .calm: return "😌"
        case .happy: return "🙂"
        case .excited: return "🤩"
        }
    }

    private func moodText(_ mood: Mood) -> String {
        switch mood {
        case .inspired: return "Inspired"
        case .calm: return "Calm"
        case .happy: return "Happy"
        case .excited: return "Excited"
        }
    }

    private func longDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    private func deleteEntry() {
        stopAudio()
        dataStore.deleteEntry(id: entryID)
        dismiss()
    }

    private func toggleAudio(_ entry: JournalEntry) {
        if let player = audioPlayer, player.isPlaying {
            player.pause()
            isAudioPlaying = false
            stopAudioProgressTimer()
            return
        }

        if let player = audioPlayer {
            if player.duration > 0, player.currentTime >= player.duration {
                player.currentTime = 0
            }
            player.play()
            isAudioPlaying = true
            startAudioProgressTimer()
            return
        }

        guard let url = audioFileURL(entry) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            audioPlayer = player
            audioDuration = player.duration > 0 ? player.duration : (entry.audio?.duration ?? 0)
            player.play()
            isAudioPlaying = true
            startAudioProgressTimer()
        } catch {
            audioPlayer = nil
            audioDuration = 0
            isAudioPlaying = false
            stopAudioProgressTimer()
        }
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isAudioPlaying = false
        audioProgress = 0
        audioDuration = 0
        stopAudioProgressTimer()
    }

    private func audioFileURL(_ entry: JournalEntry) -> URL? {
        guard let rawPath = entry.audio?.filePath, !rawPath.isEmpty else { return nil }
        if FileManager.default.fileExists(atPath: rawPath) {
            return URL(fileURLWithPath: rawPath)
        }
        if let url = URL(string: rawPath), url.isFileURL, FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        if let docsURL {
            let localPath = docsURL.appendingPathComponent((rawPath as NSString).lastPathComponent).path
            if FileManager.default.fileExists(atPath: localPath) {
                return URL(fileURLWithPath: localPath)
            }
        }
        return nil
    }

    private func timeString(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func startAudioProgressTimer() {
        stopAudioProgressTimer()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            guard let player = audioPlayer else {
                stopAudioProgressTimer()
                return
            }
            if player.isPlaying {
                audioProgress = audioDuration > 0 ? player.currentTime / audioDuration : 0
            } else {
                isAudioPlaying = false
                stopAudioProgressTimer()
            }
        }
        audioProgressTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopAudioProgressTimer() {
        audioProgressTimer?.invalidate()
        audioProgressTimer = nil
    }
}

#Preview {
    PlaceDetailsScreen(entryID: UUID())
        .environmentObject(AppDataStore())
}
