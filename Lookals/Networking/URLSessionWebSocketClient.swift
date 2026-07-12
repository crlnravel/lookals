//
//  URLSessionWebSocketClient.swift
//  Lookals
//

import Foundation

public struct URLSessionWebSocketClient: WebSocketClient, Sendable {
    private let factory: any WebSocketSessionFactory
    private let timeoutSleeper: any WebSocketTimeoutSleeper

    public init() {
        factory = URLSessionWebSocketSessionFactory()
        timeoutSleeper = TaskWebSocketTimeoutSleeper()
    }

    internal init(
        factory: any WebSocketSessionFactory,
        timeoutSleeper: any WebSocketTimeoutSleeper = TaskWebSocketTimeoutSleeper()
    ) {
        self.factory = factory
        self.timeoutSleeper = timeoutSleeper
    }

    public func connect(to endpoint: URL) async throws -> any WebSocketConnection {
        guard let scheme = endpoint.scheme?.lowercased(), scheme == "ws" || scheme == "wss", endpoint.host != nil else {
            throw WebSocketClientError.invalidEndpoint
        }

        let connection = URLSessionWebSocketConnection(
            endpoint: endpoint,
            factory: factory,
            timeoutSleeper: timeoutSleeper
        )
        try await connection.start()
        return connection
    }
}

