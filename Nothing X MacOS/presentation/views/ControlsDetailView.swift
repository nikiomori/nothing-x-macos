//
//  ControlsDetailView.swift
//  Nothing X MacOS
//
//  Created by Arunavo Ray on 23/02/23.
//

import SwiftUI

struct ControlsDetailView: View {
    @EnvironmentObject var store: Store
    var destination: Destination
    @State private var selectedTripleAction = TripleTapOptions.skip_forward
    @State private var selectedTapAndHoldAction = TapAndHoldOptions.no_extra_action
    @State private var selectedDoubleTapAction = DoubleTapOptions.play_pause
    @State private var selectedDoubleTapAndHoldAction = DoubleTapAndHoldOptions.no_extra_action

    @EnvironmentObject var mainViewModel: MainViewViewModel
    @EnvironmentObject var budsPickerViewModel: BudsPickerComponentViewModel
    @State var viewModel: ControlsDetailViewViewModel = ControlsDetailViewViewModel(nothingService: NothingServiceImpl.shared)

    @Binding var leftTripleTapAction: TripleTapGestureActions
    @Binding var rightTripleTapAction: TripleTapGestureActions
    @Binding var leftTapAndHoldAction: TapAndHoldGestureActions
    @Binding var rightTapAndHoldAction: TapAndHoldGestureActions
    @Binding var leftDoubleTapAction: DoubleTapGestureActions
    @Binding var rightDoubleTapAction: DoubleTapGestureActions
    @Binding var leftDoubleTapAndHoldAction: DoubleTapAndHoldGestureActions
    @Binding var rightDoubleTapAndHoldAction: DoubleTapAndHoldGestureActions
    
