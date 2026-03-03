//
//  EQPresetStorage.swift
//  Nothing X MacOS
//

import Foundation

class EQPresetStorage {
    static let shared = EQPresetStorage()

    private let log = NXLogger(category: .persistence)
    private let fileName = "eq_presets"
    private var presets: [EQPreset] = []

    private init() {
        loadPresets()
    }

    private func loadPresets() {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            log.error("Document directory not found")
            return
        }

        let fileURL = documentDirectory.appendingPathComponent("\(fileName).json")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            presets = try JSONDecoder().decode([EQPreset].self, from: data)
        } catch {
            log.error("Error loading EQ presets: \(error)")
        }
    }

    private func savePresets() {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            log.error("Document directory not found")
            return
        }

        let fileURL = documentDirectory.appendingPathComponent("\(fileName).json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(presets)
            try data.write(to: fileURL)
        } catch {
            log.error("Error saving EQ presets: \(error)")
        }
    }

    func getAll() -> [EQPreset] {
        return presets
    }

    func save(preset: EQPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
        } else {
            presets.append(preset)
        }
        savePresets()
    }

    func delete(id: UUID) {
        presets.removeAll { $0.id == id }
        savePresets()
    }
}
