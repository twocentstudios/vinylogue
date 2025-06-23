import Foundation

// https://sideeffect.io/posts/2021-12-10-equatableerror/
struct EquatableError: Error, Equatable, CustomStringConvertible, Sendable {
    let base: Error
    private let equals: @Sendable (Error) -> Bool

    init(_ base: some Error) {
        self.base = base
        equals = { String(reflecting: $0) == String(reflecting: base) }
    }

    init<Base: Error & Equatable>(_ base: Base) {
        self.base = base
        equals = { ($0 as? Base) == base }
    }

    static func == (lhs: EquatableError, rhs: EquatableError) -> Bool {
        lhs.equals(rhs.base)
    }

    var description: String {
        "\(base)"
    }

    func asError<Base: Error>(type: Base.Type) -> Base? {
        base as? Base
    }

    var localizedDescription: String {
        base.localizedDescription
    }
}

extension Error where Self: Equatable {
    func toEquatableError() -> EquatableError {
        EquatableError(self)
    }
}

extension Error {
    func toEquatableError() -> EquatableError {
        EquatableError(self)
    }
}
