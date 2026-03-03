//
//  FindMyBudsViewViewModel.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/3/2.
//

import Foundation

enum RingTarget {
    case both
    case left
    case right
}

class FindMyBudsViewViewModel : ObservableObject {

    private let ringBudsUseCase: RingBudsUseCaseProtocol
    private let stopRingingBudsUseCase: StopRingingBudsUseCaseProtocol
    @Published var shouldShowWarning = false
    @Published var pendingRingTarget: RingTarget = .both

    @Published var isRinging = false
    @Published var ringingTarget: RingTarget = .both

    init(nothingService: NothingService) {
        ringBudsUseCase = RingBudsUseCase(nothingService: nothingService)
        stopRingingBudsUseCase = StopRingingBudsUseCase(nothingService: nothingService)
    }

    func requestRing(target: RingTarget) {
        pendingRingTarget = target
        shouldShowWarning = true
    }

    func confirmRing() {
        isRinging = true
        ringingTarget = pendingRingTarget
        shouldShowWarning = false
        switch pendingRingTarget {
        case .both:
            ringBudsUseCase.ringBuds()
        case .left:
            ringBudsUseCase.ringBud(device: .LEFT)
        case .right:
            ringBudsUseCase.ringBud(device: .RIGHT)
        }
    }

    func stopRinging() {
        isRinging = false
        switch ringingTarget {
        case .both:
            stopRingingBudsUseCase.stopRingingBuds()
        case .left:
            stopRingingBudsUseCase.stopRingingBud(device: .LEFT)
        case .right:
            stopRingingBudsUseCase.stopRingingBud(device: .RIGHT)
        }
    }

}
