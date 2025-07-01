import SwiftUI

struct AccessRestrictedView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Acceso restringido")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

            Text("Dirígete a una de nuestras etiquetas InnovaFit para poder usar la app. Identifícalo así:")
                .font(.system(size: 16))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Image("etiqueta_innovafit") // asegúrate de tenerla en Assets
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 250)
                .padding(.bottom, 16)

            Button(action: { dismiss() }) {
                Text("Cerrar")
                    .foregroundColor(Color(hex: "#FDD835"))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
        .padding()
        .presentationDetents([.medium]) // puedes cambiar a .large o [.medium, .large]
        .presentationDragIndicator(.visible)
    }
}
