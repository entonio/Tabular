//
// Copyright © 2024 Antonio Marques. All rights reserved.
//

import Foundation

public struct Slot {
    public let row: Int
    public let col: Int
    public let content: Any
}

extension Slot {
    public var isEmpty: Bool { (content as? String)?.isEmpty == true }
    public var string: String { content as? String ?? "\(content)" }
}

extension Slot {
    var trimmed: String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Slot {
    public func text() throws -> String {
        guard !trimmed.isEmpty else {
            throw NotConvertibleError(string, "non-empty text")
        }
        return string
    }

    public func int(ifEmpty: Int? = nil) throws -> Int {
        if let int = content as? Int {
            return int
        }
        let string = trimmed
        if string.isEmpty, let ifEmpty {
            return ifEmpty
        }
        guard let value = Int(string) else {
            throw NotConvertibleError(string, Int.self)
        }
        return value
    }

    public func double(ifEmpty: Double? = nil) throws -> Double {
        if let double = content as? Double {
            return double
        }
        if let int = content as? Int {
            return Double(int)
        }
        let string = trimmed
        if string.isEmpty, let ifEmpty {
            return ifEmpty
        }
        guard let value = Double(string) else {
            throw NotConvertibleError(string, Double.self)
        }
        return value
    }
}

public struct NotConvertibleError: Error, CustomStringConvertible, CustomDebugStringConvertible {
    private let source: String
    private let target: Any

    public init(_ source: String, _ target: Any) {
        self.source = source
        self.target = target
    }

    public var description: String { "Cannot convert [\(source)] to [\(target)]" }
    public var debugDescription: String { description }
}
