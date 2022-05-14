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

extension IdentifiedArray: ModelContainer where Element: ViewModel&Identifiable, Element.State: Identifiable, Element.ID == ID, Element.State.ID == ID {
    public typealias StateContainer = IdentifiedArrayOf<Element.State>

    public static func modelContainer(from elements: [Element]) -> Self {
        .init(uniqueElements: elements)
    }

    public var stateContainer: StateContainer {
        StateContainer(uniqueElements: map { $0.value(for: \.self) })
    }
}

public extension StoreViewProvider {
    subscript<Id, Element>(dynamicMember keyPath: WritableKeyPath<State, IdentifiedArray<Id, Element>>) -> [StoreView<Root, Element>] {
        containerView(for: keyPath).value(for: \.self, isSame: IdentifiedArray<Id, Element>.hasSameStructure).ids.compactMap { id in
            storeView(for: keyPath.appending(path: \IdentifiedArray<Id, Element>[id: id]))
        }
    }

    subscript<Element: Identifiable>(dynamicMember keyPath: WritableKeyPath<State, IdentifiedArray<Element.ID, Element>>) -> IdentifiedArray<Element.ID, StoreView<Root, Element>> {
        IdentifiedArray(uniqueElements: containerStoreViewElements(for: keyPath))
    }
}

public extension IdentifiedArray {
    func map<VM: ViewModel, Root, State>(_ transform: (Element) -> VM) -> IdentifiedArray<VM.State.ID, VM> where Element == StoreView<Root, State>, VM.State == State, VM.State: Identifiable {
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
