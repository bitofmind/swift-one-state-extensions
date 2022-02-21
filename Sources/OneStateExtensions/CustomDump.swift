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

public extension View {
    func printStateUpdates<P: StoreViewProvider>(for provider: P?, name: String = "") -> some View {
        let publisher = provider?.stateDidUpdatePublisher ?? Empty().eraseToAnyPublisher()
        return onReceive(publisher.flatMap { update -> AnyPublisher<StateUpdate<P.Root, P.State>, Never> in
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

