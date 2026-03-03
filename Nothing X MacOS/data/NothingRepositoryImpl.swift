//
//  NothingRepositoryImpl.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/2/25.
//

import Foundation

class NothingRepositoryImpl : NothingRepository {
    
    static let shared = NothingRepositoryImpl()
    
    private init() {
        
    }
    
    private let encoder = JsonEncoder.shared
    
    
    func getSaved() -> [NothingDeviceEntity] {
        let entities = encoder.getAllDevices().toEntities()
        return Array(entities.sorted {
            ($0.lastConnected ?? .distantPast) > ($1.lastConnected ?? .distantPast)
        }.prefix(5))
    }
    
    func save(device: NothingDeviceEntity) {
        encoder.addOrUpdateDevice(device.toDTO())
    }
    
    func delete(device: NothingDeviceEntity) {
        encoder.deleteDevice(mac: device.bluetoothDetails.mac)
        NotificationCenter.default.post(name: Notification.Name(RepositoryNotifications.CONFIGURATION_DELETED.rawValue), object: device.bluetoothDetails)
    }
    
    func delete(mac: String) {
        encoder.deleteDevice(mac: mac)
        
        NotificationCenter.default.post(name: Notification.Name(RepositoryNotifications.CONFIGURATION_DELETED.rawValue), object: mac)
    }
    
    func contains(mac: String) -> Bool {
        encoder.getAllDevices().contains { $0.bluetoothDetails.mac == mac }
    }
    
}
