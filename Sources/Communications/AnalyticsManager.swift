import Foundation

public enum AnalyticsEvent: String, Codable {
    case messageSent
    case messageReceived
    case userJoined
    case userLeft
    case groupCreated
    case fileShared
    case videoShared
    case imageShared
    case errorOccurred
}

public class AnalyticsManager {
    private var events: [AnalyticsEventData] = []
    private let maxEvents = 1000
    private let persistenceKey = "analyticsEvents"

    public init() {
        loadEvents()
    }

    public func logEvent(_ event: AnalyticsEvent, metadata: [String: Any]? = nil) {
        let eventData = AnalyticsEventData(event: event, timestamp: Date(), metadata: metadata)
        events.append(eventData)
        
        // Keep only recent events
        if events.count > maxEvents {
            events.removeFirst()
        }
        
        saveEvents()
    }

    public func getEventCount(for event: AnalyticsEvent, since date: Date? = nil) -> Int {
        let filtered = events.filter { $0.event == event }
        if let date = date {
            return filtered.filter { $0.timestamp >= date }.count
        }
        return filtered.count
    }

    public func getAllEvents(since date: Date? = nil) -> [AnalyticsEventData] {
        if let date = date {
            return events.filter { $0.timestamp >= date }
        }
        return events
    }

    public func clearEvents() {
        events.removeAll()
        UserDefaults.standard.removeObject(forKey: persistenceKey)
    }

    private func saveEvents() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let decoded = try? JSONDecoder().decode([AnalyticsEventData].self, from: data) {
            events = decoded
        }
    }
}

public struct AnalyticsEventData: Codable {
    public let event: AnalyticsEvent
    public let timestamp: Date
    public let metadata: [String: Any]?

    private enum CodingKeys: String, CodingKey {
        case event, timestamp, metadata
    }

    public init(event: AnalyticsEvent, timestamp: Date, metadata: [String: Any]?) {
        self.event = event
        self.timestamp = timestamp
        self.metadata = metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        event = try container.decode(AnalyticsEvent.self, forKey: .event)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        // metadata is optional and may not be encodable, so skip for now
        metadata = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(event, forKey: .event)
        try container.encode(timestamp, forKey: .timestamp)
        // Skip metadata for simplicity
    }
}