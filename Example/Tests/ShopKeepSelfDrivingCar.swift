import Jester

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

            return [
                Input.startEngine           | .unstarted => .parked                            | .noEffect(),

                Input.driveAround           | .parked => .drivingAround                        | .noEffect(),
                Input.driveAround           | .droppingOffPassengers => .drivingAround         | .noEffect(),

                Input.park                  | .drivingAround => .parked                        | .noEffect(),
                Input.park                  | .drivingToLocation => .parked                    | .noEffect(),

                Input.pickUpPassengers      | .parked => .pickingUpPassengers                  | .noEffect(),
                Input.passengersHaveEntered | .pickingUpPassengers => .pickingUpPassengers     | pickedUpPassengers,
                Input.driveToLocation       | .pickingUpPassengers => .drivingToLocation       | driveToLocation,
                Input.dropOffPassengers     | .parked => .droppingOffPassengers                | dropOffPassengers,

                Input.noFailInput           | .unstarted => .unstarted                         | .noEffect(),
                Input.noFailInput           | .drivingAround => .drivingAround                 | .noEffect(),
                Input.noFailInput           | .drivingToLocation => .drivingToLocation         | .noEffect(),
                Input.noFailInput           | .parked => .parked                               | .noEffect(),
                Input.noFailInput           | .pickingUpPassengers => .pickingUpPassengers     | .noEffect(),
                Input.noFailInput           | .droppingOffPassengers => .droppingOffPassengers | .noEffect(),
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

}
