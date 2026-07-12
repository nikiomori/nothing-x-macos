//
//  NXEqualizerScreen.swift
//  Nothing X MacOS
//
//  Window equalizer: presets, saved presets, custom EQ and enhanced bass.
//

import SwiftUI

struct NXEqualizerScreen: View {
    @StateObject private var viewModel = EqualizerViewViewModel(nothingService: NothingServiceImpl.shared)

    private var presets: [EQProfiles] {
        var all: [EQProfiles] = [.BALANCED, .MORE_BASE, .MORE_TREBEL, .VOICE]
        if viewModel.supportsCustomEQ { all.append(.CUSTOM) }
        return all
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("EQUALISER")
                    .font(NX.ndot(24))
                    .tracking(2)
                    .foregroundColor(NX.textPrimary)
                Text("Customise your sound by selecting your favourite preset.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(NX.textSecondary)
            }

            HStack(alignment: .top, spacing: 24) {
                presetColumn
                curveCard
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 40)
    }

    // MARK: - Presets

    private var presetColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(presets, id: \.self) { preset in
                Button(preset.nxName) {
                    withAnimation {
                        viewModel.eq = preset // select before the device round-trip
                        viewModel.switchEQ(eq: preset)
                    }
                }
                .buttonStyle(PresetButton(selected: viewModel.eq == preset))
            }

            if viewModel.supportsCustomEQ {
                Text("SAVED PRESETS")
                    .font(.system(size: 9))
                    .tracking(2)
                    .foregroundColor(NX.textTertiary)
                    .padding(.top, 16)

                savedPresetChips
            }
        }
        .frame(width: 250)
    }

    private var savedPresetChips: some View {
        FlowLayoutLite(spacing: 8) {
            ForEach(viewModel.savedPresets, id: \.id) { preset in
                Button(preset.name.uppercased()) { viewModel.loadPreset(preset) }
                    .buttonStyle(NXChip(selected: false))
                    .contextMenu {
                        Button("Delete") { viewModel.deletePreset(preset) }
                    }
            }
            if viewModel.eq == .CUSTOM {
                Button {
                    viewModel.isNamingPreset = true
                } label: {
                    Label("SAVE", systemImage: "plus")
                        .font(.system(size: 9))
                }
                .buttonStyle(NXChip(selected: false))
                .popover(isPresented: $viewModel.isNamingPreset) {
                    HStack {
                        TextField("Preset name", text: $viewModel.newPresetName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 160)
                        Button("Save") {
                            let name = viewModel.newPresetName.trimmingCharacters(in: .whitespaces)
                            guard !name.isEmpty else { return }
                            viewModel.saveCurrentAsPreset(name: name)
                            viewModel.newPresetName = ""
                            viewModel.isNamingPreset = false
                        }
                    }
                    .padding(12)
                }
            }
        }
    }

    // MARK: - Curve and sliders

    private var curveCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            EQCurveView(
                profile: viewModel.eq,
                customBass: viewModel.customBass,
                customMid: viewModel.customMid,
                customTreble: viewModel.customTreble
            )
            .frame(height: 150)

            if viewModel.eq == .CUSTOM && viewModel.supportsCustomEQ {
                slider("BASS", value: $viewModel.customBass)
                slider("MID", value: $viewModel.customMid)
                slider("TREBLE", value: $viewModel.customTreble)
            }

            if viewModel.supportsEnhancedBass {
                Divider().overlay(NX.cardBorder)
                HStack {
                    Toggle("ENHANCED BASS", isOn: enhancedBassBinding)
                        .toggleStyle(NXSwitch())
                        .frame(width: 200)
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { level in
                            Button("\(level)") { viewModel.setEnhancedBassLevel(level: level) }
                                .buttonStyle(NXChip(selected: viewModel.enhancedBassLevel == level))
                                .disabled(!viewModel.isEnhancedBassEnabled)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .nxCard()
    }

    private func slider(_ label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .font(.system(size: 9))
                .tracking(2)
                .foregroundColor(NX.textTertiary)
                .frame(width: 56, alignment: .leading)
            Slider(
                value: Binding(
                    get: { value.wrappedValue },
                    set: {
                        value.wrappedValue = $0
                        if !viewModel.isUpdatingFromDevice { viewModel.sendCustomEQ() }
                    }
                ),
                in: -6...6,
                step: 0.5
            )
            .tint(NX.capsule)
            Text(String(format: "%+.1f", value.wrappedValue))
                .font(NX.pixel(10))
                .foregroundColor(NX.offWhite)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private var enhancedBassBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isEnhancedBassEnabled },
            set: { viewModel.isEnhancedBassEnabled = $0; viewModel.switchEnhancedBass(enabled: $0) }
        )
    }
}

// MARK: - Styles

private struct PresetButton: ButtonStyle {
    var selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11))
            .tracking(1.5)
            .foregroundColor(selected ? NX.onCapsule : NX.offWhite)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Capsule().fill(selected ? NX.capsule : NX.track))
            .contentShape(Capsule())
    }
}

// Wraps chips onto new lines; Layout protocol needs macOS 13, which matches
// the deployment target
private struct FlowLayoutLite: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, position) in zip(subviews, arrange(proposal: proposal, subviews: subviews).positions) {
            subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + rowHeight), positions)
    }
}
