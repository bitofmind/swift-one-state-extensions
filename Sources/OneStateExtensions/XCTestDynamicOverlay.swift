import OneState
import XCTestDynamicOverlay
import CustomDump

@Sendable
public func assertNoFailure<State>(failure: TestFailure<State>) {
    switch failure.kind {
    case let .assertStateMismatch(expected: expected, actual: actual):
        let difference = diff(expected, actual, format: .proportional)
            .map { "\($0.indent(by: 4))\n\n(Expected: −, Actual: +)" }
        ??  """
            Expected:
            \(String(describing: expected).indent(by: 2))
            Actual:
            \(String(describing: actual).indent(by: 2))
            """

        XCTFail(
            """
            State change does not match expectation: …
            \(difference)
            """,
            file: failure.file,
            line: failure.line
        )

    case let .stateNotExhausted(lastAsserted: lastAsserted, actual: actual):
        let difference = diff(lastAsserted, actual, format: .proportional)
            .map { "\($0.indent(by: 4))\n\n(Last asserted: −, Actual: +)" }
        ??  """
            Last asserted:
            \(String(describing: lastAsserted).indent(by: 2))
            Actual:
            \(String(describing: actual).indent(by: 2))
            """

        XCTFail(
            """
            State not exhausted: …
            \(difference)
            """,
            file: failure.file,
            line: failure.line
        )

    default:
        XCTFail(failure.message, file: failure.file, line: failure.line)
    }
}

public extension TestStore {
    convenience init(initialState: State, environments: [Any] = [], file: StaticString = #file, line: UInt = #line) {
        self.init(initialState: initialState, environments: environments, file: file, line: line, onTestFailure: assertNoFailure)
    }

    convenience init<T>(initialState: T, environments: [Any] = [], file: StaticString = #file, line: UInt = #line) where M == EmptyModel<T> {
        self.init(initialState: initialState, environments: environments, file: file, line: line)
    }
}

extension String {
    func indent(by indent: Int) -> String {
        let indentation = String(repeating: " ", count: indent)
        return indentation + self.replacingOccurrences(of: "\n", with: "\n\(indentation)")
    }
}

