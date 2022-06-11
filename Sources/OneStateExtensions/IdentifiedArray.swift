import OneState
import IdentifiedCollections

public extension IdentifiedArray  {
    static func hasSameStructure(lhs: Self, rhs: Self) -> Bool {
        lhs.ids == rhs.ids
    }
}

extension IdentifiedArray: StateContainer where Element: Identifiable, Element.ID == ID  {
    public var elementKeyPaths: [WritableKeyPath<Self, Element>] {
        indices.map { index in
            let state = self[index]
            let cursor = Cursor(id: state[keyPath: \.id], index: index, fallback: state)
            return \.[cursor: cursor]
        }
    }
}

extension IdentifiedArray: ModelContainer where Element: Model&Identifiable, Element.State: Identifiable, Element.ID == ID, Element.State.ID == ID {
    public typealias StateContainer = IdentifiedArrayOf<Element.State>

    public static func modelContainer(from elements: [Element]) -> Self {
        .init(uniqueElements: elements)
    }

    public var stateContainer: StateContainer {
        StateContainer(uniqueElements: map { $0.nonObservableState })
    }
}

public extension StoreViewProvider where Access == Write {
    subscript<Id, Element>(dynamicMember path: WritableKeyPath<State, IdentifiedArray<Id, Element>>) -> [StoreView<Root, Element, Write>] {
        value(for: path, isSame: IdentifiedArray<Id, Element>.hasSameStructure).ids.compactMap { id in
            storeView(for: path.appending(path: \IdentifiedArray<Id, Element>[id: id]))
        }
    }

    subscript<Element: Identifiable>(dynamicMember keyPath: WritableKeyPath<State, IdentifiedArray<Element.ID, Element>>) -> IdentifiedArray<Element.ID, StoreView<Root, Element, Write>> {
        IdentifiedArray(uniqueElements: containerStoreViewElements(for: keyPath))
    }
}

public extension IdentifiedArray {
    func map<M: Model, Root, State, Access>(_ transform: (Element) -> M) -> IdentifiedArray<M.State.ID, M> where Element == StoreView<Root, State, Access>, M.State == State, M.State: Identifiable {
        .init(
            uniqueElements: self.elements.map(transform),
            id: \.id
        )
    }
}

private extension IdentifiedArray {
    subscript(cursor cursor: Cursor<ID, Element>) -> Element {
        get {
            if cursor.index >= startIndex && cursor.index < endIndex {
                let element = self[cursor.index]
                if element[keyPath: id] == cursor.id {
                    return element
                }
            }
               
            return self[id: cursor.id] ?? cursor.fallback
        }
        set {
            cursor.fallback = newValue
            self[id: cursor.id] = newValue
        }
    }
}

// Crash in keypath append if struct
private class Cursor<ID: Hashable, Element>: Hashable {
    var id: ID
    var index: IdentifiedArray<ID, Element>.Index
    var fallback: Element
    
    init(id: ID, index: IdentifiedArray<ID, Element>.Index, fallback: Element) {
        self.id = id
        self.index = index
        self.fallback = fallback
    }
    
    static func == (lhs: Cursor, rhs: Cursor) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
