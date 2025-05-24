import SwiftUI
import SVGKit

struct MuscleListView: View {
    let musclesWorked: [String: Muscle]
    let gymColor: Color
    
    @StateObject private var svgLoader = SVGImageLoader()
    
    var sortedMuscles: [MuscleWithName] {
        musclesWorked.map {
            MuscleWithName(
                _id: UUID().uuidString,
                name: $0.key,
                muscle: $0.value
            )
        }
        .sorted { $0.muscle.weight > $1.muscle.weight }
    }

    
    var muscleIcons: some View {
        HStack(spacing: 32) {
            ForEach(sortedMuscles.prefix(3)) { item in
                if let uiImage = svgLoader.images[item.name] {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 110)
                } else {
                    ProgressView()
                        .frame(height: 110)
                }
            }
        }
    }

    
    var body: some View {
        let maxLabelWidth = sortedMuscles.map { $0.name.width(usingFont: .systemFont(ofSize: 16, weight: .bold)) }.max() ?? 100
        
        VStack(spacing: 24) {
            // Mostrar los íconos arriba
            muscleIcons
            
            VStack(spacing: 5) {
                ForEach(sortedMuscles) { item in
                    MuscleProgressRow(
                        label: item.name,
                        weight: Double(item.muscle.weight),
                        maxLabelWidth: maxLabelWidth,
                        gymColor: gymColor
                    )
                }
            }
        }
        .padding()
        .onAppear {
            svgLoader.loadSVGs(muscles: sortedMuscles, gymColorHex: gymColor.toHex())

        }
        
    }
}

extension String {
    func width(usingFont font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: attributes).width + 16 // Padding extra opcional
    }
}

struct MuscleWithName: Identifiable {
    var id: String { _id }  // o el campo único real
    let _id: String
    let name: String
    let muscle: Muscle
}


func longestTextWidth(for items: [MuscleWithName], font: UIFont = UIFont.boldSystemFont(ofSize: 16)) -> CGFloat {
    items.map { item in
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return (item.name as NSString).size(withAttributes: attributes).width
    }.max() ?? 0
}


struct MuscleListView_Previews: PreviewProvider {
    static var previews: some View {
        MuscleListView(
            musclesWorked: [
                "Cuádriceps": Muscle(weight: 50, icon: "https://smartgym.b-cdn.net/icons/cuadriceps.svg"),
                "Glúteos": Muscle(weight: 25, icon: "https://smartgym.b-cdn.net/icons/gluteos.svg"),
                "Isquiotibiales": Muscle(weight: 25, icon: "https://smartgym.b-cdn.net/icons/isquiotibiales.svg")
            ],
            gymColor: Color(hex: "#FDD835")
        )
    }
}
