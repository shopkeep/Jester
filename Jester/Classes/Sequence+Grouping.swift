import Foundation

public extension Sequence {
    func group<U: Hashable>(by keyFunc: (Iterator.Element) -> U) -> [U:[Iterator.Element]] {
        var dictionary: [U:[Iterator.Element]] = [:]
        for element in self {
            let key = keyFunc(element)
            if case nil = dictionary[key]?.append(element) { dictionary[key] = [element] }
        }
        return dictionary
    }
}
