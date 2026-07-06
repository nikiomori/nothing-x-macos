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
    let supportsAdaptiveANC: Bool
    let supportsDoubleTap: Bool
    let supportsDoubleTapAndHold: Bool
    // Over-ear and neckband devices: one unit, one battery, no case, no L/R split
    let isSingleUnit: Bool

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
                supportsAdaptiveANC: false,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false,
                isSingleUnit: false
            )
        case .TWO: // B155 - Ear (2)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: true,
                supportsEarTipTest: true,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: true,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false,
                isSingleUnit: false
            )
        case .TWOS: // B171 - Nothing Ear (2024)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: true,
                supportsEarTipTest: true,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true,
                isSingleUnit: false
            )
        case .ESPEON: // B172 - CMF Buds Pro 2
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: true,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true,
                isSingleUnit: false
            )
        case .DONPHAN: // B168 - CMF Buds
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: false,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true,
                isSingleUnit: false
            )
        case .CLEFFA: // B162 - Nothing Ear (a)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: true,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: false,
                isSingleUnit: false
            )
        case .CORSOLA: // B163 - CMF Buds Pro
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: false,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true,
                isSingleUnit: false
            )
        case .STICKS: // B157 - Ear (stick)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: false,
                supportsAdaptiveANC: false,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false,
                isSingleUnit: false
            )
        case .FLAFFY: // B174 - Ear (open)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: false,
                supportsAdaptiveANC: false,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false,
                isSingleUnit: false
            )
        case .CROBAT: // B164 - CMF Neckband Pro
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: false,
                supportsAdaptiveANC: false,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false,
                isSingleUnit: true
            )
        case .EAR3: // B173 - Ear (3)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: true,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true,
                isSingleUnit: false
            )
        case .GIRAFARIG: // B179 - CMF Buds 2
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: true,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true,
                isSingleUnit: false
            )
        case .GLIGAR: // B184 - CMF Buds 2 Plus
            return DeviceCapabilities(
                supportsCustomEQ: false,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: true,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true,
                isSingleUnit: false
            )
        case .HOOTHOOT: // B185 - CMF Buds 2a
            return DeviceCapabilities(
                supportsCustomEQ: false,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: false,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true,
                isSingleUnit: false
            )
        case .ELEKID: // B170 - Nothing Headphone (1)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true,
                isSingleUnit: true
            )
        case .HEADPHONE_PRO: // B175 - CMF Headphone Pro (untested, mirrors Headphone (1))
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: false,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true,
                isSingleUnit: true
            )
        case .HEADPHONE_A: // B186 - Nothing Headphone (a) (untested, advertises Adaptive ANC)
            return DeviceCapabilities(
                supportsCustomEQ: true,
                supportsEnhancedBass: true,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: true,
                supportsAdaptiveANC: true,
                supportsDoubleTap: true,
                supportsDoubleTapAndHold: true,
                isSingleUnit: true
            )
        case .UNKNOWN:
            return DeviceCapabilities(
                supportsCustomEQ: false,
                supportsEnhancedBass: false,
                supportsPersonalizedANC: false,
                supportsEarTipTest: false,
                supportsCaseLED: false,
                supportsANCCycleConfig: false,
                supportsAdaptiveANC: false,
                supportsDoubleTap: false,
                supportsDoubleTapAndHold: false,
                isSingleUnit: false
            )
        }
    }
}
