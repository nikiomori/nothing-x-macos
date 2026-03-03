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
}

class EarTipTestViewModel: ObservableObject {

    private let nothingService: NothingService

    @Published var state: EarTipTestState = .idle
    @Published var leftResult: EarTipResult = .unknown
    @Published var rightResult: EarTipResult = .unknown

    init(nothingService: NothingService) {
        self.nothingService = nothingService

        NotificationCenter.default.addObserver(forName: Notification.Name(DataNotifications.EAR_TIP_TEST_RESULT.rawValue), object: nil, queue: .main) { notification in
            if let userInfo = notification.userInfo,
               let left = userInfo["left"] as? UInt8,
               let right = userInfo["right"] as? UInt8 {

                self.leftResult = left == 1 ? .goodSeal : .poorSeal
                self.rightResult = right == 1 ? .goodSeal : .poorSeal
                self.state = .completed
            }
        }
    }

    func startTest() {
        state = .testing
        leftResult = .unknown
        rightResult = .unknown
        nothingService.launchEarTipTest()
    }
}
