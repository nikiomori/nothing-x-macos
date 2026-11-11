//
//  NXConnectPopup.swift
//  Nothing X MacOS
//
//  Floating card shown when a device connects: device art, name and
//  battery levels, AirPods-style. Lives in its own non-activating panel
//  because the menu bar extra can't open itself.
//

import AppKit
import SwiftUI

// MARK: - Controller

final class NXConnectPopupController {
    static let shared = NXConnectPopupController()
    static let enabledKey = "connectPopupEnabled"

    /// Opens the main window; registered by views that have `openWindow`.
    var openMainWindow: (() -> Void)?

    private var panel: NSPanel?
    private let state = NXConnectPopupState()
    private var observers: [NSObjectProtocol] = []
    private var awaitingFirstReport = false
    private var dismissWork: DispatchWorkItem?

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    /// Call after MainViewViewModel registers its observers so the view
    /// model already holds the new battery values when the card appears.
    func start(viewModel: MainViewViewModel) {
        guard observers.isEmpty else { return }
        let center = NotificationCenter.default

        observers.append(center.addObserver(forName: Notification.Name(BluetoothNotifications.OPENED_RFCOMM_CHANNEL.rawValue), object: nil, queue: .main) { [weak self] _ in
            self?.awaitingFirstReport = true
        })
        observers.append(center.addObserver(forName: Notification.Name(BluetoothNotifications.CLOSED_RFCOMM_CHANNEL.rawValue), object: nil, queue: .main) { [weak self] _ in
            self?.awaitingFirstReport = false
            self?.dismiss()
        })
        observers.append(center.addObserver(forName: Notification.Name(DataNotifications.REPOSITORY_DATA_UPDATED.rawValue), object: nil, queue: .main) { [weak self, weak viewModel] notification in
            guard let self, let viewModel, self.awaitingFirstReport,
                  let device = notification.object as? NothingDeviceEntity else { return }
            // Wait for the first battery report — showing empty bars defeats the point
            let single = DeviceCapabilities.capabilities(for: device.codename).isSingleUnit
            guard single ? device.leftBattery > 0 : (device.isLeftConnected || device.isRightConnected) else { return }
            self.awaitingFirstReport = false
            self.show(content: NXConnectPopupLive(viewModel: viewModel))
        })

        #if DEBUG
        // `-NXDemoPopup B173` shows the card with sample data on launch
        if let raw = UserDefaults.standard.string(forKey: "NXDemoPopup"),
           let codename = Codenames(rawValue: raw) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.show(content: NXConnectCard(data: .demo(codename), state: self.state, actions: self.actions), force: true)
            }
        }
        #endif
    }

    private var actions: NXConnectCard.Actions {
        .init(
            open: { [weak self] in
                self?.dismiss()
                self?.bringMainWindowForward()
            },
            close: { [weak self] in self?.dismiss() },
            hover: { [weak self] hovering in
                guard let self else { return }
                // Keep the card while the pointer is on it
                if hovering { self.dismissWork?.cancel() } else { self.scheduleDismiss(after: 2.5) }
            }
        )
    }

    private func show<Content: View>(content: Content, force: Bool = false) {
        guard force || isEnabled else { return }
        let panel = self.panel ?? makePanel()
        self.panel = panel

        let root = content
            .environmentObject(state)
            .environment(\.nxConnectActions, actions)
        let host = NXFirstMouseHostingView(rootView: AnyView(root))
        panel.contentView = host

        let size = NSSize(width: NXConnectCard.panelWidth, height: NXConnectCard.panelHeight)
        let screen = NSScreen.main ?? NSScreen.screens.first
        if let frame = screen?.visibleFrame {
            panel.setFrame(NSRect(x: frame.midX - size.width / 2, y: frame.minY + 12, width: size.width, height: size.height), display: true)
        }

        state.visible = false
        state.generation += 1
        panel.orderFrontRegardless()
        DispatchQueue.main.async { self.state.visible = true }
        // Fill animation ends ~1.7s in; leaves ~3s to read
        scheduleDismiss(after: 4.5)
    }

    private func scheduleDismiss(after seconds: Double) {
        dismissWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.dismiss() }
        dismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func dismiss() {
        dismissWork?.cancel()
        guard let panel, panel.isVisible else { return }
        state.visible = false
        let generation = state.generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            // A new connection may have reopened the card meanwhile
            guard let self, self.state.generation == generation else { return }
            panel.orderOut(nil)
        }
    }

    private func bringMainWindowForward() {
        if let openMainWindow {
            openMainWindow()
        } else if let window = NSApp.windows.first(where: { $0.identifier?.rawValue.contains("nothing-x") == true }) {
            window.makeKeyAndOrderFront(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false // SwiftUI draws the shadow so it follows the slide
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        return panel
    }
}

/// Clicks land on the card even though the panel never becomes key
private final class NXFirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class NXConnectPopupState: ObservableObject {
    @Published var visible = false
    /// Bumped per presentation so entrance animations restart
    @Published var generation = 0
}

private struct NXConnectActionsKey: EnvironmentKey {
    static let defaultValue = NXConnectCard.Actions(open: {}, close: {}, hover: { _ in })
}

extension EnvironmentValues {
    var nxConnectActions: NXConnectCard.Actions {
        get { self[NXConnectActionsKey.self] }
        set { self[NXConnectActionsKey.self] = newValue }
    }
}

// MARK: - Data

struct NXConnectData: Equatable {
    var name: String
    var codename: Codenames
    var isSingleUnit: Bool
    var left: Int?
    var right: Int?
    var caseLevel: Int?

    #if DEBUG
    static func demo(_ codename: Codenames) -> NXConnectData {
        let single = DeviceCapabilities.capabilities(for: codename).isSingleUnit
        return NXConnectData(name: "DEMO \(codename.rawValue)", codename: codename, isSingleUnit: single,
                             left: 80, right: single ? nil : 75, caseLevel: single ? nil : 18)
    }
    #endif
}

/// Binds the card to live view model values, so a case report arriving
/// a moment after the buds fills in while the card is up
private struct NXConnectPopupLive: View {
    @ObservedObject var viewModel: MainViewViewModel
    @EnvironmentObject var state: NXConnectPopupState
    @Environment(\.nxConnectActions) var actions

    var body: some View {
        NXConnectCard(data: data, state: state, actions: actions)
    }

    private var data: NXConnectData {
        let device = viewModel.nothingDevice
        let codename = device?.codename ?? .UNKNOWN
        return NXConnectData(
            name: device?.nxShortName ?? "NOTHING",
            codename: codename,
            isSingleUnit: DeviceCapabilities.capabilities(for: codename).isSingleUnit,
            left: viewModel.leftBattery.map { Int($0) },
            right: viewModel.rightBattery.map { Int($0) },
            caseLevel: device?.isCaseConnected == true ? device?.caseBattery : nil
        )
    }
}

// MARK: - Card

struct NXConnectCard: View {
    struct Actions {
        var open: () -> Void
        var close: () -> Void
        var hover: (Bool) -> Void
    }

    /// Scale of the "L" size picked in the mockups (base design is 360pt wide)
    static let k: CGFloat = 1.15
    static let cardWidth: CGFloat = 360 * k
    static let panelWidth: CGFloat = cardWidth + 80   // room for the shadow
    static let panelHeight: CGFloat = 300 * k

    let data: NXConnectData
    @ObservedObject var state: NXConnectPopupState
    let actions: Actions

    @State private var isHovering = false

    private let k = NXConnectCard.k

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            card
                .offset(y: state.visible ? 0 : 60 * k)
                .opacity(state.visible ? 1 : 0)
                .animation(
                    state.visible
                        ? .spring(response: 0.55, dampingFraction: 0.72)
                        : .easeIn(duration: 0.3),
                    value: state.visible
                )
        }
        .frame(width: Self.panelWidth, height: Self.panelHeight)
    }

    private var card: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6 * k) {
                Circle().fill(NX.red).frame(width: 5 * k, height: 5 * k)
                Text("CONNECTED")
                    .font(.system(size: 9 * k))
                    .tracking(2.2 * k)
                    .foregroundColor(NX.textTertiary)
            }

            NXMarqueeText(text: data.name, size: 22 * k, minimumScale: 0.7)
                .padding(.horizontal, 24 * k)
                .padding(.top, 4 * k)

            stage
                .padding(.top, 12 * k)
        }
        .padding(.top, 16 * k)
        .padding(.bottom, 16 * k)
        .padding(.horizontal, 20 * k)
        .frame(width: Self.cardWidth)
        .background(NX.card)
        .overlay(
            RoundedRectangle(cornerRadius: 24 * k)
                .stroke(isHovering ? Color(nx: 0x2A2B2E) : NX.cardBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24 * k))
        .overlay(alignment: .topTrailing) { closeButton }
        .overlay(alignment: .topLeading) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 10 * k))
                .foregroundColor(NX.textTertiary)
                .padding(14 * k)
                .opacity(isHovering ? 1 : 0)
        }
        .shadow(color: .black.opacity(0.55), radius: 30, y: 16)
        .contentShape(RoundedRectangle(cornerRadius: 24 * k))
        .onTapGesture { actions.open() }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) { isHovering = hovering }
            actions.hover(hovering)
        }
        .padding(.bottom, 24) // keep the shadow inside the panel
    }

    private var closeButton: some View {
        Button(action: actions.close) {
            Image(systemName: "xmark")
                .font(.system(size: 8 * k, weight: .semibold))
                .foregroundColor(NX.textSecondary)
                .frame(width: 20 * k, height: 20 * k)
                .background(Circle().fill(NX.track))
        }
        .buttonStyle(.plain)
        .padding(12 * k)
    }

    @ViewBuilder
    private var stage: some View {
        let art = NXDeviceArt.images(for: data.codename)
        let hasArt = NSImage(named: art.left) != nil

        if data.isSingleUnit || !hasArt || art.right == nil {
            // Headphones and the neckband have no bundled art
            unit(label: data.isSingleUnit ? "BATTERY" : "LEFT", level: data.left, delay: 0) {
                if hasArt {
                    NXEntranceImage(name: art.left, height: 72 * k, side: 0, dimmed: false, generation: state.generation)
                } else {
                    NXDotGlyph(kind: .headphone, generation: state.generation)
                        .frame(width: 60 * k, height: 50 * k)
                        .padding(.bottom, 10 * k)
                }
            }
        } else {
            HStack(alignment: .bottom, spacing: 12 * k) {
                unit(label: "LEFT", level: data.left, delay: 0) {
                    NXEntranceImage(name: art.left, height: 72 * k, side: -1, dimmed: data.left == nil, generation: state.generation)
                }
                unit(label: "CASE", level: data.caseLevel, delay: 0.15) {
                    NXDotGlyph(kind: .case, generation: state.generation)
                        .frame(width: 52 * k, height: 43 * k)
                        .padding(.bottom, 10 * k)
                }
                unit(label: "RIGHT", level: data.right, delay: 0.3) {
                    NXEntranceImage(name: art.right!, height: 72 * k, side: 1, dimmed: data.right == nil, generation: state.generation)
                }
            }
        }
    }

    private func unit<Art: View>(label: String, level: Int?, delay: Double, @ViewBuilder art: () -> Art) -> some View {
        VStack(spacing: 0) {
            art()
                .frame(height: 72 * k, alignment: .bottom)
            Text(label)
                .font(.system(size: 9 * k))
                .tracking(2.2 * k)
                .foregroundColor(NX.textTertiary)
                .padding(.top, 10 * k)
            NXCountUpBattery(level: level, delay: 0.55 + delay, generation: state.generation, k: k)
                .padding(.top, 3 * k)
        }
        .frame(width: 92 * k)
    }
}

