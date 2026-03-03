//
//  EQCurveView.swift
//  Nothing X MacOS
//

import SwiftUI
import Charts

struct EQCurveView: View {
    var bass: Double
    var mid: Double
    var treble: Double

    private var dataPoints: [(label: String, value: Double)] {
        [
            ("Bass", bass),
            ("Mid", mid),
            ("Treble", treble)
        ]
    }

    var body: some View {
        Chart {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, point in
                LineMark(
                    x: .value("Band", point.label),
                    y: .value("dB", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.red.opacity(0.8))

                AreaMark(
                    x: .value("Band", point.label),
                    y: .value("dB", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.red.opacity(0.3), Color.red.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartYScale(domain: -6...6)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 7))
                    .foregroundStyle(Color.gray)
            }
        }
        .chartYAxis {
            AxisMarks(values: [-6, 0, 6]) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel()
                    .font(.system(size: 7))
                    .foregroundStyle(Color.gray)
            }
        }
        .frame(height: 40)
    }
}

extension EQCurveView {
    init(profile: EQProfiles, customBass: Double = 0, customMid: Double = 0, customTreble: Double = 0) {
        switch profile {
        case .BALANCED:
            self.init(bass: 0, mid: 0, treble: 0)
        case .MORE_BASE:
            self.init(bass: 4, mid: 0, treble: 0)
        case .MORE_TREBEL:
            self.init(bass: 0, mid: 0, treble: 4)
        case .VOICE:
            self.init(bass: 0, mid: 3, treble: 0)
        case .CUSTOM:
            self.init(bass: customBass, mid: customMid, treble: customTreble)
        }
    }
}
