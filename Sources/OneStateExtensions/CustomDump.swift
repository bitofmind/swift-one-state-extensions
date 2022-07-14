import OneState
import CustomDump
import SwiftUI
import Combine

public extension StateUpdate {
    var stateDiff: String? {
        diff(previous, current)
    }

    func printDiff(name: String = "") {
        guard let diff = stateDiff else { return }
        Swift.print("State did update\(name.isEmpty ? "" : " for \(name)"):\n" + diff)
    }
}

@Sendable public func stateDiff<State>(_ update: StateUpdate<State>) -> String? {
    update.stateDiff
}

@Sendable public func printDiff<State>(_ update: StateUpdate<State>) {
    update.printDiff()
}

public extension View {
    func printStateUpdates<P: StoreViewProvider>(for provider: P, name: String = "") -> some View where P.State: Sendable {
        onReceive(provider.stateUpdatesPublisher.flatMap { update -> AnyPublisher<StateUpdate<P.State>, Never> in
            if Thread.isMainThread {
                return Just(update).eraseToAnyPublisher()
            } else {
                return Just(update).receive(on: DispatchQueue.main).eraseToAnyPublisher()
            }
        }) { update in
            update.printDiff(name: name)
        }
    }
}

extension Writable: CustomDumpRepresentable {
    public var customDumpValue: Any {
        wrappedValue
    }
}

extension StateModel: CustomDumpRepresentable {
    public var customDumpValue: Any {
        wrappedValue
    }
}

public extension StoreViewProvider {
    func printStateUpdates(name: String = "") where State: Sendable {
        Task {
            for await update in stateUpdates {
                update.printDiff(name: name)
            }
        }
    }
}

