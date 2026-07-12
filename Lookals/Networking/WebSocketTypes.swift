//
//  WebSocketTypes.swift
//  Lookals
//

import Foundation

nonisolated public enum WebSocketMessage: Sendable, Equatable {
    case text(String)
    case binary(Data)
}

nonisolated public enum WebSocketCloseCode: Sendable, Equatable {
    case normal
    case goingAway
    case protocolError
    case unsupportedData
    case noStatusReceived
    case abnormalClosure
    case invalidFramePayloadData
    case policyViolation
    case messageTooBig
    case mandatoryExtensionMissing
    case internalServerError
    case tlsHandshakeFailure
    case unknown(Int)

    public init(rawValue: Int) {
        switch rawValue {
        case 1000: self = .normal
        case 1001: self = .goingAway
        case 1002: self = .protocolError
        case 1003: self = .unsupportedData
        case 1005: self = .noStatusReceived
        case 1006: self = .abnormalClosure
        case 1007: self = .invalidFramePayloadData
        case 1008: self = .policyViolation
        case 1009: self = .messageTooBig
        case 1010: self = .mandatoryExtensionMissing
        case 1011: self = .internalServerError
        case 1015: self = .tlsHandshakeFailure
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: Int {
        switch self {
        case .normal: 1000
        case .goingAway: 1001
        case .protocolError: 1002
        case .unsupportedData: 1003
        case .noStatusReceived: 1005
        case .abnormalClosure: 1006
        case .invalidFramePayloadData: 1007
        case .policyViolation: 1008
        case .messageTooBig: 1009
        case .mandatoryExtensionMissing: 1010
        case .internalServerError: 1011
        case .tlsHandshakeFailure: 1015
        case let .unknown(rawValue): rawValue
        }
    }

    internal init(_ foundationCode: URLSessionWebSocketTask.CloseCode) {
        self.init(rawValue: foundationCode.rawValue)
    }

    internal var foundationCode: URLSessionWebSocketTask.CloseCode {
        URLSessionWebSocketTask.CloseCode(rawValue: rawValue) ?? .normalClosure
    }
}

nonisolated public enum WebSocketClientError: Error, Sendable, Equatable, CustomStringConvertible {
    case invalidEndpoint
    case handshakeFailed
    case connectionCancelled
    case connectionClosedBeforeHandshake
    case notConnected
    case messagesAlreadyClaimed
    case receiveBufferOverflow
    case peerClosed(code: WebSocketCloseCode)
    case sendFailed
    case receiveFailed
    case taskFailed
    case closeTimedOut
    case disconnected

    public var description: String {
        switch self {
        case .invalidEndpoint: "The WebSocket endpoint must use ws or wss."
        case .handshakeFailed: "The WebSocket handshake failed."
        case .connectionCancelled: "The WebSocket connection was cancelled."
        case .connectionClosedBeforeHandshake: "The WebSocket closed before the handshake completed."
        case .notConnected: "The WebSocket connection is not live."
        case .messagesAlreadyClaimed: "The WebSocket message stream was already claimed."
        case .receiveBufferOverflow: "The WebSocket receive buffer overflowed."
        case let .peerClosed(code): "The peer closed the WebSocket with code \(code.rawValue)."
        case .sendFailed: "The WebSocket send failed."
        case .receiveFailed: "The WebSocket receive failed."
        case .taskFailed: "The WebSocket task failed."
        case .closeTimedOut: "The WebSocket close acknowledgement timed out."
        case .disconnected: "The WebSocket is disconnected."
        }
    }
}

nonisolated public enum WebSocketConnectionState: Sendable, Equatable {
    case connecting
    case connected
    case disconnecting
    case disconnected
    case failed(WebSocketClientError)
}
