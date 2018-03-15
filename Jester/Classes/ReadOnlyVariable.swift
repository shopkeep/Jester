import RxSwift

public class ReadOnlyVariable<Element> {

    // MARK: Public properties
    /**
     Gets current value of variable.
     Whenever a new underlying value is set, all the observers are notified of the change.
     Even if the newly set value is same as the old value, observers are still notified for change.
     */
    public var value: Element {
        return readWrite.value
    }

    // MARK: Internal properties
    internal let readWrite: Variable<Element>

    // MARK: Lifecycle
    public init(_ variable: Variable<Element>) {
        self.readWrite = variable
    }

    // MARK: Public methods
    /**
     - returns: Canonical interface for push style sequence
     */
    public func asObservable() -> RxSwift.Observable<Element> {
        return readWrite.asObservable()
    }
}

extension Variable {
    public func readOnly() -> ReadOnlyVariable<Element> {
        return ReadOnlyVariable(self)
    }
}
