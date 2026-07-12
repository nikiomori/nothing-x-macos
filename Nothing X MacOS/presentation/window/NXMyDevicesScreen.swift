//
//  NXMyDevicesScreen.swift
//  Nothing X MacOS
//
//  Window device switcher: saved devices grid and pairing entry point.
//

import SwiftUI

struct NXMyDevicesScreen: View {
    @EnvironmentObject var mainViewModel: MainViewViewModel
    @StateObject private var connectVM = ConnectViewViewModel(nothingRepository: NothingRepositoryImpl.shared, nothingService: NothingServiceImpl.shared, bluetoothService: BluetoothServiceImpl())
    @State private var isPairing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("MY DEVICES")
                    .font(NX.ndot(24))
                    .tracking(2)
                    .foregroundColor(NX.textPrimary)
                Text("Switch between your paired Nothing and CMF audio devices.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(NX.textSecondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                ForEach(connectVM.savedDevices, id: \.serial) { device in
                    deviceTile(device)
                }
                pairNewTile
            }

            Spacer()
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 40)
        // loadSavedDevices is deferred: onAppear/onChange run mid view-update,
        // mutating @Published there is undefined behavior
        .onAppear { DispatchQueue.main.async { connectVM.loadSavedDevices() } }
        .onChange(of: mainViewModel.nothingDevice?.serial) { _ in
            // A new device finished pairing or the active device switched
            isPairing = false
            DispatchQueue.main.async { connectVM.loadSavedDevices() }
        }
        .sheet(isPresented: $isPairing) {
            NXConnectScreen(discoverOnly: true)
                .frame(width: 560, height: 620)
                .background(Color.black)
                .overlay(alignment: .topTrailing) {
                    Button { isPairing = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundColor(NX.textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(NX.track))
                    }
                    .buttonStyle(.plain)
                    .padding(16)
                }
        }
    }

    private func isConnected(_ device: NothingDeviceEntity) -> Bool {
        mainViewModel.isConnected && mainViewModel.nothingDevice?.bluetoothDetails.mac == device.bluetoothDetails.mac
    }

    private func deviceTile(_ device: NothingDeviceEntity) -> some View {
        let connected = isConnected(device)
        return VStack(spacing: 6) {
            HStack(spacing: 6) {
                if connected {
                    Circle().fill(NX.red).frame(width: 5, height: 5)
                }
                Text(connected ? "CONNECTED" : "PAIRED")
                    .font(.system(size: 8))
                    .tracking(1.8)
                    .foregroundColor(connected ? NX.capsule : Color(nx: 0x5A5A5C))
                Spacer()
            }

            Spacer(minLength: 0)
            NXBudsImage(codename: device.codename, height: 70)
            Spacer(minLength: 0)

            Text(device.nxShortName)
                .font(NX.ndot(12))
                .tracking(1)
                .foregroundColor(connected ? NX.textPrimary : .white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if connected {
                Text(mainViewModel.nxBatteryLine)
                    .font(NX.pixel(9))
                    .tracking(1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(NX.textSecondary)
            } else {
                Button("CONNECT") { connectVM.connect(device: device) }
                    .buttonStyle(NXConnectPill(filled: false))
                    .frame(width: 82, height: 22)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(height: 170)
        .background(NX.card)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(connected ? Color(nx: 0x3A3B3D) : NX.cardBorder))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var pairNewTile: some View {
        Button {
            isPairing = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 14))
                    .foregroundColor(Color(nx: 0x5A5A5C))
                Text("PAIR NEW DEVICE")
                    .font(.system(size: 9))
                    .tracking(1.8)
                    .foregroundColor(Color(nx: 0x5A5A5C))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 170)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundColor(Color(nx: 0x2A2B2D))
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

}
