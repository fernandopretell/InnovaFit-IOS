//
//  MuscleHistoryView.swift
//  InnovaFit
//
//  Created by Fernando Pretell Lozano on 11/07/25.
//


import SwiftUI

struct MuscleHistoryView: View {
    var body: some View {
        VStack {
            Text("Historial de músculos trabajados")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textTitle)
                .padding()

            Spacer()

            Text("Aquí se mostrará el historial próximamente...")
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }
}
