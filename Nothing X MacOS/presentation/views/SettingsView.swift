//
//  SettingsView.swift
//  Nothing X MacOS
//
//  Created by Arunavo Ray on 15/02/23.
//

import SwiftUI

struct SettingsView: View {
    
    @State var title: String? = "Forget This Device?"
    @State var text: String? = nil
    @State var topButtonText: String? = "Forget"
    @State var bottomButtonText: String? = "Cancel"
    
    
    @StateObject private var viewModel = SettingsViewViewModel(nothingService: NothingServiceImpl.shared, nothingRepository: NothingRepositoryImpl.shared)
    
    @EnvironmentObject private var mainViewModel: MainViewViewModel
    @EnvironmentObject private var store: Store

    private var batteryModeOffset: CGFloat {
        switch store.batteryDisplayMode {
        case .both: return -66
        case .average: return 0
        case .minimum: return 66
        }
    }

    private var batteryDisplayDescription: String {
        switch store.batteryDisplayMode {
        case .both: return "Show both values when different (75·85%)"
        case .average: return "Show average of left and right"
        case .minimum: return "Show lowest battery level"
        }
    }

    var body: some View {
        
        ZStack(alignment: .bottom) {
            
            VStack(spacing: 0) {
                
                // Back - Heading - Settings | Quit
                HStack {
                    // Back
                    BackButtonView()
                 
                    Spacer()
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    
                    VStack(alignment: .leading) {

                        HStack {
                            Text("App settings")
                                .font(.custom("NDOT45inspiredbyNOTHING", size: 10))
                                .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                                .multilineTextAlignment(.center)
                                .textCase(.uppercase)
                            Spacer()
                        }
                        .padding(.vertical, 6)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Menu bar battery")
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                                .textCase(.uppercase)

                            ZStack {
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(Color(#colorLiteral(red: 0.10980392247438431, green: 0.11372549086809158, blue: 0.12156862765550613, alpha: 1)))
                                    .frame(width: 200, height: 28)

                                Capsule()
                                    .frame(width: 62, height: 24)
                                    .foregroundColor(Color(#colorLiteral(red: 0.7568627595901489, green: 0.7607843279838562, blue: 0.7686274647712708, alpha: 1)))
                                    .offset(x: batteryModeOffset, y: 0)
                                    .animation(.bouncy(duration: 0.3), value: store.batteryDisplayMode)

                                HStack(spacing: 0) {
                                    ForEach(BatteryDisplayMode.allCases) { mode in
                                        Button(action: {
                                            store.batteryDisplayMode = mode
                                        }) {
                                            Text(mode.label)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(store.batteryDisplayMode == mode
                                                    ? Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.8))
                                                    : Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                                                .frame(width: 66, height: 28)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .frame(width: 200, height: 28)
                            }

                            Text(batteryDisplayDescription)
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                        }
                        .padding(.bottom, 12)

                        Rectangle()
                            .fill(Color(#colorLiteral(red: 0.07009194046, green: 0.07611755282, blue: 0.08425947279, alpha: 1)))
                            .frame(height: 0.8)
                            .padding(.bottom, 4)

                        HStack {
                            // Heading
                            Text("Device settings")
                                .font(.custom("NDOT45inspiredbyNOTHING", size: 10))

                                .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                                .multilineTextAlignment(.center)
                                .textCase(.uppercase)

                            Spacer()
                        }
                        .padding(.vertical, 6)
                        
                        VStack(alignment: .leading) {
                        
                        if viewModel.isNothingDeviceAccessible {
                            
                     
                                Text("Advanced features")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                                    .textCase(.uppercase)
                                    .padding(.top, 16)
                                // IN-EAR DETECT
                                
                                VStack(alignment: .leading) {
                                    Toggle("In-ear detection", isOn: $viewModel.inEarSwitch)
                                        .onChange(of: viewModel.inEarSwitch) { newValue in
                                            guard !viewModel.isUpdatingFromDevice else { return }
                                            viewModel.switchInEarDetection(mode: newValue)
                                        }
                                    
                                    Text("Automatically play audio when earbuds are in and pause when removed.")
                                        .font(.system(size: 10, weight: .light))
                                        .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                                        .padding(.trailing, 64)
                                }
                                .padding(.vertical, 6)
                                
                                VStack(alignment: .leading) {
                                    Toggle("Low lag mode", isOn: $viewModel.latencySwitch)
                                        .onChange(of: viewModel.latencySwitch) { newValue in
                                            guard !viewModel.isUpdatingFromDevice else { return }
                                            viewModel.switchLatency(mode: newValue)
                                        }
                                    
                                    Text("Minimize latency for an improved gaming experience.")
                                        .font(.system(size: 10, weight: .light))
                                        .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                                        .padding(.trailing, 64)
                                }
                                .padding(.vertical, 6)
                                
                                
                                // LOW LAG MODE
                                
                                
                                // Personalized ANC (Ear 2 only)
                                if viewModel.supportsPersonalizedANC {
                                    VStack(alignment: .leading) {
                                        Toggle("Personalized ANC", isOn: $viewModel.personalizedANCSwitch)
                                            .onChange(of: viewModel.personalizedANCSwitch) { newValue in
                                                guard !viewModel.isUpdatingFromDevice else { return }
                                                viewModel.switchPersonalizedANC(mode: newValue)
                                            }

                                        Text("Noise cancellation calibrated to your hearing.")
                                            .font(.system(size: 10, weight: .light))
                                            .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                                            .padding(.trailing, 64)
                                    }
                                    .padding(.vertical, 6)
                                }

                                // Ear Tip Fit Test
                                if viewModel.supportsEarTipTest {
                                    NavigationLink("EAR TIP FIT TEST", value: Destination.earTipTest)
                                        .buttonStyle(FindMyTransparentButton())
                                        .padding(.bottom, 4)
                                }

                                // Case LED Color (Ear 1 only)
                                if viewModel.supportsCaseLED {
                                    NavigationLink("CASE LED COLOR", value: Destination.caseLED)
                                        .buttonStyle(FindMyTransparentButton())
                                        .padding(.bottom, 4)
                                }

                                // Find My Earbuds
                                NavigationLink("FIND MY EARBUDS", value: Destination.findMyBuds)
                                    .buttonStyle(FindMyTransparentButton())
                                    .padding(.bottom, 8)
                                
                                Rectangle()
                                    .fill(Color(#colorLiteral(red: 0.07009194046, green: 0.07611755282, blue: 0.08425947279, alpha: 1))) // Set the color of the line
                                    .frame(height: 0.8)
                            }
                            
                            Text("Device details")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                                .textCase(.uppercase)
                                .padding(.top, 8)
                                
                            
                            VStack(alignment: .leading) {
                                Text("Device name")
                                    .font(.system(size: 10, weight: .light))
                                    .textCase(.uppercase)
                                    .padding(.bottom, 1)
                                    .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                                    
                                
                                Text(viewModel.name)
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                                    
                            }
                            .padding(.top, 8)
                            .padding(.vertical, 6)
                            
                            VStack(alignment: .leading) {
                                Text("Bluetooth address")
                                    .font(.system(size: 10, weight: .light))
                                    .textCase(.uppercase)
                                    .padding(.bottom, 1)
                                    .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                                
                                Text(viewModel.mac)
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                                    .textCase(.uppercase)
                                    
                            }
                            .padding(.vertical, 6)
                            
                            VStack(alignment: .leading) {
                                Text("Serial number")
                                    .font(.system(size: 10, weight: .light))
                                    .textCase(.uppercase)
                                    .padding(.bottom, 1)
                                    .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                                
                                Text(viewModel.serial)
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                                    
                            }
                            .padding(.vertical, 6)
                            
                            VStack(alignment: .leading) {
                                Text("Firmware version")
                                    .font(.system(size: 10, weight: .light))
                                    .textCase(.uppercase)
                                    .padding(.bottom, 1)
                                    .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                                
                                Text(viewModel.firmware)
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                                    
                            }
                            .padding(.vertical, 6)
                           
                                
                        }
                        .toggleStyle(SwitchToggleStyle())
                        
                        Spacer()
                        
                        Button("Forget") {
                            withAnimation {
                                viewModel.shouldShowForgetDialog = true
                            }
                        }
                        .buttonStyle(GreyButtonLarge())
                        .focusable(false)
                        .padding(.vertical, 16)
                    }
                }
                .frame(width: 200)
                
                
                
            }
            .navigationBarBackButtonHidden(true)
            
            .background(.black)
            .frame(width: 250, height: 230)
            .onAppear {
                if let device = mainViewModel.nothingDevice {
                    // Sync toggles from device state
                    viewModel.isUpdatingFromDevice = true
                    viewModel.inEarSwitch = device.isInEarDetectionOn
                    viewModel.latencySwitch = device.isLowLatencyOn
                    viewModel.personalizedANCSwitch = device.isPersonalizedANCEnabled
                    viewModel.isUpdatingFromDevice = false

                    // Update capabilities
                    let caps = DeviceCapabilities.capabilities(for: device.codename)
                    viewModel.supportsPersonalizedANC = caps.supportsPersonalizedANC
                    viewModel.supportsEarTipTest = caps.supportsEarTipTest
                    viewModel.supportsCaseLED = caps.supportsCaseLED
                }
            }
            if viewModel.shouldShowForgetDialog {
                Color.black.opacity(0.4) // Background dimming
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            viewModel.shouldShowForgetDialog = false
                        }
                    }
                    .zIndex(2)
                
                ModalSheetView(isPresented: $viewModel.shouldShowForgetDialog, title: $title, text: $text, topButtonText: $topButtonText, bottomButtonText: $bottomButtonText, action: {
                    
                    
                    //notify app that there is no devices saved anymore
                    
                    withAnimation {
                        viewModel.forgetDevice()
                        viewModel.shouldShowForgetDialog = false
                    }

                }, onCancelAction: {})
                .animation(.easeInOut, value: viewModel.shouldShowForgetDialog) // Animate the appearance
                .offset(y: viewModel.shouldShowForgetDialog ? 0 : 180) // Slide in from the bottom
                .zIndex(2)
            }
        }
        
    }
}

struct SettingsView_Previews: PreviewProvider {
    
    @State private var viewModel = SettingsViewViewModel(nothingService: NothingServiceImpl.shared,
                                                         nothingRepository: NothingRepositoryImpl.shared)
    
    static var previews: some View {
        
        let mainViewModel = MainViewViewModel(bluetoothService: BluetoothServiceImpl(), nothingRepository: NothingRepositoryImpl.shared, nothingService: NothingServiceImpl.shared)
        
        SettingsView()
            .environmentObject(mainViewModel)
            .environmentObject(Store())
    }
}
