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
    let command: Commands
    let operationID: UInt8
    let payload: [UInt8]
    let completion: (Result<Void, Error>) -> Void
    let requestTimeout: TimeInterval
    let responseTimeout: TimeInterval
    var retryCount: Int = 0 // Track the number of retries
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
        setRingBuds(right: true, left: true, doRing: true)
    }
    
    func stopRingingBuds() {
        setRingBuds(right: true, left: true, doRing: false)
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
        
        let payloadLength = UInt8(payload.count)
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
        let requestTimeout = DispatchTime.now() + request.requestTimeout
        DispatchQueue.global().asyncAfter(deadline: requestTimeout) {
            if self.isProcessing {
                self.log.warning("Request timed out, retrying")
                // Increment the retry count
                request.retryCount += 1
                
                // Check if the retry count exceeds the maximum allowed
                if request.retryCount <= self.maxRetries {
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
                    self.log.error("Maximum retries reached for request")
                    request.completion(.failure(DeviceError.timeoutError("Maximum retries reached.")))
                    self.isProcessing = false
                    
                    // Process the next request
                    self.processNextRequest()
                }
            }
        }
        
        // Send the command and handle the response
        send(command: request.command.rawValue, operationID: request.operationID, payload: request.payload)
    }
    
    // Function to add a request to the queue
    private func addRequest(command: Commands, operationID: UInt8, requestTimeout: TimeInterval, responseTimeout: TimeInterval, payload: [UInt8] = [], completion: @escaping (Result<Void, Error>) -> Void) {
        
        let requestTimeoutInSeconds = TimeInterval(requestTimeout) / 1000.0
        let responseTimeoutInSeconds = TimeInterval(responseTimeout) / 1000.0
        
        let request = Request(command: command, operationID: operationID, payload: payload, completion: completion, requestTimeout: requestTimeoutInSeconds, responseTimeout: responseTimeoutInSeconds)
        
        queueSemaphore.wait()
        requestQueue.append(request) // Append the request to the queue
        queueSemaphore.signal()
        
        // Start processing if not already processing
        if !isProcessing {
            processNextRequest()
        }
    }

    private func readBattery(hexString: [UInt8]) {
        
        var connectedDevices = 0
        
        let BATTERY_MASK: UInt8 = 127
        let RECHARGING_MASK: UInt8 = 128
        
        // Read the number of connected devices
        connectedDevices = Int(hexString[8])
        
        nothingDevice?.isCaseConnected = false
        nothingDevice?.isLeftConnected = false
        nothingDevice?.isRightConnected = false
        
        // Process each connected device
        for i in 0..<connectedDevices {
            let deviceId = hexString[9 + (i * 2)]
            let batteryData = hexString[10 + (i * 2)]
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
        let gestureCount: UInt8 = hexArray[8]
        
        var array: [(deviceType: DeviceType, gestureType: GestureType, action: UInt8)] = []
        
        for i in 0..<gestureCount { // Loop from 0 to gestureCount - 1
            
            let device = DeviceType(rawValue: hexArray[9 + Int(i) * 4]) // Assign values from hexString to the dictionary
            
            let _ = hexArray[10 + Int(i) * 4]
            let gesture = GestureType(rawValue: hexArray[11 + Int(i) * 4])
            
            if let device = device, let gesture = gesture {
                array.append((deviceType: device, gestureType: gesture, action: hexArray[12 + Int(i) * 4]))
            }
            
        }
        
        for a in array {
            log.debug("Gesture: device=\(a.0) gesture=\(a.1) action=\(a.2)")
        }
        
        return array
        
    }
    
    private func readANC(hexArray: [UInt8]) {
        
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
        return (hexArray[8] != 0)
    }
    
    private func readInEarDetection(hexArray: [UInt8]) -> Bool {
        log.debug("Reading in-ear detection")
        return (hexArray[10] != 0)
    }

    
    private func setRingBuds(right: Bool, left: Bool, doRing: Bool) {
        
        var byteArray: [UInt8] = [0x00] // Initialize the byte array with a single element

        // Assuming modelBase is a global variable or passed as a parameter
        let modelBase = Codenames.ONE // Replace this with the actual modelBase value as needed

        if modelBase == Codenames.ONE {
            // Set the first byte based on the isRing parameter
            byteArray[0] = doRing ? 0x01 : 0x00
            send(command: Commands.SET_RING_BUDS.rawValue, operationID: Commands.SET_RING_BUDS.firstEightBits, payload: byteArray)
        } else {
            // If modelBase is not "B181", initialize a larger byte array
            byteArray = [0x00, 0x00]
            // Set the first byte based on the isLeft parameter
            byteArray[0] = left ? 0x02 : 0x03
            // Set the second byte based on the isRing parameter
            byteArray[1] = right ? 0x01 : 0x00
            send(command: Commands.SET_RING_BUDS.rawValue, operationID: Commands.SET_RING_BUDS.firstEightBits, payload: byteArray)
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
            
        default:
            log.warning("Unhandled command: \(command)")
            
        }
        
        log.debug("Current request: \(self.getCurrentRequest()?.command.rawValue ?? 0), executed op: \(executedOperationID)")
        if let currentRequest = currentRequest {
            if currentRequest.operationID == executedOperationID as UInt8 {
                currentRequest.completion(.success(()))
            }
        }
        processNextRequest()
        
    }
    
    private func updateGestureInNothing(deviceType: DeviceType, gestureType: GestureType, action: UInt8) {
        if deviceType == .LEFT {
            if gestureType == .TAP_AND_HOLD {
                nothingDevice?.tapAndHoldGestureActionLeft = TapAndHoldGestureActions(rawValue: action) ?? TapAndHoldGestureActions.NO_EXTRA_ACTION
            }
            if gestureType == .TRIPLE_TAP {
                nothingDevice?.tripleTapGestureActionLeft = TripleTapGestureActions(rawValue: action) ?? TripleTapGestureActions.NO_EXTRA_ACTION
            }
        } else if deviceType == .RIGHT {
            if gestureType == .TAP_AND_HOLD {
                nothingDevice?.tapAndHoldGestureActionRight = TapAndHoldGestureActions(rawValue: action) ?? TapAndHoldGestureActions.NO_EXTRA_ACTION
            }
            if gestureType == .TRIPLE_TAP {
                nothingDevice?.tripleTapGestureActionRight = TripleTapGestureActions(rawValue: action) ?? TripleTapGestureActions.NO_EXTRA_ACTION
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
