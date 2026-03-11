import Foundation

enum MoroccoCity: String, CaseIterable, Codable, Identifiable {
    case marrakesh
    case casablanca
    case fes
    case rabat
    case chefchaouen
    case tangier

    var id: String { rawValue }

    var title: String {
        switch self {
        case .marrakesh:
            return "Marrakesh"
        case .casablanca:
            return "Casablanca"
        case .fes:
            return "Fes"
        case .rabat:
            return "Rabat"
        case .chefchaouen:
            return "Chefchaouen"
        case .tangier:
            return "Tangier"
        }
    }
}

enum Mood: String, CaseIterable, Codable, Identifiable {
    case inspired
    case calm
    case happy
    case excited

    var id: String { rawValue }
}

struct EntryReflection: Codable, Equatable {
    var whatWasTheHighlightOfYourDay: String
    var oneThingYouLearnedToday: String
}

struct JournalEntryNote: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var createdAt: Date = Date()
}

struct PhotoAsset: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var reference: String
    var createdAt: Date = Date()
}

struct AudioAsset: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var filePath: String
    var duration: TimeInterval?
    var createdAt: Date = Date()
}

struct JournalEntry: Identifiable, Codable, Equatable {
    static let country = "Morocco"

    var id: UUID = UUID()
    var city: MoroccoCity
    var date: Date
    var temperatureC: Int?
    var mood: Mood
    var notes: [JournalEntryNote]
    var photos: [PhotoAsset]
    var audio: AudioAsset?
    var reflection: EntryReflection?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        city: MoroccoCity,
        date: Date,
        temperatureC: Int? = nil,
        mood: Mood,
        notes: [JournalEntryNote] = [],
        photos: [PhotoAsset] = [],
        audio: AudioAsset? = nil,
        reflection: EntryReflection? = nil
    ) {
        self.city = city
        self.date = date
        self.temperatureC = temperatureC
        self.mood = mood
        self.notes = Array(notes.prefix(50))
        self.photos = Array(photos.prefix(5))
        self.audio = audio
        self.reflection = reflection
    }

    enum CodingKeys: String, CodingKey {
        case id
        case city
        case date
        case temperatureC
        case mood
        case notes
        case photos
        case audio
        case reflection
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let cityRaw = try container.decodeIfPresent(String.self, forKey: .city) ?? MoroccoCity.marrakesh.rawValue
        city = MoroccoCity(rawValue: cityRaw) ?? .marrakesh
        date = try container.decode(Date.self, forKey: .date)
        temperatureC = try container.decodeIfPresent(Int.self, forKey: .temperatureC)
        mood = try container.decode(Mood.self, forKey: .mood)
        notes = try container.decodeIfPresent([JournalEntryNote].self, forKey: .notes) ?? []
        photos = try container.decodeIfPresent([PhotoAsset].self, forKey: .photos) ?? []
        audio = try container.decodeIfPresent(AudioAsset.self, forKey: .audio)
        reflection = try container.decodeIfPresent(EntryReflection.self, forKey: .reflection)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(city.rawValue, forKey: .city)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(temperatureC, forKey: .temperatureC)
        try container.encode(mood, forKey: .mood)
        try container.encode(notes, forKey: .notes)
        try container.encode(photos, forKey: .photos)
        try container.encodeIfPresent(audio, forKey: .audio)
        try container.encodeIfPresent(reflection, forKey: .reflection)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
