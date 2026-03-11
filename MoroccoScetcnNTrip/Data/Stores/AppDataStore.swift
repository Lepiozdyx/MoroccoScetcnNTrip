import Foundation
import Combine

@MainActor
final class AppDataStore: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []
    @Published private(set) var calligraphyWorks: [CalligraphyWork] = []
    @Published private(set) var patternWorks: [PatternWork] = []

    private let defaults: UserDefaults
    private let entriesKey = "morocco_sketch_trip.entries.v1"
    private let calligraphyKey = "morocco_sketch_trip.calligraphy.v1"
    private let patternKey = "morocco_sketch_trip.pattern.v1"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        loadAll()
    }

    func createEntry(
        city: MoroccoCity,
        date: Date,
        temperatureC: Int?,
        mood: Mood,
        notes: [JournalEntryNote] = [],
        photos: [PhotoAsset] = [],
        audio: AudioAsset? = nil,
        reflection: EntryReflection? = nil
    ) {
        let entry = JournalEntry(
            city: city,
            date: date,
            temperatureC: temperatureC,
            mood: mood,
            notes: notes,
            photos: photos,
            audio: audio,
            reflection: reflection
        )

        entries.insert(entry, at: 0)
        persistEntries()
    }

    func upsert(_ entry: JournalEntry) {
        var copy = entry
        copy.photos = Array(copy.photos.prefix(5))
        copy.updatedAt = Date()

        if let index = entries.firstIndex(where: { $0.id == copy.id }) {
            entries[index] = copy
        } else {
            entries.insert(copy, at: 0)
        }

        persistEntries()
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        persistEntries()
    }

    func addNote(_ text: String, to entryID: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }
        let note = JournalEntryNote(text: text)
        entries[index].notes.append(note)
        entries[index].updatedAt = Date()
        persistEntries()
    }

    func addPhotos(_ photoRefs: [String], to entryID: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }
        let newAssets = photoRefs.map { PhotoAsset(reference: $0) }
        let merged = entries[index].photos + newAssets
        entries[index].photos = Array(merged.prefix(5))
        entries[index].updatedAt = Date()
        persistEntries()
    }

    func setAudio(filePath: String, duration: TimeInterval?, for entryID: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }
        entries[index].audio = AudioAsset(filePath: filePath, duration: duration)
        entries[index].updatedAt = Date()
        persistEntries()
    }

    func setReflection(_ reflection: EntryReflection?, for entryID: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }
        entries[index].reflection = reflection
        entries[index].updatedAt = Date()
        persistEntries()
    }

    func createCalligraphyWork(
        title: String? = nil,
        letter: ArabicLetter,
        inkColor: InkColor,
        strokes: [CalligraphyStroke] = [],
        previewPath: String? = nil,
        sourceCanvasWidth: Double? = nil,
        sourceCanvasHeight: Double? = nil
    ) {
        let work = CalligraphyWork(
            title: title,
            letter: letter,
            inkColor: inkColor,
            strokes: strokes,
            previewPath: previewPath,
            sourceCanvasWidth: sourceCanvasWidth,
            sourceCanvasHeight: sourceCanvasHeight
        )
        calligraphyWorks.insert(work, at: 0)
        persistCalligraphy()
    }

    func upsert(_ work: CalligraphyWork) {
        var copy = work
        copy.updatedAt = Date()

        if let index = calligraphyWorks.firstIndex(where: { $0.id == copy.id }) {
            calligraphyWorks[index] = copy
        } else {
            calligraphyWorks.insert(copy, at: 0)
        }

        persistCalligraphy()
    }

    func deleteCalligraphyWork(id: UUID) {
        calligraphyWorks.removeAll { $0.id == id }
        persistCalligraphy()
    }

    func createPatternWork(
        title: String = "My pattern",
        circles: [PatternCircle] = [],
        lines: [PatternLine] = [],
        symmetry: PatternSymmetry = PatternSymmetry(xAxis: false, yAxis: false),
        angleStep: Int = 15,
        previewPath: String? = nil
    ) {
        let work = PatternWork(
            title: title,
            circles: circles,
            lines: lines,
            symmetry: symmetry,
            angleStep: angleStep,
            previewPath: previewPath
        )
        patternWorks.insert(work, at: 0)
        persistPatterns()
    }

    func upsert(_ work: PatternWork) {
        var copy = work
        copy.updatedAt = Date()

        if let index = patternWorks.firstIndex(where: { $0.id == copy.id }) {
            patternWorks[index] = copy
        } else {
            patternWorks.insert(copy, at: 0)
        }

        persistPatterns()
    }

    func deletePatternWork(id: UUID) {
        patternWorks.removeAll { $0.id == id }
        persistPatterns()
    }

    private func loadAll() {
        entries = loadValue(forKey: entriesKey, as: [JournalEntry].self) ?? []
        calligraphyWorks = loadValue(forKey: calligraphyKey, as: [CalligraphyWork].self) ?? []
        patternWorks = loadValue(forKey: patternKey, as: [PatternWork].self) ?? []
    }

    private func loadValue<T: Decodable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private func persistEntries() {
        persist(entries, forKey: entriesKey)
    }

    private func persistCalligraphy() {
        persist(calligraphyWorks, forKey: calligraphyKey)
    }

    private func persistPatterns() {
        persist(patternWorks, forKey: patternKey)
    }

    private func persist<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
