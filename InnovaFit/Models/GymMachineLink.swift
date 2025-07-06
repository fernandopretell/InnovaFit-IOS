//
//  GymMachineLink.swift
//  InnovaFit
//
//  Created by Fernando Pretell Lozano on 6/07/25.
//

import FirebaseFirestore


struct GymMachineLink: Identifiable, Codable {
    @DocumentID var id: String?
    var gymId: String
    var machineId: String
}