// MARK: - Pieces

/// Bud art that swings in from its side and then floats gently
private struct NXEntranceImage: View {
    let name: String
    let height: CGFloat
    /// -1 left, 1 right, 0 centered single unit
    let side: CGFloat
    let dimmed: Bool
    let generation: Int

    @State private var settled = false
    @State private var floating = false

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .saturation(dimmed ? 0 : 1)
            .brightness(dimmed ? -0.45 : 0)
            .shadow(color: .black.opacity(0.6), radius: 10, y: 10)
            .rotation3DEffect(.degrees(yaw), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .rotationEffect(.degrees(settled ? 0 : Double(22 * side)))
            .offset(x: settled ? 0 : 40 * side, y: floating ? -3 : 0)
            .opacity(settled ? 1 : 0)
            .onAppear(perform: run)
            .onChange(of: generation) { _ in run() }
    }

    private var yaw: Double {
        let s = Double(side)
        if !settled { return -40 * s }
        return floating ? 8 * (s == 0 ? 1 : s) : 0
    }

    private func run() {
        settled = false
        floating = false
        withAnimation(.spring(response: 0.75, dampingFraction: 0.6).delay(0.2 + (side > 0 ? 0.08 : 0))) {
            settled = true
        }
        // Start the idle float out of phase per side
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + (side > 0 ? 1 : 0)) {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) { floating = true }
        }
    }
}

