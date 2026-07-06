//
//  ANC.swift
//  BluetoothTest
//
//  Created by Daniel on 2025/2/13.
//

enum ANC : UInt8, Codable {

    case OFF = 0x05
    case TRANSPARENCY = 0x07
    case ON_LOW = 0x03
    case ON_HIGH = 0x01
    case ON_MID = 0x02
    case ADAPTIVE = 0x04

    var displayName: String {
        switch self {
        case .OFF: return "Off"
        case .TRANSPARENCY: return "Transparency"
        case .ON_LOW: return "Low"
        case .ON_MID: return "Mid"
        case .ON_HIGH: return "High"
        case .ADAPTIVE: return "Adaptive"
        }
    }

    // ANC intensity levels selectable when noise cancellation is active
    static let levels: [ANC] = [.ON_LOW, .ON_MID, .ON_HIGH]

    var isNoiseCancellationActive: Bool {
        self != .OFF && self != .TRANSPARENCY
    }

}
