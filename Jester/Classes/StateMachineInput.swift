import Foundation

public protocol AnyInput {
    var id: String { get }
}

public struct BaseInput<T>: AnyInput, CustomDebugStringConvertible {
    public let id = NSUUID().uuidString
    let description: String?

    public init(description: String? = nil, file: String = #file, line: Int = #line) {
        self.description = description ?? "\((file as NSString).lastPathComponent): \(line)"
    }

    public func inputWithArgument(_ argument: T) -> InputWithArgument<T> {
        return InputWithArgument(self, argument: argument)
    }

    public var debugDescription: String {
        return "BaseInput<\(T.self)> {\n    \(description!)"
    }
}

public struct InputWithArgument<T>: AnyInput, CustomDebugStringConvertible {
    let argument: T
    let input: BaseInput<T>
    public var id: String { return input.id }

    public init(_ input: BaseInput<T>, argument: T) {
        self.input = input
        self.argument = argument
    }

    public var debugDescription: String {
        var argDesc: String = ""
        dump(argument, to: &argDesc, name: nil, indent: 6, maxDepth: 6, maxItems: 20)
        return "InputWithArgument<\(T.self)>:\n    base: \(input.debugDescription)\n    arg:\(argDesc)\n"
    }
}
