//
//  ScannerRoute.swift
//  InnovaFit
//
//  Created by Fernando Pretell Lozano on 11/07/25.
//


enum TabsRoute: Hashable, Codable {
    case qrScanner
    case machine(machine: Machine, gym: Gym)
}
