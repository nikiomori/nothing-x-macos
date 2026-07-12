//
//  NXEarTipTestScreen.swift
//  Nothing X MacOS
//
//  Window ear tip fit test: per-bud seal results.
//

import SwiftUI

struct NXEarTipTestScreen: View {
    @EnvironmentObject var mainViewModel: MainViewViewModel
    @StateObject private var viewModel = EarTipTestViewModel(nothingService: NothingServiceImpl.shared)

    private var art: (left: String, right: String?) {
        NXDeviceArt.images(for: mainViewModel.nothingDevice?.codename ?? .UNKNOWN)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("EAR TIP FIT TEST")
                    .font(NX.ndot(24))
                    .tracking(2)
                    .foregroundColor(NX.textPrimary)
                Text("Insert earbuds, stay still, and tap Start. A tone will play to measure seal quality.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(NX.textSecondary)
            }

            HStack(spacing: 20) {
                resultCard(image: art.left, label: "LEFT", result: viewModel.leftResult)
                resultCard(image: art.right ?? art.left, label: "RIGHT", result: viewModel.rightResult)
            }
            .frame(maxHeight: .infinity)

            HStack {
                Spacer()
                Button(buttonTitle) { viewModel.startTest() }
                    .buttonStyle(NXFilledPill())
                    .frame(width: 260, height: 44)
                    .disabled(viewModel.state == .testing)
                    .opacity(viewModel.state == .testing ? 0.5 : 1)
                Spacer()
            }
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 40)
    }

    private var buttonTitle: String {
        switch viewModel.state {
        case .idle: return "START TEST"
        case .testing: return "TESTING…"
        case .completed: return "RETRY TEST"
        }
    }

    private func resultCard(image: String, label: String, result: EarTipResult) -> some View {
        VStack(spacing: 16) {
            Image(image).resizable().scaledToFit().frame(width: 64, height: 110)
            Text(label)
                .font(.system(size: 9))
                .tracking(2.4)
                .foregroundColor(NX.textTertiary)
            resultBadge(result)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .nxCard()
    }

    @ViewBuilder
    private func resultBadge(_ result: EarTipResult) -> some View {
        switch result {
        case .unknown:
            if viewModel.state == .testing {
                ProgressView()
                    .controlSize(.small)
                Text("MEASURING")
                    .font(NX.ndot(15))
                    .tracking(1.5)
                    .foregroundColor(NX.textSecondary)
            } else {
                Text("NO RESULT YET")
                    .font(NX.ndot(15))
                    .tracking(1.5)
                    .foregroundColor(NX.textSecondary)
            }
        case .goodSeal:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
            Text("GOOD SEAL")
                .font(NX.ndot(15))
                .tracking(1.5)
                .foregroundColor(NX.textPrimary)
        case .poorSeal:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
            Text("POOR SEAL")
                .font(NX.ndot(15))
                .tracking(1.5)
                .foregroundColor(NX.textPrimary)
            Text("Try a different ear tip size, then retest.")
                .font(.system(size: 11, weight: .light))
                .foregroundColor(NX.textSecondary)
        case .notInEar:
            Image(systemName: "ear.trianglebadge.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(NX.textSecondary)
            Text("NOT IN EAR")
                .font(NX.ndot(15))
                .tracking(1.5)
                .foregroundColor(NX.textPrimary)
        }
    }
}
