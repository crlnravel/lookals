//
//  WebSocketAdapters.swift
//  Lookals
//

import Foundation

nonisolated internal enum WebSocketTaskMessage: Sendable, Equatable {
    case text(String)
    case binary(Data)
}

nonisolated internal protocol WebSocketTask: Sendable {
    var identity: UInt64 { get }
    func resume()
    func send(_ message: WebSocketTaskMessage) async throws
    func receive() async throws -> WebSocketTaskMessage
    func cancel(with code: WebSocketCloseCode, reason: Data?)
    func cancel()
}

nonisolated internal protocol WebSocketSession: Sendable {
    func makeWebSocketTask(url: URL) -> any WebSocketTask
    func invalidateAndCancel()
}

nonisolated internal protocol WebSocketSessionFactory: Sendable {
    func makeSession(delegate: WebSocketSessionDelegateBridge) -> any WebSocketSession
}

nonisolated internal protocol WebSocketTimeoutSleeper: Sendable {
    func sleep(for duration: Duration) async
}

nonisolated internal struct TaskWebSocketTimeoutSleeper: WebSocketTimeoutSleeper {
    func sleep(for duration: Duration) async {
        do {
            try await Task.sleep(for: duration)
        } catch {
            // Cancellation is the normal path when the peer acknowledges close.
        }
    }
}

nonisolated internal final class URLSessionWebSocketTaskAdapter: WebSocketTask, @unchecked Sendable {
    private let task: URLSessionWebSocketTask

    let identity: UInt64

    init(task: URLSessionWebSocketTask) {
        self.task = task
        identity = UInt64(UInt(bitPattern: ObjectIdentifier(task)))
    }

    func resume() {
        task.resume()
    }

    func send(_ message: WebSocketTaskMessage) async throws {
        try await task.send(message.foundationMessage)
    }

    func receive() async throws -> WebSocketTaskMessage {
        try await WebSocketTaskMessage(task.receive())
    }

    func cancel(with code: WebSocketCloseCode, reason: Data?) {
        task.cancel(with: code.foundationCode, reason: reason)
    }

    func cancel() {
        task.cancel()
    }
}

nonisolated extension WebSocketTaskMessage {
    init(_ message: WebSocketMessage) {
        switch message {
        case let .text(value): self = .text(value)
        case let .binary(value): self = .binary(value)
        }
    }

    init(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case let .string(value): self = .text(value)
        case let .data(value): self = .binary(value)
        @unknown default: self = .binary(Data())
        }
    }

    var foundationMessage: URLSessionWebSocketTask.Message {
        switch self {
        case let .text(value): .string(value)
        case let .binary(value): .data(value)
        }
    }
}

nonisolated internal final class URLSessionWebSocketSessionAdapter: WebSocketSession, @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func makeWebSocketTask(url: URL) -> any WebSocketTask {
        URLSessionWebSocketTaskAdapter(task: session.webSocketTask(with: url))
    }

    func invalidateAndCancel() {
        session.invalidateAndCancel()
    }
}

nonisolated internal struct URLSessionWebSocketSessionFactory: WebSocketSessionFactory {
    func makeSession(delegate: WebSocketSessionDelegateBridge) -> any WebSocketSession {
        let configuration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        return URLSessionWebSocketSessionAdapter(session: session)
    }
}

nonisolated internal final class WebSocketSessionDelegateBridge: NSObject, URLSessionWebSocketDelegate, URLSessionTaskDelegate, @unchecked Sendable {
    private let connectionLock = NSLock()
    private weak var connection: URLSessionWebSocketConnection?
    private let connectionID: UUID

    init(connection: URLSessionWebSocketConnection, connectionID: UUID) {
        self.connection = connection
        self.connectionID = connectionID
    }

    func clearConnection() {
        connectionLock.lock()
        defer { connectionLock.unlock() }
        connection = nil
    }

    private func connectionSnapshot() -> URLSessionWebSocketConnection? {
        connectionLock.lock()
        defer { connectionLock.unlock() }
        return connection
    }

    internal func connectionSnapshotForTesting() -> URLSessionWebSocketConnection? {
        connectionSnapshot()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        let taskID = UInt64(UInt(bitPattern: ObjectIdentifier(webSocketTask)))
        guard let connection = connectionSnapshot() else { return }
        Task { [connection] in
            await connection.didOpen(connectionID: connectionID, taskID: taskID)
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let taskID = UInt64(UInt(bitPattern: ObjectIdentifier(webSocketTask)))
        let code = WebSocketCloseCode(closeCode)
        guard let connection = connectionSnapshot() else { return }
        Task { [connection] in
            await connection.didClose(connectionID: connectionID, taskID: taskID, code: code, reason: reason)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let taskID = UInt64(UInt(bitPattern: ObjectIdentifier(task)))
        guard let connection = connectionSnapshot() else { return }
        Task { [connection] in
            await connection.didComplete(connectionID: connectionID, taskID: taskID, error: error)
        }
    }
}
