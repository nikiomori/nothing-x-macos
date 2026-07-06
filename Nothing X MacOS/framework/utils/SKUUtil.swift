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
    case .GIRAFARIG_BLACK, .GIRAFARIG_GREEN, .GIRAFARIG_ORANGE:
        return .GIRAFARIG
    case .GLIGAR_WHITE, .GLIGAR_BLUE:
        return .GLIGAR
    case .HOOTHOOT_BLACK, .HOOTHOOT_WHITE, .HOOTHOOT_ORANGE:
        return .HOOTHOOT
    case .ELEKID_BLACK, .ELEKID_GREY:
        return .ELEKID
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
        // Year-based heuristic only — the READ_SERIAL_NUMBER handler
        // cross-checks the result against the advertised device name
        let year = String(serial.prefix(8).suffix(2))
        if year == "22" || year == "23" {
            // Ear (stick)
            return SKU.EAR_STICK_1
        } else {
            // Ear (open)
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
    let lowered = name.lowercased().trimmingCharacters(in: .whitespaces)
    if lowered.contains("ear (1)") {
        return .ONE
    } else if lowered.contains("ear (stick)") || lowered.contains("ear stick") {
        return .STICKS
    } else if lowered.contains("ear (2)") {
        return .TWO
    } else if lowered.contains("ear (a)") {
        return .CLEFFA
    } else if lowered.contains("ear (3)") {
        return .EAR3
    } else if lowered.contains("ear (open)") {
        return .FLAFFY
    } else if lowered.contains("buds 2 plus") {
        return .GLIGAR
    } else if lowered.contains("buds 2a") {
        return .HOOTHOOT
    } else if lowered.contains("buds 2") {
        return .GIRAFARIG
    } else if lowered.contains("buds pro 2") {
        return .ESPEON
    } else if lowered.contains("buds pro") {
        return .CORSOLA
    } else if lowered.contains("cmf buds") {
        return .DONPHAN
    } else if lowered.contains("neckband pro") {
        return .CROBAT
    } else if lowered.contains("headphone (1)") || lowered.contains("headphone(1)") {
        return .ELEKID
    } else if lowered.contains("headphone (a)") || lowered.contains("headphone(a)") {
        return .HEADPHONE_A
    } else if lowered.contains("headphone pro") {
        return .HEADPHONE_PRO
    } else if lowered == "nothing ear" || lowered == "ear" {
        // Nothing Ear (2024) is marketed as just "Nothing Ear"
        return .TWOS
    }
    return .UNKNOWN
}
