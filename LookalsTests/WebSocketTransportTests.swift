import Foundation
import XCTest
@testable import Lookals

nonisolated final class WebSocketTransportTests: XCTestCase {
    func testConnectWaitsForMatchingOpenAndPreservesFrames() async throws {
        let harness = makeHarness()
        let start = beginStart(harness)
        await harness.session.waitUntilTaskCreated()
        XCTAssertFalse(start.isCancelled)

        await harness.connection.didOpen(connectionID: harness.connection.connectionID, taskID: harness.task.identity)
        try await start.value

        let stream = try await harness.connection.messages()
        let messageTask = Task { () -> [WebSocketMessage] in
            var values: [WebSocketMessage] = []
            for try await value in stream {
                values.append(value)
                if values.count == 2 { break }
            }
            return values
        }

        harness.task.enqueue(.text("hello"))
        harness.task.enqueue(.binary(Data([1, 2, 3])))
        let received = try await messageTask.value
        XCTAssertEqual(received, [.text("hello"), .binary(Data([1, 2, 3]))])
        await harness.connection.disconnect(code: .normal, reason: nil)
    }

    func testConnectCancellationTearsDownHandshake() async {
        let harness = makeHarness()
        let start = beginStart(harness)
        await harness.session.waitUntilTaskCreated()

        start.cancel()
        do {
            try await start.value
            XCTFail("Expected connect cancellation")
        } catch let error as WebSocketClientError {
            XCTAssertEqual(error, .connectionCancelled)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        XCTAssertGreaterThanOrEqual(harness.task.cancelCountSnapshot(), 1)
        XCTAssertEqual(harness.session.invalidationCountSnapshot(), 1)
    }

    func testHandshakeErrorWhileConnectingMapsToHandshakeFailed() async {
        let harness = makeHarness()
        let start = beginStart(harness)
        await harness.session.waitUntilTaskCreated()
        await harness.connection.didComplete(
            connectionID: harness.connection.connectionID,
            taskID: harness.task.identity,
            error: TestError.failed
        )

        do {
            try await start.value
            XCTFail("Expected handshake failure")
        } catch let error as WebSocketClientError {
            XCTAssertEqual(error, .handshakeFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        await assertState(.failed(.handshakeFailed), for: harness.connection)
    }

    func testDisconnectWhileConnectingCompletesOnTaskCompletion() async throws {
        let harness = makeHarness()
        let start = beginStart(harness)
        await harness.session.waitUntilTaskCreated()

        let disconnect = Task { await harness.connection.disconnect(code: .normal, reason: nil) }
        await harness.task.waitUntilCancelCalled()
        await harness.connection.didComplete(
            connectionID: harness.connection.connectionID,
            taskID: harness.task.identity,
            error: nil
        )
        await disconnect.value

        do {
            try await start.value
            XCTFail("Expected the connecting handshake to be terminated")
        } catch let error as WebSocketClientError {
            XCTAssertEqual(error, .connectionClosedBeforeHandshake)
        }
        await assertState(.disconnected, for: harness.connection)
    }

    func testCompletionFirstExplicitDisconnectIsIntentional() async throws {
        let harness = try await connectedHarness()
        let disconnect = Task { await harness.connection.disconnect(code: .normal, reason: nil) }
        await harness.task.waitUntilCancelCalled()
        await harness.connection.didComplete(
            connectionID: harness.connection.connectionID,
            taskID: harness.task.identity,
            error: TestError.failed
        )
        await disconnect.value

        await assertState(.disconnected, for: harness.connection)
        XCTAssertEqual(harness.session.invalidationCountSnapshot(), 1)
    }

    func testConnectedDisconnectResolvesOnMatchingPeerClose() async throws {
        let timeout = TestTimeoutSleeper()
        let harness = try await connectedHarness(timeout: timeout)
        let disconnect = Task { await harness.connection.disconnect(code: .normal, reason: nil) }
        await timeout.waitUntilSleeping()
        await harness.connection.didClose(
            connectionID: harness.connection.connectionID,
            taskID: harness.task.identity,
            code: .normal,
            reason: nil
        )
        await disconnect.value

        await assertState(.disconnected, for: harness.connection)
        XCTAssertEqual(harness.session.invalidationCountSnapshot(), 1)
    }

    func testPeerCloseMappingNormalGoingAwayAndAbnormal() async throws {
        for code in [WebSocketCloseCode.normal, .goingAway] {
            let harness = try await connectedHarness()
            await harness.connection.didClose(
                connectionID: harness.connection.connectionID,
                taskID: harness.task.identity,
                code: code,
                reason: nil
            )
            await assertState(.disconnected, for: harness.connection)
        }

        let abnormal = try await connectedHarness()
        await abnormal.connection.didClose(
            connectionID: abnormal.connection.connectionID,
            taskID: abnormal.task.identity,
            code: .protocolError,
            reason: nil
        )
        await assertState(.failed(.peerClosed(code: .protocolError)), for: abnormal.connection)
    }

    func testCompletionMappingNilErrorAndError() async throws {
        let nilCompletion = try await connectedHarness()
        await nilCompletion.connection.didComplete(
            connectionID: nilCompletion.connection.connectionID,
            taskID: nilCompletion.task.identity,
            error: nil
        )
        await assertState(.disconnected, for: nilCompletion.connection)

        let errorCompletion = try await connectedHarness()
        await errorCompletion.connection.didComplete(
            connectionID: errorCompletion.connection.connectionID,
            taskID: errorCompletion.task.identity,
            error: TestError.failed
        )
        await assertState(.failed(.taskFailed), for: errorCompletion.connection)
    }

    func testReceiveFailureFinishesStreamWithStableError() async throws {
        let harness = try await connectedHarness()
        let stream = try await harness.connection.messages()
        let next = Task { () -> Result<WebSocketMessage?, Error> in
            do {
                var iterator = stream.makeAsyncIterator()
                return .success(try await iterator.next())
            } catch {
                return .failure(error)
            }
        }
        await harness.task.waitUntilReceiveCalled()
        harness.task.failNextReceive(TestError.failed)

        guard case let .failure(error) = await next.value else {
            return XCTFail("Expected receive failure")
        }
        XCTAssertEqual(error as? WebSocketClientError, .receiveFailed)
        await assertState(.failed(.receiveFailed), for: harness.connection)
    }

    func testSendFailureTerminatesConnection() async throws {
        let harness = try await connectedHarness()
        harness.task.setNextSendFailure(TestError.failed)

        do {
            try await harness.connection.send(.text("send"))
            XCTFail("Expected send failure")
        } catch let error as WebSocketClientError {
            XCTAssertEqual(error, .sendFailed)
        }
        await assertState(.failed(.sendFailed), for: harness.connection)
    }

    func testCompetingTerminalSignalsAndStaleCallbacksAreIgnored() async throws {
        let harness = try await connectedHarness()
        await harness.connection.didClose(
            connectionID: UUID(),
            taskID: harness.task.identity,
            code: .protocolError,
            reason: nil
        )
        await assertState(.connected, for: harness.connection)

        await harness.connection.didClose(
            connectionID: harness.connection.connectionID,
            taskID: harness.task.identity,
            code: .normal,
            reason: nil
        )
        await harness.connection.didComplete(
            connectionID: harness.connection.connectionID,
            taskID: harness.task.identity,
            error: TestError.failed
        )
        await harness.connection.didClose(
            connectionID: harness.connection.connectionID,
            taskID: harness.task.identity + 1,
            code: .protocolError,
            reason: nil
        )
        await assertState(.disconnected, for: harness.connection)
        XCTAssertEqual(harness.session.invalidationCountSnapshot(), 1)
    }

    func testTerminalStreamFinishesExactlyOnce() async throws {
        let harness = try await connectedHarness()
        let stream = try await harness.connection.messages()
        await harness.connection.didClose(
            connectionID: harness.connection.connectionID,
            taskID: harness.task.identity,
            code: .normal,
            reason: nil
        )
        await harness.connection.didComplete(
            connectionID: harness.connection.connectionID,
            taskID: harness.task.identity,
            error: TestError.failed
        )

        var iterator = stream.makeAsyncIterator()
        let firstEnd = try await iterator.next()
        let secondEnd = try await iterator.next()
        XCTAssertNil(firstEnd)
        XCTAssertNil(secondEnd)
        await assertState(.disconnected, for: harness.connection)
    }

    func testSecondMessagesClaimIsRejectedByConnectionActor() async throws {
        let harness = try await connectedHarness()
        _ = try await harness.connection.messages()
        do {
            _ = try await harness.connection.messages()
            XCTFail("Expected the second messages claim to fail")
        } catch let error as WebSocketClientError {
            XCTAssertEqual(error, .messagesAlreadyClaimed)
        }
    }

    func testConcurrentSendsAreSerialAndPreserveActorEntryOrder() async throws {
        let harness = try await connectedHarness()
        harness.task.setAutomaticSendCompletion(false)

        let first = Task { try await harness.connection.send(.text("first")) }
        await harness.task.waitUntilSendCallCount(1)
        let second = Task { try await harness.connection.send(.text("second")) }
        XCTAssertEqual(harness.task.sentMessagesSnapshot(), [.text("first")])

        harness.task.completeNextSend()
        await harness.task.waitUntilSendCallCount(2)
        XCTAssertEqual(harness.task.sentMessagesSnapshot(), [.text("first"), .text("second")])
        harness.task.completeNextSend()
        try await first.value
        try await second.value
    }

    func testSendCompletionBeforeContinuationRegistrationIsDurable() async throws {
        let task = TestWebSocketTask(identity: 1)
        task.setAutomaticSendCompletion(false)
        task.completeNextSend()

        try await task.send(.text("completed-before-registration"))
        XCTAssertEqual(task.sentMessagesSnapshot(), [.text("completed-before-registration")])
    }

    func testQueuedSendsAreSuppressedAfterTerminalState() async throws {
        let harness = try await connectedHarness()
        harness.task.setAutomaticSendCompletion(false)
        let first = Task { try await harness.connection.send(.text("first")) }
        await harness.task.waitUntilSendCallCount(1)
        let second = Task { try await harness.connection.send(.text("second")) }

        await harness.connection.didClose(
            connectionID: harness.connection.connectionID,
            taskID: harness.task.identity,
            code: .normal,
            reason: nil
        )
        XCTAssertEqual(harness.task.sentMessagesSnapshot(), [.text("first")])
        do { try await first.value; XCTFail("Expected first send to fail") } catch {}
        do { try await second.value; XCTFail("Expected queued send to fail") } catch {}
    }

    func testSixtyFifthUnconsumedFrameFailsWithOverflow() async throws {
        let harness = try await connectedHarness()
        let stream = try await harness.connection.messages()
        for index in 0..<65 {
            harness.task.enqueue(.text(String(index)))
        }
        await harness.task.waitUntilReceiveCount(65)

        var iterator = stream.makeAsyncIterator()
        for _ in 0..<64 {
            _ = try await iterator.next()
        }
        do {
            _ = try await iterator.next()
            XCTFail("Expected receive buffer overflow")
        } catch let error as WebSocketClientError {
            XCTAssertEqual(error, .receiveBufferOverflow)
        }
        await assertState(.failed(.receiveBufferOverflow), for: harness.connection)
    }

    func testIteratorCancellationCleansUpNativeResources() async throws {
        let harness = try await connectedHarness()
        let stream = try await harness.connection.messages()
        let pendingNext = Task { () -> Result<WebSocketMessage?, Error> in
            do {
                var iterator = stream.makeAsyncIterator()
                return .success(try await iterator.next())
            } catch {
                return .failure(error)
            }
        }
        await harness.task.waitUntilReceiveCalled()
        pendingNext.cancel()
        _ = await pendingNext.value
        await harness.session.waitUntilInvalidated()

        XCTAssertEqual(harness.session.invalidationCountSnapshot(), 1)
        XCTAssertGreaterThanOrEqual(harness.task.cancelCountSnapshot(), 1)
    }

    func testNormalEarlyBreakRequiresExplicitDisconnect() async throws {
        let harness = try await connectedHarness()
        let stream = try await harness.connection.messages()
        let consumer = Task {
            var iterator = stream.makeAsyncIterator()
            harness.task.enqueue(.text("one"))
            _ = try? await iterator.next()
        }
        await consumer.value
        XCTAssertEqual(harness.session.invalidationCountSnapshot(), 0)

        await harness.connection.disconnect(code: .normal, reason: nil)
        XCTAssertEqual(harness.session.invalidationCountSnapshot(), 1)
    }

    func testTimeoutFallbackCancelsNativeTaskAndInvalidatesSession() async throws {
        let timeout = TestTimeoutSleeper()
        let harness = try await connectedHarness(timeout: timeout)
        let disconnect = Task { await harness.connection.disconnect(code: .normal, reason: nil) }
        await timeout.waitUntilSleeping()
        timeout.fire()
        await disconnect.value

        XCTAssertGreaterThanOrEqual(harness.task.cancelCountSnapshot(), 2)
        XCTAssertEqual(harness.session.invalidationCountSnapshot(), 1)
    }

    func testTimeoutCancellationBeforeContinuationRegistrationIsDurable() async {
        let timeout = TestTimeoutSleeper()
        timeout.cancelForTesting()
        let sleep = Task { await timeout.sleep(for: .seconds(5)) }
        await sleep.value
        XCTAssertTrue(timeout.wakeupWasRequestedSnapshot())
    }

    func testDelegateLateCallbackAfterTeardownUsesSafeWeakSnapshot() async throws {
        let harness = try await connectedHarness()
        let bridge = WebSocketSessionDelegateBridge(
            connection: harness.connection,
            connectionID: harness.connection.connectionID
        )
        XCTAssertNotNil(bridge.connectionSnapshotForTesting())
        bridge.clearConnection()
        XCTAssertNil(bridge.connectionSnapshotForTesting())

        let session = URLSession(configuration: .ephemeral)
        let nativeTask = session.webSocketTask(with: URL(string: "wss://example.test/socket")!)
        bridge.urlSession(session, webSocketTask: nativeTask, didOpenWithProtocol: nil)
        bridge.urlSession(session, webSocketTask: nativeTask, didCloseWith: .normalClosure, reason: nil)
        bridge.urlSession(session, task: nativeTask, didCompleteWithError: nil)
        session.invalidateAndCancel()
        await assertState(.connected, for: harness.connection)
    }

    private func makeHarness(timeout: TestTimeoutSleeper = TestTimeoutSleeper()) -> ConnectionHarness {
        let task = TestWebSocketTask(identity: 1)
        let session = TestWebSocketSession(task: task)
        let factory = TestSessionFactory(session: session)
        let connection = URLSessionWebSocketConnection(
            endpoint: URL(string: "wss://example.test/socket")!,
            factory: factory,
            timeoutSleeper: timeout
        )
        return ConnectionHarness(connection: connection, task: task, session: session, timeout: timeout)
    }

    private func connectedHarness(timeout: TestTimeoutSleeper = TestTimeoutSleeper()) async throws -> ConnectionHarness {
        let harness = makeHarness(timeout: timeout)
        let start = beginStart(harness)
        await harness.session.waitUntilTaskCreated()
        await harness.connection.didOpen(connectionID: harness.connection.connectionID, taskID: harness.task.identity)
        try await start.value
        return harness
    }

    private func beginStart(_ harness: ConnectionHarness) -> Task<Void, Error> {
        Task { try await harness.connection.start() }
    }

    private func assertState(_ expected: WebSocketConnectionState, for connection: URLSessionWebSocketConnection) async {
        let state = await connection.currentState()
        XCTAssertEqual(state, expected)
    }
}

nonisolated private final class ConnectionHarness: @unchecked Sendable {
    let connection: URLSessionWebSocketConnection
    let task: TestWebSocketTask
    let session: TestWebSocketSession
    let timeout: TestTimeoutSleeper

    init(connection: URLSessionWebSocketConnection, task: TestWebSocketTask, session: TestWebSocketSession, timeout: TestTimeoutSleeper) {
        self.connection = connection
        self.task = task
        self.session = session
        self.timeout = timeout
    }
}

private enum TestError: Error {
    case failed
}

private final class TestSessionFactory: WebSocketSessionFactory, @unchecked Sendable {
    private let session: TestWebSocketSession

    init(session: TestWebSocketSession) {
        self.session = session
    }

    func makeSession(delegate: WebSocketSessionDelegateBridge) -> any WebSocketSession {
        session.setDelegate(delegate)
        return session
    }
}

private final class TestWebSocketSession: WebSocketSession, @unchecked Sendable {
    private let lock = NSLock()
    private let task: TestWebSocketTask
    private weak var delegate: WebSocketSessionDelegateBridge?
    private var taskRequested = false
    private var taskRequestWaiters: [CheckedContinuation<Void, Never>] = []
    private var invalidationCount = 0
    private var invalidationWaiters: [CheckedContinuation<Void, Never>] = []

    init(task: TestWebSocketTask) {
        self.task = task
    }

    func setDelegate(_ delegate: WebSocketSessionDelegateBridge) {
        lock.withLock { self.delegate = delegate }
    }

    func makeWebSocketTask(url: URL) -> any WebSocketTask {
        let waiters = lock.withLock { () -> [CheckedContinuation<Void, Never>] in
            taskRequested = true
            let result = taskRequestWaiters
            taskRequestWaiters.removeAll()
            return result
        }
        waiters.forEach { $0.resume() }
        return task
    }

    func invalidateAndCancel() {
        let waiters = lock.withLock { () -> [CheckedContinuation<Void, Never>] in
            invalidationCount += 1
            let result = invalidationWaiters
            invalidationWaiters.removeAll()
            return result
        }
        waiters.forEach { $0.resume() }
        task.cancel()
    }

    func waitUntilTaskCreated() async {
        await withCheckedContinuation { continuation in
            let resumeImmediately = lock.withLock {
                if taskRequested { return true }
                taskRequestWaiters.append(continuation)
                return false
            }
            if resumeImmediately { continuation.resume() }
        }
    }

    func waitUntilInvalidated() async {
        await withCheckedContinuation { continuation in
            let resumeImmediately = lock.withLock {
                if invalidationCount > 0 { return true }
                invalidationWaiters.append(continuation)
                return false
            }
            if resumeImmediately { continuation.resume() }
        }
    }

    func invalidationCountSnapshot() -> Int {
        lock.withLock { invalidationCount }
    }
}

private final class TestWebSocketTask: WebSocketTask, @unchecked Sendable {
    let identity: UInt64
    private let lock = NSLock()
    private var receiveContinuations: [CheckedContinuation<WebSocketTaskMessage, Error>] = []
    private var queuedMessages: [WebSocketTaskMessage] = []
    private var nextReceiveError: Error?
    private var receiveCallCount = 0
    private var receiveWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var sendWaiters: [Int: CheckedContinuation<Void, Error>] = [:]
    private var pendingSendCalls: Set<Int> = []
    private var completedSendCalls: Set<Int> = []
    private var sendCompletionCredits = 0
    private var sendCallCount = 0
    private var sendCallWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var sentMessages: [WebSocketTaskMessage] = []
    private var automaticSendCompletion = true
    private var nextSendError: Error?
    private var cancelCount = 0
    private var cancelWaiters: [CheckedContinuation<Void, Never>] = []

    init(identity: UInt64) {
        self.identity = identity
    }

    func resume() {}

    func send(_ message: WebSocketTaskMessage) async throws {
        let outcome = lock.withLock { () -> (Int, Error?, Bool) in
            sendCallCount += 1
            let call = sendCallCount
            sentMessages.append(message)
            let error = nextSendError
            nextSendError = nil
            if error != nil {
                return (call, error, true)
            }
            if !automaticSendCompletion {
                if sendCompletionCredits > 0 {
                    sendCompletionCredits -= 1
                    return (call, error, true)
                }
                pendingSendCalls.insert(call)
            }
            return (call, error, automaticSendCompletion)
        }
        notifySendCallWaiters()
        if let error = outcome.1 { throw error }
        if outcome.2 { return }

        try await withCheckedThrowingContinuation { continuation in
            let completeImmediately = lock.withLock {
                if completedSendCalls.remove(outcome.0) != nil {
                    pendingSendCalls.remove(outcome.0)
                    return true
                }
                sendWaiters[outcome.0] = continuation
                return false
            }
            if completeImmediately { continuation.resume() }
        }
    }

    func receive() async throws -> WebSocketTaskMessage {
        try await withCheckedThrowingContinuation { continuation in
            var immediateMessage: WebSocketTaskMessage?
            var immediateError: Error?
            let waiters = lock.withLock { () -> [CheckedContinuation<Void, Never>] in
                receiveCallCount += 1
                let currentCall = receiveCallCount
                let result = receiveWaiters.filter { $0.0 <= currentCall }.map(\.1)
                receiveWaiters.removeAll { $0.0 <= currentCall }
                if !queuedMessages.isEmpty {
                    immediateMessage = queuedMessages.removeFirst()
                } else if let error = nextReceiveError {
                    immediateError = error
                    nextReceiveError = nil
                } else {
                    receiveContinuations.append(continuation)
                }
                return result
            }
            waiters.forEach { $0.resume() }
            if let immediateMessage { continuation.resume(returning: immediateMessage) }
            if let immediateError { continuation.resume(throwing: immediateError) }
            notifyReceiveWaiters()
        }
    }

    func cancel(with code: WebSocketCloseCode, reason: Data?) {
        cancel()
    }

    func cancel() {
        let continuations = lock.withLock { () -> ([CheckedContinuation<WebSocketTaskMessage, Error>], [CheckedContinuation<Void, Error>], [CheckedContinuation<Void, Never>]) in
            cancelCount += 1
            let receive = receiveContinuations
            receiveContinuations.removeAll()
            let sends = Array(sendWaiters.values)
            sendWaiters.removeAll()
            let cancels = cancelWaiters
            cancelWaiters.removeAll()
            return (receive, sends, cancels)
        }
        continuations.0.forEach { $0.resume(throwing: CancellationError()) }
        continuations.1.forEach { $0.resume(throwing: CancellationError()) }
        continuations.2.forEach { $0.resume() }
    }

    func enqueue(_ message: WebSocketTaskMessage) {
        let continuation = lock.withLock { () -> CheckedContinuation<WebSocketTaskMessage, Error>? in
            guard !receiveContinuations.isEmpty else {
                queuedMessages.append(message)
                return nil
            }
            return receiveContinuations.removeFirst()
        }
        continuation?.resume(returning: message)
    }

    func failNextReceive(_ error: Error) {
        let continuation = lock.withLock { () -> CheckedContinuation<WebSocketTaskMessage, Error>? in
            guard !receiveContinuations.isEmpty else {
                nextReceiveError = error
                return nil
            }
            return receiveContinuations.removeFirst()
        }
        continuation?.resume(throwing: error)
    }

    func setAutomaticSendCompletion(_ value: Bool) {
        lock.withLock { automaticSendCompletion = value }
    }

    func setNextSendFailure(_ error: Error) {
        lock.withLock { nextSendError = error }
    }

    func completeNextSend() {
        let continuation = lock.withLock { () -> CheckedContinuation<Void, Error>? in
            if let key = pendingSendCalls.sorted().first {
                pendingSendCalls.remove(key)
                if let continuation = sendWaiters.removeValue(forKey: key) {
                    return continuation
                }
                completedSendCalls.insert(key)
                return nil
            }
            sendCompletionCredits += 1
            return nil
        }
        continuation?.resume()
    }

    func waitUntilSendCallCount(_ expected: Int) async {
        await withCheckedContinuation { continuation in
            let resumeImmediately = lock.withLock {
                if sendCallCount >= expected { return true }
                sendCallWaiters.append((expected, continuation))
                return false
            }
            if resumeImmediately { continuation.resume() }
        }
    }

    func waitUntilReceiveCalled() async {
        await waitUntilReceiveCount(1)
    }

    func waitUntilReceiveCount(_ expected: Int) async {
        await withCheckedContinuation { continuation in
            let resumeImmediately = lock.withLock {
                if receiveCallCount >= expected { return true }
                receiveWaiters.append((expected, continuation))
                return false
            }
            if resumeImmediately { continuation.resume() }
        }
    }

    func waitUntilCancelCalled() async {
        await withCheckedContinuation { continuation in
            let resumeImmediately = lock.withLock {
                if cancelCount > 0 { return true }
                cancelWaiters.append(continuation)
                return false
            }
            if resumeImmediately { continuation.resume() }
        }
    }

    func cancelCountSnapshot() -> Int {
        lock.withLock { cancelCount }
    }

    func sentMessagesSnapshot() -> [WebSocketTaskMessage] {
        lock.withLock { sentMessages }
    }

    private func notifySendCallWaiters() {
        let waiters = lock.withLock { () -> [CheckedContinuation<Void, Never>] in
            let result = sendCallWaiters.filter { $0.0 <= sendCallCount }.map(\.1)
            sendCallWaiters.removeAll { $0.0 <= sendCallCount }
            return result
        }
        waiters.forEach { $0.resume() }
    }

    private func notifyReceiveWaiters() {
        let waiters = lock.withLock { () -> [CheckedContinuation<Void, Never>] in
            let result = receiveWaiters.filter { $0.0 <= receiveCallCount }.map(\.1)
            receiveWaiters.removeAll { $0.0 <= receiveCallCount }
            return result
        }
        waiters.forEach { $0.resume() }
    }
}

private final class TestTimeoutSleeper: WebSocketTimeoutSleeper, @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Void, Never>?
    private var sleeping = false
    private var wakeupRequested = false
    private var sleepingWaiters: [CheckedContinuation<Void, Never>] = []

    func sleep(for duration: Duration) async {
        await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                let registration = lock.withLock { () -> ([CheckedContinuation<Void, Never>], Bool) in
                    if wakeupRequested {
                        sleeping = false
                        let result = sleepingWaiters
                        sleepingWaiters.removeAll()
                        return (result, true)
                    } else {
                        self.continuation = continuation
                        sleeping = true
                        let result = sleepingWaiters
                        sleepingWaiters.removeAll()
                        return (result, false)
                    }
                }
                registration.0.forEach { $0.resume() }
                if registration.1 { continuation.resume() }
            }
        }, onCancel: {
            finish()
        })
    }

    func waitUntilSleeping() async {
        await withCheckedContinuation { continuation in
            let resumeImmediately = lock.withLock {
                if sleeping { return true }
                sleepingWaiters.append(continuation)
                return false
            }
            if resumeImmediately { continuation.resume() }
        }
    }

    func fire() {
        finish()
    }

    func cancelForTesting() {
        finish()
    }

    func wakeupWasRequestedSnapshot() -> Bool {
        lock.withLock { wakeupRequested }
    }

    private func finish() {
        let continuation = lock.withLock { () -> CheckedContinuation<Void, Never>? in
            wakeupRequested = true
            sleeping = false
            let result = self.continuation
            self.continuation = nil
            return result
        }
        continuation?.resume()
    }
}

nonisolated private extension NSLock {
    func withLock<Result>(_ body: () -> Result) -> Result {
        lock()
        defer { unlock() }
        return body()
    }
}
