//
//  LogCategory.swift
//  InnovaFit
//
//  Created by Fernando Pretell Lozano on 19/06/25.
//


import Foundation
import os

enum LogCategory: String {
    case lifecycle
    case universalLink
    case network
    case viewModel
    case error
}

struct AppLogger {
    static func log(_ message: String, category: LogCategory = .lifecycle, level: OSLogType = .default) {
        let logger = Logger(subsystem: "com.fpretell.innovafit", category: category.rawValue)

        switch level {
        case .info:
            logger.info("\(message, privacy: .public)")
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        default:
            logger.log("\(message, privacy: .public)")
        }
    }
}
