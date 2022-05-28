import OneState
import CustomDump
import SwiftUI
import Combine

public extension StateUpdate {
    var stateDiff: String? {
        diff(previous, current)
    }
    
    func printDiff(){
        guard let diff = stateDiff else {
            print("no updates")
            return
        }
        print(diff)
    }
}

public func stateDiff<Root, State, Access>(_ update: StateUpdate<Root, State, Access>) -> String? {
    update.stateDiff
}

public func printDiff<Root, State, Access>(_ update: StateUpdate<Root, State, Access>) {
    update.printDiff()
}

public extension View {
    func printStateUpdates<P: StoreViewProvider>(for provider: P, name: String = "") -> some View {
        onReceive(provider.stateUpdatePublisher.flatMap { update -> AnyPublisher<StateUpdate<P.Root, P.State, P.Access>, Never> in
            if Thread.isMainThread {
                return Just(update).eraseToAnyPublisher()
            } else {
                return Just(update).receive(on: DispatchQueue.main).eraseToAnyPublisher()
            }
        }) { update in
            guard let diff = update.stateDiff else { return }
            print("State did update\(name.isEmpty ? "" : " for \(name)"):\n" + diff)
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
