//
//  Environment.swift
//  InnovaFit
//
//  Created by Fernando Pretell Lozano on 20/06/25.
//


import Foundation

struct AppEnvironment {
    static var isTestFlight: Bool {
        guard let url = Bundle.main.appStoreReceiptURL else { return false }
        return url.lastPathComponent == "sandboxReceipt"
    }
}
