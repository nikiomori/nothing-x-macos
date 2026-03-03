//
//  EarTipTestViewModel.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/3/3.
//

import Foundation

enum EarTipTestState {
    case idle
    case testing
    case completed
}

enum EarTipResult {
    case unknown
    case goodSeal
    case poorSeal
    case notInEar
}

class EarTipTestViewModel: ObservableObject {

    private let nothingService: NothingService

    @Published var state: EarTipTestState = .idle
    @Published var leftResult: EarTipResult = .unknown
    @Published var rightResult: EarTipResult = .unknown

    private var observer: NSObjectProtocol?

    init(nothingService: NothingService) {
        self.nothingService = nothingService

        observer = NotificationCenter.default.addObserver(forName: Notification.Name(DataNotifications.EAR_TIP_TEST_RESULT.rawValue), object: nil, queue: .main) { [weak self] notification in
            guard let self else { return }
            if let userInfo = notification.userInfo,
               let left = userInfo["left"] as? UInt8,
               let right = userInfo["right"] as? UInt8 {

                self.leftResult = Self.mapResult(left)
                self.rightResult = Self.mapResult(right)
                self.state = .completed
            }
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    private static func mapResult(_ value: UInt8) -> EarTipResult {
        switch value {
        case 0: return .goodSeal
        case 1: return .poorSeal
        default: return .notInEar
        }
    }

    func startTest() {
        state = .testing
        leftResult = .unknown
        rightResult = .unknown
        nothingService.launchEarTipTest()
    }
}
