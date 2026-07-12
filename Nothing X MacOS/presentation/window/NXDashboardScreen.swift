//
//  NXDashboardScreen.swift
//  Nothing X MacOS
//
//  Window dashboard: hero, battery, noise control, EQ and quick settings.
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
            noiseCard
            HStack(spacing: 20) {
                equalizerCard
                quickSettingsCard
            }
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
            NXBudsImage(codename: device?.codename, height: 150)
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
                batteryCell("RIGHT", level: mainViewModel.rightBattery.map(Int.init), charging: device?.isRightCharging == true)
                Divider().overlay(NX.cardBorder)
                batteryCell("CASE", level: device?.isCaseConnected == true ? device?.caseBattery : nil, charging: device?.isCaseCharging == true)
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

    private var noiseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            NXSectionLabel("NOISE CONTROL")
            HStack(spacing: 24) {
                NXSegmented(
                    options: [
                        (NoiseControlOptions.anc, "ANC"),
                        (.transparency, "TRANSPARENCY"),
                        (.off, "OFF"),
                    ],
                    selection: Binding(
                        get: { noiseVM.anc },
                        set: {
                            noiseVM.anc = $0 // move the capsule before the device round-trip
                            noiseVM.switchANC(anc: noiseVM.noiseControlOptionsToAnc(option: $0))
                        }
                    )
                )
                .frame(width: 342, height: 46)

                if noiseVM.anc == .anc {
                    HStack(spacing: 8) {
                        Text("LEVEL")
                            .font(.system(size: 9))
                            .tracking(2)
                            .foregroundColor(NX.textTertiary)
                            .padding(.trailing, 4)
                        ForEach(ancLevels, id: \.self) { level in
                            Button(level.displayName.uppercased()) {
                                withAnimation { noiseVM.switchANC(anc: level) }
                            }
                            .buttonStyle(NXChip(selected: noiseVM.ancDetail == level))
                        }
                    }
                    .transition(.opacity)
                }
                Spacer()
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 26)
        .nxCard()
    }

    private var ancLevels: [ANC] {
        noiseVM.supportsAdaptiveANC ? ANC.levels + [.ADAPTIVE] : ANC.levels
    }

    // MARK: - Equalizer

    private var equalizerCard: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { section = .equaliser }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    NXSectionLabel("EQUALISER")
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(NX.textSecondary)
                }
                Text(eqVM.eq.nxName)
                    .font(NX.ndot(20))
                    .tracking(1)
                    .foregroundColor(NX.textPrimary)
                EQCurveView(
                    profile: eqVM.eq,
                    customBass: eqVM.customBass,
                    customMid: eqVM.customMid,
                    customTreble: eqVM.customTreble
                )
                Spacer(minLength: 0)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 26)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .nxCard()
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick settings

    private var quickSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            NXSectionLabel("QUICK SETTINGS")
            Toggle(settingsVM.isSingleUnit ? "WEAR DETECTION" : "IN-EAR DETECTION", isOn: inEarBinding)
                .toggleStyle(NXSwitch())
            Toggle("LOW LAG MODE", isOn: lowLagBinding)
                .toggleStyle(NXSwitch())
            Spacer(minLength: 0)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .nxCard()
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
