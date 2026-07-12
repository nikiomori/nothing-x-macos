//
//  NXFindMyBudsScreen.swift
//  Nothing X MacOS
//
//  Window find-my-buds: ring one or both earbuds.
//

import SwiftUI

struct NXFindMyBudsScreen: View {
    @StateObject private var viewModel = FindMyBudsViewViewModel(nothingService: NothingServiceImpl.shared)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("FIND MY BUDS")
                    .font(NX.ndot(24))
                    .tracking(2)
                    .foregroundColor(NX.textPrimary)
                Text("Play a sound on one or both earbuds to locate them.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(NX.textSecondary)
            }

            Spacer()

            VStack(spacing: 36) {
                HStack(spacing: 48) {
                    sideButton(.left, label: "LEFT")
                    centerButton
                    sideButton(.right, label: "RIGHT")
                }
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 14))
                        .foregroundColor(NX.textSecondary)
                    Text("A loud tone will play. Remove your earbuds before you continue.")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(NX.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 40)
        .onDisappear {
            // deferred: onDisappear runs mid view-update, mutating @Published
            // there is undefined behavior
            DispatchQueue.main.async {
                if viewModel.isRinging { viewModel.stopRinging() }
            }
        }
    }

    private var centerButton: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(NX.red.opacity(0.18 + Double(ring) * 0.21), lineWidth: 1)
                    .frame(width: 220 - CGFloat(ring) * 64, height: 220 - CGFloat(ring) * 64)
                    .scaleEffect(ringing(.both) ? 1.08 : 1)
                    .animation(
                        ringing(.both)
                            ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true).delay(Double(ring) * 0.15)
                            : .easeInOut(duration: 0.2),
                        value: ringing(.both)
                    )
            }
            Button {
                toggle(.both)
            } label: {
                Circle()
                    .fill(NX.red)
                    .frame(width: 88, height: 88)
                    .shadow(color: NX.red.opacity(0.35), radius: 30)
                    .overlay(
                        Image(systemName: ringing(.both) ? "stop.fill" : "play.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(width: 220, height: 220)
    }

    private func sideButton(_ target: RingTarget, label: String) -> some View {
        VStack(spacing: 10) {
            Button {
                toggle(target)
            } label: {
                Circle()
                    .fill(ringing(target) ? NX.red : NX.track)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: ringing(target) ? "stop.fill" : "speaker.wave.2")
                            .font(.system(size: 18))
                            .foregroundColor(ringing(target) ? .white : NX.offWhite)
                    )
            }
            .buttonStyle(.plain)
            Text(label)
                .font(.system(size: 9))
                .tracking(2)
                .foregroundColor(NX.textTertiary)
        }
    }

    private func ringing(_ target: RingTarget) -> Bool {
        viewModel.isRinging && viewModel.ringingTarget == target
    }

    private func toggle(_ target: RingTarget) {
        withAnimation {
            if viewModel.isRinging {
                viewModel.stopRinging()
            } else {
                // The on-screen warning is always visible, so skip the confirm dialog
                viewModel.pendingRingTarget = target
                viewModel.confirmRing()
            }
        }
    }
}
