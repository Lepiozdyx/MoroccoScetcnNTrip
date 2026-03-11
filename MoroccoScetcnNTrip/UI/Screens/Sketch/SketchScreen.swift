import SwiftUI
import UIKit

struct SketchScreen: View {
    @EnvironmentObject private var dataStore: AppDataStore

    @State private var selectedLetter: ArabicLetter?
    @State private var selectedTool: SketchTool = .pen
    @State private var strokes: [SketchStroke] = []
    @State private var activePoints: [CGPoint] = []
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        VStack(spacing: 8) {
            AppNavigationBar(title: "Morocco Sketch", style: .titleOnly)
                .padding(.top, 2)

            letterStrip
            sketchCanvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomTools
                .padding(.bottom, 4)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground.ignoresSafeArea())
        .clipped()
    }

    private var letterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ArabicLetter.allCases) { letter in
                    let isSelected = selectedLetter == letter

                    Button {
                        selectedLetter = letter
                        strokes.removeAll(keepingCapacity: true)
                        activePoints.removeAll(keepingCapacity: true)
                    } label: {
                        Text(letter.glyph)
                            .appFont(.semibold, size: 20)
                            .foregroundStyle(isSelected ? Color.white : Color.appBlack)
                            .frame(width: 52, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isSelected ? Color.appBlue : Color(hex: "E9E9EC"))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 16)
        }
        .padding(.horizontal, -16)
    }

    private var sketchCanvas: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(hex: "F4F4F5"))

                guideLayer

                if let selectedLetter {
                    letterShape(selectedLetter, in: geo.size)
                        .foregroundStyle(Color(hex: "C4C4C7"))
                } else {
                    Text("Select a symbol")
                        .appFont(.regular, size: 16)
                        .foregroundStyle(Color(hex: "8B8B90"))
                }

                maskedStrokesLayer(in: geo.size)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .contentShape(Rectangle())
            .gesture(drawingGesture(in: geo.size))
            .onAppear {
                canvasSize = geo.size
            }
            .onChange(of: geo.size) { newSize in
                canvasSize = newSize
            }
        }
    }

    private var guideLayer: some View { Color.clear }

    private var strokesLayer: some View {
        Canvas { context, _ in
            for stroke in strokes {
                var path = Path()
                guard let first = stroke.points.first else { continue }
                path.move(to: first)
                for point in stroke.points.dropFirst() {
                    path.addLine(to: point)
                }
                context.stroke(
                    path,
                    with: .color(stroke.color),
                    style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
                )
            }

            if !activePoints.isEmpty {
                var path = Path()
                path.move(to: activePoints[0])
                for point in activePoints.dropFirst() {
                    path.addLine(to: point)
                }
                context.stroke(
                    path,
                    with: .color(selectedTool.strokeColor),
                    style: StrokeStyle(lineWidth: selectedTool.lineWidth, lineCap: .round, lineJoin: .round)
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func maskedStrokesLayer(in size: CGSize) -> some View {
        Group {
            if let selectedLetter {
                strokesLayer
                    .mask(
                        letterShape(selectedLetter, in: size)
                            .foregroundStyle(Color.white)
                    )
            } else {
                Color.clear
            }
        }
    }

    private func letterShape(_ letter: ArabicLetter, in size: CGSize) -> some View {
        Text(letter.glyph)
            .appFont(.regular, size: min(size.width, size.height) * 0.62)
            .offset(y: -8)
    }

    private var bottomTools: some View {
        HStack(spacing: 8) {
            toolButton(.pen, symbol: "pencil.tip")
            toolButton(.ink, symbol: "paintbrush")
            toolButton(.eraser, symbol: "eraser")

            Spacer()

            Button(action: saveCalligraphy) {
                saveIcon
                    .frame(width: 52, height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.appBlue)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var saveIcon: some View {
        Group {
            if let icon = UIImage(named: "canvas_save_icon") {
                Image(uiImage: icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .foregroundStyle(Color.white)
    }

    private func toolButton(_ tool: SketchTool, symbol: String) -> some View {
        let selected = selectedTool == tool
        return Button {
            selectedTool = tool
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .medium))
                .foregroundStyle(selected ? Color.appBlue : Color(hex: "808086"))
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: "E8E8EA"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(selected ? Color.appBlue.opacity(0.45) : Color.clear, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func drawingGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard selectedLetter != nil else { return }
                let point = clamped(value.location, in: size)
                if selectedTool == .eraser {
                    erase(at: point)
                } else {
                    activePoints.append(point)
                }
            }
            .onEnded { _ in
                guard selectedLetter != nil else {
                    activePoints.removeAll(keepingCapacity: true)
                    return
                }
                guard selectedTool != .eraser else {
                    activePoints.removeAll(keepingCapacity: true)
                    return
                }
                guard activePoints.count > 1 else {
                    activePoints.removeAll(keepingCapacity: true)
                    return
                }

                strokes.append(
                    SketchStroke(
                        points: activePoints,
                        color: selectedTool.strokeColor,
                        lineWidth: selectedTool.lineWidth
                    )
                )
                activePoints.removeAll(keepingCapacity: true)
            }
    }

    private func erase(at point: CGPoint) {
        let radius: CGFloat = 18
        let radiusSquared = radius * radius
        strokes.removeAll { stroke in
            stroke.points.contains { strokePoint in
                let dx = strokePoint.x - point.x
                let dy = strokePoint.y - point.y
                return (dx * dx + dy * dy) <= radiusSquared
            }
        }
    }

    private func clamped(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(0, point.x), size.width),
            y: min(max(0, point.y), size.height)
        )
    }

    private func saveCalligraphy() {
        guard let selectedLetter else { return }

        let mappedStrokes = strokes.map { stroke in
            CalligraphyStroke(
                points: stroke.points.map { point in
                    CalligraphyStrokePoint(
                        x: point.x,
                        y: point.y,
                        pressure: 1,
                        t: 0
                    )
                }
            )
        }

        let inkColor: InkColor = selectedTool == .ink ? .blue : .black
        let previewPath = makeCalligraphyPreviewPath(letter: selectedLetter)
        if let existing = dataStore.calligraphyWorks.first(where: { $0.letter == selectedLetter }) {
            var updated = existing
            updated.inkColor = inkColor
            updated.strokes = mappedStrokes
            updated.previewPath = previewPath ?? updated.previewPath
            updated.sourceCanvasWidth = Double(max(canvasSize.width, 1))
            updated.sourceCanvasHeight = Double(max(canvasSize.height, 1))
            dataStore.upsert(updated)
        } else {
            dataStore.createCalligraphyWork(
                letter: selectedLetter,
                inkColor: inkColor,
                strokes: mappedStrokes,
                previewPath: previewPath,
                sourceCanvasWidth: Double(max(canvasSize.width, 1)),
                sourceCanvasHeight: Double(max(canvasSize.height, 1))
            )
        }
    }

    private func makeCalligraphyPreviewPath(letter: ArabicLetter) -> String? {
        let width = max(canvasSize.width, 1)
        let height = max(canvasSize.height, 1)
        let renderSize = CGSize(width: width, height: height)
        let view = CalligraphyPreviewRenderView(letter: letter, strokes: strokes, size: renderSize)
        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage, let data = image.pngData() else { return nil }

        let name = "calligraphy_preview_\(letter.rawValue)_\(UUID().uuidString).png"
        let url = documentsDirectory().appendingPathComponent(name)
        do {
            try data.write(to: url, options: .atomic)
            return url.path
        } catch {
            return nil
        }
    }

    private func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }
}

private struct CalligraphyPreviewRenderView: View {
    let letter: ArabicLetter
    let strokes: [SketchStroke]
    let size: CGSize

    var body: some View {
        ZStack {
            Color.white
            Text(letter.glyph)
                .appFont(.regular, size: min(size.width, size.height) * 0.62)
                .offset(y: -8)
                .foregroundStyle(Color(hex: "C4C4C7"))

            Canvas { context, _ in
                for stroke in strokes {
                    var path = Path()
                    guard let first = stroke.points.first else { continue }
                    path.move(to: first)
                    for point in stroke.points.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(
                        path,
                        with: .color(stroke.color),
                        style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round)
                    )
                }
            }
            .mask(
                Text(letter.glyph)
                    .appFont(.regular, size: min(size.width, size.height) * 0.62)
                    .offset(y: -8)
                    .foregroundStyle(Color.white)
            )
        }
        .frame(width: size.width, height: size.height)
    }
}

private enum SketchTool: Equatable {
    case eraser
    case pen
    case ink

    var strokeColor: Color {
        switch self {
        case .eraser:
            return Color.clear
        case .pen:
            return Color.appBlue
        case .ink:
            return Color.appBlue
        }
    }

    var lineWidth: CGFloat {
        switch self {
        case .eraser:
            return 26
        case .pen:
            return 8
        case .ink:
            return 14
        }
    }
}

private struct SketchStroke: Identifiable {
    let id = UUID()
    let points: [CGPoint]
    let color: Color
    let lineWidth: CGFloat
}

#Preview {
    SketchScreen()
        .environmentObject(AppDataStore())
}
