//
//  ExerciseLog.swift
//  InnovaFit
//
//  Created by Fernando Pretell Lozano on 14/07/25.
//


import Foundation
import FirebaseFirestore

/// Registro de un ejercicio completado por el usuario
struct ExerciseLog: Identifiable, Codable {
    @DocumentID var id: String?
    let machineId: String
    let machineName: String
    let muscleGroups: [String]
    let timestamp: Date
    let userId: String
    let videoId: String
    let videoTitle: String
}