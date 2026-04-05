//
//  NothingController.swift
//  BluetoothTest
//
//  Created by Daniel on 2025/2/13.
//
import Combine
import Foundation


// Define a custom error type
private enum DeviceError: Error {
    case responseError(String)
    case timeoutError(String)
}

// Define a structure to represent a request
private struct Request {
    let id: UUID = UUID()
    let command: Commands
    let operationID: UInt8
    let payload: [UInt8]
    let completion: (Result<Void, Error>) -> Void
    let requestTimeout: TimeInterval
    let responseTimeout: TimeInterval
    var retryCount: Int = 0 // Track the number of retries
    var maxRetries: Int = 3 // Max retries for this request (default matches global)
}

class NothingServiceImpl : NothingService {

    static let shared = NothingServiceImpl()

    private let log = NXLogger(category: .nothingService)
    private var cancellables = Set<AnyCancellable>()
    private let bluetoothManager = BluetoothManager.shared
    private var currentRequest: Request? = nil
    
    private let classOfNothing:UInt32 = 2360324
    // A queue to hold requests
    private var requestQueue: [Request] = []
    // A semaphore to control access to the queue
    private let queueSemaphore = DispatchSemaphore(value: 1)
    private let maxRetries = 3
    // A flag to indicate if a request is currently being processed
    private var isProcessing = false

    private var nothingDevice: NothingDeviceFDTO? = nil
    
    private init() {
        
        NotificationCenter.default.addObserver(forName: Notification.Name(BluetoothNotifications.CONNECTED.rawValue), object: nil, queue: .main) { notification in
            // Handle the notification here
            if let device = notification.object as? BluetoothDeviceEntity {

                    self.nothingDevice = NothingDeviceFDTO(bluetoothDetails: device)

                    // Restore codename and name from saved configuration if available
                    let savedDevices = NothingRepositoryImpl.shared.getSaved()
                    if let saved = savedDevices.first(where: { $0.bluetoothDetails.mac == device.mac }) {
                        if saved.codename != .UNKNOWN {
                            self.nothingDevice?.codename = saved.codename
                        }
                        if !saved.name.isEmpty {
                            self.nothingDevice?.name = saved.name
                        }
                    }

                    // Fallback: detect codename from device name if still unknown
                    if self.nothingDevice?.codename == .UNKNOWN {
                        let detected = codenameFromDeviceName(name: device.name)
                        if detected != .UNKNOWN {
                            self.nothingDevice?.codename = detected
                            self.log.info("Codename detected from device name: \(detected)")
                        }
                    }

                    self.log.info("Device object created: \(self.nothingDevice?.name ?? "unknown")")

                    NotificationCenter.default.post(name: Notification.Name(DataNotifications.CONNECTED.rawValue), object: self.nothingDevice)

            }
        }
     

        NotificationCenter.default.addObserver(forName: Notification.Name(DataNotifications.DATA_RECEIVED.rawValue), object: nil, queue: .main) { notification in
            // Handle the notification here
            if let userInfo = notification.userInfo, let data = userInfo["data"] as? [UInt8] {
                self.log.debug("Data received: \(data)")
                self.onDataReceived(rawData: data)
            }
        }
        
        
        
        NotificationCenter.default.addObserver(forName: Notification.Name(DataNotifications.DATA_UPDATED.rawValue), object: nil, queue: .main) { notification in
            
            if let deviceFramework = notification.object as? NothingDeviceFDTO {
                self.log.debug("Device data updated in repository")
                
                let nothingDevice = NothingDeviceFDTO.toEntity(deviceFramework)
                
                NotificationCenter.default.post(name: Notification.Name(DataNotifications.REPOSITORY_DATA_UPDATED.rawValue), object: nothingDevice, userInfo: nil)
            }
        }
        
        
        NotificationCenter.default.addObserver(forName: Notification.Name(BluetoothNotifications.FOUND.rawValue), object: nil, queue: .main) { notification in
            
           self.log.info("Found device")
            if let bluetoothDevice = notification.object as? BluetoothDeviceEntity {
                
                NotificationCenter.default.post(name: Notification.Name(DataNotifications.FOUND.rawValue), object: bluetoothDevice, userInfo: nil)
                
            }
        }
        
    }
    

    // MARK: - Custom EQ

    func switchCustomEQ(bass: Float, mid: Float, treble: Float) {
        let payload = buildCustomEQPayload(bass: bass, mid: mid, treble: treble)

        addRequest(command: Commands.SET_CUSTOM_EQ, operationID: Commands.SET_CUSTOM_EQ.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, payload: payload) { result in
            switch result {
            case .success:
                self.log.info("Successfully set custom EQ")
                self.nothingDevice?.customEQBass = bass
                self.nothingDevice?.customEQMid = mid
                self.nothingDevice?.customEQTreble = treble
            case .failure(let error):
                self.log.error("Failed to set custom EQ: \(error.localizedDescription)")
            }
        }
    }

