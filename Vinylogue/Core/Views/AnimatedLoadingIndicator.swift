import SwiftUI

/// Animated loading indicator that displays a spinning vinyl record animation
/// using the sequence of loading images from the asset catalog
struct AnimatedLoadingIndicator: View {
    private let frameCount = 12
    private let animationDuration: TimeInterval = 0.5
    private let size: CGFloat
    @State private var startTime = Date()

    init(size: CGFloat = 40) {
        self.size = size
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: animationDuration / Double(frameCount))) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startTime)
            let frameIndex = Int(elapsed / (animationDuration / Double(frameCount))) % frameCount
            let imageName = "loading\(String(format: "%02d", frameIndex + 1))"

            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        }
        .onAppear {
            startTime = Date()
        }
    }
}

// MARK: - Preview

#Preview("Small (40pt)") {
    VStack(spacing: 20) {
        AnimatedLoadingIndicator(size: 40)

        Text("40pt Loading Indicator")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("Medium (60pt)") {
    VStack(spacing: 20) {
        AnimatedLoadingIndicator(size: 60)

        Text("60pt Loading Indicator")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}

#Preview("Large (80pt)") {
    VStack(spacing: 20) {
        AnimatedLoadingIndicator(size: 80)

        Text("80pt Loading Indicator")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}
