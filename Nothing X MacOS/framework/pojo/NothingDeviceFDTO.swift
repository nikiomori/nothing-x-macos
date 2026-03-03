//
//  NothingDeviceFramework.swift
//  BluetoothTest
//
//  Created by Daniel on 2025/2/13.
//
import Combine
import Foundation

class NothingDeviceFDTO: ObservableObject {
    
    
    @Published var name: String = "" {
        didSet { notifyDataUpdated() }
    }
    @Published var serial: String = "" {
        didSet { notifyDataUpdated() }
    }
    @Published var codename: Codenames = .UNKNOWN {
        didSet { notifyDataUpdated() }
    }
    @Published var firmware: String = "" {
        didSet { notifyDataUpdated() }
    }
    @Published var sku: SKU = .UNKNOWN {
        didSet { notifyDataUpdated() }
    }
    
    @Published var bluetoothDetails: BluetoothDeviceEntity {
        didSet { notifyDataUpdated() }
    }
    
    @Published var leftBattery: Int = 0 {
        didSet { notifyDataUpdated() }
    }
    @Published var rightBattery: Int = 0 {
        didSet { notifyDataUpdated() }
    }
    @Published var caseBattery: Int = 0 {
        didSet { notifyDataUpdated() }
    }
    
    @Published var isLeftCharging: Bool = false {
        didSet { notifyDataUpdated() }
    }
    @Published var isRightCharging: Bool = false {
        didSet { notifyDataUpdated() }
    }
    @Published var isCaseCharging: Bool = false {
        didSet { notifyDataUpdated() }
    }
    
    @Published var isLeftConnected: Bool = false {
        didSet { notifyDataUpdated() }
    }
    @Published var isRightConnected: Bool = false {
        didSet { notifyDataUpdated() }
    }
    @Published var isCaseConnected: Bool = false {
        didSet { notifyDataUpdated() }
    }
    
    @Published var anc: ANC = .OFF {
        didSet { notifyDataUpdated() }
    }
    @Published var listeningMode: EQProfiles = .BALANCED {
        didSet { notifyDataUpdated() }
    }
    
    @Published var isLowLatencyOn: Bool = false {
        didSet { notifyDataUpdated() }
    }
    @Published var isInEarDetectionOn: Bool = false {
        didSet { notifyDataUpdated() }
    }
    
    @Published var tripleTapGestureActionLeft: TripleTapGestureActions = .NO_EXTRA_ACTION {
        didSet { notifyDataUpdated() }
    }
    
    @Published var tripleTapGestureActionRight: TripleTapGestureActions = .NO_EXTRA_ACTION {
        didSet { notifyDataUpdated() }
    }
    
    @Published var tapAndHoldGestureActionLeft: TapAndHoldGestureActions = .NO_EXTRA_ACTION {
        didSet { notifyDataUpdated() }
    }
    @Published var tapAndHoldGestureActionRight: TapAndHoldGestureActions = .NO_EXTRA_ACTION {
        didSet { notifyDataUpdated() }
    }

    @Published var doubleTapGestureActionLeft: DoubleTapGestureActions = .PLAY_PAUSE {
        didSet { notifyDataUpdated() }
    }
    @Published var doubleTapGestureActionRight: DoubleTapGestureActions = .PLAY_PAUSE {
        didSet { notifyDataUpdated() }
    }

    @Published var doubleTapAndHoldGestureActionLeft: DoubleTapAndHoldGestureActions = .NO_EXTRA_ACTION {
        didSet { notifyDataUpdated() }
    }
    @Published var doubleTapAndHoldGestureActionRight: DoubleTapAndHoldGestureActions = .NO_EXTRA_ACTION {
        didSet { notifyDataUpdated() }
    }

    // Custom EQ
    @Published var isAdvancedEQEnabled: Bool = false {
        didSet { notifyDataUpdated() }
    }
    @Published var customEQBass: Float = 0.0 {
        didSet { notifyDataUpdated() }
    }
    @Published var customEQMid: Float = 0.0 {
        didSet { notifyDataUpdated() }
    }
    @Published var customEQTreble: Float = 0.0 {
        didSet { notifyDataUpdated() }
    }

    // Enhanced Bass
    @Published var isEnhancedBassEnabled: Bool = false {
        didSet { notifyDataUpdated() }
    }
    @Published var enhancedBassLevel: Int = 0 {
        didSet { notifyDataUpdated() }
    }

    // Personalized ANC
    @Published var isPersonalizedANCEnabled: Bool = false {
        didSet { notifyDataUpdated() }
    }

    // Case LED Colors (5 LEDs, each [R, G, B])
    @Published var caseLEDColors: [[UInt8]] = Array(repeating: [0xFF, 0x00, 0x00], count: 5) {
        didSet { notifyDataUpdated() }
    }

    // Connection History
    @Published var lastConnected: Date? = nil {
        didSet { notifyDataUpdated() }
    }

    init(bluetoothDetails: BluetoothDeviceEntity) {
        self.bluetoothDetails = bluetoothDetails
        self.name = bluetoothDetails.name
    }
    
    private func notifyDataUpdated() {
        NotificationCenter.default.post(name: Notification.Name(DataNotifications.DATA_UPDATED.rawValue), object: self, userInfo: nil)
    }
    
    func printValues() {
        let log = NXLogger(category: .device)
        log.debug("Device: \(name), serial=\(serial), codename=\(codename), fw=\(firmware), sku=\(sku)")
        log.debug("Battery L:\(leftBattery)% R:\(rightBattery)% C:\(caseBattery)%")
        log.debug("ANC=\(anc), EQ=\(listeningMode), latency=\(isLowLatencyOn), inEar=\(isInEarDetectionOn)")
    }
}
