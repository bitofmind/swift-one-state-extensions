import OneState
import XCTestDynamicOverlay
import CustomDump

public extension TestStore {
    convenience init(initialState: State, environments: [Any] = []) {
        self.init(initialState: initialState, environments: environments) { failure in
            let difference = diff(failure.expected, failure.actual, format: .proportional)
                .map { "\($0.indent(by: 4))\n\n(Expected: −, Actual: +)" }
            ??  """
                Expected:
                \(String(describing: failure.expected).indent(by: 2))
                Actual:
                \(String(describing: failure.actual).indent(by: 2))
                """
            
            XCTFail(
                """
                State change does not match expectation: …
                \(difference)
                """,
                file: failure.file,
                line: failure.line
            )
        }
    }

    convenience init<T>(initialState: T, environments: [Any] = []) where Model == EmptyModel<T> {
        self.init(initialState: initialState, environments: environments)
    }
}

extension String {
    func indent(by indent: Int) -> String {
        let indentation = String(repeating: " ", count: indent)
        return indentation + self.replacingOccurrences(of: "\n", with: "\n\(indentation)")
    }
}

