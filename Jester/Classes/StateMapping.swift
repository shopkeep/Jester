public func wrap<State>(effect: @escaping EffectWrapper<Void, State>.Effect) -> EffectWrapper<Void, State> {
    return EffectWrapper<Void, State>(effect: effect)
}
public func wrap<T, State>(effect: @escaping EffectWrapper<T, State>.EffectWithInput) -> EffectWrapper<T, State> {
    return EffectWrapper<T, State>(effect: effect)
}
public func noEffect<State>() -> EffectWrapper<Void, State> {
    return EffectWrapper<Void, State>(effect: { _ in })
}

public struct EffectWrapper<T, State> {
    public typealias EffectWithInput = (T, StateMachine<State>) -> Void
    public typealias Effect = (StateMachine<State>) -> Void

    public let effect: EffectWithInput

    public init(effect: @escaping Effect) {
        self.effect = { _, sm in effect(sm) }
    }

    public init(effect: @escaping EffectWithInput) {
        self.effect = effect
    }
}

public enum MappingError: Swift.Error {
    case invalidArgumentType
    case noMapForInput
}
