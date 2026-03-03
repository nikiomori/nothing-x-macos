//
//  CaseLEDView.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/3/3.
//

import SwiftUI

struct CaseLEDView: View {

    @StateObject private var viewModel = CaseLEDViewModel(nothingService: NothingServiceImpl.shared)

    private let ledLabels = ["High battery", "Mid battery", "Low battery", "Charging", "Fully charged"]

    var body: some View {
        VStack {
            HStack {
                BackButtonView()
                Spacer()
            }

            VStack(alignment: .leading) {
                Text("CASE LED COLOR")
                    .font(.custom("NDOT45inspiredbyNOTHING", size: 10))
                    .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                    .textCase(.uppercase)
                    .padding(.bottom, 4)

                Text("Customise the LED colors on your charging case.")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 8)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        HStack {
                            Text(ledLabels[index])
                                .font(.system(size: 10, weight: .light))
                                .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))

                            Spacer()

                            ColorPicker("", selection: $viewModel.colors[index], supportsOpacity: false)
                                .labelsHidden()
                                .frame(width: 24, height: 24)
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.top, 8)
            }

            Button("APPLY") {
                viewModel.applyColors()
            }
            .buttonStyle(OffWhiteConnectButton())
            .padding(.bottom, 8)
        }
        .navigationBarBackButtonHidden(true)
        .background(.black)
        .frame(width: 250, height: 230)
    }
}
