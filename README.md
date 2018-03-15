# Jester

[![CI Status](http://img.shields.io/travis/vhart/Jester.svg?style=flat)](https://travis-ci.org/vhart/Jester)
[![Version](https://img.shields.io/cocoapods/v/Jester.svg?style=flat)](http://cocoapods.org/pods/Jester)
[![License](https://img.shields.io/cocoapods/l/Jester.svg?style=flat)](http://cocoapods.org/pods/Jester)
[![Platform](https://img.shields.io/cocoapods/p/Jester.svg?style=flat)](http://cocoapods.org/pods/Jester)

Jester is a pure swift state machine with a Rx streams and non-Rx callbacks.

The DSL was inspired by [RxAutomaton](https://github.com/inamiy/RxAutomaton).

## Table of Contents

- [Example](#example)
- [How To](#how-to)
    - [Inputs](#inputs)
    - [States](#states)
    - [Effects](#effects)
    - [Combining The Components](#combining-the-components)
    - [Generate Mappings](#generate-mappings)
    - [Sending an Input](#sending-an-input)
    - [Observing with RxSwift](#observing-with-rxswift)
    - [Observing with Callbacks](#observing-with-callbacks)
- [More Info](#more-info)
- [Requirements](#requirements)

## Example

```swift
class ShopKeepSelfDrivingCar {

    var numberOfPassengers: Int = 0
    var locationRequested: String? = nil
    private(set) var machine: StateMachine<State>!

    enum Input {
        static let startEngine           = BaseInput<Void>(description: "startEngine")
        static let driveAround           = BaseInput<Void>(description: "drive")
        static let park                  = BaseInput<Void>(description: "park")
        static let pickUpPassengers      = BaseInput<Void>(description: "pickUpPassengers")
        static let passengersHaveEntered = BaseInput<Int>(description: "passengersHaveEntered")
        static let driveToLocation       = BaseInput<String>(description: "driveToLocation")
        static let dropOffPassengers     = BaseInput<Void>(description: "dropOffPassengers")

        static let noMapInput            = BaseInput<Void>(description: "noMapInput")
        static let noFailInput           = BaseInput<Void>(description: "noFailInput")
    }

    enum State {
        case unstarted
        case drivingAround
        case drivingToLocation
        case parked
        case pickingUpPassengers
        case droppingOffPassengers
    }

    init() {
        let mappings: [MappedStateTransition<State>] = { [weak self] in

        let dropOffPassengers  = wrap { self?.dropOffPassengers($0) }
        let pickedUpPassengers = wrap { self?.pickedUpPassengers($0, $1) }
        let driveToLocation    = wrap { self?.driveToLocation($0, $1) }
        let noEffect           = wrap { self?.noEffect($0) }

        return [
            //    Input                 |     from State      ->      to State             | Effect (callback)
            Input.startEngine           | .unstarted => .parked                            | noEffect,

            Input.driveAround           | .parked => .drivingAround                        | noEffect,
            Input.driveAround           | .droppingOffPassengers => .drivingAround         | noEffect,

            Input.park                  | .drivingAround => .parked                        | noEffect,
            Input.park                  | .drivingToLocation => .parked                    | noEffect,

            Input.pickUpPassengers      | .parked => .pickingUpPassengers                  | noEffect,
            Input.passengersHaveEntered | .pickingUpPassengers => .pickingUpPassengers     | pickedUpPassengers,
            Input.driveToLocation       | .pickingUpPassengers => .drivingToLocation       | driveToLocation,
            Input.dropOffPassengers     | .parked => .droppingOffPassengers                | dropOffPassengers,

            Input.noFailInput           | .unstarted => .unstarted                         | noEffect,
            Input.noFailInput           | .drivingAround => .drivingAround                 | noEffect,
            Input.noFailInput           | .drivingToLocation => .drivingToLocation         | noEffect,
            Input.noFailInput           | .parked => .parked                               | noEffect,
            Input.noFailInput           | .pickingUpPassengers => .pickingUpPassengers     | noEffect,
            Input.noFailInput           | .droppingOffPassengers => .droppingOffPassengers | noEffect,
            ]
        }()

        machine = StateMachine<State>.init(initialState: .unstarted, mappings: mappings)
    }

    func driveToLocation(_ location: String, _ machine: StateMachine<State>) {
        locationRequested = location
    }

    func dropOffPassengers(_ machine: StateMachine<State>) {
        numberOfPassengers = 0
    }

    func pickedUpPassengers(_ count: Int, _ machine: StateMachine<State>) {
        numberOfPassengers = count
    }

    private func noEffect(_ machine: StateMachine<State>) {}
}
```

## How To

There are three components that are needed to set up your state machine:

### Inputs

```swift
enum Input {
    static let startEngine           = BaseInput<Void>(description: "startEngine")
    static let driveAround           = BaseInput<Void>(description: "drive")
    static let park                  = BaseInput<Void>(description: "park")
    static let pickUpPassengers      = BaseInput<Void>(description: "pickUpPassengers")
    static let passengersHaveEntered = BaseInput<Int>(description: "passengersHaveEntered")
    static let driveToLocation       = BaseInput<String>(description: "driveToLocation")
    static let dropOffPassengers     = BaseInput<Void>(description: "dropOffPassengers")

    static let noMapInput            = BaseInput<Void>(description: "noMapInput")
    static let noFailInput           = BaseInput<Void>(description: "noFailInput")
}
```
To create an input, initialize a `BaseInput`. Every `BaseInput` has an `id` and `description`. The `description` is for the
user's convenience, making it easier when debugging and reading code.

It is **required** that your `BaseInput` be static or belong to a singleton. The reason is that every instance of `BaseInput` generates
a `uuid`, so in order for the inputs to match, they must be the input used during the creation of the state machine. The above uses
an `enum` simply for name spacing but the same can be done using a `struct` or `class`.

You'll also notice that `BaseInput` has a generic type. This specifies the type of argument that can be passed the `BaseInput`'s
derivative input, `InputWithArgument`.

### States

```swift
enum State {
    case unstarted
    case drivingAround
    case drivingToLocation
    case parked
    case pickingUpPassengers
    case droppingOffPassengers
}
```

Your state machine `State` can be anything, as long as it is `Equatable`.
`Enum`s generally work well as states, but if the enum required `associated values` you will have to define `equality`.

### Effects

```swift
let dropOffPassengers  = wrap { self?.dropOffPassengers($0) }
let pickedUpPassengers = wrap { self?.pickedUpPassengers($0, $1) }
let driveToLocation    = wrap { self?.driveToLocation($0, $1) }
let noEffect           = wrap { self?.noEffect($0) }
```
The global function `wrap` will allow you to generate an `EffectWrapper`, which really just holds a callback.
Effect callback closures that **don't** require the handline of an input argument must be of type:
    `(StateMachine<State>) -> Void`
While callbacks that are intended to be used for handling input arguments must be of type:
    `(T, StateMachine<State>) -> Void`
where `T` is the type required.

### Combining The Components

```swift
//    Input                 |     from State      ->      to State             | Effect (callback)
Input.driveToLocation       | .pickingUpPassengers => .drivingToLocation       | driveToLocation,
```
This can be read as:
When I receive an input of `driveToLocation`
And I am currently on state `.pickingUpPassengers`
Then move to state `.drivingToLocation`
And call the effect `driveToLocation`

### Generate Mappings

```swift
let mappings: [MappedStateTransition<State>] = { [weak self] in
    // set up effects and mappings here
    // example:
    let driveToLocation    = wrap { self?.driveToLocation($0, $1) }

    Input.driveToLocation       | .pickingUpPassengers => .drivingToLocation       | driveToLocation,
}()
```
It is recommended to create your mappings using an immediately executed closure (similar to how lazy variables are created).
This allows you to **weakify** self, preventing retain cycles between the state machine and the owner of the machine.

Then once you have your mappings you can initialize the state machine with the mappings.

```swift
let machine = StateMachine<State>.init(initialState: .unstarted, mappings: mappings)
```

### Sending An Input

Sending an input to your state machine is straighforward:
```swift
machine.send(Input.startEngine)
```

Sending an input with an argument is just as simple:
```swift
machine.send(Input.passengersHaveEntered.inputWithArgument(4))
```
As you can see above, to generate an `InputWithArgument`, use the `inputWithArgument` function on your the
corresponding `BaseInput` instance, supplying an argument that matches the type specified by the `BaseInput`.

Because the type is specified you are guaranteed to have compile time checking - preventing any runtime type mismatches.
Additionally Jester was built to force the `Effect` to only accept the type specified by the `BaseInput` its' mapping row.

#### Observing with RxSwift

If you're using RxSwift, you can hook into your state machine's updates by using the `currentState` property on your state machine.
You can also hook into all transition results through the `transitionResults` property on your state machine.

`StateTransitionResult` :
```swift
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
```

`StateTransitionError` :
```swift
public struct StateTransitionError<State>: Swift.Error, CustomDebugStringConvertible  {
    public let current: State
    public let input: AnyInput
    public let error: MappingError

    public var debugDescription: String {
        return "STATE TRANSITION ERROR:\n    state: \(current)\n    input: \(input)\n    error: \(error)\n\n"
    }
}
```

### Observing with Callbacks

For those who opt to use callbacks instead of RxSwift, hooking into the updates and transition results is just as simple.
Simply use the `watcher()` function on your state machine to generate a callback registry, `StateMachineWatcher`.
Then add your callbacks through the `onNext(_:)` and `onTransitionResult(_:)` functions.
Just be sure to retain your `StateMachineWatcher`.

Examples:
```swift
watcher = machine.watcher()

watcher.onNext({ state in
    currentState = state
})

watcher.onTransitionResult({ result in
    switch result {
    case .Success(let oldState, let newState, let input): break
    case .Failure(let err): error = err
    }
})
```

## More Info

For more info, check out the `Tests` in the `Example` folder. There should be adequate sample code there and in the
`ShopKeepSelfDrivingCar` code which is also in the `Tests` folder and up above in [Example](#example) section.

## Requirements

iOS 9+ | Swift 4

## Installation

Jester is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Jester'
```

## Author

ShopKeep

## License

Jester is available under the MIT license. See the LICENSE file for more info.