/// Percentage that counts up while the 12 segments light one by one
private struct NXCountUpBattery: View {
    let level: Int?
    let delay: Double
    let generation: Int
    let k: CGFloat

    @State private var shown: Double = 0
    @State private var appearedAt = Date()

    var body: some View {
        NXAnimatedBattery(value: shown, target: level, k: k)
            .onAppear { run(level) }
            .onChange(of: generation) { _ in run(level) }
            // Use the argument: `self.level` is still the old value in here
            .onChange(of: level) { newLevel in animate(to: newLevel) }
    }

    private func run(_ level: Int?) {
        appearedAt = Date()
        shown = 0
        animate(to: level)
    }

    /// The other bud and the case usually report a beat after the first
    /// bud — hold them until their slot so the fill stays left → case → right
    private func animate(to level: Int?) {
        guard let level else { return }
        let wait = max(0, delay - Date().timeIntervalSince(appearedAt))
        let duration = max(0.25, abs(Double(level) - shown) / 100 * 0.8)
        withAnimation(.easeOut(duration: duration).delay(wait)) {
            shown = Double(level)
        }
    }
}

private struct NXAnimatedBattery: View, Animatable {
    var value: Double
    let target: Int?
    let k: CGFloat

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        VStack(spacing: 6 * k) {
            Text(target == nil ? "–" : "\(Int(value.rounded()))%")
                .font(NX.ndot(16 * k))
                .foregroundColor(NX.textPrimary)
                .monospacedDigit()
            HStack(spacing: 2 * k) {
                ForEach(0..<12, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(color(for: index))
                        .frame(height: 4 * k)
                }
            }
        }
    }

    private func color(for index: Int) -> Color {
        guard let target, Double(index) < (value / 100 * 12).rounded() else { return NX.segmentOff }
        return target <= 20 ? NX.red : NX.segmentOn
    }
}

