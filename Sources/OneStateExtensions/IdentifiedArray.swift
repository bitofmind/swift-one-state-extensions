import OneState
import IdentifiedCollections

public extension StoreViewProvider {
    subscript<Id, Element>(dynamicMember keyPath: WritableKeyPath<State, IdentifiedArray<Id, Element>>) -> [StoreView<Root, Element>] {
        func isSame(lhs: IdentifiedArray<Id, Element>, rhs: IdentifiedArray<Id, Element>) -> Bool {
            lhs.ids == rhs.ids
        }
        
        return value(for: keyPath, isSame: isSame).ids.compactMap { id in
            storeView(for: keyPath.appending(path: \IdentifiedArray<Id, Element>[id: id]))
        }
    }
    
    subscript<Element: Identifiable>(dynamicMember keyPath: WritableKeyPath<State, IdentifiedArray<Element.ID, Element>>) -> IdentifiedArray<Element.ID, StoreView<Root, Element>> {
        func isSame(lhs: IdentifiedArray<Element.ID, Element>, rhs: IdentifiedArray<Element.ID, Element>) -> Bool {
            lhs.ids == rhs.ids
        }

        let array = value(for: keyPath, isSame: isSame)
        let views = array.ids.compactMap { id in
            storeView(for: keyPath.appending(path: \IdentifiedArray<Element.ID, Element>[id: id]))
        }
        let idPath = \StoreView<Root, Element>.id
        return IdentifiedArray(uniqueElements: views, id: idPath)
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
