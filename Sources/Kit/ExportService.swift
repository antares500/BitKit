import Foundation
import BitCore

public final class ExportService {
    public init() {}

    public func exportConversation(messages: [BitMessage], to file: URL) throws {
        let data = try JSONEncoder().encode(messages)
        try data.write(to: file)
    }

    public func importConversation(from file: URL) throws -> [BitMessage] {
        let data = try Data(contentsOf: file)
        return try JSONDecoder().decode([BitMessage].self, from: data)
    }
}
