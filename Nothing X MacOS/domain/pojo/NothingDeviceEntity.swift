//
//  NothingDevice.swift
//  BluetoothTest
//
//  Created by Daniel on 2025/2/13.
//
import Foundation

class NothingDeviceEntity : Codable, ObservableObject {
    
    let name: String
    let serial: String
    let codename: Codenames
    let firmware: String
    let sku: SKU
    let bluetoothDetails: BluetoothDeviceEntity
    
    var leftBattery: Int
    var rightBattery: Int
    var caseBattery: Int
    
    var isLeftCharging: Bool
    var isRightCharging: Bool
    var isCaseCharging: Bool
    
    var isLeftConnected: Bool
    var isRightConnected: Bool
    var isCaseConnected: Bool
    
    var anc: ANC
    var listeningMode: EQProfiles
    
    var isLowLatencyOn: Bool
    var isInEarDetectionOn: Bool
    
    var tripleTapGestureActionLeft: TripleTapGestureActions
    var tripleTapGestureActionRight: TripleTapGestureActions
    
    var tapAndHoldGestureActionLeft: TapAndHoldGestureActions
    var tapAndHoldGestureActionRight: TapAndHoldGestureActions

    var doubleTapGestureActionLeft: DoubleTapGestureActions
    var doubleTapGestureActionRight: DoubleTapGestureActions

    var doubleTapAndHoldGestureActionLeft: DoubleTapAndHoldGestureActions
    var doubleTapAndHoldGestureActionRight: DoubleTapAndHoldGestureActions

    // Custom EQ
    var isAdvancedEQEnabled: Bool
    var customEQBass: Float
    var customEQMid: Float
    var customEQTreble: Float

    // Enhanced Bass
    var isEnhancedBassEnabled: Bool
    var enhancedBassLevel: Int

    // Personalized ANC
    var isPersonalizedANCEnabled: Bool

    // Case LED Colors
    var caseLEDColors: [[UInt8]]

    // Connection History
    var lastConnected: Date?

    init(name: String, serial: String, codename: Codenames, firmware: String, sku: SKU, leftBattery: Int, rightBattery: Int, caseBattery: Int, isLeftCharging: Bool, isRightCharging: Bool, isCaseCharging: Bool, isLeftConnected: Bool, isRightConnected: Bool, isCaseConnected: Bool, anc: ANC, listeningMode: EQProfiles, isLowLatencyOn: Bool, isInEarDetectionOn: Bool, bluetoothDetails: BluetoothDeviceEntity, tripleTapGestureActionLeft: TripleTapGestureActions, tripleTapGestureActionRight: TripleTapGestureActions, tapAndHoldGestureActionLeft: TapAndHoldGestureActions, tapAndHoldGestureActionRight: TapAndHoldGestureActions, doubleTapGestureActionLeft: DoubleTapGestureActions = .PLAY_PAUSE, doubleTapGestureActionRight: DoubleTapGestureActions = .PLAY_PAUSE, doubleTapAndHoldGestureActionLeft: DoubleTapAndHoldGestureActions = .NO_EXTRA_ACTION, doubleTapAndHoldGestureActionRight: DoubleTapAndHoldGestureActions = .NO_EXTRA_ACTION, isAdvancedEQEnabled: Bool = false, customEQBass: Float = 0.0, customEQMid: Float = 0.0, customEQTreble: Float = 0.0, isEnhancedBassEnabled: Bool = false, enhancedBassLevel: Int = 0, isPersonalizedANCEnabled: Bool = false, caseLEDColors: [[UInt8]] = Array(repeating: [0xFF, 0x00, 0x00], count: 5), lastConnected: Date? = nil) {
        self.name = name
        self.serial = serial
        self.codename = codename
        self.firmware = firmware
        self.sku = sku
        self.leftBattery = leftBattery
        self.rightBattery = rightBattery
        self.caseBattery = caseBattery
        self.isLeftCharging = isLeftCharging
        self.isRightCharging = isRightCharging
        self.isCaseCharging = isCaseCharging
        self.isLeftConnected = isLeftConnected
        self.isRightConnected = isRightConnected
        self.isCaseConnected = isCaseConnected
        self.anc = anc
        self.listeningMode = listeningMode
        self.isLowLatencyOn = isLowLatencyOn
        self.isInEarDetectionOn = isInEarDetectionOn
        self.bluetoothDetails = bluetoothDetails
        self.tripleTapGestureActionLeft = tripleTapGestureActionLeft
        self.tripleTapGestureActionRight = tripleTapGestureActionRight
        self.tapAndHoldGestureActionLeft = tapAndHoldGestureActionLeft
        self.tapAndHoldGestureActionRight = tapAndHoldGestureActionRight
        self.doubleTapGestureActionLeft = doubleTapGestureActionLeft
        self.doubleTapGestureActionRight = doubleTapGestureActionRight
        self.doubleTapAndHoldGestureActionLeft = doubleTapAndHoldGestureActionLeft
        self.doubleTapAndHoldGestureActionRight = doubleTapAndHoldGestureActionRight
        self.isAdvancedEQEnabled = isAdvancedEQEnabled
        self.customEQBass = customEQBass
        self.customEQMid = customEQMid
        self.customEQTreble = customEQTreble
        self.isEnhancedBassEnabled = isEnhancedBassEnabled
        self.enhancedBassLevel = enhancedBassLevel
        self.isPersonalizedANCEnabled = isPersonalizedANCEnabled
        self.caseLEDColors = caseLEDColors
        self.lastConnected = lastConnected
    }
    
    
    
}
