//
//  NXQuickPanel.swift
//  Nothing X MacOS
//
//  Compact menu bar panel: noise control, EQ presets, battery and a
//  shortcut to the full Nothing X window.
//

import SwiftUI

struct NXQuickPanel: View {
    @EnvironmentObject var mainViewModel: MainViewViewModel

    @StateObject private var noiseVM = NoiseControlViewViewModel(nothingService: NothingServiceImpl.shared)
    @StateObject private var eqVM = EqualizerViewViewModel(nothingService: NothingServiceImpl.shared)
    @StateObject private var connectVM = ConnectViewViewModel(nothingRepository: NothingRepositoryImpl.shared, nothingService: NothingServiceImpl.shared, bluetoothService: BluetoothServiceImpl())

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 14) {
            header

            if mainViewModel.isConnected {
                NXSegmented(
                    options: [
                        (NoiseControlOptions.anc, "ANC"),
                        (.transparency, "TRANSP."),
                        (.off, "OFF"),
                    ],
                    selection: Binding(
                        get: { noiseVM.anc },
                        set: {
                            noiseVM.anc = $0 // move the capsule before the device round-trip
                            noiseVM.switchANC(anc: noiseVM.noiseControlOptionsToAnc(option: $0))
                        }
                    ),
                    fontSize: 9
                )
                .frame(height: 40)

                HStack(spacing: 6) {
                    ForEach(eqPresets, id: \.self) { preset in
                        Button(chipName(preset)) {
                            eqVM.eq = preset // select before the device round-trip
                            eqVM.switchEQ(eq: preset)
                        }
                        .buttonStyle(QuickChip(selected: eqVM.eq == preset))
                    }
                }

                HStack(spacing: 14) {
                    if isSingleUnit {
                        batteryColumn("BATT", level: mainViewModel.leftBattery.map(Int.init))
                    } else {
                        batteryColumn("L", level: mainViewModel.leftBattery.map(Int.init))
                        batteryColumn("R", level: mainViewModel.rightBattery.map(Int.init))
                    }
                }
            } else {
                Text(connectVM.isLoading ? "CONNECTING…" : "NOT CONNECTED")
                    .font(.system(size: 10, weight: .light))
                    .tracking(1.6)
                    .foregroundColor(NX.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            footer
        }
        .padding(16)
        .frame(width: 280)
        .background(Color.black)
        .preferredColorScheme(.dark)
        .onAppear {
            // Reconnect automatically, like the old popover did on open.
            // Deferred: onAppear runs mid view-update, mutating @Published
            // there is undefined behavior.
            DispatchQueue.main.async {
                connectVM.checkBluetoothStatus()
                if !mainViewModel.isConnected && connectVM.isBluetoothOn && !connectVM.isLoading {
                    connectVM.connect()
                }
            }
        }
    }

    private var eqPresets: [EQProfiles] { [.BALANCED, .MORE_BASE, .MORE_TREBEL, .VOICE] }

    private func chipName(_ preset: EQProfiles) -> String {
        switch preset {
        case .MORE_BASE: return "BASS"
        case .MORE_TREBEL: return "TREBLE"
        default: return preset.nxName
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(mainViewModel.isConnected ? NX.capsule : NX.textFaint)
                    .frame(width: 5, height: 5)
                Text(mainViewModel.nothingDevice?.nxShortName ?? "NOTHING X")
                    .font(NX.ndot(12))
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundColor(NX.textPrimary)
            }
            Spacer()
            if mainViewModel.isConnected {
                Text(batteryLine)
                    .font(NX.pixel(10))
                    .tracking(1)
                    .foregroundColor(NX.textSecondary)
            }
        }
    }

    private var isSingleUnit: Bool {
        mainViewModel.nothingDevice.map { DeviceCapabilities.capabilities(for: $0.codename).isSingleUnit } ?? false
    }

    private var batteryLine: String {
        if isSingleUnit {
            return mainViewModel.leftBattery.map { "\(Int($0))" } ?? "–"
        }
        let left = mainViewModel.leftBattery.map { "\(Int($0))" } ?? "–"
        let right = mainViewModel.rightBattery.map { "\(Int($0))" } ?? "–"
        if let device = mainViewModel.nothingDevice, device.isCaseConnected {
            return "\(left) · \(right) · \(device.caseBattery)"
        }
        return "\(left) · \(right)"
    }

    private func batteryColumn(_ label: String, level: Int?) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 9))
                    .tracking(1.6)
                    .foregroundColor(NX.textTertiary)
                Spacer()
                Text(level.map { "\($0)%" } ?? "–")
                    .font(NX.pixel(10))
                    .foregroundColor(NX.offWhite)
            }
            NXBatteryBar(level: level, segmentHeight: 5)
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Button {
                openWindow(id: "nothing-x")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                HStack(spacing: 8) {
                    Text("OPEN NOTHING X")
                        .tracking(1.6)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                }
                .font(.system(size: 10))
                .foregroundColor(NX.offWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Capsule().fill(NX.track))
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)

            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
                    .font(.system(size: 11))
                    .foregroundColor(NX.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(NX.track))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Quit Nothing X")
        }
    }
}

private struct QuickChip: ButtonStyle {
    var selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 9))
            .tracking(0.8)
            .foregroundColor(selected ? NX.onCapsule : NX.offWhite)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(Capsule().fill(selected ? NX.capsule : NX.track))
            .contentShape(Capsule())
    }
}
