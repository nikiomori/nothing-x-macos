//
//  NXDashboardScreen.swift
//  Nothing X MacOS
//
//  Window dashboard: hero, battery, noise control with shortcuts, and
//  feature tiles.
//

import SwiftUI

struct NXDashboardScreen: View {
    @EnvironmentObject var mainViewModel: MainViewViewModel
    @Binding var section: NXSection

    @StateObject private var noiseVM = NoiseControlViewViewModel(nothingService: NothingServiceImpl.shared)
    @StateObject private var eqVM = EqualizerViewViewModel(nothingService: NothingServiceImpl.shared)
    @StateObject private var settingsVM = SettingsViewViewModel(nothingService: NothingServiceImpl.shared, nothingRepository: NothingRepositoryImpl.shared)

    private var device: NothingDeviceEntity? { mainViewModel.nothingDevice }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            hero
            batteryCard
            controlRow
            featureTiles
                .frame(maxHeight: .infinity)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 40)
    }

    // MARK: - Hero

    private var hero: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle().fill(NX.capsule).frame(width: 6, height: 6)
                    Text("CONNECTED")
                        .font(NX.pixel(10))
                        .tracking(2)
                        .foregroundColor(NX.textSecondary)
                }
                Text(device?.nxShortName ?? "")
                    .font(NX.ndot(42))
                    .tracking(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(NX.textPrimary)
                Text("\((device?.name ?? "").uppercased()) · FIRMWARE \(device?.firmware ?? "–")")
                    .font(.system(size: 11, weight: .light))
                    .tracking(1)
                    .foregroundColor(NX.textTertiary)
            }
            Spacer()
            NXBudsImage(codename: device?.codename, height: 130)
                .padding(.trailing, 12)
        }
    }

    // MARK: - Battery

    private var isSingleUnit: Bool {
        device.map { DeviceCapabilities.capabilities(for: $0.codename).isSingleUnit } ?? false
    }

    private var batteryCard: some View {
        HStack(spacing: 26) {
            if isSingleUnit {
                batteryCell("BATTERY", level: mainViewModel.leftBattery.map(Int.init), charging: device?.isLeftCharging == true)
            } else {
                batteryCell("LEFT", level: mainViewModel.leftBattery.map(Int.init), charging: device?.isLeftCharging == true)
                Divider().overlay(NX.cardBorder)
                batteryCell("CASE", level: device?.isCaseConnected == true ? device?.caseBattery : nil, charging: device?.isCaseCharging == true)
                Divider().overlay(NX.cardBorder)
                batteryCell("RIGHT", level: mainViewModel.rightBattery.map(Int.init), charging: device?.isRightCharging == true)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 26)
        .nxCard()
    }

    private func batteryCell(_ label: String, level: Int?, charging: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 9))
                .tracking(2)
                .foregroundColor(NX.textTertiary)
            HStack(spacing: 8) {
                Text(level.map { "\($0)%" } ?? "–")
                    .font(NX.ndot(22))
                    .foregroundColor(NX.textPrimary)
                if charging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11))
                        .foregroundColor(NX.textSecondary)
                }
            }
            NXBatteryBar(level: level)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Noise control

    /// Noise control, Controls and Settings side by side at 2 : 1 : 1
    private var controlRow: some View {
        let showsControls = !isSingleUnit
        return GeometryReader { geo in
            let spacing: CGFloat = 16
            let units: CGFloat = showsControls ? 4 : 3
            let unit = (geo.size.width - spacing * (units - 2)) / units
            HStack(spacing: spacing) {
                noiseCard
                    .frame(width: unit * 2)
                if showsControls {
                    shortcutTile("CONTROLS", status: "GESTURES", icon: "hand.tap", to: .controls)
                        .frame(width: unit)
                }
                shortcutTile("SETTINGS", status: "DEVICE · APP", icon: "gearshape", to: .settings)
                    .frame(width: unit)
            }
        }
        .frame(height: 170)
    }

    private func shortcutTile(_ title: String, status: String, icon: String, to target: NXSection) -> some View {
        NXFeatureTile(title: title, status: status, action: {
            withAnimation(.easeInOut(duration: 0.15)) { section = target }
        }) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .light))
                .foregroundColor(NX.offWhite)
            Spacer()
            Image(systemName: "arrow.right")
                .font(.system(size: 11))
                .foregroundColor(NX.textSecondary)
        }
    }

    private var noiseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            NXSectionLabel("NOISE CONTROL")
            NXNoiseModePicker(
                selection: Binding(
                    get: { noiseVM.anc },
                    set: {
                        noiseVM.anc = $0 // select before the device round-trip
                        noiseVM.switchANC(anc: noiseVM.noiseControlOptionsToAnc(option: $0))
                    }
                ),
                spacing: nil
            )
            // Space stays reserved so the row doesn't jump when ANC toggles
            HStack(spacing: 6) {
                ForEach(ancLevels, id: \.self) { level in
                    Button(level.displayName.uppercased()) {
                        withAnimation { noiseVM.switchANC(anc: level) }
                    }
                    .buttonStyle(NXChip(selected: noiseVM.ancDetail == level))
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(noiseVM.anc == .anc ? 1 : 0)
            .allowsHitTesting(noiseVM.anc == .anc)
            .animation(.easeOut(duration: 0.15), value: noiseVM.anc)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .nxCard()
    }

    private var ancLevels: [ANC] {
        noiseVM.supportsAdaptiveANC ? ANC.levels + [.ADAPTIVE] : ANC.levels
    }

    // MARK: - Feature tiles

    private var featureTiles: some View {
        HStack(spacing: 16) {
            NXFeatureTile(title: "EQUALISER", status: eqVM.eq.nxName, action: {
                withAnimation(.easeInOut(duration: 0.15)) { section = .equaliser }
            }) {
                Image(systemName: "slider.vertical.3")
                    .font(.system(size: 15, weight: .light))
                    .foregroundColor(NX.offWhite)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 11))
                    .foregroundColor(NX.textSecondary)
            }

            if eqVM.supportsEnhancedBass {
                NXFeatureTile(
                    title: "ENHANCED BASS",
                    status: eqVM.isEnhancedBassEnabled ? "LEVEL \(eqVM.enhancedBassLevel)" : "OFF",
                    action: { enhancedBassBinding.wrappedValue.toggle() }
                ) {
                    NXSwitchKnob(isOn: eqVM.isEnhancedBassEnabled)
                    Spacer()
                    // Level bars double as the level picker
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { level in
                            Button {
                                if !eqVM.isEnhancedBassEnabled { enhancedBassBinding.wrappedValue = true }
                                eqVM.setEnhancedBassLevel(level: level)
                            } label: {
                                Capsule()
                                    .fill(eqVM.isEnhancedBassEnabled && level <= eqVM.enhancedBassLevel ? NX.segmentOn : NX.segmentOff)
                                    .frame(width: 3, height: 6 + CGFloat(level) * 2)
                                    .frame(width: 9, height: 20, alignment: .bottom)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help("Level \(level)")
                        }
                    }
                }
            }

            NXFeatureTile(
                title: settingsVM.isSingleUnit ? "WEAR DETECTION" : "IN-EAR DETECTION",
                status: settingsVM.inEarSwitch ? "ON" : "OFF",
                action: { inEarBinding.wrappedValue.toggle() }
            ) {
                NXSwitchKnob(isOn: settingsVM.inEarSwitch)
                Spacer()
            }

            NXFeatureTile(
                title: "LOW LAG MODE",
                status: settingsVM.latencySwitch ? "ON" : "OFF",
                action: { lowLagBinding.wrappedValue.toggle() }
            ) {
                NXSwitchKnob(isOn: settingsVM.latencySwitch)
                Spacer()
            }
        }
    }

    private var enhancedBassBinding: Binding<Bool> {
        Binding(
            get: { eqVM.isEnhancedBassEnabled },
            set: { eqVM.isEnhancedBassEnabled = $0; eqVM.switchEnhancedBass(enabled: $0) }
        )
    }

    private var inEarBinding: Binding<Bool> {
        Binding(
            get: { settingsVM.inEarSwitch },
            set: { settingsVM.inEarSwitch = $0; settingsVM.switchInEarDetection(mode: $0) }
        )
    }

    private var lowLagBinding: Binding<Bool> {
        Binding(
            get: { settingsVM.latencySwitch },
            set: { settingsVM.latencySwitch = $0; settingsVM.switchLatency(mode: $0) }
        )
    }
}

/// Title, status line and a bottom accessory; the whole tile is the button
private struct NXFeatureTile<Accessory: View>: View {
    let title: String
    let status: String
    let action: () -> Void
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10))
                .tracking(1.4)
                .foregroundColor(NX.offWhite)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(status)
                .font(NX.pixel(11))
                .foregroundColor(NX.textTertiary)
                .lineLimit(1)
            Spacer(minLength: 12)
            HStack(spacing: 0) { accessory() }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .nxCard()
        .contentShape(RoundedRectangle(cornerRadius: 14))
        // A tap gesture, not a Button, so buttons inside the accessory
        // (enhanced bass levels) still get their own clicks
        .onTapGesture(perform: action)
    }
}
