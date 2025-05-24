//
//  Segment.swift
//  InnovaFit
//
//  Created by Fernando Pretell Lozano on 21/05/25.
//


import Foundation

struct Segment: Codable {
    let start: Int64 // o `Double` si usas segundos con decimales
    let end: Int64
    let tip: String
}
