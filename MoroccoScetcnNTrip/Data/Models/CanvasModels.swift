import Foundation

enum ArchiveSection: String, CaseIterable, Codable, Identifiable {
    case calligraphy
    case pattern

    var id: String { rawValue }
}

enum InkColor: String, CaseIterable, Codable, Identifiable {
    case black
    case brown
    case gold
    case blue

    var id: String { rawValue }
}

enum ArabicLetter: String, CaseIterable, Codable, Identifiable {
    case alif
    case ba
    case ta
    case tha
    case jim
    case hah
    case kha
    case dal
    case dhal
    case ra
    case zay
    case sin
    case shin
    case sad
    case dad
    case tah
    case zah
    case ayn
    case ghayn
    case fa
    case qaf
    case kaf
    case lam
    case mim
    case nun
    case heh
    case waw
    case ya

    var id: String { rawValue }

    var glyph: String {
        switch self {
        case .alif: return "ا"
        case .ba: return "ب"
        case .ta: return "ت"
        case .tha: return "ث"
        case .jim: return "ج"
        case .hah: return "ح"
        case .kha: return "خ"
        case .dal: return "د"
        case .dhal: return "ذ"
        case .ra: return "ر"
        case .zay: return "ز"
        case .sin: return "س"
        case .shin: return "ش"
        case .sad: return "ص"
        case .dad: return "ض"
        case .tah: return "ط"
        case .zah: return "ظ"
        case .ayn: return "ع"
        case .ghayn: return "غ"
        case .fa: return "ف"
        case .qaf: return "ق"
        case .kaf: return "ك"
        case .lam: return "ل"
        case .mim: return "م"
        case .nun: return "ن"
        case .heh: return "ه"
        case .waw: return "و"
        case .ya: return "ي"
        }
    }
}

struct CalligraphyStrokePoint: Codable, Equatable {
    var x: Double
    var y: Double
    var pressure: Double
    var t: TimeInterval
}

struct CalligraphyStroke: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var points: [CalligraphyStrokePoint]
}

struct CalligraphyWork: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var letter: ArabicLetter
    var inkColor: InkColor
    var strokes: [CalligraphyStroke]
    var previewPath: String?
    var sourceCanvasWidth: Double?
    var sourceCanvasHeight: Double?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        title: String? = nil,
        letter: ArabicLetter,
        inkColor: InkColor,
        strokes: [CalligraphyStroke] = [],
        previewPath: String? = nil,
        sourceCanvasWidth: Double? = nil,
        sourceCanvasHeight: Double? = nil
    ) {
        self.title = title ?? "My calligraphy - \(letter.glyph)"
        self.letter = letter
        self.inkColor = inkColor
        self.strokes = strokes
        self.previewPath = previewPath
        self.sourceCanvasWidth = sourceCanvasWidth
        self.sourceCanvasHeight = sourceCanvasHeight
    }
}

struct PatternSymmetry: Codable, Equatable {
    var xAxis: Bool
    var yAxis: Bool

    static let none = PatternSymmetry(xAxis: false, yAxis: false)
}

struct PatternCircle: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var centerX: Double
    var centerY: Double
    var radius: Double
}

struct PatternLine: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var startX: Double
    var startY: Double
    var endX: Double
    var endY: Double
    var snappedAngle: Int?
}

struct PatternWork: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var circles: [PatternCircle]
    var lines: [PatternLine]
    var symmetry: PatternSymmetry
    var angleStep: Int
    var previewPath: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(
        title: String = "My pattern",
        circles: [PatternCircle] = [],
        lines: [PatternLine] = [],
        symmetry: PatternSymmetry = PatternSymmetry(xAxis: false, yAxis: false),
        angleStep: Int = 15,
        previewPath: String? = nil
    ) {
        self.title = title
        self.circles = circles
        self.lines = lines
        self.symmetry = symmetry
        self.angleStep = angleStep
        self.previewPath = previewPath
    }
}
