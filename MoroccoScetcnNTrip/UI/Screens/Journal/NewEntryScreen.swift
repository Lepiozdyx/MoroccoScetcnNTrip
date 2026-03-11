import SwiftUI
import UniformTypeIdentifiers
import UIKit
import AVFAudio
import Combine

struct NewEntryScreen: View {
    @EnvironmentObject private var dataStore: AppDataStore
    @Environment(\.dismiss) private var dismiss

    private let editingEntry: JournalEntry?

    @State private var selectedCity: MoroccoCity?
    @State private var date: Date
    @State private var temperatureText: String
    @State private var selectedMood: Mood
    @State private var journalText: String
    @State private var highlightText: String
    @State private var learnedText: String

    @State private var photoChips: [PhotoChip]
    @State private var isPhotoSourceDialogPresented = false
    @State private var isCameraPickerPresented = false
    @State private var isGalleryPickerPresented = false

    @State private var isAudioImporterPresented = false
    @State private var audioURL: URL?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isAudioPlaying = false
    @State private var audioProgress: Double = 0
    @State private var audioDuration: TimeInterval = 0
    @State private var audioProgressTimer: Timer?
    @FocusState private var focusedField: FocusField?

    private enum FocusField: Hashable {
        case weather
        case journal
        case highlight
        case learned
    }

