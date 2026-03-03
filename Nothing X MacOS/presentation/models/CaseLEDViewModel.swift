//
//  CaseLEDViewModel.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/3/3.
//

import Foundation
import SwiftUI

class CaseLEDViewModel: ObservableObject {

    private let nothingService: NothingService

    @Published var colors: [Color] = Array(repeating: .red, count: 5)

    init(nothingService: NothingService) {
        self.nothingService = nothingService

        NotificationCenter.default.addObserver(forName: Notification.Name(DataNotifications.REPOSITORY_DATA_UPDATED.rawValue), object: nil, queue: .main) { notification in
            if let device = notification.object as? NothingDeviceEntity {
                self.colors = device.caseLEDColors.map { rgb in
                    guard rgb.count >= 3 else { return Color.red }
                    return Color(
                        red: Double(rgb[0]) / 255.0,
                        green: Double(rgb[1]) / 255.0,
                        blue: Double(rgb[2]) / 255.0
                    )
                }
            }
        }
    }

    func applyColors() {
        let rgbColors: [[UInt8]] = colors.map { color in
            let nsColor = NSColor(color)
            let r = UInt8((nsColor.redComponent * 255).clamped(to: 0...255))
            let g = UInt8((nsColor.greenComponent * 255).clamped(to: 0...255))
            let b = UInt8((nsColor.blueComponent * 255).clamped(to: 0...255))
            return [r, g, b]
        }
        nothingService.setCaseLEDColor(colors: rgbColors)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