    func setAdvancedEQ(enabled: Bool) {
        let payload: [UInt8] = [enabled ? 0x01 : 0x00, 0x00]

        addRequest(command: Commands.SET_ADVANCED_EQ, operationID: Commands.SET_ADVANCED_EQ.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, payload: payload) { result in
            switch result {
            case .success:
                self.log.info("Successfully set advanced EQ: \(enabled)")
                self.nothingDevice?.isAdvancedEQEnabled = enabled
            case .failure(let error):
                self.log.error("Failed to set advanced EQ: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Enhanced Bass

    func switchEnhancedBass(enabled: Bool, level: Int) {
        let clampedLevel = min(max(level * 2, 0), 255)
        let payload: [UInt8] = [enabled ? 0x01 : 0x00, UInt8(clampedLevel)]

        addRequest(command: Commands.SET_ENHANCED_BASS, operationID: Commands.SET_ENHANCED_BASS.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, payload: payload) { result in
            switch result {
            case .success:
                self.log.info("Successfully set enhanced bass: \(enabled), level: \(level)")
                self.nothingDevice?.isEnhancedBassEnabled = enabled
                self.nothingDevice?.enhancedBassLevel = level
            case .failure(let error):
                self.log.error("Failed to set enhanced bass: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Personalized ANC

    func switchPersonalizedANC(enabled: Bool) {
        let payload: [UInt8] = [enabled ? 0x01 : 0x00]

        addRequest(command: Commands.SET_PERSONALIZED_ANC, operationID: Commands.SET_PERSONALIZED_ANC.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, payload: payload) { result in
            switch result {
            case .success:
                self.log.info("Successfully set personalized ANC: \(enabled)")
                self.nothingDevice?.isPersonalizedANCEnabled = enabled
            case .failure(let error):
                self.log.error("Failed to set personalized ANC: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Ear Tip Fit Test

    func launchEarTipTest() {
        let payload: [UInt8] = [0x01]

        addRequest(command: Commands.SET_EAR_TIP_TEST, operationID: Commands.SET_EAR_TIP_TEST.firstEightBits, requestTimeout: 1000, responseTimeout: 5000, payload: payload) { result in
            switch result {
            case .success:
                self.log.info("Ear tip test launched")
            case .failure(let error):
                self.log.error("Failed to launch ear tip test: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Case LED Color

    func setCaseLEDColor(colors: [[UInt8]]) {
        var payload: [UInt8] = [0x05]
        for (index, color) in colors.prefix(5).enumerated() {
            payload.append(UInt8(index + 1))
            payload.append(contentsOf: color.prefix(3))
        }

        addRequest(command: Commands.SET_CASE_LED, operationID: Commands.SET_CASE_LED.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, payload: payload) { result in
            switch result {
            case .success:
                self.log.info("Successfully set case LED colors")
                self.nothingDevice?.caseLEDColors = colors
            case .failure(let error):
                self.log.error("Failed to set case LED colors: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Gestures

    func switchGesture(device: DeviceType, gesture: GestureType, action: UInt8) {
        let payload: [UInt8] = [0x01, device.rawValue, 0x01, gesture.rawValue, action]
        
        addRequest(command: Commands.SET_GESTURE, operationID: Commands.SET_GESTURE.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, payload: payload) {
            
            result in
            switch result {
            case .success:
                self.log.info("Successfully switched gesture settings")
                self.updateGestureInNothing(deviceType: device, gestureType: gesture, action: action)

            case .failure(let error):
                self.log.error("Failed to switch gesture settings: \(error.localizedDescription)")
                
            }
        }
    }
    
    func stopNothingDiscovery() {
        bluetoothManager.stopDeviceInquiry()
    }
    
    func switchLowLatency(mode: Bool) {
        
        var array: [UInt8] = [0x02, 0x00]
        if (mode) {
            array[0] = 0x01
        }
        
        addRequest(command: Commands.SET_LATENCY, operationID: Commands.SET_LATENCY.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, payload: array) {
            result in
            switch result {
            case .success:
                self.log.info("Successfully changed latency settings")
                self.nothingDevice?.isLowLatencyOn = mode
            case .failure(let error):
                self.log.error("Failed to change latency settings: \(error.localizedDescription)")
                
            }
        }
        
    }
    
    func switchInEarDetection(mode: Bool) {
        var array: [UInt8] = [0x01, 0x01, 0x00]
        
        if (mode) {
            array[2] = 0x01
        }
        
        addRequest(command: Commands.SET_IN_EAR_STATUS, operationID: Commands.SET_IN_EAR_STATUS.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, payload: array) {
            result in
            switch result {
            case .success:
                self.log.info("Successfully switched in-ear detection")
                self.nothingDevice?.isInEarDetectionOn = mode
            case .failure(let error):
                self.log.error("Failed to switch in-ear detection: \(error.localizedDescription)")

            }
        }
    }

    func ringBuds() {
        setRingBuds(device: nil, doRing: true)
    }

    func stopRingingBuds() {
        setRingBuds(device: nil, doRing: false)
    }

    func ringBud(device: DeviceType) {
        setRingBuds(device: device, doRing: true)
    }

    func stopRingingBud(device: DeviceType) {
        setRingBuds(device: device, doRing: false)
    }
    
    func switchANC(mode: ANC) {
        // Initialize the byte array
        var byteArray: [UInt8] = [0x01, 0x01, 0x00]
        
        byteArray[1] = mode.rawValue
        
        
        log.debug("ANC payload: \(byteArray)")
        
        // Call the send function with the specified parameters
        
        
        addRequest(command: Commands.SET_ANC, operationID: Commands.SET_ANC.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, payload: byteArray) {
            result in
            switch result {
            case .success:
                self.log.info("Successfully changed ANC settings")
                self.nothingDevice?.anc = mode
            case .failure(let error):
                self.log.error("Failed to change ANC settings: \(error.localizedDescription)")
                
            }
        }
        
        
    }
    
    func switchEQ(mode: EQProfiles) {
        var byteArray: [UInt8] = [0x00, 0x00]
        
        byteArray[0] = mode.rawValue
        if (nothingDevice == nil) {
            log.warning("Nothing device is nil when switching EQ")
        }
        
        
        addRequest(command: Commands.SET_EQ, operationID: Commands.SET_EQ.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, payload: byteArray) { result in  // Capture self weakly
                
                switch result {
                case .success:
                    self.log.info("Successfully switched EQ mode")
                    self.nothingDevice?.listeningMode = mode
                case .failure(let error):
                    self.log.error("Failed to switch EQ: \(error.localizedDescription)")
                }
            }
        
    }
    
    func connectToNothing(device: BluetoothDeviceEntity) {
        bluetoothManager.connectToDevice(address: device.mac, channelID: device.channelId)
    }
    
    func disconnect() {
        bluetoothManager.disconnectDevice()
        self.nothingDevice = nil
    }
        
    func discoverNothing() {
        
        let pairedDevices = bluetoothManager.getPaired(withClass: Int(classOfNothing))
        
        let connectedPaired = pairedDevices.filter({ $0.isConnected })
        
        for c in connectedPaired {
            NotificationCenter.default.post(name: Notification.Name(DataNotifications.FOUND.rawValue), object: c, userInfo: nil)
        }
        
        bluetoothManager.startDeviceInquiry(withClass: classOfNothing)
        
    }
    
    func isNothingConnected() -> BluetoothDeviceEntity? {
        return nothingDevice?.bluetoothDetails
    }
    
    func isNothingConnected() -> Bool {
        return bluetoothManager.isDeviceConnected()
    }
    
    func connectToNothing(address: String) {
        bluetoothManager.connectToDevice(address: address, channelID: 15)
    }
    
    func fetchData() {
        
        log.info("Fetching data...")

        #warning("there is a change that device gets disconnected during transfer but it is low since it takes less than a second to fetch the data will fix it in the future")
        log.debug("Connected: \(isNothingConnected()), device exists: \(nothingDevice != nil)")
        
        if isNothingConnected() && nothingDevice != nil {

            log.debug("Adding fetch requests to queue")

            // Small delay to let the device settle after RFCOMM connection
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {

                self.addRequest(command: Commands.GET_FIRMWARE, operationID: Commands.GET_FIRMWARE.firstEightBits, requestTimeout: 1000, responseTimeout: 1000) {
                    result in
                    switch result {
                    case .success:
                        self.log.info("Fetched firmware")
                    case .failure(let error):
                        self.log.error("Failed to fetch firmware: \(error.localizedDescription)")

                    }
                }

                self.addRequest(command: Commands.GET_BATTERY, operationID: Commands.GET_BATTERY.firstEightBits, requestTimeout: 1000, responseTimeout: 1000) {
                    result in
                    switch result {
                    case .success:
                        self.log.info("Fetched battery settings")
                    case .failure(let error):
                        self.log.error("Failed to fetch battery: \(error.localizedDescription)")

                    }
                }

                self.addRequest(command: Commands.GET_ANC, operationID: Commands.GET_ANC.firstEightBits, requestTimeout: 1000, responseTimeout: 1000) {
                    result in
                    switch result {
                    case .success:
                        self.log.info("Fetched ANC settings")
                    case .failure(let error):
                        self.log.error("Failed to fetch ANC: \(error.localizedDescription)")

                    }
                }

                self.addRequest(command: Commands.GET_EQ, operationID: Commands.GET_EQ.firstEightBits, requestTimeout: 1000, responseTimeout: 1000) {
                    result in
                    switch result {
                    case .success:
                        self.log.info("Fetched EQ settings")
                    case .failure(let error):
                        self.log.error("Failed to fetch EQ: \(error.localizedDescription)")

                    }
                }

                self.addRequest(command: Commands.GET_LATENCY, operationID: Commands.GET_LATENCY.firstEightBits, requestTimeout: 1000, responseTimeout: 1000) {
                    result in
                    switch result {
                    case .success:
                        self.log.info("Fetched latency settings")
                    case .failure(let error):
                        self.log.error("Failed to fetch latency: \(error.localizedDescription)")

                    }
                }

                self.addRequest(command: Commands.GET_IN_EAR_STATUS, operationID: Commands.GET_IN_EAR_STATUS.firstEightBits, requestTimeout: 1000, responseTimeout: 1000) {
                    result in
                    switch result {
                    case .success:
                        self.log.info("Fetched in-ear status")
                    case .failure(let error):
                        self.log.error("Failed to fetch in-ear status: \(error.localizedDescription)")

                    }
                }

                self.addRequest(command: Commands.GET_GESTURES, operationID: Commands.GET_GESTURES.firstEightBits, requestTimeout: 1000, responseTimeout: 1000) {
                    result in
                    switch result {
                    case .success:
                        self.log.info("Fetched gestures")
                    case .failure(let error):
                        self.log.error("Failed to fetch gestures: \(error.localizedDescription)")

                    }
                }

                self.addRequest(command: Commands.GET_SERIAL_NUMBER, operationID: Commands.GET_SERIAL_NUMBER.firstEightBits, requestTimeout: 1000, responseTimeout: 1000) {
                    result in
                    switch result {
                    case .success:
                        self.log.info("Fetched serial number")
                    case .failure(let error):
                        self.log.error("Failed to fetch serial number: \(error.localizedDescription)")

                    }
                }

                // Fetch device-specific features after a small delay to allow codename detection
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    self.fetchDeviceSpecificData()
                }

            }

        }
        
    }

    
    private func fetchDeviceSpecificData() {
        guard let codename = nothingDevice?.codename else { return }
        let caps = DeviceCapabilities.capabilities(for: codename)

        // Device-specific GET commands use maxRetries: 0 to avoid blocking the queue
        // if the device doesn't respond to these optional commands
        if caps.supportsCustomEQ {
            addRequest(command: Commands.GET_ADVANCED_EQ, operationID: Commands.GET_ADVANCED_EQ.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, maxRetries: 0) { result in
                switch result {
                case .success:
                    self.log.info("Fetched advanced EQ status")
                case .failure(let error):
                    self.log.warning("Failed to fetch advanced EQ (device may not support GET): \(error.localizedDescription)")
                    self.restoreCachedCustomEQ()
                }
            }

            addRequest(command: Commands.GET_CUSTOM_EQ, operationID: Commands.GET_CUSTOM_EQ.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, maxRetries: 0) { result in
                switch result {
                case .success:
                    self.log.info("Fetched custom EQ values")
                case .failure(let error):
                    self.log.warning("Failed to fetch custom EQ (device may not support GET): \(error.localizedDescription)")
                    self.restoreCachedCustomEQ()
                }
            }
        }

        if caps.supportsEnhancedBass {
            addRequest(command: Commands.GET_ENHANCED_BASS, operationID: Commands.GET_ENHANCED_BASS.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, maxRetries: 0) { result in
                switch result {
                case .success:
                    self.log.info("Fetched enhanced bass status")
                case .failure(let error):
                    self.log.warning("Failed to fetch enhanced bass (device may not support GET): \(error.localizedDescription)")
                }
            }
        }

        if caps.supportsPersonalizedANC {
            addRequest(command: Commands.GET_PERSONALIZED_ANC, operationID: Commands.GET_PERSONALIZED_ANC.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, maxRetries: 0) { result in
                switch result {
                case .success:
                    self.log.info("Fetched personalized ANC status")
                case .failure(let error):
                    self.log.warning("Failed to fetch personalized ANC (device may not support GET): \(error.localizedDescription)")
                }
            }
        }

        if caps.supportsCaseLED {
            addRequest(command: Commands.GET_CASE_LED, operationID: Commands.GET_CASE_LED.firstEightBits, requestTimeout: 1000, responseTimeout: 1000, maxRetries: 0) { result in
                switch result {
                case .success:
                    self.log.info("Fetched case LED colors")
                case .failure(let error):
                    self.log.warning("Failed to fetch case LED (device may not support GET): \(error.localizedDescription)")
                }
            }
        }
    }

    #warning("low latency mode switch is not implemented")
    
    private func send(command: UInt16, operationID: UInt8, payload: [UInt8] = []) {
        var header: [UInt8] = [0x55, 0x60, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        header[7] = UInt8(operationID)
        log.debug("Operation ID: \(operationID)")
        
        // Convert command to bytes
        let commandBytes = withUnsafeBytes(of: command.bigEndian) { Array($0) }
        header[3] = commandBytes[0]
        header[4] = commandBytes[1]
        
        let payloadLength = UInt8(clamping: payload.count)
        header[5] = payloadLength
        
        // Append payload to header
        header.append(contentsOf: payload)
        
        // Calculate CRC
        let crc = CRC16.crc16(buffer: header)
        header.append(UInt8(crc & 0xFF)) // Append low byte
        header.append(UInt8((crc >> 8) & 0xFF))
        
        let hexString = header.map { String(format: "%02x", $0) }.joined()
        log.debug("Sending: \(hexString)")
        
        // Send the data
     
        bluetoothManager.send(data: &header, length: UInt16(header.count))
   
    }

    
    // Function to get the current request being processed
    private func getCurrentRequest() -> Request? {
        queueSemaphore.wait()
        defer { queueSemaphore.signal() }
        return requestQueue.first // Return the first request in the queue
    }
    
    // Function to process requests in the queue
    private func processNextRequest() {
        log.debug("Queue: processing next request")
        queueSemaphore.wait()

        guard !requestQueue.isEmpty else {
            log.debug("Queue: empty")
            isProcessing = false
            queueSemaphore.signal()
            return
        }
        
        // Get the next request from the queue
        var request = requestQueue.removeFirst()
        currentRequest = request
        log.debug("Queue: processing request \(request.operationID)")
        isProcessing = true
        queueSemaphore.signal()
        
        // Set a timeout for the request
        let requestID = request.id
        let requestTimeout = DispatchTime.now() + request.requestTimeout
        DispatchQueue.global().asyncAfter(deadline: requestTimeout) {
            // Only handle timeout if this request is still the current one
            // (stale timeouts from already-completed requests must be ignored)
            guard self.isProcessing, self.currentRequest?.id == requestID else { return }

            self.log.warning("Request \(request.command) timed out (attempt \(request.retryCount + 1)/\(request.maxRetries + 1))")
            // Increment the retry count
            request.retryCount += 1

            // Check if the retry count exceeds the maximum allowed
            if request.retryCount <= request.maxRetries {
                // Re-add the request to the queue
                self.queueSemaphore.wait()
                self.requestQueue.append(request) // Re-add the request
                self.queueSemaphore.signal()

                // Call the completion handler with a timeout error
                request.completion(.failure(DeviceError.timeoutError("Request timed out.")))
                self.isProcessing = false

                // Process the next request
                self.processNextRequest()
            } else {
                // Handle the case where the maximum retries have been reached
                self.log.error("Maximum retries reached for request \(request.command)")
                request.completion(.failure(DeviceError.timeoutError("Maximum retries reached.")))
                self.isProcessing = false

                // Process the next request
                self.processNextRequest()
            }
        }
        
        // Send the command and handle the response
        send(command: request.command.rawValue, operationID: request.operationID, payload: request.payload)
    }
    
    // Function to add a request to the queue
    private func addRequest(command: Commands, operationID: UInt8, requestTimeout: TimeInterval, responseTimeout: TimeInterval, payload: [UInt8] = [], maxRetries: Int? = nil, completion: @escaping (Result<Void, Error>) -> Void) {

        let requestTimeoutInSeconds = TimeInterval(requestTimeout) / 1000.0
        let responseTimeoutInSeconds = TimeInterval(responseTimeout) / 1000.0

        let retries = maxRetries ?? self.maxRetries
        let request = Request(command: command, operationID: operationID, payload: payload, completion: completion, requestTimeout: requestTimeoutInSeconds, responseTimeout: responseTimeoutInSeconds, maxRetries: retries)
        
        queueSemaphore.wait()
        requestQueue.append(request) // Append the request to the queue
        queueSemaphore.signal()
        
        // Start processing if not already processing
        if !isProcessing {
            processNextRequest()
        }
    }

    private func readBattery(hexString: [UInt8]) {

        let BATTERY_MASK: UInt8 = 127
        let RECHARGING_MASK: UInt8 = 128

        // Read the number of connected devices
        guard hexString.count > 8 else { return }
        let connectedDevices = Int(hexString[8])
        
        nothingDevice?.isCaseConnected = false
        nothingDevice?.isLeftConnected = false
        nothingDevice?.isRightConnected = false
        
        // Process each connected device
        for i in 0..<connectedDevices {
            let deviceIdIndex = 9 + (i * 2)
            let batteryDataIndex = 10 + (i * 2)
            guard batteryDataIndex < hexString.count else { break }
            let deviceId = hexString[deviceIdIndex]
            let batteryData = hexString[batteryDataIndex]
            let batteryLevel = Int(batteryData & BATTERY_MASK)
            let isCharging = (batteryData & RECHARGING_MASK) == RECHARGING_MASK
            
            switch deviceId {
            case 0x02: // Left device
                nothingDevice?.leftBattery = batteryLevel
                nothingDevice?.isLeftCharging = isCharging
                nothingDevice?.isLeftConnected = true
            case 0x03: // Right device
                nothingDevice?.rightBattery = batteryLevel
                nothingDevice?.isRightCharging = isCharging
                nothingDevice?.isRightConnected = true
            case 0x04: // Case device
                nothingDevice?.caseBattery = batteryLevel
                nothingDevice?.isCaseCharging = isCharging
                nothingDevice?.isCaseConnected = true
            default:
                // Handle unknown device ID if necessary
                break
            }
        }
        
        log.debug("Battery L:\(nothingDevice?.leftBattery ?? -1)% R:\(nothingDevice?.rightBattery ?? -1)% C:\(nothingDevice?.caseBattery ?? -1)%")
    }
    
    private func readGestures(hexArray: [UInt8]) -> [(deviceType: DeviceType, gestureType: GestureType, action: UInt8)] {
        guard hexArray.count > 8 else { return [] }
        let gestureCount: UInt8 = hexArray[8]

        var array: [(deviceType: DeviceType, gestureType: GestureType, action: UInt8)] = []

        for i in 0..<gestureCount { // Loop from 0 to gestureCount - 1
            let actionIndex = 12 + Int(i) * 4
            guard actionIndex < hexArray.count else { break }

            let device = DeviceType(rawValue: hexArray[9 + Int(i) * 4]) // Assign values from hexString to the dictionary
            let gesture = GestureType(rawValue: hexArray[11 + Int(i) * 4])

            if let device = device, let gesture = gesture {
                array.append((deviceType: device, gestureType: gesture, action: hexArray[actionIndex]))
            }
            
        }
        
        for a in array {
            log.debug("Gesture: device=\(a.0) gesture=\(a.1) action=\(a.2)")
        }
        
        return array
        
    }
    
    private func readANC(hexArray: [UInt8]) {
        guard hexArray.count > 9 else { return }
        let ancStatus = hexArray[9]
        let level = ANC(rawValue: ancStatus)
        guard let unwrappedLevel = level else {
            return
        }
        nothingDevice?.anc = unwrappedLevel
  
        
        log.debug("ANC level: \(unwrappedLevel)")
        
        nothingDevice?.printValues()
        
    }
    
    private func readEQ(hexArray: [UInt8]) -> EQProfiles {
        guard hexArray.count > 8 else { return .BALANCED }

        let eqMode: UInt8 = hexArray[8]
        log.debug("EQ mode: \(eqMode)")
        
        return EQProfiles(rawValue: eqMode) ?? EQProfiles.BALANCED
        
    }
    
    private func readSerial(hexPayload: [UInt8]) -> String {
        
        
        var configurations: [(device: Int, type: Int, value: String)] = []
        
        // Decode the remaining payload and split by new lines
        let linesData = hexPayload[7...] // Subarray from index 7 to the end
        let lines = String(decoding: linesData, as: UTF8.self).split(separator: "\n")
        
        // Process each line
        for line in lines {
            let parts = line.split(separator: ",").map { String($0) }
            if parts.count == 3,
               let device = Int(parts[0]),
               let type = Int(parts[1]),
               let value = parts[2].nonEmpty {
                configurations.append((device: device, type: type, value: value))
            }
        }
        
        // Filter configurations to find the serial number
        let serialConfigs = configurations.filter { $0.type == 4 && !$0.value.isEmpty }
        
        for config in configurations {
            log.debug("Config: device=\(config.device) type=\(config.type) value=\(config.value)")
        }
        let serialValue = serialConfigs.first?.value ?? "12345678901234567"
        log.info("Serial: \(serialValue)")
        return serialValue
    }
    
   
    private func readFirmware(hexArray: [UInt8]) -> String {
        
        // Initialize an empty string for the firmware version
        var firmwareVersion = ""
        
        // Ensure that the hexArray has enough elements
        guard hexArray.count > 8 else {
            log.error("hexArray does not contain enough elements for firmware")
            return firmwareVersion
        }
        
        // Get the size from the hexArray
        let size = hexArray[5]
        
        // Extract the firmware version based on the size
        for i in 0..<size {
            let index = 8 + Int(i)
            if index < hexArray.count {
                firmwareVersion += String(UnicodeScalar(hexArray[index]))
            } else {
                log.warning("Index \(index) out of bounds for firmware hexArray")
                break
            }
        }
        
        nothingDevice?.firmware = firmwareVersion
        log.info("Firmware: \(firmwareVersion)")
        
        return firmwareVersion
    }
    
    private func readLatencyMode(hexArray: [UInt8]) -> Bool {
        log.debug("Reading latency mode")
        guard hexArray.count > 8 else { return false }
        return hexArray[8] == 0x01
    }

    private func readInEarDetection(hexArray: [UInt8]) -> Bool {
        log.debug("Reading in-ear detection")
        guard hexArray.count > 10 else { return false }
        return (hexArray[10] != 0)
    }

    // MARK: - Custom EQ Float Encoding

    private func formatFloatForEQ(_ value: Float, isTotal: Bool = false) -> [UInt8] {
        if isTotal && value >= 0 {
            return [0x00, 0x00, 0x00, 0x80]
        }

        let bitPattern = value.bitPattern
        var bytes: [UInt8] = [
            UInt8((bitPattern >> 24) & 0xFF),
            UInt8((bitPattern >> 16) & 0xFF),
            UInt8((bitPattern >> 8) & 0xFF),
            UInt8(bitPattern & 0xFF)
        ]

        if value != 0 && bytes[0] == 0 && bytes[1] == 0 && bytes[2] == 0 {
            bytes[3] |= 0x80
        }

        return [bytes[3], bytes[2], bytes[1], bytes[0]]
    }

    private func decodeFloatFromEQ(_ bytes: [UInt8]) -> Float {
        guard bytes.count >= 4 else { return 0.0 }
        let reversed: [UInt8] = [bytes[3], bytes[2], bytes[1], bytes[0]]
        let bitPattern = UInt32(reversed[0]) << 24 | UInt32(reversed[1]) << 16 | UInt32(reversed[2]) << 8 | UInt32(reversed[3])
        return Float(bitPattern: bitPattern)
    }

    private func buildCustomEQPayload(bass: Float, mid: Float, treble: Float) -> [UInt8] {
        let totalGain = max(bass, mid, treble) * -1
        let totalBytes = formatFloatForEQ(totalGain, isTotal: true)
        let bassBytes = formatFloatForEQ(bass)
        let midBytes = formatFloatForEQ(mid)
        let trebleBytes = formatFloatForEQ(treble)

        // Static frequency/Q params from ear-web
        let bassParams: [UInt8] = [0x00, 0x00, 0x75, 0x44, 0xc3, 0xf5, 0x28, 0x3f]
        let midParams: [UInt8] = [0x00, 0xc0, 0x5a, 0x45, 0x00, 0x00, 0x80, 0x3f]
        let trebleParams: [UInt8] = [0x00, 0x00, 0x0c, 0x43, 0xcd, 0xcc, 0x4c, 0x3f]

        var payload: [UInt8] = [0x03]
        payload.append(contentsOf: totalBytes)
        payload.append(0x01)
        payload.append(contentsOf: bassBytes)
        payload.append(0x00) // separator
        payload.append(contentsOf: bassParams)
        payload.append(0x02)
        payload.append(contentsOf: midBytes)
        payload.append(contentsOf: midParams)
        payload.append(0x00)
        payload.append(contentsOf: trebleBytes)
        payload.append(contentsOf: trebleParams)
        payload.append(0x00)

        return payload
    }

    private func readCustomEQ(hexArray: [UInt8]) {
        guard hexArray.count >= 44 else {
            log.warning("Custom EQ response too short: \(hexArray.count) bytes")
            return
        }
        // Float values at offsets 14, 27, 40 (4 bytes each)
        let trebleBytes = Array(hexArray[14..<18])
        let bassBytes = Array(hexArray[27..<31])
        let midBytes = Array(hexArray[40..<44])

        nothingDevice?.customEQBass = decodeFloatFromEQ(bassBytes)
        nothingDevice?.customEQMid = decodeFloatFromEQ(midBytes)
        nothingDevice?.customEQTreble = decodeFloatFromEQ(trebleBytes)

        log.info("Custom EQ: bass=\(nothingDevice?.customEQBass ?? 0) mid=\(nothingDevice?.customEQMid ?? 0) treble=\(nothingDevice?.customEQTreble ?? 0)")
    }

    private func readAdvancedEQ(hexArray: [UInt8]) {
        guard hexArray.count > 8 else { return }
        nothingDevice?.isAdvancedEQEnabled = hexArray[8] == 1
        log.info("Advanced EQ enabled: \(nothingDevice?.isAdvancedEQEnabled ?? false)")
    }

    private func restoreCachedCustomEQ() {
        guard let mac = nothingDevice?.bluetoothDetails.mac else { return }
        let saved = NothingRepositoryImpl.shared.getSaved()
        guard let cached = saved.first(where: { $0.bluetoothDetails.mac == mac }) else { return }

        if cached.isAdvancedEQEnabled {
            nothingDevice?.isAdvancedEQEnabled = true
            log.info("Restored cached advanced EQ: enabled")
        }
        if cached.customEQBass != 0 || cached.customEQMid != 0 || cached.customEQTreble != 0 {
            nothingDevice?.customEQBass = cached.customEQBass
            nothingDevice?.customEQMid = cached.customEQMid
            nothingDevice?.customEQTreble = cached.customEQTreble
            log.info("Restored cached custom EQ: bass=\(cached.customEQBass) mid=\(cached.customEQMid) treble=\(cached.customEQTreble)")
        }
    }

    private func readEnhancedBass(hexArray: [UInt8]) {
        guard hexArray.count > 9 else { return }
        nothingDevice?.isEnhancedBassEnabled = hexArray[8] == 1
        nothingDevice?.enhancedBassLevel = Int(hexArray[9]) / 2
        log.info("Enhanced bass: enabled=\(nothingDevice?.isEnhancedBassEnabled ?? false) level=\(nothingDevice?.enhancedBassLevel ?? 0)")
    }

    private func readPersonalizedANC(hexArray: [UInt8]) {
        guard hexArray.count > 8 else { return }
        nothingDevice?.isPersonalizedANCEnabled = hexArray[8] == 1
        log.info("Personalized ANC: \(nothingDevice?.isPersonalizedANCEnabled ?? false)")
    }

    private func readEarTipTestResult(hexArray: [UInt8]) {
        guard hexArray.count > 9 else { return }
        let leftResult = hexArray[8]
        let rightResult = hexArray[9]
        log.info("Ear tip test result: left=\(leftResult) right=\(rightResult)")

        NotificationCenter.default.post(
            name: Notification.Name(DataNotifications.EAR_TIP_TEST_RESULT.rawValue),
            object: nil,
            userInfo: ["left": leftResult, "right": rightResult]
        )
    }

    private func readCaseLED(hexArray: [UInt8]) {
        guard hexArray.count > 8 else { return }
        let numberOfLEDs = Int(hexArray[8])
        var colors: [[UInt8]] = []
        for i in 0..<numberOfLEDs {
            let baseIndex = 10 + (i * 4)
            guard baseIndex + 2 < hexArray.count else { break }
            colors.append([hexArray[baseIndex], hexArray[baseIndex + 1], hexArray[baseIndex + 2]])
        }
        nothingDevice?.caseLEDColors = colors
        log.info("Case LED colors: \(colors)")
    }

    
    private func setRingBuds(device: DeviceType?, doRing: Bool) {
        let modelBase = nothingDevice?.codename ?? .UNKNOWN

        if modelBase == .ONE {
            // Ear (1) uses a 1-byte payload: 0x01 = ring, 0x00 = stop
            let byteArray: [UInt8] = [doRing ? 0x01 : 0x00]
            send(command: Commands.SET_RING_BUDS.rawValue, operationID: Commands.SET_RING_BUDS.firstEightBits, payload: byteArray)
        } else {
            // All other devices use a 2-byte payload: [deviceId, ringState]
            // device == nil means ring both (send two commands)
            if let device = device {
                let byteArray: [UInt8] = [device.rawValue, doRing ? 0x01 : 0x00]
                send(command: Commands.SET_RING_BUDS.rawValue, operationID: Commands.SET_RING_BUDS.firstEightBits, payload: byteArray)
            } else {
                // Ring both buds
                let leftPayload: [UInt8] = [DeviceType.LEFT.rawValue, doRing ? 0x01 : 0x00]
                send(command: Commands.SET_RING_BUDS.rawValue, operationID: Commands.SET_RING_BUDS.firstEightBits, payload: leftPayload)
                let rightPayload: [UInt8] = [DeviceType.RIGHT.rawValue, doRing ? 0x01 : 0x00]
                send(command: Commands.SET_RING_BUDS.rawValue, operationID: Commands.SET_RING_BUDS.firstEightBits, payload: rightPayload)
            }
        }
    }
    
    
    
    private func onDataReceived(rawData: [UInt8]) {
        
        
        var hexString = ""
        for byte in rawData {
            hexString += String(format: "%02x", byte)
        }
        log.debug("Received: \(hexString)")
        
        // Check if the first byte is 0x55 and if the length is at least 10
        guard rawData.count >= 8, rawData[0] == 0x55 else {
            log.warning("Invalid data: first byte is not 0x55 or data length < 8")
            return
        }
        
        
        let executedOperationID = rawData[7]
        
        // Extract the header (first 6 bytes)
        let header = Array(rawData[0..<6])
        
        // Get the command from the header
        let command = getCommand(header: header)
        
        
        
        switch command {
            
        case Commands.READ_FIRMWARE.rawValue:

            let firmware = readFirmware(hexArray: rawData)
            nothingDevice?.firmware = firmware
            if (nothingDevice?.sku == SKU.UNKNOWN) {
                let detectedSku = skuFromFirmware(firmware: firmware)
                if detectedSku != .UNKNOWN {
                    nothingDevice?.sku = detectedSku
                    nothingDevice?.codename = codenameFromSKU(sku: detectedSku)
                }
            }
            
        case Commands.READ_SERIAL_NUMBER.rawValue:

            let serial = readSerial(hexPayload: rawData)
            if (!serial.isEmpty) {
                nothingDevice?.serial = serial
                let sku = skuFromSerial(serial: serial)
                if sku != .UNKNOWN {
                    nothingDevice?.sku = sku
                    nothingDevice?.codename = codenameFromSKU(sku: sku)
                } else if nothingDevice?.codename == .UNKNOWN, let name = nothingDevice?.name {
                    // Fallback: detect from device name
                    let detected = codenameFromDeviceName(name: name)
                    if detected != .UNKNOWN {
                        nothingDevice?.codename = detected
                        log.info("Codename detected from name fallback: \(detected)")
                    }
                }
            }

        case Commands.READ_ANC_ONE.rawValue:
            
            readANC(hexArray: rawData)
            
        case Commands.READ_ANC_TWO.rawValue:
            
            readANC(hexArray: rawData)
            
        case Commands.READ_EQ_ONE.rawValue:
            
            let mode = readEQ(hexArray: rawData)
            nothingDevice?.listeningMode = mode
            
        case Commands.READ_EQ_TWO.rawValue:
            
            let mode = readEQ(hexArray: rawData)
            nothingDevice?.listeningMode = mode
            
        case Commands.READ_BATTERY_ONE.rawValue:
            
            readBattery(hexString: rawData)

            
        case Commands.READ_BATTERY_TWO.rawValue:
            
            readBattery(hexString: rawData)
            
            
        case Commands.READ_BATTERY_THREE.rawValue:
            
            readBattery(hexString: rawData)
            
        case Commands.READ_LATENCY.rawValue:
            
            let latency = readLatencyMode(hexArray: rawData)
            log.debug("Latency: \(latency)")
            nothingDevice?.isLowLatencyOn = latency
            
        case Commands.READ_IN_EAR_MODE.rawValue:
            
            let inEarMode = readInEarDetection(hexArray: rawData)
            log.debug("In-ear mode: \(inEarMode)")
            nothingDevice?.isInEarDetectionOn = inEarMode
            
        case Commands.READ_GESTURES.rawValue:
            let result = readGestures(hexArray: rawData)
            for device in result {
                updateGestureInNothing(deviceType: device.0, gestureType: device.1, action: device.2)
            }

        case Commands.READ_CUSTOM_EQ.rawValue:
            readCustomEQ(hexArray: rawData)

        case Commands.READ_ADVANCED_EQ.rawValue:
            readAdvancedEQ(hexArray: rawData)

        case Commands.READ_ENHANCED_BASS.rawValue:
            readEnhancedBass(hexArray: rawData)

        case Commands.READ_PERSONALIZED_ANC.rawValue:
            readPersonalizedANC(hexArray: rawData)

        case Commands.READ_EAR_TIP_RESULT.rawValue:
            readEarTipTestResult(hexArray: rawData)

        case Commands.READ_CASE_LED.rawValue:
            readCaseLED(hexArray: rawData)

        default:
            log.warning("Unhandled command: \(command)")
            
        }
        
        log.debug("Current request: \(currentRequest?.operationID ?? 0), executed op: \(executedOperationID)")
        if let currentRequest = currentRequest {
            if currentRequest.operationID == executedOperationID {
                currentRequest.completion(.success(()))
            }
        }
        processNextRequest()
        
    }
    
    private func updateGestureInNothing(deviceType: DeviceType, gestureType: GestureType, action: UInt8) {
        if deviceType == .LEFT {
            switch gestureType {
            case .TAP_AND_HOLD:
                nothingDevice?.tapAndHoldGestureActionLeft = TapAndHoldGestureActions(rawValue: action) ?? .NO_EXTRA_ACTION
            case .TRIPLE_TAP:
                nothingDevice?.tripleTapGestureActionLeft = TripleTapGestureActions(rawValue: action) ?? .NO_EXTRA_ACTION
            case .DOUBLE_TAP:
                nothingDevice?.doubleTapGestureActionLeft = DoubleTapGestureActions(rawValue: action) ?? .PLAY_PAUSE
            case .DOUBLE_TAP_AND_HOLD:
                nothingDevice?.doubleTapAndHoldGestureActionLeft = DoubleTapAndHoldGestureActions(rawValue: action) ?? .NO_EXTRA_ACTION
            }
        } else if deviceType == .RIGHT {
            switch gestureType {
            case .TAP_AND_HOLD:
                nothingDevice?.tapAndHoldGestureActionRight = TapAndHoldGestureActions(rawValue: action) ?? .NO_EXTRA_ACTION
            case .TRIPLE_TAP:
                nothingDevice?.tripleTapGestureActionRight = TripleTapGestureActions(rawValue: action) ?? .NO_EXTRA_ACTION
            case .DOUBLE_TAP:
                nothingDevice?.doubleTapGestureActionRight = DoubleTapGestureActions(rawValue: action) ?? .PLAY_PAUSE
            case .DOUBLE_TAP_AND_HOLD:
                nothingDevice?.doubleTapAndHoldGestureActionRight = DoubleTapAndHoldGestureActions(rawValue: action) ?? .NO_EXTRA_ACTION
            }
        }
    }
    
    private func getCommand(header: [UInt8]) -> UInt16 {
        let commandBytes = Array(header[3..<5])
        let commandInt = (UInt16(commandBytes[0]) | (UInt16(commandBytes[1]) << 8))
        log.debug("Command: \(commandInt) (bytes: \(commandBytes))")
        
        return commandInt
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
}


extension String {
    var nonEmpty: String? {
        return isEmpty ? nil : self
    }
}
