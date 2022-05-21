import OneState
import CasePaths
import SwiftUI

public extension StoreViewProvider where State: Equatable, Access == Write {
    func `case`<Case>(_ casePath: CasePath<State, Case>) -> StoreView<Root, Case, Write>? {
        storeView(for: \State[case: CaseIndex(casePath: casePath)])
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
}

public extension Binding {
    func `case`<Case>(_ casePath: CasePath<Value, Case>, clearValue: Value) -> Binding<Case?> {
        .init(
            get: { casePath.extract(from: self.wrappedValue) },
            set: { newValue, transaction in
                self.transaction(transaction).wrappedValue = newValue.map(casePath.embed) ?? clearValue
            }
        )
    }
    
    func `case`<Enum, Case>(_ casePath: CasePath<Enum, Case>) -> Binding<Case?> where Value == Enum? {
        .init(
            get: { self.wrappedValue.flatMap(casePath.extract(from:)) },
            set: { newValue, transaction in
                self.transaction(transaction).wrappedValue = newValue.map(casePath.embed)
            }
        )
    }
}

struct CaseIndex<Enum, Case>: Hashable {
    var casePath: CasePath<Enum, Case>
    var clearValue: Enum?

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
