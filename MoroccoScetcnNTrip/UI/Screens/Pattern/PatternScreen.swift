import SwiftUI
import UIKit

struct PatternScreen: View {
    @EnvironmentObject private var dataStore: AppDataStore

    @State private var selectedTool: PatternTool = .circle
    @State private var symmetry: PatternSymmetry = .none
    @State private var strokeWidth: CGFloat = 8

    @State private var circles: [CanvasCircle] = []
    @State private var lines: [CanvasLine] = []

    @State private var dragStart: CGPoint?
    @State private var previewCircle: CanvasCircle?
    @State private var previewLine: CanvasLine?
    @State private var canvasSize: CGSize = .zero

    private let angleStep = 15
    private let patternDrawColor = Color.appBlack

    var body: some View {
        VStack(spacing: 8) {
            AppNavigationBar(title: "Morocco Sketch", style: .titleOnly)
                .padding(.top, 2)

            canvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 14) {
                toolsRow
                widthControl
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.appBackground.ignoresSafeArea())
        .clipped()
    }

    private var canvas: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color(hex: "F3F3F4"))

                Canvas { context, size in
                    draw(circles: circles, lines: lines, in: size, context: &context)
                    if let previewCircle {
                        draw(circles: [previewCircle], lines: [], in: size, context: &context)
                    }
                    if let previewLine {
                        draw(circles: [], lines: [previewLine], in: size, context: &context)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
            .contentShape(Rectangle())
            .gesture(drawingGesture(in: geo.size))
            .onAppear {
                canvasSize = geo.size
            }
            .onChange(of: geo.size) { newSize in
                canvasSize = newSize
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var toolsRow: some View {
        HStack(spacing: 12) {
            toolButton(.circle, symbol: "circle.fill")
            toolButton(.line, symbol: "line.diagonal")
            symmetryButton

            Spacer()

            Button(action: savePattern) {
                saveIcon
                    .frame(width: 58, height: 58)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.appBlue)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }

    private var saveIcon: some View {
        Group {
            if let icon = UIImage(named: "canvas_save_icon") {
                Image(uiImage: icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
            } else {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 20, weight: .semibold))
            }
        }
        .foregroundStyle(Color.white)
    }

    private func toolButton(_ tool: PatternTool, symbol: String) -> some View {
        let selected = selectedTool == tool
        return Button {
            selectedTool = tool
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(selected ? Color.appBlue : Color(hex: "7F7F84"))
                .frame(width: 58, height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: "ECECEF"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(selected ? Color.appBlue : Color.clear, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var symmetryButton: some View {
        Button(action: cycleSymmetry) {
            VStack(spacing: 1) {
                symmetryIcon
                Text(symmetryLabel)
                    .appFont(.medium, size: 10)
                    .foregroundStyle(symmetry == .none ? Color(hex: "7F7F84") : Color.appBlue)
            }
            .frame(width: 58, height: 58)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "ECECEF"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(symmetry == .none ? Color.clear : Color.appBlue, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var symmetryIcon: some View {
        Group {
            if let icon = UIImage(named: "pattern_symmetry") {
                Image(uiImage: icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
            } else {
                Image(systemName: "square.split.2x2")
                    .font(.system(size: 26, weight: .medium))
            }
        }
        .foregroundStyle(symmetry == .none ? Color(hex: "7F7F84") : Color.appBlue)
    }

    private var widthControl: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(hex: "8B8B91"))
                .frame(width: 20, height: 20)

            Slider(value: $strokeWidth, in: 2...22, step: 1)
                .tint(Color.appBlue)

            Circle()
                .fill(Color(hex: "8B8B91"))
                .frame(width: 56, height: 56)
        }
        .padding(.horizontal, 12)
    }

    private var symmetryLabel: String {
        if symmetry.xAxis && symmetry.yAxis { return "X+Y" }
        if symmetry.xAxis { return "X" }
        if symmetry.yAxis { return "Y" }
        return "Off"
    }

    private func cycleSymmetry() {
        if symmetry == .none {
            symmetry = PatternSymmetry(xAxis: true, yAxis: false)
            return
        }
        if symmetry.xAxis && !symmetry.yAxis {
            symmetry = PatternSymmetry(xAxis: false, yAxis: true)
            return
        }
        if !symmetry.xAxis && symmetry.yAxis {
            symmetry = PatternSymmetry(xAxis: true, yAxis: true)
            return
        }
        symmetry = .none
    }

    private func drawingGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if dragStart == nil {
                    dragStart = clamped(value.startLocation, in: size)
                }

                guard let start = dragStart else { return }
                let current = clamped(value.location, in: size)

                switch selectedTool {
                case .circle:
                    let radius = max(1, hypot(current.x - start.x, current.y - start.y))
                    previewCircle = CanvasCircle(center: start, radius: radius, lineWidth: strokeWidth)
                    previewLine = nil
                case .line:
                    let end = snappedPoint(from: start, to: current, step: angleStep)
                    let angle = snappedAngle(from: start, to: end)
                    previewLine = CanvasLine(start: start, end: end, lineWidth: strokeWidth, snappedAngle: angle)
                    previewCircle = nil
                }
            }
            .onEnded { _ in
                defer {
                    dragStart = nil
                    previewCircle = nil
                    previewLine = nil
                }

                guard let start = dragStart else { return }

                switch selectedTool {
                case .circle:
                    guard let circle = previewCircle else { return }
                    append(circle: circle, centerRef: start, in: size)
                case .line:
                    guard let line = previewLine else { return }
                    append(line: line, in: size)
                }
            }
    }

    private func append(circle: CanvasCircle, centerRef: CGPoint, in size: CGSize) {
        var generated: [CanvasCircle] = [circle]
        let mirror = mirrorPoints(of: centerRef, in: size, symmetry: symmetry)
        for point in mirror {
            generated.append(CanvasCircle(center: point, radius: circle.radius, lineWidth: circle.lineWidth))
        }
        circles.append(contentsOf: generated)
    }

    private func append(line: CanvasLine, in size: CGSize) {
        var generated: [CanvasLine] = [line]
        if symmetry.xAxis {
            generated.append(mirror(line: line, axis: .x, in: size))
        }
        if symmetry.yAxis {
            generated.append(mirror(line: line, axis: .y, in: size))
        }
        if symmetry.xAxis && symmetry.yAxis {
            generated.append(
                mirror(
                    line: mirror(line: line, axis: .x, in: size),
                    axis: .y,
                    in: size
                )
            )
        }
        lines.append(contentsOf: generated)
    }

    private func mirrorPoints(of point: CGPoint, in size: CGSize, symmetry: PatternSymmetry) -> [CGPoint] {
        var result: [CGPoint] = []
        if symmetry.xAxis {
            result.append(CGPoint(x: point.x, y: size.height - point.y))
        }
        if symmetry.yAxis {
            result.append(CGPoint(x: size.width - point.x, y: point.y))
        }
        if symmetry.xAxis && symmetry.yAxis {
            result.append(CGPoint(x: size.width - point.x, y: size.height - point.y))
        }
        return result
    }

    private func mirror(line: CanvasLine, axis: MirrorAxis, in size: CGSize) -> CanvasLine {
        let start: CGPoint
        let end: CGPoint
        switch axis {
        case .x:
            start = CGPoint(x: line.start.x, y: size.height - line.start.y)
            end = CGPoint(x: line.end.x, y: size.height - line.end.y)
        case .y:
            start = CGPoint(x: size.width - line.start.x, y: line.start.y)
            end = CGPoint(x: size.width - line.end.x, y: line.end.y)
        }
        return CanvasLine(
            start: start,
            end: end,
            lineWidth: line.lineWidth,
            snappedAngle: snappedAngle(from: start, to: end)
        )
    }

    private func snappedPoint(from start: CGPoint, to current: CGPoint, step: Int) -> CGPoint {
        let dx = current.x - start.x
        let dy = current.y - start.y
        let length = hypot(dx, dy)
        guard length > 0 else { return current }

        let angle = atan2(dy, dx)
        let stepRad = CGFloat(step) * .pi / 180
        let snapped = round(angle / stepRad) * stepRad

        return CGPoint(
            x: start.x + cos(snapped) * length,
            y: start.y + sin(snapped) * length
        )
    }

    private func snappedAngle(from start: CGPoint, to end: CGPoint) -> Int {
        let radians = atan2(end.y - start.y, end.x - start.x)
        var degrees = Int((radians * 180 / .pi).rounded())
        if degrees < 0 { degrees += 360 }
        return (degrees / angleStep) * angleStep
    }

    private func clamped(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(0, point.x), size.width),
            y: min(max(0, point.y), size.height)
        )
    }

    private func draw(
        circles: [CanvasCircle],
        lines: [CanvasLine],
        in _: CGSize,
        context: inout GraphicsContext
    ) {
        for circle in circles {
            let rect = CGRect(
                x: circle.center.x - circle.radius,
                y: circle.center.y - circle.radius,
                width: circle.radius * 2,
                height: circle.radius * 2
            )
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(patternDrawColor),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
            )
            context.fill(
                Path(ellipseIn: rect),
                with: .color(patternDrawColor.opacity(0.85))
            )
        }

        for line in lines {
            var path = Path()
            path.move(to: line.start)
            path.addLine(to: line.end)
            context.stroke(
                path,
                with: .color(patternDrawColor),
                style: StrokeStyle(lineWidth: line.lineWidth, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func savePattern() {
        let mappedCircles = circles.map { circle in
            PatternCircle(centerX: circle.center.x, centerY: circle.center.y, radius: circle.radius)
        }
        let mappedLines = lines.map { line in
            PatternLine(
                startX: line.start.x,
                startY: line.start.y,
                endX: line.end.x,
                endY: line.end.y,
                snappedAngle: line.snappedAngle
            )
        }
        let previewPath = makePreviewPath()
        dataStore.createPatternWork(
            title: "My mosaic",
            circles: mappedCircles,
            lines: mappedLines,
            symmetry: symmetry,
            angleStep: angleStep,
            previewPath: previewPath
        )
    }

    private func makePreviewPath() -> String? {
        let targetSize = CGSize(
            width: max(canvasSize.width, 1),
            height: max(canvasSize.height, 1)
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            let rect = CGRect(origin: .zero, size: targetSize)
            let clipPath = UIBezierPath(roundedRect: rect, cornerRadius: 34)
            clipPath.addClip()
            cg.setFillColor(UIColor(Color(hex: "F3F3F4")).cgColor)
            cg.fill(rect)

            for circle in circles {
                let circleRect = CGRect(
                    x: circle.center.x - circle.radius,
                    y: circle.center.y - circle.radius,
                    width: circle.radius * 2,
                    height: circle.radius * 2
                )
                cg.setFillColor(UIColor(Color.appBlack).cgColor)
                cg.fillEllipse(in: circleRect)
            }

            for line in lines {
                cg.setStrokeColor(UIColor(Color.appBlack).cgColor)
                cg.setLineWidth(line.lineWidth)
                cg.setLineCap(.round)
                cg.setLineJoin(.round)
                cg.move(to: line.start)
                cg.addLine(to: line.end)
                cg.strokePath()
            }
        }

        guard let data = image.pngData() else { return nil }
        let fileName = "pattern_preview_\(UUID().uuidString).png"
        let url = documentsDirectory().appendingPathComponent(fileName)
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

private enum PatternTool {
    case circle
    case line
}

private enum MirrorAxis {
    case x
    case y
}

private struct CanvasCircle: Identifiable {
    let id = UUID()
    let center: CGPoint
    let radius: CGFloat
    let lineWidth: CGFloat
}

private struct CanvasLine: Identifiable {
    let id = UUID()
    let start: CGPoint
    let end: CGPoint
    let lineWidth: CGFloat
    let snappedAngle: Int
}

#Preview {
    PatternScreen()
        .environmentObject(AppDataStore())
}
