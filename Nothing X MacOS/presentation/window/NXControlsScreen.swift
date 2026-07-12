//
//  NXControlsScreen.swift
//  Nothing X MacOS
//
//  Window gesture controls: per-side gesture cards with inline pickers.
//

import SwiftUI

struct NXControlsScreen: View {
    @EnvironmentObject var mainViewModel: MainViewViewModel
    @StateObject private var viewModel = ControlsDetailViewViewModel(nothingService: NothingServiceImpl.shared)
    @State private var side: EarBudSide = .left

    // The device does not echo gesture changes, so selections are tracked
    // locally and synced from the last known device state per side
    @State private var tripleTap: TripleTapOptions = .no_action
    @State private var doubleTap: DoubleTapOptions = .no_action
    @State private var tapHold: TapAndHoldOptions = .no_extra_action
    @State private var doubleTapHold: DoubleTapAndHoldOptions = .no_extra_action

    private var deviceSide: DeviceType { side == .left ? .LEFT : .RIGHT }

    private var capabilities: DeviceCapabilities? {
        mainViewModel.nothingDevice.map { DeviceCapabilities.capabilities(for: $0.codename) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CONTROLS")
                        .font(NX.ndot(24))
                        .tracking(2)
                        .foregroundColor(NX.textPrimary)
                    Text("Customise gestures for each earbud.")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(NX.textSecondary)
                }
                Spacer()
                NXSegmented(
                    options: [(EarBudSide.left, "LEFT"), (.right, "RIGHT")],
                    selection: $side,
                    fontSize: 10
                )
                .frame(width: 170, height: 38)
            }

