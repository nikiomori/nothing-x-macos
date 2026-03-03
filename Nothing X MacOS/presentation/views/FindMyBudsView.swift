//
//  FindMyBudsView.swift
//  Nothing X MacOS
//
//  Created by Arunavo Ray on 15/02/23.
//

import SwiftUI
import TipKit
struct FindMyBudsView: View {
    
    @State var title: String? = "Volume warning"
    @State var text: String? = "Your earbuds may be in use. Be sure to remove them from your ears before you continue. A loud sound will be played which could be uncomfortable for anyone wears them."
    @State var topButtonText: String? = "Play"
    @State var bottomButtonText: String? = "Cancel"
    
    @StateObject private var viewModel = FindMyBudsViewViewModel(nothingService: NothingServiceImpl.shared)
    
    @State private var scale: CGFloat = 1.0 // Initial scale for the first circle
    @State private var opacity: Double = 1.0 // Initial opacity for the first circle
    @State private var showSecondCircle: Bool = false // State variable to control the visibility of the second circle
    @State private var secondCircleScale: CGFloat = 1.0 // Initial scale for the second circle
    @State private var secondCircleOpacity: Double = 0.0 // Initial opacity for the second circle

    @State private var isRunning = false
    
    private let popoverTip = HearingLossToolTip()
    var body: some View {
        
        ZStack(alignment: .bottom) {
            
      
        ZStack(alignment: .center) {
            
            VStack(spacing: 0) {
                HStack {
                    
                    BackButtonView()
                    Spacer()
                    // Quit
                    QuitButtonView()
                    
                }
                
                // Heading
                HStack() {
                    VStack(alignment: .leading) {
                        
                        if !isRunning {
                            
                            Text("Find my buds")
                                .font(.custom("NDOT45inspiredbyNOTHING", size: 10))
                                .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                                .multilineTextAlignment(.leading)
                                .textCase(.uppercase)
                                .padding(.vertical, 6)
                                
                            Spacer()
                            
                            // Description
                            HStack {
                                Text("Click above to play sound.")
                                    .lineLimit(1)
                                    .font(.system(size: 10, weight: .light))
                                    .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))
                                    .multilineTextAlignment(.leading)
                                    .padding(.bottom, 12)
                                    
                                
                                Spacer()
                                
                            }
                            
                        } else {
                            Spacer()
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .padding(.top, 1)
                    Spacer()
                }
                
            }
            .frame(width: 250, height: 230)
            .zIndex(1)
            
            
            VStack {
                if viewModel.isRinging {
                    // Stop button with ripple animation
                    ZStack {
                        Circle()
                            .stroke(Color.red.opacity(1.0), lineWidth: 0.8)
                            .scaleEffect(scale)
                            .opacity(opacity)

                        Circle()
                            .stroke(Color.red.opacity(1.0), lineWidth: 0.8)
                            .scaleEffect(secondCircleScale)
                            .opacity(secondCircleOpacity)

                        HStack {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 18, weight: .light))
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.white)
                        }
                        .frame(width: 60, height: 60)
                        .background(Color(#colorLiteral(red: 0.843137264251709, green: 0.09019608050584793, blue: 0.12941177189350128, alpha: 1)))
                        .clipShape(Circle())
                        .onTapGesture {
                            viewModel.stopRinging()
                            withAnimation {
                                isRunning = false
                            }
                        }
                    }
                    .frame(width: 60, height: 60)
                } else {
                    // Ring buttons: Left | Both | Right
                    HStack(spacing: 12) {
                        ringButton(icon: "ear", label: "L", target: .left)
                        ringButton(icon: "play.fill", label: nil, target: .both, size: 50)
                        ringButton(icon: "ear", label: "R", target: .right)
                    }
                }
            }
            
            }
            if viewModel.shouldShowWarning {
                Color.black.opacity(0.4) // Background dimming
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            viewModel.shouldShowWarning = false
                        }
                    }
                    .zIndex(3)
                
                ModalSheetView(isPresented: $viewModel.shouldShowWarning, title: $title, text: $text, topButtonText: $topButtonText, bottomButtonText: $bottomButtonText, action: {

                    if (!isRunning) {
                        withAnimation {
                            isRunning = true
                        }
                        startAnimation()
                    }
                    viewModel.confirmRing()

                }, onCancelAction: {})
                .animation(.easeInOut, value: viewModel.shouldShowWarning) // Animate the appearance
                .offset(y: viewModel.shouldShowWarning ? 0 : 180) // Slide in from the bottom
                .zIndex(4)
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(.black)
        .frame(width: 250, height: 230)
        .onDisappear {
            viewModel.stopRinging()
        }
    }

    @ViewBuilder
    private func ringButton(icon: String, label: String?, target: RingTarget, size: CGFloat = 36) -> some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: size == 50 ? 18 : 12, weight: .light))
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white)
            }
            .frame(width: size, height: size)
            .background(Color(#colorLiteral(red: 0.843137264251709, green: 0.09019608050584793, blue: 0.12941177189350128, alpha: 1)))
            .clipShape(Circle())
            .onTapGesture {
                viewModel.requestRing(target: target)
            }

            if let label = label {
                Text(label)
                    .font(.system(size: 9, weight: .light))
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func startAnimation() {
        
        if (!isRunning) {
            return
        }
        // Animate to scale 3 and fade out
        withAnimation(.easeOut(duration: 1)) {
            scale = 3.0
            opacity = 0.0
        }
        
        
        // Show the second circle after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showSecondCircle = true // Show the second circle
            startSecondCircleAnimation()
            //Start the animation for the second circle
        }
        
        // Delay to allow the scale and fade out to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Reset to original scale and opacity
            
            scale = 1.0
            opacity = 1.0
            
            // Call the function again to create a loop
            startAnimation()
        }
        
        
    }
    
    private func startSecondCircleAnimation() {
        
        if (!isRunning) {
            return
        }
        
        // Animate the second circle to scale 1.5 and fade in
        withAnimation(.easeOut(duration: 1)) {
            secondCircleScale = 3
            secondCircleOpacity = 0.0
        }
        
        // Delay to allow the scale and fade in to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Reset the second circle to original scale and opacity
            
            secondCircleScale = 1.0
            secondCircleOpacity = 1.0
            
        }
    }
}



struct FindMyBudsView_Previews: PreviewProvider {
    static var previews: some View {
        FindMyBudsView()
    }
}


struct HearingLossToolTip : Tip {
    
    var id: String {
        "Hearing loss tool tip"
    }
    
    var title: Text {
        Text("Important hearing damage information")
    }
    
    var message: Text? {
        Text("Make sure your earbuds are not in use before you continue. Activating this feature with earbuds in-ear may cause hearing damage.")
    }
    
    var image: Image? {
        
        let image: Image = Image(systemName: "ear.trianglebadge.exclamationmark")
            
            
        return image
    }
    
    
}
