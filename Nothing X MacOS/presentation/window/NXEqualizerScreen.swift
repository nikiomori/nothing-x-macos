//
//  NXEqualizerScreen.swift
//  Nothing X MacOS
//
//  Window equalizer, after the official app: a Simple tab with a radial
//  bass/mid/treble view and presets, and an Advanced tab with a curve,
//  per-band faders and saved profiles.
//

import SwiftUI

struct NXEqualizerScreen: View {
    @StateObject private var viewModel = EqualizerViewViewModel(nothingService: NothingServiceImpl.shared)
    @State private var tab: Tab = .simple
    @State private var selectedBand: Band = .bass
    @State private var loadedProfile: EQPreset?

    private enum Tab { case simple, advanced }
    enum Band: Int, CaseIterable { case bass, mid, treble }

    private var presets: [EQProfiles] { [.BALANCED, .MORE_BASE, .MORE_TREBEL, .VOICE] }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("EQUALISER")
                .font(NX.ndot(24))
                .tracking(2)
                .foregroundColor(NX.textPrimary)

            if viewModel.supportsCustomEQ {
                NXTabBar(tabs: [(Tab.simple, "SIMPLE"), (.advanced, "ADVANCED")], selection: $tab)
            }

            Group {
                if tab == .advanced && viewModel.supportsCustomEQ {
                    advancedTab
                } else {
                    simpleTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 40)
    }

    private var gains: (bass: Double, mid: Double, treble: Double) {
        let curve = EQCurveView(
            profile: viewModel.eq,
            customBass: viewModel.customBass,
            customMid: viewModel.customMid,
            customTreble: viewModel.customTreble
        )
        return (curve.bass, curve.mid, curve.treble)
    }

    // MARK: - Simple

