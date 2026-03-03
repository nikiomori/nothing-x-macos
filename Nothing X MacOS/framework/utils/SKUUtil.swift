//
//  SKUUtil.swift
//  BluetoothTest
//
//  Created by Daniel on 2025/2/18.
//

import Foundation


func codenameFromSKU(sku: SKU) -> Codenames {
    switch sku {
    case .EAR_1_WHITE:
        return .ONE
    case .EAR_1_BLACK:
        return .ONE
    case .EAR_1_WHITE_DUPLICATE:
        return .ONE
    case .EAR_1_BLACK_DUPLICATE:
        return .ONE
    case .EAR_1_BLACK_ALTERNATE:
        return .ONE
    case .EAR_1_WHITE_ALTERNATE:
        return .ONE
    case .EAR_1_BLACK_ANOTHER:
        return .ONE
    case .EAR_1_BLACK_FINAL:
        return .ONE
    case .EAR_STICK_1:
        return .STICKS
    case .EAR_STICK_2:
        return .STICKS
    case .EAR_STICK_3:
        return .STICKS
    case .EAR_2_WHITE_1:
        return .TWO
    case .EAR_2_WHITE_2:
        return .TWO
    case .EAR_2_WHITE_3:
        return .TWO
    case .EAR_2_BLACK_1:
        return .TWO
    case .EAR_2_BLACK_2:
        return .TWO
    case .EAR_2_BLACK_3:
        return .TWO
    case .CORSOLA_BLACK_1:
        return .CORSOLA
    case .CORSOLA_BLACK_2:
        return .CORSOLA
    case .CORSOLA_WHITE_1:
        return .CORSOLA
    case .CORSOLA_WHITE_2:
        return .CORSOLA
    case .CORSOLA_ORANGE_1:
        return .CORSOLA
    case .CORSOLA_ORANGE_2:
        return .CORSOLA
    case .DONPHAN_BLACK_1:
        return .DONPHAN
    case .DONPHAN_BLACK_2:
        return .DONPHAN
    case .DONPHAN_WHITE_1:
        return .DONPHAN
    case .DONPHAN_WHITE_2:
        return .DONPHAN
    case .DONPHAN_ORANGE_1:
        return .DONPHAN
    case .DONPHAN_ORANGE_2:
        return .DONPHAN
    case .ESPEON_BLACK_1:
        return .ESPEON
    case .ESPEON_WHITE_1:
        return .ESPEON
    case .ESPEON_ORANGE_1:
        return .ESPEON
    case .ESPEON_BLUE_1:
        return .ESPEON
    case .ESPEON_BLUE_2:
        return .ESPEON
    case .ESPEON_ORANGE_2:
        return .ESPEON
    case .ESPEON_WHITE_2:
        return .ESPEON
    case .ESPEON_BLACK_3:
        return .ESPEON
    case .FLAFFY_WHITE:
        return .FLAFFY
    case .CROBAT_ORANGE:
        return .CROBAT
    case .CROBAT_WHITE:
        return .CROBAT
    case .CROBAT_BLACK_1:
        return .CROBAT
    case .CROBAT_BLACK_2:
        return .CROBAT
    case .CROBAT_WHITE_2:
        return .CROBAT
    case .CROBAT_ORANGE_2:
        return .CROBAT
    case .CLEFFA_BLACK_1:
        return .CLEFFA
    case .CLEFFA_WHITE_1:
        return .CLEFFA
    case .CLEFFA_YELLOW_1:
        return .CLEFFA
    case .CLEFFA_BLACK_2:
        return .CLEFFA
    case .CLEFFA_WHITE_2:
        return .CLEFFA
    case .CLEFFA_YELLOW_2:
        return .CLEFFA
    case .CLEFFA_BLACK_3:
        return .CLEFFA
    case .CLEFFA_WHITE_3:
        return .CLEFFA
    case .CLEFFA_YELLOW_3:
        return .CLEFFA
    case .ENTEI_BLACK_1, .ENTEI_WHITE_1, .ENTEI_BLACK_2, .ENTEI_WHITE_2, .ENTEI_BLACK_3, .ENTEI_WHITE_3:
        return .TWOS
    case .EAR3_1, .EAR3_2:
        return .EAR3
    default:
        return .UNKNOWN
    }
}


func skuFromFirmware(firmware: String) -> SKU {
    let parts = firmware.split(separator: ".")
    if parts.count > 1 && parts[1] == "6700" {
        return SKU.EAR_1_WHITE
    }

    return SKU.UNKNOWN
}

func skuFromSerial(serial: String) -> SKU {
    
    if (serial.isEmpty) {
        return SKU.UNKNOWN
    }
    
    let headSerial = String(serial.prefix(2)) // Get the first two characters
    
    
    if serial == "12345678901234567" {
        return SKU.EAR_1_WHITE
    }
    
    if headSerial == "MA" {
        let year = String(serial.prefix(8).suffix(2))
        if year == "22" || year == "23" {
            // Ear (stick)
            return SKU.EAR_STICK_1
        } else if year == "24" {
            // Ear (open) TODO: Find a better way to identify both
            return SKU.FLAFFY_WHITE
        }
    } else if headSerial == "SH" || headSerial == "13" {
        if let sku = SKU(rawValue: String(serial.prefix(6).suffix(2))) {
            return sku
        }
    }
    
    return SKU.UNKNOWN
}

func codenameFromDeviceName(name: String) -> Codenames {
    let lowered = name.lowercased()
    if lowered.contains("ear (1)") {
        return .ONE
    } else if lowered.contains("ear stick") {
        return .STICKS
    } else if lowered.contains("ear (2s)") {
        return .CLEFFA
    } else if lowered.contains("ear (2)") {
        return .TWO
    } else if lowered.contains("ear (a)") {
        return .CORSOLA
    } else if lowered.contains("ear (3)") {
        return .EAR3
    } else if lowered.contains("ear (open)") {
        return .FLAFFY
    }
    return .UNKNOWN
}
