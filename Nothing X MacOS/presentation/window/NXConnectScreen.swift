//
//  NXConnectScreen.swift
//  Nothing X MacOS
//
//  Window connect state: discover new devices and reconnect saved ones.
//

import SwiftUI

struct NXConnectScreen: View {
    /// When true (pair-new-device flow) saved devices are hidden and only
    /// discovery results are shown.
    var discoverOnly = false

    @StateObject private var connectVM = ConnectViewViewModel(nothingRepository: NothingRepositoryImpl.shared, nothingService: NothingServiceImpl.shared, bluetoothService: BluetoothServiceImpl())
    @StateObject private var discoverVM = DiscoverStartedViewViewModel(nothingService: NothingServiceImpl.shared)

    var body: some View {
        VStack(spacing: 32) {
            rings
            VStack(spacing: 10) {
                Text(title)
                    .font(NX.ndot(20))
                    .tracking(2)
                    .foregroundColor(NX.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(NX.textSecondary)
            }
            .padding(.top, -16)

            deviceList
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // deferred: onAppear runs mid view-update, mutating @Published there
            // is undefined behavior
            DispatchQueue.main.async {
                connectVM.checkBluetoothStatus()
                connectVM.loadSavedDevices()
                if connectVM.isBluetoothOn {
                    discoverVM.startDiscovery()
                }
            }
        }
        .onDisappear { discoverVM.stopDeviceDiscovery() }
        // The screen otherwise only checks Bluetooth on appear and would stay
        // on "BLUETOOTH IS OFF" after the radio comes back
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(BluetoothNotifications.BLUETOOTH_ON.rawValue)).receive(on: RunLoop.main)) { _ in
            connectVM.checkBluetoothStatus()
            discoverVM.startDiscovery()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name(BluetoothNotifications.BLUETOOTH_OFF.rawValue)).receive(on: RunLoop.main)) { _ in
            connectVM.checkBluetoothStatus()
        }
    }

    private var rings: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
                    .foregroundColor(.white.opacity(0.08 + Double(ring) * 0.1))
                    .frame(width: 340 - CGFloat(ring) * 104, height: 340 - CGFloat(ring) * 104)
            }
            NXBudsImage(codename: connectVM.savedDevices.first?.codename, height: 100)
        }
        .frame(width: 340, height: 340)
    }

    private var isBusy: Bool { connectVM.isLoading || discoverVM.viewState == .connecting }
    private var hasFailed: Bool { connectVM.isFailedToConnectPresented || discoverVM.viewState == .failed_to_connect }

    private var title: String {
        if !connectVM.isBluetoothOn { return "BLUETOOTH IS OFF" }
        if isBusy { return "CONNECTING" }
        if hasFailed { return "FAILED TO CONNECT" }
        if discoverVM.viewState == .found { return "DEVICE FOUND" }
        if discoverVM.viewState == .not_found && visibleSavedDevices.isEmpty { return "NO DEVICES FOUND" }
        return "SEARCHING FOR DEVICES"
    }

    private var subtitle: String {
        if !connectVM.isBluetoothOn { return "Turn on Bluetooth to connect your earbuds." }
        return "Make sure your earbuds are in pairing mode."
    }

    private var visibleSavedDevices: [NothingDeviceEntity] {
        discoverOnly ? [] : connectVM.savedDevices
    }

    @ViewBuilder
    private var deviceList: some View {
        if !connectVM.isBluetoothOn || isBusy {
            EmptyView()
        } else if hasFailed {
            Button("RETRY") {
                if discoverVM.viewState == .failed_to_connect {
                    discoverVM.connectToDevice()
                } else {
                    connectVM.retryConnect()
                }
            }
            .buttonStyle(NXFilledPill())
            .frame(width: 200, height: 40)
        } else {
            VStack(spacing: 10) {
                if discoverVM.viewState == .found {
                    deviceRow(
                        name: discoverVM.deviceName.uppercased(),
                        caption: "READY TO PAIR",
                        codename: nil,
                        primary: true
                    ) { discoverVM.connectToDevice() }
                }
                ForEach(visibleSavedDevices, id: \.serial) { device in
                    deviceRow(
                        name: device.name.uppercased(),
                        caption: "PAIRED PREVIOUSLY",
                        codename: device.codename,
                        primary: false
                    ) { connectVM.connect(device: device) }
                }
                if discoverVM.viewState == .not_found && visibleSavedDevices.isEmpty {
                    Button("RETRY") { discoverVM.startDiscovery() }
                        .buttonStyle(NXFilledPill())
                        .frame(width: 200, height: 40)
                }
            }
            .frame(width: 440)
        }
    }

    private func deviceRow(name: String, caption: String, codename: Codenames?, primary: Bool, connect: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            NXBudsImage(codename: codename, height: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(NX.ndot(13))
                    .tracking(1)
                    .foregroundColor(primary ? NX.textPrimary : .white.opacity(0.85))
                Text(caption)
                    .font(.system(size: 9))
                    .tracking(1.8)
                    .foregroundColor(NX.textTertiary)
            }
            Spacer()
            Button("CONNECT", action: connect)
                .buttonStyle(NXConnectPill(filled: primary))
                .frame(width: 110, height: 32)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)
        .background(NX.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(primary ? Color(nx: 0x2A2B2D) : NX.cardBorder))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct NXConnectPill: ButtonStyle {
    var filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10))
            .tracking(1.6)
            .foregroundColor(filled ? NX.onCapsule : NX.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if filled {
                    Capsule().fill(NX.capsule)
                } else {
                    Capsule().stroke(NX.chipBorder)
                }
            }
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
