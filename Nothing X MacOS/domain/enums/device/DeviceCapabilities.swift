//
//  DeviceCapabilities.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/3/3.
//

import Foundation

struct DeviceCapabilities {
    let supportsCustomEQ: Bool
    let supportsEnhancedBass: Bool
    let supportsPersonalizedANC: Bool
    let supportsEarTipTest: Bool
    let supportsCaseLED: Bool
    let supportsANCCycleConfig: Bool
    let supportsDoubleTap: Bool
    let supportsDoubleTapAndHold: Bool

    static func capabilities(for codename: Codenames) -> DeviceCapabilities {
        switch codename {
        case .ONE: // B181 - Ear (1)
            return DeviceCapabilities(
                supportsCustomEQ: false,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: true,
                supportsANCCycleConfig: false,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false
            )
        case .TWO: // B155 - Ear (2)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: true,
                supportsEarTipTest: true,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false
            )
        case .TWOS: // B171 - Ear (2024)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: true,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true
            )
        case .ESPEON: // B172
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: true,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true
            )
        case .DONPHAN: // B168
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true
            )
        case .CLEFFA: // B162
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: true,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: false
            )
        case .CORSOLA: // B163 - Ear (a)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false
            )
        case .STICKS: // B157 - Ear (stick)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: false,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false
            )
        case .FLAFFY: // B174 - Ear (open)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: false,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false
            )
        case .CROBAT: // B164
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: false,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false
            )
        case .EAR3: // B173 - Ear (3)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true
            )
        case .UNKNOWN:
            return DeviceCapabilities(
                supportsCustomEQ: false,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: false,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false
            )
        }
    }
}