/// Dot-matrix drawings for things we have no art for
private struct NXDotGlyph: View {
    enum Kind { case `case`, headphone }

    let kind: Kind
    let generation: Int

    @State private var progress: CGFloat = 0

    var body: some View {
        NXDotShape(kind: kind, progress: progress, layer: .main)
            .fill(NX.textPrimary.opacity(0.9))
            .overlay(NXDotShape(kind: kind, progress: progress, layer: .seam).fill(NX.textPrimary.opacity(0.4)))
            .overlay(NXDotShape(kind: kind, progress: progress, layer: .led).fill(NX.red))
            .onAppear(perform: run)
            .onChange(of: generation) { _ in run() }
    }

    private func run() {
        progress = 0
        withAnimation(.easeOut(duration: 0.7).delay(0.35)) { progress = 1 }
    }
}

private struct NXDotShape: Shape {
    enum Layer { case main, seam, led }

    let kind: NXDotGlyph.Kind
    var progress: CGFloat
    let layer: Layer

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for dot in dots(in: rect) {
            // Dots grow in a diagonal sweep
            let grow = min(1, max(0, progress * 1.6 - dot.order))
            guard grow > 0 else { continue }
            let r = dot.radius * grow
            path.addEllipse(in: CGRect(x: dot.point.x - r, y: dot.point.y - r, width: r * 2, height: r * 2))
        }
        return path
    }

    private struct Dot { var point: CGPoint; var radius: CGFloat; var order: CGFloat }

    private func dots(in rect: CGRect) -> [Dot] {
        switch kind {
        case .case: return caseDots(in: rect)
        case .headphone: return layer == .main ? headphoneDots(in: rect) : []
        }
    }

    /// Rounded-square case outline with a lid seam and a red LED
    private func caseDots(in rect: CGRect) -> [Dot] {
        let cols = 19, rows = 13
        let step = rect.width / CGFloat(cols)
        let radius = step * 0.36
        var result: [Dot] = []
        for j in 0..<rows {
            for i in 0..<cols {
                let nx = (CGFloat(i) - CGFloat(cols - 1) / 2) / (CGFloat(cols - 1) / 2)
                let ny = (CGFloat(j) - CGFloat(rows - 1) / 2) / (CGFloat(rows - 1) / 2)
                let d = pow(abs(nx), 4) + pow(abs(ny), 4)
                let inside = d <= 1
                let isEdge = inside && d > 0.38
                let isSeam = inside && j == 4 && !isEdge
                let isLED = i == cols / 2 && j == 7
                let wanted: Bool
                switch layer {
                case .main: wanted = isEdge
                case .seam: wanted = isSeam
                case .led: wanted = isLED
                }
                guard wanted else { continue }
                let point = CGPoint(
                    x: rect.minX + step * (CGFloat(i) + 0.5),
                    y: rect.minY + step * (CGFloat(j) + 0.5) + (j > 4 ? step * 0.4 : 0)
                )
                result.append(Dot(point: point, radius: radius, order: CGFloat(i + j) / CGFloat(cols + rows)))
            }
        }
        return result
    }

    /// Headband arc over two ear cups
    private func headphoneDots(in rect: CGRect) -> [Dot] {
        let radius = rect.width * 0.035
        let center = CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.62)
        let arc = rect.width * 0.4
        var points: [CGPoint] = (0...16).map { a in
            let t = Double.pi + Double(a) / 16 * Double.pi
            return CGPoint(x: center.x + arc * CGFloat(cos(t)), y: center.y + arc * CGFloat(sin(t)))
        }
        let cupStep = rect.width * 0.09
        for j in 0..<4 {
            for i in 0..<2 {
                let y = center.y + CGFloat(j) * cupStep
                points.append(CGPoint(x: center.x - arc + CGFloat(i) * cupStep, y: y))
                points.append(CGPoint(x: center.x + arc - CGFloat(i) * cupStep, y: y))
            }
        }
        return points.enumerated().map { Dot(point: $1, radius: radius, order: CGFloat($0) / CGFloat(points.count)) }
    }
}