internal actor URLSessionWebSocketConnection: WebSocketConnection {
    private enum TerminalOutcome {
        case disconnected
        case failed(WebSocketClientError)
    }

    private struct PendingSend {
        let id: UInt64
        let message: WebSocketTaskMessage
        var continuation: CheckedContinuation<Void, Error>?
    }

    nonisolated let connectionID: UUID
    private let endpoint: URL
    private let factory: any WebSocketSessionFactory
    private let timeoutSleeper: any WebSocketTimeoutSleeper

    private var state: WebSocketConnectionState = .connecting
    private var terminalOutcome: TerminalOutcome?
    private var session: (any WebSocketSession)?
    private var task: (any WebSocketTask)?
    private var delegateBridge: WebSocketSessionDelegateBridge?
    private var receiveTask: Task<Void, Never>?
    private var closeTimeoutTask: Task<Void, Never>?

    private var handshakeContinuation: CheckedContinuation<Void, Error>?
    private var disconnectWaiters: [CheckedContinuation<Void, Never>] = []

    private var messagesClaimed = false
    private var streamContinuation: AsyncThrowingStream<WebSocketMessage, Error>.Continuation?

    private var nextSendID: UInt64 = 0
    private var activeSend: PendingSend?
    private var sendQueue: [PendingSend] = []

    init(
        endpoint: URL,
        factory: any WebSocketSessionFactory,
        timeoutSleeper: any WebSocketTimeoutSleeper
    ) {
        self.endpoint = endpoint
        self.factory = factory
        self.timeoutSleeper = timeoutSleeper
        connectionID = UUID()
    }

    func start() async throws {
        let bridge = WebSocketSessionDelegateBridge(connection: self, connectionID: connectionID)
        let session = factory.makeSession(delegate: bridge)
        let task = session.makeWebSocketTask(url: endpoint)

        delegateBridge = bridge
        self.session = session
        self.task = task

        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                handshakeContinuation = continuation
                task.resume()
                if Task.isCancelled {
                    cancelConnect()
                }
            }
        }, onCancel: {
            Task { [weak self] in
                await self?.cancelConnect()
            }
        })
    }

    func currentState() -> WebSocketConnectionState {
        state
    }

    func messages() throws -> AsyncThrowingStream<WebSocketMessage, Error> {
        guard !messagesClaimed else {
            throw WebSocketClientError.messagesAlreadyClaimed
        }
        messagesClaimed = true

        let (actualStream, continuation) = AsyncThrowingStream<WebSocketMessage, Error>.makeStream(
            bufferingPolicy: .bufferingOldest(64)
        )

        continuation.onTermination = { [weak self] termination in
            guard case .cancelled = termination else { return }
            Task { [weak self] in
                await self?.streamCancelled()
            }
        }
        streamContinuation = continuation

        switch terminalOutcome {
        case .none:
            if state == .connected {
                startReceiveLoop()
            }
        case .some(.disconnected):
            continuation.finish()
        case let .some(.failed(error)):
            continuation.finish(throwing: error)
        }

        return actualStream
    }

    func send(_ message: WebSocketMessage) async throws {
        guard state == .connected, terminalOutcome == nil else {
            throw WebSocketClientError.notConnected
        }

        let requestID = nextSendID
        nextSendID &+= 1
        let task = self.task
        guard task != nil else { throw WebSocketClientError.notConnected }

        try await withTaskCancellationHandler(operation: {
            try Task.checkCancellation()
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                guard state == .connected, terminalOutcome == nil else {
                    continuation.resume(throwing: WebSocketClientError.notConnected)
                    return
                }
                sendQueue.append(PendingSend(id: requestID, message: WebSocketTaskMessage(message), continuation: continuation))
                startNextSendIfNeeded()
            }
        }, onCancel: {
            Task { [weak self] in
                await self?.cancelSend(requestID: requestID)
            }
        })
    }

    func disconnect(code: WebSocketCloseCode = .normal, reason: Data? = nil) async {
        guard terminalOutcome == nil else { return }

        if state == .connecting, handshakeContinuation != nil {
            state = .disconnecting
        } else if state == .connected {
            state = .disconnecting
        }

        guard let task else {
            finish(connectionID: connectionID, taskID: nil, outcome: .disconnected)
            return
        }

        task.cancel(with: code, reason: reason)
        let taskID = task.identity
        let connectionID = self.connectionID
        closeTimeoutTask = Task { [weak self, timeoutSleeper] in
            await timeoutSleeper.sleep(for: .seconds(5))
            await self?.closeTimedOut(connectionID: connectionID, taskID: taskID)
        }

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            if terminalOutcome == nil {
                disconnectWaiters.append(continuation)
            } else {
                continuation.resume()
            }
        }
    }

    // MARK: Delegate events

    func didOpen(connectionID: UUID, taskID: UInt64) {
        guard connectionID == self.connectionID, self.task?.identity == taskID, terminalOutcome == nil, state == .connecting else { return }
        state = .connected
        handshakeContinuation?.resume()
        handshakeContinuation = nil
    }

    func didClose(connectionID: UUID, taskID: UInt64, code: WebSocketCloseCode, reason: Data?) {
        guard connectionID == self.connectionID, task?.identity == taskID, terminalOutcome == nil else { return }
        if state == .disconnecting {
            finish(connectionID: connectionID, taskID: taskID, outcome: .disconnected)
        } else if code == .normal || code == .goingAway {
            finish(connectionID: connectionID, taskID: taskID, outcome: .disconnected)
        } else {
            finish(connectionID: connectionID, taskID: taskID, outcome: .failed(.peerClosed(code: code)))
        }
    }

    func didComplete(connectionID: UUID, taskID: UInt64, error: Error?) {
        guard connectionID == self.connectionID, task?.identity == taskID, terminalOutcome == nil else { return }
        if state == .disconnecting {
            finish(connectionID: connectionID, taskID: taskID, outcome: .disconnected)
        } else if let error {
            _ = error
            let failure: WebSocketClientError = state == .connecting ? .handshakeFailed : .taskFailed
            finish(connectionID: connectionID, taskID: taskID, outcome: .failed(failure))
        } else {
            finish(connectionID: connectionID, taskID: taskID, outcome: .disconnected)
        }
    }

    // MARK: Lifecycle

    private func cancelConnect() {
        guard terminalOutcome == nil, state == .connecting else { return }
        finish(connectionID: connectionID, taskID: task?.identity, outcome: .failed(.connectionCancelled))
    }

    private func streamCancelled() {
        guard terminalOutcome == nil else { return }
        if state == .connected || state == .connecting {
            Task { [weak self] in
                await self?.disconnect()
            }
        }
    }

    private func closeTimedOut(connectionID: UUID, taskID: UInt64) {
        guard connectionID == self.connectionID, terminalOutcome == nil, task?.identity == taskID else { return }
        task?.cancel()
        finish(connectionID: connectionID, taskID: taskID, outcome: .disconnected)
    }

    private func finish(connectionID: UUID, taskID: UInt64?, outcome: TerminalOutcome) {
        guard connectionID == self.connectionID, terminalOutcome == nil else { return }
        if let taskID, let liveTask = task, liveTask.identity != taskID { return }

        terminalOutcome = outcome
        switch outcome {
        case .disconnected:
            state = .disconnected
        case let .failed(error):
            state = .failed(error)
        }

        let handshake = handshakeContinuation
        handshakeContinuation = nil
        switch outcome {
        case .disconnected:
            handshake?.resume(throwing: WebSocketClientError.connectionClosedBeforeHandshake)
        case let .failed(error):
            handshake?.resume(throwing: error)
        }

        switch outcome {
        case .disconnected:
            streamContinuation?.finish()
        case let .failed(error):
            streamContinuation?.finish(throwing: error)
        }
        streamContinuation = nil

        let sendError: WebSocketClientError
        switch outcome {
        case .disconnected: sendError = .disconnected
        case let .failed(error): sendError = error
        }
        activeSend?.continuation?.resume(throwing: sendError)
        activeSend?.continuation = nil
        for var pending in sendQueue {
            pending.continuation?.resume(throwing: sendError)
            pending.continuation = nil
        }
        sendQueue.removeAll()

        receiveTask?.cancel()
        receiveTask = nil
        closeTimeoutTask?.cancel()
        closeTimeoutTask = nil

        task?.cancel()
        task = nil
        session?.invalidateAndCancel()
        session = nil
        delegateBridge?.clearConnection()
        delegateBridge = nil

        let waiters = disconnectWaiters
        disconnectWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    private func startReceiveLoop() {
        guard receiveTask == nil, let task else { return }
        let connectionID = self.connectionID
        let taskID = task.identity
        receiveTask = Task { [weak self] in
            await self?.receiveMessages(connectionID: connectionID, taskID: taskID)
        }
    }

    private func receiveMessages(connectionID: UUID, taskID: UInt64) async {
        while terminalOutcome == nil, let task, task.identity == taskID {
            do {
                let message = try await task.receive()
                didReceive(message, connectionID: connectionID, taskID: taskID)
            } catch {
                didReceiveError(connectionID: connectionID, taskID: taskID)
                return
            }
        }
    }

    private func didReceive(_ message: WebSocketTaskMessage, connectionID: UUID, taskID: UInt64) {
        guard connectionID == self.connectionID, task?.identity == taskID, terminalOutcome == nil, state == .connected, let continuation = streamContinuation else { return }
        let result = continuation.yield(WebSocketMessage(message))
        if case .dropped = result {
            finish(connectionID: connectionID, taskID: taskID, outcome: .failed(.receiveBufferOverflow))
        }
    }

    private func didReceiveError(connectionID: UUID, taskID: UInt64) {
        guard connectionID == self.connectionID, task?.identity == taskID, terminalOutcome == nil else { return }
        if state == .disconnecting {
            finish(connectionID: connectionID, taskID: taskID, outcome: .disconnected)
        } else {
            finish(connectionID: connectionID, taskID: taskID, outcome: .failed(.receiveFailed))
        }
    }

    // MARK: Send queue

    private func startNextSendIfNeeded() {
        guard activeSend == nil, terminalOutcome == nil, state == .connected, let task, !sendQueue.isEmpty else { return }
        activeSend = sendQueue.removeFirst()
        let requestID = activeSend?.id ?? 0
        let message = activeSend?.message ?? .binary(Data())
        Task { [weak self] in
            do {
                try await task.send(message)
                await self?.finishSend(requestID: requestID, error: nil)
            } catch {
                await self?.finishSend(requestID: requestID, error: error)
            }
        }
    }

    private func finishSend(requestID: UInt64, error: Error?) {
        guard activeSend?.id == requestID else { return }
        let continuation = activeSend?.continuation
        activeSend = nil

        guard terminalOutcome == nil else { return }
        if let error {
            _ = error
            continuation?.resume(throwing: WebSocketClientError.sendFailed)
            finish(connectionID: connectionID, taskID: task?.identity, outcome: .failed(.sendFailed))
        } else if state == .connected {
            continuation?.resume()
            startNextSendIfNeeded()
        } else {
            continuation?.resume(throwing: WebSocketClientError.disconnected)
        }
    }

    private func cancelSend(requestID: UInt64) {
        if let activeIndex = sendQueue.firstIndex(where: { $0.id == requestID }) {
            let pending = sendQueue.remove(at: activeIndex)
            pending.continuation?.resume(throwing: CancellationError())
            return
        }

        guard activeSend?.id == requestID else { return }
        activeSend?.continuation?.resume(throwing: CancellationError())
        activeSend?.continuation = nil
    }
}

nonisolated private extension WebSocketMessage {
    init(_ message: WebSocketTaskMessage) {
        switch message {
        case let .text(value): self = .text(value)
        case let .binary(value): self = .binary(value)
        }
    }
}
