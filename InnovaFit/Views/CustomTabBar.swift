//
//  CustomTabBar.swift
//  InnovaFit
//
//  Created by Fernando Pretell Lozano on 11/07/25.
//

import SwiftUICore
import SwiftUI


struct CustomTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    var onCentralAction: () -> Void

    var body: some View {
        HStack {
            // Tab 1
            Button {
                selectedTab = .home
            } label: {
                VStack {
                    Image(systemName: "house.fill")
                    Text("Inicio")
                }
                .foregroundColor(selectedTab == .home ? .green : .gray)
            }

            Spacer()

            // Botón central
            Button(action: onCentralAction) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 60, height: 60)
                        .shadow(radius: 4)

                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.title2)
                }
            }
            .offset(y: -20)

            Spacer()

            // Tab 2
            Button {
                selectedTab = .history
            } label: {
                VStack {
                    Image(systemName: "chart.bar.fill")
                    Text("Historial")
                }
                .foregroundColor(selectedTab == .history ? .green : .gray)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .shadow(radius: 5)
        .padding(.horizontal)
    }
}