    var body: some View {
        VStack {
            
            ZStack(alignment: .top) {
                
            // Back - Heading - Settings | Quit
                HStack {
                    // Back
                    BackButtonView()
                    
                    Spacer()
                    
                }
                .zIndex(1)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(1.0), Color.black.opacity(0.0)]), startPoint: .top, endPoint: .bottom)
                )
                
            
            
            
            ScrollView(.vertical, showsIndicators: false) {
                
                
                VStack {
                    BudsPickerComponent(action: {
                        selection in

                        withAnimation {
                            switch selection {
                            case .LEFT:
                                selectedTripleAction = viewModel.convertTripleTapActionToOption(action: leftTripleTapAction)
                                selectedTapAndHoldAction = viewModel.convertTapAndHoldActionToOption(action: leftTapAndHoldAction)
                                selectedDoubleTapAction = viewModel.convertDoubleTapActionToOption(action: leftDoubleTapAction)
                                selectedDoubleTapAndHoldAction = viewModel.convertDoubleTapAndHoldActionToOption(action: leftDoubleTapAndHoldAction)
                            case .RIGHT:
                                selectedTripleAction = viewModel.convertTripleTapActionToOption(action: rightTripleTapAction)
                                selectedTapAndHoldAction = viewModel.convertTapAndHoldActionToOption(action: rightTapAndHoldAction)
                                selectedDoubleTapAction = viewModel.convertDoubleTapActionToOption(action: rightDoubleTapAction)
                                selectedDoubleTapAndHoldAction = viewModel.convertDoubleTapAndHoldActionToOption(action: rightDoubleTapAndHoldAction)
                            }
                        }
                    })
                        
                }
                .padding(.top, 32)
                
                
                // Radio Group Option Selection
                VStack {
                    
                    // Option Title
                    HStack{
                        if destination == .controlsTripleTap {
                            VStack {
                                HStack(spacing: 2) {
                                    Circle().fill(Color.red).frame(width: 4, height: 4)
                                    Circle().fill(Color.red).frame(width: 4, height: 4)
                                    Circle().fill(Color.red).frame(width: 4, height: 4)
                                }
                                .padding(.bottom, 2)
                                Text("TRIPLE TAP").font(.system(size: 10, weight:.light))
                            }
                        } else if destination == .controlsDoubleTap {
                            VStack {
                                HStack(spacing: 2) {
                                    Circle().fill(Color.red).frame(width: 4, height: 4)
                                    Circle().fill(Color.red).frame(width: 4, height: 4)
                                }
                                .padding(.bottom, 2)
                                Text("DOUBLE TAP").font(.system(size: 10, weight:.light))
                            }
                        } else if destination == .controlsDoubleTapHold {
                            VStack {
                                HStack(spacing: 0) {
                                    Circle().fill(Color.red).frame(width: 4, height: 4)
                                    Circle().fill(Color.red).frame(width: 4, height: 4)
                                    Rectangle().fill(Color.red).frame(width: 8, height: 1)
                                }
                                .padding(.bottom, 2)
                                Text("DOUBLE TAP & HOLD").font(.system(size: 10, weight:.light))
                            }
                        } else {
                            VStack {
                                HStack(spacing: 0) {
                                    Circle().fill(Color.red).frame(width: 4, height: 4)
                                    Rectangle().fill(Color.red).frame(width: 8, height: 1)
                                }
                                .padding(.bottom, 2)
                                Text("TAP & HOLD")
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if destination == .controlsTripleTap {
                        radioGroup(options: TripleTapOptions.allCases, selected: selectedTripleAction) { option in
                            viewModel.switchTripleTapAction(device: budsPickerViewModel.selection, action: option)
                            withAnimation { selectedTripleAction = option }
                        }
                    } else if destination == .controlsDoubleTap {
                        radioGroup(options: DoubleTapOptions.allCases, selected: selectedDoubleTapAction) { option in
                            viewModel.switchDoubleTapAction(device: budsPickerViewModel.selection, action: option)
                            withAnimation { selectedDoubleTapAction = option }
                        }

                        Divider().frame(width: 140)

                        HStack {
                            Text("Answer / hang up calls")
                                .padding(4)
                            Spacer()
                        }
                    } else if destination == .controlsDoubleTapHold {
                        radioGroup(options: DoubleTapAndHoldOptions.allCases, selected: selectedDoubleTapAndHoldAction) { option in
                            viewModel.switchDoubleTapAndHoldAction(device: budsPickerViewModel.selection, action: option)
                            withAnimation { selectedDoubleTapAndHoldAction = option }
                        }

                        // ANC Cycle Configuration for Double Tap & Hold
                        if selectedDoubleTapAndHoldAction == .noise_control,
                           let device = mainViewModel.nothingDevice,
                           DeviceCapabilities.capabilities(for: device.codename).supportsANCCycleConfig {
                            ancCycleToggles(
                                ancOn: $viewModel.dthAncCycleANC,
                                transparencyOn: $viewModel.dthAncCycleTransparency,
                                offOn: $viewModel.dthAncCycleOff,
                                onUpdate: { viewModel.updateDTHANCCycle(device: budsPickerViewModel.selection) }
                            )
                        }
                    } else {
                        // Tap & Hold
                        radioGroup(options: TapAndHoldOptions.allCases, selected: selectedTapAndHoldAction) { option in
                            viewModel.switchTapAndHoldAction(device: budsPickerViewModel.selection, action: option)
                            withAnimation { selectedTapAndHoldAction = option }
                        }

                        // ANC Cycle Configuration
                        if selectedTapAndHoldAction == .noise_control,
                           let device = mainViewModel.nothingDevice,
                           DeviceCapabilities.capabilities(for: device.codename).supportsANCCycleConfig {
                            ancCycleToggles(
                                ancOn: $viewModel.ancCycleANC,
                                transparencyOn: $viewModel.ancCycleTransparency,
                                offOn: $viewModel.ancCycleOff,
                                onUpdate: { viewModel.updateANCCycle(device: budsPickerViewModel.selection) }
                            )
                        }

                        Divider().frame(width: 140)

                        HStack {
                            Text(store.fixedtapAndHoldOp)
                                .padding(4)
                            Spacer()
                        }
                    }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .frame(width: 200)
                .padding(10)
                .background(Color(#colorLiteral(red: 0.10980392247438431, green: 0.11372549086809158, blue: 0.12156862765550613, alpha: 1)))
                .font(.system(size: 10, weight:.light)).foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
                .cornerRadius(6)
                .padding(.bottom, 30)
                
                Spacer()
                
            }
            }

            
            
        }
        .navigationBarBackButtonHidden(true)
        .background(.black)
        .frame(width: 250, height: 230)
        .onAppear {
            switch budsPickerViewModel.selection {
            case .LEFT:
                selectedTripleAction = viewModel.convertTripleTapActionToOption(action: leftTripleTapAction)
                selectedTapAndHoldAction = viewModel.convertTapAndHoldActionToOption(action: leftTapAndHoldAction)
                selectedDoubleTapAction = viewModel.convertDoubleTapActionToOption(action: leftDoubleTapAction)
                selectedDoubleTapAndHoldAction = viewModel.convertDoubleTapAndHoldActionToOption(action: leftDoubleTapAndHoldAction)
                viewModel.loadANCCycleState(from: leftTapAndHoldAction)
                viewModel.loadDTHANCCycleState(from: leftDoubleTapAndHoldAction)
            case .RIGHT:
                selectedTripleAction = viewModel.convertTripleTapActionToOption(action: rightTripleTapAction)
                selectedTapAndHoldAction = viewModel.convertTapAndHoldActionToOption(action: rightTapAndHoldAction)
                selectedDoubleTapAction = viewModel.convertDoubleTapActionToOption(action: rightDoubleTapAction)
                selectedDoubleTapAndHoldAction = viewModel.convertDoubleTapAndHoldActionToOption(action: rightDoubleTapAndHoldAction)
                viewModel.loadANCCycleState(from: rightTapAndHoldAction)
                viewModel.loadDTHANCCycleState(from: rightDoubleTapAndHoldAction)
            }
        }

    }

    // MARK: - Reusable Components

    @ViewBuilder
    private func radioGroup<T: RawRepresentable & Hashable>(options: [T], selected: T, onSelect: @escaping (T) -> Void) -> some View where T.RawValue == String {
        VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                HStack {
                    Text(option.rawValue)
                        .padding(4)
                        .textCase(.uppercase)
                    Spacer()

                    Button(action: { onSelect(option) }) {
                        Image(option == selected ? "radio_button_selected_dark" : "radio_button_not_selected_dark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 2)
                }
                .buttonStyle(TransparentButton())
            }
        }.padding(.bottom, 10)
    }

    @ViewBuilder
    private func ancCycleToggles(ancOn: Binding<Bool>, transparencyOn: Binding<Bool>, offOn: Binding<Bool>, onUpdate: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CYCLE MODES")
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))

            Toggle("ANC", isOn: ancOn)
                .toggleStyle(SwitchToggleStyle())
                .disabled(!ancOn.wrappedValue && [transparencyOn.wrappedValue, offOn.wrappedValue].filter { $0 }.count < 2)
                .onChange(of: ancOn.wrappedValue) { _ in onUpdate() }

            Toggle("Transparency", isOn: transparencyOn)
                .toggleStyle(SwitchToggleStyle())
                .disabled(!transparencyOn.wrappedValue && [ancOn.wrappedValue, offOn.wrappedValue].filter { $0 }.count < 2)
                .onChange(of: transparencyOn.wrappedValue) { _ in onUpdate() }

            Toggle("Off", isOn: offOn)
                .toggleStyle(SwitchToggleStyle())
                .disabled(!offOn.wrappedValue && [ancOn.wrappedValue, transparencyOn.wrappedValue].filter { $0 }.count < 2)
                .onChange(of: offOn.wrappedValue) { _ in onUpdate() }
        }
        .font(.system(size: 10, weight: .light))
        .foregroundColor(.white)
        .padding(.bottom, 6)
    }

}

