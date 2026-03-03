//
//  EqualizerView.swift
//  Nothing X MacOS
//
//  Created by Arunavo Ray on 14/02/23.
//

import SwiftUI

struct EqualizerView: View {


    @StateObject private var viewModel = EqualizerViewViewModel(nothingService: NothingServiceImpl.shared)
    @Binding var eqMode: EQProfiles
    @EnvironmentObject private var mainViewModel: MainViewViewModel

    var body: some View {

        VStack(spacing: 0) {
            // Back button
            HStack {
                BackButtonView()
                Spacer()
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {

                    // Heading
                    VStack(alignment: .leading, spacing: 2) {
                        Text("EQUALISER")
                            .font(.custom("NDOT45inspiredbyNOTHING", size: 10))
                            .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                            .textCase(.uppercase)

                        Text("Customise your sound by selecting your favourite preset.")
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                    }

                    // Preset buttons 2x2
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Button("Balanced") { viewModel.switchEQ(eq: .BALANCED) }
                                .buttonStyle(EQButton(selected: eqMode == .BALANCED))
                            Button("More bass") { viewModel.switchEQ(eq: .MORE_BASE) }
                                .buttonStyle(EQButton(selected: eqMode == .MORE_BASE))
                        }
                        HStack(spacing: 4) {
                            Button("More trebel") { viewModel.switchEQ(eq: .MORE_TREBEL) }
                                .buttonStyle(EQButton(selected: eqMode == .MORE_TREBEL))
                            Button("Voice") { viewModel.switchEQ(eq: .VOICE) }
                                .buttonStyle(EQButton(selected: eqMode == .VOICE))
                        }

                        // Custom EQ button
                        if viewModel.supportsCustomEQ {
                            HStack(spacing: 4) {
                                Button("Custom") { viewModel.switchEQ(eq: .CUSTOM) }
                                    .buttonStyle(EQButton(selected: eqMode == .CUSTOM))
                                Spacer()
                            }
                        }
                    }

                    // EQ Curve
                    if eqMode == .CUSTOM {
                        EQCurveView(bass: viewModel.customBass, mid: viewModel.customMid, treble: viewModel.customTreble)
                    } else {
                        EQCurveView(profile: eqMode)
                    }

                    // Custom EQ sliders & presets
                    if viewModel.supportsCustomEQ && eqMode == .CUSTOM {
                        VStack(spacing: 6) {
                            EQSliderRow(label: "BASS", value: $viewModel.customBass) { viewModel.sendCustomEQ() }
                            EQSliderRow(label: "MID", value: $viewModel.customMid) { viewModel.sendCustomEQ() }
                            EQSliderRow(label: "TREBLE", value: $viewModel.customTreble) { viewModel.sendCustomEQ() }
                        }

                        // Saved presets
                        VStack(spacing: 6) {
                            if !viewModel.savedPresets.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 4) {
                                        ForEach(viewModel.savedPresets) { preset in
                                            Button(preset.name) { viewModel.loadPreset(preset) }
                                                .buttonStyle(EQButton(selected: false))
                                                .contextMenu {
                                                    Button("Delete", role: .destructive) { viewModel.deletePreset(preset) }
                                                }
                                        }
                                    }
                                }
                            }

                            if viewModel.isNamingPreset {
                                HStack(spacing: 4) {
                                    TextField("Name", text: $viewModel.newPresetName)
                                        .textFieldStyle(.plain)
                                        .font(.system(size: 10))
                                        .padding(4)
                                        .background(Color(#colorLiteral(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)))
                                        .cornerRadius(4)

                                    Button("OK") {
                                        let name = viewModel.newPresetName.trimmingCharacters(in: .whitespaces)
                                        if !name.isEmpty { viewModel.saveCurrentAsPreset(name: name) }
                                        viewModel.newPresetName = ""
                                        viewModel.isNamingPreset = false
                                    }
                                    .buttonStyle(EQButton(selected: false))

                                    Button("X") {
                                        viewModel.newPresetName = ""
                                        viewModel.isNamingPreset = false
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.gray)
                                }
                            } else {
                                Button("Save preset") { viewModel.isNamingPreset = true }
                                    .buttonStyle(EQButton(selected: false))
                            }
                        }
                        .padding(.top, 2)
                    }

                    // Enhanced Bass toggle
                    if viewModel.supportsEnhancedBass {
                        VStack(alignment: .leading, spacing: 4) {
                            Rectangle()
                                .fill(Color(#colorLiteral(red: 0.07009194046, green: 0.07611755282, blue: 0.08425947279, alpha: 1)))
                                .frame(height: 0.8)

                            Toggle("Enhanced bass", isOn: $viewModel.isEnhancedBassEnabled)
                                .onChange(of: viewModel.isEnhancedBassEnabled) { newValue in
                                    guard !viewModel.isUpdatingFromDevice else { return }
                                    viewModel.switchEnhancedBass(enabled: newValue)
                                }
                                .toggleStyle(SwitchToggleStyle())

                            if viewModel.isEnhancedBassEnabled {
                                HStack(spacing: 4) {
                                    ForEach(1...5, id: \.self) { level in
                                        Button("\(level)") { viewModel.setEnhancedBassLevel(level: level) }
                                            .buttonStyle(EQButton(selected: viewModel.enhancedBassLevel == level))
                                            .frame(width: 32, height: 26)
                                    }
                                }
                                .padding(.top, 2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 10)
            }
            .clipped()
        }
        .navigationBarBackButtonHidden(true)
        .background(.black)
        .frame(width: 250, height: 230)
        .onAppear {
            if let device = mainViewModel.nothingDevice {
                let caps = DeviceCapabilities.capabilities(for: device.codename)
                viewModel.supportsCustomEQ = caps.supportsCustomEQ
                viewModel.supportsEnhancedBass = caps.supportsEnhancedBass

                viewModel.isUpdatingFromDevice = true
                viewModel.isAdvancedEQEnabled = device.isAdvancedEQEnabled
                viewModel.customBass = Double(device.customEQBass)
                viewModel.customMid = Double(device.customEQMid)
                viewModel.customTreble = Double(device.customEQTreble)
                viewModel.isEnhancedBassEnabled = device.isEnhancedBassEnabled
                viewModel.enhancedBassLevel = device.enhancedBassLevel
                viewModel.isUpdatingFromDevice = false
            }
        }

    }
}

// MARK: - EQ Slider Row

struct EQSliderRow: View {
    let label: String
    @Binding var value: Double
    var onChange: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                .frame(width: 42, alignment: .leading)

            Slider(value: $value, in: -6...6, step: 0.5)
                .onChange(of: value) { _ in
                    onChange()
                }

            Text(String(format: "%+.1f", value))
                .font(.system(size: 9, weight: .light))
                .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                .frame(width: 28, alignment: .trailing)
        }
    }
}


struct EqualizerView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var eqMode: EQProfiles = .BALANCED // State variable for preview

        var body: some View {
            EqualizerView(eqMode: $eqMode) // Pass the binding
                .environmentObject(MainViewViewModel(bluetoothService: BluetoothServiceImpl(), nothingRepository: NothingRepositoryImpl.shared, nothingService: NothingServiceImpl.shared))
                .previewDisplayName("Equalizer View Preview")
        }
    }

    static var previews: some View {
        PreviewWrapper() // Use the wrapper to create an instance
    }
}
