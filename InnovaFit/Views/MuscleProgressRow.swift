import SwiftUICore
import SwiftUI

struct MuscleProgressRow: View {
    let label: String
    let weight: Double
    let maxLabelWidth: CGFloat
    let gymColor: Color

    var body: some View {
        
        HStack(spacing: 0) {
            // Texto con ancho fijo (igual para todos los labels)
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .frame(width: maxLabelWidth, alignment: .center)
                .foregroundColor(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Color.black)
                .cornerRadius(12)
                .zIndex(1)
            
            // Barra de progreso
            ZStack(alignment: .leading) {
                
                // Barra de fondo con degradado y máscara
                RoundedRectangle(cornerRadius: 10)
                    .fill(gymColor.opacity(weight/100))
                    .frame(height: 13)
                    .mask(
                        GeometryReader { geometry in
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: geometry.size.width * CGFloat(weight) / 100)
                            
                        }
                    )
                
                // Contorno completo
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black, lineWidth: 1)
                    .frame(height: 13)
            }
            .offset(x: -8) // Superpone con el texto
            .frame(maxWidth: .infinity)
            
            
            // Peso a la derecha
            Text("\(Int(weight))")
                .font(.system(size: 30, weight: .black))
                .foregroundColor(.black)
                .padding(.leading, 5)
            
            Text("%")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.black)
                .padding(.top, 8)
        }
    }
}

struct MuscleProgressRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            MuscleProgressRow(
                label: "Gluteos",
                weight: 70,
                maxLabelWidth: 120,
                gymColor: .red
            )
            MuscleProgressRow(
                label: "Cuadriceps",
                weight: 20,
                maxLabelWidth: 120,
                gymColor: .red
            )
            MuscleProgressRow(
                label: "Isquiotibiales",
                weight: 10,
                maxLabelWidth: 120,
                gymColor: .red
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