    /// Same stack as the phone: disc on top, two-column presets, CUSTOM
    /// full width underneath
    private var simpleTab: some View {
        VStack(spacing: 28) {
            NXRadialEQ(bass: gains.bass, mid: gains.mid, treble: gains.treble)
                .frame(width: 300, height: 300)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.eq)

            VStack(spacing: 8) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(presets, id: \.self) { preset in
                        presetButton(preset)
                    }
                }
                if viewModel.supportsCustomEQ {
                    presetButton(.CUSTOM)
                }
            }
            .frame(width: 420)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func presetButton(_ preset: EQProfiles) -> some View {
        Button(preset.nxName) {
            withAnimation {
                viewModel.eq = preset // select before the device round-trip
                viewModel.switchEQ(eq: preset)
            }
            if preset != .CUSTOM { loadedProfile = nil }
        }
        .buttonStyle(PresetButton(selected: viewModel.eq == preset))
    }

    // MARK: - Advanced

    private var advancedTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            profileBar

            NXBandGraph(
                gains: [viewModel.customBass, viewModel.customMid, viewModel.customTreble],
                selected: selectedBand.rawValue
            )
            .frame(height: 120)

            HStack(alignment: .center, spacing: 0) {
                scaleLabels
                Spacer()
                ForEach(Band.allCases, id: \.self) { band in
                    NXDotSlider(
                        label: band.label,
                        value: binding(for: band),
                        selected: selectedBand == band,
                        height: 170,
                        onSelect: { selectedBand = band },
                        onChange: customChanged
                    )
                    if band != .treble { Spacer() }
                }
                Spacer()
                scaleLabels
            }
            .padding(.horizontal, 60)

            HStack {
                Button("RESET") {
                    viewModel.customBass = 0
                    viewModel.customMid = 0
                    viewModel.customTreble = 0
                    loadedProfile = nil
                    customChanged()
                }
                .buttonStyle(ResetButton())
                Spacer()
                if viewModel.eq != .CUSTOM {
                    Text("Moving a fader switches the earbuds to the custom EQ.")
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(NX.textTertiary)
                }
            }
        }
    }

    private var scaleLabels: some View {
        VStack {
            Text("+")
            Spacer()
            Text("0")
            Spacer()
            Text("–")
        }
        .font(.system(size: 9))
        .foregroundColor(NX.textTertiary)
        .frame(height: 140)
        .padding(.top, 6) // line up with the fader track, below its value label
    }

    private var profileBar: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                NXSectionLabel("PROFILES")
                Menu {
                    if viewModel.savedPresets.isEmpty {
                        Text("No saved profiles yet")
                    }
                    ForEach(viewModel.savedPresets, id: \.id) { preset in
                        Button(preset.name) {
                            viewModel.loadPreset(preset)
                            loadedProfile = preset
                        }
                    }
                    if !viewModel.savedPresets.isEmpty {
                        Divider()
                        Menu("Delete") {
                            ForEach(viewModel.savedPresets, id: \.id) { preset in
                                Button(preset.name, role: .destructive) {
                                    viewModel.deletePreset(preset)
                                    if loadedProfile?.id == preset.id { loadedProfile = nil }
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text((loadedProfile?.name ?? "Custom").uppercased())
                            .font(.system(size: 11))
                            .tracking(1.4)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                    }
                    .foregroundColor(NX.textPrimary)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }

            Spacer()

            Button {
                viewModel.isNamingPreset = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(NX.textPrimary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Save as profile")
            .popover(isPresented: $viewModel.isNamingPreset) {
                HStack {
                    TextField("Profile name", text: $viewModel.newPresetName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)
                    Button("Save") {
                        let name = viewModel.newPresetName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        viewModel.saveCurrentAsPreset(name: name)
                        loadedProfile = viewModel.savedPresets.last { $0.name == name }
                        viewModel.newPresetName = ""
                        viewModel.isNamingPreset = false
                    }
                }
                .padding(12)
            }
        }
    }

    private func binding(for band: Band) -> Binding<Double> {
        switch band {
        case .bass: return $viewModel.customBass
        case .mid: return $viewModel.customMid
        case .treble: return $viewModel.customTreble
        }
    }

    private func customChanged() {
        guard !viewModel.isUpdatingFromDevice else { return }
        if viewModel.eq != .CUSTOM {
            viewModel.switchEQ(eq: .CUSTOM)
        }
        viewModel.sendCustomEQ()
    }
}

extension NXEqualizerScreen.Band {
    var label: String {
        switch self {
        case .bass: return "BASS"
        case .mid: return "MID"
        case .treble: return "TREBLE"
        }
    }
}

// MARK: - Radial view

/// Disc with Mid at the top, Bass lower left and Treble lower right, and
/// the official app's blob in the middle
private struct NXRadialEQ: View {
    var bass: Double
    var mid: Double
    var treble: Double

    // y grows downwards: 270° is the top
    static let angles: [Double] = [150, 270, 30]

    private var isFlat: Bool { bass == 0 && mid == 0 && treble == 0 }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let blob = NXBlobShape(gains: AnimatablePair(bass, AnimatablePair(mid, treble)))
            ZStack {
                Circle().fill(Color(nx: 0x1C1C1C))

                blob
                    .fill(Color(nx: 0x191919))
                    .overlay(
                        // Lit rim that fades inwards
                        blob
                            .stroke(Color.white.opacity(0.32), lineWidth: radius * 0.06)
                            .blur(radius: radius * 0.035)
                            .clipShape(blob)
                    )
                    .frame(width: size, height: size)
                    .position(center)

                // Three guide dots per axis
                ForEach(0..<3, id: \.self) { axis in
                    ForEach([0.135, 0.39, 0.65], id: \.self) { r in
                        Circle()
                            .fill(Color(nx: 0x3A3A3A))
                            .frame(width: radius * 0.022, height: radius * 0.022)
                            .position(point(center, radius * r, Self.angles[axis]))
                    }
                }

                Circle()
                    .fill(Color.black)
                    .frame(width: radius * 0.09, height: radius * 0.09)
                    .position(center)

                axisLabel("Mid", center: center, radius: radius, angle: 270, rotation: 0)
                axisLabel("Bass", center: center, radius: radius, angle: 150, rotation: 60)
                axisLabel("Treble", center: center, radius: radius, angle: 30, rotation: -60)
            }
        }
    }

    private func axisLabel(_ text: String, center: CGPoint, radius: CGFloat, angle: Double, rotation: Double) -> some View {
        Text(text)
            .font(.system(size: max(9, radius * 0.068)))
            // The phone dims the labels while the curve is flat
            .foregroundColor(isFlat ? Color(nx: 0x4A4A4A) : Color(nx: 0x8A8A8A))
            .rotationEffect(.degrees(rotation))
            .position(point(center, radius * 0.81, angle))
    }

    private func point(_ center: CGPoint, _ r: CGFloat, _ degrees: Double) -> CGPoint {
        let a = degrees * .pi / 180
        return CGPoint(x: center.x + r * CGFloat(cos(a)), y: center.y + r * CGFloat(sin(a)))
    }
}

/// The phone's preset outlines, measured from screenshots and fitted as
/// r(θ)/R = a0 + Σ aₙ·cos nθ + bₙ·sin nθ (n = 1…6, θ clockwise from 3
/// o'clock). Custom gains blend them: bass/4, treble/4 and mid/3 of the
/// way from Balanced to More Bass, More Treble and Voice — the same gains
/// the presets use, so each preset lands exactly on its phone shape.
private struct NXBlobShape: Shape {
    var gains: AnimatablePair<Double, AnimatablePair<Double, Double>>

