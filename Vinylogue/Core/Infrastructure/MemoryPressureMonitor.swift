import Dependencies
import Foundation

/// Monitors system memory pressure and provides updates via async stream
actor MemoryPressureMonitor {
    enum PressureLevel: Int, Comparable, Sendable, CustomStringConvertible {
        case normal = 0, moderate = 1, critical = 2

        static func < (lhs: PressureLevel, rhs: PressureLevel) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        var description: String {
            switch self {
            case .normal: return "normal"
            case .moderate: return "moderate"
            case .critical: return "critical"
            }
        }
    }

    private let pressureSource: DispatchSourceMemoryPressure
    private let pressureSubject: (stream: AsyncStream<PressureLevel>, continuation: AsyncStream<PressureLevel>.Continuation)

    var pressureUpdates: AsyncStream<PressureLevel> {
        pressureSubject.stream
    }

    init() {
        pressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.normal, .warning, .critical],
            queue: DispatchQueue.global(qos: .utility)
        )
        pressureSubject = AsyncStream<PressureLevel>.makeStream()

        setupPressureMonitoring()
    }

    private nonisolated func setupPressureMonitoring() {
        pressureSource.setEventHandler { @Sendable [weak self] in
            Task {
                await self?.handlePressureEvent()
            }
        }
        pressureSource.resume()
    }

    private func handlePressureEvent() {
        let flags = pressureSource.data
        let level: PressureLevel = if flags.contains(.critical) {
            .critical
        } else if flags.contains(.warning) {
            .moderate
        } else {
            .normal
        }

        pressureSubject.continuation.yield(level)
    }

    deinit {
        pressureSource.cancel()
        pressureSubject.continuation.finish()
    }
}

// MARK: - Dependency

extension MemoryPressureMonitor: DependencyKey {
    static let liveValue = MemoryPressureMonitor()

    static let testValue: MemoryPressureMonitor = // For tests, we want a mock that doesn't actually monitor system memory
        .init()

    static let previewValue: MemoryPressureMonitor = // For previews, use the same as test
        .init()
}

extension DependencyValues {
    var memoryPressureMonitor: MemoryPressureMonitor {
        get { self[MemoryPressureMonitor.self] }
        set { self[MemoryPressureMonitor.self] = newValue }
    }
}
