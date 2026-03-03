//
//  EQPreset.swift
//  Nothing X MacOS
//

import Foundation

struct EQPreset: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var bass: Float
    var mid: Float
    var treble: Float

    init(id: UUID = UUID(), name: String, bass: Float, mid: Float, treble: Float) {
        self.id = id
        self.name = name
        self.bass = bass
        self.mid = mid
        self.treble = treble
    }
}
