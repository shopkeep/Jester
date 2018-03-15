import Foundation

public struct StateTransition<State> {
    let currentStateMatches: (State) -> Bool
    let nextState: State

    fileprivate init(currentStateCondition: @escaping (State) -> Bool, nextState: State) {
        self.currentStateMatches = currentStateCondition
        self.nextState = nextState
    }
}

public struct TypedStateTransition<T, State> {
    let stateTransition: StateTransition<State>
    let inputId: String

    fileprivate init(_ input: BaseInput<T>, transition: StateTransition<State>) {
        self.inputId = input.id
        self.stateTransition = transition
    }

    var typeErasedTransition: TypeErasedStateTransition<State> {
        return TypeErasedStateTransition(inputId, transition: stateTransition)
    }
}

public struct TypeErasedStateTransition<State> {
    let stateTransition: StateTransition<State>
    let inputId: String

    func initialStateMatches(_ state: State) -> Bool {
        return stateTransition.currentStateMatches(state)
    }

    fileprivate init(_ inputId: String, transition: StateTransition<State>) {
        self.inputId = inputId
        self.stateTransition = transition
    }
}

public struct MappedStateTransition<State> {
    let erasedTransition: TypeErasedStateTransition<State>
    let effectWithArguments: (Any, StateMachine<State>) throws -> (() -> Void)

    fileprivate init(erasedTransition: TypeErasedStateTransition<State>,
                     effectWithArguments: @escaping (Any, StateMachine<State>) throws -> (() -> Void)) {
        self.erasedTransition = erasedTransition
        self.effectWithArguments = effectWithArguments
    }
}

infix operator => : MultiplicationPrecedence
infix operator | : AdditionPrecedence

public func => <State: Equatable>(state: State, nextState: State) -> StateTransition<State> {
    return { $0 == state } => nextState
}

public func => <State>(condition: @escaping (State) -> Bool, nextState: State) -> StateTransition<State> {
    return StateTransition(currentStateCondition: condition, nextState: nextState)
}

public func |<T, State: Equatable>(input: BaseInput<T>, transition: StateTransition<State>) -> TypedStateTransition<T, State> {
    return TypedStateTransition(input, transition: transition)
}

public func |<T, State: Equatable>(typedTransition: TypedStateTransition<T, State>, effect: EffectWrapper<T, State>) -> MappedStateTransition<State> {
    let typeErasedTransition = typedTransition.typeErasedTransition
    let effectWithArguments: (Any, StateMachine<State>) throws -> (() -> Void) = { arg, sm in
        guard let arg = arg as? T else { throw MappingError.invalidArgumentType }
        return {
            effect.effect?(arg, sm)
        }
    }

    return MappedStateTransition(erasedTransition: typeErasedTransition, effectWithArguments: effectWithArguments)
}
