import OneState
import IdentifiedCollections

public extension StoreViewProvider {
    subscript<Id, Element>(dynamicMember keyPath: WritableKeyPath<State, IdentifiedArray<Id, Element>>) -> [StoreView<Root, Element>] {
        func isSame(lhs: IdentifiedArray<Id, Element>, rhs: IdentifiedArray<Id, Element>) -> Bool {
            lhs.ids == rhs.ids
        }
        
        return value(for: keyPath, shouldUpdateViewModelAccessToViewAccess: true, isSame: isSame).ids.compactMap { id in
            storeView(for: keyPath.appending(path: \IdentifiedArray<Id, Element>[id: id]))
        }
    }
    
    subscript<Element: Identifiable>(dynamicMember keyPath: WritableKeyPath<State, IdentifiedArray<Element.ID, Element>>) -> IdentifiedArray<Element.ID, StoreView<Root, Element>> {
        func isSame(lhs: IdentifiedArray<Element.ID, Element>, rhs: IdentifiedArray<Element.ID, Element>) -> Bool {
            lhs.ids == rhs.ids
        }
        
        let array = value(for: keyPath, shouldUpdateViewModelAccessToViewAccess: true, isSame: isSame)
        let idPath = \StoreView<Root, Element>.id

        return IdentifiedArray(uniqueElements: array.indices.map { index in
            let element = array[index]
            let path = \IdentifiedArray<Element.ID, Element>[cursor: Cursor(id: element[keyPath: array.id], index: index, fallback: element)]
            return storeView(for: keyPath.appending(path: path))
        }, id: idPath)
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

extension IdentifiedArray {
    fileprivate subscript(cursor cursor: Cursor<ID, Element>) -> Element {
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
            self[id: cursor.id] = newValue
        }
    }
}

private struct Cursor<ID: Hashable, Element>: Hashable {
    var id: ID
    var index: IdentifiedArray<ID, Element>.Index
    var fallback: Element
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
