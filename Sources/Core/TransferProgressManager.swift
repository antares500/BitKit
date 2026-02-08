// TransferProgressManager.swift - Publisher progreso
import Foundation
import Combine

/// Centralized progress bus for Bluetooth file transfers.
/// Emits Combine events consumed by ChatViewModel to update UI progress indicators.
public class TransferProgressManager {
    public static let shared = TransferProgressManager()

    public enum Event {
        case started(id: String, totalFragments: Int)
        case updated(id: String, sentFragments: Int, totalFragments: Int)
        case completed(id: String, totalFragments: Int)
        case cancelled(id: String, sentFragments: Int, totalFragments: Int)
    }

    private let subject = PassthroughSubject<Event, Never>()
    private let queue = DispatchQueue(label: "com.bitchat.transfer-progress", attributes: .concurrent)
    private var states: [String: (sent: Int, total: Int)] = [:]

    public var publisher: AnyPublisher<Event, Never> {
        subject.eraseToAnyPublisher()
    }

    public func start(id: String, totalFragments: Int) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.states[id] = (sent: 0, total: totalFragments)
            self.subject.send(.started(id: id, totalFragments: totalFragments))
        }
    }

    public func recordFragmentSent(id: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self, var state = self.states[id] else { return }
            state.sent = min(state.sent + 1, state.total)
            self.states[id] = state
            self.subject.send(.updated(id: id, sentFragments: state.sent, totalFragments: state.total))
            if state.sent >= state.total {
                self.states.removeValue(forKey: id)
                self.subject.send(.completed(id: id, totalFragments: state.total))
            }
        }
    }

    public func cancel(id: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self, let state = self.states.removeValue(forKey: id) else { return }
            self.subject.send(.cancelled(id: id, sentFragments: state.sent, totalFragments: state.total))
        }
    }

    // Legacy method for backward compatibility
    public let progressPublisher = PassthroughSubject<Double, Never>()

    public func updateProgress(_ progress: Double) {
        progressPublisher.send(progress)
    }
}