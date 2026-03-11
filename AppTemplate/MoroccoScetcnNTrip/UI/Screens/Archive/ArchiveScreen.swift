import SwiftUI
import UIKit

struct ArchiveScreen: View {
    @EnvironmentObject private var dataStore: AppDataStore
    @State private var selectedSection: ArchiveSection = .calligraphy

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 10) {
            AppNavigationBar(title: navTitle, style: .titleOnly)
                .padding(.top, 2)

            sectionSwitcher

            if isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        if selectedSection == .calligraphy {
                            ForEach(dataStore.calligraphyWorks) { work in
                                sketchCard(work)
                            }
                        } else {
                            ForEach(dataStore.patternWorks) { work in
                                patternCard(work)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground.ignoresSafeArea())
    }

    private var navTitle: String {
        selectedSection == .calligraphy ? "Morocco Sketch" : "Morocco Patterns"
    }

    private var isEmpty: Bool {
        if selectedSection == .calligraphy {
            return dataStore.calligraphyWorks.isEmpty
        }
        return dataStore.patternWorks.isEmpty
    }

    private var sectionSwitcher: some View {
        HStack(spacing: 0) {
            switcherButton(title: "Skerch", section: .calligraphy)
            switcherButton(title: "Patterns", section: .pattern)
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(hex: "D0D0D4"))
        )
    }

    private func switcherButton(title: String, section: ArchiveSection) -> some View {
        let selected = selectedSection == section
        return Button {
            selectedSection = section
        } label: {
            Text(title)
                .appFont(.semibold, size: 17)
                .foregroundStyle(Color.appBlack)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    Capsule()
                        .fill(selected ? Color(hex: "F3F3F4") : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 2) {
            Text(emptyTitle)
                .appFont(.semibold, size: 17)
                .foregroundStyle(Color.appBlack)
            Text(emptySubtitle)
                .appFont(.regular, size: 17)
                .foregroundStyle(Color(hex: "787878"))
        }
    }

    private var emptyTitle: String {
        selectedSection == .calligraphy ? "Your archive is empty" : "No patterns yet"
    }

    private var emptySubtitle: String {
        selectedSection == .calligraphy ? "Save your first sketch" : "Start creating your first one"
    }

    private func sketchCard(_ work: CalligraphyWork) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                if let image = previewImage(path: work.previewPath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(14)
                } else if !work.strokes.isEmpty {
                    SketchArchiveFallbackView(work: work)
                        .padding(14)
                } else {
                    Text(work.letter.glyph)
                        .appFont(.regular, size: 74)
                        .foregroundStyle(Color.appBlack)
                        .offset(y: -8)
                }
            }
            .frame(height: 156)

            Text(dateText(work.createdAt))
                .appFont(.regular, size: 11)
                .foregroundStyle(Color(hex: "A0A0A5"))
                .padding(.top, 6)
        }
    }

    private func patternCard(_ work: PatternWork) -> some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)

                if let image = previewImage(for: work) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(14)
                } else {
                    Canvas { context, size in
                        if work.circles.isEmpty && work.lines.isEmpty {
                            let r = min(size.width, size.height) * 0.22
                            let rect = CGRect(
                                x: size.width * 0.5 - r,
                                y: size.height * 0.5 - r,
                                width: r * 2,
                                height: r * 2
                            )
                            context.fill(Path(ellipseIn: rect), with: .color(Color.appBlack))
                        } else {
                            for circle in work.circles {
                                let rect = CGRect(
                                    x: circle.centerX - circle.radius,
                                    y: circle.centerY - circle.radius,
                                    width: circle.radius * 2,
                                    height: circle.radius * 2
                                )
                                context.fill(Path(ellipseIn: rect), with: .color(Color.appBlack))
                            }
                            for line in work.lines {
                                var path = Path()
                                path.move(to: CGPoint(x: line.startX, y: line.startY))
                                path.addLine(to: CGPoint(x: line.endX, y: line.endY))
                                context.stroke(
                                    path,
                                    with: .color(Color.appBlack),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                                )
                            }
                        }
                    }
                }
            }
            .frame(height: 156)

            Text(dateText(work.createdAt))
                .appFont(.regular, size: 11)
                .foregroundStyle(Color(hex: "A0A0A5"))
                .padding(.top, 6)
        }
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }

    private func previewImage(for work: PatternWork) -> UIImage? {
        previewImage(path: work.previewPath)
    }

    private func previewImage(path: String?) -> UIImage? {
        guard let path, !path.isEmpty else { return nil }
        if FileManager.default.fileExists(atPath: path),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        if let url = URL(string: path), url.isFileURL,
           FileManager.default.fileExists(atPath: url.path),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        return nil
    }
}

private struct SketchArchiveFallbackView: View {
    let work: CalligraphyWork

    var body: some View {
        GeometryReader { geo in
            let sourceWidth = CGFloat(max(work.sourceCanvasWidth ?? inferredSourceWidth(), 1))
            let sourceHeight = CGFloat(max(work.sourceCanvasHeight ?? inferredSourceHeight(), 1))
            let xScale = geo.size.width / sourceWidth
            let yScale = geo.size.height / sourceHeight

            ZStack {
                Text(work.letter.glyph)
                    .appFont(.regular, size: min(geo.size.width, geo.size.height) * 0.62)
                    .offset(y: -8)
                    .foregroundStyle(Color(hex: "C4C4C7"))

                Canvas { context, _ in
                    for stroke in work.strokes {
                        var path = Path()
                        guard let first = stroke.points.first else { continue }
                        path.move(to: CGPoint(x: first.x * xScale, y: first.y * yScale))
                        for point in stroke.points.dropFirst() {
                            path.addLine(to: CGPoint(x: point.x * xScale, y: point.y * yScale))
                        }
                        context.stroke(
                            path,
                            with: .color(Color.appBlue),
                            style: StrokeStyle(lineWidth: 8 * min(xScale, yScale), lineCap: .round, lineJoin: .round)
                        )
                    }
                }
                .mask(
                    Text(work.letter.glyph)
                        .appFont(.regular, size: min(geo.size.width, geo.size.height) * 0.62)
                        .offset(y: -8)
                        .foregroundStyle(Color.white)
                )
            }
        }
    }

    private func inferredSourceWidth() -> Double {
        let maxX = work.strokes
            .flatMap { $0.points.map(\.x) }
            .max() ?? 300
        return max(maxX + 20, 120)
    }

    private func inferredSourceHeight() -> Double {
        let maxY = work.strokes
            .flatMap { $0.points.map(\.y) }
            .max() ?? 300
        return max(maxY + 20, 120)
    }
}

#Preview {
    ArchiveScreen()
        .environmentObject(AppDataStore())
}
