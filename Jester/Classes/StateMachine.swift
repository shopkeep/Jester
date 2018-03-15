import Foundation
import RxSwift

public enum StateTransitionResult<State> {
    case Success(old: State, new: State, input: AnyInput)
    case Failure(error: StateTransitionError<State>)
    public var debugDescription: String {
        switch self {
        case .Success(let old, let new, let input):
            return "STATE TRANSITION RESULT:\n    SUCCESS\n    transition: \(old) -> \(new)\n    input: \(input)\n\n"
        case .Failure(let error):
            return "STATE TRANSITION RESULT:\n    FAILURE\n    \(error.debugDescription)"
        }
    }
}

public struct StateTransitionError<State>: Swift.Error, CustomDebugStringConvertible  {
    public let current: State
    public let input: AnyInput
    public let error: MappingError

    public var debugDescription: String {
        return "STATE TRANSITION ERROR:\n    state: \(current)\n    input: \(input)\n    error: \(error)\n\n"
    }
}

public class StateMachine<State> {

    // MARK: Public properties
    public let currentState: ReadOnlyVariable<State>
    public let transitionResult: Observable<StateTransitionResult<State>>

    // MARK: Private properties
    private let mappedStateTransitions: [String: [MappedStateTransition<State>]]
    private let transitionResultSubject: PublishSubject<StateTransitionResult<State>>
    private let lock = NSRecursiveLock()

    // MARK: Object lifecycle
    public convenience init(initialState: State, mappings: [MappedStateTransition<State>]) {
        let stateMapping: [String: [MappedStateTransition<State>]] = mappings.group { $0.erasedTransition.inputId }
        self.init(initialState: initialState, stateMapping: stateMapping)
    }

    public init(initialState: State, stateMapping: [String: [MappedStateTransition<State>]]) {
        self.currentState = Variable(initialState).readOnly()
        self.mappedStateTransitions = stateMapping

        self.transitionResultSubject = PublishSubject()
        self.transitionResult = transitionResultSubject.asObservable()
    }

    // MARK: Public methods
    public func send(_ input: BaseInput<Void>) {
        send(input.inputWithArgument(Void()))
    }

    public func send<T>(_ input: InputWithArgument<T>) {
        lock.lock(); defer { lock.unlock() }

        let currentState = self.currentState.value

        guard let stateTransitionMap = mapping(forId: input.id) else {
            let transitionError = StateTransitionError(current: currentState, input: input, error: .noMapForInput)
            transitionResultSubject.onNext(.Failure(error: transitionError))
            return
        }

        let transition: StateTransition<State> = stateTransitionMap.erasedTransition.stateTransition
        do {
            let effect = try stateTransitionMap.effectWithArguments(input.argument, self)
            self.currentState.readWrite.value = transition.nextState
            transitionResultSubject.onNext(.Success(old: currentState, new: transition.nextState, input: input))
            effect()

        } catch let error {
            let error = error as! MappingError
            let transitionError = StateTransitionError(current: currentState, input: input, error: error)
            transitionResultSubject.onNext(.Failure(error: transitionError))
        }
    }

    public func watcher() -> StateMachineWatcher<State> {
        return StateMachineWatcher<State>(nextStateObservable: currentState.asObservable(),
                                             transitionResultObservable: transitionResult)
    }

    private func mapping(forId id: String) -> MappedStateTransition<State>? {
        guard let maps = mappedStateTransitions[id] else { return nil }
        return maps.filter({ $0.erasedTransition.initialStateMatches(self.currentState.value) }).first
    }
}

public class StateMachineWatcher<T> {
    private var onNext:((T) -> Void)?
    private var onTransitionResult:((StateTransitionResult<T>) -> Void)?

    private var onNextDisposeBag = DisposeBag()
    private var onTransitionResultDisposeBag = DisposeBag()

    private var nextStateObservable: Observable<T>
    private var transitionResultObservable: Observable<StateTransitionResult<T>>

    init(nextStateObservable: Observable<T>,
         transitionResultObservable: Observable<StateTransitionResult<T>>) {
        self.nextStateObservable = nextStateObservable
        self.transitionResultObservable = transitionResultObservable
    }

    public func onNext(_ onNext: ((T) -> Void)?) {
        onNextDisposeBag = DisposeBag()
        self.onNext = onNext

        guard let _ = onNext else { return }

        nextStateObservable
            .subscribe(onNext: { [weak self] (state) in
                self?.onNext?(state)
            }).disposed(by: onNextDisposeBag)
    }

    public func onTransitionResult(_ onTransitionResult:((StateTransitionResult<T>) -> Void)?) {
        onTransitionResultDisposeBag = DisposeBag()
        self.onTransitionResult = onTransitionResult

        guard let _ = onTransitionResult else { return }

        transitionResultObservable
            .subscribe(onNext: { [weak self] result in
                self?.onTransitionResult?(result)
            }).disposed(by: onTransitionResultDisposeBag)
    }
}
