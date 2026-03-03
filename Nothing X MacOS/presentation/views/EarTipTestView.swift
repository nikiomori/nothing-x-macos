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

    private var resultIcon: String {
        switch result {
        case .goodSeal: return "checkmark.circle.fill"
        case .poorSeal: return "exclamationmark.triangle.fill"
        case .notInEar: return "xmark.circle.fill"
        case .unknown: return "circle"
        }
    }

    private var resultColor: Color {
        switch result {
        case .goodSeal: return .green
        case .poorSeal: return .yellow
        case .notInEar: return .red
        case .unknown: return .gray
        }
    }

    private var resultText: String {
        switch result {
        case .goodSeal: return "Good seal"
        case .poorSeal: return "Poor seal"
        case .notInEar: return "Not in ear"
        case .unknown: return ""
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)))

            Image(systemName: resultIcon)
                .font(.system(size: 28))
                .foregroundColor(resultColor)

            Text(resultText)
                .font(.system(size: 10, weight: .light))
                .foregroundColor(Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8)))
        }
    }
}
