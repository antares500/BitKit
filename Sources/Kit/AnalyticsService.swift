import Foundation
import Combine

public final class AnalyticsService {
    public var isEnabled = false
    private var metrics: [String: Int] = [:]
    public let metricsPublisher = PassthroughSubject<[String: Int], Never>()

    public init() {}

    public func trackEvent(_ event: String) {
        guard isEnabled else { return }
        metrics[event, default: 0] += 1
        metricsPublisher.send(metrics)
    }

    public func getMetrics() -> [String: Int] {
        metrics
    }
}
