import OneState
import CasePaths
import SwiftUI

public extension StoreViewProvider where State: Equatable, Access == Write {
    func `case`<Case>(_ casePath: CasePath<State, Case>) -> StoreView<Root, Case, Write>? {
        storeView(for: \State[case: CaseIndex(casePath: casePath)])
    }

    func `case`<M: Model>(_ casePath: CasePath<State, M.State>) -> M? {
        M?(storeView(for: \State[case: CaseIndex(casePath: casePath)]))
    }

    func `case`<Value, Case>(_ casePath: CasePath<Value, Case>, clearValue: Value) -> Binding<StoreView<Root, Case, Write>?> where State == Writable<Value>, Value: Equatable, Case: Equatable {
        self[dynamicMember: \State[case: CaseIndex(casePath: casePath, clearValue: clearValue)]]
    }

    func `case`<Value, Case>(_ casePath: CasePath<Value, Case>) -> Binding<StoreView<Root, Case, Write>?> where State == Writable<Value?>, Value: Equatable, Case: Equatable {
        .init {
            storeView(for: \Writable<Value?>.wrappedValue[case: CaseIndex(casePath: casePath)])
        } set: { newValue in
            self.setValue(newValue.map {
                casePath.embed($0.value(for: \.self))
            }, at: \.self)
        }
    }

    func `case`<M: Model>(_ casePath: CasePath<State, StateModel<M>>) -> M? where M.StateContainer == M.State {
        M?(storeView[case: CaseIndex(casePath: casePath)].wrappedValue)
    }

    func `case`<C: ModelContainer>(_ casePath: CasePath<State, StateModel<C>>) -> C? where C.StateContainer: OneState.StateContainer, C.StateContainer.Element == C.ModelElement.State {
        guard let view = storeView[case: CaseIndex(casePath: casePath)] else { return nil }
        return C(view)
    }

    func `case`<Value, M: Model>(_ casePath: CasePath<Value, StateModel<M>>, clearValue: Value) -> Binding<M?> where State == Writable<Value>, M.State == M.StateContainer {
        Binding<M?> {
            guard let view = storeView.wrappedValue[case: CaseIndex(casePath: casePath)]?.wrappedValue else { return nil }
            return M(view)
        } set: { newValue in
            setValue(newValue.map {
                casePath.embed(StateModel($0.nonObservableState))
            } ?? clearValue, at: \.self)
        }
    }

    func `case`<Value, M: Model>(_ casePath: CasePath<Value, StateModel<M>>) -> Binding<M?> where State == Writable<Value?>, M.State == M.StateContainer {
        Binding<M?> {
            guard let view = storeView.wrappedValue[case: CaseIndex(casePath: casePath)]?.wrappedValue else { return nil }
            return M(view)
        } set: { newValue in
            setValue(newValue.map {
                casePath.embed(StateModel($0.nonObservableState))
            }, at: \.self)
        }
    }
}

public extension Optional {
  func `case`<Case>(_ casePath: CasePath<Wrapped, Case>) -> Case? {
    flatMap(casePath.extract(from:))
  }
}

final class CaseIndex<Enum, Case>: Hashable, @unchecked Sendable {
    let casePath: CasePath<Enum, Case>
    var clearValue: Enum?

    init(casePath: CasePath<Enum, Case>, clearValue: Enum? = nil) {
        self.casePath = casePath
        self.clearValue = clearValue
    }
    
    static func == (lhs: CaseIndex, rhs: CaseIndex) -> Bool {
        return true
    }
    
    func hash(into hasher: inout Hasher) { }
}

extension Writable {
    subscript<Case> (case casePath: CaseIndex<Value, Case>) -> Writable<Case?> {
        get {
            Writable<Case?>(wrappedValue: casePath.casePath.extract(from: self.wrappedValue))
        }
        set {
            guard let newValue = newValue.wrappedValue.map({
                Writable(wrappedValue: casePath.casePath.embed($0))
            }) ?? casePath.clearValue.map(Writable.init(wrappedValue:)) else { return }
            self = newValue
        }
    }
}

extension Optional {
    subscript<Case> (case casePath: CaseIndex<Wrapped, Case>) -> Case? {
        get {
            flatMap { casePath.casePath.extract(from: $0) }
        }
        set {
            guard let newValue = newValue.map({
                casePath.casePath.embed($0)
            }) ?? casePath.clearValue else { return }
            self = newValue
        }
    }
}

extension Equatable {
    subscript<Case> (case casePath: CaseIndex<Self, Case>) -> Case? {
        get {
            casePath.casePath.extract(from: self)
        }
        set {
            guard let value = newValue else { return }
            self = casePath.casePath.embed(value)
        }
    }
}
