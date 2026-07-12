//
//  WebSocketClient.swift
//  Lookals
//

import Foundation

nonisolated public protocol WebSocketClient: Sendable {
    func connect(to endpoint: URL) async throws -> any WebSocketConnection
}

nonisolated public protocol WebSocketConnection: Sendable {
    func currentState() async -> WebSocketConnectionState
    func messages() async throws -> AsyncThrowingStream<WebSocketMessage, Error>
    func send(_ message: WebSocketMessage) async throws
    func disconnect(code: WebSocketCloseCode, reason: Data?) async
}
