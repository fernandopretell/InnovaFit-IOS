import SwiftUI
import UIKit

struct MuscleListView: View {
    let musclesWorked: [String: Muscle]
    let gymColor: Color
    let loader: SVGImageLoader
    let videoId: String
    
    @State private var reloadTrigger = UUID()

    var sortedMuscles: [MuscleWithName] {
        musclesWorked.map {
            MuscleWithName(
                _id: $0.key,
                name: $0.key,
                muscle: $0.value
            )
        }
        .sorted { $0.muscle.weight > $1.muscle.weight }
    }

    var muscleIcons: some View {
        let visibleMuscles = Array(sortedMuscles.prefix(3))
        let expectedNames = visibleMuscles.map { $0.name }
        let loadedNames = loader.images.keys.sorted()

        let _ = print("🧪 Esperados: " + expectedNames.joined(separator: ", "))
        let _ = print("✅ loader.images: " + loadedNames.joined(separator: ", "))

        return HStack(spacing: 32) {
            ForEach(visibleMuscles) { item in
                let name = item.name
                let uiImage = loader.images[name]
                let idString = uiImage != nil ? item._id + "-loaded" : item._id + "-loading"

                let status = loader.images[name] != nil ? "sí" : "no"
                let _ = print("🔍 Item.name = '\(name)' | loader.images contiene: \(status)")

                Group {
                    if let uiImage {
                        ReloadableImageView(
                            image: uiImage,
                            id: idString
                        )
                    } else {
                        ProgressView()
                            .frame(height: 100)
                            .id(idString)
                    }
                }
            }
        }
        .id(reloadTrigger)
        .onReceive(loader.$images) { _ in
            reloadTrigger = UUID()
            let _ = print("🔁 images cambió, redibujando muscleIcons con trigger: \(reloadTrigger)")
        }
    }

    var body: some View {
        let maxLabelWidth = sortedMuscles.map { $0.name.width(usingFont: .systemFont(ofSize: 16, weight: .bold)) }.max() ?? 100

        VStack(spacing: 12) {
            muscleIcons
            VStack(spacing: 4) {
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
    }
}

struct ReloadableImageView: View {
    let image: UIImage
    let id: String

    var body: some View {
        Image(uiImage: UIImage(data: image.pngData() ?? Data()) ?? image)
            .resizable()
            .scaledToFit()
            .frame(height: 100)
            .id(id)
    }
}

extension String {
    func width(usingFont font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: attributes).width + 16
    }
}

struct MuscleWithName: Identifiable {
    var id: String { _id }
    let _id: String
    let name: String
    let muscle: Muscle
}

struct MuscleListView_Previews: PreviewProvider {
    static var previews: some View {
        let loader = SVGImageLoader()
        MuscleListView(
            musclesWorked: [
                "Cuádriceps": Muscle(weight: 50, icon: "https://smartgym.b-cdn.net/icons/cuadriceps.svg"),
                "Glúteos": Muscle(weight: 25, icon: "https://smartgym.b-cdn.net/icons/gluteos.svg"),
                "Isquiotibiales": Muscle(weight: 25, icon: "https://smartgym.b-cdn.net/icons/isquiotibiales.svg")
            ],
            gymColor: Color(hex: "#FDD835"),
            loader: loader,
            videoId: "preview"
        )
    }
}



