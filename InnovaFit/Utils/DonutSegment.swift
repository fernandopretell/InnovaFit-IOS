import SwiftUI

struct DonutSegment: Identifiable {
    let id = UUID()
    let percent: Double // Entre 0.0 y 1.0
    let color: Color
}

struct DonutChartView: View {
    let segments: [DonutSegment]
    let total: Int

    var body: some View {
        ZStack {
            // Dibuja cada segmento manualmente, acumulando los "offsets"
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                Circle()
                    .trim(from: startAngle(for: index), to: endAngle(for: index))
                    .stroke(segment.color, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 160, height: 160)
            }

            // El centro (blanco, para el hueco del donut)
            Circle()
                .fill(Color.white)
                .frame(width: 110, height: 110)

            // Texto central
            VStack(spacing: 0) {
                Text("\(total)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                Text("Sesiones")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 150, height: 150)
    }

    // Helpers para ángulos acumulados
    private func startAngle(for idx: Int) -> CGFloat {
        let totalPercent = segments.prefix(idx).map { $0.percent }.reduce(0, +)
        return CGFloat(totalPercent)
    }
    private func endAngle(for idx: Int) -> CGFloat {
        let totalPercent = segments.prefix(idx+1).map { $0.percent }.reduce(0, +)
        return CGFloat(totalPercent)
    }
}