    init(entry: JournalEntry? = nil) {
        self.editingEntry = entry
        _selectedCity = State(initialValue: entry?.city)
        _date = State(initialValue: entry?.date ?? .now)
        _temperatureText = State(initialValue: entry?.temperatureC.map(String.init) ?? "")
        _selectedMood = State(initialValue: entry?.mood ?? .inspired)
        _journalText = State(initialValue: entry?.notes.first?.text ?? "")
        _highlightText = State(initialValue: entry?.reflection?.whatWasTheHighlightOfYourDay ?? "")
        _learnedText = State(initialValue: entry?.reflection?.oneThingYouLearnedToday ?? "")
        _photoChips = State(initialValue: Self.initialPhotoChips(from: entry?.photos ?? []))
        _audioURL = State(initialValue: entry?.audio.map { URL(fileURLWithPath: $0.filePath) })
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("City")
                    cityBlock

                    sectionTitle("Date")
                    dateField

                    sectionTitle("Weather")
                    weatherField

                    sectionTitle("How are you feeling?")
                    moodRow

                    sectionTitle("Journal Entry")
                    journalField

                    sectionTitle("Reflection")
                    reflectionField(title: "What was the highlight of your day?", text: $highlightText, field: .highlight)
                    reflectionField(title: "One thing you learned today?", text: $learnedText, field: .learned)

                    sectionTitle("Image")
                    imageRow

                    sectionTitle("Audio")
                    audioSection
                    
                    saveButton
                        
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 18)
            }

            
        }
        .background(Color.appBackground.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .dynamicTypeSize(.medium)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if focusedField != nil {
                HStack {
                    Spacer()
                    Button("Done") {
                        closeKeyboard()
                    }
                    .appFont(.semibold, size: 16)
                    .foregroundStyle(Color.appBlue)
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(Color(hex: "F2F2F4"))
            }
        }
        .confirmationDialog("Select Photo Source", isPresented: $isPhotoSourceDialogPresented, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Camera") {
                    isCameraPickerPresented = true
                }
            }
            Button("Gallery") {
                isGalleryPickerPresented = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $isCameraPickerPresented) {
            CameraPicker { image in
                if let image {
                    addPickedImages([image])
                }
                isCameraPickerPresented = false
            }
        }
        .sheet(isPresented: $isGalleryPickerPresented) {
            GalleryPicker(selectionLimit: max(1, 5 - photoChips.count)) { images in
                addPickedImages(images)
                isGalleryPickerPresented = false
            }
        }
        .fileImporter(
            isPresented: $isAudioImporterPresented,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            if case let .success(urls) = result {
                if let picked = urls.first {
                    audioURL = copyAudioToDocuments(from: picked)
                }
            }
        }
        .onChange(of: audioURL) { _ in
            prepareAudioPlayer()
        }
        .onAppear {
            if audioPlayer == nil, audioURL != nil {
                prepareAudioPlayer()
            }
        }
        .onDisappear {
            stopAudio()
        }
    }

    private var topBar: some View {
        ZStack {
            Text("Morocco")
                .appFont(.semibold, size: 17)
                .foregroundStyle(Color.appBlack)

            HStack {
                circleIconButton(
                    systemName: "xmark",
                    iconColor: Color(hex: "9F9FA3"),
                    backgroundColor: Color(hex: "D8D8DB"),
                    action: { dismiss() }
                )

                Spacer()

                circleIconButton(
                    systemName: "square.and.arrow.up",
                    iconColor: .white,
                    backgroundColor: Color.appBlue,
                    rotation: 180,
                    action: {}
                )
            }
        }
        .frame(height: 44)
    }

    private func circleIconButton(
        systemName: String,
        iconColor: Color,
        backgroundColor: Color,
        rotation: Double = 0,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .rotationEffect(.degrees(rotation))
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(Circle().fill(backgroundColor))
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .appFont(.semibold, size: 14)
            .foregroundStyle(Color.appBlack)
    }

    private func capsuleText(_ text: String, textColor: Color) -> some View {
        HStack {
            Text(text)
                .appFont(.regular, size: 17)
                .foregroundStyle(textColor)
            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(Capsule().fill(Color(hex: "DCDDDF")))
    }

    private var cityBlock: some View {
        Menu {
            ForEach(MoroccoCity.allCases) { city in
                Button(city.title) {
                    selectedCity = city
                }
            }
        } label: {
            HStack {
                Text(selectedCity?.title ?? "Choose")
                    .appFont(.regular, size: 17)
                    .foregroundStyle(Color.appBlack)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appBlack)
            }
            .padding(.horizontal, 18)
            .frame(height: 52)
            .background(Capsule().fill(Color(hex: "DCDDDF")))
        }
        .buttonStyle(.plain)
    }

    private var dateField: some View {
        HStack {
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                .tint(Color.appBlack)
            Spacer()
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(Capsule().fill(Color(hex: "DCDDDF")))
    }

    private var weatherField: some View {
        HStack {
            TextField("Temperature", text: $temperatureText)
                .keyboardType(.numberPad)
                .appFont(.regular, size: 17)
                .foregroundStyle(Color.appBlack)
                .submitLabel(.done)
                .focused($focusedField, equals: .weather)

            Text("°C")
                .appFont(.regular, size: 17)
                .foregroundStyle(Color(hex: "787878"))
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .background(Capsule().fill(Color(hex: "DCDDDF")))
    }

    private var moodRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                moodChip(.inspired, title: "Inspired", emoji: "✨")
                moodChip(.calm, title: "Calm", emoji: "😌")
                moodChip(.happy, title: "Happy", emoji: "🙂")
                moodChip(.excited, title: "Excited", emoji: "🤩")
            }
            .padding(.leading, 16)
            .padding(.vertical, 2)
        }
        .padding(.horizontal, -16)
    }

    private func moodChip(_ mood: Mood, title: String, emoji: String) -> some View {
        let isSelected = selectedMood == mood
        return Button {
            selectedMood = mood
        } label: {
            VStack(spacing: 8) {
                Text(emoji)
                    .appFont(.regular, size: 24)
                Text(title)
                    .appFont(.medium, size: 15)
                    .foregroundStyle(isSelected ? Color.white : Color.appBlack)
            }
            .frame(width: 100, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Color.appBlue : Color(hex: "DCDDDF"))
            )
        }
        .buttonStyle(.plain)
    }

    private var journalField: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "DCDDDF"))
                .frame(minHeight: 130)

            TextEditor(text: $journalText)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 130)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .appFont(.regular, size: 16)
                .foregroundStyle(Color.appBlack)
                .focused($focusedField, equals: .journal)

            if journalText.isEmpty {
                Text("Start writing your thoughts...")
                    .appFont(.regular, size: 15)
                    .foregroundStyle(Color(hex: "99999E"))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
            }
        }
    }

    private func reflectionField(title: String, text: Binding<String>, field: FocusField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .appFont(.semibold, size: 13)
                .foregroundStyle(Color.appBlack)

            TextField("Type here...", text: text)
                .appFont(.regular, size: 16)
                .foregroundStyle(Color.appBlack)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(hex: "DCDDDF"))
                )
                .focused($focusedField, equals: field)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: "D7EBFF"))
        )
    }

    private var imageRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                photoAddButton
                ForEach(photoChips) { chip in
                    Image(uiImage: chip.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                removePhoto(chip.id)
                            } label: {
                                Circle()
                                    .fill(Color.appRed)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(Color.white)
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(6)
                        }
                }
            }
            .padding(.leading, 16)
            .padding(.vertical, 2)
        }
        .padding(.horizontal, -16)
    }

    private var photoAddButton: some View {
        Button {
            isPhotoSourceDialogPresented = true
        } label: {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                .foregroundStyle(Color(hex: "A8A8AE"))
                .frame(width: 100, height: 100)
                .overlay(
                    VStack(spacing: 6) {
                        Image("camerabadgeplus")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(Color(hex: "B3B3B8"))
                        Text("PHOTO")
                            .appFont(.regular, size: 12)
                            .foregroundStyle(Color(hex: "8F8F95"))
                    }
                )
        }
        .buttonStyle(.plain)
    }

    private var audioSection: some View {
        VStack(spacing: 8) {
            if audioURL != nil {
                HStack(spacing: 10) {
                    Button {
                        toggleAudioPlayback()
                    } label: {
                        Circle()
                            .fill(Color.appBlue)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: isAudioPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .offset(x: isAudioPlaying ? 0 : 1)
                            )
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(audioDisplayTitle)
                            .appFont(.medium, size: 14)
                            .foregroundStyle(Color.appBlack)
                            .lineLimit(1)

                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(hex: "D5D5D9")).frame(height: 4)
                            Capsule().fill(Color.appBlue).frame(width: CGFloat(audioProgress) * 140, height: 4)
                        }

                        HStack {
                            Text(timeString(audioPlayer?.currentTime ?? 0))
                            Spacer()
                            Text(timeString(audioDuration))
                        }
                        .appFont(.regular, size: 11)
                        .foregroundStyle(Color(hex: "8A8A90"))
                    }

                    Spacer()

                    Button {
                        stopAudio()
                        audioURL = nil
                    } label: {
                        Circle()
                            .fill(Color.appRed)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.white)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(hex: "DCDDDF"))
                )
            }

            Button {
                isAudioImporterPresented = true
            } label: {
                Text("Add Audio")
                    .appFont(.medium, size: 15)
                    .foregroundStyle(Color.appBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(hex: "CBE6FF"))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var saveButton: some View {
        Button(action: saveEntry) {
            Text("SAVE JOURNAL ENTRY")
                .appFont(.semibold, size: 15)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.appBlue)
                )
        }
        .buttonStyle(.plain)
    }

    private func removePhoto(_ id: UUID) {
        photoChips.removeAll { $0.id == id }
    }

    private func addPickedImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        var newChips = photoChips
        let remaining = max(0, 5 - newChips.count)
        if remaining == 0 { return }
        for image in images.prefix(remaining) {
            newChips.append(PhotoChip(image: image, storedPath: nil))
        }
        photoChips = Array(newChips.prefix(5))
    }

    private func persistPhotos() -> [PhotoAsset] {
        photoChips.prefix(5).compactMap { chip in
            if let storedPath = chip.storedPath {
                return PhotoAsset(reference: storedPath)
            }
            guard let data = chip.image.jpegData(compressionQuality: 0.85) else { return nil }
            let name = "journal_photo_\(chip.id.uuidString).jpg"
            let url = documentsDirectory().appendingPathComponent(name)
            do {
                try data.write(to: url, options: .atomic)
                return PhotoAsset(reference: url.path)
            } catch {
                return nil
            }
        }
    }

    private func saveEntry() {
        let finalCity = selectedCity ?? .marrakesh
        let note = journalText.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = note.isEmpty ? [JournalEntryNote]() : [JournalEntryNote(text: note)]
        let highlight = highlightText.trimmingCharacters(in: .whitespacesAndNewlines)
        let learned = learnedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let reflection = (highlight.isEmpty && learned.isEmpty) ? nil : EntryReflection(
            whatWasTheHighlightOfYourDay: highlight,
            oneThingYouLearnedToday: learned
        )
        let temp = Int(temperatureText.trimmingCharacters(in: .whitespacesAndNewlines))
        let photos = persistPhotos()
        let audio = validAudioURL().map { AudioAsset(filePath: $0.path, duration: audioDuration > 0 ? audioDuration : nil) }

        if let existing = editingEntry {
            var edited = existing
            edited.city = finalCity
            edited.date = date
            edited.temperatureC = temp
            edited.mood = selectedMood
            edited.notes = notes
            edited.photos = photos
            edited.audio = audio
            edited.reflection = reflection
            dataStore.upsert(edited)
        } else {
            dataStore.createEntry(
                city: finalCity,
                date: date,
                temperatureC: temp,
                mood: selectedMood,
                notes: notes,
                photos: photos,
                audio: audio,
                reflection: reflection
            )
        }

        dismiss()
    }

    private static func initialPhotoChips(from assets: [PhotoAsset]) -> [PhotoChip] {
        assets.compactMap { asset in
            guard let image = imageFromReference(asset.reference) else {
                return nil
            }
            return PhotoChip(image: image, storedPath: asset.reference)
        }
    }

    private static func imageFromReference(_ reference: String) -> UIImage? {
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

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }

    private func closeKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func copyAudioToDocuments(from sourceURL: URL) -> URL? {
        let needsScopedAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if needsScopedAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let fileName = "journal_audio_\(UUID().uuidString).\(ext)"
        let destination = documentsDirectory().appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destination)
            return destination
        } catch {
            return nil
        }
    }

    private func prepareAudioPlayer() {
        stopAudio()
        guard let audioURL else {
            audioDuration = 0
            audioProgress = 0
            return
        }
        do {
            let player = try AVAudioPlayer(contentsOf: audioURL)
            player.prepareToPlay()
            audioPlayer = player
            audioDuration = player.duration
            audioProgress = 0
        } catch {
            audioPlayer = nil
            audioDuration = 0
            audioProgress = 0
        }
    }

    private func toggleAudioPlayback() {
        guard let player = audioPlayer else {
            prepareAudioPlayer()
            guard let prepared = audioPlayer else { return }
            prepared.play()
            isAudioPlaying = true
            startAudioProgressTimer()
            return
        }
        if player.isPlaying {
            player.pause()
            isAudioPlaying = false
            stopAudioProgressTimer()
        } else {
            if player.duration > 0, player.currentTime >= player.duration {
                player.currentTime = 0
            }
            player.play()
            isAudioPlaying = true
            startAudioProgressTimer()
        }
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        audioProgress = 0
        isAudioPlaying = false
        stopAudioProgressTimer()
    }

    private func timeString(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func validAudioURL() -> URL? {
        guard let audioURL else { return nil }
        if FileManager.default.fileExists(atPath: audioURL.path) {
            return audioURL
        }
        return nil
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

    private var audioDisplayTitle: String {
        let cityTitle = (selectedCity ?? .marrakesh).title
        return "\(cityTitle) - \(entryDateText(date))"
    }

    private func entryDateText(_ value: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: value)
    }
}

private struct PhotoChip: Identifiable, Equatable {
    let id: UUID
    let image: UIImage
    let storedPath: String?

    init(id: UUID = UUID(), image: UIImage, storedPath: String?) {
        self.id = id
        self.image = image
        self.storedPath = storedPath
    }

    static func == (lhs: PhotoChip, rhs: PhotoChip) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    NewEntryScreen()
        .environmentObject(AppDataStore())
}
