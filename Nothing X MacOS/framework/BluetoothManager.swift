//
//  BluetoothManager.swift
//  BluetoothTest
//
//  Created by Daniel on 2025/2/13.
//

import Foundation
import AppKit
import IOBluetooth
import CoreBluetooth


class BluetoothManager: NSObject, IOBluetoothDeviceInquiryDelegate, IOBluetoothRFCOMMChannelDelegate, CBCentralManagerDelegate {

    static let shared = BluetoothManager()

    private let log = NXLogger(category: .bluetooth)
    private var device: IOBluetoothDevice?
    private var channel: IOBluetoothRFCOMMChannel?
    private var deviceInquiry: IOBluetoothDeviceInquiry?
    private var connectedDevice: IOBluetoothDevice?
    private var rfcommChannel: IOBluetoothRFCOMMChannel?
    private var centralManager: CBCentralManager!
    private var deviceClass: UInt32? = nil
    private var bluetoothState: BluetoothStates = .OFF
    private var lastConnectedAddress: String? = nil
    private var lastConnectedChannelID: UInt8 = 15
    private var reconnectAfterWake = false
    private var isConnecting = false
    private var systemConnectNotification: IOBluetoothUserNotification?



    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)

        // Reconnect state is lost when the Mac sleeps: the RFCOMM channel dies
        // but no delegate callback fires until wake, so track sleep explicitly.
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleSystemWillSleep()
        }
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.handleSystemDidWake()
        }

        systemConnectNotification = IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(systemDeviceConnected(_:device:)))
    }

    @objc private func systemDeviceConnected(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        guard let address = device.addressString else { return }
        log.debug("System-level device connection: \(device.name ?? address)")

        let bluetoothDevice = BluetoothDeviceEntity(
            name: device.name ?? "Unknown",
            mac: address,
            channelId: lastConnectedChannelID,
            isPaired: device.isPaired(),
            isConnected: true
        )
        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.SYSTEM_DEVICE_CONNECTED.rawValue), object: bluetoothDevice)
    }

    private func handleSystemWillSleep() {
        guard channel != nil, let address = device?.addressString else { return }
        log.info("System is going to sleep, closing connection to \(address)")
        reconnectAfterWake = true
        channel?.close()
        channel = nil
        if let device = self.device, device.isConnected() {
            device.closeConnection()
        }
        device = nil
    }

    private func handleSystemDidWake() {
        guard reconnectAfterWake, let address = lastConnectedAddress else { return }
        log.info("System woke up, waiting for \(address) to come back")
        attemptWakeReconnect(address: address, attemptsLeft: 10)
    }

    // The Bluetooth stack and the headphones both need a few seconds after wake,
    // so poll the system connection state instead of connecting blindly.
    // Devices that re-associate later are caught by the connect notification.
    private func attemptWakeReconnect(address: String, attemptsLeft: Int) {
        guard attemptsLeft > 0 else {
            reconnectAfterWake = false
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self, self.reconnectAfterWake, self.channel == nil else { return }
            if let device = IOBluetoothDevice(addressString: address), device.isConnected() {
                self.reconnectAfterWake = false
                self.connectToDevice(address: address, channelID: self.lastConnectedChannelID)
            } else {
                self.attemptWakeReconnect(address: address, attemptsLeft: attemptsLeft - 1)
            }
        }
    }
    
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bluetoothState = .ON
            log.info("Bluetooth is ON")
            NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.BLUETOOTH_ON.rawValue), object: nil)

        case .poweredOff:
            bluetoothState = .OFF
            log.info("Bluetooth is OFF")
            NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.BLUETOOTH_OFF.rawValue), object: nil)
        case .resetting:
            log.warning("Bluetooth is resetting")
        case .unauthorized:
            log.error("Bluetooth is unauthorized")
        case .unsupported:
            log.error("Bluetooth is unsupported")
        case .unknown:
            log.warning("Bluetooth state is unknown")
        @unknown default:
            log.warning("Unknown Bluetooth state")
        }
    }
    
    func isBluetoothEnabled() -> Bool {
        return centralManager.state == .poweredOn
    }
    
    func isDeviceConnected() -> Bool {
        
        return device?.isConnected() ?? false
    }

    func getPaired(withClass: Int) -> [BluetoothDeviceEntity] {
        return IOBluetoothDevice.pairedDevices()
            .compactMap { $0 as? IOBluetoothDevice } // Safely unwrap and cast to IOBluetoothDevice
            .filter { $0.classOfDevice == withClass } // Filter by the specified device class
            .map { device in
                // Create an instance of BluetoothDevice
                BluetoothDeviceEntity(
                    name: device.name ?? "Unknown",
                    mac: device.addressString,
                    channelId: 15, // Set channelId as needed; using 0 as a placeholder
                    isPaired: true, // Assuming these devices are paired
                    isConnected: device.isConnected()
                )
            }
    }

        
    func startDeviceInquiry(withClass: UInt32) {
        if deviceInquiry == nil {
            
            deviceInquiry = IOBluetoothDeviceInquiry(delegate: self)
            deviceInquiry?.start()
            deviceClass = withClass
            log.info("Starting device inquiry")
            NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.SEARCHING.rawValue), object: nil)
        }
    }
    
    
    func deviceInquiryComplete(_ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
        deviceInquiry = nil
        log.info("Device inquiry complete")
        deviceClass = nil
        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.SEARCHING_COMPLETE.rawValue), object: nil)
    }
    
    func deviceInquiryDeviceFound(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
        
        log.debug("Device found during inquiry")
    
        if (device.classOfDevice == deviceClass) {
            
            let bluetoothDevice = BluetoothDeviceEntity(name: device.name, mac: device.addressString, channelId: 15, isPaired: false, isConnected: false)
           
            NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.FOUND.rawValue), object: bluetoothDevice)
        }
        
    }
    
    
    
    func connectToDevice(address: String, channelID: UInt8) {


        stopDeviceInquiry()

        DispatchQueue.global(qos: .userInitiated).async {
                self.log.info("Connecting to device \(address)")

                guard !self.isConnecting else {
                    self.log.info("Connection attempt already in progress, skipping")
                    return
                }
                self.isConnecting = true
                defer { self.isConnecting = false }

                // Already connected with an open RFCOMM channel — nothing to do.
                // The baseband link alone is not enough: after sleep the device can
                // still report isConnected() while the RFCOMM channel is gone.
                if (self.device?.isConnected() ?? false) && self.channel != nil {
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.OPENED_RFCOMM_CHANNEL.rawValue), object: nil)
                    }
                    return
                }

                self.device = IOBluetoothDevice(addressString: address)

                // Open a connection to the device (no-op if the link is already up)
                let resultConnection = self.device?.openConnection()
                if resultConnection == kIOReturnSuccess {
                    self.log.info("Connected to device")
                    let bluetoothDevice = BluetoothDeviceEntity(name: self.device!.name, mac: address, channelId: channelID, isPaired: true, isConnected: true)

                    // Notify on the main thread
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.CONNECTED.rawValue), object: bluetoothDevice)

                    }
                } else {
                    self.log.error("Failed to connect to device")
                    DispatchQueue.main.async {
                        self.device = nil
                        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.FAILED_TO_CONNECT.rawValue), object: nil)

                    }
                    return
                }

                // Open an RFCOMM channel to the device

                let resultRFCOMM = self.device?.openRFCOMMChannelAsync(&self.channel, withChannelID: channelID, delegate: self)

                if resultRFCOMM == kIOReturnSuccess {
                    self.log.info("Opened RFCOMM channel")
                    self.lastConnectedAddress = address
                    self.lastConnectedChannelID = channelID
                    self.reconnectAfterWake = false
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.OPENED_RFCOMM_CHANNEL.rawValue), object: nil)
                    }
                } else {
                    self.log.error("Failed to open RFCOMM channel")
                    self.device = nil
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.FAILED_RFCOMM_CHANNEL.rawValue), object: nil)
                    }
                }
            }

    }
    
    func send(data: UnsafeMutableRawPointer!, length: UInt16) {
        channel?.writeSync(data, length: length)
    }
    
    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        
        // Create Data object from the received bytes
        let data = Data(bytes: dataPointer, count: dataLength)
        
        // Convert Data to [UInt8] (byte array)
        let rawData = [UInt8](data)
        
        NotificationCenter.default.post(name: Notification.Name(DataNotifications.DATA_RECEIVED.rawValue), object: nil, userInfo: ["data": rawData])
        
    }
    
    
    func rfcommChannelClosed(_ channel: IOBluetoothRFCOMMChannel) {
        log.info("RFCOMM channel closed")
        self.device = nil
        self.channel = nil
        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.CLOSED_RFCOMM_CHANNEL.rawValue), object: nil)
    }

    func disconnectDevice() {
        // Explicit disconnect — drop any pending auto-reconnect intent
        lastConnectedAddress = nil
        reconnectAfterWake = false

        if let channel = self.channel {
            channel.close() // This should trigger rfcommChannelClosed delegate method
            self.channel = nil // Ensure it's set to nil immediately
        }
        
        // 2. Close the Connection to the Device
        if let device = self.device, device.isConnected() {
            device.closeConnection()
        }
        self.device = nil // Ensure it's set to nil immediately
        
        // 3. Stop Device Inquiry (if running) - important to prevent further connections
        if let inquiry = self.deviceInquiry {
            inquiry.stop()
            self.deviceInquiry = nil
        }
        
        // 4. Clear any stored device information
        connectedDevice = nil
        rfcommChannel = nil
        
        // 5. Post a Notification (optional, but good practice)
        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.DISCONNECTED.rawValue), object: nil)
        
        log.info("Disconnected from device")
    }
    
    func stopDeviceInquiry() {
        deviceInquiry?.stop()
    }

   
}
