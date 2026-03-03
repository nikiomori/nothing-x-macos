//
//  SettingsViewViewModel.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/3/3.
//

import Foundation

class SettingsViewViewModel : ObservableObject {
    
    private let switchLatencyUseCase: SwitchLatencyUseCaseProtocol
    private let switchInEarDetectionUseCase: SwitchInEarDetectionUseCaseProtocol
    private let deleteSavedDeviceUseCase: DeleteSavedUseCaseProtocol
    private let getSavedDevicesUseCase: GetSavedDevicesUseCaseProtocol
    private let isNothingConnectedUseCase: IsNothingConnectedUseCaseProtocol
    private let nothingService: NothingService

    @Published var shouldShowForgetDialog = false
    @Published var latencySwitch = false
    @Published var inEarSwitch = false
    @Published var personalizedANCSwitch = false

    var isUpdatingFromDevice = false

    @Published var name: String = ""
    @Published var mac: String = ""
    @Published var serial: String = ""
    @Published var firmware: String = ""
    @Published var isNothingDeviceAccessible = false

    // Device capabilities
    @Published var supportsPersonalizedANC = false
    @Published var supportsEarTipTest = false
    @Published var supportsCaseLED = false

    @Published var nothingDevice: NothingDeviceEntity?

    private var observer: NSObjectProtocol?


    init(nothingService: NothingService, nothingRepository: NothingRepository) {
        self.nothingService = nothingService
        self.switchLatencyUseCase = SwitchLatencyUseCase(nothingService: nothingService)
        self.switchInEarDetectionUseCase = SwitchInEarDetectionUseCase(nothingService: nothingService)
        self.deleteSavedDeviceUseCase = DeleteSavedDeviceUseCase(nothingRepository: nothingRepository)
        self.getSavedDevicesUseCase = GetSavedDevicesUseCase(nothingRepository: nothingRepository)
        self.isNothingConnectedUseCase = IsNothingConnectedUseCase(nothingService: nothingService)


        observer = NotificationCenter.default.addObserver(forName: Notification.Name(DataNotifications.REPOSITORY_DATA_UPDATED.rawValue), object: nil, queue: .main) { [weak self] notification in
            guard let self else { return }

            if let device = notification.object as? NothingDeviceEntity {

                // Update toggles from device state

                self.isUpdatingFromDevice = true
                self.latencySwitch = device.isLowLatencyOn
                self.inEarSwitch = device.isInEarDetectionOn
                self.personalizedANCSwitch = device.isPersonalizedANCEnabled
                self.isUpdatingFromDevice = false

                // Update capabilities
                let caps = DeviceCapabilities.capabilities(for: device.codename)
                self.supportsPersonalizedANC = caps.supportsPersonalizedANC
                self.supportsEarTipTest = caps.supportsEarTipTest
                self.supportsCaseLED = caps.supportsCaseLED

                self.nothingDevice = device

                self.name = device.bluetoothDetails.name
                self.mac = device.bluetoothDetails.mac
                self.serial = device.serial
                self.firmware = device.firmware
            }
        }
        
        isNothingDeviceAccessible = isNothingConnectedUseCase.isNothingConnected()
        
        
        let devices = getSavedDevicesUseCase.getSaved()
        if (!devices.isEmpty) {
            name = devices[0].bluetoothDetails.name
            mac = devices[0].bluetoothDetails.mac
            serial = devices[0].serial
            firmware = devices[0].firmware
        }

    }
    
    func switchLatency(mode: Bool) {
        switchLatencyUseCase.switchLatency(mode: mode)
    }
    
    func switchInEarDetection(mode: Bool) {
        switchInEarDetectionUseCase.switchInEarDetection(mode: mode)
    }
    
    func switchPersonalizedANC(mode: Bool) {
        nothingService.switchPersonalizedANC(enabled: mode)
    }

    func launchEarTipTest() {
        nothingService.launchEarTipTest()
    }

    func forgetDevice() {
        let devices = getSavedDevicesUseCase.getSaved()
        guard let first = devices.first else { return }
        deleteSavedDeviceUseCase.delete(device: first)
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

}