    var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get { gains }
        set { gains = newValue }
    }

    private static let balanced: [Double] = [0.5227, 0.0224, 0.0216, 0.0169, -0.0355, -0.0037, 0.0132, -0.045, -0.0086, 0.0018, 0.0011, -0.0024, -0.0064]
    private static let moreBass: [Double] = [0.5333, 0.0332, 0.0527, 0.0282, -0.0758, -0.0244, 0.0618, -0.0147, 0.0258, -0.0085, 0.0071, -0.0001, 0.0001]
    private static let moreTreble: [Double] = [0.5509, -0.0211, 0.0621, 0.0427, 0.0426, -0.004, 0.0915, 0.0032, 0.006, -0.003, -0.0006, 0.0083, 0.0027]
    private static let voice: [Double] = [0.4608, -0.0029, 0.0033, -0.049, 0.0394, -0.0203, 0.0237, -0.0246, -0.001, -0.002, -0.0123, 0.0045, 0.0045]

    private var coefficients: [Double] {
        let wBass = gains.first / 4, wMid = gains.second.first / 3, wTreble = gains.second.second / 4
        return Self.balanced.indices.map { i in
            let base = Self.balanced[i]
            return base
                + wBass * (Self.moreBass[i] - base)
                + wTreble * (Self.moreTreble[i] - base)
                + wMid * (Self.voice[i] - base)
        }
    }

    func path(in rect: CGRect) -> Path {
        let c = coefficients
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for step in 0...180 {
            let theta = Double(step) * 2 * .pi / 180
            var r = c[0]
            for n in 1...6 {
                r += c[2 * n - 1] * cos(Double(n) * theta) + c[2 * n] * sin(Double(n) * theta)
            }
            let p = CGPoint(x: center.x + radius * CGFloat(r * cos(theta)), y: center.y + radius * CGFloat(r * sin(theta)))
            if step == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Band graph

/// Curve over a log-ish frequency grid with a dot per band
private struct NXBandGraph: View {
    let gains: [Double]
    let selected: Int

    private let positions: [CGFloat] = [0.18, 0.5, 0.82]
    private let gridLines: [(CGFloat, String)] = [
        (0.04, "20"), (0.18, "100"), (0.34, "300"), (0.5, "1k"), (0.66, "3k"), (0.82, "10k"), (0.96, "20k"),
    ]

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                let points = gains.indices.map { i in
                    CGPoint(x: w * positions[i], y: y(gains[i], h))
                }
                ZStack {
                    ForEach(gridLines.indices, id: \.self) { i in
                        Path { p in
                            p.move(to: CGPoint(x: w * gridLines[i].0, y: 0))
                            p.addLine(to: CGPoint(x: w * gridLines[i].0, y: h))
                        }
                        .stroke(NX.cardBorder)
                    }
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h / 2))
                        p.addLine(to: CGPoint(x: w, y: h / 2))
                    }
                    .stroke(NX.chipBorder)

                    curve(points, w: w, h: h, closed: true)
                        .fill(Color.white.opacity(0.06))
                    curve(points, w: w, h: h, closed: false)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1.2)

                    ForEach(points.indices, id: \.self) { i in
                        Circle()
                            .fill(i == selected ? NX.redSoft : NX.textSecondary)
                            .frame(width: 9, height: 9)
                            .position(points[i])
                    }
                }
            }
            .background(NX.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(NX.cardBorder))

            GeometryReader { geo in
                ForEach(gridLines.indices, id: \.self) { i in
                    Text(gridLines[i].1)
                        .font(.system(size: 9))
                        .foregroundColor(NX.textTertiary)
                        .position(x: geo.size.width * gridLines[i].0, y: 6)
                }
            }
            .frame(height: 12)
        }
        .animation(.easeOut(duration: 0.15), value: gains)
    }

    private func y(_ gain: Double, _ h: CGFloat) -> CGFloat {
        h / 2 - CGFloat(gain / 6) * (h / 2 - 14)
    }

    /// Flat at the edges, smooth through the band points
    private func curve(_ points: [CGPoint], w: CGFloat, h: CGFloat, closed: Bool) -> Path {
        let all = [CGPoint(x: 0, y: points.first?.y ?? h / 2)] + points + [CGPoint(x: w, y: points.last?.y ?? h / 2)]
        var path = Path()
        path.move(to: all[0])
        for i in 1..<all.count {
            let prev = all[i - 1], next = all[i]
            let mid = (prev.x + next.x) / 2
            path.addCurve(to: next, control1: CGPoint(x: mid, y: prev.y), control2: CGPoint(x: mid, y: next.y))
        }
        if closed {
            path.addLine(to: CGPoint(x: w, y: h / 2))
            path.addLine(to: CGPoint(x: 0, y: h / 2))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Styles

private struct PresetButton: ButtonStyle {
    var selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11))
            .tracking(1.5)
            .foregroundColor(selected ? .white : NX.offWhite)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Capsule().fill(selected ? NX.redSoft : NX.track))
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

private struct ResetButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10))
            .tracking(1.5)
            .foregroundColor(.white)
            .frame(width: 96, height: 44)
            .background(RoundedRectangle(cornerRadius: 14).fill(NX.redSoft))
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
