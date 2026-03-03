//
//  EarTipTestView.swift
//  Nothing X MacOS
//
//  Created by Daniel on 2025/3/3.
//

import SwiftUI

struct EarTipTestView: View {

    @StateObject private var viewModel = EarTipTestViewModel(nothingService: NothingServiceImpl.shared)

    var body: some View {
        VStack {
            HStack {
                BackButtonView()
                Spacer()
            }

            VStack(alignment: .leading) {
                Text("EAR TIP FIT TEST")
                    .font(.custom("NDOT45inspiredbyNOTHING", size: 10))
                    .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
                    .textCase(.uppercase)
                    .padding(.bottom, 4)

                Text("Insert earbuds, stay still, and tap Start. A tone will play to measure seal quality.")
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 8)

            Spacer()

            switch viewModel.state {
            case .idle:
                Button("START TEST") {
                    viewModel.startTest()
                }
                .buttonStyle(OffWhiteConnectButton())

            case .testing:
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Testing...")
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                }

            case .completed:
                HStack(spacing: 24) {
                    EarTipResultColumn(label: "LEFT", result: viewModel.leftResult)
                    EarTipResultColumn(label: "RIGHT", result: viewModel.rightResult)
                }

                Button("RETRY") {
                    viewModel.startTest()
                }
                .buttonStyle(GreyButtonLarge())
                .padding(.top, 12)
            }

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .background(.black)
        .frame(width: 250, height: 230)
    }
}

struct EarTipResultColumn: View {
    let label: String
    let result: EarTipResult

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))

            Image(systemName: result == .goodSeal ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(result == .goodSeal ? .green : .red)

            Text(result == .goodSeal ? "Good seal" : "Poor seal")
                .font(.system(size: 10, weight: .light))
                .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
        }
    }
}
