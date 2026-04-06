//
//  Repository.swift
//  BluetoothTest
//
//  Created by Daniel on 2025/2/13.
//

import Foundation

protocol NothingService {
    
    func ringBuds()

    func stopRingingBuds()

    func ringBud(device: DeviceType)

    func stopRingingBud(device: DeviceType)
    
    func switchANC(mode: ANC)
    
    func switchEQ(mode: EQProfiles)
    
    func fetchData()
    
    func discoverNothing()
    
    func stopNothingDiscovery()
    
    func connectToNothing(device: BluetoothDeviceEntity)
    
    func connectedNothingDevice() -> BluetoothDeviceEntity?

    func isNothingConnected() -> Bool
    
    func switchLowLatency(mode: Bool)
    
    func switchInEarDetection(mode: Bool)
    
    func switchGesture(device: DeviceType, gesture: GestureType, action: UInt8)

    func disconnect()

    func switchCustomEQ(bass: Float, mid: Float, treble: Float)

    func setAdvancedEQ(enabled: Bool)

    func switchEnhancedBass(enabled: Bool, level: Int)

    func switchPersonalizedANC(enabled: Bool)

    func launchEarTipTest()

    func setCaseLEDColor(colors: [[UInt8]])
    
}