struct ControlsDetailView_Previews: PreviewProvider {
    static let store = Store()

    struct PreviewWrapper: View {
        @State var leftTripleTapAction: TripleTapGestureActions = .NO_EXTRA_ACTION
        @State var rightTripleTapAction: TripleTapGestureActions = .SKIP_BACK
        @State var leftTapAndHoldAction: TapAndHoldGestureActions = .NO_EXTRA_ACTION
        @State var rightTapAndHoldAction: TapAndHoldGestureActions = .NOISE_CONTROL
        @State var leftDoubleTapAction: DoubleTapGestureActions = .PLAY_PAUSE
        @State var rightDoubleTapAction: DoubleTapGestureActions = .PLAY_PAUSE
        @State var leftDoubleTapAndHoldAction: DoubleTapAndHoldGestureActions = .NO_EXTRA_ACTION
        @State var rightDoubleTapAndHoldAction: DoubleTapAndHoldGestureActions = .NO_EXTRA_ACTION

        @State private var viewModel: BudsPickerComponentViewModel = BudsPickerComponentViewModel()
        var body: some View {
            ControlsDetailView(destination: .controlsTripleTap,
                               leftTripleTapAction: $leftTripleTapAction,
                               rightTripleTapAction: $rightTripleTapAction,
                               leftTapAndHoldAction: $leftTapAndHoldAction,
                               rightTapAndHoldAction: $rightTapAndHoldAction,
                               leftDoubleTapAction: $leftDoubleTapAction,
                               rightDoubleTapAction: $rightDoubleTapAction,
                               leftDoubleTapAndHoldAction: $leftDoubleTapAndHoldAction,
                               rightDoubleTapAndHoldAction: $rightDoubleTapAndHoldAction
            ).environmentObject(store)
                .environmentObject(MainViewViewModel(bluetoothService: BluetoothServiceImpl(), nothingRepository: NothingRepositoryImpl.shared, nothingService: NothingServiceImpl.shared))
                .environmentObject(viewModel)
        }
    }

    static var previews: some View {
        PreviewWrapper()
    }
}
