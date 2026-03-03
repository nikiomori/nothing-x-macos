//
//  EqualizerViewViewModel.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/2/19.
//

import Foundation
import SwiftUI
import Combine

class EqualizerViewViewModel : ObservableObject {


    private let switchEqUseCase: SwitchEqUseCaseProtocol
    private let nothingService: NothingService

    @Published var eq: EQProfiles = .BALANCED

    // Custom EQ
    @Published var isAdvancedEQEnabled: Bool = false
    @Published var customBass: Double = 0.0
    @Published var customMid: Double = 0.0
    @Published var customTreble: Double = 0.0

    // Enhanced Bass
    @Published var isEnhancedBassEnabled: Bool = false
    @Published var enhancedBassLevel: Int = 0

    // Device capabilities
    @Published var supportsCustomEQ: Bool = false
    @Published var supportsEnhancedBass: Bool = false

    // EQ Presets
    @Published var savedPresets: [EQPreset] = []
    @Published var isNamingPreset: Bool = false
    @Published var newPresetName: String = ""

    var isUpdatingFromDevice = false

    private var debounceTimer: Timer?
    private let presetStorage = EQPresetStorage.shared

    init(nothingService: NothingService) {

        self.nothingService = nothingService
        self.switchEqUseCase = SwitchEqUseCase(service: nothingService)


        savedPresets = presetStorage.getAll()

        NotificationCenter.default.addObserver(forName: Notification.Name(DataNotifications.REPOSITORY_DATA_UPDATED.rawValue), object: nil, queue: .main) { notification in

            if let device = notification.object as? NothingDeviceEntity {

                if self.eq != device.listeningMode {
                    self.eq = device.listeningMode
                }

                // Update capabilities
                let caps = DeviceCapabilities.capabilities(for: device.codename)
                self.supportsCustomEQ = caps.supportsCustomEQ
                self.supportsEnhancedBass = caps.supportsEnhancedBass

                // Update custom EQ values from device
                self.isUpdatingFromDevice = true
                self.isAdvancedEQEnabled = device.isAdvancedEQEnabled
                self.customBass = Double(device.customEQBass)
                self.customMid = Double(device.customEQMid)
                self.customTreble = Double(device.customEQTreble)
                self.isEnhancedBassEnabled = device.isEnhancedBassEnabled
                self.enhancedBassLevel = device.enhancedBassLevel
                self.isUpdatingFromDevice = false
            }
        }
    }



    func switchEQ(eq: EQProfiles) {
        if eq == .CUSTOM {
            // Enable advanced EQ mode
            if !isAdvancedEQEnabled {
                nothingService.setAdvancedEQ(enabled: true)
            }
            self.eq = .CUSTOM
        } else {
            // Disable advanced EQ if switching to preset
            if isAdvancedEQEnabled {
                nothingService.setAdvancedEQ(enabled: false)
            }
            switchEqUseCase.switchEQ(mode: eq)
        }
    }

    func sendCustomEQ() {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            self.nothingService.switchCustomEQ(
                bass: Float(self.customBass),
                mid: Float(self.customMid),
                treble: Float(self.customTreble)
            )
        }
    }

    func switchEnhancedBass(enabled: Bool) {
        nothingService.switchEnhancedBass(enabled: enabled, level: enhancedBassLevel)
    }

    func setEnhancedBassLevel(level: Int) {
        enhancedBassLevel = level
        nothingService.switchEnhancedBass(enabled: isEnhancedBassEnabled, level: level)
    }

    // MARK: - EQ Presets

    func saveCurrentAsPreset(name: String) {
        let preset = EQPreset(
            name: name,
            bass: Float(customBass),
            mid: Float(customMid),
            treble: Float(customTreble)
        )
        presetStorage.save(preset: preset)
        savedPresets = presetStorage.getAll()
    }

    func loadPreset(_ preset: EQPreset) {
        if eq != .CUSTOM {
            switchEQ(eq: .CUSTOM)
        }
        customBass = Double(preset.bass)
        customMid = Double(preset.mid)
        customTreble = Double(preset.treble)
        sendCustomEQ()
    }

    func deletePreset(_ preset: EQPreset) {
        presetStorage.delete(id: preset.id)
        savedPresets = presetStorage.getAll()
    }

}
