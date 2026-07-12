//
//  NXWindowView.swift
//  Nothing X MacOS
//
//  Root of the full-window interface: sidebar navigation + detail screens.
//

import SwiftUI

enum NXSection: String, CaseIterable, Identifiable {
    case dashboard = "DASHBOARD"
    case equaliser = "EQUALISER"
    case controls = "CONTROLS"
    case findMyBuds = "FIND MY BUDS"
    case earTipFit = "EAR TIP FIT TEST"
    case settings = "SETTINGS"
    case devices = "MY DEVICES" // reached from the sidebar device card, not the nav list

    var id: String { rawValue }
}

struct NXWindowView: View {
    @EnvironmentObject var mainViewModel: MainViewViewModel
    @EnvironmentObject var store: Store
    @State private var section: NXSection = .dashboard

    private var capabilities: DeviceCapabilities? {
        mainViewModel.nothingDevice.map { DeviceCapabilities.capabilities(for: $0.codename) }
    }

    private var sections: [NXSection] {
        NXSection.allCases.filter {
            switch $0 {
            case .controls, .findMyBuds: return capabilities?.isSingleUnit != true
            case .earTipFit: return capabilities?.supportsEarTipTest == true
            case .devices: return false
            default: return true
            }
        }
    }

    var body: some View {
        Group {
            if mainViewModel.isConnected {
                HStack(spacing: 0) {
                    sidebar
                    detail
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            } else {
                NXConnectScreen()
            }
        }
        .frame(width: 1060, height: 700)
        .background(Color.black)
        .preferredColorScheme(.dark)
        .onChange(of: mainViewModel.nothingDevice?.codename) { _ in
            // Switching devices can remove the current section from the nav
            if !sections.contains(section) && section != .devices {
                section = .dashboard
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch section {
        case .dashboard: NXDashboardScreen(section: $section)
        case .equaliser: NXEqualizerScreen()
        case .controls: NXControlsScreen()
        case .findMyBuds: NXFindMyBudsScreen()
        case .earTipFit: NXEarTipTestScreen()
        case .settings: NXSettingsScreen()
        case .devices: NXMyDevicesScreen()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            deviceCard
                .padding(.horizontal, 12)
                .padding(.top, 44) // clears the window traffic lights
                .padding(.bottom, 14)

            VStack(spacing: 0) {
                ForEach(sections) { item in
                    navRow(item)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            footer
        }
        .frame(width: 240)
        .frame(maxHeight: .infinity)
        .background(NX.sidebar)
        .overlay(alignment: .trailing) { NX.sidebarBorder.frame(width: 1) }
    }

    private var deviceCard: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { section = .devices }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    NXBudsImage(codename: mainViewModel.nothingDevice?.codename, height: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(deviceName)
                            .font(NX.ndot(14))
                            .tracking(1)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .foregroundColor(NX.textPrimary)
                        HStack(spacing: 6) {
                            Circle().fill(NX.capsule).frame(width: 5, height: 5)
                            Text("CONNECTED")
                                .font(.system(size: 9))
                                .tracking(1.4)
                                .foregroundColor(NX.textTertiary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(Color(nx: 0x5A5A5C))
                }
                Divider().overlay(NX.deviceCardBorder)
                Text(batteryLine)
                    .font(NX.pixel(10))
                    .tracking(1)
                    .foregroundColor(NX.textSecondary)
            }
            .padding(14)
            .background(NX.deviceCard)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(NX.deviceCardBorder))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func navRow(_ item: NXSection) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { section = item }
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(section == item ? NX.red : .clear)
                    .frame(width: 4, height: 4)
                Text(item.rawValue)
                    .font(.system(size: 11))
                    .tracking(1.8)
                    .foregroundColor(section == item ? NX.textPrimary : NX.textTertiary)
                Spacer()
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(section == item ? NX.hairline : .clear))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Text("NOTHING X · \(appVersion)")
                .font(NX.pixel(9))
                .tracking(1.6)
                .foregroundColor(NX.textFaint)
            Spacer()
            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power")
                    .font(.system(size: 11))
                    .foregroundColor(NX.textTertiary)
            }
            .buttonStyle(.plain)
            .help("Quit Nothing X")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .overlay(alignment: .top) { NX.hairline.frame(height: 1) }
    }

    private var deviceName: String {
        mainViewModel.nothingDevice?.nxShortName ?? "NOTHING"
    }

    private var batteryLine: String {
        mainViewModel.nxBatteryLine
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
    }
}
