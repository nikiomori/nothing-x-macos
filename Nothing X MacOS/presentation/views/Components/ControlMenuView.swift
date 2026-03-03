//
//  ControlMenuView.swift
//  Nothing X MacOS
//
//  Created by Arunavo Ray on 22/02/23.
//

import SwiftUI

struct ControlMenuView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var mainViewModel: MainViewViewModel

    private var capabilities: DeviceCapabilities? {
        guard let device = mainViewModel.nothingDevice else { return nil }
        return DeviceCapabilities.capabilities(for: device.codename)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Triple Tap
            NavigationLink(value: Destination.controlsTripleTap) {
                HStack {
                    VStack(alignment: .leading) {
                        HStack{
                            Text("TRIPLE TAP")
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 4, height: 4)
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 4, height: 4)
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 4, height: 4)
                            }
                        }

                        Spacer(minLength: 2)

                        Text(self.store.selectedTripleTapOp[store.earBudSelectedSide == EarBudSide.left.rawValue ? 0 : 1].rawValue.capitalized)
                                .fontWeight(.ultraLight)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                }
            }
            .frame(width: 220, height: 42)
            .buttonStyle(ControlTapButton())

            // Double Tap (conditional)
            if capabilities?.supportsDoubleTap == true {
                NavigationLink(value: Destination.controlsDoubleTap) {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack{
                                Text("DOUBLE TAP")
                                HStack(spacing: 2) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 4, height: 4)
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 4, height: 4)
                                }
                            }

                            Spacer(minLength: 2)

                            Text(doubleTapLabel)
                                .fontWeight(.ultraLight)

                            Spacer(minLength: 2)

                            Text("Answer / hang up calls")
                                .fontWeight(.ultraLight)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 220, height: 58)
                .buttonStyle(ControlTapButton())
            }

            // Tap & Hold
            NavigationLink(value: Destination.controlsTapHold) {
                HStack {
                    VStack(alignment: .leading) {
                        HStack{
                            Text("TAP & HOLD")
                            HStack(spacing: 0) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 4, height: 4)
                                Rectangle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 1)
                            }
                        }

                        Spacer(minLength: 2)

                        Text(self.store.selectedtapAndHoldOp[store.earBudSelectedSide == EarBudSide.left.rawValue ? 0 : 1].rawValue.capitalized)
                            .fontWeight(.ultraLight)

                        Spacer(minLength: 2)

                        Text(self.store.fixedtapAndHoldOp.capitalized)
                            .fontWeight(.ultraLight)
                    }

                    Spacer()

                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                }
            }
            .frame(width: 220, height: 58)
            .buttonStyle(ControlTapButton())

            // Double Tap & Hold (conditional)
            if capabilities?.supportsDoubleTapAndHold == true {
                NavigationLink(value: Destination.controlsDoubleTapHold) {
                    HStack {
                        VStack(alignment: .leading) {
                            HStack{
                                Text("DOUBLE TAP & HOLD")
                                HStack(spacing: 0) {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 4, height: 4)
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 4, height: 4)
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 1)
                                }
                            }

                            Spacer(minLength: 2)

                            Text(doubleTapAndHoldLabel)
                                .fontWeight(.ultraLight)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 220, height: 42)
                .buttonStyle(ControlTapButton())
            }
        }
    }

    private var doubleTapLabel: String {
        guard let device = mainViewModel.nothingDevice else { return "Play / pause" }
        let isLeft = store.earBudSelectedSide == EarBudSide.left.rawValue
        let action = isLeft ? device.doubleTapGestureActionLeft : device.doubleTapGestureActionRight
        switch action {
        case .PLAY_PAUSE: return "Play / pause"
        case .SKIP_BACK: return "Skip back"
        case .SKIP_FORWARD: return "Skip forward"
        case .VOICE_ASSISTANT: return "Voice assistant"
        case .NO_EXTRA_ACTION: return "No action"
        }
    }

    private var doubleTapAndHoldLabel: String {
        guard let device = mainViewModel.nothingDevice else { return "No action" }
        let isLeft = store.earBudSelectedSide == EarBudSide.left.rawValue
        let action = isLeft ? device.doubleTapAndHoldGestureActionLeft : device.doubleTapAndHoldGestureActionRight
        if action.isNoiseControl { return "Noise control" }
        switch action {
        case .VOLUME_UP: return "Volume up"
        case .VOLUME_DOWN: return "Volume down"
        case .VOICE_ASSISTANT: return "Voice assistant"
        default: return "No action"
        }
    }
}

struct ControlMenuView_Previews: PreviewProvider {
    static let store = Store()
    static var previews: some View {
        ControlMenuView().environmentObject(store)
            .environmentObject(MainViewViewModel(bluetoothService: BluetoothServiceImpl(), nothingRepository: NothingRepositoryImpl.shared, nothingService: NothingServiceImpl.shared))
    }
}
