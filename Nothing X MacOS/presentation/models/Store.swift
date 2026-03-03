//
//  Store.swift
//  Nothing X MacOS
//
//  Created by Arunavo Ray on 21/02/23.
//

import Foundation
import SwiftUI

enum BatteryDisplayMode: String, CaseIterable, Identifiable {
    case both = "both"
    case average = "average"
    case minimum = "minimum"

    var label: String {
        switch self {
        case .both: return "L·R"
        case .average: return "AVG"
        case .minimum: return "MIN"
        }
    }

    var id: String { self.rawValue }
}

enum DiscoverStates {
    case not_discovering
    case discovering
    case found
    case not_found
    case connecting
    case failed_to_connect
}

enum TripleTapOptions: String, CaseIterable, Hashable {
    case skip_forward = "skip forward"
    case skip_back = "skip back"
    case voice_assistant = "voice assistant"
    case no_action = "no action"
}

enum TapAndHoldOptions: String, CaseIterable, Hashable {
    case noise_control = "noise control"
    case voice_assistant = "voice assistant"
    case volume_up = "volume up"
    case volume_down = "volume down"
    case no_extra_action = "no extra action"
}

enum DoubleTapOptions: String, CaseIterable, Hashable {
    case play_pause = "play / pause"
    case skip_forward = "skip forward"
    case skip_back = "skip back"
    case voice_assistant = "voice assistant"
    case no_action = "no action"
}

enum DoubleTapAndHoldOptions: String, CaseIterable, Hashable {
    case noise_control = "noise control"
    case volume_up = "volume up"
    case volume_down = "volume down"
    case voice_assistant = "voice assistant"
    case no_extra_action = "no extra action"
}

enum EarBudSide: String, CaseIterable, Identifiable, Hashable {
    case left
    case right

    var id: String { self.rawValue }
}

enum NoiseControlOptions: String, CaseIterable, Identifiable, Hashable {
    case anc
    case transparency
    case off
    
    var icon: String {
        switch self {
            case .anc:
                return "person.crop.circle"
            case .transparency:
                return "person.and.background.dotted"
            case .off:
                return "person.crop.circle.dashed"
        }
    }
    
    var id: String { self.rawValue }
}

class Store: ObservableObject {
    @AppStorage("batteryDisplayMode") var batteryDisplayMode: BatteryDisplayMode = .both

    // [left, right]
    @Published var selectedTripleTapOp: [TripleTapOptions] = [TripleTapOptions.skip_forward, TripleTapOptions.skip_forward]
    @Published var selectedtapAndHoldOp: [TapAndHoldOptions] = [TapAndHoldOptions.noise_control, TapAndHoldOptions.noise_control]
    @Published var fixedtapAndHoldOp = "Decline incoming call"
    
    @Published var earBudSelectedSide = EarBudSide.left.rawValue
    
    @Published var noiseControlSelected = NoiseControlOptions.transparency.rawValue
    
    @Published var leftBattery: Float = 40.0
    @Published var caseBattery: Float = 70.0
    @Published var rightBattery: Float = 50.0
}
