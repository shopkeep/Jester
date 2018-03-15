import Nimble
import Quick
import Jester
import RxSwift

class StateMachineSpec_Rx: QuickSpec {

    typealias Input = ShopKeepSelfDrivingCar.Input
    typealias State = ShopKeepSelfDrivingCar.State

    override func spec() {
        describe("StateMachineSpec") {

            let selfDrivingCar = ShopKeepSelfDrivingCar()
            let machine = selfDrivingCar.machine!

            context("when the car is initialized") {
                it("has an unstarted state") {
                    expect(machine.currentState.value) == State.unstarted
                }

                context("when the unstarted car's state machine is sent a .startEngine input") {
                    it("has a state of .parked") {
                        machine.send(Input.startEngine)
                        expect(machine.currentState.value) == State.parked
                    }

                    context("and the parked car's state machine is sent a .driveAround input") {
                        it("has a state of .drivingAround") {
                            machine.send(Input.driveAround)
                            expect(machine.currentState.value) == State.drivingAround
                        }

                        context("and the moving car's state machine is sent a .park input") {
                            it("has a state of .parked") {
                                machine.send(Input.park)
                                expect(machine.currentState.value) == State.parked
                            }

                            context("and the parked car's state machine is sent a .pickUpPassengers input") {
                                it("has a state of .pickingUpPassengers") {
                                    machine.send(Input.pickUpPassengers)
                                    expect(machine.currentState.value) == State.pickingUpPassengers
                                }

                                context("and the car's state machine is sent an input that 4 passengers have entered") {
                                    it("has a state of .pickingUpPassengers and the car has 4 passengers") {
                                        expect(selfDrivingCar.numberOfPassengers) == 0

                                        machine.send(Input.passengersHaveEntered.inputWithArgument(4))

                                        expect(machine.currentState.value) == State.pickingUpPassengers
                                        expect(selfDrivingCar.numberOfPassengers) == 4
                                    }

                                    context("and the passenger carrying car's state machine is given a location to drive to") {
                                        it("has a state of .drivingToLocation and the car updates its location request") {
                                            expect(selfDrivingCar.locationRequested).to(beNil())

                                            machine.send(Input.driveToLocation.inputWithArgument("The Witches Brew"))

                                            expect(machine.currentState.value) == State.drivingToLocation
                                            expect(selfDrivingCar.locationRequested) == "The Witches Brew"
                                        }

                                        context("and the moving car's state machine is sent a .park input") {
                                            it("has a state of .parked") {
                                                machine.send(Input.park)
                                                expect(machine.currentState.value) == State.parked
                                            }

                                            context("and the parked car's state machine is sent a .dropOffPassengers input") {
                                                it("has a state of .droppingOffPassengers and the car's passenger count should reset") {
                                                    expect(selfDrivingCar.numberOfPassengers) == 4

                                                    machine.send(Input.dropOffPassengers)

                                                    expect(machine.currentState.value) == State.droppingOffPassengers
                                                    expect(selfDrivingCar.numberOfPassengers) == 0
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            context("when the car's state machine is sent an input that has no mapping") {
                it("emits a state transition error") {
                    let currentState = machine.currentState.value
                    var error: StateTransitionError<State>?
                    let disposeBag = DisposeBag()

                    machine.transitionResult.asObservable().subscribe(onNext: { result in
                        switch result {
                        case .Success(_, _, _): break
                        case .Failure(let err): error = err
                        }
                    }).disposed(by: disposeBag)

                    machine.send(Input.noMapInput)

                    expect(error!.current) == currentState
                    expect(error!.input.id) == Input.noMapInput.id
                    expect(error!.error) == MappingError.noMapForInput
                }
            }

            context("when the car's state machine is sent an input that succeeds") {
                it("emits a state transition success") {
                    let currentState = machine.currentState.value

                    var oldState: State?
                    var newState: State?
                    var inputSent: AnyInput?
                    let disposeBag = DisposeBag()

                    machine.transitionResult.asObservable().subscribe(onNext: { result in
                        switch result {
                        case .Success(let old, let new, let input):
                            oldState = old
                            newState = new
                            inputSent = input
                        case .Failure(_): break
                        }
                    }).disposed(by: disposeBag)

                    machine.send(Input.noFailInput)

                    expect(oldState!) == currentState
                    expect(newState!) == currentState
                    expect(inputSent!.id) == Input.noFailInput.id
                }
            }

            context("when the car's state machine is sent an input that succeeds") {
                it("emits a state transition success") {
                    let currentState = machine.currentState.value

                    var oldState: State?
                    var newState: State?
                    var inputSent: AnyInput?
                    let disposeBag = DisposeBag()

                    machine.transitionResult.asObservable().subscribe(onNext: { result in
                        switch result {
                        case .Success(let old, let new, let input):
                            oldState = old
                            newState = new
                            inputSent = input
                        case .Failure(_): break
                        }
                    }).disposed(by: disposeBag)

                    machine.send(Input.noFailInput)

                    expect(oldState!) == currentState
                    expect(newState!) == currentState
                    expect(inputSent!.id) == Input.noFailInput.id
                }
            }

            context("send(_: AnyInputWithArgument)") {
                context("when the car's state machine is sent an input that succeeds") {
                    it("emits a state transition success") {
                        let currentState = machine.currentState.value

                        var oldState: State?
                        var newState: State?
                        var inputSent: AnyInput?
                        let disposeBag = DisposeBag()

                        machine.transitionResult.asObservable().subscribe(onNext: { result in
                            switch result {
                            case .Success(let old, let new, let input):
                                oldState = old
                                newState = new
                                inputSent = input
                            case .Failure(_): break
                            }
                        }).disposed(by: disposeBag)

                        machine.send(Input.noFailInput.inputWithArgument(Void()))

                        expect(oldState!) == currentState
                        expect(newState!) == currentState
                        expect(inputSent!.id) == Input.noFailInput.id
                    }
                }

                context("when the car's state machine is sent an input that has no mapping") {
                    it("emits a state transition error") {
                        let currentState = machine.currentState.value
                        var error: StateTransitionError<State>?
                        let disposeBag = DisposeBag()

                        machine.transitionResult.asObservable().subscribe(onNext: { result in
                            switch result {
                            case .Success(_, _, _): break
                            case .Failure(let err): error = err
                            }
                        }).disposed(by: disposeBag)

                        machine.send(Input.noMapInput.inputWithArgument(Void()))

                        expect(error!.current) == currentState
                        expect(error!.input.id) == Input.noMapInput.id
                        expect(error!.error) == MappingError.noMapForInput
                    }
                }
            }
        }
    }
}

