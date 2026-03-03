//
//  ConnectView.swift
//  Nothing X MacOS
//
//  Created by Arunavo Ray on 14/02/23.
//

import SwiftUI

struct ConnectView: View {
    
    @State var title: String? = "Failed to connect"
    @State var text: String? = "Make sure device is on and in discovery mode."
    @State var topButtonText: String? = "Retry"
    @State var bottomButtonText: String? = "Cancel"
    
    @StateObject private var viewModel = ConnectViewViewModel(nothingRepository: NothingRepositoryImpl.shared, nothingService: NothingServiceImpl.shared, bluetoothService: BluetoothServiceImpl())
    
    @EnvironmentObject var mainViewModel: MainViewViewModel
    
    var body: some View {
        
        
        ZStack(alignment: .bottom) {
            
            
            // ear (1)
            
            HStack {
                DeviceNameDotTextView()
                Spacer()
            }
            .padding(.bottom, 4)
            .zIndex(1)
            
            
            
            VStack {
                
                HStack {
                    Spacer()
                    
                    // Settings
                    SettingsButtonView()
                    
                    // Quit
                    QuitButtonView()
                }
                
                VStack {
                    // Ear 1 Image
                    Image("ear_1")
                        .overlay(
                            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                                .blendMode(.darken) // Blend mode to darken the image
                        )
                    
                    
                    Spacer(minLength: 15)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(Color.white)
                            .colorInvert()
                            .scaleEffect(0.6)

                    } else if viewModel.savedDevices.count > 1 {
                        VStack(spacing: 2) {
                            ForEach(viewModel.savedDevices, id: \.bluetoothDetails.mac) { device in
                                Button(action: {
                                    viewModel.checkBluetoothStatus()
                                    if viewModel.isBluetoothOn {
                                        viewModel.connect(device: device)
                                    } else {
                                        mainViewModel.navigateToBluetoothIsOff()
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(device.name)
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(.white)
                                            if let date = device.lastConnected {
                                                Text(date, style: .relative)
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "arrow.right.circle")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(#colorLiteral(red: 0.10980392247438431, green: 0.11372549086809158, blue: 0.12156862765550613, alpha: 1)))
                                    .cornerRadius(4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                    } else {
                        Button("RECONNECT") {
                            viewModel.checkBluetoothStatus()
                            if viewModel.isBluetoothOn {
                                viewModel.connect()
                            } else {
                                mainViewModel.navigateToBluetoothIsOff()
                            }
                        }
                        .buttonStyle(OffWhiteConnectButton())
                        .focusable(false)
                    }
                    Spacer(minLength: 15)
                }
                
                
            }
            
            // Bottom sheet overlay
            if viewModel.isFailedToConnectPresented {
                Color.black.opacity(0.4) // Background dimming
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            viewModel.isFailedToConnectPresented = false
                        }
                    }
                    .zIndex(2)
                
                ModalSheetView(isPresented: $viewModel.isFailedToConnectPresented, title: $title, text: $text, topButtonText: $topButtonText, bottomButtonText: $bottomButtonText, action: {
                    viewModel.retryConnect()
                }, onCancelAction: {})
                .animation(.easeInOut, value: viewModel.isFailedToConnectPresented) // Animate the appearance
                .offset(y: viewModel.isFailedToConnectPresented ? 0 : 180) // Slide in from the bottom
                .zIndex(3)
                
            }
            
        }
        
        .padding(.bottom, 0)
        .background(.black)
        .frame(width: 250,height: 230)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.loadSavedDevices()
            viewModel.checkBluetoothStatus()
            if viewModel.isBluetoothOn && !viewModel.isLoading {
                viewModel.connect()
            } else if !viewModel.isBluetoothOn {
                mainViewModel.navigateToBluetoothIsOff()
            }
        }
        
    }
        
        
        
}


struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView()
    }
}
