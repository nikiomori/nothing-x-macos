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

        // Register on the next runloop tick: for already-connected devices the
        // callback fires immediately, and during init the service singletons
        // haven't subscribed to the notification yet — the event would be lost
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.systemConnectNotification = IOBluetoothDevice.register(forConnectNotifications: self, selector: #selector(self.systemDeviceConnected(_:device:)))
        }
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

    // Lets the service layer distinguish a sleep-time channel close from a
    // device switch or a transient drop
    private(set) var isPreparingForSleep = false

    private func handleSystemWillSleep() {
        isPreparingForSleep = true
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
        isPreparingForSleep = false
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

    // Whether macOS currently holds a baseband connection to this address,
    // regardless of the app's own connection state
    func isSystemConnected(address: String) -> Bool {
        return IOBluetoothDevice(addressString: address)?.isConnected() ?? false
    }

    // Earbuds advertise the "Wearable Headset" minor class (0x240404), but
    // over-ear devices like Headphone (1) advertise "Headphones" (0x240418),
    // so an exact class match misses them. Accept any Audio/Video device
    // whose name identifies it as a Nothing/CMF product.
    private func isNothingAudioDevice(_ device: IOBluetoothDevice, exactClass: UInt32) -> Bool {
        let cod = UInt32(device.classOfDevice)
        if cod == exactClass { return true }

        let hasAudioService = (cod & 0x200000) != 0
        let isAudioVideoMajor = ((cod >> 8) & 0x1F) == 0x04
        guard hasAudioService && isAudioVideoMajor else { return false }

        return codenameFromDeviceName(name: device.name ?? "") != .UNKNOWN
    }

    func getPaired(withClass: Int) -> [BluetoothDeviceEntity] {
        return IOBluetoothDevice.pairedDevices()
            .compactMap { $0 as? IOBluetoothDevice } // Safely unwrap and cast to IOBluetoothDevice
            .filter { self.isNothingAudioDevice($0, exactClass: UInt32(withClass)) }
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
            // Names are needed to recognize devices that don't match the exact
            // device class (e.g. Headphone (1))
            deviceInquiry?.updateNewDeviceNames = true
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

        if let targetClass = deviceClass, isNothingAudioDevice(device, exactClass: targetClass) {

            let bluetoothDevice = BluetoothDeviceEntity(name: device.name, mac: device.addressString, channelId: 15, isPaired: false, isConnected: false)

            NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.FOUND.rawValue), object: bluetoothDevice)
        }

    }

    func deviceInquiryDeviceNameUpdated(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!, devicesRemaining: UInt32) {

        // Devices recognized by name only can't match in deviceInquiryDeviceFound
        // when the name arrives later; exact-class matches were already posted there
        guard let targetClass = deviceClass, UInt32(device.classOfDevice) != targetClass else { return }

        if isNothingAudioDevice(device, exactClass: targetClass) {
            let bluetoothDevice = BluetoothDeviceEntity(name: device.name, mac: device.addressString, channelId: 15, isPaired: false, isConnected: false)

            NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.FOUND.rawValue), object: bluetoothDevice)
        }

    }
    
    
    
    // The Nothing/CMF control service, same UUID Gadgetbridge connects to.
    // The RFCOMM channel it lives on is not fixed across products (earbuds
    // use 15), so the channel is resolved from this record via SDP.
    private static let nothingControlServiceUUID: IOBluetoothSDPUUID = {
        var bytes: [UInt8] = [0xae, 0xac, 0x4a, 0x03, 0xdf, 0xf5, 0x49, 0x8f,
                              0x84, 0x3a, 0x34, 0x48, 0x7c, 0xf1, 0x33, 0xeb]
        return IOBluetoothSDPUUID(bytes: &bytes, length: bytes.count)
    }()

    private var pendingSDPResolve: ((UInt8) -> Void)?
    private var sdpFallbackChannel: UInt8 = 15

    func connectToDevice(address: String, channelID: UInt8) {


        stopDeviceInquiry()

        DispatchQueue.global(qos: .userInitiated).async {
                self.log.info("Connecting to device \(address)")

                guard !self.isConnecting else {
                    self.log.info("Connection attempt already in progress, skipping")
                    return
                }
                self.isConnecting = true

                // Already connected with an open RFCOMM channel — nothing to do.
                // The baseband link alone is not enough: after sleep the device can
                // still report isConnected() while the RFCOMM channel is gone.
                if (self.device?.isConnected() ?? false) && self.channel != nil {
                    self.isConnecting = false
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.OPENED_RFCOMM_CHANNEL.rawValue), object: nil)
                    }
                    return
                }

                guard let device = IOBluetoothDevice(addressString: address) else {
                    self.log.error("Invalid device address: \(address)")
                    self.isConnecting = false
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.FAILED_TO_CONNECT.rawValue), object: nil)
                    }
                    return
                }
                self.device = device

                // Open the baseband link only when macOS doesn't hold one already —
                // opening a fresh connection over an established link can fail
                if !device.isConnected() {
                    var resultConnection = device.openConnection()

                    // A just-stopped inquiry blocks new connections for a moment,
                    // so give it a couple of retries before giving up
                    var attempts = 0
                    while resultConnection != kIOReturnSuccess && attempts < 2 {
                        Thread.sleep(forTimeInterval: 1.0)
                        resultConnection = device.openConnection()
                        attempts += 1
                    }

                    guard resultConnection == kIOReturnSuccess else {
                        self.log.error("Failed to connect to device, IOReturn: \(String(format: "0x%08x", resultConnection))")
                        self.isConnecting = false
                        DispatchQueue.main.async {
                            self.device = nil
                            NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.FAILED_TO_CONNECT.rawValue), object: nil)
                        }
                        return
                    }
                } else {
                    self.log.info("Device already connected at system level, skipping openConnection")
                }

                self.log.info("Connected to device")
                let bluetoothDevice = BluetoothDeviceEntity(name: device.name, mac: address, channelId: channelID, isPaired: true, isConnected: true)

                // Notify on the main thread
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.CONNECTED.rawValue), object: bluetoothDevice)

                }

                // Resolve the control-service channel, then open RFCOMM on it
                self.resolveControlChannel(device: device, fallback: channelID) { resolvedChannel in

                    if resolvedChannel != channelID {
                        self.log.info("Control service resolved to RFCOMM channel \(resolvedChannel)")
                    }

                    let resultRFCOMM = device.openRFCOMMChannelAsync(&self.channel, withChannelID: resolvedChannel, delegate: self)
                    self.isConnecting = false

                    if resultRFCOMM == kIOReturnSuccess {
                        self.log.info("Opened RFCOMM channel \(resolvedChannel)")
                        self.lastConnectedAddress = address
                        self.lastConnectedChannelID = resolvedChannel
                        self.reconnectAfterWake = false
                        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.OPENED_RFCOMM_CHANNEL.rawValue), object: nil)
                    } else {
                        self.log.error("Failed to open RFCOMM channel \(resolvedChannel), IOReturn: \(String(format: "0x%08x", resultRFCOMM))")
                        self.device = nil
                        NotificationCenter.default.post(name: Notification.Name(BluetoothNotifications.FAILED_RFCOMM_CHANNEL.rawValue), object: nil)
                    }
                }
            }

    }

    // Finds the RFCOMM channel of the Nothing control service via SDP.
    // Uses cached service records when available, falls back to the given
    // channel when the record is missing or the query fails.
    private func resolveControlChannel(device: IOBluetoothDevice, fallback: UInt8, completion: @escaping (UInt8) -> Void) {

        if let channel = controlChannel(from: device) {
            DispatchQueue.main.async { completion(channel) }
            return
        }

        DispatchQueue.main.async {
            self.pendingSDPResolve = completion
            self.sdpFallbackChannel = fallback

            if device.performSDPQuery(self) != kIOReturnSuccess {
                self.pendingSDPResolve = nil
                completion(fallback)
                return
            }

            // Safety net: never leave the connection flow hanging on SDP
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                guard let pending = self.pendingSDPResolve else { return }
                self.pendingSDPResolve = nil
                self.log.warning("SDP query timed out, using fallback channel \(fallback)")
                pending(fallback)
            }
        }
    }

    private func controlChannel(from device: IOBluetoothDevice) -> UInt8? {
        guard let record = device.getServiceRecord(for: BluetoothManager.nothingControlServiceUUID) else { return nil }
        var channel: BluetoothRFCOMMChannelID = 0
        guard record.getRFCOMMChannelID(&channel) == kIOReturnSuccess else { return nil }
        return channel
    }

    @objc func sdpQueryComplete(_ device: IOBluetoothDevice!, status: IOReturn) {
        guard let completion = pendingSDPResolve else { return }
        pendingSDPResolve = nil

        var channel: UInt8? = nil
        if status == kIOReturnSuccess, let device = device {
            channel = controlChannel(from: device)
        }
        if channel == nil {
            log.info("Control service not found via SDP, using fallback channel \(sdpFallbackChannel)")
        }
        completion(channel ?? sdpFallbackChannel)
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