            HStack(alignment: .top, spacing: 28) {
                budsIllustration
                // Two explicit columns: LazyVGrid collapsed to content width
                // next to the fixed buds column and the cards overlapped
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 14) {
                        tripleTapCard
                        tapAndHoldCard
                        Spacer(minLength: 0)
                    }
                    VStack(spacing: 14) {
                        if capabilities?.supportsDoubleTap == true { doubleTapCard }
                        if capabilities?.supportsDoubleTapAndHold == true { doubleTapAndHoldCard }
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 40)
        .onAppear(perform: sync)
        .onChange(of: side) { _ in sync() }
    }

    private func sync() {
        let isLeft = side == .left
        tripleTap = viewModel.convertTripleTapActionToOption(action: isLeft ? mainViewModel.leftTripleTapAction : mainViewModel.rightTripleTapAction)
        doubleTap = viewModel.convertDoubleTapActionToOption(action: isLeft ? mainViewModel.leftDoubleTapAction : mainViewModel.rightDoubleTapAction)
        let tapHoldAction = isLeft ? mainViewModel.leftTapAndHoldAction : mainViewModel.rightTapAndHoldAction
        tapHold = viewModel.convertTapAndHoldActionToOption(action: tapHoldAction)
        let dthAction = isLeft ? mainViewModel.leftDoubleTapAndHoldAction : mainViewModel.rightDoubleTapAndHoldAction
        doubleTapHold = viewModel.convertDoubleTapAndHoldActionToOption(action: dthAction)
        // sync() runs from onAppear/onChange, i.e. mid view-update — mutating
        // @Published there is undefined behavior, so defer it
        DispatchQueue.main.async {
            viewModel.loadANCCycleState(from: tapHoldAction)
            viewModel.loadDTHANCCycleState(from: dthAction)
        }
    }

    // MARK: - Buds

    private var budsIllustration: some View {
        let art = NXDeviceArt.images(for: mainViewModel.nothingDevice?.codename ?? .UNKNOWN)
        return VStack(spacing: 12) {
            Spacer()
            HStack(alignment: .bottom, spacing: 0) {
                budImage(art.left, side: .left)
                budImage(art.right ?? art.left, side: .right)
            }
            .animation(.bouncy(duration: 0.3), value: side)
            Text(side == .left ? "LEFT" : "RIGHT")
                .font(NX.ndot(10))
                .tracking(2)
                .foregroundColor(NX.offWhite)
            Spacer()
        }
        .frame(width: 220)
    }

    private func budImage(_ name: String, side target: EarBudSide) -> some View {
        Button {
            side = target
        } label: {
            Image(name)
                .resizable().scaledToFit()
                .frame(width: 105, height: 190)
                .scaleEffect(side == target ? 1.08 : 1)
                .opacity(side == target ? 1 : 0.75)
                .brightness(side == target ? 0 : -0.2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(target == .left ? "Show left earbud controls" : "Show right earbud controls")
    }

    // MARK: - Gesture cards

    private var tripleTapCard: some View {
        gestureCard(title: "TRIPLE PRESS", glyph: glyph(dots: 3, hold: false), footnote: nil) {
            picker($tripleTap) { viewModel.switchTripleTapAction(device: deviceSide, action: $0) }
        }
    }

    private var doubleTapCard: some View {
        gestureCard(title: "DOUBLE PRESS", glyph: glyph(dots: 2, hold: false), footnote: "Decline incoming call") {
            picker($doubleTap) { viewModel.switchDoubleTapAction(device: deviceSide, action: $0) }
        }
    }

    private var tapAndHoldCard: some View {
        gestureCard(title: "HOLD", glyph: glyph(dots: 1, hold: true), footnote: nil) {
            picker($tapHold) { viewModel.switchTapAndHoldAction(device: deviceSide, action: $0) }
            if tapHold == .noise_control && capabilities?.supportsANCCycleConfig == true {
                cycleRow(
                    anc: $viewModel.ancCycleANC,
                    transparency: $viewModel.ancCycleTransparency,
                    off: $viewModel.ancCycleOff
                ) { viewModel.updateANCCycle(device: deviceSide) }
            }
        }
    }

    private var doubleTapAndHoldCard: some View {
        gestureCard(title: "DOUBLE PRESS & HOLD", glyph: glyph(dots: 2, hold: true), footnote: nil) {
            picker($doubleTapHold) { viewModel.switchDoubleTapAndHoldAction(device: deviceSide, action: $0) }
            if doubleTapHold == .noise_control && capabilities?.supportsANCCycleConfig == true {
                cycleRow(
                    anc: $viewModel.dthAncCycleANC,
                    transparency: $viewModel.dthAncCycleTransparency,
                    off: $viewModel.dthAncCycleOff
                ) { viewModel.updateDTHANCCycle(device: deviceSide) }
            }
        }
    }

    private func cycleRow(anc: Binding<Bool>, transparency: Binding<Bool>, off: Binding<Bool>, update: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CYCLE")
                .font(.system(size: 9))
                .tracking(1.6)
                .foregroundColor(NX.textTertiary)
            HStack(spacing: 6) {
                cycleChip("ANC", isOn: anc, update: update)
                cycleChip("TRANSP.", isOn: transparency, update: update)
                cycleChip("OFF", isOn: off, update: update)
            }
        }
    }

    private func cycleChip(_ label: String, isOn: Binding<Bool>, update: @escaping () -> Void) -> some View {
        Button(label) {
            isOn.wrappedValue.toggle()
            update()
        }
        .buttonStyle(NXChip(selected: isOn.wrappedValue))
    }

    // MARK: - Building blocks

    private func gestureCard(title: String, glyph: some View, footnote: String?, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                glyph
                Text(title)
                    .font(.system(size: 11))
                    .tracking(1.8)
                    .foregroundColor(NX.offWhite)
            }
            content()
            if let footnote {
                Text(footnote)
                    .font(.system(size: 10, weight: .light))
                    .foregroundColor(NX.textTertiary)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .nxCard()
    }

    private func picker<T: CaseIterable & Hashable & RawRepresentable>(
        _ selection: Binding<T>,
        apply: @escaping (T) -> Void
    ) -> some View where T.RawValue == String, T.AllCases: RandomAccessCollection {
        Menu {
            ForEach(Array(T.allCases), id: \.self) { option in
                Button(title(option)) {
                    withAnimation { selection.wrappedValue = option }
                    apply(option)
                }
            }
        } label: {
            HStack {
                Text(title(selection.wrappedValue))
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 9))
                    .foregroundColor(NX.textSecondary)
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(RoundedRectangle(cornerRadius: 10).fill(NX.track))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }

    private func title<T: RawRepresentable>(_ option: T) -> String where T.RawValue == String {
        option.rawValue.prefix(1).uppercased() + option.rawValue.dropFirst()
    }

    @ViewBuilder
    private func glyph(dots: Int, hold: Bool) -> some View {
        if hold {
            // Horizontal: dot(s) then a rounded bar
            HStack(spacing: 1.4) {
                ForEach(0..<dots, id: \.self) { _ in
                    Circle().fill(NX.segmentOn).frame(width: 4.6, height: 4.6)
                }
                RoundedRectangle(cornerRadius: 1.1)
                    .fill(NX.segmentOn)
                    .frame(width: dots == 1 ? 11.5 : 9, height: 2.2)
            }
        } else {
            // Diagonal dot trail
            let span = 4.6 + CGFloat(dots - 1) * 4.5
            ZStack(alignment: .topLeading) {
                ForEach(0..<dots, id: \.self) { index in
                    Circle().fill(NX.segmentOn)
                        .frame(width: 4.6, height: 4.6)
                        .offset(x: CGFloat(index) * 4.5, y: CGFloat(index) * 4.5)
                }
            }
            .frame(width: span, height: span, alignment: .topLeading)
        }
    }
}
