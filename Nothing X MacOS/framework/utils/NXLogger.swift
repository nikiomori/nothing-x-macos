//
//  NXLogger.swift
//  Nothing X MacOS
//
//  Created by Claude on 2026/3/3.
//

import Foundation
import os

enum LogCategory: String {
    case bluetooth = "Bluetooth"
    case nothingService = "NothingService"
    case persistence = "Persistence"
    case ui = "UI"
    case device = "Device"
}

struct NXLogger {
    private let logger: os.Logger

    init(category: LogCategory) {
        self.logger = os.Logger(
            subsystem: Bundle.main.bundleIdentifier ?? "com.nothingx.macos",
            category: category.rawValue
        )
    }

    func debug(_ message: String) { logger.debug("\(message, privacy: .public)") }
    func info(_ message: String) { logger.info("\(message, privacy: .public)") }
    func warning(_ message: String) { logger.warning("\(message, privacy: .public)") }
    func error(_ message: String) { logger.error("\(message, privacy: .public)") }
}
