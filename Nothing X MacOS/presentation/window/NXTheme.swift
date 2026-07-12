//
//  NXTheme.swift
//  Nothing X MacOS
//
//  Design tokens and shared controls for the full-window interface.
//

import SwiftUI

extension Color {
    init(nx hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum NX {
    // Surfaces
    static let sidebar = Color(nx: 0x0A0A0B)
    static let sidebarBorder = Color(nx: 0x17181A)
    static let card = Color(nx: 0x101113)
    static let cardBorder = Color(nx: 0x1B1C1E)
    static let deviceCard = Color(nx: 0x131416)
    static let deviceCardBorder = Color(nx: 0x1D1E20)
    static let track = Color(nx: 0x1C1D1F)
    static let capsule = Color(nx: 0xC1C2C4)
    static let hairline = Color(nx: 0x141517)
    static let chipBorder = Color(nx: 0x232426)

    // Text
    static let textPrimary = Color(nx: 0xF2F2F2)
    static let textSecondary = Color(nx: 0x8A8A8C)
    static let textTertiary = Color(nx: 0x6E6E70)
    static let textFaint = Color(nx: 0x4A4A4C)
    static let onCapsule = Color.black.opacity(0.85)
    static let offWhite = Color.white.opacity(0.8)

    // Accents
    static let red = Color(nx: 0xD71721)
    static let segmentOn = Color(nx: 0xE4E3E1)
    static let segmentOff = Color(nx: 0x232427)

    static func ndot(_ size: CGFloat) -> Font { .custom("NDOT45inspiredbyNOTHING", size: size) }
    static func pixel(_ size: CGFloat) -> Font { .custom("5by7", size: size) }
}

// MARK: - Device art

enum NXDeviceArt {
    /// Asset names for a device; `right` is nil for single-unit devices.
    static func images(for codename: Codenames) -> (left: String, right: String?) {
        switch codename {
        case .ONE: return ("ear_1_left", "ear_1_right")
        case .TWO, .UNKNOWN: return ("ear_2_left", "ear_2_right")
        case .TWOS: return ("ear_left", "ear_right")
        case .CLEFFA: return ("ear_a_yellow_left", "ear_a_yellow_right")
        case .FLAFFY: return ("ear_open_left", "ear_open_right")
        case .STICKS: return ("ear_stick_left", "ear_stick_right")
        case .EAR3: return ("ear_3_left", "ear_3_right")
        case .CORSOLA: return ("cmf_buds_pro_left", "cmf_buds_pro_right")
        case .ESPEON: return ("cmf_buds_pro_2_left", "cmf_buds_pro_2_right")
        case .DONPHAN, .GIRAFARIG, .GLIGAR, .HOOTHOOT: return ("cmf_buds_left", "cmf_buds_right")
        case .CROBAT: return ("cmf_neckband_pro", nil)
        case .ELEKID, .HEADPHONE_PRO: return ("headphone_1", nil)
        case .HEADPHONE_A: return ("headphone_a", nil)
        }
    }
}

/// Device illustration: an earbud pair side by side, or a single image
/// for single-unit devices. Widths follow the design's 0.56 bud ratio.
struct NXBudsImage: View {
    let codename: Codenames?
    var height: CGFloat

    var body: some View {
        let art = NXDeviceArt.images(for: codename ?? .UNKNOWN)
        if NSImage(named: art.left) == nil {
            // Art not bundled (headphone/neckband images exceed the design
            // export size cap) — show a glyph instead of an empty frame
            Image(systemName: "headphones")
                .font(.system(size: height * 0.42, weight: .light))
                .foregroundColor(NX.textSecondary)
                .frame(width: height * 0.92, height: height)
        } else {
            HStack(alignment: .bottom, spacing: 0) {
                Image(art.left)
                    .resizable().scaledToFit()
                    .frame(width: height * (art.right == nil ? 0.92 : 0.56), height: height)
                if let right = art.right {
                    Image(right)
                        .resizable().scaledToFit()
                        .frame(width: height * 0.56, height: height)
                }
            }
        }
    }
}

extension NothingDeviceEntity {
    /// "Nothing Ear (2)" → "EAR (2)" — compact UI drops the brand prefix
    var nxShortName: String {
        let name = self.name.uppercased()
        return name.hasPrefix("NOTHING ") ? String(name.dropFirst("NOTHING ".count)) : name
    }
}

extension MainViewViewModel {
    /// "L 35 · R 25 · CASE 70", or "BATTERY 90" for single-unit devices
    var nxBatteryLine: String {
        let single = nothingDevice.map { DeviceCapabilities.capabilities(for: $0.codename).isSingleUnit } ?? false
        if single {
            return "BATTERY \(leftBattery.map { String(Int($0)) } ?? "–")"
        }
        let left = leftBattery.map { String(Int($0)) } ?? "–"
        let right = rightBattery.map { String(Int($0)) } ?? "–"
        let box = nothingDevice?.isCaseConnected == true ? String(nothingDevice!.caseBattery) : "–"
        return "L \(left) · R \(right) · CASE \(box)"
    }
}

extension EQProfiles {
    var nxName: String {
        switch self {
        case .BALANCED: return "BALANCED"
        case .MORE_BASE: return "MORE BASS"
        case .MORE_TREBEL: return "MORE TREBLE"
        case .VOICE: return "VOICE"
        case .CUSTOM: return "CUSTOM"
        }
    }
}

// MARK: - Card

struct NXCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(NX.card)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(NX.cardBorder))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

extension View {
    func nxCard() -> some View { modifier(NXCardModifier()) }
}

// MARK: - Labels

struct NXSectionLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 10))
            .tracking(2.4)
            .foregroundColor(NX.textTertiary)
    }
}

