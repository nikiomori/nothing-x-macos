//
//  NXSettingsScreen.swift
//  Nothing X MacOS
//
//  Window settings: app preferences, device toggles and device details.
//

import SwiftUI

struct NXSettingsScreen: View {
    @EnvironmentObject var store: Store
    @StateObject private var viewModel = SettingsViewViewModel(nothingService: NothingServiceImpl.shared, nothingRepository: NothingRepositoryImpl.shared)
    @State private var isEditingCaseLED = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("SETTINGS")
                .font(NX.ndot(24))
                .tracking(2)
                .foregroundColor(NX.textPrimary)

            HStack(alignment: .top, spacing: 40) {
                leftColumn
                rightColumn
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 40)
    }

    // MARK: - App & device settings

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("APP SETTINGS")

            VStack(alignment: .leading, spacing: 10) {
                Text("MENU BAR BATTERY")
                    .font(.system(size: 10, weight: .light))
                    .tracking(1.4)
                    .foregroundColor(NX.offWhite)
                NXSegmented(
                    options: BatteryDisplayMode.allCases.map { ($0, $0.label) },
                    selection: $store.batteryDisplayMode,
                    fontSize: 10
                )
                .frame(width: 252, height: 34)
                Text(batteryModeCaption)
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(NX.textTertiary)
            }

            Divider().overlay(NX.hairline)

            sectionTitle("DEVICE SETTINGS")

            VStack(alignment: .leading, spacing: 16) {
                deviceToggle(
                    viewModel.isSingleUnit ? "WEAR DETECTION" : "IN-EAR DETECTION",
                    caption: viewModel.isSingleUnit
                        ? "Automatically play audio when the headphones are on and pause when taken off."
                        : "Automatically play audio when earbuds are in and pause when removed.",
                    isOn: Binding(
                        get: { viewModel.inEarSwitch },
                        set: { viewModel.inEarSwitch = $0; viewModel.switchInEarDetection(mode: $0) }
                    )
                )
                deviceToggle(
                    "LOW LAG MODE",
                    caption: "Minimize latency for an improved gaming experience.",
                    isOn: Binding(
                        get: { viewModel.latencySwitch },
                        set: { viewModel.latencySwitch = $0; viewModel.switchLatency(mode: $0) }
                    )
                )
                if viewModel.supportsPersonalizedANC {
                    deviceToggle(
                        "PERSONALIZED ANC",
                        caption: "Noise cancellation calibrated to your hearing.",
                        isOn: Binding(
                            get: { viewModel.personalizedANCSwitch },
                            set: { viewModel.personalizedANCSwitch = $0; viewModel.switchPersonalizedANC(mode: $0) }
                        )
                    )
                }
                if viewModel.supportsCaseLED {
                    Button {
                        isEditingCaseLED = true
                    } label: {
                        HStack {
                            Text("CASE LED COLOR")
                                .font(.system(size: 11, weight: .light))
                                .tracking(1)
                                .foregroundColor(NX.offWhite)
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                                .foregroundColor(NX.textSecondary)
                        }
                        .padding(.vertical, 12)
                        .overlay(alignment: .top) { NX.hairline.frame(height: 1) }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $isEditingCaseLED) { CaseLEDSheet() }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var batteryModeCaption: String {
        switch store.batteryDisplayMode {
        case .both: return "Show both values when different (75·85%)"
        case .average: return "Show the average of both earbuds"
        case .minimum: return "Show the lowest of both earbuds"
        }
    }

    private func deviceToggle(_ title: String, caption: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .light))
                    .tracking(1)
                    .foregroundColor(NX.offWhite)
                Text(caption)
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(NX.textTertiary)
                    .frame(maxWidth: 300, alignment: .leading)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(NXSwitch())
                .labelsHidden()
        }
    }

    // MARK: - Device details

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("DEVICE DETAILS")

            VStack(alignment: .leading, spacing: 16) {
                detailRow("DEVICE NAME", value: viewModel.name, mono: false)
                detailRow("BLUETOOTH ADDRESS", value: viewModel.mac, mono: true)
                detailRow("SERIAL NUMBER", value: viewModel.serial, mono: true)
                detailRow("FIRMWARE VERSION", value: viewModel.firmware, mono: true)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .nxCard()

            Button("FORGET THIS DEVICE") { viewModel.shouldShowForgetDialog = true }
                .buttonStyle(ForgetButton())
                .confirmationDialog("Forget this device?", isPresented: $viewModel.shouldShowForgetDialog) {
                    Button("Forget", role: .destructive) { viewModel.forgetDevice() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("The device will be removed from Nothing X. You can pair it again later.")
                }
        }
        .frame(width: 300)
    }

    private func detailRow(_ label: String, value: String, mono: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9))
                .tracking(2)
                .foregroundColor(NX.textTertiary)
            Text(value.isEmpty ? "–" : value)
                .font(mono ? NX.pixel(11) : .system(size: 12, weight: .light))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(NX.ndot(13))
            .tracking(1.5)
            .foregroundColor(NX.offWhite)
    }
}

private struct CaseLEDSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CaseLEDViewModel(nothingService: NothingServiceImpl.shared)

    private let labels = ["High battery", "Mid battery", "Low battery", "Charging", "Fully charged"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("CASE LED COLOR")
                    .font(NX.ndot(16))
                    .tracking(2)
                    .foregroundColor(NX.textPrimary)
                Text("Customise the LED colors on your charging case.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(NX.textSecondary)
            }

            VStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        Text(labels[index].uppercased())
                            .font(.system(size: 11, weight: .light))
                            .tracking(1)
                            .foregroundColor(NX.offWhite)
                        Spacer()
                        ColorPicker("", selection: $viewModel.colors[index], supportsOpacity: false)
                            .labelsHidden()
                    }
                    .padding(.vertical, 10)
                    if index < 4 { Divider().overlay(NX.cardBorder) }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 20)
            .nxCard()

            HStack(spacing: 10) {
                Button("CANCEL") { dismiss() }
                    .buttonStyle(NXConnectPill(filled: false))
                    .frame(height: 40)
                Button("APPLY") {
                    viewModel.applyColors()
                    dismiss()
                }
                .buttonStyle(NXFilledPill())
                .frame(height: 40)
            }
        }
        .padding(28)
        .frame(width: 360)
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

private struct ForgetButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11))
            .tracking(1.8)
            .foregroundColor(NX.red)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Capsule().stroke(Color(nx: 0x3A1214)))
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
