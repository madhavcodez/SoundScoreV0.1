import Foundation
import Combine

// MARK: - Outbox Types

enum OutboxOperationType: String {
    case rateAlbum
    case toggleReaction
    case createList
    case exportData
    case registerDeviceToken
    case updateNotificationPreferences
}

struct OutboxOperation: Identifiable {
    let id: UUID
    let type: OutboxOperationType
    let payload: [String: String]
    let idempotencyKey: UUID
    let createdAt: Date
    var attemptCount: Int
    var nextAttemptAt: Date
    var lastError: String?

    init(
        type: OutboxOperationType,
        payload: [String: String],
        id: UUID = UUID(),
        idempotencyKey: UUID = UUID(),
        createdAt: Date = Date(),
        attemptCount: Int = 0,
        nextAttemptAt: Date = Date(),
        lastError: String? = nil
    ) {
        self.id = id
        self.type = type
        self.payload = payload
        self.idempotencyKey = idempotencyKey
        self.createdAt = createdAt
        self.attemptCount = attemptCount
        self.nextAttemptAt = nextAttemptAt
        self.lastError = lastError
    }
}

// MARK: - In-Memory Store

class InMemoryOutboxStore: ObservableObject {
    @Published var pending: [OutboxOperation] = []

    func enqueue(_ op: OutboxOperation) {
        pending.append(op)
    }

    func markDispatched(_ id: UUID) {
        pending.removeAll { $0.id == id }
    }

    func markFailed(_ id: UUID, error: String) {
        guard let index = pending.firstIndex(where: { $0.id == id }) else { return }
        let nextAttempt = pending[index].attemptCount + 1
        let backoffSeconds = pow(2.0, Double(min(nextAttempt, 6)))
        pending[index].attemptCount = nextAttempt
        pending[index].nextAttemptAt = Date().addingTimeInterval(backoffSeconds)
        pending[index].lastError = error
    }
}

// MARK: - Sync Engine

struct OutboxSyncEngine {
    let store: InMemoryOutboxStore

    func flush(handler: (OutboxOperation) async throws -> Void) async {
        let snapshot = store.pending
        let now = Date()

        for op in snapshot {
            guard op.nextAttemptAt <= now else { continue }
            do {
                try await handler(op)
                await MainActor.run { store.markDispatched(op.id) }
            } catch {
                await MainActor.run {
                    store.markFailed(op.id, error: error.localizedDescription)
                }
            }
        }
    }
}