// MARK: - Segmented control

struct NXSegmented<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T
    var fontSize: CGFloat = 11

    var body: some View {
        GeometryReader { geo in
            let slot = (geo.size.width - 8) / CGFloat(max(options.count, 1))
            let index = options.firstIndex { $0.value == selection } ?? 0
            ZStack(alignment: .topLeading) {
                Capsule().fill(NX.track)
                Capsule()
                    .fill(NX.capsule)
                    .frame(width: slot, height: geo.size.height - 8)
                    .offset(x: 4 + slot * CGFloat(index), y: 4)
                    .animation(.bouncy(duration: 0.3), value: index)
                HStack(spacing: 0) {
                    ForEach(options, id: \.value) { option in
                        Button {
                            selection = option.value
                        } label: {
                            Text(option.label)
                                .font(.system(size: fontSize))
                                .tracking(1.5)
                                .foregroundColor(selection == option.value ? NX.onCapsule : NX.offWhite)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
            }
        }
    }
}

// MARK: - Switch

struct NXSwitch: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .font(.system(size: 11, weight: .light))
                .tracking(1)
                .foregroundColor(NX.offWhite)
            Spacer()
            Capsule()
                .fill(configuration.isOn ? NX.capsule : NX.track)
                .frame(width: 40, height: 22)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(configuration.isOn ? NX.sidebar : Color(nx: 0x5A5A5C))
                        .frame(width: 18, height: 18)
                        .padding(2)
                }
                .onTapGesture {
                    withAnimation(.bouncy(duration: 0.25)) { configuration.isOn.toggle() }
                }
        }
    }
}

// MARK: - Battery segments

struct NXBatteryBar: View {
    let level: Int?
    var segmentHeight: CGFloat = 6

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(index < filled ? NX.segmentOn : NX.segmentOff)
                    .frame(height: segmentHeight)
            }
        }
    }

    private var filled: Int {
        guard let level else { return 0 }
        return Int((Double(level) / 100 * 12).rounded())
    }
}

// MARK: - Buttons

struct NXFilledPill: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11))
            .tracking(1.8)
            .foregroundColor(NX.onCapsule)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Capsule().fill(NX.capsule))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct NXChip: ButtonStyle {
    var selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 9))
            .tracking(1.2)
            .foregroundColor(selected ? NX.onCapsule : NX.textSecondary)
            .lineLimit(1)
            .fixedSize() // chips keep their label instead of collapsing when space is tight
            .padding(.horizontal, 12)
            .frame(height: 26)
            .background(
                Capsule()
                    .fill(selected ? NX.capsule : .clear)
                    .overlay(Capsule().stroke(selected ? .clear : NX.chipBorder))
            )
            .contentShape(Capsule())
    }
}