/// One line of NDOT text: shrinks to `minimumScale`, then scrolls when even
/// that doesn't fit (Bluetooth names can be renamed to anything)
struct NXMarqueeText: View {
    let text: String
    let size: CGFloat
    var minimumScale: CGFloat = 0.7

    @State private var fullWidth: CGFloat = 0
    @State private var scrolling = false

    private let gap: CGFloat = 48

    var body: some View {
        GeometryReader { geo in
            let available = geo.size.width
            let fitsShrunk = fullWidth * minimumScale <= available

            ZStack {
                if fitsShrunk || fullWidth == 0 {
                    Text(text)
                        .font(NX.ndot(size))
                        .foregroundColor(NX.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(minimumScale)
                        .frame(width: available)
                } else {
                    marquee(available: available)
                }
            }
            .frame(width: available, height: geo.size.height)
        }
        .frame(height: size * 1.15)
        .background(
            // Natural width at full size, measured off-screen
            Text(text)
                .font(NX.ndot(size))
                .fixedSize()
                .hidden()
                .background(GeometryReader { proxy in
                    Color.clear
                        .onAppear { fullWidth = proxy.size.width }
                        .onChange(of: proxy.size.width) { fullWidth = $0 }
                })
        )
    }

    private func marquee(available: CGFloat) -> some View {
        let shrunk = size * minimumScale
        let width = fullWidth * minimumScale
        return HStack(spacing: gap) {
            Text(text)
            Text(text)
        }
        .font(NX.ndot(shrunk))
        .foregroundColor(NX.textPrimary)
        .fixedSize()
        .offset(x: scrolling ? -(width + gap) : 0)
        .frame(width: available, alignment: .leading)
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 14 / available),
                    .init(color: .black, location: 1 - 14 / available),
                    .init(color: .clear, location: 1),
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .onAppear {
            scrolling = false
            withAnimation(.linear(duration: Double((width + gap) / 34)).delay(1.5).repeatForever(autoreverses: false)) {
                scrolling = true
            }
        }
    }
}
